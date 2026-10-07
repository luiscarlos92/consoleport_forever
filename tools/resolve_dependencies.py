"""Pin official stable release packages; locked verification is network-free."""
import argparse
import concurrent.futures
from datetime import datetime, timezone
import io
import hashlib
import json
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import urllib.request
import zipfile
from repository_paths import ROOT, contained, output, sha


def segment(value):
    if not isinstance(value, str) or not value or len(PurePosixPath(value).parts) != 1 or any(c in value for c in '<>:"/\\|?*') or any(ord(c)<32 for c in value) or value.endswith((' ', '.')) or re.match(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',value,re.I):
        raise ValueError('Unsafe package identity: ' + str(value))
    return value


def selected_coverage(installed, sources):
    """Extend the immutable reference with explicitly adopted addon folders."""
    additional = sources.get('additionalAddonFolders', [])
    if not isinstance(additional, list):
        raise ValueError('Additional addon coverage must be a list')
    return sorted(set(installed) | {segment(name) for name in additional})


def metadata(entries, require_retail=True):
    toc, advisories = {}, {}
    for name, body in entries:
        if not name.lower().endswith('.toc'):
            continue
        text = body.decode('utf-8-sig', errors='replace')
        if re.search(r'@(?:project-version|interface|wow-version-[\w-]+)@', text):
            if len(PurePosixPath(name).parts)==2:
                raise ValueError('Unpackaged TOC metadata: ' + name)
            advisories[name] = 'Bundled unused standalone library TOC has packager tokens; official bytes retained.'
        # Horizontal whitespace only: an empty Notes field must not consume the
        # next line's Dependencies declaration. Normalize metadata, not bytes.
        toc[name] = {key.strip():value.strip() for key,value in
            re.findall(r'^##[ \t]*([^:\r\n]+):[ \t]*(.*)$',text,re.M)}
    if require_retail and not any(len(PurePosixPath(name).parts)==2 and any(int(n)>=120000 for n in re.findall(r'\d+',meta.get('Interface',''))) for name,meta in toc.items()):
        raise ValueError('No qualifying Retail addon TOC')
    return toc, advisories


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
    if source['repo'].startswith('curseforge/'):
        return curseforge_package(source)
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
        if not assets and source.get('sourceArchiveAddon'):
            return source_archive(source, release)
        raise ValueError('Ambiguous stable Retail asset: ' + ', '.join(a['name'] for a in assets))
    asset = assets[0]
    segment(asset['name']); segment(release['tag_name'])
    cache = output(ROOT / 'dependencies/cache' / asset['name'], ROOT / 'dependencies')
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
    toc, advisories = metadata(entries)
    target = output(ROOT / 'dependencies/unpacked' / repo.split('/')[-1] / release['tag_name'], ROOT / 'dependencies')
    for name, body in entries:
        dest = output(target / name, ROOT / 'dependencies')
        if dest.exists() and dest.read_bytes() != body:
            raise ValueError('Immutable package cache drift: ' + str(dest))
    cache.write_bytes(data)
    for name, body in entries:
        dest = output(target / name, ROOT / 'dependencies')
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists() and dest.read_bytes() != body:
            raise ValueError('Immutable package cache drift: ' + str(dest))
        dest.write_bytes(body)
    return {'repo': repo, 'channel': 'stable', 'flavor': 'Retail', 'version': release['tag_name'],
            'releaseURL': release['html_url'], 'assetURL': asset['browser_download_url'],
            'retrievedAt': datetime.now(timezone.utc).isoformat(), 'expectedDigest': expected,
            'sha256': actual, 'bytes': len(data), 'cache': cache.relative_to(ROOT).as_posix(),
            'unpacked': target.relative_to(ROOT).as_posix(), 'addonFolders': folders, 'toc': toc, 'metadataAdvisories': advisories,
            'files': {name: hashlib.sha256(body).hexdigest() for name, body in entries}}


def materialize(source, data, asset_url, version, archive_prefix=None):
    """Qualify official bytes before writing a normalized standalone folder."""
    segment(version); segment(source['addon'])
    entries = members(data)
    if archive_prefix:
        prefix = archive_prefix + '/'
        if any(not name.startswith(prefix) for name, _ in entries):
            raise ValueError('Mixed source archive roots')
        entries = [(source['addon'] + '/' + name[len(prefix):], body) for name, body in entries]
    folders = sorted({name.split('/')[0] for name, _ in entries if '/' in name})
    if folders != [source['addon']]:
        raise ValueError('Unexpected official package folders: ' + str(folders))
    toc, advisories = metadata(entries)
    versions = {meta['Version'].strip() for name,meta in toc.items() if len(PurePosixPath(name).parts)==2 and meta.get('Version')}
    if versions and version.lstrip('v') not in {v.lstrip('v') for v in versions}:
        raise ValueError('Official file/TOC version mismatch: ' + str(versions))
    # Source packaging is allowed only when every actual runtime file resolves
    # and there are no absent external libraries or packager directives.
    if archive_prefix:
        by_name = dict(entries)
        for name, body in entries:
            if name.lower().endswith(('.toc', '.xml')):
                text = body.decode('utf-8-sig', errors='replace')
                if '#@' in text or '@project' in text:
                    raise ValueError('Source requires packager transformations: ' + name)
                if name.lower().endswith('.toc'):
                    for line in text.splitlines():
                        line = line.strip()
                        if line and not line.startswith('#'):
                            runtime = str(PurePosixPath(name).parent / line.replace('\\', '/'))
                            if runtime not in by_name:
                                raise ValueError('Missing source runtime file: ' + runtime)
                else:
                    for file in re.findall(r'file=[\"\']([^\"\']+)[\"\']', text):
                        runtime = str(PurePosixPath(name).parent / file.replace('\\', '/'))
                        if runtime not in by_name:
                            raise ValueError('Missing source XML include: ' + runtime)
    digest = hashlib.sha256(data).hexdigest()
    cache = output(ROOT / 'dependencies/cache' / (source['addon'] + '-' + version + '-official.zip'), ROOT / 'dependencies')
    target = output(ROOT / 'dependencies/unpacked' / source['addon'] / version, ROOT / 'dependencies')
    for name, body in entries:
        dest = output(target / name, ROOT / 'dependencies')
        if dest.exists() and dest.read_bytes() != body:
            raise ValueError('Immutable official package drift: ' + name)
    cache.parent.mkdir(parents=True, exist_ok=True)
    cache.write_bytes(data)
    for name, body in entries:
        dest = output(target / name, ROOT / 'dependencies')
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists() and dest.read_bytes() != body:
            raise ValueError('Immutable official package drift: ' + name)
        dest.write_bytes(body)
    return {'repo': source['repo'], 'channel': 'stable', 'flavor': 'Retail', 'version': version,
            'releaseURL': source['url'], 'assetURL': asset_url, 'expectedDigest': None,
            'retrievedAt': datetime.now(timezone.utc).isoformat(), 'sha256': digest, 'bytes': len(data),
            'cache': cache.relative_to(ROOT).as_posix(), 'unpacked': target.relative_to(ROOT).as_posix(),
            'addonFolders': folders, 'toc': toc, 'metadataAdvisories': advisories, 'files': {name: hashlib.sha256(body).hexdigest() for name, body in entries}}


def curseforge_package(source):
    verified = datetime.fromisoformat(source['metadataVerifiedAt'].replace('Z', '+00:00'))
    if not source.get('supportsRetail') or abs((datetime.now(timezone.utc) - verified).total_seconds()) > 86400:
        raise ValueError('Recheck official latest stable Retail file metadata before refresh')
    file_id = str(source['fileID'])
    url = 'https://edge.forgecdn.net/files/' + file_id[:-3] + '/' + str(int(file_id[-3:])) + '/' + source['filename']
    # No advertised independent digest: refresh must fetch official CDN bytes,
    # not accept a stale local cache merely because its filename matches.
    data = fetch(url)
    entry = materialize(source, data, url, source['version'])
    entry['distribution'] = 'CurseForge official CDN'
    entry['projectID'], entry['fileID'] = source['projectID'], source['fileID']
    entry['metadataVerifiedAt'], entry['license'] = source['metadataVerifiedAt'], source['license']
    entry['latestURL'] = source['latestURL']
    return entry


def source_archive(source, release):
    repo = source['repo']
    commit = json.loads(subprocess.check_output(['gh', 'api', 'repos/' + repo + '/commits/' + release['tag_name']], timeout=45))['sha']
    url = 'https://api.github.com/repos/' + repo + '/zipball/' + commit
    data = fetch(url)
    entries = members(data)
    roots = {name.split('/')[0] for name, _ in entries}
    if len(roots) != 1:
        raise ValueError('Source archive root mismatch')
    descriptor = dict(source, addon=source['sourceArchiveAddon'], url=release['html_url'])
    entry = materialize(descriptor, data, url, release['tag_name'], next(iter(roots)))
    entry['distribution'], entry['sourceCommit'] = 'Qualified official tagged standalone source', commit
    entry['qualification'] = source['qualification']
    return entry


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
    parser.add_argument('--only', action='append', help='Resolve selected official repositories and merge into lock; repeat for multiple packages')
    args = parser.parse_args()
    lock_path = output(ROOT / 'dependencies/lock.json', ROOT / 'dependencies')
    if not args.refresh:
        lock = json.loads(lock_path.read_text())
        verify(lock)
        print(json.dumps({'verifiedPackages': len(lock['packages']), 'complete': lock['complete']}))
        return
    sources = json.loads((ROOT / 'dependencies/sources.json').read_text())
    packages, blockers = [], list(sources['manualSources'])
    selected = sources['github'] + sources.get('curseforge', [])
    if args.only:
        if any(repo not in [x['repo'] for x in selected] for repo in args.only):
            raise ValueError('Unknown dependency repository')
        selected = [x for x in selected if x['repo'] in args.only]
        previous = json.loads(lock_path.read_text())
        packages = [p for p in previous['packages'] if p['repo'] not in args.only]
        names = {x.get('addon') for x in selected if x.get('addon')}
        blockers = [b for b in previous['blockers'] if b.get('repo') not in args.only and b.get('package') not in names]
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
    installed = selected_coverage([p.name for p in (ROOT / 'reference/installed-addons/2026-10-03-initial').iterdir() if p.is_dir()], sources)
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
