#!/usr/bin/env python3
"""Publish exact, compiled SwiftUI recipes next to their native captures."""
from pathlib import Path
from html import escape
import argparse
import hashlib
import json
import struct

parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
recipes = [
    ('morph', 'Cards, segments and chips', 'MorphingPlanPicker', 'Selection + BehaviorChoiceList + AnyLayout',
     'Change the layout while keeping the same controls and Selection binding. SwiftUI moves the controls between cards, segments and chips. Team stays selected; choosing Studio updates the same model.',
     'MorphingPlanPicker()'),
    ('conversation', 'Read while a response streams', 'ChatInteractionCatalog', 'StreamScrollCoordinator + ReadingAnchorTracker + ActivityDisclosureStore + KeyboardViewport',
     'The conversation follows incoming output until you scroll back. It keeps the reading row in place through history insertion and layout changes. Tool expansion survives stream updates. The composer uses the native keyboard guide. Compact, expanded and tabletop are explicit layout previews.',
     'ChatInteractionCatalog()'),
    ('workspace', 'Crop, review and publish', 'MediaWorkspace', 'CropSelection + OverlayStack + Selection',
     'Edit a draft crop, open a nested publishing sheet, and return to the crop without losing edits. Cancel keeps the saved cover. Publish exports the crop, commits the draft and dismisses both sheets. The host owns the transaction and caption; the package handles crop geometry, selection and overlay transitions.',
     'MediaWorkspace()'),
    ('confirmation', 'A confirmation sheet', 'DeleteProjectButton', 'Disclosure + behaviorSheet',
     'Disclosure owns open and dismiss state. SwiftUI presents the sheet. Your view supplies the title, actions and layout.',
     'DeleteProjectButton(project: "Weekend project") {\n  deleteProject()\n}'),
    ('selection', 'A plan picker', 'PlanPicker', 'Selection + BehaviorChoiceList',
     'The adapter supplies native buttons, selection, keyboard focus and typeahead. The row closure supplies the cards you see.',
     'import SwiftUI\nimport UIBehaviorCore\n\nstruct SettingsView: View {\n  @State private var plan = Selection<String>(selected: ["Personal"])\n\n  var body: some View {\n    PlanPicker(selection: $plan)\n  }\n}'),
    ('activity', 'Expandable tool activity', 'ToolActivity', 'Disclosure + BehaviorDisclosure',
     'Disclosure stores whether the details are open. The adapter binds it to a native DisclosureGroup. You supply both views.',
     'ToolActivity()'),
]

parts = []
out = root / 'site/examples'
receipt = json.loads((out / 'capture.json').read_text()) if args.check else None
motion = json.loads((out / 'motion.json').read_text()) if (out / 'motion.json').exists() else None
for key, title, name, adapter, explanation, usage in recipes:
    caption = {'morph': 'Team stays selected through each shape change. Studio is selected at the end.', 'workspace': 'Rotate the draft, choose a destination, return to the crop, then publish.', 'conversation': 'Scroll back during streaming, load history, return to latest, change the layout and type a draft.', 'confirmation': 'Open with Delete project. Cancel keeps the project; Delete calls your callback.', 'selection': 'Team selected after a native tap. Only one plan stays selected.', 'activity': 'Tap the heading to hide or show the files.'}[key]
    source_path = root / (f'Examples/Catalog/{name}.swift' if key == 'conversation' else f'Examples/Catalog/Recipes/{name}.swift')
    source = source_path.read_text()
    image_file = f'{key}-poster.png' if motion and key in motion['examples'] else f'{key}.png'
    motion_attr = f' data-motion-src="{key}.gif"' if motion else ''
    image_path = out / image_file
    width, height = struct.unpack('>II', image_path.read_bytes()[16:24]) if image_path.exists() else (1320, 980)
    excerpt = source
    if key == 'conversation':
        excerpt = '\n'.join(source.splitlines()[6:9]) + '\n\n' + '\n'.join(source.splitlines()[226:242]) + '\n\n' + '\n'.join(source.splitlines()[260:279])
    elif key == 'workspace':
        excerpt = '\n'.join(source.splitlines()[8:17]) + '\n\n' + '\n'.join(source.splitlines()[46:62]) + '\n\n' + '\n'.join(source.splitlines()[80:91])
    highlighted = escape(excerpt)
    for token in ['BehaviorChoiceList', 'BehaviorDisclosure', 'behaviorSheet', 'Disclosure', 'Selection&lt;String&gt;', 'StreamScrollCoordinator', 'ReadingAnchorTracker', 'ActivityDisclosureStore', 'BehaviorKeyboardObserver', 'BehaviorCropper', 'CropSelection', 'BehaviorOverlayHost', 'OverlayStack', 'AnyLayout']:
        # Highlight identifiers once; do not rewrite the downloadable source.
        if token != 'Disclosure':
            highlighted = highlighted.replace(token, f'<mark>{token}</mark>')
    full_source = f'<details class="full-source"><summary>Complete component source</summary><pre><code>{escape(source)}</code></pre></details>' if excerpt != source else ''
    parts.append(f'''<article class="recipe" id="{key}"><p class="eyebrow">{escape(adapter)}</p><h2>{title}</h2><p>{explanation}</p>
<div class="recipe-grid"><div class="recipe-source"><div class="recipe-label"><span>{name}.swift{" · orchestration excerpt" if excerpt != source else ""}</span><a href="{name}.swift" download>Download source ↓</a></div><pre><code>{highlighted}</code></pre>{full_source}<div class="recipe-use"><p>Use it in your app</p><pre><code>{escape(usage)}</code></pre></div></div>
<figure class="recipe-result"><div class="recipe-label">iOS SIMULATOR RECORDING</div><img src="{image_file}"{motion_attr} alt="Native SwiftUI {title.lower()}, captured directly from the running component" width="{width}" height="{height}" loading="{'eager' if key=='confirmation' else 'lazy'}"><p>{caption}</p><button class="figure-motion" type="button" data-motion-toggle hidden>Pause motion</button></figure></div></article>''')
    if args.check:
        if key == 'confirmation':
            assert source.strip() in (root / 'README.md').read_text(), 'README confirmation source drifted'
        assert (out / f'{name}.swift').read_text() == source, f'Stale published source: {name}'
        if key in ['confirmation', 'selection', 'activity']:
            assert (out / f'{key}.png').is_file(), f'Missing native capture: {key}'
            record = receipt['examples'][key]
            assert record['sourceSHA256'] == hashlib.sha256(source.encode()).hexdigest(), f'Stale native capture: {name}'
            assert record['imageSHA256'] == hashlib.sha256((out / f'{key}.png').read_bytes()).hexdigest(), f'Changed native image: {key}'
        if motion:
            clip = motion['examples'][key]
            assert clip['sourceSHA256'] == hashlib.sha256(source.encode()).hexdigest(), f'Stale motion capture: {key}'
            assert clip['gifSHA256'] == hashlib.sha256((out / f'{key}.gif').read_bytes()).hexdigest(), f'Changed GIF: {key}'
            assert clip['posterSHA256'] == hashlib.sha256(image_path.read_bytes()).hexdigest(), f'Changed poster: {key}'
    else:
        out.mkdir(parents=True, exist_ok=True)
        (out / f'{name}.swift').write_text(source)
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Build components · iosUI-sdk</title><meta name="description" content="SwiftUI examples with shared behavior, coordinated interactions and native recordings."><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,500;12..96,600;12..96,700;12..96,800&display=swap" rel="stylesheet"><link rel="stylesheet" href="../style.css"><link rel="stylesheet" href="recipes.css"><script src="../motion.js" defer></script></head>
<body><a class="skip" href="#main">Skip to content</a><header><a class="wordmark" href="../">↗ iosUI-sdk</a><nav aria-label="Main"><a href="../docs/">Docs</a><a href="../#install">Install</a><a href="https://github.com/killa-kyle/iosUI-sdk">GitHub ↗</a></nav></header>
<main id="main"><div class="recipe-intro"><p class="eyebrow">SWIFTUI COMPONENT RECIPES</p><h1>Components built<br>with shared behavior.</h1><p>Import a behavior, bind your state, and write the SwiftUI view. See state survive a layout change, a streaming update and a nested editing flow.</p><button type="button" data-motion-toggle hidden>Pause motion</button><nav class="recipe-nav" aria-label="Component examples"><a href="#morph">Morphing controls</a><a href="#conversation">Streaming conversation</a><a href="#workspace">Media workspace</a><a href="#confirmation">Confirmation sheet</a><a href="#selection">Plan picker</a><a href="#activity">Tool activity</a></nav></div>
{''.join(parts)}<div class="recipe-foot">Requires iosUI-sdk 0.4.0 and iOS 17+. Add <code>UIBehaviorCore</code> and <code>UIBehaviorSwiftUI</code> to your target. <a href="../#install">Install the package</a> · <a href="https://github.com/killa-kyle/iosUI-sdk/tree/main/Examples/Catalog/Recipes">Browse the compiled sources</a>.<br>These examples use disposable local state. The confirmation callback belongs to your app.</div></main></body></html>'''
if args.check:
    assert motion, 'Record the native recipe GIFs before publishing'
    for path, expected in motion['producerInputsSHA256'].items():
        assert hashlib.sha256((root / path).read_bytes()).hexdigest() == expected, f'Stale native recording fixture: {path}'
    hero_dir = root / 'site/motion'
    hero = json.loads((hero_dir / 'capture.json').read_text())
    assert hero['sha256'] == hashlib.sha256((hero_dir / 'hero.mp4').read_bytes()).hexdigest(), 'Changed hero video'
    assert hero['posterSHA256'] == hashlib.sha256((hero_dir / 'poster.png').read_bytes()).hexdigest(), 'Changed hero poster'
    assert hero['graphicsSourceSHA256'] == hashlib.sha256((root / 'scripts/hero-stage.html').read_bytes()).hexdigest(), 'Stale hero graphics'
    assert hero['rendererSourceSHA256'] == hashlib.sha256((root / 'scripts/render-hero-film.mjs').read_bytes()).hexdigest(), 'Stale hero renderer'
    assert hero['nativeMotionReceiptSHA256'] == hashlib.sha256((out / 'motion.json').read_bytes()).hexdigest(), 'Stale native hero footage'
target = out / 'index.html'
if args.check:
    assert target.read_text() == html, 'Run python3 scripts/build-component-recipes.py'
else:
    target.write_text(html)
