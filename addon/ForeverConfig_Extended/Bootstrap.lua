local _, Addon = ...
if not Addon.active then return end
local frame = CreateFrame("Frame")
local generation = 0
local function refresh()
    Addon:ApplySettings()
    Addon:InstallBagBridge()
    Addon:Snapshot()
end
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if event == "PLAYER_LOGOUT" then
        generation = generation + 1
        if Addon.bagState then Addon.bagState.pending = nil end
        Addon:Snapshot("logout")
    elseif event ~= "ADDON_LOADED" or name == "Plater" or name == "BetterBags" or name == Addon.name then
        generation = generation + 1
        local current = generation
        C_Timer.After(2, function() if generation == current then refresh() end end)
    end
end)
SLASH_FOREVERCONFIGEXTENDED1 = "/foreverconfig"
SlashCmdList.FOREVERCONFIGEXTENDED = function() Addon:PrintStatus() end
