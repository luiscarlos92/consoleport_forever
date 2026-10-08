-- A production-like native recovery startup must not call SecureModes.Install,
-- replace native UpdateState/page snippets, create supplemental controls or own
-- gameplay bindings. Targeting alone must work through every native chord.
Addon.SecureModes.Install=function() error('targeting acquired secure modes') end
Addon.SecureModes.Probe=function() error('targeting depends on custom mode probe') end
local controls={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}
local banks={'Base','L2','R2','L2R2'}
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}
local routes={}
for bankIndex,bank in ipairs(banks) do
    for index,key in ipairs(controls) do
        local target=api['ConsolePortGroup'..bank].buttons[key]
        local slot=(bankIndex-1)*12+index
        slots[slot]={'spell',index%2==0 and 999 or 207684}
        target:SetState('','action',slot)
        local chord=modifiers[bankIndex]..key
        routes[#routes+1]={key=chord,target=target,slot=slot,ground=index%2~=0}
        engine:Register(chord,'CPFNativeTargeting'..#routes,function(down,button)
            local prior=trusted trusted,hardware=true,true
            target.scripts.OnClick(target,button,down,true,true)
            trusted,hardware=prior,false
        end)
    end
end
assert(Addon.GroundTargeting.Enable(bridge,api,true))
local wrappers=wrapCount
for _,route in ipairs(routes) do
    assert(not route.target:GetAttribute('cpf-enabled'))
    assert(route.target:GetAttribute('UpdateState')==CPAPI.ConvertSecureBody(env.SlotButton.Env.UpdateState))
end
-- Exact engine binding -> secure CP/LAB/manager wrappers -> macro/UseAction.
-- Test both cast edges, before combat, first press after focused UI, repeated
-- entry/exit, and all 32 gameplay chords with unrelated abilities interleaved.
for _,keydown in ipairs({true,false}) do
    state.keydown=keydown
    assert(Addon.GroundTargeting.Enable(bridge,api,true) and wrapCount==wrappers)
    for cycle=1,3 do
        if cycle>1 then engine:Focus() end
        engine:Combat(true) combat=true
        for _,route in ipairs(routes) do
            casts,uses,releases={},{},{}
            engine:Dispatch(route.key,true)
            if route.ground then assert(#casts==(keydown and 1 or 0)) end
            engine:Dispatch(route.key,false)
            assert(#casts==(route.ground and 1 or 0),route.key..' lost or duplicated targeted cast')
            assert(#uses==(route.ground and 0 or 1),route.key..' lost native ability dispatch')
            if not route.ground then assert(uses[1].slot==route.slot) end
            assert(route.target:GetAttribute('type')=='action')
            assert(not route.target:GetAttribute('*type-ControllerInput'))
            assert(not route.target:GetAttribute('cpf-ground-active'))
        end
        engine:Combat(false) combat=false
        engine:ForeignClaim(true)
        engine:Combat(true) combat=true
        assert(not pcall(engine.Dispatch,engine,'PAD1',true),'targeting stole foreign modal ownership')
        engine:Combat(false) combat=false engine:ForeignClaim(false)
    end
end
-- A real native resolved temporary slot gets context preferences in ANY bank,
-- not a hardcoded Forever special-bank policy. Ordinary slots ignore vehicle UI.
local target=routes[1].target
local prefs={spells={[207684]='player'},contexts={vehicle='manual'},contextSpells={vehicle={[207684]='cursor'}}}
state.family='vehicle' slots[133]={'spell',207684}
target:SetState('','action',133)
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
casts,uses={},{},{}
engine:Combat(true) combat=true
engine:Dispatch('PAD1',true) engine:Dispatch('PAD1',false)
assert(#casts==1 and casts[1].text=='/cast [@cursor] Sigil of Misery')
engine:Combat(false) combat=false
target:SetState('','action',1)
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
casts,uses={},{},{} engine:Combat(true) combat=true
engine:Dispatch('PAD1',true) engine:Dispatch('PAD1',false)
assert(#casts==1 and casts[1].text=='/cast [@player] Sigil of Misery')
engine:Combat(false) combat=false
-- Native Blizzard vehicle overflow/extra buttons use LeftButton suffix 1 and
-- preserve native action paging. Explicit contextual qualification stays local.
local extra=frame() extra.scripts.OnClick=SecureActionButton_OnClick
extra:SetAttribute('type','action') extra:SetAttribute('action',133)
api.ExtraActionButton1=extra api.OverrideActionBarButton9=frame()
local overflow=api.OverrideActionBarButton9
overflow.scripts.OnClick=SecureActionButton_OnClick
overflow:SetAttribute('type','action') overflow:SetAttribute('action',133)
names[999001]='Vehicle reticle' slots[133]={'spell',999001}
prefs={spells={},contexts={},contextSpells={vehicle={[999001]='player'},extra={[999001]='cursor'}}}
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
assert(not Addon.GroundTargeting.prepared[999001],'context qualification leaked into ordinary actions')
local function pair(target)
    casts,uses={},{},{} trusted,hardware,combat=true,true,true
    target.scripts.OnClick(target,'LeftButton',true,true,true)
    target.scripts.OnClick(target,'LeftButton',false,true,true)
    trusted,hardware,combat=false,false,false
end
pair(overflow) assert(#casts==1 and casts[1].text=='/cast [@player] Vehicle reticle')
pair(extra) assert(#casts==1 and casts[1].text=='/cast [@cursor] Vehicle reticle')
assert(overflow:GetAttribute('type')=='action' and overflow:GetAttribute('action')==133)
assert(not overflow:GetAttribute('*macrotext1'))
-- A context-only unknown reticle remains usable even when every curated
-- ordinary spell has been set to Manual; no ordinary command may leak.
for id in pairs(Addon.GroundSpells) do prefs.spells[id]='manual' end
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
assert(not next(Addon.GroundTargeting.prepared))
pair(overflow) assert(#casts==1 and casts[1].text=='/cast [@player] Vehicle reticle')
-- Disabling placement leaves all gameplay chords dispatching natively.
state.family=nil assert(Addon.GroundTargeting.Disable(api))
engine:Combat(true) combat=true
for _,route in ipairs(routes) do
    casts,uses={},{},{} engine:Dispatch(route.key,true) engine:Dispatch(route.key,false)
    assert(#uses==1 and #casts==0,'disabled placement broke native gameplay '..route.key)
end
engine:Combat(false) combat=false
TEST_SUCCESS=true
