const fs=require('fs'),path=require('path'),assert=require('assert');
const lua=require('../ConsolePort-Polish-2026-09-27/tools/node_modules/luaparse');
const root=path.join(__dirname,'staged'),mods=['','SHIFT-','CTRL-','CTRL-SHIFT-'];
const MENU='CLICK ConsolePortMenuTrigger:LeftButton';
function str(n){return n.raw[0]==='"'?JSON.parse(n.raw):n.raw.slice(1,-1);}
function key(f){return f.type==='TableKeyString'?f.key.name:str(f.key);}
function field(t,k){return t.fields.find(f=>key(f)===k);}
function get(t,k){const f=field(t,k);assert(f,`Missing ${k}`);return f.value;}
function global(ast,n){return ast.body.find(s=>s.type==='AssignmentStatement'&&s.variables[0].name===n).init[0];}
function parse(s){return lua.parse(s,{ranges:true,luaVersion:'5.1'});}
function edit(rel,cb){
 const file=path.join(root,rel),s=fs.readFileSync(file,'utf8'),ast=parse(s),edits=[];
 function set(t,k,v){const f=field(t,k),text=JSON.stringify(v);if(f)edits.push([f.value.range[0],f.value.range[1],text]);else edits.push([t.range[1]-1,t.range[1]-1,`[${JSON.stringify(k)}] = ${text},\n`]);}
 function mapping(t){for(const [b,a]of [['PADBACK','TOGGLEWORLDMAP'],['PADFORWARD',MENU]])for(const m of mods)set(get(t,b),m,a);}
 cb(ast,{set,mapping});let out=s,end=s.length;
 for(const [a,b,v]of edits.sort((a,b)=>b[0]-a[0])){assert(b<=end);out=out.slice(0,a)+v+out.slice(b);end=a;}
 parse(out);fs.writeFileSync(file,out);console.log(rel+': '+edits.length+' scoped edits');
}
edit('WTF/Account/119624169#1/SavedVariables/ConsolePort.lua',(ast,{mapping})=>{
 mapping(get(get(get(global(ast,'ConsolePortDevices'),'PlayStation 5'),'Generator'),'Center'));
 let n=0;for(const f of global(ast,'ConsolePortShared').fields){const b=field(f.value,'Bindings');if(b){mapping(b.value);n++;}}
 assert.equal(n,5,'stable preset plus four current snapshots');
});
edit('Interface/AddOns/ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua',(ast,{mapping})=>{
 const device=ast.body.find(n=>n.type==='CallStatement').expression.arguments[0];mapping(get(get(device,'Generator'),'Center'));
});
edit('WTF/Account/119624169#1/SavedVariables/Immersion.lua',(ast,{set})=>set(global(ast,'ImmersionSetup'),'boxoffsetX',0));
edit('WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua',(ast,{set})=>{
 const banks=get(global(ast,'ConsolePort_BarLayout'),'children');
 for(const b of ['Base','L2','R2','L2R2']){
  const bank=get(banks,b);assert.equal(get(bank,'width').value,250);set(bank,'width',277.5);
  // Center-anchored bank widens by 27.5: D-pad shifts -13.75 and face +13.75.
  // Inner edges were 105+45 and 145; now they are 105+45 and 172.5: gap=22.5.
  for(const id of ['PAD1','PAD2','PAD3','PAD4']){const p=get(get(get(bank,'children'),id),'pos');set(p,'x',get(p,'x').value+27.5);}
 }
});
for(const rel of ['WTF/Account/119624169#1/bindings-cache.wtf','WTF/Account/_template_/bindings-cache.wtf']){
 const file=path.join(root,rel),s=fs.readFileSync(file,'utf8'),wanted=Object.fromEntries(mods.flatMap(m=>[[m+'PADBACK','TOGGLEWORLDMAP'],[m+'PADFORWARD',MENU]])),seen=new Set();
 let lines=s.split(/\r?\n/).map(l=>{const m=l.match(/^bind (\S+) (.*)$/);if(m&&wanted[m[1]]){assert(!seen.has(m[1]));seen.add(m[1]);return `bind ${m[1]} ${wanted[m[1]]}`;}return l;});
 while(lines.at(-1)==='')lines.pop();for(const [k,v]of Object.entries(wanted))if(!seen.has(k))lines.push(`bind ${k} ${v}`);
 fs.writeFileSync(file,lines.join('\r\n')+'\r\n');
}
