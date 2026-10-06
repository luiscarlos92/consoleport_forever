"""Deploy only the tested companion; never write CurseForge addons or WTF."""
import argparse
import json
import os
from pathlib import Path
import re
from deployment_guard import GameTree, copy_inventory, inventory, write_json
from install_pack import identity, now, prepare_backups
from pack_format import digest, file_hash, is_link, read_pack, safe_relative

NAME='ConsolePort_Forever'


def vendor_fingerprints(root):
    result={}
    for base,dirs,names in os.walk(root,followlinks=False):
        if Path(base)==root: dirs[:]=[n for n in dirs if n!=NAME]
        for name in dirs+names:
            if is_link(Path(base)/name): raise ValueError('Vendor code link refused')
        for name in names:
            path=Path(base)/name
            result[path.relative_to(root).as_posix()]=file_hash(path)
    return result


def deploy(tree,pack,checksum,backup_root,execute=False,fault=lambda event:None):
    manifest,all_rows=read_pack(pack,checksum,True)
    prefix='Interface/AddOns/'+NAME+'/'
    rows={n[len(prefix):]:data for n,data in all_rows.items() if n.startswith(prefix)}
    if not rows or NAME not in manifest['addonFolders']: raise ValueError('Verified companion payload missing')
    expected={n:{'bytes':len(data),'sha256':digest(data)} for n,data in rows.items()}
    for name in rows: safe_relative(name)
    tree.check(force_process=True)
    cp_toc=(tree.addons/'ConsolePort/ConsolePort.toc').read_text(encoding='utf-8-sig')
    version=re.search(r'^## Version:\s*(.+)$',cp_toc,re.M).group(1).strip()
    required=manifest['compatibility']['dependencyVersions'].get('seblindfors/ConsolePort',manifest['compatibility']['dependencyVersions'].get('ConsolePort'))
    if version!=required: raise ValueError('Installed ConsolePort differs from tested dependency')
    target=tree.addons/NAME
    before=inventory(target)
    wtf=inventory(tree.wtf,True)
    vendors=vendor_fingerprints(tree.addons)
    result={'operation':'deploy-companion','sourceCommit':manifest['sourceCommit'],'packSHA256':checksum,
        'dependencyUpdates':[],'testedDependencies':manifest.get('testedDependencies',{}),
        'root':str(tree.root),'consolePortVersion':version,'addonFolders':[NAME],
        'vendorFileCount':len(vendors),'characterLinkCount':len(wtf['links']),
        'currentConfigurationWrites':False,'vendorWrites':False,'execute':execute}
    if not execute: return result
    backups,guard=prepare_backups(tree,backup_root)
    run_id=identity(); backup=guard(backups/run_id);backup.mkdir()
    stage=tree.guard(tree.addons.parent/('.cpf-companion-stage-'+run_id),tree.addons.parent);stage.mkdir()
    receipt={**result,'id':run_id,'backup':str(backup),'stage':str(stage),'status':'backing-up','startedAt':now()}
    snapshot={'companion':before,'wtf':wtf,'vendors':vendors,'anchors':tree.identity}
    write_json(backup/'snapshot.json',snapshot,guard)
    write_json(backup/'install-receipt.json',receipt,guard)
    copy_inventory(target,backup/NAME,before,guard)
    copy_inventory(tree.wtf,backup/'WTF',wtf,guard)
    if inventory(backup/NAME)!=before or inventory(backup/'WTF')['files']!=wtf['files']:
        raise ValueError('Companion/configuration backup verification failed')
    new=tree.guard(stage/'new',stage);new.mkdir()
    for name,data in rows.items():
        path=tree.guard(new/name,stage);path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    staged=inventory(new)
    if staged['files']!=expected: raise ValueError('Staged companion verification failed')
    tree.check(force_process=True)
    if inventory(target)!=before or inventory(tree.wtf,True)!=wtf or vendor_fingerprints(tree.addons)!=vendors:
        raise ValueError('Live files changed during staging; deployment refused')
    previous=stage/'previous';failed=stage/'failed';parked=False;promoted=False
    try:
        fault('before-promotion')
        os.rename(tree.guard(target,tree.addons),tree.guard(previous,stage));parked=True
        os.rename(tree.guard(new,stage),tree.guard(target,tree.addons));promoted=True
        fault('after-promotion')
        if inventory(target)!=staged or inventory(tree.wtf,True)!=wtf or vendor_fingerprints(tree.addons)!=vendors:
            raise ValueError('Deployment readback or vendor/configuration preservation failed')
        receipt.update(status='installed',closedAt=now(),installedFiles=expected,wtfUnchanged=True,vendorsUnchanged=True)
        write_json(backup/'install-receipt.json',receipt,guard)
        write_json(tree.addons.parent/'.cpf-companion-installed.json',receipt,lambda p:tree.guard(p,tree.addons.parent))
    except Exception as error:
        if promoted: os.rename(tree.guard(target,tree.addons),tree.guard(failed,stage))
        if parked: os.rename(tree.guard(previous,stage),tree.guard(target,tree.addons))
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
    print(json.dumps({key:value for key,value in result.items() if key!='installedFiles'},indent=2))
