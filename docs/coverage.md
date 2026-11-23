# Behavior coverage

Upstream reference: [vercel-labs/ui at 63df19a](https://github.com/vercel-labs/ui/tree/63df19ae09452fb185d54275404da044f0addda2).
This is a semantic native adaptation, not a GitHub source fork or drop-in binding.

| Foundation         | Native core       | SwiftUI                              | UIKit                                             | Differences / upstream reference                                                                                                              |
| ------------------ | ----------------- | ------------------------------------ | ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| Selection          | `Selection`       | Choice list                          | Choice controller                                 | Stable Hashable IDs; no DOM events or cancellable change callbacks. `foundation/selection/selection-model.ts`                                 |
| Roving focus       | `FocusNavigation` | Choice list key presses              | Native table focus; explicit logical movement API | No DOM tab-stop emulation. Disabled IDs skipped; wraps by default; web default differs. `foundation/focus/roving-focus.ts`                    |
| Typeahead          | `Typeahead`       | Choice list                          | Explicit search API                               | Caller-supplied time; Foundation locale folding; no DOM label extraction. `foundation/text/typeahead.ts`                                      |
| Popup / disclosure | `Disclosure`      | DisclosureGroup and native sheet     | Core model only                                   | Sheet uses native presentation rather than anchored web popup positioning. Nested behavior is available through OverlayStack/BehaviorOverlayHost.                                 |
| Numeric values     | `BoundedValue`    | Slider, stepper                      | UISlider, UIStepper binding                       | Clamp and snap relative to lower bound. Reject nonfinite updates. Can also model rating or one-axis resizing.                                 |
| Reorder            | `Reorder`         | Accessibility actions                | Table row editing                                 | Final-index moves; disabled rows are barriers. Native local drag/drop is provided separately by DragDropBehavior. `foundation/drag-and-drop/reorder.ts` |
| Field validation   | `FieldValidation` | BehaviorField                        | Core model only                                   | Caller provides validation; touched/submitted visibility; no form submission service.                                                         |
| Pan / zoom         | `Viewport`        | BehaviorViewport                     | Core model only                                   | Anchored zoom and translation; no collision, inertia, fit-to-content or keyboard avoidance. `foundation/canvas/viewport.ts`                   |
| Virtualization     | `VirtualWindow`   | Use native List, or custom rendering | Use native UITableView                            | Fixed row extents only. Variable-size measurement not ported. `foundation/lists/virtualizer.ts`                                               |

## Extended native behaviors

| Family | Core | Native adapter / upstream source |
| --- | --- | --- |
| Calendar/date | `CalendarDate`, `CalendarSelection` | `BehaviorCalendar`, `BehaviorUIKit.calendar`; Gregorian civil days, month paging, bounded/disabled single or range selection. `foundation/date/plain-date.ts` |
| Color | `ColorValue` | `BehaviorColorPicker`, `BehaviorUIKit.color`; sRGB hex/RGBA/HSV conversion, alpha composition and contrast. `foundation/color/*` |
| Tree/grid | `TreeNavigation`, `GridNavigation` | `BehaviorTree`, `BehaviorGrid`, UIKit factories; visible preorder, expansion, disabled nodes, rectangular/range selection and hardware arrows. `foundation/lists/tree-collection.ts`, `foundation/focus/grid-focus.ts` |
| Drag/drop | `DragDropBehavior` | `behaviorDraggable`, `behaviorDropTarget`; local native ID transfer, accepted types, nested hit testing, final revalidation, cancellation and auto-scroll velocity. `foundation/drag-and-drop/*` |
| 2D resize | `ResizeBehavior` | `BehaviorResizable`; eight edges/corners plus movement, bounded min/max/aspect geometry, drag cancellation, keyboard and accessibility adjustments. `foundation/direct-manipulation/resize.ts` |
| Cropper | `CropSelection` | `BehaviorCropper`, UIKit `BehaviorImageCrop`; pixel-space crop, quarter turns, oriented UIImage export. `foundation/image/crop.ts`, `components/image-cropper/*` |
| Carousel | `CarouselBehavior` | `BehaviorCarousel`; bounded/looping pages, native gestures, keyboard/accessibility adjustment, caller-owned autoplay clock and Reduce Motion. `components/carousel/*` |
| Rich text | `RichTextDocument` | `BehaviorRichTextEditor`, UIKit `BehaviorRichTextView`; TextKit editing, native composition/selection/undo and bold/italic/underline/link spans. `foundation/text/text-editor.ts` |
| Menus | `MenuBehavior` | `BehaviorMenu` uses native Menu; action/toggle/radio/submenu state and disabled ancestor admission. `components/menu/*` |
| Nested overlays | `OverlayStack` | `BehaviorOverlayHost`; native nested sheets, parent/child dismissal, interactive-dismiss policy and host focus-restoration callback. `foundation/popups/*` |
| Agent protocol | `BehaviorAgent`, `AgentStep`, `AgentSnapshot` | Upstream-compatible ref/action/args step shape; opt-in native snapshots/query and host-authorized registered action dispatch. Stale revisions, ambiguous labels, private/read-only/disabled controls fail closed. `page/agent/agent.ts` |
| Measurements | `BehaviorRect` | `behaviorMeasure` and UIKit `BehaviorMeasurement.frame`; explicit native logical-point coordinates, using GeometryReader or UIView-to-window conversion. No DOM emulation. |
| Catalog | Actual production adapters | `Examples/Catalog/ExtendedCatalog.swift` covers every extended family, including a live local agent-to-carousel action. This is a native counterpart to the web catalog, not its HTML/CSS renderer. |

UIKit can embed **all** SwiftUI behavior adapters through `BehaviorController(state:onChange:content:)` using standard view-controller containment. Calendar/color/tree/grid additionally have UIKit factories; rich text and image export have direct UIKit APIs. No application code or services are imported.

Native List, Menu, Picker, Toggle, Button and platform presentation remain appropriate when they already cover the desired behavior. These adapters compose those APIs rather than replacing them.

### Deliberate platform boundaries

This is coverage of every requested behavior family, not every upstream recipe or browser API. Color math is sRGB/HSV, not CSS parsing, named colors, OKLCH or wide-gamut management. Calendar logic is Gregorian, not an alternate-calendar engine. Drag/drop transfers local IDs and never arbitrary files or app objects. Crop export supports quarter turns, not arbitrary-angle perspective correction. Rich text is native attributed text, not a collaborative HTML editor or web plugin system. Overlay positioning/focus trapping and text input/undo remain owned by native presentation/TextKit. Autoplay clocks and persistence belong to the host.

The agent **step** shape is compatible with upstream; native snapshots add revision and point-space metadata. This package does not inject the web observer, install a network listener, infer host authorization or reproduce DOM measurements. Use a transport adapter in the host and an explicit authorization callback. See [agent integration](agents.md).

## Contract boundaries

IDs must be unique and stable. Core state is synchronous value state; callers own
persistence and control updates. Change callbacks are native adapter callbacks,
not a cross-platform event/cancellation kernel. Range selection and toggle-all are
available through core methods; the initial choice adapters do not map Shift/Cmd
shortcuts to those methods. UIKit logical focus methods do not claim to move the
hardware focus engine; use native focus APIs for custom hardware-keyboard routes.

## Chat and viewport behavior

Version 0.3.0 adds `StreamScrollCoordinator`, `ReadingAnchorMemory`,
`ReadingAnchorTracker`, `ActivityDisclosureStore`, `KeyboardViewport` and native
scroll-phase/keyboard adapters. See [streaming chat](chat-interactions.md) for
contracts and the native catalog. These are independent native additions,
informed by observed interactions and Apple's native layout APIs; they do not
import application code or implement a model provider. See
[reference evidence](reference-interactions.md).

### Animated choice layouts

`BehaviorChoiceList` accepts an `AnyLayout`, defaulting to a vertical stack.
Keep the same list and `Selection` binding while changing between stack layouts;
SwiftUI animates the existing controls between positions. The catalog's
`MorphingPlanPicker` demonstrates cards, segments and chips, preserves selection,
and respects Reduce Motion. Layout changes belong to the view; selection, focus
and typeahead remain in the behavior adapter.
