import SwiftUI
import UIBehaviorCore

/// Composes selection, roving keyboard focus and typeahead with caller-owned state.
/// Rows use native buttons; appearance comes entirely from `row` and button styles.
public struct BehaviorChoiceList<ID: Hashable & Sendable, Row: View>: View {
  private let layout: AnyLayout
  private let ids: [ID]
  private let disabled: Set<ID>
  private let label: (ID) -> String
  private let row: (ID, Bool) -> Row
  @Binding private var selection: Selection<ID>
  @FocusState private var focused: ID?
  @State private var navigation = FocusNavigation<ID>()
  @State private var typeahead = Typeahead()

  public init(
    _ ids: [ID], selection: Binding<Selection<ID>>, disabled: Set<ID> = [],
    layout: AnyLayout = AnyLayout(VStackLayout(alignment: .leading, spacing: 0)),
    label: @escaping (ID) -> String,
    @ViewBuilder row: @escaping (ID, Bool) -> Row
  ) {
    precondition(Set(ids).count == ids.count, "Choice IDs must be unique")
    self.layout = layout
    self.ids = ids
    self._selection = selection
    self.disabled = disabled
    self.label = label
    self.row = row
  }

  public var body: some View {
    layout {
      ForEach(ids, id: \.self) { id in
        Button {
          if selection.mode == .multiple {
            selection.toggle(id, disabled: disabled)
          } else {
            selection.choose(id, disabled: disabled)
          }
        } label: {
          row(id, selection.selected.contains(id))
            .contentShape(Rectangle())
        }
        // Form/List automatic styling can dispatch a row tap to sibling buttons.
        // Keep each choice independent, including when embedded inside a form.
        .buttonStyle(.plain)
        .disabled(disabled.contains(id))
        .focused($focused, equals: id)
        .accessibilityLabel(label(id))
        .accessibilityAddTraits(selection.selected.contains(id) ? .isSelected : [])
      }
    }
    .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow, .home, .end]) { press in
      navigation.focus(focused, order: ids, disabled: disabled)
      let movement: FocusNavigation<ID>.Movement
      switch press.key {
      case .upArrow, .leftArrow: movement = .previous
      case .home: movement = .first
      case .end: movement = .last
      default: movement = .next
      }
      focused = navigation.move(movement, order: ids, disabled: disabled)
      return .handled
    }
    .onKeyPress(characters: .alphanumerics) { press in
      guard press.modifiers.intersection([.command, .control, .option]).isEmpty else {
        return .ignored
      }
      let eligible = ids.filter { !disabled.contains($0) }
      let current = focused.flatMap { eligible.firstIndex(of: $0) }
      if let index = typeahead.search(
        press.characters, labels: eligible.map(label),
        current: current, at: ProcessInfo.processInfo.systemUptime)
      {
        focused = eligible[index]
      }
      return .handled
    }
    .onChange(of: ids) { _, order in
      selection.reconcile(order: order)
      if let focused, !order.contains(focused) { self.focused = nil }
    }
  }
}
