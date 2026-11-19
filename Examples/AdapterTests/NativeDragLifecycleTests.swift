import SwiftUI
import UIBehaviorCore
@testable import UIBehaviorSwiftUI
import UIKit
import XCTest

@MainActor final class NativeDragLifecycleTests: XCTestCase {
  func testPreparationDoesNotAdmitAndConfirmedSessionCanCancel() {
    var state = DragDropBehavior()
    let binding = Binding(get: { state }, set: { state = $0 })
    let controller = NativeDragController(content: Text("Card"),
      payload: DragPayload(id: "card", type: "note"), session: binding)
    let interaction = UIDragInteraction(delegate: controller)
    let abandoned = DragSessionStub()
    XCTAssertEqual(controller.dragInteraction(interaction, itemsForBeginning: abandoned).count, 1)
    XCTAssertNil(state.payload, "A cancelled lift must not publish a behavior session")
    let confirmed = DragSessionStub()
    XCTAssertEqual(controller.dragInteraction(interaction, itemsForBeginning: confirmed).count, 1)
    controller.dragInteraction(interaction, sessionWillBegin: confirmed)
    XCTAssertEqual(state.payload?.id, "card")
    controller.dragInteraction(interaction, session: abandoned, didEndWith: .cancel)
    XCTAssertEqual(state.payload?.id, "card", "An old lift must not clear the current session")
    controller.dragInteraction(interaction, session: confirmed, didEndWith: .cancel)
    XCTAssertNil(state.payload)
    XCTAssertEqual(controller.dragInteraction(interaction, itemsForBeginning: abandoned).count, 1)
    controller.dragInteraction(interaction, sessionWillBegin: abandoned)
    XCTAssertEqual(state.payload?.id, "card", "A fresh drag must work after cancellation")
    controller.cancelSession()
    XCTAssertNil(state.payload)
  }
}

@MainActor private final class DragSessionStub: NSObject, UIDragSession {
  var localContext: Any?
  var items: [UIDragItem] { [] }
  var allowsMoveOperation: Bool { true }
  var isRestrictedToDraggingApplication: Bool { true }
  func location(in view: UIView) -> CGPoint { CGPoint(x: 12, y: 24) }
  func hasItemsConforming(toTypeIdentifiers typeIdentifiers: [String]) -> Bool { false }
  func canLoadObjects(ofClass aClass: any NSItemProviderReading.Type) -> Bool { false }
}
