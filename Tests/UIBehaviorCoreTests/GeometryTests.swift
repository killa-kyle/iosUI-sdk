import XCTest
import UIBehaviorCore

final class GeometryTests: XCTestCase {
    func testZoomPreservesAnchorContentPoint() {
        var state = Viewport(x: 10, y: 20)
        let before = state.contentPoint(screenX: 100, screenY: 200)
        state.zoom(to: 2, anchorX: 100, anchorY: 200)
        let after = state.contentPoint(screenX: 100, screenY: 200)
        XCTAssertEqual(before.x, after.x); XCTAssertEqual(before.y, after.y)
        state.pan(dx: 5, dy: -5)
        XCTAssertEqual(state.x, -75); XCTAssertEqual(state.y, -165)
    }
    func testViewportBoundsAndInvalidInput() {
        var state = Viewport()
        state.zoom(to: 100, anchorX: 0, anchorY: 0)
        XCTAssertEqual(state.scale, 8)
        state.pan(dx: .nan, dy: 0); XCTAssertEqual(state.x, 0)
        state.zoom(to: -1, anchorX: 0, anchorY: 0); XCTAssertEqual(state.scale, 0.25)
    }
    func testVirtualRangeAtEdgesAndBeyondEnd() {
        let window = VirtualWindow(count: 100, itemExtent: 20)
        XCTAssertEqual(window.totalExtent, 2000)
        XCTAssertEqual(window.visibleRange(offset: 0, viewportExtent: 100), 0..<7)
        XCTAssertEqual(window.visibleRange(offset: 200, viewportExtent: 100), 8..<17)
        XCTAssertEqual(window.visibleRange(offset: 9999, viewportExtent: 100), 98..<100)
        XCTAssertEqual(window.visibleRange(offset: 0, viewportExtent: 0), 0..<0)
        XCTAssertEqual(window.offset(for: 9), 180); XCTAssertNil(window.offset(for: 100))
    }
}
