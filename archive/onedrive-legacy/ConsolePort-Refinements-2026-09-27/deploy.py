from pathlib import Path
import json, shutil, sys, difflib
from datetime import datetime, timezone
from prepare import WORK, ROOT, closed, digest
m=json.loads((WORK/'manifest.json').read_text())
tested=json.loads((WORK/'evidence/validated-staged-hashes.json').read_text())
deployment_file=WORK/'deployment.json'
installed=(json.loads(deployment_file.read_text())['hashes'] if deployment_file.exists() else tested)
changed_real={(ROOT/rel).resolve() for rel in m['originals']}

def preserve():
    n=0;runtime_refs=[]
    runtime_file=WORK/'evidence/runtime-preservation-diff.json'
    runtime={d['path']:d for d in json.loads(runtime_file.read_text())} if runtime_file.exists() else {}
    for rel,sha in m['preserved'].items():
        p=ROOT/rel
        if p.resolve() in changed_real: continue
        current=digest(p) if p.exists() else None
        # Client startup regenerated its documented reference-only defaults.
        # Keep the original baseline and accept only this recorded exact hash.
        if rel=='WTF/GamePadConfig_Default.json' and rel in runtime and current==runtime[rel]['after'] and current!=sha:
            runtime_refs.append(rel);continue
        assert p.exists() and current==sha, 'Unrequested change: '+rel
        n+=1
    inventory=sorted(p.name for p in (ROOT/'Interface/AddOns').iterdir() if p.is_dir())
    assert inventory==m['addons'], 'Addon inventory changed'
    template=(ROOT/'WTF/Account/_template_').resolve();count=0
    for realm in (ROOT/'WTF/Account/119624169#1').iterdir():
        if realm.is_dir() and realm.name!='SavedVariables':
            for char in realm.iterdir():
                if char.is_dir():
                    assert char.is_junction() and char.resolve()==template,str(char)
                    count+=1
    assert count==42,count
    return dict(preserved_paths=n,addon_folders=len(inventory),character_junctions=count,runtime_regenerated_references=runtime_refs)

closed()
mode=sys.argv[1] if len(sys.argv)>1 else '--verify'
if mode=='--apply':
    assert not deployment_file.exists(),'Already installed; do not replay.'
    for rel,sha in m['originals'].items(): assert digest(ROOT/rel)==sha,'Live target changed since backup: '+rel
    for rel in m['new']: assert not (ROOT/rel).exists(),rel
    for rel,sha in tested.items(): assert digest(WORK/'staged'/rel)==sha,'Untested staged file: '+rel
    preserve();closed()
    copied=[]
    try:
        for rel in tested:
            (ROOT/rel).parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(WORK/'staged'/rel,ROOT/rel);copied.append(rel)
    except Exception:
        for rel in copied:
            if rel in m['originals']: shutil.copy2(WORK/'before'/rel,ROOT/rel)
            elif digest(ROOT/rel)==tested[rel]: (ROOT/rel).unlink()
        raise
    deployment_file.write_text(json.dumps(dict(time=datetime.now(timezone.utc).isoformat(),hashes=tested),indent=2))
    patch=[]
    for rel in m['originals']:
        a=(WORK/'before'/rel).read_text().splitlines(keepends=True)
        b=(WORK/'staged'/rel).read_text().splitlines(keepends=True)
        patch.extend(difflib.unified_diff(a,b,fromfile='before/'+rel,tofile='after/'+rel))
    (WORK/'changes.patch').write_text(''.join(patch),encoding='utf8')
elif mode=='--rollback':
    for rel,sha in installed.items(): assert digest(ROOT/rel)==sha,'Changed since install; compare before restoring: '+rel
    closed()
    for rel in m['originals']: shutil.copy2(WORK/'before'/rel,ROOT/rel)
    for rel in m['new']:
        p=(ROOT/rel).resolve()
        assert p.is_relative_to((ROOT/'Interface/AddOns/ConsolePort_Forever/Assets').resolve())
        p.unlink()
    print('Restored eight pre-refinement files and removed the two added art sheets.');sys.exit(0)
elif mode!='--verify': raise SystemExit('Use --apply, --verify or --rollback')
for rel,sha in installed.items(): assert digest(ROOT/rel)==sha,'Installed file differs: '+rel
checks=preserve();checks.update(time=datetime.now(timezone.utc).isoformat(),installed_files=len(tested))
(WORK/'evidence/preservation.json').write_text(json.dumps(checks,indent=2))
print('PASS: '+json.dumps(checks))
