# Computer-use and native agent integration

Computer use supplies evidence: capture the reference interaction, its accessible
names, starting state, geometry and outcome. Replay the same intent against the
native catalog and compare the resulting selection, focus, value or presentation.
Use fresh visible candidates for advisory routing; use deterministic XCTest/WDA
or browser replay for acceptance. A successful tap alone does not establish the
expected state change.

`BehaviorAgent` makes the native side inspectable without a DOM. It is opt-in,
local and synchronous. It has no network listener, model provider, application
service, credentials or implicit access to arbitrary views.

## Register real application state

```swift
@MainActor
final class GallerySession {
    var carousel = CarouselBehavior(count: 3)
    let agent = BehaviorAgent { component, step in
        component.ref == "gallery" && component.confirm == nil
            && ["next", "previous"].contains(step.action)
    }

    init() throws {
        try agent.register(ref: "gallery", read: { [weak self] in
            AgentComponent(
                ref: "gallery", component: "carousel", label: "Scenery",
                state: ["index": .number(Double(self?.carousel.index ?? 0))],
                actions: ["next", "previous"]
            )
        }, perform: { [weak self] step in
            guard step.args.isEmpty else {
                throw AgentProtocolError.unavailableAction
            }
            if step.action == "next" { self?.carousel.next() }
            else { self?.carousel.previous() }
        })
    }
}
```

Capture and act on the same observed revision:

```swift
let snapshot = session.agent.snapshot()
try session.agent.act(
    AgentStep(ref: "gallery", action: "next"),
    revision: snapshot.revision
)
let after = session.agent.snapshot()
```

`AgentStep` uses the upstream web `ref`, `action`, optional `args` JSON shape.
`query(label:offset:limit:)` returns bounded component matches. Exact references
win; ambiguous labels fail. `snapshot` adds a revision and coordinate-space name
around the components. This is a native transport contract, not the injected web
observer's complete wire protocol.

Invalidate after **host-driven** value, visibility, enabled/read-only, geometry or
membership changes: `agent.invalidate()`. Registered action attempts also invalidate
previous observations. Unregister controls when their owning screen is removed.
Do not cache a closure's initial state; read its current binding/store each time.

## Keep authorization in the host

The required authorization closure runs before every registered action. A
`confirm` description is metadata, not approval; the host must verify its own
current approval receipt or reject the action. A remote caller cannot authorize
itself by supplying an argument. Recheck membership and operation scope in the
host before bridging any action that writes externally.

Disabled and read-only components expose no actions. Mark sensitive controls
`sensitive: true`; snapshots redact their label/state and expose no actions.
Register only data that the observing agent is authorized to see. Registration
is not an authorization grant, and the package does not infer which app fields
contain credentials.

## Measure native controls

SwiftUI's `behaviorMeasure(in:onChange:)` reports `BehaviorRect` using an explicit
coordinate space. UIKit's `BehaviorMeasurement.frame(of:)` converts to window
points. Associate the measured rectangle with the registered component and
invalidate on changes. The native catalog's agent example does this with the
same carousel a person operates.

These are logical points, not screenshot pixels. Keep the device/display ID,
orientation, window bounds and scale with an external computer-use observation.
Re-read the actual accessibility tree and hittability before coordinate input;
a frame alone does not prove a view is visible or actionable. Never derive
native coordinates from DOM measurements or silently select an inactive display.

## Replay and improve

Use `--story agent` to open the catalog's real agent-to-carousel demonstration.
The extended catalog also has calendar, color, tree, grid, drag/drop, resize,
crop, carousel, editor, menu, overlays and measurement stories. Capture dark/light,
large text and narrow layouts; compare both state and geometry. Record uncertain
or untested behavior rather than converting a screenshot into a parity claim.
