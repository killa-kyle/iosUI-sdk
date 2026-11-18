import XCTest

@MainActor final class ExtendedCatalogTests: XCTestCase {
  private func launch(_ story: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--story", story, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
  }
  private func expect(_ element: XCUIElement, label: String) {
    let predicate = NSPredicate(format: "label == %@", label)
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
  }
  func testCalendarTreeAndGridUseRealAdapters() {
    var app = launch("calendar")
    XCTAssertTrue(app.buttons["calendar-2026-11-05"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["calendar-2026-11-03"].isEnabled)
    app.buttons["calendar-2026-11-05"].tap()
    app.buttons["calendar-2026-11-07"].tap()
    expect(app.staticTexts["calendar-result"], label: "2026-11-05…2026-11-07")
    app = launch("tree")
    app.buttons["Expand Library"].tap()
    app.buttons["Photos"].tap()
    expect(app.staticTexts["tree-result"], label: "Selected: Photos")
    app = launch("grid")
    app.buttons["R1 C1"].tap()
    app.buttons["Extend to R3 C4"].tap()
    expect(app.staticTexts["grid-result"], label: "Selected cells: 11")
  }
  func testColorHexBindingAndUIKitCalendarHosting() {
    var app = launch("color")
    let field = app.textFields["Hex color"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 7) + "#000000")
    app.buttons["Apply hex"].tap()
    expect(app.staticTexts["color-result"], label: "#000000FF")
    app = launch("calendar")
    let link = app.buttons["UIKit calendar controller"]
    if !link.isHittable { app.swipeUp() }
    XCTAssertTrue(link.waitForExistence(timeout: 5))
    link.tap()
    let date = app.buttons["calendar-2026-11-05"]
    XCTAssertTrue(date.waitForExistence(timeout: 5))
    date.tap()
    XCTAssertEqual(date.value as? String, "Selected")
  }
  func testDragResizeAndActualImageExport() {
    var app = launch("drag")
    let card = app.descendants(matching: .any).matching(identifier: "drag-card").firstMatch
    let zone = app.descendants(matching: .any).matching(identifier: "drop-archive").firstMatch
    XCTAssertTrue(card.waitForExistence(timeout: 5))
    XCTAssertTrue(card.isHittable && zone.isHittable)
    card.press(forDuration: 1, thenDragTo: zone)
    expect(app.staticTexts["drop-result"], label: "Moved card to archive")
    app = launch("resize")
    let handle = app.descendants(matching: .any).matching(
      NSPredicate(format: "label == %@", "Resize bottom right")
    ).firstMatch
    XCTAssertTrue(handle.waitForExistence(timeout: 5))
    let point = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    point.press(forDuration: 0.1, thenDragTo: point.withOffset(CGVector(dx: 30, dy: 20)))
    XCTAssertNotEqual(app.staticTexts["resize-result"].label, "120 × 100")
    app = launch("crop")
    app.buttons["Rotate crop"].tap()
    app.buttons["Export crop"].tap()
    expect(app.staticTexts["crop-result"], label: "Exported 200 × 200")
  }
  func testCarouselMenuAndNestedPresentation() {
    var app = launch("carousel")
    app.buttons["Next slide"].tap()
    expect(app.staticTexts["carousel-position"], label: "2 of 3")
    app = launch("menu")
    app.buttons["Open menu"].tap()
    XCTAssertTrue(app.buttons["Favorite"].waitForExistence(timeout: 5))
    app.buttons["Favorite"].tap()
    expect(app.staticTexts["menu-result"], label: "Action: favorite")
    app = launch("overlays")
    app.buttons["Open inspector"].tap()
    XCTAssertTrue(app.buttons["Open nested overlay"].waitForExistence(timeout: 5))
    app.buttons["Open nested overlay"].tap()
    XCTAssertTrue(app.buttons["Close confirmation"].waitForExistence(timeout: 5))
    app.buttons["Close confirmation"].tap()
    XCTAssertTrue(app.buttons["Close inspector"].waitForExistence(timeout: 5))
    app.buttons["Close inspector"].tap()
    expect(app.staticTexts["overlay-result"], label: "Overlay count: 0")
  }
  func testEditorMeasurementAndRegisteredAgentAction() {
    var app = launch("editor")
    let editor = app.textViews["Rich text"]
    XCTAssertTrue(editor.waitForExistence(timeout: 5))
    editor.tap()
    editor.typeText("!")
    app.buttons["Bold first word"].tap()
    expect(app.staticTexts["editor-format"], label: "Bold runs: 1")
    XCTAssertTrue(app.staticTexts["editor-result"].label.contains("!"))
    app = launch("measurements")
    let measured = app.staticTexts["measurement-result"]
    XCTAssertTrue(measured.waitForExistence(timeout: 5))
    XCTAssertFalse(measured.label.hasPrefix("0 × 0"))
    app = launch("agent")
    app.buttons["Agent next"].tap()
    expect(app.staticTexts["agent-result"], label: "Agent moved to slide 2")
    expect(app.staticTexts["carousel-position"], label: "2 of 3")
  }
}
