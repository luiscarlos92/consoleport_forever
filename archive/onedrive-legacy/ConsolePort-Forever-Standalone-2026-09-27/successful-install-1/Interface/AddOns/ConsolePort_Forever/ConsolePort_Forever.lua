local ADDON_NAME, Addon = ...

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0.0.0"
Addon.SCHEMA = 1
Addon.PROFILE_NAME = "Console Port - Forever"

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0Console Port - Forever:|r " .. message)
end

local function AccountDB()
    ConsolePortForeverDB = ConsolePortForeverDB or {}
    ConsolePortForeverDB.backup = ConsolePortForeverDB.backup or {}
    return ConsolePortForeverDB
end

local function CharacterDB()
    ConsolePortForeverCharacterDB = ConsolePortForeverCharacterDB or {}
    return ConsolePortForeverCharacterDB
end

local function FindProfile(layouts, name)
    for index, layout in pairs(layouts or {}) do
        if layout.layoutName == name then return index, layout end
    end
end

local function FindUsableSource(layoutInfo)
    local layouts = layoutInfo and layoutInfo.layouts
    local active = layoutInfo and layoutInfo.activeLayout
    if layouts and layouts[active] and layouts[active].systems then return active, layouts[active] end
    for index, layout in pairs(layouts or {}) do
        if type(index) == "number" and type(layout) == "table" and type(layout.systems) == "table" then
            return index, layout
        end
    end
end

local function FindSystem(layout, system, systemIndex)
    for _, info in ipairs(layout.systems or {}) do
        if info.system == system and info.systemIndex == systemIndex then return info end
    end
end

local function SetAnchor(layout, system, systemIndex, point, relativePoint, x, y)
    local info = FindSystem(layout, system, systemIndex)
    if not info then return false end
    info.anchorInfo = info.anchorInfo or {}
    info.anchorInfo.point, info.anchorInfo.relativeTo = point, "UIParent"
    info.anchorInfo.relativePoint, info.anchorInfo.offsetX, info.anchorInfo.offsetY = relativePoint, x, y
    return true
end

local function SetSetting(layout, system, systemIndex, setting, value)
    if setting == nil then return false end
    local info = FindSystem(layout, system, systemIndex)
    if not info then return false end
    info.settings = info.settings or {}
    for key, entry in pairs(info.settings) do
        if type(entry) == "table" and entry.setting == setting then entry.value = value return true end
        if key == setting and type(entry) == "number" then info.settings[key] = value return true end
    end
    table.insert(info.settings, {setting = setting, value = value})
    return true
end

local function PatchProfile(profile)
    local s, u = Enum.EditModeSystem, Enum.EditModeUnitFrameSystemIndices
    SetAnchor(profile, s.UnitFrame, u.Player, "CENTER", "CENTER", -315, -175)
    SetAnchor(profile, s.UnitFrame, u.Target, "CENTER", "CENTER", 315, -175)
    SetAnchor(profile, s.CastBar, nil, "BOTTOM", "CENTER", 0, -116)
    SetSetting(profile, s.CastBar, nil, Enum.EditModeCastBarSetting.LockToPlayerFrame, 0)
    local a = Enum.EditModeAuraFrameSystemIndices
    SetAnchor(profile, s.AuraFrame, a.BuffFrame, "TOPRIGHT", "CENTER", -443, -125)
    SetAnchor(profile, s.AuraFrame, a.DebuffFrame, "TOPRIGHT", "CENTER", -443, -220)
    for _, index in ipairs({a.BuffFrame, a.DebuffFrame}) do
        SetSetting(profile, s.AuraFrame, index, Enum.EditModeAuraFrameSetting.IconDirection, Enum.AuraFrameIconDirection.Left)
        SetSetting(profile, s.AuraFrame, index, Enum.EditModeAuraFrameSetting.IconWrap, Enum.AuraFrameIconWrap.Down)
    end
    SetAnchor(profile, s.ChatFrame, nil, "BOTTOMLEFT", "BOTTOMLEFT", 35, 55)
    SetSetting(profile, s.ChatFrame, nil, Enum.EditModeChatFrameSetting.WidthHundreds, 4)
    SetSetting(profile, s.ChatFrame, nil, Enum.EditModeChatFrameSetting.WidthTensAndOnes, 0)
    SetSetting(profile, s.ChatFrame, nil, Enum.EditModeChatFrameSetting.HeightHundreds, 1)
    SetSetting(profile, s.ChatFrame, nil, Enum.EditModeChatFrameSetting.HeightTensAndOnes, 20)
end

local BINDINGS = {
    PADBACK="TOGGLEWORLDMAP", ["SHIFT-PADBACK"]="TOGGLEWORLDMAP",
    ["CTRL-PADBACK"]="TOGGLEWORLDMAP", ["CTRL-SHIFT-PADBACK"]="TOGGLEWORLDMAP",
    PADFORWARD="CLICK ConsolePortMenuTrigger:LeftButton",
    ["SHIFT-PADFORWARD"]="CLICK ConsolePortMenuTrigger:LeftButton",
    ["CTRL-PADFORWARD"]="CLICK ConsolePortMenuTrigger:LeftButton",
    ["CTRL-SHIFT-PADFORWARD"]="CLICK ConsolePortMenuTrigger:LeftButton",
}

local function InstallBindings(db)
    db.backup.bindings = db.backup.bindings or {}
    for key, action in pairs(BINDINGS) do
        if db.backup.bindings[key] == nil then db.backup.bindings[key] = GetBindingAction(key, true) or false end
        SetBinding(key, action)
    end
    db.backup.cvars = db.backup.cvars or {}
    for cvar, value in pairs({GamePadEmulateShift="PADLTRIGGER", GamePadEmulateCtrl="PADRTRIGGER"}) do
        if db.backup.cvars[cvar] == nil then db.backup.cvars[cvar] = GetCVar(cvar) end
        SetCVar(cvar, value)
    end
    SaveBindings(GetCurrentBindingSet())
end

local function InstallBarLayout(charDB)
    if type(Addon.BundledBarLayout) ~= "table" then return false end
    if charDB.backupBarLayout == nil then charDB.backupBarLayout = CopyTable(ConsolePort_BarLayout) end
    ConsolePort_BarPresets = ConsolePort_BarPresets or {}
    ConsolePort_BarPresets[Addon.BundledBarLayout.name] = CopyTable(Addon.BundledBarLayout)
    ConsolePort_BarLayout = CopyTable(Addon.BundledBarLayout)
    return true
end

local function InstallImmersion(db)
    if type(ImmersionSetup) ~= "table" then return false end
    if db.backup.immersion == nil then db.backup.immersion = CopyTable(ImmersionSetup) end
    for key, value in pairs({
        strata="MEDIUM", boxoffsetY=39.27963256835938, boxoffsetX=0, scale=1.2,
        elementscale=1, titlescale=1, titleoffset=446.7689819335938,
        titleoffsetY=-117.6884460449219, enablenumbers=true, movetalkinghead=true,
        hidetooltip=true, hideminimap=true, hidetracker=true, hideui=true,
        boxpoint="Bottom", immersivemode=true,
    }) do ImmersionSetup[key] = value end
    return true
end

function Addon:Install()
    if InCombatLockdown() then self.pendingInstall = true Print("Installation is queued until combat ends.") return end
    local db, charDB = AccountDB(), CharacterDB()
    if not C_EditMode or not C_EditMode.GetLayouts or not Enum.EditModeSystem then
        db.lastError = "Edit Mode API unavailable" Print("Could not install: Blizzard Edit Mode is unavailable.") return
    end
    local layoutInfo = C_EditMode.GetLayouts()
    local layouts = layoutInfo and layoutInfo.layouts
    local active, source = FindUsableSource(layoutInfo)
    if not source then db.lastError = "No usable Edit Mode layout" Print("Could not install: Blizzard did not provide a usable Edit Mode layout.") return end

    db.backup.editMode = db.backup.editMode or C_EditMode.ConvertLayoutInfoToString(source)
    db.backup.activeLayout, db.backup.activeLayoutName = db.backup.activeLayout or active, db.backup.activeLayoutName or source.layoutName
    local profileIndex, existing = FindProfile(layouts, self.PROFILE_NAME)
    local profile = CopyTable(existing or source)
    profile.layoutName, profile.layoutType = self.PROFILE_NAME, Enum.EditModeLayoutType.Account
    PatchProfile(profile)
    if profileIndex then layouts[profileIndex] = profile else table.insert(layouts, profile) profileIndex = #layouts end
    if not InstallBarLayout(charDB) then db.lastError = "Bundled action-bar layout unavailable" Print("Could not install the action-bar layout.") return end
    if not InstallImmersion(db) then db.lastError = "Immersion settings unavailable" Print("Could not install the Immersion layout.") return end

    -- This C API serialization is the trust boundary. Never pass this addon-owned
    -- table to a live Edit Mode frame or call that frame's UpdateSystem method.
    layoutInfo.activeLayout = profileIndex
    C_EditMode.SaveLayouts(layoutInfo)
    C_EditMode.SetActiveLayout(profileIndex)
    InstallBindings(db)
    db.installedSchema, db.installedAddonVersion, db.profileName = self.SCHEMA, self.VERSION, self.PROFILE_NAME
    db.lastInstallAt, db.lastError = time(), nil
    db.dependencies = {ConsolePort=C_AddOns.IsAddOnLoaded("ConsolePort"), ConsolePort_Bar=C_AddOns.IsAddOnLoaded("ConsolePort_Bar"), ConsolePort_Menu=C_AddOns.IsAddOnLoaded("ConsolePort_Menu"), Immersion=C_AddOns.IsAddOnLoaded("Immersion")}
    charDB.installedSchema = self.SCHEMA
    Print("Interface installed. Reloading to activate " .. self.PROFILE_NAME .. ".")
    -- Keep this in the original mouse/controller hardware event. Deferring it
    -- through a timer makes Retail reject the reload as an addon action.
    ReloadUI()
end

function Addon:Restore()
    if InCombatLockdown() then Print("Restore is unavailable in combat.") return end
    local db, charDB, info = AccountDB(), CharacterDB(), C_EditMode.GetLayouts()
    local index = db.backup.activeLayout
    if index and info.layouts[index] and (not db.backup.activeLayoutName or info.layouts[index].layoutName == db.backup.activeLayoutName) then C_EditMode.SetActiveLayout(index) end
    for key, action in pairs(db.backup.bindings or {}) do SetBinding(key, action or nil) end
    for cvar, value in pairs(db.backup.cvars or {}) do SetCVar(cvar, value) end
    if charDB.backupBarLayout then ConsolePort_BarLayout = CopyTable(charDB.backupBarLayout) end
    if db.backup.immersion then ImmersionSetup = CopyTable(db.backup.immersion) end
    SaveBindings(GetCurrentBindingSet())
    Print("Previous layout and recorded bindings restored. Reloading.")
    ReloadUI()
end

function Addon:ShowPrompt(force, attempt)
    local db, charDB = AccountDB(), CharacterDB()
    if not force and db.installedSchema == self.SCHEMA and charDB.installedSchema == self.SCHEMA then return end
    attempt = attempt or 1
    if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        local loaded, reason = C_AddOns.LoadAddOn("Blizzard_EditMode")
        if not loaded then
            db.lastError = "Could not load Blizzard Edit Mode: " .. tostring(reason)
            Print(db.lastError)
            return
        end
    end
    local _, source = FindUsableSource(C_EditMode.GetLayouts())
    if not source and attempt < 25 then
        C_Timer.After(0.1, function() Addon:ShowPrompt(force, attempt + 1) end)
        return
    elseif not source then
        db.lastError = "Blizzard Edit Mode did not initialize"
        Print(db.lastError .. "; type /cpf install to retry.")
        return
    end
    local dialog = StaticPopup_Show("CONSOLEPORT_FOREVER_INSTALL", db.installedSchema and "update" or "install")
    if dialog then
        dialog:EnableGamePadButton(true)
        dialog:SetPropagateKeyboardInput(false)
        dialog:SetScript("OnGamePadButtonDown", function(self, button)
            local accept = self.button1 or _G[self:GetName() .. "Button1"]
            local cancel = self.button2 or _G[self:GetName() .. "Button2"]
            if button == "PAD1" and accept and accept:IsEnabled() then
                accept:Click()
            elseif button == "PAD2" and cancel and cancel:IsEnabled() then
                cancel:Click()
            end
        end)
    end
end

StaticPopupDialogs.CONSOLEPORT_FOREVER_INSTALL = {
    text="New interface to be installed\n\nConsole Port - Forever will %s its native Edit Mode profile and controller layout. Your current profile and changed bindings will be backed up.",
    button1="Cross / A  Install", button2="Circle / B  Cancel", OnAccept=function() Addon:Install() end,
    timeout=0, whileDead=true, hideOnEscape=true, preferredIndex=3,
}

SLASH_CONSOLEPORTFOREVER1 = "/cpf"
SlashCmdList.CONSOLEPORTFOREVER = function(input)
    input = strtrim(input or ""):lower()
    if input == "install" or input == "update" then Addon:ShowPrompt(true)
    elseif input == "restore" then Addon:Restore()
    else
        local db, charDB = AccountDB(), CharacterDB()
        Print(("schema %s (account %s, character %s); profile %s; last error: %s"):format(Addon.SCHEMA,
            tostring(db.installedSchema or "not installed"), tostring(charDB.installedSchema or "not installed"),
            tostring(db.profileName or "none"), tostring(db.lastError or "none")))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("ADDON_ACTION_BLOCKED")
events:RegisterEvent("ADDON_ACTION_FORBIDDEN")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_REGEN_ENABLED" and Addon.pendingInstall then Addon.pendingInstall = nil Addon:ShowPrompt(true)
    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local blamedAddon, blockedFunction = ...
        if blamedAddon == ADDON_NAME then
            AccountDB().lastError = event .. ": " .. tostring(blockedFunction)
            Print(AccountDB().lastError)
        end
    elseif event == "PLAYER_LOGIN" then C_Timer.After(2, function() Addon:ShowPrompt(false) end) end
end)
