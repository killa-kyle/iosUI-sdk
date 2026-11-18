/// Identity-based reorder; `to` is the final index, not a pre-removal offset.
public enum Reorder {
  @discardableResult
  public static func move<ID: Hashable>(
    _ id: ID, to index: Int, in items: inout [ID],
    disabled: Set<ID> = []
  ) -> Bool {
    guard !disabled.contains(id), let old = items.firstIndex(of: id),
      items.indices.contains(index), old != index
    else { return false }
    // Disabled rows stay in place: moves cannot cross them.
    guard !items[min(old, index)...max(old, index)].contains(where: disabled.contains) else {
      return false
    }
    items.remove(at: old)
    items.insert(id, at: index)
    return true
  }
}
