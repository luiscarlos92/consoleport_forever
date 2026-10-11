-- The action HUD uses a 78.75-unit center-out rhythm: the Base/L2R2
-- D-pad and face crosses sit at -/+1 step, L1/R1 at -/+2 steps, the
-- L2/R2 bank centers (and unit frames) at -/+4 steps, and their outer
-- crosses at -/+5 steps. Keep these shared anchors on the same axis.
local HUD_HALF_STEP = 78.75
local HUD_SHOULDER_X = HUD_HALF_STEP * 2
local HUD_SIDE_X = HUD_HALF_STEP * 4

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
    if InCombatLockdown() or auraLaneApplying then return end
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

-- The saved RealUI layouts predate the current Retail Edit Mode roster. Use
-- Blizzard's shipped Modern system records as the baseline for everything the
-- user did not ask us to preserve. This is an in-memory policy: it leaves the
-- serialized custom layouts intact and is reapplied after login, reload, scale
-- changes, late frame registration and Edit Mode exit.
local modernQueued, modernApplying, modernHooksInstalled;
local ApplyModernLayoutPolicy;

local function DeepCopy(value, seen)
    if type(value) ~= 'table' then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, child in pairs(value) do
        copy[DeepCopy(key, seen)] = DeepCopy(child, seen)
    end
    return copy
end

local function IsProtectedModernSystem(frame)
    if not Enum or not Enum.EditModeSystem then return true end
    local system = frame.system
    local systems = Enum.EditModeSystem
    if system == systems.ActionBar or system == systems.CastBar or
       system == systems.ChatFrame or system == systems.Minimap or
       system == systems.ObjectiveTracker or system == systems.MicroMenu or
       system == systems.Bags then
        return true
    end
    -- Unit-frame UpdateSystem methods can immediately refresh health/range data.
    -- Those values are secret in combat content, so entering that code from an
    -- addon taints Blizzard's later unit-frame updates and causes an error storm.
    -- Player and target positioning is handled separately with region anchors.
    if system == systems.UnitFrame then return true end
    return false
end

local function FindModernSystemInfo(frame)
    if not EditModePresetLayoutManager or
       type(EditModePresetLayoutManager.GetModernSystems) ~= 'function' then return end
    for _, info in ipairs(EditModePresetLayoutManager:GetModernSystems() or {}) do
        if info.system == frame.system and info.systemIndex == frame.systemIndex then
            return DeepCopy(info)
        end
    end
end

local function SetAnchor(info, point, relativePoint, offsetX, offsetY)
    info.anchorInfo = {
        point = point, relativeTo = 'UIParent', relativePoint = relativePoint,
        offsetX = offsetX, offsetY = offsetY,
    }
end

local function ApplyControllerSafeAnchor(frame, info)
    local systems = Enum.EditModeSystem
    local system = frame.system
    if system == systems.ExtraAbilities then
        SetAnchor(info, 'BOTTOM', 'CENTER', 0, -80)
    elseif system == systems.EncounterBar then
        SetAnchor(info, 'BOTTOM', 'CENTER', 0, 0)
    elseif system == systems.TalkingHeadFrame then
        SetAnchor(info, 'TOP', 'TOP', -420, -220)
    elseif system == systems.VehicleLeaveButton then
        SetAnchor(info, 'BOTTOM', 'CENTER', 92, -80)
    elseif system == systems.ArchaeologyBar then
        SetAnchor(info, 'TOP', 'TOP', 300, -225)
    elseif system == systems.CooldownViewer and
           Enum.EditModeCooldownViewerSystemIndices then
        local cooldowns = Enum.EditModeCooldownViewerSystemIndices
        if frame.systemIndex == cooldowns.Essential then
            SetAnchor(info, 'BOTTOM', 'CENTER', 0, 110)
        elseif frame.systemIndex == cooldowns.Utility then
            SetAnchor(info, 'BOTTOM', 'CENTER', 0, 55)
        elseif frame.systemIndex == cooldowns.BuffIcon then
            SetAnchor(info, 'BOTTOM', 'CENTER', 0, 165)
        elseif frame.systemIndex == cooldowns.BuffBar then
            SetAnchor(info, 'BOTTOMRIGHT', 'CENTER', -460, -40)
        end
    end
end

local function QueueModernLayoutPolicy()
    if modernApplying or modernQueued then return end
    modernQueued = true
    C_Timer.After(0, function()
        modernQueued = false
        ApplyModernLayoutPolicy()
    end)
end

local function InstallModernPolicyHooks()
    local manager = EditModeManagerFrame
    if modernHooksInstalled or not manager then return end
    modernHooksInstalled = true
    if type(manager.RegisterSystemFrame) == 'function' then
        hooksecurefunc(manager, 'RegisterSystemFrame', QueueModernLayoutPolicy)
    end
    if type(manager.ExitEditMode) == 'function' then
        hooksecurefunc(manager, 'ExitEditMode', QueueModernLayoutPolicy)
    end
end

ApplyModernLayoutPolicy = function()
    if modernApplying or InCombatLockdown() then return end
    local manager = EditModeManagerFrame
    if not manager or manager.editModeActive or
       type(manager.registeredSystemFrames) ~= 'table' then return end
    InstallModernPolicyHooks()

    modernApplying = true
    for _, frame in ipairs(manager.registeredSystemFrames) do
        if frame and type(frame.UpdateSystem) == 'function' and
           not IsProtectedModernSystem(frame) and
           (type(frame.IsInitialized) ~= 'function' or frame:IsInitialized()) then
            local info = FindModernSystemInfo(frame)
            if info then
                ApplyControllerSafeAnchor(frame, info)
                frame:UpdateSystem(info)
            end
        end
    end
    modernApplying = false
    MovePlayerAuraLane()
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
    ApplyModernLayoutPolicy()
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
        -- Aura and Edit Mode modules can load after this helper.
        QueuePlayerAuraLane()
        QueueModernLayoutPolicy()
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
