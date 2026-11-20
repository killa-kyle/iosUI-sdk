import SwiftUI
import UIBehaviorCore

/// Record exact geometry without publishing a SwiftUI state update for every scrolled pixel.
@MainActor public final class ReadingAnchorTracker<ID: Hashable & Sendable> {
  private var memory = ReadingAnchorMemory<ID>()
  public var anchor: ReadingAnchor<ID>? { memory.anchor }
  public var isFrozen: Bool { memory.isFrozen }
  public init() {}
  @discardableResult public func record(_ value: ReadingAnchor<ID>) -> Bool { memory.record(value) }
  @discardableResult public func record(_ value: ReadingAnchorMeasurement<ID>) -> Bool {
    memory.record(value)
  }
  public func freeze() { memory.freeze() }
  public func resume(in viewport: BehaviorRect, layoutRevision: UInt64) {
    memory.resume(in: viewport, layoutRevision: layoutRevision)
  }
  public func clear() { memory.clear() }
}

public struct BehaviorReadingAnchorPreference<ID: Hashable & Sendable>: PreferenceKey {
  public static var defaultValue: ReadingAnchorMeasurement<ID>? { nil }
  public static func reduce(
    value: inout ReadingAnchorMeasurement<ID>?,
    nextValue: () -> ReadingAnchorMeasurement<ID>?
  ) {
    guard let next = nextValue() else { return }
    if value == nil || next.isRestorationTarget { value = next }
  }
}

extension View {
  /// Measure visible rows, prioritizing a requested restoration target after reflow.
  public func behaviorReadingAnchor<ID: Hashable & Sendable>(
    _ id: ID, in space: CoordinateSpace, viewport: BehaviorRect, layoutRevision: UInt64,
    restorationTarget: ID? = nil
  ) -> some View {
    background {
      GeometryReader { geometry in
        let frame = geometry.frame(in: space)
        let anchor =
          frame.maxY > 0 && frame.minY < viewport.height
          ? ReadingAnchor(id: id, top: Double(frame.minY), height: Double(frame.height)) : nil
        Color.clear.preference(
          key: BehaviorReadingAnchorPreference<ID>.self,
          value: anchor.flatMap {
            ReadingAnchorMeasurement(
              anchor: $0, viewport: viewport,
              layoutRevision: layoutRevision, isRestorationTarget: id == restorationTarget)
          })
      }
    }
  }
}
