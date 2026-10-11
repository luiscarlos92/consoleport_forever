local STAGE = arg[1] or 'UI-Layout-Audit-2026-09-27/staged/'
local unpack = table.unpack or unpack
local function eq(actual, expected, label)
    assert(actual == expected, (label or 'value')..': expected '..tostring(expected)..', got '..tostring(actual))
end
local function check(value, label) assert(value, label) end

local Methods = {}
local function object(parent)
    return setmetatable({parent=parent, points={}, scripts={}, width=45, height=45,
        scale=1, strata='MEDIUM', shown=true, textures={}}, {__index=Methods})
end
function Methods:ClearAllPoints() self.points={} end
function Methods:SetPoint(...) self.points={...} end
function Methods:SetSize(w,h) self.width=w self.height=h end
function Methods:SetWidth(w) self.width=w end
function Methods:SetHeight(h) self.height=h end
function Methods:GetWidth() return self.width end
function Methods:GetHeight() return self.height end
function Methods:GetParent() return self.parent end
function Methods:SetParent(parent) self.parent=parent end
function Methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Methods:SetScale(scale) self.scale=scale end
function Methods:GetFrameStrata() return self.strata end
function Methods:SetFrameStrata(strata) self.strata=strata end
function Methods:SetLook(look) self.look=look end
function Methods:Hide() self.shown=false end
function Methods:Show() self.shown=true end
function Methods:EnableMouse(value) self.mouse=value end
function Methods:RegisterEvent(event) self.events=self.events or {} self.events[event]=true end
function Methods:SetScript(script, callback) self.scripts[script]=callback end
function Methods:HookScript(script, callback)
    local original=self.scripts[script]
    self.scripts[script]=function(...) if original then original(...) end callback(...) end
end
function Methods:CreateTexture(_, layer)
    local texture=object(self) texture.layer=layer
    self.textures[#self.textures+1]=texture return texture
end
function Methods:SetAllPoints(target) self.allPoints=target or self.parent end
function Methods:SetTexture(texture) self.texture=texture end
function Methods:SetTexCoord(...) self.texcoord={...} end

local queue, inCombat = {}, false
C_Timer={After=function(_, callback) queue[#queue+1]=callback end}
local function flush()
    local count=0
    while #queue > 0 do
        local callback=table.remove(queue,1) callback() count=count+1
        assert(count < 300, 'queued callback recursion')
    end
end
InCombatLockdown=function() return inCombat end

function hooksecurefunc(target, method, callback)
    if type(target) == 'string' then target, method, callback = _G, target, method end
    local original=assert(target[method], method)
    target[method]=function(...) local result={original(...)} callback(...) return unpack(result) end
end

Enum={
    EditModeSystem={ActionBar=1,CastBar=2,UnitFrame=3,ChatFrame=4,Minimap=5,
        ObjectiveTracker=6,MicroMenu=7,Bags=8,AuraFrame=9,ExtraAbilities=10,
        EncounterBar=11,TalkingHeadFrame=12,VehicleLeaveButton=13,
        ArchaeologyBar=14,CooldownViewer=15,DamageMeter=16},
    EditModeUnitFrameSystemIndices={Player=0,Target=1,Focus=2},
    EditModeAuraFrameSystemIndices={BuffFrame=0,DebuffFrame=1,ExternalDefensivesFrame=2},
    EditModeCooldownViewerSystemIndices={Essential=0,Utility=1,BuffIcon=2,BuffBar=3},
}

UIParent=object() UIParent.scale=0.76
PlayerFrame=object(UIParent) TargetFrame=object(UIParent)
TargetFrame.UpdateAuras=function(self) self.auraUpdates=(self.auraUpdates or 0)+1 end
TargetFrame.UpdateAuraContainerAnchors=function(self) self.auraAnchorUpdates=(self.auraAnchorUpdates or 0)+1 end
TargetFrame.UpdateSystemSettingBuffsOnTop=function(self) self.buffsOnTop=false end
TargetFrame.ApplySystemAnchor=function(self) self:SetPoint('TOPLEFT',UIParent,'TOPLEFT',0,0) end
TargetFrame.OnEditModeExit=function() end
local nativeTargetBuffSetting = TargetFrame.UpdateSystemSettingBuffsOnTop
local nativeTargetAnchor = TargetFrame.ApplySystemAnchor
ConsolePortGroupBase=object(UIParent) ConsolePortGroupBase.buttons={}
MicroButtonAndBagsBar=object(UIParent) MicroMenuContainer=object(UIParent) BagsBar=object(UIParent)
PlayerCastingBarFrame=object(PlayerFrame)
PlayerCastingBarFrame.width=150 PlayerCastingBarFrame.height=10
PlayerCastingBarFrame.scale=1.25 PlayerCastingBarFrame.look='UNITFRAME'
PlayerCastingBarFrame.SetPointBase=Methods.SetPoint
PlayerCastingBarFrame.ClearAllPointsBase=Methods.ClearAllPoints
PlayerCastingBarFrame.SetScaleBase=Methods.SetScale
PlayerCastingBarFrame.ApplySystemAnchor=function(self) self:SetPoint('TOPRIGHT',PlayerFrame,'BOTTOMRIGHT',0,0) end
PlayerCastingBarFrame.OnEditModeExit=function() end
PlayerFrame_AttachCastBar=function() end
PlayerFrame_DetachCastBar=function() end
GetBottomManagedFrameContainer=function() return {RemoveManagedFrame=function() end} end

local function auraFrame(name, index)
    local frame=object(UIParent) frame.name=name frame.system=Enum.EditModeSystem.AuraFrame frame.systemIndex=index
    frame.AuraContainer={addIconsToRight=true,addIconsToTop=true}
    frame.SetPointBase=Methods.SetPoint frame.ClearAllPointsBase=Methods.ClearAllPoints
    frame.UpdateGridLayout=function(self) self.gridUpdates=(self.gridUpdates or 0)+1 end
    frame.UpdateSize=function(self, height) self.height=height end
    frame.ApplySystemAnchor=function(self) self:SetPoint('TOPRIGHT',UIParent,'TOPRIGHT',-10,-10) end
    frame.OnEditModeExit=function() end
    return frame
end
BuffFrame=auraFrame('BuffFrame',Enum.EditModeAuraFrameSystemIndices.BuffFrame)
DebuffFrame=auraFrame('DebuffFrame',Enum.EditModeAuraFrameSystemIndices.DebuffFrame)

local modernSystems={}
local function modern(system,index)
    local info={system=system,systemIndex=index,settings={{setting=1,value=5}},
        anchorInfo={point='TOPLEFT',relativeTo='UIParent',relativePoint='TOPLEFT',offsetX=13,offsetY=-17}}
    modernSystems[#modernSystems+1]=info return info
end
local protected={}
for _, system in ipairs({Enum.EditModeSystem.ActionBar,Enum.EditModeSystem.CastBar,
    Enum.EditModeSystem.ChatFrame,Enum.EditModeSystem.Minimap,Enum.EditModeSystem.ObjectiveTracker,
    Enum.EditModeSystem.MicroMenu,Enum.EditModeSystem.Bags}) do
    protected[#protected+1]=object(UIParent) protected[#protected].system=system
end
local playerSystem=object(UIParent) playerSystem.system=Enum.EditModeSystem.UnitFrame playerSystem.systemIndex=0 protected[#protected+1]=playerSystem
local targetSystem=object(UIParent) targetSystem.system=Enum.EditModeSystem.UnitFrame targetSystem.systemIndex=1 protected[#protected+1]=targetSystem
local focus=object(UIParent) focus.system=Enum.EditModeSystem.UnitFrame focus.systemIndex=2 modern(focus.system,focus.systemIndex)
protected[#protected+1]=focus
modern(BuffFrame.system,BuffFrame.systemIndex) modern(DebuffFrame.system,DebuffFrame.systemIndex)
local external=object(UIParent) external.system=Enum.EditModeSystem.AuraFrame external.systemIndex=2 modern(external.system,external.systemIndex)

local expectedAnchors={}
local function managed(system,index,key)
    local frame=object(UIParent) frame.system=system frame.systemIndex=index modern(system,index)
    expectedAnchors[key]=frame return frame
end
local extra=managed(Enum.EditModeSystem.ExtraAbilities,nil,'extra')
local encounter=managed(Enum.EditModeSystem.EncounterBar,nil,'encounter')
local talking=managed(Enum.EditModeSystem.TalkingHeadFrame,nil,'talking')
local vehicle=managed(Enum.EditModeSystem.VehicleLeaveButton,nil,'vehicle')
local archaeology=managed(Enum.EditModeSystem.ArchaeologyBar,nil,'archaeology')
local essential=managed(Enum.EditModeSystem.CooldownViewer,0,'essential')
local utility=managed(Enum.EditModeSystem.CooldownViewer,1,'utility')
local buffIcon=managed(Enum.EditModeSystem.CooldownViewer,2,'buffIcon')
local buffBar=managed(Enum.EditModeSystem.CooldownViewer,3,'buffBar')
local damage=managed(Enum.EditModeSystem.DamageMeter,nil,'damage')

local function configure(frame)
    frame.IsInitialized=function() return true end
    frame.UpdateSystem=function(self, info)
        self.updateCount=(self.updateCount or 0)+1 self.systemInfo=info
        local a=info.anchorInfo
        self:SetPoint(a.point,_G[a.relativeTo],a.relativePoint,a.offsetX,a.offsetY)
    end
end
for _, frame in ipairs(protected) do configure(frame) modern(frame.system,frame.systemIndex) end
for _, frame in ipairs({BuffFrame,DebuffFrame,external,extra,encounter,talking,vehicle,
    archaeology,essential,utility,buffIcon,buffBar,damage}) do configure(frame) end

EditModePresetLayoutManager={GetModernSystems=function() return modernSystems end}
EditModeManagerFrame={registeredSystemFrames={},editModeActive=false}
function EditModeManagerFrame:RegisterSystemFrame(frame) self.registeredSystemFrames[#self.registeredSystemFrames+1]=frame end
function EditModeManagerFrame:ExitEditMode() self.editModeActive=false end
for _, frame in ipairs(protected) do EditModeManagerFrame:RegisterSystemFrame(frame) end
for _, frame in ipairs({BuffFrame,DebuffFrame,external,extra,encounter,talking,vehicle,
    archaeology,essential,utility,buffIcon,buffBar,damage}) do EditModeManagerFrame:RegisterSystemFrame(frame) end

local events, prompts
prompts={}
CreateFrame=function(_,name,parent)
    local frame=object(parent) frame.name=name
    if name then prompts[#prompts+1]=frame else events=frame end
    return frame
end

assert(loadfile(STAGE..'Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua'))()
events.scripts.OnEvent(events,'PLAYER_ENTERING_WORLD') flush()

for _, frame in ipairs(protected) do eq(frame.updateCount,nil,'protected Modern system') end
for _, frame in ipairs({BuffFrame,DebuffFrame,external,extra,encounter,talking,vehicle,
    archaeology,essential,utility,buffIcon,buffBar,damage}) do eq(frame.updateCount,3,'Modern policy retries') end

eq(BuffFrame.points[1],'TOPRIGHT','buff point') eq(BuffFrame.points[2],PlayerFrame,'buff relative frame')
eq(BuffFrame.points[3],'TOPLEFT','buff relative point') eq(BuffFrame.points[4],-12,'buff x') eq(BuffFrame.points[5],5,'buff y')
eq(DebuffFrame.points[1],'TOPRIGHT','debuff point') eq(DebuffFrame.points[2],BuffFrame,'debuff relative frame')
eq(DebuffFrame.points[3],'BOTTOMRIGHT','debuff relative point') eq(DebuffFrame.points[4],0,'debuff x') eq(DebuffFrame.points[5],-6,'debuff y')
eq(BuffFrame.AuraContainer.addIconsToRight,false,'buff grows left') eq(BuffFrame.AuraContainer.addIconsToTop,false,'buff wraps down')
eq(DebuffFrame.AuraContainer.addIconsToRight,false,'debuff grows left') eq(DebuffFrame.AuraContainer.addIconsToTop,false,'debuff wraps down')
BuffFrame:UpdateSize(105) flush() eq(DebuffFrame.points[2],BuffFrame,'debuff follows resized buff frame')

local function anchor(frame,point,relativePoint,x,y)
    eq(frame.points[1],point) eq(frame.points[2],UIParent) eq(frame.points[3],relativePoint)
    eq(frame.points[4],x) eq(frame.points[5],y)
end
anchor(extra,'BOTTOM','CENTER',0,-80) anchor(encounter,'BOTTOM','CENTER',0,0)
anchor(talking,'TOP','TOP',-420,-220) anchor(vehicle,'BOTTOM','CENTER',92,-80)
anchor(archaeology,'TOP','TOP',300,-225) anchor(essential,'BOTTOM','CENTER',0,110)
anchor(utility,'BOTTOM','CENTER',0,55) anchor(buffIcon,'BOTTOM','CENTER',0,165)
anchor(buffBar,'BOTTOMRIGHT','CENTER',-460,-40)
anchor(damage,'TOPLEFT','TOPLEFT',13,-17)

extra:SetPoint('BOTTOM',UIParent,'BOTTOM',0,0)
EditModeManagerFrame:ExitEditMode() flush() anchor(extra,'BOTTOM','CENTER',0,-80)
local late=managed(Enum.EditModeSystem.DamageMeter,7,'late') configure(late)
EditModeManagerFrame:RegisterSystemFrame(late) flush() eq(late.updateCount,1,'late registered system')

inCombat=true DebuffFrame:ApplySystemAnchor() flush()
eq(DebuffFrame.points[2],UIParent,'combat leaves native debuff write pending')
inCombat=false events.scripts.OnEvent(events,'PLAYER_REGEN_ENABLED') flush()
eq(DebuffFrame.points[2],BuffFrame,'regen repairs debuff lane')

eq(PlayerFrame.points[4],-310,'player x preserved') eq(PlayerFrame.points[5],-175,'player y preserved')
eq(TargetFrame.points[4],310,'target x preserved') eq(TargetFrame.points[5],-175,'target y preserved')
eq(TargetFrame.buffsOnTop,nil,'addon does not taint the target aura setting')
eq(TargetFrame.auraUpdates,nil,'addon does not enter target aura updates')
eq(TargetFrame.auraAnchorUpdates,nil,'addon does not enter target aura anchoring')
eq(TargetFrame.UpdateSystemSettingBuffsOnTop,nativeTargetBuffSetting,'target setting method is not hooked')
eq(TargetFrame.ApplySystemAnchor,nativeTargetAnchor,'target anchor method is not hooked')
eq(PlayerCastingBarFrame.points[2],ConsolePortGroupBase,'cast anchor preserved')
eq(#prompts,2,'target prompts not duplicated')
print('PASS: independent buff/debuff systems share a left-growing, down-wrapping lane and follow dynamic height.')
print('PASS: all unit frames and protected HUD systems are untouched; other registered systems receive Blizzard Modern records.')
print('PASS: target position is preserved without persistent target-frame writes, aura calls or method hooks.')
print('PASS: controller-safe transient rail survives retries, Edit Mode exit, late registration and combat deferral.')
