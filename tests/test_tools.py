import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from repository_paths import ROOT, contained, fixture_copy, sha
from resolve_dependencies import members


class ToolGuards(unittest.TestCase):
    def test_live_aliases_refused(self):
        for path in ['C:/Program Files (x86)/World of Warcraft/_retail_/WTF/test',
                     'C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/_retail_/Interface/test',
                     ROOT / 'reference/config/test']:
            with self.assertRaises(ValueError):
                contained(path, ROOT / 'scratch')

    def test_archive_attacks(self):
        for name in ['../test.lua', '/test.lua', 'C:/test.lua', 'CON.lua', 'folder/a.exe', 'folder./x.lua']:
            stream=io.BytesIO()
            with zipfile.ZipFile(stream,'w') as archive:
                archive.writestr(name,b'bad')
            with self.assertRaises(ValueError, msg=name):
                members(stream.getvalue())
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as archive:
            archive.writestr('foo/bar.lua',b'bad')
        # Windows ZipInfo normalizes backslashes while creating the fixture;
        # patch both raw directory names to model an actual hostile archive.
        with self.assertRaises(ValueError):
            members(stream.getvalue().replace(b'foo/bar.lua',b'foo\\bar.lua'))
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as archive:
            archive.writestr('Addon/one.lua',b'a')
            archive.writestr('addon/ONE.lua',b'b')
        with self.assertRaises(ValueError):
            members(stream.getvalue())

    def test_copy_fixture_without_writing_reference(self):
        source=ROOT/'reference/config/2026-10-03-initial/Account/_template_/SavedVariables'
        prior={p.name:sha(p) for p in source.iterdir() if p.is_file()}
        (ROOT/'scratch').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT/'scratch') as temp:
            target=fixture_copy(source,Path(temp)/'copy')
            (target/'ConsolePort_Forever.lua').write_text('simulation only')
        self.assertEqual(prior,{p.name:sha(p) for p in source.iterdir() if p.is_file()})


if __name__=='__main__':
    unittest.main()
