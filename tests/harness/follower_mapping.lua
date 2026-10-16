-- Continues the native execution/proxy fixture after its counterexamples.
-- The proxy itself is still NOT qualified: this probe only solves admission.
TEST_SUCCESS=nil
--@FOLLOWER_MAPPING_SOURCE
do
local total=0
local function expect(value,message) total=total+1 assert(value,message) end
local binding='CLICK CPFOfflineFollowerProxy:LeftButton'
local ready=true
local beforeMap,beforeAdd=env.GetKindAndAction,ring.AddSecureAction
local api={blocked=function() return combat or ring:IsShown() end,
    ready=function() return ready end,binding=binding}
ring:Hide()
local mapping=assert(Addon.FollowerMappingPrototype.New(env,api))
local plain=db.ActionMap.spellID(ID) plain.autoassigned=true
local manual=Addon.Core.Copy(plain) manual.autoassigned=nil
local unrelated={type='spell',spell=999002,link='spell:999002',autoassigned=true}
ring.Data={[1]={[0]={},plain,manual,unrelated},Personal={[0]={},Addon.Core.Copy(plain)}}
ring.Shared={AccountOther={[0]={},Addon.Core.Copy(plain)}}
local originalData=Addon.Core.Copy(ring.Data)
local originalShared=Addon.Core.Copy(ring.Shared)
local function dataSlot(set,index) return ring.secureEnv.DATA[tostring(set)][index] end
for iteration=1,5 do
    ring:RefreshAll()
    expect(Addon.Core.Equal(originalData,ring.Data) and Addon.Core.Equal(originalShared,ring.Shared),
        'compiled mapping mutated authoritative native entries')
    local slot=dataSlot(1,1)
    expect(slot.type=='macro' and slot.macrotext=='/click CPFOfflineFollowerProxy LeftButton'
        and slot.macro==false and slot.spell==ID,'compiled route missing or not separated from source')
    expect(ring.widgets[1].states[1][1]=='spell' and tonumber(ring.widgets[1].states[1][2])==ID,
        'compiled route replaced native LAB spell feedback')
    expect(dataSlot(1,2).type=='spell' and dataSlot(1,3).type=='spell'
        and dataSlot('Personal',1).type=='spell' and dataSlot('AccountOther',1).type=='spell',
        'compiled follower mapping escaped native default autoassigned scope')
    ring:ToggleZoneAbilities()
    expect(#ring.Data[1]==3 and Addon.Core.Equal(originalData,ring.Data),
        'preserving source identity still allowed native duplicate re-add')
end
-- Prove that separated LAB state and secure DATA still compose into one actual
-- native ring dispatch, using a single-row ring to retain the original sample.
local savedDefault=ring.Data[1]
ring.Data[1]={[0]={},plain} ring:RefreshAll()
nativeSettings.ringPressAndHold=true ring:OnPressAndHoldChanged()
currentIndex=1 local beforeCalls=#calls
edge('LeftButton',true) edge('LeftButton',false)
expect(#calls==beforeCalls+1 and calls[#calls].toggle==true,'identity-preserving compiled mapping lost single native toggle dispatch')
ring.Data[1]=savedDefault ring:RefreshAll()
-- Actual auto-assignment removes its auto row when the spell is on a bar;
-- the manually added row and unrelated GUID/account sets remain unchanged.
C_ActionBar.FindSpellActionButtons=function() return {9} end
ring:ToggleZoneAbilities()
expect(#ring.Data[1]==2 and ring.Data[1][1]==manual,'native removal lost manual row or retained automatic entry')
expect(Addon.Core.Equal(originalData.Personal,ring.Data.Personal)
    and Addon.Core.Equal(originalShared,ring.Shared),'native removal touched other sets')
C_ActionBar.FindSpellActionButtons=function() end
ring:ToggleZoneAbilities()
expect(#ring.Data[1]==3 and ring.Data[1][3].autoassigned,'native re-entry failed to restore automatic source row')
expect(dataSlot(1,3).type=='macro' and dataSlot(1,1).type=='spell','re-entry did not map only the new automatic row')
-- Actual Forever shared admission must still classify the source as transient.
local contextAPI={context=function() return {guid='probe',spec=70,config=1} end,
    blocked=blocked,defer=function(fn) queue[#queue+1]=fn end,enabled=function() return true end,
    spellKnown=function() return true end,overrideSpell=function(id) return id end,
    spellInfo=function(id) return {spellID=id} end}
model=Addon.SharedUtility.New(contextAPI)
-- The product bootstrap seeds existing manual choices before admission; an
-- empty archive intentionally projects no manual entries on first admission.
assert(model:AddNative(manual))
runtime=Addon.SharedUtilityRuntime.New(model,env,1,{enabled=contextAPI.enabled,blocked=blocked,
    hardBlocked=function() return combat end,defer=contextAPI.defer,owner=function() return ring end})
runtime:Install() ring:RefreshAll() pump()
expect(runtime:Owns() and runtime.primed,'actual shared adapter failed mapped-entry admission')
expect(#model.archive.entries==1,'mapping persisted transient entry or lost manual choices: '..#model.archive.entries)
for _,info in ipairs(model.archive.entries) do expect(not info.autoassigned,'temporary identity entered shared archive') end
pump() detach()
-- Refresh with unresolved route leaves the original native spell available.
ready=false ring:RefreshAll()
expect(dataSlot(1,3).type=='spell','unready route removed native spell fallback')
ready=true ring:RefreshAll()
expect(dataSlot(1,3).type=='macro','ready route failed to remap transient entry')
expect(mapping:Abort() and env.GetKindAndAction==beforeMap and ring.AddSecureAction==beforeAdd,
    'abort did not restore exact public setup owners')
ring:RefreshAll()
expect(dataSlot(1,3).type=='spell','abort left a compiled proxy route')
-- A foreign replacement is not overwritten on detach; remaining wrapper must
-- fall back rather than compiling a partial route after ownership is lost.
mapping=assert(Addon.FollowerMappingPrototype.New(env,api))
local foreign=function(owner,info) return beforeMap(owner,info) end
env.GetKindAndAction=foreign
expect(not mapping:Owns(),'foreign map replacement still reported ownership')
ring:RefreshAll()
expect(dataSlot(1,3).type=='spell','foreign owner retained compiled delegate route')
expect(mapping:Abort() and env.GetKindAndAction==foreign,'abort overwrote foreign mapping owner')
env.GetKindAndAction=beforeMap
combat=true
expect(not Addon.FollowerMappingPrototype.New(env,api),'combat installed public setup mapping')
combat=false
FOLLOWER_MAPPING_RESULTS={checks=total,refreshes=5,sourceIdentityPreserved=true,
    labSpellFeedbackKindPreserved=true,nativeAutoReaddedSpell=false,
    nativeRemovalAndReentry=true,fullExecutionRouteQualified=false,
    limit='Admission only. LAB state kind is verified; actual cooldown rendering, proxy lifecycle, Retail macro authority and follower toggle semantics remain unqualified.'}
TEST_SUCCESS=true
end
