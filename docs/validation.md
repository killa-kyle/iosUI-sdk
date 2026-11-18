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

The catalog uses real package adapters. Native adapter unit tests exercise table
selection/disabled state/external reconciliation and slider callbacks. The UI
replay covers selecting/deselecting choices, disabled options, disclosure and
native sheet open/close. It does not yet cover every adapter or accessibility mode.
