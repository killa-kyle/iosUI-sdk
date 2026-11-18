/// Pan and zoom math in logical points. Wire to native MagnifyGesture/UIPinchGestureRecognizer.
public struct Viewport: Sendable, Equatable {
    public private(set) var scale: Double
    public private(set) var x: Double
    public private(set) var y: Double
    public let scaleBounds: ClosedRange<Double>

    public init(scale: Double = 1, x: Double = 0, y: Double = 0,
                scaleBounds: ClosedRange<Double> = 0.25...8) {
        precondition(scaleBounds.lowerBound > 0 && scaleBounds.upperBound.isFinite)
        precondition(scale.isFinite && x.isFinite && y.isFinite)
        self.scaleBounds = scaleBounds
        self.scale = min(max(scale, scaleBounds.lowerBound), scaleBounds.upperBound)
        self.x = x; self.y = y
    }
    public mutating func pan(dx: Double, dy: Double) {
        guard dx.isFinite && dy.isFinite else { return }
        x += dx; y += dy
    }
    /// Anchor remains at the same screen point while scale changes.
    public mutating func zoom(to proposed: Double, anchorX: Double, anchorY: Double) {
        guard proposed.isFinite && anchorX.isFinite && anchorY.isFinite else { return }
        let next = min(max(proposed, scaleBounds.lowerBound), scaleBounds.upperBound)
        let ratio = next / scale
        x = anchorX - (anchorX - x) * ratio
        y = anchorY - (anchorY - y) * ratio
        scale = next
    }
    public func contentPoint(screenX: Double, screenY: Double) -> (x: Double, y: Double) {
        ((screenX - x) / scale, (screenY - y) / scale)
    }
}
