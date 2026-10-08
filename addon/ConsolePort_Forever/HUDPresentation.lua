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
local CIRCLE = [[Interface\CharacterFrame\TempPortraitAlphaMask]]
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
function HUD.CircleMask(mask)
    if not HUD.Atlas(mask,'CircleMask') then
        mask:SetTexture(CIRCLE,'CLAMPTOBLACKADDITIVE','CLAMPTOBLACKADDITIVE')
    end
    mask:Show()
end
function HUD.RetireMasqueNormal(button)
    -- RemoveButton applies Masque's default skin; UseStates=false leaves a
    -- separately drawn Normal_Custom region alive after its registry is cleared.
    -- It is not returned by Button:GetNormalTexture or the native field.
    local config=button._MSQ_CFG
    local extra=config and config.Normal_Custom
    if extra then extra:SetTexture(nil) extra:SetAlpha(0) extra:Hide() end
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
            HUD.CircleMask(localMask)
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
function HUD.FaceLayers(button)
    -- The native template declares SlotBackground after Icon on BACKGROUND/0.
    -- Masque's default icon reset restores that same layer. Our black matte
    -- therefore covered the image even when its tint/opacity were fully usable.
    button.icon:SetDrawLayer('ARTWORK',0)
    if button.SlotBackground then button.SlotBackground:SetDrawLayer('BACKGROUND',-1) end
    for _,key in ipairs({'SlotBackground','SlotArt'}) do
        local texture=button[key]
        if texture and texture.Show and not texture.__cpfFilledWatch then
            texture.__cpfFilledWatch=true
            hooksecurefunc(texture,'Show',function() HUD.EmptyVisibility(button) end)
        end
    end
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
    if occupied then
        button.__cpfEmptyArt:Hide()
        if button.__cpfFaceMask and button.SlotBackground then button.SlotBackground:Hide() end
        if button.__cpfFaceMask and button.SlotArt then button.SlotArt:Hide() end
    else button.__cpfEmptyArt:Show() if button.icon then button.icon:Hide() end end
end
local STATE_ATLASES={
    NormalTexture='normal',PushedTexture='pressed',HighlightTexture='hover',CheckedTexture='selected',
    SpellHighlightTexture='hover',NewActionTexture='hover',Border='iconframe-border',
}
function HUD.RoundRegion(texture, button, key, mask, imageOnly)
    if not texture then return end
    local state=STATE_ATLASES[key]
    local atlas=key=='Border' and 'gamepad-actionbar-circleslot-iconframe-border'
        or state and ('gamepad-actionbar-circleslot-border-'..state)
    local fallback=not atlas or not HUD.Atlas(texture,atlas)
    if fallback then
        HUD.Sprite(texture,key=='Border' and 'border' or 'frame')
        texture:SetVertexColor(key=='PushedTexture' and .6 or 1,key=='PushedTexture' and .6 or 1,key=='PushedTexture' and .6 or 1,1)
    end
    if not imageOnly then
        texture:ClearAllPoints()
        texture:SetPoint('CENTER',button) texture:SetSize(button:GetWidth(),button:GetWidth())
    end
    texture:SetAlpha(1)
    if key=='NormalTexture' then texture:Show() end
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
    f:SetParent(parent) f:ClearAllPoints() f:SetPoint(point,parent,relativePoint,x,y) f:SetSize(#keys*22+(#keys-1)*14,22)
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
function HUD.MirrorBank(frame,bank)
    frame.__cpfMirrorBank=bank frame.__cpfMirrorEnabled=true
    if frame.SetScript and bank.GetAlpha then
        frame:SetScript('OnUpdate',function() frame:SetAlpha(frame.__cpfMirrorBank:GetAlpha()) end)
        frame:SetAlpha(bank:GetAlpha())
    end
    if bank.HookScript then
        bank.__cpfFollowers=bank.__cpfFollowers or setmetatable({},{__mode='k'})
        bank.__cpfFollowers[frame]=true
        if not bank.__cpfFollowerWatch then
            bank.__cpfFollowerWatch=true
            bank:HookScript('OnHide',function()
                for follower in pairs(bank.__cpfFollowers) do if follower.__cpfMirrorBank==bank then follower:Hide() end end
            end)
            bank:HookScript('OnShow',function()
                for follower in pairs(bank.__cpfFollowers) do
                    if follower.__cpfMirrorBank==bank and follower.__cpfMirrorEnabled then follower:Show() end
                end
            end)
        end
    end
    if bank.IsShown and not bank:IsShown() then frame:Hide() else frame:Show() end
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
    local f=Prompt(bank,'__cpfBankPrompt',keys,'BOTTOM','BOTTOM',0,16)
    if bankID~='L2R2' and bank.buttons and bank.buttons.PADDRIGHT then
        -- A separate decorative anchor has the native INACTIVE bank transform.
        -- Selected bank scaling moves both its cells and its anchor offsets;
        -- inheriting either made the trigger jump on every modifier transition.
        local pos=bank.props and bank.props.pos
        if pos and pos.point=='BOTTOM' and pos.relPoint=='BOTTOM' and bank.SetScale then
            local anchor=bank.__cpfInactiveHintAnchor
            if not anchor then
                anchor=CreateFrame('Frame',nil,bank:GetParent()) bank.__cpfInactiveHintAnchor=anchor
            end
            local scale=(tonumber(tostring(bank.props.rescale or ''):match('(%d+)%s*$')) or 94)/100
            anchor:SetScale(scale) anchor:SetSize(bank:GetWidth(),bank:GetHeight())
            anchor:ClearAllPoints() anchor:SetPoint('BOTTOM',UIParent,'BOTTOM',pos.x,pos.y)
            f.__cpfStationary=true f:SetParent(anchor)
            f:ClearAllPoints()
            -- Native right D-pad cell starts 82.5 from the bank's left edge.
            local cell=bank.buttons.PADDRIGHT
            f:SetPoint('TOPRIGHT',anchor,'LEFT',82.5+cell:GetWidth()+12,-cell:GetHeight()/2-4)
            HUD.MirrorBank(anchor,bank)
        else
            f:ClearAllPoints() f:SetPoint('TOPRIGHT',bank.buttons.PADDRIGHT,'BOTTOMRIGHT',12,-4)
        end
    end
end
function HUD.PlaceBank(bank)
    local pos=bank.props and bank.props.pos
    if not pos or pos.point~='BOTTOM' or pos.relPoint~='BOTTOM' then return end
    local y=pos.y
    -- Current 160/5 geometry is unchanged. Older 150/10 layouts can overlap
    -- Base's bottom cells with the expanded combined bank. Qualify both native
    -- 94/106 scale extremes before a combat modifier can expand either bank.
    if bank==ConsolePortGroupBase then
        local lower=ConsolePortGroupL2R2
        local lowPos=lower and lower.props and lower.props.pos
        local baseCell=bank.buttons and bank.buttons.PAD1
        local highCell=lower and lower.buttons and lower.buttons.PAD4
        if lowPos and baseCell and highCell and bank.GetHeight and lower.GetHeight then
            local bottom=bank:GetHeight()/2-45-baseCell:GetHeight()/2
            local top=lower:GetHeight()/2+45+highCell:GetHeight()/2
            local minimum=((lowPos.y+top)*1.06-bottom*.94)/.94+.25
            y=math.max(y,minimum)
        end
    end
    bank:ClearAllPoints() bank:SetPoint(pos.point,UIParent,pos.relPoint,pos.x,y)
end
function HUD.Rect(frame)
    if not frame or not frame.GetRect or not frame.GetEffectiveScale then return end
    local x,y,w,h=frame:GetRect()
    local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
    if not Public(x) or not Public(y) or not Public(w) or not Public(h) or not Public(scale)
        or type(x)~='number' or type(y)~='number' or type(w)~='number' or type(h)~='number' then return end
    return {x=x*scale,y=y*scale,w=w*scale,h=h*scale}
end
function HUD.Overlap(a,b,gap)
    gap=gap or 0
    local epsilon=.001 -- Scaling can put touching edges a few ulps apart.
    return a.x < b.x+b.w+gap-epsilon and a.x+a.w+gap > b.x+epsilon
        and a.y < b.y+b.h+gap-epsilon and a.y+a.h+gap > b.y+epsilon
end
local function Bounds(frame)
    local box=HUD.Rect(frame)
    local child=frame.prompt and HUD.Rect(frame.prompt)
    if box and child then
        local x,y=math.min(box.x,child.x),math.min(box.y,child.y)
        box={x=x,y=y,w=math.max(box.x+box.w,child.x+child.w)-x,h=math.max(box.y+box.h,child.y+child.h)-y}
    end
    return box
end
function HUD.LayoutGuard()
    if InCombatLockdown() then return end
    if not UIParent or not UIParent.GetEffectiveScale then return false end
    local obstacles,ornaments,extremes={},{},{}
    for _,id in ipairs({'Base','L2','R2','L2R2'}) do
        local bank=_G['ConsolePortGroup'..id]
        if bank and bank.buttons then
            for _,button in pairs(bank.buttons) do
                local rect=HUD.Rect(button)
                if rect then
                    obstacles[#obstacles+1]=rect
                    -- Fit once against both native bank size extremes, rather
                    -- than finding a different gap after each selection.
                    if bank.GetScale and bank.props and bank.props.pos and bank.props.pos.point=='BOTTOM' then
                        local current=bank:GetScale()
                        for _,scale in ipairs({.94,1.06}) do
                            local ratio=scale/current
                            local center=UIParent:GetWidth()/2
                            extremes[#extremes+1]={x=center+(rect.x-center)*ratio,y=rect.y*ratio,w=rect.w*ratio,h=rect.h*ratio}
                        end
                    end
                end
            end
            if bank.__cpfBankPrompt and bank.__cpfBankPrompt:IsShown() then ornaments[#ornaments+1]=bank.__cpfBankPrompt end
        end
    end
    local base=ConsolePortGroupBase
    if base and base.__cpfClassShortcut and base.__cpfClassShortcut:IsShown() then ornaments[#ornaments+1]=base.__cpfClassShortcut end
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    local failures,shifted=0,0
    local function Fits(rect,stationary)
        if rect.x<4 or rect.y<4 or rect.x+rect.w>width-4 or rect.y+rect.h>height-4 then return false end
        for _,other in ipairs(obstacles) do if HUD.Overlap(rect,other,4) then return false end end
        if stationary then for _,other in ipairs(extremes) do if HUD.Overlap(rect,other,4) then return false end end end
        return true
    end
    for _,frame in ipairs(ornaments) do
        local box=Bounds(frame)
        if box then
            local stationary=frame.__cpfStationary
            local placed=Fits(box,stationary)
            if not placed then
                -- Only move unprotected decorative groups. Keep all spell cells
                -- at their native anchors. Search nearby clear, fully visible space.
                local original=HUD.Rect(frame)
                local cx=math.max(4,math.min(box.x,width-box.w-4))-box.x
                local cy=math.max(4,math.min(box.y,height-box.h-4))-box.y
                for radius=0,96,8 do
                    for _,direction in ipairs({{0,1},{-1,0},{1,0},{0,-1},{-1,1},{1,1}}) do
                        local dx,dy=cx+direction[1]*radius,cy+direction[2]*radius
                        local candidate={x=box.x+dx,y=box.y+dy,w=box.w,h=box.h}
                        if Fits(candidate,stationary) then
                            local scale=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
                            frame:ClearAllPoints()
                            frame:SetPoint('BOTTOMLEFT',UIParent,'BOTTOMLEFT',(original.x+dx)*scale,(original.y+dy)*scale)
                            box=candidate placed=true shifted=shifted+1 break
                        end
                    end
                    if placed then break end
                end
            end
            if placed then obstacles[#obstacles+1]=box else failures=failures+1 end
        else failures=failures+1 end
    end
    if Addon.Diagnostics then Addon.Diagnostics:SetFeature('hudGeometry',failures==0 and 'offline-verified' or 'pending',
        failures==0 and ('Decorative groups fit visible bounds; '..shifted..' adjusted around collisions') or ('No clear space near '..failures..' groups; native cells retained')) end
    return failures==0
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
    if not valid then
        if badge then badge.__cpfMirrorEnabled=false badge:Hide() end
        if Addon.Diagnostics then Addon.Diagnostics:SetFeature('classShortcut','pending',
            not chord and 'installed class ring opener is not bound' or 'class ring icon or device glyph unavailable') end
        return
    end
    if not badge then
        badge=CreateFrame('Frame',nil,bank:GetParent()) bank.__cpfClassShortcut=badge

        badge.icon=badge:CreateTexture(nil,'ARTWORK') badge.icon:SetAllPoints()
        badge.mask=badge:CreateMaskTexture(nil,'BACKGROUND') badge.mask:SetAllPoints()
        HUD.CircleMask(badge.mask)
        HUD.Mask(badge.icon,badge.mask)
        badge.border=badge:CreateTexture(nil,'OVERLAY') badge.border:SetAllPoints()
        if not HUD.Atlas(badge.border,'gamepad-actionbar-circleslot-border-normal') then HUD.Sprite(badge.border,'frame') end
    end
    badge:SetSize(26,26) badge:ClearAllPoints()
    local side=chord==Addon.ClassActions.LEFT_CHORD and 'L2' or 'R2'
    local group=_G['ConsolePortGroup'..side]
    local anchor=group and group.buttons and group.buttons.PADDDOWN
    if not anchor then badge:Hide() return end
    badge:SetPoint('TOP',anchor,'BOTTOM',0,-8)
    badge.icon:SetTexture(icon)
    local prompt=Prompt(badge,'prompt',keys,'TOP','BOTTOM',0,-2)
    prompt:SetSize(#keys*18+(#keys-1)*10,18)
    for i,texture in ipairs(prompt.icons) do
        texture:ClearAllPoints() texture:SetPoint('LEFT',prompt,'LEFT',(i-1)*28,0) texture:SetSize(18,18)
    end
    for i,plus in ipairs(prompt.plus) do plus:ClearAllPoints() plus:SetPoint('LEFT',prompt,'LEFT',i*28-10,0) end
    HUD.MirrorBank(badge,group)
    if Addon.Diagnostics then Addon.Diagnostics:SetFeature('classShortcut','offline-verified','class ring badge displayed below '..side) end
end
function HUD.Watch()
    local db=DB()
    if not db or db.__cpfHUDWatch or not db.RegisterCallback then return end
    db.__cpfHUDWatch=true
    db:RegisterCallback('OnIconsChanged',function() Addon:RequestSkinRefresh() end)
    db:RegisterCallback('OnModifierChanged',function() Addon:RequestSkinRefresh() end)
end
