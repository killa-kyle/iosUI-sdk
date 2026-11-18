import SwiftUI
import UIBehaviorCore

public struct BehaviorStepper<Label: View>: View {
  @Binding private var value: BoundedValue
  private let label: () -> Label
  public init(_ value: Binding<BoundedValue>, @ViewBuilder label: @escaping () -> Label) {
    _value = value
    self.label = label
  }
  public var body: some View {
    Stepper(onIncrement: { value.increment() }, onDecrement: { value.decrement() }, label: label)
      .accessibilityValue(value.value.formatted())
  }
}

public struct BehaviorSlider<Label: View>: View {
  @Binding private var value: BoundedValue
  private let label: () -> Label
  public init(_ value: Binding<BoundedValue>, @ViewBuilder label: @escaping () -> Label) {
    _value = value
    self.label = label
  }
  public var body: some View {
    Slider(
      value: Binding(get: { value.value }, set: { value.set($0) }),
      in: value.bounds, step: value.step, label: label)
  }
}

/// An accessible reorder action usable on any custom row, with no drag requirement.
extension View {
  public func behaviorReorderActions<ID: Hashable>(
    id: ID, order: Binding<[ID]>,
    disabled: Set<ID> = []
  ) -> some View {
    accessibilityAction(named: Text("Move up")) {
      guard let index = order.wrappedValue.firstIndex(of: id) else { return }
      Reorder.move(id, to: index - 1, in: &order.wrappedValue, disabled: disabled)
    }
    .accessibilityAction(named: Text("Move down")) {
      guard let index = order.wrappedValue.firstIndex(of: id) else { return }
      Reorder.move(id, to: index + 1, in: &order.wrappedValue, disabled: disabled)
    }
  }
}
