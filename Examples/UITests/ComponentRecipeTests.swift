import XCTest

@MainActor final class ComponentRecipeTests: XCTestCase {
  private func launch(_ recipe: String) -> XCUIApplication {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launchArguments = ["--recipe", recipe]
    app.launch()
    return app
  }
  private func capture(_ name: String, component: XCUIElement) {
    XCTAssertTrue(component.exists)
    let detail = XCTAttachment(screenshot: component.screenshot())
    detail.name = name
    detail.lifetime = .keepAlways
    add(detail)
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name + "-screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
  func testConfirmationCancelAndConfirm() {
    let app = launch("confirmation")
    let trigger = app.buttons["Delete project"]
    XCTAssertTrue(trigger.waitForExistence(timeout: 8))
    trigger.tap()
    XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
    capture("recipe-confirmation", component: app.otherElements["confirmation-content"])
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
    capture("recipe-selection", component: app.otherElements["recipe-component"])
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
    capture("recipe-activity", component: app.otherElements["recipe-component"])
    title.tap()
    XCTAssertFalse(app.staticTexts["Package.swift"].exists)
    title.tap()
    XCTAssertTrue(app.staticTexts["Package.swift"].isHittable)
  }
  func testSelectionSurvivesComponentMorph() {
    let app = launch("morph")
    XCTAssertTrue(app.buttons["Team"].waitForExistence(timeout: 8))
    XCTAssertTrue(app.buttons["Team"].isSelected)
    for style in ["Segments", "Chips", "Cards"] {
      app.buttons[style].tap()
      XCTAssertTrue(app.buttons["Team"].isSelected)
      XCTAssertEqual(app.staticTexts["morph-selection"].label, "Selected: Team")
    }
    app.buttons["Studio"].tap()
    app.buttons["Chips"].tap()
    XCTAssertTrue(app.buttons["Studio"].isSelected)
    XCTAssertFalse(app.buttons["Team"].isSelected)
    XCTAssertEqual(app.staticTexts["morph-selection"].label, "Selected: Studio")
    capture("recipe-morph", component: app.otherElements["morph-component"])
  }

  func testCropTransactionAndNestedPublish() {
    let app = launch("workspace")
    XCTAssertTrue(app.buttons["Edit cover"].waitForExistence(timeout: 8))
    app.buttons["Edit cover"].tap()
    app.buttons["Rotate"].tap()
    XCTAssertEqual(app.staticTexts["media-draft"].label, "Draft: 90°")
    app.buttons["Cancel edit"].tap()
    XCTAssertEqual(app.staticTexts["media-saved"].label, "Saved rotation: 0°")
    app.buttons["Edit cover"].tap()
    XCTAssertEqual(app.staticTexts["media-draft"].label, "Draft: 0°")
    app.buttons["Rotate"].tap()
    app.buttons["Continue to publish"].tap()
    XCTAssertTrue(app.textFields["Caption"].waitForExistence(timeout: 5))
    app.buttons["Portfolio"].tap()
    app.buttons["Back to crop"].tap()
    XCTAssertEqual(app.staticTexts["media-draft"].label, "Draft: 90°")
    app.buttons["Continue to publish"].tap()
    XCTAssertTrue(app.buttons["Portfolio"].isSelected)
    app.buttons["Publish cover"].tap()
    XCTAssertTrue(app.staticTexts["media-published"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["media-saved"].label, "Saved rotation: 90°")
    XCTAssertEqual(app.staticTexts["media-published"].label, "Published to Portfolio")
  }

}
