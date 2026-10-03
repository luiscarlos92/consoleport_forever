local ADDON_NAME, Addon = ...

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "0.0.0"
Addon.SCHEMA = 2
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

local function GetPresetLayouts()
    if not EditModePresetLayoutManager or type(EditModePresetLayoutManager.GetCopyOfPresetLayouts) ~= "function" then
        return nil
    end
    return EditModePresetLayoutManager:GetCopyOfPresetLayouts()
end

-- GetLayouts() contains only saved layouts, while activeLayout and
-- SetActiveLayout() address Blizzard's combined list: presets first, then saved.
local function ResolveActiveLayout(layoutInfo, presets)
    local active = layoutInfo and layoutInfo.activeLayout
    if not active then return nil end
    if active <= #presets then return active, presets[active] end
    return active, layoutInfo.layouts and layoutInfo.layouts[active - #presets]
end

local function FindProfile(layouts, name)
    for index, layout in ipairs(layouts or {}) do
        if layout.layoutName == name then return index, layout end
    end
end

local function PutAccountProfile(layouts, profile, existingIndex)
    if existingIndex then
        layouts[existingIndex] = profile
        return existingIndex
    end

    -- Blizzard keeps account layouts before character layouts. Preserve that
    -- ordering so its own Edit Mode manager can continue editing the profile.
    local insertAt = #layouts + 1
    for index, layout in ipairs(layouts) do
        if layout.layoutType == Enum.EditModeLayoutType.Character then
            insertAt = index
            break
        end
    end
    table.insert(layouts, insertAt, profile)
    return insertAt
end

local function BuildCombinedLayouts(presets, savedLayouts)
    local combined = {}
    for _, layout in ipairs(presets) do table.insert(combined, CopyTable(layout)) end
    for _, layout in ipairs(savedLayouts) do table.insert(combined, layout) end
    return combined
end

local function CreateManagedProfile(existing, modern)
    if existing then return CopyTable(existing), "existing" end
    if type(Addon.BundledEditModeProfile) == "string" and
       C_EditMode and type(C_EditMode.ConvertStringToLayoutInfo) == "function" then
        local ok, imported = pcall(C_EditMode.ConvertStringToLayoutInfo, Addon.BundledEditModeProfile)
        if ok and type(imported) == "table" and type(imported.systems) == "table" then
            return imported, "bundled"
        end
    end
    return CopyTable(modern), "modern-fallback"
end

local function CanAddAccountProfile(savedLayouts, existing)
    if existing then return true end
    local limit = Constants and Constants.EditModeConsts and Constants.EditModeConsts.EditModeMaxLayoutsPerType
    if not limit then return true end
    local count = 0
    for _, layout in ipairs(savedLayouts) do
        if layout.layoutType == Enum.EditModeLayoutType.Account then count = count + 1 end
    end
    return count < limit
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

local function SetControllerBinding(key, action)
    if CPAPI and type(CPAPI.SetBinding) == "function" then
        return CPAPI.SetBinding(key, action or "", false)
    end
    return SetBinding(key, action ~= "" and action or nil)
end

local function InstallBindings(db)
    local presetName, bindings = Addon.BINDING_PRESET_NAME, Addon.BundledBindings
    if type(bindings) ~= "table" then return false end

    ConsolePortShared = ConsolePortShared or {}
    if db.backup.consolePortPreset == nil then
        db.backup.consolePortPreset = ConsolePortShared[presetName] and CopyTable(ConsolePortShared[presetName]) or false
    end
    ConsolePortShared[presetName] = {
        Meta = {Name=presetName, Type="PlayStation 5"},
        Bindings = CopyTable(bindings),
    }

    ConsolePortSettings = ConsolePortSettings or {}
    if db.backup.bindingPresetCondition == nil then
        db.backup.bindingPresetCondition = ConsolePortSettings.bindingPresetCondition or false
    end
    -- ConsolePort can evaluate this before Shared/Data is loaded. The installer
    -- owns application, so disable the racy loader but keep the named preset.
    ConsolePortSettings.bindingPresetCondition = ""
    if ConsolePortBindings and type(ConsolePortBindings.OnConditionChanged) == "function" then
        pcall(ConsolePortBindings.OnConditionChanged, ConsolePortBindings)
    end

    db.backup.bindings = db.backup.bindings or {}
    for button, set in pairs(bindings) do
        for modifier, action in pairs(set) do
            local key = modifier .. button
            if db.backup.bindings[key] == nil then db.backup.bindings[key] = GetBindingAction(key, true) or false end
            SetControllerBinding(key, action)
        end
    end
    db.backup.cvars = db.backup.cvars or {}
    for cvar, value in pairs({GamePadEmulateShift="PADLTRIGGER", GamePadEmulateCtrl="PADRTRIGGER"}) do
        if db.backup.cvars[cvar] == nil then db.backup.cvars[cvar] = GetCVar(cvar) end
        SetCVar(cvar, value)
    end
    SaveBindings(GetCurrentBindingSet())
    return true
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

local function ReadyForEditMode()
    local presets = GetPresetLayouts()
    local info = C_EditMode and C_EditMode.GetLayouts and C_EditMode.GetLayouts()
    -- The manager window is load-on-demand and may not have consumed its first
    -- layout event yet. The C API and preset manager are the actual prerequisites.
    return presets and #presets > 0 and presets[1] and presets[1].systems and info and info.layouts, presets, info
end

function Addon:Install()
    if InCombatLockdown() then self.pendingInstall = true Print("Installation is queued until combat ends.") return end
    local db, charDB = AccountDB(), CharacterDB()
    local ready, presets, layoutInfo = ReadyForEditMode()
    if not ready then db.lastError = "Edit Mode API unavailable" Print("Could not install: Blizzard Edit Mode is unavailable.") return end

    local active, source = ResolveActiveLayout(layoutInfo, presets)
    source = source or presets[1]
    db.backup.editMode = db.backup.editMode or C_EditMode.ConvertLayoutInfoToString(source)
    db.backup.activeLayout = db.backup.activeLayout or active
    db.backup.activeLayoutName = db.backup.activeLayoutName or source.layoutName

    local savedLayouts = layoutInfo.layouts
    local savedIndex, existing = FindProfile(savedLayouts, self.PROFILE_NAME)
    if not CanAddAccountProfile(savedLayouts, existing) then
        db.lastError = "Maximum account Edit Mode layouts reached"
        Print("Could not install: delete one account layout in Edit Mode, then use /cpf install.")
        return
    end
    if type(Addon.BundledBarLayout) ~= "table" or type(Addon.BundledBindings) ~= "table" or type(ImmersionSetup) ~= "table" then
        db.lastError = "Bundled data or required dependency unavailable"
        Print("Could not install: required ConsolePort or Immersion data is unavailable.")
        return
    end
    -- Preserve the complete schema-1 profile when migrating this prototype: it
    -- already contains the approved minimap, objective, and remaining Blizzard
    -- geometry. Clean installs use the bundled native export; current Modern is
    -- only the forward-compatibility fallback if Blizzard rejects that export.
    local profile, profileSource = CreateManagedProfile(existing, presets[1])
    if existing and existing.layoutIndex ~= nil then profile.layoutIndex = existing.layoutIndex end
    profile.layoutName, profile.layoutType = self.PROFILE_NAME, Enum.EditModeLayoutType.Account
    PatchProfile(profile)
    savedIndex = PutAccountProfile(savedLayouts, profile, savedIndex)
    local combinedIndex = #presets + savedIndex

    -- The C API is the trust boundary; never call live Edit Mode UpdateSystem.
    -- SaveLayouts expects the same combined list used internally by Blizzard's
    -- Edit Mode manager, even though GetLayouts() returns only saved layouts.
    layoutInfo.layouts = BuildCombinedLayouts(presets, savedLayouts)
    layoutInfo.activeLayout = combinedIndex
    local savedOK, savedError = pcall(C_EditMode.SaveLayouts, layoutInfo)
    if not savedOK then
        db.lastError = "Edit Mode save failed: " .. tostring(savedError)
        Print("Could not install the Edit Mode profile; no controller data was changed.")
        return
    end
    local selectedOK, selectedError = pcall(C_EditMode.SetActiveLayout, combinedIndex)
    if not selectedOK then
        db.lastError = "Edit Mode activation failed: " .. tostring(selectedError)
        Print("The profile was saved but could not be activated; use /cpf install to retry.")
        return
    end

    -- All fallible Edit Mode work completed before touching dependency-owned
    -- SavedVariables, preventing the partial-install state seen in schema 1.
    InstallBarLayout(charDB)
    InstallImmersion(db)
    InstallBindings(db)
    db.installedSchema, db.installedAddonVersion, db.profileName = self.SCHEMA, self.VERSION, self.PROFILE_NAME
    db.activeCombinedIndex, db.savedProfileIndex = combinedIndex, savedIndex
    db.profileSource = profileSource
    db.lastInstallAt, db.lastError = time(), nil
    db.dependencies = {ConsolePort=C_AddOns.IsAddOnLoaded("ConsolePort"), ConsolePort_Bar=C_AddOns.IsAddOnLoaded("ConsolePort_Bar"), ConsolePort_Menu=C_AddOns.IsAddOnLoaded("ConsolePort_Menu"), Immersion=C_AddOns.IsAddOnLoaded("Immersion")}
    charDB.installedSchema = self.SCHEMA
    Print("Interface installed. Reloading to activate " .. self.PROFILE_NAME .. ".")
    ReloadUI()
end

function Addon:Restore()
    if InCombatLockdown() then Print("Restore is unavailable in combat.") return end
    local db, charDB = AccountDB(), CharacterDB()
    local ready, presets, info = ReadyForEditMode()
    if not ready then Print("Restore is unavailable until Blizzard Edit Mode initializes.") return end
    local index = db.backup.activeLayout
    if index and ((index <= #presets and presets[index]) or info.layouts[index - #presets]) then C_EditMode.SetActiveLayout(index) end
    for key, action in pairs(db.backup.bindings or {}) do SetControllerBinding(key, action or "") end
    for cvar, value in pairs(db.backup.cvars or {}) do SetCVar(cvar, value) end
    if db.backup.bindingPresetCondition ~= nil then ConsolePortSettings.bindingPresetCondition = db.backup.bindingPresetCondition or "" end
    if db.backup.consolePortPreset ~= nil then ConsolePortShared[Addon.BINDING_PRESET_NAME] = db.backup.consolePortPreset or nil end
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
        if not loaded then db.lastError = "Could not load Blizzard Edit Mode: " .. tostring(reason) Print(db.lastError) return end
    end
    if not ReadyForEditMode() and attempt < 40 then
        C_Timer.After(0.1, function() Addon:ShowPrompt(force, attempt + 1) end)
        return
    elseif not ReadyForEditMode() then
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
            if button == "PAD1" and accept and accept:IsEnabled() then accept:Click()
            elseif button == "PAD2" and cancel and cancel:IsEnabled() then cancel:Click() end
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

-- Migrate schema 1 before ConsolePort's conditional driver can fire again.
if ConsolePortSettings and ConsolePortSettings.bindingPresetCondition == "[] Forever Controller" then
    ConsolePortSettings.bindingPresetCondition = ""
    if ConsolePortBindings and type(ConsolePortBindings.OnConditionChanged) == "function" then
        pcall(ConsolePortBindings.OnConditionChanged, ConsolePortBindings)
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
        if blamedAddon == ADDON_NAME then AccountDB().lastError = event .. ": " .. tostring(blockedFunction) Print(AccountDB().lastError) end
    elseif event == "PLAYER_LOGIN" then C_Timer.After(2, function() Addon:ShowPrompt(false) end) end
end)
