import XCTest

/// Run with the ReadmeCapture scheme to retain real native screen recordings.
@MainActor final class ReadmeCaptureTests: XCTestCase {
  private func launch(_ story: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--story", story, "--showcase", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
  }
  private func checkpoint(_ app: XCUIApplication, _ name: String) {
    let image = XCTAttachment(screenshot: app.screenshot())
    image.name = name
    image.lifetime = .keepAlways
    add(image)
  }
  func testCalendarVideo() {
    let app = launch("calendar")
    XCTAssertTrue(app.buttons["calendar-2026-11-05"].waitForExistence(timeout: 5))
    checkpoint(app, "README-start")
    for day in ["05", "09", "12", "15"] { app.buttons["calendar-2026-11-" + day].tap() }
    XCTAssertEqual(app.staticTexts["calendar-result"].label, "2026-11-12…2026-11-15")
    checkpoint(app, "README-end")
  }
  func testDragVideo() {
    let app = launch("drag")
    let card = app.descendants(matching: .any).matching(identifier: "drag-card").firstMatch
    let zone = app.descendants(matching: .any).matching(identifier: "drop-archive").firstMatch
    XCTAssertTrue(card.waitForExistence(timeout: 5))
    checkpoint(app, "README-start")
    card.press(forDuration: 1, thenDragTo: zone, withVelocity: XCUIGestureVelocity(rawValue: 80), thenHoldForDuration: 1)
    let dropped = expectation(for: NSPredicate(format: "label == %@", "Drops: 1"),
      evaluatedWith: app.staticTexts["drop-count"])
    wait(for: [dropped], timeout: 5)
    XCTAssertEqual(app.staticTexts["drag-session"].label, "Session: none")
    checkpoint(app, "README-end")
  }
  func testCropVideo() {
    let app = launch("crop")
    checkpoint(app, "README-launched")
    let hierarchy = XCTAttachment(string: app.debugDescription)
    hierarchy.name = "Crop accessibility"
    hierarchy.lifetime = .keepAlways
    add(hierarchy)
    let handle = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Resize bottom right")).firstMatch
    XCTAssertTrue(handle.waitForExistence(timeout: 5))
    checkpoint(app, "README-start")
    let from = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
    from.press(forDuration: 0.2, thenDragTo: from.withOffset(CGVector(dx: -35, dy: -35)), withVelocity: XCUIGestureVelocity(rawValue: 35), thenHoldForDuration: 0.5)
    app.buttons["Rotate crop"].tap()
    app.buttons["Export crop"].tap()
    let exported = app.staticTexts["crop-result"]
    if !exported.isHittable { app.swipeUp() }
    XCTAssertTrue(exported.isHittable)
    checkpoint(app, "README-end")
  }
}
