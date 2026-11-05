// Execute pinned native dispatch and upstream bag handlers in an inert Lua VM.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),parser=require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring}=require('fengari');
const root=path.resolve(__dirname,'..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
function functions(file,names){
  const source=read(file).replace(/\r\n/g,'\n');
  return names.map(name=>{
    const escaped=name.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
    const start=source.search(new RegExp('function '+escaped+'\\s*\\('));
    const end=source.indexOf('\nend',start)+4;
    if(start<0||end<start)throw Error('Missing native function '+name);
    const body=source.slice(start,end);parser.parse(body,{luaVersion:'5.1'});return body;
  }).join('\n');
}
function fixture(mutation='none'){
  const native='scratch/forever-config-inputs/ContainerFrame.lua';
  if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,native))).digest('hex')!=='9af2c76d16ebff607dd8b983722f36f98e819b35bc77395232bb2f960d15e3d3')throw Error('Native input drift');
  const lock=JSON.parse(read('dependencies/lock.json'));
  const bb=lock.packages.find(p=>p.repo==='Cidan/BetterBags').unpacked+'/BetterBags/core/hooks.lua';
  const product=['Core','Settings','BetterBags','Navigation','Bootstrap'].map(n=>{
    let source=read('addon/ForeverConfig_Extended/'+n+'.lua');
    if(n==='Settings'&&mutation==='skip-scale')source=source.replace('profile.ui_parent_scale_tune = desiredScale','profile.ui_parent_scale_tune = 1');
    if(n==='Settings'&&mutation==='repeat-migration')source=source.replace('if db.migrations[key] then return end','-- omitted receipt').replace('profile.ui_parent_scale_tune ~= 1','false');
    if(n==='BetterBags'&&mutation==='no-owner-dedup')source=source.replace('state.handled ~= pending.handled','false');
    if(n==='BetterBags'&&mutation==='no-combat-guard')source=source.replaceAll('InCombatLockdown()','false');
    if(n==='BetterBags'&&mutation==='no-native-route')source=source.replace('if type(_G[name]) == "function" then','if false then').replace('if type(ToggleBag) == "function" then','if false then');
    if(n==='BetterBags'&&mutation==='stale-queue-mode')source=source.replace('state.pending.mode = mode','if mode == "toggle" then state.pending.mode = mode end');
    if(n==='BetterBags'&&mutation==='replaced-bag')source=source.replace('or bag ~= pending.bag','');
    if(n==='BetterBags'&&mutation==='circle-bypass')source=source.replace('if combined and type(combined.Hide) == "function" then','if false then');
    return `assert(load(${JSON.stringify(source)},${JSON.stringify(n)}))('ForeverConfig_Extended',A)`;
  }).join('\n');
  return read('tests/harness/forever_config.lua')
    .replace('--@NATIVE',()=>functions(native,['ToggleBackpack_Combined','ToggleBackpack_Individual','ToggleBackpack','OpenBackpack','ToggleAllBags','OpenAllBags','OpenAllBagsInternal']))
    .replace('--@BETTERBAGS',()=>functions(bb,['addon:ToggleAllBags','addon.OnUpdate'])).replace('--@PRODUCT',()=>product);
}
function execute(source){
  const L=lauxlib.luaL_newstate();
  for(const [n,open]of [['_G',lualib.luaopen_base],['table',lualib.luaopen_table],['string',lualib.luaopen_string],['math',lualib.luaopen_math]]){lauxlib.luaL_requiref(L,to_luastring(n),open,1);lua.lua_pop(L,1);}
  let rc=lauxlib.luaL_loadstring(L,to_luastring(source));if(rc===lua.LUA_OK)rc=lua.lua_pcall(L,0,0,0);
  const error=rc===lua.LUA_OK?null:to_jsstring(lua.lua_tostring(L,-1));lua.lua_close(L);if(error)throw Error(error);
}
function run(){
  execute(fixture());
  const controls={'skip-scale':'scale migration missing','repeat-migration':'manual scale reset',
    'no-owner-dedup':'later BetterBags action overwritten','no-combat-guard':'queued combat action leaked',
    'no-native-route':'direct backpack did not open','stale-queue-mode':'latest same-frame open request lost',
    'replaced-bag':'stale request reached replacement bag','circle-bypass':'captured Circle close left BetterBags open'};
  for(const [mutation,expected]of Object.entries(controls)){let rejected=false;try{execute(fixture(mutation));}catch(error){rejected=String(error).includes(expected);}if(!rejected)throw Error('Surviving defect control: '+mutation);}
  const navigation=runNavigation();
  return {passed:true,nativeDispatch:true,upstreamBagHandlers:true,defectControls:controls,navigation,
    limits:'Native leaf frame/C APIs and timing modeled; no engine rendering, taint, hardware or item actions certified.'};
}
function navigationFixture(mutation='none'){
  const inputs={
    'FrameControlsManager.lua':'d1b1f6e21e9f103806c67c6274b4cb2ad947da99ee8315143ea9f37e1d13416f',
    'SmartNavigation.lua':'6907e694572194b8bb01aa73f035c75f04c02b33d7c14d0cd6bb98bfd85545d2',
    'Utility.lua':'a00c0086b9c24de2770ccfe7de992b991f3c4aab942f32fd9f52471553ef09f8',
    'PromptedBinding.lua':'6966073a5c98149389f793d95e3b9f5e7237153f263b1a2216b652e23782c6f9',
    'PromptedBindingFooter.lua':'dea94417a2672882d2bfa5e12be23cad8476c731e6e13a357ba779b292c78c1b'};
  const native=name=>{const p='scratch/forever-config-inputs/navigation/'+name; if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,p))).digest('hex')!==inputs[name])throw Error('Navigation source drift: '+name);return read(p);};
  const product=['Core','Navigation'].map(n=>{
    let source=read('addon/ForeverConfig_Extended/'+n+'.lua');
    parser.parse(source,{luaVersion:'5.1'});
    if(n==='Navigation'&&mutation==='missing-window')source=source.replace('nav:HandlePanelOpen(host, {frame})','-- omitted extra panel').replaceAll('nav:RefreshButtonGroups(host, {frame})','nav:RefreshButtonGroups(host)');
    if(n==='Navigation'&&mutation==='decorative-item')source=source.replace('SmartNavigation_MarkFrameIgnored(decoration)','do end');
    if(n==='Navigation'&&mutation==='focus-theft')source=source.replace('elseif nav:GetActiveFrame() == host then','elseif true then\n nav:HandlePanelOpen(host, {frame})');
    if(n==='Navigation'&&mutation==='combat-registration')source=source.replaceAll('InCombatLockdown()','false');
    if(n==='Navigation'&&mutation==='lost-close')source=source.replace('bag:Hide(context:New("ForeverConfig_NativeClose"))','do end');
    if(n==='Navigation'&&mutation==='stale-native-open')source=source.replace('if record.kind == "Backpack" and not frame:IsShown() then CloseBackpack() end','-- omitted native bookkeeping');
    if(n==='Navigation'&&mutation==='no-scroll-owner')source=source.replace('nav:SetScrollFrameForFrame(host, scroll)','do end');
    if(n==='Navigation'&&mutation==='stale-logout')source=source.replace('state.stopped = true','state.stopped = false').replace('state.generation = state.generation + 1','-- omitted generation');
    if(n==='Navigation'&&mutation==='raw-bindings')source=source.replace('    local bb = owner(self)\n    local manager',"    GamepadMode.ActivateBindingGroup(GamepadMode.CreateBindingGroup('forbidden'))\n    local bb = owner(self)\n    local manager");
    if(n==='Navigation'&&mutation==='lost-refocus')source=source.replace('hooksecurefunc(nav, "HandlePanelOpen", function(_, host) self:AttachBagPanel(host) end)','do end');
    return `assert(load(${JSON.stringify(source)},${JSON.stringify(n)}))('ForeverConfig_Extended',A)`;
  }).join('\n');
  let fixture=read('tests/harness/betterbags_navigation.lua');
  if(mutation==='startup-combat')fixture=fixture.replace('local startupCombat = false','local startupCombat = true');
  return fixture
    .replace('--@NAV_UTILITY',()=>'(function() end)(); utility=(function()\n'+native('Utility.lua')+'\nend)()')
    .replace('--@NAV_SMART',()=>native('SmartNavigation.lua'))
    .replace('--@NAV_MANAGER',()=>native('FrameControlsManager.lua'))
    .replace('--@NAV_PROMPTS',()=>native('PromptedBinding.lua')+'\n'+native('PromptedBindingFooter.lua'))
    .replace('--@NAV_CONTAINER_PROMPTS',()=>{const src=read('scratch/forever-config-inputs/ContainerFrame.lua');return src.slice(src.indexOf('local function Gamepad_OpenBagDropdownSettings()'),src.indexOf('function ContainerFrameCombinedBagsMixin:ApplySmartNavOverrideForLeftmostButton()'));})
    .replace('--@NAV_NATIVE_BAGS',()=>functions('scratch/forever-config-inputs/ContainerFrame.lua',['CloseBackpack_Combined','CloseBackpack_Individual','CloseBackpack','OpenBackpack','ToggleBackpack_Combined']))
    .replace('--@NAV_NATIVE_FOCUS',()=>functions('scratch/forever-config-inputs/ContainerFrame.lua',['ContainerFrameCombinedBagsMixin:FocusGamepad','ContainerFrameCombinedBagsMixin:UnfocusGamepad']))
    .replace('--@NAV_PRODUCT',()=>product);
}
function runNavigation(){
  execute(navigationFixture());
  execute(navigationFixture('startup-combat'));
  const controls={'missing-window':'real item/tooltip focus failed','decorative-item':'decorative duplicate remained navigable',
    'focus-theft':'bag draw stole another window focus','combat-registration':'combat registration attempted',
    'lost-close':'Circle did not release native owner','stale-native-open':'manual close retained native bag-open bookkeeping',
    'no-scroll-owner':'native scrolling binding missing',
    'raw-bindings':'addon attempted direct input stack write','lost-refocus':'native menu return lost navigation groups',
    'stale-logout':'logout work resurrected navigation'};
  for(const [mutation,expected]of Object.entries(controls)){let rejected=false,failure='no failure';try{execute(navigationFixture(mutation));}catch(error){failure=String(error);rejected=failure.includes(expected);}if(!rejected)throw Error('Surviving navigation defect control: '+mutation+' ('+failure+')');}
  return {passed:true,nativeFrameControls:true,nativeNavigation:true,nativeButtonDiscovery:true,defectControls:controls,
    limits:'Native code executed unchanged. Frame/C APIs, vectors, rendering and secure-wrapper authority modeled; no engine taint, hardware, actual scrolling or protected item-action certification.'};
}
function runDynamicCam(){
  const lock=JSON.parse(read('dependencies/lock.json'));
  const owner=lock.packages.find(p=>p.repo==='curseforge/DynamicCam');
  const base=owner.unpacked+'/DynamicCam/';
  const load=(relative)=>{
    const full='DynamicCam/'+relative,body=read(base+relative);
    if(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,base+relative))).digest('hex')!==owner.files[full])throw Error('DynamicCam source drift');
    return `assert(load(${JSON.stringify(body)},${JSON.stringify(relative)}))('DynamicCam')`;
  };
  const build=(mode)=>read('tests/harness/dynamiccam_forever.lua')
    .replace('profile.situations[id]={enabled=true',mode==='old-disabled-profile'?'profile.situations[id]={enabled=false':'profile.situations[id]={enabled=true')
    .replace('--@LIBS',()=>['Libs/LibStub/LibStub.lua','Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua','Libs/AceDB-3.0/AceDB-3.0.lua'].map(load).join('\n'))
    .replace('--@DEFAULTS',()=>load('DefaultSettings.lua'))
    .replace('--@STARTUP',()=>{
      const body=functions(base+'Core.lua',['DynamicCam:Startup']);
      return mode==='missing-initial-evaluation'?body.replace('self:ScheduleTimer("EvaluateSituations", 0.2)','-- omitted evaluation'):body;
    })
    .replace('--@EVALUATOR',()=>functions(base+'SituationManager.lua',['DynamicCam:EvaluateSituations']));
  execute(build());
  for(const [mode,expected]of Object.entries({'old-disabled-profile':'enabled contexts lost','missing-initial-evaluation':'startup never evaluated'})){
    let rejected=false;try{execute(build(mode));}catch(error){rejected=String(error).includes(expected);}
    if(!rejected)throw Error('DynamicCam negative control survived: '+mode);
  }
  return {passed:true,nativeStartup:true,nativeEvaluator:true,enabledContexts:20,transitions:7,actualAceDBLogout:true,
    limits:'Camera application/interpolation, leaf WoW C APIs and UI visibility modeled; actual engine movement remains unverified.'};
}
module.exports={run,runDynamicCam};if(require.main===module)console.log(JSON.stringify({bags:run(),camera:runDynamicCam()}));
