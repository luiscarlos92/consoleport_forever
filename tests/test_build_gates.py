from pathlib import Path
import re
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from build_pack import validate_runtime_results


class RuntimeBuildGateTests(unittest.TestCase):
    def setUp(self):
        self.source = (Path(__file__).resolve().parents[1]/'tools/test-all.cjs').read_text(encoding='utf-8')
        ids = re.findall(r"check\('([^']+)',", self.source)
        ids.extend('baseline.'+name for name in ('installer', 'runtime', 'skin'))
        self.results = [{'id': name, 'status': 'passed'} for name in ids]

    def test_full_current_suite_qualifies(self):
        validate_runtime_results(self.results, self.source)

    def test_targeting_and_combat_suites_cannot_be_omitted(self):
        for prefix in ('T12.', 'T41.', 'T42.', 'T54.', 'T55.', 'T56.'):
            with self.subTest(prefix=prefix), self.assertRaisesRegex(ValueError, 'Complete runtime'):
                validate_runtime_results([row for row in self.results if not row['id'].startswith(prefix)], self.source)

    def test_duplicate_or_failed_results_cannot_qualify(self):
        with self.assertRaisesRegex(ValueError, 'Complete runtime'):
            validate_runtime_results(self.results+[self.results[0]], self.source)
        self.results[0]['status'] = 'failed'
        with self.assertRaisesRegex(ValueError, 'not passed'):
            validate_runtime_results(self.results, self.source)
