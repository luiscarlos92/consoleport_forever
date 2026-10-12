"""Explicit running-game exception stays confined to a known Forever update."""
import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT,sha
from deployment_guard import GameTree,inventory
from deploy_update import deploy
from deploy_companion import deploy as companion
from install_pack import install,recover,restore
from pack_format import archive_bytes,digest,read_pack
from test_pack import game,make_pack


class RunningCompanion(unittest.TestCase):
    def setup_case(self):
        temporary=tempfile.TemporaryDirectory(dir=ROOT/'scratch');self.addCleanup(temporary.cleanup)
        scope=Path(temporary.name);root=game(scope)
        (root/'Interface/AddOns/ConsolePort').mkdir()
        (root/'Interface/AddOns/ConsolePort/ConsolePort.toc').write_text('## Version: 3.3.10\n')
        tree=GameTree(root,simulation=True,process_check=lambda:True,allow_running_companion=True)
        (tree.addons/'ConsolePort_Forever/Store.lua').write_text('local Core, Store = Addon.Core, {VERSION = 3}\n')
        marker=tree.addons.parent/'.cpf-companion-installed.json'
        prior={'status':'installed','addonFolders':['ConsolePort_Forever'],'installedFiles':inventory(tree.addons/'ConsolePort_Forever')['files'],
            'sourceCommit':'a'*40,'packSHA256':'b'*64}
        marker.write_text(json.dumps(prior))
        old,checksum=make_pack(scope,'hot-update');manifest,rows=read_pack(old,checksum,True)
        rows={name:body for name,body in rows.items() if name.startswith('Interface/AddOns/ConsolePort_Forever/')}
        rows['Interface/AddOns/ConsolePort_Forever/Store.lua']=b'local Core, Store = Addon.Core, {VERSION = 3}\n'
        manifest.update(deploymentScope='companion-and-updated-dependencies',dependencyUpdates={},retiredAddonFolders={},
            addonFolders=['ConsolePort_Forever'],requiredAddonFolders=['ConsolePort_Forever'],
            runtimeClosure={'ConsolePort_Forever':manifest['runtimeClosure']['ConsolePort_Forever']})
        return scope,tree,marker,manifest,rows

    def pack(self,scope,manifest,rows):
        manifest['files']={name:digest(body) for name,body in rows.items()}
        target=scope/'hot.zip';target.write_bytes(archive_bytes(rows,manifest));return target,sha(target)

    def test_default_running_game_gate_and_explicit_user_authority(self):
        scope,tree,*_=self.setup_case()
        with self.assertRaisesRegex(ValueError,'WoW is running'): GameTree(tree.root,simulation=True,process_check=lambda:True)
        with self.assertRaisesRegex(ValueError,'explicit user installation'): GameTree(tree.root,allow_running_companion=True)

    def test_preview_is_read_only_and_exact_scoped_install_preserves_everything_else(self):
        scope,tree,marker,manifest,rows=self.setup_case();pack,checksum=self.pack(scope,manifest,rows)
        wtf=inventory(tree.wtf,True);before=inventory(tree.addons)
        preview=deploy(tree,pack,checksum,scope/'backups')
        self.assertTrue(preview['allowRunningCompanion'] and preview['gameRunningAtPreview'] and preview['reloadRequired'])
        self.assertFalse(preview['currentConfigurationWrites'] or preview['vendorWrites'])
        self.assertFalse((scope/'backups').exists());self.assertEqual(inventory(tree.addons),before)
        result=deploy(tree,pack,checksum,scope/'backups',True)
        self.assertEqual(result['status'],'installed');self.assertEqual(inventory(tree.wtf,True),wtf)
        for name,row in before['files'].items():
            if not name.startswith('ConsolePort_Forever/'): self.assertEqual(sha(tree.addons/name),row['sha256'])
        self.assertEqual(inventory(Path(result['backup'])/'ConsolePort_Forever')['files'],
            {name.split('/',1)[1]:row for name,row in before['files'].items() if name.startswith('ConsolePort_Forever/')})

    def test_unknown_prior_receipt_and_manually_changed_code_are_refused(self):
        for kind in ['missing','status','inventory','source','artifact','manual']:
            with self.subTest(kind=kind):
                scope,tree,marker,manifest,rows=self.setup_case();pack,checksum=self.pack(scope,manifest,rows)
                if kind=='missing': marker.unlink()
                elif kind=='manual': (tree.addons/'ConsolePort_Forever/Main.lua').write_bytes(b'user edit')
                else:
                    prior=json.loads(marker.read_text());key={'status':'status','inventory':'installedFiles','source':'sourceCommit','artifact':'packSHA256'}[kind]
                    prior[key]={} if kind=='inventory' else 'invalid';marker.write_text(json.dumps(prior))
                before=inventory(tree.addons)
                with self.assertRaises((ValueError,FileNotFoundError)): deploy(tree,pack,checksum,scope/'backups',True)
                self.assertFalse((scope/'backups').exists());self.assertEqual(inventory(tree.addons),before)

    def test_schema_change_unknown_source_and_declared_schema_mismatch_are_refused(self):
        for kind in ['change','unknown','declaration']:
            with self.subTest(kind=kind):
                scope,tree,marker,manifest,rows=self.setup_case()
                if kind=='declaration': manifest['compatibility']['storeSchema']=4
                else: rows['Interface/AddOns/ConsolePort_Forever/Store.lua']=b'local Core, Store = Addon.Core, {VERSION = 4}' if kind=='change' else b'unknown'
                pack,checksum=self.pack(scope,manifest,rows)
                with self.assertRaisesRegex(ValueError,'StoreSchema|store compatibility'): deploy(tree,pack,checksum,scope/'backups',True)
                self.assertFalse((scope/'backups').exists())

    def test_full_install_recovery_restore_and_vendor_payload_cannot_use_exception(self):
        scope,tree,marker,manifest,rows=self.setup_case();pack,checksum=make_pack(scope,'full')
        for call in [lambda:install(tree,pack,checksum,scope/'backups',True),lambda:recover(tree,scope/'absent',True),
                lambda:restore(tree,scope/'absent',True,True,True),lambda:companion(tree,pack,checksum,scope/'backups',True)]:
            with self.assertRaisesRegex(ValueError,'companion-only|companion-only payload'): call()
        self.assertFalse((scope/'backups').exists())

    def test_dependency_update_or_retirement_is_refused(self):
        for kind in ['dependency','retirement']:
            with self.subTest(kind=kind):
                scope,tree,marker,manifest,rows=self.setup_case()
                if kind=='retirement': manifest['retiredAddonFolders']={'Retired':{'owner':'official/Retired','reason':'scoped'}}
                else:
                    rows['Interface/AddOns/A/A.toc']=b'## Interface: 120100\nMain.lua\n';rows['Interface/AddOns/A/Main.lua']=b'new'
                    manifest['addonFolders']=manifest['requiredAddonFolders']=['A','ConsolePort_Forever']
                    manifest['runtimeClosure']['A']={'toc':'A/A.toc','runtimeFiles':['A/A.toc','A/Main.lua']}
                    manifest['compatibility']['dependencyVersions']['official/A']='new'
                    manifest['dependencyUpdates']={'official/A':{'version':'new','packageSHA256':'c'*64,'addonFolders':['A'],
                        'files':{name[len('Interface/AddOns/'):]:digest(body) for name,body in rows.items() if '/A/' in name}}}
                pack,checksum=self.pack(scope,manifest,rows)
                with self.assertRaisesRegex(ValueError,'companion-only'): deploy(tree,pack,checksum,scope/'backups',True)
                self.assertFalse((scope/'backups').exists())

    def test_live_wtf_drift_aborts_without_erasing_game_writes(self):
        for edge in ['before-promotion','after-promotion']:
            with self.subTest(edge=edge):
                scope,tree,marker,manifest,rows=self.setup_case();pack,checksum=self.pack(scope,manifest,rows)
                before=inventory(tree.addons);live=tree.wtf/'Config.wtf'
                def change(event):
                    if event==edge: live.write_bytes(b'new user play')
                with self.assertRaisesRegex(ValueError,'Live files changed|preservation failed'): deploy(tree,pack,checksum,scope/'backups',True,change)
                self.assertEqual(live.read_bytes(),b'new user play');self.assertEqual(inventory(tree.addons),before)

    def test_keyboard_interrupt_rolls_back_code_and_retains_verified_backup(self):
        scope,tree,marker,manifest,rows=self.setup_case();pack,checksum=self.pack(scope,manifest,rows)
        before=inventory(tree.addons);wtf=inventory(tree.wtf,True)
        def interrupt(event):
            if event=='after-promotion': raise KeyboardInterrupt('interrupted')
        with self.assertRaises(KeyboardInterrupt): deploy(tree,pack,checksum,scope/'backups',True,interrupt)
        self.assertEqual(inventory(tree.addons),before);self.assertEqual(inventory(tree.wtf,True),wtf)
        receipts=list((scope/'backups').glob('*/install-receipt.json'));self.assertEqual(len(receipts),1)
        self.assertEqual(json.loads(receipts[0].read_text())['status'],'rolled-back')

    def test_anchor_replacement_still_rejected_in_running_mode(self):
        scope,tree,marker,manifest,rows=self.setup_case()
        tree.identity['wtf']['inode']=-1
        with self.assertRaisesRegex(ValueError,'identity changed'): tree.check(force_process=True)


if __name__=='__main__': unittest.main()
