import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI
import UIBehaviorUIKit
import UIKit
import XCTest

@MainActor final class KeyboardGuideTests: XCTestCase {
  func testNativeObserverTracksReparentingAndExplicitReservedRegions() async {
    let first = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    let second = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 700))
    first.rootViewController = UIViewController()
    second.rootViewController = UIViewController()
    first.isHidden = false
    second.isHidden = false
    defer {
      first.isHidden = true
      second.isHidden = true
    }
    let observer = BehaviorKeyboardGuideView(frame: first.bounds)
    first.rootViewController!.view.addSubview(observer)
    observer.configure(posture: .compact)
    first.layoutIfNeeded()
    observer.layoutIfNeeded()
    let initial = observer.snapshot.context
    XCTAssertEqual(initial.posture, .compact)
    XCTAssertEqual(initial.bounds.width, 390)
    XCTAssertFalse(observer.isUserInteractionEnabled)
    second.rootViewController!.view.addSubview(observer)
    observer.frame = second.bounds
    observer.configure(
      posture: .expanded, reservedRegions: [BehaviorRect(x: 294, width: 12, height: 700)])
    second.layoutIfNeeded()
    observer.layoutIfNeeded()
    XCTAssertNotEqual(observer.snapshot.context.surfaceID, initial.surfaceID)
    XCTAssertEqual(observer.snapshot.context.bounds.width, 600)
    XCTAssertEqual(observer.snapshot.context.posture, .expanded)
    XCTAssertEqual(observer.snapshot.availableRegions.count, 2)
  }
  func testSwiftUIObserverUpdatesPostureWithoutRecreatingWindow() async {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 700))
    var latest: KeyboardViewportSnapshot?
    let makeRoot: (ViewportPosture, [BehaviorRect]) -> AnyView = { posture, regions in
      AnyView(
        Color.clear.frame(width: 390, height: 600).background {
          BehaviorKeyboardObserver(posture: posture, reservedRegions: regions) { latest = $0 }
        })
    }
    let controller = UIHostingController(rootView: makeRoot(.compact, []))
    window.rootViewController = controller
    window.isHidden = false
    defer { window.isHidden = true }
    for _ in 0..<50 {
      if latest?.context.bounds.width == 390 { break }
      try? await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertEqual(latest?.context.posture, .compact)
    XCTAssertEqual(latest?.context.bounds.width, 390)
    let surface = latest?.context.surfaceID
    controller.rootView = makeRoot(.expanded, [BehaviorRect(x: 189, width: 12, height: 600)])
    for _ in 0..<50 {
      if latest?.context.posture == .expanded { break }
      try? await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertEqual(latest?.context.surfaceID, surface)
    XCTAssertEqual(latest?.context.posture, .expanded)
    XCTAssertEqual(latest?.availableRegions.count, 2)
  }

}
