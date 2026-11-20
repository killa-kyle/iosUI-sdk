export const chatGuides = [
  {
    id: "streaming-chat",
    title: "Streaming chat",
    group: "Behaviors",
    kind: "guide",
    codeTitle: "Core",
    core: "StreamScrollCoordinator · ActivityDisclosureStore · ReadingAnchorTracker",
    description:
      "Preserve reading position and activity choices while content arrives.",
    body: [
      "StreamScrollCoordinator separates following the latest content from reading earlier messages. New chunks can request a scroll without overriding that choice. Latest explicitly restores following.",
      "Feed native scroll phases through behaviorScrollPhase, then execute current requests with ScrollViewReader or your UIKit scrolling code. Pending requests coalesce; cancellation and replacement invalidate older work.",
      "Before inserting history or resizing, freeze the ReadingAnchorTracker. Locate the saved row, measure its new height, then align its saved pixel offset. The native catalog exercises these steps with real ScrollView input.",
      "ActivityDisclosureStore keeps expansion choices above collapsed rows. Supply an activity revision for every host update, including a stop before the next chunk. Prune with the complete set of live activity IDs.",
    ],
    code: '@State private var scroll = StreamScrollCoordinator<String>()\n@State private var activity = ActivityDisclosureStore<String>()\n\n// A host update; status comes from your application.\nactivity.observe("lookup", phase: .running, revision: 1)\n\n// Execute only while this request is still current.\nif let request = scroll.request(.latest, reason: .stream) {\n    guard scroll.isCurrent(request) else { return }\n    proxy.scrollTo("latest", anchor: .bottom)\n    scroll.finish(request)\n}',
    source: "docs/chat-interactions.md",
    notes: [
      "iOS 18/macOS 15 and newer provide native tracking, dragging, deceleration and animation phases. The compatibility adapter on older supported systems reports drag start/end; the host supplies richer measurements.",
      "Keep message admission, draft persistence, stream transport and confirmed cancellation in the host.",
      "The Streaming chat native story uses a local stream and explicit layout previews. Reference-app observations and remaining parity checks are recorded separately.",
    ],
    api: [
      [
        "beginReading / followLatest",
        "Intent",
        "Choose reading continuity or follow the latest content.",
      ],
      [
        "request / isCurrent / finish",
        "Scroll requests",
        "Coalesce pending work and reject stale execution.",
      ],
      [
        "beginAnchorRestoration / measureRestoration",
        "Row geometry",
        "Preserve the saved offset after measuring a reflowed row.",
      ],
      [
        "ActivityDisclosureStore",
        "Activity state",
        "Retain explicit expansion across newer host revisions.",
      ],
    ],
  },
  {
    id: "keyboard-layout",
    title: "Keyboard & layout",
    group: "Behaviors",
    kind: "guide",
    codeTitle: "UIKit",
    core: "KeyboardViewport · BehaviorKeyboardObserver · BehaviorKeyboardGuideView",
    description:
      "Measure keyboard overlap and host-supplied reserved regions in native points.",
    body: [
      "Attach BehaviorKeyboardObserver behind a SwiftUI container, or embed BehaviorKeyboardGuideView in a UIKit container. Both observe the native keyboard layout guide in that container's coordinate space.",
      "The snapshot reports remaining bottom overlap and available regions. A container already resized by the system has no additional keyboard overlap to add. Enable followsUndockedKeyboard to track a floating keyboard as a rectangle.",
      "Supply reserved rectangles for a known hinge or unavailable area. Set posture only from explicit host information. Width alone does not identify a physical posture.",
      "Window, size and posture changes invalidate older callback contexts. Native focus and keyboard animation stay with the platform. The catalog's Compact, Expanded and Tabletop controls simulate layout inputs.",
    ],
    code: "let observer = BehaviorKeyboardGuideView(frame: container.bounds)\nobserver.autoresizingMask = [.flexibleWidth, .flexibleHeight]\nobserver.configure(\n    posture: .unspecified,\n    followsUndockedKeyboard: true\n)\nobserver.onChange = { snapshot in\n    let remainingOverlap = snapshot.bottomInset\n    let availableRegions = snapshot.availableRegions\n    // Update your existing layout from these container-local measurements.\n}\ncontainer.addSubview(observer)",
    source: "docs/chat-interactions.md",
    notes: [
      "UIKit and SwiftUI keyboard observers require iOS. The pure geometry model is also available in UIBehaviorCore.",
      "Use adjustment(toReveal:) for a focus target near floating keyboard geometry.",
      "Physical posture, VoiceOver and hardware-keyboard acceptance need device replay; a simulated reserved rectangle does not establish those results.",
    ],
    api: [
      [
        "bottomInset",
        "Double",
        "Full-width docked keyboard overlap remaining in this container.",
      ],
      [
        "availableRegions",
        "[BehaviorRect]",
        "Unobscured regions after subtracting the keyboard and reserved areas.",
      ],
      [
        "adjustment(toReveal:)",
        "BehaviorPoint?",
        "A translation into an available region that can fit the target.",
      ],
      [
        "ViewportContext",
        "Revision token",
        "Reject delayed observations from another window or layout.",
      ],
    ],
  },
];
