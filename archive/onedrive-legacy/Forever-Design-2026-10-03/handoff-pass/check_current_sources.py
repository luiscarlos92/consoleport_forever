"""Inspect official package/source evidence without installing any addon."""
import concurrent.futures
import hashlib
import io
import json
from pathlib import Path
import urllib.request
import zipfile
from validate_handoff import OUT, api

def fetch(url):
    req=urllib.request.Request(url,headers={'User-Agent':'ConsolePort-Forever-handoff-audit'})
    with urllib.request.urlopen(req,timeout=45) as r:
        return r.read()

def inspect_package(release):
    asset=next(a for a in release['assets'] if a['name'].endswith('.zip') and 'nolib' not in a['name'].lower())
    data=fetch(asset['url'])
    sha=hashlib.sha256(data).hexdigest()
    if asset.get('digest') and asset['digest']!='sha256:'+sha:
        raise ValueError('Package digest mismatch: '+release['repo'])
    (OUT/'packages').mkdir(exist_ok=True)
    (OUT/'packages'/asset['name']).write_bytes(data)
    target=OUT/'current-packages'/release['repo'].split('/')[-1]
    target.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for item in z.infolist():
            dst=target/item.filename
            if not dst.resolve().is_relative_to(target.resolve()):
                raise ValueError('Unsafe archive member')
            if item.is_dir():
                continue
            dst.parent.mkdir(parents=True,exist_ok=True)
            dst.write_bytes(z.read(item))
    return {'repo':release['repo'],'tag':release['tag'],'url':asset['url'],
            'sha256':sha,'digestVerified':bool(asset.get('digest')),'path':str(target)}

def main():
    records=json.loads((OUT/'upstream-releases.json').read_text())
    selected=[r for r in records if r['repo'] in ['seblindfors/ConsolePort','Cidan/BetterBags']]
    results=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        for r in pool.map(inspect_package,selected): results.append(r)
    supplementary={}
    for repo in ['mpstark/DynamicCam','LudiusMaximus/Immersion_ExtraFade','DeadlyBossMods/DBM-Voicepack-VEM']:
        try:
            tags=api('repos/'+repo+'/tags?per_page=10')
            supplementary[repo]={'tags':[{'name':t['name'],'sha':t['commit']['sha']} for t in tags]}
            meta=api('repos/'+repo)
            branch=meta['default_branch']
            commit=api('repos/'+repo+'/commits/'+branch)['sha']
            supplementary[repo].update({'defaultBranch':branch,'head':commit})
            for file in ('DynamicCam.toc','Immersion_ExtraFade.toc','DBM-VPVEM.toc','main.lua','Core.lua'):
                try:
                    body=fetch('https://raw.githubusercontent.com/'+repo+'/'+commit+'/'+file)
                    dst=OUT/'current-source'/repo.split('/')[-1]/file
                    dst.parent.mkdir(parents=True,exist_ok=True)
                    dst.write_bytes(body)
                except Exception: pass
        except Exception as error: supplementary[repo]={'error':str(error)}
    meta=api('repos/luiscarlos92/consoleport_forever')
    supplementary['productRepository']={k:meta.get(k) for k in ('html_url','private','default_branch','size','empty')}
    result={'packages':results,'supplementary':supplementary}
    (OUT/'current-source-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps(result,indent=2))

if __name__=='__main__': main()
