# Component recipe captures

The examples at `site/examples/` use compiled SwiftUI components in
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

## Motion examples and hero

`RecipeMotionCaptureTests`, run only with the ReadmeCapture scheme, records native
morphing choice layouts, crop publishing, streaming chat, selection changes, activity expansion and sheet presentation. The `--motion-capture`
fixture gives activity a stable recording canvas so surrounding demo copy stays
outside the frame while the real component animates.

The existing Native example recordings workflow accepts `suite: recipes` for a
single six-test recording job. Its artifact includes actual screen recordings,
checkpoints, measured native bounds, a passing summary and source revision.

```sh
python3 scripts/render-recipe-motion.py "$RECIPE_EXPORTS" --staging "$RECIPE_STAGING"
PLAYWRIGHT_MODULE="$RECIPE_PLAYWRIGHT_MODULE" node scripts/render-hero-film.mjs "$RECIPE_STAGING"
python3 scripts/build-component-recipes.py
python3 scripts/build-component-recipes.py --check
```

The GIF encoder matches real checkpoint pixels, retains intermediate motion,
crops using native measurements, and encodes 12 fps loops. Hero chapters compose
real native clips with authored typography/code animation and explicitly excerpted
component source. The hero uses silent H.264, 30 seconds, 1280×720, 30 fps. Source and
asset hashes are recorded in `site/examples/motion.json` and `site/motion/capture.json`.
Motion respects the browser's reduced-motion preference and has explicit play/pause
controls. Static posters have matching GIF aspect ratios to keep layout stable.
