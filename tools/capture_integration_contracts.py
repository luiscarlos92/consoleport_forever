"""Copy exact locked integration sources for offline lifecycle contracts."""
import json
from repository_paths import ROOT, contained, output, sha

FILES = {
    'DynamicCam': ['DynamicCam/Core.lua', 'DynamicCam/DefaultSettings.lua', 'DynamicCam/LICENSE',
        'DynamicCam/Libs/LICENSE.md', 'DynamicCam/Libs/LibStub/LibStub.lua',
        'DynamicCam/Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua',
        'DynamicCam/Libs/AceDB-3.0/AceDB-3.0.lua'],
}

if __name__ == '__main__':
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
