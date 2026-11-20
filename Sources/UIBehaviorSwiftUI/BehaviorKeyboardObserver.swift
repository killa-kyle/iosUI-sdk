#if os(iOS)
  import SwiftUI
  import UIKit
  import UIBehaviorCore
  import UIBehaviorNative

  /// Attach as a background to the viewport whose remaining keyboard overlap you need.
  public struct BehaviorKeyboardObserver: UIViewRepresentable {
    private let posture: ViewportPosture
    private let regions: [BehaviorRect]
    private let followsUndocked: Bool
    private let changed: (KeyboardViewportSnapshot) -> Void
    public init(
      posture: ViewportPosture = .unspecified, reservedRegions: [BehaviorRect] = [],
      followsUndockedKeyboard: Bool = false,
      changed: @escaping (KeyboardViewportSnapshot) -> Void
    ) {
      self.posture = posture
      regions = reservedRegions
      followsUndocked = followsUndockedKeyboard
      self.changed = changed
    }
    public func makeUIView(context: Context) -> UIView { KeyboardGuideProbe() }
    public func updateUIView(_ uiView: UIView, context: Context) {
      guard let probe = uiView as? KeyboardGuideProbe else { return }
      probe.changed = changed
      probe.configure(
        posture: posture, reservedRegions: regions,
        followsUndockedKeyboard: followsUndocked)
    }
    public static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
      (uiView as? KeyboardGuideProbe)?.changed = nil
    }
    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context)
      -> CGSize?
    {
      CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }
  }
#endif
