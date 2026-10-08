local _, Addon = ...
local BANKS, FACE = {Base=true,L2=true,R2=true,L2R2=true}, {PAD1=true,PAD2=true,PAD3=true,PAD4=true}
local DPAD = {PADDUP=true,PADDDOWN=true,PADDLEFT=true,PADDRIGHT=true}
local HUD = Addon.HUDPresentation
local CIRCLE = [[Interface\Masks\CircleMaskScalable]]
local REGION_GETTERS={NormalTexture='GetNormalTexture',PushedTexture='GetPushedTexture',HighlightTexture='GetHighlightTexture',CheckedTexture='GetCheckedTexture'}
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function Availability(button)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    if not button.icon or not button.icon.SetDesaturated then return end
    if button._state_type=='custom' then
        local binding=Addon:ResolvedPresentationBinding(button)
        local exit=binding=='' and button:GetParent().id=='Base' and button.id=='PAD2'
        if not exit and binding~='JUMP' and binding~='INTERACTTARGET' and binding~='TURNORACTION' then return end
    end
    -- LAB sets this true for a party-sync lock but its quick usability update
    -- never clears it on unlock. Preserve its native range/resource tint.
    local locked=false
    if button._state_type=='action' then
        if not C_LevelLink or not C_LevelLink.IsActionLocked or not Public(button._state_action) then return end
        local ok,value=pcall(C_LevelLink.IsActionLocked,button._state_action)
        if not ok or not Public(value) or type(value)~='boolean' then return end
        locked=value
    end
    if not Public(button.zoneAbilityDisabled) then return end
    button.icon:SetDesaturated(locked or button.zoneAbilityDisabled==true)
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

local function Apply(button)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    if not button or not button.icon then return end
    if InCombatLockdown() then
        Addon.skinRefreshPending=true
        Availability(button) BaseIcon(button) HUD.EmptyVisibility(button)
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
    mask:SetTexture(CIRCLE,"CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE") mask:ClearAllPoints()
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
    for _,key in ipairs({'NormalTexture','PushedTexture','HighlightTexture','CheckedTexture','Flash','Border','NewActionTexture','SpellHighlightTexture'}) do
        local texture=button[key]
        local getter=REGION_GETTERS[key]
        local actual=getter and button[getter] and button[getter](button)
        if actual and actual~=texture then HUD.RoundRegion(actual,button,key,mask) end
        if not texture then texture=actual end
        HUD.RoundRegion(texture,button,key,mask)
    end
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
        hooksecurefunc(button.icon,'SetVertexColor',function() Availability(button) end)
    end
    Availability(button)
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
            HUD.LiftBank(bank)
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
function Addon:RefreshFaceAvailability()
    for bankID in pairs(BANKS) do
        local bank=_G['ConsolePortGroup'..bankID]
        if bank and bank.buttons then for id in pairs(FACE) do local button=bank.buttons[id] if button then Availability(button) end end end
    end
end
events:SetScript("OnEvent",function()
    Addon:RequestSkinRefresh()
    C_Timer.After(1,function() Addon:RequestSkinRefresh() end)
end)
-- Install the handler first; unavailable events must not abort skin startup.
for _,event in ipairs({'PLAYER_ENTERING_WORLD','PLAYER_TARGET_CHANGED','PLAYER_EQUIPMENT_CHANGED','PLAYER_REGEN_ENABLED',
    'PLAYER_REGEN_DISABLED','ACTIONBAR_UPDATE_USABLE','ACTIONBAR_SLOT_CHANGED','GROUP_ROSTER_UPDATE','UPDATE_BINDINGS','ADDON_LOADED',
    'GAME_PAD_CONFIGS_CHANGED','UPDATE_SHAPESHIFT_FORMS','SPELLS_CHANGED'}) do
    local supported=not C_EventUtils or not C_EventUtils.IsEventValid or C_EventUtils.IsEventValid(event)
    if supported then
        local ok,reason=pcall(events.RegisterEvent,events,event)
        if not ok and Addon.Diagnostics then Addon.Diagnostics:Log('skin-event',tostring(reason)) end
    end
end
