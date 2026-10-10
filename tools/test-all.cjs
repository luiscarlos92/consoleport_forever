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
  console.log('RUNNING '+id);
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
  // Lua 5.1 setfenv compatibility for the unchanged Blizzard restricted compiler.
  // Kept outside restricted snippet environments; no debug library is exposed.
  lua.lua_pushcfunction(L, S => {
    lauxlib.luaL_checktype(S,1,lua.LUA_TFUNCTION);
    lauxlib.luaL_checktype(S,2,lua.LUA_TTABLE);
    for(let i=1;;i++) {
      const name=lua.lua_getupvalue(S,1,i);
      if(name===null) break;
      lua.lua_pop(S,1);
      if(to_jsstring(name)==='_ENV') {
        lua.lua_pushvalue(S,2); lua.lua_setupvalue(S,1,i); break;
      }
    }
    lua.lua_pushvalue(S,1); return 1;
  });
  lua.lua_setglobal(L,to_luastring('CPFSetFunctionEnvironment'));
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
const modules = ['Core','Store','Plan','Transactions','BindingPolicy','ModePolicy','Rings/Discovery','Rings/Selectors','ClassActions','SecureModes','TemporaryAccess','TemporaryRouting','Targeting/Registry','Targeting/Preferences','Targeting/Ground','Targeting/Ping','UI/Ownership','UI/InputBridge','UI/Windows','UI/Scroll','UI/Map','UI/PartyLayout','Cinematic','Adapters/BetterBags','UI/ItemHints','UI/Contexts','UI/FocusVisuals','UI/Proof','Adapters/NativeBindings',
  'Adapters/BindingState','Adapters/BindingBanks','Diagnostics','Capability','Adapters/ConsolePort','Adapters/EditMode','Adapters/FlatConfig','Adapters/Integrations','SavedEditModeReference','UI/ImmersionProgress','UI/EditModeReference','Adapters/LiteMount','Adapters/DynamicCam','Adapters/Rings','Baseline','Coordinator','Prompt'];
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
check('T43.Forever-class-chord-native-ring-proposal-and-rollback', () => {
  const manifest=JSON.parse(read('evidence/forever-ui/native-manifest.json'));
  for(const row of manifest) if(sha('evidence/forever-ui/native/'+row.path)!==row.sha256) throw Error('Forever source drift: '+row.path);
  execute(source+ringFixture().split('--@LIFECYCLE')[0]+read('tests/harness/class_actions.lua'),'Forever-class-chord');
});
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
    .replace('--@NATIVE_LAYER_CONVERSION',()=>{
      const utils=read(base+'ConsolePort/Utils/Utils.lua');
      const start=utils.indexOf('do\tlocal ConvertSecureBody');
      return utils.slice(start,utils.indexOf('\nend',start)+4);
    })
    .replace('--@NATIVE_UI_LAYERS',()=>';(function(...)\n'+read(base+'ConsolePort/Controller/Layers.lua')+'\nend)("ConsolePort",db);')
    .replace('--@CURRENT_SCRIPT_MIXIN',database.slice(begin,end))
    .replace('--@CURRENT_INPUT','(function(...)\n'+read(base+'ConsolePort/Controller/Input.lua')+'\nend)("ConsolePort",db)')
    .replace('--@NATIVE_POPUP_CLICK',click)
    .replace('--@NATIVE_SECURE_CLICK',secureClick)
    .replace('--@NATIVE_STACK_SPLIT',read('evidence/native/Blizzard_FrameXML/Mainline/StackSplitFrame.lua'));
  return fixture;
}
check('T16-T20-T22.current-native-UI-contexts', () => execute(source+uiContextFixture(),'UI-contexts-current-source'));
check('T41.native-combat-engine-dispatch-after-UI-ownership', () => {
  const native=read('evidence/native/Blizzard_FrameXML/SecureTemplates.lua');
  const action=native.slice(native.indexOf('SECURE_ACTIONS.action ='),native.indexOf('SECURE_ACTIONS.actionrelease ='));
  execute(source+uiContextFixture()+'\n'+read('tests/harness/combat_dispatch.lua')
    .replace('--@NATIVE_ACTION_DISPATCH',()=>action)
    .replace('--@NATIVE_CLASS_HOLD',()=>{
      const body=read('evidence/consoleport-contracts/ConsolePort_Rings/Controller/Secure.lua').match(/Hold = \[\[([\s\S]*?)\]\]/)[1];
      return 'classHold=[=['+body+']=]';
    }),'combat-engine-dispatch');
});
function windowFixture() {
  const base='evidence/consoleport-contracts/';
  const windows=read('tests/harness/ui_windows.lua')
    .replace('--@NATIVE_STACK',()=>';(function(...)\n'+read(base+'ConsolePort_Cursor/Controller/Stack.lua')+'\nend)("ConsolePort_Cursor");')
    .replace('--@NATIVE_CURSOR_REGISTRATION',()=>nativeFunction(base+'ConsolePort/API.lua','ConsolePort:RemoveInterfaceCursorFrame'))
    .replace('--@NATIVE_TABS',()=>read('evidence/native/Blizzard_SharedXML/Shared/TabSystem/TabSystemOwner.lua')+'\n'+read('evidence/native/Blizzard_SharedXML/Shared/TabSystem/TabSystemTemplates.lua'));
  return uiContextFixture()+'\n'+windows;
}
check('T20.current-native-window-controls', () => execute(source+windowFixture(),'ui-windows-native-source'));
function nativeFunction(file,signature) {
    const text=read(file).replace(/\r\n/g,'\n');
    const start=text.search(new RegExp('function '+signature.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')+'\\s*\\('));
    const end=text.indexOf('\nend',start)+4;
    if(start<0 || end<start) throw Error('native function not found: '+signature);
    const body=text.slice(start,end);
    parser.parse(body,{luaVersion:'5.1'}); return body;
}
function betterBagsFixture() {
  const container='evidence/native/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua';
  const base='evidence/consoleport-contracts/';
  const fixture=read('tests/harness/betterbags.lua')
    .replace('--@NATIVE_CONTAINER_METHODS',()=>['ContainerFrameItemButton_OnClick','ContainerFrameItemButtonMixin:OnClick','ContainerFrameItemButtonMixin:OnModifiedClick','ContainerFrameItemButtonMixin:GetBagID','ContainerFrameItemButtonMixin:GetSlotAndBagID'].map(name=>nativeFunction(container,name)).join('\n'))
    .replace('--@NATIVE_BETTERBAGS_ITEM',()=>';(function(...)\n'+read('evidence/integration-contracts/BetterBags/frames/item.lua')+'\nend)("BetterBags");')
    .replace('--@NATIVE_BETTERBAGS_INTEGRATION',()=>';(function(...)\n'+read('evidence/integration-contracts/BetterBags/integrations/consoleport.lua')+'\nend)("BetterBags");')
    .replace('--@NATIVE_ITEM_MENU_SET',()=>nativeFunction(base+'ConsolePort_Menu/View/Popup/ItemMenu.lua','ItemMenu:SetItem'))
    .replace('--@NATIVE_MODULE_DEMAND',()=>['Modules:IsEnabled','Modules:Demand'].map(name=>nativeFunction(base+'ConsolePort/Controller/Modules.lua',name)).join('\n'));
  return windowFixture()+'\n'+fixture;
}
check('T21-T22.native-BetterBags-item-guards', () => {
  execute(source+betterBagsFixture(),'BetterBags-native-item-contexts');
});
check('T35.native-merchant-container-hints', () => {
  const fixture=read('tests/harness/item_hints.lua')
    .replace('--@NATIVE_TOOLTIP_PROMPT',()=>nativeFunction('evidence/consoleport-contracts/ConsolePort/Model/Gamepad/Gamepad.lua','GamepadMixin:GetTooltipButtonPrompt'))
    .replace('--@NATIVE_MERCHANT_BUTTONS',()=>['MerchantItemButton_OnLoad','MerchantItemButton_OnClick','MerchantItemButton_OnEnter'].map(name=>nativeFunction('evidence/native/Blizzard_UIPanels_Game/Mainline/MerchantFrame.lua',name)).join('\n'));
  execute(source+betterBagsFixture()+'\n'+fixture,'native-merchant-container-hints');
});
function scrollFixture() {
  const base='evidence/consoleport-contracts/';
  const scroll=read('tests/harness/ui_scroll.lua')
    .replace('--@NATIVE_RADIAL',()=>';(function(...)\n'+read(base+'ConsolePort/Controller/Radial.lua')+'\nend)("ConsolePort",db);')
    .replace('--@NATIVE_SCROLL_CONTROLLER',()=>read('evidence/native/Blizzard_SharedXML/Shared/Scroll/ScrollController.lua'))
    .replace('--@NATIVE_SCROLL',()=>';(function(...)\n'+read(base+'ConsolePort_Cursor/Controller/Scroll.lua')+'\nend)("ConsolePort_Cursor");');
  return windowFixture()+'\n'+scroll;
}
check('T20.native-UI-stick-scroll-ownership', () => {
  execute(source+scrollFixture(),'UI-scroll-native-dispatcher');
});
check('T21.native-map-canvas-controls', () => {
  const base='evidence/native/';
  const fixture=read('tests/harness/map.lua')
    .replace('--@NATIVE_MAP_CANVAS',()=>read(base+'Blizzard_MapCanvas/Blizzard_MapCanvas.lua'))
    .replace('--@NATIVE_MAP_SCROLL',()=>read(base+'Blizzard_MapCanvas/MapCanvas_ScrollContainerMixin.lua'))
    .replace('--@NATIVE_QUEST_OWNER',()=>read(base+'Blizzard_WorldMap/QuestLogOwnerMixin.lua'))
    .replace('--@NATIVE_QUEST_BACK',()=>['QuestMapFrame_CloseQuestDetails','QuestMapFrame_ReturnFromQuestDetails'].map(name=>nativeFunction(base+'Blizzard_UIPanels_Game/Mainline/QuestMapFrame.lua',name)).join('\n'))
    .replace('--@NATIVE_MAP_MAXIMIZED',()=>nativeFunction(base+'Blizzard_WorldMap/Blizzard_WorldMap.lua','WorldMapMixin:IsMaximized'))
    .replace('--@NATIVE_WAYPOINT',()=>read(base+'Blizzard_SharedMapDataProviders/WaypointLocationDataProvider.lua'));
  execute(source+scrollFixture()+'\n'+fixture,'map-native-canvas');
});
function presentationFixture() {
  if (!read('evidence/native/Blizzard_APIDocumentationGenerated/EventUtilsDocumentation.lua').includes('Name = "IsEventValid"')) throw Error('skin event validation lacks pinned native API evidence');
  const masque='reference/installed-addons/2026-10-03-initial/Masque/Core/Group.lua';
  const package=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='SFX-WoW/Masque');
  if(sha(masque)!==package.files['Masque/Core/Group.lua']) throw Error('Masque reference differs from current audited package');
  const group='evidence/consoleport-contracts/ConsolePort_Bar/Widget/Group/Group.lua';
  const fixture=read('tests/harness/presentation.lua')
    .replace('--@NATIVE_MASQUE_NORMAL',()=>{
      const file=package.unpacked+'/Masque/Core/Regions/Normal.lua';
      if(sha(file)!==package.files['Masque/Core/Regions/Normal.lua']) throw Error('Native Masque normal source drift');
      return ['Update_Normal','Hook_SetNormal','Core.Skin_Normal'].map(name=>nativeFunction(file,name)).join('\n');
    })
    .replace('--@NATIVE_MASQUE_REMOVE',()=>nativeFunction(masque,'GMT:RemoveButton'))
    .replace('--@NATIVE_GROUP_SKIN_LIFECYCLE',()=>['CPGroupBar:UpdateButtons','CPGroupBar:OnMasqueLoaded'].map(name=>nativeFunction(group,name)).join('\n'))
    .replace('--@NATIVE_MANAGER_BINDINGS',()=>nativeFunction('evidence/consoleport-contracts/ConsolePort_Bar/Controller/Manager/Manager.lua','Manager:GetBindings'))
    .replace('--@NATIVE_AVAILABILITY',()=>['UpdateUsable','SpellVFX_CastingAnim_OnHide'].map(name=>nativeFunction('evidence/consoleport-contracts/ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua',name)).join('\n'))
    .replace('--@NATIVE_UNBOUND_GLYPH',()=>['ResetGlyphTexture','ProxyButtonTextureProvider'].map(name=>nativeFunction('evidence/consoleport-contracts/ConsolePort_Bar/Widget/Button/Button.lua',name)).join('\n'))
    .replace('--@PRODUCT_SKIN',()=>['HUDPresentation','Skin'].map(name=>';(function(...)\n'+read('addon/ConsolePort_Forever/'+name+'.lua')+'\nend)("ConsolePort_Forever",Addon);').join('\n'));
  return fixture;
}
check('T24.current-native-presentation-lifecycle', () => {
  const fixture=presentationFixture();
  execute(source+fixture,'current-native-presentation');
  // A negative control must fail with the original unretired Masque region.
  let reproduced=false;
  try {
    execute(source+fixture.replace("fire('PLAYER_ENTERING_WORLD') flush()", "Addon.HUDPresentation.RetireMasqueNormal=function() end\nfire('PLAYER_ENTERING_WORLD') flush()"),'unretired-Masque-square');
  } catch(error) { reproduced=String(error).includes('Masque private square normal remains visible'); }
  if(!reproduced) throw Error('Private square overlay regression was not reproduced');
});
function geometryFixture() {
  const template=JSON.parse(read('evidence/forever-ui/retail-button-template.json'));
  if(sha('evidence/forever-ui/retail-button-template.xml')!==template.sha256 || !read('evidence/forever-ui/retail-button-template.xml').includes('<Size x="45" y="45"/>')) throw Error('Native button dimensions unqualified');
  const cp=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='seblindfors/ConsolePort');
  if(sha(cp.unpacked+'/ConsolePort/Libs/External/ConsolePortNode/ConsolePortNode.lua')!==cp.files['ConsolePort/Libs/External/ConsolePortNode/ConsolePortNode.lua']) throw Error('Native rectangle contract drift');
  const fixture=read('tests/harness/hud_geometry.lua')
    .replace('--@PRODUCT_HUD',()=>';(function(...)\n'+read('addon/ConsolePort_Forever/HUDPresentation.lua')+'\nend)("ConsolePort_Forever",Addon);')
    .replace('--@NATIVE_SCALED_RECT',()=>nativeFunction(cp.unpacked+'/ConsolePort/Libs/External/ConsolePortNode/ConsolePortNode.lua','GetHitRectScaled'))
    .replace('--@NATIVE_GROUP_FACTORY',()=>{
      const group=read(cp.unpacked+'/ConsolePort_Bar/Widget/Group/Group.lua');
      return group.slice(group.indexOf('env:AddFactory(GROUP,'),group.indexOf('env:AddFactory(GROUP_BUTTON,'));
    });
  return fixture;
}
check('T45.HUD-collision-screen-bounds-and-scale-transitions', () => execute(source+geometryFixture(),'HUD-physical-rectangles'));
check('T50.trigger-hints-stationary-across-selection', () => {
  const fixture=geometryFixture()+read('tests/harness/stationary_hints.lua');
  execute(source+fixture,'stationary-trigger-hints');
  let reproduced=false;
  try { execute(source+fixture.replace("anchor:SetPoint('BOTTOM',UIParent,", "anchor:SetPoint('BOTTOM',bank:GetParent(),"),'unanchored-manager-hints'); }
  catch(error) { reproduced=String(error).includes('no clear placement'); }
  if(!reproduced) throw Error('candidate15 unanchored manager failure was not reproduced');
});
check('T51.class-badge-side-and-continuous-bank-opacity', () => execute(source+geometryFixture()+read('tests/harness/class_badge_side.lua'),'class-badge-side-opacity'));
check('T52.visual-observations-retained-without-secret-values', () => execute(source+presentationFixture()+read('tests/harness/visual_snapshot.lua'),'visual-evidence-snapshot'));

check('T46.native-aura-bar-complete-ring-access-and-editor-release', () => {
  const fixture=read('tests/harness/class_bar.lua').replace('--@NATIVE_STANCE_VISIBILITY',()=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua','StanceBarMixin:ShouldShow'));
  execute(source+fixture,'native-class-bar');
});
check('T13.native-LiteMount-binding-icons', () => {
  const file='evidence/consoleport-contracts/ConsolePort/Model/Game/Bindings.lua';
  const fixture=read('tests/harness/litemount.lua').replace('--@NATIVE_BINDING_ICON_METHODS',()=>['Bindings:GetIcon','Bindings:SetIcon'].map(name=>nativeFunction(file,name)).join('\n'));
  for(const version of ['12.1.0-1','12.1.0-2']) execute(source+fixture.replace("local version='12.1.0-1'","local version='"+version+"'"),'native-LiteMount-icons-'+version);
});
check('T23.native-cinematic-held-skip-gate', () => {
  const base='evidence/native/Blizzard_FrameXML/';
  const xml=read(base+'Shared/CinematicFrame.xml');
  if(!xml.includes('<OnGamePadButtonDown function="CinematicFrame_OnKeyDown"/>')) throw Error('native gamepad cinematic key route drift');
  if(!read(base+'MovieFrame.xml').includes('method="OnKeyUp"')) throw Error('native movie key-up route drift');
  const fixture=read('tests/harness/cinematic.lua')
    .replace('--@NATIVE_CINEMATIC_KEYS',()=>['CinematicFrame_OnKeyDown','CinematicFrame_CancelCinematic'].map(name=>nativeFunction(base+'Shared/CinematicFrame.lua',name)).join('\n'))
    .replace('--@NATIVE_MOVIE',()=>read(base+'MovieFrame.lua'));
  execute(source+scrollFixture()+'\n'+fixture,'cinematic-native-eligibility-gate');
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
function groundTargetingFixture() {
  const base='evidence/consoleport-contracts/';
  const native=read(base+'ConsolePort_Bar/Widget/Button/Button.lua');
  const utils=read(base+'ConsolePort/Utils/Utils.lua');
  const conversion=utils.slice(utils.indexOf('do\tlocal ConvertSecureBody'),utils.indexOf('\nend',utils.indexOf('do\tlocal ConvertSecureBody'))+4);
  const handlers=read('evidence/native/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua');
  const templates=read('evidence/native/Blizzard_FrameXML/SecureTemplates.lua');
  const lib=read(base+'ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua');
  const start=lib.indexOf('button.header:WrapScript(button, "OnClick", [[');
  const end=lib.indexOf('\nend',start);
  if(start<0 || end<start) throw Error('native LAB click contract not found');
  const lab='local function installLABClick(button)\n'+lib.slice(start,end)+'\nend';
  const restricted=read('evidence/native/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua');
  for(const name of ['GetActionInfo','IsPressHoldReleaseSpell','IsModifiedClick','IsShiftKeyDown','IsControlKeyDown','IsAltKeyDown','GetVehicleBarIndex','GetOverrideBarIndex','GetTempShapeshiftBarIndex']) {
    if(!restricted.includes(name)) throw Error('ground snippet API unavailable: '+name);
  }
  const execution=read('evidence/native/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua');
  const environment=execution.slice(execution.indexOf('local function CreateRestrictedEnvironment('),execution.indexOf('\nend',execution.indexOf('local function CreateRestrictedEnvironment('))+4);
  const fixture=read('tests/harness/ground_targeting.lua')
    .replace('--@NATIVE_RESTRICTED_ENV',()=>environment)
    .replace('--@NATIVE_HANDLE_ACCESS',()=>{
      const frames=read('evidence/native/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua');
      const end=frames.indexOf('function HANDLE:IsVisible(');
      return frames.slice(frames.indexOf('local function GetPossiblyForbiddenHandleFrame('),frames.indexOf('function HANDLE:IsShown(')).split('---------------------------------------------------------------------------')[0]+'\n'+frames.slice(frames.indexOf('function HANDLE:IsShown('),end);
    })
    .replace('--@CURRENT_CP',conversion+'\n'+native.slice(0,native.indexOf('function SlotButton:OnLoad')))
    .replace('--@NATIVE_MODIFIED_ATTRIBUTES',templates.slice(0,templates.indexOf('function SecureButton_GetUnit(')))
    .replace('--@NATIVE_SECURE_ACTIONS',()=>templates.slice(templates.indexOf('SECURE_ACTIONS.action ='),templates.indexOf('SECURE_ACTIONS.pet ='))+'\n'
      +templates.slice(templates.indexOf('SECURE_ACTIONS.macro ='),templates.indexOf('local CANCELABLE_ITEMS')))
    .replace('--@NATIVE_SECURE_DISPATCH',templates.slice(templates.indexOf('local PRESS_TYPE_DOWN'),templates.indexOf('function SecureUnitButton_OnLoad')))
    .replace('--@NATIVE_WRAPPED_CLICK',handlers.slice(handlers.indexOf('local function Wrapped_Click('),handlers.indexOf('local function Wrapped_OnEnter(')))
    .replace('--@NATIVE_MANAGER_REROUTE',()=>nativeFunction(base+'ConsolePort_Bar/Controller/Manager/Manager.lua','Manager:RegisterReroute'))
    .replace('--@NATIVE_LAB_CLICK_FACTORY',lab);
  return fixture;
}
check('T12.current-native-ground-targeting', () => {
  execute(source+'\n;(function(...)\n'+read('addon/ConsolePort_Forever/RuntimeSetup.lua')+'\nend)("ConsolePort_Forever",Addon);\n'+groundTargetingFixture(),'ground-targeting-current-native-source');
  const registry=read('addon/ConsolePort_Forever/Targeting/Registry.lua');
  const evidence=JSON.parse(read('evidence/targeting/ground-spells.json'));
  const ids=[...registry.matchAll(/\[(\d+)\]=/g)].map(m=>Number(m[1])).sort((a,b)=>a-b);
  if(JSON.stringify(ids)!==JSON.stringify(evidence.spells.map(s=>s.id).sort((a,b)=>a-b))) throw Error('ground registry qualification drift');
  for(const spell of evidence.spells) if(!spell.source || !spell.qualification) throw Error('unqualified ground spell '+spell.id);
});
check('T42.native-targeting-combat-bindings-full-dispatch', () => {
  const prelude=groundTargetingFixture().split('assert(Addon.SecureModes.Install(bridge,api))')[0];
  const manager=read('evidence/consoleport-contracts/ConsolePort_Bar/Controller/Manager/Manager.lua');
  const utils=read('evidence/consoleport-contracts/ConsolePort/Utils/Utils.lua');
  const parseStart=utils.indexOf('Parse = function(self, body, args)');
  const adapter=read('tests/harness/targeting_engine.lua')
    .replace('--@NATIVE_MANAGER_ENV',manager.slice(manager.indexOf('Manager.Env = {'),manager.indexOf('\n};')+4))
    .replace('--@NATIVE_MANAGER_REGISTER',()=>nativeFunction('evidence/consoleport-contracts/ConsolePort_Bar/Controller/Manager/Manager.lua','Manager:RegisterOverride'))
    .replace('--@NATIVE_MANAGER_PARSE','local native'+utils.slice(parseStart,utils.indexOf('\n\tend;',parseStart)+6));
  const gameplay=read('tests/harness/native_targeting_dispatch.lua');
  execute(source+uiContextFixture()+'\n'+adapter+'\nlocal scenario='+JSON.stringify(prelude+'\n'+gameplay)+'\nlocal scope=setmetatable({},{__index=_G}); scope._G=scope; scope.engine=targetingEngine; scope.Addon=Addon; assert(load(scenario,"native-targeting-dispatch","t",scope))(); TEST_SUCCESS=scope.TEST_SUCCESS;','native-targeting-full-dispatch');
});
check('T44.Forever-original-art-region-provenance', () => {
  const evidence=JSON.parse(read('evidence/forever-ui/sprite-regions.json'));
  if(sha('addon/ConsolePort_Forever/Assets/ForeverInGame.blp')!==evidence.assetSHA256) throw Error('Original Blizzard artwork changed');
  const hud=read('addon/ConsolePort_Forever/HUDPresentation.lua');
  const block=hud.slice(hud.indexOf('local SPRITES={'),hud.indexOf('HUD.Sprites=SPRITES'));
  const actual={};
  for(const match of block.matchAll(/(?:\['([^']+)'\]|(\w+))=\{(\d+),(\d+),(\d+),(\d+)\}/g)) actual[match[1]||match[2]]=match.slice(3).map(Number);
  if(Object.keys(actual).length!==Object.keys(evidence.regions).length) throw Error('Missing original sprite region');
  for(const [name,record] of Object.entries(evidence.regions)) {
    if(JSON.stringify(actual[name])!==JSON.stringify(record.pixels)) throw Error('Wrong Blizzard sprite coordinates: '+name);
  }
  const lock=JSON.parse(read('dependencies/lock.json'));
  const current=lock.packages.find(p=>p.repo==='seblindfors/ConsolePort');
  const cursor=read(current.unpacked+'/ConsolePort_Cursor/View/Cursor.xml');
  if(!cursor.includes('<Button name="ConsolePortCursor" hidden="true" frameStrata="TOOLTIP" frameLevel="10000">')) throw Error('Unprotected native cursor contract changed');
  if(read(current.unpacked+'/ConsolePort_Cursor/View/Cursor.lua').includes('SetProtected')) throw Error('Native cursor protection changed');
});
check('T36.native-party-layout-default', () => {
  const base='evidence/native/';
  for(const [file,index] of [['Blizzard_UnitFrame/Shared/PartyFrame.xml','Party'],['Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameContainer.xml','Raid']]) {
    const xml=read(base+file);
    if(!xml.includes('EditModeUnitFrameSystemTemplate') || !xml.includes('value="Enum.EditModeUnitFrameSystemIndices.'+index+'"')) throw Error('native Party/Raid XML contract changed');
  }
  if(!read(base+'Blizzard_EditMode/Shared/EditModeSystemTemplates.xml').includes('value="Enum.EditModeSystem.UnitFrame"')) throw Error('native UnitFrame system inheritance changed');
  const fixture=read('tests/harness/party_layout.lua')
    .replace('--@NATIVE_ANCHOR',()=>nativeFunction(base+'Blizzard_EditMode/Shared/EditModeSystemTemplates.lua','EditModeSystemMixin:ApplySystemAnchor'))
    .replace('--@NATIVE_PARTY_ORIENTATION',()=>nativeFunction(base+'Blizzard_EditMode/Shared/EditModeManager.lua','EditModeManagerFrameMixin:ShouldRaidFrameUseHorizontalRaidGroups'))
    .replace('--@NATIVE_COMPACT_GENERATE',()=>nativeFunction(base+'Blizzard_UnitFrame/Shared/CompactPartyFrame.lua','CompactPartyFrame_Generate'));
  execute(source+serializer+'\n;(function(...)\n'+read('addon/ConsolePort_Forever/RuntimeSetup.lua')+'\nend)("ConsolePort_Forever",Addon);\n'+fixture,'native-party-layout-default');
});
check('T38.account-targeting-native-config-panel', () => {
  const native=read('evidence/consoleport-contracts/ConsolePort_Config/View/Config/Config.lua');
  const lifecycle=native.slice(native.indexOf('local Panel ='),native.indexOf('local Canvas ='))+'\n'
    +native.slice(native.indexOf('do  local panelIDGen'));
  const fixture=read('tests/harness/targeting_preferences.lua')
    .replace('--@NATIVE_PANEL_LIFECYCLE',()=>lifecycle)
    .replace('--@PRODUCT_TARGETING_UI',()=>';(function(...)\n'+read('addon/ConsolePort_Forever/UI/Targeting.lua')+'\nend)("ConsolePort_Forever",Addon);');
  execute(source+fixture,'account-targeting-native-panel');
});
check('T39.ConsolePort-3.3.10-layout-compatibility', () => {
  const base='evidence/consoleport-contracts/';
  const pet=read(base+'ConsolePort_Bar/View/Pet/Petring.lua');
  const fixture=read('tests/harness/cp_3310.lua')
    .replace('--@NATIVE_DATA_TABLE',()=>['Table:Get','Table:Set'].map(name=>nativeFunction(base+'ConsolePort/Model/Data/Data.lua',name)).join('\n'))
    .replace('--@NATIVE_BUILD_LAYOUT',()=>nativeFunction(base+'ConsolePort_Bar/Model/Upgrade.lua','env.BuildLayout'))
    .replace('--@NATIVE_RENAME',()=>nativeFunction(base+'ConsolePort_Bar/View/Config/Loadout.lua','Loadout:OnRename'))
    .replace('--@NATIVE_PET_FACTORY',()=>pet.slice(pet.indexOf("env:AddFactory('Petring'")));
  execute(source+fixture,'ConsolePort-3.3.10-current-layout-source');
  const iface=read(base+'ConsolePort_Bar/Model/Interface.lua');
  if(!iface.includes('Petring = false;') || !iface.includes('pos = _(Type.ComplexPoint') || !iface.includes('level    = 1;')) throw Error('current interface definitions changed');
});
let bootstrapState,bootstrapPrelude;
check('T10-T11.product-bootstrap', () => {
  // Hardware Binding XML is exercised separately by T60; only Lua belongs in
  // the bootstrap VM's ordered module compilation.
  const entries=read('addon/ConsolePort_Forever/ConsolePort_Forever.toc').split(/\r?\n/).filter(x=>x.trim() && !x.startsWith('#') && x.endsWith('.lua'));
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
  bootstrapState=state; bootstrapPrelude=fixture.split('--@LIFECYCLE')[0];
  execute('SESSION_STATE=('+state+').installed\n'+fixture.split('--@LIFECYCLE')[0]+`
fire('PLAYER_LOGIN') flush()
assert(writes==0 and Addon.record.pendingReload==nil,'persisted login changed the accepted configuration')
assert(Addon:IsCharacterInstalled() and Addon.record.controllerBindings['SHIFT-PAD1']==(SESSION_STATE.banks[2]['SHIFT-PAD1'] or ''))
assert(Addon.db.transactions[Addon.record.lastInstallTransaction].reloadVerification.failures[1]==nil)
TEST_SUCCESS=true
`,'bootstrap-persisted-reload');
  for(const playerClass of ['WARRIOR','DRUID','PALADIN']) for(const previousRevision of [14,15,16]) execute('SESSION_STATE=('+state+').installed\n'+fixture.split('--@LIFECYCLE')[0]+`
function UnitClass() return '${playerClass}','${playerClass}' end
local chosenChord=Addon.ClassActions.Chord(_G)
local record=ConsolePortForeverDB.characters.A
record.appliedRevision=${previousRevision} record.pendingReload=nil record.declinedRevision=nil
record.controllerBindings['CTRL-PADRSHOULDER']=''
record.controllerBindings['SHIFT-PADLSHOULDER']=''
banks[2]['CTRL-PADRSHOULDER']=nil
banks[2]['SHIFT-PADLSHOULDER']=nil
local oppositeChord=chosenChord==Addon.ClassActions.CHORD and Addon.ClassActions.LEFT_CHORD or Addon.ClassActions.CHORD
if ${previousRevision}==15 then banks[2][oppositeChord]='CLICK NativeUtility:Auras' end
banks[2]['CTRL-PADFORWARD']='CLICK NativeUtility:Auras'
local before=Addon.Core.Copy(banks)
fire('PLAYER_LOGIN') flush()
assert(Addon.record.appliedRevision==17 and banks[2][chosenChord]=='CLICK NativeUtility:Auras','first login did not apply actual class binding')
assert((banks[2][oppositeChord] or '')=='','duplicate opposite-side class binding remains')
assert((banks[2]['CTRL-PADFORWARD'] or '')=='' and banks[2].SPACE=='JUMP','first login retained old menu or lost keyboard binding')
assert(shown==nil,'authorized class migration asked for another review')
local journal=Addon.db.transactions[Addon.record.lastInstallTransaction]
assert(journal.context.foreverClassMigration and journal.status=='committed' and journal.bindingDetails.saved)
assert(journal.steps[1].before.keys['CTRL-PADFORWARD']=='CLICK NativeUtility:Auras','class migration omitted independent backup')
local count,writesBefore=Addon.db.nextTransactionID,writes
fire('PLAYER_ENTERING_WORLD') flush()
assert(Addon.db.nextTransactionID==count and writes==writesBefore,'repeat login reapplied class migration')
Addon:Restore('') choose(1) flush()
while shown.name=='CPF_FIELD_REVIEW' do choose(1) flush() end
choose(1) flush()
assert(Addon.Core.Equal(banks,before),'native restore did not recover the pre-migration binding bank')
TEST_SUCCESS=true
`,'bootstrap-first-login-authorized-class-binding-migration-'+playerClass);
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
function visibilityFixture() {
  const file='evidence/native/Blizzard_ActionBar/Shared/ActionBar.lua';
  const names=['SetupVisibilityFunctionOverrides','EditModeActionBar_OnEvent','IsShownOverride','SetShownOverride','ShowOverride','HideOverride','UpdateVisibility'];
  const fixture=read('tests/harness/visibility.lua')
    .replace('--@NATIVE_BAR_METHODS',()=>names.map(name=>nativeFunction(file,'EditModeActionBarMixin:'+name)).join('\n'))
    .replace('--@NATIVE_EXTRA_ACTION',()=>read('evidence/native/Blizzard_ActionBar/Shared/ExtraActionBar.lua'))
    .replace('--@RUNTIME_VISIBILITY',()=>';(function(...)\n'+read('addon/ConsolePort_Forever/Runtime.lua')+'\nend)("ConsolePort_Forever",Addon);');
  return fixture;
}
check('T31.native-visibility-parent-lifecycle', () => execute(visibilityFixture(),'native-visibility-parent-lifecycle'));
check('T40.hidden-controls-native-ring-and-seat-access', () => {
  const fixture=read('tests/harness/hidden_access.lua')
    .replace('--@NATIVE_LIBSTUB',()=>normalized('evidence/consoleport-contracts/ConsolePort/Libs/External/LibStub/LibStub.lua'))
    .replace('--@NATIVE_RING_MAP',()=>read('evidence/consoleport-contracts/ConsolePort_Rings/Model/Map.lua'))
    .replace('--@NATIVE_STANCE_VISIBILITY',()=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua','StanceBarMixin:ShouldShow'))
    .replace('--@NATIVE_SEAT_VISIBILITY',()=>nativeFunction('evidence/native/Blizzard_UIPanels_Game/Shared/VehicleSeatIndicator.lua','VehicleSeatIndicatorMixin:UpdateShownState'))
    .replace('--@HIDDEN_ACCESS',()=>';(function(...)\n'+read('addon/ConsolePort_Forever/UI/HiddenAccess.lua')+'\nend)("ConsolePort_Forever",Addon);')
    .replace('--@VISIBILITY',()=>';(function(...)\n'+read('addon/ConsolePort_Forever/Runtime.lua')+'\nend)("ConsolePort_Forever",Addon);');
  execute(source+fixture,'hidden-controls-native-ring-and-seat-access');
});
check('T32.current-ConsolePort-upgrade-contracts', () => {
  const base='evidence/consoleport-contracts/';
  const utils=read(base+'ConsolePort/Utils/Utils.lua');
  const conversion=utils.slice(utils.indexOf('do\tlocal ConvertSecureBody'),utils.indexOf('\nend',utils.indexOf('do\tlocal ConvertSecureBody'))+4);
  const modules=read(base+'ConsolePort/Controller/Modules.lua');
  const keyboard=read(base+'ConsolePort_Keyboard/View/Keyboard.lua');
  const fixture=read('tests/harness/cp_upgrade.lua')
    .replace('--@NATIVE_CONVERSION',()=>conversion)
    .replace('--@NATIVE_MACRO',()=>read(base+'ConsolePort/Utils/Macro.lua').slice(0,read(base+'ConsolePort/Utils/Macro.lua').indexOf('function CPAPI.ModComplement')))
    .replace('--@NATIVE_LAYERS',()=>';(function(...)\n'+read(base+'ConsolePort/Controller/Layers.lua')+'\nend)("ConsolePort",db);')
    .replace('--@NATIVE_MODULE_MIGRATION',()=>modules.slice(modules.indexOf('Modules.Deprecated ='),modules.indexOf('function Modules:OnDataLoaded')))
    .replace('--@NATIVE_KEYBOARD_MIGRATION',()=>keyboard.slice(keyboard.indexOf('local BUTTON_CONVENTION_VERSION'),keyboard.indexOf('function Keyboard:OnDataLoaded')))
    .replace('--@NATIVE_CLEAR_BLOCKED',()=>nativeFunction(base+'ConsolePort/Model/Gamepad/Gamepad.lua','GamepadAPI:ClearBlockedBindings'));
  execute(fixture,'native-ConsolePort-upgrade');
});
check('T33.current-native-shared-bar-layout', () => {
  const file='evidence/consoleport-contracts/ConsolePort_Bar/Model/Utils.lua';
  const body=read(file);
  const start=body.indexOf('do -- Data handler');
  const end=body.indexOf('end -- Data handler',start)+'end -- Data handler'.length;
  if(start<0 || end<start) throw Error('native bar data-source contract changed');
  const fixture=read('tests/harness/cp_shared_layout.lua')
    .replace('--@NATIVE_BAR_DATA',()=>body.slice(start,end))
    .replace('--@NATIVE_APPLY_PRESET',()=>nativeFunction(file,'env:ApplyPreset'));
  execute(source+fixture,'native-shared-bar-layout');
});
check('T34.current-native-EditMode-hover-safety', () => {
  const body=read('evidence/consoleport-contracts/ConsolePort_Cursor/Controller/Scripts.lua');
  const start=body.indexOf("_('Blizzard_EditMode', function()");
  const end=body.indexOf("_('Blizzard_DelvesCompanionConfiguration'",start);
  if(start<0 || end<start) throw Error('native Edit Mode hover contract changed');
  execute(read('tests/harness/cp_editmode_hover.lua')
    .replace('--@NATIVE_EDITMODE_HOVERS',()=>body.slice(start,end)),'native-EditMode-hover-safety');
});
check('T01.data-parser', () => {
  const parse=require('./saved_variables.cjs').parse;
  for (const text of ['x=os.execute("bad")','x=(function() return 1 end)()','while true do end','x={f=CreateFrame("Frame")}']) {
    let rejected=false; try {parse(text);} catch {rejected=true;}
    if (!rejected) throw Error('accepted executable saved-variable data');
  }
  const v=parse('x={yes=false,n=-2,empty=nil,text="hello"}').x;
  if(v.yes!==false || v.n!==-2 || v.empty!==null || v.text!=='hello') throw Error('literal parse mismatch');
  const unicode=parse('x={["Fëanturï - Proudmoore"]="Lóriën",escaped="\\195\\171"}').x;
  if(unicode['Fëanturï - Proudmoore']!=='Lóriën' || unicode.escaped!=='ë') throw Error('UTF-8 saved names or byte escapes were corrupted');
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
check('T47.missing-class-badge-binding-first-login-repair', () => {
  if(!bootstrapState) throw Error('native bootstrap qualification unavailable');
  execute('SESSION_STATE=('+bootstrapState+').installed\n'+bootstrapPrelude+read('tests/harness/class_binding_repair.lua'),'missing-class-opener-repair');
});
check('T48.duplicate-aura-row-native-show-refresh', () => {
  const fixture=read('tests/harness/class_bar.lua').replace('--@NATIVE_STANCE_VISIBILITY',()=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua','StanceBarMixin:ShouldShow'));
  execute(source+fixture+read('tests/harness/aura_row_refresh.lua').replace('--@NATIVE_STANCE_UPDATE',()=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua','StanceBarMixin:Update')),'native-aura-row-refresh');
});
check('T49.ready-round-spells-combat-colour-and-opacity', () => {
  const cp=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='seblindfors/ConsolePort');
  const line=read(cp.unpacked+'/ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua').split(/\r?\n/).find(s=>s.startsWith('Action.IsUsable '));
  if(!line) throw Error('native action usability contract missing');
  const fixture=presentationFixture()+read('tests/harness/combat_colours.lua').replace('--@NATIVE_ACTION_USABILITY',()=>line);
  execute(source+fixture,'combat-round-colour-regression');
  let reproduced=false;
  try { execute(source+fixture.replace('local function PaintAvailability(button,refreshUsable)','local function PaintAvailability(button,refreshUsable) refreshUsable=false'),'stale-ready-round-tint'); }
  catch(error) { reproduced=String(error).includes('ready round combat spell remains grey'); }
  if(!reproduced) throw Error('ready spell grey tint negative control did not fail');
});
check('T53.ready-round-face-native-background-composition', () => {
  const pkg=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='SFX-WoW/Masque');
  const icon=pkg.unpacked+'/Masque/Core/Regions/Icon.lua',art=pkg.unpacked+'/Masque/Core/Button.lua';
  if(sha(icon)!==pkg.files['Masque/Core/Regions/Icon.lua'] || sha(art)!==pkg.files['Masque/Core/Button.lua']) throw Error('Native composition source drift');
  const xml=read('evidence/forever-ui/retail-button-template.xml');
  const layer=xml.match(/<Layer level="BACKGROUND">([\s\S]*?)<\/Layer>/)[1];
  const iconPos=layer.indexOf('parentKey="icon"'),bgPos=layer.indexOf('parentKey="SlotBackground"');
  if(iconPos<0 || bgPos<=iconPos) throw Error('Native template declaration order changed');
  const fixture=read('tests/harness/face_composition.lua')
    .replace('--@NATIVE_MASQUE_ICON',()=>nativeFunction(icon,'Core.Skin_Icon'))
    .replace('--@NATIVE_MASQUE_ART',()=>nativeFunction(art,'UpdateButtonArt'))
    .replace('--@NATIVE_TEMPLATE_ORDER',()=>`local NATIVE_ICON_ORDER,NATIVE_BACKGROUND_ORDER=${iconPos},${bgPos}`);
  const observations=JSON.parse(read('evidence/forever-ui/candidate16-ready-face-observations.json'));
  if(!observations.observedReadyFaces.length || observations.observedReadyFaces.some(r=>r.desaturation!==0 || r.iconAlpha!==1 || r.colour.some(v=>v!==1))) throw Error('Expected actual white-ready-icon evidence absent');
  const joined=presentationFixture()+fixture;
  execute(source+joined,'native-round-face-composition');
  const old=joined
    .replace('function HUD.FaceLayers(button)','function HUD.FaceLayers(button) return end\nfunction HUD.DisabledFaceLayers(button)')
    .replace("bg bg:SetDrawLayer('BACKGROUND',-1) bg:SetColorTexture",'bg bg:SetColorTexture')
    .replace('if button.__cpfFaceMask and button.SlotBackground then button.SlotBackground:Hide() end','-- filled backdrop retirement disabled');
  let reproduced=false;
  try { execute(source+old,'unretired-native-face-backdrop'); }
  catch(error) { reproduced=String(error).includes('ready white-tinted round spell darkened by placeholder backdrop'); }
  if(!reproduced) throw Error('candidate16 backdrop occlusion negative control did not fail');
  // Independent mutations prove that these visibility/layer assertions are active.
  for (const [name,mutated,message] of [
    ['late-native-show',joined.replace("hooksecurefunc(texture,'Show',function() HUD.EmptyVisibility(button) end)","hooksecurefunc(texture,'Show',function() end)"),'late SlotBackground Show covered a filled spell'],
    ['same-native-layer',joined.replace('function HUD.FaceLayers(button)','function HUD.FaceLayers(button) return end\nfunction HUD.DisabledFaceLayers(button)'),'native icon reset lost distinct draw layers'],
  ]) {
    let rejected=false;
    try { execute(source+mutated,name); }
    catch(error) { rejected=String(error).includes(message); }
    if(!rejected) throw Error(name+' regression mutation did not fail for its expected reason');
  }
});
check('T54.native-pressed-round-golden-feedback-all-banks', () => {
  const pkg=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='SFX-WoW/Masque');
  const texture=pkg.unpacked+'/Masque/Core/Regions/Texture.lua';
  if(sha(texture)!==pkg.files['Masque/Core/Regions/Texture.lua']) throw Error('Masque texture source drift');
  const fixture=presentationFixture()+read('tests/harness/action_feedback.lua')
    .replace('--@NATIVE_MASQUE_TEXTURE',()=>nativeFunction(texture,'Core.Skin_Texture'))
    .replace('--@NATIVE_BUTTON_DOWN_UP',()=>['MultiActionButtonDown','MultiActionButtonUp'].map(name=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/MultiActionBars.lua',name)).join('\n'));
  execute(source+fixture,'native-round-press-release');
  for(const [name,mutation,message] of [
    ['occluded-press',fixture.replace("texture:SetDrawLayer('OVERLAY',1)","texture:SetDrawLayer('ARTWORK',0)"),'native press feedback hidden by icon'],
    ['grey-press',fixture.replace('texture:SetVertexColor(1,.82,.15,1)','texture:SetVertexColor(.6,.6,.6,1)'),'pressed feedback lost golden colour'],
  ]) {
    let rejected=false;
    try {execute(source+mutation,name);} catch(error) {rejected=String(error).includes(message);}
    if(!rejected) throw Error(name+' mutation did not fail for expected reason');
  }
});
check('T55.native-Retail-duration-object-round-cooldown-all-banks', () => {
  const pkg=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='seblindfors/ConsolePort');
  const file=pkg.unpacked+'/ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua';
  if(sha(file)!==pkg.files['ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua']) throw Error('LAB cooldown source drift');
  const lab=read(file).replace(/\r\n/g,'\n');
  const start=lab.indexOf('local defaultCooldownInfo ='),end=lab.indexOf('\nelse\n',start);
  if(start<0 || end<start) throw Error('Retail duration-object branch missing');
  // Retain Retail getters, excluding the later Classic-only LoC override.
  const getters=lab.slice(0,lab.indexOf('-- Classic overrides for item')).split('\n').filter(line=>/^\s*Action\.(GetCooldownInfo|GetChargeInfo|GetLoCCooldownInfo|GetCooldownDuration|GetChargeDuration|GetLoCCooldownDuration)\s*=/.test(line)).join('\n');
  const fixture=presentationFixture()+read('tests/harness/cooldown_feedback.lua')
    .replace('--@NATIVE_ACTION_COOLDOWN_GETTERS',()=>getters)
    .replace('--@NATIVE_RETAIL_COOLDOWN',()=>lab.slice(start,end)+'\nend\n');
  execute(source+fixture,'native-duration-object-swipes');
  let rejected=false;
  try {execute(source+fixture.replace('cd:SetUsingParentLevel(false) cd:SetFrameLevel(button:GetFrameLevel()+1)','-- original useParentLevel retained'),'occluded-native-swipe');}
  catch(error) {rejected=String(error).includes('native swipe hidden beneath ARTWORK icon');}
  if(!rejected) throw Error('same-parent-level cooldown regression not reproduced');
  rejected=false;
  try {execute(source+fixture.replace('SetOrClearCooldown(self.cooldown, showNormal, self:GetCooldownDuration())','SetOrClearCooldown(self.cooldown, true, self:GetCooldownDuration())'),'invented-failed-action-cooldown');}
  catch(error) {rejected=String(error).includes('cooldown sink disagrees with game normal/GCD state');}
  if(!rejected) throw Error('invented cooldown mutation did not fail');
});
check('T56.R2-mirrors-final-L2-without-moving-other-HUD-elements', () => {
  const fixture=geometryFixture().replace("local identity=table.concat", `
local left=HUD.Rect(ConsolePortGroupL2.__cpfBankPrompt)
local right=HUD.Rect(ConsolePortGroupR2.__cpfBankPrompt)
assert(math.abs(left.y-right.y)<.001,'R2 vertical alignment differs from L2')
assert(math.abs(left.x+left.w+right.x-UIParent:GetWidth())<.001,'R2 horizontal position does not mirror L2')
local identity=table.concat`);
  execute(source+fixture+read('tests/harness/stationary_hints.lua'),'mirrored-trigger-geometry');
  const oldHUD=code=>code
    .replace('if ConsolePortGroupR2 and frame==ConsolePortGroupR2.__cpfBankPrompt then','if false then')
    .replace('if not placed and not (ConsolePortGroupR2 and frame==ConsolePortGroupR2.__cpfBankPrompt) then','if not placed then');
  let rejected=false;
  try {execute(source+oldHUD(fixture),'independently-fitted-R2');}
  catch(error) {rejected=/R2 (vertical alignment|horizontal position)/.test(String(error));}
  if(!rejected) throw Error('original asymmetric R2 layout not reproduced');
  // Run original and fixed layout algorithms across all 120 cases and compare
  // physical rectangles of L2, combo/class prompts and every gameplay cell.
  const snapshot=geometryFixture().replace('local fixedHints={}','local fixedHints={} local unchangedRects={}').replace('cases=cases+1',`
local row={}
for _,id in ipairs({'Base','L2','R2','L2R2'}) do
 local bank=_G['ConsolePortGroup'..id]
 for key,button in pairs(bank.buttons) do row[id..key]=HUD.Rect(button) end
 if id~='R2' and bank.__cpfBankPrompt then row[id..'prompt']=HUD.Rect(bank.__cpfBankPrompt) end
end
local badge=ConsolePortGroupBase.__cpfClassShortcut
row.class=HUD.Rect(badge) row.classPrompt=HUD.Rect(badge.prompt)
unchangedRects[#unchangedRects+1]=row
cases=cases+1`)+ '\nSERIALIZED_STATE=serialized(unchangedRects)';
  const before=execute(source+serializer+oldHUD(snapshot),'original-non-R2-geometry');
  const after=execute(source+serializer+snapshot,'fixed-non-R2-geometry');
  if(before!==after) throw Error('alignment changed L2 or unrelated HUD rectangles');
});
check('T57.native-player-power-remains-visible-through-redraw-and-combat', () => {
  const base='evidence/aura-regression/native/';
  const manifest=JSON.parse(read('evidence/aura-regression/native-manifest.json'));
  for(const row of manifest) if(sha(base+row.path)!==row.sha256) throw Error('Native player-resource contract drift: '+row.path);
  const xml=read(base+'Blizzard_UnitFrame/Mainline/PaladinPowerBar.xml');
  if(!xml.includes('atlas="uf-holypower-runeholder"') || !xml.includes('name="PaladinPowerBarFrame"') || [...xml.matchAll(/parentKey="rune[1-5]"/g)].length!==5) throw Error('Screenshot five-rune frame identity unqualified');
  const fixture=visibilityFixture()+read('tests/harness/player_resource_strip.lua')
    .replace('--@NATIVE_CLASS_POWER',()=>['GetUnit','UsesPowerToken','OnEvent','Setup'].map(n=>nativeFunction(base+'Blizzard_UnitFrame/Mainline/ClassPowerBar.lua','ClassPowerBar:'+n)).join('\n'))
    .replace('--@NATIVE_RESOURCE_BAR',()=>['OnHideClassInfoOnPlayerFrameChanged','OnEvent','HandleBarSetup','Setup','UpdateMaxPower'].map(n=>nativeFunction(base+'Blizzard_UnitFrame/Mainline/ClassResourceBarTemplate.lua','ClassResourceBarMixin:'+n)).join('\n'))
    .replace('--@NATIVE_PALADIN_POWER',()=>nativeFunction(base+'Blizzard_UnitFrame/Mainline/PaladinPowerBar.lua','PaladinPowerBar:UpdatePower'));
  execute(fixture,'native-player-resource-strip');
  let rejected=false;
  const suppressed=fixture.replace('local ok,reason=self:Refresh(_G,enabled)',"if PaladinPowerBarFrame then PaladinPowerBarFrame:SetAlpha(0) end\n    local ok,reason=self:Refresh(_G,enabled)");
  try {execute(suppressed,'wrong-power-target');} catch(error) {rejected=String(error).includes('native power strip unexpectedly suppressed');}
  if(!rejected) throw Error('wrong power-bar suppression mutation was not reproduced');
});
check('T58.revision17-lost-class-access-native-recovery-and-aura-row', () => {
  if(!bootstrapState) throw Error('native bootstrap fixture unavailable');
  const fixture=read('tests/harness/class_access_recovery.lua')
    .replace('--@NATIVE_STANCE_VISIBILITY',()=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua','StanceBarMixin:ShouldShow'))
    .replace('--@NATIVE_STANCE_UPDATE',()=>nativeFunction('evidence/native/Blizzard_ActionBar/Shared/StanceBar.lua','StanceBarMixin:Update'));
  for(const cls of ['PALADIN','DRUID','WARRIOR']) execute('SESSION_STATE=('+bootstrapState+').installed\nRECOVERY_CLASS="'+cls+'"\n'+bootstrapPrelude+fixture,'lost-native-class-access-'+cls);
  let rejected=false;
  const original=bootstrapPrelude.replace("local repair=record.appliedRevision==17 and record.classAccessRepair~=1 and Class.Supported(api)","local repair=false");
  try {execute('SESSION_STATE=('+bootstrapState+').installed\nRECOVERY_CLASS="PALADIN"\n'+original+fixture,'skipped-revision17-class-repair');}
  catch(error) {rejected=String(error).includes('revision17 lost class opener was not recovered');}
  if(!rejected) throw Error('accepted17 class recovery negative control did not fail');
  rejected=false;
  const leaked=bootstrapPrelude.replace('sets=Addon.ClassActions.FilterOwnedSets(sets,self.guid,self.api.classForGUID and self.api.classForGUID())','-- owner filtering removed');
  try {execute('SESSION_STATE=('+bootstrapState+').installed\nRECOVERY_CLASS="PALADIN"\n'+leaked+fixture,'foreign-class-ring-leak');}
  catch(error) {rejected=String(error).includes('Paladin aura ring leaked into Demon Hunter proposal');}
  if(!rejected) throw Error('cross-character class-ring leak negative control did not fail');
});
check('T59.character-binding-capture-rejects-account-view', () => {
  if(!bootstrapState) throw Error('native bootstrap fixture unavailable');
  execute('SESSION_STATE=('+bootstrapState+').installed\n'+bootstrapPrelude+read('tests/harness/character_capture_owner.lua'),'character-capture-owner');
  let rejected=false;
  const old=bootstrapPrelude.replace('if not native or state.set~=native.api.CharacterSet then','if false then');
  try {execute('SESSION_STATE=('+bootstrapState+').installed\n'+old+read('tests/harness/character_capture_owner.lua'),'account-overwrites-character');}
  catch(error) {rejected=String(error).includes('account view erased character class binding');}
  if(!rejected) throw Error('account character-capture negative control did not fail');
});
check('T60.inactive-candidate27-secure-ping-fallback', () => {
  const nativeManifest=JSON.parse(read('evidence/native/manifest.json'));
  const cpManifest=JSON.parse(read('evidence/consoleport-contracts/manifest.json'));
  for(const name of ['Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua','Blizzard_PingUI/Blizzard_PingManager.lua','Blizzard_FrameXML/SecureTemplates.lua','Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua','Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua','Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua']) {
    const row=nativeManifest.find(r=>r.path===name);
    if(!row || sha('evidence/native/'+name)!==row.sha256) throw Error('Native secure ping source drift: '+name);
  }
  for(const name of ['ConsolePort/Controller/Radial.lua','ConsolePort/Controller/Layers.lua','ConsolePort/Utils/Utils.lua','ConsolePort/Utils/Database.lua','ConsolePort_Cursor/View/Cursor.xml','ConsolePort_Target/View/Cursor/Raid.xml','ConsolePort_Target/View/Ring/Targetring.xml','ConsolePort/View/Pie/Pie.xml','ConsolePort/Widget/PieMenu/PieMenu.lua','ConsolePort/Widget/PieMenu/PieMenu.xml','ConsolePort_Rings/View/Ring/Ring.xml']) {
    const row=cpManifest.files.find(r=>r.path===name);
    if(!row || sha('evidence/consoleport-contracts/'+name)!==row.sha256) throw Error('ConsolePort secure ping source drift: '+name);
  }
  // The UI cursor is unprotected; the raid cursor and target ring are protected.
  // A synthetic all-protected model would wrongly qualify an unusable startup guard.
  if(/Secure/.test(read('evidence/consoleport-contracts/ConsolePort_Cursor/View/Cursor.xml'))) throw Error('Native UI cursor protection contract changed');
  if(!/SecureHandlerStateTemplate/.test(read('evidence/consoleport-contracts/ConsolePort_Target/View/Cursor/Raid.xml')) || !/ConsolePortSecurePie/.test(read('evidence/consoleport-contracts/ConsolePort_Target/View/Ring/Targetring.xml')) || !/SecureActionButtonTemplate/.test(read('evidence/consoleport-contracts/ConsolePort/View/Pie/Pie.xml'))) throw Error('Native protected target owners unavailable');
  const product=read('addon/ConsolePort_Forever/Targeting/Ping.lua');
  if(/(?:C_Ping(?:Secure)?\.|TogglePingListener\s*\(|RunBinding\s*\(|RunMacroText\s*\()/.test(product)) throw Error('Public addon ping crossed protected dispatch boundary');
  if(fs.existsSync(path.join(root,'addon/ConsolePort_Forever/Bindings.xml'))) throw Error('Insecure custom ping binding retained');
  const normalized=p=>read(p).replace(/\r\n/g,'\n');
  const utils=normalized('evidence/consoleport-contracts/ConsolePort/Utils/Utils.lua');
  const database=normalized('evidence/consoleport-contracts/ConsolePort/Utils/Database.lua');
  const handlers=normalized('evidence/native/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua');
  const native=normalized('evidence/native/Blizzard_FrameXML/SecureTemplates.lua');
  const manager=normalized('evidence/native/Blizzard_PingUI/Blizzard_PingManager.lua');
  const slash=normalized('evidence/native/Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua');
  const compiler=normalized('evidence/native/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua');
  const wrap=p=>';(function(...)\n'+normalized(p)+'\nend)("ConsolePort",db);';
  const legacy=read('fallbacks/ping-candidate27/Ping.lua.disabled');
  const fixture=source.replace(product,()=>legacy)+'\n'+normalized('fallbacks/ping-candidate27/ping_targeting.lua.disabled')
    .replace('--@CURRENT_PIE_STYLE',()=> 'CPPieSliceMixin={}\nlocal SLICE_FRACTION,BG_FRACTION,MASK_FRACTION=512/300,480/300,512/300;\n'+['CPPieMenuMixin:UpdatePieSlices','CPPieSliceMixin:SetIndex','CPPieSliceMixin:RotateMasks','CPPieSliceMixin:UpdateSize'].map(name=>nativeFunction('evidence/consoleport-contracts/ConsolePort/Widget/PieMenu/PieMenu.lua',name)).join('\n'))
    .replace('--@CURRENT_CONVERSION',()=>utils.slice(utils.indexOf('do\tlocal ConvertSecureBody'),utils.indexOf('\nend',utils.indexOf('do\tlocal ConvertSecureBody'))+4))
    .replace('--@CURRENT_SECURE_ENV',()=>utils.slice(utils.indexOf('CPAPI.SecureExportMixin ='),utils.indexOf('do local UIHider;')))
    .replace('--@CURRENT_SCRIPT_MIXIN',()=>database.slice(database.indexOf('db.table.mixin ='),database.indexOf('return obj\nend;',database.indexOf('db.table.mixin ='))+15))
    .replace('--@CURRENT_LAYERS',()=>wrap('evidence/consoleport-contracts/ConsolePort/Controller/Layers.lua'))
    .replace('--@CURRENT_RADIAL',()=>wrap('evidence/consoleport-contracts/ConsolePort/Controller/Radial.lua'))
    .replace('--@NATIVE_RESTRICTED_COMPILER',()=>compiler.slice(compiler.indexOf('local function SelfScrub('),compiler.indexOf('-- Max number of cached closures')))
    .replace('--@NATIVE_WRAPPED_CLICK',()=>handlers.slice(handlers.indexOf('local function Wrapped_Click('),handlers.indexOf('local function Wrapped_OnEnter(')))
    .replace('--@NATIVE_WRAPPED_OTHER',()=>handlers.slice(handlers.indexOf('local function CreateSimpleWrapper('),handlers.indexOf('local function Wrapped_Drag('))+handlers.slice(handlers.indexOf('local function Wrapped_Attribute('),handlers.indexOf('local LOCAL_Wrap_Handlers')))
    .replace('--@NATIVE_ACTION_DISPATCH',()=>native.slice(native.indexOf('SECURE_ACTIONS.macro ='),native.indexOf('local CANCELABLE_ITEMS'))+native.slice(native.indexOf('local PRESS_TYPE_DOWN'),native.indexOf('function SecureUnitButton_OnLoad')))
    .replace('--@NATIVE_PING_METHODS',()=>manager.slice(manager.indexOf('function PingManager:SendMacroPing('),manager.indexOf('function PingManager:CancelPendingPing(')))
    .replace('--@NATIVE_PING_SLASH',()=>slash.slice(slash.indexOf('\tlocal function CleanupPingTypeString('),slash.indexOf('\n\tSlashCommandUtil.CheckAddSecureSlashCommand(SLASH_COMMAND.PING_SPELL')));
  if(/--@(?:CURRENT|NATIVE)_/.test(fixture)) throw Error('Unfilled secure ping contract marker');
  execute(fixture,'secure-macro-controller-ping');
  for(const [name,from,to,expected] of [
    ['raw-restricted-table-literal',"ipairs(newtable('Cursor','Raid','TargetRing'))","ipairs({'Cursor','Raid','TargetRing'})",'Direct table creation is not permitted'],
    ['unprotected-cursor-startup-rejection',"(name~='Cursor' and not owner:IsProtected())","not owner:IsProtected()",'qualified unprotected UI cursor prevented ping startup'],
    ['unprotected-cursor-combat-inspection',"(owner:IsProtected() or self:GetAttribute('state-cpf-combat')~='combat')",'true','restricted unprotected handle in combat'],
    ['vanished-soft-unit-fallback',"..unit..',exists]'","..unit..']'",'vanished aimed unit fell back to stale hit test'],
    ['public-onshow-protected-write',"frame:HookScript('OnShow',function()","frame:HookScript('OnShow',function() frame:SetAttribute('cpf-public-bug',true)",'insecure protected attribute write'],
    ['missing-inline-centering',"body='/console GamePadCursorCentering 1","body='/console GamePadCursorCentering 0",'point ping used parked UI receiver'],
    ['other-native-radial-handoff',"self:CaptureRadialOwners(bridge)",'do end','other native radial did not cancel ping gesture'],
    ['already-open-native-radial',"for index=1,(self:GetAttribute('cpf-radial-owner-count') or 0) do",'for index=1,0 do','ping started over another radial'],
    ['insecure-public-macro-ping',"function frame:CaptureCenter()", "function frame:CaptureCenter() api.C_Ping.SendMacroPing({targetToken='cursor'})", 'ADDON_ACTION_FORBIDDEN'],
    ['plain-ping-ui-blocker','/ping [@cursor]','/ping ', 'contextual point tap not sent'],
    ['wrong-selected-ping-type',"(' '..index)","(' '..1)",'selected ping type not dispatched'],
    ['ring-on-tap',"frame:SetAlpha(0) frame:OnInput(0,0,0)","frame:SetAlpha(1) frame:OnInput(0,0,0)",'tap displayed the ping ring on press'],
    ['missing-cursor-restoration',"self:CallMethod('RestoreCenter')",'do end','release did not restore/clear'],
    ['foreign-modal-delayed-release',"then ping:RunAttribute('cpf-cancel') end",'then do end end','foreign modal takeover did not cancel'],
    ['camera-tap-cancels',"local index=self:RunAttribute('GetIndex',nil,6)","local index=self:RunAttribute('GetIndex',nil,6) if index==6 then self:RunAttribute('cpf-cancel') return end",'selected ping type not dispatched: 6']
  ]) {
    if(!fixture.includes(from)) throw Error('Stale ping negative-control needle: '+name);
    let rejected=false;
    try {execute(fixture.replaceAll(from,to),name);}
    catch(error) {rejected=String(error).includes(expected);}
    if(!rejected) throw Error('Secure ping negative control did not fail for expected reason: '+name);
  }
  const registration="api.RegisterStateDriver(frame,'cpf-combat','[combat] combat; peace')";
  if(!fixture.includes(registration)) throw Error('Initial combat-state registration missing');
  const early=fixture.replace(registration,'do end').replace("radial:Register(frame,'ForeverPing'",registration+"\nradial:Register(frame,'ForeverPing'");
  let rejected=false;
  try {execute(early,'early-combat-registration');} catch(error) {rejected=String(error).includes('nil value');}
  if(!rejected) throw Error('Initial state-driver ordering negative control did not fail');
});
check('T61.all-classes-native-dragonriding-and-temporary-L2R2-engine-dispatch', () => {
  const base='evidence/consoleport-contracts/';
  const manifest=JSON.parse(read(base+'manifest.json'));
  for(const name of ['ConsolePort/Controller/Pager.lua','ConsolePort_Bar/Widget/Bar/Bar.lua']) {
    const row=manifest.files.find(r=>r.path===name);
    if(!row || sha(base+name)!==row.sha256) throw Error('Native temporary paging contract drift: '+name);
  }
  const pager=read(base+'ConsolePort/Controller/Pager.lua');
  const response=pager.match(/local DEFAULT_PAGE_RESPONSE = \(\[\[([\s\S]*?)\]\]\):format\(NUM_ACTIONBAR_PAGES\)/)?.[1].replace('%s','6');
  const header=pager.match(/local HEADER_RESPONSE = \[\[([\s\S]*?)\]\];/)?.[1];
  if(!response || !header) throw Error('Native pager response unavailable');
  const prelude=groundTargetingFixture().split('assert(Addon.SecureModes.Install(bridge,api))')[0];
  const manager=read(base+'ConsolePort_Bar/Controller/Manager/Manager.lua');
  const utils=read(base+'ConsolePort/Utils/Utils.lua');
  const start=utils.indexOf('Parse = function(self, body, args)');
  const engine=read('tests/harness/targeting_engine.lua')
    .replace('--@NATIVE_MANAGER_ENV',manager.slice(manager.indexOf('Manager.Env = {'),manager.indexOf('\n};')+4))
    .replace('--@NATIVE_MANAGER_REGISTER',()=>nativeFunction(base+'ConsolePort_Bar/Controller/Manager/Manager.lua','Manager:RegisterOverride'))
    .replace('--@NATIVE_MANAGER_PARSE','local native'+utils.slice(start,utils.indexOf('\n\tend;',start)+6));
  const fixture=read('tests/harness/temporary_routing.lua')
    .replace('--@NATIVE_EDIT_SNIPPETS',()=>{
      const lib=read(base+'ConsolePort/Libs/External/LibActionButton-1.0/LibActionButton-1.0.lua');
      const button=read(base+'ConsolePort_Bar/Widget/Button/Button.lua');
      const drag=lib.match(/button:SetAttribute\("OnDragStart", \[\[([\s\S]*?)\]\]\)/)?.[1];
      const pickup=lib.match(/button:SetAttribute\("PickupButton", \[\[([\s\S]*?)\]\]\)/)?.[1];
      const receive=button.match(/OnReceiveDrag =\[\[([\s\S]*?)\]\];/)?.[1];
      if(!drag || !pickup || !receive) throw Error('Native drag editing contract unavailable');
      return `nativeDragStart=[==[${drag}]==]\nnativeReceiveDrag=[==[${receive}]==]\nnativePickup=[==[${pickup}]==]`;
    })
    .replace('--@NATIVE_PAGER_RESPONSE',()=>`nativePageBody=[=[${response}\n${header}]=]`)
    .replace('--@NATIVE_PAGER_ACTION_HELPERS',()=>{
      const actionID=pager.match(/GetActionID = \(\[\[([\s\S]*?)\]\]\):format\(NUM_ACTIONBAR_BUTTONS\)/)?.[1].replace('%d','12');
      const info=pager.match(/GetActionInfo = \[\[([\s\S]*?)\]\];/)?.[1];
      const spell=pager.match(/GetSpellID = \[\[([\s\S]*?)\]\];/)?.[1];
      if(!actionID || !info || !spell) throw Error('Native pager action helpers unavailable');
      return [['GetActionID',actionID],['GetActionInfo',info],['GetSpellID',spell]].map(([k,b])=>`pager:SetAttribute('${k}',[=[${b}]=])`).join('\n');
    });
  const scenario=prelude.replace('CallMethod=function(_,method,...) return raw:CallMethod(method,...) end,',
    'ChildUpdate=function(_,name,value) return raw:ChildUpdate(name,value) end, CallMethod=function(_,method,...) return raw:CallMethod(method,...) end,')+'\n'+fixture;
  const prefix=source+uiContextFixture()+'\n'+engine+'\n';
  const wrap=s=>prefix+'\nlocal scenario='+JSON.stringify(s)+'\nlocal scope=setmetatable({},{__index=_G}); scope._G=scope; scope.engine=targetingEngine; scope.Addon=Addon; assert(load(scenario,"temporary-routing","t",scope))(); TEST_SUCCESS=scope.TEST_SUCCESS;';
  try {execute(wrap(scenario),'all-class-native-temporary-routing');}
  catch(error) {
    const line=Number(String(error).match(/\[string "temporary-routing"\]:(\d+)/)?.[1]);
    if(line) error.message+='\nScenario context:\n'+scenario.split('\n').slice(Math.max(0,line-3),line+2).join('\n');
    throw error;
  }
  let rejected=false;
  const skipped=scenario.replace('assert(Routing:Refresh(bridge,api,true))','assert(true)');
  try {execute(wrap(skipped),'native-recovery-skips-temporary-routing');}
  catch(error) {rejected=String(error).includes('dragonriding still possesses L2');}
  if(!rejected) throw Error('Native recovery L2 regression was not reproduced');
  rejected=false;
  const wrong=prefix.replace("name=='L2R2' and index or nil","name=='L2' and index or nil");
  try {execute(wrong+'\nlocal scenario='+JSON.stringify(scenario)+'\nlocal scope=setmetatable({},{__index=_G}); scope._G=scope; scope.engine=targetingEngine; scope.Addon=Addon; assert(load(scenario,"wrong-bank","t",scope))(); TEST_SUCCESS=scope.TEST_SUCCESS;','wrong-bank-temporary-routing');}
  catch(error) {rejected=String(error).includes('dragonriding still possesses L2');}
  if(!rejected) throw Error('Wrong temporary bank regression was not reproduced');
  const editProbe=scenario.slice(0,scenario.indexOf('local classes='))+`
local edited=api.ConsolePortGroupL2R2.buttons.PAD1
edited:SetAttribute('LABdisableDragNDrop',nil)
page(nil) edited:SetState('CTRL-SHIFT-','spell',902)
assert(Routing:Refresh(bridge,api,true))
assert(edited:GetAttribute('type')=='spell' and edited:GetAttribute('spell')==902,'ordinary edit reset by unchanged bindings')
run(edited.header,edited,'self,button,down',Routing.PreClick,'LeftButton',true)
edited:RunAttribute('OnDragStart')
assert(edited:GetAttribute('type')=='empty','ordinary dragged-off ability came back')
TEST_SUCCESS=true
`;
  for(const [name,changed,message] of [
    ['refresh-overwrites-edit',prefix.replace('if bindings and not Addon.Core.Equal(button.__cpfTemporary.bindings,bindings) then','if bindings then'),'ordinary edit reset by unchanged bindings'],
    ['drag-resurrects-action',prefix.replace(/    if dragStart then[\s\S]*?\n    end/,''),'ordinary dragged-off ability came back'],
    ['drag-keeps-held-action',prefix.replaceAll("self:SetAttribute('cpf-temp-held',nil)",'do end'),'ordinary dragged-off ability came back']
  ]) {
    rejected=false;
    try {execute(changed+'\nlocal scenario='+JSON.stringify(editProbe)+'\nlocal scope=setmetatable({},{__index=_G}); scope._G=scope; scope.engine=targetingEngine; scope.Addon=Addon; assert(load(scenario,"native-edit-regression","t",scope))(); TEST_SUCCESS=scope.TEST_SUCCESS;',name);}
    catch(error) {rejected=String(error).includes(message);}
    if(!rejected) throw Error('Native editing regression was not reproduced: '+name);
  }
});
check('T62.recovery-startup-enables-temporary-routing-for-every-character', () => {
  if(!bootstrapState) throw Error('native bootstrap fixture unavailable');
  const test=`
local routed={}
Addon.TemporaryRouting.Refresh=function(_,bridge,api,enabled)
 assert(Addon.NATIVE_INPUT_RECOVERY and bridge,'temporary routing requires full mode/UI takeover')
 routed[UnitGUID()]=enabled
 return true,'test route'
end
fire('PLAYER_LOGIN') flush()
assert(routed.A==true,'installed recovery startup omitted temporary routing')
Addon.db.shared.runtimePolicy.modesEnabled=false
for _,class in ipairs({'DEMONHUNTER','PALADIN','DRUID','WARRIOR','DEATHKNIGHT','EVOKER','HUNTER','MAGE','MONK','PRIEST','ROGUE','SHAMAN','WARLOCK'}) do
 guid='TEMP-'..class
 function UnitClass() return class,class end
 local record=Addon.Store.GetCharacter(Addon.db,guid)
 record.appliedRevision=17 record.classAccessRepair=1 record.ringOfferedRevision=17
 record.bindingAccepted=false record.ringAccepted=false
 fire('PLAYER_LOGIN') flush()
 assert(routed[guid]==true,'class startup omitted combined temporary bank: '..class)
end
Addon.record.appliedRevision=0
Addon:RefreshModes()
assert(routed[guid]==false,'restored character kept temporary routing')
TEST_SUCCESS=true
`;
  const setup='SESSION_STATE=('+bootstrapState+').installed\n'+bootstrapPrelude;
  execute(setup+test,'class-neutral-recovery-startup');
  let rejected=false;
  const skipped=setup.replace('local routed,routeReason=self.TemporaryRouting:Refresh(self.adapters.consoleport,_G,self:IsCharacterInstalled())',"local routed,routeReason=false,'skipped'");
  try {execute(skipped+test,'skipped-recovery-routing');}
  catch(error) {rejected=String(error).includes('installed recovery startup omitted temporary routing');}
  if(!rejected) throw Error('Skipped recovery routing mutation was not reproduced');
});
check('T63.incomplete-character-archive-projection-recovery', () => {
  const setup=source+'\n;(function(...)\n'+read('addon/ConsolePort_Forever/RuntimeSetup.lua')+'\nend)("ConsolePort_Forever",Addon);\n';
  const test=`
local db={characters={PAL={controllerBindings={['SHIFT-PAD1']='ACTIONBUTTON1'}},DH={controllerBindings={['SHIFT-PAD1']='ACTIONBUTTON2'}}},
 shared={faceBindings={PAD1='JUMP'}},managedFields={['PAL/controller']={value={keys={['SHIFT-PADLSHOULDER']='CLICK ConsolePortUtilityToggle:CPFClass',['CTRL-PADRSHOULDER']=''}}}}}
local current={set=2,keys={PAD1='JUMP',['SHIFT-PAD1']='ACTIONBUTTON1',['SHIFT-PADLSHOULDER']='CLICK ConsolePortUtilityToggle:CPFClass',['CTRL-PADRSHOULDER']=''},keyboard={G='TOGGLEPINGLISTENER'}}
local adapter={mask={PAD1=true,['SHIFT-PAD1']=true,['SHIFT-PADLSHOULDER']=true,['CTRL-PADRSHOULDER']=true},native={api={CharacterSet=2}},read=function() return Addon.Core.Copy(current) end}
Addon.Store.GetCharacter(db,'PAL') Addon.Store.GetCharacter(db,'DH')
local before=Addon.Core.Copy(db)
local desired=Addon.RuntimeSetup.BindingProposal(db,'PAL',adapter,{})
assert(Addon.Core.Equal(current,desired),'incomplete Paladin archive rejects a no-op binding readback')
local dh=Addon.RuntimeSetup.BindingProposal(db,'DH',adapter,{})
assert(dh.keys['SHIFT-PADLSHOULDER']=='' and dh.keys['CTRL-PADRSHOULDER']=='','Paladin class keys leaked into DH')
db.characters.PAL.controllerBindings['SHIFT-PADLSHOULDER']=''
assert(Addon.RuntimeSetup.BindingProposal(db,'PAL',adapter,{}).keys['SHIFT-PADLSHOULDER']=='','explicit player removal was overwritten')
db.characters.PAL.controllerBindings['SHIFT-PADLSHOULDER']=nil
assert(Addon.Core.Equal(db,before),'proposal mutated saved archives')
TEST_SUCCESS=true
`;
  execute(setup+test,'incomplete-Paladin-character-archive');
  const original=setup.replace('personal=Core.Copy(personal)', 'personal=Core.Copy(personal)').replace(/    local committed=db.managedFields[\s\S]*?    state.set=adapter.native.api.CharacterSet/, '    state.keys=Addon.BindingPolicy.Compose(shared,personal,split.retained)\n    state.set=adapter.native.api.CharacterSet');
  let rejected=false;
  try {execute(original+test,'old-incomplete-archive');} catch(error) {rejected=String(error).includes('incomplete Paladin archive rejects');}
  if(!rejected) throw Error('Original incomplete archive defect was not reproduced');
});
check('T64.action-storage-observers-never-restore-or-rewrite-bars', () => {
  const legacy=JSON.parse(read('evidence/action-recovery/candidate27-diagnosis.json')).legacyAutomaticWriter;
  if(sha(legacy.path)!==legacy.sha256) throw Error('Legacy automatic writer regression source drift');
  execute(source+'\n;(function(...)\n'+read('addon/ConsolePort_Forever/ActionRecovery.lua')+'\nend)("ConsolePort_Forever",Addon);\n'+read('tests/harness/action_recovery.lua'),'action-storage-recovery');
  let rejected=false;
  try {execute(source+'\n;(function(...)\n'+read('evidence/action-recovery/ActionRecovery-candidate26.lua')+'\nend)("ConsolePort_Forever",Addon);\n'+read('tests/harness/action_recovery.lua'),'removed-automatic-restoration');}
  catch(error) {rejected=String(error).includes('automatic action-slot restoration rewrote edited bars');}
  if(!rejected) throw Error('Automatic action-slot rewrite regression was not reproduced');
});
check('T65.native-account-ping-ring-immediate-press-and-native-controls', () => {
  const product=read('addon/ConsolePort_Forever/Targeting/Ping.lua');
  if(/CreateFrame\('PieMenu'|CreateTexture|CreateMaskTexture|cpfIcons|SetFocusByIndex|GetIndexForPos/.test(product)) throw Error('Separate ping renderer or selector retained');
  if(/C_Ping(?:Secure)?\.|RunMacroText\s*\(/.test(product)) throw Error('Public privileged ping dispatch');
  const manifest=JSON.parse(read('evidence/consoleport-contracts/manifest.json'));
  for(const name of ['Database.lua','Model/Map.lua','Model/Container.lua','Controller/Secure.lua','View/Ring/Ring.lua','View/Ring/Button.lua']) {
    const relative='ConsolePort_Rings/'+name;
    if(sha('evidence/consoleport-contracts/'+relative)!==manifest.files.find(row=>row.path===relative)?.sha256) throw Error('Native account ring contract drift: '+relative);
  }
  const normalized=p=>read(p).replace(/\r\n/g,'\n');
  const utils=normalized('evidence/consoleport-contracts/ConsolePort/Utils/Utils.lua');
  const database=normalized('evidence/consoleport-contracts/ConsolePort/Utils/Database.lua');
  const handlers=normalized('evidence/native/Blizzard_RestrictedAddOnEnvironment/SecureHandlers.lua');
  const native=normalized('evidence/native/Blizzard_FrameXML/SecureTemplates.lua');
  const manager=normalized('evidence/native/Blizzard_PingUI/Blizzard_PingManager.lua');
  const slash=normalized('evidence/native/Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua');
  const compiler=normalized('evidence/native/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua');
  const wrap=p=>';(function(...)\n'+normalized(p)+'\nend)("ConsolePort",db);';
  let fixture=source+'\n'+normalized('tests/harness/ping_account_ring.lua').replace('--@NATIVE_ACCOUNT_RING_HOST',()=>normalized('tests/harness/ping_account_ring_host.lua')).replace('--@NATIVE_ACCOUNT_RING_CHECKS',()=>normalized('tests/harness/ping_account_ring_checks.lua'))
    .replace('--@CURRENT_PIE_STYLE',()=> 'CPPieSliceMixin={}\nlocal SLICE_FRACTION,BG_FRACTION,MASK_FRACTION=512/300,480/300,512/300;\n'+['CPPieMenuMixin:UpdatePieSlices','CPPieSliceMixin:SetIndex','CPPieSliceMixin:RotateMasks','CPPieSliceMixin:UpdateSize'].map(name=>nativeFunction('evidence/consoleport-contracts/ConsolePort/Widget/PieMenu/PieMenu.lua',name)).join('\n'))
    .replace('--@CURRENT_CONVERSION',()=>utils.slice(utils.indexOf('do\tlocal ConvertSecureBody'),utils.indexOf('\nend',utils.indexOf('do\tlocal ConvertSecureBody'))+4))
    .replace('--@CURRENT_SECURE_ENV',()=>utils.slice(utils.indexOf('CPAPI.SecureExportMixin ='),utils.indexOf('do local UIHider;')))
    .replace('--@CURRENT_SCRIPT_MIXIN',()=>database.slice(database.indexOf('db.table.mixin ='),database.indexOf('return obj\nend;',database.indexOf('db.table.mixin ='))+15))
    .replace('--@CURRENT_LAYERS',()=>wrap('evidence/consoleport-contracts/ConsolePort/Controller/Layers.lua'))
    .replace('--@CURRENT_RADIAL',()=>wrap('evidence/consoleport-contracts/ConsolePort/Controller/Radial.lua'))
    .replace('--@NATIVE_RESTRICTED_COMPILER',()=>compiler.slice(compiler.indexOf('local function SelfScrub('),compiler.indexOf('-- Max number of cached closures')))
    .replace('--@NATIVE_WRAPPED_CLICK',()=>handlers.slice(handlers.indexOf('local function Wrapped_Click('),handlers.indexOf('local function Wrapped_OnEnter(')))
    .replace('--@NATIVE_WRAPPED_OTHER',()=>handlers.slice(handlers.indexOf('local function CreateSimpleWrapper('),handlers.indexOf('local function Wrapped_Drag('))+handlers.slice(handlers.indexOf('local function Wrapped_Attribute('),handlers.indexOf('local LOCAL_Wrap_Handlers')))
    .replace('--@NATIVE_ACTION_DISPATCH',()=>native.slice(native.indexOf('SECURE_ACTIONS.macro ='),native.indexOf('local CANCELABLE_ITEMS'))+native.slice(native.indexOf('local PRESS_TYPE_DOWN'),native.indexOf('function SecureUnitButton_OnLoad')))
    .replace('--@NATIVE_PING_METHODS',()=>manager.slice(manager.indexOf('function PingManager:SendMacroPing('),manager.indexOf('function PingManager:CancelPendingPing(')))
    .replace('--@NATIVE_PING_SLASH',()=>slash.slice(slash.indexOf('\tlocal function CleanupPingTypeString('),slash.indexOf('\n\tSlashCommandUtil.CheckAddSecureSlashCommand(SLASH_COMMAND.PING_SPELL')));
  const ringBase='evidence/consoleport-contracts/ConsolePort_Rings/';
  fixture=fixture.replace('--@NATIVE_RING_DATABASE',()=>normalized(ringBase+'Database.lua').slice(normalized(ringBase+'Database.lua').indexOf('env.Attributes ='),normalized(ringBase+'Database.lua').indexOf('env.LABConfig ='))+normalized(ringBase+'Database.lua').slice(normalized(ringBase+'Database.lua').indexOf('function env:GetData(')))
    .replace('--@NATIVE_LIBSTUB',()=>normalized('evidence/consoleport-contracts/ConsolePort/Libs/External/LibStub/LibStub.lua'))
    .replace('--@NATIVE_RING_MAP',()=>';(function(...)\n'+normalized(ringBase+'Model/Map.lua')+'\nend)("ConsolePort_Rings",db);')
    .replace('--@NATIVE_RING_CONTAINER',()=>';(function(...)\n'+normalized(ringBase+'Model/Container.lua')+'\nend)("ConsolePort_Rings",db);')
    .replace('--@NATIVE_RING_SECURE',()=>';(function(...)\n'+normalized(ringBase+'Controller/Secure.lua')+'\nend)("ConsolePort_Rings",db);')
    .replace('--@NATIVE_RING_FRONTEND',()=>';(function(...)\n'+normalized(ringBase+'View/Ring/Ring.lua')+'\nend)("ConsolePort_Rings",db);')
    .replace('--@NATIVE_RING_BUTTON',()=>';(function(...)\n'+normalized(ringBase+'View/Ring/Button.lua')+'\nend)("ConsolePort_Rings",db);')
    .replace('--@NATIVE_TEXTURE_ADAPTER',()=>nativeFunction('evidence/consoleport-contracts/ConsolePort/Libs/Local/ActionButton.lua','Lib.SkinUtility.SetTexture'))
    .replace('--@NATIVE_CLICK_ACTION',()=>native.slice(native.indexOf('SECURE_ACTIONS.click ='),native.indexOf('SECURE_ACTIONS.attribute =')));
  if(/--@(?:CURRENT|NATIVE)_/.test(fixture)) throw Error('Unfilled native account ring marker');
  execute(fixture,'native-account-ping-ring');
  for(const [name,from,to,expected] of [
    ['callable-LibStub-startup',"type(cp.Static)~='function'","type(cp.Static)~='function' or type(api.LibStub)~='function'",'qualified native secure ping selector unavailable'],
    ['missing-immediate-press',"self:SetAttribute('type','macro')","self:SetAttribute('type',nil)",'press did not send immediately'],
    ['native-open-before-press',"self:SetAttribute('type','macro')","self:GetFrameRef('ring'):RunAttribute('Main',self:GetAttribute('cpf-ring-id'),true) self:SetAttribute('type','macro')",'immediate ping sent after camera capture'],
    ['tap-artwork',"ring:SetAlpha(0)","ring:SetAlpha(1)",'tap displayed selector'],
    ['personal-ring-storage',"self.ring,self.env=ring,env","ring.Data[id]=ring.Shared[id] ring.Shared[id]=nil self.ring,self.env=ring,env",'native account Shared container missing'],
    ['missing-native-release',"self:SetAttribute('typerelease','click')","self:SetAttribute('typerelease',nil)",'neutral tap release retained ring or sent extra ping'],
    ['reseed-account-edits',"if not ring.Shared[id] then", "if true then",'native account creation rejected'],
    ['missing-centering',"/console GamePadCursorCentering 1","/console GamePadCursorCentering 0",'point ping used parked UI receiver'],
    ['shared-header-state-hijack',"ring:RunAttribute('Main',self:GetAttribute('cpf-ring-id'),true)","ring:RunAttribute('SetContextAttribute','state',self:GetAttribute('cpf-ring-id')) ring:RunAttribute('Main',self:GetAttribute('cpf-ring-id'),true)",'ping context hijacked aura opener'],
    ['atlas-widget-unmount',"return function(texture) texture:SetTexCoord(0,1,0,1) end","return nil",'ping atlas UVs leaked into aura icon'],
    ['native-skin-bypassed',"button:OnLoad()","do end",'native skin/initializer missing']
  ]) {
    if(!fixture.includes(from)) throw Error('Stale account-ring mutation: '+name);
    let rejected=false;
    try {execute(fixture.replaceAll(from,to),name);} catch(error) {rejected=String(error).includes(expected);}
    if(!rejected) throw Error('Account-ring mutation did not fail for expected reason: '+name);
  }
});
check('T66.native-immersion-required-items', () => {
  const base='evidence/integration-contracts/Immersion/';
  const fixture=read('tests/harness/immersion_progress.lua')
    .replace('--@NATIVE_ADJUST_CHILDREN',()=>['IterateChildren','GetAdjustableChildren','AdjustToChildren'].map(name=>nativeFunction(base+'Components/Scaler.lua','AdjustMixin:'+name)).join('\n'))
    .replace('--@NATIVE_BOUNDARIES',()=>nativeFunction(base+'Components/Elements.lua','Elements:UpdateBoundaries'))
    .replace('--@NATIVE_TALKBOX_OFFSETS',()=> 'local GetOffset=UIParent.GetBottom\n'+['SetOffset','SetExtraOffset'].map(name=>nativeFunction(base+'Logic/Talkbox.lua','TalkBox:'+name)).join('\n'))
    .replace('--@NATIVE_QUEST_EVENTS',()=>['QUEST_PROGRESS','QUEST_COMPLETE','QUEST_ITEM_UPDATE'].map(name=>nativeFunction(base+'Logic/Events.lua','Events:'+name)).join('\n'))
    .replace('--@NATIVE_FRAME_EVENT',()=>nativeFunction(base+'Logic/Frame.lua','Frame:OnEvent'));
  execute(source+fixture,'native-immersion-required-items');
  // The native defect must still reproduce if the correction disappears.
  let rejected=false;
  try {execute((source+fixture).replace('frame.TalkBox:SetExtraOffset(offset)','do end'),'missing-required-items-correction');}
  catch(error) {rejected=String(error).includes('assertion failed');}
  if(!rejected) throw Error('Required Items negative control did not detect missing correction');
});
check('T67.saved-editmode-default-reference', () => {
  const captured=JSON.parse(read('evidence/editmode/saved-reference-2026-10-10.json'));
  if(captured.systemCount!==52 || captured.records.length!==52 || !read('addon/ConsolePort_Forever/SavedEditModeReference.lua').includes(captured.export)) throw Error('Packaged saved layout reference differs from captured cache');
  const fixture=source+serializer+'\n;(function(...)\n'+read('addon/ConsolePort_Forever/RuntimeSetup.lua')+'\nend)("ConsolePort_Forever",Addon);\n'+read('tests/harness/editmode_reference.lua');
  execute(fixture,'saved-editmode-default-reference');
});
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
