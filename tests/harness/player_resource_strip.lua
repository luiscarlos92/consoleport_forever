-- The screenshot's five-glyph strip is the native player-frame Holy Power bar,
-- not StanceBar. Execute its actual Setup/OnEvent/UpdatePower lifecycle.
ClassPowerBar={}
ClassResourceBarMixin={}
PaladinPowerBar={VisualState={Inactive=1,Active=2,SpellReady=3}}
HOLY_POWER_SPELL_READY=3
--@NATIVE_CLASS_POWER
--@NATIVE_RESOURCE_BAR
--@NATIVE_PALADIN_POWER
Enum={PowerType={HolyPower=9}}
local power,class=0,'PALADIN'
function UnitClass() return class,class end
function UnitPower() return power end
function UnitPowerMax() return 5 end
function UnitInVehicle() return false end
function PlayerVehicleHasComboPoints() return false end
C_SpecializationInfo={GetSpecialization=function() return 1 end}
local function resourceFrame(parent,name)
    local f=frame(parent)
    f.name=name
    f.alpha=.73 f.level=10 f.unit='player'
    function f:GetName() return self.name end
    function f:GetAlpha() return self.alpha end
    function f:SetAlpha(value) self.alpha=value end
    function f:GetEffectiveAlpha() return self:GetAlpha()*(self:GetParent() and self:GetParent().GetEffectiveAlpha and self:GetParent():GetEffectiveAlpha() or 1) end
    function f:HookScript(key,callback) self.hooks=self.hooks or {} self.hooks[key]=callback end
    function f:Show() self.shown=true if self.hooks and self.hooks.OnShow then self.hooks.OnShow(self) end end
    function f:SetShown(value) if value then self:Show() else self:Hide() end end
    function f:GetFrameLevel() return self.level end
    function f:SetFrameLevel(level) self.level=level end
    function f:GetPoint() return 'TOP',self.parent,'BOTTOM',5,-4 end
    function f:RegisterUnitEvent(event,unit) self.events[event]=unit end
    function f:UnregisterEvent(event) self.events[event]=nil end
    f.class='PALADIN' f.powerToken='HOLY_POWER' f.powerType=Enum.PowerType.HolyPower
    f.powerTokens={HOLY_POWER=true} f.usePooledResourceButtons=false f.canBeHiddenByPersonalResourceDisplay=true
    f.resourceBarMixin=ClassPowerBar
    for key,fn in pairs(ClassPowerBar) do f[key]=fn end
    for key,fn in pairs(ClassResourceBarMixin) do f[key]=fn end
    f.UpdatePower=PaladinPowerBar.UpdatePower
    for i=1,5 do
        local rune={parent=f}
        function rune:SetVisualState(state) self.visualState=state end
        function rune:Painted() return self.parent:IsVisible() and self.parent:GetEffectiveAlpha()>0 end
        f['rune'..i]=rune
    end
    function f:UpdateVisualState(state,value) self.visualState=state self.lastPower=value self.powerUpdates=(self.powerUpdates or 0)+1 end
    return f
end
UIParent.GetEffectiveAlpha=function() return 1 end
PlayerFrame=resourceFrame(UIParent,'PlayerFrame')
local container=resourceFrame(PlayerFrame,'PlayerBottomManagedFrameContainer')
PaladinPowerBarFrame=resourceFrame(container,'PaladinPowerBarFrame')
local bar=PaladinPowerBarFrame
local nameplate=resourceFrame(UIParent,'ClassNameplateBarPaladinFrame')
local personal=resourceFrame(UIParent,'PersonalResourcePaladinClone')
bar:Setup()
assert(bar:IsVisible() and bar.rune1:Painted() and PlayerFrame.classPowerBar==bar,'native screenshot strip not reproduced')
local nativeParent,nativePoints,nativeEvent,nativePower=bar:GetParent(),bar.points,bar.OnEvent,bar.UpdatePower
installed=true Addon.db.shared.runtimePolicy.blizzardVisibility=true
V:Update()
assert(not bar.rune1:Painted(),'native five-rune strip still rendered under player frame')
local count=0
for cycle=1,6 do
    combat=cycle%2==0
    for value=0,5 do
        power=value
        bar:OnEvent('PLAYER_ENTERING_WORLD')
        bar:OnEvent('UNIT_POWER_FREQUENT','player','HOLY_POWER')
        bar:OnEvent('UNIT_MAXPOWER','player')
        bar:OnEvent('UNIT_DISPLAYPOWER','player')
        bar:OnEvent('PLAYER_TALENT_UPDATE')
        bar:OnHideClassInfoOnPlayerFrameChanged(true)
        bar:OnHideClassInfoOnPlayerFrameChanged(false)
        bar:Hide() bar:Show()
        local lastAlpha=.2+.1*value
        bar:SetAlpha(lastAlpha)
        for i=1,5 do assert(not bar['rune'..i]:Painted(),'native resource redraw leaked visible glyph') end
        assert(bar.lastPower==power and bar.rune1.visualState==(power==0 and 1 or power>=3 and 3 or 2),'hiding broke native resource state')
        assert(bar.OnEvent==nativeEvent and bar.UpdatePower==nativePower and bar:GetParent()==nativeParent and bar.points==nativePoints,'resource policy replaced native gameplay or geometry')
        assert(bar.events.UNIT_POWER_FREQUENT=='player' and bar.events.UNIT_MAXPOWER=='player','hiding disabled native resource events')
        assert(nameplate:GetAlpha()==.73 and personal:GetAlpha()==.73 and PlayerFrame:GetAlpha()==.73,'policy hid unrelated resource/player frames')
        count=count+1
    end
end
assert(count==36)
combat=false
editing=true EventRegistry:TriggerEvent('EditMode.Enter')
assert(bar.rune1:Painted() and bar:GetAlpha()==.7,'Edit Mode did not restore latest native opacity')
editing=false EventRegistry:TriggerEvent('EditMode.Exit')
for _,callback in ipairs(queue) do callback() end queue={}
assert(not bar.rune1:Painted(),'Edit Mode exit leaked the strip')
installed=false V:Update()
assert(bar.rune1:Painted() and bar:GetAlpha()==.7,'disable did not restore original/latest native opacity')
bar:SetAlpha(.4)
assert(bar:GetAlpha()==.4,'inactive hooks still suppress native resource art')
installed=true V:Update()
assert(not bar.rune1:Painted())
Addon.db.shared.runtimePolicy.blizzardVisibility=false V:Update()
assert(bar:GetAlpha()==.4,'disabled visibility policy did not restore opacity')
Addon.db.shared.runtimePolicy.blizzardVisibility=true V:Update()
local previous=bar
PaladinPowerBarFrame=resourceFrame(container,'PaladinPowerBarFrame')
bar=PaladinPowerBarFrame bar:Setup() V:Update()
assert(previous:GetAlpha()==.4 and not bar.rune1:Painted(),'late/replaced native strip retained stale ownership')
previous:SetAlpha(.6) assert(previous:GetAlpha()==.6,'stale frame hook still active')
class='WARRIOR' V:Update()
assert(bar:GetAlpha()==.73,'different class retained Paladin visual override')
class='PALADIN' V:Update()
local realPower=bar.UpdatePower
bar.UpdatePower=function() end V:Update()
assert(bar:GetAlpha()==.73,'foreign resource method retained owned override')
bar.UpdatePower=realPower V:Update()
assert(not bar.rune1:Painted())
TEST_SUCCESS=true
