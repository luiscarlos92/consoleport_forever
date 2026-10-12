-- Original Blizzard Forever callback is an oracle, not shipped Retail code.
-- Its privileged C functions are explicit host models. This test prevents
-- describing our cancel-all macro as the stock first-success chain.
local calls,state={},{}
function SpellStopCasting()
    calls[#calls+1]='cast' local success=state.cast state.cast=false return success
end
function SpellStopTargeting()
    calls[#calls+1]='ground' local success=state.ground state.ground=false return success
end
function ClearTarget()
    calls[#calls+1]='target' local success=state.target state.target=false return success
end
local icon=setmetatable({},{__index=function() return function() end end})
local button={SpecialActionIcon=icon,SlotArt=icon}
function button:RegisterForClicks(...) self.edges={...} end
function button:SetScript(name,callback) assert(name=='OnClick') self.click=callback end
function button:ApplyPressedStyle(down) self.down=down end
--@NATIVE_FOREVER_BACK
SetupNonBindableBack({PageUnit={actionBars={topBar={Right={ActionButton3=button}}}}})
local cases=0
for mask=0,7 do
    local cast,ground,target=mask%2==1,math.floor(mask/2)%2==1,math.floor(mask/4)%2==1
    state={cast=cast,ground=ground,target=target} calls={}
    button.click(button,'LeftButton',true)
    local expected=cast and 'cast' or ground and 'cast,ground' or 'cast,ground,target'
    assert(table.concat(calls,',')==expected,'native first-success priority changed')
    assert(state.cast==false)
    assert(state.ground==(cast and ground or false),'native cast cancellation also cancelled reticle')
    assert(state.target==((cast or ground) and target or false),'native cancellation also cleared target')
    local count=#calls button.click(button,'LeftButton',false)
    assert(#calls==count and button.down==false,'native Back release dispatched cancellation')
    cases=cases+5
end
SERIALIZED_STATE='Native Forever Circle assertions: '..cases
TEST_SUCCESS=true
