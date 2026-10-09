-- Replay the saved candidate.19 condition through real bootstrap, bindings,
-- GUID ring projection, native validation/compiler and transaction machinery.
function UnitClass() return RECOVERY_CLASS,RECOVERY_CLASS end
function GetNumShapeshiftForms() return 2 end
function GetShapeshiftFormInfo(slot) return 1,slot==1,true,100+slot end
function PetHasActionBar() return false end
function GetPetActionInfo() end
local record=ConsolePortForeverDB.characters.A
record.appliedRevision=17 record.pendingReload=nil record.declinedRevision=nil
record.classAccessRepair=nil
record.controllerBindings['SHIFT-PADLSHOULDER']=''
record.controllerBindings['CTRL-PADRSHOULDER']=''
record.rings.sets={ [1]={[0]={name='Utility'},{type='item',item='6948'}} }
bootstrapRings.Data=Addon.Core.Copy(record.rings.sets)
banks[2]['SHIFT-PADLSHOULDER']=nil banks[2]['CTRL-PADRSHOULDER']=nil
if RECOVERY_CLASS=='PALADIN' then
 banks[2]['CTRL-PADRSHOULDER']=bootstrapRings:GetBindingForSet('Auras')
 record.controllerBindings['CTRL-PADRSHOULDER']=banks[2]['CTRL-PADRSHOULDER']
end
local before=Addon.Core.Copy(banks)
fire('PLAYER_LOGIN') flush()
local chord=Addon.ClassActions.Chord(_G)
local set=Addon.adapters.rings.api.classSet
local command=bootstrapRings:GetBindingForSet(set)
assert(banks[2][chord]==command,'revision17 lost class opener was not recovered')
assert(record.classAccessRepair==1 and record.appliedRevision==17,'one-time repair marker/revision incorrect')
local nativeSet=bootstrapRings.Data[set]
assert(nativeSet and #nativeSet==2,'lost class ring did not receive all learned forms')
local compiled=bootstrapRings.compiled[set]
assert(compiled and #compiled.actions==2 and compiled.actions[1].kind=='spell' and compiled.actions[2].kind=='spell','native secure compiler lost class actions')
assert(nativeSet[1].spell==101 and nativeSet[2].spell==102,'native learned forms not preserved')
if RECOVERY_CLASS=='PALADIN' then
 assert(chord=='SHIFT-PADLSHOULDER','Paladin aura ring did not use L1+L2')
 assert(not banks[2]['CTRL-PADRSHOULDER'] or banks[2]['CTRL-PADRSHOULDER']=='','obsolete R2+R1 aura opener remains')
 assert(nativeSet[0].name=='Auras (Forever)','restored Paladin ring has no recognizable name')
end
assert(nativeSet[0].cpfForeverClassOwner==Addon.guid and nativeSet[0].cpfForeverClass==RECOVERY_CLASS,'restored class ring lacks GUID/class ownership')
assert(bootstrapRings.Data[1][1].item=='6948','repair changed utility ring')
local journal=Addon.db.transactions[record.lastInstallTransaction]
assert(journal.context.classAccessRepair and journal.context.foreverClassMigration and journal.status=='committed' and journal.bindingDetails.saved,'class recovery lacks transaction/native save')
for key,value in pairs(before[2]) do if key~=chord and key~=Addon.ClassActions.LEGACY and not (RECOVERY_CLASS=='PALADIN' and key=='CTRL-PADRSHOULDER') then assert(banks[2][key]==value,'recovery changed unrelated chord '..key) end end
local count,writesBefore=Addon.db.nextTransactionID,writes
fire('PLAYER_ENTERING_WORLD') flush()
assert(Addon.db.nextTransactionID==count and writes==writesBefore,'class recovery is not idempotent')
assert(shown==nil,'accepted repair triggered a full installer prompt')
-- Render the actual native stance visibility/update after access restoration.
local originalCreate=CreateFrame
local function visual(parent)
 local f={parent=parent,shown=true}
 function f:GetParent() return self.parent end
 function f:SetParent(value) assert(not combat) self.parent=value end
 function f:Hide() self.shown=false end
 function f:SetShown(value) self.shown=value end
 function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
 return f
end
UIParent=visual()
StanceBarMixin={}
--@NATIVE_STANCE_VISIBILITY
--@NATIVE_STANCE_UPDATE
StanceBar=visual(UIParent) StanceBar.numForms=2
StanceBar.ShouldShow=StanceBarMixin.ShouldShow StanceBar.Update=StanceBarMixin.Update
function StanceBar:UpdateBackgroundArt() end
function StanceBar:UpdateState() self.nativeUpdates=(self.nativeUpdates or 0)+1 end
C_ActionBar={IsPossessBarVisible=function() return false end}
function ActionBarBusy() return false end
LE_ACTIONBAR_STATE_OVERRIDE=2
function ActionBarController_GetCurrentActionBarState() return 1 end
CreateFrame=function(_,_,parent) return visual(parent) end
assert(Addon.ClassActions.UpdateNativeBar(Addon,_G,false),'recovered ring still failed aura-row readiness')
for cycle=1,8 do
 combat=cycle%2==0 StanceBar:Update()
 assert(not StanceBar:IsVisible(),'native aura refresh leaked after class recovery')
end
combat=false
assert(not Addon.ClassActions.UpdateNativeBar(Addon,_G,true) and StanceBar:IsVisible(),'Edit Mode lost aura access')
assert(Addon.ClassActions.UpdateNativeBar(Addon,_G,false) and not StanceBar:IsVisible())
CreateFrame=originalCreate
-- Switch through the real per-GUID adapter into the Demon Hunter, including
-- the obsolete empty Auras placeholder that appeared in the saved evidence.
local dh=Addon.Store.GetCharacter(Addon.db,'B')
dh.ringAccepted=true
dh.rings.sets={ [1]={[0]={name='DH utility'},{type='item',item='6948'}},
 Auras={[0]={}},[set]=Addon.Core.Copy(nativeSet) }
guid='B' Addon.guid='B'
function UnitClass() return 'Demon Hunter','DEMONHUNTER' end
function GetNumShapeshiftForms() return 0 end
local dhAdapters=Addon.RuntimeSetup.Adapters(_G,Addon.db)
local dhAdapter=dhAdapters.rings
local projected=assert(dhAdapter:Proposal())
assert(projected.sets[set]==nil and projected.sets.Auras==nil,'Paladin aura ring leaked into Demon Hunter proposal')
assert(dhAdapter:write({'state'},projected),'DH projection failed')
assert(bootstrapRings.Data[set]==nil and bootstrapRings.compiled[set]==nil,'Paladin aura ring remained visible/compiled for DH')
assert(record.rings.sets[set] and #record.rings.sets[set]==2,'DH projection erased Paladin archive')
dh.bindingAccepted=true Addon.record=dh Addon.adapters=dhAdapters
Addon:HydrateController()
assert(GetBindingAction('SHIFT-PADLSHOULDER')~=command and GetBindingAction('CTRL-PADRSHOULDER')~=command,'Paladin class binding leaked into DH')
assert(not Addon.ClassActions.Migrate(Addon,_G,function() return true end) and dh.classAccessRepair==nil,'DH acquired a Paladin class repair')
guid='A' Addon.guid='A'
function UnitClass() return RECOVERY_CLASS,RECOVERY_CLASS end
function GetNumShapeshiftForms() return 2 end
local returnAdapters=Addon.RuntimeSetup.Adapters(_G,Addon.db)
local returned=returnAdapters.rings
local restored=assert(returned:Proposal())
assert(restored.sets[set] and #restored.sets[set]==2 and returned:write({'state'},restored),'returning Paladin lost class ring')
Addon.record=record Addon.adapters=returnAdapters Addon:HydrateController()
assert(GetBindingAction(chord)==command,'returning Paladin lost its class opener')
TEST_SUCCESS=true
