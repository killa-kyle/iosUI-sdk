import SwiftUI
import UIBehaviorCore

public struct BehaviorTree<ID: Hashable & Sendable>: View {
  @Binding private var model: TreeNavigation<ID>
  private let label: (ID) -> String
  @FocusState private var focus: ID?
  public init(_ model: Binding<TreeNavigation<ID>>, label: @escaping (ID) -> String) {
    _model = model
    self.label = label
  }
  public var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(model.visible, id: \.node.id) { row in
        HStack {
          if !row.node.children.isEmpty {
            Button(
              model.expanded.contains(row.node.id) ? "Collapse" : "Expand",
              systemImage: model.expanded.contains(row.node.id) ? "chevron.down" : "chevron.right"
            ) { model.toggle(row.node.id) }
            .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(
              (model.expanded.contains(row.node.id) ? "Collapse " : "Expand ") + label(row.node.id))
          }
          Button {
            model.select(row.node.id)
          } label: {
            HStack {
              Text(label(row.node.id))
              Spacer()
              if model.selection.selected.contains(row.node.id) { Image(systemName: "checkmark") }
            }.frame(minHeight: 44).contentShape(Rectangle())
          }.focused($focus, equals: row.node.id)
            .accessibilityValue(model.selection.selected.contains(row.node.id) ? "Selected" : "")
        }.padding(.leading, CGFloat(row.depth * 16)).disabled(row.node.disabled)
      }
    }.buttonStyle(.plain)
      .onChange(of: model.focused) { _, id in focus = id }
      .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow]) { press in
        let direction: NavigationDirection =
          press.key == .upArrow
          ? .up
          : press.key == .downArrow
            ? .down
            : press.key == .leftArrow ? .left : .right
        model.move(direction)
        if press.modifiers.contains(.shift), let id = model.focused {
          model.select(id, extending: true)
        }
        return .handled
      }
  }
}

public struct BehaviorGrid: View {
  @Binding private var model: GridNavigation
  private let label: (GridCell) -> String
  @FocusState private var focus: GridCell?
  @Environment(\.layoutDirection) private var layoutDirection
  public init(_ model: Binding<GridNavigation>, label: @escaping (GridCell) -> String) {
    _model = model
    self.label = label
  }
  public var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: max(1, model.columns))) {
      ForEach(0..<model.rows, id: \.self) { row in
        ForEach(0..<model.columns, id: \.self) { column in
          let cell = GridCell(row, column)
          Button {
            model.focus(cell)
          } label: {
            Text(label(cell)).frame(maxWidth: .infinity, minHeight: 44)
              .background(
                model.selected.contains(cell) ? Color.accentColor.opacity(0.2) : .clear,
                in: RoundedRectangle(cornerRadius: 6))
          }.disabled(model.disabled.contains(cell)).focused($focus, equals: cell)
            .accessibilityValue(model.selected.contains(cell) ? "Selected" : "")
        }
      }
    }.buttonStyle(.plain).onChange(of: model.focused) { _, value in focus = value }
      .onKeyPress(keys: [.upArrow, .downArrow, .leftArrow, .rightArrow]) { press in
        let direction: NavigationDirection =
          press.key == .upArrow
          ? .up
          : press.key == .downArrow
            ? .down
            : press.key == .leftArrow ? .left : .right
        model.move(
          direction, extending: press.modifiers.contains(.shift),
          rightToLeft: layoutDirection == .rightToLeft)
        return .handled
      }
  }
}
