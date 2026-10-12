local _,Addon=...
local Circle={NAME='ConsolePortForeverCircleCancel',MACRO_NAME='CPF Circle'}
Addon.CircleCancel=Circle
Circle.LEGACY_BINDING='CLICK '..Circle.NAME..':LeftButton'
Circle.BINDING='MACRO '..Circle.MACRO_NAME
-- Native saved macro dispatch, never Escape or an insecure /run callback.
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
    local found,index,format
    -- Scan both banks: name dispatch must never select a character duplicate.
    for slot=1,account+character do
        local name,_,body=api.GetMacroInfo(slot)
        assert(not api.issecretvalue or (not api.issecretvalue(name) and not api.issecretvalue(body)),'unreadable native macro')
        if name==Circle.MACRO_NAME then
            assert(not found and slot<=account,'Circle macro name collision; no overwrite')
            -- Native cache/editor round trips may add CRLF or terminal blank
            -- lines. Canonicalize only the exact four commands we own; never
            -- trim spaces, rearrange commands or rewrite the native macro.
            local canonical=type(body)=='string' and body:gsub('\r\n','\n'):gsub('\n+$','') or body
            format={length=type(body)=='string' and #body or 0,
                crlf=type(body)=='string' and select(2,body:gsub('\r\n','')) or 0,
                terminalNewlines=type(body)=='string' and #(body:gsub('\r\n','\n'):match('\n+$') or '') or 0,
                expectedCommands=canonical==Circle.MACRO}
            found,index={name=name,body=canonical==Circle.MACRO and Circle.MACRO or body},slot
        end
    end
    return found,index,format
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
function Circle.Proposal(state,legacyOwned)
    local proposed=Addon.Core.Copy(state)
    if proposed.keys.PAD2~='' and not (legacyOwned and proposed.keys.PAD2==Circle.LEGACY_BINDING) then return proposed,false end
    proposed.keys.PAD2=Circle.BINDING
    return proposed,true
end

function Circle.Probe(api)
    local adapter,reason=Circle.NewMacroAdapter(api)
    if not adapter then return false,reason end
    if type(api.SetBindingMacro)~='function' then return false,'native macro binding API unavailable' end
    return true,'native MACRO binding available; engine execution remains unverified'
end
function Circle.IsBinding(binding)
    return binding==Circle.BINDING or binding==Circle.LEGACY_BINDING
end

function Circle:Refresh(api,installed)
    if not installed then return false,'character configuration not installed' end
    local ready,reason=self.Probe(api)
    if ready then
        local adapter=self.NewMacroAdapter(api)
        local ok,macro,_,format=pcall(adapter.read,adapter,{'state'})
        self:GetLog().resource=ok and (format or {missing=true}) or {unreadable=true}
        ready=ok and Addon.Core.Equal(macro,{name=self.MACRO_NAME,body=self.MACRO})
        reason=ready and 'native MACRO resource ready; effective engine dispatch is logged, not certified' or 'Circle saved macro missing/changed/unreadable; no automatic repair'
    end
    local binding=api.GetBindingAction and api.GetBindingAction('PAD2')
    if api.issecretvalue and api.issecretvalue(binding) then binding=nil end
    if binding==self.LEGACY_BINDING then
        local prepared,legacyReason=self:Prepare(api)
        ready=prepared and self.activeType=='macro'
        reason='legacy click retained pending reviewed native MACRO migration: '..tostring(legacyReason)
    elseif binding~=self.BINDING then ready=false reason='Circle binding manually changed/unreadable; retained' end
    Addon.Diagnostics:SetFeature('circleCancel',ready and 'resource-ready' or 'pending',reason)
    self:Record(api,'refresh')
    return ready,reason
end

-- Bounded public observations only. No protected actions, spell predicates or
-- routing writes occur in the logger. WoW persists this through SavedVariables.
local function Public(api,value)
    if api.issecretvalue and api.issecretvalue(value) then return 'unknown' end
    local kind=type(value)
    if kind=='string' or kind=='number' or kind=='boolean' then return value end
    return 'unknown'
end
local function Observe(api,name,...)
    if type(api[name])~='function' then return 'unavailable' end
    local ok,value=pcall(api[name],...)
    if ok then return Public(api,value) end
    return 'unavailable'
end
function Circle:Record(api,event)
    local log=self:GetLog()
    log.sequence=log.sequence+1
    local row={sequence=log.sequence,event=event,time=Observe(api,'GetTime'),
        saved=Observe(api,'GetBindingAction','PAD2'),effective=Observe(api,'GetBindingAction','PAD2',true),
        shift=Observe(api,'IsShiftKeyDown'),ctrl=Observe(api,'IsControlKeyDown'),alt=Observe(api,'IsAltKeyDown'),
        useKeyDown=Observe(api,'GetCVar','ActionButtonUseKeyDown'),calls=Addon.Core.Copy(log.calls),
        resource=Addon.Core.Copy(log.resource or {})}
    if event=='refresh' and log.lastRefresh then
        local a,b=Addon.Core.Copy(row),Addon.Core.Copy(log.lastRefresh)
        a.sequence,a.time=nil,nil b.sequence,b.time=nil,nil
        if Addon.Core.Equal(a,b) then return end
    end
    if event=='refresh' then log.lastRefresh=Addon.Core.Copy(row) end
    log.rows[#log.rows+1]=row
    if #log.rows>80 then table.remove(log.rows,1) end
    local record=Addon.record
    if record and (record.circleLogSessions==nil or type(record.circleLogSessions)=='table') then
        record.circleLogSessions=record.circleLogSessions or {}
        if not self.logSession then
            local count=record.circleLogSequence
            if type(count)~='number' or count<0 or count%1~=0 then count=0 end
            record.circleLogSequence=count+1 self.logSession=count+1
            record.circleLogSessions[#record.circleLogSessions+1]={session=self.logSession}
            if #record.circleLogSessions>4 then table.remove(record.circleLogSessions,1) end
        end
        local entry=record.circleLogSessions[#record.circleLogSessions]
        if entry and entry.session==self.logSession then
            entry.codeVersion,entry.configRevision=Addon.VERSION,Addon.CONFIG_REVISION
            entry.observations=Addon.Core.Copy(log)
        end
    end
    Addon.Diagnostics:Persist('circle')
end
function Circle:GetLog()
    if self.logOwner~=Addon.record then
        self.logOwner=Addon.record self.logSession=nil Addon.Diagnostics.circle=nil
    end
    Addon.Diagnostics.circle=Addon.Diagnostics.circle or {sequence=0,rows={},calls={}}
    return Addon.Diagnostics.circle
end
function Circle:InstallLog(api)
    self.logHooks=self.logHooks or {}
    if type(api.hooksecurefunc)~='function' then return end
    for _,name in ipairs({'RunMacro','SpellStopCasting','SpellStopTargeting','ClearTarget'}) do
        if type(api[name])=='function' and not self.logHooks[name] then
            local ok=pcall(api.hooksecurefunc,name,function()
                local log=self:GetLog()
                log.calls[name]=(log.calls[name] or 0)+1
                self:Record(api,'native-call:'..name)
            end)
            if ok then self.logHooks[name]=true end
        end
    end
end
function Circle:OnLogEvent(api,event,unit)
    if event:find('^UNIT_SPELLCAST_') then
        if Public(api,unit)~='player' then return end
    end
    self:Record(api,event)
end
