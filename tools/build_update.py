"""Build a small tested update: companion and explicitly changed packages only."""
import argparse
from datetime import datetime, timezone
import json
import re
from build_pack import verified_source, git, validate_runtime_results
from repository_paths import ROOT, contained, output, immutable_hashes, sha
from audit_dependencies import runtime_closure
from pack_format import FORMAT, archive_bytes, digest, read_pack, STANDALONE_FOREVER_ADDON, STANDALONE_FOREVER_SCOPE, STANDALONE_FOREVER_CONTRACTS


def standalone_payload(folder=STANDALONE_FOREVER_ADDON):
    if folder not in STANDALONE_FOREVER_CONTRACTS:
        raise ValueError('Unqualified standalone addon')
    product = ROOT/'addon'/folder
    files = {folder+'/'+name:(product/name).read_bytes() for name in immutable_hashes(product)}
    closure = runtime_closure(folder, files, require_retail=False)
    return {'Interface/AddOns/'+name:body for name,body in files.items()}, {folder:closure}


def validate_targeted_immersion(baseline, current, hashes):
    """Explicit user-scoped regression route; never represents a full fresh run."""
    required = {'T109.forever-immersion-extension-native-lifecycle-and-layout',
                'T110.forever-immersion-extension-defect-and-work-controls'}
    if len(current['results']) != 2 or {r['id'] for r in current['results']} != required or any(r['status'] != 'passed' for r in current['results']):
        raise ValueError('Exact passing Forever Immersion regression checks required')
    normalize = lambda values: {k.replace('\\', '/'): v for k, v in values.items()}
    allowed = {'tools/build_update.py', 'tools/test-all.cjs', 'tests/test_targeted_immersion.py',
               'tests/harness/immersion_extended.lua'}
    for group in ('productHashes', 'toolingHashes'):
        before, tested, actual = map(normalize, (baseline[group], current[group], hashes[group]))
        if tested != actual:
            raise ValueError('Targeted tested inventory changed')
        for name in set(before) | set(actual):
            if before.get(name) != actual.get(name) and not (name.startswith('addon/ImmersionExtended_Forever/') or name in allowed):
                raise ValueError('Change outside targeted Immersion scope: '+name)


def targeted_immersion_source(report):
    if git('status', '--porcelain', '--untracked-files=normal'):
        raise ValueError('Pack source must be clean and committed')
    commit = git('rev-parse', 'HEAD')
    if git('ls-remote', 'origin', 'refs/heads/main').split()[0] != commit:
        raise ValueError('Source commit must already be pushed on main')
    baseline = json.loads((ROOT/'scratch/test-results/latest.json').read_text(encoding='utf-8'))
    validate_runtime_results(baseline['results'], (ROOT/'tools/test-all.cjs').read_text(encoding='utf-8'))
    path = contained(ROOT/report)
    current = json.loads(path.read_text(encoding='utf-8'))
    hashes = {'productHashes': {str(p.relative_to(ROOT)): sha(p) for p in (ROOT/'addon').rglob('*') if p.is_file()},
              'toolingHashes': {str(p.relative_to(ROOT)): sha(p) for base in ('tools', 'tests') for p in (ROOT/base).rglob('*') if p.is_file() and '__pycache__' not in p.parts}}
    validate_targeted_immersion(baseline, current, hashes)
    if current['pinnedDependencyLockSHA256'] != baseline['pinnedDependencyLockSHA256']:
        raise ValueError('Targeted route cannot change dependency lock')
    current['toolingReportSHA256'] = sha(ROOT/'scratch/test-results/tooling-latest.json')
    return commit, current, sha(path)


def build_standalone(label=None, folder=STANDALONE_FOREVER_ADDON, targeted_report=None):
    if targeted_report and folder != STANDALONE_FOREVER_ADDON:
        raise ValueError('Targeted route is only for Forever Immersion')
    commit, tests, test_hash = targeted_immersion_source(targeted_report) if targeted_report else verified_source()
    stable = json.loads((ROOT/'evidence/dependencies/stable-recheck.json').read_text(encoding='utf-8'))
    lock_hash = sha(ROOT/'dependencies/lock.json')
    age = (datetime.now(timezone.utc)-datetime.fromisoformat(stable['checkedAt'])).total_seconds()
    if (not stable['allCurrent'] or not 0 <= age <= 86400 or
            stable['lockSHA256'] != lock_hash or tests['pinnedDependencyLockSHA256'] != lock_hash):
        raise ValueError('Current tested official source check required')
    if label is not None and not re.fullmatch(r'[a-z][a-z0-9-]{0,47}',label):
        raise ValueError('Output label must be a short lowercase slug')
    rows, closures = standalone_payload(folder)
    version = closures[folder]['metadata']['Version'].strip()
    if not re.fullmatch(r'[0-9A-Za-z][0-9A-Za-z.+_-]{0,63}', version):
        raise ValueError('Unsafe standalone artifact version')
    manifest = {'format':FORMAT,'formatVersion':1,'sourceCommit':commit,
        'deploymentScope':STANDALONE_FOREVER_SCOPE,'dependencyUpdates':{},
        'dependencyLockSHA256':lock_hash,'localPersonalUseOnly':True,
        'redistributionApproved':False,'assemblyComplete':True,'addonFolders':[folder],
        'requiredAddonFolders':[folder],'retiredAddonFolders':{},
        'compatibility':{'gameType':'camelot','interface':16001},
        'runtimeClosure':closures,'files':{n:digest(b) for n,b in rows.items()},
        'runtimeReportSHA256':test_hash,'toolingReportSHA256':tests['toolingReportSHA256']}
    if targeted_report:
        manifest['qualificationScope'] = 'user-authorized-forever-immersion-only'
    data = archive_bytes(rows,manifest)
    stem = 'ImmersionExtended-Forever' if folder == STANDALONE_FOREVER_ADDON else folder.replace('_','-')
    directory = 'immersion-extended' if folder == STANDALONE_FOREVER_ADDON else stem.lower()
    destination = output(ROOT/'dist'/(directory+'-'+version)/
        (stem+'-'+version+('-'+label if label else '')+'.zip'))
    if destination.exists():
        raise ValueError('Retain existing artifact; choose a new label')
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(data)
    checksum = digest(data)
    read_pack(destination,checksum,True)
    receipt = {'path':str(destination),'sha256':checksum,'bytes':len(data),
        'sourceCommit':commit,'addonFolders':[folder],'version':version}
    output(destination.with_suffix('.zip.receipt.json')).write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    return receipt


def update_payload(lock, coverage, selected_repos=()):
    """Do not open any unchanged vendor package, cache, or unpacked file."""
    selected=set(selected_repos)
    packages={p['repo']:p for p in lock['packages']}
    if not selected.issubset(packages): raise ValueError('Unknown selected dependency')
    product=ROOT/'addon/ConsolePort_Forever'
    files={'ConsolePort_Forever/'+name:(product/name).read_bytes()
        for name in immutable_hashes(product) if name not in {'Bindings.lua','Layout.lua','Profile.lua'}}
    closures={'ConsolePort_Forever':runtime_closure('ConsolePort_Forever',files)}
    updates={}
    for repo in sorted(selected):
        package=packages[repo]
        folders=sorted(name for name,row in coverage['selectedFolders'].items() if row['owner']==repo)
        if not folders: raise ValueError('Selected dependency has no qualified folders: '+repo)
        package_files={name:value for name,value in package['files'].items() if name.split('/')[0] in folders}
        for name,expected in package_files.items():
            path=contained(ROOT/package['unpacked']/name)
            if sha(path)!=expected: raise ValueError('Selected official dependency drift: '+name)
            files[name]=path.read_bytes()
        for folder in folders:
            closures[folder]=runtime_closure(folder,files,require_retail=coverage['selectedFolders'][folder]['eligibleForRetail'])
        updates[repo]={'version':package['version'],'packageSHA256':package['sha256'],
            'addonFolders':folders,'files':package_files}
    return {'Interface/AddOns/'+name:body for name,body in files.items()},closures,updates


def artifact_name(selected_key,label=None):
    if label is not None and not re.fullmatch(r'[a-z][a-z0-9-]{0,47}',label):
        raise ValueError('Output label must be a short lowercase slug')
    return 'ConsolePort-Forever-Update-'+selected_key+('-'+label if label else '')+'.zip'


def build(selected_repos=(),label=None,retire_addons=()):
    commit,tests,test_hash=verified_source()
    lock_path=ROOT/'dependencies/lock.json'
    lock=json.loads(lock_path.read_text(encoding='utf-8'))
    coverage=json.loads((ROOT/'evidence/dependencies/coverage.json').read_text(encoding='utf-8'))
    stable=json.loads((ROOT/'evidence/dependencies/stable-recheck.json').read_text(encoding='utf-8'))
    lock_hash=sha(lock_path)
    if not lock.get('coverageQualified') or coverage['lockSHA256']!=lock_hash or stable['lockSHA256']!=lock_hash or tests['pinnedDependencyLockSHA256']!=lock_hash:
        raise ValueError('Current tested dependency lock and coverage required')
    age=(datetime.now(timezone.utc)-datetime.fromisoformat(stable['checkedAt'])).total_seconds()
    if not stable['allCurrent'] or not 0<=age<=86400: raise ValueError('Current official release check required')
    rows,closures,updates=update_payload(lock,coverage,selected_repos)
    declared=json.loads((ROOT/'dependencies/sources.json').read_text(encoding='utf-8')).get('retiredAddonFolders',{})
    if not set(retire_addons).issubset(declared): raise ValueError('Undeclared addon retirement')
    retired={name:declared[name] for name in sorted(set(retire_addons))}
    version=closures['ConsolePort_Forever']['metadata']['Version'].strip()
    revision=int(re.search(r'Addon.CONFIG_REVISION=(\d+)',rows['Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua'].decode()).group(1))
    # Keep all package identities in the receipt without shipping their bytes.
    identities={p['repo']:{'version':p['version'],'sha256':p['sha256']} for p in lock['packages']}
    manifest={'format':FORMAT,'formatVersion':1,'sourceCommit':commit,
        'deploymentScope':'companion-and-updated-dependencies','dependencyUpdates':updates,
        'testedDependencies':identities,'dependencyLockSHA256':lock_hash,
        'localPersonalUseOnly':True,'redistributionApproved':False,'assemblyComplete':True,
        'addonFolders':sorted(closures),'requiredAddonFolders':sorted(closures),'retiredAddonFolders':retired,
        'compatibility':{'storeSchema':3,'configurationRevision':revision,
            'dependencyVersions':{p['repo']:p['version'] for p in lock['packages']}},
        'runtimeClosure':closures,'files':{name:digest(body) for name,body in rows.items()},
        'runtimeReportSHA256':test_hash,'toolingReportSHA256':tests['toolingReportSHA256']}
    data=archive_bytes(rows,manifest)
    selected_key='dependencies-'+digest(json.dumps(sorted(updates)).encode())[:12] if updates else 'companion-only'
    destination=output(ROOT/'dist'/version/artifact_name(selected_key,label))
    if destination.exists(): raise ValueError('Retain existing update artifact; choose a new version/output before rebuilding')
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_bytes(data)
    checksum=digest(data)
    read_pack(destination,checksum,True)
    receipt={'path':str(destination),'sha256':checksum,'bytes':len(data),'sourceCommit':commit,
        'addonFolders':manifest['addonFolders'],'dependencyUpdates':sorted(updates),'retiredAddonFolders':retired,'version':version,
        'testedDependencies':identities,'dependencyLockSHA256':lock_hash}
    output(destination.with_suffix('.zip.receipt.json')).write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    return receipt


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--dependency',action='append',default=[],help='Updated locked repository to include; repeat as needed, default is Forever only')
    parser.add_argument('--label',help='Retained artifact label when rebuilding the same candidate version')
    parser.add_argument('--retire-addon',action='append',default=[],help='Explicit declared retirement to back up and park; never broad pruning')
    parser.add_argument('--standalone-forever',action='store_true',help='Only ImmersionExtended_Forever; never ships the Retail companion')
    parser.add_argument('--standalone-addon',choices=sorted(STANDALONE_FOREVER_CONTRACTS),help='One qualified Forever-only addon; never ships the Retail companion')
    parser.add_argument('--targeted-immersion-report',help='Explicit user-authorized Forever Immersion checks; unchanged baseline required')
    args=parser.parse_args()
    if (args.standalone_forever or args.standalone_addon) and (args.dependency or args.retire_addon):
        parser.error('Standalone Forever cannot update/retire dependencies')
    if args.standalone_forever and args.standalone_addon:
        parser.error('Select one standalone mode')
    if args.targeted_immersion_report and not (args.standalone_forever or args.standalone_addon):
        parser.error('Targeted report requires standalone mode')
    print(json.dumps(build_standalone(args.label,args.standalone_addon or STANDALONE_FOREVER_ADDON,args.targeted_immersion_report) if args.standalone_forever or args.standalone_addon else
        build(args.dependency,args.label,args.retire_addon),indent=2))
