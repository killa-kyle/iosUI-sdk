import Foundation

public enum ScrollInteractionPhase: Sendable, Equatable {
  case idle, tracking, dragging, decelerating, animating
  public var holdsAutomaticScrolling: Bool {
    self == .tracking || self == .dragging || self == .decelerating
  }
}

/// A measured row position in viewport-local logical points.
public struct ReadingAnchor<ID: Hashable & Sendable>: Sendable, Equatable {
  public let id: ID
  public let top: Double
  public let height: Double
  public init?(id: ID, top: Double, height: Double) {
    guard top.isFinite, height.isFinite, (top + height).isFinite, height > 0 else { return nil }
    self.id = id
    self.top = top
    self.height = height
  }
  /// Alignment preserving this row's pixel offset after a viewport resize.
  public func alignment(in viewportHeight: Double) -> Double? {
    guard viewportHeight.isFinite, viewportHeight > 0 else { return nil }
    let remaining = viewportHeight - height
    let value = abs(remaining) > 1 ? top / remaining : 0
    return value.isFinite ? value : nil
  }
}

/// A row measured in a particular native layout pass.
public struct ReadingAnchorMeasurement<ID: Hashable & Sendable>: Sendable, Equatable {
  public let anchor: ReadingAnchor<ID>
  public let viewport: BehaviorRect
  public let layoutRevision: UInt64
  public let isRestorationTarget: Bool
  public init?(
    anchor: ReadingAnchor<ID>, viewport: BehaviorRect, layoutRevision: UInt64,
    isRestorationTarget: Bool = false
  ) {
    guard viewport.isValid, viewport.width > 0, viewport.height > 0 else { return nil }
    self.anchor = anchor
    self.viewport = viewport
    self.layoutRevision = layoutRevision
    self.isRestorationTarget = isRestorationTarget
  }
}

/// Intent, coalescing and stale-command fencing. The host executes requests with native scrolling.
public struct StreamScrollCoordinator<ID: Hashable & Sendable>: Sendable, Equatable {
  public enum Target: Sendable, Equatable {
    case latest
    case item(ID, alignment: Double)
  }
  public enum Reason: Sendable, Equatable {
    case stream, initial, history, viewport, keyboard, explicit
  }
  public struct Request: Sendable, Equatable {
    fileprivate let scope: UUID
    public let revision: UInt64
    public let target: Target
    public let reason: Reason
    public let animated: Bool
  }
  private let scope = UUID()
  private var revision: UInt64 = 0
  private struct Restoration: Sendable, Equatable {
    let anchor: ReadingAnchor<ID>
    let viewport: BehaviorRect
    let layoutRevision: UInt64
  }
  private var restoration: Restoration?
  public var restorationTarget: ID? { restoration?.anchor.id }
  public var isRestoringAnchor: Bool {
    if restoration != nil { return true }
    guard let pending else { return false }
    if case .item = pending.target { return true }
    return false
  }
  private var userGesture = false
  public private(set) var followsLatest: Bool
  public private(set) var phase: ScrollInteractionPhase = .idle
  public private(set) var readingAnchor: ReadingAnchor<ID>?
  public private(set) var pending: Request?
  public init(followsLatest: Bool = true) { self.followsLatest = followsLatest }

  /// Restore caller-owned intent when switching conversations or restoring a screen.
  public mutating func setIntent(followsLatest: Bool) {
    if self.followsLatest != followsLatest { cancel() }
    self.followsLatest = followsLatest
    if followsLatest { readingAnchor = nil }
  }
  public mutating func beginReading(anchor: ReadingAnchor<ID>? = nil) {
    cancel()
    followsLatest = false
    if let anchor { readingAnchor = anchor }
  }
  public mutating func followLatest() {
    cancel()
    followsLatest = true
    readingAnchor = nil
  }
  /// Native tracking pauses following; actual dragging changes reading intent.
  public mutating func observePhase(_ next: ScrollInteractionPhase, atLatest: Bool) {
    phase = next
    switch next {
    case .tracking:
      cancel()
    case .dragging, .decelerating:
      userGesture = true
      beginReading()
    case .idle:
      if userGesture && atLatest { followLatest() }
      userGesture = false
    case .animating:
      userGesture = false
    }
  }
  public mutating func remember(_ anchor: ReadingAnchor<ID>) {
    guard !followsLatest, !isRestoringAnchor else { return }
    readingAnchor = anchor
  }
  @discardableResult public mutating func request(
    _ target: Target, reason: Reason, animated: Bool = false, replacingPending: Bool = false
  ) -> Request? {
    guard !phase.holdsAutomaticScrolling else { return nil }
    if case .latest = target, !followsLatest { return nil }
    if case .item(_, let alignment) = target, !alignment.isFinite { return nil }
    guard replacingPending || pending == nil else { return nil }
    restoration = nil
    revision &+= 1
    let next = Request(
      scope: scope, revision: revision, target: target, reason: reason, animated: animated)
    pending = next
    return next
  }
  @discardableResult public mutating func restoreAnchor(
    viewportHeight: Double, reason: Reason = .viewport
  ) -> Request? {
    guard !followsLatest, let anchor = readingAnchor,
      let alignment = anchor.alignment(in: viewportHeight)
    else { return nil }
    return request(.item(anchor.id, alignment: alignment), reason: reason, replacingPending: true)
  }
  /// Locate first, then align after measuring the row in its new width/height.
  @discardableResult public mutating func beginAnchorRestoration(
    in viewport: BehaviorRect, layoutRevision: UInt64, reason: Reason = .viewport
  ) -> Request? {
    guard viewport.isValid, viewport.width > 0, viewport.height > 0 else {
      cancel()
      return nil
    }
    guard !followsLatest, let anchor = readingAnchor,
      let request = request(.item(anchor.id, alignment: 0), reason: reason, replacingPending: true)
    else { return nil }
    restoration = Restoration(anchor: anchor, viewport: viewport, layoutRevision: layoutRevision)
    return request
  }
  @discardableResult public mutating func measureRestoration(
    _ measurement: ReadingAnchorMeasurement<ID>
  ) -> Request? {
    guard let restoration, measurement.anchor.id == restoration.anchor.id,
      measurement.viewport == restoration.viewport,
      measurement.layoutRevision == restoration.layoutRevision,
      let adjusted = ReadingAnchor(
        id: restoration.anchor.id, top: restoration.anchor.top,
        height: measurement.anchor.height),
      let alignment = adjusted.alignment(in: restoration.viewport.height)
    else { return nil }
    return request(
      .item(adjusted.id, alignment: alignment), reason: .viewport,
      replacingPending: true)
  }
  /// Call with the complete set of live row IDs after deletion/filtering.
  public mutating func reconcile(availableIDs: Set<ID>) {
    let removedAnchor = readingAnchor.map { !availableIDs.contains($0.id) } ?? false
    let removedRequest: Bool
    if let pending, case .item(let id, _) = pending.target {
      removedRequest = !availableIDs.contains(id)
    } else {
      removedRequest = false
    }
    if removedAnchor || removedRequest {
      cancel()
      if removedAnchor { readingAnchor = nil }
    }
  }
  public func isCurrent(_ request: Request) -> Bool { pending == request }
  @discardableResult public mutating func finish(_ request: Request) -> Bool {
    guard isCurrent(request) else { return false }
    pending = nil
    return true
  }
  public mutating func cancel() {
    revision &+= 1
    pending = nil
    restoration = nil
  }
}
