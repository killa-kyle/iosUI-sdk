public struct FieldValidation: Sendable, Equatable {
    public private(set) var isTouched = false
    public private(set) var isSubmitted = false
    public private(set) var errors: [String] = []
    public init() {}
    public var visibleErrors: [String] { isTouched || isSubmitted ? errors : [] }
    public var isValid: Bool { errors.isEmpty }
    public mutating func validate(_ errors: [String]) { self.errors = errors }
    public mutating func blur() { isTouched = true }
    public mutating func submit() { isSubmitted = true }
    public mutating func reset() { self = Self() }
}
