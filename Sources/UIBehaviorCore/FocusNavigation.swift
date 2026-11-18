/// Logical roving focus. Adapters apply the result with FocusState/UIFocusSystem.
public struct FocusNavigation<ID: Hashable & Sendable>: Sendable, Equatable {
  public enum Movement: Sendable { case next, previous, first, last }
  public private(set) var focused: ID?
  public var wraps: Bool

  public init(focused: ID? = nil, wraps: Bool = true) {
    self.focused = focused
    self.wraps = wraps
  }

  @discardableResult
  public mutating func move(_ movement: Movement, order: [ID], disabled: Set<ID> = []) -> ID? {
    let items = order.filter { !disabled.contains($0) }
    guard !items.isEmpty else {
      focused = nil
      return nil
    }
    let current = focused.flatMap { items.firstIndex(of: $0) }
    let index: Int
    switch movement {
    case .first: index = 0
    case .last: index = items.count - 1
    case .next:
      let next = (current ?? -1) + 1
      index = wraps ? next % items.count : min(next, items.count - 1)
    case .previous:
      let previous = (current ?? items.count) - 1
      index = wraps ? (previous + items.count) % items.count : max(previous, 0)
    }
    focused = items[index]
    return focused
  }

  public mutating func focus(_ id: ID?, order: [ID], disabled: Set<ID> = []) {
    focused = id.flatMap { order.contains($0) && !disabled.contains($0) ? $0 : nil }
  }
}
