local _, Addon = ...
local BANKS, FACE = {Base=true,L2=true,R2=true,L2R2=true}, {PAD1=true,PAD2=true,PAD3=true,PAD4=true}
local CIRCLE = [[Interface\Masks\CircleMaskScalable]]
local RING = [[Interface\AddOns\ConsolePort\Assets\Textures\Cursor\RoundBorderHighlight]]
local BASE = {PAD1="JUMP", PAD2="", PAD3="INTERACTTARGET", PAD4="TURNORACTION"}

local function Round(texture, button)
    if not texture then return end
    texture:SetTexture(RING) texture:SetTexCoord(0,1,0,1) texture:ClearAllPoints()
    texture:SetPoint("CENTER", button) texture:SetSize(button:GetWidth(), button:GetWidth())
end

local function BaseIcon(button)
    if button:GetParent().id ~= "Base" or button._state_type ~= "custom" or GetBindingAction(button.id) ~= BASE[button.id] then return end
    if button.id == "PAD1" then button.icon:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverInGame.blp]]) button.icon:SetTexCoord(397/2048,461/2048,1682/2048,1746/2048)
    elseif button.id == "PAD2" then button.icon:SetAtlas("128-redbutton-exit")
    elseif button.id == "PAD3" then button.icon:SetTexture(C_Spell.GetSpellTexture(6603))
    elseif button.id == "PAD4" then button.icon:SetAtlas(UnitExists("target") and "crosshair_inspect_32" or "crosshair_unableinspect_32") end
    button.icon:Show()
end

local function Apply(button)
    if not button or not button.icon then return end
    button.MasqueSkinned = true
    local mask = button.IconMask or button:CreateMaskTexture(nil, "BACKGROUND")
    button.IconMask = mask button.icon:AddMaskTexture(mask)
    mask:SetTexture(CIRCLE,"CLAMPTOBLACKADDITIVE","CLAMPTOBLACKADDITIVE") mask:ClearAllPoints()
    mask:SetPoint("CENTER",button) mask:SetSize(button:GetWidth()*0.88,button:GetWidth()*0.88)
    button.icon:SetTexCoord(0,1,0,1)
    local bg = button.SlotBackground or button:CreateTexture(nil,"BACKGROUND")
    button.SlotBackground = bg bg:SetColorTexture(0.04,0.04,0.04,0.65) bg:SetAllPoints(button.icon) bg:AddMaskTexture(mask) bg:Show()
    if button.SlotArt then button.SlotArt:Hide() end
    for _, texture in ipairs({button.NormalTexture,button.PushedTexture or button:GetPushedTexture(),button.HighlightTexture or button:GetHighlightTexture(),button.CheckedTexture or button:GetCheckedTexture(),button.Flash,button.Border,button.NewActionTexture,button.SpellHighlightTexture}) do Round(texture,button) end
    for _, key in ipairs({"cooldown","chargeCooldown","lossOfControlCooldown"}) do
        local cd=button[key] if cd then cd:ClearAllPoints() cd:SetAllPoints(mask) cd:SetSwipeTexture(CIRCLE) cd:SetUseCircularEdge(true) end
    end
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
local function Prompts(bank)
    if targetingBank==bank or InCombatLockdown() then return end targetingBank=bank
    for _,i in ipairs({{n="Friendly",x=-157.5,g="ps_s_l1",t=141,b=186,l=297,r=347},{n="Hostile",x=157.5,g="ps_s_r1",t=188,b=233,l=349,r=399}}) do
        local f=CreateFrame("Frame","ConsolePortForever"..i.n.."Prompt",bank) f:SetSize(34,30.6) f:SetPoint("BOTTOM",bank,"TOP",i.x,-32)
        local bg=f:CreateTexture(nil,"BACKGROUND") bg:SetAllPoints() bg:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]]) bg:SetTexCoord(i.l/512,i.r/512,1/256,46/256)
        local icon=f:CreateTexture(nil,"ARTWORK") icon:SetAllPoints() icon:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]]) icon:SetTexCoord(223/512,273/512,i.t/256,i.b/256)
        local glyph=f:CreateTexture(nil,"OVERLAY") glyph:SetSize(18,18) glyph:SetPoint("BOTTOM",f,"TOP",0,1) glyph:SetTexture([[Interface\AddOns\ConsolePort\Assets\Icons\64\]]..i.g)
    end
end

function Addon:RefreshConsolePortSkin()
    if not ConsolePortForeverDB or ConsolePortForeverDB.installedSchema~=self.SCHEMA then return end
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
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_TARGET_CHANGED","PLAYER_EQUIPMENT_CHANGED","PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function() C_Timer.After(0,function() Addon:RefreshConsolePortSkin() end) C_Timer.After(1,function() Addon:RefreshConsolePortSkin() end) end)
