import Foundation

public struct BehaviorPoint: Sendable, Codable, Equatable {
  public var x: Double
  public var y: Double
  public init(_ x: Double, _ y: Double) {
    self.x = x
    self.y = y
  }
}
public struct BehaviorRect: Sendable, Codable, Equatable {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double
  public init(x: Double = 0, y: Double = 0, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
  public var isValid: Bool {
    [x, y, width, height, x + width, y + height].allSatisfy(\.isFinite) && width >= 0 && height >= 0
  }
  public var maxX: Double { x + width }
  public var maxY: Double { y + height }
  public func contains(_ point: BehaviorPoint) -> Bool {
    isValid && point.x.isFinite && point.y.isFinite && point.x >= x && point.x <= maxX
      && point.y >= y && point.y <= maxY
  }
}

public enum ResizeHandle: String, CaseIterable, Sendable, Codable {
  case n, e, s, w, ne, nw, se, sw, move
}

public struct ResizeBehavior: Sendable {
  public private(set) var rect: BehaviorRect
  public var bounds: BehaviorRect
  public var minimum: BehaviorPoint
  public var maximum: BehaviorPoint
  public var aspect: Double?
  private var origin: BehaviorRect?
  private var handle: ResizeHandle?
  public init(
    rect: BehaviorRect, bounds: BehaviorRect,
    minimum: BehaviorPoint = BehaviorPoint(1, 1), maximum: BehaviorPoint? = nil,
    aspect: Double? = nil
  ) {
    precondition(
      rect.isValid && bounds.isValid && rect.x >= bounds.x && rect.y >= bounds.y
        && rect.maxX <= bounds.maxX && rect.maxY <= bounds.maxY)
    self.rect = rect
    self.bounds = bounds
    self.minimum = minimum
    self.maximum = maximum ?? BehaviorPoint(bounds.width, bounds.height)
    self.aspect = aspect
  }
  public mutating func begin(_ handle: ResizeHandle) {
    origin = rect
    self.handle = handle
  }
  /// Translation is measured from gesture start, not the preceding event.
  public mutating func update(dx: Double, dy: Double) {
    guard let start = origin, let handle, dx.isFinite, dy.isFinite, bounds.isValid,
      minimum.x.isFinite, minimum.y.isFinite, maximum.x.isFinite, maximum.y.isFinite
    else { return }
    if handle == .move {
      rect.x = min(max(bounds.x, start.x + dx), bounds.maxX - start.width)
      rect.y = min(max(bounds.y, start.y + dy), bounds.maxY - start.height)
      return
    }
    let west = [.w, .nw, .sw].contains(handle)
    let north = [.n, .nw, .ne].contains(handle)
    let east = [.e, .ne, .se].contains(handle)
    let south = [.s, .sw, .se].contains(handle)
    var width = start.width + (east ? dx : west ? -dx : 0)
    var height = start.height + (south ? dy : north ? -dy : 0)
    let limitW = min(maximum.x, west ? start.maxX - bounds.x : bounds.maxX - start.x)
    let limitH = min(maximum.y, north ? start.maxY - bounds.y : bounds.maxY - start.y)
    if let ratio = aspect, ratio.isFinite, ratio > 0 {
      if east || west { height = width / ratio } else { width = height * ratio }
      let lower = max(0, minimum.x, minimum.y * ratio)
      let upper = max(0, min(limitW, limitH * ratio))
      width = min(max(width, min(lower, upper)), upper)
      height = width / ratio
    } else {
      width = min(max(width, max(0, min(minimum.x, limitW))), max(0, limitW))
      height = min(max(height, max(0, min(minimum.y, limitH))), max(0, limitH))
    }
    rect = BehaviorRect(
      x: west ? start.maxX - width : start.x,
      y: north ? start.maxY - height : start.y, width: width, height: height)
  }
  public mutating func commit() {
    origin = nil
    handle = nil
  }
  public mutating func cancel() {
    if let origin { rect = origin }
    commit()
  }
}

/// Crop coordinates are pixels in the oriented image, never screen points.
public struct CropSelection: Sendable {
  public private(set) var rotation = 0
  public private(set) var resize: ResizeBehavior
  public var rect: BehaviorRect { resize.rect }
  public init(width: Double, height: Double, aspect: Double? = nil) {
    precondition(width.isFinite && height.isFinite && width >= 1 && height >= 1)
    let bounds = BehaviorRect(width: width, height: height)
    var rect = bounds
    if let aspect, aspect.isFinite, aspect > 0 {
      rect.width = min(width, height * aspect)
      rect.height = rect.width / aspect
    }
    resize = ResizeBehavior(rect: rect, bounds: bounds, aspect: aspect)
  }
  public mutating func begin(_ handle: ResizeHandle) { resize.begin(handle) }
  public mutating func setResize(_ value: ResizeBehavior) {
    guard value.bounds == resize.bounds, value.aspect == resize.aspect, value.rect.isValid else {
      return
    }
    resize = value
  }
  public mutating func update(dx: Double, dy: Double) { resize.update(dx: dx, dy: dy) }
  public mutating func commit() { resize.commit() }
  public mutating func cancel() { resize.cancel() }
  public mutating func rotateClockwise() {
    resize.cancel()
    let old = rect
    let bounds = resize.bounds
    let turned = BehaviorRect(
      x: bounds.height - old.maxY, y: old.x, width: old.height, height: old.width)
    rotation = (rotation + 90) % 360
    resize = ResizeBehavior(
      rect: turned, bounds: BehaviorRect(width: bounds.height, height: bounds.width),
      aspect: resize.aspect.map { 1 / $0 })
  }
}
