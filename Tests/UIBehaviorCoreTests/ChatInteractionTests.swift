import XCTest

@testable import UIBehaviorCore

final class ChatInteractionTests: XCTestCase {
  func testStreamCoalescingAndUrgentReplacementFenceOldCompletions() throws {
    var state = StreamScrollCoordinator<String>()
    let first = try XCTUnwrap(state.request(.latest, reason: .stream))
    for _ in 0..<1000 { XCTAssertNil(state.request(.latest, reason: .stream)) }
    let resized = try XCTUnwrap(state.request(.latest, reason: .keyboard, replacingPending: true))
    XCTAssertFalse(state.isCurrent(first))
    XCTAssertFalse(state.finish(first))
    XCTAssertTrue(state.isCurrent(resized))
    XCTAssertTrue(state.finish(resized))
    XCTAssertNil(state.pending)
  }

  func testTouchesPauseFollowingAndDraggingPreservesReadingIntent() throws {
    var state = StreamScrollCoordinator<String>()
    let first = try XCTUnwrap(state.request(.latest, reason: .stream))
    state.observePhase(.tracking, atLatest: true)
    XCTAssertFalse(state.isCurrent(first))
    XCTAssertTrue(state.followsLatest)
    XCTAssertNil(state.request(.latest, reason: .stream))
    state.observePhase(.idle, atLatest: true)
    XCTAssertNotNil(state.request(.latest, reason: .stream))
    state.observePhase(.dragging, atLatest: false)
    state.observePhase(.decelerating, atLatest: false)
    XCTAssertFalse(state.followsLatest)
    XCTAssertNil(state.pending)
    state.observePhase(.idle, atLatest: false)
    state.observePhase(.animating, atLatest: true)
    state.observePhase(.idle, atLatest: true)
    XCTAssertFalse(state.followsLatest, "Programmatic layout cannot steal reading intent")
    state.observePhase(.dragging, atLatest: true)
    state.observePhase(.idle, atLatest: true)
    XCTAssertTrue(state.followsLatest)
  }

  func testReadingAnchorSurvivesHistoryAndViewportChanges() throws {
    var state = StreamScrollCoordinator<String>(followsLatest: false)
    let anchor = try XCTUnwrap(ReadingAnchor(id: "message", top: -20, height: 120))
    state.remember(anchor)
    let request = try XCTUnwrap(state.restoreAnchor(viewportHeight: 520, reason: .history))
    state.remember(try XCTUnwrap(ReadingAnchor(id: "older", top: 0, height: 40)))
    XCTAssertEqual(state.readingAnchor, anchor)
    XCTAssertEqual(request.target, .item("message", alignment: -0.05))
    XCTAssertNil(state.request(.latest, reason: .stream))
    XCTAssertTrue(state.finish(request))
    let next = try XCTUnwrap(state.restoreAnchor(viewportHeight: 320))
    XCTAssertEqual(next.target, .item("message", alignment: -0.1))
    state.followLatest()
    XCTAssertFalse(state.isCurrent(next))
    XCTAssertNil(state.readingAnchor)
  }

  func testScrollRequestScopesAndInvalidGeometry() throws {
    var a = StreamScrollCoordinator<String>()
    var b = StreamScrollCoordinator<String>()
    let first = try XCTUnwrap(a.request(.latest, reason: .initial))
    _ = b.request(.latest, reason: .initial)
    XCTAssertFalse(b.isCurrent(first))
    a.cancel()
    XCTAssertNil(a.request(.item("a", alignment: .nan), reason: .viewport))
    XCTAssertNil(ReadingAnchor(id: "a", top: .infinity, height: 20))
    XCTAssertNil(ReadingAnchor(id: "a", top: 0, height: 0))
    let anchor = try XCTUnwrap(ReadingAnchor(id: "a", top: -10, height: 200))
    XCTAssertEqual(anchor.alignment(in: 200), 0)
    XCTAssertNil(anchor.alignment(in: .nan))
  }

  func testTwoPassRestorationUsesFreshRowHeightAndRejectsOldLayout() throws {
    var state = StreamScrollCoordinator<String>(followsLatest: false)
    state.remember(try XCTUnwrap(ReadingAnchor(id: "row", top: -40, height: 100)))
    let viewport = BehaviorRect(width: 300, height: 400)
    let locate = try XCTUnwrap(state.beginAnchorRestoration(in: viewport, layoutRevision: 7))
    XCTAssertEqual(locate.target, .item("row", alignment: 0))
    XCTAssertTrue(state.finish(locate))
    XCTAssertTrue(state.isRestoringAnchor)
    let fresh = try XCTUnwrap(ReadingAnchor(id: "row", top: 0, height: 200))
    let stale = try XCTUnwrap(
      ReadingAnchorMeasurement(anchor: fresh, viewport: viewport, layoutRevision: 6))
    XCTAssertNil(state.measureRestoration(stale))
    let measurement = try XCTUnwrap(
      ReadingAnchorMeasurement(anchor: fresh, viewport: viewport, layoutRevision: 7))
    let align = try XCTUnwrap(state.measureRestoration(measurement))
    XCTAssertEqual(align.target, .item("row", alignment: -0.2))
    XCTAssertTrue(state.finish(align))
    XCTAssertFalse(state.isRestoringAnchor)
  }

  func testCancelledOrDeletedRestoreCannotConsumeLaterMeasurements() throws {
    var state = StreamScrollCoordinator<String>(followsLatest: false)
    let anchor = try XCTUnwrap(ReadingAnchor(id: "row", top: -20, height: 100))
    state.remember(anchor)
    let viewport = BehaviorRect(width: 300, height: 400)
    _ = state.beginAnchorRestoration(in: viewport, layoutRevision: 1)
    let measured = try XCTUnwrap(
      ReadingAnchorMeasurement(anchor: anchor, viewport: viewport, layoutRevision: 1))
    state.observePhase(.dragging, atLatest: false)
    XCTAssertFalse(state.isRestoringAnchor)
    XCTAssertNil(state.measureRestoration(measured))
    state.observePhase(.idle, atLatest: false)
    _ = state.beginAnchorRestoration(in: viewport, layoutRevision: 2)
    state.reconcile(availableIDs: [])
    XCTAssertNil(state.restorationTarget)
    XCTAssertNil(state.pending)
    XCTAssertFalse(state.followsLatest)
  }

  func testAnchorMemoryFreezesBeforeNewGeometryCanReplaceReadingPosition() throws {
    var memory = ReadingAnchorMemory<String>()
    let oldBounds = BehaviorRect(width: 600, height: 700)
    let anchor = try XCTUnwrap(ReadingAnchor(id: "read", top: -30, height: 100))
    let first = try XCTUnwrap(
      ReadingAnchorMeasurement(anchor: anchor, viewport: oldBounds, layoutRevision: 1))
    XCTAssertTrue(memory.record(first))
    let newBounds = BehaviorRect(width: 300, height: 400)
    let other = try XCTUnwrap(ReadingAnchor(id: "other", top: -10, height: 200))
    let changed = try XCTUnwrap(
      ReadingAnchorMeasurement(anchor: other, viewport: newBounds, layoutRevision: 1))
    XCTAssertFalse(memory.record(changed))
    XCTAssertTrue(memory.isFrozen)
    XCTAssertEqual(memory.anchor, anchor)
    memory.resume(in: newBounds, layoutRevision: 2)
    XCTAssertFalse(memory.record(first), "Late pre-resize frames must not replace the anchor")
    let current = try XCTUnwrap(
      ReadingAnchorMeasurement(anchor: other, viewport: newBounds, layoutRevision: 2))
    XCTAssertTrue(memory.record(current))
    XCTAssertFalse(memory.isFrozen)
    XCTAssertEqual(memory.anchor, other)
    memory.freeze()
    XCTAssertFalse(memory.record(anchor))
    memory.clear()
    XCTAssertNil(memory.anchor)
  }

  func testActivityChoicesSurviveRevisionsAndParentCollapse() {
    var state = ActivityDisclosureStore<String>()
    XCTAssertTrue(state.observe("child", phase: .running, revision: 1))
    state["child"].toggle(running: true)
    state["parent"].toggle(running: false)
    state["parent"].toggle(running: false)
    for revision in 2...1000 {
      XCTAssertTrue(state.observe("child", phase: .running, revision: UInt64(revision)))
      XCTAssertFalse(state["child"].expanded(running: true))
    }
    XCTAssertTrue(state.observe("child", phase: .completed, revision: 1001))
    XCTAssertFalse(state.observe("child", phase: .running, revision: 1000))
    XCTAssertEqual(state.phase(for: "child"), .completed)
    XCTAssertFalse(state["child"].expanded(running: false))
    state.retain(["child"])
    XCTAssertEqual(state.count, 1)
    XCTAssertEqual(state["child"].explicit, false)
  }

  func testObservedRunningActivityStaysReadableAfterCompletion() {
    var state = ActivityDisclosureStore<String>()
    state.observe("a", phase: .running, revision: 1)
    state.observe("a", phase: .failed, revision: 2)
    XCTAssertTrue(state["a"].expanded(running: false))
    XCTAssertEqual(state["a"].toggle(running: false), .closed)
    XCTAssertFalse(state["a"].expanded(running: true))
    state.removeAll()
    XCTAssertEqual(state.count, 0)
  }

  func testKeyboardAndHingeProduceSeparateUnobscuredPanes() throws {
    var state = KeyboardViewport()
    let bounds = BehaviorRect(width: 400, height: 800)
    let hinge = BehaviorRect(x: 195, width: 10, height: 800)
    let context = try XCTUnwrap(
      state.updateContext(
        surfaceID: "scene", bounds: bounds,
        posture: .expanded, reservedRegions: [hinge]))
    XCTAssertTrue(
      state.observeKeyboard(BehaviorRect(y: 600, width: 400, height: 200), context: context))
    XCTAssertEqual(state.snapshot.bottomInset, 200)
    XCTAssertEqual(state.snapshot.availableRegions.count, 2)
    XCTAssertEqual(state.snapshot.availableRegions.reduce(0) { $0 + $1.width * $1.height }, 234_000)
    XCTAssertTrue(
      state.snapshot.availableRegions.allSatisfy { ViewportGeometry.intersection($0, hinge) == nil }
    )
  }

  func testFloatingKeyboardRevealsFocusWithoutShrinkingWholeViewport() throws {
    var state = KeyboardViewport()
    let context = try XCTUnwrap(
      state.updateContext(surfaceID: "scene", bounds: BehaviorRect(width: 400, height: 800)))
    state.observeKeyboard(BehaviorRect(x: 100, y: 350, width: 200, height: 150), context: context)
    XCTAssertEqual(state.snapshot.bottomInset, 0)
    let delta = try XCTUnwrap(
      state.snapshot.adjustment(toReveal: BehaviorRect(x: 150, y: 375, width: 60, height: 50)))
    XCTAssertEqual(delta, BehaviorPoint(0, -75))
    XCTAssertNil(state.snapshot.adjustment(toReveal: BehaviorRect(width: 450, height: 50)))
  }

  func testKeyboardContextFencesOldWindowSizeAndPostureCallbacks() throws {
    var state = KeyboardViewport()
    let bounds = BehaviorRect(width: 400, height: 800)
    let first = try XCTUnwrap(
      state.updateContext(surfaceID: "cover", bounds: bounds, posture: .compact))
    let inner = try XCTUnwrap(
      state.updateContext(surfaceID: "inner", bounds: bounds, posture: .expanded))
    XCTAssertFalse(
      state.observeKeyboard(BehaviorRect(y: 600, width: 400, height: 200), context: first))
    XCTAssertEqual(state.snapshot.bottomInset, 0)
    state.observeKeyboard(BehaviorRect(y: 600, width: 400, height: 200), context: inner)
    let tabletop = try XCTUnwrap(
      state.updateContext(surfaceID: "inner", bounds: bounds, posture: .tabletop))
    XCTAssertNotEqual(tabletop.revision, inner.revision)
    XCTAssertFalse(state.observeKeyboard(nil, context: inner))
    XCTAssertEqual(state.snapshot.bottomInset, 0)
    XCTAssertEqual(state.snapshot.context.posture, .tabletop)
  }

  func testAlreadyAdjustedViewportDoesNotAddKeyboardInsetAgain() throws {
    var state = KeyboardViewport()
    let context = try XCTUnwrap(
      state.updateContext(surfaceID: "scene", bounds: BehaviorRect(width: 400, height: 600)))
    state.observeKeyboard(BehaviorRect(y: 600, width: 400, height: 200), context: context)
    XCTAssertEqual(state.snapshot.bottomInset, 0)
    XCTAssertEqual(state.snapshot.availableRegions, [context.bounds])
    XCTAssertFalse(state.observeKeyboard(BehaviorRect(width: .nan, height: 200), context: context))
    XCTAssertNil(
      state.updateContext(surfaceID: "scene", bounds: BehaviorRect(width: .infinity, height: 800)))
    XCTAssertEqual(state.context, context)
  }
}
