local combat,editing,installed,callbacks=false,false,false,{}
Addon={db={shared={runtimePolicy={blizzardVisibility=false}}}}
function Addon:IsCharacterInstalled() return installed end
function InCombatLockdown() return combat end
function UnitAffectingCombat() return combat end
local frames,queue={},{}
local function frame(parent)
    local f={parent=parent,shown=true,events={},points={"native geometry"}}
    function f:GetParent() return self.parent end
    function f:SetParent(p) assert(not combat,"parent mutation in combat") self.parent=p end
    function f:Show() self.shown=true end
    function f:Hide() self.shown=false end
    function f:SetShown(v) self.shown=v end
    function f:IsShown() return self.shown end
    function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
    function f:RegisterEvent(e) self.events[e]=true end
    function f:SetScript(k,v) self[k]=v end
    function f:ShouldBreakSnappedFramesOnHide() return false end
    function f:GetShowAllButtons() return self.showAll end
    frames[#frames+1]=f return f
end
UIParent=frame()
function CreateFrame(kind,name,parent,template) assert(kind=="Frame") if template then assert(template=="SecureHandlerBaseTemplate" and not combat) end return frame(parent) end
function hooksecurefunc(target,key,callback)
    local original=target[key]
    target[key]=function(self,...) local result=original(self,...) callback(self,...) return result end
end
C_Timer={After=function(_,callback) queue[#queue+1]=callback end}
EventRegistry={RegisterCallback=function(_,key,callback) callbacks[key]=callback end,
    TriggerEvent=function(_,key) if callbacks[key] then callbacks[key]() end end}
EditModeManagerFrame={IsShown=function() return editing end,IsEditModeActive=function() return editing end,
    UpdateActionBarLayout=function() end}
EditModeActionBarMixin={}
--@NATIVE_BAR_METHODS
local names={"MultiBarLeft","MultiBarRight","MultiBar5","MultiBar6","MultiBar7"}
for _,name in ipairs(names) do
    local f=frame(UIParent) _G[name]=f
    for k,v in pairs(EditModeActionBarMixin) do f[k]=v end
    f:SetupVisibilityFunctionOverrides()
    f.visibility="InCombat" f.isShownExternal=true
    f:RegisterEvent("PLAYER_REGEN_DISABLED") f:RegisterEvent("ACTIONBAR_SHOWGRID")
    f:UpdateVisibility()
end
MicroMenuContainer=frame(UIParent) MicroMenu=frame(MicroMenuContainer) BagsBar=frame(UIParent)
BagsBar:Hide()
ExtraAbilityContainer=frame(UIParent)
ExtraActionBarFrame=frame(ExtraAbilityContainer)
ExtraActionBarFrame:Hide()
ExtraActionButton1=frame(ExtraActionBarFrame)
ExtraActionButton1.action=217
local extraAvailable=false
C_ActionBar={HasExtraActionBar=function() return extraAvailable end,GetOverrideBarSkin=function() return nil end}
local function animation() return {Play=function() end,Stop=function() end} end
ExtraActionBarFrame.intro,ExtraActionBarFrame.outro=animation(),animation()
ExtraActionButton1.icon=frame(ExtraActionButton1)
ExtraActionButton1.style={SetTexture=function() end}
function ExtraActionButton1:UpdateUsable() end
function ExtraActionButton1:GetButtonState() return self.state or 'NORMAL' end
function ExtraActionButton1:SetButtonState(value) self.state=value end
ExtraActionBarFrame.button=ExtraActionButton1
function ExtraAbilityContainer:AddFrame(value) self.extra=value end
function ExtraAbilityContainer:RemoveFrame() self.extra=nil end
local extraUses=0
function TryUseActionButton(button,down)
    assert(button==ExtraActionButton1 and button.action==217)
    if not down then extraUses=extraUses+1 end
end
--@NATIVE_EXTRA_ACTION
local retained=frame(UIParent)
--@RUNTIME_VISIBILITY
local V=Addon.BlizzardVisibility
V:Update()
assert(not V.hidden and MultiBarLeft:GetParent()==UIParent,"unapproved login acquired visibility")
installed=true V:Update()
assert(not V.hidden,"missing reviewed policy acquired visibility")
Addon.db.shared.runtimePolicy.blizzardVisibility=true V:Update()
assert(V.hidden and not V.hidden:IsShown() and MultiBarLeft:GetParent()==V.hidden)
assert(MultiBarLeft.events.PLAYER_REGEN_DISABLED and MultiBarLeft.events.ACTIONBAR_SHOWGRID)
assert(MultiBarLeft.isShownExternal==true and MultiBarLeft:IsShown()==true,"native semantic shown state changed")
assert(not MultiBarLeft:IsVisible() and not MicroMenuContainer:IsVisible() and not MicroMenu:IsVisible() and not BagsBar:IsVisible())
assert(MicroMenu:GetParent()==MicroMenuContainer,"nested native menu parent changed")
assert(retained:IsVisible() and MultiBarLeft.points[1]=="native geometry")
extraAvailable=true ExtraActionBar_Update()
assert(ExtraActionBarFrame:IsVisible() and ExtraActionButton1:IsVisible()
    and ExtraAbilityContainer:GetParent()==UIParent,'side-bar hiding swallowed native extra ability')
ExtraActionButtonKey(1,true) ExtraActionButtonKey(1,false)
assert(extraUses==1,'native extra action did not execute once')
combat=true
for _,name in ipairs(names) do _G[name]:EditModeActionBar_OnEvent("PLAYER_REGEN_DISABLED") _G[name].showAll=true _G[name]:UpdateVisibility() assert(not _G[name]:IsVisible()) end
ExtraActionButtonKey(1,true) ExtraActionButtonKey(1,false)
assert(extraUses==2 and ExtraActionButton1:IsVisible(),'combat/visibility blocked the native extra action')
extraAvailable=false ExtraActionButtonKey(1,true) ExtraActionButtonKey(1,false)
assert(extraUses==2,'unavailable extra action executed')
Addon.db.shared.runtimePolicy.blizzardVisibility=false V:Update()
assert(MultiBarLeft:GetParent()==V.hidden,"combat disable mutated parent")
combat=false V:Update()
assert(MultiBarLeft:GetParent()==UIParent and MultiBarLeft:IsVisible())
assert(not BagsBar:IsShown(),"cleanup forced a natively hidden bag bar shown")
Addon.db.shared.runtimePolicy.blizzardVisibility=true V:Update()
editing=true EventRegistry:TriggerEvent("EditMode.Enter")
assert(MultiBarLeft:GetParent()==UIParent and MicroMenuContainer:GetParent()==UIParent)
MultiBarLeft:SetShown(false)
assert(not MultiBarLeft.isShownExternal and not MultiBarLeft:IsVisible())
editing=false EventRegistry:TriggerEvent("EditMode.Exit")
for _,callback in ipairs(queue) do callback() end queue={}
assert(MultiBarLeft:GetParent()==V.hidden and not MultiBarLeft.isShownExternal)
assert(not BagsBar:IsShown())
local foreign=frame(UIParent)
MultiBar6:SetParent(foreign)
V:Update()
assert(MultiBar6:GetParent()==foreign,"newer owner overwritten")
Addon.db.shared.runtimePolicy.blizzardVisibility=false V:Update()
assert(MultiBar6:GetParent()==foreign and MultiBar7:GetParent()==UIParent)
Addon.db.shared.runtimePolicy.blizzardVisibility=true
local nativeUpdate=MultiBar7.UpdateVisibility MultiBar7.UpdateVisibility=function() end
V:Update()
assert(MultiBar5:GetParent()==UIParent,"changed native bridge retained hidden ownership")
MultiBar7.UpdateVisibility=nativeUpdate V:Update()
assert(MultiBar5:GetParent()==V.hidden and MultiBar6:GetParent()==foreign)
local oldBar=MultiBar5
MultiBar5=frame(UIParent) for k,v in pairs(EditModeActionBarMixin) do MultiBar5[k]=v end
MultiBar5:SetupVisibilityFunctionOverrides()
V:Update()
assert(oldBar:GetParent()==UIParent and MultiBar5:GetParent()==V.hidden,"replaced native frame retained stale ownership")
installed=false V:Update()
assert(MicroMenuContainer:GetParent()==UIParent and MultiBar5:GetParent()==UIParent)
TEST_SUCCESS=true
