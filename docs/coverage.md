# Behavior coverage

Upstream reference: [vercel-labs/ui at 63df19a](https://github.com/vercel-labs/ui/tree/63df19ae09452fb185d54275404da044f0addda2).
This is a semantic native adaptation, not a GitHub source fork or drop-in binding.

| Foundation         | Native core       | SwiftUI                              | UIKit                                             | Differences / upstream reference                                                                                                              |
| ------------------ | ----------------- | ------------------------------------ | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Selection          | `Selection`       | Choice list                          | Choice controller                                 | Stable Hashable IDs; no DOM events or cancellable change callbacks. `foundation/selection/selection-model.ts`                                 |
| Roving focus       | `FocusNavigation` | Choice list key presses              | Native table focus; explicit logical movement API | No DOM tab-stop emulation. Disabled IDs skipped; wraps by default; web default differs. `foundation/focus/roving-focus.ts`                    |
| Typeahead          | `Typeahead`       | Choice list                          | Explicit search API                               | Caller-supplied time; Foundation locale folding; no DOM label extraction. `foundation/text/typeahead.ts`                                      |
| Popup / disclosure | `Disclosure`      | DisclosureGroup and native sheet     | Core model only                                   | Sheet uses native presentation rather than anchored web popup positioning. No nested modal stack abstraction.                                 |
| Numeric values     | `BoundedValue`    | Slider, stepper                      | UISlider, UIStepper binding                       | Clamp and snap relative to lower bound. Reject nonfinite updates. Can also model rating or one-axis resizing.                                 |
| Reorder            | `Reorder`         | Accessibility actions                | Table row editing                                 | Final-index moves; disabled rows are barriers. SwiftUI drag preview/drop orchestration is not included. `foundation/drag-and-drop/reorder.ts` |
| Field validation   | `FieldValidation` | BehaviorField                        | Core model only                                   | Caller provides validation; touched/submitted visibility; no form submission service.                                                         |
| Pan / zoom         | `Viewport`        | BehaviorViewport                     | Core model only                                   | Anchored zoom and translation; no collision, inertia, fit-to-content or keyboard avoidance. `foundation/canvas/viewport.ts`                   |
| Virtualization     | `VirtualWindow`   | Use native List, or custom rendering | Use native UITableView                            | Fixed row extents only. Variable-size measurement not ported. `foundation/lists/virtualizer.ts`                                               |

## Not implemented in 0.1

Calendar/date logic, color picker, tree/grid range navigation, drag/drop engine,
2D resize handles, cropper, carousel, rich text editing, menus, nested overlays,
web agent protocols, DOM measurements and the web component catalog are not ported.
Native List, Menu, Picker, Toggle, Button and platform presentation remain appropriate
when they already cover the desired behavior. This package does not replace them.

## Contract boundaries

IDs must be unique and stable. Core state is synchronous value state; callers own
persistence and control updates. Change callbacks are native adapter callbacks,
not a cross-platform event/cancellation kernel. Range selection and toggle-all are
available through core methods; the initial choice adapters do not map Shift/Cmd
shortcuts to those methods. UIKit logical focus methods do not claim to move the
hardware focus engine; use native focus APIs for custom hardware-keyboard routes.
