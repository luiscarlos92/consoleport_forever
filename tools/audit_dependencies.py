"""Select installed Retail coverage, validate runtime closure and upstream voice."""
import argparse
import hashlib
import json
import posixpath
import re
from pathlib import PurePosixPath
from repository_paths import ROOT, contained, output, sha
from resolve_dependencies import metadata, verify


def runtime_closure(folder, files, require_retail=True):
    """Resolve Retail TOC includes; validate all declared locale/flavor files.

    This verifies file presence, not the client loader or protected execution.
    Native conditional annotations are retained byte-for-byte in distribution.
    """
    names = {n.casefold():n for n in files}
    candidates = [folder+'/'+folder+suffix for suffix in ['_Mainline.toc','_mainline.toc','_Retail.toc','.toc']]
    toc = next((names[n.casefold()] for n in candidates if n.casefold() in names),None)
    if not toc:
        raise ValueError('Missing native Retail TOC: '+folder)
    visited = set()
    def visit(name):
        name = posixpath.normpath(name.replace('\\','/'))
        if name.casefold() not in names or not name.casefold().startswith(folder.casefold()+'/'):
            raise ValueError('Missing or escaping runtime include: '+name)
        name = names[name.casefold()]
        if name in visited: return
        visited.add(name)
        text = files[name].decode('utf-8-sig',errors='replace')
        if name.lower().endswith('.toc'):
            includes = [line.strip() for line in text.splitlines() if line.strip() and not line.strip().startswith('#')]
        elif name.lower().endswith('.xml'):
            # XML comments are packager/source annotation, not active includes.
            text = re.sub(r'<!--.*?-->','',text,flags=re.S)
            includes = re.findall(r'<(?:Include|Script)\b[^>]*\bfile\s*=\s*[\"\']([^\"\']+)[\"\']',text,re.I)
        else: return
        for include in includes:
            include = re.sub(r'\s+\[(?:Allow|Exclude)LoadGameType [\w, ]+\]$','',include)
            if '[TextLocale]' in include:
                for locale in ['enUS','deDE','esES','esMX','frFR','itIT','koKR','ptBR','ruRU','zhCN','zhTW']:
                    visit(str(PurePosixPath(name).parent / include.replace('[TextLocale]',locale).replace('\\','/')))
            elif '[Family]' in include:
                # Current ConsolePort ships Mainline/Classic family modules.
                visit(str(PurePosixPath(name).parent / include.replace('[Family]','Mainline').replace('\\','/')))
                classic = str(PurePosixPath(name).parent / include.replace('[Family]','Classic').replace('\\','/'))
                if classic.casefold() in names: visit(classic)
            else:
                visit(str(PurePosixPath(name).parent / include.replace('\\','/')))
    visit(toc)
    meta = metadata([(toc,files[toc])], require_retail=require_retail)[0][toc]
    return {'toc':toc,'runtimeFiles':sorted(visited),'metadata':meta}


def voice_provenance(lock):
    if not any(p['repo']=='DeadlyBossMods/DeadlyBossMods' for p in lock['packages']):
        return {'applicable':False,'reason':'DBM removed by user; retained historical provenance is inactive.'}
    record = json.loads((ROOT/'evidence/dependencies/voice-provenance.json').read_text(encoding='utf-8'))
    core = next(p for p in lock['packages'] if p['repo']=='DeadlyBossMods/DeadlyBossMods')
    actual = {n for n in core['files'] if n.startswith('DBM-VPVEM/')}
    if actual != set(record['files']): raise ValueError('Voice file set differs from pinned maintainer source')
    for name, expected in record['files'].items():
        data = contained(ROOT/core['unpacked']/name).read_bytes()
        if name.endswith('.toc'):
            text = data.decode('utf-8-sig').replace('## Version: 99e0c33','## Version: @project-version@')
            if text.splitlines() != record['sourceTOC'].splitlines(): raise ValueError('Unexpected generated voice TOC change')
        elif hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()!=expected:
            raise ValueError('Voice upstream drift: '+name)
    return {'owner':core['repo'],'packageSHA256':core['sha256'],'commit':record['commit'],
            'matchedUnmodifiedFiles':len(actual)-1,'generatedTOC':'Only Version packager token resolved to 99e0c33; upstream package bytes retained.'}


NATIVE_ADDON_TOCS = {
    'Blizzard_Collections': 'Blizzard_Collections/Blizzard_Collections_Mainline.toc',
    'Blizzard_Transmog': 'Blizzard_Transmog/Blizzard_Transmog.toc',
}


def native_addon_dependencies(required):
    """Qualify only explicit client-owned addons from hashed Retail contracts."""
    accepted = {}
    requested = set(required).intersection(NATIVE_ADDON_TOCS)
    if not requested: return accepted
    records = {r['path']:r for r in json.loads((ROOT/'evidence/native/manifest.json').read_text(encoding='utf-8'))}
    for name in sorted(requested):
        path = NATIVE_ADDON_TOCS[name]
        record = records.get(path, {})
        source = contained(ROOT/'evidence/native'/path)
        if not record.get('sha256') or sha(source) != record['sha256']:
            raise ValueError('Native addon contract drift: '+name)
        meta = metadata([(path, source.read_bytes())], require_retail=False)[0][path]
        allowed = set(re.split(r'[,\s]+', meta.get('AllowLoadGameType', '').strip()))- {''}
        excluded = set(re.split(r'[,\s]+', meta.get('ExcludeLoadGameType', '').strip()))
        if meta.get('Title') not in {name,name.replace('_',' ')} or (allowed and 'mainline' not in allowed) or 'mainline' in excluded or 'standard' in excluded:
            raise ValueError('Native addon is not a qualified Retail contract: '+name)
        accepted[name] = {**record, 'clientOwned':True, 'shipped':False}
    return accepted


def audit(lock):
    owners = verify(lock)
    selected = set(lock['installedFolders'])
    if selected-set(owners): raise ValueError('Installed coverage is incomplete')
    folders, exclusions = {}, {}
    for package in lock['packages']:
        files = {n:contained(ROOT/package['unpacked']/n).read_bytes() for n in package['files']}
        package['toc'], package['metadataAdvisories'] = metadata(list(files.items()))
        for folder in package['addonFolders']:
            if folder not in selected:
                exclusions[folder] = {'owner':package['repo'],'reason':'Not installed reference coverage or required dependency; retain archive but omit from personal pack.'}
                if folder=='DBM-Party-Forever': exclusions[folder]['reason']='Forever-only content is not a Retail dependency; exclude without editing upstream.'
                continue
            immediate = [meta for name,meta in package['toc'].items() if name.startswith(folder+'/') and len(PurePosixPath(name).parts)==2]
            retail = any(any(int(n)>=120000 for n in re.findall(r'\d+',meta.get('Interface',''))) and not set(re.split(r'[,\s]+',meta.get('ExcludeLoadGameType',''))).intersection({'standard','mainline'}) for meta in immediate)
            # Preserve installed official package companions even when their
            # native TOCs exclude Retail. Removing them makes CurseForge's
            # otherwise correct package incomplete. WoW owns load eligibility.
            closure = runtime_closure(folder,files,require_retail=retail)
            folders[folder] = {'owner':package['repo'],'eligibleForRetail':retail,**closure}
    native = {}
    for folder, record in folders.items():
        meta = record['metadata']
        required = meta.get('RequiredDeps',meta.get('Dependencies',''))
        missing = set(re.split(r'[,\s]+',required.strip()))-set(folders)-{''}
        qualified = native_addon_dependencies(missing)
        native.update(qualified)
        missing -= set(qualified)
        if missing: raise ValueError('Missing required addon closure for '+folder+': '+str(missing))
    return {'lockSHA256':None,'selectedFolders':folders,'excludedFolders':exclusions,
            'nativeAddonDependencies':native,
            'voice':voice_provenance(lock),
            'distribution':{'restrictedOfficialAssembly':['SFX-WoW/Masque','Tercioo/Plater-Nameplates','SLOKnightfall/BetterWardrobe']+[p['repo'] for p in lock['packages'] if p['repo'].startswith('DeadlyBossMods/')],
                            'reason':'License/redistribution terms require an official-source assembly mechanism; do not publish these dependency bytes in the pack ZIP.',
                            'pending':'Prepare assembly mechanism, complete license/notices inventory and verify clean installed file hashes.'}}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--record',action='store_true',help='Persist verified package coverage and close bundled voice retrieval ticket')
    args=parser.parse_args()
    lock_path=ROOT/'dependencies/lock.json'
    lock=json.loads(lock_path.read_text(encoding='utf-8'))
    if args.record:
        sources=json.loads((ROOT/'dependencies/sources.json').read_text(encoding='utf-8'))
        for source in sources.get('curseforge',[]):
            package=next(p for p in lock['packages'] if p['repo']==source['repo'])
            if package.get('fileID')==source['fileID'] and package['version']==source['version']:
                package['metadataVerifiedAt']=source['metadataVerifiedAt']
    result=audit(lock)
    if args.record:
        lock['blockers']=[b for b in lock['blockers'] if b.get('package')!='DBM-VPVEM']
        lock['coverageQualified']=True
        lock['complete']=not lock['blockers'] and not lock['unmappedFolders']
        lock['packDistributionReady']=False
        lock['selectedFolders']=sorted(result['selectedFolders'])
        lock['excludedFolders']=result['excludedFolders']
        output(lock_path).write_text(json.dumps(lock,indent=2),encoding='utf-8')
        result['lockSHA256']=sha(lock_path)
        target=output(ROOT/'evidence/dependencies/coverage.json')
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'selected':len(result['selectedFolders']),'excluded':len(result['excludedFolders']),'voice':result['voice']}))
