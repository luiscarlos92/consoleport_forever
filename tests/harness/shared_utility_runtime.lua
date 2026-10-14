-- Fresh native-source setup precedes this harness. Runtime addon modules, not
-- the deliberately failing admission prototype, are exercised below.
P=Addon.SharedUtility
local enabled=true
local hideHooks={}
function container:HookScript(event,callback) hideHooks[event]=hideHooks[event] or {} table.insert(hideHooks[event],callback) end
local function closeWheel()
    open=false for _,callback in ipairs(hideHooks.OnHide or {}) do callback(container) end pump()
end
local frameOwner=container
local runtime
api.enabled=function() return enabled and not (runtime and runtime.stopped) end
api.writeView=function(value) return runtime:Write(value) end
api.nativeAvailable=function(entry)
    if entry.native.binding then return true end
    if entry.native.ring then return env:GetSet(entry.native.ring,true)~=nil end
    return false
end
api.macroScope=function(id) if id>120 then return ctx.guid end end
api.ringScope=function(id) if not container.Shared[id] then return ctx.guid end end
local mountCollected=true
api.mountForSpell=function(id) if id==201 then return 1 end end
api.mountInfo=function() return {name='Mount',collected=mountCollected,hidden=false} end
local originalSpellInfo=CPAPI.GetSpellInfo
CPAPI.GetSpellInfo=function(id) if id=='Mount' then return {name='Mount',spellID=201} end return originalSpellInfo(id) end
api.spellInfo=CPAPI.GetSpellInfo
api.toyOwned=function(id) return id==999 and true or false end
container.Data[1]={[0]={name='Utility'}}
local model=P.New(api)
local menu=model:AddNative(env:GetStarterSet()[1])
local rite=model:AddNative({type='spell',spell='Rite',link='spell:101'})
local other=model:Add('spell',102)
local item=model:Add('item',12345)
local mount=model:AddNative({type='spell',spell=201})
local toy=model:Add('item',999)
runtime=Addon.SharedUtilityRuntime.New(model,env,1,{enabled=function() return enabled end,
    blocked=api.blocked,defer=api.defer,owner=function() return frameOwner end})
runtime:Install() model:Mark() model:Flush() pump()
check(activeSpell(101) and not activeSpell(102),'runtime initial availability incorrect')
local function hasBinding(binding) for _,action in ipairs(container.Data[1]) do if action.binding==binding then return true end end end
check(hasBinding('UNITMENU') and model.byID[menu],'native starter command dropped')
check(activeItem(999),'owned toy incorrectly required bag possession')
local function hasMount() for _,action in ipairs(container.Data[1]) do if action.spell=='Mount' then return true end end end
check(hasMount(),'collected mount lost native name execution')
mountCollected=false model:Mark('mount') model:Queue() pump()
check(not hasMount() and model.byID[mount],'uncollected mount was removed from archive or stayed active')
mountCollected=true model:Mark('mount') model:Queue() pump()
check(hasMount(),'re-collected mount failed to return')
check(#logs==0,'runtime initial projection noisy')
local beforeSpell,beforeItem,beforeRebuild=model.counts.spell,model.counts.item,refreshes
for i=1,100 do runtime:Notify('item',12345) end pump()
check(model.counts.spell==beforeSpell and model.counts.item==beforeItem+1,'runtime bag burst broadened classifications')
check(refreshes==beforeRebuild,'runtime unchanged bag burst rebuilt native rings')

-- Native event arrives before a deferred Forever callback, even with uncached
-- metadata. The event decorator must invalidate before native QueueRefresh.
catalog[101].loaded=false container:SPELLS_CHANGED()
check(not activeSpell(101) and model.byID[rite] and #logs==0,'native-first uncached spell rejected/deleted')
catalog[101].loaded=true runtime:Notify('spell',101) pump()
check(activeSpell(101),'runtime loaded spell failed to return')
ctx.spec=65 container:SPELLS_CHANGED()
check(not activeSpell(101) and activeSpell(102),'runtime spec switch leaked ability')
ctx={guid='B',spec=577,config=2} container:SPELLS_CHANGED()
check(not activeSpell(101) and activeSpell(102) and hasBinding('UNITMENU'),'runtime class switch lost native command')
ctx={guid='A',spec=66,config=1} container:SPELLS_CHANGED()
check(activeSpell(101) and #logs==0,'runtime spec/character return failed')

-- Deferral guards the native compiled rebuild, not merely the model's worker.
local heldView=Core.Copy(container.Data[1]) local heldCompiled=Core.Copy(container.compiled)
local heldRefreshes=refreshes
open=true ctx.spec=65 container:SPELLS_CHANGED() runtime:Notify('context') pump()
check(Core.Equal(container.Data[1],heldView) and Core.Equal(container.compiled,heldCompiled),'open wheel changed active/compiled projection')
check(refreshes==heldRefreshes,'open wheel performed native rebuild')
container:AssignAction({type='item',item='6948',autoassigned=true,questID=900})
check(refreshes==heldRefreshes and Core.Equal(container.compiled,heldCompiled),'native automatic extra bypassed held-wheel guard')
closeWheel()
check(not activeSpell(101) and activeSpell(102),'close failed to apply pending context')
ctx.spec=66 runtime:Notify('context') pump()
for _,guard in ipairs({'combat','editor','busy'}) do
    local before=Core.Copy(container.Data[1]) local rebuilds=refreshes
    if guard=='combat' then combat=true elseif guard=='editor' then editing=true else busy=true end
    ctx.spec=65 container:SPELLS_CHANGED() runtime:Notify('context') pump()
    check(Core.Equal(container.Data[1],before) and refreshes==rebuilds,'blocked context published through native setup')
    combat=false editing=false busy=false Callbacks:OnSafeMode() runtime:Resume() pump()
    check(activeSpell(102) and not activeSpell(101),'blocked state failed to resume')
    ctx.spec=66 runtime:Notify('context') pump()
end

-- Reject unknown context before field comparisons, classification or rebuild.
local readContext=api.context local publicOwner=Core.Copy(model.owner)
api.context=function() return {guid={__secret=true},spec=66} end
local before=Core.Copy(container.Data[1]) local rebuilds=refreshes
container:SPELLS_CHANGED() runtime:Notify('context') pump()
check(Core.Equal(model.owner,publicOwner) and Core.Equal(container.Data[1],before) and refreshes==rebuilds,'opaque context published owner/view')
api.context=readContext runtime:Notify('context') pump()

-- Native edit paths: cursor, gameplay removal, completed drag and confirmed
-- clear; automatic availability filtering never becomes explicit deletion.
cursor={'spell',1,'player',103} learned.A[66][103]=true container:CheckCursorInfo(1,true)
check(activeSpell(103),'native cursor addition lost')
local removeIndex for index,action in ipairs(container.Data[1]) do if action.spell==103 then removeIndex=index end end
container:SafeRemoveAction(1,removeIndex) pump()
check(not activeSpell(103),'native removal resurrected choice')
ctx.spec=65 container:SPELLS_CHANGED() ctx.spec=66 container:SPELLS_CHANGED()
check(not activeSpell(103),'removed spell returned on spec switch')
local editor=CreateFromMixins(env.SharedConfig.Ring)
env.MockRingMixins.MockRing.Mock=function() end
function editor:GetWidth() return 390 end function editor:SetScale() end function editor:SetScript() end
editor.EmptyText={SetShown=function() end}
function editor:EnumerateActive() return function() end end
editor.currentData=container.Data[1]
local first=Core.Copy(container.Data[1][1])
editor:SetDragEntry({GetID=function() return 1 end})
editor.dragData[1],editor.dragData[2]=editor.dragData[2],editor.dragData[1]
editor:SetDragEntry(nil) pump()
check(Core.Equal(container.Data[1][2],first),'completed native drag order lost')
ctx.spec=65 container:SPELLS_CHANGED()
local savedBefore=#model.archive.entries
Config:OnRequestWipe(1,container.Data[1],container.Data,true,false)
check(#model.archive.entries==savedBefore,'clear prompt erased choices before confirmation')
env.lastPopup.OnAccept() pump()
check(#model.archive.entries==0,'confirmed clear retained dormant choices')
ctx.spec=66 container:SPELLS_CHANGED()
check(not activeSpell(101),'confirmed clear resurrected dormant spell')

-- Restore test choices, save a native seed at PLAYER_LOGOUT and simulate the
-- exact late native OnDataLoaded path before the feature can attach next login.
model:AddNative(env:GetStarterSet()[1]) rite=model:Add('spell',101) model:Add('spell',102) model:Add('item',12345) pump()
local persisted=Core.Copy(model.archive)
local compiledBeforeLogout=Core.Copy(container.compiled)
check(runtime:SaveNativeSeed(),'native startup seed was not saved')
check(Core.Equal(compiledBeforeLogout,container.compiled),'logout seed touched protected compiled dispatch')
local nativeSeed=Core.Copy(container.Data[1])
env.ValidateSet=runtime.originalValidate container.RefreshAll=runtime.originalRefresh
for event,original in pairs(runtime.eventOriginals) do container[event]=original end
function IsLoggedIn() return true end function env:LoadModules() end function db:Load() end function container:UnregisterEvent() end
catalog[101].loaded=false container.Data[1]=Core.Copy(nativeSeed)
container:OnDataLoaded()
check(#logs==0 and hasBinding('UNITMENU'),'late startup seed validation emitted a removal/lost menu')
local reload=P.New(api,persisted)
runtime=Addon.SharedUtilityRuntime.New(reload,env,1,{enabled=function() return enabled end,blocked=api.blocked,defer=api.defer,owner=function() return frameOwner end})
runtime:Install() reload:Mark() reload:Flush() pump()
check(#reload.archive.entries==4 and not activeSpell(101),'startup archive lost choices or published uncached spell')
catalog[101].loaded=true runtime:Notify('spell',101) pump()
check(activeSpell(101),'startup loaded-data response did not restore choice')

-- Legacy GUID capture and proposal exclude the managed default utility set.
local account={} assert(Addon.Store.EnsureSchema(account,'A'))
local record=Addon.Store.GetCharacter(account,'A')
record.ringAccepted=true record.rings.sets={[1]={{type='spell',spell='Rite',link='spell:101'}},Class=Core.Copy(container.Data.Class)}
account.shared.ringProjectionGUID='A'
local baseline=Core.Copy(record.rings.sets[1])
local bridge=Addon.RingsAdapter.New({version='3.3.10',currentGUID=function() return ctx.guid end,getEnv=function() return env end,
    getDB=function() return db end,inCombat=function() return combat end,defaultSet=1},account,'A')
Addon.utilityRuntime=runtime
ctx.spec=65 container:SPELLS_CHANGED() bridge:CaptureEdits() bridge:Proposal()
check(#logs==0 and Core.Equal(record.rings.sets[1],baseline),'legacy capture overwrote shared data or repeated dormant logs')
check(Core.Equal({Class=container.Data.Class,Shared=container.Shared},otherBefore),'runtime changed unrelated ring content')

-- Queued work is inert after disable; archive survives. Foreign replacement
-- ownership cannot authorize a subsequent write through a stale adapter.
local archiveBefore=Core.Copy(reload.archive)
runtime:Notify('item',12345) runtime:Disable() enabled=false pump()
check(Core.Equal(reload.archive,archiveBefore),'disable deleted/rewrote shared archive')
enabled=true runtime.stopped=nil frameOwner={}
local prior=Core.Copy(container.Data[1]) runtime:Notify('context') pump()
check(Core.Equal(container.Data[1],prior),'foreign owner permitted stale projection')
RUNTIME_UTILITY_RESULTS={checks=checks,counts=Core.Copy(reload.counts),nativeDeferred=runtime.counts.deferredNative,
    startupMessages=#logs,receiptLimit=2,archive=Core.Copy(reload.archive),nativeSeed=nativeSeed}
TEST_SUCCESS=true
