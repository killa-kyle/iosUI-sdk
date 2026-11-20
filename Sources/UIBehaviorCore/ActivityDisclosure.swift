/// Presentation phases supplied by the host. The SDK never infers task completion.
public enum ActivityPhase: String, Sendable, Codable {
  case pending, running, completed, failed, cancelled, unknown
}
public enum ActivityDisclosureChange: Sendable { case opened, closed }

/// Explicit choices survive streaming updates; an observed active section stays open on completion.
public struct ActivityDisclosure: Sendable, Equatable {
  private var disclosure: Disclosure?
  private var observedRunning = false
  public var explicit: Bool? { disclosure?.isOpen }
  public init() {}
  public func expanded(running: Bool) -> Bool { explicit ?? (running || observedRunning) }
  public mutating func observe(running: Bool) {
    if running { observedRunning = true }
  }
  @discardableResult public mutating func toggle(running: Bool) -> ActivityDisclosureChange {
    var value = disclosure ?? Disclosure(isOpen: expanded(running: running))
    value.toggle()
    disclosure = value
    return value.isOpen ? .opened : .closed
  }
}

/// Keep this store above deferred/collapsed rows. Prune against the full model, not visible rows.
public struct ActivityDisclosureStore<ID: Hashable & Sendable>: Sendable {
  private struct Record: Sendable {
    var disclosure = ActivityDisclosure()
    var revision: UInt64?
    var phase: ActivityPhase = .pending
  }
  private var records: [ID: Record] = [:]
  public init() {}
  public var count: Int { records.count }
  public subscript(id: ID) -> ActivityDisclosure {
    get { records[id]?.disclosure ?? ActivityDisclosure() }
    set { records[id, default: Record()].disclosure = newValue }
  }
  public func phase(for id: ID) -> ActivityPhase? { records[id]?.phase }
  @discardableResult public mutating func observe(
    _ id: ID, phase: ActivityPhase, revision: UInt64
  ) -> Bool {
    var record = records[id] ?? Record()
    guard record.revision.map({ revision > $0 }) ?? true else { return false }
    record.revision = revision
    record.phase = phase
    record.disclosure.observe(running: phase == .running)
    records[id] = record
    return true
  }
  public mutating func retain(_ ids: Set<ID>) {
    records = records.filter { ids.contains($0.key) }
  }
  public mutating func removeAll() { records.removeAll() }
}
