"""Copy exact locked integration sources for offline lifecycle contracts."""
import json
import argparse
import re
from repository_paths import ROOT, contained, output, sha
from pack_format import safe_relative, digest
from verify_pinned_sources import fetch_research_bytes

FILES = {
    'Immersion': ['Immersion/Config.lua', 'Immersion/Settings.lua', 'Immersion/Display/Onload.lua', 'Immersion/Display/Theme.lua', 'Immersion/LICENSE.md',
        'Immersion/Logic/Events.lua', 'Immersion/Logic/Frame.lua', 'Immersion/Logic/Talkbox.lua',
        'Immersion/Components/Elements.lua', 'Immersion/Components/Scaler.lua', 'Immersion/Display/Frame.xml'],
    'Immersion_ExtraFade': ['Immersion_ExtraFade/options.lua', 'Immersion_ExtraFade/main.lua', 'Immersion_ExtraFade/hide_module.lua'],
    'BetterBags': ['BetterBags/integrations/consoleport.lua', 'BetterBags/integrations/masque.lua', 'BetterBags/frames/item.lua', 'BetterBags/frames/bag.lua', 'BetterBags/themes/default.lua', 'BetterBags/themes/elvui.lua', 'BetterBags/LICENSE'],
    'DynamicCam': ['DynamicCam/Core.lua', 'DynamicCam/DefaultSettings.lua', 'DynamicCam/LICENSE',
        'DynamicCam/Libs/LICENSE.md', 'DynamicCam/Libs/LibStub/LibStub.lua',
        'DynamicCam/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua',
        'DynamicCam/Libs/AceDB-3.0/AceDB-3.0.lua'],
}

def restore_manifests(integration_manifests=(), native_manifests=(), fetch=None):
    """Reconstruct ignored inputs from exact manifests, without replacing captures."""
    lock = json.loads((ROOT/'dependencies/lock.json').read_text(encoding='utf-8'))
    packages = {p['repo']:p for p in lock['packages']}
    restored = 0
    def read_manifest(name):
        manifest=contained(ROOT/name)
        if not manifest.is_relative_to(ROOT/'evidence') or not manifest.name.endswith('manifest.json'):
            raise ValueError('Capture manifest must be evidence metadata')
        return manifest,json.loads(manifest.read_text(encoding='utf-8'))
    def retain(target, expected, content):
        nonlocal restored
        if not re.fullmatch('[0-9a-f]{64}',expected): raise ValueError('Invalid pinned capture hash')
        target = output(target)
        if target.exists():
            if sha(target) != expected: raise ValueError('Existing capture drift: '+str(target))
            return
        data = content()
        if digest(data) != expected: raise ValueError('Pinned reconstruction hash mismatch')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        restored += 1
    for name in integration_manifests:
        manifest,metadata = read_manifest(name)
        for row in metadata['files']:
            relative = safe_relative(row['path'])
            package = packages[row['repo']]
            if package['sha256'] != row['packageSHA256'] or package['files'].get(relative.as_posix()) != row['sha256']:
                raise ValueError('Integration manifest differs from current lock')
            source = contained(ROOT/package['unpacked']/relative)
            retain(manifest.parent/relative, row['sha256'], source.read_bytes)
    for name in native_manifests:
        manifest,metadata = read_manifest(name)
        for row in metadata:
            relative = safe_relative(row['file'].replace('\\','/'))
            target = ROOT/relative
            if target.parent != manifest.parent or target.suffix not in {'.lua','.xml'}:
                raise ValueError('Native capture must remain beside its manifest')
            if not re.fullmatch(r'https://raw\.githubusercontent\.com/Gethe/wow-ui-source/[0-9a-f]{40}/Interface/AddOns/[A-Za-z0-9_./-]+',row['source']) or '..' in row['source'].split('/'):
                raise ValueError('Native source must name the pinned source mirror commit')
            retain(target, row['sha256'], lambda: (fetch or fetch_research_bytes)(row['source']))
    return restored

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--from-manifest',action='append',default=[])
    parser.add_argument('--native-manifest',action='append',default=[])
    args=parser.parse_args()
    if args.from_manifest or args.native_manifest:
        print('Reconstructed',restore_manifests(args.from_manifest,args.native_manifest),'pinned contract files')
        raise SystemExit(0)
    lock = json.loads((ROOT / 'dependencies/lock.json').read_text())
    records = []
    for addon, names in FILES.items():
        package = next(p for p in lock['packages'] if addon in p['addonFolders'])
        for name in names:
            source = contained(ROOT / package['unpacked'] / name)
            expected = package['files'][name]
            if sha(source) != expected:
                raise ValueError('Pinned source drift: ' + name)
            target = output(ROOT / 'evidence/integration-contracts' / name)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read_bytes())
            if sha(source) != expected or sha(target) != expected:
                raise ValueError('Source changed during capture: ' + name)
            records.append({'path': name, 'sha256': expected, 'repo': package['repo'],
                'version': package['version'], 'packageSHA256': package['sha256']})
    output(ROOT / 'evidence/integration-contracts/manifest.json').write_text(
        json.dumps({'purpose': 'Exact unmodified integration lifecycle contracts; not deployed dependency copies.',
            'files': records}, indent=2), encoding='utf-8')
    print('Captured', len(records), 'integration contract files')
