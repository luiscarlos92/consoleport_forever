import json
from datetime import datetime,timezone
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT,sha
from deployment_guard import GameTree,inventory
from pack_format import archive_bytes,digest,read_pack
from deploy_update import deploy
from build_update import update_payload,artifact_name
import check_stable_sources
from test_pack import game,make_pack


class ScopedUpdates(unittest.TestCase):
    def test_same_candidate_output_label_preserves_prior_artifact_names_and_rejects_paths(self):
        self.assertEqual(artifact_name('companion-only'),'ConsolePort-Forever-Update-companion-only.zip')
        self.assertEqual(artifact_name('companion-only','targeting-options'),'ConsolePort-Forever-Update-companion-only-targeting-options.zip')
        for label in ['', '../overwrite', 'C:/path', 'Upper', 'x'*49]:
            with self.assertRaises(ValueError): artifact_name('companion-only',label)

    def scope(self):
        temporary=tempfile.TemporaryDirectory(dir=ROOT/'scratch')
        self.addCleanup(temporary.cleanup)
        return Path(temporary.name)

    def tree(self,scope):
        root=game(scope)
        (root/'Interface/AddOns/ConsolePort').mkdir()
        (root/'Interface/AddOns/ConsolePort/ConsolePort.toc').write_text('## Version: 3.3.10\n')
        return GameTree(root,simulation=True,process_check=lambda:False)

    def pack(self,scope,new_folder=False):
        original,checksum=make_pack(scope,'updated')
        manifest,rows=read_pack(original,checksum,True)
        if new_folder:
            rows['Interface/AddOns/B/B.toc']=b'## Interface: 120100\nMain.lua\n'
            rows['Interface/AddOns/B/Main.lua']=b'new official companion folder'
            manifest['runtimeClosure']['B']={'toc':'B/B.toc','runtimeFiles':['B/B.toc','B/Main.lua']}
        folders=['A','B'] if new_folder else ['A']
        selected={n[len('Interface/AddOns/'):]:digest(b) for n,b in rows.items() if n.split('/')[2] in folders}
        manifest.update(deploymentScope='companion-and-updated-dependencies',
            dependencyUpdates={'official/A':{'version':'new','packageSHA256':'c'*64,'addonFolders':folders,'files':selected}})
        manifest['compatibility']['dependencyVersions']['official/A']='new'
        manifest['addonFolders']=manifest['requiredAddonFolders']=sorted(folders+['ConsolePort_Forever'])
        manifest['files']={n:digest(b) for n,b in rows.items()}
        target=scope/'update.zip';target.write_bytes(archive_bytes(rows,manifest))
        return target,sha(target)

    def test_update_replaces_only_selected_packages_and_backs_up_only_touched_folders(self):
        scope=self.scope();tree=self.tree(scope)
        before=inventory(tree.addons);wtf=inventory(tree.wtf,True)
        pack,checksum=self.pack(scope,True)
        preview=deploy(tree,pack,checksum,scope/'backups')
        self.assertEqual(preview['dependencyUpdates'],['official/A'])
        self.assertFalse((scope/'backups').exists())
        result=deploy(tree,pack,checksum,scope/'backups',True)
        self.assertEqual(result['status'],'installed')
        self.assertFalse((tree.addons/'A/obsolete.lua').exists())
        self.assertTrue((tree.addons/'B/Main.lua').exists())
        self.assertEqual(inventory(tree.wtf,True),wtf)
        for name,row in before['files'].items():
            if name.split('/')[0] not in {'A','ConsolePort_Forever'}:
                self.assertEqual(sha(tree.addons/name),row['sha256'])
        backup=Path(result['backup'])
        self.assertTrue((backup/'A/obsolete.lua').exists())
        self.assertFalse((backup/'ConsolePort').exists())
        self.assertFalse((backup/'Unrelated').exists())

    def test_interruption_rolls_back_every_promoted_folder_including_new_folders(self):
        for stop in ['ConsolePort_Forever','A','B']:
            with self.subTest(stop=stop):
                scope=self.scope();tree=self.tree(scope)
                before=inventory(tree.addons);wtf=inventory(tree.wtf,True)
                pack,checksum=self.pack(scope,True)
                def fail(event):
                    if event=='after-promotion:'+stop: raise KeyboardInterrupt('interrupted update')
                with self.assertRaises(KeyboardInterrupt): deploy(tree,pack,checksum,scope/'backups',True,fail)
                self.assertEqual(inventory(tree.addons),before)
                self.assertEqual(inventory(tree.wtf,True),wtf)

    def test_undeclared_or_mismatched_dependency_scope_is_refused_before_backup(self):
        scope=self.scope();tree=self.tree(scope)
        pack,checksum=self.pack(scope)
        manifest,rows=read_pack(pack,checksum,True)
        before=inventory(tree.addons)
        manifest['dependencyUpdates']['official/A']['files']['A/Main.lua']='d'*64
        bad=scope/'bad.zip';bad.write_bytes(archive_bytes(rows,manifest))
        with self.assertRaises(ValueError): deploy(tree,bad,sha(bad),scope/'backups',True)
        self.assertEqual(inventory(tree.addons),before)
        self.assertFalse((scope/'backups').exists())
        manifest['dependencyUpdates']={}
        bad.write_bytes(archive_bytes(rows,manifest))
        with self.assertRaises(ValueError): deploy(tree,bad,sha(bad),scope/'backups',True)

    def test_companion_payload_never_reads_unchanged_vendor_sources(self):
        lock={'packages':[{'repo':'official/A','unpacked':'does-not-exist','files':{},'version':'new','sha256':'c'*64}]}
        coverage={'selectedFolders':{'A':{'owner':'official/A','eligibleForRetail':True}}}
        rows,closures,updates=update_payload(lock,coverage)
        self.assertEqual(set(closures),{'ConsolePort_Forever'})
        self.assertFalse(updates)
        self.assertTrue(all(n.startswith('Interface/AddOns/ConsolePort_Forever/') for n in rows))
        scope=self.scope();folder=scope/'A';folder.mkdir()
        (folder/'A.toc').write_bytes(b'## Interface: 120100\n## Version: new\nMain.lua\n')
        (folder/'Main.lua').write_bytes(b'local official=true')
        (folder/'helper.lua').write_bytes(b'-- official unused helper retained')
        lock['packages'][0].update(unpacked=str(scope.relative_to(ROOT)),files={
            'A/'+p.name:sha(p) for p in folder.iterdir()})
        rows,closures,updates=update_payload(lock,coverage,['official/A'])
        self.assertIn('Interface/AddOns/A/helper.lua',rows)
        self.assertEqual(rows['Interface/AddOns/A/Main.lua'],b'local official=true')

    def test_discovery_detects_new_releases_and_same_version_curseforge_file_ids(self):
        scope=self.scope();(scope/'dependencies').mkdir();(scope/'evidence/dependencies').mkdir(parents=True)
        current=datetime.now(timezone.utc).isoformat()
        sources={'github':[{'repo':'official/A'}],'curseforge':[{'repo':'curseforge/B','latestURL':'https://official/list',
            'url':'https://official/file/2','version':'1','fileID':2,'metadataVerifiedAt':current,'supportsRetail':True}]}
        lock={'packages':[{'repo':'official/A','version':'1','assetURL':'https://official/a.zip','sha256':'c'*64,'bytes':10},
            {'repo':'curseforge/B','version':'1','fileID':1}]}
        (scope/'dependencies/sources.json').write_text(json.dumps(sources))
        (scope/'dependencies/lock.json').write_text(json.dumps(lock))
        def github(endpoint):
            if endpoint.endswith('/releases/latest'):
                return {'html_url':'https://official/release/2','tag_name':'2','id':2,'published_at':current,'draft':False,'prerelease':False}
            return [{'sha':'99e0c336444fd7105e1414c46f9d6a4e0cf99bc6'}]
        with patch.object(check_stable_sources,'ROOT',scope),patch.object(check_stable_sources,'github_api',github):
            result=check_stable_sources.check(allow_updates=True)
            self.assertEqual(result['updates'],['official/A','curseforge/B'])
            self.assertFalse(result['allCurrent'])
            with self.assertRaises(ValueError): check_stable_sources.check()


if __name__=='__main__': unittest.main()
