public struct BehaviorMenuItem: Identifiable, Sendable, Equatable {
  public enum Kind: Sendable, Equatable {
    case action, toggle
    case radio(group: String)
    case submenu
  }
  public let id: String
  public var title: String
  public var enabled: Bool
  public var kind: Kind
  public var children: [Self]
  public init(
    _ id: String, title: String, enabled: Bool = true, kind: Kind = .action,
    children: [Self] = []
  ) {
    self.id = id
    self.title = title
    self.enabled = enabled
    self.kind = kind
    self.children = children
  }
}
public struct MenuBehavior: Sendable {
  public let items: [BehaviorMenuItem]
  public private(set) var path: [String] = []
  public private(set) var checked: Set<String>
  public private(set) var radio: [String: String] = [:]
  public private(set) var focused: String?
  public init(_ items: [BehaviorMenuItem], checked: Set<String> = []) {
    func ids(_ items: [BehaviorMenuItem]) -> [String] {
      items.flatMap { [$0.id] + ids($0.children) }
    }
    let all = ids(items)
    precondition(Set(all).count == all.count, "Menu IDs must be unique")
    self.items = items
    self.checked = checked.intersection(all)
  }
  public var currentItems: [BehaviorMenuItem] {
    path.reduce(items) { items, id in items.first(where: { $0.id == id })?.children ?? [] }
  }
  public func item(_ id: String) -> BehaviorMenuItem? {
    func find(_ entries: [BehaviorMenuItem]) -> BehaviorMenuItem? {
      for entry in entries {
        if entry.id == id { return entry }
        if let child = find(entry.children) { return child }
      }
      return nil
    }
    return find(items)
  }
  /// Activation returns a committed action ID; submenu navigation returns nil.
  @discardableResult public mutating func activate(_ id: String) -> String? {
    // Native menus may invoke descendants directly, but disabled ancestors still block them.
    func admitted(_ entries: [BehaviorMenuItem]) -> Bool {
      entries.contains { entry in entry.enabled && (entry.id == id || admitted(entry.children)) }
    }
    guard admitted(items), let entry = item(id), entry.enabled else { return nil }
    switch entry.kind {
    case .submenu:
      if currentItems.contains(where: { $0.id == id }) {
        path.append(id)
        focused = currentItems.first(where: \.enabled)?.id
      }
      return nil
    case .toggle: if checked.remove(id) == nil { checked.insert(id) }
    case .radio(let group): radio[group] = id
    case .action: break
    }
    path = []
    focused = nil
    return id
  }
  public mutating func closeLevel() { if !path.isEmpty { focused = path.removeLast() } }
  public mutating func close() {
    path = []
    focused = nil
  }
  public mutating func move(_ direction: NavigationDirection) {
    let eligible = currentItems.filter(\.enabled)
    guard !eligible.isEmpty else { return }
    if direction == .left {
      closeLevel()
      return
    }
    if direction == .right, let focused {
      if item(focused)?.kind == .submenu { _ = activate(focused) }
      return
    }
    let index = eligible.firstIndex { $0.id == focused }
    switch direction {
    case .first: focused = eligible.first?.id
    case .last: focused = eligible.last?.id
    case .up: focused = eligible[((index ?? 0) + eligible.count - 1) % eligible.count].id
    default: focused = eligible[((index ?? -1) + 1) % eligible.count].id
    }
  }
}
