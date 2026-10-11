const fs=require('fs'),path=require('path'),assert=require('assert');
const lua=require('../ConsolePort-Polish-2026-09-27/tools/node_modules/luaparse');
const w=__dirname,m=JSON.parse(fs.readFileSync(path.join(w,'manifest.json'))),dir=process.argv[2]||path.join(w,'staged');
function parse(s){return lua.parse(s,{luaVersion:'5.1',comments:false});}
function val(n){
 if(n.type==='StringLiteral')return n.raw[0]==='"'?JSON.parse(n.raw):n.raw.slice(1,-1);
 if(n.type==='NumericLiteral'||n.type==='BooleanLiteral')return n.value;
 if(n.type==='NilLiteral')return null;
 if(n.type==='UnaryExpression'&&n.operator==='-')return -val(n.argument);
 if(n.type==='TableConstructorExpression')return Object.fromEntries(n.fields.map(f=>[f.type==='TableKeyString'?f.key.name:val(f.key),val(f.value)]));
 throw Error(n.type);
}
function saved(base,rel){return Object.fromEntries(parse(fs.readFileSync(path.join(base,rel),'utf8')).body.map(n=>[n.variables[0].name,val(n.init[0])]))}
function diff(a,b,p='',out=[]){if(a&&b&&typeof a==='object'&&typeof b==='object'){for(const k of new Set([...Object.keys(a),...Object.keys(b)]))diff(a[k],b[k],p+'/'+k,out);}else if(a!==b)out.push({path:p,before:a,after:b});return out;}
const before=path.join(w,'before'),mods=['','SHIFT-','CTRL-','CTRL-SHIFT-'],menu='CLICK ConsolePortMenuTrigger:LeftButton',mount='CLICK LM_B1:LeftButton';
let syntax=0;for(const rel of Object.keys(m.originals))if(rel.endsWith('.lua')){parse(fs.readFileSync(path.join(dir,rel),'utf8'));syntax++;}
const cp='WTF/Account/119624169#1/SavedVariables/ConsolePort.lua',old=saved(before,cp),now=saved(dir,cp);
function bindings(b){for(const mod of mods){assert.equal(b.PADBACK[mod],'TOGGLEWORLDMAP');assert.equal(b.PADFORWARD[mod],menu);assert.equal(b.PADSYSTEM[mod],'TOGGLEWORLDMAP');}assert.equal(b.PADDUP['CTRL-SHIFT-'],mount);}
let count=0;for(const p of Object.values(now.ConsolePortShared))if(p.Bindings){bindings(p.Bindings);count++;for(const mod of mods){assert.equal(p.Bindings.PADLSHOULDER[mod],'TARGETNEARESTFRIEND');assert.equal(p.Bindings.PADRSHOULDER[mod],'TARGETSCANENEMY');}assert.equal(p.Bindings.PAD2[''],'');}
assert.equal(count,5);
const gen=now.ConsolePortDevices['PlayStation 5'].Generator;bindings({...gen.Center,...gen.Face});
const changes=diff(old,now);
for(const d of changes)assert((d.path.startsWith('/ConsolePortShared/')&&/\/Bindings\/(PADBACK|PADFORWARD)\//.test(d.path))||/^\/ConsolePortDevices\/PlayStation 5\/Generator\/Center\/(PADBACK|PADFORWARD)\//.test(d.path),d.path);
assert.equal(now.ConsolePortBindingIcons[mount],132247);assert.equal(now.ConsolePortSettings.bindingPresetCondition,'[] Forever Controller');assert.equal(now.ConsolePortSettings.useCharacterSettings,false);assert.equal(now.ConsolePortSettings.bindingOverlapEnable,true);
const ps='Interface/AddOns/ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua';
function device(base){return val(parse(fs.readFileSync(path.join(base,ps),'utf8')).body.find(n=>n.type==='CallStatement').expression.arguments[0]);}
const oldDev=device(before),newDev=device(dir);bindings({...newDev.Generator.Center,...newDev.Generator.Face});
for(const d of diff(oldDev,newDev))assert(/^\/Generator\/Center\/(PADBACK|PADFORWARD)\//.test(d.path),d.path);
const im='WTF/Account/119624169#1/SavedVariables/Immersion.lua',oldIm=saved(before,im),newIm=saved(dir,im);
assert.deepEqual(diff(oldIm,newIm).map(d=>d.path),['/ImmersionSetup/boxoffsetX']);assert.equal(newIm.ImmersionSetup.boxoffsetX,0);assert.equal(newIm.ImmersionSetup.boxoffsetY,39.27963256835938);assert.equal(newIm.ImmersionSetup.scale,1.2);assert.equal(newIm.ImmersionSetup.boxpoint,'Bottom');
const bar='WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua',ob=saved(before,bar),nb=saved(dir,bar);
const geometry=[];
for(const bank of ['Base','L2','R2','L2R2']){
 const a=ob.ConsolePort_BarLayout.children[bank],b=nb.ConsolePort_BarLayout.children[bank];
 assert.deepEqual(a.pos,b.pos);assert.equal(a.rescale,b.rescale);assert.equal(a.opacity,b.opacity);assert.equal(a.height,b.height);assert.equal(b.width,277.5);
 const gap=b.children.PAD3.pos.x-(b.children.PADDRIGHT.pos.x+45);assert.equal(gap,22.5);
 for(const [id,child]of Object.entries(b.children)){const face=/^PAD[1-4]$/.test(id);assert.equal(child.pos.x-a.children[id].pos.x,face?27.5:0);assert.equal(child.pos.y,a.children[id].pos.y);}
 geometry.push({bank,frame_gap:gap,nominal_gap_94:gap*0.94,nominal_gap_106:gap*1.06,bank_anchor:b.pos,opposite_cross_displacement:13.75});
}
const bd=diff(ob,nb);assert.equal(bd.length,20);for(const d of bd)assert(/^\/ConsolePort_BarLayout\/children\/(Base|L2|R2|L2R2)\/(width|children\/PAD[1-4]\/pos\/x)$/.test(d.path),d.path);
for(const rel of ['WTF/Account/119624169#1/bindings-cache.wtf','WTF/Account/_template_/bindings-cache.wtf']){
 const a=fs.readFileSync(path.join(before,rel),'utf8').split(/\r?\n/),b=fs.readFileSync(path.join(dir,rel),'utf8').split(/\r?\n/);
 const relevant=l=>/^bind (?:CTRL-SHIFT-|SHIFT-|CTRL-)?PAD(?:BACK|FORWARD) /.test(l);
 assert.deepEqual(a.filter(l=>l&&!relevant(l)),b.filter(l=>l&&!relevant(l)));
 for(const mod of mods)for(const [key,v]of [['PADBACK','TOGGLEWORLDMAP'],['PADFORWARD',menu]])assert.equal(b.filter(l=>l.startsWith('bind '+mod+key+' ')).join(''),'bind '+mod+key+' '+v);
 assert(b.includes('bind CTRL-SHIFT-PADDUP '+mount));
}
// Include art sheet identity and verified source atlas membership in the receipt.
for(const [file,id,width,height]of [['ForeverInGame.blp',6227336,2048,2048],['ForeverTargeting.blp',8395116,512,256]]){
 const data=fs.readFileSync(path.join(dir,'Interface/AddOns/ConsolePort_Forever/Assets',file));assert.equal(data.toString('ascii',0,4),'BLP2');assert.equal(data.readUInt32LE(12),width);assert.equal(data.readUInt32LE(16),height);assert(data.equals(fs.readFileSync(path.join(w,'evidence',id+'.blp'))));
}
const retail=fs.readFileSync(path.join(w,'evidence/retail-atlas.csv'),'utf8');for(const name of ['128-redbutton-exit','crosshair_inspect_32','crosshair_unableinspect_32'])assert(retail.includes('\n'+name+','));
fs.writeFileSync(path.join(w,'evidence/data-diff.json'),JSON.stringify({bindings:changes,layout:bd,immersion:diff(oldIm,newIm),geometry},null,2));
console.log(`PASS: ${syntax} Lua files parse as Lua 5.1; ${changes.length} scoped binding changes; five presets/snapshots, both generators/caches, empty PAD2 and LiteMount retained; 20 geometry-only edits; Immersion X-only edit; original art sheets verified.`);
