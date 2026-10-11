"""Read-only live audit; all executable simulations use an isolated copied tree."""
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
ADDONS = ROOT / '_retail_/Interface/AddOns'
WTF = ROOT / '_retail_/WTF'
NODE = Path(r'C:\Users\luisr\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe')
MODULES = ROOT / 'ConsolePort-Polish-2026-09-27/tools/node_modules'
REPOS = ['seblindfors/ConsolePort', 'Cidan/BetterBags', 'mpstark/DynamicCam',
         'seblindfors/Immersion', 'LudiusMaximus/Immersion_ExtraFade', 'xod-wow/LiteMount',
         'SFX-WoW/Masque', 'rursache/HideClassBars', 'Tercioo/Plater-Nameplates',
         'DeadlyBossMods/DeadlyBossMods', 'DeadlyBossMods/DBM-Dungeons',
         'DeadlyBossMods/DBM-Vanilla', 'DeadlyBossMods/DBM-WotLK',
         'DeadlyBossMods/DBM-Cataclysm', 'DeadlyBossMods/DBM-MoP',
         'DeadlyBossMods/DBM-WoD', 'DeadlyBossMods/DBM-Legion',
         'DeadlyBossMods/DBM-Voicepack-VEM']

def digest(p):
    return hashlib.sha256(p.read_bytes()).hexdigest().upper()

def inventory():
    paths = {}
    for base in (ADDONS, WTF):
        for current, dirs, files in os.walk(base, followlinks=False):
            dirs[:] = [d for d in dirs if not os.path.islink(Path(current)/d)
                       and not os.path.isjunction(Path(current)/d)]
            for name in files:
                p = Path(current)/name
                canonical = str(p.resolve())
                paths[canonical] = {'path': str(p), 'sha256': digest(p), 'bytes': p.stat().st_size}
    return sorted(paths.values(), key=lambda x: x['path'])

def api(path):
    request = urllib.request.Request('https://api.github.com/' + path,
                                     headers={'User-Agent':'ConsolePort-Forever-handoff-audit'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)

def release(repo):
    try:
        data = api('repos/' + repo + '/releases/latest')
        return {'repo':repo, 'tag':data['tag_name'], 'url':data['html_url'],
                'publishedAt':data['published_at'], 'prerelease':data['prerelease'],
                'assets':[{'name':a['name'], 'url':a['browser_download_url'],
                           'bytes':a['size'], 'digest':a.get('digest')} for a in data['assets']]}
    except Exception as error:
        return {'repo':repo, 'unverified':True, 'error':str(error)}

def run_harnesses():
    sandbox = OUT/'sandbox'
    if sandbox.resolve().is_relative_to(ADDONS.resolve()) or sandbox.resolve().is_relative_to(WTF.resolve()):
        raise RuntimeError('Unsafe simulation directory')
    dest = sandbox/'_retail_/Interface/AddOns/ConsolePort_Forever'
    shutil.copytree(ADDONS/'ConsolePort_Forever', dest, dirs_exist_ok=True)
    cases=[]
    for name in ('installer', 'runtime', 'skin'):
        source = ROOT/f'ConsolePort-Forever-Standalone-2026-09-27/tests/{name}_harness.lua'
        target = sandbox/f'{name}_harness.lua'
        shutil.copy2(source, target)
        command=[str(NODE),str(MODULES/'fengari-node-cli/src/lua-cli.js'),str(target)]
        result=subprocess.run(command,cwd=sandbox,capture_output=True,text=True,timeout=30)
        log=result.stdout+result.stderr
        (OUT/f'{name}-harness.txt').write_text(log,encoding='utf-8')
        # The CLI may emit Lua errors yet return zero; require explicit PASS and no traceback.
        cases.append({'name':name,'exitCode':result.returncode,'output':log,
                      'passed':result.returncode==0 and 'PASS' in log and 'stack traceback' not in log})
    parser=OUT/'parse_sources.cjs'
    parser.write_text("const fs=require('fs');const path=require('path');const parser=require("+
                      json.dumps(str(MODULES/'luaparse'))+
                      ");let files=fs.readdirSync(process.argv[2]).filter(x=>x.endsWith('.lua'));"+
                      "for(const file of files){parser.parse(fs.readFileSync(path.join(process.argv[2],file),'utf8'),{luaVersion:'5.1'});}console.log('PASS Lua 5.1 syntax: '+files.length+' sources');",encoding='utf-8')
    syntax=subprocess.run([str(NODE),str(parser),str(dest)],capture_output=True,text=True,timeout=30)
    cases.append({'name':'lua51-syntax','exitCode':syntax.returncode,'output':syntax.stdout+syntax.stderr,
                  'passed':syntax.returncode==0 and 'PASS' in syntax.stdout})
    return cases

def main():
    OUT.mkdir(exist_ok=True)
    before=inventory()
    (OUT/'preservation-before.json').write_text(json.dumps(before,indent=2),encoding='utf-8')
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        releases=list(pool.map(release,REPOS))
    (OUT/'upstream-releases.json').write_text(json.dumps(releases,indent=2),encoding='utf-8')
    tests=run_harnesses()
    after=inventory()
    result={'liveFiles':len(before),'liveFilesUnchanged':before==after,
            'tests':tests,'gameOpened':False,'protectedRuntimeValidated':False,
            'fullSavedVariablesUsedInSimulation':False}
    (OUT/'validation.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'liveFiles':len(before),'unchanged':before==after,
                      'tests':[{'name':t['name'],'passed':t['passed']} for t in tests],
                      'releases':[{'repo':r['repo'],'tag':r.get('tag'),'error':r.get('error')} for r in releases]},indent=2))
    if before!=after or not all(t['passed'] for t in tests):
        raise SystemExit(1)

if __name__ == '__main__':
    main()
