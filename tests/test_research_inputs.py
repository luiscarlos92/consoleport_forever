from pathlib import Path
import copy
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from pack_format import digest
from repository_paths import ROOT, output
from verify_pinned_sources import verify_research_source, fetch_research_bytes


class ResearchInputs(unittest.TestCase):
    def setUp(self):
        output(ROOT/'scratch').mkdir(exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(prefix='research-test-', dir=output(ROOT/'scratch'))
        self.addCleanup(self.temp.cleanup)
        self.cache = Path(self.temp.name)/'cache'
        self.body = b'local pinned_research_input=true\n'
        self.row = {'file': 'Retail-Test.lua', 'url': 'https://raw.githubusercontent.com/Gethe/wow-ui-source/'+'a'*40+'/Interface/AddOns/Blizzard_Test/Test.lua',
            'sha256': digest(self.body), 'bytes': len(self.body)}

    def test_verified_fetch_and_offline_cache_reuse(self):
        fetch = Mock(return_value=self.body)
        self.assertEqual(verify_research_source(self.row, self.cache, fetch)['status'], 'passed')
        fetch.assert_called_once_with(self.row['url'])
        fetch.reset_mock()
        verify_research_source(self.row, self.cache, fetch)
        fetch.assert_not_called()
        self.assertEqual((self.cache/self.row['file']).read_bytes(), self.body)

    def test_bad_downloads_never_create_input(self):
        for body in (b'bad', b'x'*len(self.body)):
            with self.assertRaisesRegex(ValueError, 'source drift'):
                verify_research_source(self.row, self.cache, lambda _: body)
            self.assertFalse(self.cache.exists())

    def test_drifted_cache_is_preserved_and_rejected(self):
        self.cache.mkdir()
        target = self.cache/self.row['file']
        target.write_bytes(b'manual drift')
        fetch = Mock(return_value=self.body)
        with self.assertRaisesRegex(ValueError, 'source drift'):
            verify_research_source(self.row, self.cache, fetch)
        fetch.assert_not_called()
        self.assertEqual(target.read_bytes(), b'manual drift')

    def test_invalid_identities_and_paths_rejected_before_fetch(self):
        cases = [('file', '../escape.lua'), ('file', 'C:/live.lua'), ('file', 'nested/source.lua'),
            ('url', self.row['url'].replace('a'*40, 'live')), ('url', self.row['url'].replace('Gethe', 'other')),
            ('url', self.row['url']+'?secret=value'), ('url', self.row['url'].replace('/Blizzard_Test/', '/../')),
            ('sha256', 'bad'), ('bytes', 0), ('bytes', True)]
        fetch = Mock(return_value=self.body)
        for key, value in cases:
            row = copy.deepcopy(self.row)
            row[key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                verify_research_source(row, self.cache, fetch)
        for cache in (ROOT/'evidence', ROOT/'reference', ROOT/'tests/fixtures', ROOT.parent/'outside'):
            with self.subTest(cache=cache), self.assertRaises(ValueError):
                verify_research_source(self.row, cache, fetch)
        fetch.assert_not_called()
        self.assertFalse(self.cache.exists())

    def test_network_failure_and_redirect_do_not_create_input(self):
        with self.assertRaisesRegex(OSError, 'offline'):
            verify_research_source(self.row, self.cache, Mock(side_effect=OSError('offline')))
        self.assertFalse(self.cache.exists())
        response = Mock()
        response.geturl.return_value = 'https://example.com/unpinned'
        context = Mock()
        context.__enter__ = Mock(return_value=response)
        context.__exit__ = Mock(return_value=False)
        with patch('verify_pinned_sources.urlopen', return_value=context), self.assertRaisesRegex(ValueError, 'redirected'):
            fetch_research_bytes(self.row['url'])
        response.read.assert_not_called()
