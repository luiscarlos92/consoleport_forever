"""Read immutable installed references against matching official old packages."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
from repository_paths import ROOT, contained, output, immutable_hashes, sha
from resolve_dependencies import fetch, members, segment, verify

OLD=[('seblindfors/ConsolePort','3.2.6'),('Cidan/BetterBags','v0.5.11')]
BASE=ROOT/'reference/installed-addons/2026-10-03-initial'
LOCK=ROOT/'evidence/dependencies/migration-lock.json'

def historical_package(identity):
    repo,tag=identity
    release=json.loads(subprocess.check_output(['gh','api','repos/'+repo+'/releases/tags/'+tag],timeout=45))
    if release['draft'] or release['prerelease'] or release['tag_name']!=tag:
        raise ValueError('Matching stable release required')
    assets=[a for a in release['assets'] if a['name'].lower().endswith('.zip') and 'nolib' not in a['name'].lower()]
    if len(assets)!=1: raise ValueError('Ambiguous matching historical package')
    asset=assets[0]
    segment(asset['name'])
    cache=output(ROOT/'dependencies/cache/migration'/asset['name'])
    digest=asset.get('digest')
    if not digest or not digest.startswith('sha256:'): raise ValueError('Matching upstream digest required')
    data=cache.read_bytes() if cache.exists() and digest=='sha256:'+sha(cache) else fetch(asset['browser_download_url'])
    actual=hashlib.sha256(data).hexdigest()
    if digest!='sha256:'+actual or len(data)!=asset['size']: raise ValueError('Historical asset identity mismatch')
    entries=members(data)
    cache.parent.mkdir(parents=True,exist_ok=True)
    if cache.exists() and sha(cache)!=actual: raise ValueError('Historical cache drift')
    cache.write_bytes(data)
    return {'repo':repo,'version':tag,'releaseURL':release['html_url'],'assetURL':asset['browser_download_url'],
            'expectedDigest':digest,'sha256':actual,'bytes':len(data),'cache':cache.relative_to(ROOT).as_posix(),
            'files':{name:hashlib.sha256(body).hexdigest() for name,body in entries}}

def classify(a,b,path):
    if a==b: return 'exact'
    if path.lower().endswith(('.lua','.toc','.xml','.md','.txt')):
        if a.replace(b'\r\n',b'\n')==b.replace(b'\r\n',b'\n'): return 'line-endings-only'
    return 'changed-needs-review'

def audit(packages, current):
    before=immutable_hashes(BASE)
    files,package_rows={},[]
    for package in packages:
        cache=contained(ROOT/package['cache'])
        if sha(cache)!=package['sha256'] or package['expectedDigest']!='sha256:'+sha(cache): raise ValueError('Historical package drift')
        entries=dict(members(cache.read_bytes()))
        if {name:hashlib.sha256(body).hexdigest() for name,body in entries.items()}!=package['files']: raise ValueError('Historical member drift')
        package_rows.append(package)
        for name,body in entries.items(): files[name]=(body,package['repo'],package['version'])
    # Immersion is already pinned to the exact installed release, including libs.
    immersion=next(p for p in current['packages'] if p['repo']=='seblindfors/Immersion')
    if immersion['version']!='1.4.61': raise ValueError('Matching Immersion release required')
    for name,digest in immersion['files'].items():
        path=contained(ROOT/immersion['unpacked']/name)
        if sha(path)!=digest: raise ValueError('Matching Immersion source drift')
        files[name]=(path.read_bytes(),immersion['repo'],immersion['version'])
    package_rows.append({k:immersion[k] for k in ['repo','version','releaseURL','assetURL','sha256','bytes']})
    folders={name.split('/')[0] for name in files}
    rows=[];lua_pairs=[];lua_rows=[]
    for name in sorted(set(files)|{n for n in before if n.split('/')[0] in folders}):
        baseline=BASE/name
        source=files.get(name)
        a=baseline.read_bytes() if name in before else None
        b=source[0] if source else None
        kind='installed-only' if b is None else 'package-only' if a is None else classify(a,b,name)
        row={'path':name,'classification':kind,'installedSHA256':hashlib.sha256(a).hexdigest() if a is not None else None,
             'officialSHA256':hashlib.sha256(b).hexdigest() if b is not None else None,
             'repo':source[1] if source else None,'version':source[2] if source else None}
        rows.append(row)
        if kind=='changed-needs-review' and name.lower().endswith('.lua'):
            try: lua_pairs.append([a.decode('utf-8-sig'),b.decode('utf-8-sig')]);lua_rows.append(row)
            except UnicodeDecodeError: pass
    if lua_pairs:
        result=subprocess.run(['node',str(ROOT/'tools/lua_equivalence.cjs')],input=json.dumps(lua_pairs),text=True,capture_output=True,check=True,timeout=45,cwd=ROOT)
        matches=json.loads(result.stdout)
        if len(matches)!=len(lua_rows): raise ValueError('Lua comparison result mismatch')
        for row,equal in zip(lua_rows,matches):
            if equal is True: row['classification']='Lua-formatting-comments-only'
            elif equal is False: row['classification']='substantive-Lua-change'
            else: row['classification']='unparsed-Lua-needs-review'
    if immutable_hashes(BASE)!=before: raise ValueError('Immutable reference drift during migration audit')
    counts={kind:sum(r['classification']==kind for r in rows) for kind in sorted({r['classification'] for r in rows})}
    return {'at':datetime.now(timezone.utc).isoformat(),'scope':'Copied installed CP suite, BetterBags and Immersion against matching packaged versions, including libraries.',
            'baselineManifestSHA256':sha(ROOT/'reference/manifests/2026-10-03-initial.json'),
            'packages':package_rows,'counts':counts,'files':rows,'limitations':'Parsed equality classifies formatting/comments only. Nonidentical code/additions require explicit migration ledger review. No source restored or live path read/written.'}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--refresh',action='store_true');args=parser.parse_args()
    if args.refresh:
        with ThreadPoolExecutor(max_workers=2) as pool: packages=list(pool.map(historical_package,OLD))
        output(LOCK).parent.mkdir(parents=True,exist_ok=True)
        output(LOCK).write_text(json.dumps(packages,indent=2))
    else: packages=json.loads(LOCK.read_text())
    if [(p['repo'],p['version']) for p in packages]!=OLD: raise ValueError('Historical lock identity drift')
    current=json.loads((ROOT/'dependencies/lock.json').read_text());verify(current)
    result=audit(packages,current)
    output(ROOT/'evidence/dependencies/migration-audit.json').write_text(json.dumps(result,indent=2))
    print(json.dumps(result['counts']))
    for row in result['files']:
        if row['classification'] not in ['exact','line-endings-only','Lua-formatting-comments-only']:
            print(row['classification'],row['path'])

if __name__=='__main__': main()
