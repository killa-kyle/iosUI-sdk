/// Keeps pre-transition geometry stable while a viewport changes or a row reflows.
public struct ReadingAnchorMemory<ID: Hashable & Sendable>: Sendable, Equatable {
  public private(set) var anchor: ReadingAnchor<ID>?
  public private(set) var isFrozen = false
  private var viewport: BehaviorRect?
  private var layoutRevision: UInt64?
  public init() {}
  @discardableResult public mutating func record(_ value: ReadingAnchor<ID>) -> Bool {
    guard !isFrozen else { return false }
    let changedID = anchor?.id != value.id
    anchor = value
    return changedID
  }
  @discardableResult public mutating func record(_ value: ReadingAnchorMeasurement<ID>) -> Bool {
    if let revision = layoutRevision, value.layoutRevision < revision { return false }
    if let viewport, viewport != value.viewport || layoutRevision != value.layoutRevision {
      isFrozen = true
      return false
    }
    guard !isFrozen else { return false }
    viewport = value.viewport
    layoutRevision = value.layoutRevision
    return record(value.anchor)
  }
  public mutating func freeze() { isFrozen = true }
  public mutating func resume(in viewport: BehaviorRect, layoutRevision: UInt64) {
    guard viewport.isValid, viewport.width > 0, viewport.height > 0 else { return }
    self.viewport = viewport
    self.layoutRevision = layoutRevision
    isFrozen = false
  }
  public mutating func clear() {
    anchor = nil
    viewport = nil
    layoutRevision = nil
    isFrozen = false
  }
}
