import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

@MainActor private final class AgentDemoState: ObservableObject {
  @Published var carousel = CarouselBehavior(count: 3)
  @Published var output = "Capture a snapshot, then dispatch a registered action."
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
    let snapshot = agent.snapshot()
    do {
      try agent.act(AgentStep(ref: "demo-carousel", action: "next"), revision: snapshot.revision)
      output = "Agent moved to slide \(carousel.index+1)"
    } catch { output = String(describing: error) }
  }
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
      Button("Agent next") { model.next() }
      Text(model.output).font(.caption.monospaced()).textSelection(.enabled)
        .accessibilityIdentifier("agent-result")
      Text("Local, opt-in actions only. This demo does not connect to an AI provider.").font(
        .caption)
    }.onChange(of: model.carousel.index) { _, _ in model.agent.invalidate() }
  }
}
