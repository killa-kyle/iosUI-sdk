import SwiftUI
import UIBehaviorCore

public struct BehaviorCarousel<Content: View>: View {
  @Binding private var model: CarouselBehavior
  private let content: (Int) -> Content
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.layoutDirection) private var direction
  @State private var extent: CGFloat = 1
  public init(_ model: Binding<CarouselBehavior>, @ViewBuilder content: @escaping (Int) -> Content)
  {
    _model = model
    self.content = content
  }
  public var body: some View {
    VStack {
      if model.count > 0 {
        content(model.index).id(model.index)
          .frame(maxWidth: .infinity, minHeight: 100)
          .contentShape(Rectangle())
          .background {
            GeometryReader { geometry in
              Color.clear.onAppear { extent = geometry.size.width }
                .onChange(of: geometry.size.width) { _, value in extent = value }
            }.allowsHitTesting(false)
          }
          .simultaneousGesture(
            DragGesture().onEnded { value in
              model.swipe(
                translation: value.translation.width, extent: extent,
                rightToLeft: direction == .rightToLeft)
            })
      }
      HStack {
        Button("Previous slide") {
          model.pause()
          model.previous()
        }.disabled(!model.canGoPrevious)
        Spacer()
        Text(model.count == 0 ? "No slides" : "\(model.index+1) of \(model.count)")
          .accessibilityIdentifier("carousel-position")
        Spacer()
        Button("Next slide") {
          model.pause()
          model.next()
        }.disabled(!model.canGoNext)
      }.frame(minHeight: 44)
    }.animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.index)
      .accessibilityAdjustableAction { change in
        model.pause()
        if change == .increment { model.next() } else { model.previous() }
      }
      .onKeyPress(.leftArrow) {
        model.previous()
        return .handled
      }
      .onKeyPress(.rightArrow) {
        model.next()
        return .handled
      }
  }
}

public struct BehaviorMenu: View {
  private let title: String
  @Binding private var model: MenuBehavior
  private let onAction: (String) -> Void
  public init(_ title: String, model: Binding<MenuBehavior>, onAction: @escaping (String) -> Void) {
    self.title = title
    _model = model
    self.onAction = onAction
  }
  public var body: some View { Menu(title) { entries(model.items) } }
  @ViewBuilder private func entries(_ items: [BehaviorMenuItem]) -> some View {
    ForEach(items) { item in
      if item.kind == .submenu {
        Menu(item.title) { AnyView(entries(item.children)) }.disabled(!item.enabled)
      } else {
        Button {
          if let id = model.activate(item.id) { onAction(id) }
        } label: {
          if isChecked(item) {
            Label(item.title, systemImage: "checkmark")
          } else {
            Text(item.title)
          }
        }.disabled(!item.enabled)
      }
    }
  }
  private func isChecked(_ item: BehaviorMenuItem) -> Bool {
    if case .radio(let group) = item.kind { return model.radio[group] == item.id }
    return model.checked.contains(item.id)
  }
}

/// Each nested entry is presented by its parent using the platform sheet stack.
public struct BehaviorOverlayHost<Content: View, Overlay: View>: View {
  @Binding private var stack: OverlayStack
  private let content: Content
  private let overlay: (BehaviorOverlay) -> Overlay
  private let restoreFocus: (String) -> Void
  public init(
    _ stack: Binding<OverlayStack>, @ViewBuilder content: () -> Content,
    @ViewBuilder overlay: @escaping (BehaviorOverlay) -> Overlay,
    restoreFocus: @escaping (String) -> Void = { _ in }
  ) {
    _stack = stack
    self.content = content()
    self.overlay = overlay
    self.restoreFocus = restoreFocus
  }
  public var body: some View {
    content.modifier(OverlayLevel(stack: $stack, level: 0, overlay: overlay))
      .onChange(of: stack.focusToRestore) { _, id in if let id { restoreFocus(id) } }
  }
}
private struct OverlayLevel<Overlay: View>: ViewModifier {
  @Binding var stack: OverlayStack
  let level: Int
  let overlay: (BehaviorOverlay) -> Overlay
  private var entry: BehaviorOverlay? {
    stack.entries.indices.contains(level) ? stack.entries[level] : nil
  }
  func body(content: Content) -> some View {
    content.sheet(
      item: Binding(
        get: { entry },
        set: { new in
          if new == nil, let entry { stack.dismiss(entry.id) }
        })
    ) { item in
      AnyView(
        overlay(item).interactiveDismissDisabled(!item.dismissible)
          .modifier(OverlayLevel(stack: $stack, level: level + 1, overlay: overlay)))
    }
  }
}
