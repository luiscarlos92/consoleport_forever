"""Inventory exact locked notice files; no redistribution permission is inferred."""
import argparse
import hashlib
import json
from pathlib import PurePosixPath
import re
from repository_paths import ROOT, contained, output, sha
from resolve_dependencies import verify


def classify(name, data):
    basename = PurePosixPath(name).name
    if re.match(r'^(?:licen[sc]e|copying|copyright|notice)(?:[._-]|$)', basename, re.I):
        return 'notice-file'
    if name.lower().endswith(('.lua', '.xml', '.toc', '.md', '.txt')):
        header = data[:12000].decode('utf-8-sig', errors='replace')
        if re.search(r'copyright|all rights reserved|permission is hereby granted|licensed under', header, re.I):
            return 'embedded-notice-source'
    return None


def inventory(lock, coverage, notice_dir=None):
    if coverage['lockSHA256'] != sha(ROOT/'dependencies/lock.json'):
        raise ValueError('Notice inventory requires current verified coverage')
    verify(lock)
    selected = coverage['selectedFolders']
    restricted = set(coverage['distribution']['restrictedOfficialAssembly'])
    records = []
    for package in lock['packages']:
        folders = sorted(n for n, row in selected.items() if row['owner'] == package['repo'])
        notices, embedded = [], []
        for name, expected in sorted(package['files'].items()):
            if PurePosixPath(name).parts[0] not in folders:
                continue
            source = contained(ROOT/package['unpacked']/name)
            data = source.read_bytes()
            if hashlib.sha256(data).hexdigest() != expected:
                raise ValueError('Upstream file changed during notice capture: '+name)
            kind = classify(name, data)
            if kind == 'notice-file':
                # Keep exact bytes under the package owner to avoid conflating
                # bundled library terms with the containing addon's license.
                owner = package['repo'].replace('/', '__')
                target = output((notice_dir or ROOT/'evidence/dependencies/notices')/owner/name)
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(data)
                if sha(target) != expected or sha(source) != expected:
                    raise ValueError('Notice copy drift: '+name)
                notices.append({'source': name, 'sha256': expected,
                    'copy': target.relative_to(ROOT).as_posix()})
            elif kind == 'embedded-notice-source':
                embedded.append({'source': name, 'sha256': expected})
        records.append({'repo': package['repo'], 'version': package['version'],
            'officialRelease': package['releaseURL'], 'packageSHA256': package['sha256'],
            'selectedFolders': folders, 'noticeFiles': notices, 'embeddedNoticeSources': embedded,
            'assemblyRequiredByCoverage': package['repo'] in restricted,
            'noticeFilesAbsent': not notices,
            'review': 'Review main addon, bundled libraries and media terms independently; filename discovery does not grant redistribution rights.'})
    return {'lockSHA256': coverage['lockSHA256'], 'discoveryComplete': True,
        'releaseNoticeReviewComplete': False, 'packDistributionReady': False,
        'packages': records,
        'remaining': 'Finalize notices and official-source assembly before candidate distribution. Missing notice files require official terms/provenance review; no implicit permissive fallback.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.parse_args()
    lock = json.loads((ROOT/'dependencies/lock.json').read_text())
    coverage = json.loads((ROOT/'evidence/dependencies/coverage.json').read_text())
    result = inventory(lock, coverage)
    output(ROOT/'evidence/dependencies/notices.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    print(json.dumps({'packages': len(result['packages']),
        'exactNoticeFiles': sum(len(p['noticeFiles']) for p in result['packages']),
        'packagesWithoutNoticeFiles': [p['repo'] for p in result['packages'] if p['noticeFilesAbsent']],
        'reviewComplete': False}))
