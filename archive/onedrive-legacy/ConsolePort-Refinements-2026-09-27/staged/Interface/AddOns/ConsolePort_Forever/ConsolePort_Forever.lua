local function HideBlizzardMenuBar()
    if InCombatLockdown() then return false end

    for _, name in ipairs({
        'MicroButtonAndBagsBar',
        'MicroMenuContainer',
        'BagsBar',
    }) do
        local frame = _G[name]
        if frame then
            frame:Hide()
        end
    end
    return true
end

local function MoveUnitFrames()
    if InCombatLockdown() then return false end

    if PlayerFrame then
        PlayerFrame:ClearAllPoints()
        PlayerFrame:SetPoint('CENTER', UIParent, 'CENTER', -310, -175)
    end
    if TargetFrame then
        TargetFrame:ClearAllPoints()
        TargetFrame:SetPoint('CENTER', UIParent, 'CENTER', 310, -175)
    end
    return true
end

-- Retail's toolbar deliberately skips cast bars. Keep the loaded look/size and
-- give the player's real cast/progress frame a position owned by this helper.
local castFrame, castLayout;
local castApplying, castQueued;
local MovePlayerCastBar;

local function QueuePlayerCastBar()
    if castApplying or castQueued then return end
    castQueued = true
    C_Timer.After(0, function()
        castQueued = false
        MovePlayerCastBar()
    end)
end

MovePlayerCastBar = function()
    if InCombatLockdown() or castApplying then return end
    local frame = PlayerCastingBarFrame
    local bank = ConsolePortGroupBase
    if not frame or not bank then return end

    if castFrame ~= frame then
        castFrame = frame
        castLayout = {
            width = frame:GetWidth(), height = frame:GetHeight(),
            scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale(),
            look = frame.look, strata = frame:GetFrameStrata(),
        }
        -- Post-hooks preserve Blizzard's functions and never write Edit Mode's
        -- saved systemInfo or snapped-frame tables.
        for _, method in ipairs({
            'SetPoint', 'ClearAllPoints', 'SetParent', 'SetScale', 'SetLook',
            'ApplySystemAnchor', 'OnEditModeExit',
        }) do
            if type(frame[method]) == 'function' then
                hooksecurefunc(frame, method, QueuePlayerCastBar)
            end
        end
        frame:HookScript('OnShow', QueuePlayerCastBar)
        for _, name in ipairs({'PlayerFrame_AttachCastBar', 'PlayerFrame_DetachCastBar'}) do
            if type(_G[name]) == 'function' then hooksecurefunc(name, QueuePlayerCastBar) end
        end
        if GetBottomManagedFrameContainer then
            GetBottomManagedFrameContainer():RemoveManagedFrame(frame)
        end
    end

    castApplying = true
    frame.ignoreFramePositionManager = true
    frame.attachedToPlayerFrame = false
    if frame:GetParent() ~= UIParent then frame:SetParent(UIParent) end
    if castLayout.look and frame.look ~= castLayout.look then frame:SetLook(castLayout.look) end
    frame:SetSize(castLayout.width, castLayout.height)
    -- Reparenting must not change the bar's effective size. Using the base
    -- methods also avoids Edit Mode's SetPointOverride/SetScaleOverride bookkeeping.
    local setScale = frame.SetScaleBase or frame.SetScale
    setScale(frame, castLayout.scale)
    frame:SetFrameStrata(castLayout.strata)
    local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
    local point = frame.SetPointBase or frame.SetPoint
    clear(frame)
    -- Five physical pixels above the original approved gap, at the bar's scale.
    point(frame, 'BOTTOM', bank, 'TOP', 0, 12 + 5 / frame:GetEffectiveScale())
    castApplying = false
end

-- Player auras are created by BuffFrame.AuraContainer; their tooltip uses
-- AuraButtonMixin:OnEnter. Keep the actual aura display beside the health bar.
-- Its native layout/collapse code still owns icon sizes, durations and sorting.
local buffFrame, buffsQueued, buffsApplying;
local MovePlayerBuffs;
local function QueuePlayerBuffs()
    if buffsApplying or buffsQueued then return end
    buffsQueued = true
    C_Timer.After(0, function()
        buffsQueued = false
        MovePlayerBuffs()
    end)
end

MovePlayerBuffs = function()
    if InCombatLockdown() or buffsApplying then return end
    local frame = BuffFrame
    local player = PlayerFrame
    if not frame or not frame.AuraContainer or not player then return end
    if buffFrame ~= frame then
        buffFrame = frame
        for _, method in ipairs({'SetPoint', 'ClearAllPoints', 'ApplySystemAnchor',
            'OnEditModeExit', 'UpdateGridLayout'}) do
            if type(frame[method]) == 'function' then
                hooksecurefunc(frame, method, QueuePlayerBuffs)
            end
        end
        frame:HookScript('OnShow', QueuePlayerBuffs)
    end
    buffsApplying = true
    -- Anchor on the health bar's left and grow farther left, so additional auras
    -- cannot cover the health/portrait. Native UpdateGridLayout keeps its
    -- collapse button and aura anchors in sync.
    if frame.AuraContainer.addIconsToRight ~= false then
        frame.AuraContainer.addIconsToRight = false
        frame:UpdateGridLayout()
    end
    local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
    local point = frame.SetPointBase or frame.SetPoint
    clear(frame)
    local upward = frame.AuraContainer.addIconsToTop
    point(frame, upward and 'BOTTOMRIGHT' or 'TOPRIGHT', player,
        upward and 'BOTTOMLEFT' or 'TOPLEFT', -12, upward and -5 or 5)
    buffsApplying = false
end

local targetingBank;
local function AddTargetingPrompts()
    local bank = ConsolePortGroupBase
    if not bank or InCombatLockdown() then return end
    if targetingBank == bank then return end
    targetingBank = bank
    -- Decorative children inherit the bank's visibility (vehicle/pet battle),
    -- alpha and scale. They neither receive input nor introduce new bindings.
    for _, info in ipairs({
        {name = 'Friendly', x = -155, glyph = 'ps_s_l1', top = 141, bottom = 186, left = 297, right = 347},
        {name = 'Hostile', x = 155, glyph = 'ps_s_r1', top = 188, bottom = 233, left = 349, right = 399},
    }) do
        local prompt = CreateFrame('Frame', 'ConsolePortForever'..info.name..'Prompt', bank)
        prompt:SetSize(34, 30.6)
        prompt:SetPoint('BOTTOM', bank, 'TOP', info.x, -32)
        prompt:EnableMouse(false)
        local background = prompt:CreateTexture(nil, 'BACKGROUND')
        background:SetAllPoints()
        background:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]])
        background:SetTexCoord(info.left/512, info.right/512, 1/256, 46/256)
        local icon = prompt:CreateTexture(nil, 'ARTWORK')
        icon:SetAllPoints()
        icon:SetTexture([[Interface\AddOns\ConsolePort_Forever\Assets\ForeverTargeting.blp]])
        icon:SetTexCoord(223/512, 273/512, info.top/256, info.bottom/256)
        local glyph = prompt:CreateTexture(nil, 'OVERLAY')
        glyph:SetSize(18, 18)
        glyph:SetPoint('BOTTOM', prompt, 'TOP', 0, 1)
        glyph:SetTexture([[Interface\AddOns\ConsolePort\Assets\Icons\64\]]..info.glyph)
    end
end

local function RefreshBaseArt()
    local bank = ConsolePortGroupBase
    if not bank or not bank.buttons then return end
    for _, id in ipairs({'PAD1', 'PAD2', 'PAD3', 'PAD4'}) do
        local button = bank.buttons[id]
        if button and button.isForeverFaceButton then button:UpdateLocal() end
    end
end

local function RefreshForeverHUD()
    MoveUnitFrames()
    HideBlizzardMenuBar()
    MovePlayerCastBar()
    MovePlayerBuffs()
    AddTargetingPrompts()
    RefreshBaseArt()
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:RegisterEvent('PLAYER_TARGET_CHANGED')
events:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
events:RegisterEvent('ADDON_LOADED')
events:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_TARGET_CHANGED' or event == 'PLAYER_EQUIPMENT_CHANGED' then
        RefreshBaseArt()
        return
    end
    if event == 'ADDON_LOADED' then
        -- Buff/Edit Mode modules can load after this helper.
        QueuePlayerBuffs()
        return
    end
    if event == 'PLAYER_REGEN_ENABLED' then
        RefreshForeverHUD()
        return
    end

    C_Timer.After(0, RefreshForeverHUD)
    C_Timer.After(1, RefreshForeverHUD)
    C_Timer.After(3, RefreshForeverHUD)
end)
