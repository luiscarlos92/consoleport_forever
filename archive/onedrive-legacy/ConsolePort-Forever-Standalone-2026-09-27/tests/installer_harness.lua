local reloads, savedLayouts, selectedLayout = 0, nil, nil
local loaded, conditionRefreshes = false, 0
local appliedBindings = {}

local function deepcopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do copy[deepcopy(key, seen)] = deepcopy(item, seen) end
    return copy
end

CopyTable = deepcopy
DEFAULT_CHAT_FRAME = { AddMessage = function() end }
ConsolePort_BarLayout = { name = "Before" }
ImmersionSetup = { scale = 1 }
ConsolePort_BarPresets = {}
ConsolePortShared = {}
ConsolePortSettings = { bindingPresetCondition = "[] Forever Controller" }
ConsolePortBindings = { OnConditionChanged=function() conditionRefreshes=conditionRefreshes+1 end }
StaticPopupDialogs, SlashCmdList = {}, {}
INSTALL, CANCEL = "Install", "Cancel"
UIParent = {}

Enum = {
    EditModeSystem = { UnitFrame=1, CastBar=2, AuraFrame=3, ChatFrame=4 },
    EditModeUnitFrameSystemIndices = { Player=1, Target=2 },
    EditModeCastBarSetting = { LockToPlayerFrame=1 },
    EditModeAuraFrameSystemIndices = { BuffFrame=1, DebuffFrame=2 },
    EditModeAuraFrameSetting = { IconDirection=1, IconWrap=2 },
    AuraFrameIconDirection = { Left=1 }, AuraFrameIconWrap = { Down=1 },
    EditModeChatFrameSetting = { WidthHundreds=1, WidthTensAndOnes=2, HeightHundreds=3, HeightTensAndOnes=4 },
    EditModeLayoutType = { Preset=0, Account=1, Character=2 },
}

local function systems()
    return {
        {system=1,systemIndex=1,settings={},anchorInfo={}}, {system=1,systemIndex=2,settings={},anchorInfo={}},
        {system=2,settings={},anchorInfo={}}, {system=3,systemIndex=1,settings={},anchorInfo={}},
        {system=3,systemIndex=2,settings={},anchorInfo={}}, {system=4,settings={},anchorInfo={}},
    }
end

local presets = {
    {layoutName="Modern", layoutType=0, layoutIndex=1, systems=systems()},
    {layoutName="Classic", layoutType=0, layoutIndex=2, systems=systems()},
}
local saved = {
    {layoutName="RealUI", layoutType=1, layoutIndex=41, systems=systems()},
    {layoutName="Console Port - Forever", layoutType=1, layoutIndex=77, systems=systems()},
}
table.insert(saved[2].systems, {system=99, systemIndex=7, settings={}, anchorInfo={offsetX=123}})
local layoutInfo = { activeLayout=1, layouts=saved }

EditModePresetLayoutManager = { GetCopyOfPresetLayouts=function() return deepcopy(presets) end }
EditModeManagerFrame = { IsInitialized=function() return true end }
C_AddOns = {
    GetAddOnMetadata=function() return "1.2.0" end,
    IsAddOnLoaded=function(name) return name ~= "Blizzard_EditMode" or loaded end,
    LoadAddOn=function(name) assert(name == "Blizzard_EditMode") loaded=true return true end,
}
C_EditMode = {
    GetLayouts=function() return layoutInfo end,
    ConvertLayoutInfoToString=function(layout) return "backup:"..layout.layoutName end,
    ConvertStringToLayoutInfo=function() error("existing migration must not discard the approved profile") end,
    SaveLayouts=function(info) savedLayouts=deepcopy(info) end,
    SetActiveLayout=function(index) selectedLayout=index end,
}
C_Timer = { After=function(_, callback) callback() end }
CPAPI = { SetBinding=function(key, action) appliedBindings[key]=action return true end }

function CreateFrame()
    local frame = {events={}}
    function frame:RegisterEvent(event) self.events[event]=true end
    function frame:SetScript(kind, script) self[kind]=script end
    return frame
end
function InCombatLockdown() return false end
function GetBindingAction(key) return "OLD_"..key end
function SetBinding(key, action) appliedBindings[key]=action return true end
function SaveBindings() end
function GetCurrentBindingSet() return 1 end
function GetCVar() return "OLD" end
function SetCVar() end
function time() return 123 end
function ReloadUI() reloads=reloads+1 end
function strtrim(value) return value:match("^%s*(.-)%s*$") end

local shownDialog
function StaticPopup_Show(key)
    local definition = assert(StaticPopupDialogs[key])
    local dialog = {name="StaticPopup1"}
    local function button(onClick) return {IsEnabled=function() return true end, Click=function() onClick() end} end
    dialog.button1 = button(definition.OnAccept)
    dialog.button2 = button(function() end)
    function dialog:GetName() return self.name end
    function dialog:EnableGamePadButton(value) self.gamepad=value end
    function dialog:SetPropagateKeyboardInput(value) self.propagate=value end
    function dialog:SetScript(kind, script) self[kind]=script end
    shownDialog=dialog
    return dialog
end

local Addon = {}
assert(loadfile("_retail_/Interface/AddOns/ConsolePort_Forever/Layout.lua"))("ConsolePort_Forever", Addon)
assert(loadfile("_retail_/Interface/AddOns/ConsolePort_Forever/Bindings.lua"))("ConsolePort_Forever", Addon)
assert(loadfile("_retail_/Interface/AddOns/ConsolePort_Forever/Profile.lua"))("ConsolePort_Forever", Addon)
assert(loadfile("_retail_/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua"))("ConsolePort_Forever", Addon)

assert(ConsolePortSettings.bindingPresetCondition == "", "schema-1 condition was not migrated early")
assert(conditionRefreshes == 1, "ConsolePort condition driver was not refreshed")

Addon:ShowPrompt(true)
assert(loaded, "Blizzard_EditMode was not preloaded")
assert(shownDialog and shownDialog.gamepad, "prompt did not enable gamepad input")
shownDialog.OnGamePadButtonDown(shownDialog, "PAD1")

local expectedCombinedIndex = #presets + 2
assert(reloads == 1, "reload was not synchronous with the controller press")
assert(savedLayouts and selectedLayout == expectedCombinedIndex, "combined Edit Mode index was not selected")
assert(savedLayouts.activeLayout == expectedCombinedIndex, "saved active layout used the wrong index space")
assert(#savedLayouts.layouts == #presets + #saved, "SaveLayouts did not receive the combined layout list")
assert(savedLayouts.layouts[1].layoutName == "Modern" and savedLayouts.layouts[2].layoutName == "Classic", "built-in presets were not retained")
assert(savedLayouts.layouts[expectedCombinedIndex].layoutName == "Console Port - Forever", "managed profile was not replaced in the combined slot")
assert(savedLayouts.layouts[expectedCombinedIndex].layoutIndex == 77, "existing profile identity was not preserved")
assert(ConsolePortForeverDB.profileSource == "existing", "schema-1 migration did not retain the complete approved profile")

local player, target
for _, info in ipairs(savedLayouts.layouts[expectedCombinedIndex].systems) do
    if info.system==Enum.EditModeSystem.UnitFrame and info.systemIndex==Enum.EditModeUnitFrameSystemIndices.Player then player=info end
    if info.system==Enum.EditModeSystem.UnitFrame and info.systemIndex==Enum.EditModeUnitFrameSystemIndices.Target then target=info end
end
assert(player.anchorInfo.offsetX == -315 and target.anchorInfo.offsetX == 315, "unit frames are not symmetric")
assert(ConsolePortForeverDB.installedSchema == 2, "account schema not recorded")
assert(ConsolePortForeverDB.activeCombinedIndex == expectedCombinedIndex, "diagnostic combined index missing")
assert(ConsolePortForeverCharacterDB.installedSchema == 2, "character schema not recorded")
assert(ConsolePort_BarLayout.name == "Forever: Expanded Crosses", "bar layout not installed")
assert(ImmersionSetup.scale == 1.2, "Immersion settings not installed")
assert(ConsolePortShared[Addon.BINDING_PRESET_NAME], "named ConsolePort preset was not registered")
assert(ConsolePortSettings.bindingPresetCondition == "", "racy condition was re-enabled")
assert(appliedBindings.PAD1 == "JUMP", "base binding preset was not applied")
assert(appliedBindings["CTRL-SHIFT-PADDUP"] == "CLICK LM_B1:LeftButton", "modified binding preset was not applied")

local retained
for _, info in ipairs(savedLayouts.layouts[expectedCombinedIndex].systems) do
    if info.system == 99 then retained = info end
end
assert(retained and retained.anchorInfo.offsetX == 123, "unowned approved systems were discarded during migration")

-- Clean account: import the bundled native profile and insert its account
-- layout before any character layouts, while still selecting combined space.
layoutInfo = {activeLayout=1, layouts={{layoutName="CharacterUI", layoutType=Enum.EditModeLayoutType.Character, layoutIndex=88, systems=systems()}}}
C_EditMode.ConvertStringToLayoutInfo = function(serialized)
    assert(serialized == Addon.BundledEditModeProfile and #serialized > 2000, "bundled native profile is missing")
    local imported=deepcopy(presets[1])
    table.insert(imported.systems, {system=98, settings={}, anchorInfo={offsetX=456}})
    return imported
end
ConsolePortForeverDB, ConsolePortForeverCharacterDB = nil, nil
Addon:Install()
assert(reloads == 2, "clean install did not reload")
assert(selectedLayout == #presets + 1, "clean install selected the wrong combined index")
assert(savedLayouts.layouts[#presets + 1].layoutName == "Console Port - Forever", "clean account profile was not inserted before character layouts")
assert(savedLayouts.layouts[#presets + 2].layoutName == "CharacterUI", "character layout ordering was not preserved")
assert(ConsolePortForeverDB.profileSource == "bundled", "clean install did not use the portable bundled profile")

-- A rejected Edit Mode save must not leave bar, Immersion, or binding state
-- half-installed, which was the schema-1 failure mode seen in game.
local reloadsBeforeFailure = reloads
layoutInfo = {activeLayout=1, layouts={}}
ConsolePortForeverDB, ConsolePortForeverCharacterDB = nil, nil
ConsolePort_BarLayout, ImmersionSetup = {name="Untouched"}, {scale=0.75}
ConsolePortShared, appliedBindings = {}, {}
C_EditMode.SaveLayouts = function() error("simulated save rejection") end
Addon:Install()
assert(reloads == reloadsBeforeFailure, "failed Edit Mode save still reloaded")
assert(ConsolePort_BarLayout.name == "Untouched", "failed Edit Mode save partially changed the action bars")
assert(ImmersionSetup.scale == 0.75, "failed Edit Mode save partially changed Immersion")
assert(next(appliedBindings) == nil, "failed Edit Mode save partially changed bindings")
assert(ConsolePortForeverDB.lastError and ConsolePortForeverDB.lastError:match("Edit Mode save failed"), "failed transaction did not record its error")

print("PASS exact migration + portable clean install + combined index + fail-closed transaction")
