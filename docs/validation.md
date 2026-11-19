# Validation

## Local validation — 2026-11-18

- Swift 6.4 host build: core and SwiftUI products compiled on macOS.
- 17 deterministic core tests passed, including composed picker state replay.
- iOS simulator catalog, SwiftUI/UIKit products and test bundles compiled with
  the iOS 27.1 SDK, with an iOS 17 deployment target.
- Browser landing page: multiple selection, switching to single selection,
  shared slider/stepper state and disclosure interactions observed; narrow
  layout reviewed. Browser demos are illustrations, not native acceptance.
- Local SSD-backed simulator creation failed in CoreSimulator (Creating/fixup
  error); no local simulator interaction pass is claimed. The iOS test targets
  run separately in GitHub Actions. See the current Quality run for results.
- Physical-device interaction, VoiceOver, hardware-keyboard and Duo posture
  acceptance have not been completed. No claim of exhaustive accessibility
  or full web feature parity is made.

## Native simulator observations

The iOS 26.4 hosted simulator completed the real SwiftUI interaction replay:
independent choice taps, selected accessibility traits, disabled options,
deselecting, disclosure and sheet open/close. This caught and verified the
Form-row choice-button isolation fix. The native slider's Float readback differs
from its exact core Double state by about one ULP on that runtime; adapter tests
allow two Float ULPs for control readback while keeping core state and callback
counts exact. The current Quality run is the authority for the release head.

An additional local existing-simulator attempt installed the catalog but did
not finish its test session; Xcode reported SDK/build-version parsing and test
log finalization diagnostics. Simulator screenshot export to the SSD was also
denied by the host. Local native runtime/visual approval is not claimed. The
existing simulator was returned to its initial shutdown state and only the
temporary catalog/test-runner apps were removed.

The catalog uses real package adapters. Native adapter unit tests exercise table
selection/disabled state/external reconciliation and slider callbacks. The UI
replay covers selecting/deselecting choices, disabled options, disclosure and
native sheet open/close. It does not yet cover every adapter or accessibility mode.

## Extended behavior work

The expanded core suite currently passes 37 tests, including invalid civil dates,
disabled date ranges, sRGB/HSV/alpha contrast, tree/grid focus and ranges, nested
drop hit-testing, all resize handles/aspect bounds/cancellation, crop rotations,
carousel timing, menu/overlay rules, UTF-16 editing and agent authority/redaction.
The extended iOS catalog and UIKit/TextKit adapters compile in a local unsigned
build. Hosted simulator adapter tests pass for TextKit trait/selection bridging,
pixel crop export and UIKit containment/state/measurement. The extended native
interaction suite replays calendar/tree/grid, color/UIKit hosting, drag/drop,
resize/crop, carousel/menu, nested presentation and editor/measurement/agent actions.
Local iOS 27.1 XCTest replay also passes actual drag/repeated drop/cancellation,
resize/pixel crop export and nested overlays. The exact release head's Quality
run is the authority for simulator acceptance;
physical-device and exhaustive accessibility acceptance remain pending.

Documentation browser replay passes all 30 pages and 22 interactive illustrations,
including keyboard code tabs, clipboard, grid/date ranges, nested dialogs, stale
agent rejection and desktop/mobile layouts in both themes. Screenshots were
inspected locally. This browser replay does not establish native UI acceptance.

README examples use real XCTest screen recordings from an iPhone 17 Pro simulator
running iOS 26.4.1. Calendar, drag and crop gesture outcomes are asserted by the
capture cases. Native video frames were inspected, including the moving drag
preview and accepted drop. Each GIF's actual source revision is recorded in
docs/media/capture.json; the older drag capture has unchanged adapter/showcase
source. Crop handle accessibility regression and hex text replacement also pass
on the local iOS 27.1 simulator. These are separate from physical-device acceptance.
