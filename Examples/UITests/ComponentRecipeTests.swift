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
    XCTAssertTrue(trigger.waitForExistence(timeout: 5))
    let reachable = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: trigger)
    wait(for: [reachable], timeout: 5)
    trigger.tap()
    XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 5))
    app.buttons["Delete"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Deleted locally: 1")
    XCTAssertTrue(trigger.isHittable)
  }
  func testPlanSelection() {
    let app = launch("selection")
    XCTAssertTrue(app.buttons["Team, Work together"].waitForExistence(timeout: 8))
    app.buttons["Team, Work together"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Selected: Team")
    XCTAssertTrue(app.buttons["Team, Work together"].isSelected)
    XCTAssertFalse(app.buttons["Personal, Just you"].isSelected)
    capture("recipe-selection")
    app.buttons["Studio, Work together"].tap()
    XCTAssertEqual(app.staticTexts["recipe-result"].label, "Selected: Studio")
    XCTAssertTrue(app.buttons["Studio, Work together"].isSelected)
    XCTAssertFalse(app.buttons["Team, Work together"].isSelected)
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
