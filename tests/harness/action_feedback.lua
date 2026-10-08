-- Native button-state semantics and actual Masque late texture reset. Engine
-- state visibility is a double; physical CLICK dispatch stays covered by T41/42.
local SkinRoot={Pushed={Texture='native-square-depress',DrawLayer='ARTWORK',DrawLevel=0}}
local Settings={Pushed={}}
local BASE_BLEND,BASE_SIZE,STR_COLOR,STR_HIGHLIGHT='BLEND',36,'Color_','Highlight'
local Store_Color={Pushed=true}
--@NATIVE_MASQUE_TEXTURE
--@NATIVE_BUTTON_DOWN_UP
local casts=0
function TryUseActionButton(button,down) casts=casts+1 return false end
local function visiblePress(button)
    local texture=button:GetPushedTexture()
    local layer,level=texture:GetDrawLayer()
    local iconLayer,iconLevel=button.icon:GetDrawLayer()
    local order={BACKGROUND=1,BORDER=2,ARTWORK=3,OVERLAY=4,HIGHLIGHT=5}
    return button:GetButtonState()=='PUSHED' and texture:GetAlpha()>0
        and (order[layer]>order[iconLayer] or (layer==iconLayer and (level>iconLevel
            or (level==iconLevel and texture.sequence>button.icon.sequence))))
end
local count=0
for _,atlasAvailable in ipairs({false,true}) do
    C_Texture=atlasAvailable and {GetAtlasInfo=function() return {} end} or nil
    for _,id in ipairs({'Base','L2','R2','L2R2'}) do
        local bank=_G['ConsolePortGroup'..id] bank.actionButtons={}
        for index,key in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do
            local face=bank.buttons[key]
            combat=false
            if not face.PushedTexture then face.PushedTexture=region(face) end
            function face:GetPushedTexture() return self.PushedTexture end
            function face:GetButtonState() return self.engineState or 'NORMAL' end
            function face:SetButtonState(state) self.engineState=state end
            bank.actionButtons[index]=face
            face._state_type='action' face._state_action=index face.zoneAbilityDisabled=false
            face.config={outOfRangeColoring='button',colors={range={1,.1,.1},mana={.1,.1,1}}}
            local usable,mana=true,false
            function face:IsUsable() return usable,mana end
            -- Retain declaration order in the ordinary case, and reproduce a
            -- later icon replacement (already covered by T24) in fallback mode.
            if not atlasAvailable then face.icon=region(face) face.icon:SetTexture('native-spell') end
            face:UpdateLocal()
            local mask=face.icon.mask
            local normal=face.NormalTexture and face.NormalTexture.texture
            local cooldownWrites=face.cooldown.durationWrites or 0
            for _,state in ipairs({'ready','unusable','mana','range','cooldown','empty'}) do
                usable=state~='unusable' and state~='mana' mana=state=='mana' face.outOfRange=state=='range'
                face._state_type=state=='empty' and 'empty' or 'action'
                -- A late upstream writer must not retain a square or hide press
                -- art under the icon, in either combat or normal rendering.
                combat=false Core.Skin_Texture('Pushed',face.PushedTexture,face,{})
                combat=state~='ready' face:UpdateButtonArt()
                face:SetButtonState('NORMAL')
                MultiActionButtonDown('ConsolePortGroup'..id,index)
                assert(visiblePress(face),'native press feedback hidden by icon')
                local tex=face:GetPushedTexture()
                assert(tex.texture==[[Interface\AddOns\ConsolePort\Assets\Textures\Cursor\RoundBorderHighlight]] and tex.blend=='ADD','pressed surface is not original round highlight')
                assert(tex.tint[1]==1 and tex.tint[2]==.82 and tex.tint[3]==.15,'pressed feedback lost golden colour')
                assert(face.cooldown.durationWrites==nil or face.cooldown.durationWrites==cooldownWrites,'failed press invented cooldown')
                MultiActionButtonUp('ConsolePortGroup'..id,index)
                assert(not visiblePress(face),'released press remains highlighted')
                assert(face.icon.mask==mask and (not face.NormalTexture or face.NormalTexture.texture==normal),'press changed resting round design')
                if state=='ready' then assert(face.icon.tint[1]==1 and not face.SlotBackground:IsShown(),'press restored grey matte') end
                if state=='mana' then assert(face.icon.tint[1]==.1 and face.icon.tint[3]==1,'press erased resource colour') end
                if state=='range' then assert(face.icon.tint[2]==.1,'press erased range colour') end
                count=count+1
            end
        end
    end
end
assert(count==192 and casts==384)
combat=false C_Texture=nil
TEST_SUCCESS=true
