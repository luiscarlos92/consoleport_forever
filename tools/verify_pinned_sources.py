"""Explicit network verification of pinned official archives for fresh CI."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import subprocess
from assemble_pack import fetch_official
from pack_format import digest, zip_entries
from repository_paths import ROOT, output, sha


def verify_download(package):
    data = fetch_official(package)
    if len(data) != package['bytes'] or digest(data) != package['sha256']:
        raise ValueError('Pinned official archive drift: '+package['repo'])
    files = zip_entries(data)
    if package.get('sourceCommit'):
        prefixes = {name.split('/')[0] for name in files}
        if len(prefixes) != 1 or len(package['addonFolders']) != 1:
            raise ValueError('Pinned standalone source root mismatch')
        files = {package['addonFolders'][0]+'/'+name.split('/', 1)[1]: body for name, body in files.items()}
    if {name: digest(body) for name, body in files.items()} != package['files']:
        raise ValueError('Pinned whole package file inventory drift: '+package['repo'])
    return {'repo': package['repo'], 'version': package['version'], 'sha256': package['sha256'], 'status': 'passed'}


if __name__ == '__main__':
    lock = ROOT/'dependencies/lock.json'
    packages = json.loads(lock.read_text(encoding='utf-8'))['packages']
    with ThreadPoolExecutor(max_workers=3) as pool:
        rows = list(pool.map(verify_download, packages))
    report = {'at': datetime.now(timezone.utc).isoformat(), 'lockSHA256': sha(lock),
        'sourceCommit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
        'method': 'Explicit pinned official network fetch; full archive and every upstream file hash checked.', 'results': rows}
    destination = output(ROOT/'scratch/test-results/pinned-downloads.json')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'pinnedOfficialPackages': len(rows), 'status': 'passed'}))
