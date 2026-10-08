-- Every round face, selected and unselected, across repeated combat cycles.
local usable,mana=true,false
installed=true
local Action={}
function IsUsableAction(slot) assert(slot==1) return usable,mana end
--@NATIVE_ACTION_USABILITY
for _,bankID in ipairs({'Base','L2','R2','L2R2'}) do
    local bank=_G['ConsolePortGroup'..bankID]
    for _,id in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do
        local face=bank.buttons[id]
        face._state_type='action' face._state_action=1 face.zoneAbilityDisabled=false
        face.config={outOfRangeColoring='button',colors={range={1,.1,.1},mana={.1,.1,1}}}
        face.IsUsable=Action.IsUsable
        for iteration=1,6 do
            combat=true usable,mana=true,false locked=false face.outOfRange=false
            -- Reproduce each visual channel independently of protected casting.
            face.icon:SetVertexColor(.4,.4,.4) face.icon:SetAlpha(.5) face.icon:SetDesaturated(true)
            fire('ACTIONBAR_UPDATE_USABLE') flush()
            assert(face.icon.tint[1]==1 and face.icon.tint[2]==1 and face.icon.tint[3]==1 and face.icon.alpha==1 and not face.icon.desaturated,'ready combat round face remains grey '..bankID..id)
            usable,mana=false,true Addon:RefreshFaceAvailability()
            assert(face.icon.tint[1]==.1 and face.icon.tint[3]==1,'actual resource restriction was erased')
            usable,mana=false,false Addon:RefreshFaceAvailability()
            assert(face.icon.tint[1]==.4,'actual unusable restriction was erased')
            usable,mana=true,false face.outOfRange=true Addon:RefreshFaceAvailability()
            assert(face.icon.tint[2]==.1,'actual range restriction was erased')
            combat=false face.outOfRange=false face:UpdateLocal()
            assert(face.__cpfFaceMask==face.IconMask and face.NormalTexture.texture:find('ForeverInGame',1,true),'round shape regressed after combat')
        end
    end
end
-- Texture:SetDesaturated allows secret booleans; never branch on the result.
local secretLock={}
local secretTrue,secretFalse={},{}
C_CurveUtil={EvaluateColorValueFromBoolean=function(value,yes,no)
    local selected=value==secretTrue or (value~=secretFalse and value==true)
    return selected and yes or no
end}
function issecretvalue(value) return value==secretLock or value==secretTrue or value==secretFalse end
local previous=C_LevelLink.IsActionLocked
C_LevelLink.IsActionLocked=function() return secretLock end
combat=true usable,mana=secretTrue,secretFalse
for _,bankID in ipairs({'Base','L2','R2','L2R2'}) do
    for _,id in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do _G['ConsolePortGroup'..bankID].buttons[id].outOfRange=secretFalse end
end
Addon:RefreshFaceAvailability()
local icon=ConsolePortGroupL2.buttons.PAD1.icon
assert(icon.tint[1]==1 and icon.tint[2]==1 and icon.tint[3]==1,'opaque ready combat availability retained grey tint')
usable,mana=secretFalse,secretTrue Addon:RefreshFaceAvailability()
assert(icon.tint[1]==.1 and icon.tint[3]==1,'opaque resource restriction lost native colour')
assert(ConsolePortGroupL2.buttons.PAD1.icon.desaturated==secretLock,'opaque lock result was discarded instead of forwarded to texture API')
C_LevelLink.IsActionLocked=previous issecretvalue=nil
combat=false TEST_SUCCESS=true
