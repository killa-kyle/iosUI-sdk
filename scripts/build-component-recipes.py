#!/usr/bin/env python3
"""Publish exact, compiled SwiftUI recipes next to their native captures."""
from pathlib import Path
from html import escape
import argparse

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
css = '''.recipe-intro{max-width:1100px;margin:70px auto 44px;padding:0 28px}.recipe-intro h1{font-size:clamp(36px,5vw,64px);letter-spacing:-.05em;line-height:1.05;margin:12px 0 20px}.recipe-intro>p{max-width:650px;font-size:19px;line-height:1.5}.recipe-nav{display:flex;gap:10px;flex-wrap:wrap;margin:28px 0}.recipe-nav a{border:1px solid var(--line);border-radius:30px;padding:12px 18px;background:#fff}.recipe{max-width:1100px;margin:0 auto 80px;padding:0 28px;scroll-margin-top:24px}.recipe h2{font-size:34px;letter-spacing:-.04em;margin-bottom:12px}.recipe>p{max-width:760px;line-height:1.6}.recipe-grid{display:grid;grid-template-columns:minmax(0,1.6fr) minmax(240px,1fr);gap:22px;align-items:start;margin-top:26px}.recipe-source,.recipe-result{border:1px solid var(--line);border-radius:18px;overflow:hidden;background:#fff}.recipe-label{padding:15px 20px;border-bottom:1px solid var(--line);font:12px ui-monospace,monospace;display:flex;justify-content:space-between;gap:10px}.recipe-label a{text-decoration:underline}.recipe-source pre{background:#20251f;color:#eef1e8;margin:0;padding:22px;font:12px/1.65 ui-monospace,SFMono-Regular,monospace;overflow:auto;tab-size:2}.recipe-source mark{background:#d9ed9c;color:#222722;border-radius:3px;padding:1px 2px}.recipe-use{padding:18px 20px}.recipe-use p{margin-top:0;font-size:13px}.recipe-use pre{font-size:12px;padding:14px;border-radius:8px}.recipe-result{margin:0}.recipe-result img{display:block;width:100%;height:auto}.recipe-result p{padding:0 18px;font-size:12px;color:#62685d;line-height:1.5}.recipe-foot{max-width:1044px;margin:0 auto 60px;padding:24px;border:1px solid var(--line);border-radius:16px;line-height:1.6}.recipe-foot a{text-decoration:underline}@media(max-width:760px){.recipe-intro{margin-top:36px}.recipe-grid{grid-template-columns:minmax(0,1fr)}.recipe-result{max-width:340px;justify-self:center;grid-row:1}.recipe-source pre{font-size:11px}.recipe-intro,.recipe{padding:0 18px}}'''
parts = []
out = root / 'site/examples'
for key, title, name, adapter, explanation, usage in recipes:
    source = (root / f'Examples/Catalog/Recipes/{name}.swift').read_text()
    highlighted = escape(source)
    for token in ['BehaviorChoiceList', 'BehaviorDisclosure', 'behaviorSheet', 'Disclosure', 'Selection&lt;String&gt;']:
        # Highlight identifiers once; do not rewrite the downloadable source.
        if token != 'Disclosure':
            highlighted = highlighted.replace(token, f'<mark>{token}</mark>')
    parts.append(f'''<article class="recipe" id="{key}"><p class="eyebrow">{escape(adapter)}</p><h2>{title}</h2><p>{explanation}</p>
<div class="recipe-grid"><div class="recipe-source"><div class="recipe-label"><span>{name}.swift</span><a href="{name}.swift" download>Copy the file ↗</a></div><pre><code>{highlighted}</code></pre><div class="recipe-use"><p>Use it in your app</p><pre><code>{escape(usage)}</code></pre></div></div>
<figure class="recipe-result"><div class="recipe-label">ACTUAL iOS SIMULATOR</div><img src="{key}.png" alt="Native SwiftUI {title.lower()}, built from the source beside it" width="1320" height="2868" loading="{'eager' if key=='confirmation' else 'lazy'}"><p>Built from this Swift file with the package’s native adapters.</p></figure></div></article>''')
    if args.check:
        assert (out / f'{name}.swift').read_text() == source, f'Stale published source: {name}'
        assert (out / f'{key}.png').is_file(), f'Missing native capture: {key}'
    else:
        out.mkdir(parents=True, exist_ok=True)
        (out / f'{name}.swift').write_text(source)
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Build components · iosUI-sdk</title><meta name="description" content="Three complete SwiftUI components, their behavior adapters, and real native iOS screenshots."><link rel="stylesheet" href="../style.css"><style>{css}</style></head>
<body><a class="skip" href="#main">Skip to content</a><header><a class="wordmark" href="../">↗ iosUI-sdk</a><nav aria-label="Main"><a href="../docs/">Docs</a><a href="../#install">Install</a><a href="https://github.com/killa-kyle/iosUI-sdk">GitHub ↗</a></nav></header>
<main id="main"><div class="recipe-intro"><p class="eyebrow">SWIFTUI COMPONENT RECIPES</p><h1>Build a component<br>with a behavior.</h1><p>Import a behavior, bind your state, and write the SwiftUI view. Here are three complete examples and what they look like running on iOS.</p><nav class="recipe-nav" aria-label="Component examples"><a href="#confirmation">Confirmation sheet</a><a href="#selection">Plan picker</a><a href="#activity">Tool activity</a></nav></div>
{''.join(parts)}<div class="recipe-foot">Requires iosUI-sdk 0.3.0 and iOS 17+. Add <code>UIBehaviorCore</code> and <code>UIBehaviorSwiftUI</code> to your target. <a href="../#install">Install the package</a> · <a href="https://github.com/killa-kyle/iosUI-sdk/tree/main/Examples/Catalog/Recipes">Browse the compiled sources</a>.<br>These examples use disposable local state. The confirmation callback belongs to your app.</div></main></body></html>'''
target = out / 'index.html'
if args.check:
    assert target.read_text() == html, 'Run python3 scripts/build-component-recipes.py'
else:
    target.write_text(html)
