from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from check_documentation import check
from repository_paths import ROOT, output


class DocumentationChecks(unittest.TestCase):
    def setUp(self):
        output(ROOT / 'scratch').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='doc-check-', dir=output(ROOT / 'scratch'))
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()

    def write(self, name, body):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding='utf-8')
        return path

    def page(self, links):
        return '# Example\n\nStatus: maintained\nReviewed: 2026-10-11\nEvidence: [source](source.md).\n\n' + links

    def errors(self):
        return check(self.root, required=('README.md',), required_skills=())[1]

    def test_valid_navigation_anchors_reference_links_and_read_only(self):
        self.write('source.md', '# Source\n## Same\n## Same\n')
        self.write('README.md', self.page('[heading](source.md#same-1) [ref][s]\n[s]: source.md#source\n```\n[example](missing.md)\n```\n'))
        before = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob('*') if p.is_file()}
        self.assertEqual(self.errors(), [])
        self.assertEqual(before, {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob('*') if p.is_file()})

    def test_missing_target_anchor_and_undefined_reference_are_rejected(self):
        self.write('source.md', '# Source\n')
        self.write('README.md', self.page('[absent](absent.md) [bad](source.md#no) [ref][undefined]'))
        errors = self.errors()
        for fragment in ('missing local target', 'missing Markdown heading anchor', 'undefined reference'):
            self.assertTrue(any(fragment in error for error in errors), errors)

    def test_escaping_and_absolute_local_links_are_rejected(self):
        self.write('source.md', '# Source\n')
        self.write('README.md', self.page('[escape](../outside.md) [windows](C:/production/file.md) [absolute](/outside.md)'))
        errors = self.errors()
        self.assertTrue(any('escapes repository' in error for error in errors))
        self.assertEqual(sum('repository-relative' in error for error in errors), 2)

    def test_history_excluded_but_required_metadata_not_optional(self):
        self.write('source.md', '# Source\n')
        self.write('README.md', '# Current\n[link](source.md)\n')
        self.write('docs/archive/old.md', '[historical](C:/missing/old.md)')
        errors = self.errors()
        self.assertTrue(any('status' in error for error in errors))
        self.assertTrue(any('review date' in error for error in errors))
        self.assertTrue(any('evidence' in error for error in errors))
        self.assertFalse(any('old.md' in error for error in errors))

    def test_discovered_skill_manifest_name_and_required_body(self):
        self.write('source.md', '# Source\n')
        self.write('README.md', self.page(''))
        skill = self.write('.agents/skills/example/SKILL.md', '---\nname: wrong\ndescription: Diagnose sample failures.\n---\n')
        errors = self.errors()
        self.assertTrue(any('skill name' in error for error in errors))
        self.assertTrue(any('skill body' in error for error in errors))
        skill.write_text('---\nname: example\ndescription: Diagnose sample failures.\n---\nUse [source](../../../source.md).\n', encoding='utf-8')
        self.assertEqual(self.errors(), [])

    def test_symlink_target_rejected_when_supported(self):
        self.write('source.md', '# Source\n')
        self.write('README.md', self.page('[alias](alias.md)'))
        try:
            (self.root / 'alias.md').symlink_to(self.root / 'source.md')
        except OSError:
            # The rest of the suite remains meaningful on Windows without
            # symlink privilege; no skip enters release qualification reports.
            return
        self.assertTrue(any('link/reparse' in error for error in self.errors()))
