#if os(iOS)
import SwiftUI
import UIKit
import UIBehaviorCore

/// Admission follows the native session, not provider-factory evaluation.
/// A lift may be abandoned before sessionWillBegin; preparing its provider must
/// not publish state or invalidate the hosted preview during the lift.
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
  private var preparedSession: ObjectIdentifier?
  private var preparedPayload: DragPayload?
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
    guard session.wrappedValue.payload == nil, !payload.id.isEmpty else { return [] }
    preparedSession = ObjectIdentifier(drag)
    preparedPayload = payload
    return [UIDragItem(itemProvider: NSItemProvider(object: payload.id as NSString))]
  }
  func dragInteraction(_ interaction: UIDragInteraction, sessionWillBegin drag: UIDragSession) {
    guard preparedSession == ObjectIdentifier(drag), let preparedPayload else { return }
    let point = drag.location(in: view)
    if session.wrappedValue.begin(preparedPayload, at: BehaviorPoint(point.x, point.y)) {
      admittedID = preparedPayload.id
    }
  }
  func dragInteraction(
    _ interaction: UIDragInteraction, session: UIDragSession, didEndWith operation: UIDropOperation
  ) {
    if preparedSession == ObjectIdentifier(session), operation == .cancel || operation == .forbidden {
      finish()
    }
  }
  func dragInteraction(_ interaction: UIDragInteraction, sessionDidTransferItems session: UIDragSession) {
    if preparedSession == ObjectIdentifier(session) { finish() }
  }
  func dragInteraction(
    _ interaction: UIDragInteraction, sessionIsRestrictedToDraggingApplication session: UIDragSession
  ) -> Bool { true }
  private func finish() {
    if self.session.wrappedValue.payload?.id == admittedID { self.session.wrappedValue.cancel() }
    admittedID = nil
    preparedSession = nil
    preparedPayload = nil
  }
  func cancelSession() { finish() }
}
#endif
