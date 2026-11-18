import XCTest

final class CatalogTests: XCTestCase {
    @MainActor
    func testSelectionDisclosureAndSheetReplay() {
        let app = XCUIApplication()
        app.launch()
        app.buttons["SwiftUI"].tap()
        XCTAssertTrue(app.staticTexts["Selected: SwiftUI"].exists)
        app.buttons["UIKit"].tap()
        XCTAssertTrue(app.staticTexts["Selected: SwiftUI, UIKit"].exists)
        XCTAssertFalse(app.buttons["Unavailable"].isEnabled)
        app.buttons["SwiftUI"].tap()
        XCTAssertTrue(app.staticTexts["Selected: UIKit"].exists)
        app.buttons["How it works"].tap()
        XCTAssertTrue(app.staticTexts["Compose small behaviors. Keep your own design."].exists)
        app.buttons["Open sheet"].tap()
        XCTAssertTrue(app.buttons["Close sheet"].waitForExistence(timeout: 3))
        app.buttons["Close sheet"].tap()
        XCTAssertTrue(app.buttons["Open sheet"].waitForExistence(timeout: 3))
    }
}
