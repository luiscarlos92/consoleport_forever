"""Record personal-assembly decisions; never infer public redistribution rights."""
import json
import re
from repository_paths import ROOT, contained, output, sha
from resolve_dependencies import verify

MAIN_TERMS = {
    'seblindfors/ConsolePort': 'Artistic-2.0',
    'Cidan/BetterBags': 'MIT',
    'seblindfors/Immersion': 'Artistic-2.0',
    'xod-wow/LiteMount': 'GPL-2.0; bundled MountsRarity declares GPL-3.0',
    'SFX-WoW/Masque': 'Custom personal-use and restricted compilation distribution terms',
    'Tercioo/Plater-Nameplates': 'Maintainer distribution; no permissive main-addon notice in package',
    'DeadlyBossMods/DeadlyBossMods': 'All Rights Reserved; VEM voice separately All Rights Reserved',
    'DeadlyBossMods/DBM-Dungeons': 'All Rights Reserved in tagged-source LICENSE; absent from ZIP',
    'DeadlyBossMods/DBM-Vanilla': 'All Rights Reserved',
    'DeadlyBossMods/DBM-WotLK': 'All Rights Reserved',
    'DeadlyBossMods/DBM-Cataclysm': 'All Rights Reserved',
    'DeadlyBossMods/DBM-MoP': 'All Rights Reserved',
    'DeadlyBossMods/DBM-WoD': 'All Rights Reserved',
    'DeadlyBossMods/DBM-Legion': 'All Rights Reserved',
    'rursache/HideClassBars': 'Apache-2.0',
    'curseforge/DynamicCam': 'MIT; separate bundled library notices retained',
    'curseforge/Immersion_ExtraFade': 'MIT',
    'curseforge/SharedMedia_Causese': 'GPL-3.0 declared on official project/license page; absent from ZIP',
}


def review():
    lock = json.loads((ROOT/'dependencies/lock.json').read_text(encoding='utf-8'))
    verify(lock)
    notices = json.loads((ROOT/'evidence/dependencies/notices.json').read_text(encoding='utf-8'))
    if notices['lockSHA256'] != sha(ROOT/'dependencies/lock.json'):
        raise ValueError('Stale notice inventory')
    supplemental = json.loads((ROOT/'evidence/dependencies/supplemental-notices.json').read_text(encoding='utf-8'))
    for row in supplemental['sources']:
        if sha(contained(ROOT/row['copy'])) != row['sha256']:
            raise ValueError('Supplemental notice drift')
    records = []
    for package in lock['packages']:
        owner = package['repo']
        if owner not in MAIN_TERMS:
            raise ValueError('Unreviewed package: ' + owner)
        row = next(n for n in notices['packages'] if n['repo'] == owner)
        embedded = []
        for source in row['embeddedNoticeSources']:
            path = contained(ROOT/package['unpacked']/source['source'])
            if sha(path) != source['sha256']:
                raise ValueError('Embedded notice source drift')
            # Declarations remain in exact upstream runtime files; copied
            # license texts are supplemental, not edits to those files.
            text = path.read_bytes()[:12000].decode('utf-8-sig', errors='replace')
            declarations = sorted(set(re.findall(
                r'(?im)^.*(?:licen[sc]e[ :]|licensed under|public domain|all rights reserved|copyright).{0,200}', text)))
            embedded.append({**source, 'declarations': declarations,
                'disposition': 'Retain the entire original file and bundled terms unchanged; do not generalize containing-addon terms.'})
        records.append({'repo': owner, 'version': package['version'],
            'mainTerms': MAIN_TERMS[owner], 'officialRelease': package['releaseURL'],
            'noticeFiles': row['noticeFiles'], 'embeddedNoticeSources': embedded,
            'standaloneNoticeAbsent': row['noticeFilesAbsent'],
            'supplemental': [r for r in supplemental['sources'] if r['repo'] == owner],
            'assembly': 'Fetch exact official package for this user and retain all original source/media/notice bytes.',
            'publicRedistributionApproved': False})
    if {r['repo'] for r in records} != set(MAIN_TERMS):
        raise ValueError('Notice review/lock coverage differs')
    result = {'lockSHA256': sha(ROOT/'dependencies/lock.json'),
        'noticeInventorySHA256': sha(ROOT/'evidence/dependencies/notices.json'),
        'localPersonalAssemblyReviewComplete': True, 'publicRedistributionApproved': False,
        'scope': 'All third-party dependencies use official-source local assembly. This inventory is not a license grant or approval to publish dependency code or media.',
        'media': 'Own unchanged baseline BLPs and exact current upstream/client media remain qualified by media.json; public image/font/audio rights and actual rendering are not inferred.',
        'packages': records}
    output(ROOT/'evidence/dependencies/notice-review.json').write_text(json.dumps(result, indent=2), encoding='utf-8')
    return result


if __name__ == '__main__':
    result = review()
    print(json.dumps({'packages': len(result['packages']), 'personalReview': True, 'publicationApproval': False}))
