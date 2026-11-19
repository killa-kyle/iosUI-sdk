# iosUI-sdk

Independent Swift package. No application dependencies, secrets, analytics or services.
Read README.md and docs/coverage.md before adding behaviors. Keep state transitions
in UIBehaviorCore, SwiftUI bindings in UIBehaviorSwiftUI, UIKit in UIBehaviorUIKit.
Use native accessibility, keyboard, presentation and gesture APIs. Do not emulate a DOM.
Write meaningful transition tests for new behaviors and compose the actual adapters
in Examples/Catalog. Do not describe host tests as on-device acceptance.
Keep API names and installation examples synchronized with the package products.
Record upstream source paths and semantic differences in docs/coverage.md.
Build outputs and validation staging belong outside the source checkout.

Before building an app component with this package, follow skills/iosui-sdk/SKILL.md
if available and read the installed revision's API/source and docs/coverage.md.
The skill is consumer guidance; these instructions govern package contributions.
