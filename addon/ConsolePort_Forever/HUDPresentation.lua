local _, Addon = ...
-- Presentation only: no bindings, secure handlers, ring data or action pages.
local HUD = {}
Addon.HUDPresentation = HUD
local BANK_MODS = {L2={'SHIFT'}, R2={'CTRL'}, L2R2={'SHIFT','CTRL'}}
local FACE_NAMES = {
    SHP={PAD1='ps-cross',PAD2='ps-circle',PAD3='ps-square',PAD4='ps-triangle'},
    LTR={PAD1='xbox-a',PAD2='xbox-b',PAD3='xbox-x',PAD4='xbox-y'},
    REV={PAD1='xbox-b',PAD2='xbox-a',PAD3='xbox-y',PAD4='xbox-x'},
}
local DPAD = {PADDUP='dpadup',PADDDOWN='dpaddown',PADDLEFT='dpadleft',PADDRIGHT='dpadright'}
local CIRCLE = [[Interface\Masks\CircleMaskScalable]]
local RING = [[Interface\AddOns\ConsolePort\Assets\Textures\Cursor\RoundBorderHighlight]]
local ART = [[Interface\AddOns\ConsolePort_Forever\Assets\ForeverInGame.blp]]
-- Blizzard UiTextureAtlasMember, atlas 3024 / FileDataID 6227336.
-- Pixel boundaries from the retained original data, not reconstructed glyphs.
local SPRITES={
    ['ps-circle']={1990,2036,216,262}, ['ps-cross']={1990,2036,264,310},
    ['ps-square']={1990,2036,312,358}, ['ps-triangle']={455,501,1514,1560},
    ['xbox-a']={455,501,1562,1608}, ['xbox-b']={210,256,1942,1988},
    ['xbox-x']={210,256,1990,2036}, ['xbox-y']={463,509,1682,1728},
    dpadup={1282,1326,553,598}, dpaddown={469,513,1948,1993},
    dpadleft={469,513,1995,2040}, dpadright={1236,1280,553,598},
    frame={1093,1139,553,599}, border={1141,1187,553,599},
    shadow={1990,2047,1,59}, toggle={1189,1234,553,599},
    casting={1858,1900,553,595}, channel={1902,1944,553,595},
    interrupt={1946,1988,553,595}, aoetarget={1990,2036,168,214},
}
HUD.Sprites=SPRITES
function HUD.Sprite(texture,name)
    local r=assert(SPRITES[name],'Unknown original Forever sprite')
    texture:SetTexture(ART) texture:SetTexCoord(r[1]/2048,r[2]/2048,r[3]/2048,r[4]/2048)
end
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function DB()
    local bridge=Addon.adapters and Addon.adapters.consoleport
    if bridge and bridge.api.version=='3.3.10' then return bridge.db end
end
function HUD.Atlas(texture, name)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name) then
        texture:SetAtlas(name) return true
    end
    return false
end
function HUD.Glyph(texture, id)
    local db=DB()
    local gamepad=db and db.Gamepad
    local device=gamepad and gamepad.GetActiveDevice and gamepad:GetActiveDevice()
    if not device or not device.GetIconForButton then texture:SetTexture(nil) return false end
    local icon,atlas=device:GetIconForButton(id,64)
    if type(icon)~='string' or not Public(icon) then texture:SetTexture(nil) return false end
    if atlas then texture:SetAtlas(icon) else texture:SetTexture(icon) texture:SetTexCoord(0,1,0,1) end
    return true
end
function HUD.Mask(texture, mask)
    if not texture or not texture.AddMaskTexture then return end
    -- WoW requires texture and mask to have the same parent. VFX textures live
    -- in nested frames, unlike the icon/button-state textures.
    if texture.GetParent and mask.GetParent and texture:GetParent()~=mask:GetParent() then
        local parent=texture:GetParent()
        local localMask=texture.__cpfLocalMask
        if not localMask then
            localMask=parent:CreateMaskTexture(nil,'BACKGROUND') texture.__cpfLocalMask=localMask
            localMask:SetTexture(CIRCLE,'CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')
            localMask:SetAllPoints(texture)
        end
        mask=localMask
    end
    if texture.__cpfRoundMask==mask then return end
    if texture.__cpfRoundMask and texture.RemoveMaskTexture then texture:RemoveMaskTexture(texture.__cpfRoundMask) end
    texture:AddMaskTexture(mask) texture.__cpfRoundMask=mask
end
function HUD.EmptySlot(button, mask)
    local db=DB()
    local gamepad=db and db.Gamepad
    local device=gamepad and gamepad.GetActiveDevice and gamepad:GetActiveDevice()
    local label=device and device.Label or 'LTR'
    local name=DPAD[button.id] or ((FACE_NAMES[label] or FACE_NAMES.LTR)[button.id] or 'xbox-a')
    local atlas=DPAD[button.id] and ('gamepad-actionbar-squareslot-generic-'..name..'-normal')
        or ('gamepad-actionbar-circleslot-'..name..'-normal')
    -- Own this layer independently of LAB's texture-dependent SlotArt visibility.
    local art=button.__cpfEmptyArt or button:CreateTexture(nil,'BACKGROUND',nil,1)
    button.__cpfEmptyArt=art
    art:ClearAllPoints() art:SetPoint('CENTER',button) art:SetSize(button:GetWidth(),button:GetWidth())
    if not HUD.Atlas(art,atlas) then
        HUD.Sprite(art,name)
    end
    art:SetDesaturated(false) art:SetVertexColor(1,1,1,1)
    art:SetAlpha(1)
    -- The original empty-slot image already includes its round bevel. An icon
    -- mask would crop that bevel and change the exact reference artwork.
    HUD.EmptyVisibility(button)
    if button.SlotArt then button.SlotArt:Hide() end
end
function HUD.EmptyVisibility(button)
    if not button.__cpfEmptyArt then return end
    local kind=button._state_type
    if not Public(kind) then button.__cpfEmptyArt:Hide() return end
    local occupied=kind and kind~='empty'
    if kind=='custom' then
        local binding=Addon:ResolvedPresentationBinding(button)
        occupied=binding~=nil and binding~=''
        -- Forever's Base Circle is Exit, even though CP represents it unbound.
        occupied=occupied or (button.id=='PAD2' and button:GetParent().id=='Base')
        if binding==nil then occupied=true end -- Don't disturb a held native action.
    elseif kind=='action' then
        local slot=button._state_action
        local hasAction=C_ActionBar and C_ActionBar.HasAction or HasAction
        if hasAction and Public(slot) and type(slot)=='number' then occupied=hasAction(slot) end
    end
    if occupied then button.__cpfEmptyArt:Hide()
    else button.__cpfEmptyArt:Show() if button.icon then button.icon:Hide() end end
end
local STATE_ATLASES={
    NormalTexture='normal',PushedTexture='pressed',HighlightTexture='hover',CheckedTexture='selected',
    SpellHighlightTexture='hover',NewActionTexture='hover',Border='iconframe-border',
}
function HUD.RoundRegion(texture, button, key, mask)
    if not texture then return end
    local state=STATE_ATLASES[key]
    local atlas=key=='Border' and 'gamepad-actionbar-circleslot-iconframe-border'
        or state and ('gamepad-actionbar-circleslot-border-'..state)
    local fallback=not atlas or not HUD.Atlas(texture,atlas)
    if fallback then
        HUD.Sprite(texture,key=='Border' and 'border' or 'frame')
        texture:SetVertexColor(key=='PushedTexture' and .6 or 1,key=='PushedTexture' and .6 or 1,key=='PushedTexture' and .6 or 1,1)
    end
    texture:ClearAllPoints()
    texture:SetPoint('CENTER',button) texture:SetSize(button:GetWidth(),button:GetWidth())
    -- Flash is a fill, while borders and highlights have transparent centres.
    if key=='Flash' then texture:SetColorTexture(1,0,0,.35) HUD.Mask(texture,mask) end
end
function HUD.RoundEffects(button, mask)
    -- Blizzard's casting and interrupt frames are separate from the icon. Their
    -- masks must also be round or a cast/interrupt restores a square silhouette.
    local cast=button.SpellCastAnimFrame
    if cast then
        local fill=cast.Fill
        if fill then
            if fill.FillMask then fill.FillMask:SetTexture(CIRCLE) end
            if fill.InnerGlowTexture then
                if not HUD.Atlas(fill.InnerGlowTexture,'gamepad-actionbar-circleslot-casting') then HUD.Sprite(fill.InnerGlowTexture,'casting') end
            end
            HUD.Mask(fill.InnerGlowTexture,mask) HUD.Mask(fill.CastFill,mask)
        end
        local burst=cast.EndBurst
        if burst then
            if burst.EndMask then burst.EndMask:SetTexture(CIRCLE) end
            HUD.Mask(burst.GlowRing,mask)
        end
    end
    local interrupt=button.InterruptDisplay
    if interrupt then
        if interrupt.Highlight and interrupt.Highlight.Mask then interrupt.Highlight.Mask:SetTexture(CIRCLE) end
        if interrupt.Base then
            local base=interrupt.Base.Base
            if base and not HUD.Atlas(base,'gamepad-actionbar-circleslot-interrupt') then HUD.Sprite(base,'interrupt') end
            HUD.Mask(base,mask)
        end
    end
    local reticle=button.TargetReticleAnimFrame
    if reticle then
        if reticle.Mask then reticle.Mask:SetTexture(CIRCLE) end
        if reticle.Base and not HUD.Atlas(reticle.Base,'gamepad-actionbar-circleslot-aoetarget') then HUD.Sprite(reticle.Base,'aoetarget') end
        HUD.Mask(reticle.Base,mask)
    end
end
local function ModKey(mod)
    local db=DB()
    local index=db and db.Gamepad and db.Gamepad.Index and db.Gamepad.Index.Modifier
    return index and index.Key[mod]
end
local function Prompt(parent, field, keys, point, relativePoint, x, y)
    local f=parent[field]
    if not f then
        f=CreateFrame('Frame',nil,parent) parent[field]=f
        f.icons={f:CreateTexture(nil,'ARTWORK'),f:CreateTexture(nil,'ARTWORK'),f:CreateTexture(nil,'ARTWORK')}
        f.plus={f:CreateFontString(nil,'OVERLAY','GameFontNormal'),f:CreateFontString(nil,'OVERLAY','GameFontNormal')}
        for _,plus in ipairs(f.plus) do plus:SetText('+') plus:SetTextColor(.85,.85,.85,1) end
    end
    f:ClearAllPoints() f:SetPoint(point,parent,relativePoint,x,y) f:SetSize(#keys*22+(#keys-1)*14,22)
    local valid=#keys>0 and #keys<=3
    for i,icon in ipairs(f.icons) do
        icon:ClearAllPoints() icon:SetPoint('LEFT',f,'LEFT',(i-1)*36,0) icon:SetSize(22,22)
        if keys[i] and HUD.Glyph(icon,keys[i]) then icon:Show() else icon:Hide() if keys[i] then valid=false end end
    end
    for i,plus in ipairs(f.plus) do
        plus:ClearAllPoints() plus:SetPoint('LEFT',f,'LEFT',i*36-14,0)
        if i<#keys then plus:Show() else plus:Hide() end
    end
    if valid then f:Show() else f:Hide() end
    return f
end
function HUD.BankPrompt(bank, bankID)
    local mods=BANK_MODS[bankID]
    if not mods then return end
    local keys={}
    for _,mod in ipairs(mods) do
        local key=ModKey(mod)
        if not key then if bank.__cpfBankPrompt then bank.__cpfBankPrompt:Hide() end return end
        keys[#keys+1]=key
    end
    Prompt(bank,'__cpfBankPrompt',keys,'TOP','BOTTOM',0,10)
end
function HUD.LiftBank(bank)
    local pos=bank.props and bank.props.pos
    if not pos or pos.point~='BOTTOM' or pos.relPoint~='BOTTOM' then return end
    bank:ClearAllPoints() bank:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,pos.y+64)
end
function HUD.ClassShortcut(bank)
    local bridge=Addon.adapters and Addon.adapters.rings
    local rings=bridge and bridge.rings
    local id=bridge and bridge.api.classSet
    local badge=bank.__cpfClassShortcut
    local binding=id and rings and rings:GetBindingForSet(id)
    local classChord=bridge and (bridge.api.classChord or Addon.ClassActions.CHORD)
    local chord=binding and GetBindingAction and GetBindingAction(classChord)==binding and classChord
    local set=id and rings and rings.Data[id]
    local keys={}
    if Public(chord) and type(chord)=='string' then
        keys[#keys+1]=chord:match('(PAD[A-Z0-9]+)$') or false
        for mod in chord:gmatch('([A-Z]+)%-') do keys[#keys+1]=ModKey(mod) or false end
    end
    local entry=set and set[1]
    if set and GetNumShapeshiftForms and GetShapeshiftFormInfo then
        for slot=1,GetNumShapeshiftForms() do
            local _,active,_,spell=GetShapeshiftFormInfo(slot)
            if Public(active) and active and Public(spell) then
                for _,action in ipairs(set) do if action.type=='spell' and action.spell==spell then entry=action break end end
            end
        end
    end
    local icon=entry and entry.type=='spell' and Public(entry.spell) and C_Spell.GetSpellTexture(entry.spell)
    local valid=icon and Public(icon) and #keys>0 and #keys<=3
    for _,key in ipairs(keys) do if not key then valid=false end end
    if not valid then if badge then badge:Hide() end return end
    if not badge then
        badge=CreateFrame('Frame',nil,bank:GetParent()) bank.__cpfClassShortcut=badge
        if badge.SetIgnoreParentAlpha then badge:SetIgnoreParentAlpha(true) end
        badge.icon=badge:CreateTexture(nil,'ARTWORK') badge.icon:SetAllPoints()
        badge.mask=badge:CreateMaskTexture(nil,'BACKGROUND') badge.mask:SetAllPoints()
        badge.mask:SetTexture(CIRCLE,'CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')
        HUD.Mask(badge.icon,badge.mask)
        badge.border=badge:CreateTexture(nil,'OVERLAY') badge.border:SetAllPoints()
        if not HUD.Atlas(badge.border,'gamepad-actionbar-circleslot-border-normal') then HUD.Sprite(badge.border,'frame') end
    end
    badge:SetSize(34,34) badge:ClearAllPoints()
    local bottom=ConsolePortGroupL2R2 or bank
    -- Source PageUnit puts class actions outside the three modifier banks.
    local side=classChord==Addon.ClassActions.LEFT_CHORD and -1 or 1
    -- Native PageUnit uses +/-138,-50 against its 266x86 expanded rail.
    badge:SetPoint('CENTER',bottom,'CENTER',side*bottom:GetWidth()*138/266,-bottom:GetHeight()*50/86)
    badge.icon:SetTexture(icon)
    Prompt(badge,'prompt',keys,'TOP','BOTTOM',0,-2)
    badge:Show()
end
function HUD.Watch()
    local db=DB()
    if not db or db.__cpfHUDWatch or not db.RegisterCallback then return end
    db.__cpfHUDWatch=true
    db:RegisterCallback('OnIconsChanged',function() Addon:RequestSkinRefresh() end)
    db:RegisterCallback('OnModifierChanged',function() Addon:RequestSkinRefresh() end)
end
