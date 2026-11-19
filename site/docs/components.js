import { foundations } from "./foundations.js";
export const components = [
  ...foundations,
  ...[
    {
      id: "calendar",
      title: "Calendar & dates",
      group: "Behaviors",
      kind: "calendar",
      description:
        "Civil-day arithmetic and bounded, disabled-aware date selection.",
      code: '@State private var dates = CalendarSelection(\n    month: try! CalendarDate("2026-11-01"), mode: .range,\n    disabled: [try! CalendarDate("2026-11-03")]\n)\nBehaviorCalendar($dates)',
      core: "CalendarDate · CalendarSelection",
      source: "UIBehaviorCore/CalendarDate.swift",
      notes: [
        "Gregorian dates have no time zone or daylight-saving offset.",
        "Month arithmetic clamps the day; disabled dates block range admission.",
        "The catalog contains a real SwiftUI calendar and UIKit-hosted counterpart.",
      ],
      uikit:
        'let calendar = BehaviorUIKit.calendar(\n    CalendarSelection(month: try! CalendarDate("2026-11-01"))\n) { state in print(state.selected as Any) }\n// Embed with normal UIViewController containment.',
      api: [
        [
          "model",
          "CalendarDate · CalendarSelection",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "color",
      title: "Color picker",
      group: "Behaviors",
      kind: "color",
      description:
        "sRGB values, HSV conversion, alpha composition and contrast.",
      code: '@State private var color = ColorValue(hex: "#4F46E5")!\nBehaviorColorPicker("Choose color", value: $color)\nlet hex = color.hex(includeAlpha: true)',
      core: "ColorValue",
      source: "UIBehaviorCore/ColorValue.swift",
      notes: [
        "The adapter uses the native platform color picker.",
        "Core math supports sRGB/HSV, not every CSS color space or named color.",
        "Composite translucent colors before evaluating contrast.",
      ],
      uikit:
        'let picker = BehaviorUIKit.color(ColorValue(hex: "#4F46E5")!) {\n    print($0.hex(includeAlpha: true))\n}',
      api: [
        [
          "model",
          "ColorValue",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "tree",
      title: "Tree navigation",
      group: "Behaviors",
      kind: "tree",
      description: "Visible preorder, expansion and stable-ID selection.",
      code: '@State private var tree = try! TreeNavigation([\n    BehaviorTreeNode("Library", children: [\n        BehaviorTreeNode("Photos"), BehaviorTreeNode("Notes")\n    ])\n])\nBehaviorTree($tree, label: { $0 })',
      core: "TreeNavigation<ID>",
      source: "UIBehaviorCore/SpatialNavigation.swift",
      notes: [
        "Left/right collapse, expand or move to a parent/child.",
        "Up/down skip disabled nodes. Collapsing a parent moves hidden focus to it.",
        "Range selection operates on the visible order.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "TreeNavigation<ID>",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "grid",
      title: "Grid navigation",
      group: "Behaviors",
      kind: "grid",
      description: "Two-dimensional focus and rectangular range selection.",
      code: '@State private var grid = GridNavigation(rows: 3, columns: 4,\n    disabled: [GridCell(0, 1)])\nBehaviorGrid($grid) { cell in\n    "R\\(cell.row + 1) C\\(cell.column + 1)"\n}',
      core: "GridNavigation · GridCell",
      source: "UIBehaviorCore/SpatialNavigation.swift",
      notes: [
        "Shift-arrow extends a rectangle from a stable anchor.",
        "Disabled cells are excluded; horizontal movement can follow RTL layout.",
        "Core range work is bounded; use native lazy/virtualized containers for large data.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "GridNavigation · GridCell",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "drag",
      title: "Drag & drop",
      group: "Behaviors",
      kind: "drag",
      description:
        "Admit a local payload, resolve a target and revalidate at drop time.",
      code: '@State private var drag = DragDropBehavior()\nText("Drag me")\n    .behaviorDraggable(DragPayload(id: "card", type: "card"), session: $drag)\nText("Archive")\n    .behaviorDropTarget("archive", acceptedTypes: ["card"], session: $drag) {\n        receipt in print(receipt.target)\n    }',
      core: "DragDropBehavior",
      source: "UIBehaviorCore/DragDropBehavior.swift",
      notes: [
        "Native transfer carries a local ID, not arbitrary objects or secrets.",
        "Smaller accepted targets win nested hit tests; disabled targets are rechecked.",
        "A receipt is an intent. The host performs and authorizes its data mutation.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "DragDropBehavior",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "resize",
      title: "2D resize",
      group: "Behaviors",
      kind: "resize",
      description:
        "Eight resize handles plus movement, with native input alternatives.",
      code: "@State private var box = ResizeBehavior(\n    rect: BehaviorRect(x: 40, y: 40, width: 120, height: 100),\n    bounds: BehaviorRect(width: 300, height: 220)\n)\nBehaviorResizable($box) { Color.blue.opacity(0.15) }",
      core: "ResizeBehavior",
      source: "UIBehaviorCore/ResizeBehavior.swift",
      notes: [
        "Limits include bounds, minimum/maximum dimensions and an optional aspect ratio.",
        "Gesture translations are measured from the start, avoiding cumulative drift.",
        "Cancel restores the starting rectangle; keyboard and accessibility actions are available.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "ResizeBehavior",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "crop",
      title: "Image cropper",
      group: "Behaviors",
      kind: "crop",
      description:
        "Pixel-space crop selection, quarter turns and oriented UIImage export.",
      code: '@State private var crop = CropSelection(width: 300, height: 200, aspect: 1)\nBehaviorCropper($crop, image: Image("Sample"))\n    .frame(height: 260)\n// Supply an app-owned image with matching pixel dimensions.',
      core: "CropSelection",
      source: "UIBehaviorCore/ResizeBehavior.swift",
      notes: [
        "Crop coordinates are image pixels, not screen points.",
        "UIImage export resolves image orientation before applying quarter-turn rotation.",
        "The browser preview illustrates the rectangle; use the native exporter for image pixels.",
      ],
      uikit:
        "let cropped: UIImage? = BehaviorImageCrop.image(\n    sourceImage, selection: crop\n)",
      api: [
        [
          "model",
          "CropSelection",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "carousel",
      title: "Carousel",
      group: "Behaviors",
      kind: "carousel",
      description:
        "Page selection, looping and native swipe/accessibility controls.",
      code: '@State private var pages = CarouselBehavior(count: 3)\nBehaviorCarousel($pages) { index in\n    Text(["Mountains", "Harbor", "Forest"][index])\n}',
      core: "CarouselBehavior",
      source: "UIBehaviorCore/CarouselBehavior.swift",
      notes: [
        "Empty and single-item collections stay bounded.",
        "The host owns autoplay time/lifecycle; tick respects Reduce Motion.",
        "Native interactive content remains usable inside a slide.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "CarouselBehavior",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "editor",
      title: "Rich text",
      group: "Behaviors",
      kind: "editor",
      description:
        "Native TextKit editing with attributed spans and UTF-16-safe state.",
      code: '@State private var document = RichTextDocument("Hello native editor")\nBehaviorRichTextEditor("Message", document: $document)\n    .frame(height: 220)',
      core: "RichTextDocument",
      source: "UIBehaviorTextKit/BehaviorTextView.swift",
      notes: [
        "iOS TextKit owns composition, selection, paste and native undo.",
        "Core edits reject ranges that split a UTF-16 surrogate pair.",
        "Bold, italic, underline and safe native links are supported; this is not a collaborative HTML editor.",
      ],
      uikit:
        'let editor = BehaviorRichTextView(frame: .zero, textContainer: nil)\neditor.setDocument(RichTextDocument("Hello native editor"))\neditor.onDocumentChange = { print($0.text) }',
      api: [
        [
          "model",
          "RichTextDocument",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "menu",
      title: "Menus",
      group: "Behaviors",
      kind: "menu",
      description:
        "Action, toggle, radio and submenu state with native presentation.",
      code: '@State private var menu = MenuBehavior([\n    BehaviorMenuItem("favorite", title: "Favorite", kind: .toggle),\n    BehaviorMenuItem("copy", title: "Copy sample")\n])\nBehaviorMenu("Actions", model: $menu) { id in print(id) }',
      core: "MenuBehavior",
      source: "UIBehaviorCore/MenuBehavior.swift",
      notes: [
        "Native Menu handles presentation and platform interaction.",
        "Disabled ancestors block descendant actions.",
        "A returned action ID is for the host to handle; the package does not execute application commands.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "MenuBehavior",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "overlays",
      title: "Nested overlays",
      group: "Behaviors",
      kind: "overlays",
      description: "Parent-child presentation with deterministic dismissal.",
      code: '@State private var stack = OverlayStack()\nBehaviorOverlayHost($stack) {\n    Button("Open inspector") {\n        stack.present(BehaviorOverlay("inspector", restoreFocus: "open-button"))\n    }\n} overlay: { item in\n    Button("Close") { stack.dismiss(item.id) }\n}',
      core: "OverlayStack",
      source: "UIBehaviorCore/OverlayStack.swift",
      notes: [
        "Present children with the current top entry as parent.",
        "Dismissing a parent removes descendants. Interactive dismissal respects policy.",
        "Use the restoreFocus callback to restore your actual native accessibility/focus binding.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "OverlayStack",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "measurements",
      title: "Native measurements",
      group: "Behaviors",
      kind: "measurements",
      description: "Observe native logical-point geometry without a DOM.",
      code: '@State private var frame = BehaviorRect(width: 0, height: 0)\nText("Measure me")\n    .behaviorMeasure { frame = $0 }',
      core: "BehaviorRect",
      source: "UIBehaviorSwiftUI/BehaviorMeasurement.swift",
      notes: [
        "SwiftUI uses an explicit coordinate space; UIKit converts to window points.",
        "Bounds are not proof of hittability. Check the current display and accessibility tree.",
        "Keep orientation, scale and window identity with external computer-use captures.",
      ],
      uikit:
        "if let frame = BehaviorMeasurement.frame(of: view) {\n    print(frame.width, frame.height)\n}\n// The UIView must be mounted in a window.",
      api: [
        [
          "model",
          "BehaviorRect",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
    },
    {
      id: "agent",
      title: "Agent observe & act",
      group: "Behaviors",
      kind: "agent",
      description:
        "Expose registered native controls through stable references and explicit authority.",
      code: 'let snapshot = agent.snapshot()\ntry agent.act(\n    AgentStep(ref: "gallery", action: "next"),\n    revision: snapshot.revision\n)\nlet after = agent.snapshot()',
      core: "BehaviorAgent · AgentStep",
      source: "UIBehaviorCore/AgentProtocol.swift",
      notes: [
        "Register current state and explicit handlers; see the agent integration guide.",
        "The host authorizes every action. Disabled, read-only and sensitive controls expose no actions.",
        "Actions reject stale revisions and ambiguous labels. There is no network listener or model provider.",
      ],
      uikit: "",
      api: [
        [
          "model",
          "BehaviorAgent · AgentStep",
          "Caller-owned value state. SwiftUI adapters take a Binding.",
        ],
      ],
      extended: true,
      codeTitle: "Core",
    },
  ],
];
