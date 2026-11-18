import SwiftUI
import UIBehaviorCore

public struct BehaviorDisclosure<Label: View, Content: View>: View {
    @Binding private var state: Disclosure
    private let label: () -> Label
    private let content: () -> Content

    public init(_ state: Binding<Disclosure>, @ViewBuilder label: @escaping () -> Label,
                @ViewBuilder content: @escaping () -> Content) {
        _state = state; self.label = label; self.content = content
    }
    public var body: some View {
        DisclosureGroup(isExpanded: Binding(get: { state.isOpen }, set: { value in
            if value { state.open() } else { state.dismiss(.action) }
        }), content: content, label: label)
        .disabled(state.isDisabled)
    }
}

extension View {
    /// Native sheet presentation owns modal accessibility and focus restoration.
    public func behaviorSheet<Content: View>(_ state: Binding<Disclosure>,
                                             @ViewBuilder content: @escaping () -> Content) -> some View {
        sheet(isPresented: Binding(get: { state.wrappedValue.isOpen }, set: { value in
            if value { state.wrappedValue.open() }
            else { state.wrappedValue.dismiss(.outsidePress) }
        })) {
            content()
                .interactiveDismissDisabled(!state.wrappedValue.dismissOnOutsidePress)
                .onKeyPress(.escape) { state.wrappedValue.dismiss(.escape); return .handled }
        }
    }
}
