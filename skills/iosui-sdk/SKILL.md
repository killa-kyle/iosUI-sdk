---
name: iosui-sdk
description: Build or modify native SwiftUI and UIKit components with iosUI-sdk. Use for choosing and composing its behavior models, binding native adapters, adding accessible input, and validating interactions in an iOS app.
---

# Build with iosUI-sdk

Use the app's existing design system. Prefer native Button, Toggle, Picker, List,
Menu and platform presentation when they already provide the required behavior.
Add a shared behavior when the app needs reusable state or interaction rules.

## Find the actual API

Identify the installed package revision from Package.resolved or the SwiftPM
checkout. Read its README and docs/coverage.md, then search the relevant types
under Sources/. Use the installed revision's declarations and catalog examples;
do not invent overloads from the web UI SDK. If source is unavailable, consult
https://github.com/killa-kyle/iosUI-sdk and https://killa-kyle.github.io/iosUI-sdk/docs/.
The package has no application services, model provider or JavaScript runtime.

## Choose and compose

- UIBehaviorCore owns pure value state: selection/focus/typeahead/disclosure,
  bounded values, field validation, reorder/viewport/windows; calendar/color,
  tree/grid, drag/drop, resize/crop, carousel, rich text, menu and overlay models.
- UIBehaviorSwiftUI binds those values to real platform input and presentation.
  Keep model state in the owning view with State/Binding; do not recreate it in
  body or duplicate it in an unrelated singleton. Logical focus and selection
  are separate; apply focus through native FocusState/accessibility focus.
- UIBehaviorUIKit provides direct controllers, TextKit, measurement and image
  export. BehaviorController can host shared SwiftUI adapters using normal child
  controller containment; keep external state reconciliation distinct from user
  callbacks. Search Examples/Catalog and Examples/AdapterTests for real usage.

Expose app data and callbacks to presentation. Compose the existing adapters
before writing another gesture recognizer or replacement control. For a missing
behavior, add deterministic transitions in Core and a platform adapter; extend
the catalog with the real adapter, rather than a parallel demonstration model.

Check docs/coverage.md for semantic limits: Gregorian civil dates, sRGB color,
local admitted drag IDs, pixel-based crop with quarter-turn rotation, native
TextKit editing and native presentation. This is not a DOM compatibility layer
or an exhaustive port of every web component recipe.

## Validate the app, not only the model

Test meaningful transition boundaries in Core. Build the actual iOS target and
replay affected gestures, focus/selection, cancellation and external updates
through the existing XCTest or device automation route. Inspect loading/error,
disabled states, large text, narrow layouts and light/dark as relevant to the app.
A passing host test or browser illustration does not establish native acceptance.
For animation examples, capture the actual running native interface and retain
intermediate motion; never substitute an animated mockup or endpoint screenshots.
State the tested runtime/device and remaining gaps.

## Optional agent control

Only read docs/agents.md when implementing observation/actions. BehaviorAgent is
opt-in: register current views and handlers, provide explicit host authorization,
invalidate revisions after external state changes, unregister on teardown and
redact sensitive state. Registration is not permission to perform arbitrary app
or network actions. Build-time skill guidance and runtime agent authority are
separate concerns; no agent service is required to use the UI package.
