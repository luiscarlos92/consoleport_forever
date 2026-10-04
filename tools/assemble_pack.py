"""Personal official-source assembly, outside every game tree."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import urllib.parse
import urllib.request
from pack_format import (archive_bytes, digest, plain_path, read_pack,
                         safe_relative, validate_manifest, zip_entries)

OFFICIAL_HOSTS = {'github.com', 'api.github.com', 'codeload.github.com',
    'release-assets.githubusercontent.com', 'objects.githubusercontent.com',
    'edge.forgecdn.net', 'mediafilez.forgecdn.net'}


def fetch_official(package):
    url = urllib.parse.urlsplit(package['assetURL'])
    if url.scheme != 'https' or url.hostname not in OFFICIAL_HOSTS or url.username or url.password:
        raise ValueError('Unofficial package download URL')
    request = urllib.request.Request(package['assetURL'], headers={'User-Agent': 'ConsolePort-Forever-personal-assembly'})
    with urllib.request.urlopen(request, timeout=60) as response:
        final = urllib.parse.urlsplit(response.geturl())
        if final.scheme != 'https' or final.hostname not in OFFICIAL_HOSTS:
            raise ValueError('Unofficial download redirect')
        data = response.read(package['bytes']+1)
    return data


def assembly_output(path):
    path = Path(path).absolute()
    plain_path(path, path.parent)
    if any(p.name.casefold() in {'_retail_', 'world of warcraft', 'addons', 'wtf'} for p in [path.parent, *path.parents]):
        raise ValueError('Assembly output must be outside game/configuration trees')
    if not path.parent.is_dir() or path.exists():
        raise ValueError('Assembly requires an existing plain parent and fresh output file')
    return path


def assemble(recipe_path, expected_sha256, destination, provider=fetch_official):
    destination = assembly_output(destination)
    manifest, rows = read_pack(recipe_path, expected_sha256)
    if manifest['assemblyComplete']:
        raise ValueError('Expected an official-source recipe, not an assembled pack')
    recipe = json.loads(rows['dependencies/official-sources.json'])
    all_files = set(rows)
    owners = set()
    for package in recipe['packages']:
        data = provider(package)
        if len(data) != package['bytes'] or digest(data) != package['sha256']:
            raise ValueError('Official package digest/truncation: '+package['repo'])
        entries = zip_entries(data)
        normalize = package.get('normalization')
        if normalize:
            prefix = normalize['stripPrefix']+'/'
            if any(not name.startswith(prefix) for name in entries):
                raise ValueError('Source archive root changed')
            entries = {normalize['folder']+'/'+name[len(prefix):]: body for name, body in entries.items()}
        for folder in package['selectedFolders']:
            safe_relative(folder)
            if '/' in folder or folder.casefold() in owners:
                raise ValueError('Duplicate/unsafe official folder owner')
            owners.add(folder.casefold())
        selected = {name: body for name, body in entries.items() if name.split('/')[0] in package['selectedFolders']}
        omitted = package.get('omittedFiles', {})
        declared = {**package['selectedFiles'], **omitted}
        if set(selected) != set(declared):
            raise ValueError('Official selected file inventory mismatch: '+package['repo'])
        for name, body in selected.items():
            if digest(body) != declared[name]:
                raise ValueError('Official file drift: '+name)
            if name in omitted:
                continue
            target = 'Interface/AddOns/'+name
            if target in all_files:
                raise ValueError('Companion/official file collision')
            rows[target] = body
            all_files.add(target)
        print('Qualified official package '+package['repo']+' '+package['version'], flush=True)
    manifest['assemblyComplete'] = True
    manifest['assembly'] = {'recipeSHA256': expected_sha256,
        'assembledAt': datetime.now(timezone.utc).isoformat(),
        'method': 'Exact pinned official downloads; no dependency source transformations.'}
    manifest['addonFolders'] = manifest['requiredAddonFolders']
    manifest['files'] = {name: digest(body) for name, body in rows.items()}
    validate_manifest(manifest, rows, require_complete=True)
    archive = archive_bytes(rows, manifest)
    # Open exclusively: a second run must never overwrite a candidate.
    with destination.open('xb') as stream:
        stream.write(archive)
    receipt = {'path': destination.name, 'sha256': digest(archive), 'bytes': len(archive),
        'sourceCommit': manifest['sourceCommit'], 'addonFolders': len(manifest['addonFolders']),
        'dependencyLockSHA256': manifest['dependencyLockSHA256'], 'personalUseOnly': True,
        'runtimeAcceptance': 'Pending the H8 Retail client checklist.'}
    receipt_path = assembly_output(destination.with_suffix(destination.suffix+'.receipt.json'))
    receipt_path.write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf-8')
    read_pack(destination, receipt['sha256'], require_complete=True)
    return receipt


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--recipe', required=True)
    parser.add_argument('--sha256', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    print(json.dumps(assemble(args.recipe, args.sha256, args.output), indent=2))
