import XCTest

final class CatalogTests: XCTestCase {
  @MainActor
  func testSelectionDisclosureAndSheetReplay() {
    continueAfterFailure = false
    let app = XCUIApplication()
    app.launch()
    defer { app.terminate() }
    let status = app.staticTexts["selection-status"]
    XCTAssertTrue(status.waitForExistence(timeout: 3))
    app.buttons["SwiftUI"].tap()
    XCTAssertEqual(status.label, "Selected: SwiftUI")
    XCTAssertTrue(app.buttons["SwiftUI"].isSelected)
    XCTAssertFalse(app.buttons["UIKit"].isSelected)
    app.buttons["UIKit"].tap()
    XCTAssertEqual(status.label, "Selected: SwiftUI, UIKit")
    XCTAssertFalse(app.buttons["Unavailable"].isEnabled)
    app.buttons["SwiftUI"].tap()
    XCTAssertEqual(status.label, "Selected: UIKit")
    app.buttons["How it works"].tap()
    XCTAssertTrue(app.staticTexts["Compose small behaviors. Keep your own design."].exists)
    app.buttons["Open sheet"].tap()
    XCTAssertTrue(app.buttons["Close sheet"].waitForExistence(timeout: 3))
    app.buttons["Close sheet"].tap()
    XCTAssertTrue(app.buttons["Open sheet"].waitForExistence(timeout: 3))
  }
}
