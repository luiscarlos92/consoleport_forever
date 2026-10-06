"""Recheck current official stable identities without changing pinned packages."""
import concurrent.futures
import argparse
from datetime import datetime, timezone
import json
import subprocess
from repository_paths import ROOT, output, sha
from resolve_dependencies import fetch


def github_api(endpoint):
    return json.loads(subprocess.check_output(['gh', 'api', endpoint], stderr=subprocess.PIPE, timeout=45))


def check(allow_updates=False):
    lock = json.loads((ROOT/'dependencies/lock.json').read_text(encoding='utf-8'))
    sources = json.loads((ROOT/'dependencies/sources.json').read_text(encoding='utf-8'))
    pinned = {p['repo']: p for p in lock['packages']}

    def resolve(source):
        owner = source['repo']
        prior = pinned[owner]
        release = github_api('repos/'+owner+'/releases/latest')
        row = {'repo': owner, 'url': release['html_url'], 'latestStable': release['tag_name'],
            'releaseID': release['id'], 'publishedAt': release['published_at'], 'matchesLock': False}
        if release['draft'] or release['prerelease'] or release['tag_name'] != prior['version']:
            return row
        if prior.get('sourceCommit'):
            row['sourceCommit'] = github_api('repos/'+owner+'/commits/'+release['tag_name'])['sha']
            row['matchesLock'] = row['sourceCommit'] == prior['sourceCommit']
        else:
            asset = next((a for a in release['assets'] if a['browser_download_url'] == prior['assetURL']), None)
            if asset:
                row['assetID'], row['digest'], row['bytes'] = asset['id'], asset.get('digest'), asset['size']
                if asset.get('digest'):
                    row['matchesLock'] = asset['digest'] == 'sha256:'+prior['sha256'] and asset['size'] == prior['bytes']
                else:
                    # An absent independent digest must never turn cache
                    # existence into current-asset qualification.
                    import hashlib
                    fresh = fetch(asset['browser_download_url'])
                    row['freshSHA256'] = hashlib.sha256(fresh).hexdigest()
                    row['matchesLock'] = row['freshSHA256'] == prior['sha256'] and len(fresh) == prior['bytes']
        return row

    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        github = list(pool.map(resolve, sources['github']))
    curseforge = []
    now = datetime.now(timezone.utc)
    for source in sources['curseforge']:
        checked = datetime.fromisoformat(source['metadataVerifiedAt'].replace('Z', '+00:00'))
        prior = pinned[source['repo']]
        curseforge.append({'repo': source['repo'], 'latestURL': source['latestURL'],
            'officialFile': source['url'], 'latestStable': source['version'], 'fileID': source['fileID'],
            'metadataVerifiedAt': source['metadataVerifiedAt'],
            'method': 'Official latest-stable Retail listing and file page inspected; no floating latest fetch during assembly.',
            'matchesLock': 0 <= (now-checked).total_seconds() <= 86400 and source['supportsRetail'] and source['version'] == prior['version'] and source['fileID'] == prior.get('fileID')})
    voice = github_api('repos/DeadlyBossMods/DBM-Voicepack-VEM/commits?per_page=1')[0]['sha']
    result = {'checkedAt': now.isoformat(), 'lockSHA256': sha(ROOT/'dependencies/lock.json'),
        'github': github, 'curseforge': curseforge,
        'bundledVoice': {'maintainerCommit': voice, 'expectedCommit': '99e0c336444fd7105e1414c46f9d6a4e0cf99bc6',
            'matchesLock': voice == '99e0c336444fd7105e1414c46f9d6a4e0cf99bc6'},
        'updates': [r['repo'] for r in github+curseforge if not r['matchesLock']],
        'allCurrent': all(r['matchesLock'] for r in github+curseforge) and voice == '99e0c336444fd7105e1414c46f9d6a4e0cf99bc6'}
    output(ROOT/'evidence/dependencies/stable-recheck.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    if not result['allCurrent'] and not allow_updates:
        raise ValueError('Stable source changed/unavailable: refresh the affected lock and compatibility checks before packaging')
    return result


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--discover',action='store_true',help='Report changed identities for selective refresh rather than requiring an already-current lock')
    result = check(allow_updates=parser.parse_args().discover)
    print(json.dumps({'officialPackages': len(result['github'])+len(result['curseforge']), 'allCurrent': result['allCurrent'], 'updates':result['updates'], 'voiceCurrent':result['bundledVoice']['matchesLock']}))
