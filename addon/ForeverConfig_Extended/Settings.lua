local _, Addon = ...
-- Match the active shared Retail profile's overall multiplier. Native bar dimensions
-- already agree; copying them again would not repair the reported size difference.
local desiredScale = 1.428571452899855

function Addon:ApplySettings()
    if not self.active or InCombatLockdown() then return end
    local plater = _G.Plater
    if not (plater and plater.db and type(plater.db.GetCurrentProfile) == "function"
        and type(plater.RefreshConfig) == "function" and type(plater.db.profile) == "table") then return end
    local name = plater.db:GetCurrentProfile()
    if name ~= "Default" then return end
    local db = self:Database()
    local key = "plater-default-retail-scale-1"
    if db.migrations[key] then return end
    local profile = plater.db.profile
    -- A newer manual scale wins. Only the exact audited prior state is eligible.
    if profile.ui_parent_scale_tune ~= 1 or profile.use_ui_parent ~= true then
        db.migrations[key] = {outcome = "preserved-current-value", value = profile.ui_parent_scale_tune}
        return
    end
    profile.ui_parent_scale_tune = desiredScale
    local ok, message = pcall(plater.RefreshConfig, plater)
    if not ok then
        -- Roll back only our own value, never a concurrent/native replacement.
        if profile.ui_parent_scale_tune == desiredScale then profile.ui_parent_scale_tune = 1 end
        db.lastMigrationError = tostring(message)
        return
    end
    db.migrations[key] = {outcome = "applied", before = 1, after = desiredScale}
    db.lastMigrationError = nil
end
