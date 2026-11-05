"""Standalone client/package admission, preservation, drift and failure recovery."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT
from deployment_guard import GameTree, inventory
from pack_format import FORMAT, STANDALONE_FOREVER_ADDON as NAME, STANDALONE_FOREVER_SCOPE as SCOPE
from pack_format import archive_bytes, digest, read_pack
from build_update import standalone_payload
from deploy_update import deploy
from test_pack import game, make_pack, junction


class StandaloneForever(unittest.TestCase):
    def scope(self):
        temporary = tempfile.TemporaryDirectory(dir=ROOT/'scratch', prefix='standalone-')
        self.addCleanup(temporary.cleanup)
        return Path(temporary.name)

    def tree(self, scope):
        root = scope/'_forever_'
        (root/'Interface/AddOns/Unrelated').mkdir(parents=True)
        (root/'Interface/AddOns/Unrelated/manual.lua').write_bytes(b'manual')
        (root/'WTF/Account/Current').mkdir(parents=True)
        (root/'WTF/Account/Current/progress.lua').write_bytes(b'progress and settings')
        return GameTree(root, simulation=True, process_check=lambda:False, game='forever')

    def pack(self, scope, mutate=lambda m,r:None):
        rows, closures = standalone_payload()
        manifest = {'format':FORMAT,'formatVersion':1,'sourceCommit':'a'*40,
            'deploymentScope':SCOPE,'dependencyUpdates':{},'localPersonalUseOnly':True,
            'redistributionApproved':False,'assemblyComplete':True,
            'addonFolders':[NAME],'requiredAddonFolders':[NAME],'retiredAddonFolders':{},
            'compatibility':{'gameType':'camelot','interface':16001},'runtimeClosure':closures}
        mutate(manifest,rows)
        manifest['files']={name:digest(body) for name,body in rows.items()}
        destination=scope/'standalone.zip'
        destination.write_bytes(archive_bytes(rows,manifest))
        return destination,digest(destination.read_bytes())

    def test_payload_only_contains_standalone_and_forever_loading_contract(self):
        rows, closures=standalone_payload()
        self.assertEqual(set(closures),{NAME})
        self.assertTrue(all(n.startswith('Interface/AddOns/'+NAME+'/') for n in rows))
        self.assertEqual(closures[NAME]['metadata']['Interface'],'16001')
        self.assertEqual(closures[NAME]['metadata']['AllowLoadGameType'],'camelot')
        self.assertNotIn('SavedVariables',closures[NAME]['metadata'])

    def test_preview_preserves_all_files_and_creates_no_backup(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope)
        before=inventory(tree.root)
        result=deploy(tree,pack,checksum,scope/'backups')
        self.assertFalse(result['execute']);self.assertEqual(result['addonFolders'],[NAME])
        self.assertEqual(inventory(tree.root),before);self.assertFalse((scope/'backups').exists())

    def test_first_install_preserves_wtf_other_addons_and_has_exact_readback(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope)
        other=inventory(tree.addons/'Unrelated');wtf=inventory(tree.wtf)
        result=deploy(tree,pack,checksum,scope/'backups',True)
        self.assertEqual(result['status'],'installed')
        self.assertEqual(inventory(tree.wtf),wtf);self.assertEqual(inventory(tree.addons/'Unrelated'),other)
        self.assertFalse((tree.addons/'ConsolePort').exists())
        self.assertFalse((tree.addons/'ConsolePort_Forever').exists())
        self.assertEqual(inventory(tree.addons/NAME),result['installedAddons'][NAME])
        self.assertEqual(inventory(Path(result['backup'])/'WTF'),wtf)

    def test_retail_and_forever_packages_cannot_cross_clients(self):
        scope=self.scope();forever=self.tree(scope);pack,checksum=self.pack(scope)
        retail=GameTree(game(scope),simulation=True,process_check=lambda:False)
        with self.assertRaisesRegex(ValueError,'explicit Forever'):deploy(retail,pack,checksum,scope/'backup')
        old,oldhash=make_pack(scope)
        with self.assertRaisesRegex(ValueError,'cannot target Forever'):deploy(forever,old,oldhash,scope/'backup')
        with self.assertRaisesRegex(ValueError,'_retail_'):GameTree(forever.root,simulation=True,process_check=lambda:False)
        with self.assertRaisesRegex(ValueError,'Unknown game profile'):GameTree(forever.root,game='unknown')
        self.assertFalse((scope/'backup').exists())

    def test_closed_game_required_without_companion_running_exception(self):
        scope=self.scope();tree=self.tree(scope)
        with self.assertRaisesRegex(ValueError,'WoW is running'):
            GameTree(tree.root,simulation=True,process_check=lambda:True,game='forever')
        with self.assertRaisesRegex(ValueError,'closed WoW'):
            GameTree(tree.root,simulation=True,process_check=lambda:True,game='forever',allow_running_companion=True)

    def test_replacement_failure_restores_manual_previous_version_and_keeps_backups(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope)
        (tree.addons/NAME).mkdir();(tree.addons/NAME/'manual.lua').write_bytes(b'my previous version')
        before=inventory(tree.addons);wtf=inventory(tree.wtf)
        def fault(event):
            if event=='after-promotion':raise RuntimeError('injected failure')
        with self.assertRaisesRegex(RuntimeError,'injected failure'):
            deploy(tree,pack,checksum,scope/'backups',True,fault)
        self.assertEqual(inventory(tree.addons),before);self.assertEqual(inventory(tree.wtf),wtf)
        receipts=list((scope/'backups').glob('*/install-receipt.json'))
        self.assertEqual(len(receipts),1)
        data=json.loads(receipts[0].read_text());self.assertEqual(data['status'],'rolled-back')
        self.assertEqual((Path(data['backup'])/NAME/'manual.lua').read_bytes(),b'my previous version')

    def test_first_install_interruption_parks_new_folder_without_deleting_other_data(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope);before=inventory(tree.addons)
        def fault(event):
            if event=='after-promotion:'+NAME:raise KeyboardInterrupt()
        with self.assertRaises(KeyboardInterrupt):deploy(tree,pack,checksum,scope/'backups',True,fault)
        self.assertEqual(inventory(tree.addons),before)
        self.assertTrue(list(tree.addons.parent.glob('.cpf-update-stage-*/failed/'+NAME+'/Core.lua')))

    def test_bad_checksum_and_unrelated_payloads_refused_before_backups(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope)
        with self.assertRaisesRegex(ValueError,'SHA-256'):deploy(tree,pack,'0'*64,scope/'backups',True)
        def extra(m,r):r['Interface/AddOns/ConsolePort_Forever/Injected.lua']=b'not allowed'
        bad,badhash=self.pack(scope,extra)
        with self.assertRaises(ValueError):deploy(tree,bad,badhash,scope/'backups',True)
        def saved(m,r):
            toc='Interface/AddOns/'+NAME+'/'+NAME+'.toc'
            r[toc]+=b'\n## SavedVariables: Unapproved\n'
        bad,badhash=self.pack(scope,saved)
        with self.assertRaisesRegex(ValueError,'loading contract'):deploy(tree,bad,badhash,scope/'backups',True)
        self.assertFalse((scope/'backups').exists())

    def test_target_alias_refused_before_backup(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope)
        outside=scope/'other';outside.mkdir();junction(tree.addons/NAME,outside)
        with self.assertRaises(ValueError):deploy(tree,pack,checksum,scope/'backups',True)
        self.assertFalse((scope/'backups').exists())

    def test_concurrent_wtf_change_is_preserved_when_code_promotion_rolls_back(self):
        scope=self.scope();tree=self.tree(scope);pack,checksum=self.pack(scope)
        progress=tree.wtf/'Account/Current/progress.lua'
        def fault(event):
            if event=='before-promotion':progress.write_bytes(b'new user progress')
        with self.assertRaisesRegex(ValueError,'preservation failed'):
            deploy(tree,pack,checksum,scope/'backups',True,fault)
        self.assertEqual(progress.read_bytes(),b'new user progress')
        self.assertFalse((tree.addons/NAME).exists())
