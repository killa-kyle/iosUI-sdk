import SwiftUI
import UIBehaviorCore

public struct BehaviorField: View {
    private let title: String
    private let validate: (String) -> [String]
    @Binding private var text: String
    @Binding private var validation: FieldValidation
    @FocusState private var focused: Bool

    public init(_ title: String, text: Binding<String>, validation: Binding<FieldValidation>,
                validate: @escaping (String) -> [String]) {
        self.title = title; _text = text; _validation = validation; self.validate = validate
    }
    public var body: some View {
        VStack(alignment: .leading) {
            TextField(title, text: $text)
                .focused($focused)
                .accessibilityHint(validation.visibleErrors.joined(separator: ". "))
                .onChange(of: focused) { _, active in if !active { validation.blur() } }
                .onChange(of: text, initial: true) { _, value in validation.validate(validate(value)) }
                .onSubmit { validation.submit() }
            ForEach(Array(validation.visibleErrors.enumerated()), id: \.offset) { _, error in
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
    }
}
