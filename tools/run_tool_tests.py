"""Run tooling tests with a machine-readable, exact-source result receipt."""
from datetime import datetime, timezone
import json
import platform
import subprocess
import sys
import unittest
from repository_paths import ROOT, output, sha


class RecordedResult(unittest.TextTestResult):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.rows = []

    def addSuccess(self, test):
        super().addSuccess(test)
        self.rows.append({'id': test.id(), 'status': 'passed'})

    def addFailure(self, test, error):
        super().addFailure(test, error)
        self.rows.append({'id': test.id(), 'status': 'failed'})

    def addError(self, test, error):
        super().addError(test, error)
        self.rows.append({'id': test.id(), 'status': 'error'})

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self.rows.append({'id': test.id(), 'status': 'skipped', 'reason': reason})


if __name__ == '__main__':
    suite = unittest.defaultTestLoader.discover(str(ROOT/'tests'), pattern='test_*.py')
    result = unittest.TextTestRunner(resultclass=RecordedResult).run(suite)
    sources = {p.relative_to(ROOT).as_posix(): sha(p)
        for base in ['tools', 'tests'] for p in (ROOT/base).rglob('*')
        if p.is_file() and '__pycache__' not in p.parts}
    report = {'at': datetime.now(timezone.utc).isoformat(), 'python': platform.python_version(),
        'overallPassed': result.wasSuccessful(), 'testsRun': result.testsRun,
        'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
        'sourceHashes': sources, 'pinnedDependencyLockSHA256': sha(ROOT/'dependencies/lock.json'),
        'results': result.rows, 'limitation': 'Only guarded repository scratch simulations; no actual game installation or Retail client execution.'}
    destination = output(ROOT/'scratch/test-results/tooling-latest.json')
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
    sys.exit(0 if result.wasSuccessful() else 1)
