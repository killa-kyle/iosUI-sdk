import SwiftUI
import UIBehaviorCore

public struct BehaviorResizable<Content: View>: View {
  @Binding private var model: ResizeBehavior
  private let content: Content
  @State private var active: ResizeHandle?
  @GestureState private var dragging = false
  public init(_ model: Binding<ResizeBehavior>, @ViewBuilder content: () -> Content) {
    _model = model
    self.content = content()
  }
  public var body: some View {
    ZStack(alignment: .topLeading) {
      content.frame(width: model.rect.width, height: model.rect.height)
        .overlay(Rectangle().stroke(Color.accentColor, lineWidth: 2))
        .position(x: model.rect.x + model.rect.width / 2, y: model.rect.y + model.rect.height / 2)
      ForEach(ResizeHandle.allCases, id: \.self) { handle in
        handleView(handle)
      }
    }.frame(width: model.bounds.width, height: model.bounds.height)
      .onChange(of: dragging) { _, value in
        if !value, active != nil {
          model.cancel()
          active = nil
        }
      }
      .onKeyPress(.escape) {
        model.cancel()
        active = nil
        return .handled
      }
  }
  private func point(_ handle: ResizeHandle) -> CGPoint {
    let west = [.w, .nw, .sw].contains(handle)
    let east = [.e, .ne, .se].contains(handle)
    let north = [.n, .nw, .ne].contains(handle)
    let south = [.s, .sw, .se].contains(handle)
    return CGPoint(
      x: west ? model.rect.x : east ? model.rect.maxX : model.rect.x + model.rect.width / 2,
      y: north ? model.rect.y : south ? model.rect.maxY : model.rect.y + model.rect.height / 2)
  }
  private func adjust(_ handle: ResizeHandle, dx: Double, dy: Double) {
    model.begin(handle)
    model.update(dx: dx, dy: dy)
    model.commit()
  }
  private func handleView(_ handle: ResizeHandle) -> some View {
    let names: [ResizeHandle: String] = [
      .n: "top", .s: "bottom", .w: "left", .e: "right", .nw: "top left",
      .ne: "top right", .sw: "bottom left", .se: "bottom right", .move: "move",
    ]
    return Circle().fill(Color.accentColor).frame(width: 12, height: 12)
      .frame(width: 44, height: 44).contentShape(Rectangle()).position(point(handle))
      .gesture(
        DragGesture(minimumDistance: 0).updating($dragging) { _, state, _ in state = true }
          .onChanged { value in
            if active != handle {
              active = handle
              model.begin(handle)
            }
            model.update(dx: value.translation.width, dy: value.translation.height)
          }.onEnded { _ in
            model.commit()
            active = nil
          }
      )
      .accessibilityElement().accessibilityLabel("Resize " + (names[handle] ?? handle.rawValue))
      .accessibilityValue("\(Int(model.rect.width)) by \(Int(model.rect.height))")
      .accessibilityAdjustableAction { direction in
        let amount = direction == .increment ? 10.0 : -10.0
        adjust(handle, dx: amount, dy: amount)
      }.focusable()
      .onKeyPress(.leftArrow) {
        adjust(handle, dx: -1, dy: 0)
        return .handled
      }
      .onKeyPress(.rightArrow) {
        adjust(handle, dx: 1, dy: 0)
        return .handled
      }
      .onKeyPress(.upArrow) {
        adjust(handle, dx: 0, dy: -1)
        return .handled
      }
      .onKeyPress(.downArrow) {
        adjust(handle, dx: 0, dy: 1)
        return .handled
      }
  }
}

public struct BehaviorCropper: View {
  @Binding private var selection: CropSelection
  private let image: Image
  public init(_ selection: Binding<CropSelection>, image: Image) {
    _selection = selection
    self.image = image
  }
  public var body: some View {
    GeometryReader { geometry in
      let bounds = selection.resize.bounds
      let scale = min(geometry.size.width / bounds.width, geometry.size.height / bounds.height)
      ZStack(alignment: .topLeading) {
        image.resizable()
          .frame(
            width: selection.rotation % 180 == 0 ? bounds.width : bounds.height,
            height: selection.rotation % 180 == 0 ? bounds.height : bounds.width
          )
          .rotationEffect(.degrees(Double(selection.rotation)))
          .frame(width: bounds.width, height: bounds.height)
        BehaviorResizable(Binding(get: { selection.resize }, set: { selection.setResize($0) })) {
          Color.clear
        }
      }.scaleEffect(scale, anchor: .topLeading)
    }.accessibilityLabel("Image crop selection")
  }
}

extension View {
  /// Local native drag; the ID is transferred, never an app object or secret payload.
  public func behaviorDraggable(_ payload: DragPayload, session: Binding<DragDropBehavior>)
    -> some View
  {
    onDrag {
      session.wrappedValue.cancel()
      _ = session.wrappedValue.begin(payload, at: BehaviorPoint(0, 0))
      return NSItemProvider(object: payload.id as NSString)
    }
  }
  /// Only accepts a payload already admitted by this local session. Revalidates at drop time.
  public func behaviorDropTarget(
    _ id: String, acceptedTypes: Set<String>,
    session: Binding<DragDropBehavior>, onDrop: @escaping (DropReceipt) -> Void
  ) -> some View {
    modifier(
      BehaviorDropModifier(id: id, acceptedTypes: acceptedTypes, session: session, onDrop: onDrop))
  }
}
private struct BehaviorDropModifier: ViewModifier {
  let id: String
  let acceptedTypes: Set<String>
  @Binding var session: DragDropBehavior
  let onDrop: (DropReceipt) -> Void
  @State private var size: CGSize = .zero
  func body(content: Content) -> some View {
    content.background {
      GeometryReader { geometry in
        Color.clear.onAppear { size = geometry.size }.onChange(of: geometry.size) { _, new in
          size = new
        }
      }.allowsHitTesting(false)
    }.dropDestination(for: String.self) { values, point in
      guard values.count == 1, values.first == session.payload?.id else {
        session.cancel()
        return false
      }
      let target = DropTarget(
        id: id, rect: BehaviorRect(width: size.width, height: size.height),
        acceptedTypes: acceptedTypes)
      session.update(at: BehaviorPoint(point.x, point.y), targets: [target])
      guard let receipt = session.drop(targets: [target]) else { return false }
      onDrop(receipt)
      return true
    }
  }
}
