import SwiftUI
import UIBehaviorCore

extension View {
  /// Report logical-point frames in an explicit SwiftUI coordinate space; no screen-pixel inference.
  public func behaviorMeasure(
    in space: CoordinateSpace = .global,
    onChange: @escaping (BehaviorRect) -> Void
  ) -> some View {
    background {
      GeometryReader { geometry in
        let frame = geometry.frame(in: space)
        Color.clear.onAppear { onChange(Self.behaviorRect(frame)) }
          .onChange(of: frame) { _, next in onChange(Self.behaviorRect(next)) }
      }.allowsHitTesting(false)
    }
  }
  private static func behaviorRect(_ frame: CGRect) -> BehaviorRect {
    BehaviorRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height)
  }
}
