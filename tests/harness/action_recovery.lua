local slots,cursor={},nil
local combat,temporary,class,spec=false,false,'PALADIN',70
local calls=0
local api={InCombatLockdown=function() return combat end,HasVehicleActionBar=function() return temporary end,
 HasOverrideActionBar=function() return false end,HasTempShapeshiftActionBar=function() return false end,
 GetBonusBarOffset=function() return 0 end,GetActionBarPage=function() return 1 end,
 GetSpecialization=function() return 1 end,GetSpecializationInfo=function() return spec end,
 UnitClass=function() return class,class end,IsPlayerSpell=function() return true end,
 GetActionInfo=function(slot) local row=slots[slot] or {} return row[1],row[2],row[3] end,
 GetCursorInfo=function() if cursor then return cursor[1],cursor[2] end end,
 ClearCursor=function() cursor=nil end}
api.C_Spell={PickupSpell=function(spell) calls=calls+1 cursor={'spell',spell} end}
api.PlaceAction=function(slot) assert(not combat and not temporary and cursor) slots[slot]=cursor cursor=nil end
local addon={record={},IsCharacterInstalled=function() return true end,Diagnostics=Addon.Diagnostics}
slots[1]={'spell',255937} slots[2]={'spell',184575} slots[53]={'macro',122}
combat=true Addon.ActionRecovery:Refresh(addon,api) assert(calls==0)
combat=false temporary=true Addon.ActionRecovery:Refresh(addon,api) assert(calls==0)
temporary=false cursor={'item',123} Addon.ActionRecovery:Refresh(addon,api) assert(calls==0 and cursor[1]=='item')
cursor=nil class='DEMONHUNTER' Addon.ActionRecovery:Refresh(addon,api) assert(calls==0)
class='PALADIN' spec=66 Addon.ActionRecovery:Refresh(addon,api) assert(calls==0)
spec=70 Addon.ActionRecovery:Refresh(addon,api)
assert(calls==20 and slots[1][2]==383328 and slots[2][2]==53385 and slots[3][2]==184575,'original Paladin layout was not recovered')
assert(slots[53][1]=='macro' and slots[53][2]==122,'player macro overwritten')
assert(addon.record.actionRecovery.lastAttempt.before[1].id==255937,'pre-repair displaced action was not backed up')
assert(addon.record.actionRecovery.lastAttempt.status=='restored')
local snapshot={banks={L2={buttons={}}}}
for slot,row in pairs(slots) do snapshot.banks.L2.buttons[slot]={kind='action',action=slot,slotKind=row[1],spell=row[2]} end
Addon.ActionRecovery:Observe(addon,api,snapshot)
local good=Addon.Core.Copy(addon.record.actionRecovery.specs[70])
assert(good.count==20)
Addon.ActionRecovery:Observe(addon,api,{banks={L2={buttons={}}}})
assert(Addon.Core.Equal(good,addon.record.actionRecovery.specs[70]),'empty transition replaced last good snapshot')
calls=0 slots={} Addon.ActionRecovery:Refresh(addon,api)
assert(calls==20 and addon.record.actionRecovery.lastAttempt.source=='GUID/spec snapshot','future wipe did not restore GUID/spec snapshot')
slots[1]=nil calls=0 Addon.ActionRecovery:Refresh(addon,api) assert(calls==0,'ordinary one-slot player edit was undone')
addon.record.actionRecoveryDisabled=true slots={} Addon.ActionRecovery:Refresh(addon,api) assert(calls==0)
TEST_SUCCESS=true
