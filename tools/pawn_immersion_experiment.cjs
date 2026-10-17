// R16 standalone source experiment. Never loaded by addon or shipping bootstrap.
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const parser = require('luaparse');
const {lua,lauxlib,lualib,to_luastring,to_jsstring} = require('fengari');
const root = fs.realpathSync(path.resolve(__dirname,'..'));
const runtime=process.argv.includes('--runtime');
const base = 'scratch/pawn-immersion-inputs/';
function safe(p) {
  const candidate=path.resolve(root,p), real=fs.realpathSync(candidate);
  if(!real.startsWith(root+path.sep) || real!==candidate) throw Error('Noncanonical/outside source: '+p);
  for(let f=candidate; f!==root; f=path.dirname(f)) if(fs.lstatSync(f).isSymbolicLink()) throw Error('source alias');
  return real;
}
// Strip only the optional UTF-8 BOM when embedding a file inside a Lua chunk.
const read=p=>fs.readFileSync(safe(p),'utf8').replace(/^\uFEFF/,'');
const hash=p=>crypto.createHash('sha256').update(fs.readFileSync(safe(p))).digest('hex');
function output(relative) {
 const target=path.resolve(root,relative);
 if(!target.startsWith(root+path.sep+'scratch'+path.sep))throw Error('Experiment output must be in scratch');
 for(let f=target; f!==root; f=path.dirname(f))if(fs.existsSync(f)&&fs.lstatSync(f).isSymbolicLink())throw Error('output alias');
 fs.mkdirSync(path.dirname(target),{recursive:true});safe(path.relative(root,path.dirname(target)));return target;
}
const manifestPath='evidence/pawn-immersion/2026-10-16/'+(runtime?'runtime':'experiment')+'-inputs.json';
const manifest=JSON.parse(read(manifestPath));
for(const row of manifest.files) if(hash(base+row.path)!==row.sha256) throw Error('Input drift: '+row.path);
const excerpts=[];
function exprName(n) { return !n?'':n.type==='Identifier'?n.name:exprName(n.base)+n.indexer+exprName(n.identifier); }
function select(file,names,source=read(base+file)) {
  const ast=parser.parse(source,{luaVersion:'5.1',ranges:true,locations:true});
  const found=new Map();
  function walk(n) { if(!n||typeof n!=='object')return;
    if(n.type==='FunctionDeclaration' && n.identifier) found.set(exprName(n.identifier),n);
    for(const [k,v] of Object.entries(n)) if(k!=='range'&&k!=='loc') Array.isArray(v)?v.forEach(walk):walk(v);
  } walk(ast);
  return names.map(name=>{const n=found.get(name); if(!n)throw Error('Missing actual function: '+name);
    excerpts.push({file,name,line:n.loc.start.line,endLine:n.loc.end.line}); return source.slice(...n.range);
  }).join('\n');
}
const prelude=read('tests/harness/pawn_immersion_environment.lua');
const pawn=select('Pawn/VgerCore/VgerCore.lua',['VgerCore.ThrottleDelayCore','VgerCore.Throttle'])+`\ndo\n${read(base+'Pawn/Localization.lua')}\n${read(base+'Pawn/Pawn.lua')}\n${runtime?'':'function SetPawnInitialized(v) PawnIsInitialized=v end'}\nend\n`;
const frame='local Frame,Inspector,L,API = ImmersionFrame,ImmersionFrame.Inspector,ImmersionL,ImmersionAPI\n'+
  select('Immersion/Logic/Frame.lua',['Frame:SetItemTooltip','Frame:GetItemColumn','Frame:ShowItems','Frame:UpdateItems'])+'\n';
const pool='do local self=ImmersionFrame.Inspector; local Inspector,L=self,ImmersionL\n'+
 select('Immersion/Logic/Inspector.lua',['self.tooltipFramePool:Acquire','self.tooltipFramePool:ReleaseAll','self.tooltipFramePool:EnumerateActive','Inspector:OnShow','Inspector:OnHide','Inspector:OnUpdate'])+'\nend\n';
const compare='TooltipComparisonManager={}\n'+select('Native/Interface/AddOns/Blizzard_SharedXMLGame/Tooltip/TooltipComparisonManager.lua',['TooltipComparisonManager:CreateComparisonItem'])+'\n'+
select('Native/Interface/AddOns/Blizzard_GameTooltip/Mainline/GameTooltip.lua',['GameTooltip_ShowCompareItem'])+'\n';
const tooltip=`(function(...)\n${read(base+'Immersion/Components/Tooltip.lua')}\nend)('Immersion',ImmersionL)\n`+
 select('Immersion/Logic/Controller.lua',['Inspector:ShowFocusedTooltip'])+'\n';
const utils='do local L=ImmersionL; local _="Immersion"\n'+select('Immersion/Utils.lua',['L.Create'])+'\nend\n';
const scaler=`;(function(...)\n${read(base+'Immersion/Components/Scaler.lua')}\nend)('Immersion',ImmersionL);\n`;
const elements=`;(function(...)\n${read(base+'Immersion/Components/Elements.lua')}\nend)('Immersion',ImmersionL);\n`;
const prepared=process.argv.includes('--prepared');
const better=read(base+(prepared?'BetterBagsPrepared':'BetterBags')+'/integrations/pawn.lua')+'\n';
const providers='do local items,database = BetterItems,BetterDatabase\n'+select((prepared?'BetterBagsPrepared':'BetterBags')+'/data/items.lua',['items:RegisterUpgradeProvider','items:GetActiveUpgradeProvider','items:ResolveUpgrade'])+'\nend\n';
const nativeXml=read(base+'Native/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.xml');
const arrow=nativeXml.match(/<Texture parentKey="UpgradeIcon" atlas="([^"]+)"[\s\S]*?<Anchor point="([^"]+)" x="([^"]+)" y="([^"]+)"/);
if(!arrow)throw Error('Missing actual bag upgrade artwork');
const xml=read(base+'Immersion/Display/Frame.xml');
const template=xml.slice(xml.indexOf('<GameTooltip name="ImmersionItemTooltipTemplate"'),xml.indexOf('</GameTooltip>',xml.indexOf('<GameTooltip name="ImmersionItemTooltipTemplate"')));
const onshow=template.match(/<OnShow>([\s\S]*?)<\/OnShow>/)[1];
const bindings=`NATIVE_BAG_ARROW=${JSON.stringify(arrow[1])}; NATIVE_BAG_ANCHOR=${JSON.stringify(arrow[2])}\n`+
 `function NativeTooltipOnShow(self) ${onshow} end\n`;
const prototype=read('tests/prototypes/pawn_immersion.lua');
const addonSource=runtime?read('addon/ConsolePort_Forever/UI/PawnImmersion.lua'):'';
let aceSource='',eventSource='';
if(runtime){
 const toc=read('addon/ConsolePort_Forever/ConsolePort_Forever.toc');
 if(!toc.match(/^## OptionalDeps:.*\bPawn\b/m) || !toc.includes('UI\\PawnImmersion.lua')
   || toc.indexOf('UI\\PawnImmersion.lua')>toc.indexOf('\nConsolePort_Forever.lua')
   || read(base+'Pawn/Pawn.toc').match(/^## LoadOnDemand:\s*1/m)
   || !read(base+'Pawn/PawnUI.xml').includes('RegisterEvent("PLAYER_LOGIN")'))throw Error('Pawn startup load contract unavailable');
 const lock=JSON.parse(read('dependencies/lock.json')).packages.find(p=>p.repo==='Cidan/BetterBags');
 const ace='BetterBags/libs/AceAddon-3.0/AceAddon-3.0.lua';
 if(hash(lock.unpacked+'/'+ace)!==lock.files[ace])throw Error('AceAddon lookup source drift');
 aceSource='do local AceAddon={addons={}}\n'+select(ace,['AceAddon:GetAddon','GetModule'],read(lock.unpacked+'/'+ace))+`\nlocal bags=LibStub('AceAddon-3.0'):GetAddon('BetterBags');bags.modules={Items=BetterItems,Events=bags:GetModule('Events')};bags.GetModule=GetModule;AceAddon.addons.BetterBags=bags;function LibStub(name,silent)if name=='AceAddon-3.0' then return AceAddon end;if not silent then error('missing library')end end\nend\n`;
 eventSource='do local Frame,Events,API,L=ImmersionFrame,ImmersionFrame,ImmersionAPI,ImmersionL\n'+
 select('Immersion/Logic/Frame.lua',['Frame:OnEvent','Frame:ResetElements','Frame:PlayIntro'])+'\n'+
 select('Immersion/Logic/Events.lua',['Events:QUEST_COMPLETE','Events:QUEST_DETAIL','Events:QUEST_ITEM_UPDATE'])+'\nend\n';
}
const boot=runtime?aceSource+eventSource+'Addon={}\n;(function(...)\n'+addonSource+'\nend)("ConsolePort_Forever",Addon)\n'+'do\n'+read('tests/harness/pawn_immersion_runtime_boot.lua')+'\nend\n':'';
const source=prelude+bindings+pawn+utils+scaler+elements+frame+pool+compare+tooltip+providers+
 `(function(...) ${better}\nend)('BetterBags')\n`+boot+read('tests/harness/pawn_immersion_setup.lua')+
 (runtime?'function NewBridge() local b=TEST_BOOT_BRIDGE or Addon.PawnImmersion.New(TEST_OWNER,_G);Addon.PawnImmersion.instance=b;return b end\n':prototype+'\nfunction NewBridge()return Bridge.New()end\n')+
 read('tests/harness/pawn_immersion.lua')+(runtime?'\n'+read('tests/harness/pawn_immersion_runtime.lua'):'');
const runtimeMutations={
 hardcoded:['local verdict=self.api.PawnShouldItemLinkHaveUpgradeArrow(link,true)','local verdict=true'],
 'hardcoded-text':["self.api.PawnUpdateTooltip(tooltip:GetName(),'SetHyperlink',link)","tooltip:AddLine('Protection: +28% upgrade')"],
 itemlevel:['local verdict=self.api.PawnShouldItemLinkHaveUpgradeArrow(link,true)','local verdict=MODEL.items[link].Level>MODEL.base.Level'],
 'pending-false':['local verdict=self.api.PawnShouldItemLinkHaveUpgradeArrow(link,true)','local verdict=self.api.PawnShouldItemLinkHaveUpgradeArrow(link,true) or false'],
 'stale-widget':['self:UpdateArrow(item);self:RetryTip(item)',"self:Arrow(item):SetShown(self.api.PawnShouldItemLinkHaveUpgradeArrow(record.link,true));self:RetryTip(item)"],
 'duplicate-lines':['if record and record.link==link and record.annotated then return end','if false then return end'],
 'unbounded-retry':['or self.attempts>=8',''],
 'scope-leak':["or (item.type~='choice' and item.type~='reward')",''],
 'hidden-refresh':['or not self.frame:IsVisible()',''],
 'premature-readiness':['and observed[api] and observed[api].ready','and observed[api]'],
 'missing-initialization-observer':["api.hooksecurefunc('PawnInitialize',function()","api.hooksecurefunc('PawnOnLogout',function()"],
 'padding-loss':['layout.onShow(tooltip);self:LayoutPending(tooltip,layout)','self:LayoutPending(tooltip,layout)'],
 'pool-owner-loss':['and self.inspector.tooltipFramePool==self.pool',''],
 'retained-inspector':['local tips=self.tips','local tips={}'],
};
function execute(mutation,workload=false,enabled=false,bagsFirst=false) {
 const L=lauxlib.luaL_newstate();
 for(const [n,f] of [['_G',lualib.luaopen_base],['table',lualib.luaopen_table],['string',lualib.luaopen_string],['math',lualib.luaopen_math]]) {
  lauxlib.luaL_requiref(L,to_luastring(n),f,1); lua.lua_pop(L,1);
 }
 for(const n of ['dofile','loadfile','load']) {lua.lua_pushnil(L);lua.lua_setglobal(L,to_luastring(n));}
 let body=source;
 if(runtime && runtimeMutations[mutation]) {const [before,after]=runtimeMutations[mutation];if(!body.includes(before))throw Error('Missing mutation target');body=body.replaceAll(before,after);if(mutation==='stale-widget')body=body.replaceAll('self:Identity(item)==record.link','true');if(mutation==='scope-leak')body=body
   .replace('function Bridge:TooltipOwned(tooltip)',"function Bridge:TooltipOwned(tooltip) if tooltip:GetName()=='ForeignTooltip' then return true end")
   .replace('for _,button in ipairs(self.buttons) do if button==item then return true end end','if true then return true end');}
 const program=`RUNTIME=${runtime}; PREPARED=${prepared}; MUTATION=${JSON.stringify(mutation)}; WORKLOAD_ONLY=${workload}; BRIDGE_ENABLED=${enabled}; BAGS_FIRST=${bagsFirst}\n`+body;
 const rc=lauxlib.luaL_loadbuffer(L,to_luastring(program),null,to_luastring('R16-experiment'))||lua.lua_pcall(L,0,0,0);
 if(rc!==lua.LUA_OK){ const e=to_jsstring(lua.lua_tostring(L,-1)); const n=Number(e.match(/\]:(\d+):/)?.[1]);
  if(!mutation)fs.writeFileSync(output('scratch/pawn-immersion-expanded.lua'),program);
  throw Error(e+(n?'\n'+program.split('\n').slice(n-2,n+1).join('\n'):'')); }
 lua.lua_getglobal(L,to_luastring('EXPERIMENT_RESULT'));
 if(!lua.lua_isstring(L,-1)) throw Error('No explicit receipt');
 const result=JSON.parse(to_jsstring(lua.lua_tostring(L,-1)));
 if(runtime){lua.lua_getglobal(L,to_luastring('RUNTIME_RESULT'));if(lua.lua_isstring(L,-1))result.runtime=JSON.parse(to_jsstring(lua.lua_tostring(L,-1)));}
 lua.lua_close(L);return result;
}
const result=execute('');
const lateLoad=execute('',false,false,true);
if(result.assertions!==lateLoad.assertions)throw Error('Load order changes tested cases');
const workload={nativeOnly:execute('',true,false),withBridge:execute('',true,true)};
if(workload.withBridge.bridgeRefreshes!==1 || workload.nativeOnly.nativeCompareCalls!==workload.withBridge.nativeCompareCalls || workload.nativeOnly.poolFrames!==workload.withBridge.poolFrames)
 throw Error('Comparable workload changes native comparison/pool bounds or fails coalescing');
const controls=[];
const expectedFailures={'hardcoded':'non-upgrade summary has no arrow','hardcoded-text':'Pawn generated output parity','itemlevel':'summary upgrade arrow',
 'pending-false':'budget exhaustion schedules retry','stale-widget':'stale generation/link result rejected','duplicate-lines':'repeated hook cannot duplicate annotation',
 'lose-on-compare':'L2 selected note retained','unbounded-retry':'finite pending attempts','scope-leak':'Required Items unchanged',
 'hidden-refresh':'hidden native refresh cannot restart queries'};
if(runtime)Object.assign(expectedFailures,{'premature-readiness':'runtime queried before actual Pawn initialization',
 'missing-initialization-observer':'observed actual Pawn initialization did not activate bridge',
 'padding-loss':'native tooltip padding lost or accumulated on refresh','pool-owner-loss':'replaced pool owner retained arrow',
 'retained-inspector':'retained inspector lost annotation owner on UpdateItems'});
for(const [name,expected] of Object.entries(expectedFailures)) {
 let failure;try {execute(name);}catch(e){failure=e.message;}
 if(!failure || !failure.includes(expected))throw Error(name+' did not fail its intended assertion: '+failure);
 controls.push({name,rejected:true,expectedAssertion:expected,error:failure.split('\n')[0]});
}
const inventory={};
for(const file of ['tools/capture_pawn_immersion_experiment.py','tools/pawn_immersion_experiment.cjs','tests/prototypes/pawn_immersion.lua',
 'tests/harness/pawn_immersion_environment.lua','tests/harness/pawn_immersion_setup.lua','tests/harness/pawn_immersion.lua']) inventory[file]=hash(file);
if(runtime)for(const file of ['tests/harness/pawn_immersion_runtime_boot.lua','tests/harness/pawn_immersion_runtime.lua',
 'addon/ConsolePort_Forever/UI/PawnImmersion.lua','addon/ConsolePort_Forever/ConsolePort_Forever.toc','addon/ConsolePort_Forever/ConsolePort_Forever.lua'])inventory[file]=hash(file);
const report={stage:'isolated experiment only',betterBags:prepared?'v0.5.16 prepared':'v0.5.14 installed',...result,
 loadOrders:{pawnFirst:result.assertions,bagsFirst:lateLoad.assertions},workload,controls,excerpts,
 sourceManifestSHA256:hash(manifestPath),experimentInventory:inventory,
 limits:['Item cache/stat parsing inputs and C APIs are modeled; actual Pawn upgrade arithmetic/formatting execute.',
 'Frame engine, text metrics, scheduling, protected/secret semantics, rendering and hardware timing are modeled.',
 'Not an addon initialization, Retail acceptance, persistence/taint or measured CPU proof.']};
if(runtime){report.stage='Forever integration source qualification';report.runtimeSHA256=hash('addon/ConsolePort_Forever/UI/PawnImmersion.lua');
 report.limits[0]='Real Pawn initialization/event/plugin bodies execute; options migration, UI/keybinding setup and scale parsing subsystems are modeled. Actual upgrade arithmetic and tooltip formatting execute.';
 report.limits[2]='Native initialization and quest event ordering are exercised with C/UI models; no Retail acceptance, persistence/taint or measured CPU proof.';}
const destination=output('scratch/test-results/pawn-immersion'+(runtime?'-runtime':'')+(prepared?'-prepared':'')+'.json');
fs.writeFileSync(destination,JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify({assertions:report.assertions,scenarios:report.scenarios,negativeControls:controls.length,report:path.relative(root,destination)}));
