-- Native binding -> ConsolePort/LAB wrappers -> Blizzard action dispatch.
-- No Forever casting wrapper may consume a reticle or a user macro slot.
Addon.SecureModes.Install=function() error('native dispatch acquired suspended modes') end
local controls={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}
local banks={'Base','L2','R2','L2R2'}
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}
local routes={}
for bankIndex,bank in ipairs(banks) do
    -- The retained TemporaryRouting startup initializes LAB's header owner.
    -- Use its actual initializer; do not invent an owner argument in run().
    local group=api['ConsolePortGroup'..bank]
    --@RETAINED_HEADER_INIT
    for index,key in ipairs(controls) do
        local target=api['ConsolePortGroup'..bank].buttons[key]
        local slot=(bankIndex-1)*12+index
        slots[slot]={index%2==0 and 'macro' or 'spell',207684}
        target:SetState('','action',slot)
        local chord=modifiers[bankIndex]..key
        routes[#routes+1]={key=chord,target=target,slot=slot}
        engine:Register(chord,'NativeAction'..#routes,function(down,button)
            local prior=trusted trusted,hardware=true,true
            target.scripts.OnClick(target,button,down,state.engineFlags and true or nil,state.engineFlags and true or nil)
            trusted,hardware=prior,false
        end)
    end
end
local wrappers=wrapCount
for _,engineFlags in ipairs({true,false}) do
    state.engineFlags=engineFlags
    for _,keydown in ipairs({true,false}) do
        state.keydown=keydown
        for cycle=1,3 do
            if cycle>1 then engine:Focus() end
            engine:Combat(true) combat=true
            for _,route in ipairs(routes) do
                casts,uses,releases={},{},{}
                engine:Dispatch(route.key,true)
                engine:Dispatch(route.key,false)
                assert(#uses==1 and uses[1].slot==route.slot,'native action lost or duplicated '..route.key)
                assert(#casts==0,'native slot converted into a Forever targeting macro')
                assert(route.target:GetAttribute('type')=='action')
                assert(route.target:GetAttribute('UpdateState')==CPAPI.ConvertSecureBody(env.SlotButton.Env.UpdateState))
                assert(not route.target:GetAttribute('*macrotext-ControllerInput'))
            end
            engine:Combat(false) combat=false
            engine:ForeignClaim(true) engine:Combat(true) combat=true
            assert(not pcall(engine.Dispatch,engine,'PAD1',true),'native dispatch stole foreign modal ownership')
            engine:Combat(false) combat=false engine:ForeignClaim(false)
        end
    end
end
-- The real template dispatches supplemental vehicle/extra buttons unchanged.
for _,slot in ipairs({133,137}) do
    local target=frame() target.scripts.OnClick=SecureActionButton_OnClick
    target:SetAttribute('type','action') target:SetAttribute('action',slot)
    slots[slot]={'spell',207684}
    casts,uses={},{},{} trusted,hardware,combat=true,true,true
    target.scripts.OnClick(target,'LeftButton',true,true,true)
    target.scripts.OnClick(target,'LeftButton',false,true,true)
    trusted,hardware,combat=false,false,false
    assert(#uses==1 and uses[1].slot==slot and #casts==0,'supplemental action was intercepted')
end
assert(wrapCount==wrappers,'native dispatch installed unexpected wrappers')
TEST_SUCCESS=true
