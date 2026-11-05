"""Explicit selected-addon contracts and authorized running-game preservation."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT
from deployment_guard import GameTree, inventory
from pack_format import FORMAT, STANDALONE_FOREVER_SCOPE, archive_bytes, digest, read_pack
from build_update import standalone_payload
from deploy_update import deploy

NAME='ForeverConfig_Extended'

class ForeverConfigPackage(unittest.TestCase):
    def scope(self):
        temp=tempfile.TemporaryDirectory(dir=ROOT/'scratch',prefix='forever-config-')
        self.addCleanup(temp.cleanup)
        return Path(temp.name)

    def tree(self,scope,running=False):
        root=scope/'_forever_'
        (root/'Interface/AddOns/Other').mkdir(parents=True)
        (root/'Interface/AddOns/Other/manual.lua').write_bytes(b'manual')
        (root/'WTF/Account').mkdir(parents=True)
        (root/'WTF/Account/current.lua').write_bytes(b'latest progress')
        (root/'Interface/.immersion-extended-installed.json').write_bytes(b'prior receipt')
        return GameTree(root,simulation=True,process_check=lambda:running,game='forever',allow_running_forever=running)

    def pack(self,scope,mutate=lambda m,r:None):
        rows,closures=standalone_payload(NAME)
        manifest={'format':FORMAT,'formatVersion':1,'sourceCommit':'a'*40,
            'deploymentScope':STANDALONE_FOREVER_SCOPE,'dependencyUpdates':{},
            'localPersonalUseOnly':True,'redistributionApproved':False,'assemblyComplete':True,
            'addonFolders':[NAME],'requiredAddonFolders':[NAME],'retiredAddonFolders':{},
            'compatibility':{'gameType':'camelot','interface':16001},'runtimeClosure':closures}
        mutate(manifest,rows)
        manifest['files']={n:digest(b) for n,b in rows.items()}
        target=scope/'config.zip'; target.write_bytes(archive_bytes(rows,manifest))
        return target,digest(target.read_bytes())

    def test_exact_selected_scope_and_saved_variable_contract(self):
        scope=self.scope();pack,checksum=self.pack(scope)
        manifest,rows=read_pack(pack,checksum,True)
        self.assertEqual(manifest['addonFolders'],[NAME])
        self.assertTrue(all(n.startswith('Interface/AddOns/'+NAME+'/') for n in rows))
        self.assertEqual(manifest['runtimeClosure'][NAME]['metadata']['SavedVariables'],'ForeverConfigExtendedDB')
        with self.assertRaisesRegex(ValueError,'Unqualified'):standalone_payload('BetterBags')

    def test_running_preview_and_install_preserve_data_and_prior_receipt(self):
        scope=self.scope();tree=self.tree(scope,True);pack,checksum=self.pack(scope)
        before=inventory(tree.root);wtf=inventory(tree.wtf);other=inventory(tree.addons/'Other')
        preview=deploy(tree,pack,checksum,scope/'backups')
        self.assertFalse(preview['execute']);self.assertEqual(inventory(tree.root),before)
        receipt=deploy(tree,pack,checksum,scope/'backups',True)
        self.assertEqual(receipt['status'],'installed')
        self.assertEqual(inventory(tree.wtf),wtf);self.assertEqual(inventory(tree.addons/'Other'),other)
        self.assertEqual(inventory(tree.addons/NAME),receipt['installedAddons'][NAME])
        self.assertEqual((tree.root/'Interface/.immersion-extended-installed.json').read_bytes(),b'prior receipt')
        self.assertTrue((tree.root/'Interface/.forever-config-extended-installed.json').is_file())

    def test_running_permission_cannot_enable_full_operations_or_retail(self):
        scope=self.scope();tree=self.tree(scope,True)
        with self.assertRaisesRegex(ValueError,'limited'):tree.closed_operation()
        with self.assertRaisesRegex(ValueError,'explicit Forever'):
            GameTree(tree.root,simulation=True,game='retail',allow_running_forever=True)
        with self.assertRaisesRegex(ValueError,'explicit Forever'):
            GameTree(tree.root,process_check=lambda:True,game='forever',allow_running_forever=True)

    def test_saved_variable_or_dependency_scope_tampering_rejected(self):
        scope=self.scope()
        def wrong_db(m,r):
            key='Interface/AddOns/'+NAME+'/'+NAME+'.toc'
            r[key]=r[key].replace(b'ForeverConfigExtendedDB',b'PlaterDB')
        pack,checksum=self.pack(scope,wrong_db)
        with self.assertRaisesRegex(ValueError,'loading contract'):read_pack(pack,checksum,True)
        pack,checksum=self.pack(scope,lambda m,r:m.update(dependencyUpdates={'Cidan/BetterBags':{}}))
        with self.assertRaisesRegex(ValueError,'standalone Forever scope'):read_pack(pack,checksum,True)

    def test_running_drift_rolls_back_code_and_keeps_newer_game_save(self):
        scope=self.scope();tree=self.tree(scope,True);pack,checksum=self.pack(scope)
        target=tree.wtf/'Account/current.lua'
        def drift(event):
            if event=='before-promotion':target.write_bytes(b'newer game save')
        with self.assertRaisesRegex(ValueError,'preservation failed'):
            deploy(tree,pack,checksum,scope/'backups',True,drift)
        self.assertEqual(target.read_bytes(),b'newer game save')
        self.assertFalse((tree.addons/NAME).exists())

    def test_interrupted_update_restores_previous_selected_addon(self):
        scope=self.scope();tree=self.tree(scope,True);pack,checksum=self.pack(scope)
        (tree.addons/NAME).mkdir();(tree.addons/NAME/'manual.lua').write_bytes(b'old local code')
        before=inventory(tree.addons)
        def fail(event):
            if event=='after-promotion':raise RuntimeError('injected')
        with self.assertRaisesRegex(RuntimeError,'injected'):
            deploy(tree,pack,checksum,scope/'backups',True,fail)
        self.assertEqual(inventory(tree.addons),before)

if __name__=='__main__':unittest.main()
