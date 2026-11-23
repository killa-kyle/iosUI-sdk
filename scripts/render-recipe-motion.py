#!/usr/bin/env python3
"""Encode real native recipe recordings; retain intermediate interaction frames."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('exports', type=Path)
parser.add_argument('--staging', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
out = root / 'site/examples'
args.staging.mkdir(parents=True, exist_ok=True)
recipes = {'morph': 'MorphingPlanPicker', 'workspace': 'MediaWorkspace', 'conversation': 'ChatInteractionCatalog', 'selection': 'PlanPicker', 'activity': 'ToolActivity', 'confirmation': 'DeleteProjectButton'}

def probe(path):
    return json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-select_streams', 'v:0', '-show_entries', 'stream=width,height,nb_frames:format=duration', '-of', 'json', str(path)]))

def moment(video, checkpoint, start, first=False):
    # Find real checkpoint pixels, excluding status chrome, rather than relying
    # on wall-clock timestamps that can drift during simulator startup.
    w, h, rate = 120, 260, 6
    scale = f'scale={w}:{h}:flags=area,format=gray'
    ref = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(checkpoint), '-vf', scale, '-frames:v', '1', '-f', 'rawvideo', '-'])
    frames = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(video), '-vf', f'setpts=PTS-STARTPTS,fps={rate},'+scale, '-f', 'rawvideo', '-'])
    size = w*h
    indices = range(w*20, w*240, 2)
    scores = [sum((frames[offset+i]-ref[i])**2 for i in indices) for offset in range(0, len(frames)-size+1, size)]
    best = min(scores)
    matches = [i for i, score in enumerate(scores) if score <= best*1.02+1]
    clusters = [[matches[0]]]
    for i in matches[1:]:
        if i-clusters[-1][-1] > 2: clusters.append([])
        clusters[-1].append(i)
    return (clusters[0][-1] if start else clusters[0][0] if first else clusters[-1][0])/rate

entries = [(test, manifest.parent) for manifest in args.exports.rglob('manifest.json') for test in json.loads(manifest.read_text())]
producer_paths = ['Examples/Catalog/ComponentRecipes.swift', 'Examples/Catalog/CatalogShowcase.swift', 'Examples/Catalog/App.swift', 'Examples/Catalog/ChatInteractionCatalog.swift', 'Sources/UIBehaviorSwiftUI/BehaviorChoiceList.swift', 'Examples/UITests/RecipeMotionCaptureTests.swift']
producer_hashes = {}
receipt = {'capture': 'Actual native iOS simulator screen recordings of the compiled SwiftUI recipes', 'processing': 'Pixel-match native checkpoints, trim idle lead-in, crop by measured native bounds, resize and encode. GIFs preserve native motion; no generated interaction frames.', 'examples': {}}
for key, component in recipes.items():
    name = f'RecipeMotionCaptureTests/test{key.title()}Video()'
    test, directory = next((t,d) for t,d in entries if t['testIdentifier'] == name)
    summary = json.loads((directory/'summary.json').read_text())
    assert summary['result'] == 'Passed', f'Native motion replay failed: {key}'
    revision = (directory/'source-revision.txt').read_text().strip()
    for path in producer_paths:
        current = (root/path).read_bytes()
        assert current == subprocess.check_output(['git','show',f'{revision}:{path}'],cwd=root), f'Native recording fixture changed: {path}'
        producer_hashes[path] = hashlib.sha256(current).hexdigest()
    source_path = f'Examples/Catalog/{component}.swift' if key == 'conversation' else f'Examples/Catalog/Recipes/{component}.swift'
    source = (root/source_path).read_bytes()
    assert source == subprocess.check_output(['git','show',f'{revision}:{source_path}'],cwd=root), 'Capture source changed'
    attachments = test['attachments']
    def attachment(prefix):
        a = next(a for a in attachments if a['suggestedHumanReadableName'].startswith(prefix))
        return directory/a['exportedFileName']
    video = directory/next(a['exportedFileName'] for a in attachments if a['exportedFileName'].endswith('.mp4'))
    metadata = probe(video)
    stream = metadata['streams'][0]
    assert int(stream.get('nb_frames',0)) > 10, 'Reject broken one-frame recordings'
    start = max(0, moment(video, attachment('MOTION-start'), True)-0.4)
    end = min(float(metadata['format']['duration']), moment(video, attachment('MOTION-end'), False)+1)
    assert end-start > 1, 'No usable native interaction interval'
    geometry = json.loads(attachment('motion-geometry').read_text())
    width, height = int(stream['width']), int(stream['height'])
    crop = [0,0,width,height]
    if 'component' in geometry:
        x,y,w,h = geometry['component']
        wx,wy,ww,wh = geometry['window']
        sx,sy = width/ww,height/wh
        left,top = max(0,int((x-wx-8)*sx)),max(0,int((y-wy-8)*sy))
        right,bottom = min(width,int((x-wx+w+8)*sx)),min(height,int((y-wy+h+8)*sy))
        crop = [left,top,right-left,bottom-top]
    if key == 'morph':
        crop = [int(width*0.045), int(height*0.28), int(width*0.91), int(height*0.55)]
    if key == 'confirmation':
        top = int(height*0.25)
        crop = [0, top, width, height-top]
    x,y,w,h = crop
    spatial = f'crop={w}:{h}:{x}:{y}'
    trim = f'setpts=PTS-STARTPTS,trim=start={start}:end={end},setpts=PTS-STARTPTS'
    target = out/f'{key}.gif'
    filters = f'{trim},{spatial},fps=12,scale=480:-2:flags=lanczos,tpad=stop_mode=clone:stop_duration=0.7,split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=sierra2_4a'
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(video),'-filter_complex',filters,'-fps_mode','vfr','-loop','0',str(target)],check=True)
    assert target.stat().st_size < 6_000_000, 'Keep native example GIF under 6 MB'
    poster_checkpoint = {'selection':'MOTION-team','activity':'MOTION-start','confirmation':'MOTION-open', 'morph':'MOTION-start', 'workspace':'MOTION-crop', 'conversation':'MOTION-reading'}[key]
    poster_time = moment(video, attachment(poster_checkpoint), False)
    poster = out/f'{key}-poster.png'
    subprocess.run(['ffmpeg','-v','error','-y','-ss',str(poster_time),'-i',str(video),'-vf',f'{spatial},scale=800:-2:flags=lanczos','-frames:v','1',str(poster)],check=True)
    hero_spatial = spatial
    if key == 'morph':
        crop = [int(width*0.045), int(height*0.28), int(width*0.91), int(height*0.55)]
    if key == 'confirmation':
        top = int(height*0.60)
        hero_spatial = f'crop={width}:{height-top}:0:{top}'
    hero_end = end
    if key == 'confirmation':
        hero_end = min(end, moment(video, attachment('MOTION-open'), False, first=True)+1.1)
    elif key == 'activity':
        hero_end = min(end, moment(video, attachment('MOTION-reopened'), False)+0.9)
    hero_trim = f'setpts=PTS-STARTPTS,trim=start={start}:end={hero_end},setpts=PTS-STARTPTS'
    native_clip = args.staging/f'{key}.mp4'
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(video),'-vf',f'{hero_trim},{hero_spatial},scale=720:-2:flags=lanczos,setsar=1,format=yuv420p','-an','-c:v','libx264','-preset','fast','-crf','18','-movflags','+faststart',str(native_clip)],check=True)
    px = struct.unpack('>II',poster.read_bytes()[16:24])
    receipt['examples'][key] = {'sourceRevision':revision,'source':source_path,'sourceSHA256':hashlib.sha256(source).hexdigest(),'test':name,'runtime':[d['device'] for d in summary['devicesAndConfigurations']],'sourceVideoSHA256':hashlib.sha256(video.read_bytes()).hexdigest(),'sourceVideoFrames':int(stream['nb_frames']),'trimSeconds':[round(start,3),round(end,3)],'cropPixels':crop,'heroTrimSeconds':[round(start,3),round(hero_end,3)],'gifSHA256':hashlib.sha256(target.read_bytes()).hexdigest(),'posterSHA256':hashlib.sha256(poster.read_bytes()).hexdigest(),'gifBytes':target.stat().st_size,'posterPixels':list(px)}
receipt['producerInputsSHA256'] = producer_hashes
(out/'motion.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
