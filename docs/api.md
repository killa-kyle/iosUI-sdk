# API recipes

All adapters require the main actor through their native framework isolation.
Core values are Sendable; mutation still belongs to the caller's chosen isolation.

## Selection and focus

```swift
var selection = Selection<String>(mode: .multiple)
selection.choose("a")
selection.extend(to: "c", order: ["a", "b", "c"], disabled: ["b"])
// selected == ["a", "c"]
var focus = FocusNavigation<String>(wraps: false)
let next = focus.move(.next, order: ["a", "b", "c"], disabled: ["b"])
```

`choose` replaces; `toggle` adds/removes in multiple mode; `extend` uses a stable
anchor and can union with its base using `additive: true`. `reconcile(order:)`
discards removed IDs. Mutate a bound value as normal Swift state.

## Disclosure and sheets

```swift
@State private var sheet = Disclosure()
// In a view:
Button("Details") { sheet.open() }
    .behaviorSheet($sheet) {
        Button("Done") { sheet.dismiss(.action) }
    }
```

`isDisabled` blocks opening; closing still works. Outside/escape dismissals honor
policy flags. Native interactive sheet dismissal uses the outside-press policy.
The core does not own screen geometry or focus restoration.

## Shared numeric state

```swift
@State private var volume = BoundedValue(40, in: 0...100, step: 10)
// Both controls use the same state:
BehaviorSlider($volume) { Text("Volume") }
BehaviorStepper($volume) { Text("Volume: \(Int(volume.value))") }
```

UIKit: retain `BehaviorValueBinding(value, slider: slider)` or
`BehaviorValueBinding(value, stepper: stepper)` and set `onChange`. UIKit slider
storage uses Float precision; choose sensible Float-representable bounds.
`BoundedValue` uses Double arithmetic with normal floating-point tolerance.

## Viewport and virtual windows

```swift
@State private var viewport = UIBehaviorCore.Viewport()
BehaviorViewport($viewport) { YourCanvas() }
    .frame(height: 300)
let window = VirtualWindow(count: 1000, itemExtent: 44)
let indices = window.visibleRange(offset: 440, viewportExtent: 300)
```

Viewport translations are points, scale is unitless. Magnification and pan compose.
Provide visible controls for essential zoom tasks. VirtualWindow computes a range;
it does not render, measure or scroll. Prefer native lazy containers for ordinary UI.
