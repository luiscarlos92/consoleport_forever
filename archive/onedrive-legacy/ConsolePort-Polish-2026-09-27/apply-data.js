const fs = require('fs'), path = require('path'), assert = require('assert');
const lua = require('./tools/node_modules/luaparse');
const root = path.join(__dirname, 'staged');
const mods = ['', 'SHIFT-', 'CTRL-', 'CTRL-SHIFT-'];
const MENU = 'CLICK ConsolePortMenuTrigger:LeftButton', MOUNT = 'CLICK LM_B1:LeftButton';
function str(n) {return n.raw[0] === '"' ? JSON.parse(n.raw) : n.raw.slice(1, -1);}
function key(f) {return f.type === 'TableKeyString' ? f.key.name : str(f.key);}
function field(t,k) {return t.fields.find(f=>key(f)===k);}
function get(t,k) {const f=field(t,k); assert(f, `Missing ${k}`); return f.value;}
function parse(s) {return lua.parse(s,{ranges:true, luaVersion:'5.1', comments:false});}
function edit(rel, cb) {
 const file=path.join(root,rel), s=fs.readFileSync(file,'utf8'), ast=parse(s), edits=[];
 function set(t,k,v) {
   const f=field(t,k), text=typeof v==='object' ? '{'+Object.entries(v).map(([k,v])=>`[${JSON.stringify(k)}] = ${JSON.stringify(v)},`).join('\n')+'}' : JSON.stringify(v);
   if(f) edits.push([f.value.range[0],f.value.range[1],text]);
   else edits.push([t.range[1]-1,t.range[1]-1,`[${JSON.stringify(k)}] = ${text},\n`]);
 }
 function mapping(t) {
   for(const [button,action] of [['PADBACK',MENU],['PADSYSTEM','TOGGLEWORLDMAP']]) {
     const f=field(t,button);
     if(f) for(const m of mods) set(f.value,m,action);
     else set(t,button,Object.fromEntries(mods.map(m=>[m,action])));
   }
 }
 cb(ast,{set,mapping});
 let out=s, end=s.length;
 for(const [a,b,v] of edits.sort((a,b)=>b[0]-a[0])) {assert(b<=end, 'Overlapping edits'); out=out.slice(0,a)+v+out.slice(b); end=a;}
 parse(out); fs.writeFileSync(file,out); console.log(`${rel}: ${edits.length} targeted edits`);
}
function global(ast,name) {const stmt=ast.body.find(n=>n.type==='AssignmentStatement' && n.variables[0].name===name);assert(stmt,name);return stmt.init[0];}
edit('WTF/Account/119624169#1/SavedVariables/ConsolePort.lua',(ast,{set,mapping})=>{
 const gen=get(get(global(ast,'ConsolePortDevices'),'PlayStation 5'),'Generator');
 mapping(get(gen,'Center')); set(get(get(gen,'Face'),'PADDUP'),'CTRL-SHIFT-',MOUNT);
 const shared=global(ast,'ConsolePortShared'); let count=0;
 for(const f of shared.fields) {const bindings=field(f.value,'Bindings');if(bindings){mapping(bindings.value);set(get(bindings.value,'PADDUP'),'CTRL-SHIFT-',MOUNT);count++;}}
 assert(count===5,`Expected stable preset and four snapshots, found ${count}`);
 set(global(ast,'ConsolePortBindingIcons'),MOUNT,132247);
});
edit('WTF/Account/119624169#1/SavedVariables/Immersion.lua',(ast,{set})=>{
 const t=global(ast,'ImmersionSetup');set(t,'boxoffsetX',0);set(t,'boxoffsetY',150);
});
edit('Interface/AddOns/ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua',(ast,{set,mapping})=>{
 const call=ast.body.find(n=>n.type==='CallStatement').expression;
 const gen=get(call.arguments[0],'Generator');mapping(get(gen,'Center'));set(get(get(gen,'Face'),'PADDUP'),'CTRL-SHIFT-',MOUNT);
});
for(const rel of ['WTF/Account/119624169#1/bindings-cache.wtf','WTF/Account/_template_/bindings-cache.wtf']) {
 const file=path.join(root,rel); const src=fs.readFileSync(file,'utf8');
 const wanted=Object.fromEntries(mods.flatMap(m=>[[m+'PADBACK',MENU],[m+'PADSYSTEM','TOGGLEWORLDMAP']]));wanted['CTRL-SHIFT-PADDUP']=MOUNT;
 let lines=src.split(/\r?\n/), seen=new Set;
 lines=lines.map(line=>{const m=line.match(/^bind (\S+) (.*)$/);if(m && wanted[m[1]]){assert(!seen.has(m[1]),'duplicate binding');seen.add(m[1]);return `bind ${m[1]} ${wanted[m[1]]}`;}return line;});
 while(lines.length && lines.at(-1)==='')lines.pop();
 for(const [k,v] of Object.entries(wanted))if(!seen.has(k))lines.push(`bind ${k} ${v}`);
 fs.writeFileSync(file,lines.join('\r\n')+'\r\n');console.log(`${rel}: nine requested combinations set`);
}
