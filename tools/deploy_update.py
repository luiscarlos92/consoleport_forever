"""Scoped update with atomic folder swaps, rollback and unchanged WTF/vendors."""
import argparse
import json
import os
import re
from deployment_guard import GameTree, copy_inventory, inventory, write_json
from deploy_companion import deploy as deploy_companion, vendor_fingerprints
from install_pack import identity, now, prepare_backups
from pack_format import digest, read_pack, safe_relative

NAME='ConsolePort_Forever'


def targets(manifest,rows):
    if manifest.get('deploymentScope')!='companion-and-updated-dependencies':
        raise ValueError('Explicit scoped update manifest required')
    updates=manifest.get('dependencyUpdates')
    if not isinstance(updates,dict): raise ValueError('Explicit dependency update identities required')
    owners={NAME:'companion'}
    for repo,entry in updates.items():
        if not isinstance(entry,dict) or manifest['compatibility']['dependencyVersions'].get(repo)!=entry.get('version'):
            raise ValueError('Updated dependency differs from tested version')
        if not re.fullmatch('[0-9a-f]{64}',entry.get('packageSHA256','')):
            raise ValueError('Qualified official package identity missing')
        if not entry.get('addonFolders') or not entry.get('files'): raise ValueError('Empty dependency update')
        for folder in entry['addonFolders']:
            if len(safe_relative(folder).parts)!=1 or folder in owners or folder.casefold() in {n.casefold() for n in owners}:
                raise ValueError('Unsafe or overlapping update folder')
            if folder.casefold() in {'wtf','reference','tests','tools','scratch'}: raise ValueError('Invalid addon scope')
            owners[folder]=repo
        prefix='Interface/AddOns/'
        actual={name[len(prefix):]:digest(body) for name,body in rows.items()
            if name.startswith(prefix) and name[len(prefix):].split('/')[0] in entry['addonFolders']}
        if actual!=entry['files']: raise ValueError('Official dependency update file inventory mismatch')
    if sorted(owners)!=manifest['addonFolders']: raise ValueError('Payload contains an unselected addon')
    return owners,updates


def untouched(root,folders):
    return {name:value for name,value in vendor_fingerprints(root).items() if name.split('/')[0] not in folders}


def deploy(tree,pack,checksum,backup_root,execute=False,fault=lambda event:None):
    manifest,rows=read_pack(pack,checksum,True)
    owners,updates=targets(manifest,rows)
    if not updates:
        result=deploy_companion(tree,pack,checksum,backup_root,execute,fault)
        result['dependencyUpdates']=[]
        return result
    tree.check(force_process=True)
    folders=[NAME]+sorted(folder for folder in owners if folder!=NAME)
    payloads={folder:{} for folder in folders}
    for name,data in rows.items():
        parts=safe_relative(name).parts
        if parts[:2]==('Interface','AddOns'):
            payloads[parts[2]]['/'.join(parts[3:])]=data
    before={folder:inventory(tree.addons/folder) if (tree.addons/folder).exists() else None for folder in folders}
    if before[NAME] is None: raise ValueError('Existing companion required')
    wtf=inventory(tree.wtf,True)
    vendors=untouched(tree.addons,folders)
    required=manifest['compatibility']['dependencyVersions'].get('seblindfors/ConsolePort',manifest['compatibility']['dependencyVersions'].get('ConsolePort'))
    def cp_version():
        text=(tree.addons/'ConsolePort/ConsolePort.toc').read_text(encoding='utf-8-sig')
        return re.search(r'^## Version:\s*(.+)$',text,re.M).group(1).strip()
    if 'ConsolePort' not in folders and cp_version()!=required: raise ValueError('Installed ConsolePort differs from tested version')
    result={'operation':'deploy-scoped-update','sourceCommit':manifest['sourceCommit'],'packSHA256':checksum,
        'root':str(tree.root),'addonFolders':folders,'dependencyUpdates':sorted(updates),
        'testedDependencies':manifest.get('testedDependencies',{}),'vendorFileCount':len(vendors),
        'characterLinkCount':len(wtf['links']),'currentConfigurationWrites':False,'vendorWrites':True,'execute':execute}
    if not execute: return result
    backups,guard=prepare_backups(tree,backup_root)
    run_id=identity();backup=guard(backups/run_id);backup.mkdir()
    stage=tree.guard(tree.addons.parent/('.cpf-update-stage-'+run_id),tree.addons.parent);stage.mkdir()
    receipt={**result,'id':run_id,'backup':str(backup),'stage':str(stage),'status':'backing-up','startedAt':now()}
    write_json(backup/'snapshot.json',{'addons':before,'wtf':wtf,'vendors':vendors,'anchors':tree.identity},guard)
    write_json(backup/'install-receipt.json',receipt,guard)
    for folder,snapshot in before.items():
        if snapshot is not None: copy_inventory(tree.addons/folder,backup/folder,snapshot,guard)
    copy_inventory(tree.wtf,backup/'WTF',wtf,guard)
    new=tree.guard(stage/'new',stage);new.mkdir()
    staged={}
    for folder,files in payloads.items():
        base=tree.guard(new/folder,stage);base.mkdir()
        for name,data in files.items():
            path=tree.guard(base/name,stage);path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
        staged[folder]=inventory(base)
        expected={name:{'bytes':len(data),'sha256':digest(data)} for name,data in files.items()}
        if staged[folder]['files']!=expected: raise ValueError('Staged update verification failed')
    tree.check(force_process=True)
    def originals_unchanged():
        return all((inventory(tree.addons/folder) if (tree.addons/folder).exists() else None)==snapshot for folder,snapshot in before.items())
    if not originals_unchanged() or inventory(tree.wtf,True)!=wtf or untouched(tree.addons,folders)!=vendors:
        raise ValueError('Live files changed during staging')
    previous=tree.guard(stage/'previous',stage);previous.mkdir()
    failed=tree.guard(stage/'failed',stage);failed.mkdir()
    parked,promoted=[],[]
    try:
        fault('before-promotion')
        for folder in folders:
            target=tree.guard(tree.addons/folder,tree.addons)
            if before[folder] is not None:
                os.rename(target,tree.guard(previous/folder,stage));parked.append(folder)
            os.rename(tree.guard(new/folder,stage),target);promoted.append(folder)
            fault('after-promotion:'+folder)
        fault('after-promotion')
        if any(inventory(tree.addons/folder)!=snapshot for folder,snapshot in staged.items()) or inventory(tree.wtf,True)!=wtf or untouched(tree.addons,folders)!=vendors:
            raise ValueError('Scoped update readback/preservation failed')
        if cp_version()!=required: raise ValueError('Updated ConsolePort differs from tested version')
        receipt.update(status='installed',closedAt=now(),installedAddons=staged,wtfUnchanged=True,unselectedVendorsUnchanged=True)
        write_json(backup/'install-receipt.json',receipt,guard)
        write_json(tree.addons.parent/'.cpf-companion-installed.json',receipt,lambda p:tree.guard(p,tree.addons.parent))
    except BaseException as error:
        for folder in reversed(promoted): os.rename(tree.guard(tree.addons/folder,tree.addons),tree.guard(failed/folder,stage))
        for folder in reversed(parked): os.rename(tree.guard(previous/folder,stage),tree.guard(tree.addons/folder,tree.addons))
        receipt.update(status='rolled-back',error=str(error),closedAt=now())
        write_json(backup/'install-receipt.json',receipt,guard)
        raise
    return receipt


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--retail-root',required=True)
    parser.add_argument('--pack',required=True)
    parser.add_argument('--sha256',required=True)
    parser.add_argument('--backup-root',required=True)
    parser.add_argument('--user-install',action='store_true')
    parser.add_argument('--execute',action='store_true')
    args=parser.parse_args()
    tree=GameTree(args.retail_root,user_install=args.user_install)
    result=deploy(tree,args.pack,args.sha256,args.backup_root,args.execute)
    print(json.dumps({key:value for key,value in result.items() if key not in {'installedFiles','installedAddons'}},indent=2))
