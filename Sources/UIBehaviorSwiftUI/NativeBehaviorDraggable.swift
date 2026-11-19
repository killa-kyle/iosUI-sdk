#if os(iOS)
import SwiftUI
import UIKit
import UIBehaviorCore

/// Admission follows the native session, not provider-factory evaluation.
/// SwiftUI may evaluate an onDrag provider again after a completed drop.
struct NativeBehaviorDraggable<Content: View>: UIViewControllerRepresentable {
  let content: Content
  let payload: DragPayload
  let session: Binding<DragDropBehavior>
  func makeUIViewController(context: Context) -> NativeDragController<Content> {
    NativeDragController(content: content, payload: payload, session: session)
  }
  func updateUIViewController(_ controller: NativeDragController<Content>, context: Context) {
    controller.host.rootView = content
    controller.payload = payload
    controller.session = session
  }
  static func dismantleUIViewController(_ controller: NativeDragController<Content>, coordinator: ()) {
    controller.cancelSession()
  }
  func sizeThatFits(
    _ proposal: ProposedViewSize, uiViewController: NativeDragController<Content>, context: Context
  ) -> CGSize? {
    uiViewController.host.sizeThatFits(in: CGSize(
      width: proposal.width ?? 10_000, height: proposal.height ?? 10_000))
  }
}

final class NativeDragController<Content: View>: UIViewController, UIDragInteractionDelegate {
  let host: UIHostingController<Content>
  var payload: DragPayload
  var session: Binding<DragDropBehavior>
  private var admittedID: String?
  init(content: Content, payload: DragPayload, session: Binding<DragDropBehavior>) {
    host = UIHostingController(rootView: content)
    self.payload = payload
    self.session = session
    super.init(nibName: nil, bundle: nil)
  }
  @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    addChild(host)
    host.view.backgroundColor = .clear
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    let interaction = UIDragInteraction(delegate: self)
    interaction.isEnabled = true
    view.addInteraction(interaction)
  }
  func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning drag: UIDragSession)
    -> [UIDragItem]
  {
    let point = drag.location(in: view)
    guard session.wrappedValue.begin(payload, at: BehaviorPoint(point.x, point.y)) else { return [] }
    admittedID = payload.id
    return [UIDragItem(itemProvider: NSItemProvider(object: payload.id as NSString))]
  }
  func dragInteraction(
    _ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation
  ) {
    if operation == .cancel || operation == .forbidden { finish() }
  }
  func dragInteraction(_ interaction: UIDragInteraction, sessionDidTransferItems session: UIDragSession) {
    finish()
  }
  func dragInteraction(
    _ interaction: UIDragInteraction, sessionIsRestrictedToDraggingApplication session: UIDragSession
  ) -> Bool { true }
  private func finish() {
    if self.session.wrappedValue.payload?.id == admittedID { self.session.wrappedValue.cancel() }
    admittedID = nil
  }
  func cancelSession() { finish() }
}
#endif
