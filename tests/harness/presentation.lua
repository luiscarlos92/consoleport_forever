local installed,combat=true,false
function Addon:IsCharacterInstalled() return installed end
function InCombatLockdown() return combat end
local timers,frames={},{}
C_Timer={After=function(_,callback) timers[#timers+1]=callback end}
local function flush() while #timers>0 do table.remove(timers,1)() end end
function hooksecurefunc(object,key,callback)
    local native=object[key]
    object[key]=function(...) local result=native(...) callback(...) return result end
end
local function region()
    local r={maskCalls=0}
    for _,method in ipairs({'SetTexCoord','ClearAllPoints','SetPoint','SetSize','SetColorTexture','SetAllPoints','SetSwipeTexture','SetUseCircularEdge'}) do
        r[method]=function(self,...) self[method..'Args']={...} end
    end
    function r:SetTexture(value) self.texture=value end function r:SetAtlas(value) self.atlas=value end
    function r:AddMaskTexture(mask) self.mask=mask self.maskCalls=self.maskCalls+1 end
    function r:RemoveMaskTexture(mask) assert(self.mask==mask) self.mask=nil self.removals=(self.removals or 0)+1 end
    function r:Show() self.shown=true end function r:Hide() self.shown=false end
    return r
end
local Frame={}
function Frame:RegisterEvent() end function Frame:SetScript(key,fn) self[key]=fn end
function Frame:SetSize() end function Frame:SetPoint() end function Frame:ClearAllPoints() end
function Frame:SetParent(parent) self.parent=parent end function Frame:GetParent() return self.parent end
function Frame:GetName() return self.name end function Frame:GetWidth() return 50 end
function Frame:CreateTexture() return region() end
function Frame:CreateMaskTexture() self.maskCount=(self.maskCount or 0)+1 return region() end
function Frame:HookScript(key,fn) self.hooks=self.hooks or {} self.hooks[key]=fn end
function Frame:Show() end
function CreateFrame(_,name,parent)
    if name then assert(not frames[name],'duplicate named prompt/frame') end
    local f=setmetatable({name=name,parent=parent},{__index=Frame})
    if name then frames[name]=f _G[name]=f end return f
end
function wipe(t) for key in pairs(t) do t[key]=nil end end
local GMT,Group={},{}
local removals=0
local function SkinButton(button,regions,skin) assert(skin==false) removals=removals+1 button.icon:SetTexture('native-default') end
--@NATIVE_MASQUE_REMOVE
local CPGroupBar={}
local GROUP,GROUP_BUTTON='Group','GroupButton'
GROUP='Action Group' YELLOW_FONT_COLOR={WrapTextInColorCode=function(_,value) return value end}
local env={}
function env.MakeID(format,...) return string.format(format,...) end
local function makeButton(id,bank)
    local button=setmetatable({id=id,parent=bank,_state_type='custom',attributes={state=''},icon=region()},{__index=Frame})
    for _,key in ipairs({'NormalTexture','PushedTexture','HighlightTexture','CheckedTexture','Flash','Border','NewActionTexture','SpellHighlightTexture','cooldown','chargeCooldown','lossOfControlCooldown'}) do button[key]=region() end
    function button:GetAttribute(key) return self.attributes[key] end
    function button:SetProps() end function button:UpdateLocal() end function button:UpdateButtonArt() end
    function button:AddToMasque(group) group:AddButton(self) end
    return button
end
function env:Acquire(kind,name,id,bank) assert(kind==GROUP_BUTTON) return makeButton(id,bank) end
--@NATIVE_GROUP_SKIN_LIFECYCLE
local Manager={bindingSnapshot={PAD1={['']='JUMP',['SHIFT-']='INTERACTTARGET'},PAD2={['']=''},PAD3={['']='INTERACTTARGET'},PAD4={['']='TURNORACTION'}}}
--@NATIVE_MANAGER_BINDINGS
Addon.adapters={consoleport={api={version='3.3.3'},bar={Manager=Manager}}}
C_Spell={GetSpellTexture=function(id) assert(id==6603) return 6603 end}
function UnitExists() return false end
local function makeBank(id,name)
    local bank=setmetatable({id=id,name=name,buttons={}},{__index=Frame})
    bank.UpdateButtons=CPGroupBar.UpdateButtons bank.OnMasqueLoaded=CPGroupBar.OnMasqueLoaded
    function bank:OnRelease() wipe(self.buttons) end
    local group=setmetatable({Buttons={},db={Disabled=false}},{__index=GMT})
    function group:AddButton(button) self.Buttons[button]={} Group[button]=self end
    bank.msqGroup=group
    bank:UpdateButtons({PAD1={},PAD2={},PAD3={},PAD4={},PADDUP={}})
    return bank
end
for _,id in ipairs({'Base','L2','R2','L2R2'}) do _G['ConsolePortGroup'..id]=makeBank(id,'ConsolePortGroup'..id) end
--@PRODUCT_SKIN
Addon:RefreshConsolePortSkin()
assert(removals==16)
for _,id in ipairs({'Base','L2','R2','L2R2'}) do
    local bank=_G['ConsolePortGroup'..id]
    assert(bank.msqGroup.Buttons[bank.buttons.PADDUP] and bank.buttons.PADDUP.IconMask==nil,'D-pad was detached/skinned')
    for _,key in ipairs({'PAD1','PAD2','PAD3','PAD4'}) do
        local b=bank.buttons[key]
        assert(b.maskCount==1 and b.icon.maskCalls==1 and b.SlotBackground.maskCalls==1 and not bank.msqGroup.Buttons[b])
    end
end
local base=ConsolePortGroupBase
local jump=base.buttons.PAD1
assert(jump.icon.texture:find('ForeverInGame',1,true))
jump.attributes.state='SHIFT-' jump:UpdateLocal() assert(jump.icon.texture==6603,'display ignored the resolved native state')
jump._state_type='action' jump.icon:SetTexture('native-spell') jump:UpdateLocal() assert(jump.icon.texture=='native-spell','style replaced a native spell icon')
jump._state_type='custom' jump.attributes['cpf-held']=true jump.icon:SetTexture('held-native') jump:UpdateLocal() assert(jump.icon.texture=='held-native')
jump.attributes['cpf-held']=nil
Addon:RefreshConsolePortSkin() assert(removals==16 and jump.maskCount==1 and jump.icon.maskCalls==1)
local oldIcon=jump.icon
jump.icon=region() jump:UpdateLocal()
assert(jump.icon.maskCalls==1 and oldIcon.mask==nil and oldIcon.removals==1)
local previousMask=jump.IconMask
jump.IconMask=region() jump:UpdateLocal()
assert(jump.icon.mask==jump.IconMask and jump.icon.mask~=previousMask and jump.icon.maskCalls==2 and jump.icon.removals==1)
local msq={Group=function(_,addon,name) assert(addon=='ConsolePort' and name) return base.msqGroup end}
base:OnMasqueLoaded(msq) flush() assert(removals==20 and base.msqGroup.Buttons[base.buttons.PADDUP])
base:UpdateButtons({PAD1={},PAD2={},PAD3={},PAD4={},PADDUP={}}) flush()
assert(removals==24 and base.buttons.PAD1.maskCount==1)
combat=true base:OnMasqueLoaded(msq) flush() assert(removals==24,'combat setup modified group membership')
combat=false Addon:RefreshConsolePortSkin() assert(removals==28)
installed=false base.buttons.PAD1.icon:SetTexture('manual-after-restore') base.buttons.PAD1:UpdateLocal()
assert(base.buttons.PAD1.icon.texture=='manual-after-restore','inactive hook reapplied owned skin')
installed=true
local friendly=frames.ConsolePortForeverFriendlyPrompt
ConsolePortGroupBase=makeBank('Base','ReplacementBase') Addon:RefreshConsolePortSkin()
assert(frames.ConsolePortForeverFriendlyPrompt==friendly and friendly.parent==ConsolePortGroupBase,'replaced bank duplicated targeting prompt')
TEST_SUCCESS=true
