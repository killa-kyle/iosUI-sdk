public struct CarouselBehavior: Sendable, Equatable {
  public let count: Int
  public let loops: Bool
  public private(set) var index: Int
  public private(set) var playing = false
  private var lastTick: Double?
  public init(count: Int, index: Int = 0, loops: Bool = false) {
    precondition(count >= 0)
    self.count = count
    self.loops = loops
    self.index = min(max(0, index), max(0, count - 1))
  }
  public var canGoNext: Bool { count > 1 && (loops || index < count - 1) }
  public var canGoPrevious: Bool { count > 1 && (loops || index > 0) }
  public mutating func select(_ index: Int) {
    guard (0..<count).contains(index) else { return }
    self.index = index
  }
  public mutating func next() { if canGoNext { index = index < count - 1 ? index + 1 : 0 } }
  public mutating func previous() { if canGoPrevious { index = index > 0 ? index - 1 : count - 1 } }
  public mutating func swipe(
    translation: Double, velocity: Double = 0, extent: Double,
    rightToLeft: Bool = false
  ) {
    guard [translation, velocity, extent].allSatisfy(\.isFinite), extent > 0 else { return }
    pause()
    let direction = rightToLeft ? -1.0 : 1.0
    if translation * direction < -extent * 0.2 || velocity * direction < -500 {
      next()
    } else if translation * direction > extent * 0.2 || velocity * direction > 500 {
      previous()
    }
  }
  public mutating func play(now: Double) {
    guard now.isFinite else { return }
    playing = true
    lastTick = now
  }
  public mutating func pause() {
    playing = false
    lastTick = nil
  }
  /// Caller owns its clock/lifecycle. No background timer survives a removed view.
  public mutating func tick(now: Double, interval: Double, reduceMotion: Bool = false) {
    guard playing, !reduceMotion, now.isFinite, interval.isFinite, interval > 0, let lastTick else {
      return
    }
    if now < lastTick {
      self.lastTick = now
      return
    }
    guard now - lastTick >= interval else { return }
    if canGoNext {
      next()
      self.lastTick = now
    } else {
      pause()
    }
  }
}
