from pathlib import Path
import io
import sys
import tempfile
import unittest
from unittest.mock import patch, Mock
import zipfile

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT, output, immutable_hashes
from pack_format import digest
from verify_pinned_sources import verify_download, retain_verified_inputs


class PinnedInputs(unittest.TestCase):
    def setUp(self):
        output(ROOT/'scratch').mkdir(exist_ok=True)
        self.temp=tempfile.TemporaryDirectory(prefix='pinned-inputs-',dir=output(ROOT/'scratch'))
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve()
        self.patch=patch('verify_pinned_sources.ROOT',self.root)
        self.patch.start()
        self.addCleanup(self.patch.stop)
        self.files={'Example/Example.toc':b'## Version: 1\nMain.lua\n','Example/Main.lua':b'local pinned=true\n'}
        self.data=self.archive(self.files)
        self.package={'repo':'official/Example','bytes':len(self.data),'sha256':digest(self.data),
            'cache':'dependencies/cache/Example.zip','unpacked':'dependencies/unpacked/Example/1',
            'files':{n:digest(b) for n,b in self.files.items()},'addonFolders':['Example'],'version':'1'}

    def archive(self,files):
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as z:
            for name,body in files.items(): z.writestr(name,body)
        return stream.getvalue()

    def snapshots(self):
        return {p.relative_to(self.root).as_posix():(p.read_bytes(),p.stat().st_mtime_ns) for p in self.root.rglob('*') if p.is_file()}

    def prepare(self):
        retain_verified_inputs(self.package,self.data,self.files)

    def test_fresh_clone_missing_inputs_reproduced_then_repaired(self):
        self.assertFalse((self.root/self.package['unpacked']).exists())
        with patch('verify_pinned_sources.fetch_official',return_value=self.data):
            self.assertEqual(verify_download(self.package)['status'],'passed')
        self.assertEqual((self.root/self.package['cache']).read_bytes(),self.data)
        self.assertEqual(immutable_hashes(self.root/self.package['unpacked']),self.package['files'])

    def test_existing_verified_inputs_are_never_rewritten(self):
        self.prepare()
        before=self.snapshots()
        self.prepare()
        self.assertEqual(before,self.snapshots())

    def test_missing_file_reconstructed_without_rewriting_others(self):
        self.prepare()
        target=self.root/self.package['unpacked']/'Example/Main.lua'
        target.unlink()
        before=self.snapshots()
        self.prepare()
        for name,row in before.items(): self.assertEqual(self.snapshots()[name],row)
        self.assertEqual(target.read_bytes(),self.files['Example/Main.lua'])

    def test_cache_drift_file_drift_and_foreign_files_preserved(self):
        self.prepare()
        for target in [self.root/self.package['cache'],self.root/self.package['unpacked']/'Example/Main.lua',self.root/self.package['unpacked']/'manual.txt']:
            original=target.read_bytes() if target.exists() else None
            target.write_bytes(b'manual drift')
            before=self.snapshots()
            with self.assertRaisesRegex(ValueError,'drift'): self.prepare()
            self.assertEqual(self.snapshots(),before)
            if original is None: target.unlink()
            else: target.write_bytes(original)

    def test_unverified_bytes_or_members_do_not_write(self):
        for data,files in [(b'bad',self.files),(self.data,{}),(self.data,{**self.files,'Example/Main.lua':b'drift'})]:
            with self.assertRaisesRegex(ValueError,'fully verified'):
                retain_verified_inputs(self.package,data,files)
            self.assertEqual(self.snapshots(),{})

    def test_escaping_destinations_rejected_before_writes(self):
        for key,value in [('cache','reference/Example.zip'),('cache','../outside.zip'),('unpacked','tests/fixtures/input'),('unpacked','dependencies/cache/Example')]:
            package={**self.package,key:value}
            with self.assertRaises(ValueError): retain_verified_inputs(package,self.data,self.files)
            self.assertEqual(self.snapshots(),{})
        files={'../foreign.lua':b'escape'}
        package={**self.package,'files':{n:digest(b) for n,b in files.items()}}
        with self.assertRaises(ValueError): retain_verified_inputs(package,self.data,files)
        self.assertEqual(self.snapshots(),{})

    def test_tagged_source_archive_normalizes_verified_root(self):
        data=self.archive({'official-prefix/'+name.split('/',1)[1]:body for name,body in self.files.items()})
        package={**self.package,'sourceCommit':'a'*40,'bytes':len(data),'sha256':digest(data)}
        with patch('verify_pinned_sources.fetch_official',return_value=data):
            self.assertEqual(verify_download(package)['status'],'passed')
        self.assertEqual(immutable_hashes(self.root/package['unpacked']),package['files'])
