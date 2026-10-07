local combat,open,class=false,false,'DRUID'
local learned={101,102}
local bindings={['CTRL-PADFORWARD']='CLICK NativeRing:Auras',['SHIFT-PADFORWARD']='CLICK NativeRing:LeftButton'}
function InCombatLockdown() return combat end
function UnitClass() return class,class end
function UnitGUID(unit) return unit=='player' and 'A' or nil end
function GetNumShapeshiftForms() return #learned end
function GetShapeshiftFormInfo(slot) return 'icon',false,true,learned[slot] end
function PetHasActionBar() return false end
function GetPetActionInfo() end
function GetBindingAction(key) return bindings[key] or '' end
local queue,registered={},{}
C_Timer={After=function(_,f) queue[#queue+1]=f end}
local function frame(parent)
    local f={parent=parent,shown=true,attrs={},refs={},events={},hooks={}}
    function f:SetSize() end function f:SetPoint() end function f:EnableMouse() end
    function f:RegisterForClicks() end function f:SetText() end
    function f:SetAttribute(k,v) assert(not combat) self.attrs[k]=v end
    function f:GetAttribute(k) return self.attrs[k] end
    function f:SetFrameRef(k,v) self.refs[k]=v end function f:GetFrameRef(k) return self.refs[k] end
    function f:WrapScript(target,key,body) target.hooks[key]=function() assert(load('local self,control=...; '..body))(target,self) end end
    function f:HookScript(k,v) self.hooks[k]=v end
    function f:GetParent() return self.parent end
    function f:SetParent(v) assert(not combat) self.parent=v end
    function f:Hide() self.shown=false if self.hooks.OnHide then self.hooks.OnHide() end end
    function f:Show() self.shown=true end function f:IsShown() return self.shown end
    function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function f:SetShown(v) if v then self:Show() else self:Hide() end end
    function f:RegisterEvent(k) self.events[k]=true end function f:SetScript() end
    return f
end
UIParent=frame()
function CreateFrame(_,name,parent) assert(not combat) local f=frame(parent) if name then _G[name]=f end return f end
function hooksecurefunc(target,key,callback) local old=target[key] target[key]=function(self,...) old(self,...) callback(self,...) end end
EditModeActionBarMixin={UpdateVisibility=function() end,SetShownOverride=function() end}
for _,name in ipairs({'MultiBarLeft','MultiBarRight','MultiBar5','MultiBar6','MultiBar7'}) do
    _G[name]=frame(UIParent) _G[name].UpdateVisibility=EditModeActionBarMixin.UpdateVisibility _G[name].SetShown=EditModeActionBarMixin.SetShownOverride
end
StanceBarMixin={}
--@NATIVE_STANCE_VISIBILITY
StanceBar=frame(UIParent) StanceBar.ShouldShow=StanceBarMixin.ShouldShow StanceBar.numForms=2
VehicleSeatIndicatorMixin={}
--@NATIVE_SEAT_VISIBILITY
VehicleSeatIndicator=frame(UIParent)
VehicleSeatIndicator.UpdateShownState=VehicleSeatIndicatorMixin.UpdateShownState
VehicleSeatIndicator:Hide()
ConsolePort={AddInterfaceCursorFrame=function(_,f) registered[f]=true end}
Addon.guid='A' Addon.record={ringAccepted=true}
Addon.db={shared={runtimePolicy={blizzardVisibility=true,hiddenAccessEnabled=true}}}
function Addon:IsCharacterInstalled() return true end
Addon.Diagnostics={SetFeature=function() end}
local rings={Data={[1]={{type='item',item='6948'},[0]={name='Utility'}},Auras={{type='spell',spell=101},[0]={name='My class'}}},Shared={},hooks={}}
function rings:GetName() return 'NativeRing' end
function rings:GetBindingForSet(id) return 'CLICK NativeRing:'..(id==1 and 'LeftButton' or id) end
function rings:IsShown() return open end
function rings:HookScript(k,v) self.hooks[k]=v end
local refreshes=0
function rings:RefreshAll() assert(not combat) refreshes=refreshes+1 end
local descriptionDB={Bindings={Dynamic={}},Stack={GetVisibleCursorFrames=function() end},Cursor={SetCurrentNode=function() end}}
local nativeEnv={Attributes={}}
descriptionDB.ActionMap={}
function descriptionDB.Bindings:GetDescriptionForBinding(binding)
    for _,entry in ipairs(self.Dynamic) do if entry.binding==binding then return entry.desc,nil,entry.name,entry.texture end end
end
CPAPI={GetEnv=function() return nativeEnv,descriptionDB end,GetSpellInfo=function(id) return {spellID=id} end,
    Static=function(value) return function() return value end end}
function CreateFromMixins(...) local result={} for i=1,select('#',...) do for k,v in pairs(select(i,...)) do result[k]=v end end return result end
--@NATIVE_RING_MAP
Addon.adapters={rings={rings=rings,api={defaultSet=1,classSet='Auras'},Probe=function() return true end},consoleport={db=descriptionDB}}
Addon.UIWindows={CanUse=function(db) return db==descriptionDB end}
--@HIDDEN_ACCESS
--@VISIBILITY
local A,V=Addon.HiddenAccess,Addon.BlizzardVisibility
V:Update()
assert(A.stanceReady and A.vehicleReady and #rings.Data.Auras==2 and rings.Data.Auras[1].spell==101)
assert(rings.Data.Auras[0].name=='My class' and rings.Data[1][1].item=='6948')
assert(StanceBar:GetParent()==V.hidden and not StanceBar:IsVisible())
assert(VehicleSeatIndicator:GetParent()==A.panel and not A.panel:IsShown() and registered[A.panel])
local kind,spell=nativeEnv:GetKindAndAction(rings.Data.Auras[2])
assert(kind=='spell' and spell==102,'native ring did not compile the discovered form')
local custom,display,attrs=nativeEnv:GetKindAndAction(rings.Data[1][2])
assert(custom=='custom' and attrs.type=='macro' and attrs.macro==false
    and attrs.macrotext=='/click ConsolePortForeverVehicleSeatsToggle LeftButton'
    and display.text=='Vehicle seats','native ring did not compile the hardware seat reveal')
local snapshot=Addon.Core.Copy(rings.Data) local count=refreshes
V:Update() assert(Addon.Core.Equal(snapshot,rings.Data) and refreshes==count,'repeat refresh changed rings')
for _,name in ipairs({'WARRIOR','PRIEST','ROGUE','DRUID','PALADIN'}) do class=name V:Update() assert(A.stanceReady) end
class='MAGE' V:Update() assert(not A.stanceReady and StanceBar:GetParent()==UIParent)
class='DRUID' learned={101,103} V:Update() assert(rings.Data.Auras[2].spell==103 and #rings.Data.Auras==2)
VehicleSeatIndicator.currSkin=1 VehicleSeatIndicator:UpdateShownState()
assert(VehicleSeatIndicator:IsShown() and not VehicleSeatIndicator:IsVisible())
local function click(button,down)
    assert(load('local self,button,down=...; '..button:GetAttribute('_onclick')))(button,'LeftButton',down)
end
combat=true local before=Addon.Core.Copy(rings.Data)
V:Update() assert(Addon.Core.Equal(before,rings.Data),'combat changed ring configuration')
click(A.toggle,true) assert(not A.panel:IsShown(),'toggle fired on keydown')
click(A.toggle,false) assert(A.panel:IsShown() and VehicleSeatIndicator:IsVisible(),'hardware release failed to reveal native seats')
click(A.close,false) assert(not A.panel:IsShown())
click(A.toggle,false) VehicleSeatIndicator.currSkin=nil VehicleSeatIndicator:UpdateShownState()
assert(not A.panel:IsShown(),'vehicle exit retained empty cursor window')
click(A.toggle,false) assert(not A.panel:IsShown(),'empty vehicle panel opened')
combat=false V:Update()
bindings['CTRL-PADFORWARD']='CUSTOM' V:Update() assert(StanceBar:GetParent()==UIParent and not A.stanceReady)
bindings['CTRL-PADFORWARD']='CLICK NativeRing:Auras'
bindings['SHIFT-PADFORWARD']='CUSTOM' V:Update() assert(VehicleSeatIndicator:GetParent()==UIParent and not A.vehicleReady)
bindings['SHIFT-PADFORWARD']='CLICK NativeRing:LeftButton' V:Update()
V.editing=true V:Update()
assert(StanceBar:GetParent()==UIParent and VehicleSeatIndicator:GetParent()==UIParent,'Edit Mode retained hidden parents')
V.editing=false V:Update()
Addon.db.shared.runtimePolicy.hiddenAccessEnabled=false V:Update()
assert(StanceBar:GetParent()==UIParent and VehicleSeatIndicator:GetParent()==UIParent)
assert(#rings.Data.Auras==1 and #rings.Data[1]==1 and rings.Data.Auras[1].spell==101,'disable damaged manual entries')
TEST_SUCCESS=true
