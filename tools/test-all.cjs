// All file reads are constrained to this checkout. No Lua io/os/loadfile libs.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const cp = require('child_process');
const parser = require('luaparse');
const {lua, lauxlib, lualib, to_luastring, to_jsstring} = require('fengari');
const root = fs.realpathSync(path.resolve(__dirname, '..'));
function safe(relative) {
  const real = fs.realpathSync(path.resolve(root, relative));
  if (!real.startsWith(root + path.sep)) throw Error('outside checkout: ' + relative);
  return real;
}
function read(relative) { return fs.readFileSync(safe(relative), 'utf8'); }
function files(relative) {
  return fs.readdirSync(safe(relative), {withFileTypes:true}).flatMap(e => {
    const p = path.join(relative, e.name);
    if (e.isSymbolicLink()) throw Error('reference link: ' + p);
    return e.isDirectory() ? files(p) : [p];
  });
}
const sha = relative => crypto.createHash('sha256').update(fs.readFileSync(safe(relative))).digest('hex');
const results = [];
function check(id, fn) {
  const start = Date.now();
  try { fn(); results.push({id, status:'passed', ms:Date.now()-start}); }
  catch (e) { results.push({id, status:'failed', error:e.stack}); }
}
function execute(source, name) {
  const L = lauxlib.luaL_newstate();
  // Only base/table/string/math; runtime fixtures cannot access disk or shell.
  for (const [name, open] of [['_G',lualib.luaopen_base],['table',lualib.luaopen_table],
      ['string',lualib.luaopen_string],['math',lualib.luaopen_math]]) {
    lauxlib.luaL_requiref(L, to_luastring(name), open, 1); lua.lua_pop(L,1);
  }
  lua.lua_pushnil(L); lua.lua_setglobal(L,to_luastring('dofile'));
  lua.lua_pushnil(L); lua.lua_setglobal(L,to_luastring('loadfile'));
  const rc = lauxlib.luaL_loadbuffer(L,to_luastring(source),null,to_luastring(name)) || lua.lua_pcall(L,0,0,0);
  if (rc !== lua.LUA_OK) throw Error(to_jsstring(lua.lua_tostring(L,-1)));
  lua.lua_getglobal(L,to_luastring('TEST_SUCCESS'));
  if (!lua.lua_toboolean(L,-1)) throw Error('missing explicit success marker');
  lua.lua_getglobal(L,to_luastring('SERIALIZED_STATE'));
  return lua.lua_isstring(L,-1) ? to_jsstring(lua.lua_tostring(L,-1)) : null;
}
check('T01.snapshot', () => {
  const manifest = JSON.parse(read('reference/manifests/2026-10-03-initial.json'));
  for (const f of manifest.files) {
    // Product evolves after baseline; immutable references/fixtures must not.
    if (!f.destination.startsWith('addon/')) {
      if (sha(f.destination) !== f.sha256) throw Error('fixture drift: '+f.destination);
    }
  }
  if (manifest.links.length !== 44) throw Error('link inventory changed');
  files('reference');
});
check('T27.lua51', () => {
  for (const f of files('addon').filter(f=>f.endsWith('.lua'))) parser.parse(read(f),{luaVersion:'5.1'});
});
const modules = ['Core','Store','Plan','Transactions','BindingPolicy','ModePolicy','SecureModes','UI/Ownership','UI/FocusVisuals','UI/Proof','Adapters/NativeBindings',
  'Adapters/BindingState','Diagnostics','Capability','Adapters/ConsolePort','Adapters/EditMode','Adapters/FlatConfig','Baseline','Coordinator'];
const source = 'Addon={};\n' + modules.map(m=>
  ';(function(...)\n'+read('addon/ConsolePort_Forever/'+m+'.lua')+'\nend)("ConsolePort_Forever",Addon);\n').join('');
const serializer=`
local function serialized(value)
  if type(value)=='table' then
    local fields={}
    for key,item in pairs(value) do fields[#fields+1]='['..serialized(key)..']='..serialized(item) end
    table.sort(fields)
    return '{'..table.concat(fields,',')..'}'
  elseif type(value)=='string' then return string.format('%q',value)
  else return tostring(value) end
end
`;
check('T04-T09.foundations', () => execute(source + read('tests/harness/foundations.lua'),'foundations'));
check('T05.sequential-VM-persistence', () => {
  const serialize = `
local function serialized(value)
  if type(value)=='table' then
    local fields={}
    for key,item in pairs(value) do fields[#fields+1]='['..serialized(key)..']='..serialized(item) end
    table.sort(fields)
    return '{'..table.concat(fields,',')..'}'
  elseif type(value)=='string' then return string.format('%q',value)
  else return tostring(value) end
end
SERIALIZED_STATE=serialized(db)
TEST_SUCCESS=true
`;
  const start = `
local db={}
assert(Addon.Store.EnsureSchema(db,'A'))
Addon.Store.GetCharacter(db,'A',{class='DRUID',spec=1})
local live={}
local adapter={capture=function() return live end,project=function(_,v) live=v return true end}
assert(Addon.Store.Hydrate(db,'A',adapter,{personal='A-default'}))
live.personal='A-edit'
assert(Addon.Store.CaptureOwnedEdits(db,'A',adapter))
`;
  let state=execute(source+start+serialize,'session-A');
  // These strings originate solely from our own serializer; validate data-only
  // grammar before compiling in a fresh restricted VM.
  const validate=s=>require('./saved_variables.cjs').parse('db='+s);
  validate(state);
  const projection=`
local live={personal='leftover-A'}
local adapter={capture=function() return live end,project=function(_,v) live=v return true end}
`;
  state=execute(source+'local db='+state+'\n'+projection+`
assert(not Addon.Store.CaptureOwnedEdits(db,'B',adapter))
assert(Addon.Store.Hydrate(db,'B',adapter,{personal='B-default'}))
assert(live.personal=='B-default')
live.personal='B-edit'
assert(Addon.Store.CaptureOwnedEdits(db,'B',adapter))
`+serialize,'session-B');
  validate(state);
  execute(source+'local db='+state+'\n'+projection+`
assert(Addon.Store.Hydrate(db,'A',adapter,{}))
assert(live.personal=='A-edit' and db.characters.B.projectedView.personal=='B-edit')
assert(db.characters.A.identity.class=='DRUID' and db.characters.B.appliedRevision==0)
TEST_SUCCESS=true
`,'session-A-restored');
});
check('T06-T14-T16.policies', () => execute(source+read('tests/harness/policies.lua'),'policies'));
check('T07.native-binding-readiness', () => execute(source+read('tests/harness/native_bindings.lua'),'native-bindings'));
check('T09-T10.coordinator', () => execute(source+read('tests/harness/coordinator.lua'),'coordinator'));
check('T12-T13.adapters', () => execute(source+read('tests/harness/adapters.lua'),'adapters'));
check('T21.focus-visuals-proof', () => execute(source+read('tests/harness/focus_visuals.lua'),'focus-visuals-proof'));
check('T14.current-ConsolePort-secure-contract', () => {
  const base='evidence/consoleport-contracts/';
  const manifest=JSON.parse(read(base+'manifest.json'));
  const package=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='seblindfors/ConsolePort');
  if(manifest.version!==package.version || manifest.packageSHA256!==package.sha256) throw Error('contract package drift');
  for(const file of manifest.files) if(sha(base+file.path)!==file.sha256 || package.files[file.path]!==file.sha256) throw Error('contract source drift: '+file.path);
  const native=read(base+'ConsolePort_Bar/Widget/Button/Button.lua');
  const utils=read(base+'ConsolePort/Utils/Utils.lua');
  const lib=read(base+'ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua');
  const conversion=utils.slice(utils.indexOf('do\tlocal ConvertSecureBody'),utils.indexOf('\nend',utils.indexOf('do\tlocal ConvertSecureBody'))+4);
  const nativeLoad=native.slice(0,native.indexOf('function SlotButton:OnLoad'));
  execute(source+read('tests/harness/secure_modes.lua').replace('--@CURRENT_CP',conversion+'\n'+nativeLoad)
    .replace('--@CURRENT_LAB',lib.slice(lib.indexOf('function Generic:SetState('),lib.indexOf('function Generic:DisableDragNDrop('))),'secure-modes-current-source');
});
check('T10-T11.product-bootstrap', () => {
  const entries=read('addon/ConsolePort_Forever/ConsolePort_Forever.toc').split(/\r?\n/).filter(x=>x.trim() && !x.startsWith('#'));
  const product='Addon={};\n'+entries.map(f=>';(function(...)\n'+read('addon/ConsolePort_Forever/'+f.replace(/\\/g,'/'))+'\nend)("ConsolePort_Forever",Addon);\n').join('');
  const fixture=read('tests/harness/bootstrap.lua').replace('--@LOAD_PRODUCT',product);
  const state=execute(fixture+serializer+'\nSERIALIZED_STATE=serialized(SESSION_STATE)','bootstrap');
  require('./saved_variables.cjs').parse('SESSION_STATE='+state);
  execute('SESSION_STATE='+state+'\n'+fixture.split('--@LIFECYCLE')[0]+`
fire('PLAYER_LOGIN') flush()
assert(writes==0 and Addon.record.pendingReload==nil,'persisted login changed the accepted configuration')
assert(Addon:IsCharacterInstalled() and Addon.record.controllerBindings['SHIFT-PAD1']==(SESSION_STATE.banks[2]['SHIFT-PAD1'] or ''))
assert(Addon.db.transactions[Addon.record.lastInstallTransaction].reloadVerification.failures[1]==nil)
TEST_SUCCESS=true
`,'bootstrap-persisted-reload');
});
check('T01.data-parser', () => {
  const parse=require('./saved_variables.cjs').parse;
  for (const text of ['x=os.execute("bad")','x=(function() return 1 end)()','while true do end','x={f=CreateFrame("Frame")}']) {
    let rejected=false; try {parse(text);} catch {rejected=true;}
    if (!rejected) throw Error('accepted executable saved-variable data');
  }
  const v=parse('x={yes=false,n=-2,empty=nil,text="hello"}').x;
  if(v.yes!==false || v.n!==-2 || v.empty!==null || v.text!=='hello') throw Error('literal parse mismatch');
});
// Keep historical behavior as evidence, using copied source only. Its old
// synchronous timers are not accepted as tests of the new lifecycle.
for (const name of ['installer','runtime','skin']) {
  check('baseline.'+name, () => {
    const base = 'tests/fixtures/historical-sandbox/';
    let harness = read(base+name+'_harness.lua');
    harness = harness.replace(/assert\(loadfile\("([^"]+)"\)\)\(([^\n]+)\)/g, (_,file,args) =>
      ';(function(...)\n'+read(base+file)+'\nend)('+args+');');
    execute(harness+'\nTEST_SUCCESS=true\n','historical-'+name);
  });
}
const report = {at:new Date().toISOString(), commit:cp.execFileSync('git',['rev-parse','HEAD'],{cwd:root}).toString().trim(),
  productHashes:Object.fromEntries(files('addon').map(f=>[f,sha(f)])),
  toolingHashes:Object.fromEntries([...files('tools'),...files('tests')].filter(f=>!f.includes('__pycache__')).map(f=>[f,sha(f)])),
  pinnedDependencyLockSHA256:sha('dependencies/lock.json'),
  limitation:'Fengari uses Lua 5.3 semantics. Lua 5.1 syntax checked separately. No Retail secure/hardware proof.', results};
const {output} = require('./repository_paths.cjs');
fs.mkdirSync(output('scratch/test-results'),{recursive:true});
fs.writeFileSync(output('scratch/test-results/latest.json'),JSON.stringify(report,null,2));
for (const r of results) console.log(r.status.toUpperCase()+' '+r.id+(r.error?'\n'+r.error:''));
process.exitCode=results.some(r=>r.status==='failed')?1:0;
