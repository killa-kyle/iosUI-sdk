import XCTest

@MainActor final class ComponentRecipeTests: XCTestCase {
  private func launch(_ recipe: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--recipe", recipe]
    app.launch()
    return app
  }
  private func capture(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  func testConfirmationCancelAndConfirm() {
    let app = launch("confirmation")
    let trigger = app.buttons["Delete project"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 8))
    trigger.tap()
    XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
    capture("recipe-confirmation")
    app.buttons["Cancel"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Project kept")
    trigger.tap()
    app.buttons["Delete"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Deleted locally: 1")
    XCTAssertTrue(trigger.isHittable)
  }
  func testPlanSelection() {
    let app = launch("selection")
    XCTAssertTrue(app.buttons["Team"].waitForExistence(timeout: 8))
    app.buttons["Team"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Selected: Team")
    capture("recipe-selection")
    app.buttons["Studio"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Selected: Studio")
  }
  func testActivityDisclosure() {
    let app = launch("activity")
    let title = app.buttons["Read project files"]
    XCTAssertTrue(title.waitForExistence(timeout: 8))
    XCTAssertTrue(app.staticTexts["Package.swift"].isHittable)
    capture("recipe-activity")
    title.tap()
    XCTAssertFalse(app.staticTexts["Package.swift"].exists)
    title.tap()
    XCTAssertTrue(app.staticTexts["Package.swift"].isHittable)
  }
}
