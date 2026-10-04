"""Explicit game-root guards and link-aware read-only backup inventories."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import time
from pack_format import file_hash, is_link, plain_path, safe_relative


def wow_is_running():
    if os.name != 'nt':
        raise ValueError('Real process verification requires Windows')
    result = subprocess.run(['powershell', '-NoProfile', '-NonInteractive', '-Command',
        "@(Get-Process | Where-Object { $_.ProcessName -match '^Wow(?:-64|Classic|T)?$' }).Count"],
        check=True, capture_output=True, text=True, timeout=20,
        creationflags=subprocess.CREATE_NO_WINDOW)
    return int(result.stdout.strip()) > 0


def anchor_info(path):
    path = Path(path).absolute()
    return {'lexical': str(path), 'canonical': str(path.resolve(strict=True)),
        'link': is_link(path), 'target': os.readlink(path) if is_link(path) else None,
        'device': path.stat().st_dev, 'inode': path.stat().st_ino}


class GameTree:
    def __init__(self, root, simulation=False, user_install=False, process_check=wow_is_running):
        self.root = Path(root).absolute()
        self.simulation, self.process_check = simulation, process_check
        plain_path(self.root, self.root)
        if not self.root.is_dir() or self.root.name.casefold() != '_retail_':
            raise ValueError('Select an existing, explicit _retail_ directory')
        if simulation:
            from repository_paths import ROOT, output
            output(self.root, ROOT/'scratch')
        elif not user_install or not (self.root/'WoW.exe').is_file():
            raise ValueError('Real installation requires explicit user execution and the Retail executable root')
        lexical = {'root': self.root, 'interface': self.root/'Interface',
            'addons': self.root/'Interface/AddOns', 'wtf': self.root/'WTF'}
        self.lexical = lexical
        self.identity = {key: anchor_info(path) for key, path in lexical.items()}
        if simulation and any(row['link'] for row in self.identity.values()):
            raise ValueError('Simulation root/anchor aliases refused')
        # Only explicitly inventoried real Interface/WTF anchor links are
        # supported. AddOns itself and every code descendant must be plain.
        if self.identity['addons']['link']:
            raise ValueError('AddOns anchor link refused')
        self.addons = Path(self.identity['addons']['canonical'])
        self.wtf = Path(self.identity['wtf']['canonical'])
        for anchor in [self.addons, self.wtf]:
            plain_path(anchor, anchor)
            if not anchor.is_dir():
                raise ValueError('Current addon/configuration directory missing')
        if self.addons == self.wtf or self.addons.is_relative_to(self.wtf) or self.wtf.is_relative_to(self.addons):
            raise ValueError('Overlapping addon/configuration anchors')
        self.check(force_process=True)

    def check(self, force_process=False):
        checked = time.monotonic()
        # Per-file guards still revalidate every anchor. Process enumeration is
        # bounded to once a second, with forced checks at promotion boundaries.
        if force_process or checked-getattr(self, '_last_process_check', 0) >= 1:
            if self.process_check():
                raise ValueError('WoW is running; close the game before backup, install or restore')
            self._last_process_check = checked
        current = {key: anchor_info(path) for key, path in self.lexical.items()}
        if current != self.identity:
            raise ValueError('Game root/junction identity changed during operation')

    def guard(self, path, scope):
        self.check()
        path, scope = Path(path).absolute(), Path(scope).absolute()
        if path == scope or not path.is_relative_to(scope):
            raise ValueError('Mutation must stay strictly in its selected scope')
        return plain_path(path, scope)


def inventory(root, allow_links=False):
    root = Path(root).absolute()
    plain_path(root, root)
    if not root.is_dir():
        raise ValueError('Inventory directory missing: '+str(root))
    files, directories, links, seen = {}, [], {}, set()
    for current, dirs, names in os.walk(root, followlinks=False):
        current = Path(current)
        for name in sorted(dirs+names):
            path = current/name
            relative = path.relative_to(root).as_posix()
            safe_relative(relative)
            if relative.casefold() in seen:
                raise ValueError('Case-insensitive inventory collision')
            seen.add(relative.casefold())
            if is_link(path):
                if not allow_links:
                    raise ValueError('Code tree link refused: '+relative)
                target = path.resolve(strict=True)
                if not target.is_relative_to(root) or target == root:
                    raise ValueError('Configuration link escapes its anchor: '+relative)
                links[relative] = {'target': os.readlink(path),
                    'canonicalRelative': target.relative_to(root).as_posix(),
                    'directory': path.is_dir(),
                    'junction': bool(getattr(path.lstat(), 'st_file_attributes', 0) & 0x400) and not path.is_symlink()}
                if name in dirs:
                    dirs.remove(name)
            elif path.is_dir():
                directories.append(relative)
            elif path.is_file():
                plain_path(path, root)
                files[relative] = {'sha256': file_hash(path), 'bytes': path.stat().st_size}
            else:
                raise ValueError('Unsupported filesystem entry: '+relative)
    # Link content is backed up once through its ordinary canonical path.
    for relative, row in links.items():
        target = row['canonicalRelative']
        if row['directory'] and target not in directories or not row['directory'] and target not in files:
            raise ValueError('Linked data has no ordinary backup target: '+relative)
    return {'files': files, 'directories': sorted(directories), 'links': links}


def copy_inventory(source, destination, snapshot, guard, fault=lambda event: None):
    source, destination = Path(source), Path(destination)
    guard(destination).mkdir()
    for name in snapshot['directories']:
        guard(destination/name).mkdir(parents=True, exist_ok=True)
    for name, row in snapshot['files'].items():
        fault('copy:'+name)
        src = plain_path(source/name, source)
        dst = guard(destination/name)
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        if file_hash(src) != row['sha256'] or file_hash(dst) != row['sha256']:
            raise ValueError('Backup copy/readback drift: '+name)
    # Never recreate backup links that could point into current live data.
    # Exact link topology is retained as metadata and verified separately.
    copied = inventory(destination)
    if copied['files'] != snapshot['files'] or copied['directories'] != snapshot['directories']:
        raise ValueError('Backup inventory incomplete')


def write_json(path, data, guard):
    path = guard(Path(path))
    temporary = guard(path.with_name(path.name+'.writing'))
    with temporary.open('wb') as stream:
        stream.write((json.dumps(data, indent=2, sort_keys=True)+'\n').encode('utf-8'))
        stream.flush()
        os.fsync(stream.fileno())
    guard(path)
    os.replace(temporary, path)


def backup_current(tree, backup_root, identity, guard, fault=lambda event: None):
    tree.check(force_process=True)
    snapshot = {'anchors': tree.identity, 'addons': inventory(tree.addons),
        'wtf': inventory(tree.wtf, allow_links=True)}
    versions = {}
    for name, row in snapshot['addons']['files'].items():
        if name.count('/') == 1 and name.lower().endswith('.toc'):
            body = plain_path(tree.addons/name, tree.addons).read_bytes()
            if file_hash(tree.addons/name) != row['sha256']:
                raise ValueError('Prior TOC changed during version capture')
            fields = {}
            for line in body.decode('utf-8-sig', errors='replace').splitlines():
                if line.startswith('##') and ':' in line:
                    key, value = line[2:].split(':', 1)
                    if key.strip() in {'Version', 'Interface', 'SavedVariables', 'SavedVariablesPerCharacter'}:
                        fields[key.strip()] = value.strip()
            versions[name] = {'sha256': row['sha256'], 'metadata': fields}
    snapshot['priorAddonMetadata'] = versions
    destination = guard(Path(backup_root)/identity)
    if destination.exists():
        raise ValueError('Backup must be fresh')
    destination.mkdir()
    write_json(destination/'snapshot.json', snapshot, guard)
    copy_inventory(tree.addons, destination/'AddOns', snapshot['addons'], guard, fault)
    copy_inventory(tree.wtf, destination/'WTF', snapshot['wtf'], guard, fault)
    tree.check(force_process=True)
    if inventory(tree.addons) != snapshot['addons'] or inventory(tree.wtf, True) != snapshot['wtf']:
        raise ValueError('Current files changed during backup')
    return destination, snapshot


def verify_backup(path, snapshot):
    for key, folder in [('addons', 'AddOns'), ('wtf', 'WTF')]:
        copied = inventory(Path(path)/folder)
        if copied['files'] != snapshot[key]['files'] or copied['directories'] != snapshot[key]['directories']:
            raise ValueError('Retained backup hash/inventory drift: '+folder)
