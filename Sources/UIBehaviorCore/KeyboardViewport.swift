import Foundation

/// Explicit host information. Window dimensions alone do not identify a physical posture.
public enum ViewportPosture: String, Sendable, Codable {
  case unspecified, compact, expanded, tabletop
}

public struct ViewportContext: Sendable, Equatable {
  public let surfaceID: String
  public let revision: UInt64
  public let bounds: BehaviorRect
  public let posture: ViewportPosture
  public let reservedRegions: [BehaviorRect]
}

public struct KeyboardViewportSnapshot: Sendable, Equatable {
  public let context: ViewportContext
  public let keyboard: BehaviorRect?
  public var bottomInset: Double {
    guard let keyboard, let overlap = ViewportGeometry.intersection(context.bounds, keyboard),
      overlap.width >= context.bounds.width - 1,
      overlap.maxY >= context.bounds.maxY - 1
    else { return 0 }
    return overlap.height
  }
  public var availableRegions: [BehaviorRect] {
    ViewportGeometry.availableRegions(
      in: context.bounds,
      excluding: context.reservedRegions + (keyboard.map { [$0] } ?? []))
  }
  /// Smallest translation into one available region; useful for floating keyboards and editors.
  public func adjustment(toReveal rect: BehaviorRect) -> BehaviorPoint? {
    guard rect.isValid else { return nil }
    return availableRegions.compactMap { region -> BehaviorPoint? in
      guard rect.width <= region.width, rect.height <= region.height else { return nil }
      return BehaviorPoint(
        min(max(rect.x, region.x), region.maxX - rect.width) - rect.x,
        min(max(rect.y, region.y), region.maxY - rect.height) - rect.y)
    }.min { abs($0.x) + abs($0.y) < abs($1.x) + abs($1.y) }
  }
}

/// Context tokens reject delayed keyboard observations from a previous window, size or posture.
public struct KeyboardViewport: Sendable, Equatable {
  public private(set) var context = ViewportContext(
    surfaceID: "detached", revision: 0, bounds: BehaviorRect(width: 0, height: 0),
    posture: .unspecified, reservedRegions: [])
  private var keyboard: BehaviorRect?
  public init() {}
  public var snapshot: KeyboardViewportSnapshot { .init(context: context, keyboard: keyboard) }
  @discardableResult public mutating func updateContext(
    surfaceID: String, bounds: BehaviorRect, posture: ViewportPosture = .unspecified,
    reservedRegions: [BehaviorRect] = []
  ) -> ViewportContext? {
    guard !surfaceID.isEmpty, bounds.isValid else { return nil }
    let regions = reservedRegions.filter { $0.isValid && $0.width > 0 && $0.height > 0 }
    if context.surfaceID != surfaceID || context.bounds != bounds || context.posture != posture
      || context.reservedRegions != regions
    {
      context = ViewportContext(
        surfaceID: surfaceID, revision: context.revision &+ 1,
        bounds: bounds, posture: posture, reservedRegions: regions)
      keyboard = nil
    }
    return context
  }
  @discardableResult public mutating func observeKeyboard(
    _ frame: BehaviorRect?, context observed: ViewportContext
  ) -> Bool {
    guard observed == context else { return false }
    if let frame, !frame.isValid { return false }
    keyboard = frame.flatMap { $0.width > 0 && $0.height > 0 ? $0 : nil }
    return true
  }
}

public enum ViewportGeometry {
  public static func intersection(_ a: BehaviorRect, _ b: BehaviorRect) -> BehaviorRect? {
    guard a.isValid, b.isValid else { return nil }
    let x = max(a.x, b.x)
    let y = max(a.y, b.y)
    let right = min(a.maxX, b.maxX)
    let bottom = min(a.maxY, b.maxY)
    guard right > x, bottom > y else { return nil }
    return BehaviorRect(x: x, y: y, width: right - x, height: bottom - y)
  }
  /// Subtract native reserved regions (including hinges) and keyboard intersections.
  public static func availableRegions(
    in bounds: BehaviorRect, excluding occlusions: [BehaviorRect]
  ) -> [BehaviorRect] {
    guard bounds.isValid, bounds.width > 0, bounds.height > 0 else { return [] }
    var regions = [bounds]
    for occlusion in occlusions where occlusion.isValid {
      regions = regions.flatMap { region -> [BehaviorRect] in
        guard let overlap = intersection(region, occlusion) else { return [region] }
        // SwiftUI and UIKit can round the same native edge differently. Keep a rounded shared edge from creating an extra region.
        let tolerance = min(0.001, min(region.width, region.height) * 0.001)
        let x = abs(overlap.x - region.x) < tolerance ? region.x : overlap.x
        let y = abs(overlap.y - region.y) < tolerance ? region.y : overlap.y
        let maxX = abs(overlap.maxX - region.maxX) < tolerance ? region.maxX : overlap.maxX
        let maxY = abs(overlap.maxY - region.maxY) < tolerance ? region.maxY : overlap.maxY
        let cut = BehaviorRect(x: x, y: y, width: maxX - x, height: maxY - y)
        let candidates = [
          BehaviorRect(x: region.x, y: region.y, width: region.width, height: cut.y - region.y),
          BehaviorRect(
            x: region.x, y: cut.maxY, width: region.width, height: region.maxY - cut.maxY),
          BehaviorRect(x: region.x, y: cut.y, width: cut.x - region.x, height: cut.height),
          BehaviorRect(x: cut.maxX, y: cut.y, width: region.maxX - cut.maxX, height: cut.height),
        ]
        return candidates.filter { $0.width > 0 && $0.height > 0 }
      }
    }
    return regions
  }
}
