# Native README recordings

These GIFs come from XCTest screen recordings of the compiled iOS catalog. The
`--showcase` launch flag applies the site's palette with `CatalogShowcase`; the
controls, state, drag session, crop handles and exporter are actual package adapters.
No browser footage, synthetic motion or moving screenshot layers are used.

Run the **Native example recordings** GitHub workflow (or the `ReadmeCapture`
scheme locally with a compatible standard iPhone simulator). It retains the
screen recordings of `ReadmeCaptureTests`, verifies the resulting state and exports
media, test results and the exact source revision as `native-examples-Calendar`, `native-examples-Crop` and `native-examples-Drag` artifacts. Each runs on a fresh simulator to isolate recording lifecycles.
The main Quality scheme skips these documentary recordings; its behavior replays
and adapter tests remain separate.

Download those artifacts into subdirectories of an external staging directory and encode with Python 3
and ffmpeg:

```sh
python3 scripts/render-native-gifs.py "$OUTPUT_ROOT/native-examples"
```

The renderer aligns checkpoint screenshots with decoded video frames to avoid
simulator clock drift, trims the interaction, scales the image and samples 12
frames per second. It rejects broken one-frame recordings
and requires all three examples. Inspect the full GIF and intermediate drag frames
before committing. The compact [capture receipt](capture.json) records provenance.
These simulator recordings do not establish physical-device or exhaustive
accessibility acceptance; see [validation](../validation.md).

The receipt records each example's actual capture revision. An older recording
can be reused when its component and showcase implementation are unchanged; never
assign a newer revision to existing footage.
