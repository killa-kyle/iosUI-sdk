# Component recipe captures

The examples at `site/examples/` use the three actual SwiftUI components in
`Examples/Catalog/Recipes`. `ComponentRecipeTests` opens a native confirmation
sheet, selects a plan and collapses/reopens tool activity. It attaches both the
component's own `XCUIElement.screenshot()` and a full-screen checkpoint.

Use the existing Quality workflow or run the `BehaviorCatalog` scheme with
`-only-testing:BehaviorCatalogUITests/ComponentRecipeTests` on an available iPhone
simulator. Keep DerivedData and result bundles outside the checkout.

Export the passing result bundle:

```sh
xcrun xcresulttool export attachments --path "$RECIPE_RESULT" --output-path "$RECIPE_ATTACHMENTS"
xcrun xcresulttool get test-results summary --path "$RECIPE_RESULT" --format json > "$RECIPE_SUMMARY"
python3 scripts/capture-component-recipes.py \
  --attachments "$RECIPE_ATTACHMENTS" --summary "$RECIPE_SUMMARY" \
  --source-revision "$RECIPE_SOURCE_SHA" --tested-checkout "$RECIPE_CHECKOUT_SHA" \
  --run-url "$RECIPE_RUN_URL"
python3 scripts/build-component-recipes.py
python3 scripts/build-component-recipes.py --check
```

`RECIPE_SOURCE_SHA` identifies the component source committed before the run.
For a pull-request CI run, `RECIPE_CHECKOUT_SHA` records the tested merge checkout.
The capture script verifies committed source bytes before copying the native PNGs.
It applies no image processing. `site/examples/capture.json` records runtime,
test identifiers, source hashes and image hashes. The website check rejects stale
source listings, stale captures and changed image bytes.
