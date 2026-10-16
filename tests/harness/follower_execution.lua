-- Isolated experiment. Native ring controller/selection/compiler/dispatch are
-- injected unchanged by the runner. Frame C methods, input edges, modifiers,
-- spell metadata and cast API are doubles; no engine toggle model is invented.
--@FOLLOWER_PRODUCT
--@FOLLOWER_ZONE_SOURCE
local calls,trace={},{}
local checks,gestures=0,0
local function check(value,message) checks=checks+1 assert(value,message) end
local ID=426756
function CastSpellByID(...)
    check(hardware and trusted,'cast lost modeled secure hardware route')
    calls[#calls+1]={id=select(1,...),unit=select(2,...),toggle=select(3,...),argc=select('#',...)}
end
function CastSpellByName(...) error('unexpected named spell route') end
CPAPI.GetSpellInfo=function(id) return {spellID=tonumber(id),name='Dungeon Assistance'} end
CPAPI.GetSpellLink=function(id) return 'spell:'..tostring(id) end
CPAPI.Log=function(...) error('unexpected native rejection') end
db.Bindings.ConvertRingSetIDToDisplayName=function(_,id) return tostring(id) end
CPAPI.Index=function(value) return getmetatable(value).__index end
function ring:ChildUpdate(kind,state)
    for _,widget in ipairs(self.widgets) do
        local row=widget.states[state]
        if row then widget._state_type,widget._state_action=row[1],row[2] widget.RunCustom=nil end
    end
end
function ring:GetCurrentMetadataValue(key)
    local state=self:GetAttribute('state')
    local set=env:GetSet(tonumber(state) or state,true)
    return set and set[0] and set[0][key]
end
function ring:SafeSetMetadata(set,key,value) env:GetSet(tonumber(set) or set,true)[0][key]=value end
local transient={type='spell',spell=ID,link='spell:'..ID,autoassigned=true}
ring.Data={[1]={[0]={},Addon.Core.Copy(transient)}} ring.Shared={}
env.IsDataReady,env.IsSpellValidationReady=true,true
local currentIndex=1
-- The stick sample is a C-API double; selection itself uses the actual native
-- Radial.GetIndex and angle/deadzone calculations, as well as ring commit.
ring:SetAttribute('GetButtonsHeld','return "PADFORWARD"')
ring:RefreshAll()
local runtime,model
local queue={}
local function blocked() return combat or ring:IsShown() end
local function pump()
    for turn=1,6 do
        if #queue==0 then return end
        local batch=queue queue={} for _,fn in ipairs(batch) do fn() end
    end
    error('unexpected reconciliation loop')
end
local function attach()
    local api={context=function() return {guid='probe',spec=70,config=1} end,
        blocked=blocked,defer=function(fn) queue[#queue+1]=fn end,
        enabled=function() return true end}
    model=Addon.SharedUtility.New(api)
    runtime=Addon.SharedUtilityRuntime.New(model,env,1,{enabled=api.enabled,blocked=blocked,
        hardBlocked=function() return combat end,defer=api.defer,owner=function() return ring end})
    runtime:Install()
    ring:RefreshAll() pump()
    check(runtime:Owns() and runtime.primed,'actual shared adapter failed admission')
    check(#model.archive.entries==0 and #ring.Data[1]==1,'temporary spell leaked into shared archive')
end
local function detach()
    if runtime then runtime:Abort('experiment phase complete') runtime=nil model=nil end
end
local function edge(button,down)
    hardware=true trusted=true
    mapped.sticks[2]={x=0,y=currentIndex and 1 or 0,len=currentIndex and 1 or 0}
    fire(ring,'PreClick',button,down)
    fire(ring,'OnClick',button,down,true,true)
    fire(ring,'PostClick',button,down)
    trace[#trace+1]={button=button,down=down,casts=#calls,release=ring.attrs.typerelease,shown=ring:IsShown()}
    trusted=false hardware=false
end
local function gesture(hold,index,button)
    button=button or 'LeftButton' currentIndex=index
    local before=#calls
    edge(button,true)
    if hold then
        check(#calls==before,'ring opening unexpectedly cast')
        edge(button,false)
    else
        edge(button,false)
        check(#calls==before,'ring opening unexpectedly cast')
        edge(button,true) edge(button,false)
    end
    local expected=index or (nativeSettings.ringStickySelect and ring.Data[1][0].sticky)
    check(#calls-before==(expected and 1 or 0),'one deliberate selection emitted multiple cast calls or lost selection')
    if expected then
        local call=calls[#calls]
        check(call.id==ID and call.argc==2 and call.toggle==nil,'generic secure spell contract changed')
    end
    check(not ring:IsShown(),'commit retained ring')
    gestures=gestures+1
end
local cases={}
for _,withAdapter in ipairs({false,true}) do
    ring:Hide()
    if withAdapter then attach() end
    local before=#calls
    for _,inCombat in ipairs({false,true}) do
        combat=inCombat
        for _,hold in ipairs({true,false}) do
            nativeSettings.ringPressAndHold=hold
            trusted=true ring:OnPressAndHoldChanged() trusted=false
            for _,sticky in ipairs({false,true}) do
                nativeSettings.ringStickySelect=sticky
                trusted=true ring:OnStickySelectChanged() trusted=false
                for _,modifier in ipairs({'','shift','ctrl','alt','ctrlshift'}) do
                    FOLLOWER_MODIFIERS={shift=modifier:find('shift')~=nil,ctrl=modifier:find('ctrl')~=nil,alt=modifier=='alt'}
                    for iteration=1,3 do gesture(hold,1) end
                    gesture(hold,nil)
                end
            end
        end
    end
    combat=false FOLLOWER_MODIFIERS={}
    cases[#cases+1]={adapter=withAdapter,casts=#calls-before}
    if withAdapter then
        check(#model.archive.entries==0,'dispatch saved native transient as manual choice')
        local snapshot=Addon.Core.Copy(ring.Data[1])
        nativeSettings.ringPressAndHold=true ring:OnPressAndHoldChanged()
        currentIndex=1 edge('LeftButton',true)
        local beforeHeld=#calls runtime:Notify('context') pump()
        check(#calls==beforeHeld and Addon.Core.Equal(snapshot,ring.Data[1]),'held reconciliation changed dispatch payload')
        edge('LeftButton',false)
        check(#calls==beforeHeld+1,'held reconciliation duplicated or lost release')
        pump()
        detach()
    end
end
-- Native modal accept binding: obtain its actual Layer-produced click slug,
-- rather than treating a different physical accept key as a second opener.
nativeSettings.ringPressAndHold=false ring:OnPressAndHoldChanged()
nativeSettings.ringStickySelect=false ring:OnStickySelectChanged()
currentIndex=1
local acceptBefore=#calls
edge('LeftButton',true) edge('LeftButton',false)
local accept=overrides.PAD1 and overrides.PAD1.action
check(type(accept)=='string' and accept:match('^CLICK ConsolePortUtilityToggle:'),'native accept claim unavailable')
local acceptSlug=accept:match(':([^:]+)$')
edge(acceptSlug,true) edge(acceptSlug,false)
check(#calls==acceptBefore+1 and not ring:IsShown(),'native accept key duplicated or lost cast')
-- Adversarial replay is kept distinct from normal paired input. Native Commit
-- has no shown/armed check: another release with a deflected stick can select
-- again. This does not establish that Retail delivers such an extra event.
nativeSettings.ringPressAndHold=true ring:OnPressAndHoldChanged()
nativeSettings.ringStickySelect=false ring:OnStickySelectChanged()
gesture(true,1)
local count=#calls edge('LeftButton',false)
local replayedReleaseCalls=#calls-count
check(replayedReleaseCalls==1,'native replay characterization changed')
-- Native cancel/foreign owner behavior: cancel via its native Disable snippet,
-- then a neutral release has no selected ring action to execute.
currentIndex=nil edge('LeftButton',true)
trusted=true ring:RunAttribute('Disable') trusted=false
count=#calls edge('LeftButton',false)
check(#calls==count,'cancelled neutral ring dispatched')
-- Record the argument hypothesis without implementing speculative C behavior.
local zoneButton={GetSpellID=function() return ID end}
hardware=true trusted=true ZoneAbilityFrameSpellButtonMixin.OnClick(zoneButton) trusted=false hardware=false
check(calls[#calls].argc==3 and calls[#calls].toggle==true,'native zone handler lost toggle request')
-- Explore native click delegation separately from ring integration. The source
-- handler checks two engine-owned access predicates; neither may be assumed
-- false in Retail just because the isolated doubles permit this candidate.
local delegate=CreateFrame('Button',nil,UIParent,'PingableActionButtonTemplate')
delegate.GetSpellID=function() return ID end
delegate:SetScript('OnClick',ZoneAbilityFrameSpellButtonMixin.OnClick)
secureScripts[ZoneAbilityFrameSpellButtonMixin.OnClick]=true
local access,forbidden=false,false
function delegate:HasAccessConstraints() return access end
function delegate:HasAnyForbiddenAspects() return forbidden end
local clickProxy=CreateFrame('Button','FollowerProbeProxy',UIParent,'SecureActionButtonTemplate')
clickProxy:SetAttribute('pressAndHoldAction',true)
clickProxy:SetAttribute('typerelease','click')
clickProxy:SetAttribute('clickbutton',delegate)
local delegateCasts=0
for _,inCombat in ipairs({false,true}) do
    combat=inCombat
    for _,mask in ipairs({0,1,2}) do
        access,forbidden=mask==1,mask==2
        local before=#calls
        hardware=true trusted=true
        fire(clickProxy,'OnClick','LeftButton',true,true,true)
        fire(clickProxy,'OnClick','LeftButton',false,true,true)
        trusted=false hardware=false
        check(#calls-before==(mask==0 and 1 or 0),'native click access predicate bypassed or duplicated dispatch')
        if mask==0 then
            check(calls[#calls].toggle==true,'native delegation lost toggle request')
            delegateCasts=delegateCasts+1
        end
    end
end
combat=false
-- A direct click entry is not a supported native ring kind. A passing direct
-- proxy experiment cannot be called a qualified saved-ring representation.
local supported=pcall(env.GetKindAndAction,env,{type='click',clickbutton=delegate})
check(not supported,'native click-entry support changed; revisit integration design')
local fn,reason=BuildRestrictedClosure('local illegal = {}',restricted,'self')
check(fn==nil and reason=='Direct table creation is not permitted','pinned restricted compiler was bypassed')
local traceSamples={}
for index=math.max(1,#trace-11),#trace do traceSamples[#traceSamples+1]=trace[index] end
FOLLOWER_EXECUTION_RESULTS={checks=checks,gestures=gestures,cases=cases,
    genericCastArguments=2,nativeZoneCastArguments=3,nativeZoneToggle=true,
    pairedGestureDoubleDispatchReproduced=false,replayedReleaseCalls=replayedReleaseCalls,
    nativeAcceptCasts=1,nativeDelegateCasts=delegateCasts,nativeClickEntrySupported=false,
    inputEdges=#trace,traceSamples=traceSamples,
    limits='C cast semantics/taint/hardware timing remain modeled; argument difference is not a demonstrated cause of Retail reversal.'}
TEST_SUCCESS=true
