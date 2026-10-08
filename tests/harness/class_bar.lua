local combat=false
function InCombatLockdown() return combat end
local Frame={}
function Frame:GetParent() return self.parent end
function Frame:SetParent(parent) assert(not combat,'combat parent change') self.parent=parent end
function Frame:Hide() self.shown=false end
function Frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function CreateFrame(_,_,parent) return setmetatable({parent=parent,shown=true},{__index=Frame}) end
UIParent=CreateFrame('Frame')
StanceBarMixin={}
--@NATIVE_STANCE_VISIBILITY
C_ActionBar={IsPossessBarVisible=function() return false end}
LE_ACTIONBAR_STATE_OVERRIDE=2
function ActionBarController_GetCurrentActionBarState() return 1 end
local bar=CreateFrame('Frame',nil,UIParent) bar.ShouldShow=StanceBarMixin.ShouldShow bar.numForms=3
local ring={{type='spell',spell=1},{type='spell',spell=2},{type='spell',spell=3}}
local adapter={api={classSet='Auras',classChord=Addon.ClassActions.LEFT_CHORD},rings={Data={Auras=ring},GetBindingForSet=function() return 'CLICK Auras' end},Probe=function() return true end}
local addon={record={ringAccepted=true},adapters={rings=adapter},IsCharacterInstalled=function() return true end}
local api={InCombatLockdown=InCombatLockdown,StanceBar=bar,StanceBarMixin=StanceBarMixin,UIParent=UIParent,CreateFrame=CreateFrame,
 UnitClass=function() return 'Paladin','PALADIN' end,GetBindingAction=function() return 'CLICK Auras' end,
 GetNumShapeshiftForms=function() return 3 end,GetShapeshiftFormInfo=function(slot) return 1,false,true,slot end}
local Class=Addon.ClassActions
assert(bar:ShouldShow() and bar:IsVisible())
assert(Class.UpdateNativeBar(addon,api,false) and not bar:IsVisible(),'duplicate native auras row visible')
local hidden=bar:GetParent()
assert(Class.UpdateNativeBar(addon,api,false) and bar:GetParent()==hidden,'repeat update changed parent')
combat=true assert(not Class.UpdateNativeBar(addon,api,true) and bar:GetParent()==hidden) combat=false
assert(not Class.UpdateNativeBar(addon,api,true) and bar:GetParent()==UIParent and bar:IsVisible(),'Edit Mode lost native bar')
assert(Class.UpdateNativeBar(addon,api,false))
table.remove(ring)
assert(not Class.UpdateNativeBar(addon,api,false) and bar:IsVisible(),'incomplete ring hides native access')
ring[3]={type='spell',spell=3}
api.GetBindingAction=function() return 'OTHER' end
assert(not Class.UpdateNativeBar(addon,api,false) and bar:IsVisible(),'unbound class menu hid native access')
api.GetBindingAction=function() return 'CLICK Auras' end
assert(Class.UpdateNativeBar(addon,api,false))
local foreign=CreateFrame('Frame',nil,UIParent) bar:SetParent(foreign)
assert(not Class.UpdateNativeBar(addon,api,false) and bar:GetParent()==foreign,'foreign parent overwritten')
assert(not Class.UpdateNativeBar(addon,api,true) and bar:GetParent()==foreign,'Edit Mode overwrote foreign parent')
TEST_SUCCESS=true
