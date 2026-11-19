export const foundations = [
  {
    id: "selection",
    title: "Selection",
    group: "Behaviors",
    kind: "selection",
    description:
      "Choose one or many stable IDs. Keep selection independent from focus.",
    code: '@State private var selection = Selection<String>(mode: .multiple)\n\nBehaviorChoiceList(["SwiftUI", "UIKit"], selection: $selection,\n    label: { $0 }) { name, selected in\n    Label(name, systemImage: selected ? "checkmark" : "circle")\n}',
    core: "Selection<ID>",
    source: "UIBehaviorCore/Selection.swift",
    notes: [
      "Disabled IDs do not change the selection anchor.",
      "Range extension keeps a stable anchor; reconcile after removing items.",
      "The shared choice adapter composes focus and typeahead.",
    ],
    uikit:
      'let controller = BehaviorChoiceController(\n    ["SwiftUI", "UIKit"],\n    selection: Selection<String>(mode: .multiple),\n    label: { $0 }\n)\ncontroller.onSelectionChange = { print($0.selected) }',
    api: [
      [
        "model",
        "Selection<ID>",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
  },
  {
    id: "focus",
    title: "Focus navigation",
    group: "Behaviors",
    kind: "focus",
    description:
      "Move logical focus through eligible items without changing selection.",
    code: 'var focus = FocusNavigation<String>(wraps: true)\nlet next = focus.move(.next, order: ["First", "Second", "Third"],\n    disabled: ["Second"])\n// Apply next using FocusState or UIKit focus APIs.',
    core: "FocusNavigation<ID>",
    source: "UIBehaviorCore/FocusNavigation.swift",
    notes: [
      "Next, previous, first and last skip disabled IDs.",
      "Wrapping is explicit; focus and selection remain separate.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "FocusNavigation<ID>",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
    codeTitle: "Core",
  },
  {
    id: "typeahead",
    title: "Typeahead",
    group: "Behaviors",
    kind: "typeahead",
    description:
      "Find an option by typing, including accent folding and repeated-key cycling.",
    code: 'var search = Typeahead(timeout: 0.5)\nlet index = search.search("c", labels: ["Café", "Color", "Motion"],\n    current: nil, at: ProcessInfo.processInfo.systemUptime)',
    core: "Typeahead",
    source: "UIBehaviorCore/Typeahead.swift",
    notes: [
      "Use a monotonic caller-supplied clock.",
      "The choice adapter wires native key input; standalone callers supply labels.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "Typeahead",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
    codeTitle: "Core",
  },
  {
    id: "disclosure",
    title: "Disclosure",
    group: "Behaviors",
    kind: "disclosure",
    description: "Explicit open and close state backed by native presentation.",
    code: '@State private var details = Disclosure()\nBehaviorDisclosure($details) { Text("Details") } content: {\n    Text("A native reveal, using your design.")\n}',
    core: "Disclosure",
    source: "UIBehaviorCore/Disclosure.swift",
    notes: [
      "Opening respects disabled state. Closing still works.",
      "Use behaviorSheet for native sheets; OverlayStack composes nested presentations.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "Disclosure",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
  },
  {
    id: "values",
    title: "Slider & stepper",
    group: "Behaviors",
    kind: "values",
    description: "One bounded value shared across different native controls.",
    code: '@State private var energy = BoundedValue(40, in: 0...100, step: 10)\nBehaviorSlider($energy) { Text("Energy") }\nBehaviorStepper($energy) { Text("Energy: \\(Int(energy.value))") }',
    core: "BoundedValue",
    source: "UIBehaviorCore/BoundedValue.swift",
    notes: [
      "Values clamp and snap relative to the lower bound.",
      "Nonfinite changes are rejected. UIKit slider readback has Float precision.",
    ],
    uikit:
      "let binding = BehaviorValueBinding(\n    BoundedValue(40, in: 0...100, step: 10), slider: slider\n)\nbinding.onChange = { print($0.value) }\n// Retain binding for the control’s lifetime.",
    api: [
      [
        "model",
        "BoundedValue",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
  },
  {
    id: "reorder",
    title: "Reorder",
    group: "Behaviors",
    kind: "reorder",
    description: "Move stable IDs by final index while respecting locked rows.",
    code: '@State private var order = ["First", "Second", "Third"]\nText("Second")\n    .behaviorReorderActions(id: "Second", order: $order)',
    core: "Reorder",
    source: "UIBehaviorCore/Reorder.swift",
    notes: [
      "Disabled rows act as barriers.",
      "Native accessibility actions provide an alternative to drag gestures.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "Reorder",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
  },
  {
    id: "field-validation",
    title: "Field validation",
    group: "Behaviors",
    kind: "validation",
    description:
      "Show validation after blur or submission, with caller-owned rules.",
    code: '@State private var name = ""\n@State private var validation = FieldValidation()\nBehaviorField("Project name", text: $name, validation: $validation) {\n    $0.isEmpty ? ["Enter a project name"] : []\n}',
    core: "FieldValidation",
    source: "UIBehaviorSwiftUI/BehaviorField.swift",
    notes: [
      "Validation rules belong to the host.",
      "The adapter uses native text input and publishes visible error messages.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "FieldValidation",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
  },
  {
    id: "viewport",
    title: "Pan & zoom",
    group: "Behaviors",
    kind: "viewport",
    description: "Keep the anchor under the pointer while zoom changes.",
    code: "@State private var viewport = UIBehaviorCore.Viewport()\nBehaviorViewport($viewport) { YourCanvas() }\n    .frame(height: 300)",
    core: "Viewport",
    source: "UIBehaviorCore/Viewport.swift",
    notes: [
      "Translation uses logical points; scale is unitless.",
      "The host supplies visible zoom controls and owns fit-to-content or inertia.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "Viewport",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
  },
  {
    id: "virtual-window",
    title: "Virtual windows",
    group: "Behaviors",
    kind: "virtual",
    description: "Calculate a fixed-size visible range for a custom renderer.",
    code: "let window = VirtualWindow(count: 1000, itemExtent: 44, overscan: 2)\nlet visible = window.visibleRange(offset: 440, viewportExtent: 300)\n// Prefer native List or UITableView for ordinary lists.",
    core: "VirtualWindow",
    source: "UIBehaviorCore/VirtualWindow.swift",
    notes: [
      "Computes ranges without rendering or scrolling.",
      "Variable-height virtualization is outside this fixed-extent model.",
    ],
    uikit: "",
    api: [
      [
        "model",
        "VirtualWindow",
        "Caller-owned value state. SwiftUI adapters take a Binding.",
      ],
    ],
    extended: false,
    codeTitle: "Core",
  },
];
