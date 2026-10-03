local _, Addon = ...

local MENU_FRAMES = {"MicroButtonAndBagsBar", "MicroMenuContainer", "BagsBar"}
local originalShown = {}
local editModeActive = false

local function Installed()
    return Addon.IsCharacterInstalled and Addon:IsCharacterInstalled()
end

local function HideMenus()
    if not Installed() or editModeActive or InCombatLockdown() then return end
    for _, name in ipairs(MENU_FRAMES) do
        local frame = _G[name]
        if frame then
            if originalShown[name] == nil then originalShown[name] = frame:IsShown() end
            frame:Hide()
        end
    end
end

local function RestoreMenusForEditing()
    if not Installed() or InCombatLockdown() then return end
    editModeActive = true
    for _, name in ipairs(MENU_FRAMES) do
        local frame = _G[name]
        if frame and originalShown[name] then frame:Show() end
    end
end

local function LeaveEditMode()
    editModeActive = false
    C_Timer.After(0, HideMenus)
end

if EventRegistry and type(EventRegistry.RegisterCallback) == "function" then
    EventRegistry:RegisterCallback("EditMode.Enter", RestoreMenusForEditing, Addon)
    EventRegistry:RegisterCallback("EditMode.Exit", LeaveEditMode, Addon)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:SetScript("OnEvent", function()
    C_Timer.After(0, HideMenus)
    C_Timer.After(1, HideMenus)
end)
