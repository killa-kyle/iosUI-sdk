# README examples

These GIFs capture the actual documentation previews using the site's own CSS.
Playwright drives the pointer and takes intermediate browser frames; ffmpeg
encodes them into looping GIFs. Drag/drop visibly moves the card into its target,
and crop visibly resizes the aspect-constrained selection. No synthetic motion
frames or separate visual mockups are inserted.

These are browser illustrations of behavior contracts. They do not execute Swift
or establish native, physical-device or accessibility acceptance. Native replay
coverage and its limits are recorded in [validation](../validation.md).

To regenerate, use Node 24, ffmpeg and an isolated Playwright 1.63.0 installation.
Pass an external staging directory so PNG frames stay outside the repository:

```sh
PLAYWRIGHT_MODULE=/path/to/isolated/playwright/index.mjs \
  node scripts/capture-readme-gifs.mjs "$OUTPUT_ROOT/readme-frames"
```

The script serves the existing site on loopback, verifies the resulting date
range/drop/geometry state, captures real interactions, and writes the final GIFs
and compact [capture receipt](capture.json) here. Inspect the full animation and
its intermediate frames before committing regenerated examples.
