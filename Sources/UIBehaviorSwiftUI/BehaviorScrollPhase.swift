import SwiftUI
import UIBehaviorCore

public struct BehaviorScrollObservation: Sendable {
  public let phase: ScrollInteractionPhase
  /// Native geometry on iOS 18+/macOS 15+; nil in the drag-only compatibility path.
  public let atLatest: Bool?
}

private struct ScrollPhaseObserver: ViewModifier {
  let changed: (BehaviorScrollObservation) -> Void
  @GestureState private var dragging = false
  @ViewBuilder func body(content: Content) -> some View {
    if #available(iOS 18, macOS 15, *) {
      content.onScrollPhaseChange { _, phase, context in
        let mapped: ScrollInteractionPhase
        switch phase {
        case .idle: mapped = .idle
        case .tracking: mapped = .tracking
        case .interacting: mapped = .dragging
        case .decelerating: mapped = .decelerating
        case .animating: mapped = .animating
        @unknown default: mapped = .tracking
        }
        changed(
          BehaviorScrollObservation(
            phase: mapped,
            atLatest: context.geometry.visibleRect.maxY >= context.geometry.contentSize.height - 1))
      }
    } else {
      content.simultaneousGesture(
        DragGesture(minimumDistance: 1).updating($dragging) { _, active, _ in
          active = true
        }
      ).onChange(of: dragging) { _, active in
        changed(BehaviorScrollObservation(phase: active ? .dragging : .idle, atLatest: nil))
      }
    }
  }
}

extension View {
  /// Apply directly to one scroll view. Native phases distinguish touch tracking and deceleration.
  public func behaviorScrollPhase(
    _ changed: @escaping (BehaviorScrollObservation) -> Void
  ) -> some View {
    modifier(ScrollPhaseObserver(changed: changed))
  }
}
