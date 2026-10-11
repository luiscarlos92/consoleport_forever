-- The action HUD uses a 78.75-unit center-out rhythm: the Base/L2R2
-- D-pad and face crosses sit at -/+1 step, L1/R1 at -/+2 steps, the
-- L2/R2 bank centers (and unit frames) at -/+4 steps, and their outer
-- crosses at -/+5 steps. Keep these shared anchors on the same axis.
local HUD_HALF_STEP = 78.75
local HUD_SHOULDER_X = HUD_HALF_STEP * 2
local HUD_SIDE_X = HUD_HALF_STEP * 4

local function IsEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame.editModeActive
end

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
    if InCombatLockdown() or IsEditModeActive() then return false end
    for _, layout in ipairs({
        {frame = PlayerFrame, x = -HUD_SIDE_X},
        {frame = TargetFrame, x = HUD_SIDE_X},
    }) do
        local frame = layout.frame
        if frame then
            local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
            local point = frame.SetPointBase or frame.SetPoint
            clear(frame)
            point(frame, 'CENTER', UIParent, 'CENTER', layout.x, -175)
        end
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
    if InCombatLockdown() or IsEditModeActive() or castApplying then return end
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

-- BuffFrame and DebuffFrame are independent Edit Mode systems. Treat them as
-- one lane beside the player frame: buffs own the first rows, and debuffs are
-- attached to the changing bottom edge of the buff container. Both grow left
-- and wrap down, so neither can expand across the portrait or health bars.
local auraFrames = {};
local auraLaneQueued, auraLaneApplying;
local MovePlayerAuraLane;
local function QueuePlayerAuraLane()
    if auraLaneApplying or auraLaneQueued then return end
    auraLaneQueued = true
    C_Timer.After(0, function()
        auraLaneQueued = false
        MovePlayerAuraLane()
    end)
end

local function HookAuraFrame(frame)
    if auraFrames[frame] then return end
    auraFrames[frame] = true
    for _, method in ipairs({'SetPoint', 'ClearAllPoints', 'ApplySystemAnchor',
        'OnEditModeExit', 'UpdateGridLayout', 'UpdateSize'}) do
        if type(frame[method]) == 'function' then
            hooksecurefunc(frame, method, QueuePlayerAuraLane)
        end
    end
    frame:HookScript('OnShow', QueuePlayerAuraLane)
end

MovePlayerAuraLane = function()
    if InCombatLockdown() or IsEditModeActive() or auraLaneApplying then return end
    local buffs = BuffFrame
    local debuffs = DebuffFrame
    local player = PlayerFrame
    if not buffs or not buffs.AuraContainer or
       not debuffs or not debuffs.AuraContainer or not player then return end

    HookAuraFrame(buffs)
    HookAuraFrame(debuffs)
    auraLaneApplying = true

    for _, frame in ipairs({buffs, debuffs}) do
        local container = frame.AuraContainer
        local changed = container.addIconsToRight ~= false or
                        container.addIconsToTop ~= false
        container.addIconsToRight = false
        container.addIconsToTop = false
        if changed and type(frame.UpdateGridLayout) == 'function' then
            frame:UpdateGridLayout()
        end

        local clear = frame.ClearAllPointsBase or frame.ClearAllPoints
        clear(frame)
        if frame == buffs then
            local point = frame.SetPointBase or frame.SetPoint
            point(frame, 'TOPRIGHT', player, 'TOPLEFT', -12, 5)
        else
            local point = frame.SetPointBase or frame.SetPoint
            point(frame, 'TOPRIGHT', buffs, 'BOTTOMRIGHT', 0, -6)
        end
    end
    auraLaneApplying = false
end

-- Never inject addon-created systemInfo tables into Blizzard Edit Mode frames.
-- UpdateSystem stores those tables for later reuse; on current Retail that
-- contaminates Edit Mode's compact unit-frame refresh and makes secret health
-- and range values unsafe as soon as the editor opens.

local targetingBank;
local function AddTargetingPrompts()
    local bank = ConsolePortGroupBase
    if not bank or InCombatLockdown() then return end
    if targetingBank == bank then return end
    targetingBank = bank
    -- Decorative children inherit the bank's visibility (vehicle/pet battle),
    -- alpha and scale. They neither receive input nor introduce new bindings.
    for _, info in ipairs({
        {name = 'Friendly', x = -HUD_SHOULDER_X, glyph = 'ps_s_l1', top = 141, bottom = 186, left = 297, right = 347},
        {name = 'Hostile', x = HUD_SHOULDER_X, glyph = 'ps_s_r1', top = 188, bottom = 233, left = 349, right = 399},
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
    MovePlayerAuraLane()
    AddTargetingPrompts()
    RefreshBaseArt()
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:RegisterEvent('PLAYER_TARGET_CHANGED')
events:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')
events:RegisterEvent('ADDON_LOADED')
events:RegisterEvent('DISPLAY_SIZE_CHANGED')
events:RegisterEvent('UI_SCALE_CHANGED')
events:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
events:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_TARGET_CHANGED' or event == 'PLAYER_EQUIPMENT_CHANGED' then
        RefreshBaseArt()
        return
    end
    if event == 'ADDON_LOADED' then
        -- Aura modules can load after this helper.
        QueuePlayerAuraLane()
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
