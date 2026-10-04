import io
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1]/'tools'))
from repository_paths import ROOT, output
from pack_format import FORMAT, archive_bytes, digest, read_pack, zip_entries
from assemble_pack import assemble
from deployment_guard import GameTree, inventory, verify_backup
from install_pack import install, recover, restore


def make_pack(scope, version='candidate', complete=True, dependency=None, retired=False):
    rows = {'Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.toc':
                ('## Interface: 120100\n## Version: '+version+'\nMain.lua\n').encode(),
            'Interface/AddOns/ConsolePort_Forever/Main.lua': version.encode(),
            'Interface/AddOns/A/A.toc': b'## Interface: 120100\nMain.lua\n',
            'Interface/AddOns/A/Main.lua': version.encode()}
    manifest = {'format': FORMAT, 'formatVersion': 1, 'sourceCommit': 'a'*40,
        'localPersonalUseOnly': True, 'redistributionApproved': False,
        'assemblyComplete': complete, 'addonFolders': ['A', 'ConsolePort_Forever'],
        'requiredAddonFolders': ['A', 'ConsolePort_Forever'], 'dependencyLockSHA256': 'b'*64,
        'compatibility': {'storeSchema': 3, 'configurationRevision': 11,
            'dependencyVersions': {'ConsolePort': '3.3.5'}},
        'runtimeClosure': {'A': {'toc': 'A/A.toc', 'runtimeFiles': ['A/A.toc', 'A/Main.lua']},
            'ConsolePort_Forever': {'toc': 'ConsolePort_Forever/ConsolePort_Forever.toc',
                'runtimeFiles': ['ConsolePort_Forever/ConsolePort_Forever.toc', 'ConsolePort_Forever/Main.lua']}}}
    if not complete:
        rows = {n: b for n, b in rows.items() if '/A/' not in n}
        rows['dependencies/official-sources.json'] = json.dumps({'packages': [dependency]}).encode()
        manifest['addonFolders'] = ['ConsolePort_Forever']
    if retired:
        manifest['retiredAddonFolders'] = {'Retired': {'owner': 'official/A', 'reason': 'No Retail interface in current native package'}}
    manifest['files'] = {n: digest(b) for n, b in rows.items()}
    path = output(scope/('pack-'+version+'.zip'))
    data = archive_bytes(rows, manifest)
    path.write_bytes(data)
    return path, digest(data)


def game(scope):
    root = output(scope/'_retail_')
    (root/'Interface/AddOns/A').mkdir(parents=True)
    (root/'Interface/AddOns/ConsolePort_Forever').mkdir()
    (root/'Interface/AddOns/Unrelated/empty').mkdir(parents=True)
    (root/'Interface/AddOns/A/obsolete.lua').write_bytes(b'old code removed upstream')
    (root/'Interface/AddOns/ConsolePort_Forever/Main.lua').write_bytes(b'old companion')
    (root/'Interface/AddOns/Unrelated/manual.lua').write_bytes(b'unrelated unchanged')
    (root/'WTF/Account/_template_/SavedVariables').mkdir(parents=True)
    (root/'WTF/Config.wtf').write_bytes(b'current cvars')
    (root/'WTF/Account/_template_/bindings-cache.wtf').write_bytes(b'current shared bindings')
    (root/'WTF/Account/_template_/SavedVariables/Example.lua.bak').write_bytes(b'fallback saved variables')
    return root


def junction(alias, target):
    output(alias)
    output(target)
    if os.name == 'nt':
        script = "New-Item -ItemType Junction -Path '"+str(alias).replace("'", "''")+"' -Value '"+str(target).replace("'", "''")+"' | Out-Null"
        subprocess.run(['powershell', '-NoProfile', '-Command', script], check=True, capture_output=True,
            creationflags=subprocess.CREATE_NO_WINDOW)
    else:
        alias.symlink_to(target, target_is_directory=True)


class PackDelivery(unittest.TestCase):
    def scope(self):
        output(ROOT/'scratch').mkdir(exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=ROOT/'scratch')
        scope = output(Path(temporary.name), ROOT/'scratch')
        self.addCleanup(temporary.cleanup)
        return scope

    def test_archive_digest_paths_and_missing_files(self):
        scope = self.scope()
        path, checksum = make_pack(scope)
        manifest, rows = read_pack(path, checksum, True)
        self.assertEqual(len(manifest['addonFolders']), 2)
        with self.assertRaises(ValueError): read_pack(path, '0'*64, True)
        changed = dict(rows); changed['Interface/AddOns/A/Main.lua'] = b'drift'
        other = scope/'changed.zip'; other.write_bytes(archive_bytes(changed, manifest))
        with self.assertRaises(ValueError): read_pack(other, digest(other.read_bytes()), True)
        for name, mode in [('../escape', 0), ('C:/escape', 0), ('A/NUL.lua', 0), ('A/link', stat.S_IFLNK << 16)]:
            stream = io.BytesIO()
            with zipfile.ZipFile(stream, 'w') as archive:
                info = zipfile.ZipInfo(name); info.external_attr = mode
                archive.writestr(info, 'bad')
            with self.assertRaises(ValueError): zip_entries(stream.getvalue())

    def test_official_assembly_and_unchanged_bytes(self):
        scope = self.scope()
        files = {'A/A.toc': b'## Interface: 120100\nMain.lua\n', 'A/Main.lua': b'official unmodified'}
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, 'w') as archive:
            for n, b in files.items(): archive.writestr(n, b)
        data = stream.getvalue()
        dependency = {'repo': 'official/A', 'version': '1', 'bytes': len(data), 'sha256': digest(data),
            'assetURL': 'https://github.com/official/A/releases/download/1/A.zip',
            'selectedFolders': ['A'], 'selectedFiles': {n: digest(b) for n, b in files.items()}}
        recipe, checksum = make_pack(scope, 'recipe', False, dependency)
        with self.assertRaises(ValueError): read_pack(recipe, checksum, True)
        with self.assertRaises(ValueError): assemble(recipe, checksum, scope/'truncated.zip', lambda _: data[:-1])
        receipt = assemble(recipe, checksum, scope/'assembled.zip', lambda _: data)
        _, rows = read_pack(scope/'assembled.zip', receipt['sha256'], True)
        self.assertEqual(rows['Interface/AddOns/A/Main.lua'], files['A/Main.lua'])
        with self.assertRaises(ValueError): assemble(recipe, checksum, scope/'assembled.zip', lambda _: data)
        retail = game(scope)
        with self.assertRaises(ValueError): assemble(recipe, checksum, retail/'output.zip', lambda _: data)

    def test_preview_backup_links_and_owned_folder_replacement(self):
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        junction(root/'WTF/Account/Character', root/'WTF/Account/_template_')
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        before = inventory(tree.addons); config = inventory(tree.wtf, True)
        proposal = install(tree, pack, checksum)
        self.assertFalse(proposal['execute'])
        self.assertFalse((root/'CPFBackups').exists())
        receipt = install(tree, pack, checksum, execute=True)
        self.assertEqual(receipt['status'], 'installed')
        self.assertFalse((tree.addons/'A/obsolete.lua').exists())
        self.assertEqual((tree.addons/'Unrelated/manual.lua').read_bytes(), b'unrelated unchanged')
        self.assertTrue((tree.addons/'Unrelated/empty').is_dir())
        self.assertEqual(inventory(tree.wtf, True), config)
        backup = Path(receipt['backup'])
        snapshot = json.loads((backup/'snapshot.json').read_text(encoding='utf-8'))
        self.assertEqual(snapshot['addons'], before)
        self.assertEqual(snapshot['wtf'], config)
        self.assertFalse((backup/'WTF/Account/Character').exists(), 'backup recreated a link to current game data')
        verify_backup(backup, snapshot)
        with self.assertRaises(ValueError): restore(tree, backup, execute=True)
        with self.assertRaises(ValueError): restore(tree, backup, execute=True, restore_config=True)

    def test_alias_running_game_and_backup_drift_refusal(self):
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        with self.assertRaises(ValueError): GameTree(root, simulation=True, process_check=lambda: True)
        alias = scope/'_retail_alias_'; junction(alias, root)
        with self.assertRaises(ValueError): GameTree(alias, simulation=True, process_check=lambda: False)
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        before = inventory(tree.addons)
        def drift(event):
            if event == 'before-promotion':
                backup = next((root/'CPFBackups').iterdir())
                (backup/'AddOns/A/obsolete.lua').write_bytes(b'drifted backup')
        with self.assertRaises(RuntimeError): install(tree, pack, checksum, execute=True, fault=drift)
        self.assertEqual(inventory(tree.addons), before)
        self.assertEqual(json.loads(next((root/'CPFBackups').glob('*/install-receipt.json')).read_text())['status'], 'failed-before-promotion')

    def test_copy_failure_promotion_failure_and_recovery(self):
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        before = inventory(tree.addons); config = inventory(tree.wtf, True)
        def copy_failure(event):
            if event.startswith('copy:'): raise IOError('injected copy failure')
        with self.assertRaises(RuntimeError): install(tree, pack, checksum, execute=True, fault=copy_failure)
        self.assertEqual(inventory(tree.addons), before)
        def promotion_failure(event):
            if event == 'promote:ConsolePort_Forever': raise IOError('injected mid-promotion failure')
        with self.assertRaises(RuntimeError): install(tree, pack, checksum, execute=True, fault=promotion_failure)
        self.assertEqual(inventory(tree.addons), before)
        self.assertEqual(inventory(tree.wtf, True), config)
        def rollback_failure(event):
            if event in {'promote:ConsolePort_Forever', 'rollback:A'}: raise IOError('injected rollback failure')
        with self.assertRaises(RuntimeError): install(tree, pack, checksum, execute=True, fault=rollback_failure)
        receipts = [json.loads(p.read_text()) for p in (root/'CPFBackups').glob('*/install-receipt.json')]
        pending = next(r for r in receipts if r['status'] == 'recovery-required')
        self.assertEqual(recover(tree, pending['backup'], execute=True)['status'], 'rolled-back')
        self.assertEqual(inventory(tree.addons), before)
        self.assertEqual(len(list((root/'CPFBackups').iterdir())), 3, 'old backups were pruned')

    def test_code_only_and_explicit_disaster_restore(self):
        scope = self.scope(); root = game(scope); first, first_sha = make_pack(scope, 'first')
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        original = inventory(tree.addons); original_config = inventory(tree.wtf, True)
        installed = install(tree, first, first_sha, execute=True)
        (tree.wtf/'Config.wtf').write_bytes(b'user play after install')
        (tree.wtf/'new-config.lua').write_bytes(b'new native saved configuration')
        second, second_sha = make_pack(scope, 'second')
        updated = install(tree, second, second_sha, execute=True)
        played = inventory(tree.wtf, True)
        result = restore(tree, updated['backup'], execute=True)
        self.assertEqual(result['status'], 'restored')
        self.assertEqual((tree.addons/'ConsolePort_Forever/Main.lua').read_bytes(), b'first')
        self.assertEqual(inventory(tree.wtf, True), played, 'code-only restore overwrote later saved data')
        result = restore(tree, installed['backup'], execute=True, restore_config=True, accept_config_loss=True)
        self.assertEqual(result['status'], 'restored')
        self.assertEqual(inventory(tree.addons), original)
        self.assertEqual(inventory(tree.wtf, True), original_config)
        current_backup = Path(result['backup'])
        self.assertEqual((current_backup/'WTF/Config.wtf').read_bytes(), b'user play after install')
        self.assertEqual((current_backup/'WTF/new-config.lua').read_bytes(), b'new native saved configuration')

    def test_restore_failures_compensate_and_preserve_newer_edits(self):
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        installed = install(tree, pack, checksum, execute=True)
        (tree.wtf/'Config.wtf').write_bytes(b'later play')
        current = inventory(tree.addons); config = inventory(tree.wtf, True)
        def failure(event):
            if event == 'config:Config.wtf': raise IOError('injected configuration restore failure')
        with self.assertRaises(RuntimeError): restore(tree, installed['backup'], True, True, True, failure)
        self.assertEqual(inventory(tree.addons), current)
        self.assertEqual(inventory(tree.wtf, True), config)
        (tree.addons/'A/Main.lua').write_bytes(b'newer code edit')
        with self.assertRaises(ValueError): restore(tree, installed['backup'], True, True, True)
        self.assertEqual((tree.addons/'A/Main.lua').read_bytes(), b'newer code edit')

    def test_stage_current_and_anchor_drift_are_not_promoted(self):
        for kind in ['stage', 'current', 'anchor', 'running']:
            with self.subTest(kind=kind):
                scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
                running = [False]
                tree = GameTree(root, simulation=True, process_check=lambda: running[0])
                old = (root/'Interface/AddOns/A/obsolete.lua').read_bytes()
                other = scope/'other'; other.mkdir(); (other/'AddOns').mkdir()
                def drift(event):
                    if event != 'before-promotion': return
                    if kind == 'stage':
                        next((root/'Interface').glob('.cpf-stage-*/new/A/Main.lua')).write_bytes(b'staged drift')
                    elif kind == 'current':
                        (tree.addons/'Unrelated/manual.lua').write_bytes(b'newer unrelated edit')
                    elif kind == 'running':
                        running[0] = True
                    else:
                        saved = output(root/'Interface.saved')
                        output(root/'Interface')
                        (root/'Interface').rename(saved)
                        junction(root/'Interface', other)
                with self.assertRaises((RuntimeError, ValueError)): install(tree, pack, checksum, execute=True, fault=drift)
                if kind == 'anchor':
                    self.assertEqual(list((other/'AddOns').iterdir()), [])
                    self.assertEqual((root/'Interface.saved/AddOns/A/obsolete.lua').read_bytes(), old)
                else:
                    self.assertEqual((tree.addons/'A/obsolete.lua').read_bytes(), old)
                if kind == 'current':
                    self.assertEqual((tree.addons/'Unrelated/manual.lua').read_bytes(), b'newer unrelated edit')

    def test_script_entry_points_default_to_read_only(self):
        if os.name != 'nt': self.skipTest('Windows PowerShell delivery wrappers')
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        before = inventory(root/'Interface/AddOns')
        command = ['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', str(ROOT/'tools/Install-Pack.ps1'),
            '-RetailRoot', str(root), '-Pack', str(pack), '-ExpectedSHA256', checksum, '-Simulation']
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        self.assertIn('"execute": false', result.stdout)
        self.assertEqual(inventory(root/'Interface/AddOns'), before)
        self.assertFalse((root/'CPFBackups').exists())
        wrong = command.copy(); wrong[wrong.index(checksum)] = '0'*64
        self.assertNotEqual(subprocess.run(wrong, cwd=ROOT, capture_output=True).returncode, 0)

    def test_real_anchor_branch_only_on_guarded_fake_root_with_42_links(self):
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        # Exercise real anchor resolution on an explicitly guarded disposable
        # copy. No installed executable, live path or CLI real-mode call occurs.
        output(root, ROOT/'scratch')
        (root/'WoW.exe').write_bytes(b'fake executable identity, never launched')
        for name in ['Interface', 'WTF']:
            target = output(scope/('canonical-'+name), ROOT/'scratch')
            output(root/name, ROOT/'scratch').rename(target)
            junction(root/name, target)
        tree = GameTree(root, user_install=True, process_check=lambda: False)
        for index in range(42):
            junction(tree.wtf/'Account'/('Character-'+str(index)), tree.wtf/'Account/_template_')
        (tree.addons/'A/A.toc').write_bytes(b'## Version: old-native\n## Interface: 120100\n')
        config = inventory(tree.wtf, True); anchors = tree.identity
        installed = install(tree, pack, checksum, execute=True)
        snapshot = json.loads((Path(installed['backup'])/'snapshot.json').read_text())
        self.assertEqual(len(snapshot['wtf']['links']), 42)
        self.assertEqual(snapshot['priorAddonMetadata']['A/A.toc']['metadata']['Version'], 'old-native')
        self.assertEqual(inventory(tree.wtf, True), config)
        restore(tree, installed['backup'], True, True, True)
        self.assertEqual(tree.identity, anchors)
        self.assertEqual(inventory(tree.wtf, True), config)

    def test_abrupt_exit_after_rename_recovers_from_durable_intent(self):
        import install_pack
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope)
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        before = inventory(tree.addons); original_move = install_pack.move
        def interrupted(*args):
            original_move(*args)
            if args[1] == tree.addons/'A':
                raise KeyboardInterrupt('simulated abrupt exit after original rename')
        with patch.object(install_pack, 'move', interrupted):
            with self.assertRaises(KeyboardInterrupt): install(tree, pack, checksum, execute=True)
        backup = next((root/'CPFBackups').iterdir())
        self.assertEqual(json.loads((backup/'install-receipt.json').read_text())['status'], 'applying')
        self.assertEqual(recover(tree, backup, True)['status'], 'rolled-back')
        self.assertEqual(inventory(tree.addons), before)

    def test_explicit_package_retirement_is_parked_and_reversible(self):
        scope = self.scope(); root = game(scope); pack, checksum = make_pack(scope, retired=True)
        tree = GameTree(root, simulation=True, process_check=lambda: False)
        (tree.addons/'Retired').mkdir()
        (tree.addons/'Retired/old.lua').write_bytes(b'old incompatible package folder')
        before = inventory(tree.addons)
        preview = install(tree, pack, checksum)
        self.assertIn('Retired', preview['retiredAddonFolders'])
        def failure(event):
            if event == 'promote:Retired': raise IOError('interrupted retirement')
        with self.assertRaises(RuntimeError): install(tree, pack, checksum, execute=True, fault=failure)
        self.assertEqual(inventory(tree.addons), before)
        installed = install(tree, pack, checksum, execute=True)
        self.assertFalse((tree.addons/'Retired').exists())
        self.assertEqual((Path(installed['stage'])/'previous/Retired/old.lua').read_bytes(), b'old incompatible package folder')
        restore(tree, installed['backup'], True, True, True)
        self.assertEqual(inventory(tree.addons), before)


if __name__ == '__main__':
    unittest.main()
