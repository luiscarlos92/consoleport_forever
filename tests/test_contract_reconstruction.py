from pathlib import Path
import copy
import json
import sys
import tempfile
import unittest
from unittest.mock import Mock,patch

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT,output
from pack_format import digest
import capture_integration_contracts as capture

class ContractReconstruction(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='contract-rebuild-',dir=output(ROOT/'scratch'))
        self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name).resolve()
        scope=patch.object(capture,'ROOT',self.root);scope.start();self.addCleanup(scope.stop)
        self.body=b'local immutable_source=true\n'
        self.relative='Sample/Main.lua'
        self.write('dependencies/unpacked/Sample/1/'+self.relative,self.body)
        self.package={'repo':'official/Sample','unpacked':'dependencies/unpacked/Sample/1',
            'sha256':'a'*64,'files':{self.relative:digest(self.body)}}
        self.write('dependencies/lock.json',{'packages':[self.package]})
        self.integration='evidence/current/manifest.json'
        self.write(self.integration,{'files':[{'repo':self.package['repo'],'packageSHA256':'a'*64,
            'path':self.relative,'sha256':digest(self.body)}]})
        self.native='evidence/research/source-manifest.json'
        self.row={'file':'evidence/research/Pinned.lua','sha256':digest(self.body),
            'source':'https://raw.githubusercontent.com/Gethe/wow-ui-source/'+'a'*40+'/Interface/AddOns/Blizzard_Test/Main.lua'}
        self.write(self.native,[self.row])
    def write(self,name,data):
        path=output(self.root/name);path.parent.mkdir(parents=True,exist_ok=True)
        path.write_bytes(data if isinstance(data,bytes) else json.dumps(data).encode())
    def test_exact_reconstruction_and_no_fetch_on_reuse(self):
        fetch=Mock(return_value=self.body)
        self.assertEqual(capture.restore_manifests([self.integration],[self.native],fetch),2)
        fetch.assert_called_once_with(self.row['source']);fetch.reset_mock()
        self.assertEqual(capture.restore_manifests([self.integration],[self.native],fetch),0)
        fetch.assert_not_called()
        self.assertEqual((self.root/'evidence/current/Sample/Main.lua').read_bytes(),self.body)
        self.assertEqual((self.root/self.row['file']).read_bytes(),self.body)
    def test_existing_drift_is_retained_without_fetch(self):
        self.write(self.row['file'],b'preserve manual difference')
        fetch=Mock()
        with self.assertRaisesRegex(ValueError,'Existing capture drift'):
            capture.restore_manifests([], [self.native],fetch)
        self.assertEqual((self.root/self.row['file']).read_bytes(),b'preserve manual difference')
        fetch.assert_not_called()
    def test_native_escape_unpinned_identity_and_bad_bytes_rejected(self):
        fetch=Mock(return_value=b'wrong source')
        for key,value in [('file','../outside.lua'),('file','evidence/Other.lua'),
            ('source',self.row['source'].replace('a'*40,'main')),('source',self.row['source']+'?query'),
            ('source',self.row['source'].replace('/Blizzard_Test/','/../')),('sha256','bad')]:
            row=copy.deepcopy(self.row);row[key]=value;self.write(self.native,[row])
            with self.subTest(key=key,value=value),self.assertRaises(ValueError):
                capture.restore_manifests([], [self.native],fetch)
        fetch.assert_not_called()
        self.write(self.native,[self.row])
        with self.assertRaisesRegex(ValueError,'hash mismatch'):
            capture.restore_manifests([], [self.native],fetch)
        self.assertFalse((self.root/self.row['file']).exists())
    def test_integration_lock_and_target_escape_rejected(self):
        metadata=json.loads((self.root/self.integration).read_text())
        for key,value in [('packageSHA256','b'*64),('sha256','b'*64),('path','../../escape.lua')]:
            changed=copy.deepcopy(metadata);changed['files'][0][key]=value;self.write(self.integration,changed)
            with self.subTest(key=key),self.assertRaises(ValueError):
                capture.restore_manifests([self.integration])
        self.assertFalse((self.root/'evidence/current/Sample/Main.lua').exists())
        self.write('scratch/not-manifest.json',metadata)
        with self.assertRaisesRegex(ValueError,'evidence metadata'):
            capture.restore_manifests(['scratch/not-manifest.json'])
