import XCTest

@testable import UIBehaviorCore

final class ExtendedBehaviorTests: XCTestCase {
  func testCivilDateLeapCenturyMonthClampingAndBounds() throws {
    XCTAssertThrowsError(try CalendarDate("1900-02-29"))
    XCTAssertThrowsError(try CalendarDate("2026-2-01"))
    XCTAssertThrowsError(try CalendarDate("0000-01-01"))
    XCTAssertEqual(try CalendarDate("2000-02-29").addingDays(1)?.description, "2000-03-01")
    XCTAssertEqual(try CalendarDate("2024-01-31").addingMonths(1)?.description, "2024-02-29")
    XCTAssertEqual(try CalendarDate("2026-03-08").addingDays(1)?.description, "2026-03-09")
    XCTAssertNil(try CalendarDate("0001-01-01").addingDays(-1))
    XCTAssertNil(try CalendarDate("9999-12-31").addingDays(1))
    XCTAssertNil(try CalendarDate("2026-11-01").addingDays(Int.max))
    XCTAssertEqual(try CalendarDate("0001-01-01").weekday, 2)
  }
  func testCalendarRangeRejectsDisabledInteriorAndBuildsAdjacentMonthGrid() throws {
    let start = try CalendarDate("2026-11-01")
    let blocked = try CalendarDate("2026-11-03")
    var model = CalendarSelection(month: start, mode: .range, disabled: [blocked])
    XCTAssertEqual(model.grid().count, 42)
    XCTAssertEqual(model.grid()[0], start)
    XCTAssertTrue(model.select(start))
    XCTAssertFalse(model.select(try CalendarDate("2026-11-05")))
    XCTAssertEqual(model.selected, start...start)
    model.page(months: 1)
    XCTAssertEqual(model.visibleMonth.description, "2026-12-01")
  }
  func testColorHexHSVARoundTripAndAlphaContrast() throws {
    XCTAssertNil(ColorValue(hex: "#GG0000"))
    XCTAssertEqual(ColorValue(hex: "#f008")?.hex(includeAlpha: true), "#FF000088")
    for rgb in ["#4F46E5", "#FFFFFF", "#000000", "#05A180"] {
      let c = try XCTUnwrap(ColorValue(hex: rgb))
      let hsv = c.hsba
      XCTAssertEqual(
        ColorValue(hue: hsv.hue, saturation: hsv.saturation, brightness: hsv.brightness).hex(), rgb)
    }
    let white = ColorValue(red: 1, green: 1, blue: 1)
    let black = ColorValue(red: 0, green: 0, blue: 0)
    XCTAssertEqual(black.contrast(against: white), 21, accuracy: 0.001)
    XCTAssertEqual(
      ColorValue(red: 0, green: 0, blue: 0, alpha: 0).contrast(against: white), 1, accuracy: 0.001)
    XCTAssertEqual(ColorValue(hue: -1, saturation: 1, brightness: 1).hex(), "#FF0000")
  }
  func testGridSkipsDisabledAndShrinksRectangleFromStableAnchor() {
    var grid = GridNavigation(rows: 3, columns: 4, disabled: [GridCell(0, 1)])
    grid.move(.right)
    XCTAssertEqual(grid.focused, GridCell(0, 0))
    grid.move(.right)
    XCTAssertEqual(grid.focused, GridCell(0, 2))
    grid.focus(GridCell(0, 0))
    grid.focus(GridCell(2, 3), extending: true)
    XCTAssertEqual(grid.selected.count, 11)
    grid.focus(GridCell(1, 1), extending: true)
    XCTAssertEqual(grid.selected.count, 3)
    grid.focus(GridCell(-1, 0))
    XCTAssertEqual(grid.focused, GridCell(1, 1))
    grid.move(.right, rightToLeft: true)
    XCTAssertEqual(grid.focused, GridCell(1, 0))
  }
  func testTreeCollapseRetainsSelectionButMovesHiddenFocusToParent() throws {
    var tree = try TreeNavigation([
      BehaviorTreeNode(
        "root", children: [BehaviorTreeNode("a"), BehaviorTreeNode("b", disabled: true)])
    ])
    tree.move(.first)
    tree.move(.right)
    XCTAssertTrue(tree.expanded.contains("root"))
    tree.move(.right)
    XCTAssertEqual(tree.focused, "a")
    tree.select("a")
    tree.toggle("root")
    XCTAssertEqual(tree.focused, "root")
    XCTAssertEqual(tree.selection.selected, ["a"])
    XCTAssertThrowsError(
      try TreeNavigation([BehaviorTreeNode("duplicate"), BehaviorTreeNode("duplicate")]))
  }
  func testTreeRightDoesNotEscapeToSiblingWhenAllChildrenDisabled() throws {
    var tree = try TreeNavigation(
      [
        BehaviorTreeNode("root", children: [BehaviorTreeNode("locked", disabled: true)]),
        BehaviorTreeNode("other"),
      ], expanded: ["root"])
    tree.move(.first)
    tree.move(.right)
    XCTAssertEqual(tree.focused, "root")
  }
  func testDropChoosesInnerZoneRevalidatesAndCancelsWithoutCommit() {
    let outer = DropTarget(
      id: "outer", rect: BehaviorRect(width: 100, height: 100), acceptedTypes: ["card"])
    var inner = DropTarget(
      id: "inner", rect: BehaviorRect(x: 10, y: 10, width: 30, height: 30), acceptedTypes: ["card"])
    var drag = DragDropBehavior()
    XCTAssertTrue(drag.begin(DragPayload(id: "source", type: "card"), at: BehaviorPoint(20, 20)))
    drag.update(at: BehaviorPoint(20, 20), targets: [outer, inner])
    XCTAssertEqual(drag.target, "inner")
    inner.enabled = false
    XCTAssertEqual(drag.drop(targets: [outer, inner])?.target, "outer")
    XCTAssertNil(drag.payload)
    _ = drag.begin(DragPayload(id: "source", type: "file"), at: BehaviorPoint(20, 20))
    XCTAssertNil(drag.drop(targets: [outer]))
    XCTAssertNil(drag.target)
    XCTAssertLessThan(DragDropBehavior.autoScroll(pointer: 0, length: 100), 0)
    XCTAssertEqual(DragDropBehavior.autoScroll(pointer: .nan, length: 100), 0)
  }
  func testResizeAnchorsOppositeEdgesClampsAndCancels() {
    let original = BehaviorRect(x: 20, y: 20, width: 60, height: 40)
    var resize = ResizeBehavior(rect: original, bounds: BehaviorRect(width: 100, height: 100))
    resize.begin(.nw)
    resize.update(dx: -100, dy: -100)
    XCTAssertEqual(resize.rect, BehaviorRect(width: 80, height: 60))
    resize.cancel()
    XCTAssertEqual(resize.rect, original)
    resize.begin(.se)
    resize.update(dx: 10, dy: 10)
    resize.update(dx: 20, dy: 20)
    XCTAssertEqual(resize.rect.width, 80)
    XCTAssertEqual(resize.rect.height, 60)
    resize.update(dx: .nan, dy: 0)
    XCTAssertEqual(resize.rect.width, 80)
    resize.commit()
    resize.cancel()
    XCTAssertEqual(resize.rect.width, 80)
  }
  func testEveryResizeHandleAndAspectStayInBounds() {
    for handle in ResizeHandle.allCases {
      var r = ResizeBehavior(
        rect: BehaviorRect(x: 20, y: 20, width: 40, height: 20),
        bounds: BehaviorRect(width: 100, height: 100), aspect: 2)
      r.begin(handle)
      r.update(dx: 500, dy: -500)
      XCTAssertTrue(r.rect.isValid)
      XCTAssertGreaterThanOrEqual(r.rect.x, 0)
      XCTAssertGreaterThanOrEqual(r.rect.y, 0)
      XCTAssertLessThanOrEqual(r.rect.maxX, 100)
      XCTAssertLessThanOrEqual(r.rect.maxY, 100)
      XCTAssertEqual(r.rect.width / r.rect.height, 2, accuracy: 0.0001)
    }
  }
  func testCropFourQuarterTurnsRestorePixelRectangle() {
    var crop = CropSelection(width: 300, height: 200, aspect: 1.5)
    crop.begin(.se)
    crop.update(dx: -60, dy: -40)
    crop.commit()
    let rect = crop.rect
    for _ in 0..<4 { crop.rotateClockwise() }
    XCTAssertEqual(crop.rotation, 0)
    XCTAssertEqual(crop.rect, rect)
  }
  func testCarouselEmptyLoopSwipeAndReducedMotionClock() {
    var empty = CarouselBehavior(count: 0)
    empty.next()
    empty.previous()
    XCTAssertEqual(empty.index, 0)
    var carousel = CarouselBehavior(count: 3, loops: true)
    carousel.previous()
    XCTAssertEqual(carousel.index, 2)
    carousel.next()
    XCTAssertEqual(carousel.index, 0)
    carousel.swipe(translation: -100, extent: 300)
    XCTAssertEqual(carousel.index, 1)
    carousel.play(now: 0)
    carousel.tick(now: 10, interval: 1, reduceMotion: true)
    XCTAssertEqual(carousel.index, 1)
    carousel.tick(now: 10, interval: 1)
    XCTAssertEqual(carousel.index, 2)
    carousel.tick(now: 10.5, interval: 1)
    XCTAssertEqual(carousel.index, 2)
    carousel.pause()
    carousel.tick(now: 100, interval: 1)
    XCTAssertEqual(carousel.index, 2)
  }
  func testMenuRadioDisabledAncestorsAndNestedEscape() {
    var menu = MenuBehavior([
      BehaviorMenuItem(
        "sub", title: "Sub", kind: .submenu,
        children: [
          BehaviorMenuItem("a", title: "A", kind: .radio(group: "group")),
          BehaviorMenuItem("b", title: "B", kind: .radio(group: "group")),
        ]),
      BehaviorMenuItem(
        "locked", title: "Locked", enabled: false, kind: .submenu,
        children: [BehaviorMenuItem("child", title: "Child")]),
    ])
    XCTAssertNil(menu.activate("child"))
    XCTAssertNil(menu.activate("sub"))
    XCTAssertEqual(menu.path, ["sub"])
    menu.closeLevel()
    XCTAssertEqual(menu.path, [])
    XCTAssertEqual(menu.activate("a"), "a")
    XCTAssertEqual(menu.activate("b"), "b")
    XCTAssertEqual(menu.radio["group"], "b")
  }
  func testOverlayDismissesDescendantsAndRestoresOwningFocus() {
    var stack = OverlayStack()
    XCTAssertTrue(stack.present(BehaviorOverlay("root", restoreFocus: "root-button")))
    XCTAssertFalse(stack.present(BehaviorOverlay("orphan", parent: "unknown")))
    XCTAssertTrue(stack.present(BehaviorOverlay("child", parent: "root", dismissible: false)))
    XCTAssertFalse(stack.dismissTop())
    stack.dismiss("root")
    XCTAssertEqual(stack.entries, [])
    XCTAssertEqual(stack.focusToRestore, "root-button")
  }
  func testRichTextUTF16ReplacementPreservesRunsAndRejectsSplitEmoji() {
    var document = RichTextDocument("A😀BC", runs: [.init(location: 3, length: 2, style: .bold)])
    XCTAssertFalse(document.select(NSRange(location: 2, length: 1)))
    XCTAssertTrue(document.select(NSRange(location: 1, length: 2)))
    XCTAssertTrue(document.replaceSelection(with: "Z"))
    XCTAssertEqual(document.text, "AZBC")
    XCTAssertEqual(document.runs, [.init(location: 2, length: 2, style: .bold)])
    _ = document.select(NSRange(location: 2, length: 2))
    document.toggle(.bold)
    XCTAssertEqual(document.runs, [])
    document.toggle(.italic)
    XCTAssertEqual(document.runs.first?.style, .italic)
  }
}
