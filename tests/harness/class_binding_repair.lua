-- Replay the real bootstrap against the observed accepted-revision-16 gap.
function UnitClass() return 'Paladin','PALADIN' end
local record=ConsolePortForeverDB.characters.A
record.appliedRevision=16 record.pendingReload=nil record.declinedRevision=nil
record.controllerBindings['SHIFT-PADLSHOULDER']=''
record.controllerBindings['CTRL-PADRSHOULDER']=''
banks[2]['SHIFT-PADLSHOULDER']=nil banks[2]['CTRL-PADRSHOULDER']=nil
local before=Addon.Core.Copy(banks)
fire('PLAYER_LOGIN') flush()
local chord=Addon.ClassActions.LEFT_CHORD
assert(Addon.record.appliedRevision==17 and banks[2][chord]=='CLICK NativeUtility:Auras','missing paladin class binding was not repaired in game')
local journal=Addon.db.transactions[Addon.record.lastInstallTransaction]
assert(journal.context.foreverClassMigration and journal.status=='committed' and journal.bindingDetails.saved,'repair omitted transaction or native save')
for key,value in pairs(before[2]) do if key~=chord and key~=Addon.ClassActions.LEGACY then assert(banks[2][key]==value,'class repair changed other input '..key) end end
local count,writesBefore=Addon.db.nextTransactionID,writes
fire('PLAYER_ENTERING_WORLD') flush()
assert(Addon.db.nextTransactionID==count and writes==writesBefore,'repeat refresh reapplied class binding repair')
assert(shown==nil,'already authorized repair asked for another installer review')
TEST_SUCCESS=true
