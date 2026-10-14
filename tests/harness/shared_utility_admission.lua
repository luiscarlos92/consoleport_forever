-- Runs after the native-source setup in shared_utility.lua, in a fresh VM.
-- This prototype intentionally has no production hook installer.
local Admission=Addon.SharedUtilityAdmissionPrototype
local function choiceCount(model) return #model.archive.entries end
local function newModel()
    queue={} logs={} ctx={guid='A',spec=66,config=1}
    catalog[101].loaded=true catalog[102].loaded=true
    container.Data[1]={[0]={name='Utility'}}
    local model=P.New(api)
    model:Add('spell',101) model:Add('spell',102) model:Add('item',12345)
    pump()
    return model
end

-- A native RefreshAll posthook is too late to intercept validation messages.
local model=newModel()
local originalRefresh=container.RefreshAll
container.RefreshAll=function(self,...)
    local result=originalRefresh(self,...)
    model:Notify('context')
    return result
end
catalog[101].loaded=false container:SPELLS_CHANGED()
check(#logs==1,'post-refresh hook did not reproduce native-first rejection')
check(choiceCount(model)==3,'native rejection erased saved choice')
container.RefreshAll=originalRefresh

-- Public admission can prevent that particular message. It is an ordinary
-- function replacement; offline execution cannot qualify its Retail taint.
model=newModel()
local admission=Admission.New(model,env,1)
admission:Install()
container:RefreshAll()
catalog[101].loaded=false container:SPELLS_CHANGED()
check(#logs==1 and not activeSpell(101),'cache invalidation counterexample was concealed')
admission:Uninstall()
model=newModel() admission=Admission.New(model,env,1) admission:Install(true)
container:RefreshAll()
catalog[101].loaded=false container:SPELLS_CHANGED()
check(#logs==0 and not activeSpell(101),'synchronous event invalidation did not prevent native rejection')
check(choiceCount(model)==3,'event admission deleted uncached choice')
catalog[101].loaded=true model:Notify('spell',101) container:RefreshAll()
check(activeSpell(101) and #logs==0,'admission failed to restore cached spell')
ctx.spec=65 container:SPELLS_CHANGED()
check(not activeSpell(101) and activeSpell(102),'native-first spec admission leaked spell')
ctx={guid='B',spec=577,config=2} container:SPELLS_CHANGED()
check(not activeSpell(101) and activeSpell(102),'native-first class admission leaked spell')
ctx={guid='A',spec=66,config=1} container:SPELLS_CHANGED()
check(activeSpell(101) and not activeSpell(102),'native-first return lost choices')

-- Native removal has no configuration OnSetChanged requirement.
container:RemoveAction(1,1)
check(choiceCount(model)==2 and not activeSpell(101),'native removal resurrected visible spell')
ctx.spec=65 container:SPELLS_CHANGED() ctx.spec=66 container:SPELLS_CHANGED()
check(not activeSpell(101),'deleted spell reappeared after spec return')
cursor={'spell',1,'player',101} container:CheckCursorInfo(1,true)
check(activeSpell(101) and choiceCount(model)==3,'cursor addition not admitted before validation')

-- Actual native drag writes directly, then calls RefreshAll.
local configRing=CreateFromMixins(env.SharedConfig.Ring)
env.MockRingMixins.MockRing.Mock=function() end
function configRing:GetWidth() return 390 end
function configRing:SetScale() end function configRing:SetScript() end
configRing.EmptyText={SetShown=function() end}
function configRing:EnumerateActive() return function() end end
configRing.currentData=container.Data[1]
local first=container.Data[1][1].type
configRing:SetDragEntry({GetID=function() return 1 end})
configRing.dragData[1],configRing.dragData[2]=configRing.dragData[2],configRing.dragData[1]
configRing:SetDragEntry(nil)
check(container.Data[1][2].type==first and choiceCount(model)==3,'native drag was not captured')

-- Confirmed Clear wipes metadata before SelectSet validates. Hidden choices
-- need an explicit-clear signal; an ordinary missing-active diff is insufficient.
ctx.spec=65 container:SPELLS_CHANGED()
local beforeClear=choiceCount(model)
Config:OnRequestWipe(1,container.Data[1],container.Data,true,false)
check(choiceCount(model)==beforeClear,'opening clear prompt changed archive')
env.lastPopup.OnAccept()
local remainingAfterClear=choiceCount(model)
check(remainingAfterClear==0,'confirmed clear retained hidden choices')
check(not activeSpell(102),'confirmed clear did not remove visible choice')
ctx.spec=66 container:SPELLS_CHANGED()
check(not activeSpell(101),'confirmed clear resurrected hidden choice')
check(Core.Equal({Class=container.Data.Class,Shared=container.Shared},otherBefore),'admission modified another ring')

-- Detaching only the validator must restore the exact original function.
admission:Uninstall()
check(env.ValidateSet==admission.original,'prototype failed to detach')
local qualifiedCounts=Core.Copy(admission.counts)
local qualifiedMessages=#logs

-- This seam bypasses the model worker's open-wheel guard: native RefreshAll
-- asks it for a projection synchronously, while the wheel is still held open.
model=newModel() admission=Admission.New(model,env,1) admission:Install(true)
container:RefreshAll()
open=true ctx.spec=65 container:SPELLS_CHANGED()
local openWheelChanged=not activeSpell(101) and activeSpell(102)
check(openWheelChanged,'open-wheel bypass counterexample was concealed')
open=false admission:Uninstall()

-- Late attachment cannot repair a message already emitted by OnDataLoaded.
model=newModel() catalog[101].loaded=false
function IsLoggedIn() return true end
function env:LoadModules() end
function db:Load() end
function container:UnregisterEvent() end
container:OnDataLoaded()
local startupMessages=#logs
check(startupMessages==1,'native late-load startup counterexample was concealed')
admission=Admission.New(model,env,1) admission:Install(true)
admission:Uninstall()

-- Native menu bindings are real existing utility choices, not spell/item
-- records. Importing only the qualified two types drops them in this seam.
model=newModel()
container.Data[1][#container.Data[1]+1]=env:GetStarterSet()[1]
admission=Admission.New(model,env,1)
admission:Install(true) container:RefreshAll()
local starterPreserved=false
for _,action in ipairs(container.Data[1]) do if action.binding=='UNITMENU' then starterPreserved=true end end
check(not starterPreserved,'unqualified native starter-kind counterexample was concealed')
admission:Uninstall()

-- Unknown/secret context must never reach field comparisons or classification.
model=newModel() admission=Admission.New(model,env,1) admission:Install(true)
local contextReader=api.context
api.context=function() return {guid={__secret=true},spec=66,config=1} end
container:RefreshAll()
local opaqueOwnerAccepted=type(model.owner.guid)=='table' and model.owner.guid.__secret==true
check(opaqueOwnerAccepted,'opaque admission context counterexample was concealed')
api.context=contextReader admission:Uninstall()

ADMISSION_RESULTS={checks=checks,posthookMessages=1,staleAdmissionCacheMessages=1,admittedMessages=qualifiedMessages,
    hiddenAfterConfirmedClear=remainingAfterClear,counts=qualifiedCounts,
    blockers={openWheelChanged=openWheelChanged,startupMessages=startupMessages,
        nativeStarterDropped=not starterPreserved,opaqueOwnerAccepted=opaqueOwnerAccepted},
    limitation='Not runtime qualified: open-wheel bypass, late-load startup rejection, unsupported native starter kinds and opaque context reproduced; feature disable and Retail taint unqualified.'}
TEST_SUCCESS=true
