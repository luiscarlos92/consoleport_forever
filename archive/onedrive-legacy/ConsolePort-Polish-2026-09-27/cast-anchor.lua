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
    point(frame, 'BOTTOM', bank, 'TOP', 0, 12)
    castApplying = false
end
