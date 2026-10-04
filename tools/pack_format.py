"""Standalone pack verification. It never opens or changes a game tree."""
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import stat
import zipfile

FORMAT = 'ConsolePort-Forever-Personal-Pack'
MAX_BYTES = 1024 * 1024 * 1024


def digest(data):
    return hashlib.sha256(data).hexdigest()


def file_hash(path):
    value = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(block)
    return value.hexdigest()


def safe_relative(name):
    if not isinstance(name, str) or not name or '\\' in name or ':' in name or '\x00' in name:
        raise ValueError('Unsafe relative path: ' + repr(name))
    path = PurePosixPath(name)
    if path.is_absolute() or str(path) != name or any(p in {'.', '..'} for p in path.parts):
        raise ValueError('Unnormalized relative path: ' + name)
    for part in path.parts:
        if (part.endswith((' ', '.')) or any(c in part for c in '<>"|?*') or
            any(ord(c) < 32 for c in part) or
            re.match(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)', part, re.I)):
            raise ValueError('Unsafe Windows path: ' + name)
    return path


def is_link(path):
    return Path(path).is_symlink() or bool(getattr(Path(path).lstat(), 'st_file_attributes', 0) & 0x400)


def plain_path(path, base):
    """Reject aliases on every ancestor, not just the final canonical target."""
    path, base = Path(path).absolute(), Path(base).absolute()
    if path != base and not path.is_relative_to(base):
        raise ValueError('Path is outside selected scope: ' + str(path))
    for current in [path, *path.parents]:
        if (current.exists() or current.is_symlink()) and is_link(current):
            raise ValueError('Alias/reparse point refused: ' + str(current))
    if path.resolve() != path:
        raise ValueError('Canonical path changed: ' + str(path))
    return path


def zip_entries(data, allow_scripts=False):
    rows, seen, total = {}, set(), 0
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for item in archive.infolist():
            name = item.orig_filename.rstrip('/') if item.is_dir() else item.orig_filename
            if item.orig_filename != item.filename:
                raise ValueError('ZIP normalized an unsafe member')
            safe_relative(name)
            mode = item.external_attr >> 16
            if stat.S_IFMT(mode) not in {0, stat.S_IFREG, stat.S_IFDIR}:
                raise ValueError('ZIP link/special file refused: ' + name)
            if name.casefold() in seen:
                raise ValueError('Duplicate ZIP path: ' + name)
            seen.add(name.casefold())
            total += item.file_size
            if total > MAX_BYTES:
                raise ValueError('Archive exceeds bounded pack size')
            if item.is_dir():
                continue
            suffix = PurePosixPath(name).suffix.lower()
            if suffix in {'.exe', '.dll', '.msi', '.bat', '.cmd'} or (suffix == '.ps1' and not allow_scripts):
                raise ValueError('Executable package member refused: ' + name)
            rows[name] = archive.read(item)
    prefixes = {}
    for name in rows:
        parts = PurePosixPath(name).parts
        for index in range(1, len(parts)+1):
            prefix = '/'.join(parts[:index])
            key = prefix.casefold()
            if key in prefixes and prefixes[key] != prefix:
                raise ValueError('Case-insensitive directory collision')
            prefixes[key] = prefix
        if any('/'.join(parts[:index]) in rows for index in range(1, len(parts))):
            raise ValueError('ZIP file collides with a directory')
    return rows


def manifest_bytes(manifest):
    return (json.dumps(manifest, indent=2, sort_keys=True) + '\n').encode('utf-8')


def archive_bytes(rows, manifest):
    if 'pack-manifest.json' in rows:
        raise ValueError('Manifest is generated separately')
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for name, body in sorted({**rows, 'pack-manifest.json': manifest_bytes(manifest)}.items()):
            safe_relative(name)
            item = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            item.compress_type = zipfile.ZIP_DEFLATED
            item.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(item, body)
    return stream.getvalue()


def validate_manifest(manifest, rows, require_complete=False):
    if manifest.get('format') != FORMAT or manifest.get('formatVersion') != 1:
        raise ValueError('Unknown pack format')
    if not manifest.get('localPersonalUseOnly') or manifest.get('redistributionApproved') is not False:
        raise ValueError('Personal-use assembly boundary missing')
    if require_complete and not manifest.get('assemblyComplete'):
        raise ValueError('Official-source assembly has not completed')
    files = manifest.get('files')
    if not isinstance(files, dict) or set(files) != set(rows):
        raise ValueError('Pack file inventory mismatch')
    seen = set()
    folders = set()
    for name, expected in files.items():
        path = safe_relative(name)
        if name.casefold() in seen:
            raise ValueError('Case-insensitive file collision')
        seen.add(name.casefold())
        if digest(rows[name]) != expected:
            raise ValueError('Pack hash drift: ' + name)
        if path.parts[:2] == ('Interface', 'AddOns'):
            if len(path.parts) < 4 or path.parts[2] in {'WTF', 'reference', 'tests', 'tools', 'scratch'}:
                raise ValueError('Development/configuration files inside AddOns')
            if path.suffix.lower() in {'.py', '.ps1', '.zip', '.exe', '.dll', '.msi', '.bat', '.cmd'}:
                raise ValueError('Tooling/executable inside AddOns: ' + name)
            folders.add(path.parts[2])
        elif path.parts[0] not in {'Delivery', 'Notices', 'dependencies'} and name != 'README.md':
            raise ValueError('Unexpected pack root: ' + name)
    if sorted(folders) != manifest.get('addonFolders'):
        raise ValueError('Addon folder inventory mismatch')
    retired = manifest.get('retiredAddonFolders', {})
    if not isinstance(retired, dict):
        raise ValueError('Retired folder ownership must be explicit')
    retired_names = {f.casefold() for f in folders}
    for name, reason in retired.items():
        safe_relative(name)
        if '/' in name or name.casefold() in retired_names or not reason.get('owner') or not reason.get('reason'):
            raise ValueError('Unsafe or undisclosed retired addon folder')
        retired_names.add(name.casefold())
    if not re.fullmatch('[0-9a-f]{40}', manifest.get('sourceCommit', '')):
        raise ValueError('Exact source commit missing')
    if not isinstance(manifest.get('compatibility'), dict) or manifest['compatibility'].get('storeSchema') != 3:
        raise ValueError('Unsupported companion store compatibility')
    if not set(folders).issubset(manifest.get('runtimeClosure', {})):
        raise ValueError('Native runtime closure missing')
    for folder, closure in manifest.get('runtimeClosure', {}).items():
        if folder not in folders:
            if require_complete:
                raise ValueError('Required addon has not been assembled: ' + folder)
            continue
        for name in closure['runtimeFiles']:
            if 'Interface/AddOns/' + name not in files:
                raise ValueError('Runtime include absent: ' + name)
        toc_name = 'Interface/AddOns/' + closure['toc']
        text = rows[toc_name].decode('utf-8-sig', errors='replace')
        if re.search(r'@(?:project-version|interface|wow-version-[\w-]+)@', text):
            raise ValueError('Root TOC packager token: ' + toc_name)
    if require_complete and sorted(folders) != manifest.get('requiredAddonFolders'):
        raise ValueError('Required dependency coverage incomplete')
    return manifest


def read_pack(path, expected_sha256, require_complete=False):
    if not re.fullmatch('[0-9a-f]{64}', expected_sha256 or ''):
        raise ValueError('An independently supplied SHA-256 is required')
    path = Path(path).absolute()
    plain_path(path, path.parent)
    data = path.read_bytes()
    if digest(data) != expected_sha256:
        raise ValueError('Pack archive SHA-256 mismatch')
    rows = zip_entries(data, allow_scripts=True)
    raw = rows.pop('pack-manifest.json', None)
    if raw is None:
        raise ValueError('Pack manifest absent')
    manifest = json.loads(raw)
    validate_manifest(manifest, rows, require_complete)
    return manifest, rows
