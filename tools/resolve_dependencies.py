"""Pin official stable release packages; locked verification is network-free."""
import argparse
import concurrent.futures
from datetime import datetime, timezone
import io
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import urllib.request
import zipfile
from repository_paths import ROOT, contained, sha


def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': 'ConsolePort-Forever-build', 'Accept': 'application/vnd.github+json' if 'api.github.com' in url else '*/*'})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def members(data):
    entries, seen = [], set()
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for item in archive.infolist():
            name = item.orig_filename
            if name != item.filename:
                raise ValueError('ZIP name normalization rejected: ' + name)
            path = PurePosixPath(name)
            if ('\\' in name or ':' in name or path.is_absolute() or '..' in path.parts
                or any(p.endswith((' ', '.')) for p in path.parts)
                or any(re.match(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)', p, re.I) for p in path.parts)
                or (item.external_attr >> 16) & 0o170000 == 0o120000):
                raise ValueError('Unsafe ZIP member: ' + name)
            if item.is_dir():
                continue
            if name.casefold() in seen:
                raise ValueError('Duplicate ZIP member: ' + name)
            if path.suffix.lower() in {'.exe', '.dll', '.msi', '.bat', '.cmd', '.ps1'}:
                raise ValueError('Executable in addon package: ' + name)
            seen.add(name.casefold())
            entries.append((name, archive.read(item)))
    return entries


def package(source):
    repo = source['repo']
    endpoint = 'repos/' + repo + '/releases/latest'
    if shutil.which('gh'):
        response = subprocess.run(['gh', 'api', endpoint], capture_output=True, check=True, timeout=45)
        release = json.loads(response.stdout)
    else:
        release = json.loads(fetch('https://api.github.com/' + endpoint))
    if release['prerelease'] or release['draft']:
        raise ValueError('Stable release required')
    assets = [a for a in release['assets'] if a['name'].endswith('.zip')
              and not re.search(r'nolib|classic|bcc|wrath|cata|mists', a['name'], re.I)]
    # Some project names include Cataclysm; game-flavor suffixes are checked
    # through TOCs below rather than rejecting the expansion project itself.
    if not assets:
        assets = [a for a in release['assets'] if a['name'].endswith('.zip')
                  and not re.search(r'nolib|-(?:classic|bcc|wrath|cata|mists)\.', a['name'], re.I)]
    preferred = [a for a in assets if 'retail' in a['name'].lower() or 'mainline' in a['name'].lower()]
    if preferred:
        assets = preferred
    if len(assets) != 1:
        raise ValueError('Ambiguous stable Retail asset: ' + ', '.join(a['name'] for a in assets))
    asset = assets[0]
    cache = contained(ROOT / 'dependencies/cache' / asset['name'])
    cache.parent.mkdir(parents=True, exist_ok=True)
    expected = asset.get('digest')
    # Existing cache qualifies only if the freshly resolved stable asset
    # independently advertises the exact matching SHA-256.
    if cache.exists() and expected == 'sha256:' + sha(cache):
        data = cache.read_bytes()
    else:
        data = fetch(asset['browser_download_url'])
    import hashlib
    actual = hashlib.sha256(data).hexdigest()
    if expected and expected != 'sha256:' + actual:
        raise ValueError('Upstream digest mismatch')
    if len(data) != asset['size']:
        raise ValueError('Truncated package')
    entries = members(data)
    folders = sorted({name.split('/')[0] for name, _ in entries if '/' in name})
    toc = {}
    for name, body in entries:
        if name.lower().endswith('.toc'):
            text = body.decode('utf-8-sig', errors='replace')
            if '@project-version@' in text or '@interface@' in text:
                raise ValueError('Unpackaged metadata: ' + name)
            toc[name] = dict(re.findall(r'^##\s*([^:]+):\s*(.*)$', text, re.M))
    if not toc or not any(any(int(n) >= 120000 for n in re.findall(r'\d+', meta.get('Interface', ''))) for meta in toc.values()):
        raise ValueError('No current Retail TOC')
    cache.write_bytes(data)
    target = contained(ROOT / 'dependencies/unpacked' / repo.split('/')[-1] / release['tag_name'])
    for name, body in entries:
        dest = contained(target / name, target)
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists() and dest.read_bytes() != body:
            raise ValueError('Immutable package cache drift: ' + str(dest))
        dest.write_bytes(body)
    return {'repo': repo, 'channel': 'stable', 'flavor': 'Retail', 'version': release['tag_name'],
            'releaseURL': release['html_url'], 'assetURL': asset['browser_download_url'],
            'retrievedAt': datetime.now(timezone.utc).isoformat(), 'expectedDigest': expected,
            'sha256': actual, 'bytes': len(data), 'cache': cache.relative_to(ROOT).as_posix(),
            'unpacked': target.relative_to(ROOT).as_posix(), 'addonFolders': folders, 'toc': toc,
            'files': {name: hashlib.sha256(body).hexdigest() for name, body in entries}}


def verify(lock):
    owners = {}
    for entry in lock['packages']:
        cache = contained(ROOT / entry['cache'])
        if sha(cache) != entry['sha256']:
            raise ValueError('Locked package hash mismatch: ' + entry['repo'])
        for folder in entry['addonFolders']:
            if folder in owners:
                raise ValueError('Duplicate folder owners: ' + folder)
            owners[folder] = entry['repo']
        for name, expected in entry['files'].items():
            if sha(contained(ROOT / entry['unpacked'] / name)) != expected:
                raise ValueError('Unpacked upstream drift: ' + name)
    return owners


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--refresh', action='store_true')
    parser.add_argument('--only', help='Resolve one official repository and merge into lock')
    args = parser.parse_args()
    lock_path = ROOT / 'dependencies/lock.json'
    if not args.refresh:
        lock = json.loads(lock_path.read_text())
        verify(lock)
        print(json.dumps({'verifiedPackages': len(lock['packages']), 'complete': lock['complete']}))
        return
    sources = json.loads((ROOT / 'dependencies/sources.json').read_text())
    packages, blockers = [], list(sources['manualSources'])
    selected = sources['github']
    if args.only:
        if args.only not in [x['repo'] for x in selected]:
            raise ValueError('Unknown dependency repository')
        selected = [x for x in selected if x['repo'] == args.only]
        previous = json.loads(lock_path.read_text())
        packages = [p for p in previous['packages'] if p['repo'] != args.only]
        blockers = [b for b in previous['blockers'] if b.get('repo') != args.only]
    def resolve(source):
        try:
            return package(source), None
        except Exception as error:
            return None, {'repo': source['repo'], 'reason': str(error)}
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        for entry, error in pool.map(resolve, selected):
            if entry:
                packages.append(entry)
            if error:
                blockers.append(error)
    installed = [p.name for p in (ROOT / 'reference/installed-addons/2026-10-03-initial').iterdir() if p.is_dir()]
    lock = {'resolvedAt': datetime.now(timezone.utc).isoformat(), 'packages': packages, 'blockers': blockers,
            'installedFolders': sorted(installed), 'complete': False}
    owners = verify(lock)
    lock['unmappedFolders'] = sorted(set(installed) - set(owners))
    lock['unexpectedFolders'] = sorted(set(owners) - set(installed))
    lock['complete'] = not blockers and not lock['unmappedFolders'] and not lock['unexpectedFolders']
    lock_path.write_text(json.dumps(lock, indent=2), encoding='utf-8')
    print(json.dumps({'packages': len(packages), 'blockers': blockers, 'unmapped': lock['unmappedFolders'], 'unexpected': lock['unexpectedFolders']}))


if __name__ == '__main__':
    main()
