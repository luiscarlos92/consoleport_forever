"""Guard source capture: immutable pins and repository-only output, no live inputs."""
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import capture_pawn_immersion_experiment as capture
from repository_paths import ROOT


class PawnImmersionCaptureTests(unittest.TestCase):
    def setUp(self):
        (ROOT / 'scratch').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / 'scratch')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name) / 'inputs'
        self.manifest = Path(self.temp.name) / 'manifest.json'
        self.enter = self.enterContext
        self.enter(patch.object(capture, 'BASE', self.base))
        self.enter(patch.object(capture, 'MANIFEST', self.manifest))
        self.enter(patch.object(capture, 'GROUPS', [('Owner/Source', 'tag', 'Example', ['input.lua'])]))
        self.network = self.enter(patch.object(capture.urllib.request, 'urlopen', side_effect=lambda *a, **k: io.BytesIO(b'-- exact source\n')))
        self.enter(patch('builtins.print'))

    def test_capture_and_identical_reconstruction(self):
        capture.main()
        original = self.manifest.read_bytes()
        capture.main()
        self.assertEqual(self.manifest.read_bytes(), original)
        self.assertEqual((self.base / 'Example/input.lua').read_bytes(), b'-- exact source\n')

    def test_local_drift_refused_without_replacement(self):
        capture.main()
        source = self.base / 'Example/input.lua'
        source.write_bytes(b'local edit')
        with self.assertRaisesRegex(ValueError, 'Existing experiment copy drift'):
            capture.main()
        self.assertEqual(source.read_bytes(), b'local edit')

    def test_remote_drift_refused_without_repinning(self):
        capture.main()
        original = self.manifest.read_bytes()
        self.network.side_effect = lambda *a, **k: io.BytesIO(b'changed upstream')
        with self.assertRaisesRegex(ValueError, 'Pinned experiment input changed'):
            capture.main()
        self.assertEqual(self.manifest.read_bytes(), original)

    def test_immutable_or_outside_output_refused_before_network(self):
        for target in [ROOT / 'reference/new-experiment', ROOT.parent / 'outside-experiment']:
            with self.subTest(target=target), patch.object(capture, 'BASE', target):
                with self.assertRaises(ValueError):
                    capture.main()
        self.network.assert_not_called()


if __name__ == '__main__':
    unittest.main()
