#if canImport(UIKit)
  import UIKit
  import UIBehaviorCore

  /// Shared UIKit bridge used by the public SwiftUI and UIKit adapters.
  package final class KeyboardGuideProbe: UIView {
    package var changed: ((KeyboardViewportSnapshot) -> Void)?
    private var posture: ViewportPosture = .unspecified
    private var reservedRegions: [BehaviorRect] = []
    private var surfaceID = UUID().uuidString
    private weak var observedWindow: UIWindow?
    private var model = KeyboardViewport()
    private var reported: KeyboardViewportSnapshot?
    private let marker = UIView()
    package var snapshot: KeyboardViewportSnapshot { model.snapshot }
    private var logicalBounds: BehaviorRect {
      BehaviorRect(
        x: Double(bounds.minX), y: Double(bounds.minY),
        width: Double(bounds.width), height: Double(bounds.height))
    }
    package init() {
      super.init(frame: .zero)
      isUserInteractionEnabled = false
      accessibilityElementsHidden = true
      keyboardLayoutGuide.usesBottomSafeArea = false
      marker.translatesAutoresizingMaskIntoConstraints = false
      addSubview(marker)
      NSLayoutConstraint.activate([
        marker.topAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
        marker.leadingAnchor.constraint(equalTo: keyboardLayoutGuide.leadingAnchor),
        marker.trailingAnchor.constraint(equalTo: keyboardLayoutGuide.trailingAnchor),
        marker.heightAnchor.constraint(equalToConstant: 0),
      ])
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    package func configure(
      posture: ViewportPosture, reservedRegions: [BehaviorRect], followsUndockedKeyboard: Bool
    ) {
      self.posture = posture
      self.reservedRegions = reservedRegions
      keyboardLayoutGuide.followsUndockedKeyboard = followsUndockedKeyboard
      _ = model.updateContext(
        surfaceID: surfaceID, bounds: logicalBounds,
        posture: posture, reservedRegions: reservedRegions)
      setNeedsLayout()
    }
    package override func didMoveToWindow() {
      super.didMoveToWindow()
      if observedWindow !== window {
        observedWindow = window
        surfaceID = UUID().uuidString
        reported = nil
        _ = model.updateContext(
          surfaceID: surfaceID, bounds: logicalBounds,
          posture: posture, reservedRegions: reservedRegions)
      }
      setNeedsLayout()
    }
    package override func layoutSubviews() {
      super.layoutSubviews()
      guard
        let context = model.updateContext(
          surfaceID: surfaceID, bounds: logicalBounds,
          posture: posture, reservedRegions: reservedRegions)
      else { return }
      let frame = keyboardLayoutGuide.layoutFrame
      let keyboard =
        window == nil
        ? nil
        : BehaviorRect(
          x: Double(frame.minX), y: Double(frame.minY),
          width: Double(frame.width), height: Double(frame.height))
      guard model.observeKeyboard(keyboard, context: context) else { return }
      let value = model.snapshot
      guard value != reported else { return }
      reported = value
      // UIKit can reparent/resize before this turn executes. Reject that older observation.
      DispatchQueue.main.async { [weak self] in
        guard let self, self.logicalBounds == value.context.bounds,
          self.model.snapshot == value
        else { return }
        self.changed?(value)
      }
    }
  }
#endif
