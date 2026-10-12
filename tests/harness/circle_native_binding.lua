-- Continues the native Circle fixture's declarations only, before legacy tests.
-- Full native Layers.OnNewBindings/ApplyRow/Resolve run. C macro binding dispatch,
-- hardware and secure post-hooks remain host models, not Retail certification.
TEST_SUCCESS=nil
Circle.BINDING=requestedBinding
verify(Circle.BINDING=='MACRO CPF Circle','Circle still routes through addon button')
local createdFrames=0
circleApi.CreateFrame=function() createdFrames=createdFrames+1 error('native macro route created intermediate frame') end
verify(Circle.Probe(circleApi),'native macro binding probe failed')
local missing=C.Copy(circleApi) missing.SetBindingMacro=false
verify(not Circle.Probe(missing),'missing native macro binding API accepted')
local old={set=2,keys={PAD2=Circle.LEGACY_BINDING,PAD1='JUMP',PAD3='INTERACTTARGET',
 ['SHIFT-PAD2']='ACTIONBUTTON2',['CTRL-PAD2']='MULTIACTIONBAR1BUTTON2'},keyboard={ESCAPE='TOGGLEGAMEMENU'}}
local proposal,changed=Circle.Proposal(old,true)
verify(changed and proposal.keys.PAD2==Circle.BINDING,'reviewed legacy click did not migrate to native macro')
proposal.keys.PAD2=Circle.LEGACY_BINDING
verify(C.Equal(old,proposal),'migration altered other native/manual bindings')
verify(not select(2,Circle.Proposal(old,false)),'unowned legacy click was migrated')

-- Model native post-reload body formatting, which was absent from the original
-- accepted-record fixture. Readback equality must tolerate only line endings
-- and final empty lines, without a native edit/delete/create or lost user text.
local macroAdapter=assert(Circle.NewMacroAdapter(circleApi))
local bodyBefore=macros[3].body
local createsBefore,deletesBefore=macroCreates,macroDeletes
for _,body in ipairs({Circle.MACRO, Circle.MACRO..'\n', Circle.MACRO..'\n\n',
    Circle.MACRO:gsub('\n','\r\n'), ((Circle.MACRO..'\n'):gsub('\n','\r\n'))}) do
    macros[3].body=body
    local observed,index,format=macroAdapter:read({'state'})
    verify(observed.body==Circle.MACRO and index==3 and format.expectedCommands,'native line endings misclassified as manual macro edit')
    verify(macroAdapter:Proposal() and macroAdapter:write({'state'},observed),'equivalent native macro cannot be reused/read back')
    verify(macros[3].body==body and macroCreates==createsBefore and macroDeletes==deletesBefore,'normalization rewrote native macro bytes')
end
for _,body in ipairs({' '..Circle.MACRO, Circle.MACRO..' ', Circle.MACRO..'\n/say edited',
    Circle.MACRO:gsub('/stopcasting','/say casting'), Circle.MACRO:gsub('\n','\r'),
    Circle.MACRO:gsub('/stopmacro %[mod%]\n',''), (Circle.MACRO:gsub('\n/cleartarget',''))}) do
    macros[3].body=body
    local observed=macroAdapter:read({'state'})
    verify(observed.body==body and not macroAdapter:Proposal(),'actual manual macro edit normalized/accepted')
    verify(not macroAdapter:write({'state'},{name=Circle.MACRO_NAME,body=Circle.MACRO}) and not macroAdapter:write({'state'},nil),'manual macro edit overwritten/deleted')
end
macros[3].body=bodyBefore

-- Native OnNewBindings mirrors the real saved command as a binding, not a test
-- shortcut claiming the CPF frame directly. Formatter is captured native code.
db.Gamepad={Index={Modifier={Blocked={}}}}
--@NATIVE_CIRCLE_FORMATTER
local settingsChanged=db.Layers.OnSettingsChanged
db.Layers.OnSettingsChanged=function() end -- Modifier wiring is covered by T41/T61.
local nativeSet={PAD2={['']=Circle.BINDING,['SHIFT-']='ACTIONBUTTON2'},PAD1={['']='JUMP'}}
db.Layers:OnNewBindings(nativeSet)
db.Layers:Execute(CPAPI.ConvertSecureBody("self::ApplyRow('', '')"))
verify(GetBindingAction('PAD2',true)==Circle.BINDING,'full native binding row lost macro command')
local function engine(chord,down)
    local command=GetBindingAction(chord,true)
    local macro=command:match('^MACRO (.+)$')
    if macro then
        if not down then return end -- C binding edge is explicitly modeled.
        local h,s=hardware,secureCircleCall hardware,secureCircleCall=true,true
        local ok,error=pcall(RunMacro,macro,'LeftButton')
        hardware,secureCircleCall=h,s assert(ok,error)
    else
        local name,click=command:match('^CLICK ([^:]+):(.+)$')
        if name then press(assert(named[name]),down,click) end
    end
end
for _,fighting in ipairs({false,true}) do
    combat=fighting
    for mask=0,7 do
        state={cast=mask%2==1,ground=math.floor(mask/2)%2==1,target=math.floor(mask/4)%2==1}
        calls={} local before=macroRuns engine('PAD2',true) engine('PAD2',false)
        verify(macroRuns==before+1 and table.concat(calls,',')=='cast,ground,target','native macro binding did not dispatch cancellation once')
        verify(not state.cast and not state.ground and not state.target,'native macro route left cancellable state')
    end
end
combat=false
for _,level in ipairs({'NAV','MODAL'}) do
    local owner=CreateFrame('Button','CPFNativeMacroOwner'..level,UIParent,'SecureActionButtonTemplate')
    local cancel=0 owner:SetScript('OnClick',function(_,_,down) if down then cancel=cancel+1 end end)
    db.Layers:Claim('native-macro-modal',level,'PAD2','click',owner:GetName(),'LeftButton')
    local before=macroRuns engine('PAD2',true) engine('PAD2',false)
    verify(cancel==1 and macroRuns==before,'native macro stole UI/ring cancel')
    db.Layers:ReleaseAll('native-macro-modal')
    verify(GetBindingAction('PAD2',true)==Circle.BINDING,'native macro did not return from native modal')
end
db.Layers:Execute(CPAPI.ConvertSecureBody("self::ApplyRow('SHIFT-', 'SHIFT-')"))
verify(GetBindingAction('SHIFT-PAD2',true)=='ACTIONBUTTON2','native macro changed modified actions')
db.Layers:Execute(CPAPI.ConvertSecureBody("self::ApplyRow('', '')"))
local before=C.Copy(overrides)
for _=1,5 do Circle:Refresh(circleApi,true) end
verify(createdFrames==0 and C.Equal(before,overrides),'native macro refresh added frame/binding claim')

-- Logging cannot authorize or perform native actions. Secure post-hooks are
-- modeled as wrappers only; real Retail taint remains unproved.
function hooksecurefunc(name,callback)
    local fn=assert(_G[name])
    _G[name]=function(...)
        local result=table.pack(fn(...)) callback(...)
        return table.unpack(result,1,result.n)
    end
end
function GetTime() return 123 end
function GetCVar() return '1' end
local account=assert(Addon.Store.EnsureSchema({},'LogOwner'))
Addon.record=Addon.Store.GetCharacter(account,'LogOwner')
Addon.Diagnostics.circle=nil Circle.logHooks=nil
Circle:InstallLog(circleApi) Circle:InstallLog(circleApi)
state={cast=true} calls={} engine('PAD2',true) engine('PAD2',false)
local log=Addon.Diagnostics.circle
verify(log.calls.RunMacro==1 and log.calls.SpellStopCasting==1,'automatic native call log absent/duplicated')
verify(log.calls.SpellStopTargeting==1 and log.calls.ClearTarget==1,'cancellation chain log incomplete')
verify(Addon.record.lastRuntimeDiagnostics.circle.calls.SpellStopCasting==1,'native call log not persisted automatically')
local runs=macroRuns
Circle:OnLogEvent(circleApi,'UNIT_SPELLCAST_START','player',{}, {})
Circle:OnLogEvent(circleApi,'UNIT_SPELLCAST_INTERRUPTED','player',{}, {})
verify(macroRuns==runs,'spell observer dispatched protected macro')
verify(log.rows[#log.rows].event=='UNIT_SPELLCAST_INTERRUPTED','spell interruption log absent')
verify(log.rows[#log.rows].shift==false and log.rows[#log.rows].ctrl==false and log.rows[#log.rows].alt==false,'false modifier became unavailable')
local seq=log.sequence
Circle:OnLogEvent(circleApi,'UNIT_SPELLCAST_START','target')
verify(log.sequence==seq,'other-unit spell data logged')
local secret={} local secretApi=C.Copy(circleApi)
secretApi.issecretvalue=function(value) return value==secret end
secretApi.GetBindingAction=function() return secret end
secretApi.IsShiftKeyDown=function() return secret end
secretApi.IsControlKeyDown=function() return false end
secretApi.IsAltKeyDown=function() return false end
secretApi.GetTime=function() return secret end
Circle:Record(secretApi,'secret-test')
local row=log.rows[#log.rows]
verify(row.saved=='unknown' and row.effective=='unknown' and row.shift=='unknown' and row.time=='unknown','logger disclosed secret values')
macros[3].body=Circle.MACRO..'\n'
Circle:Refresh(circleApi,true)
verify(log.resource.length==#Circle.MACRO+1 and log.resource.terminalNewlines==1 and log.resource.expectedCommands,'automatic native macro format evidence missing')
verify(Addon.record.lastRuntimeDiagnostics.circle.resource.terminalNewlines==1,'native macro format evidence not automatically persisted')
local hiddenBody={} local hiddenApi=C.Copy(circleApi)
hiddenApi.GetMacroInfo=function(slot) if slot==3 then return Circle.MACRO_NAME,134400,hiddenBody end end
hiddenApi.issecretvalue=function(value) return value==hiddenBody end
Circle:Refresh(hiddenApi,true)
verify(log.resource.unreadable and log.resource.length==nil,'secret macro body formatted/disclosed')
macros[3].body=bodyBefore Circle:Refresh(circleApi,true)
local rowsBefore=#log.rows
macros[3].body=bodyBefore..'\n' Circle:Refresh(circleApi,true)
verify(#log.rows==rowsBefore+1 and log.rows[#log.rows].resource.terminalNewlines==1,'format-only resource refresh was deduplicated')
verify(Addon.record.circleLogSessions[#Addon.record.circleLogSessions].observations.resource.terminalNewlines==1,'format-only resource refresh absent from retained session')
macros[3].body=bodyBefore Circle:Refresh(circleApi,true)
seq=log.sequence Circle:OnLogEvent(secretApi,'UNIT_SPELLCAST_START',secret)
verify(log.sequence==seq,'secret unit inferred player')
for i=1,200 do Circle:OnLogEvent(circleApi,'MODIFIER_STATE_CHANGED') end
verify(#log.rows==80 and #Addon.record.lastRuntimeDiagnostics.circle.rows==80,'automatic log is unbounded/not persisted')
verify(#Addon.record.circleLogSessions==1 and #Addon.record.circleLogSessions[1].observations.rows==80,'session archive omitted current observations')
local callsBefore=C.Copy(log.calls)
Circle:Record(circleApi,'refresh') local count=#log.rows
Circle:Record(circleApi,'refresh')
verify(#log.rows==count and C.Equal(log.calls,callsBefore),'unchanged refresh duplicated rows/native actions')
for i=1,6 do
    Circle.logOwner=nil -- Model a new UI session loading the retained record.
    Circle:Record(circleApi,'reload-'..i)
end
verify(#Addon.record.circleLogSessions==4 and Addon.record.circleLogSessions[4].observations.rows[1].event=='reload-6','recent session archive lost logs or grew unbounded')
local priorRecord=Addon.record
Addon.record=Addon.Store.GetCharacter(account,'OtherLogOwner') Circle:Record(circleApi,'new-character')
verify(#Addon.record.circleLogSessions==1 and Addon.record.circleLogSessions[1].observations.rows[1].event=='new-character','Circle logs leaked across GUID owner')
Addon.record=priorRecord
local badHooks=C.Copy(circleApi) badHooks.hooksecurefunc=function() error('hooks unavailable') end
Circle.logHooks=nil verify(pcall(Circle.InstallLog,Circle,badHooks),'optional logging hook failure stopped runtime')
db.Layers.OnSettingsChanged=settingsChanged
SERIALIZED_STATE='Native macro/log assertions: '..cases
TEST_SUCCESS=true
