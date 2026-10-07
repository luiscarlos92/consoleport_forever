local _, Addon = ...
local BANKS, FACE = {Base=true,L2=true,R2=true,L2R2=true}, {PAD1=true,PAD2=true,PAD3=true,PAD4=true}
local CIRCLE = [[Interface\Masks\CircleMaskScalable]]
local RING = [[Interface\AddOns\ConsolePort\Assets\Textures\Cursor\RoundBorderHighlight]]
local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function Availability(button)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    if not button.icon or not button.icon.SetDesaturated then return end
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

local function Round(texture, button)
    if not texture then return end
    texture:SetTexture(RING) texture:SetTexCoord(0,1,0,1) texture:ClearAllPoints()
    texture:SetPoint("CENTER", button) texture:SetSize(button:GetWidth(), button:GetWidth())
end

function Addon:ResolvedPresentationBinding(button)
    if button._state_type~='custom' or not button.GetAttribute or button:GetAttribute('cpf-held') then return end
    local bridge=self.adapters and self.adapters.consoleport
    if not bridge or bridge.api.version~='3.3.9' then return end
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
    button.icon:Show()
end

local function Apply(button)
    if not Addon.IsCharacterInstalled or not Addon:IsCharacterInstalled() then return end
    if not button or not button.icon then return end
    button.MasqueSkinned = true
    local mask = button.IconMask or button:CreateMaskTexture(nil, "BACKGROUND")
    button.IconMask = mask
    if button.__cpfMaskIcon~=button.icon or button.__cpfConnectedMask~=mask then
        if button.__cpfMaskIcon and button.__cpfConnectedMask and button.__cpfMaskIcon.RemoveMaskTexture then button.__cpfMaskIcon:RemoveMaskTexture(button.__cpfConnectedMask) end
        button.icon:AddMaskTexture(mask) button.__cpfMaskIcon=button.icon button.__cpfConnectedMask=mask
    end
    mask:SetTexture(CIRCLE,"CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE") mask:ClearAllPoints()
    mask:SetPoint("CENTER",button) mask:SetSize(button:GetWidth()*0.88,button:GetWidth()*0.88)
    button.icon:SetTexCoord(0,1,0,1)
    local bg = button.SlotBackground or button:CreateTexture(nil,"BACKGROUND")
    button.SlotBackground = bg bg:SetColorTexture(0.04,0.04,0.04,0.65) bg:SetAllPoints(button.icon)
    if button.__cpfMaskBackground~=bg or button.__cpfBackgroundMask~=mask then
        if button.__cpfMaskBackground and button.__cpfBackgroundMask and button.__cpfMaskBackground.RemoveMaskTexture then button.__cpfMaskBackground:RemoveMaskTexture(button.__cpfBackgroundMask) end
        bg:AddMaskTexture(mask) button.__cpfMaskBackground=bg button.__cpfBackgroundMask=mask
    end
    bg:Show()
    if button.SlotArt then button.SlotArt:Hide() end
    for _, texture in ipairs({button.NormalTexture,button.PushedTexture or button:GetPushedTexture(),button.HighlightTexture or button:GetHighlightTexture(),button.CheckedTexture or button:GetCheckedTexture(),button.Flash,button.Border,button.NewActionTexture,button.SpellHighlightTexture}) do Round(texture,button) end
    for _, key in ipairs({"cooldown","chargeCooldown","lossOfControlCooldown"}) do
        local cd=button[key] if cd then
            cd:ClearAllPoints() cd:SetAllPoints(mask) cd:SetSwipeTexture(CIRCLE) cd:SetUseCircularEdge(true)
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

local targetingBank
local targetingPrompts={}
local function Prompts(bank)
    if targetingBank==bank or InCombatLockdown() then return end targetingBank=bank
    for _,i in ipairs({{n="Friendly",x=-157.5,g="ps_s_l1",t=141,b=186,l=297,r=347},{n="Hostile",x=157.5,g="ps_s_r1",t=188,b=233,l=349,r=399}}) do
        local f=targetingPrompts[i.n]
        if f then
            f:SetParent(bank) f:ClearAllPoints() f:SetSize(34,30.6) f:SetPoint('BOTTOM',bank,'TOP',i.x,-32)
        else
        f=CreateFrame("Frame","ConsolePortForever"..i.n.."Prompt",bank) f:SetSize(34,30.6) f:SetPoint("BOTTOM",bank,"TOP",i.x,-32)
        targetingPrompts[i.n]=f
        local bg=f:CreateTexture(nil,"BACKGROUND") bg:SetAllPoints() bg:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]]) bg:SetTexCoord(i.l/512,i.r/512,1/256,46/256)
        local icon=f:CreateTexture(nil,"ARTWORK") icon:SetAllPoints() icon:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]]) icon:SetTexCoord(223/512,273/512,i.t/256,i.b/256)
        local glyph=f:CreateTexture(nil,"OVERLAY") glyph:SetSize(18,18) glyph:SetPoint("BOTTOM",f,"TOP",0,1) glyph:SetTexture([[Interface\AddOns\ConsolePort\Assets\Icons\64\]]..i.g)
        end
    end
end

function Addon:RefreshConsolePortSkin()
    if not self.IsCharacterInstalled or not self:IsCharacterInstalled() or InCombatLockdown() then return end
    for bankID in pairs(BANKS) do
        local bank=_G["ConsolePortGroup"..bankID]
        if bank and bank.buttons then
            if not bank.__cpfSkinHooks then
                bank.__cpfSkinHooks=true
                if type(bank.UpdateButtons)=="function" then
                    hooksecurefunc(bank,"UpdateButtons",function() C_Timer.After(0,function() Addon:RefreshConsolePortSkin() end) end)
                end
                if type(bank.OnMasqueLoaded)=="function" then
                    hooksecurefunc(bank,"OnMasqueLoaded",function() C_Timer.After(0,function() Addon:RefreshConsolePortSkin() end) end)
                end
            end
            for id in pairs(FACE) do
                local button=bank.buttons[id]
                DetachMasque(bank,button)
                if button then button.isForeverFaceButton=true end
                Install(button)
            end
        end
    end
    if ConsolePortGroupBase then Prompts(ConsolePortGroupBase) end
end

local events=CreateFrame("Frame")
function Addon:RefreshFaceAvailability()
    for bankID in pairs(BANKS) do
        local bank=_G['ConsolePortGroup'..bankID]
        if bank and bank.buttons then for id in pairs(FACE) do local button=bank.buttons[id] if button then Availability(button) end end end
    end
end
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","PLAYER_EQUIPMENT_CHANGED","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","ACTIONBAR_UPDATE_USABLE","ACTIONBAR_SLOT_CHANGED","PARTY_SYNC_DISABLED","PARTY_SYNC_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function()
    C_Timer.After(0,function() Addon:RefreshFaceAvailability() Addon:RefreshConsolePortSkin() end)
    C_Timer.After(1,function() Addon:RefreshFaceAvailability() Addon:RefreshConsolePortSkin() end)
end)
