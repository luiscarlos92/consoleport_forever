"""Build only from clean pushed tested source; emit an official-source recipe.

The complete ZIP is locally assembled from qualified official cache bytes.
Neither ZIP grants approval to republish third-party code or media.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
import zipfile
from repository_paths import ROOT, output, sha, immutable_hashes
from resolve_dependencies import verify
from audit_dependencies import runtime_closure
from pack_format import FORMAT, archive_bytes, digest, read_pack
from assemble_pack import assemble

DELIVERY = ['Install-Pack.ps1', 'Restore-Pack.ps1', 'Assemble-Pack.ps1', 'Verify-Pack.ps1',
    'verify_pack.py', 'install_pack.py', 'deployment_guard.py', 'assemble_pack.py', 'pack_format.py']
GATES = {
    'exactStickReturn': 'Precise protected stick-return/close-and-continue activation unproved; native wheel controls retained.',
    'oneSuccessCircle': 'One successful gameplay cancellation per press unproved; no combined cancellation substitute.',
    'activeEntryCancellation': 'Independent secure cancellation gate; native ring baseline retained.',
    'learnedSelectorsAndPetOpener': 'Privately prepared and inactive until the precise native ring execution route is proved.',
    'transientLootHold': 'Exact 0.5-second transient loot preference route unproved; native modified clicks retained.',
    'cinematicHeldSkip': 'Exact held eligible skip unproved; native confirmation/menu controls retained.',
    'LiteMountSecondIcon': 'LM_B2 lacks a proven current icon default; preserve the native action/rules and explicit icon if present.',
    'otherScrollWidgets': 'Only audited native ScrollController/map callbacks are extended; other widgets retain baseline input.',
    'RetailAcceptance': 'All actual hardware/secure/combat/taint/visual/persistence and A-B-A tests remain pending H8.'}


def git(*arguments):
    return subprocess.check_output(['git', *arguments], cwd=ROOT).decode('utf-8').strip()


def verified_source():
    if git('status', '--porcelain', '--untracked-files=normal'):
        raise ValueError('Pack source must be clean and committed')
    commit = git('rev-parse', 'HEAD')
    remote = git('ls-remote', 'origin', 'refs/heads/main').split()
    if not remote or remote[0] != commit:
        raise ValueError('Source commit must already be pushed on main')
    report = ROOT/'scratch/test-results/latest.json'
    tests = json.loads(report.read_text(encoding='utf-8'))
    if not tests['results'] or any(r['status'] != 'passed' for r in tests['results']):
        raise ValueError('Required runtime/source checks have not passed')
    for group in ['productHashes', 'toolingHashes']:
        for name, expected in tests[group].items():
            if sha(ROOT/name) != expected:
                raise ValueError('Tested source changed: '+name)
    current_tools = {p.relative_to(ROOT).as_posix(): sha(p)
        for base in ['tools', 'tests'] for p in (ROOT/base).rglob('*')
        if p.is_file() and '__pycache__' not in p.parts}
    if current_tools != {n.replace('\\', '/'): value for n, value in tests['toolingHashes'].items()}:
        raise ValueError('Tooling file inventory changed since tests')
    tooling = json.loads((ROOT/'scratch/test-results/tooling-latest.json').read_text(encoding='utf-8'))
    if not tooling.get('overallPassed') or not tooling['results'] or any(r['status'] != 'passed' for r in tooling['results']) or tooling['sourceHashes'] != current_tools:
        raise ValueError('Current tooling/installer simulations must pass without skipped checks')
    tests['toolingReportSHA256'] = sha(ROOT/'scratch/test-results/tooling-latest.json')
    tests['toolingSuiteCount'] = len(tooling['results'])
    current_product = {str(p.relative_to(ROOT)).replace('\\', '/'): sha(p) for p in (ROOT/'addon').rglob('*') if p.is_file()}
    tested_product = {n.replace('\\', '/'): value for n, value in tests['productHashes'].items()}
    if current_product != tested_product:
        raise ValueError('Product file inventory changed since tests')
    # Tests retain exact file hashes independently of the pre-commit parent
    # HEAD. Committing the tested bytes does not invalidate their provenance.
    return commit, tests, sha(report)


def build(recipe_only=False):
    commit, tests, test_hash = verified_source()
    lock_path = ROOT/'dependencies/lock.json'
    lock = json.loads(lock_path.read_text(encoding='utf-8'))
    verify(lock)
    if not lock['complete'] or not lock.get('coverageQualified'):
        raise ValueError('Required official package retrieval/coverage incomplete')
    coverage = json.loads((ROOT/'evidence/dependencies/coverage.json').read_text(encoding='utf-8'))
    review = json.loads((ROOT/'evidence/dependencies/notice-review.json').read_text(encoding='utf-8'))
    stable = json.loads((ROOT/'evidence/dependencies/stable-recheck.json').read_text(encoding='utf-8'))
    lock_hash = sha(lock_path)
    if any(row['lockSHA256'] != lock_hash for row in [coverage, review, stable]) or tests['pinnedDependencyLockSHA256'] != lock_hash:
        raise ValueError('Evidence or tests refer to another dependency lock')
    age = (datetime.now(timezone.utc)-datetime.fromisoformat(stable['checkedAt'])).total_seconds()
    if not stable['allCurrent'] or not 0 <= age <= 86400 or not review['localPersonalAssemblyReviewComplete']:
        raise ValueError('Current official metadata/personal notice review required')
    product = ROOT/'addon/ConsolePort_Forever'
    omitted_product = {'Bindings.lua', 'Layout.lua', 'Profile.lua'}
    product_files = {'ConsolePort_Forever/'+name: (product/name).read_bytes()
        for name in immutable_hashes(product) if name not in omitted_product}
    closure = runtime_closure('ConsolePort_Forever', product_files)
    version = closure['metadata']['Version'].strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+-candidate\.\d+', version):
        raise ValueError('Set and test a concrete candidate version before delivery')
    revision = int(re.search(r'Addon.CONFIG_REVISION=(\d+)', product_files['ConsolePort_Forever/ConsolePort_Forever.lua'].decode()).group(1))
    rows = {'Interface/AddOns/'+name: body for name, body in product_files.items()}
    packages = []
    omissions = json.loads((ROOT/'dependencies/pack-exclusions.json').read_text(encoding='utf-8'))['files']
    for package in lock['packages']:
        folders = sorted(n for n, r in coverage['selectedFolders'].items() if r['owner'] == package['repo'])
        selected = {n: value for n, value in package['files'].items() if n.split('/')[0] in folders}
        omitted = {}
        for item in omissions:
            if item['repo'] != package['repo']:
                continue
            if item['version'] != package['version'] or selected.get(item['path']) != item['sha256']:
                raise ValueError('Unreviewed upstream helper exclusion')
            if any(item['path'] in coverage['selectedFolders'][f]['runtimeFiles'] for f in folders):
                raise ValueError('Cannot omit a runtime-required dependency file')
            omitted[item['path']] = selected.pop(item['path'])
        item = {key: package[key] for key in ['repo', 'version', 'releaseURL', 'assetURL', 'sha256', 'bytes']}
        item.update(selectedFolders=folders, selectedFiles=selected, omittedFiles=omitted)
        if package.get('sourceCommit'):
            with zipfile.ZipFile(ROOT/package['cache']) as archive:
                prefix = archive.namelist()[0].split('/')[0]
            item['normalization'] = {'stripPrefix': prefix, 'folder': folders[0]}
        packages.append(item)
    rows['dependencies/official-sources.json'] = (json.dumps({'lockSHA256': lock_hash, 'packages': packages}, indent=2)+'\n').encode()
    rows['dependencies/lock.json'] = lock_path.read_bytes()
    for name in DELIVERY:
        rows['Delivery/'+name] = (ROOT/'tools'/name).read_bytes()
    rows['README.md'] = (ROOT/'docs/INSTALLATION.md').read_bytes()
    rows['Delivery/ACCEPTANCE.md'] = (ROOT/'docs/ACCEPTANCE.md').read_bytes()
    for path in (ROOT/'evidence/dependencies/notices').rglob('*'):
        if path.is_file():
            rows['Notices/'+path.relative_to(ROOT/'evidence/dependencies/notices').as_posix()] = path.read_bytes()
    for name in ['notices.json', 'notice-review.json', 'supplemental-notices.json', 'media.json', 'coverage.json', 'stable-recheck.json']:
        rows['Notices/'+name] = (ROOT/'evidence/dependencies'/name).read_bytes()
    closures = {**coverage['selectedFolders'], 'ConsolePort_Forever': closure}
    retired = {name: row for name, row in coverage['excludedFolders'].items()
        if name in lock['installedFolders']}
    manifest = {'format': FORMAT, 'formatVersion': 1, 'version': version, 'sourceCommit': commit,
        'localPersonalUseOnly': True, 'redistributionApproved': False, 'assemblyComplete': False,
        'dependencyLockSHA256': lock_hash, 'addonFolders': ['ConsolePort_Forever'],
        'requiredAddonFolders': sorted(closures), 'runtimeClosure': closures,
        'retiredAddonFolders': retired,
        'compatibility': {'storeSchema': 3, 'configurationRevision': revision,
            'dependencyVersions': {p['repo']: p['version'] for p in packages},
            'priorUnknownCode': 'Requires separate explicit disk configuration recovery; never automatically restore stale WTF.'},
        'tests': {'exactReportSHA256': test_hash, 'reportParentHEAD': tests['commit'],
            'runtimeSuites': len(tests['results']), 'toolingReportSHA256': tests['toolingReportSHA256'],
            'toolingSuiteCount': tests['toolingSuiteCount'], 'sourceHashes': tests['productHashes']},
        'featureGates': GATES, 'omittedUpstreamFiles': omissions,
        'omittedProductSources': [{'path': name, 'sha256': sha(product/name),
            'reason': 'Unloaded historical preset/migration evidence retained in Git; absent from game pack.'} for name in sorted(omitted_product)],
        'files': {name: digest(body) for name, body in rows.items()}}
    destination = output(ROOT/'dist'/version)
    if destination.exists():
        raise ValueError('Retain prior artifacts; candidate output must be fresh')
    destination.mkdir(parents=True)
    recipe_path = output(destination/('ConsolePort-Forever-Official-Sources-'+version+'.zip'))
    data = archive_bytes(rows, manifest)
    recipe_path.write_bytes(data)
    recipe_hash = digest(data)
    read_pack(recipe_path, recipe_hash)
    recipe_receipt = {'path': recipe_path.name, 'sha256': recipe_hash, 'bytes': len(data), 'sourceCommit': commit,
        'assemblyComplete': False, 'dependencyPackages': len(packages), 'requiredAddonFolders': len(closures),
        'localPersonalUseOnly': True, 'redistributionApproved': False}
    output(recipe_path.with_suffix('.zip.receipt.json')).write_text(json.dumps(recipe_receipt, indent=2)+'\n', encoding='utf-8')
    result = {'recipe': recipe_receipt}
    if not recipe_only:
        caches = {p['repo']: ROOT/p['cache'] for p in lock['packages']}
        full = destination/('ConsolePort-Forever-UI-Pack-'+version+'.zip')
        result['personalPack'] = assemble(recipe_path, recipe_hash, full, lambda p: caches[p['repo']].read_bytes())
    print(json.dumps(result, indent=2))
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--recipe-only', action='store_true')
    args = parser.parse_args()
    build(args.recipe_only)
