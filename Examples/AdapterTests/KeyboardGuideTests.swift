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
  func testSwiftUIObserverUpdatesPostureWithoutRecreatingWindow() async throws {
    let scene = try XCTUnwrap(
      UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
    let window = UIWindow(windowScene: scene)
    window.frame = CGRect(x: 0, y: 0, width: 390, height: 700)
    let fixture = KeyboardObservationFixture()
    let controller = UIHostingController(rootView: KeyboardObservationView(fixture: fixture))
    let previous = scene.windows.first(where: \.isKeyWindow)
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.loadViewIfNeeded()
    controller.view.layoutIfNeeded()
    defer {
      window.isHidden = true
      previous?.makeKey()
    }
    for _ in 0..<50 {
      if fixture.latest?.context.bounds.width == 390 { break }
      try? await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertEqual(fixture.latest?.context.posture, .compact)
    XCTAssertEqual(fixture.latest?.context.bounds.width, 390)
    let surface = fixture.latest?.context.surfaceID
    fixture.expanded = true
    controller.view.setNeedsLayout()
    controller.view.layoutIfNeeded()
    for _ in 0..<50 {
      if fixture.latest?.context.posture == .expanded { break }
      try? await Task.sleep(for: .milliseconds(100))
    }
    XCTAssertEqual(fixture.latest?.context.surfaceID, surface)
    XCTAssertEqual(fixture.latest?.context.posture, .expanded)
    XCTAssertEqual(fixture.latest?.availableRegions.count, 2)
  }

}

@MainActor private final class KeyboardObservationFixture: ObservableObject {
  @Published var expanded = false
  var latest: KeyboardViewportSnapshot?
}

private struct KeyboardObservationView: View {
  @ObservedObject var fixture: KeyboardObservationFixture
  var body: some View {
    Color.clear.frame(width: 390, height: 600).background {
      BehaviorKeyboardObserver(
        posture: fixture.expanded ? .expanded : .compact,
        reservedRegions: fixture.expanded ? [BehaviorRect(x: 189, width: 12, height: 600)] : []
      ) { fixture.latest = $0 }
    }
  }
}
