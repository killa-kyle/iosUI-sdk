import UIBehaviorCore
import UIBehaviorUIKit
import UIKit
import XCTest

final class UIKitAdapterTests: XCTestCase {
  @MainActor
  func testChoiceControllerDisabledAndExternalState() {
    let controller = BehaviorChoiceController(
      ["a", "b", "c"],
      selection: Selection<String>(mode: .multiple), label: { $0 })
    controller.loadViewIfNeeded()
    controller.disabled = ["b"]
    var changes = 0
    controller.onSelectionChange = { _ in changes += 1 }
    controller.tableView(controller.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
    controller.tableView(controller.tableView, didSelectRowAt: IndexPath(row: 1, section: 0))
    XCTAssertEqual(controller.selection.selected, ["a"])
    XCTAssertEqual(changes, 1)
    let cell = controller.tableView(
      controller.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
    XCTAssertEqual(cell.accessoryType, .checkmark)
    XCTAssertTrue(cell.accessibilityTraits.contains(.selected))
    controller.update(ids: ["c"], selection: controller.selection)
    XCTAssertTrue(controller.selection.selected.isEmpty)
  }

  @MainActor
  func testSliderBindingSnapsAndDoesNotEmitExternalSet() {
    let slider = UISlider()
    let binding = BehaviorValueBinding(BoundedValue(40, in: 0...100, step: 10), slider: slider)
    var changes = 0
    binding.onChange = { _ in changes += 1 }
    slider.value = 57
    slider.sendActions(for: .valueChanged)
    XCTAssertEqual(binding.state.value, 60)
    // UISlider normalizes through Float; its readback may differ by one ULP.
    XCTAssertEqual(slider.value, 60, accuracy: Float(60).ulp * 2)
    XCTAssertEqual(changes, 1)
    binding.set(20)
    XCTAssertEqual(slider.value, 20, accuracy: Float(20).ulp * 2)
    XCTAssertEqual(changes, 1)
  }
}
