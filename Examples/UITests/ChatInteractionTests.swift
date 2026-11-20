import XCTest

@MainActor final class ChatInteractionTests: XCTestCase {
  private func launch() -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--story", "chat", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    XCTAssertTrue(app.buttons["chat-append"].waitForExistence(timeout: 5))
    return app
  }
  private func expect(_ element: XCUIElement, label: String) {
    let expected = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == %@", label), object: element)
    XCTAssertEqual(XCTWaiter.wait(for: [expected], timeout: 5), .completed)
  }
  private func capture(_ app: XCUIApplication, _ name: String) {
    let image = XCTAttachment(screenshot: app.screenshot())
    image.name = name
    image.lifetime = .keepAlways
    add(image)
    let tree = XCTAttachment(string: app.debugDescription)
    tree.name = name + "-accessibility"
    tree.lifetime = .keepAlways
    add(tree)
  }
  private func expectRow(_ row: XCUIElement, y: CGFloat) async {
    for _ in 0..<50 {
      if row.exists && abs(row.frame.minY - y) <= 2 { return }
      try? await Task.sleep(for: .milliseconds(100))
    }
    XCTFail("The reading row did not retain its vertical offset after layout settled")
  }
  func testReadingDuringUpdatesAndHistoryInsertion() async {
    let app = launch()
    defer { app.terminate() }
    let transcript = app.scrollViews["chat-transcript"]
    transcript.swipeDown()
    expect(app.staticTexts["chat-follow-mode"], label: "Reading earlier")
    let anchor = app.staticTexts["chat-anchor"].label
    XCTAssertNotEqual(anchor, "Anchor: none")
    let rowID = String(anchor.dropFirst("Anchor: ".count))
    let row = app.staticTexts["chat-" + rowID]
    XCTAssertTrue(row.exists)
    let originalY = row.frame.minY
    let originalWidth = row.frame.width
    app.buttons["chat-append"].tap()
    app.buttons["chat-append"].tap()
    expect(app.staticTexts["chat-follow-mode"], label: "Reading earlier")
    expect(app.staticTexts["chat-anchor"], label: anchor)
    XCTAssertEqual(row.frame.minY, originalY, accuracy: 2)
    app.buttons["chat-load-earlier"].tap()
    expect(app.staticTexts["chat-anchor"], label: anchor)
    await expectRow(row, y: originalY)
    app.buttons["chat-layout-expanded"].tap()
    expect(app.staticTexts["chat-layout-value"], label: "Layout: expanded")
    await expectRow(row, y: originalY)
    XCTAssertLessThan(row.frame.width, originalWidth - 20)
    app.buttons["chat-jump-latest"].tap()
    expect(app.staticTexts["chat-follow-mode"], label: "Following latest")
  }
  func testManualActivityChoiceSurvivesStreamingAndCancellation() {
    let app = launch()
    defer { app.terminate() }
    app.buttons["chat-stream"].tap()
    expect(app.buttons["chat-stream"], label: "Stop stream")
    let toggle = app.buttons["chat-activity-toggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    toggle.tap()
    capture(app, "chat-activity-after-toggle")
    expect(app.staticTexts["chat-activity-actions"], label: "Activity actions: 1")
    XCTAssertEqual(toggle.value as? String, "Collapsed")
    app.buttons["chat-append"].tap()
    XCTAssertEqual(toggle.value as? String, "Collapsed")
    app.buttons["chat-stream"].tap()
    let stopped = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label == 'Start stream'"), object: app.buttons["chat-stream"])
    XCTAssertEqual(XCTWaiter.wait(for: [stopped], timeout: 5), .completed)
    toggle.tap()
    let cancelled = XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS 'Phase: cancelled'"),
      object: app.staticTexts["chat-activity-details"])
    XCTAssertEqual(XCTWaiter.wait(for: [cancelled], timeout: 5), .completed)
    expect(app.staticTexts["chat-follow-mode"], label: "Reading earlier")
  }
  func testKeyboardAndExplicitLayoutPreviews() {
    let app = launch()
    defer { app.terminate() }
    app.buttons["chat-layout-expanded"].tap()
    capture(app, "chat-expanded-action")
    expect(app.staticTexts["chat-layout-value"], label: "Layout: expanded")
    expect(app.staticTexts["chat-pane-count"], label: "Available panes: 2")
    app.buttons["chat-layout-tabletop"].tap()
    expect(app.staticTexts["chat-pane-count"], label: "Available panes: 2")
    app.buttons["chat-layout-compact"].tap()
    expect(app.staticTexts["chat-pane-count"], label: "Available panes: 1")
    let composer = app.textFields["chat-composer"]
    composer.tap()
    composer.typeText("Local draft")
    XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
    XCTAssertLessThanOrEqual(composer.frame.maxY, app.keyboards.firstMatch.frame.minY + 1)
    let image = XCTAttachment(screenshot: app.screenshot())
    image.name = "chat-keyboard-local-draft"
    image.lifetime = .keepAlways
    add(image)
    composer.typeText("\n")
    XCTAssertEqual(composer.value as? String, "Local draft")
  }
}
