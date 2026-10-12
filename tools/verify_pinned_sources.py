"""Explicit network verification of pinned official archives for fresh CI."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
import re
import subprocess
from urllib.request import urlopen
from assemble_pack import fetch_official
from pack_format import digest, zip_entries
from repository_paths import ROOT, contained, output, sha


def fetch_research_bytes(url):
    with urlopen(url, timeout=40) as response:
        if response.geturl() != url:
            raise ValueError('Pinned research URL redirected')
        return response.read()


def verify_research_source(row, cache, fetch=fetch_research_bytes):
    """Reconstruct research inputs locally; never publish their source bytes."""
    name, url = row['file'], row['url']
    if not re.fullmatch(r'[A-Za-z0-9_-]+\.(?:lua|xml)', name):
        raise ValueError('Unsafe research filename')
    if not re.fullmatch(r'https://raw\.githubusercontent\.com/Gethe/wow-ui-source/[0-9a-f]{40}/Interface/AddOns/[A-Za-z0-9_/-]+\.(?:lua|xml)', url) or '..' in url:
        raise ValueError('Research URL must pin the inspected source commit')
    if not re.fullmatch(r'[0-9a-f]{64}', row['sha256']) or type(row['bytes']) is not int or row['bytes'] <= 0:
        raise ValueError('Invalid research identity')
    cache = output(contained(cache, ROOT/'scratch'), ROOT/'scratch')
    target = output(cache/name, ROOT/'scratch')
    data = target.read_bytes() if target.exists() else fetch(url)
    if len(data) != row['bytes'] or digest(data) != row['sha256']:
        raise ValueError('Pinned research source drift: '+name)
    if not target.exists():
        cache.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    return {'file': name, 'sha256': row['sha256'], 'status': 'passed'}


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
    research = json.loads((ROOT/'evidence/circle/research/sources.json').read_text(encoding='utf-8'))
    inputs = research['files']+[research['forever'], research['latestForever']]
    with ThreadPoolExecutor(max_workers=3) as pool:
        research_rows = list(pool.map(lambda row: verify_research_source(row, ROOT/research['localCache']), inputs))
    report = {'at': datetime.now(timezone.utc).isoformat(), 'lockSHA256': sha(lock),
        'sourceCommit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
        'method': 'Explicit pinned official network fetch; full archive and every upstream file hash checked.', 'results': rows,
        'researchSources': research_rows}
    destination = output(ROOT/'scratch/test-results/pinned-downloads.json')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'pinnedOfficialPackages': len(rows), 'pinnedResearchSources': len(research_rows), 'status': 'passed'}))
