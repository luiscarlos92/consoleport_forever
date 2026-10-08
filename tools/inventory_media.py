"""Qualify personal presentation assets without inferring redistribution rights."""
import json
from repository_paths import ROOT, output, sha

CP_MEDIA=['ConsolePort/Assets/Textures/Cursor/RoundBorderHighlight.blp',
          'ConsolePort/Assets/Icons/64/ps_s_l1.blp','ConsolePort/Assets/Icons/64/ps_s_r1.blp']

def inventory():
    lock=json.loads((ROOT/'dependencies/lock.json').read_text())
    cp=next(p for p in lock['packages'] if p['repo']=='seblindfors/ConsolePort')
    # Selected-device glyphs are resolved dynamically by the official API.
    media=CP_MEDIA+[name for name in cp['files'] if name.startswith('ConsolePort/Assets/Icons/64/') and name not in CP_MEDIA]
    baseline=json.loads((ROOT/'reference/manifests/2026-10-03-initial.json').read_text())
    records=[]
    for path in sorted((ROOT/'addon/ConsolePort_Forever/Assets').iterdir()):
        name=path.relative_to(ROOT).as_posix()
        captured=next(f for f in baseline['files'] if f['destination']==name)
        digest=sha(path)
        if digest!=captured['sha256']: raise ValueError('Captured artwork drift: '+name)
        records.append({'path':name,'sha256':digest,'bytes':path.stat().st_size,
                        'provenance':'Exact authorized installed companion baseline copy.',
                        'use':'Personal candidate artwork retained. Original artwork/third-party rights are not established by a capture hash.'})
    dependencies=[]
    for name in media:
        path=ROOT/cp['unpacked']/name
        if sha(path)!=cp['files'][name]: raise ValueError('Native CP presentation media drift: '+name)
        dependencies.append({'path':name,'sha256':cp['files'][name],'packageSHA256':cp['sha256'],
                             'source':cp['releaseURL'],'use':'Referenced from clean official ConsolePort; not duplicated into companion.'})
    return {'artwork':records,'referencedDependencyMedia':dependencies,
            'nativeResources':['CircleMaskScalable client mask','Optional gamepad-actionbar circle border/state/shadow and device empty-slot atlases, qualified at runtime by C_Texture.GetAtlasInfo; clean CP circular artwork/glyph fallback','128-redbutton-exit client atlas','crosshair_inspect_32/crosshair_unableinspect_32 client atlases','C_Spell.GetSpellTexture client resource for current class stance and 6603','LiteMount IconTexture metadata; explicit current LM_B2 icon preserved'],
            'behavior':'Round face surfaces (including the retained Forever sheet thin circle at x=1044..1089,y=552..597), grey device glyph backgrounds on all 32 cells and bank trigger prompts follow the selected native device. Class prompts follow native Forever side: warrior right shoulder+trigger, druid/paladin left shoulder+trigger. Usability/range colors and native actions remain owned upstream.',
            'acceptance':'Actual client atlas/path availability, clipping/empty slots/cooldowns/colors/glyphs remain user-rendered checks.',
            'distribution':'Personal locally assembled pack only. No public asset permission inferred; final notices/official-source assembly remain required.'}

if __name__=='__main__':
    result=inventory()
    output(ROOT/'evidence/dependencies/media.json').write_text(json.dumps(result,indent=2))
    print('Qualified',len(result['artwork']),'captured assets and',len(result['referencedDependencyMedia']),'native CP media files')
