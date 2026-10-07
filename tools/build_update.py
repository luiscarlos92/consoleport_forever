"""Build a small tested update: companion and explicitly changed packages only."""
import argparse
from datetime import datetime, timezone
import json
import re
from build_pack import verified_source
from repository_paths import ROOT, contained, output, immutable_hashes, sha
from audit_dependencies import runtime_closure
from pack_format import FORMAT, archive_bytes, digest, read_pack


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


def build(selected_repos=(),label=None):
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
    version=closures['ConsolePort_Forever']['metadata']['Version'].strip()
    revision=int(re.search(r'Addon.CONFIG_REVISION=(\d+)',rows['Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua'].decode()).group(1))
    # Keep all package identities in the receipt without shipping their bytes.
    identities={p['repo']:{'version':p['version'],'sha256':p['sha256']} for p in lock['packages']}
    manifest={'format':FORMAT,'formatVersion':1,'sourceCommit':commit,
        'deploymentScope':'companion-and-updated-dependencies','dependencyUpdates':updates,
        'testedDependencies':identities,'dependencyLockSHA256':lock_hash,
        'localPersonalUseOnly':True,'redistributionApproved':False,'assemblyComplete':True,
        'addonFolders':sorted(closures),'requiredAddonFolders':sorted(closures),'retiredAddonFolders':{},
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
        'addonFolders':manifest['addonFolders'],'dependencyUpdates':sorted(updates),'version':version,
        'testedDependencies':identities,'dependencyLockSHA256':lock_hash}
    output(destination.with_suffix('.zip.receipt.json')).write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
    return receipt


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--dependency',action='append',default=[],help='Updated locked repository to include; repeat as needed, default is Forever only')
    parser.add_argument('--label',help='Retained artifact label when rebuilding the same candidate version')
    args=parser.parse_args()
    print(json.dumps(build(args.dependency,args.label),indent=2))
