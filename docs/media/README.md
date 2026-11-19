# Native README examples

These GIFs animate actual iOS simulator checkpoints from the production adapters.
They are step-by-step captures, not recordings of gesture timing. Calendar shows
range selection and replacement; drag shows two successful native drops with a
cleared session and one receipt each; crop shows rotation and real pixel export.

The source behavior revision is recorded in [capture.json](capture.json). Captures
used iOS 27.1, the existing 466 × 678 point simulator and default text size. The
right-side system status region was cropped; component pixels were not changed.
Each GIF is under 30 KiB. Browser illustrations and these simulator captures do not
establish physical-device or exhaustive accessibility acceptance.

To regenerate, use the existing catalog scheme and a simulator supported by your
Xcode. Keep DerivedData and result bundles outside the repository:

```sh
xcodegen generate --spec Examples/project.yml
xcodebuild -project Examples/BehaviorCatalog.xcodeproj \
  -scheme BehaviorCatalog -destination 'platform=iOS Simulator,id=YOUR_SIMULATOR_ID' \
  -derivedDataPath "$OUTPUT_ROOT/DerivedData" \
  -resultBundlePath "$OUTPUT_ROOT/ReadmeCaptures.xcresult" \
  -only-testing:BehaviorCatalogUITests/ReadmeCaptureTests \
  CODE_SIGNING_ALLOWED=NO test
xcrun xcresulttool export attachments \
  --path "$OUTPUT_ROOT/ReadmeCaptures.xcresult" \
  --output-path "$OUTPUT_ROOT/readme-frames"
python3 scripts/render-readme-gifs.py "$OUTPUT_ROOT/readme-frames" \
  --revision "$(git rev-parse HEAD)"
```

The renderer needs Python 3 and ffmpeg. Its optional `--crop width:height:x:y`
argument crops system chrome; choose bounds from your fresh screenshots and keep
all behavior content. It preserves frame order, pauses on each checkpoint and
loops without inserting synthetic interaction frames. Inspect every checkpoint
before committing regenerated examples.
