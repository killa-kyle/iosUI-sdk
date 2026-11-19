import XCTest

/// Reproducible native checkpoints used to encode the README's animated GIFs.
@MainActor final class ReadmeCaptureTests: XCTestCase {
  private func launch(_ story: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--story", story, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
  }
  private func capture(_ app: XCUIApplication, _ name: String) {
    let frame = XCTAttachment(screenshot: app.screenshot())
    frame.name = name
    frame.lifetime = .keepAlways
    add(frame)
  }
  func testCalendarCheckpoints() {
    let app = launch("calendar")
    XCTAssertTrue(app.buttons["calendar-2026-11-05"].waitForExistence(timeout: 5))
    capture(app, "calendar-01")
    for (index, date) in ["05", "07", "12", "15"].enumerated() {
      app.buttons["calendar-2026-11-" + date].tap()
      capture(app, "calendar-0\(index + 2)")
    }
    XCTAssertEqual(app.staticTexts["calendar-result"].label, "2026-11-12…2026-11-15")
  }
  func testDragCheckpoints() {
    let app = launch("drag")
    let card = app.descendants(matching: .any).matching(identifier: "drag-card").firstMatch
    let zone = app.descendants(matching: .any).matching(identifier: "drop-archive").firstMatch
    XCTAssertTrue(card.waitForExistence(timeout: 5))
    capture(app, "drag-01")
    for index in 1...2 {
      card.press(forDuration: 1, thenDragTo: zone, withVelocity: .slow, thenHoldForDuration: 1)
      XCTAssertEqual(app.staticTexts["drop-count"].label, "Drops: \(index)")
      XCTAssertEqual(app.staticTexts["drag-session"].label, "Session: none")
      capture(app, "drag-0\(index + 1)")
    }
  }
  func testCropCheckpoints() {
    let app = launch("crop")
    XCTAssertTrue(app.buttons["Rotate crop"].waitForExistence(timeout: 5))
    capture(app, "crop-01")
    app.buttons["Rotate crop"].tap()
    capture(app, "crop-02")
    app.buttons["Export crop"].tap()
    XCTAssertEqual(app.staticTexts["crop-result"].label, "Exported 200 × 200")
    capture(app, "crop-03")
  }
}
