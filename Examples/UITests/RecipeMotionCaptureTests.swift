import XCTest

/// Real native video capture; run explicitly with the ReadmeCapture scheme.
@MainActor final class RecipeMotionCaptureTests: XCTestCase {
  private func launch(_ recipe: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--recipe", recipe, "--motion-capture", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
  }
  private func checkpoint(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  private func geometry(_ app: XCUIApplication, component: XCUIElement? = nil) throws {
    func values(_ frame: CGRect) -> [Double] {
      [frame.minX, frame.minY, frame.width, frame.height].map(Double.init)
    }
    var value = ["window": values(app.frame)]
    if let component { value["component"] = values(component.frame) }
    let data = try JSONSerialization.data(withJSONObject: value, options: [.sortedKeys])
    let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
    attachment.name = "motion-geometry"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  // Pauses are deliberate recording holds so each native state is readable.
  private func hold() { Thread.sleep(forTimeInterval: 0.8) }

  func testConfirmationVideo() throws {
    let app = launch("confirmation")
    let trigger = app.buttons["Delete project"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 8))
    try geometry(app)
    checkpoint("MOTION-start")
    hold()
    trigger.tap()
    XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
    checkpoint("MOTION-open")
    hold()
    app.buttons["Cancel"].tap()
    let reachable = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: trigger)
    wait(for: [reachable], timeout: 5)
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Project kept")
    hold()
    trigger.tap()
    XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 5))
    hold()
    app.buttons["Delete"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Deleted locally: 1")
    hold()
    checkpoint("MOTION-end")
  }
  func testSelectionVideo() throws {
    let app = launch("selection")
    let personal = app.buttons["Personal, Just you"]
    XCTAssertTrue(personal.waitForExistence(timeout: 8))
    XCTAssertTrue(personal.isSelected)
    try geometry(app, component: app.otherElements["recipe-component"])
    checkpoint("MOTION-start")
    hold()
    app.buttons["Team, Work together"].tap()
    XCTAssertTrue(app.buttons["Team, Work together"].isSelected)
    checkpoint("MOTION-team")
    hold()
    app.buttons["Studio, Work together"].tap()
    XCTAssertTrue(app.buttons["Studio, Work together"].isSelected)
    XCTAssertFalse(personal.isSelected)
    hold()
    checkpoint("MOTION-end")
  }
  func testActivityVideo() throws {
    let app = launch("activity")
    let title = app.buttons["Read project files"]
    XCTAssertTrue(title.waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["Package.swift"].isHittable)
    try geometry(app, component: app.otherElements["recipe-component"])
    checkpoint("MOTION-start")
    hold()
    title.tap()
    XCTAssertFalse(app.staticTexts["Package.swift"].exists)
    checkpoint("MOTION-collapsed")
    hold()
    title.tap()
    XCTAssertTrue(app.staticTexts["Package.swift"].isHittable)
    checkpoint("MOTION-reopened")
    hold()
    title.tap()
    XCTAssertFalse(app.staticTexts["Package.swift"].exists)
    hold()
    checkpoint("MOTION-end")
  }
  func testMorphVideo() throws {
    let app = launch("morph")
    XCTAssertTrue(app.buttons["Team"].waitForExistence(timeout: 8))
    try geometry(app)
    checkpoint("MOTION-start")
    hold()
    for style in ["Segments", "Chips", "Cards"] {
      app.buttons[style].tap()
      XCTAssertTrue(app.buttons["Team"].isSelected)
      XCTAssertEqual(app.staticTexts["morph-selection"].label, "Selected: Team")
      hold()
      checkpoint("MOTION-" + style)
    }
    app.buttons["Studio"].tap()
    app.buttons["Segments"].tap()
    XCTAssertTrue(app.buttons["Studio"].isSelected)
    hold()
    checkpoint("MOTION-end")
  }

}
