"""Capture source-only inputs for the isolated R16 experiment; never read live WoW."""
import hashlib
import json
import sys
import urllib.request
from datetime import datetime, timezone

from repository_paths import ROOT, output

BASE = ROOT / 'scratch/pawn-immersion-inputs'
MANIFEST = ROOT / 'evidence/pawn-immersion/2026-10-16/experiment-inputs.json'
PIN = '09b9db7948abc9b9648dedaab51eb0cf3ee67b31'
GROUPS = [
    ('VgerMods/Pawn', 'Pawn-2.13.17', 'Pawn',
     ['Pawn.lua', 'PawnBags.lua', 'Core.lua', 'Localization.lua', 'VgerCore/VgerCore.lua', 'Readme.md']),
    ('Cidan/BetterBags', 'v0.5.14', 'BetterBags',
     ['integrations/pawn.lua', 'data/items.lua', 'frames/item.lua', 'themes/themes.lua']),
    ('Cidan/BetterBags', 'v0.5.16', 'BetterBagsPrepared',
     ['integrations/pawn.lua', 'data/items.lua']),
    ('seblindfors/Immersion', '1.4.61', 'Immersion',
     ['Components/Elements.lua', 'Components/Tooltip.lua', 'Components/Scaler.lua', 'Logic/Frame.lua',
      'Logic/Inspector.lua', 'Logic/Controller.lua', 'Display/Frame.xml', 'Utils.lua']),
    ('Gethe/wow-ui-source', PIN, 'Native',
     ['Interface/AddOns/Blizzard_ItemButton/Mainline/ItemButtonTemplate.xml',
      'Interface/AddOns/Blizzard_ItemButton/Shared/ItemButtonTemplate.xml',
      'Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.xml',
      'Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.lua',
      'Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipComparisonManager.lua']),
]


def main():
    output(MANIFEST)
    output(BASE)
    prior = json.loads(MANIFEST.read_text()) if MANIFEST.exists() else None
    expected = {row['path']: row['sha256'] for row in prior['files']} if prior else {}
    rows = []
    for repo, ref, group, paths in GROUPS:
        for path in paths:
            relative = f'{group}/{path}'
            url = f'https://raw.githubusercontent.com/{repo}/{ref}/{path}'
            request = urllib.request.Request(url, headers={'User-Agent': 'Forever-R16-source-experiment'})
            with urllib.request.urlopen(request, timeout=30) as response:
                data = response.read()
            digest = hashlib.sha256(data).hexdigest()
            if relative in expected and expected[relative] != digest:
                raise ValueError('Pinned experiment input changed: ' + relative)
            target = output(BASE / relative)
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest() != digest:
                raise ValueError('Existing experiment copy drift: ' + relative)
            target.write_bytes(data)
            rows.append({'path': relative, 'repo': repo, 'ref': ref, 'url': url,
                         'sha256': digest, 'bytes': len(data)})
    if not prior or set(expected) != {row['path'] for row in rows}:
        result = {'capturedAt': datetime.now(timezone.utc).isoformat(),
                  'purpose': 'R16 isolated source execution only; no package/install',
                  'copyRoot': BASE.relative_to(ROOT).as_posix(), 'files': rows}
        target = output(MANIFEST)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'sourceFiles': len(rows), 'manifest': MANIFEST.relative_to(ROOT).as_posix()}))


if __name__ == '__main__':
    if '--runtime' in sys.argv:
        MANIFEST = ROOT / 'evidence/pawn-immersion/2026-10-16/runtime-inputs.json'
        GROUPS = GROUPS + [
            ('VgerMods/Pawn', 'Pawn-2.13.17', 'Pawn', ['Pawn.toc', 'PawnUI.xml']),
            ('seblindfors/Immersion', '1.4.61', 'Immersion', ['Immersion.toc', 'Logic/Events.lua']),
            ('Cidan/BetterBags', 'v0.5.14', 'BetterBags',
             ['core/init.lua']),
        ]
    main()
