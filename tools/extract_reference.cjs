const fs=require('fs'), path=require('path'), crypto=require('crypto');
const {parse}=require('./saved_variables.cjs');
const root=fs.realpathSync(path.resolve(__dirname,'..'));
const base='reference/config/2026-10-03-initial/Account/_template_/';
function read(file) {
  const p=fs.realpathSync(path.join(root,base,file));
  if (!p.startsWith(root+path.sep)) throw Error('Reference path escaped checkout');
  return fs.readFileSync(p,'utf8');
}
const layout=parse(read('SavedVariables/ConsolePort_Bar.lua')).ConsolePort_BarLayout;
const bindings={};
for (const line of read('bindings-cache.wtf').split(/\r?\n/)) {
  const match=/^bind (\S+) (.+)$/.exec(line);
  if (match && /(?:^|-)PAD/.test(match[1])) bindings[match[1]]=match[2]==='NONE'?'':match[2];
}
function lua(v) {
  if (v===null) return 'nil';
  if (typeof v==='string') return '"'+v.replace(/\\/g,'\\\\').replace(/"/g,'\\"').replace(/\n/g,'\\n').replace(/\r/g,'\\r')+'"';
  if (typeof v==='number' || typeof v==='boolean') return String(v);
  return '{\n'+Object.entries(v).map(([k,x])=>'['+(/^[1-9]\d*$/.test(k)?k:lua(k))+']='+lua(x)+',').join('\n')+'\n}';
}
const result={layout,bindings};
const generated='-- Generated from verified current saved data by tools/extract_reference.cjs.\n'+
  '-- Data only; runtime capture takes precedence. Temporary routing must be replaced only after proof.\n'+
  'local _, Addon = ...\nAddon.ReferenceLayout='+lua(layout)+'\nAddon.ReferenceBindings='+lua(bindings)+'\n';
fs.writeFileSync(path.join(root,'addon/ConsolePort_Forever/Reference.lua'),generated);
fs.mkdirSync(path.join(root,'evidence/reference'),{recursive:true});
fs.writeFileSync(path.join(root,'evidence/reference/current-definition.json'),JSON.stringify({
  source:base,sha256:crypto.createHash('sha256').update(generated).digest('hex'),controllerKeys:Object.keys(bindings).length,
  banks:Object.keys(layout.children)},null,2));
console.log('Extracted current layout and '+Object.keys(bindings).length+' controller bindings without execution');
