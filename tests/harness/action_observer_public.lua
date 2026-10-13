-- Execute the passive observer with opaque/failing API returns. The host models
-- secrecy; these checks do not establish Retail taint provenance.
TEST_SUCCESS=nil
local opaque=setmetatable({}, {__tostring=function() error('opaque formatted') end,
    __lt=function() error('opaque compared') end,__le=function() error('opaque compared') end,
    __add=function() error('opaque arithmetic') end})
local calls=0
local api={issecretvalue=function(value) return rawequal(value,opaque) end,
    GetTime=function() return 10 end,GetSpecialization=function() return opaque end,
    GetSpecializationInfo=function(index) assert(not rawequal(index,opaque),'opaque specialization forwarded') return 70 end,
    GetBonusBarOffset=function() return opaque end,GetActionBarPage=function() return opaque end,
    InCombatLockdown=function() return true end,HasVehicleActionBar=function() return opaque end,
    HasOverrideActionBar=function() return false end,HasTempShapeshiftActionBar=function() return false end,
    GetActionInfo=function(slot) calls=calls+1 return 'spell',opaque end,
    debugstack=function() return 'Interface/AddOns/ConsolePort_Config/Widget/Button.lua:10' end,
    C_ClassTalents={GetActiveConfigID=function() return opaque end}}
local addon={record={},IsCharacterInstalled=function() return true end}
local function noOpaque(value)
    assert(not rawequal(value,opaque),'opaque persisted in action observer')
    if type(value)=='table' then for key,item in pairs(value) do noOpaque(key) noOpaque(item) end end
end
Addon.ActionRecovery:Record(addon,api,'ACTIONBAR_SLOT_CHANGED',opaque)
assert(calls==0,'opaque action slot forwarded')
local row=addon.record.actionRecovery.events[1]
noOpaque(addon.record)
assert(row.config==nil and row.temporary==nil and row.bonusOffset==nil and row.actionPage==nil,
    'opaque observation manufactured public state')
assert(row.combat==true and addon.record.actionRecovery.manualUntil==12,'known public observation lost')
api.GetSpecialization=function() return 1 end
api.C_ClassTalents.GetActiveConfigID=function() return 999 end
api.C_ClassTalents.GetStarterBuildActive=function() return opaque end
Addon.ActionRecovery:Record(addon,api,'PlaceAction',1)
assert(addon.record.actionRecovery.events[2].config==nil,'opaque starter state formatted as a config')
api.C_ClassTalents.GetStarterBuildActive=function() return false end
api.C_ClassTalents.GetLastSelectedSavedConfigID=function() return opaque end
Addon.ActionRecovery:Record(addon,api,'PlaceAction',1)
assert(addon.record.actionRecovery.events[3].config==nil,'opaque saved identity replaced with working config')
api.C_ClassTalents.GetLastSelectedSavedConfigID=function() return 123 end
api.GetTime=function() return opaque end
api.HasOverrideActionBar=function() return true end
Addon.ActionRecovery:Record(addon,api,'PlaceAction',1)
row=addon.record.actionRecovery.events[4]
assert(row.time==nil and row.config==123 and row.temporary==true,'known public loadout/temporary identity lost')
noOpaque(addon.record)
api.GetTime=function() error('query unavailable') end
api.debugstack=function() return opaque end
api.GetActionInfo=function() error('query unavailable') end
Addon.ActionRecovery:Record(addon,api,'PlaceAction',1)
noOpaque(addon.record)
assert(addon.record.actionRecovery.events[5].writer=='engine/unknown','failed observer read invented writer')
for i=1,60 do Addon.ActionRecovery:Record(addon,api,'ACTIONBAR_SLOT_CHANGED',1) end
assert(#addon.record.actionRecovery.events==40,'observer history became unbounded')
-- Observe must not index spec snapshots, compare pages, or archive secret slots.
api.GetCursorInfo=function() return nil end
api.UnitClass=function() return 'Paladin','PALADIN' end
api.GetTime=function() return 10 end
local before=Addon.Core.Copy(addon.record.actionRecovery.specs)
Addon.ActionRecovery:Observe(addon,api,{banks={}})
assert(Addon.Core.Equal(before,addon.record.actionRecovery.specs),'unknown page mutated diagnostic snapshot')
api.HasVehicleActionBar=function() return false end
api.HasOverrideActionBar=function() return false end
api.GetBonusBarOffset=function() return 0 end
api.GetActionBarPage=function() return 1 end
Addon.ActionRecovery:Observe(addon,api,{banks={Base={buttons={bad={kind='action',slotKind='spell',action=opaque,spell=opaque}}}}})
noOpaque(addon.record)
TEST_SUCCESS=true
