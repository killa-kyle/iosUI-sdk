#if canImport(UIKit)
  import UIKit
  import UIBehaviorCore

  /// Retain this binding alongside your native slider or stepper.
  @MainActor
  public final class BehaviorValueBinding: NSObject {
    public private(set) var state: BoundedValue
    public var onChange: ((BoundedValue) -> Void)?
    private weak var slider: UISlider?
    private weak var stepper: UIStepper?

    public init(_ state: BoundedValue, slider: UISlider) {
      self.state = state
      self.slider = slider
      super.init()
      slider.minimumValue = Float(state.bounds.lowerBound)
      slider.maximumValue = Float(state.bounds.upperBound)
      slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
      render()
    }
    public init(_ state: BoundedValue, stepper: UIStepper) {
      self.state = state
      self.stepper = stepper
      super.init()
      stepper.minimumValue = state.bounds.lowerBound
      stepper.maximumValue = state.bounds.upperBound
      stepper.stepValue = state.step
      stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)
      render()
    }
    public func set(_ value: Double) {
      state.set(value)
      render()
    }
    private func render() {
      slider?.value = Float(state.value)
      stepper?.value = state.value
      slider?.accessibilityValue = state.value.formatted()
      stepper?.accessibilityValue = state.value.formatted()
    }
    @objc private func sliderChanged() {
      guard let slider else { return }
      state.set(Double(slider.value))
      render()
      onChange?(state)
    }
    @objc private func stepperChanged() {
      guard let stepper else { return }
      state.set(stepper.value)
      render()
      onChange?(state)
    }
  }
#endif
