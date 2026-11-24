import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

@MainActor private final class AgentDemoState: ObservableObject {
  @Published var carousel = CarouselBehavior(count: 3)
  @Published var output = "Capture a snapshot, then dispatch a registered action."
  @Published var waiting = false
  private var pending: Task<Void, Never>?
  @Published private var decision: AsyncStream<Bool>.Continuation?
  var canApprove: Bool { decision != nil }
  var bounds: BehaviorRect?
  let agent: BehaviorAgent
  var captured: AgentSnapshot?
  init() {
    agent = BehaviorAgent { component, step in
      component.confirm == nil && component.ref == "demo-carousel"
        && ["next", "previous"].contains(step.action)
    }
    try! agent.register(
      ref: "demo-carousel",
      read: { [weak self] in
        AgentComponent(
          ref: "demo-carousel", component: "carousel", label: "Scenery",
          state: ["index": .number(Double(self?.carousel.index ?? 0))],
          actions: ["next", "previous"], bounds: self?.bounds)
      },
      perform: { [weak self] step in
        guard step.args.isEmpty else { throw AgentProtocolError.unavailableAction }
        if step.action == "next" { self?.carousel.next() } else { self?.carousel.previous() }
      })
  }
  func capture() {
    captured = agent.snapshot()
    output = String(decoding: try! JSONEncoder().encode(captured), as: UTF8.self)
  }
  func next() {
    guard !waiting else { return }
    let snapshot = agent.snapshot()
    do {
      try agent.act(AgentStep(ref: "demo-carousel", action: "next"), revision: snapshot.revision)
      output = "Agent moved to slide \(carousel.index+1)"
    } catch { output = String(describing: error) }
  }
  func requestNext() {
    guard !waiting else { return }
    waiting = true
    output = "Waiting for approval"
    let revision = agent.snapshot().revision
    pending = Task {
      defer {
        pending = nil
        decision = nil
        waiting = false
      }
      do {
        try await agent.act(
          AgentStep(ref: "demo-carousel", action: "next"), revision: revision,
          confirming: { [weak self] _, _ in
            guard let self else { return false }
            let (answers, response) = AsyncStream.makeStream(of: Bool.self)
            decision = response
            var iterator = answers.makeAsyncIterator()
            return await iterator.next() ?? false
          })
        output = "Agent moved to slide \(carousel.index + 1)"
      } catch is CancellationError {
        output = "Agent action cancelled"
      } catch {
        output = "Agent action refused"
      }
    }
  }

  func approve() {
    decision?.yield(true)
    decision?.finish()
  }

  func stop() { pending?.cancel() }

}
struct AgentCatalogDemo: View {
  @StateObject private var model = AgentDemoState()
  var body: some View {
    VStack(spacing: 20) {
      BehaviorCarousel($model.carousel) { Text("Scenery \($0+1)").font(.title) }
        .behaviorMeasure {
          model.bounds = $0
          model.agent.invalidate()
        }
      Button("Capture agent snapshot") { model.capture() }
      Button("Agent next") { model.next() }.disabled(model.waiting)
      Button("Request agent next") { model.requestNext() }.disabled(model.waiting)
      if model.waiting {
        HStack {
          Button("Approve agent action") { model.approve() }.disabled(!model.canApprove)
          Button("Stop agent action") { model.stop() }
        }
      }
      Text(model.output).font(.caption.monospaced()).textSelection(.enabled)
        .accessibilityIdentifier("agent-result")
      Text("Local, opt-in actions only. This demo does not connect to an AI provider.").font(
        .caption)
    }.onDisappear { model.stop() }
      .onChange(of: model.carousel.index) { _, _ in model.agent.invalidate() }
  }
}
