-- Actual Masque Icon and art-reset functions; only engine setters are doubles.
local BASE_LAYER,BASE_LEVEL,BASE_SIZE='BACKGROUND',0,36
local TYPE_BACKPACK,TYPE_ITEM,STR_BORDER='Backpack','Item','BORDER'
local function Skin_Mask() end -- Mask ownership/roundness is independently exercised in T24.
local function SetEmpty() end -- No shadow/gloss in this layer-order reproduction.
local Hook_Icon={}
--@NATIVE_MASQUE_ICON
--@NATIVE_MASQUE_ART
--@NATIVE_TEMPLATE_ORDER
local layers={BACKGROUND=1,BORDER=2,ARTWORK=3,OVERLAY=4,HIGHLIGHT=5}
local spellPixel={.90,.75,.35}
local function pixel(button)
    local regions={button.icon,button.SlotBackground}
    table.sort(regions,function(a,b)
        local al,bl=layers[a.layer[1]],layers[b.layer[1]]
        if al~=bl then return al<bl end
        if a.layer[2]~=b.layer[2] then return a.layer[2]<b.layer[2] end
        return a.sequence<b.sequence
    end)
    local out={0,0,0}
    for _,r in ipairs(regions) do
        if r:IsShown() then
            local tint=r.tint or {1,1,1,1}
            local colour=r==button.icon and {spellPixel[1]*tint[1],spellPixel[2]*tint[2],spellPixel[3]*tint[3],r:GetAlpha()} or r.SetColorTextureArgs
            if colour then
                for i=1,3 do out[i]=colour[i]*colour[4]+out[i]*(1-colour[4]) end
            end
        end
    end
    return out
end
local function assertPixel(face,expected,message)
    local result=pixel(face)
    for channel=1,3 do assert(math.abs(result[channel]-expected[channel])<.0001,message) end
end
local checkedFaces,checkedKinds,redraws=0,0,0
installed=true combat=false locked=false
local oldHasAction=C_ActionBar and C_ActionBar.HasAction or HasAction
C_ActionBar=C_ActionBar or {}
local occupied=true
C_ActionBar.HasAction=function() return occupied end
for _,bankID in ipairs({'Base','L2','R2','L2R2'}) do
    for _,id in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do
        local face=_G['ConsolePortGroup'..bankID].buttons[id]
        checkedFaces=checkedFaces+1
        face._state_action=2 face.zoneAbilityDisabled=false face.outOfRange=false
        face.config={outOfRangeColoring='button',colors={range={1,.1,.1},mana={.1,.1,1}}}
        local usable,mana=true,false
        function face:IsUsable() return usable,mana end
        face._MSQ_CFG.bType='Action' face._MSQ_CFG.Enabled=false face._MSQ_CFG.IsEmptyType=false
        -- A held custom action preserves its native icon; named base art is covered in T24.
        face.attributes['cpf-held']=true
        local mask=face.__cpfFaceMask
        for _,kind in ipairs({'action','spell','item','macro','flyout','custom'}) do
            checkedKinds=checkedKinds+1
            for cycle=1,6 do
                combat=false occupied=true usable,mana=true,false face.outOfRange=false
                face._state_type=kind
                -- Execute Masque's real default-icon reset and native XML draw order.
                face.icon.sequence=NATIVE_ICON_ORDER face.SlotBackground.sequence=NATIVE_BACKGROUND_ORDER
                face.SlotBackground:SetDrawLayer('BACKGROUND',0)
                Core.Skin_Icon(face.icon,face,{})
                face:UpdateLocal() face.icon:Show()
                assertPixel(face,spellPixel,'ready white-tinted round spell darkened by placeholder backdrop')
                assert(not face.SlotBackground:IsShown() and not face.SlotArt:IsShown(),'filled round face retains native background/art')
                assert(not face.__cpfEmptyArt:IsShown(),'filled round face retains empty device glyph')
                local iconLayer,iconLevel=face.icon:GetDrawLayer()
                local bgLayer,bgLevel=face.SlotBackground:GetDrawLayer()
                assert(iconLayer=='ARTWORK' and iconLevel==0 and bgLayer=='BACKGROUND' and bgLevel==-1,'native icon reset lost distinct draw layers')
                -- Exercise both combat and peace redraws, including independent late Show calls.
                for _,inCombat in ipairs({true,false}) do
                    combat=inCombat
                    UpdateButtonArt(face)
                    face.SlotBackground:Show()
                    assert(not face.SlotBackground:IsShown(),'late SlotBackground Show covered a filled spell')
                    face.SlotArt:Show()
                    assert(not face.SlotArt:IsShown(),'late SlotArt Show covered a filled spell')
                    face:UpdateButtonArt()
                    redraws=redraws+1
                    assert(not face.SlotBackground:IsShown() and not face.SlotArt:IsShown(),'native art reset covered a filled spell')
                    assertPixel(face,spellPixel,'native art reshow darkened ready icon')
                    assert(face.icon.mask==mask and face.__cpfFaceMask==mask,'layer repair regressed round mask')
                    -- Slot clear and refill can happen while combat locks geometry.
                    face._state_type='empty' face:UpdateLocal()
                    assert(face.__cpfEmptyArt:IsShown() and not face.icon:IsShown(),'empty round face lost original grey glyph artwork')
                    face._state_type=kind face:UpdateLocal() face.icon:Show()
                    assert(not face.__cpfEmptyArt:IsShown(),'refilled round face retained empty glyph')
                    assertPixel(face,spellPixel,'refilled face darkened by stale background')
                end
                if kind=='action' then
                    -- HasAction=false is a real empty action slot, not an unavailable spell.
                    combat=true occupied=false face:UpdateLocal()
                    assert(face.__cpfEmptyArt:IsShown() and not face.icon:IsShown(),'empty action slot lost default device art')
                    occupied=true face:UpdateLocal() face.icon:Show()
                    -- The composition repair must still respect genuine native colour changes.
                    usable,mana=false,true UpdateUsable(face,false,true)
                    assertPixel(face,{spellPixel[1]*.1,spellPixel[2]*.1,spellPixel[3]},'resource colour lost in composed icon')
                    usable,mana=false,false UpdateUsable(face,false,false)
                    assertPixel(face,{spellPixel[1]*.4,spellPixel[2]*.4,spellPixel[3]*.4},'actual unusable colour lost in composed icon')
                    usable,mana=true,false face.outOfRange=true UpdateUsable(face,true,false)
                    assertPixel(face,{spellPixel[1],spellPixel[2]*.1,spellPixel[3]*.1},'range colour lost in composed icon')
                    face.outOfRange=false UpdateUsable(face,true,false)
                    assertPixel(face,spellPixel,'ready composed icon did not recover after restriction')
                end
                combat=false
            end
        end
        face.attributes['cpf-held']=nil
    end
end
C_ActionBar.HasAction=oldHasAction
assert(checkedFaces==16 and checkedKinds==96 and redraws==1152,'composition matrix omitted a bank, face, action kind or redraw')
TEST_SUCCESS=true
