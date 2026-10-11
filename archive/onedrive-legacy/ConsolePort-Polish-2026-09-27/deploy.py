from pathlib import Path
import json, shutil, sys
from datetime import datetime, timezone
from prepare import ROOT, WORK, closed, digest

manifest=json.loads((WORK/'manifest.json').read_text(encoding='utf8'))
originals=manifest['originals']
validated=json.loads((WORK/'evidence/validated-staged-hashes.json').read_text(encoding='utf8'))
changed_real={(ROOT/rel).resolve() for rel in originals}
def preserve():
    count=0
    for rel,sha in manifest['preserved'].items():
        p=ROOT/rel
        if p.resolve() in changed_real: continue
        assert p.exists() and digest(p)==sha,'Unrequested file change: '+str(p)
        count+=1
    inventory=sorted(p.name for p in (ROOT/'Interface/AddOns').iterdir() if p.is_dir())
    assert inventory==manifest['addon_folders'],'Addon inventory changed'
    account=ROOT/'WTF/Account/119624169#1'
    template=(ROOT/'WTF/Account/_template_').resolve()
    characters=[]
    for realm in account.iterdir():
        if realm.is_dir() and realm.name!='SavedVariables':
            for character in realm.iterdir():
                if character.is_dir():
                    assert character.is_junction() and character.resolve()==template,'Non-shared character: '+str(character)
                    characters.append(str(character))
    assert len(characters)==42,len(characters)
    return dict(preserved_paths=count,addon_folders=len(inventory),character_junctions=len(characters))

closed()
mode=sys.argv[1] if len(sys.argv)>1 else '--verify'
if mode=='--apply':
    assert not (WORK/'deployment.json').exists(),'Already deployed; do not apply again.'
    for rel,sha in originals.items():
        assert digest(ROOT/rel)==sha,'Live file changed since backup: '+rel
        assert digest(WORK/'staged'/rel)==validated[rel],'Staged file not validated: '+rel
    preserve()
    copied=[]
    try:
        for rel in originals:
            shutil.copy2(WORK/'staged'/rel,ROOT/rel);copied.append(rel)
    except Exception:
        for rel in copied: shutil.copy2(WORK/'before'/rel,ROOT/rel)
        raise
    (WORK/'deployment.json').write_text(json.dumps(dict(time=datetime.now(timezone.utc).isoformat(),hashes=validated),indent=2),encoding='utf8')
elif mode=='--rollback':
    for rel,sha in validated.items():
        assert digest(ROOT/rel)==sha,'File changed after deployment; review before restoring: '+rel
    for rel in originals: shutil.copy2(WORK/'before'/rel,ROOT/rel)
    print('Restored the ten pre-polish files. WoW was closed.');sys.exit(0)
elif mode!='--verify': raise SystemExit('Use --apply, --verify or --rollback')

for rel,sha in validated.items(): assert digest(ROOT/rel)==sha,'Deployment hash differs: '+rel
checks=preserve();checks['time']=datetime.now(timezone.utc).isoformat();checks['deployed_files']=len(validated)
(WORK/'evidence/preservation.json').write_text(json.dumps(checks,indent=2),encoding='utf8')
print('PASS: '+json.dumps(checks))
