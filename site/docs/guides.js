export const guides = [
  {
    id: "introduction",
    title: "Introduction",
    group: "Get started",
    description: "Small Swift behaviors. Native interfaces. Your design.",
    body: [
      "iosUI-sdk is an independent Swift package for composing the rules behind controls. The core owns deterministic state; SwiftUI and UIKit own native input, focus, accessibility and presentation.",
      "Start with a native control when it already covers your use case. Add a behavior when you need reusable selection, navigation, geometry or interaction rules.",
      "The extended native catalog covers calendar/date, color, tree/grid, drag/drop, resize, crop, carousel, editing, menus, overlays, measurement and local agent actions.",
    ],
    code: "import UIBehaviorCore\nimport UIBehaviorSwiftUI\n// UIKit hosts can also import UIBehaviorUIKit.",
    notes: [
      "Swift 6, iOS 17+. Core and most SwiftUI adapters support macOS 14+.",
      "No application dependencies, analytics, model provider or network service.",
      "Apache-2.0. Independent adaptation of UI SDK concepts; not affiliated with Vercel or Apple.",
    ],
    kind: "guide",
    codeTitle: "Core",
    core: "Native Swift",
    source: "README.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
  {
    id: "installation",
    title: "Installation",
    group: "Get started",
    description:
      "Add the Swift package in Xcode and choose the products your target uses.",
    body: [
      "In Xcode, choose File → Add Package Dependencies and enter https://github.com/killa-kyle/iosUI-sdk. Select UIBehaviorCore, UIBehaviorSwiftUI and/or UIBehaviorUIKit.",
      "Version 0.2.0 includes the foundations and extended native behaviors. Choose the products your app uses; no application service or model provider is required.",
    ],
    code: '.package(\n    url: "https://github.com/killa-kyle/iosUI-sdk.git",\n    from: "0.2.0"\n)',
    notes: [
      "Choose a version or revision intentionally. Do not assume a released tag includes unreleased APIs.",
      "UIBehaviorUIKit can host every shared SwiftUI adapter through BehaviorController; direct UIKit APIs also cover choices, values, TextKit, image crop export and measurement.",
    ],
    kind: "guide",
    codeTitle: "Setup",
    core: "Native Swift",
    source: "README.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
  {
    id: "accessibility",
    title: "Accessibility & input",
    group: "Get started",
    description:
      "Use native semantics and verify the interaction, not only the screenshot.",
    body: [
      "State models do not replace native focus or accessibility. Adapters use platform controls, accessibility labels/values and native presentation. Supply clear labels for your application data.",
      "Tree and grid adapters support arrow navigation and Shift ranges. Resize handles have keyboard and accessibility adjustments. Reordering has accessible move actions as an alternative to dragging.",
      "Review large text, narrow layouts, Reduce Motion, disabled/error states, hardware input and relevant device postures in your application. The validation page records the package evidence and its limits.",
    ],
    code: "// Keep focus and selection independent.\nvar focus = FocusNavigation<String>()\nvar selection = Selection<String>(mode: .multiple)\n// Apply logical focus using native FocusState / UIKit focus.",
    notes: [
      "No exhaustive VoiceOver, hardware-keyboard or physical-device certification is claimed.",
      "A visible native frame does not prove a control is hittable.",
      "Never render credentials into agent-observable state or test attachments.",
    ],
    kind: "guide",
    codeTitle: "Core",
    core: "Native Swift",
    source: "README.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
  {
    id: "agent-guide",
    title: "Build for native agents",
    group: "Agents",
    description:
      "Let an authorized agent observe and operate the same state a person uses.",
    body: [
      "Register stable refs, accessible names, current state and explicit action handlers with BehaviorAgent. The required host callback authorizes every action. There is no implicit app-wide control surface.",
      "Capture a snapshot, resolve the intended component, perform a registered action against its revision, then inspect the result. Re-read after any state or geometry change.",
      "Computer use can discover an interaction contract in a reference interface. A native replay verifies that the same intent produces the expected focus, selection, value or dismissal. Observations inform implementation; they do not grant authority.",
    ],
    code: 'let before = agent.snapshot()\ntry agent.act(\n    AgentStep(ref: "gallery", action: "next"),\n    revision: before.revision\n)\nlet after = agent.snapshot()',
    notes: [
      "Read the complete registration example in docs/agents.md.",
      "The ref/action/args step shape matches upstream; native snapshots add revision and coordinate-space metadata. This is not the complete injected web observer protocol.",
      "Host-driven updates must call invalidate(). Unregister removed controls. Sensitive, disabled and read-only controls expose no actions.",
    ],
    links: [
      [
        "Read agent integration",
        "https://github.com/killa-kyle/iosUI-sdk/blob/0.2.0/docs/agents.md",
      ],
    ],
    kind: "guide",
    codeTitle: "Core",
    core: "Native Swift",
    source: "docs/agents.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
  {
    id: "catalog",
    title: "Native component catalog",
    group: "Reference",
    description:
      "A runnable iOS catalog composed from the production adapters.",
    body: [
      "The catalog keeps disposable local state and never connects to an application backend. Each extended behavior has its own story, including real UIImage crop export and a local agent action that changes the visible carousel.",
      "Use the story launch argument for deterministic XCTest/WDA replay. Compare both the resulting state and fresh accessibility geometry.",
    ],
    code: "brew install xcodegen\nxcodegen generate --spec Examples/project.yml\nopen Examples/BehaviorCatalog.xcodeproj\n\n// Catalog launch arguments for a focused replay:\n// --story calendar\n// --story agent",
    notes: [
      "Use an available simulator/device and normal development signing.",
      "Story IDs: calendar, color, tree, grid, drag, resize, crop, carousel, editor, menu, overlays, measurements, agent.",
      "Browser previews illustrate contracts. Native catalog replay is separate evidence.",
    ],
    kind: "guide",
    codeTitle: "Setup",
    core: "Native Swift",
    source: "README.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
  {
    id: "coverage",
    title: "Coverage & differences",
    group: "Reference",
    description:
      "Every requested family has a native implementation; platform boundaries remain explicit.",
    body: [
      "Foundation behaviors include selection, focus, typeahead, disclosure, bounded values, reorder, validation, viewport and fixed-row virtualization.",
      "Extended native families include calendar/date, sRGB color, tree/grid ranges, local drag/drop, 2D resize, pixel crop/quarter turns, carousel, TextKit editing, native menus, nested sheets, measurement and opt-in agent actions.",
      "This is semantic native coverage, not every upstream recipe. Native List, Menu, Picker, Toggle and Button remain appropriate where they cover the desired behavior.",
    ],
    code: "UIBehaviorCore\nUIBehaviorSwiftUI\nUIBehaviorUIKit",
    notes: [
      "Calendar arithmetic is Gregorian. Color math is sRGB/HSV, not all CSS color spaces.",
      "Drag transfer is local IDs. Crop rotation is in quarter turns. Text editing is attributed TextKit, not collaborative HTML.",
      "DOM measurement and browser injection are replaced by explicit native point-space measurement and host-authorized action registration.",
    ],
    links: [
      [
        "Full coverage map",
        "https://github.com/killa-kyle/iosUI-sdk/blob/0.2.0/docs/coverage.md",
      ],
    ],
    kind: "guide",
    codeTitle: "Core",
    core: "Native Swift",
    source: "README.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
  {
    id: "validation",
    title: "Validation",
    group: "Reference",
    description:
      "Compilation, state tests and interaction replay establish different things.",
    body: [
      "The expanded local core suite passes 37 tests. The extended catalog and SwiftUI/UIKit/TextKit products compile for iOS. Native replay for the new stories is being expanded; see the current Quality run before treating an API as interaction-verified.",
      "The original 0.1.0 hosted simulator replay verified choice selection/deselection, disabled state, disclosure and sheet behavior, plus UIKit table/value bindings.",
      "Passing host tests does not establish physical-device behavior, exhaustive accessibility or complete web parity.",
    ],
    code: 'swift test\nxcodegen generate --spec Examples/project.yml\nxcodebuild -project Examples/BehaviorCatalog.xcodeproj \\\n    -scheme BehaviorCatalog \\\n    -destination "platform=iOS Simulator,name=YOUR_SIMULATOR" test',
    notes: [
      "Validation evidence is tied to a source revision and runtime.",
      "Use the native catalog for acceptance and preserve state/geometry captures for unresolved failures.",
    ],
    links: [
      [
        "Quality runs",
        "https://github.com/killa-kyle/iosUI-sdk/actions/workflows/quality.yml",
      ],
      [
        "Validation record",
        "https://github.com/killa-kyle/iosUI-sdk/blob/0.2.0/docs/validation.md",
      ],
    ],
    kind: "guide",
    codeTitle: "Setup",
    core: "Native Swift",
    source: "README.md",
    api: [
      [
        "UIBehaviorCore",
        "Swift values",
        "Interaction state and deterministic transitions.",
      ],
      [
        "UIBehaviorSwiftUI",
        "Native views",
        "Bindings, input and platform presentation.",
      ],
      [
        "UIBehaviorUIKit",
        "Native controllers",
        "UIKit hosting, TextKit, image crop export and measurement.",
      ],
    ],
  },
];
