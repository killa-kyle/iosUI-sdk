#!/usr/bin/env python3
"""Encode real XCTest recordings; reject broken one-frame video exports."""
import argparse
import json
import pathlib
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("exports", type=pathlib.Path)
parser.add_argument("--revision", required=True)
parser.add_argument("--output", type=pathlib.Path, default=pathlib.Path("docs/media"))
args = parser.parse_args()
assert re.fullmatch(r"[0-9a-f]{40}", args.revision)
manifests = list(args.exports.rglob("manifest.json"))
assert manifests, "Download the native-examples artifacts first"
entries = [(test, manifest.parent) for manifest in manifests for test in json.loads(manifest.read_text())]
args.output.mkdir(parents=True, exist_ok=True)
receipt = {"sourceRevision": args.revision, "capture": "Actual SwiftUI adapters in an iOS simulator; XCTest screen recordings", "styling": "Native CatalogShowcase using the documentation site's palette", "processing": "Trim to verified interaction, reduce to 12 fps, scale, palette encode; no synthetic motion", "examples": {}}
for test, directory in entries:
    match = re.search(r"test(Calendar|Crop|Drag)Video", test["testIdentifier"])
    if not match:
        continue
    kind = match[1].lower()
    attachments = test["attachments"]
    video = next(a for a in attachments if a["exportedFileName"].endswith(".mp4"))
    start = next(a for a in attachments if a["suggestedHumanReadableName"].startswith("README-start"))
    end = next(a for a in attachments if a["suggestedHumanReadableName"].startswith("README-end"))
    source = directory / video["exportedFileName"]
    metadata = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=width,height,nb_frames:format=duration", "-of", "json", str(source)]))
    stream = metadata["streams"][0]
    assert int(stream.get("nb_frames", 0)) > 10, "Broken or one-frame native recording; do not substitute screenshots"
    offset = max(0, start["timestamp"] - video["timestamp"] - 1.1)
    duration = min(float(metadata["format"]["duration"]) - offset, end["timestamp"] - start["timestamp"] + 1.8)
    assert duration > 1, "No usable interaction recording"
    target = args.output / f"{kind}.gif"
    filters = "[0:v]fps=12,scale=400:-2:flags=lanczos,tpad=stop_mode=clone:stop_duration=0.7,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=sierra2_4a"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", str(offset), "-i", str(source), "-t", str(duration + 0.7), "-filter_complex", filters, "-fps_mode", "vfr", "-loop", "0", str(target)], check=True)
    assert target.stat().st_size < 2_000_000, "Keep README media lightweight"
    receipt["examples"][kind] = {"test": test["testIdentifier"], "device": video["deviceName"], "videoFrames": int(stream["nb_frames"]), "trimStart": round(offset, 3), "duration": round(duration, 3), "bytes": target.stat().st_size}
assert set(receipt["examples"]) == {"calendar", "crop", "drag"}, "All three real native recordings are required"
(args.output / "capture.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt))
