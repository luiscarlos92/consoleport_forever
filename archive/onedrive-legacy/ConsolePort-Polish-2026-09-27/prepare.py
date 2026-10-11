from pathlib import Path
import hashlib, json, shutil, subprocess
from datetime import datetime, timezone

ROOT = Path(r'C:\Program Files (x86)\World of Warcraft\_retail_')
WORK = Path(__file__).resolve().parent
def digest(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def closed():
    r = subprocess.run(['powershell', '-NoProfile', '-Command', "if (Get-Process | Where-Object {$_.ProcessName -match '^Wow'}) {exit 2}"], capture_output=True)
    assert r.returncode == 0, 'WoW is running; do not modify game files.'

changed = [
    'Interface/AddOns/ConsolePort_Bar/Widget/Group/Group.lua',
    'Interface/AddOns/ConsolePort_Bar/Widget/Cluster/Cluster.lua',
    'Interface/AddOns/ConsolePort_Bar/Widget/Cluster/Skins.lua',
    'Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua',
    'Interface/AddOns/ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua',
    'Interface/AddOns/ConsolePort/Model/Game/Bindings.lua',
    'WTF/Account/119624169#1/SavedVariables/ConsolePort.lua',
    'WTF/Account/119624169#1/SavedVariables/Immersion.lua',
    'WTF/Account/119624169#1/bindings-cache.wtf',
    'WTF/Account/_template_/bindings-cache.wtf',
]

if __name__ == '__main__':
    closed()
    assert not (WORK/'manifest.json').exists(), 'Snapshot already exists; never overwrite rollback.'
    preserved = {}
    # Account directory contains character junctions. rglob does not follow them;
    # the canonical shared template is snapshotted separately by this traversal.
    for p in (ROOT/'WTF').rglob('*'):
        if p.is_file(): preserved[p.relative_to(ROOT).as_posix()] = digest(p)
    for addon in ['Immersion', 'Immersion_ExtraFade', 'DynamicCam']:
        for p in (ROOT/'Interface/AddOns'/addon).rglob('*'):
            if p.is_file(): preserved[p.relative_to(ROOT).as_posix()] = digest(p)
    originals = {}
    for rel in changed:
        src = ROOT/rel
        originals[rel] = digest(src)
        for folder in ['before', 'staged']:
            dest = WORK/folder/rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
    manifest = dict(time=datetime.now(timezone.utc).isoformat(), root=str(ROOT),
                    originals=originals, preserved=preserved,
                    addon_folders=sorted(p.name for p in (ROOT/'Interface/AddOns').iterdir() if p.is_dir()))
    (WORK/'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
    print(f'WoW closed; backed up {len(originals)} targets; hashed {len(preserved)} preservation files; {len(manifest["addon_folders"])} addon folders.')
