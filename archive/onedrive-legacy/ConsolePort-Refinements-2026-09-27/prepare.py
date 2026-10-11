from pathlib import Path
import hashlib, json, shutil, subprocess
from datetime import datetime, timezone

ROOT = Path(r'C:\Program Files (x86)\World of Warcraft\_retail_')
WORK = Path(__file__).resolve().parent
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def closed():
    result = subprocess.run(['powershell', '-NoProfile', '-Command',
        "if (Get-Process | Where-Object {$_.ProcessName -match '^Wow'}) {exit 2}"], capture_output=True)
    assert result.returncode == 0, 'WoW is open. Leave staged files unapplied; never force an exit.'

changed = [
    'Interface/AddOns/ConsolePort_Bar/Widget/Group/Group.lua',
    'Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua',
    'Interface/AddOns/ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua',
    'WTF/Account/119624169#1/SavedVariables/ConsolePort.lua',
    'WTF/Account/119624169#1/SavedVariables/Immersion.lua',
    'WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua',
    'WTF/Account/119624169#1/bindings-cache.wtf',
    'WTF/Account/_template_/bindings-cache.wtf',
]
new = ['Interface/AddOns/ConsolePort_Forever/Assets/ForeverInGame.blp',
       'Interface/AddOns/ConsolePort_Forever/Assets/ForeverTargeting.blp']

if __name__ == '__main__':
    closed()
    assert not (WORK/'manifest.json').exists(), 'Never overwrite fresh rollback snapshot.'
    preserved = {}
    for base in [ROOT/'WTF', ROOT/'Interface/AddOns']:
        for p in base.rglob('*'):
            if p.is_file(): preserved[p.relative_to(ROOT).as_posix()] = digest(p)
    originals = {}
    for rel in changed:
        originals[rel] = digest(ROOT/rel)
        for folder in ['before', 'staged']:
            dst = WORK/folder/rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT/rel, dst)
    for rel in new: assert not (ROOT/rel).exists(), rel
    for name in ['ConsolePort-Forever-Implementation-Report.md', 'ConsolePort-Forever-Configuration-Plan.md', 'ConsolePort-Refinements-2026-09-27-Handoff.md']:
        dst = WORK/'before-docs'/name
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(WORK.parent/name, dst)
    manifest = dict(time=datetime.now(timezone.utc).isoformat(), root=str(ROOT), originals=originals,
        new=new, preserved=preserved,
        addons=sorted(p.name for p in (ROOT/'Interface/AddOns').iterdir() if p.is_dir()))
    (WORK/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
    print(f'WoW closed; fresh backups of {len(originals)} targets, {len(preserved)} preservation hashes, {len(manifest["addons"])} addon folders.')
