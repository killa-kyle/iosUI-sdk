import Foundation

/// Fixed-row virtualization math for custom renderers. Prefer native List for ordinary lists.
public struct VirtualWindow: Sendable, Equatable {
  public let count: Int
  public let itemExtent: Double
  public let overscan: Int
  public init(count: Int, itemExtent: Double, overscan: Int = 2) {
    precondition(count >= 0 && itemExtent.isFinite && itemExtent > 0 && overscan >= 0)
    self.count = count
    self.itemExtent = itemExtent
    self.overscan = overscan
  }
  public var totalExtent: Double { Double(count) * itemExtent }
  public func visibleRange(offset: Double, viewportExtent: Double) -> Range<Int> {
    guard offset.isFinite && viewportExtent.isFinite && viewportExtent > 0 && count > 0 else {
      return 0..<0
    }
    let start = min(max(offset, 0), totalExtent)
    let first = max(0, Int(floor(start / itemExtent)) - overscan)
    let last = min(
      count, Int(ceil(min(start + viewportExtent, totalExtent) / itemExtent)) + overscan)
    return first..<max(first, last)
  }
  public func offset(for index: Int) -> Double? {
    guard index >= 0 && index < count else { return nil }
    return Double(index) * itemExtent
  }
}
