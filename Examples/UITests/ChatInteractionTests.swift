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
  func testReadingDuringUpdatesAndHistoryInsertion() {
    let app = launch()
    defer { app.terminate() }
    let transcript = app.scrollViews["chat-transcript"]
    transcript.swipeDown()
    expect(app.staticTexts["chat-follow-mode"], label: "Reading earlier")
    let anchor = app.staticTexts["chat-anchor"].label
    XCTAssertNotEqual(anchor, "Anchor: none")
    app.buttons["chat-append"].tap()
    app.buttons["chat-append"].tap()
    expect(app.staticTexts["chat-follow-mode"], label: "Reading earlier")
    expect(app.staticTexts["chat-anchor"], label: anchor)
    app.buttons["chat-load-earlier"].tap()
    expect(app.staticTexts["chat-anchor"], label: anchor)
    app.buttons["chat-jump-latest"].tap()
    expect(app.staticTexts["chat-follow-mode"], label: "Following latest")
  }
  func testManualActivityChoiceSurvivesStreamingAndCancellation() {
    let app = launch()
    defer { app.terminate() }
    app.buttons["chat-stream"].tap()
    let toggle = app.buttons["chat-activity-toggle"]
    XCTAssertTrue(toggle.waitForExistence(timeout: 5))
    toggle.tap()
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
