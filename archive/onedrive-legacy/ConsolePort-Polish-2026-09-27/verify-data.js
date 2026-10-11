const fs=require('fs'), path=require('path'), assert=require('assert');
const lua=require('./tools/node_modules/luaparse');
const work=__dirname, manifest=JSON.parse(fs.readFileSync(path.join(work,'manifest.json')));
const dir=process.argv[2] || path.join(work,'staged');
function parse(s){return lua.parse(s,{luaVersion:'5.1',comments:false});}
function str(n){return n.raw[0]==='"'?JSON.parse(n.raw):n.raw.slice(1,-1);}
function val(n){
 if(n.type==='StringLiteral')return str(n);
 if(n.type==='NumericLiteral'||n.type==='BooleanLiteral')return n.value;
 if(n.type==='NilLiteral')return null;
 if(n.type==='UnaryExpression'&&n.operator==='-')return -val(n.argument);
 if(n.type==='TableConstructorExpression')return Object.fromEntries(n.fields.map(f=>[f.type==='TableKeyString'?f.key.name:val(f.key),val(f.value)]));
 throw Error('Unexpected data node '+n.type);
}
function saved(file){return Object.fromEntries(parse(fs.readFileSync(file,'utf8')).body.map(n=>[n.variables[0].name,val(n.init[0])]))}
function diff(a,b,p='',out=[]){
 if(a && b && typeof a==='object' && typeof b==='object') {for(const k of new Set([...Object.keys(a),...Object.keys(b)]))diff(a[k],b[k],p+'/'+k,out);}
 else if(a!==b)out.push({path:p,before:a,after:b});return out;
}
let syntax=0;
for(const rel of Object.keys(manifest.originals))if(rel.endsWith('.lua')) {parse(fs.readFileSync(path.join(dir,rel),'utf8'));syntax++;}
const cp='WTF/Account/119624169#1/SavedVariables/ConsolePort.lua';
const before=saved(path.join(work,'before',cp)), after=saved(path.join(dir,cp));
const changes=diff(before,after);
const mods=['','SHIFT-','CTRL-','CTRL-SHIFT-'], menu='CLICK ConsolePortMenuTrigger:LeftButton', mount='CLICK LM_B1:LeftButton';
function assertBindings(b){for(const m of mods){assert.equal(b.PADBACK[m],menu);assert.equal(b.PADSYSTEM[m],'TOGGLEWORLDMAP');}assert.equal(b.PADDUP['CTRL-SHIFT-'],mount);}
for(const p of Object.values(after.ConsolePortShared))if(p.Bindings)assertBindings(p.Bindings);
const gen=after.ConsolePortDevices['PlayStation 5'].Generator;assertBindings({...gen.Center,...gen.Face});
for(const d of changes){
 const p=d.path;
 const bindingScope=p.startsWith('/ConsolePortShared/')&&p.includes('/Bindings/') || p.startsWith('/ConsolePortDevices/PlayStation 5/Generator/');
 assert(bindingScope && (/\/(PADBACK|PADSYSTEM)(\/|$)/.test(p)||p.endsWith('/PADDUP/CTRL-SHIFT-')) || p==='/ConsolePortBindingIcons/'+mount, 'Unrequested data edit: '+p);
}
assert.equal(after.ConsolePortBindingIcons[mount],132247);
assert.equal(after.ConsolePortSettings.bindingPresetCondition,'[] Forever Controller');
assert.equal(after.ConsolePortSettings.useCharacterSettings,false);
assert.equal(after.ConsolePortSettings.bindingOverlapEnable,true);
const im='WTF/Account/119624169#1/SavedVariables/Immersion.lua';
const oldIm=saved(path.join(work,'before',im)), newIm=saved(path.join(dir,im));
assert.deepEqual(diff(oldIm,newIm).map(d=>d.path).sort(),['/ImmersionSetup/boxoffsetX','/ImmersionSetup/boxoffsetY']);
assert.equal(newIm.ImmersionSetup.boxoffsetX,0);assert.equal(newIm.ImmersionSetup.boxoffsetY,150);
assert.equal(newIm.ImmersionSetup.scale,1.2);assert.equal(newIm.ImmersionSetup.boxpoint,'Bottom');
for(const rel of ['WTF/Account/119624169#1/bindings-cache.wtf','WTF/Account/_template_/bindings-cache.wtf']){
 const wanted=Object.fromEntries(mods.flatMap(m=>[[m+'PADBACK',menu],[m+'PADSYSTEM','TOGGLEWORLDMAP']]));wanted['CTRL-SHIFT-PADDUP']=mount;
 const lines=fs.readFileSync(path.join(dir,rel),'utf8').split(/\r?\n/), base=fs.readFileSync(path.join(work,'before',rel),'utf8').split(/\r?\n/);
 const relevant=line=>{const m=line.match(/^bind (\S+) (.*)$/);return m&&Object.hasOwn(wanted,m[1]);};
 for(const [k,v] of Object.entries(wanted))assert.equal(lines.filter(l=>l.startsWith('bind '+k+' ')).join(''),`bind ${k} ${v}`);
 assert.deepEqual(lines.filter(l=>l&&!relevant(l)),base.filter(l=>l&&!relevant(l)));
}
const ps5='Interface/AddOns/ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua';
function sourceDevice(folder){const ast=parse(fs.readFileSync(path.join(folder,ps5),'utf8'));return val(ast.body.find(n=>n.type==='CallStatement').expression.arguments[0]);}
const oldPs=sourceDevice(path.join(work,'before')), newPs=sourceDevice(dir);
assertBindings({...newPs.Generator.Center,...newPs.Generator.Face});
for(const d of diff(oldPs,newPs))assert(/^\/Generator\/Center\/(PADSYSTEM|PADBACK)(\/|$)/.test(d.path)||d.path==='/Generator/Face/PADDUP/CTRL-SHIFT-',d.path);
const layout=fs.readFileSync(path.join(manifest.root,'WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua'),'utf8');
const banks=saved(path.join(manifest.root,'WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua')).ConsolePort_BarLayout.children;
assert.deepEqual(['Base','L2','R2','L2R2'].map(b=>[banks[b].type,banks[b].pos.x,banks[b].pos.y]),[['Group',0,150],['Group',-280,80],['Group',280,80],['Group',0,10]]);
assert.equal(['Base','L2','R2','L2R2'].flatMap(b=>Object.values(banks[b].children)).filter(b=>b.type==='GroupButton').length,32);
fs.writeFileSync(path.join(work,'evidence','data-diff.json'),JSON.stringify(changes,null,2));
console.log(`PASS: ${syntax} edited Lua files parse as Lua 5.1; ${changes.length} scoped SavedVariables differences; stable preset + four snapshots + both generators + both caches; all other bindings/settings preserved.`);
