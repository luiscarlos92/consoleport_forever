local _, Addon = ...
local BANKS, FACE = {Base=true,L2=true,R2=true,L2R2=true}, {PAD1=true,PAD2=true,PAD3=true,PAD4=true}
local DPAD = {PADDUP=true,PADDDOWN=true,PADDLEFT=true,PADDRIGHT=true}
local HUD = Addon.HUDPresentation
local CIRCLE = [[Interface\CharacterFrame\TempPortraitAlphaMask]]
local REGION_GETTERS={NormalTexture='GetNormalTexture',PushedTexture='GetPushedTexture',HighlightTexture='GetHighlightTexture',CheckedTexture='GetCheckedTexture'}
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function SafeVisualValue(value)
    if not Public(value) then return '[opaque]' end
    if type(value)=='number' or type(value)=='boolean' or type(value)=='string' then return value end
end
local function PaintAvailability(button,refreshUsable)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    if not button.icon or not button.icon.SetDesaturated then return end
    if button._state_type=='custom' then
        local binding=Addon:ResolvedPresentationBinding(button)
        local exit=binding=='' and button:GetParent().id=='Base' and button.id=='PAD2'
        if not exit and binding~='JUMP' and binding~='INTERACTTARGET' and binding~='TURNORACTION' then return end
    end
    if refreshUsable and type(button.IsUsable)=='function' then
        local ok,usable,mana=pcall(button.IsUsable,button)
        if Public(mana) and mana==nil then mana=false end
        local config=button.config
        local valid=ok and (not Public(usable) or type(usable)=='boolean')
            and (not Public(mana) or type(mana)=='boolean') and config and config.colors
        if valid and C_CurveUtil and C_CurveUtil.EvaluateColorValueFromBoolean then
            -- Retail permits opaque booleans through this colour evaluator.
            -- Forward the resulting components to the texture without branching
            -- on availability/range or inspecting protected combat values.
            local choose=C_CurveUtil.EvaluateColorValueFromBoolean
            local range=button.outOfRange
            if Public(range) and type(range)~='boolean' then range=false end
            local color={}
            for i=1,3 do
                color[i]=choose(usable,1,choose(mana,config.colors.mana[i],.4))
                if config.outOfRangeColoring=='button' then color[i]=choose(range,config.colors.range[i],color[i]) end
            end
            button.icon:SetVertexColor(color[1],color[2],color[3])
        elseif valid and Public(usable) and Public(mana) and Public(button.outOfRange) then
            local color
            if config.outOfRangeColoring=='button' and button.outOfRange then color=config.colors.range
            elseif usable then color={1,1,1}
            elseif mana then color=config.colors.mana
            else color={.4,.4,.4} end
            if color then button.icon:SetVertexColor(color[1],color[2],color[3]) end
        end
    end
    -- Placeholder opacity is separate from native usability tint.
    if button._state_type~='empty' then button.icon:SetAlpha(1) end
    -- LAB sets this true for a party-sync lock but its quick usability update
    -- never clears it on unlock. Preserve its native range/resource tint.
    local locked=false
    if button._state_type=='action' then
        if not C_LevelLink or not C_LevelLink.IsActionLocked or not Public(button._state_action) then return end
        local ok,value=pcall(C_LevelLink.IsActionLocked,button._state_action)
        if not ok or (Public(value) and type(value)~='boolean') then return end
        locked=value
    end
    if not Public(button.zoneAbilityDisabled) then return end
    if button.zoneAbilityDisabled==true then button.icon:SetDesaturated(true)
    else button.icon:SetDesaturated(locked) end -- Forward opaque combat booleans to the permitted texture sink.
end
local function Availability(button,refreshUsable)
    if button.__cpfPaintingAvailability then return end
    button.__cpfPaintingAvailability=true
    local ok=pcall(PaintAvailability,button,refreshUsable)
    button.__cpfPaintingAvailability=nil
    if not ok and Addon.Diagnostics then Addon.Diagnostics:SetFeature('faceAvailability','pending','native colour/lock query could not be reconciled; visual snapshot retained') end
end
local function Swipe(cd,r,g,b,a)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    -- Native LAB restores alpha 1 at cast completion. The scoped circular
    -- skin needs a translucent swipe, including every GCD. Preserve alpha 0
    -- during the casting animation and the native loss-of-control color.
    if cd.__cpfSwipeWriting or not Public(a) or not Public(r) or not Public(g) or not Public(b) then return end
    if a==nil then a=1 end
    if type(a)~='number' or a<=0.65 then return end
    cd.__cpfSwipeWriting=true
    cd:SetSwipeColor(r,g,b,0.65)
    cd.__cpfSwipeWriting=nil
end

function Addon:ResolvedPresentationBinding(button)
    if button._state_type~='custom' or not button.GetAttribute or button:GetAttribute('cpf-held') then return end
    local bridge=self.adapters and self.adapters.consoleport
    if not bridge or bridge.api.version~='3.3.10' then return end
    local manager=bridge.bar and bridge.bar.Manager
    if not manager or type(manager.GetBindings)~='function' then return end
    local state=button:GetAttribute('state')
    if issecretvalue and issecretvalue(state) then return end
    if type(state)~='string' then return end
    local bindings=manager:GetBindings(button.id)
    if type(bindings)~='table' then return end
    local binding=bindings[state]
    if issecretvalue and issecretvalue(binding) then return end
    if type(binding)=='string' then return binding end
end
local function BaseIcon(button)
    local binding=Addon:ResolvedPresentationBinding(button)
    if binding=='JUMP' then button.icon:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverInGame.blp]]) button.icon:SetTexCoord(397/2048,461/2048,1682/2048,1746/2048)
    elseif binding=='' and button:GetParent().id=='Base' and button.id=='PAD2' then button.icon:SetAtlas('128-redbutton-exit')
    elseif binding=='INTERACTTARGET' then button.icon:SetTexture(C_Spell.GetSpellTexture(6603))
    elseif binding=='TURNORACTION' then button.icon:SetAtlas(UnitExists('target') and 'crosshair_inspect_32' or 'crosshair_unableinspect_32')
    else return end
    button.icon:SetDesaturated(false)
    if button.icon.SetAlpha then button.icon:SetAlpha(1) end
    button.icon:Show()
end
local function RoundStates(button,imageOnly)
    for _,key in ipairs({'NormalTexture','PushedTexture','HighlightTexture','CheckedTexture','Flash','Border','NewActionTexture','SpellHighlightTexture'}) do
        local texture=button[key]
        local getter=REGION_GETTERS[key]
        local actual=getter and button[getter] and button[getter](button)
        if actual and actual~=texture then HUD.RoundRegion(actual,button,key,button.__cpfFaceMask,imageOnly) end
        if not texture then texture=actual end
        HUD.RoundRegion(texture,button,key,button.__cpfFaceMask,imageOnly)
    end
end

local function Apply(button)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    if not button or not button.icon then return end
    HUD.RetireMasqueNormal(button)
    if InCombatLockdown() then
        Addon.skinRefreshPending=true
        if button.__cpfFaceMask then RoundStates(button,true) end
        if button.SlotArt then button.SlotArt:Hide() end
        Availability(button,true) BaseIcon(button) HUD.EmptyVisibility(button)
        return
    end
    button.MasqueSkinned = true
    -- Keep our circular mask independent of native/Masque mask replacement.
    local mask = button.__cpfFaceMask or button:CreateMaskTexture(nil, "BACKGROUND")
    button.__cpfFaceMask=mask
    if button.IconMask and button.IconMask~=mask and button.icon.RemoveMaskTexture then
        pcall(button.icon.RemoveMaskTexture,button.icon,button.IconMask)
    end
    button.IconMask = mask
    if button.__cpfMaskIcon~=button.icon or button.__cpfConnectedMask~=mask then
        if button.__cpfMaskIcon and button.__cpfConnectedMask and button.__cpfMaskIcon.RemoveMaskTexture then button.__cpfMaskIcon:RemoveMaskTexture(button.__cpfConnectedMask) end
        button.icon:AddMaskTexture(mask) button.__cpfMaskIcon=button.icon button.__cpfConnectedMask=mask
    end
    if not button.icon.__cpfMaskWatch and button.icon.RemoveMaskTexture then
        button.icon.__cpfMaskWatch=true
        local watched=button.icon
        hooksecurefunc(watched,'RemoveMaskTexture',function(_,removed)
            if button.__cpfMaskIcon==watched and button.__cpfConnectedMask==removed then
                button.__cpfConnectedMask=nil
                Addon:RequestSkinRefresh()
            end
        end)
    end
    HUD.CircleMask(mask) mask:ClearAllPoints()
    mask:SetPoint("CENTER",button) mask:SetSize(button:GetWidth()*0.88,button:GetWidth()*0.88)
    -- SetAtlas owns its texture coordinates; resetting them exposes its sheet.
    if not button.icon.GetAtlas or not button.icon:GetAtlas() then button.icon:SetTexCoord(0,1,0,1) end
    local bg = button.SlotBackground or button:CreateTexture(nil,"BACKGROUND")
    button.SlotBackground = bg bg:SetColorTexture(0.04,0.04,0.04,0.65) bg:SetAllPoints(button.icon)
    if button.__cpfMaskBackground~=bg or button.__cpfBackgroundMask~=mask then
        if button.__cpfMaskBackground and button.__cpfBackgroundMask and button.__cpfMaskBackground.RemoveMaskTexture then button.__cpfMaskBackground:RemoveMaskTexture(button.__cpfBackgroundMask) end
        bg:AddMaskTexture(mask) button.__cpfMaskBackground=bg button.__cpfBackgroundMask=mask
    end
    bg:Show()
    HUD.EmptySlot(button,mask)
    local shadow=button.__cpfRoundShadow or button:CreateTexture(nil,'BACKGROUND',nil,-2)
    button.__cpfRoundShadow=shadow
    shadow:ClearAllPoints() shadow:SetPoint('CENTER',button, 'CENTER',0,-1)
    shadow:SetSize(button:GetWidth()*1.08,button:GetWidth()*1.08)
    if not HUD.Atlas(shadow,'gamepad-actionbar-circleslot-dropshadow') then
        HUD.Sprite(shadow,'shadow')
    end
    shadow:Show()
    -- Optional texture holes must not terminate an ipairs traversal.
    RoundStates(button)
    HUD.RoundEffects(button,mask)
    for _, key in ipairs({"cooldown","chargeCooldown","lossOfControlCooldown"}) do
        local cd=button[key] if cd then
            cd:ClearAllPoints() cd:SetAllPoints(mask) cd:SetSwipeTexture(CIRCLE)
            if cd.SetUseCircularEdge then cd:SetUseCircularEdge(true) end
            if cd.SetSwipeColor and not cd.__cpfSwipeHook then
                cd.__cpfSwipeHook=true hooksecurefunc(cd,'SetSwipeColor',Swipe)
                cd:SetSwipeColor(key=='lossOfControlCooldown' and 0.17 or 0,0,0,0.65)
            end
        end
    end
    if button.icon.SetVertexColor and button.__cpfAvailabilityIcon~=button.icon then
        button.__cpfAvailabilityIcon=button.icon
        hooksecurefunc(button.icon,'SetVertexColor',function(_,r,g,b,a)
            if not button.__cpfPaintingAvailability then button.__cpfLastIncomingColour={SafeVisualValue(r),SafeVisualValue(g),SafeVisualValue(b),SafeVisualValue(a)} end
            Availability(button,true)
        end)
    end
    Availability(button,true)
    BaseIcon(button)
end

local function DetachMasque(bank, button)
    if not bank or not bank.msqGroup or not button then return end
    local registered = bank.msqGroup.Buttons and bank.msqGroup.Buttons[button]
    if registered and type(bank.msqGroup.RemoveButton)=="function" then
        bank.msqGroup:RemoveButton(button)
    end
end

local function Install(button)
    if not button then return end
    if not button.__cpfInstalled then
        button.__cpfInstalled=true
        if type(button.UpdateLocal)=="function" then hooksecurefunc(button,"UpdateLocal",Apply) end
        if type(button.UpdateButtonArt)=="function" then hooksecurefunc(button,"UpdateButtonArt",Apply) end
        button:HookScript("OnSizeChanged",Apply)
    end
    Apply(button)
end

local targetingPrompts={}
local function Prompts(bank)
    if InCombatLockdown() then return end
    for _,i in ipairs({{n="Friendly",x=-157.5,g="PADLSHOULDER",t=141,b=186,l=297,r=347},{n="Hostile",x=157.5,g="PADRSHOULDER",t=188,b=233,l=349,r=399}}) do
        local f=targetingPrompts[i.n]
        if f then
            f:SetParent(bank) f:ClearAllPoints() f:SetSize(34,30.6) f:SetPoint('BOTTOM',bank,'TOP',i.x,-32)
        else
        f=CreateFrame("Frame","ConsolePortForever"..i.n.."Prompt",bank) f:SetSize(34,30.6) f:SetPoint("BOTTOM",bank,"TOP",i.x,-32)
        targetingPrompts[i.n]=f
        local bg=f:CreateTexture(nil,"BACKGROUND") bg:SetAllPoints() bg:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]]) bg:SetTexCoord(i.l/512,i.r/512,1/256,46/256)
        local icon=f:CreateTexture(nil,"ARTWORK") icon:SetAllPoints() icon:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]]) icon:SetTexCoord(223/512,273/512,i.t/256,i.b/256)
        f.glyph=f:CreateTexture(nil,"OVERLAY") f.glyph:SetSize(18,18) f.glyph:SetPoint("BOTTOM",f,"TOP",0,1)
        end
        HUD.Glyph(f.glyph,i.g)
    end
end

function Addon:RefreshConsolePortSkin()
    if not self.IsCharacterInstalled or not self:IsCharacterInstalled() then return end
    if InCombatLockdown() then self.skinRefreshPending=true return end
    self.skinRefreshPending=nil
    HUD.Watch()
    local ready,errors=0,{}
    for bankID in pairs(BANKS) do
        local bank=_G["ConsolePortGroup"..bankID]
        if bank and bank.buttons then
            HUD.PlaceBank(bank)
            if not bank.__cpfSkinHooks then
                bank.__cpfSkinHooks=true
                if type(bank.UpdateButtons)=="function" then
                    hooksecurefunc(bank,"UpdateButtons",function() Addon:RequestSkinRefresh() end)
                end
                if type(bank.OnMasqueLoaded)=="function" then
                    hooksecurefunc(bank,"OnMasqueLoaded",function() Addon:RequestSkinRefresh() end)
                end
                if type(bank.OnPropsUpdated)=='function' then
                    hooksecurefunc(bank,'OnPropsUpdated',function() Addon:RequestSkinRefresh() end)
                end
            end
            for id in pairs(FACE) do
                local button=bank.buttons[id]
                if button then
                    local ok,reason=pcall(function()
                        DetachMasque(bank,button)
                        button.isForeverFaceButton=true
                        Install(button)
                    end)
                    if ok then ready=ready+1 else errors[#errors+1]=bankID..'/'..id..': '..tostring(reason) end
                end
            end
            for id in pairs(DPAD) do
                local button=bank.buttons[id]
                if button then
                    if not button.__cpfEmptyHook then
                        button.__cpfEmptyHook=true
                        local function empty()
                            if Addon:IsCharacterInstalled() then
                                if InCombatLockdown() then HUD.EmptyVisibility(button) else HUD.EmptySlot(button) end
                            end
                        end
                        if type(button.UpdateLocal)=='function' then hooksecurefunc(button,'UpdateLocal',empty) end
                        if type(button.UpdateButtonArt)=='function' then hooksecurefunc(button,'UpdateButtonArt',empty) end
                        button:HookScript('OnSizeChanged',empty)
                    end
                    HUD.EmptySlot(button)
                end
            end
            HUD.BankPrompt(bank,bankID)
        end
    end
    if ConsolePortGroupBase then Prompts(ConsolePortGroupBase) HUD.ClassShortcut(ConsolePortGroupBase) end
    HUD.LayoutGuard()
    if self.Diagnostics then self.Diagnostics:SetFeature('faceSkin',ready==16 and #errors==0 and 'offline-verified' or 'pending',
        #errors>0 and table.concat(errors,'; ') or (ready..'/16 face skins prepared; rendered Retail acceptance pending')) end
end

function Addon:RequestSkinRefresh()
    if self.skinRefreshQueued then return end
    self.skinRefreshQueued=true
    C_Timer.After(0,function()
        Addon.skinRefreshQueued=nil
        Addon:RefreshFaceAvailability()
        Addon:RefreshConsolePortSkin()
    end)
end

local events=CreateFrame("Frame")
local function VisualGetter(object,method)
    if not object or type(object[method])~='function' then return end
    local ok,a,b,c,d=pcall(object[method],object)
    if not ok then return '[query failed]' end
    if method=='GetVertexColor' then return {SafeVisualValue(a),SafeVisualValue(b),SafeVisualValue(c),SafeVisualValue(d)} end
    return SafeVisualValue(a)
end
function Addon:SnapshotFaceVisuals(force)
    if not self.record or not self.Diagnostics or not self:IsCharacterInstalled() then return end
    local now=GetTime and GetTime() or 0
    local combat=InCombatLockdown()
    if not force and self.__cpfVisualSnapshotCombat==combat and self.__cpfVisualSnapshotAt and now-self.__cpfVisualSnapshotAt<2 then return end
    self.__cpfVisualSnapshotAt=now self.__cpfVisualSnapshotCombat=combat
    local snapshot={time=now,combat=combat,banks={}}
    for bankID in pairs(BANKS) do
        local bank=_G['ConsolePortGroup'..bankID]
        if bank and bank.buttons then
            local group={alpha=VisualGetter(bank,'GetAlpha'),effectiveAlpha=VisualGetter(bank,'GetEffectiveAlpha'),buttons={}}
            snapshot.banks[bankID]=group
            for id,button in pairs(bank.buttons) do
                local row={kind=SafeVisualValue(button._state_type),action=SafeVisualValue(button._state_action),range=SafeVisualValue(button.outOfRange),incomingColour=button.__cpfLastIncomingColour,zoneDisabled=SafeVisualValue(button.zoneAbilityDisabled),
                    icon={colour=VisualGetter(button.icon,'GetVertexColor'),alpha=VisualGetter(button.icon,'GetAlpha'),effectiveAlpha=VisualGetter(button.icon,'GetEffectiveAlpha'),desaturated=VisualGetter(button.icon,'IsDesaturated'),desaturation=VisualGetter(button.icon,'GetDesaturation')},layers={}}
                if type(button.IsUsable)=='function' then
                    local ok,usable,mana=pcall(button.IsUsable,button)
                    row.queryOK=ok row.usable=SafeVisualValue(usable) row.mana=SafeVisualValue(mana)
                end
                local actionInfo=C_ActionBar and C_ActionBar.GetActionInfo or GetActionInfo
                if actionInfo and Public(button._state_action) and type(button._state_action)=='number' and button._state_type=='action' then
                    local ok,kind,spell,subType=pcall(actionInfo,button._state_action)
                    row.actionInfoOK=ok row.slotKind=SafeVisualValue(kind) row.spell=SafeVisualValue(spell)
                    if ok and Public(kind) and kind=='spell' and Public(spell) and type(spell)=='number' and C_Spell and C_Spell.IsSpellUsable then
                        local queried,usable,mana=pcall(C_Spell.IsSpellUsable,spell)
                        row.spellQueryOK=queried row.spellUsable=SafeVisualValue(usable) row.spellMana=SafeVisualValue(mana)
                    end
                end
                for _,key in ipairs({'NormalTexture','PushedTexture','CheckedTexture','Flash','SpellCastAnimFrame','cooldown','chargeCooldown','lossOfControlCooldown'}) do
                    local layer=button[key]
                    if layer then row.layers[key]={shown=VisualGetter(layer,'IsShown'),alpha=VisualGetter(layer,'GetAlpha'),effectiveAlpha=VisualGetter(layer,'GetEffectiveAlpha')} end
                end
                group.buttons[id]=row
            end
        end
    end
    self.Diagnostics.visuals=self.Diagnostics.visuals or {}
    self.Diagnostics.visuals[snapshot.combat and 'combat' or 'peace']=snapshot
    self.Diagnostics:Persist()
end
function Addon:RefreshFaceAvailability()
    for bankID in pairs(BANKS) do
        local bank=_G['ConsolePortGroup'..bankID]
        if bank and bank.buttons then for id in pairs(FACE) do local button=bank.buttons[id] if button then Availability(button,true) end end end
    end
    self:SnapshotFaceVisuals()
end
events:SetScript("OnEvent",function()
    Addon:RequestSkinRefresh()
    C_Timer.After(1,function() Addon:RequestSkinRefresh() end)
end)
-- Install the handler first; unavailable events must not abort skin startup.
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_TARGET_CHANGED','PLAYER_EQUIPMENT_CHANGED','PLAYER_REGEN_ENABLED',
    'PLAYER_REGEN_DISABLED','ACTIONBAR_UPDATE_USABLE','ACTIONBAR_SLOT_CHANGED','GROUP_ROSTER_UPDATE','UPDATE_BINDINGS','ADDON_LOADED',
    'GAME_PAD_CONFIGS_CHANGED','UPDATE_SHAPESHIFT_FORMS','SPELLS_CHANGED','UI_SCALE_CHANGED','DISPLAY_SIZE_CHANGED'}) do
    local supported=not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event)
    if supported then
        local ok,reason=pcall(events.RegisterEvent,events,event)
        if not ok and Addon.Diagnostics then Addon.Diagnostics:Log('skin-event',tostring(reason)) end
    end
end
