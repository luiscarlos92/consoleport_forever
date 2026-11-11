local A, events, callbacks, messages = {}, {}, {}, {}
WOW_PROJECT_CAMELOT, WOW_PROJECT_ID = 18, 18
SlashCmdList = {}
C_Timer = {After = function(_, callback) callbacks[#callbacks + 1] = callback end}
function CreateFrame()
    return {
        RegisterEvent = function(_, event) events[event] = true end,
        SetScript = function(_, _, callback) events.dispatch = callback end,
    }
end
local function fire(event, name)
    assert(events[event], 'diagnostic event registration missing')
    events.dispatch(nil, event, name)
end
local function flush()
    local pending = callbacks
    callbacks = {}
    for _, callback in ipairs(pending) do callback() end
end
local function platerProfile(scale)
    return setmetatable({}, {
        __index = {ui_parent_scale_tune = scale, use_ui_parent = true},
        __newindex = function() error('configuration wrote a Plater profile field') end,
    })
end
Plater = {db = {profile = platerProfile(1), GetCurrentProfile = function() return 'Default' end},
    RefreshConfig = function() error('configuration refreshed Plater') end}
local camera = {enteredSituationAtLogin = true, currentSituationID = '004',
    db = {GetCurrentProfile = function() return 'Forever' end,
        profile = {situations = {{enabled = true}, {enabled = false}}}},
    IsEnabled = function() return true end}
local betterBags = {IsEnabled = function() return true end,
    ToggleAllBags = function() error('configuration dispatched a bag action') end,
    _buttons = {}, Bags = {Backpack = {IsShown = function() return true end}}}
local addons = {DynamicCam = camera, BetterBags = betterBags}
function LibStub() return {GetAddon = function(_, name) return addons[name] end} end
function hooksecurefunc() error('configuration registered a bag hook') end
function SetOverrideBinding() error('configuration attempted a binding write') end
function OpenBackpack() error('configuration dispatched a bag action') end
function GetTime() return 1 end
function GetCVar(name) if name == 'uiScale' then return '0.75' end end
function print(message) messages[#messages + 1] = message end

--@PRODUCT

fire('PLAYER_LOGIN')
flush()
local db = ForeverConfigExtendedDB
assert(db.status.platerScale == 1 and next(db.migrations) == nil, 'retired migration replayed')
assert(db.status.dynamicCamEnabled and db.status.dynamicCamSituation == '004', 'camera diagnostics missing')

local receipt = {before = 1, after = 1.428571452899855, outcome = 'applied'}
db.migrations['plater-default-retail-scale-1'] = receipt
Plater.db.profile = platerProfile(1.35)
addons.BetterBags = nil
fire('PLAYER_REGEN_ENABLED')
flush()
assert(db.status.platerScale == 1.35, 'manual Plater scale changed')
addons.BetterBags = betterBags
fire('ADDON_LOADED', 'BetterBags')
fire('ADDON_LOADED', 'Blizzard_GamepadSmartNavigation')
assert(#callbacks == 0, 'retired addon load queued work')
assert(not A.bagState and not A.navigationState and not A.InstallBagBridge and not A.InstallBagNavigation,
    'retired bridge remains callable')
assert(db.migrations['plater-default-retail-scale-1'] == receipt, 'migration history changed')

assert(SLASH_FOREVERCONFIGEXTENDED1 == '/foreverconfig')
SlashCmdList.FOREVERCONFIGEXTENDED()
assert(#messages == 3 and messages[2]:find('1.35') and messages[3]:find('004'), 'status output lost')
fire('ADDON_LOADED', 'Plater')
fire('PLAYER_LOGOUT')
local status = db.status
flush()
assert(db.logoutStatus.phase == 'logout' and db.status == status, 'stale callback ran after logout')
