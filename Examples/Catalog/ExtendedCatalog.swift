import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI
import UIBehaviorUIKit
import UIKit

enum ExtendedStory: String, CaseIterable, Identifiable {
  case calendar, color, tree, grid, drag, resize, crop, carousel, editor, menu, overlays,
    measurements, agent
  var id: String { rawValue }
  var title: String {
    switch self {
    case .calendar: "Calendar & range"
    case .color: "Color & contrast"
    case .tree: "Tree navigation"
    case .grid: "Grid & rectangle selection"
    case .drag: "Drag & drop"
    case .resize: "Two-dimensional resize"
    case .crop: "Image crop & rotation"
    case .carousel: "Carousel"
    case .editor: "Rich text editor"
    case .menu: "Native menus"
    case .overlays: "Nested overlays"
    case .measurements: "Native measurements"
    case .agent: "Agent observe & act"
    }
  }
}
struct ExtendedCatalog: View {
  var body: some View {
    List(ExtendedStory.allCases) { story in
      NavigationLink(story.title) { BehaviorDemo(story: story) }
        .accessibilityIdentifier("story-" + story.rawValue)
    }.navigationTitle("Behavior catalog")
  }
}

struct BehaviorDemo: View {
  let story: ExtendedStory
  @State private var calendar = CalendarSelection(
    month: try! CalendarDate("2026-11-01"), mode: .range,
    bounds: (try! CalendarDate("2026-11-01"))...(try! CalendarDate("2026-12-31")),
    disabled: [try! CalendarDate("2026-11-03")])
  @State private var color = ColorValue(hex: "#4F46E5")!
  @State private var hex = "#4F46E5"
  @State private var tree = try! TreeNavigation([
    BehaviorTreeNode("Library", children: [BehaviorTreeNode("Photos"), BehaviorTreeNode("Notes")]),
    BehaviorTreeNode("Unavailable", disabled: true),
  ])
  @State private var grid = GridNavigation(rows: 3, columns: 4, disabled: [GridCell(0, 1)])
  @State private var drag = DragDropBehavior()
  @State private var dropped = "No drop"
  @State private var resize = ResizeBehavior(
    rect: BehaviorRect(x: 40, y: 40, width: 120, height: 100),
    bounds: BehaviorRect(width: 300, height: 220))
  @State private var crop = CropSelection(width: 300, height: 200, aspect: 1)
  @State private var cropped: UIImage?
  @State private var carousel = CarouselBehavior(count: 3)
  @State private var editor = RichTextDocument("Hello native editor")
  @State private var menu = MenuBehavior([
    BehaviorMenuItem("copy", title: "Copy sample"),
    BehaviorMenuItem("favorite", title: "Favorite", kind: .toggle),
    BehaviorMenuItem(
      "more", title: "More", kind: .submenu,
      children: [
        BehaviorMenuItem("compact", title: "Compact", kind: .radio(group: "density")),
        BehaviorMenuItem("comfortable", title: "Comfortable", kind: .radio(group: "density")),
      ]), BehaviorMenuItem("disabled", title: "Unavailable", enabled: false),
  ])
  @State private var action = "No action"
  @State private var overlays = OverlayStack()
  @AccessibilityFocusState private var restored: String?
  @State private var measurement = BehaviorRect(width: 0, height: 0)
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) { demo }
        .padding().frame(maxWidth: 600)
    }.navigationTitle(story.title)
  }
  @ViewBuilder private var demo: some View {
    switch story {
    case .calendar:
      BehaviorCalendar($calendar)
      Text(
        calendar.selected.map { $0.lowerBound.description + "…" + $0.upperBound.description }
          ?? "No dates"
      )
      .accessibilityIdentifier("calendar-result")
      Text("November 3 is disabled. A range cannot cross it.").font(.caption)
      NavigationLink("UIKit calendar controller") { UIKitCalendarDemo() }
    case .color:
      BehaviorColorPicker("Choose color", value: $color)
      TextField("Hex color", text: $hex).textInputAutocapitalization(.never)
      Button("Apply hex") { if let next = ColorValue(hex: hex) { color = next } }
      Text(color.hex(includeAlpha: true)).accessibilityIdentifier("color-result")
      Text(
        "Contrast on white: \(color.contrast(against: ColorValue(red: 1,green: 1,blue: 1)),specifier: "%.2f"):1"
      )
    case .tree:
      BehaviorTree($tree, label: { $0 })
      Text("Selected: " + tree.selection.selected.sorted().joined(separator: ", "))
        .accessibilityIdentifier("tree-result")
    case .grid:
      BehaviorGrid($grid) { "R\($0.row+1) C\($0.column+1)" }
      Button("Extend to R3 C4") { grid.focus(GridCell(2, 3), extending: true) }
      Text("Selected cells: \(grid.selected.count)").accessibilityIdentifier("grid-result")
    case .drag:
      Text("Drag me").padding().background(.blue.opacity(0.15)).accessibilityIdentifier("drag-card")
        .behaviorDraggable(DragPayload(id: "card", type: "card"), session: $drag)
      Text("Archive drop zone").frame(maxWidth: .infinity, minHeight: 100).border(.secondary)
        .accessibilityIdentifier("drop-archive")
        .behaviorDropTarget("archive", acceptedTypes: ["card"], session: $drag) { receipt in
          dropped = "Moved \(receipt.payload.id) to \(receipt.target)"
        }
      Button("Move to archive") { accessibleDrop() }
      Text(dropped).accessibilityIdentifier("drop-result")
    case .resize:
      BehaviorResizable($resize) { Color.blue.opacity(0.15) }.frame(height: 220)
      Text("\(Int(resize.rect.width)) × \(Int(resize.rect.height))").accessibilityIdentifier(
        "resize-result")
    case .crop:
      BehaviorCropper($crop, image: Image(uiImage: Self.sampleImage)).frame(height: 260)
      Button("Rotate crop") { crop.rotateClockwise() }
      Button("Export crop") { cropped = BehaviorImageCrop.image(Self.sampleImage, selection: crop) }
      if let cropped {
        Image(uiImage: cropped).resizable().scaledToFit().frame(height: 120)
        Text("Exported \(Int(cropped.size.width)) × \(Int(cropped.size.height))")
          .accessibilityIdentifier("crop-result")
      }
    case .carousel:
      BehaviorCarousel($carousel) { index in
        Text(["Mountains", "Harbor", "Forest"][index]).font(.title)
          .frame(maxWidth: .infinity, minHeight: 140).background(.blue.opacity(0.15))
      }
    case .editor:
      BehaviorRichTextEditor("Rich text", document: $editor).frame(height: 220).border(.secondary)
      Button("Bold first word") {
        _ = editor.select(NSRange(location: 0, length: min(5, editor.text.utf16.count)))
        editor.toggle(.bold)
      }
      Text("Bold runs: \(editor.runs.filter { $0.style == .bold }.count)").accessibilityIdentifier(
        "editor-format")
      Text(editor.text).accessibilityIdentifier("editor-result")
    case .menu:
      BehaviorMenu("Open menu", model: $menu) { action = $0 }
      Text("Action: " + action).accessibilityIdentifier("menu-result")
      Text("Favorites: " + menu.checked.sorted().joined(separator: ", "))
    case .overlays:
      BehaviorOverlayHost($overlays) {
        Button("Open inspector") {
          _ = overlays.present(BehaviorOverlay("inspector", restoreFocus: "inspector"))
        }
        .accessibilityFocused($restored, equals: "inspector")
      } overlay: { entry in
        VStack(spacing: 24) {
          Text(entry.id).font(.title)
          if entry.id == "inspector" {
            Button("Open nested overlay") {
              _ = overlays.present(
                BehaviorOverlay("confirmation", parent: entry.id, restoreFocus: "nested"))
            }
            .accessibilityFocused($restored, equals: "nested")
          }
          Button("Close " + entry.id) { overlays.dismiss(entry.id) }
        }.padding()
      } restoreFocus: {
        restored = $0
      }
      Text("Overlay count: \(overlays.entries.count)").accessibilityIdentifier("overlay-result")
    case .measurements:
      Text("Measured native view").padding().background(.blue.opacity(0.15))
        .behaviorMeasure { measurement = $0 }
      Text("\(Int(measurement.width)) × \(Int(measurement.height)) points")
        .accessibilityIdentifier("measurement-result")
    case .agent: AgentCatalogDemo()
    }
  }
  private func accessibleDrop() {
    drag.cancel()
    _ = drag.begin(DragPayload(id: "card", type: "card"), at: BehaviorPoint(20, 20))
    let target = DropTarget(
      id: "archive", rect: BehaviorRect(width: 100, height: 100), acceptedTypes: ["card"])
    if let receipt = drag.drop(targets: [target]) {
      dropped = "Moved \(receipt.payload.id) to \(receipt.target)"
    }
  }
  static var sampleImage: UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200), format: format).image {
      c in
      UIColor.systemBlue.setFill()
      c.fill(CGRect(x: 0, y: 0, width: 150, height: 200))
      UIColor.systemOrange.setFill()
      c.fill(CGRect(x: 150, y: 0, width: 150, height: 200))
    }
  }
}
private struct UIKitCalendarDemo: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIViewController {
    BehaviorUIKit.calendar(CalendarSelection(month: try! CalendarDate("2026-11-01")))
  }
  func updateUIViewController(_ controller: UIViewController, context: Context) {}
}
