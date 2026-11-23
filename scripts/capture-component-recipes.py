#!/usr/bin/env python3
"""Publish unmodified XCUIElement captures tied to their compiled Swift sources."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument('--attachments', type=Path, required=True)
parser.add_argument('--summary', type=Path, required=True)
parser.add_argument('--source-revision', required=True)
parser.add_argument('--tested-checkout', required=True)
parser.add_argument('--run-url', required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
summary = json.loads(args.summary.read_text())
assert summary['result'] == 'Passed', 'Native replay must pass before publishing captures'
manifest = json.loads((args.attachments / 'manifest.json').read_text())
recipes = {
    'confirmation': ('DeleteProjectButton', 'testConfirmationCancelAndConfirm'),
    'selection': ('PlanPicker', 'testPlanSelection'),
    'activity': ('ToolActivity', 'testActivityDisclosure'),
}
receipt = {
    'sourceRevision': args.source_revision,
    'testedCheckout': args.tested_checkout,
    'run': args.run_url,
    'capture': 'Unmodified XCUIElement.screenshot() from actual native SwiftUI components. Full-screen checkpoints are also attached to the test report.',
    'runtime': [entry['device'] for entry in summary['devicesAndConfigurations']],
    'nativeResult': summary['result'],
    'examples': {},
}
out = root / 'site/examples'
for key, (name, method) in recipes.items():
    source_path = f'Examples/Catalog/Recipes/{name}.swift'
    source = (root / source_path).read_bytes()
    committed = subprocess.check_output(['git', 'show', f'{args.source_revision}:{source_path}'], cwd=root)
    assert source == committed, f'Capture source differs from compiled revision: {name}'
    matches = []
    for test in manifest:
        if test['testIdentifier'] != f'ComponentRecipeTests/{method}()':
            continue
        for attachment in test['attachments']:
            label = attachment.get('suggestedHumanReadableName', '')
            if label.startswith(f'recipe-{key}_') and attachment['exportedFileName'].endswith('.png'):
                matches.append(attachment)
    assert matches, f'Missing real component capture: {key}'
    selected = max(matches, key=lambda item: item['timestamp'])
    image = args.attachments / selected['exportedFileName']
    target = out / f'{key}.png'
    shutil.copy2(image, target)
    data = target.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width, height = struct.unpack('>II', data[16:24])
    receipt['examples'][key] = {
        'source': source_path,
        'sourceSHA256': hashlib.sha256(source).hexdigest(),
        'imageSHA256': hashlib.sha256(data).hexdigest(),
        'test': f'ComponentRecipeTests/{method}()',
        'imagePixels': [width, height],
        'bytes': len(data),
    }
(out / 'capture.json').write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
