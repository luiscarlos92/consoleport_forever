-- Execute the pinned Retail duration-object branch verbatim. The only fake
-- timing is the engine sink; CPF must never inspect or synthesize duration data.
local Action={}
local Feat_CooldownDurationObject=true
local records={}
C_ActionBar={
    GetActionCooldown=function(slot) return records[slot].normalInfo end,
    GetActionCharges=function(slot) return records[slot].chargeInfo end,
    GetActionLossOfControlCooldownInfo=function(slot) return records[slot].locInfo end,
    GetActionCooldownDuration=function(slot) return records[slot].normal end,
    GetActionChargeDuration=function(slot) return records[slot].charge end,
    GetActionLossOfControlCooldownDuration=function(slot) return records[slot].loc end,
}
local GetActionCooldownInfo,GetActionChargeInfo,GetActionLoCCooldownInfo=C_ActionBar.GetActionCooldown,C_ActionBar.GetActionCharges,C_ActionBar.GetActionLossOfControlCooldownInfo
--@NATIVE_ACTION_COOLDOWN_GETTERS
--@NATIVE_RETAIL_COOLDOWN
local count=0
for _,id in ipairs({'Base','L2','R2','L2R2'}) do
    for index,key in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do
        local face=_G['ConsolePortGroup'..id].buttons[key]
        face._state_type='action' face._state_action=index face.config={lossOfControlCooldown=true}
        for name,fn in pairs(Action) do face[name]=fn end
        face:UpdateLocal()
        for _,name in ipairs({'cooldown','chargeCooldown','lossOfControlCooldown'}) do
            local cd=face[name]
            function cd:SetCooldownFromDurationObject(value) self.duration=value self.durationWrites=(self.durationWrites or 0)+1 self:Show() end
            function cd:Clear() self.duration=nil self:Hide() end
            assert(cd:GetFrameLevel()>face:GetFrameLevel(),'native swipe hidden beneath ARTWORK icon')
            assert(cd.SetSwipeTextureArgs[1]==[[Interface\CharacterFrame\TempPortraitAlphaMask]] and cd.SetAllPointsArgs[1]==face.__cpfFaceMask,'native cooldown lost circular geometry')
            assert(cd.drawSwipe==(name~='chargeCooldown'),'native charge-edge/swipe policy changed')
        end
        local function duration()
            return setmetatable({},{__index=function() error('opaque duration inspected') end})
        end
        for _,kind in ipairs({'gcd','ability','haste-change','off-gcd','failed','finished','charges','loc','loc-replaces','missing-duration'}) do
            local active=kind=='gcd' or kind=='ability' or kind=='haste-change' or kind=='loc'
            local normal,charge,loc=duration(),duration(),duration()
            records[index]={normal=kind~='missing-duration' and normal or nil,charge=charge,loc=loc,
                normalInfo={isActive=active or kind=='loc-replaces' or kind=='missing-duration'},
                chargeInfo={isActive=kind=='charges' or kind=='loc-replaces'},
                locInfo={isActive=kind=='loc' or kind=='loc-replaces',shouldReplaceNormalCooldown=kind=='loc-replaces'}}
            combat=true UpdateCooldown(face)
            assert(face.cooldown.duration==(active and normal or nil),'cooldown sink disagrees with game normal/GCD state')
            assert(face.chargeCooldown.duration==(kind=='charges' and charge or nil),'native charge transition incorrect')
            assert(face.lossOfControlCooldown.duration==((kind=='loc' or kind=='loc-replaces') and loc or nil),'native LoC transition incorrect')
            assert(face.cooldown:IsShown()==active,'zero/failed/completed cooldown remained visible')
            count=count+1
        end
        -- Native cast VFX temporarily suppresses the swipe; its finish restores
        -- translucency and the next native cooldown update, never a fake GCD.
        face.cooldown:SetSwipeColor(0,0,0,0)
        assert(face.cooldown.swipe[4]==0)
        face.cooldown:SetSwipeColor(0,0,0,1)
        assert(face.cooldown.swipe[4]==.65)
        assert(face.chargeCooldown.drawSwipe==false)
        combat=false
    end
end
assert(count==160)
TEST_SUCCESS=true
