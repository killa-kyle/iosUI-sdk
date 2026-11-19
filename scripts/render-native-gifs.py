#!/usr/bin/env python3
"""Encode real XCTest recordings; reject broken one-frame video exports."""
import argparse
import json
import pathlib
import re
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("exports", type=pathlib.Path)
parser.add_argument("--output", type=pathlib.Path, default=pathlib.Path("docs/media"))
args = parser.parse_args()

def checkpoint_time(source, image, last):
    # Native recording wall-clock timestamps can drift during simulator startup.
    # Match the actual checkpoint pixels to decoded video, excluding status chrome.
    width, height, rate = 120, 260, 6
    scale = f"scale={width}:{height}:flags=area,format=gray"
    reference = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(image), "-vf", scale, "-frames:v", "1", "-f", "rawvideo", "-"])
    decoded = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(source), "-vf", f"setpts=PTS-STARTPTS,fps={rate}," + scale, "-f", "rawvideo", "-"])
    frame_bytes = width * height
    indices = range(width * 20, width * 220, 2)
    scores = []
    for offset in range(0, len(decoded), frame_bytes):
        frame = decoded[offset:offset + frame_bytes]
        if len(frame) != frame_bytes: continue
        scores.append(sum((frame[i] - reference[i]) ** 2 for i in indices))
    best = min(scores)
    matches = [i for i, score in enumerate(scores) if score <= best * 1.02 + 1]
    moment = (matches[-1] if last else matches[0]) / rate
    if last:
        # Remove idle lead-in, while retaining real press/drag motion and timing.
        for index in range(int((moment + 0.7) * rate), len(scores)):
            current = decoded[index * frame_bytes:(index + 1) * frame_bytes]
            previous = decoded[(index - 1) * frame_bytes:index * frame_bytes]
            if sum(abs(current[i] - previous[i]) for i in indices) > 250:
                return max(moment, index / rate - 0.6)
    return moment

manifests = list(args.exports.rglob("manifest.json"))
assert manifests, "Download the native-examples artifacts first"
entries = [(test, manifest.parent) for manifest in manifests for test in json.loads(manifest.read_text())]
args.output.mkdir(parents=True, exist_ok=True)
receipt = {"capture": "Actual SwiftUI adapters in an iOS simulator; XCTest screen recordings", "styling": "Native CatalogShowcase using the documentation site's palette", "processing": "Align real checkpoint pixels to the recording, trim to the verified interaction, reduce to 12 fps, scale, palette encode; no synthetic motion", "examples": {}}
for test, directory in entries:
    match = re.search(r"test(Calendar|Crop|Drag)Video", test["testIdentifier"])
    if not match:
        continue
    kind = match[1].lower()
    revision = (directory / "source-revision.txt").read_text().strip()
    assert re.fullmatch(r"[0-9a-f]{40}", revision)
    attachments = test["attachments"]
    video = next(a for a in attachments if a["exportedFileName"].endswith(".mp4"))
    start = next(a for a in attachments if a["suggestedHumanReadableName"].startswith("README-start"))
    end = next(a for a in attachments if a["suggestedHumanReadableName"].startswith("README-end"))
    source = directory / video["exportedFileName"]
    metadata = json.loads(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "stream=width,height,nb_frames:format=duration", "-of", "json", str(source)]))
    stream = metadata["streams"][0]
    assert int(stream.get("nb_frames", 0)) > 10, "Broken or one-frame native recording; do not substitute screenshots"
    begin = checkpoint_time(source, directory / start["exportedFileName"], last=True)
    finish = checkpoint_time(source, directory / end["exportedFileName"], last=False)
    offset = max(0, begin)
    duration = min(float(metadata["format"]["duration"]) - offset, finish - offset + 0.8)
    assert duration > 1, "No usable interaction recording"
    target = args.output / f"{kind}.gif"
    filters = f"[0:v]setpts=PTS-STARTPTS,trim=start={offset}:end={offset + duration},setpts=PTS-STARTPTS,fps=12,scale=400:-2:flags=lanczos,tpad=stop_mode=clone:stop_duration=0.7,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=sierra2_4a"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(source), "-filter_complex", filters, "-fps_mode", "vfr", "-loop", "0", str(target)], check=True)
    assert target.stat().st_size < 2_000_000, "Keep README media lightweight"
    receipt["examples"][kind] = {"sourceRevision": revision, "test": test["testIdentifier"], "device": video["deviceName"], "videoFrames": int(stream["nb_frames"]), "trimStart": round(offset, 3), "duration": round(duration, 3), "bytes": target.stat().st_size}
assert set(receipt["examples"]) == {"calendar", "crop", "drag"}, "All three real native recordings are required"
(args.output / "capture.json").write_text(json.dumps(receipt, indent=2) + "\n")
print(json.dumps(receipt))
