"""User-executed install/restore, with repository-only simulation mode.

No command launches WoW. Defaults are read-only. All backups and parked code
are retained; no recursive deletion is used for addon replacement.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import uuid
import os
import re
from deployment_guard import (GameTree, backup_current, copy_inventory, inventory,
                              verify_backup, write_json)
from pack_format import digest, file_hash, plain_path, read_pack, safe_relative


def now():
    return datetime.now(timezone.utc).isoformat()


def identity():
    return datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+uuid.uuid4().hex[:12]


def owned(snapshot, folders):
    return {name: row for name, row in snapshot['files'].items() if name.split('/')[0] in folders}


def folder_snapshot(snapshot, folder):
    prefix = folder+'/'
    return {'files': {n[len(prefix):]: r for n, r in snapshot['files'].items() if n.startswith(prefix)},
        'directories': sorted(n[len(prefix):] for n in snapshot['directories'] if n.startswith(prefix)), 'links': {}}


def replace_owned(before, replacement, folders):
    return {'files': {**{n: r for n, r in before['files'].items() if n.split('/')[0] not in folders},
                      **replacement['files']},
        'directories': sorted([n for n in before['directories'] if n.split('/')[0] not in folders]+replacement['directories']),
        'links': {}}


def prepare_backups(tree, path):
    path = Path(path).absolute()
    plain_path(path, path.parent)
    for anchor in [tree.addons, tree.wtf]:
        if path == anchor or path.is_relative_to(anchor) or anchor.is_relative_to(path):
            raise ValueError('Backup path overlaps current addon/configuration data')
    if tree.simulation:
        from repository_paths import ROOT, output
        output(path, ROOT/'scratch')
    tree.check(force_process=True)
    path.mkdir(parents=True, exist_ok=True)
    return path, lambda target: tree.guard(target, path)


def move(tree, source, destination, source_scope, destination_scope):
    source = tree.guard(source, source_scope)
    destination = tree.guard(destination, destination_scope)
    if destination.exists():
        raise ValueError('Refusing to overwrite retained staged data')
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Folder renames stay on the AddOns volume, including real Interface links.
    os.rename(source, destination)


def marker(tree):
    return tree.addons.parent/'.cpf-installed.json'


def read_prior_marker(tree, snapshot):
    path = marker(tree)
    if not path.exists():
        return None
    plain_path(path, tree.addons.parent)
    prior = json.loads(path.read_text(encoding='utf-8'))
    if prior.get('format') != 'CPF-installed-receipt-1':
        raise ValueError('Unknown prior installation marker')
    if owned(snapshot, prior['addonFolders']) != prior['installedFiles']:
        raise ValueError('Prior installed marker no longer matches addon files')
    return prior


def stage_rows(tree, stage, rows):
    new = tree.guard(stage/'new', stage)
    new.mkdir()
    for name, body in rows.items():
        prefix = 'Interface/AddOns/'
        if not name.startswith(prefix):
            continue
        relative = name[len(prefix):]
        safe_relative(relative)
        target = tree.guard(new/relative, stage)
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as stream:
            stream.write(body)
        if file_hash(target) != digest(body):
            raise ValueError('Staged package readback mismatch: '+relative)
    return new


def rollback_install(tree, receipt, snapshot, guard, fault=lambda event: None):
    stage = Path(receipt['stage'])
    errors = []
    for folder in reversed(receipt['addonFolders']):
        try:
            fault('rollback:'+folder)
            live, parked = tree.addons/folder, stage/'previous'/folder
            expected = folder_snapshot(snapshot['addons'], folder)
            new_expected = folder_snapshot(receipt['stagedSnapshot'], folder)
            existed = folder in snapshot['addons']['directories']
            if live.exists():
                current = inventory(live)
                if existed and current == expected and not parked.exists():
                    continue
                if current != new_expected:
                    # Never overwrite a later manual change while compensating.
                    raise ValueError('Newer live folder changes retained: '+folder)
                displaced = stage/'failed-new'/uuid.uuid4().hex/folder
                move(tree, live, displaced, tree.addons, stage)
            if existed:
                if not parked.exists() or inventory(parked) != expected:
                    raise ValueError('Original parked folder unavailable/drifted: '+folder)
                move(tree, parked, live, stage, tree.addons)
            elif parked.exists():
                raise ValueError('Unexpected prior folder: '+folder)
        except Exception as error:
            errors.append(str(error))
    if not errors:
        try:
            restore_marker(tree, receipt, stage)
        except Exception as error:
            errors.append(str(error))
    receipt['rollbackErrors'] = errors
    receipt['status'] = 'recovery-required' if errors else 'rolled-back'
    receipt['closedAt'] = now()
    write_json(Path(receipt['backup'])/'install-receipt.json', receipt, guard)
    if not errors and inventory(tree.addons) != snapshot['addons']:
        receipt['status'] = 'recovery-required'
        receipt['rollbackErrors'].append('Whole addon readback differs; unrelated edits retained')
        write_json(Path(receipt['backup'])/'install-receipt.json', receipt, guard)
    return receipt['status'] == 'rolled-back'


def restore_marker(tree, receipt, stage):
    path = marker(tree)
    plain_path(path, tree.addons.parent)
    current = json.loads(path.read_text(encoding='utf-8')) if path.exists() else None
    prior = receipt.get('priorPack')
    intended = receipt.get('nextMarker')
    if current == prior:
        return
    parked_marker = stage/'retained-install-marker.json'
    own_gap = current is None and receipt.get('markerParked') and parked_marker.is_file() and json.loads(plain_path(parked_marker, stage).read_text(encoding='utf-8')) == prior
    if current != intended and not own_gap:
        raise ValueError('Newer installation marker retained')
    if path.exists():
        move(tree, path, stage/('retained-marker-'+uuid.uuid4().hex+'.json'), tree.addons.parent, stage)
    if prior:
        write_json(path, prior, lambda p: tree.guard(p, tree.addons.parent))


def install(tree, pack_path, expected_sha256, backup_root=None, execute=False, fault=lambda event: None):
    manifest, rows = read_pack(pack_path, expected_sha256, require_complete=True)
    if Path(pack_path).absolute().is_relative_to(tree.root):
        raise ValueError('Keep the pack outside the selected game root')
    tree.check(force_process=True)
    before = {'addons': inventory(tree.addons), 'wtf': inventory(tree.wtf, True)}
    folders = sorted(manifest['addonFolders']+list(manifest.get('retiredAddonFolders', {})))
    for name in folders:
        safe_relative(name)
        if '/' in name or (tree.addons/name).exists() and not (tree.addons/name).is_dir():
            raise ValueError('Addon folder collides with an existing file')
    prior = read_prior_marker(tree, before['addons'])
    proposal = {'operation': 'install', 'root': str(tree.root), 'anchors': tree.identity,
        'sourceCommit': manifest['sourceCommit'], 'packSHA256': expected_sha256,
        'addonFolders': folders, 'backupFiles': len(before['addons']['files'])+len(before['wtf']['files']),
        'retiredAddonFolders': manifest.get('retiredAddonFolders', {}),
        'configurationLinks': before['wtf']['links'], 'currentConfigurationWrites': False,
        'execute': execute, 'runtimeAcceptance': 'Pending H8 Retail tests'}
    if not execute:
        return proposal
    backups, guard = prepare_backups(tree, backup_root or tree.root/'CPFBackups')
    run_id = identity()
    backup = backups/run_id
    stage = tree.addons.parent/('.cpf-stage-'+run_id)
    receipt = {**proposal, 'format': 'CPF-operation-1', 'id': run_id, 'status': 'preparing', 'startedAt': now(),
        'backup': str(backup), 'stage': str(stage), 'priorPack': prior,
        'compatibility': manifest['compatibility'], 'progress': [], 'backupsRetained': True}
    snapshot = None
    try:
        backup, snapshot = backup_current(tree, backups, run_id, guard, fault)
        receipt['snapshotSHA256'] = file_hash(backup/'snapshot.json')
        receipt['status'] = 'backed-up'
        write_json(backup/'install-receipt.json', receipt, guard)
        verify_backup(backup, snapshot)
        tree.guard(stage, tree.addons.parent).mkdir()
        new = stage_rows(tree, stage, rows)
        receipt['stagedSnapshot'] = inventory(new)
        expected = {name[len('Interface/AddOns/'):]: {'sha256': digest(body), 'bytes': len(body)}
            for name, body in rows.items() if name.startswith('Interface/AddOns/')}
        if receipt['stagedSnapshot']['files'] != expected:
            raise ValueError('Complete staged addon inventory mismatch')
        fault('before-promotion')
        tree.check(force_process=True)
        verify_backup(backup, snapshot)
        if inventory(new) != receipt['stagedSnapshot'] or file_hash(pack_path) != expected_sha256:
            raise ValueError('Staged code or input archive drifted before promotion')
        if inventory(tree.addons) != snapshot['addons'] or inventory(tree.wtf, True) != snapshot['wtf']:
            raise ValueError('Current code/configuration drifted after backup; promotion refused')
        receipt['status'] = 'applying'
        write_json(backup/'install-receipt.json', receipt, guard)
        for folder in folders:
            tree.check(force_process=True)
            has_new = folder in manifest['addonFolders']
            if has_new and inventory(new/folder) != folder_snapshot(receipt['stagedSnapshot'], folder):
                raise ValueError('Staged owned folder drifted before promotion: '+folder)
            if not has_new and (new/folder).exists():
                raise ValueError('Retired folder unexpectedly staged: '+folder)
            live = tree.addons/folder
            if live.exists():
                if inventory(live) != folder_snapshot(snapshot['addons'], folder):
                    raise ValueError('Current owned folder drifted before replacement: '+folder)
                move(tree, live, stage/'previous'/folder, tree.addons, stage)
                if inventory(stage/'previous'/folder) != folder_snapshot(snapshot['addons'], folder):
                    raise ValueError('Parked original folder drifted: '+folder)
            receipt['progress'].append({'folder': folder, 'oldParked': True, 'newPlaced': False})
            write_json(backup/'install-receipt.json', receipt, guard)
            fault('promote:'+folder)
            if has_new:
                move(tree, new/folder, live, stage, tree.addons)
                receipt['progress'][-1]['newPlaced'] = True
            write_json(backup/'install-receipt.json', receipt, guard)
        current = inventory(tree.addons)
        if current != replace_owned(snapshot['addons'], receipt['stagedSnapshot'], folders):
            raise ValueError('Installed readback or unrelated addon preservation failed')
        if inventory(tree.wtf, True) != snapshot['wtf']:
            raise ValueError('Current configuration changed during promotion')
        installed = {'format': 'CPF-installed-receipt-1', 'sourceCommit': manifest['sourceCommit'],
            'packSHA256': expected_sha256, 'addonFolders': folders, 'installedFiles': expected,
            'compatibility': manifest['compatibility'], 'backup': str(backup)}
        receipt['nextMarker'] = installed
        write_json(backup/'install-receipt.json', receipt, guard)
        write_json(marker(tree), installed, lambda p: tree.guard(p, tree.addons.parent))
        receipt['status'], receipt['installedFiles'], receipt['closedAt'] = 'installed', expected, now()
        write_json(backup/'install-receipt.json', receipt, guard)
        receipt['receiptSHA256'] = file_hash(backup/'install-receipt.json')
        return receipt
    except Exception as error:
        receipt['error'] = str(error)
        if snapshot and receipt['status'] in {'applying', 'installed'}:
            rollback_install(tree, receipt, snapshot, guard, fault)
        elif backup.exists():
            receipt['status'], receipt['closedAt'] = 'failed-before-promotion', now()
            write_json(backup/'install-receipt.json', receipt, guard)
        raise RuntimeError(str(error)+'; retained backup '+str(backup)) from error


def load_receipt(tree, backup):
    tree.check(force_process=True)
    backup = Path(backup).absolute()
    plain_path(backup, backup)
    if tree.simulation:
        from repository_paths import ROOT, output
        output(backup, ROOT/'scratch')
    receipt = json.loads(plain_path(backup/'install-receipt.json', backup).read_text(encoding='utf-8'))
    snapshot = json.loads(plain_path(backup/'snapshot.json', backup).read_text(encoding='utf-8'))
    if receipt.get('format') != 'CPF-operation-1' or not re.fullmatch(r'\d{8}T\d{6}Z-[0-9a-f]{12}', receipt.get('id', '')) or backup.name != receipt['id']:
        raise ValueError('Invalid retained operation identity')
    expected_stage = tree.addons.parent/('.cpf-stage-'+receipt['id'])
    if receipt['stage'] != str(expected_stage):
        raise ValueError('Retained stage path is outside its approved scope')
    plain_path(expected_stage, tree.addons.parent)
    for name in receipt['addonFolders']:
        safe_relative(name)
        if '/' in name:
            raise ValueError('Unsafe retained folder identity')
    if receipt['backup'] != str(backup) or receipt['anchors'] != tree.identity:
        raise ValueError('Backup belongs to another game root/junction identity')
    if file_hash(backup/'snapshot.json') != receipt['snapshotSHA256']:
        raise ValueError('Snapshot metadata hash mismatch')
    verify_backup(backup, snapshot)
    return receipt, snapshot


def recover(tree, backup, execute=False):
    receipt, snapshot = load_receipt(tree, backup)
    if receipt['status'] not in {'applying', 'recovery-required'}:
        raise ValueError('No interrupted folder promotion to recover')
    if not execute:
        return {'operation': 'recover', 'backup': str(backup), 'status': receipt['status'], 'execute': False}
    guard = lambda target: tree.guard(target, Path(backup).parent)
    if not rollback_install(tree, receipt, snapshot, guard):
        raise ValueError('Recovery still requires attention; original code and all backups retained')
    if receipt.get('configIntent'):
        try:
            intent = receipt['configIntent']
            apply_configuration(tree, Path(backup)/'WTF', snapshot['wtf'], intent['before'], intent['after'])
        except Exception as error:
            receipt['status'] = 'recovery-required'
            receipt['rollbackErrors'].append(str(error))
            write_json(Path(backup)/'install-receipt.json', receipt, guard)
            raise ValueError('Configuration recovery still pending; all code/configuration backups retained') from error
    return receipt


def apply_configuration(tree, source, target, before, after, fault=lambda event: None):
    """Explicit disaster recovery only; never called by ordinary install."""
    tree.check(force_process=True)
    current = inventory(tree.wtf, True)
    if before['links'] != after['links'] or current['links'] != target['links']:
        raise ValueError('Configuration link topology changed; preserve links and review manually')
    for name, row in current['files'].items():
        if row != before['files'].get(name) and row != after['files'].get(name):
            raise ValueError('Newer configuration edit retained: '+name)
    for name in set(before['files']) & set(after['files']):
        if name not in current['files']:
            raise ValueError('Newer configuration deletion retained: '+name)
    dirs = set(current['directories'])
    if dirs-set(before['directories'])-set(after['directories']) or (set(before['directories']) & set(after['directories']))-dirs:
        raise ValueError('Newer configuration directory changes retained')
    for name in target['directories']:
        tree.guard(tree.wtf/name, tree.wtf).mkdir(parents=True, exist_ok=True)
    for name, row in target['files'].items():
        fault('config:'+name)
        src = plain_path(Path(source)/name, source)
        if file_hash(src) != row['sha256']:
            raise ValueError('Configuration source backup drift')
        dst = tree.guard(tree.wtf/name, tree.wtf)
        if dst.exists() and file_hash(dst) == row['sha256']:
            continue
        actual = {'sha256': file_hash(dst), 'bytes': dst.stat().st_size} if dst.exists() else None
        if actual not in (before['files'].get(name), after['files'].get(name)):
            raise ValueError('Configuration changed immediately before restore: '+name)
        # Same-volume atomic staging outside WTF keeps interrupted temporary
        # copies out of both native data and the restore drift inventory.
        temporary = tree.guard(tree.wtf.parent/('.cpf-config-'+uuid.uuid4().hex), tree.wtf.parent)
        with temporary.open('xb') as stream:
            stream.write(src.read_bytes())
            stream.flush()
            os.fsync(stream.fileno())
        if file_hash(temporary) != row['sha256']:
            raise ValueError('Configuration staged copy drift')
        tree.guard(dst, tree.wtf)
        os.replace(temporary, dst)
    for name, row in current['files'].items():
        if name not in target['files']:
            fault('config-remove:'+name)
            dst = tree.guard(tree.wtf/name, tree.wtf)
            if not dst.exists():
                continue
            if file_hash(dst) != row['sha256']:
                raise ValueError('Newer configuration file retained before removal')
            dst.unlink()
    for name in sorted(dirs-set(target['directories']), key=lambda x: x.count('/'), reverse=True):
        tree.guard(tree.wtf/name, tree.wtf).rmdir()
    if inventory(tree.wtf, True) != target:
        raise ValueError('Configuration restore readback failed')


def restore(tree, backup, execute=False, restore_config=False, accept_config_loss=False, fault=lambda event: None):
    original, old = load_receipt(tree, backup)
    if original['status'] != 'installed':
        raise ValueError('Choose a successfully installed receipt; interrupted installs use recover')
    before = {'addons': inventory(tree.addons), 'wtf': inventory(tree.wtf, True)}
    folders = original['addonFolders']
    if owned(before['addons'], folders) != original['installedFiles']:
        raise ValueError('Pack-owned code has newer edits; code restore refused')
    prior = original.get('priorPack')
    compatible = bool(prior and prior['compatibility']['storeSchema'] == original['compatibility']['storeSchema']
        and prior['compatibility']['dependencyVersions'] == original['compatibility']['dependencyVersions'])
    if restore_config:
        if not accept_config_loss:
            raise ValueError('Disaster restore requires explicit acceptance of replacing current saved configuration')
        if before['wtf']['links'] != old['wtf']['links']:
            raise ValueError('Preserve changed character/configuration links; manual recovery review required')
    elif not compatible:
        raise ValueError('Prior code/runtime compatibility unknown; use reviewed /cpf restore where compatible, or the separate explicit disaster-config recovery')
    proposal = {'operation': 'code-restore', 'backup': str(backup), 'root': str(tree.root),
        'addonFolders': folders, 'compatibleCodeOnly': compatible, 'restoreConfiguration': restore_config,
        'newerConfigurationWillBeBackedUp': True, 'execute': execute}
    if not execute:
        return proposal
    backups, guard = prepare_backups(tree, Path(backup).parent)
    run_id = identity()
    current_backup = backups/run_id
    stage = tree.addons.parent/('.cpf-stage-'+run_id)
    receipt = {**proposal, 'format': 'CPF-operation-1', 'id': run_id, 'backup': str(current_backup), 'originalBackup': str(backup),
        'stage': str(stage), 'anchors': tree.identity, 'status': 'preparing', 'startedAt': now(),
        'priorPack': read_prior_marker(tree, before['addons']), 'progress': [], 'backupsRetained': True}
    current_snapshot = None
    try:
        current_backup, current_snapshot = backup_current(tree, backups, run_id, guard, fault)
        receipt['snapshotSHA256'] = file_hash(current_backup/'snapshot.json')
        tree.guard(stage, tree.addons.parent).mkdir()
        restored = tree.guard(stage/'restored', stage)
        restored.mkdir()
        for folder in folders:
            if folder in old['addons']['directories']:
                copy_inventory(Path(backup)/'AddOns'/folder, restored/folder,
                    folder_snapshot(old['addons'], folder), lambda p: tree.guard(p, stage), fault)
        receipt['stagedSnapshot'] = inventory(restored)
        verify_backup(backup, old)
        verify_backup(current_backup, current_snapshot)
        fault('before-restore')
        if inventory(tree.addons) != current_snapshot['addons'] or inventory(tree.wtf, True) != current_snapshot['wtf']:
            raise ValueError('Current code/configuration drifted after restore backup')
        receipt['status'] = 'applying'
        if restore_config:
            receipt['configIntent'] = {'before': current_snapshot['wtf'], 'after': old['wtf']}
        write_json(current_backup/'install-receipt.json', receipt, guard)
        for folder in folders:
            tree.check(force_process=True)
            if (restored/folder).exists() and inventory(restored/folder) != folder_snapshot(receipt['stagedSnapshot'], folder):
                raise ValueError('Staged old code drifted before restore: '+folder)
            live = tree.addons/folder
            existed = folder in current_snapshot['addons']['directories']
            if live.exists():
                if not existed or inventory(live) != folder_snapshot(current_snapshot['addons'], folder):
                    raise ValueError('Current code drifted before restore: '+folder)
                move(tree, live, stage/'previous'/folder, tree.addons, stage)
            elif existed:
                raise ValueError('Current code disappeared before restore: '+folder)
            receipt['progress'].append({'folder': folder, 'oldParked': existed, 'newPlaced': False})
            write_json(current_backup/'install-receipt.json', receipt, guard)
            fault('restore:'+folder)
            if (restored/folder).exists():
                move(tree, restored/folder, live, stage, tree.addons)
                receipt['progress'][-1]['newPlaced'] = True
                write_json(current_backup/'install-receipt.json', receipt, guard)
        if restore_config:
            apply_configuration(tree, Path(backup)/'WTF', old['wtf'], current_snapshot['wtf'], old['wtf'], fault)
        elif inventory(tree.wtf, True) != current_snapshot['wtf']:
            raise ValueError('Current configuration changed during code restore')
        if inventory(tree.addons) != replace_owned(current_snapshot['addons'], receipt['stagedSnapshot'], folders):
            raise ValueError('Restored code/unrelated addon readback failed')
        receipt['nextMarker'] = original.get('priorPack')
        write_json(current_backup/'install-receipt.json', receipt, guard)
        current_marker = marker(tree)
        if current_marker.exists():
            receipt['markerParked'] = True
            write_json(current_backup/'install-receipt.json', receipt, guard)
            move(tree, current_marker, stage/'retained-install-marker.json', tree.addons.parent, stage)
        if receipt['nextMarker']:
            write_json(marker(tree), receipt['nextMarker'], lambda p: tree.guard(p, tree.addons.parent))
        receipt['status'], receipt['closedAt'] = 'restored', now()
        write_json(current_backup/'install-receipt.json', receipt, guard)
        receipt['receiptSHA256'] = file_hash(current_backup/'install-receipt.json')
        return receipt
    except Exception as error:
        receipt['error'] = str(error)
        if current_snapshot and receipt['status'] in {'applying', 'restored'}:
            rollback_install(tree, receipt, current_snapshot, guard, fault)
            if restore_config:
                try:
                    apply_configuration(tree, current_backup/'WTF', current_snapshot['wtf'], current_snapshot['wtf'], old['wtf'])
                except Exception as config_error:
                    receipt['status'] = 'recovery-required'
                    receipt.setdefault('rollbackErrors', []).append(str(config_error))
                    write_json(current_backup/'install-receipt.json', receipt, guard)
        elif current_backup.exists():
            receipt['status'] = 'failed-before-promotion'
            write_json(current_backup/'install-receipt.json', receipt, guard)
        raise RuntimeError(str(error)+'; retained current backup '+str(current_backup)) from error


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('operation', choices=['install', 'restore', 'recover'])
    parser.add_argument('--retail-root', required=True)
    parser.add_argument('--simulation', action='store_true')
    parser.add_argument('--user-install', action='store_true')
    parser.add_argument('--execute', action='store_true')
    parser.add_argument('--pack')
    parser.add_argument('--sha256')
    parser.add_argument('--backup-root')
    parser.add_argument('--backup')
    parser.add_argument('--restore-config', action='store_true')
    parser.add_argument('--accept-current-config-loss', action='store_true')
    args = parser.parse_args()
    tree = GameTree(args.retail_root, args.simulation, args.user_install)
    if args.operation == 'install':
        if not args.pack or not args.sha256:
            parser.error('install requires --pack and independently supplied --sha256')
        result = install(tree, args.pack, args.sha256, args.backup_root, args.execute)
    else:
        if not args.backup:
            parser.error('recover requires --backup')
        result = (recover(tree, args.backup, args.execute) if args.operation == 'recover' else
            restore(tree, args.backup, args.execute, args.restore_config, args.accept_current_config_loss))
    summary = {key: result[key] for key in ['operation', 'status', 'root', 'sourceCommit', 'packSHA256',
        'backup', 'stage', 'receiptSHA256', 'compatibleCodeOnly', 'restoreConfiguration', 'execute'] if key in result}
    summary['addonFolders'] = result.get('addonFolders', [])
    if result.get('retiredAddonFolders'): summary['retiredAddonFolders'] = result['retiredAddonFolders']
    if 'anchors' in result: summary['anchors'] = result['anchors']
    if 'configurationLinks' in result: summary['configurationLinkCount'] = len(result['configurationLinks'])
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
