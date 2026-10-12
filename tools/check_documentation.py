"""Read-only maintained-document/skill checks; no network or output files.

Historical reports, archives and immutable source evidence are deliberately not
linted as current guidance. This validates navigation/structure, not claim truth.
"""
from datetime import date
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
REQUIRED = (
    'AGENTS.md', 'README.md', 'CHANGELOG.md', 'tests/AGENTS.md', 'tools/AGENTS.md',
    'docs/MASTER-PLAN.md', 'docs/IMPLEMENTATION-STATUS.md',
    'docs/ARCHITECTURE.md', 'docs/REQUIREMENTS.md', 'docs/CONTROLLER_SPEC.md',
    'docs/STATE_MATRIX.md', 'docs/COMPATIBILITY.md', 'docs/DEVELOPMENT.md',
    'docs/TESTING.md', 'docs/KNOWN_ISSUES.md',
    'docs/reference/README.md', 'docs/reference/EVIDENCE.md',
    'docs/reference/DEVELOPMENT-HISTORY.md', 'docs/decisions/README.md',
    'docs/plans/README.md',
)
SKILLS = ('forever-regression-investigation', 'forever-dependency-qualification',
          'forever-scoped-release')


def scoped(path, root):
    """Reject aliases even when their canonical target is inside the checkout."""
    lexical = path.absolute()
    resolved = lexical.resolve()
    if not resolved.is_relative_to(root):
        raise ValueError('local target escapes repository')
    for ancestor in (lexical, *lexical.parents):
        if ancestor.exists() or ancestor.is_symlink():
            if ancestor.is_symlink() or getattr(ancestor.lstat(), 'st_file_attributes', 0) & 0x400:
                raise ValueError('local target uses a link/reparse point')
        if ancestor == root:
            break
    return resolved


def prose(text):
    """Ignore fenced examples; they are not rendered navigation."""
    rows = []
    fence = None
    for line in text.splitlines():
        marker = re.match(r'^\s{0,3}(`{3,}|~{3,})', line)
        if marker:
            run = marker[1]
            if fence is None:
                fence = run
            elif run[0] == fence[0] and len(run) >= len(fence):
                fence = None
            continue
        if fence is None:
            rows.append(line)
    return '\n'.join(rows)


def anchors(text):
    used = set()
    for line in prose(text).splitlines():
        heading = re.match(r'^#{1,6}\s+(.+?)(?:\s+#+)?\s*$', line)
        if not heading:
            continue
        label = re.sub(r'\[([^]]+)\]\([^)]*\)', r'\1', heading[1])
        slug = re.sub(r'[^\w\- ]', '', label.lower()).replace(' ', '-')
        candidate, suffix = slug, 0
        while candidate in used:
            suffix += 1
            candidate = f'{slug}-{suffix}'
        used.add(candidate)
    return used


def links(text):
    visible = re.sub(r'(`+).*?\1', '', prose(text))
    definitions = {}
    for match in re.finditer(r'^\s{0,3}\[([^]]+)\]:\s*(<[^>]+>|\S+)', visible, re.M):
        definitions[match[1].strip().casefold()] = match[2].strip('<>')
    targets = [m[1].strip('<>') for m in re.finditer(
        r'!?\[[^\n]*?\]\(\s*(<[^>]+>|[^\s)]+)(?:\s+["\'][^\n]*?["\'])?\s*\)', visible)]
    missing = []
    for match in re.finditer(r'!?\[([^]\n]+)\]\[([^]\n]*)\]', visible):
        key = (match[2] or match[1]).strip().casefold()
        if key not in definitions:
            missing.append(key)
        else:
            targets.append(definitions[key])
    targets.extend(definitions.values())
    return targets, missing


def skill_errors(path, text):
    """The local manifest convention is two simple single-line YAML scalars.

    No YAML dependency is needed. Rich optional YAML metadata should additionally
    use Skill Creator's full validator when introduced.
    """
    match = re.match(r'\A---\n(.*?)\n---(?:\n|$)', text, re.S)
    if not match:
        return ['missing skill YAML frontmatter']
    fields = {}
    for line in match[1].splitlines():
        if not line.strip() or line.lstrip().startswith('#'):
            continue
        row = re.fullmatch(r'(name|description):\s*(.+)', line)
        if not row or row[1] in fields:
            return ['skill frontmatter must use unique single-line name/description fields']
        value = row[2]
        if value.startswith(('"', "'")):
            if len(value) < 2 or value[-1] != value[0]:
                return ['unclosed skill scalar quote']
            value = value[1:-1]
        elif re.search(r':\s|\s#', value) or value in ('|', '>'):
            return ['quote YAML punctuation or use the documented single-line scalar convention']
        fields[row[1]] = value
    errors = []
    name = fields.get('name', '')
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', name) or len(name) > 64 or name != path.parent.name:
        errors.append('skill name must match its folder and use a <=64-character lowercase slug')
    if not fields.get('description', '').strip():
        errors.append('skill description is required')
    if not text[match.end():].strip():
        errors.append('skill body is required')
    return errors


def check(root=ROOT, required=REQUIRED, required_skills=SKILLS):
    root = Path(root).resolve()
    paths = {root / name for name in required}
    for directory in ('docs/decisions', 'docs/plans', 'docs/reference'):
        base = root / directory
        try:
            scoped(base, root)
            paths.update(base.glob('*.md'))
        except ValueError:
            paths.add(base)
    skill_base = root / '.agents/skills'
    paths.update(skill_base / name / 'SKILL.md' for name in required_skills)
    try:
        scoped(skill_base, root)
        for directory in skill_base.glob('*'):
            scoped(directory, root)
            if directory.is_dir():
                paths.add(directory / 'SKILL.md')
                paths.update(directory.glob('references/*.md'))
    except ValueError:
        paths.add(skill_base)
    failures = []
    for path in sorted(paths):
        prefix = path.relative_to(root).as_posix()
        try:
            target = scoped(path, root)
            text = target.read_text(encoding='utf-8-sig')
        except (OSError, ValueError) as error:
            failures.append(f'{prefix}: {error}')
            continue
        if path.name == 'SKILL.md':
            failures.extend(f'{prefix}: {error}' for error in skill_errors(path, text))
        elif '.agents' not in path.relative_to(root).parts:
            if not re.search(r'^Status: maintained$', text, re.M):
                failures.append(f'{prefix}: missing maintained status')
            review = re.search(r'^Reviewed: (\d{4}-\d{2}-\d{2})$', text, re.M)
            try:
                if review is None:
                    raise ValueError('missing review date')
                date.fromisoformat(review[1])
            except ValueError:
                failures.append(f'{prefix}: missing/invalid ISO review date')
            evidence = re.search(r'^Evidence:\s*(.+?)(?:\n\s*\n|\Z)', text, re.M | re.S)
            if evidence is None or not links(evidence[1])[0]:
                failures.append(f'{prefix}: evidence must contain a source link')
        targets, missing = links(text)
        failures.extend(f'{prefix}: undefined reference [{name}]' for name in missing)
        for raw in targets:
            try:
                url = urlsplit(raw)
                if url.scheme in ('https', 'http', 'mailto'):
                    continue
                if url.scheme or url.netloc or raw.startswith(('/', '\\')):
                    raise ValueError('use repository-relative local links')
                local = scoped(path.parent / unquote(url.path), root) if url.path else target
                if not local.exists():
                    raise ValueError('missing local target')
                if url.fragment:
                    if local.suffix.lower() != '.md' or unquote(url.fragment) not in anchors(local.read_text(encoding='utf-8-sig')):
                        raise ValueError('missing Markdown heading anchor')
            except (OSError, ValueError) as error:
                failures.append(f'{prefix}: {raw}: {error}')
    return len(paths), failures


if __name__ == '__main__':
    count, failures = check()
    for failure in failures:
        print('ERROR ' + failure)
    print(f'Documentation: {count} maintained pages/skill files checked; {len(failures)} errors. Historical text excluded; semantic/remote/Retail proof not evaluated.')
    sys.exit(1 if failures else 0)
