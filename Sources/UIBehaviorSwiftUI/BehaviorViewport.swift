import SwiftUI
import UIBehaviorCore

/// Simultaneous native pan and magnification with caller-owned transform state.
/// Expose zoom controls as well when using this for essential content.
public struct BehaviorViewport<Content: View>: View {
  @Binding private var state: UIBehaviorCore.Viewport
  private let content: () -> Content
  @State private var previousTranslation: CGSize = .zero
  @State private var initialScale: Double?

  public init(
    _ state: Binding<UIBehaviorCore.Viewport>, @ViewBuilder content: @escaping () -> Content
  ) {
    _state = state
    self.content = content
  }
  public var body: some View {
    GeometryReader { geometry in
      content()
        .scaleEffect(state.scale, anchor: .topLeading)
        .offset(x: state.x, y: state.y)
        .gesture(
          DragGesture().onChanged { event in
            state.pan(
              dx: event.translation.width - previousTranslation.width,
              dy: event.translation.height - previousTranslation.height)
            previousTranslation = event.translation
          }.onEnded { _ in previousTranslation = .zero }
        )
        .simultaneousGesture(
          MagnifyGesture().onChanged { event in
            if initialScale == nil { initialScale = state.scale }
            state.zoom(
              to: initialScale! * event.magnification,
              anchorX: event.startAnchor.x * geometry.size.width,
              anchorY: event.startAnchor.y * geometry.size.height)
          }.onEnded { _ in initialScale = nil })
    }
    .clipped()
    .accessibilityAction(named: Text("Zoom in")) {
      state.zoom(to: state.scale * 1.25, anchorX: 0, anchorY: 0)
    }
    .accessibilityAction(named: Text("Zoom out")) {
      state.zoom(to: state.scale / 1.25, anchorX: 0, anchorY: 0)
    }
  }
}
