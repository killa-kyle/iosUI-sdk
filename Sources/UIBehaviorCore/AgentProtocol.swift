import Foundation

public indirect enum AgentValue: Sendable, Equatable, Codable {
  case string(String)
  case number(Double)
  case bool(Bool)
  case array([Self])
  case object([String: Self])
  case null
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if c.decodeNil() {
      self = .null
    } else if let v = try? c.decode(Bool.self) {
      self = .bool(v)
    } else if let v = try? c.decode(Double.self) {
      self = .number(v)
    } else if let v = try? c.decode(String.self) {
      self = .string(v)
    } else if let v = try? c.decode([Self].self) {
      self = .array(v)
    } else {
      self = .object(try c.decode([String: Self].self))
    }
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .null: try c.encodeNil()
    case .string(let v): try c.encode(v)
    case .number(let v): try c.encode(v)
    case .bool(let v): try c.encode(v)
    case .array(let v): try c.encode(v)
    case .object(let v): try c.encode(v)
    }
  }
}

/// Same ref/action/args step shape as the upstream web agent. Transport belongs to the host.
public struct AgentStep: Sendable, Codable, Equatable {
  public let ref: String
  public let action: String
  public let args: [AgentValue]
  public init(ref: String, action: String, args: [AgentValue] = []) {
    self.ref = ref
    self.action = action
    self.args = args
  }
  private enum CodingKeys: CodingKey { case ref, action, args }
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    ref = try c.decode(String.self, forKey: .ref)
    action = try c.decode(String.self, forKey: .action)
    args = try c.decodeIfPresent([AgentValue].self, forKey: .args) ?? []
  }
}
public struct AgentComponent: Sendable, Codable, Equatable {
  public let ref: String
  public let component: String
  public var label: String
  public var state: [String: AgentValue]
  public var actions: [String]
  public var bounds: BehaviorRect?
  public var enabled: Bool
  public var readOnly: Bool
  public var sensitive: Bool
  public var confirm: String?
  public init(
    ref: String, component: String, label: String, state: [String: AgentValue] = [:],
    actions: [String] = [], bounds: BehaviorRect? = nil, enabled: Bool = true,
    readOnly: Bool = false, sensitive: Bool = false, confirm: String? = nil
  ) {
    self.ref = ref
    self.component = component
    self.label = label
    self.state = state
    self.actions = actions
    self.bounds = bounds
    self.enabled = enabled
    self.readOnly = readOnly
    self.sensitive = sensitive
    self.confirm = confirm
  }
  public var observable: Self {
    var copy = self
    if !enabled || readOnly || sensitive { copy.actions = [] }
    if sensitive {
      copy.label = "Private control"
      copy.state = [:]
      copy.confirm = nil
    }
    if copy.bounds?.isValid != true { copy.bounds = nil }
    return copy
  }
}
public struct AgentSnapshot: Sendable, Codable {
  public let revision: UInt64
  public let coordinateSpace: String
  public let components: [AgentComponent]
}
public enum AgentProtocolError: Error {
  case duplicateRef, staleSnapshot, unknownRef, ambiguousLabel, unavailableAction, denied, reentrant
}

/// Opt-in local dispatch. No network server, injected JS or implicit authority.
@MainActor public final class BehaviorAgent {
  public typealias Action = (_ component: AgentComponent, _ step: AgentStep) -> Bool
  public typealias Confirmation =
    @MainActor (_ component: AgentComponent, _ step: AgentStep) async -> Bool
  private struct Registration {
    let read: () -> AgentComponent
    let perform: (AgentStep) throws -> Void
  }
  private var entries: [String: Registration] = [:]
  private var revision: UInt64 = 0
  private var dispatching = false
  private let authorize: Action
  public init(authorize: @escaping Action) { self.authorize = authorize }
  public func register(
    ref: String, read: @escaping () -> AgentComponent,
    perform: @escaping (AgentStep) throws -> Void
  ) throws {
    guard !ref.isEmpty, entries[ref] == nil, read().ref == ref else {
      throw AgentProtocolError.duplicateRef
    }
    entries[ref] = Registration(read: read, perform: perform)
    invalidate()
  }
  public func unregister(_ ref: String) {
    entries.removeValue(forKey: ref)
    invalidate()
  }
  /// Call after host-driven state or geometry changes, including changes not made by this agent.
  public func invalidate() { revision &+= 1 }
  public func snapshot(coordinateSpace: String = "window-points") -> AgentSnapshot {
    AgentSnapshot(
      revision: revision, coordinateSpace: coordinateSpace,
      components: entries.keys.sorted().compactMap { entries[$0]?.read().observable })
  }
  public func query(label: String, offset: Int = 0, limit: Int = 50) -> [AgentComponent] {
    Array(
      snapshot().components.filter { $0.label.localizedCaseInsensitiveContains(label) }
        .dropFirst(max(0, offset)).prefix(min(100, max(0, limit))))
  }
  public func act(_ step: AgentStep, revision expected: UInt64) throws {
    guard !dispatching else { throw AgentProtocolError.reentrant }
    let component = try resolve(step, revision: expected)
    dispatching = true
    defer { finishDispatch() }
    try perform(step, on: component, revision: expected)
  }

  /// Waits for host confirmation. Cancel the calling Task to stop waiting.
  /// A late approval cannot dispatch an action, even if the callback ignores cancellation.
  public func act(
    _ step: AgentStep, revision expected: UInt64, confirming confirmation: @escaping Confirmation
  ) async throws {
    try Task.checkCancellation()
    guard !dispatching else { throw AgentProtocolError.reentrant }
    let component = try resolve(step, revision: expected)
    dispatching = true
    defer { finishDispatch() }

    let (decisions, response) = AsyncStream.makeStream(of: Bool.self)
    let canonicalStep = AgentStep(ref: component.ref, action: step.action, args: step.args)
    let prompt = Task { @MainActor in
      guard !Task.isCancelled else { return }
      response.yield(await confirmation(component, canonicalStep))
      response.finish()
    }
    defer {
      response.finish()
      prompt.cancel()
    }
    var iterator = decisions.makeAsyncIterator()
    let approved = await iterator.next()
    try Task.checkCancellation()
    guard approved == true else { throw AgentProtocolError.denied }
    guard try resolve(step, revision: expected) == component else {
      throw AgentProtocolError.staleSnapshot
    }
    try perform(step, on: component, revision: expected, cancellable: true)
  }

  private func resolve(_ step: AgentStep, revision expected: UInt64) throws -> AgentComponent {
    guard expected == revision else { throw AgentProtocolError.staleSnapshot }
    let components = snapshot().components
    let matches = components.filter { $0.ref == step.ref }
    let labels = matches.isEmpty ? components.filter { $0.label == step.ref } : matches
    guard let component = labels.first else { throw AgentProtocolError.unknownRef }
    guard labels.count == 1 else { throw AgentProtocolError.ambiguousLabel }
    guard component.actions.contains(step.action), entries[component.ref] != nil else {
      throw AgentProtocolError.unavailableAction
    }
    return component
  }

  private func perform(
    _ step: AgentStep, on component: AgentComponent, revision expected: UInt64,
    cancellable: Bool = false
  ) throws {
    guard authorize(component, step) else { throw AgentProtocolError.denied }
    guard expected == revision, let entry = entries[component.ref] else {
      throw AgentProtocolError.staleSnapshot
    }
    if cancellable { try Task.checkCancellation() }
    try entry.perform(AgentStep(ref: component.ref, action: step.action, args: step.args))
  }

  private func finishDispatch() {
    dispatching = false
    invalidate()
  }
}
