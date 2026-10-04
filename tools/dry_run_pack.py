"""Exercise a complete delivered pack on fresh copied references only."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path, PureWindowsPath
import subprocess
import tempfile
from repository_paths import ROOT, output, fixture_copy, immutable_hashes, sha
from pack_format import read_pack
from deployment_guard import GameTree, inventory, verify_backup
from install_pack import install, restore


def dry_run(pack, checksum):
    manifest, _ = read_pack(pack, checksum, True)
    sources = [ROOT/'reference/installed-addons/2026-10-03-initial', ROOT/'reference/config/2026-10-03-initial']
    before = [immutable_hashes(path) for path in sources]
    scope = output(Path(tempfile.mkdtemp(prefix='candidate-', dir=ROOT/'scratch')), ROOT/'scratch')
    root = output(scope/'_retail_', ROOT/'scratch'); root.mkdir()
    output(root/'Interface', ROOT/'scratch').mkdir()
    fixture_copy(sources[0], root/'Interface/AddOns')
    fixture_copy(sources[1], root/'WTF')
    capture = json.loads((ROOT/'reference/manifests/2026-10-03-initial.json').read_text(encoding='utf-8'))
    links = []
    for row in capture['links']:
        parts = PureWindowsPath(row['alias']).parts
        if 'WTF' not in parts:
            continue
        relative = Path(*parts[parts.index('WTF')+1:])
        target_parts = PureWindowsPath(row['target']).parts
        target = output(root/'WTF'/Path(*target_parts[target_parts.index('WTF')+1:]), ROOT/'scratch')
        alias = output(root/'WTF'/relative, ROOT/'scratch')
        if alias.exists() or not target.is_dir():
            raise ValueError('Unexpected copied character alias/target')
        alias.parent.mkdir(parents=True, exist_ok=True)
        links.append({'alias': str(alias), 'target': str(target)})
    if len(links) != 42:
        raise ValueError('Expected exact captured 42 character links')
    if os.name == 'nt':
        link_file = output(scope/'links.json', ROOT/'scratch')
        link_file.write_text(json.dumps(links), encoding='utf-8')
        script = "$cpfLinks=Get-Content -LiteralPath '"+str(link_file).replace("'", "''")+"' -Raw | ConvertFrom-Json; foreach($cpfLink in $cpfLinks) { New-Item -ItemType Junction -Path $cpfLink.alias -Value $cpfLink.target -ErrorAction Stop | Out-Null }"
        subprocess.run(['powershell', '-NoProfile', '-NonInteractive', '-Command', script], check=True,
            capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
    else:
        for row in links:
            Path(row['alias']).symlink_to(row['target'], target_is_directory=True)
    tree = GameTree(root, simulation=True, process_check=lambda: False)
    code = inventory(tree.addons); config = inventory(tree.wtf, True)
    preview = install(tree, pack, checksum)
    if preview['execute'] or (root/'CPFBackups').exists():
        raise ValueError('Read-only preview wrote data')
    installed = install(tree, pack, checksum, execute=True)
    backup = Path(installed['backup'])
    snapshot = json.loads((backup/'snapshot.json').read_text(encoding='utf-8'))
    verify_backup(backup, snapshot)
    current = inventory(tree.addons)
    if inventory(tree.wtf, True) != config or len(current['files']) < len(manifest['addonFolders']):
        raise ValueError('Complete installed code/configuration readback failed')
    output(tree.wtf/'Config.wtf', ROOT/'scratch').write_bytes((tree.wtf/'Config.wtf').read_bytes()+b'\n# simulated later play\n')
    later_hash = sha(tree.wtf/'Config.wtf')
    restored = restore(tree, backup, True, True, True)
    if inventory(tree.addons) != code or inventory(tree.wtf, True) != config:
        raise ValueError('Full pre-install reference restoration failed')
    if sha(Path(restored['backup'])/'WTF/Config.wtf') != later_hash:
        raise ValueError('Later play was not retained in the fresh restore backup')
    if [immutable_hashes(path) for path in sources] != before:
        raise ValueError('Immutable reference drift')
    report = {'at': datetime.now(timezone.utc).isoformat(), 'status': 'passed', 'scope': str(scope),
        'packSHA256': checksum, 'sourceCommit': manifest['sourceCommit'],
        'addonFolders': len(manifest['addonFolders']), 'installedAddonFiles': len(current['files']),
        'referenceAddonFiles': len(code['files']), 'canonicalConfigurationFiles': len(config['files']),
        'characterLinksPreserved': len(config['links']), 'priorAddonMetadata': len(snapshot['priorAddonMetadata']),
        'readOnlyPreview': True, 'backupVerified': True, 'configurationUntouchedByInstall': True,
        'unrelatedAddonsPreserved': True, 'fullDisasterRestoreVerified': True, 'laterPlayBackupVerified': True,
        'immutableReferencesUnchanged': True,
        'installReceiptSHA256': sha(backup/'install-receipt.json'),
        'restoreReceiptSHA256': sha(Path(restored['backup'])/'install-receipt.json'),
        'simulationBackupsRetained': [str(backup), restored['backup']],
        'limitation': 'Copied snapshot plus recreated repository-local junctions only; no live writes or Retail/client execution.'}
    destination = output(ROOT/'evidence/delivery'/('dry-run-'+checksum[:16]+'.json'))
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        raise ValueError('Retain prior evidence; use a new candidate for rerun')
    destination.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps(report, indent=2))
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--pack', required=True)
    parser.add_argument('--sha256', required=True)
    args = parser.parse_args()
    dry_run(args.pack, args.sha256)
