public enum DismissReason: Sendable, Equatable { case escape, outsidePress, action, programmatic }

/// The native adapter owns presentation, focus restoration and modal accessibility.
public struct Disclosure: Sendable, Equatable {
    public private(set) var isOpen: Bool
    public var isDisabled: Bool
    public var dismissOnEscape: Bool
    public var dismissOnOutsidePress: Bool
    public private(set) var lastDismissReason: DismissReason?

    public init(isOpen: Bool = false, isDisabled: Bool = false,
                dismissOnEscape: Bool = true, dismissOnOutsidePress: Bool = true) {
        self.isOpen = isOpen
        self.isDisabled = isDisabled
        self.dismissOnEscape = dismissOnEscape
        self.dismissOnOutsidePress = dismissOnOutsidePress
    }
    public mutating func open() {
        guard !isDisabled else { return }
        isOpen = true; lastDismissReason = nil
    }
    public mutating func dismiss(_ reason: DismissReason = .programmatic) {
        guard isOpen else { return }
        if reason == .escape && !dismissOnEscape { return }
        if reason == .outsidePress && !dismissOnOutsidePress { return }
        isOpen = false; lastDismissReason = reason
    }
    public mutating func toggle() { if isOpen { dismiss(.action) } else { open() } }
}
