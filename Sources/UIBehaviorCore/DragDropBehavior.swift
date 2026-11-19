import Foundation

public struct DragPayload: Sendable, Equatable, Codable {
  public let id: String
  public let type: String
  public init(id: String, type: String) {
    self.id = id
    self.type = type
  }
}
public struct DropTarget: Sendable {
  public let id: String
  public var rect: BehaviorRect
  public var acceptedTypes: Set<String>
  public var enabled: Bool
  public init(id: String, rect: BehaviorRect, acceptedTypes: Set<String>, enabled: Bool = true) {
    self.id = id
    self.rect = rect
    self.acceptedTypes = acceptedTypes
    self.enabled = enabled
  }
}
public struct DropReceipt: Sendable, Equatable {
  public let payload: DragPayload
  public let target: String
  public let point: BehaviorPoint
}
/// Local drag admission/hit-testing. Returning a receipt does not mutate app data.
public struct DragDropBehavior: Sendable {
  public private(set) var payload: DragPayload?
  public private(set) var point = BehaviorPoint(0, 0)
  public private(set) var target: String?
  public init() {}
  @discardableResult public mutating func begin(
    _ payload: DragPayload, at point: BehaviorPoint,
    enabled: Bool = true
  ) -> Bool {
    guard self.payload == nil, enabled, !payload.id.isEmpty, point.x.isFinite, point.y.isFinite
    else { return false }
    self.payload = payload
    self.point = point
    target = nil
    return true
  }
  public mutating func update(at point: BehaviorPoint, targets: [DropTarget]) {
    guard let payload, point.x.isFinite, point.y.isFinite else { return }
    self.point = point
    // A smaller accepted zone wins, so nested drop targets do not both receive a drop.
    target =
      targets.enumerated().filter {
        $0.element.enabled && $0.element.id != payload.id
          && $0.element.acceptedTypes.contains(payload.type)
          && $0.element.rect.contains(point)
      }.min {
        let a = $0.element.rect.width * $0.element.rect.height
        let b = $1.element.rect.width * $1.element.rect.height
        return a == b ? $0.offset < $1.offset : a < b
      }?.element.id
  }
  public mutating func drop(targets: [DropTarget]) -> DropReceipt? {
    update(at: point, targets: targets)
    defer { cancel() }
    guard let payload, let target else { return nil }
    return DropReceipt(payload: payload, target: target, point: point)
  }
  public mutating func cancel() {
    payload = nil
    target = nil
  }
  public static func autoScroll(
    pointer: Double, length: Double, edge: Double = 32,
    maximum: Double = 16
  ) -> Double {
    guard [pointer, length, edge, maximum].allSatisfy(\.isFinite), length > 0, edge > 0,
      maximum >= 0
    else { return 0 }
    let edge = min(edge, length / 2)
    if pointer < edge { return -maximum * min(1, max(0, (edge - pointer) / edge)) }
    if pointer > length - edge { return maximum * min(1, max(0, (pointer - length + edge) / edge)) }
    return 0
  }
}
