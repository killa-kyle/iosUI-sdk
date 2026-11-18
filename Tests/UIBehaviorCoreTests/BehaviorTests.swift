import XCTest

@testable import UIBehaviorCore

final class BehaviorTests: XCTestCase {
  func testSingleSelectionReplacesAndTogglesOff() {
    var state = Selection<String>()
    state.choose("a")
    state.choose("b")
    XCTAssertEqual(state.selected, ["b"])
    state.toggle("b")
    XCTAssertTrue(state.selected.isEmpty)
  }
  func testDisabledChoiceDoesNotMoveAnchor() {
    var state = Selection<String>(mode: .multiple)
    state.choose("a")
    state.toggle("b", disabled: ["b"])
    XCTAssertEqual(state.selected, ["a"])
    XCTAssertEqual(state.anchor, "a")
  }
  func testRangeShrinksFromStableAnchor() {
    var state = Selection<String>(mode: .multiple)
    let order = ["a", "b", "c", "d"]
    state.choose("a")
    state.extend(to: "d", order: order, disabled: ["b"])
    XCTAssertEqual(state.selected, ["a", "c", "d"])
    state.extend(to: "c", order: order, disabled: ["b"])
    XCTAssertEqual(state.selected, ["a", "c"])
  }
  func testAdditiveRangePreservesBaseWithoutLeakingPreviousRange() {
    var state = Selection<String>(mode: .multiple)
    state.toggle("d")
    state.toggle("a")
    state.extend(to: "c", order: ["a", "b", "c", "d"], additive: true)
    state.extend(to: "b", order: ["a", "b", "c", "d"], additive: true)
    XCTAssertEqual(state.selected, ["a", "b", "d"])
  }
  func testSelectAllAndReconcile() {
    var state = Selection<String>(mode: .multiple)
    state.toggleAll(order: ["a", "b", "c"], disabled: ["b"])
    XCTAssertEqual(state.selected, ["a", "c"])
    state.toggleAll(order: ["a", "b", "c"], disabled: ["b"])
    XCTAssertTrue(state.selected.isEmpty)
    state.choose("c")
    state.reconcile(order: ["a"])
    XCTAssertNil(state.anchor)
    XCTAssertTrue(state.selected.isEmpty)
  }
  func testFocusSkipsDisabledWrapsAndHandlesEmpty() {
    var state = FocusNavigation<String>()
    XCTAssertEqual(state.move(.next, order: ["a", "b", "c"], disabled: ["b"]), "a")
    XCTAssertEqual(state.move(.next, order: ["a", "b", "c"], disabled: ["b"]), "c")
    XCTAssertEqual(state.move(.next, order: ["a", "b", "c"]), "a")
    XCTAssertEqual(state.move(.previous, order: ["a", "b", "c"]), "c")
    XCTAssertNil(state.move(.next, order: ["a"], disabled: ["a"]))
  }
  func testFocusClampAndRemovedIdentity() {
    var state = FocusNavigation(focused: "a", wraps: false)
    XCTAssertEqual(state.move(.previous, order: ["a", "b"]), "a")
    state.focus("missing", order: ["a", "b"])
    XCTAssertNil(state.focused)
    XCTAssertEqual(state.move(.last, order: ["a", "b"]), "b")
    XCTAssertEqual(state.move(.next, order: ["a", "b"]), "b")
  }
  func testTypeaheadFoldsAccentsAndTimesOut() {
    var state = Typeahead()
    let labels = ["Alpha", "Éclair", "Echo"]
    XCTAssertEqual(state.search("e", labels: labels, at: 1), 1)
    XCTAssertEqual(state.search("c", labels: labels, current: 1, at: 1.1), 1)
    XCTAssertEqual(state.search("a", labels: labels, current: 1, at: 2), 0)
  }
  func testTypeaheadCyclesButAllowsRepeatedLetters() {
    var state = Typeahead()
    XCTAssertEqual(state.search("e", labels: ["Echo", "Elm"], at: 0), 0)
    XCTAssertEqual(state.search("e", labels: ["Echo", "Elm"], current: 0, at: 0.1), 1)
    state.reset()
    XCTAssertEqual(state.search("l", labels: ["Lake", "Llama"], at: 0), 0)
    XCTAssertEqual(state.search("l", labels: ["Lake", "Llama"], current: 0, at: 0.1), 1)
    XCTAssertNil(state.search("z", labels: [], at: 1))
  }
  func testDisclosureDismissPolicyAndDisabledOpening() {
    var state = Disclosure(isDisabled: true)
    state.open()
    XCTAssertFalse(state.isOpen)
    state.isDisabled = false
    state.open()
    state.dismissOnOutsidePress = false
    state.dismiss(.outsidePress)
    XCTAssertTrue(state.isOpen)
    state.dismiss(.escape)
    XCTAssertFalse(state.isOpen)
    XCTAssertEqual(state.lastDismissReason, .escape)
    state.open()
    XCTAssertNil(state.lastDismissReason)
  }
  func testBoundedValueSnapsFromLowerBoundClampsAndRejectsNaN() {
    var state = BoundedValue(0.24, in: 0.1...1.1, step: 0.2)
    XCTAssertEqual(state.value, 0.3, accuracy: 0.00001)
    state.set(100)
    XCTAssertEqual(state.value, 1.1, accuracy: 0.00001)
    state.increment()
    XCTAssertEqual(state.value, 1.1, accuracy: 0.00001)
    state.set(.nan)
    XCTAssertEqual(state.value, 1.1, accuracy: 0.00001)
    state.setFraction(0)
    XCTAssertEqual(state.value, 0.1, accuracy: 0.00001)
    XCTAssertEqual(BoundedValue(1, in: 1...1).fraction, 0)
  }
  func testReorderUsesFinalIndexAndHonorsLockedRows() {
    var ids = ["a", "b", "c", "d"]
    XCTAssertTrue(Reorder.move("a", to: 2, in: &ids))
    XCTAssertEqual(ids, ["b", "c", "a", "d"])
    XCTAssertFalse(Reorder.move("b", to: 3, in: &ids, disabled: ["a"]))
    XCTAssertFalse(Reorder.move("d", to: -1, in: &ids))
    XCTAssertFalse(Reorder.move("missing", to: 0, in: &ids))
  }
  func testValidationRevealsErrorsAfterBlurOrSubmit() {
    var state = FieldValidation()
    state.validate(["Required"])
    XCTAssertFalse(state.isValid)
    XCTAssertTrue(state.visibleErrors.isEmpty)
    state.blur()
    XCTAssertEqual(state.visibleErrors, ["Required"])
    state.validate([])
    XCTAssertTrue(state.isValid)
    state.reset()
    state.validate(["Invalid"])
    state.submit()
    XCTAssertEqual(state.visibleErrors, ["Invalid"])
  }

  /// Repeatable composed scenario: state transitions, not a substitute for UI replay.
  func testComposedPickerReplay() {
    var popup = Disclosure()
    var focus = FocusNavigation<String>()
    var choice = Selection<String>()
    var search = Typeahead()
    let ids = ["SwiftUI", "UIKit", "Both"]
    popup.open()
    let index = search.search("u", labels: ids, at: 0)!
    focus.focus(ids[index], order: ids)
    choice.choose(focus.focused!)
    popup.dismiss(.action)
    XCTAssertEqual(choice.selected, ["UIKit"])
    XCTAssertFalse(popup.isOpen)
    popup.open()
    XCTAssertEqual(choice.selected, ["UIKit"])
  }
}
