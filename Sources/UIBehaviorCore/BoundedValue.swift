import Foundation

/// Shared numeric rules for sliders, steppers, ratings and resize handles.
public struct BoundedValue: Sendable, Equatable {
    public let bounds: ClosedRange<Double>
    public let step: Double
    public private(set) var value: Double

    public init(_ value: Double, in bounds: ClosedRange<Double>, step: Double = 1) {
        precondition(bounds.lowerBound.isFinite && bounds.upperBound.isFinite)
        precondition(step.isFinite && step > 0 && value.isFinite)
        self.bounds = bounds; self.step = step; self.value = bounds.lowerBound
        set(value)
    }
    public mutating func set(_ proposed: Double) {
        guard proposed.isFinite else { return }
        let clamped = min(max(proposed, bounds.lowerBound), bounds.upperBound)
        let snapped = bounds.lowerBound + ((clamped - bounds.lowerBound) / step).rounded() * step
        value = min(max(snapped, bounds.lowerBound), bounds.upperBound)
    }
    public mutating func increment() { set(value + step) }
    public mutating func decrement() { set(value - step) }
    public var fraction: Double {
        let span = bounds.upperBound - bounds.lowerBound
        return span > 0 ? (value - bounds.lowerBound) / span : 0
    }
    public mutating func setFraction(_ fraction: Double) {
        guard fraction.isFinite else { return }
        set(bounds.lowerBound + min(max(fraction, 0), 1) * (bounds.upperBound - bounds.lowerBound))
    }
}
