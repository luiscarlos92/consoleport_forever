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
            local colour=r==button.icon and {spellPixel[1],spellPixel[2],spellPixel[3],1} or r.SetColorTextureArgs
            if colour then
                for i=1,3 do out[i]=colour[i]*colour[4]+out[i]*(1-colour[4]) end
            end
        end
    end
    return out
end
local face=ConsolePortGroupL2.buttons.PAD2
installed=true combat=false
face._state_type='action' face._state_action=2 face.zoneAbilityDisabled=false face.outOfRange=false
face.config={outOfRangeColoring='button',colors={range={1,.1,.1},mana={.1,.1,1}}}
function face:IsUsable() return true,false end
face._MSQ_CFG.bType='Action' face._MSQ_CFG.Enabled=false face._MSQ_CFG.IsEmptyType=false
-- Native default skin reset leaves both textures in BACKGROUND sublevel zero.
face.icon.sequence=NATIVE_ICON_ORDER face.SlotBackground.sequence=NATIVE_BACKGROUND_ORDER
Core.Skin_Icon(face.icon,face,{})
face:UpdateLocal()
face.icon:Show()
local result=pixel(face)
assert(math.abs(result[1]-spellPixel[1])<.0001 and math.abs(result[2]-spellPixel[2])<.0001,'ready white-tinted round spell darkened by placeholder backdrop')
assert(not face.SlotBackground:IsShown(),'filled round face retains grey background')
-- Native combat art resets and late Show calls must not bring back the matte.
combat=true
for iteration=1,6 do
    UpdateButtonArt(face)
    face.SlotBackground:Show() face.SlotArt:Show()
    face:UpdateButtonArt()
    assert(not face.SlotBackground:IsShown() and not face.SlotArt:IsShown(),'combat art reset covered a filled spell')
    result=pixel(face)
    assert(math.abs(result[1]-spellPixel[1])<.0001,'combat native art reshow darkened ready icon')
    assert(face.icon.mask==face.__cpfFaceMask,'layer repair regressed round mask')
end
combat=false
face._state_type='empty' face:UpdateLocal()
assert(face.__cpfEmptyArt:IsShown() and not face.icon:IsShown(),'empty round face lost original grey glyph artwork')
TEST_SUCCESS=true
