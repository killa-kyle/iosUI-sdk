import UIBehaviorCore
import UIBehaviorUIKit
import UIKit
import XCTest

@MainActor final class ExtendedAdapterTests: XCTestCase {
  func testTextKitAppliesOverlappingNativeTraitsAndPreservesSelection() {
    let view = BehaviorRichTextView(frame: .zero, textContainer: nil)
    let document = RichTextDocument(
      "Native",
      runs: [
        RichTextRun(location: 0, length: 6, style: .bold),
        RichTextRun(location: 0, length: 6, style: .italic),
      ], selection: NSRange(location: 1, length: 2))
    view.setDocument(document)
    let font = view.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
    XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitBold), true)
    XCTAssertEqual(font?.fontDescriptor.symbolicTraits.contains(.traitItalic), true)
    XCTAssertEqual(view.selectedRange, document.selection)
    XCTAssertEqual(Set(view.document.runs.map(\.style)), [.bold, .italic])
  }
  func testCropExportsPhysicalPixelsAfterQuarterTurn() {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 2
    let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 10), format: format).image {
      context in
      UIColor.systemBlue.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 20, height: 10))
    }
    var crop = CropSelection(width: 40, height: 20, aspect: 1)
    crop.rotateClockwise()
    let result = BehaviorImageCrop.image(image, selection: crop)
    XCTAssertEqual(result?.cgImage?.width, 20)
    XCTAssertEqual(result?.cgImage?.height, 20)
    XCTAssertEqual(result?.imageOrientation, .up)
  }
  func testUIKitHostingPreservesStateAndReportsWindowPoints() {
    let controller = BehaviorUIKit.calendar(
      CalendarSelection(month: try! CalendarDate("2026-11-01")))
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = controller
    window.makeKeyAndVisible()
    controller.loadViewIfNeeded()
    controller.view.layoutIfNeeded()
    XCTAssertEqual(controller.children.count, 1)
    XCTAssertEqual(controller.state.visibleMonth.description, "2026-11-01")
    let rect = BehaviorMeasurement.frame(of: controller.view)
    XCTAssertNotNil(rect)
    XCTAssertEqual(rect?.width, Double(controller.view.bounds.width))
    window.isHidden = true
  }
}
