#!/usr/bin/env python3
"""Encode actual XCTest checkpoint screenshots; never synthesize interaction frames."""
import argparse
import json
import pathlib
import re
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("attachments", type=pathlib.Path)
parser.add_argument("--output", type=pathlib.Path, default=pathlib.Path("docs/media"))
parser.add_argument("--crop", help="Optional ffmpeg crop rectangle width:height:x:y")
parser.add_argument("--width", type=int, default=320)
parser.add_argument("--revision", required=True)
args = parser.parse_args()
assert re.fullmatch(r"[0-9a-f]{40}", args.revision)
assert 160 <= args.width <= 1200
if args.crop:
    assert re.fullmatch(r"\d+:\d+:\d+:\d+", args.crop)
manifest = json.loads((args.attachments / "manifest.json").read_text())
args.output.mkdir(parents=True, exist_ok=True)
receipt = {"productionRevision": args.revision, "capture": "ReadmeCaptureTests, iOS simulator", "playback": "Animated native checkpoints; not real-time video", "crop": args.crop, "examples": {}}
for name, count in [("calendar", 5), ("drag", 3), ("crop", 3)]:
    frames = {}
    for test in manifest:
        for attachment in test["attachments"]:
            match = re.match(rf"{name}-(\d+)_", attachment["suggestedHumanReadableName"])
            if match:
                frames[int(match[1])] = args.attachments / attachment["exportedFileName"]
    assert sorted(frames) == list(range(1, count + 1)), (name, frames)
    with tempfile.TemporaryDirectory(dir=args.attachments) as temporary:
        sequence = pathlib.Path(temporary) / "frames.txt"
        lines = []
        for index, frame in sorted(frames.items()):
            filename = str(frame.resolve()).replace("'", "'\\''")
            assert "\n" not in filename
            lines += [f"file '{filename}'", f"duration {2 if index == count else 1.2}"]
        lines.append(f"file '{filename}'")
        sequence.write_text("\n".join(lines) + "\n")
        resize = (f"crop={args.crop}," if args.crop else "") + f"scale={args.width}:-1:flags=lanczos"
        filters = f"[0:v]{resize},split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=sierra2_4a"
        target = args.output / f"{name}.gif"
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(sequence), "-filter_complex", filters, "-fps_mode", "vfr", "-loop", "0", str(target)], check=True)
        assert target.stat().st_size < 1_000_000, "Keep README examples lightweight"
        receipt["examples"][name] = {"checkpoints": count, "bytes": target.stat().st_size}
(args.output / "capture.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt))
