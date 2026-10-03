"""Read-only, verified import of the authorized installed addon/config baseline.

Run once from the repository. Links are inventoried, never copied as links.
No Lua data is executed. A changing source aborts capture before baseline commit.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
LIVE = Path('C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft')
SNAPSHOT = '2026-10-03-initial'


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def inventory(source):
    files, links = [], []
    for base, dirs, names in os.walk(source, followlinks=False):
        for name in list(dirs):
            path = Path(base) / name
            if path.is_symlink() or (hasattr(os.path, 'isjunction') and os.path.isjunction(path)) or (path.lstat().st_file_attributes & 0x400):
                links.append({'alias': str(path), 'target': str(path.resolve())})
                dirs.remove(name)
        for name in names:
            path = Path(base) / name
            if path.is_symlink():
                links.append({'alias': str(path), 'target': str(path.resolve())})
                continue
            # Old compressed template archive is not active configuration.
            if path.suffix.lower() == '.rar':
                continue
            files.append((path, path.relative_to(source), path.stat().st_size, digest(path)))
    return files, links


def capture(source, target):
    source = source.resolve(strict=True)
    target = ROOT / target
    if not target.resolve().is_relative_to(ROOT) or target.exists():
        raise RuntimeError('Capture requires a new repository-contained destination: ' + str(target))
    files, links = inventory(source)
    for path, relative, size, sha in files:
        dest = target / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, dest)
        if digest(dest) != sha:
            raise RuntimeError('Destination hash mismatch: ' + str(dest))
        manifest.append({'source': str(path), 'canonicalSource': str(path.resolve()),
                         'destination': dest.relative_to(ROOT).as_posix(), 'bytes': size, 'sha256': sha})
    after, after_links = inventory(source)
    if [(str(p), s, h) for p, _, s, h in files] != [(str(p), s, h) for p, _, s, h in after] or links != after_links:
        raise RuntimeError('Source changed during capture; retry under a new snapshot identity')
    link_inventory.extend(links)


if __name__ == '__main__':
    manifest, link_inventory = [], []
    addons = LIVE / '_retail_/Interface/AddOns'
    capture(addons / 'ConsolePort_Forever', Path('addon/ConsolePort_Forever'))
    for addon in sorted(addons.iterdir()):
        if addon.is_dir() and addon.name != 'ConsolePort_Forever':
            capture(addon, Path('reference/installed-addons') / SNAPSHOT / addon.name)
    capture(LIVE / '_retail_/WTF', Path('reference/config') / SNAPSHOT)
    capture(LIVE / 'Forever-Design-2026-10-03/handoff-pass/sandbox', Path('tests/fixtures/historical-sandbox'))
    docs = ROOT / 'docs'
    docs.mkdir(exist_ok=True)
    shutil.copyfile(LIVE / 'ConsolePort-Forever-Phased-Plan-2026-10-03.md', docs / 'MASTER-PLAN.md')
    evidence = ROOT / 'evidence/design-handoff'
    evidence.mkdir(parents=True, exist_ok=True)
    for path in (LIVE / 'Forever-Design-2026-10-03/handoff-pass').glob('*.json'):
        shutil.copyfile(path, evidence / path.name)
    for name in ['evidence-manifest.json', 'verification.json', 'consoleport-restoration-audit.json',
                 'form-and-storage-review.json', 'specialization-review.json']:
        path = LIVE / 'Forever-Design-2026-10-03' / name
        if path.exists():
            shutil.copyfile(path, evidence / name)
    for name in ['Interface', 'WTF']:
        path = Path('C:/Program Files (x86)/World of Warcraft/_retail_') / name
        link_inventory.append({'alias': str(path), 'target': str(path.resolve())})
    out = ROOT / 'reference/manifests'
    out.mkdir(parents=True, exist_ok=True)
    receipt = {'snapshot': SNAPSHOT, 'capturedAt': datetime.now(timezone.utc).isoformat(),
               'files': manifest, 'links': link_inventory,
               'exclusions': ['inactive .rar archives', 'WoW binaries/Data', 'removed-addon archives', 'credential stores']}
    (out / (SNAPSHOT + '.json')).write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    print(json.dumps({'files': len(manifest), 'bytes': sum(x['bytes'] for x in manifest),
                      'links': len(link_inventory), 'largestBytes': max(x['bytes'] for x in manifest)}))
