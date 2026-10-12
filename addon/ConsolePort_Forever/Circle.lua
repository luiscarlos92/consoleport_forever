local _,Addon=...
local Circle={NAME='ConsolePortForeverCircleCancel',MACRO_NAME='CPF Circle'}
Addon.CircleCancel=Circle
Circle.BINDING='CLICK '..Circle.NAME..':LeftButton'
-- A direct native secure click, never Escape or an insecure /run callback.
-- Retail exposes no qualified first-success result branch to addon snippets.
-- This deliberately cancels all three states; it does not claim exact parity.
Circle.MACRO='/stopmacro [mod]\n/stopcasting\n/stopspelltarget\n/cleartarget'

local function CanWrite(api)
    return not api.InCombatLockdown() and not (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown())
end
local function MacroLimits(api)
    local limits=api.Constants and api.Constants.MacroConsts
    assert(limits and limits.MAX_ACCOUNT_MACROS==120 and limits.MAX_CHARACTER_MACROS==30,'unqualified native macro limits')
    return limits.MAX_ACCOUNT_MACROS,limits.MAX_CHARACTER_MACROS
end
local function MacroState(api)
    local account,character=MacroLimits(api)
    local found,index
    -- Scan both banks: name dispatch must never select a character duplicate.
    for slot=1,account+character do
        local name,_,body=api.GetMacroInfo(slot)
        assert(not api.issecretvalue or (not api.issecretvalue(name) and not api.issecretvalue(body)),'unreadable native macro')
        if name==Circle.MACRO_NAME then
            assert(not found and slot<=account,'Circle macro name collision; no overwrite')
            found,index={name=name,body=body},slot
        end
    end
    return found,index
end
local MacroAdapter={}
function Circle.NewMacroAdapter(api)
    for _,name in ipairs({'GetMacroInfo','GetNumMacros','CreateMacro','DeleteMacro','RunMacro','InCombatLockdown'}) do
        if type(api[name])~='function' then return nil,'native saved-macro API unavailable' end
    end
    if not pcall(MacroLimits,api) then return nil,'unqualified native macro limits' end
    return setmetatable({api=api},{__index=MacroAdapter})
end
function MacroAdapter:read(path)
    assert(#path==1 and path[1]=='state','unowned macro field')
    return MacroState(self.api)
end
function MacroAdapter:Proposal()
    local ok,current=pcall(self.read,self,{'state'})
    if not ok then return nil,current end
    local proposal={name=Circle.MACRO_NAME,body=Circle.MACRO}
    if current and not Addon.Core.Equal(current,proposal) then return nil,'Circle macro manually edited; no overwrite' end
    local count=self.api.GetNumMacros()
    if not current and ((self.api.issecretvalue and self.api.issecretvalue(count)) or type(count)~='number' or count<0 or count>=120) then return nil,'account macro storage full/unreadable; no existing macro replaced' end
    return proposal
end
function MacroAdapter:write(path,value)
    assert(#path==1 and path[1]=='state','unowned macro field')
    if not CanWrite(self.api) then return false end
    local current,index=MacroState(self.api)
    local expected={name=Circle.MACRO_NAME,body=Circle.MACRO}
    if value==nil then
        if not current then return true end
        if not Addon.Core.Equal(current,expected) then return false end
        self.api.DeleteMacro(index)
        return MacroState(self.api)==nil
    end
    if not Addon.Core.Equal(value,expected) then return false end
    if current then return Addon.Core.Equal(current,expected) end
    if not self:Proposal() then return false end
    -- A reviewed native account macro, never an EditMacro/RunMacroText fallback.
    self.api.CreateMacro(Circle.MACRO_NAME,134400,Circle.MACRO,false)
    return Addon.Core.Equal(MacroState(self.api),expected)
end

function Circle:Prepare(api)
    if type(api.CreateFrame)~='function' or type(api.InCombatLockdown)~='function'
        or type(api.SecureActionButton_OnClick)~='function' then
        return false,'native secure click dispatcher unavailable'
    end
    local adapter,reason=self.NewMacroAdapter(api)
    if not adapter then return false,reason end
    local ok,macro=pcall(adapter.read,adapter,{'state'})
    local valid=ok and Addon.Core.Equal(macro,{name=self.MACRO_NAME,body=self.MACRO})
    local current=api[self.NAME]
    if current and current~=self.frame then return false,'Circle frame name belongs to another owner' end
    if self.frame then
        local frame=self.frame
        if current~=frame or frame:GetScript('OnClick')~=api.SecureActionButton_OnClick
            or frame:GetAttribute('type')~=self.activeType or frame:GetAttribute('macro')~=self.MACRO_NAME
            or frame:GetAttribute('macrotext')~=nil
            or frame:GetAttribute('useOnKeyDown')~=true then
            return false,'Circle native frame contract changed; no overwrite'
        end
        local desired=valid and 'macro' or nil
        if desired~=self.activeType then
            if not CanWrite(api) then return false,'Circle macro activation waits for combat/Edit Mode' end
            frame:SetAttribute('type',desired) self.activeType=desired
        end
        if not ok or (macro and not valid) then return false,ok and 'Circle macro manually edited; route disabled' or macro end
        return true,'native saved-macro click prepared; exact first-success parity remains gated'
    end
    if api.InCombatLockdown() or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown()) then
        return false,'Circle preparation waits for combat/Edit Mode to end'
    end
    local frame=api.CreateFrame('Button',self.NAME,api.UIParent,'SecureActionButtonTemplate')
    -- Keep the template-owned script slot. Reassigning even the same function
    -- from addon Lua can lose secure provenance; pointer equality is insufficient.
    if frame:GetScript('OnClick')~=api.SecureActionButton_OnClick then
        return false,'Circle template-native click handler unavailable; no replacement'
    end
    frame:SetSize(1,1) frame:SetPoint('TOPLEFT',api.UIParent,'TOPLEFT') frame:EnableMouse(false)
    frame:RegisterForClicks('AnyDown','AnyUp')
    frame:SetAttribute('macro',self.MACRO_NAME)
    self.activeType=valid and 'macro' or nil
    frame:SetAttribute('type',self.activeType)
    frame:SetAttribute('useOnKeyDown',true)
    self.frame=frame
    if not ok or (macro and not valid) then return false,ok and 'Circle macro manually edited; route disabled' or macro end
    return true,'native saved-macro click prepared; exact first-success parity remains gated'
end

-- Only configuration review may offer the new command. Hydration never calls
-- this helper, so a later manual removal/empty binding is not restored.
function Circle.Proposal(state)
    local proposed=Addon.Core.Copy(state)
    if proposed.keys.PAD2~='' then return proposed,false end
    proposed.keys.PAD2=Circle.BINDING
    return proposed,true
end

function Circle:Refresh(api,installed)
    if not installed then return false,'character configuration not installed' end
    local ready,reason=self:Prepare(api)
    ready=ready and self.activeType=='macro'
    if not ready and self.frame and not self.activeType then reason='Circle awaits reviewed saved macro; no RunMacroText fallback' end
    Addon.Diagnostics:SetFeature('circleCancel',ready and 'offline-verified' or 'pending',reason)
    return ready,reason
end
