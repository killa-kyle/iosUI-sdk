export const guides = [
  {
    id: "introduction",
    title: "Introduction",
    group: "Get started",
    description: "State models and native adapters for SwiftUI and UIKit.",
    body: [
      "iosUI-sdk provides state models and native adapters for custom SwiftUI and UIKit components. Core models handle state transitions. Adapters connect them to native input, focus, accessibility and presentation.",
      "Start with a native control when it already covers your use case. Add a behavior when you need reusable selection, navigation, geometry or interaction rules.",
      "The extended native catalog covers calendar/date, color, tree/grid, drag/drop, resize, crop, carousel, editing, menus, overlays, measurement and local agent actions.",
    ],
    code: "import UIBehaviorCore\nimport UIBehaviorSwiftUI\n// UIKit hosts can also import UIBehaviorUIKit.",
    notes: [
      "Swift 6, iOS 17+. Core and most SwiftUI adapters support macOS 14+.",
      "Runs locally with Swift value types, SwiftUI views and UIKit controllers.",
      "Apache-2.0. Independent project inspired by UI SDK.",
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
      "Version 0.2.1 includes the behavior models and native adapters listed in the docs. Add the products your app uses.",
    ],
    code: '.package(\n    url: "https://github.com/killa-kyle/iosUI-sdk.git",\n    from: "0.2.1"\n)',
    notes: [
      "Pin a version or revision and use its matching API reference.",
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
    id: "agent-skill",
    title: "Build with an agent",
    group: "Get started",
    description:
      "Give your coding agent the native package's composition and validation workflow.",
    body: [
      "Install the iosui-sdk skill to help an agent choose behaviors, integrate real SwiftUI/UIKit adapters, preserve native focus and accessibility, and replay actual interactions.",
      "The skill reads the installed package revision's declarations and coverage notes. It prefers native controls when they already fit, and avoids inventing web or DOM APIs in Swift.",
      "The skill guides coding agents during development. Runtime agent actions use a separate API with explicit registration and host authorization.",
    ],
    code: "npx skills@latest add killa-kyle/iosUI-sdk --skill iosui-sdk",
    codeTitle: "Shell",
    kind: "guide",
    source: "skills/iosui-sdk/SKILL.md",
    core: "Agent skill",
    notes: [
      "Agents without skill support can read the SKILL.md directly.",
      "Use the native catalog and XCTest to validate iOS interactions. The README includes simulator recordings.",
    ],
    api: [
      [
        "iosui-sdk",
        "Consumer skill",
        "Native component composition and validation guidance.",
      ],
    ],
  },
  {
    id: "accessibility",
    title: "Accessibility & input",
    group: "Get started",
    description:
      "Check native labels, focus, selection and input behavior with an interaction replay.",
    body: [
      "Adapters use platform controls, native focus, accessibility labels and presentation. Supply clear labels for your application data.",
      "Tree and grid adapters support arrow navigation and Shift ranges. Resize handles have keyboard and accessibility adjustments. Reordering has accessible move actions as an alternative to dragging.",
      "Review large text, narrow layouts, Reduce Motion, disabled/error states, hardware input and relevant device postures in your application. The validation page records the package evidence and its limits.",
    ],
    code: "// Keep focus and selection independent.\nvar focus = FocusNavigation<String>()\nvar selection = Selection<String>(mode: .multiple)\n// Apply logical focus using native FocusState / UIKit focus.",
    notes: [
      "No exhaustive VoiceOver, hardware-keyboard or physical-device certification is claimed.",
      "Check hittability against the current display and accessibility tree.",
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
      "Computer use can help inspect an interface. Replay the interaction in the native app to verify focus, selection, values and dismissal. Runtime actions still require host authorization.",
    ],
    code: 'let before = agent.snapshot()\ntry agent.act(\n    AgentStep(ref: "gallery", action: "next"),\n    revision: before.revision\n)\nlet after = agent.snapshot()',
    notes: [
      "Read the complete registration example in docs/agents.md.",
      "Steps use the upstream ref/action/args shape. Native snapshots include revisions and coordinate-space metadata. The native protocol is documented in docs/agents.md.",
      "Host-driven updates must call invalidate(). Unregister removed controls. Sensitive, disabled and read-only controls expose no actions.",
    ],
    links: [
      [
        "Read agent integration",
        "https://github.com/killa-kyle/iosUI-sdk/blob/0.2.1/docs/agents.md",
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
      "The coverage map lists each native behavior and its API differences. Use native List, Menu, Picker, Toggle and Button when they cover your needs.",
    ],
    code: "UIBehaviorCore\nUIBehaviorSwiftUI\nUIBehaviorUIKit",
    notes: [
      "Calendar arithmetic uses Gregorian civil dates. Color math supports sRGB and HSV.",
      "Drag sessions transfer local IDs. Crop rotation uses quarter turns. Text editing uses attributed TextKit.",
      "DOM measurement and browser injection are replaced by explicit native point-space measurement and host-authorized action registration.",
    ],
    links: [
      [
        "Full coverage map",
        "https://github.com/killa-kyle/iosUI-sdk/blob/0.2.1/docs/coverage.md",
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
      "Version 0.2.1 passed 37 Core tests, 6 native adapter tests and 15 simulator UI tests. The calendar, drag and crop recording cases also assert their outcomes.",
      "Native replay covers selection, disabled controls, disclosure, sheets, calendar, navigation, drag and drop, crop, editing and other catalog interactions. Check the Quality run for the revision you use.",
      "Physical-device and accessibility coverage is tracked separately in docs/validation.md.",
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
        "https://github.com/killa-kyle/iosUI-sdk/blob/0.2.1/docs/validation.md",
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
