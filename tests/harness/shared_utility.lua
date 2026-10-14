-- Engine APIs/frames are modeled; marked native Lua bodies are hash-verified by the runner.
local Core,P=Addon.Core,Addon.SharedUtilityPrototype
local combat,open,editing,busy=false,false,false,false
local ctx={guid='A',spec=66,config=1}
local catalog={ [101]={name='Rite',loaded=true},[102]={name='Other',loaded=true},[103]={name='Override',loaded=true} }
local learned={A={[66]={[101]=true},[65]={[102]=true}},B={[577]={[102]=true}}}
local inventory={[6948]=1,[12345]=20}
local itemLoaded={[6948]=true,[12345]=true}
local overrides,macros={},{[1]={name='Personal',body='/cast Rite',icon=1}}
local queue,logs,refreshes={}, {},0
local checks=0
local cursor
function GetCursorInfo() if cursor then return table.unpack(cursor) end end
function ClearCursor() cursor=nil end
local function check(value,message) checks=checks+1 assert(value,message) end
local function known(id) return not not (((learned[ctx.guid] or {})[ctx.spec] or {})[id]) end
local function spellInfo(id)
    if type(id)=='string' then
        for spell,data in pairs(catalog) do if data.name==id and known(spell) and data.loaded then return {spellID=spell,name=data.name} end end
    elseif catalog[id] and catalog[id].loaded then return {spellID=id,name=catalog[id].name} end
    return {}
end
local function pump()
    local turns=0
    while #queue>0 do
        turns=turns+1 check(turns<5,'worker loop')
        local batch=queue queue={}
        for _,callback in ipairs(batch) do callback() end
    end
end
function CreateFromMixins(...)
    local value={} for i=1,select('#',...) do for key,item in pairs(select(i,...)) do value[key]=item end end return value
end
CopyTable=Core.Copy
function wipe(value) for key in pairs(value) do value[key]=nil end return value end
function tAppendAll(dest,src) for _,value in ipairs(src) do table.insert(dest,value) end end
tinsert,tremove=table.insert,table.remove
function Clamp(value,low,high) return math.max(low,math.min(high,value)) end
function InCombatLockdown() return combat end
function foreach(values,callback) for key,value in pairs(values) do callback(key,value) end end
function unpack(...) return table.unpack(...) end
CallbackRegistryMixin={OnLoad=function() end}
EventRegistry={RegisterCallback=function() end}
local callbacks={}
local container={GetName=function() return 'NativeUtility' end,IsShown=function() return open end}
function container:RegisterUnitEvent() end
local env={Frame=container,Attributes={MetadataIndex=0,DefaultSetBtn='LeftButton'},IsDataReady=true,IsSpellValidationReady=true,
    SharedConfig={LoadoutEntry={UnpackID=function(id) return id end}},MockRingMixins={MockRing={},MockRingButton={}},
    L={REMOVE_RING_TEXT='remove',CLEAR_RING_TEXT='clear'}}
function env:AddLoader() end
function env:RegisterCallback(event,callback,owner) callbacks[event]=callbacks[event] or {} table.insert(callbacks[event],{callback,owner}) end
function env:TriggerEvent(event,...) for _,row in ipairs(callbacks[event] or {}) do row[1](row[2],...) end end
local db=setmetatable({table={compare=Core.Equal},Bindings={Custom={UnitMenu='UNITMENU',MenuRing='MENURING'},
    ConvertRingSetIDToDisplayName=function(_,id) return tostring(id) end,GetDescriptionForBinding=function(_,id) return id,nil,id,'texture' end}},
    {__call=function() return true end})
function db:Register(name,value)
    self[name]=value
    -- Model the native database-backed addon environment's symbol lookup.
    if name=='ActionMap' then ActionMap=value end
    return value
end
function db:Save() end
function db:RegisterCallback() end
function db:RegisterSafeCallback() end
function db:TriggerEvent() end
CPAPI={DefaultRingSetID=1,ExtraActionButtonID=169,IsModernVersion=true,GetEnv=function() return env,db end,
    GetSpellInfo=spellInfo,GetSpellLink=function(id) local info=spellInfo(id) return info.spellID and 'spell:'..info.spellID end,
    GetItemInfo=function(id) return itemLoaded[id] and {itemLink=tostring(id)} or {} end,
    GetMacroInfo=function(id) return macros[id] end,GetAllMacroInfo=function() return macros end,
    MinEditDistance=function(a,b) return a==b and 0 or 10 end,
    Log=function(message,...) logs[#logs+1]=string.format(message,...) end,
    Static=function(value) return function() return value end end,
    Next=function(callback,...) local args={...} queue[#queue+1]=function() callback(table.unpack(args)) end end,
    EventHandler=function(handler) return handler end,
    CreateElement=function() local value={} env.lastElement=value return value end,
    Popup=function(_,options) env.lastPopup=options return options end}
--@NATIVE_ACTION_MAP
--@NATIVE_DATABASE
--@NATIVE_MAP
--@NATIVE_CONTAINER
local Database=db
--@NATIVE_RUN_SAFE
local Callbacks={SetUndefinedEventsAllowed=function() end,RegisterEvent=function() end,SetScript=function() end}
--@NATIVE_SAFE_QUEUE
Callbacks:OnLoad()
db.callbacks=Callbacks
local Secure=container
--@NATIVE_REFRESH
function container:ClearAllActions() check(not combat,'protected refresh during combat') refreshes=refreshes+1 self.compiled={} end
function container:AddSecureMetadata(id,data) self.compiled[id]={meta=Core.Copy(data),actions={}} end
function container:AddSecureAction(id,index,info)
    local kind,action=env:GetKindAndAction(info)
    self.compiled[id].actions[index]={kind=kind,action=action}
end
function container:SetAttribute() end
function container:IsAutoEnabled() return false end
function env:EnumerateAvailableSets() return next,self:GetAvailableSets(),nil end
--@NATIVE_EVENTS
--@NATIVE_AUTO
--@NATIVE_OBSERVER
--@NATIVE_CONFIG_RING
--@NATIVE_CONFIG_LOADOUT
local Config,L,Container={},env.L,container
--@NATIVE_CLEAR
function Config:SelectSet() env:GetData() end
function container:GetBindingDisplayNameForSetID(id) return tostring(id) end
container.Data={[1]={[0]={name='Utility',custom='keep'}},Class={[0]={name='Class'},{type='spell',spell=102}}}
container.Shared={Ping={[0]={name='Ping'},{type='custom',binding='PING'}}}
db.Rings=container
local otherBefore=Core.Copy({Class=container.Data.Class,Shared=container.Shared})
local nativeKindCalls={}
local api={context=function() return Core.Copy(ctx) end,
    issecretvalue=function(value) return type(value)=='table' and value.__secret==true end,
    defer=function(callback) queue[#queue+1]=callback end,
    blocked=function() return combat or open or editing or busy end,
    spellKnown=known,overrideSpell=function(id) return overrides[id] or id end,spellInfo=spellInfo,
    itemCount=function(id,bank,uses,reagent,account)
        check(bank==false and uses==false and reagent==false and account==false,'bank-inclusive item query')
        nativeKindCalls.item=(nativeKindCalls.item or 0)+1 return inventory[id] or 0
    end,
    itemReady=function(id) return not not itemLoaded[id] end,
    macroInfo=function(id) return macros[id] end,
    requestData=function(kind,id) nativeKindCalls[kind..':'..id]=(nativeKindCalls[kind..':'..id] or 0)+1 end,
    readView=function() return Core.Copy(container.Data[1]) end,
    writeView=function(value) Core.Replace(container.Data[1],value) container:RefreshAll() return true end}
local function activeSpell(id) for _,entry in ipairs(container.Data[1]) do if entry.spell==id then return true end end return false end
local function activeItem(id) for _,entry in ipairs(container.Data[1]) do if tonumber(entry.item)==id then return true end end return false end
local function activeMacro() for _,entry in ipairs(container.Data[1]) do if entry.type=='macro' then return true end end return false end

-- Reproduce native name failure and current Forever's repeated archive validation.
container.Data[1][1]={type='spell',spell='Rite',link='spell:101'}
container:RefreshAll() check(#logs==0,'baseline known name rejected')
local account={} assert(Addon.Store.EnsureSchema(account,'A'))
local record=Addon.Store.GetCharacter(account,'A')
record.ringAccepted=true record.rings.sets={[1]=Core.Copy(container.Data[1])} account.shared.ringProjectionGUID='A'
local legacy=Addon.RingsAdapter.New({version='3.3.10',currentGUID=function() return ctx.guid end,
    getEnv=function() return env end,getDB=function() return db end,inCombat=function() return combat end,defaultSet=1},account,'A')
ctx.spec=65 container:SPELLS_CHANGED()
check(#logs==1 and #container.Data[1]==0,'native name rejection not reproduced')
legacy:CaptureEdits() legacy:Proposal()
check(#logs>=4,'repeated dormant archive messages not reproduced')
local baselineMessages=#logs
logs={} queue={} container.Data[1]={[0]={name='Utility',custom='keep'}} ctx.spec=66

cursor={'spell',1,'player',101}
container:CheckCursorInfo(1,true)
check(cursor==nil and container.Data[1][1].spell==101,'native cursor spell did not retain numeric identity')

local model=P.New(api)
local rite=model:AddNative({type='spell',spell='Rite',link='spell:101'})
local item=model:Add('item',12345)
local hidden=model:Add('spell',102)
check(#queue==1,'add burst not coalesced') pump()
check(activeSpell(101) and not activeSpell(102),'initial learned projection incorrect')
check(activeItem(12345) and #logs==0,'initial item/spell projection noisy')
local chosen=Core.Copy(model.archive.entries)

-- Native-first ordering: a loaded numeric spell still exists when unlearned.
ctx.spec=65 container:SPELLS_CHANGED()
check(activeSpell(101) and #logs==0,'native-first catalog ID should stay resolved')
model:Notify('context') pump()
check(not activeSpell(101) and activeSpell(102),'offspec spell leaked')
check(Core.Equal(chosen,model.archive.entries),'context transition deleted saved choice')
ctx.spec=66 model:Notify('context') pump() container:SPELLS_CHANGED()
check(activeSpell(101) and not activeSpell(102),'return did not restore saved spell')
check(#logs==0,'loaded numeric transition noisy')

-- Same-class alt and different-class login, then independent saved archive hydration.
learned.C={[66]={[101]=true}} ctx.guid='C' model:Notify('context') pump()
check(activeSpell(101),'same-class alt did not share selected spell')
ctx={guid='B',spec=577,config=2} model:Notify('context') pump()
check(not activeSpell(101) and activeSpell(102),'cross-class spell leakage')
check(Core.Equal(chosen,model.archive.entries),'different character erased choices')
ctx={guid='A',spec=66,config=1} model:Notify('context') pump()
local reloaded=P.New(api,Core.Copy(model.archive)) reloaded:ResetAfterReload() pump()
check(activeSpell(101) and #reloaded.archive.entries==3,'reload lost shared choices')
model=reloaded
PERSISTENCE_SAMPLE=Core.Copy(model.archive)

-- Work invariants: no item rebuild while positive, no spell work for an item batch.
local beforeSpell,beforeRebuild=model.counts.spell,model.counts.rebuilds
local beforeWorker,beforeItem=model.counts.workers,model.counts.item
inventory[12345]=19
for i=1,100 do model:Notify('item',12345) end
check(#queue==1,'item burst queued multiple workers') pump()
check(model.counts.spell==beforeSpell,'bag batch rescanned spells')
check(model.counts.rebuilds==beforeRebuild,'positive count rebuilt utility')
local itemBurst={notifications=100,workers=model.counts.workers-beforeWorker,
    itemQueries=model.counts.item-beforeItem,spellQueries=model.counts.spell-beforeSpell,rebuilds=model.counts.rebuilds-beforeRebuild}
check(itemBurst.workers==1 and itemBurst.itemQueries==1,'item burst did not classify once')
local beforeQueries=model.counts.item
model:Notify('item',99999) model:Notify('resume') pump()
check(model.counts.item==beforeQueries and model.counts.rebuilds==beforeRebuild,'untracked/idle event added work')
inventory[12345]=0 model:Notify('item',12345) pump()
check(not activeItem(12345),'absent item leaked')
inventory[12345]=1 model:Notify('item',12345) pump()
check(activeItem(12345),'replenished item did not return')

-- Unknown metadata/opaque values do not become archive deletion or public guesses.
itemLoaded[12345]=false model:Notify('item',12345) pump()
check(not activeItem(12345) and model.cache[item].state=='pending','item data absence was not pending')
for i=1,5 do model:Notify('item',12345) pump() end
check(nativeKindCalls['item:12345']==1,'metadata request loop')
itemLoaded[12345]=true model:Notify('item',12345) pump()
check(activeItem(12345),'item data response did not restore entry')
local actualKnown=api.spellKnown api.spellKnown=function() return {__secret=true} end
model:Notify('spell',101) pump()
check(not activeSpell(101) and model.cache[rite].state=='pending','opaque learned status exposed')
api.spellKnown=actualKnown model:Notify('spell',101) pump()
learned.A[66][103]=true overrides[101]=103 model:Notify('spell',101) pump()
check(activeSpell(103) and model.archive.entries[model.byID[rite]].id==101,'override changed selected identity')
learned.A[66][101]=nil model:Notify('spell',101) pump()
check(activeSpell(103),'known override hidden because base spell was not known')
learned.A[66][101]=true
catalog[103].loaded=false model:Notify('spell',101) pump()
check(not activeSpell(103) and model.cache[rite].state=='pending','uncached override not pending')
catalog[103].loaded=true model:Notify('spell',103) pump()
check(activeSpell(103),'resolved override metadata event missed base entry')
overrides[101]=nil learned.A[66][103]=nil model:Notify('spell',101) pump()
api.spellKnown=function() error('engine getter rejected') end model:Notify('spell',101) pump()
check(model.cache[rite].state=='pending','failing learned getter manufactured state')
api.spellKnown=actualKnown model:Notify('spell',101) pump()
local realContext=api.context api.context=function() return {guid={__secret=true},spec=66} end
model:Notify('context') pump()
check(model.pendingIdentity and #model.archive.entries==3,'opaque context erased saved entries')
api.context=realContext model:Notify('context') pump()

-- Deliberate removal survives every later transition; stale edits are rejected.
local revision=model.archive.revision
check(not model:Remove(rite,revision-1),'stale deletion accepted')
check(model:Remove(rite,revision),'deliberate deletion rejected') pump()
ctx.spec=65 model:Notify('context') pump() ctx.spec=66 model:Notify('context') pump()
check(not activeSpell(101) and not model.byID[rite],'deleted choice resurrected')
rite=model:Add('spell',101) pump()

-- Native extra, duplicate identities, hidden reorder and sticky remapping.
check(container:AssignAction({type='item',item='6948',autoassigned=true,questID=900}),'native extra not assigned')
model:Notify('item',12345) pump()
check(container.Data[1][#container.Data[1]].autoassigned,'native extra not preserved')
local duplicate=model:Add('spell',101) pump()
check(model.byID[rite]~=model.byID[duplicate],'intentional duplicate collapsed')
local hiddenPosition=model.byID[hidden]
check(model:Reorder({duplicate,item,rite},model.archive.revision),'reorder rejected') pump()
check(model.byID[hidden]==hiddenPosition,'reorder moved dormant choice')
local stickyIndex
for index,id in ipairs(model.mapping) do if id==rite then stickyIndex=index end end
container.Data[1][0].sticky=stickyIndex
check(model:Reorder({rite,item,duplicate},model.archive.revision),'sticky reorder rejected') pump()
check(model.mapping[container.Data[1][0].sticky]==rite,'sticky selection retargeted')
check(Core.Equal(otherBefore,{Class=container.Data.Class,Shared=container.Shared}),'other rings changed')

-- Native mouse drag writes entries directly and emits no OnSetChanged callback.
local edits=0 env:RegisterCallback('OnSetChanged',function() edits=edits+1 end)
local editor=CreateFromMixins(env.SharedConfig.Ring)
env.MockRingMixins.MockRing.Mock=function() end
function editor:GetWidth() return 390 end function editor:SetScale() end function editor:SetScript() end
editor.EmptyText={SetShown=function() end}
function editor:EnumerateActive() return function() end end
editor.currentData=container.Data[1]
local dragStart=edits
editor:SetDragEntry({GetID=function() return 1 end})
editor.dragData[1],editor.dragData[2]=editor.dragData[2],editor.dragData[1]
editor:SetDragEntry(nil)
check(edits==dragStart,'mouse drag unexpectedly emitted OnSetChanged')
check(container.Data[1][1].type=='item' and container.Data[1][2].spell~=nil,'native drag result missing')
-- Replay the completed native operation through the stable-ID prototype contract.
local order={} for index,id in ipairs(model.mapping) do order[index]=id end
order[1],order[2]=order[2],order[1]
local manual={} for _,id in ipairs(order) do if id~=0 then manual[#manual+1]=id end end
check(model:Reorder(manual,model.archive.revision),'completed drag could not reconcile') pump()

-- Actual native gameplay removal has no config callback. Bridge requires explicit edit provenance.
local removedID=model.mapping[1] local removeStart=edits
container:SafeRemoveAction(1,1)
check(edits==removeStart,'gameplay removal unexpectedly emitted config callback')
check(model:Remove(removedID,model.archive.revision),'native removed ID not retained as deletion') pump()

-- Native loadout replacement does two rebuilds; capture completes as one shared edit burst.
local loadout=env.SharedConfig.Loadout
function loadout:InitDefault() end function loadout:ClearCollections() end
function loadout:GetScrollView() return {ReinitializeFrames=function() end} end
loadout:OnLoad() loadout:OnSelectSet(nil,1,true)
local card=env.lastElement
card.checked=true
function card:GetChecked() return self.checked end function card:SetChecked(value) self.checked=value end
function card:OnButtonStateChanged() end
local replacingID=model.mapping[1] local replaceRefreshes=refreshes
env.ReplaceID=1
card:OnSelected({id=102,funcs={map=function(map,id) return map.spellID(id) end}})
check(refreshes==replaceRefreshes+2,'native replacement baseline count changed')
check(model:Remove(replacingID,model.archive.revision),'replacement did not remove old stable ID')
local replaced=model:AddNative({type='spell',spell=102}) pump()
check(replaced and not activeSpell(102),'unlearned replacement was not retained dormant')

-- Clear popup is cancelable; merely requesting it must not erase the shared archive.
local beforeClear=Core.Copy(model.archive.entries)
local popup=Config:OnRequestWipe(1,container.Data[1],container.Data,true,false)
check(Core.Equal(beforeClear,model.archive.entries),'clear request erased archive before confirmation')
popup.OnAccept()
check(#container.Data[1]==0,'native confirmed clear did not wipe visible ring')
check(model:Clear(model.archive.revision),'explicit shared clear failed') pump()
check(#model.archive.entries==0 and not activeSpell(101),'shared clear retained dormant choices')

-- A raw macro drift can fuzzy-retarget in native validation; prototype rejects it.
macros[2]={name='Other macro',body='/cast Other',icon=1}
container.Data[1][1]={type='macro',macro=1,name='Personal',body='/cast Rite',icon=1}
macros[1]=nil container:RefreshAll()
check(container.Data[1][1].macro==2,'native macro similarity fallback not reproduced')
container.Data[1]={[0]={name='Utility'}}
macros[1]={name='Personal',body='/cast Rite',icon=1}
local macro=model:Add('macro',1,{guid='A',name='Personal',body='/cast Rite'}) pump()
check(activeMacro(),'qualified personal macro absent')
macros[1].body='/cast Edited' model:Notify('macro',1) pump()
check(not activeMacro() and model.cache[macro].state=='pending','macro drift retargeted execution')
macros[1]=nil model:Notify('macro',1) pump()
check(not activeMacro() and model.cache[macro].state=='pending','macro drift retargeted execution')
ctx={guid='B',spec=577,config=2} model:Notify('context') pump()
check(not activeMacro(),'personal macro leaked across GUID')
ctx={guid='A',spec=66,config=1} model:Notify('context') pump()

-- Bounded deferral and resume: no worker loop during combat/open ring/Edit Mode.
rite=model:Add('spell',101) pump()
for _,block in ipairs({'combat','open','editing','busy'}) do
    if block=='combat' then combat=true elseif block=='open' then open=true elseif block=='editing' then editing=true else busy=true end
    inventory[12345]=1 local pendingItem=model:Add('item',12345) pump()
    check(model.pending and not activeItem(12345),'blocked projection wrote native ring')
    check(#queue==0,'blocked worker rescheduled itself')
    combat,open,editing,busy=false,false,false,false
    model:Notify('resume') pump() check(activeItem(12345),'deferred projection stranded')
    check(model:Remove(pendingItem,model.archive.revision),'pending item cleanup failed') pump()
end
local beforeGuard=refreshes local guardedKnown=api.spellKnown
api.spellKnown=function(id) open=true return guardedKnown(id) end
model:Notify('spell',101) pump()
check(model.pending and refreshes==beforeGuard,'open state changed during classification but projection wrote')
open=false api.spellKnown=guardedKnown model:Notify('resume') pump()
combat=true ctx.spec=65 container:SPELLS_CHANGED()
check(next(Callbacks.runSafeClosures)~=nil,'native combat refresh not queued')
model:Notify('context') pump()
combat=false Callbacks:OnSafeMode() model:Notify('resume') pump()
check(not activeSpell(101),'combat end did not reconcile current spec')
ctx.spec=66 model:Notify('context') pump()

-- Identity changing within classification cannot publish a stale result.
local query=api.spellKnown
api.spellKnown=function(id) ctx={guid='B',spec=577,config=2} return query(id) end
model:Notify('spell',101) pump()
check(model.pending and model.owner.guid=='A','stale classification published')
api.spellKnown=query model:Notify('context') pump()
check(not activeSpell(101),'stale prior character action persisted')
ctx={guid='A',spec=66,config=1} model:Notify('context') pump()

-- Persistent receipt bounds and drift-aware failure, including a new VM/model.
for i=1,10 do ctx.spec=(i%2==0 and 66 or 65) model:Notify('context') pump() end
check(#model.receipts<=2,'projection receipts unbounded')
local writer=api.writeView
api.writeView=function(value) writer(value) error('after write') end
ctx.spec=65 model:Notify('context') pump()
check(model.receipts[#model.receipts].status=='recovery-required','failed write not retained')
local recovery=P.New(api,Core.Copy(model.archive)) recovery:ResetAfterReload() pump()
check(recovery.receipts[#recovery.receipts].status=='recovery-required','reload discarded recovery requirement')
api.writeView=writer
container.Data[1][0].custom='foreign edit'
check(not recovery:Recover(),'recovery overwrote foreign edit')
check(container.Data[1][0].custom=='foreign edit','foreign edit lost')
Core.Replace(container.Data[1],recovery.receipts[#recovery.receipts].desired)
check(recovery:Recover(),'owned failed write not recoverable')
check(Core.Equal(container.Data[1],recovery.receipts[#recovery.receipts].desired),'recovery reinstalled old spec view')
recovery:Notify('resume') pump()
check(#recovery.receipts<=2,'recovery receipt bound lost')

-- Counterexample retained: uncached numeric metadata can be rejected before delayed preprocessing.
ctx={guid='A',spec=66,config=1} catalog[101].loaded=true
container.Data[1]={[0]={name='Utility'},{type='spell',spell=101}}
local beforeUncached=#logs catalog[101].loaded=false
container:SPELLS_CHANGED()
check(#logs>beforeUncached,'uncached native-first limitation was hidden')
local unresolvedMessages=#logs-beforeUncached
catalog[101].loaded=true
check(model:AddNative({type='spell',spell='Ambiguous'})==nil,'ambiguous name guessed ID')
check(model:AddNative({type='item',item='6948',autoassigned=true})==nil,'transient action archived')
PROTOTYPE_RESULTS={checks=checks,baselineMessages=baselineMessages,uncachedNativeFirstMessages=unresolvedMessages,
    counts=Core.Copy(model.counts),itemBurst=itemBurst,receiptLimit=2,
    limitation='No runtime integration/taint/hardware/CPU-time proof; C APIs and rendering modeled.'}
TEST_SUCCESS=true
