import XCTest

@testable import UIBehaviorCore

final class AgentProtocolTests: XCTestCase {
  @MainActor func testAuthorizationCannotReenterOrChangeRevisionBeforeDispatch() throws {
    var agent: BehaviorAgent!
    var reentryRejected = false
    var calls = 0
    agent = BehaviorAgent { _, step in
      do { try agent.act(step, revision: agent.snapshot().revision) } catch AgentProtocolError
        .reentrant
      { reentryRejected = true } catch {}
      return true
    }
    let read = { AgentComponent(ref: "one", component: "button", label: "One", actions: ["press"]) }
    try agent.register(ref: "one", read: read, perform: { _ in calls += 1 })
    try agent.act(AgentStep(ref: "one", action: "press"), revision: agent.snapshot().revision)
    XCTAssertTrue(reentryRejected)
    XCTAssertEqual(calls, 1)
    var changing: BehaviorAgent!
    changing = BehaviorAgent { _, _ in
      changing.invalidate()
      return true
    }
    try changing.register(ref: "one", read: read, perform: { _ in calls += 1 })
    XCTAssertThrowsError(
      try changing.act(
        AgentStep(ref: "one", action: "press"), revision: changing.snapshot().revision))
    XCTAssertEqual(calls, 1)
  }
  @MainActor func testOptionalWebArgumentsAndExplicitHostAuthority() throws {
    let step = try JSONDecoder().decode(
      AgentStep.self, from: Data(#"{"ref":"next","action":"press"}"#.utf8))
    XCTAssertEqual(step.args, [])
    var calls = 0
    let denied = BehaviorAgent { _, _ in false }
    try denied.register(
      ref: "next",
      read: { AgentComponent(ref: "next", component: "button", label: "Next", actions: ["press"]) },
      perform: { _ in calls += 1 })
    XCTAssertThrowsError(try denied.act(step, revision: denied.snapshot().revision))
    XCTAssertEqual(calls, 0)
  }
  @MainActor func testAgentRejectsStaleAmbiguousPrivateAndReadonlyActions() throws {
    var calls = 0
    let agent = BehaviorAgent { _, _ in true }
    for id in ["a", "b"] {
      try agent.register(
        ref: id,
        read: { AgentComponent(ref: id, component: "button", label: "Same", actions: ["press"]) },
        perform: { _ in calls += 1 })
    }
    let snapshot = agent.snapshot()
    XCTAssertThrowsError(
      try agent.act(AgentStep(ref: "Same", action: "press"), revision: snapshot.revision))
    try agent.act(AgentStep(ref: "a", action: "press"), revision: snapshot.revision)
    XCTAssertEqual(calls, 1)
    XCTAssertThrowsError(
      try agent.act(AgentStep(ref: "a", action: "press"), revision: snapshot.revision))
    try agent.register(
      ref: "secret",
      read: {
        AgentComponent(
          ref: "secret", component: "field", label: "Hidden token",
          state: ["value": .string("credential")], actions: ["setValue"], sensitive: true)
      }, perform: { _ in calls += 1 })
    try agent.register(
      ref: "readonly",
      read: {
        AgentComponent(
          ref: "readonly", component: "field", label: "Read only", actions: ["setValue"],
          readOnly: true)
      }, perform: { _ in calls += 1 })
    let data = try JSONEncoder().encode(agent.snapshot())
    XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("credential"))
    XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("Hidden token"))
    XCTAssertThrowsError(
      try agent.act(
        AgentStep(ref: "secret", action: "setValue"), revision: agent.snapshot().revision))
    XCTAssertThrowsError(
      try agent.act(
        AgentStep(ref: "readonly", action: "setValue"), revision: agent.snapshot().revision))
    XCTAssertEqual(calls, 1)
  }
  @MainActor func testAgentRemovalAndHostChangeInvalidateSnapshot() throws {
    let agent = BehaviorAgent { _, _ in true }
    try agent.register(
      ref: "one",
      read: { AgentComponent(ref: "one", component: "button", label: "One", actions: ["press"]) },
      perform: { _ in })
    XCTAssertThrowsError(
      try agent.register(
        ref: "one", read: { AgentComponent(ref: "one", component: "button", label: "One") },
        perform: { _ in }))
    let before = agent.snapshot()
    agent.invalidate()
    XCTAssertThrowsError(
      try agent.act(AgentStep(ref: "one", action: "press"), revision: before.revision))
    agent.unregister("one")
    XCTAssertTrue(agent.snapshot().components.isEmpty)
  }
}
