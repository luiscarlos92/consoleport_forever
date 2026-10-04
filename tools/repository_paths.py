"""Contain all tooling output and simulation copies inside this checkout."""
from pathlib import Path
import os
import shutil
import hashlib

ROOT = Path(__file__).resolve().parents[1]
LIVE_ROOTS = [Path('C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/_retail_'),
              Path('C:/Program Files (x86)/World of Warcraft/_retail_')]


def contained(path, base=ROOT):
    path, base = Path(path).resolve(), Path(base).resolve()
    if path == base or not path.is_relative_to(base):
        raise ValueError('Output must be strictly inside repository scope: ' + str(path))
    if any(path == live.resolve() or path.is_relative_to(live.resolve()) for live in LIVE_ROOTS):
        raise ValueError('Live WoW output rejected: ' + str(path))
    return path


def output(path, base=ROOT):
    """Check lexical ancestors as well as canonical containment before writes."""
    lexical, scope = Path(path).absolute(), Path(base).absolute()
    if scope != ROOT and not scope.is_relative_to(ROOT):
        raise ValueError('Output scope is outside checkout: ' + str(scope))
    if scope.resolve() != scope:
        raise ValueError('Output scope is an alias: ' + str(scope))
    canonical = contained(lexical, scope)
    for immutable in [ROOT / 'reference', ROOT / 'tests/fixtures']:
        if canonical == immutable or canonical.is_relative_to(immutable):
            raise ValueError('Immutable reference output rejected: ' + str(canonical))
    for parent in [lexical, *lexical.parents]:
        if parent.exists() or parent.is_symlink():
            if parent.is_symlink() or (getattr(parent.lstat(), 'st_file_attributes', 0) & 0x400):
                raise ValueError('Output ancestor is a link: ' + str(parent))
        if parent == scope:
            break
    return canonical


def sha(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for data in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(data)
    return h.hexdigest()


def immutable_hashes(source):
    result = {}
    for base, dirs, names in os.walk(source, followlinks=False):
        for name in dirs + names:
            path = Path(base) / name
            if path.is_symlink() or (getattr(path.lstat(), 'st_file_attributes', 0) & 0x400):
                raise ValueError('Reference contains a link: ' + str(path))
        for name in names:
            path = Path(base) / name
            result[path.relative_to(source).as_posix()] = sha(path)
    return result


def fixture_copy(source, destination):
    source = contained(source, ROOT / 'reference')
    destination = output(destination, ROOT / 'scratch')
    if destination.exists():
        raise ValueError('Simulation requires a fresh destination')
    before = immutable_hashes(source)
    shutil.copytree(source, destination)
    if immutable_hashes(source) != before or immutable_hashes(destination) != before:
        raise ValueError('Fixture drift during copy')
    return destination
