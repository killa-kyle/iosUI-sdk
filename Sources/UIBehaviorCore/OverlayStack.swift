public struct BehaviorOverlay: Identifiable, Sendable, Equatable {
  public let id: String
  public let parent: String?
  public let restoreFocus: String?
  public let dismissible: Bool
  public init(
    _ id: String, parent: String? = nil, restoreFocus: String? = nil, dismissible: Bool = true
  ) {
    self.id = id
    self.parent = parent
    self.restoreFocus = restoreFocus
    self.dismissible = dismissible
  }
}
public struct OverlayStack: Sendable, Equatable {
  public private(set) var entries: [BehaviorOverlay] = []
  public private(set) var focusToRestore: String?
  public init() {}
  @discardableResult public mutating func present(_ overlay: BehaviorOverlay) -> Bool {
    guard !entries.contains(where: { $0.id == overlay.id }), !overlay.id.isEmpty,
      overlay.parent == entries.last?.id
    else { return false }
    entries.append(overlay)
    focusToRestore = nil
    return true
  }
  /// Programmatic dismissal removes a parent and every descendant, even if noninteractive.
  public mutating func dismiss(_ id: String) {
    guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
    focusToRestore = entries[index].restoreFocus
    entries.removeSubrange(index...)
  }
  @discardableResult public mutating func dismissTop() -> Bool {
    guard let top = entries.last, top.dismissible else { return false }
    dismiss(top.id)
    return true
  }
}
