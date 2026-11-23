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
for key, title, name, adapter, explanation, usage in recipes:
    caption = {'confirmation': 'Open with Delete project. Cancel keeps the project; Delete calls your callback.', 'selection': 'Team selected after a native tap. Only one plan stays selected.', 'activity': 'Tap the heading to hide or show the files.'}[key]
    source = (root / f'Examples/Catalog/Recipes/{name}.swift').read_text()
    image_path = out / f'{key}.png'
    width, height = struct.unpack('>II', image_path.read_bytes()[16:24]) if image_path.exists() else (1320, 980)
    highlighted = escape(source)
    for token in ['BehaviorChoiceList', 'BehaviorDisclosure', 'behaviorSheet', 'Disclosure', 'Selection&lt;String&gt;']:
        # Highlight identifiers once; do not rewrite the downloadable source.
        if token != 'Disclosure':
            highlighted = highlighted.replace(token, f'<mark>{token}</mark>')
    parts.append(f'''<article class="recipe" id="{key}"><p class="eyebrow">{escape(adapter)}</p><h2>{title}</h2><p>{explanation}</p>
<div class="recipe-grid"><div class="recipe-source"><div class="recipe-label"><span>{name}.swift</span><a href="{name}.swift" download>Download source ↓</a></div><pre><code>{highlighted}</code></pre><div class="recipe-use"><p>Use it in your app</p><pre><code>{escape(usage)}</code></pre></div></div>
<figure class="recipe-result"><div class="recipe-label">ACTUAL iOS SIMULATOR</div><img src="{key}.png" alt="Native SwiftUI {title.lower()}, captured directly from the running component" width="{width}" height="{height}" loading="{'eager' if key=='confirmation' else 'lazy'}"><p>{caption} Captured directly from the running SwiftUI view.</p></figure></div></article>''')
    if args.check:
        if key == 'confirmation':
            assert source.strip() in (root / 'README.md').read_text(), 'README confirmation source drifted'
        assert (out / f'{name}.swift').read_text() == source, f'Stale published source: {name}'
        assert image_path.is_file(), f'Missing native capture: {key}'
        record = receipt['examples'][key]
        assert record['sourceSHA256'] == hashlib.sha256(source.encode()).hexdigest(), f'Stale native capture: {name}'
        assert record['imageSHA256'] == hashlib.sha256(image_path.read_bytes()).hexdigest(), f'Changed native image: {key}'
    else:
        out.mkdir(parents=True, exist_ok=True)
        (out / f'{name}.swift').write_text(source)
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Build components · iosUI-sdk</title><meta name="description" content="Three complete SwiftUI components, their behavior adapters, and real native iOS screenshots."><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,500;12..96,600;12..96,700;12..96,800&display=swap" rel="stylesheet"><link rel="stylesheet" href="../style.css"><link rel="stylesheet" href="recipes.css"></head>
<body><a class="skip" href="#main">Skip to content</a><header><a class="wordmark" href="../">↗ iosUI-sdk</a><nav aria-label="Main"><a href="../docs/">Docs</a><a href="../#install">Install</a><a href="https://github.com/killa-kyle/iosUI-sdk">GitHub ↗</a></nav></header>
<main id="main"><div class="recipe-intro"><p class="eyebrow">SWIFTUI COMPONENT RECIPES</p><h1>Build a component<br>with a behavior.</h1><p>Import a behavior, bind your state, and write the SwiftUI view. Here are three complete examples and what they look like running on iOS.</p><nav class="recipe-nav" aria-label="Component examples"><a href="#confirmation">Confirmation sheet</a><a href="#selection">Plan picker</a><a href="#activity">Tool activity</a></nav></div>
{''.join(parts)}<div class="recipe-foot">Requires iosUI-sdk 0.3.0 and iOS 17+. Add <code>UIBehaviorCore</code> and <code>UIBehaviorSwiftUI</code> to your target. <a href="../#install">Install the package</a> · <a href="https://github.com/killa-kyle/iosUI-sdk/tree/main/Examples/Catalog/Recipes">Browse the compiled sources</a>.<br>These examples use disposable local state. The confirmation callback belongs to your app.</div></main></body></html>'''
target = out / 'index.html'
if args.check:
    assert target.read_text() == html, 'Run python3 scripts/build-component-recipes.py'
else:
    target.write_text(html)
