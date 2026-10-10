local slots,cursor={},nil
local combat,temporary,bonus,page,class,spec=false,false,0,1,'PALADIN',70
local writes=0
local config=1
local api={InCombatLockdown=function() return combat end,
 HasVehicleActionBar=function() return temporary=='vehicle' end,
 HasOverrideActionBar=function() return temporary=='override' end,
 HasTempShapeshiftActionBar=function() return temporary=='temporary' end,
 GetBonusBarOffset=function() return bonus end,GetActionBarPage=function() return page end,
 GetSpecialization=function() return 1 end,GetSpecializationInfo=function() return spec end,
 UnitClass=function() return class,class end,IsPlayerSpell=function() return true end,
 GetActionInfo=function(slot) local row=slots[slot] or {} return row[1],row[2],row[3] end,
 GetCursorInfo=function() if cursor then return cursor[1],cursor[2] end end,
 ClearCursor=function() writes=writes+1 cursor=nil end,
 GetTime=function() return 10 end,
 C_ClassTalents={GetActiveConfigID=function() return 999 end,GetLastSelectedSavedConfigID=function() return config end}}
api.C_Spell={PickupSpell=function(spell) writes=writes+1 cursor={'spell',spell} end}
api.PlaceAction=function(slot) writes=writes+1 slots[slot]=cursor cursor=nil return 'native-result' end
local addon={guid='Player-5-0E664CF8',record={},IsCharacterInstalled=function() return true end,Diagnostics=Addon.Diagnostics}
-- Even a legacy opt-in and known majority loss cannot re-enable automatic writes.
for _,family in ipairs({'normal','skyriding','vehicle','override','temporary','form','high-page'}) do
 combat=false temporary=family bonus=family=='skyriding' and 5 or family=='form' and 1 or 0
 page=family=='high-page' and 12 or 1
 addon.record.actionRecoveryDisabled=false
 local before=Addon.Core.Copy(slots)
 Addon.ActionRecovery:Refresh(addon,api)
 assert(writes==0 and Addon.Core.Equal(before,slots),'automatic action-slot restoration rewrote edited bars: '..family)
 assert(addon.record.actionRecoveryDisabled,'legacy opt-in revived automatic recovery')
end
combat=true cursor={'item',123}
Addon.ActionRecovery:Refresh(addon,api)
assert(writes==0 and cursor[1]=='item','read-only diagnostics consumed player cursor')
combat=false temporary=false bonus=0 page=1 cursor=nil
local snapshot={banks={L2={buttons={}}}}
for slot=1,20 do snapshot.banks.L2.buttons[slot]={kind='action',action=slot,slotKind='spell',spell=100+slot} end
Addon.ActionRecovery:Observe(addon,api,snapshot)
local good=Addon.Core.Copy(addon.record.actionRecovery.specs[70])
assert(good.count==20 and good.config==1,'read-only good snapshot missing')
Addon.ActionRecovery:Observe(addon,api,{banks={L2={buttons={}}}})
assert(Addon.Core.Equal(good,addon.record.actionRecovery.specs[70]),'loss destroyed retained diagnostic snapshot')
local corrupt=Addon.Core.Copy(snapshot)
for _,row in pairs(corrupt.banks.L2.buttons) do row.spell=row.spell+100 end
Addon.ActionRecovery:Observe(addon,api,corrupt)
assert(Addon.Core.Equal(good,addon.record.actionRecovery.specs[70]),'scramble destroyed retained diagnostic snapshot')
config=2 Addon.ActionRecovery:Observe(addon,api,corrupt)
assert(addon.record.actionRecovery.loadouts['70:1'].slots[1]==101,'diagnostic loadouts merged')
config=1 Addon.ActionRecovery:Observe(addon,api,snapshot)
assert(addon.record.actionRecovery.loadouts['70:2'].slots[1]==201,'departing diagnostic loadout discarded')
api.debugstack=function() return 'Interface/AddOns/ConsolePort_Config/Widget/Button/Button.lua:400' end
Addon.ActionRecovery:Record(addon,api,'PlaceAction',1)
Addon.ActionRecovery:Observe(addon,api,{banks={L2={buttons={}}}})
assert(addon.record.actionRecovery.specs[70].count==0,'explicit empty edit not retained for diagnosis')
for i=1,45 do Addon.ActionRecovery:Record(addon,api,'ACTIONBAR_SLOT_CHANGED',1) end
assert(#addon.record.actionRecovery.events==40,'diagnostic history unbounded')
local hooks=0
api.PickupAction=function(slot) writes=writes+1 slots[slot]=nil end
api.C_ClassTalents.LoadConfig=function() return 'native-config-result' end
api.hooksecurefunc=function(target,name,callback)
 if type(target)=='string' then callback=name name=target target=api end
 local original=target[name]
 target[name]=function(...) local result=original(...) callback(...) return result end
 hooks=hooks+1
end
api.debugstack=function() return 'Interface/AddOns/TalentLoadoutManager/modules/Leveling.lua:89' end
Addon.ActionRecovery:InstallObservers(addon,api)
local installed=hooks Addon.ActionRecovery:InstallObservers(addon,api)
assert(installed==3 and hooks==installed,'observer hooks duplicated')
assert(api.C_ClassTalents.LoadConfig(10,true)=='native-config-result','observer changed native return')
api.PickupAction(1)
local last=addon.record.actionRecovery.events[#addon.record.actionRecovery.events]
assert(last.event=='PickupAction' and last.slot==1 and last.writer=='TalentLoadoutManager','passive writer context missing')
local beforeWrites=writes
Addon.ActionRecovery:Refresh(addon,api)
assert(writes==beforeWrites,'observer refresh performed storage writes')
TEST_SUCCESS=true
