# Streaming chat and native viewports

`UIBehaviorCore` provides three pieces you can compose with an existing chat UI.
The host owns messages, stream transport, persistence and task status.

## Keep the reading position

Use `StreamScrollCoordinator<RowID>` to distinguish following the latest content
from reading earlier messages. Feed native scroll phases through
`behaviorScrollPhase`. Touch tracking pauses automatic scrolling; dragging changes
the reading intent. Programmatic scrolling does not count as a reader returning
to the end. A Latest action explicitly restores following.

Requests coalesce while one is pending. Execute them through the platform's scroll
API, check `isCurrent` immediately before execution, and call `finish` afterward.
Cancellation, a new explicit request or a conversation change fences older work.
Create a coordinator for each conversation; IDs alone do not identify its scope.

```swift
@State private var scroll = StreamScrollCoordinator<String>()

// New content may request a scroll without overriding the reader's intent.
if let request = scroll.request(.latest, reason: .stream) {
  // Schedule with your existing UI update loop.
  guard scroll.isCurrent(request) else { return }
  proxy.scrollTo("latest", anchor: .bottom)
  scroll.finish(request)
}
```

Measure rows using `behaviorReadingAnchor(_:in:viewport:layoutRevision:restorationTarget:)`
and collect `BehaviorReadingAnchorPreference<RowID>`. Keep a
`ReadingAnchorTracker<RowID>` in the view owner. It records exact row geometry
without publishing state for every scrolled pixel. Update visible UI only when
its returned row-ID change flag is true.

Before loading earlier messages or changing the viewport, freeze the tracker and
pass its saved anchor to the coordinator. After a width change, use
`beginAnchorRestoration(in:layoutRevision:reason:)` to locate the row, then feed a
fresh measurement to `measureRestoration`. This second request aligns using the
row's new height and its saved pixel offset. Resume the tracker after alignment.
Reconcile against the full set of row IDs after deletion. A missing row cancels
its pending restoration.

On iOS 18/macOS 15 and newer the phase adapter uses native scroll phases. On
older supported systems it reports drag start/end; deceleration and end-of-content
measurements need host integration. The coordinator does not estimate them.

## Keep activity choices across updates

`ActivityDisclosureStore<ID>` stores each activity's expansion choice above
collapsed or deferred rows. Supply a monotonically increasing revision for each
host update. Older or duplicate revisions are rejected. Running activity opens
by default, an explicit collapse survives new chunks, and activity observed
running stays open when it ends unless the user chose otherwise.

```swift
@State private var activities = ActivityDisclosureStore<String>()
activities.observe("lookup", phase: .running, revision: 1)
let change = activities["lookup"].toggle(running: true)
if change == .opened {
  scroll.beginReading() // Inspecting details should preserve reading intent.
}
activities.observe("lookup", phase: .completed, revision: 2)
```

Use an independent revision counter for activity updates. A stop may occur before
the next content chunk. Prune with all live activity IDs, rather than just the
visible rows. Only the host confirms completed, failed or cancelled status.

## Observe the keyboard and available regions

Place `BehaviorKeyboardObserver` behind the container being measured. UIKit can
use `BehaviorKeyboardGuideView`, pinned with constraints or an autoresizing mask
to its container. Both observe the native keyboard layout guide,
report container-local logical points, and reject callbacks from an older
window, size or posture. Native focus and keyboard animation remain platform-owned.

```swift
.background {
  BehaviorKeyboardObserver(posture: .unspecified) { snapshot in
    keyboard = snapshot
  }
}
```

`KeyboardViewportSnapshot.bottomInset` covers a full-width docked keyboard's
intersection with that container. A viewport already shortened by the system
has no extra overlap to add. Set `followsUndockedKeyboard: true` to track floating keyboards as rectangles; use
`availableRegions` or `adjustment(toReveal:)` instead of treating every keyboard
as a bottom inset.

Shared edges within a thousandth of a logical point are normalized when cutting
available regions, avoiding phantom panes from native coordinate rounding.

Pass host-known reserved regions for a hinge or unavailable area, and an explicit
`ViewportPosture` when the platform supplies it. Width alone does not identify a
physical posture. The native catalog's Compact, Expanded and Tabletop controls
simulate these inputs and label them as previews.

## Try the native example

Open the Streaming chat story in `Examples/Catalog`. It uses the public models,
real ScrollView/TextField input, a cancellable local stream and the native
keyboard observer. The corresponding XCTest cases exercise reading during new
chunks, history insertion, explicit activity choice, keyboard placement and
reserved-region layouts. Browser previews remain illustrations.

See [the reference interaction ledger](reference-interactions.md) for the evidence
behind additional interaction candidates and the checks still needed.
