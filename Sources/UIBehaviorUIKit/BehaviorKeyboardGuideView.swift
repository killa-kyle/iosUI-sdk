#if canImport(UIKit)
  import UIKit
  import UIBehaviorCore
  import UIBehaviorNative

  /// A transparent, noninteractive keyboard-layout observer for a UIKit container.
  public final class BehaviorKeyboardGuideView: UIView {
    private let probe = KeyboardGuideProbe()
    public var onChange: ((KeyboardViewportSnapshot) -> Void)? {
      get { probe.changed }
      set { probe.changed = newValue }
    }
    public var snapshot: KeyboardViewportSnapshot { probe.snapshot }
    public override init(frame: CGRect) {
      super.init(frame: frame)
      isUserInteractionEnabled = false
      accessibilityElementsHidden = true
      probe.translatesAutoresizingMaskIntoConstraints = false
      addSubview(probe)
      NSLayoutConstraint.activate([
        probe.leadingAnchor.constraint(equalTo: leadingAnchor),
        probe.trailingAnchor.constraint(equalTo: trailingAnchor),
        probe.topAnchor.constraint(equalTo: topAnchor),
        probe.bottomAnchor.constraint(equalTo: bottomAnchor),
      ])
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    public func configure(
      posture: ViewportPosture = .unspecified, reservedRegions: [BehaviorRect] = [],
      followsUndockedKeyboard: Bool = false
    ) {
      probe.configure(
        posture: posture, reservedRegions: reservedRegions,
        followsUndockedKeyboard: followsUndockedKeyboard)
    }
  }
#endif
