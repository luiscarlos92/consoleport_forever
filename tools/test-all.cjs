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
  if (rc !== lua.LUA_OK) {
    const message=to_jsstring(lua.lua_tostring(L,-1));
    const line=Number(message.match(/\]:(\d+):/)?.[1]);
    const context=line ? source.split('\n').slice(Math.max(0,line-3),line+2).join('\n') : '';
    throw Error(message+(context ? '\n'+context : ''));
  }
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
const modules = ['Core','Store','Plan','Transactions','BindingPolicy','ModePolicy','Rings/Discovery','Rings/Selectors','SecureModes','UI/Ownership','UI/InputBridge','UI/Windows','UI/Scroll','Adapters/BetterBags','UI/Contexts','UI/FocusVisuals','UI/Proof','Adapters/NativeBindings',
  'Adapters/BindingState','Adapters/BindingBanks','Diagnostics','Capability','Adapters/ConsolePort','Adapters/EditMode','Adapters/FlatConfig','Adapters/Integrations','Adapters/DynamicCam','Adapters/Rings','Baseline','Coordinator','Prompt'];
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
check('T18.current-native-ring-discovery', () => {
  const native=read('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua')+'\n'+read('evidence/native/Blizzard_ActionBar/Shared/PetActionBar.lua');
  const current=read('evidence/consoleport-contracts/ConsolePort_Rings/Model/Container.lua');
  execute(source+read('tests/harness/ring_discovery.lua').replace('--@NATIVE_ACTION_BARS',()=>native)
    .replace('--@CURRENT_RING_CONTAINER',()=>';(function(...)\n'+current+'\nend)("ConsolePort_Rings");'),'ring-discovery-native-source');
});
check('T18.learned-selector-preparation', () => execute(source+read('tests/harness/ring_selectors.lua'),'learned-selector-preparation'));
function ringFixture() {
  const base='evidence/consoleport-contracts/ConsolePort_Rings/';
  const database=read(base+'Database.lua');
  const secure=read(base+'Controller/Secure.lua');
  const fixture=read('tests/harness/rings.lua')
    .replace('--@NATIVE_DATABASE',()=>database.slice(database.indexOf('function env:GetData('),database.indexOf('function env:GetSetIcon(')))
    .replace('--@NATIVE_MAP', ()=>';(function(...)\n'+read(base+'Model/Map.lua')+'\nend)("ConsolePort_Rings");')
    .replace('--@NATIVE_CONTAINER', ()=>';(function(...)\n'+read(base+'Model/Container.lua')+'\nend)("ConsolePort_Rings");')
    .replace('--@NATIVE_REFRESH',()=>secure.slice(secure.indexOf('function Secure:QueueRefresh('),secure.indexOf('function Secure:ClearAllActions(')))
    .replace('--@NATIVE_AUTO',()=>';(function(...)\n'+read(base+'Controller/Auto.lua')+'\nend)("ConsolePort_Rings");');
  return fixture;
}
check('T05-T18.GUID-native-ring-projection', () => {
  const fixture=ringFixture();
  const state=execute(source+fixture+serializer+'\nSERIALIZED_STATE=serialized(SESSION_STATE)','ring-projection-native');
  require('./saved_variables.cjs').parse('SESSION_STATE='+state);
  const prelude=source+'SESSION_STATE='+state+'\n'+fixture.split('--@LIFECYCLE')[0];
  const bState=execute(prelude+`
currentGUID='B'
local desired=assert(b:Proposal())
assert(desired.sets.Auras[0].name=='B own order' and #desired.sets.Auras==1)
assert(b:write({'state'},desired))
assert(b:CaptureEdits() and account.shared.ringProjectionGUID=='B')
SESSION_STATE={account=account,live=container.Data,shared=container.Shared}
TEST_SUCCESS=true
`+serializer+'\nSERIALIZED_STATE=serialized(SESSION_STATE)','ring-new-VM-B');
  require('./saved_variables.cjs').parse('SESSION_STATE='+bState);
  execute(source+'SESSION_STATE='+bState+'\n'+fixture.split('--@LIFECYCLE')[0]+`
assert(not a:CaptureEdits(),'new VM A adopted B leftover')
local desired=assert(a:Proposal())
assert(desired.sets.Auras[0].name=='Manual class' and #desired.sets.Auras==2)
assert(a:write({'state'},desired))
assert(account.characters.B.rings.sets.Auras[0].name=='B own order')
TEST_SUCCESS=true
`,'ring-new-VM-A-return');
});
check('T07.native-binding-readiness', () => execute(source+read('tests/harness/native_bindings.lua'),'native-bindings'));
check('T09-T10.coordinator', () => execute(source+read('tests/harness/coordinator.lua'),'coordinator'));
check('T07-T09.both-binding-bank-restore', () => execute(source+read('tests/harness/binding_banks.lua'),'binding-bank-restore'));
check('T08-T10.review-details', () => execute(source+read('tests/harness/prompt.lua'),'review-details'));
check('T12-T13.adapters', () => execute(source+read('tests/harness/adapters.lua'),'adapters'));
check('T13.pinned-flat-integration-settings', () => {
  const base='evidence/integration-contracts/';
  const settingsAST=parser.parse(read(base+'Immersion/Settings.lua'),{luaVersion:'5.1',encodingMode:'x-user-defined'});
  const keys=new Set();
  function visit(value) {
    if(!value || typeof value!=='object') return;
    if(value.type==='CallExpression') {
      const name=value.base?.name;
      const index=name==='Keybind' ? 2 : 1;
      if(['Checkbox','Slider','Dropdown','Keybind'].includes(name) && value.arguments[index]?.type==='StringLiteral') keys.add(value.arguments[index].value);
    }
    for(const child of Object.values(value)) if(Array.isArray(child)) child.forEach(visit); else if(child && typeof child==='object') visit(child);
  }
  visit(settingsAST);
  if(keys.size<25) throw Error('native panel key extraction did not qualify');
  const fixture=read('tests/harness/flat_integrations.lua')
    .replace('--@NATIVE_IMMERSION_CONFIG',()=>';(function(...)\n'+read(base+'Immersion/Config.lua')+'\nend)("Immersion",nativeImmersion);')
    .replace('--@NATIVE_EXTRFADE_OPTIONS',()=>';(function(...)\n'+read(base+'Immersion_ExtraFade/options.lua')+'\nend)("Immersion_ExtraFade");');
  execute(source+'NATIVE_IMMERSION_SETTINGS_KEYS={'+[...keys].sort().map(k=>JSON.stringify(k)).join(',')+'}\n'+fixture,'flat-integrations-native-settings');
});
check('T13.current-DynamicCam-AceDB', () => {
  const base='evidence/integration-contracts/';
  const lock=JSON.parse(read('dependencies/lock.json'));
  for(const file of JSON.parse(read(base+'manifest.json')).files) {
    const package=lock.packages.find(p=>p.repo===file.repo);
    if(!package || package.sha256!==file.packageSHA256 || sha(base+file.path)!==file.sha256 || package.files[file.path]!==file.sha256) throw Error('integration contract drift: '+file.path);
  }
  const native=['LibStub/LibStub.lua','CallbackHandler-1.0/CallbackHandler-1.0.lua','AceDB-3.0/AceDB-3.0.lua']
    .map(file=>';(function()\n'+read(base+'DynamicCam/Libs/'+file)+'\nend)();').join('\n');
  const current=read(base+'DynamicCam/Core.lua');
  if(!current.includes('self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")') || !current.includes('function DynamicCam:RefreshConfig()')) throw Error('native DynamicCam lifecycle changed');
  const fixture=read('tests/harness/dynamiccam.lua').replace('--@CURRENT_ACEDB',native)
    .replace('--@CURRENT_DYNAMIC_DEFAULTS',';(function(...)\n'+read(base+'DynamicCam/DefaultSettings.lua')+'\nend)("DynamicCam");');
  const state=execute(source+serializer+fixture,'DynamicCam-native-AceDB');
  require('./saved_variables.cjs').parse('PERSISTED_STATE='+state);
  execute(source+'local PERSISTED_STATE='+state+'\n'+fixture.split('--@LIFECYCLE')[0]+`
assert(adapter:Probe() and db:GetCurrentProfile()=='CPF managed' and owned['CPF managed'].created)
local name,value=adapter:Proposal('CPF managed')
assert(name=='CPF managed' and value.nested.manual==7 and value.nested.default==9)
assert(value.situations.one.executeOnInit=='preserved script' and db.profiles.Original)
assert(refreshes==0,'persisted profile initialization refreshed or replaced the accepted data')
TEST_SUCCESS=true
`,'DynamicCam-persisted-native-AceDB');
});
check('T21.focus-visuals-proof', () => execute(source+read('tests/harness/focus_visuals.lua'),'focus-visuals-proof'));
function uiContextFixture() {
  const base='evidence/consoleport-contracts/';
  const database=read(base+'ConsolePort/Utils/Database.lua').replace(/\r\n/g,'\n');
  const begin=database.indexOf('db.table.mixin = function');
  const end=database.indexOf('return obj\nend;',begin)+'return obj\nend;'.length;
  if(begin<0 || end<begin) throw Error('native script mixin source changed');
  const handlers=read('evidence/native/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua');
  const wrapped=handlers.slice(handlers.indexOf('local function Wrapped_Click('),handlers.indexOf('local function Wrapped_OnEnter('));
  const popup=read('evidence/native/Blizzard_StaticPopup/StaticPopup.lua');
  const click=popup.slice(popup.indexOf('function StaticPopup_OnClick('),popup.indexOf('local function CallOnButton('));
  const templates=read('evidence/native/Blizzard_FrameXML/SecureTemplates.lua');
  const secureClick=templates.slice(templates.indexOf('SECURE_ACTIONS.click ='),templates.indexOf('SECURE_ACTIONS.attribute ='));
  const fixture=read('tests/harness/ui_contexts.lua').replace('--@NATIVE_WRAPPED_CLICK',wrapped)
    .replace('--@CURRENT_SCRIPT_MIXIN',database.slice(begin,end))
    .replace('--@CURRENT_INPUT','(function(...)\n'+read(base+'ConsolePort/Controller/Input.lua')+'\nend)("ConsolePort",db)')
    .replace('--@NATIVE_POPUP_CLICK',click)
    .replace('--@NATIVE_SECURE_CLICK',secureClick)
    .replace('--@NATIVE_STACK_SPLIT',read('evidence/native/Blizzard_FrameXML/Mainline/StackSplitFrame.lua'));
  return fixture;
}
check('T16-T20-T22.current-native-UI-contexts', () => execute(source+uiContextFixture(),'UI-contexts-current-source'));
function windowFixture() {
  const base='evidence/consoleport-contracts/';
  const windows=read('tests/harness/ui_windows.lua')
    .replace('--@NATIVE_STACK',()=>';(function(...)\n'+read(base+'ConsolePort_Cursor/Controller/Stack.lua')+'\nend)("ConsolePort_Cursor");')
    .replace('--@NATIVE_TABS',()=>read('evidence/native/Blizzard_SharedXML/Shared/TabSystem/TabSystemOwner.lua')+'\n'+read('evidence/native/Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.lua'));
  return uiContextFixture()+'\n'+windows;
}
check('T20.current-native-window-controls', () => execute(source+windowFixture(),'ui-windows-native-source'));
check('T21-T22.native-BetterBags-item-guards', () => {
  function nativeFunction(file,signature) {
    const text=read(file).replace(/\r\n/g,'\n');
    const start=text.indexOf('function '+signature+'(');
    const end=text.indexOf('\nend',start)+4;
    if(start<0 || end<start) throw Error('native function not found: '+signature);
    const body=text.slice(start,end);
    parser.parse(body,{luaVersion:'5.1'}); return body;
  }
  const container='evidence/native/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua';
  const base='evidence/consoleport-contracts/';
  const fixture=read('tests/harness/betterbags.lua')
    .replace('--@NATIVE_CONTAINER_METHODS',()=>['ContainerFrameItemButton_OnClick','ContainerFrameItemButtonMixin:OnClick','ContainerFrameItemButtonMixin:OnModifiedClick','ContainerFrameItemButtonMixin:GetBagID','ContainerFrameItemButtonMixin:GetSlotAndBagID'].map(name=>nativeFunction(container,name)).join('\n'))
    .replace('--@NATIVE_BETTERBAGS_ITEM',()=>';(function(...)\n'+read('evidence/integration-contracts/BetterBags/frames/item.lua')+'\nend)("BetterBags");')
    .replace('--@NATIVE_BETTERBAGS_INTEGRATION',()=>';(function(...)\n'+read('evidence/integration-contracts/BetterBags/integrations/consoleport.lua')+'\nend)("BetterBags");')
    .replace('--@NATIVE_ITEM_MENU_SET',()=>nativeFunction(base+'ConsolePort_Menu/View/Popup/ItemMenu.lua','ItemMenu:SetItem'))
    .replace('--@NATIVE_MODULE_DEMAND',()=>['Modules:IsEnabled','Modules:Demand'].map(name=>nativeFunction(base+'ConsolePort/Controller/Modules.lua',name)).join('\n'));
  execute(source+windowFixture()+'\n'+fixture,'BetterBags-native-item-contexts');
});
check('T20.native-UI-stick-scroll-ownership', () => {
  const base='evidence/consoleport-contracts/';
  const scroll=read('tests/harness/ui_scroll.lua')
    .replace('--@NATIVE_RADIAL',()=>';(function(...)\n'+read(base+'ConsolePort/Controller/Radial.lua')+'\nend)("ConsolePort",db);')
    .replace('--@NATIVE_SCROLL_CONTROLLER',()=>read('evidence/native/Blizzard_SharedXML/Shared/Scroll/ScrollController.lua'))
    .replace('--@NATIVE_SCROLL',()=>';(function(...)\n'+read(base+'ConsolePort_Cursor/Controller/Scroll.lua')+'\nend)("ConsolePort_Cursor");');
  execute(source+windowFixture()+'\n'+scroll,'UI-scroll-native-dispatcher');
});
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
  const ringPrelude=ringFixture().split('local account=')[0]
    .replace('function InCombatLockdown() return combat end','');
  const fixture=read('tests/harness/bootstrap.lua').replace('--@LOAD_PRODUCT',()=>product)
    .replace('--@NATIVE_RING_BOOTSTRAP',()=>`
local bootstrapRings,bootstrapRingEnv
do
local originalCPAPI,mainDB=CPAPI,ConsolePort:GetData()
${ringPrelude}
for key,value in pairs(originalCPAPI) do if CPAPI[key]==nil then CPAPI[key]=value end end
container.Data=SESSION_STATE and Core.Copy(SESSION_STATE.rings) or {
 [1]={{type='item',item='6948'},[0]={name='Utility'}},
 Auras={{type='spell',spell=101},[0]={name='Manual class'}}}
container.Shared=SESSION_STATE and Core.Copy(SESSION_STATE.sharedRings) or {SharedManual={[0]={name='Account ring'}}}
mainDB.Rings=container bootstrapRings=container bootstrapRingEnv=env
function LibStub(name,silent) assert(name=='RelaTable') return {ConsolePort_Bar=bar,ConsolePort_Rings=env} end
function hooksecurefunc(target,method,callback)
 local original=target[method]
 target[method]=function(...) local result=table.pack(original(...)) callback(...) return table.unpack(result,1,result.n) end
end
function container:HookScript(name,callback) assert(name=='OnHide') self.onHide=callback end
end
`);
  const state=execute(fixture+serializer+'\nSERIALIZED_STATE=serialized({installed=SESSION_STATE,restored=RESTORED_SESSION_STATE})','bootstrap');
  require('./saved_variables.cjs').parse('SESSION_STATE='+state);
  execute('SESSION_STATE=('+state+').installed\n'+fixture.split('--@LIFECYCLE')[0]+`
fire('PLAYER_LOGIN') flush()
assert(writes==0 and Addon.record.pendingReload==nil,'persisted login changed the accepted configuration')
assert(Addon:IsCharacterInstalled() and Addon.record.controllerBindings['SHIFT-PAD1']==(SESSION_STATE.banks[2]['SHIFT-PAD1'] or ''))
assert(Addon.db.transactions[Addon.record.lastInstallTransaction].reloadVerification.failures[1]==nil)
TEST_SUCCESS=true
`,'bootstrap-persisted-reload');
  execute('SESSION_STATE=('+state+').restored\n'+fixture.split('--@LIFECYCLE')[0]+`
local preserved=Addon.Core.Copy(banks)
fire('PLAYER_LOGIN') flush()
assert(Addon.record.appliedRevision==0 and not Addon.record.bindingAccepted and Addon.record.pendingReload==nil)
assert(bindingSet==1 and Addon.Core.Equal(banks,preserved),'restored reload changed native bank contents or selected set')
local journal=Addon.db.transactions[Addon.record.transactionIDs[#Addon.record.transactionIDs]]
assert(journal.status=='restored' and #journal.reloadVerification.failures==0)
TEST_SUCCESS=true
`,'bootstrap-restored-reload');
  execute(fixture.split('--@LIFECYCLE')[0]+`
bootstrapRingEnv.IsDataReady=false
bindingSet=1 fire('PLAYER_LOGIN') flush()
choose(1) flush()
while shown.name=='CPF_FIELD_REVIEW' do choose(1) flush() end
choose(1) flush()
assert(Addon:IsCharacterInstalled() and not Addon.record.ringAccepted)
choose(2)
bootstrapRingEnv.IsDataReady=true fire('ADDON_LOADED') flush()
assert(shown.name=='CPF_PLAN_REVIEW' and Addon.record.ringOfferedRevision==Addon.CONFIG_REVISION,'late optional ring readiness had no review')
local declined=shown choose(2)
fire('SPELLS_CHANGED') flush()
assert(shown==declined and not Addon.Prompt.active,'declined optional ring review repeated')
SlashCmdList.CONSOLEPORTFOREVER('update') choose(1) flush()
while shown.name=='CPF_FIELD_REVIEW' do choose(1) flush() end
choose(1) flush()
assert(Addon.record.ringAccepted and Addon.db.shared.ringProjectionGUID=='A')
choose(2)
Addon.Store.GetCharacter(Addon.db,'B')
Addon.db.shared.ringProjectionGUID='B'
bootstrapRings.Data.Auras[0].name='B current ring'
SlashCmdList.CONSOLEPORTFOREVER('update') choose(1) flush()
while shown.name=='CPF_FIELD_REVIEW' do
 if shown.text:find('personal ring contents',1,true) then choose(2) else choose(1) end
 flush()
end
choose(1) flush()
assert(not Addon.record.ringAccepted and Addon.db.shared.ringProjectionGUID=='B','Keep mine was followed by an automatic ring projection')
assert(bootstrapRings.Data.Auras[0].name=='B current ring')
assert(Addon.record.rings.sets.Auras[0].name=='Manual class','Keep mine erased the earlier GUID archive')
fire('SPELLS_CHANGED') flush()
assert(bootstrapRings.Data.Auras[0].name=='B current ring')
TEST_SUCCESS=true
`,'bootstrap-late-ring-ready-and-declined');
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
