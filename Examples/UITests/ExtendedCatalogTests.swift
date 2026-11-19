import XCTest

@MainActor final class ExtendedCatalogTests: XCTestCase {
  private func launch(_ story: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--story", story, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
  }
  private func capture(_ app: XCUIApplication, name: String) {
    let image = XCTAttachment(screenshot: app.screenshot())
    image.name = name
    image.lifetime = .keepAlways
    add(image)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = name + "-accessibility"
    tree.lifetime = .keepAlways
    add(tree)
  }
  private func expect(_ element: XCUIElement, label: String) {
    let predicate = NSPredicate(format: "label == %@", label)
    let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
    XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
  }
  func testCalendarRangeAndDisabledDates() {
    let app = launch("calendar")
    defer { app.terminate() }
    XCTAssertTrue(app.buttons["calendar-2026-11-05"].waitForExistence(timeout: 5))
    XCTAssertFalse(app.buttons["calendar-2026-11-03"].isEnabled)
    app.buttons["calendar-2026-11-05"].tap()
    app.buttons["calendar-2026-11-07"].tap()
    expect(app.staticTexts["calendar-result"], label: "2026-11-05…2026-11-07")
  }
  func testTreeNavigation() {
    let app = launch("tree")
    defer { app.terminate() }
    app.buttons["Expand Library"].tap()
    app.buttons["Photos"].tap()
    expect(app.staticTexts["tree-result"], label: "Selected: Photos")
  }
  func testGridRangeSelection() {
    let app = launch("grid")
    defer { app.terminate() }
    app.buttons["R1 C1"].tap()
    app.buttons["Extend to R3 C4"].tap()
    expect(app.staticTexts["grid-result"], label: "Selected cells: 11")
  }
  func testColorHexBinding() {
    let app = launch("color")
    defer { app.terminate() }
    let field = app.textFields["Hex color"]
    XCTAssertTrue(field.waitForExistence(timeout: 5))
    field.tap()
    field.typeKey("a", modifierFlags: .command)
    field.typeText("#000000")
    XCTAssertEqual(field.value as? String, "#000000")
    app.buttons["Apply hex"].tap()
    expect(app.staticTexts["color-result"], label: "#000000FF")
  }
  func testUIKitCalendarHosting() {
    let app = launch("calendar")
    defer { app.terminate() }
    let link = app.buttons["UIKit calendar controller"]
    if !link.isHittable { app.swipeUp() }
    XCTAssertTrue(link.waitForExistence(timeout: 5))
    link.tap()
    let date = app.buttons["calendar-2026-11-05"]
    XCTAssertTrue(date.waitForExistence(timeout: 5))
    date.tap()
    XCTAssertEqual(date.value as? String, "Selected")
  }
  func testNativeDragDrop() {
    let app = launch("drag")
    defer { app.terminate() }
    let card = app.descendants(matching: .any).matching(identifier: "drag-card").firstMatch
    let zone = app.descendants(matching: .any).matching(identifier: "drop-archive").firstMatch
    XCTAssertTrue(card.waitForExistence(timeout: 5))
    XCTAssertTrue(card.isHittable && zone.isHittable)
    capture(app, name: "drag-before")
    card.press(forDuration: 1, thenDragTo: zone, withVelocity: .slow, thenHoldForDuration: 1)
    capture(app, name: "drag-after")
    print("Native drag session: " + app.staticTexts["drag-session"].label)
    expect(app.staticTexts["drop-result"], label: "Moved card to archive")
    expect(app.staticTexts["drag-session"], label: "Session: none")
    expect(app.staticTexts["drop-count"], label: "Drops: 1")
    card.press(forDuration: 1, thenDragTo: zone, withVelocity: .slow, thenHoldForDuration: 1)
    expect(app.staticTexts["drag-session"], label: "Session: none")
    expect(app.staticTexts["drop-count"], label: "Drops: 2")
  }
  func testNativeDragCancellation() {
    let app = launch("drag")
    defer { app.terminate() }
    let card = app.descendants(matching: .any).matching(identifier: "drag-card").firstMatch
    XCTAssertTrue(card.waitForExistence(timeout: 5))
    let start = card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    let outside = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
    start.press(forDuration: 1, thenDragTo: outside, withVelocity: .slow, thenHoldForDuration: 1)
    expect(app.staticTexts["drag-session"], label: "Session: none")
    expect(app.staticTexts["drop-count"], label: "Drops: 0")
  }
  func testResizeAndActualImageExport() {
    var app = launch("resize")
    defer { app.terminate() }
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
  func testCropResizeHandleAccessibility() {
    let app = launch("crop")
    defer { app.terminate() }
    let corner = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Resize bottom right")).firstMatch
    XCTAssertTrue(corner.waitForExistence(timeout: 5))
    XCTAssertTrue(corner.isHittable)
    XCTAssertEqual(corner.value as? String, "200 by 200")
    let from = corner.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    from.press(forDuration: 0.1, thenDragTo: from.withOffset(CGVector(dx: -30, dy: -30)))
    XCTAssertNotEqual(corner.value as? String, "200 by 200")
  }
  func testCarouselAndMenu() {
    var app = launch("carousel")
    defer { app.terminate() }
    app.buttons["Next slide"].tap()
    expect(app.staticTexts["carousel-position"], label: "2 of 3")
    app = launch("menu")
    app.buttons["Open menu"].tap()
    XCTAssertTrue(app.buttons["Favorite"].waitForExistence(timeout: 5))
    app.buttons["Favorite"].tap()
    expect(app.staticTexts["menu-result"], label: "Action: favorite")
  }
  func testNestedPresentation() {
    let app = launch("overlays")
    defer { app.terminate() }
    app.buttons["Open inspector"].tap()
    XCTAssertTrue(app.buttons["Open nested overlay"].waitForExistence(timeout: 5))
    app.buttons["Open nested overlay"].tap()
    XCTAssertTrue(app.buttons["Close confirmation"].waitForExistence(timeout: 5))
    app.buttons["Close confirmation"].tap()
    XCTAssertTrue(app.buttons["Close inspector"].waitForExistence(timeout: 5))
    app.buttons["Close inspector"].tap()
    expect(app.staticTexts["overlay-result"], label: "Overlay count: 0")
  }
  func testEditorNativeTypingAndFormatting() {
    let app = launch("editor")
    defer { app.terminate() }
    let editor = app.textViews["Rich text"]
    XCTAssertTrue(editor.waitForExistence(timeout: 5))
    editor.tap()
    editor.typeText("!")
    app.buttons["Bold first word"].tap()
    expect(app.staticTexts["editor-format"], label: "Bold runs: 1")
    XCTAssertTrue(app.staticTexts["editor-result"].label.contains("!"))
  }
  func testNativeMeasurements() {
    let app = launch("measurements")
    defer { app.terminate() }
    let measured = app.staticTexts["measurement-result"]
    XCTAssertTrue(measured.waitForExistence(timeout: 5))
    XCTAssertFalse(measured.label.hasPrefix("0 × 0"))
  }
  func testRegisteredAgentAction() {
    let app = launch("agent")
    defer { app.terminate() }
    app.buttons["Agent next"].tap()
    expect(app.staticTexts["agent-result"], label: "Agent moved to slide 2")
    expect(app.staticTexts["carousel-position"], label: "2 of 3")
  }
}
