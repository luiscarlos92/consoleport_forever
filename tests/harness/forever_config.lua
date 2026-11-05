local timers, frames = {}, {}
local combat, allowed, nativeOpen = false, true, false
local BB = {Bags = {}, _buttons = {}, isForever = true}
local bag = {shown = false}
function bag:IsShown() return self.shown end
function bag:Show() self.shown = true end
function bag:Hide() self.shown = false end
BB.Bags.Backpack = bag
function BB:IsEnabled() return true end
function BB:UpdateButtonHighlight() end
local addon = BB
local context = {New = function() return {} end}
local debug = {Log = function() end}
local events = {}
function events:SendMessage(_, name) if name == 'bags/OpenClose' then addon.OnUpdate({}) end end
--@BETTERBAGS
local bagToggles = 0
local originalBagToggle = BB.ToggleAllBags
function BB:ToggleAllBags(...) bagToggles = bagToggles + 1; return originalBagToggle(self, ...) end
function InCombatLockdown() return combat end
function ContainerFrame_AllowedToOpenBags() return allowed end
function IsAnyStandardHeldBagOpen() return nativeOpen end
function IsAnyBagOpen() return nativeOpen end
function GetBackpackFrame() return nativeOpen and {} or nil end
function OpenBag() nativeOpen = true end
function CloseBackpack() nativeOpen = false end
function CloseAllBags() nativeOpen = false end
function ToggleBag() nativeOpen = not nativeOpen end
function CloseSpecialWindows() end
Constants = {InventoryConstants = {NumBagSlots = 4}}
Enum = {BagIndex = {Backpack = 0, Keyring = -1}}
NUM_TOTAL_BAG_FRAMES = 4
InputUtil = {IsGamepadUIEnabled = function() return true end}
ContainerFrameSettingsManager = {IsUsingCombinedBags = function() return true end}
ContainerFrameCombinedBags = {Hide = function() nativeOpen = false end}
EventRegistry = {TriggerEvent = function() end}
--@NATIVE
function hooksecurefunc(target, key, callback)
    if type(target) == 'string' then target, key, callback = _G, target, key end
    local prior = assert(target[key])
    target[key] = function(...)
        local values = {prior(...)}; callback(...); return table.unpack(values)
    end
end
hooksecurefunc('ToggleAllBags', function() BB:ToggleAllBags() end)
local function flush()
    local pending = timers; timers = {}
    for _, fn in ipairs(pending) do fn() end
end
C_Timer = {After = function(_,fn) timers[#timers + 1] = fn end}
function CreateFrame()
    local frame = {RegisterEvent = function() end, SetScript = function(self,_,fn) self.event = fn end}
    frames[#frames + 1] = frame; return frame
end
WOW_PROJECT_CAMELOT = 18; WOW_PROJECT_ID = 18
function GetTime() return 10 end
function GetCVar(name) return name == 'uiScale' and '0.75' or '0.8' end
function GetCameraZoom() return 14 end
UIParent = {GetEffectiveScale = function() return 0.75 end}
SlashCmdList = {}
local ace = {GetAddon = function(_,name) if name == 'BetterBags' then return BB end end}
LibStub = function() return ace end
Plater = {db = {profile = {ui_parent_scale_tune = 1, use_ui_parent = true}, GetCurrentProfile = function() return 'Default' end}}
local refreshes = 0
function Plater:RefreshConfig() refreshes = refreshes + 1 end
local A = {}
--@PRODUCT
ToggleBackpack()
assert(nativeOpen and not bag.shown, 'old native route must reproduce invisible BetterBags')
CloseAllBags()
A:ApplySettings()
assert(Plater.db.profile.ui_parent_scale_tune > 1.42 and refreshes == 1, 'scale migration missing')
Plater.db.profile.ui_parent_scale_tune = 1.7; A:ApplySettings()
assert(Plater.db.profile.ui_parent_scale_tune == 1.7 and refreshes == 1, 'manual scale reset')
ForeverConfigExtendedDB = nil; A:ApplySettings()
assert(Plater.db.profile.ui_parent_scale_tune == 1.7, 'preexisting manual scale lost')
A:InstallBagBridge()
local state = assert(A.bagState)
ToggleBackpack(); flush()
assert(bag.shown and bagToggles == 1 and state.actions == 1, 'direct backpack did not open')
ToggleAllBags(); flush()
assert(not bag.shown and bagToggles == 2 and state.actions == 1, 'native owner doubled close')
ToggleAllBags(); flush()
assert(bag.shown and bagToggles == 3 and state.actions == 1, 'native owner doubled open')
OpenBackpack(); flush()
assert(bag.shown and bagToggles == 3, 'idempotent open toggled')
CloseAllBags(); flush()
assert(not bag.shown and bagToggles == 4, 'direct close failed')
ToggleBackpack(); ToggleBackpack(); flush()
assert(not bag.shown and bagToggles == 4, 'same-frame toggle parity lost')
ToggleBackpack(); combat = true; flush()
assert(not bag.shown and bagToggles == 4, 'queued combat action leaked')
combat = false; CloseAllBags(); flush()
allowed = false; ToggleBackpack(); flush()
assert(not bag.shown, 'native permission ignored')
allowed = true
ToggleBackpack(); BB.Bags.Backpack = nil; flush()
assert(not bag.shown, 'stale bag used')
BB.Bags.Backpack = bag; CloseAllBags(); flush()
local before = bagToggles
A:InstallBagBridge(); A:InstallBagBridge()
ToggleBackpack(); flush()
assert(bag.shown and bagToggles == before + 1, 'duplicate bridge')
CloseAllBags(); flush()
ToggleAllBags(); BB:ToggleAllBags(); flush()
assert(not bag.shown, 'later BetterBags action overwritten')
CloseAllBags(); OpenBackpack(); flush()
assert(bag.shown,'latest same-frame open request lost')
OpenBackpack(); CloseAllBags(); flush()
assert(not bag.shown,'latest same-frame close request lost')
before=bagToggles
ToggleBackpack()
local replacement={shown=false,IsShown=bag.IsShown,Show=bag.Show,Hide=bag.Hide}
BB.Bags.Backpack=replacement;flush()
assert(not replacement.shown and bagToggles==before,'stale request reached replacement bag')
BB.Bags.Backpack=bag
CloseAllBags(); flush()
before=bagToggles
for _=1,100 do OpenBackpack() end
assert(#timers==1,'native open burst was not coalesced')
flush();assert(bag.shown and bagToggles==before+1,'burst opened more than once')
local status = A:Snapshot()
assert(status.betterBagsBackpack and status.betterBagsForever and status.betterBagsBridge)
before = bagToggles; A:Snapshot(); A:Snapshot(); assert(bagToggles == before)
local bootstrap = frames[#frames]
bootstrap.event(bootstrap, 'PLAYER_LOGIN'); bootstrap.event(bootstrap, 'PLAYER_LOGOUT')
local persisted = ForeverConfigExtendedDB.status
assert(ForeverConfigExtendedDB.logoutStatus.phase=='logout')
flush(); assert(ForeverConfigExtendedDB.status == persisted, 'stale login callback after logout')
assert(state.pending == nil)
A.active = false; ForeverConfigExtendedDB = nil
A:ApplySettings(); A:Snapshot(); assert(ForeverConfigExtendedDB == nil)
