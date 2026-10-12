-- Runs after actual ConsolePort Layers/Input/UI handlers. New macro execution,
-- key edges, modifier parsing, C cancellation results and engine trust are host
-- models; actual Blizzard attribute/secure-click/slash functions run below.
TEST_SUCCESS=nil
local Circle,C=Addon.CircleCancel,Addon.Core
-- Retain candidate31/32's intermediate-button contract as historical coverage.
-- T71 separately runs the current engine-owned binding and full native row.
local requestedBinding=Circle.BINDING
Circle.BINDING=Circle.LEGACY_BINDING
local cases=0
local function verify(condition,message) cases=cases+1 assert(condition,message) end
local editing,keydown,mod=false,true,false
-- Engine provenance is modeled separately from hardware and function equality.
-- Template handlers come from the pinned XML; addon SetScript loses that slot
-- provenance even if it assigns the identical native function pointer.
local templateSlots=setmetatable({},{__mode='k'})
local rawSetScript=Frame.SetScript
function Frame:SetScript(event,callback)
    if event=='OnClick' and templateSlots[self] then templateSlots[self].secure=false end
    return rawSetScript(self,event,callback)
end
local rawFire=fire
local secureCircleCall=false
fire=function(frame,event,...)
    local previous=secureCircleCall
    local slot=templateSlots[frame]
    if slot and event=='OnClick' then secureCircleCall=slot.secure end
    local ok,reason=pcall(rawFire,frame,event,...)
    secureCircleCall=previous
    assert(ok,reason)
end
function Frame:EnableMouse(value) self.mouseEnabled=value end
function Frame:GetAttribute(prefix,name,suffix)
    if not name then return self.attributes[prefix] end
    return self.attributes[prefix..name..suffix] or self.attributes['*'..name..suffix]
        or self.attributes[prefix..name..'*'] or self.attributes['*'..name..'*'] or self.attributes[name]
end
local LOCAL_CHECK_Frame=Frame
local BUTTON_LOOKUP_TABLE={}
ATTRIBUTE_NOOP=''
function IsShiftKeyDown() return mod=='shift' end
function IsControlKeyDown() return mod=='ctrl' end
function IsAltKeyDown() return mod=='alt' end
function GetCVarBool(name) return name=='ActionButtonUseKeyDown' and keydown or false end
function UnitCanAttack() return false end
function UnitCanAssist() return false end
function UnitExists() return true end
function SpellCanTargetItem() return false end
function SpellCanTargetItemID() return false end
function forceinsecure() error('Circle attempted an insecure custom action') end
--@NATIVE_CIRCLE_ATTRIBUTES
--@NATIVE_CIRCLE_MACRO_ACTION
--@NATIVE_CIRCLE_CLICK
local state,calls,macroRuns={}, {}, 0
function SpellStopCasting()
    assert(hardware,'cast cancellation lacks hardware authority')
    assert(secureCircleCall,'[ADDON_ACTION_BLOCKED] Circle script provenance lost')
    calls[#calls+1]='cast'
    local success=state.cast or state.channel
    state.cast,state.channel=false,false
    return success
end
function SpellStopTargeting()
    assert(hardware,'reticle cancellation lacks hardware authority')
    calls[#calls+1]='ground'
    local success=state.ground state.ground=false return success
end
function ClearTarget()
    assert(hardware,'target cancellation lacks hardware authority')
    calls[#calls+1]='target'
    local success=state.target state.target=false return success
end
local stopped,commands=false,{}
function SecureCmdOptionParse(msg)
    if msg=='' then return '' end
    if msg=='[mod]' then return mod and '' or nil end
    error('unexpected conditional; no fabricated casting/reticle conditional')
end
function StopMacro() stopped=true end
SLASH_COMMAND={STOPCASTING='STOPCASTING',STOPSPELLTARGET='STOPSPELLTARGET',CLEARTARGET='CLEARTARGET',STOPMACRO='STOPMACRO'}
SLASH_COMMAND_CATEGORY={COMBAT=1,TARGETING=2}
SlashCommandUtil={CheckAddSecureSlashCommand=function(name,_,callback) commands[name:lower()]=callback end}
--@NATIVE_CIRCLE_SLASH
C_Macro={RunMacroText=function() error('[ADDON_ACTION_FORBIDDEN] RunMacroText()') end}
local macros={[3]={name=Circle.MACRO_NAME,body=Circle.MACRO,icon=134400}}
local macroCreates,macroDeletes=0,0
Constants=Constants or {} Constants.MacroConsts={MAX_ACCOUNT_MACROS=120,MAX_CHARACTER_MACROS=30}
function GetMacroInfo(index)
    local row=macros[index]
    if row then return row.name,row.icon,row.body end
end
function GetNumMacros()
    local a,c=0,0 for index in pairs(macros) do if index<=120 then a=a+1 else c=c+1 end end return a,c
end
function CreateMacro(name,icon,body,character)
    assert(not combat and not editing and not character,'unsafe native macro creation')
    macroCreates=macroCreates+1
    for index=1,120 do if not macros[index] then macros[index]={name=name,icon=icon,body=body} return index end end
    error('macro storage full')
end
function DeleteMacro(index)
    assert(not combat and not editing,'unsafe native macro deletion') macroDeletes=macroDeletes+1 macros[index]=nil
end
function securecallfunction(callback,...) return callback(...) end
--@NATIVE_CIRCLE_SAVE_MACRO
function RunMacro(name,button)
    assert(hardware and button=='LeftButton','Circle macro did not use native hardware click')
    assert(secureCircleCall,'[ADDON_ACTION_BLOCKED] Circle script provenance lost')
    local text
    for _,row in pairs(macros) do if row.name==name then assert(not text,'ambiguous macro dispatch') text=row.body end end
    assert(text,'native saved macro missing')
    macroRuns=macroRuns+1 stopped=false
    for line in text:gmatch('[^\n]+') do
        local command,msg=line:match('^/([a-z]+)%s*(.*)$')
        assert(commands[command],'unexpected non-cancellation macro command')
        commands[command](msg)
        if stopped then break end
    end
end
function SetBindingMacro() error('preparation wrote a native macro binding') end
local circleApi={CreateFrame=function(kind,name,parent,template)
        assert(not combat,'Circle attempted secure creation in combat')
        local frame=CreateFrame(kind,name,parent,template)
        --@NATIVE_CIRCLE_TEMPLATE
        frame.scripts.OnClick=SecureActionButton_OnClick
        templateSlots[frame]={secure=true}
        return frame
    end,UIParent=UIParent,C_Macro=C_Macro,Constants=Constants,
    GetMacroInfo=GetMacroInfo,GetNumMacros=GetNumMacros,CreateMacro=CreateMacro,DeleteMacro=DeleteMacro,RunMacro=RunMacro,SetBindingMacro=SetBindingMacro,
    InCombatLockdown=InCombatLockdown,SecureActionButton_OnClick=SecureActionButton_OnClick,
    EditModeManagerFrame={IsShown=function() return editing end}}
setmetatable(circleApi,{__index=_G})
local originalName,originalFrame=Circle.NAME,Circle.frame
-- Preparation is inert and unavailable native APIs must not create a route.
Circle.NAME='CPFTestCircleUnavailable' Circle.frame=nil
local missing=C.Copy(circleApi) missing.GetMacroInfo=false
verify(not Circle:Prepare(missing),'unavailable API installed cancellation')
combat=true verify(not Circle:Prepare(circleApi),'created secure button in combat') combat=false
editing=true verify(not Circle:Prepare(circleApi),'created secure button in Edit Mode') editing=false
verify(not _G[Circle.NAME],'blocked preparation created a frame')
_G[Circle.NAME]={foreign=true}
verify(not Circle:Prepare(circleApi) and _G[Circle.NAME].foreign,'foreign frame name overwritten')
_G[Circle.NAME]=nil
for _,inherited in ipairs({'missing','foreign'}) do
    Circle.NAME='CPFTestCircleBadTemplate'..inherited
    local badApi=C.Copy(circleApi)
    badApi.CreateFrame=function(kind,name,parent,template)
        local frame=CreateFrame(kind,name,parent,template)
        frame.scripts.OnClick=inherited=='foreign' and function() error('foreign handler') end or nil
        frame.SetScript=function() error('invalid native handler was overwritten') end
        return frame
    end
    verify(not Circle:Prepare(badApi),'invalid inherited Circle handler accepted')
    verify(_G[Circle.NAME]:GetAttribute('macrotext')==nil and Circle.frame==nil,
        'invalid template received protected macro or became prepared owner')
    _G[Circle.NAME]=nil
end
Circle.NAME=originalName Circle.frame=originalFrame
verify(Circle:Prepare(circleApi),'Circle native secure frame did not prepare')
local button=Circle.frame
verify(button:GetAttribute('macro')==Circle.MACRO_NAME and button:GetAttribute('macrotext')==nil,'Circle used forbidden macrotext route')
verify(button:GetScript('OnClick')==SecureActionButton_OnClick and button.mouseEnabled==false,
    'native callback or invisible non-mouse route changed')
verify(macroRuns==0 and #calls==0,'preparation dispatched a game action')
-- Replay candidate.31's exact same-function reassignment under real native
-- Layers/input dispatch later; matching pointer and hardware are not authority.
local defect=circleApi.CreateFrame('Button','CPFTestCircleBlocked',UIParent,'SecureActionButtonTemplate')
defect:SetAttribute('type','macro') defect:SetAttribute('macrotext',Circle.MACRO)
defect:SetAttribute('useOnKeyDown',true) defect:RegisterForClicks('AnyDown','AnyUp')
defect:SetScript('OnClick',SecureActionButton_OnClick)
verify(defect:GetScript('OnClick')==SecureActionButton_OnClick,'old defect lost identical native pointer')
state={cast=true,target=true}
local previousHardware=hardware
local rejected,message=pcall(press,defect,true,'LeftButton')
hardware=previousHardware -- The modeled hardware scope must unwind after failure.
verify(not rejected and tostring(message):find('[ADDON_ACTION_FORBIDDEN] RunMacroText()',1,true),'candidate31 protected-action defect did not reproduce')
verify(state.cast and state.target,'blocked old handler changed protected state')
combat=true
for _=1,5 do verify(Circle:Prepare(circleApi) and Circle.frame==button,'combat refresh mutated prepared action') end
combat=false
for _,attribute in ipairs({'type','macro','macrotext','useOnKeyDown'}) do
    local previous=button:GetAttribute(attribute)
    button:SetAttribute(attribute,'foreign')
    verify(not Circle:Prepare(circleApi) and button:GetAttribute(attribute)=='foreign','foreign attribute overwritten')
    button:SetAttribute(attribute,previous)
end
local script,originalSecure=button:GetScript('OnClick'),templateSlots[button].secure
button:SetScript('OnClick',function() end)
verify(not Circle:Prepare(circleApi),'replaced native script accepted') button:SetScript('OnClick',script)
-- This intentional foreign-script probe restores the test engine's inherited
-- slot; production never repairs provenance by setting a function back.
templateSlots[button].secure=originalSecure
verify(not pcall(script,button,'LeftButton',true),'public callback obtained protected cancellation')
verify(not Circle:Refresh(circleApi,false) and macroRuns==0,'uninstalled character refreshed a route')

-- Actual native Layers dispatch keeps Circle at BASE and other chords intact.
db.Layers:Claim('circle-character-bindings','BASE','PAD2','click',button:GetName(),'LeftButton')
local other={}
for _,prefix in ipairs({'','SHIFT-','CTRL-','CTRL-SHIFT-'}) do
    for _,key in ipairs({'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}) do
        local chord=prefix..key
        if chord~='PAD2' then
            local action=CreateFrame('Button','CPFTestCircleOther'..#other+1,UIParent,'SecureActionButtonTemplate')
            action:SetScript('OnClick',function(_,_,down) if down then action.count=(action.count or 0)+1 end end)
            db.Layers:Claim('circle-other-bindings','BASE',chord,'click',action:GetName(),'LeftButton')
            other[#other+1]={chord=chord,action=action}
        end
    end
end
local function dispatch(chord,down)
    local name,click=GetBindingAction(chord,true):match('^CLICK ([^:]+):(.+)$')
    assert(named[name],'effective engine binding had no target')
    press(named[name],down,click)
end
for _,fighting in ipairs({false,true}) do
    combat=fighting
    for _,setting in ipairs({false,true}) do
        keydown=setting
        for mask=0,7 do
            state={cast=mask%2==1,ground=math.floor(mask/2)%2==1,target=math.floor(mask/4)%2==1}
            calls={} local before=macroRuns
            dispatch('PAD2',true)
            verify(macroRuns==before+1 and table.concat(calls,',')=='cast,ground,target','cancel-all did not execute once on down')
            verify(not state.cast and not state.ground and not state.target,'cancel-all left a cancellable state active')
            dispatch('PAD2',false)
            verify(macroRuns==before+1,'Circle release dispatched a duplicate')
        end
        state={channel=true,target=true} calls={}
        dispatch('PAD2',true) dispatch('PAD2',false)
        verify(not state.channel and not state.target,'channel/hard-target combined cancellation changed')
        for _,row in ipairs(other) do
            local before=row.action.count or 0 local runs=macroRuns
            dispatch(row.chord,true) dispatch(row.chord,false)
            verify(row.action.count==before+1 and macroRuns==runs,'Circle stole another ordinary chord: '..row.chord)
        end
    end
end
combat=false
-- A misrouted modified click still cannot invoke Base cancellation.
for _,modifier in ipairs({'shift','ctrl','alt'}) do
    mod=modifier calls={}
    press(button,true,'LeftButton') press(button,false,'LeftButton')
    verify(#calls==0,'modified click reached Base cancellation')
end
mod=false
-- Foreign modals and native rings own their cancel keys; no CPF lease is added.
for _,level in ipairs({'NAV','MODAL'}) do
    local owner=CreateFrame('Button','CPFTestCircleOwner'..level,UIParent,'SecureActionButtonTemplate')
    local cancelled=0 owner:SetScript('OnClick',function(_,_,down) if down then cancelled=cancelled+1 end end)
    db.Layers:Claim('circle-foreign-owner',level,'PAD2','click',owner:GetName(),'LeftButton')
    local before=macroRuns
    dispatch('PAD2',true) dispatch('PAD2',false)
    verify(cancelled==1 and macroRuns==before,'Circle intercepted native ring/UI cancel')
    db.Layers:ReleaseAll('circle-foreign-owner')
    verify(GetBindingAction('PAD2',true)==Circle.BINDING,'native Base return lost Circle')
end
-- Held UI release across combat must not execute the new gameplay action.
local heldOwner=CreateFrame('Frame','CPFTestCircleHeldOwner',UIParent)
input:SetCommand('PAD2',heldOwner,true,'LeftButton','CircleHeldCancel',function() end)
local held=input.Widgets.PAD2 press(held,true)
local before=macroRuns
combat=true trusted=true input:SetAttribute('state-combat',true)
SecureHandler_Other_Execute(input,input,'self,newstate',input:GetAttribute('_onstate-combat'),true)
trusted=false press(held,false)
verify(macroRuns==before,'stale UI release invoked Circle')
dispatch('PAD2',true) dispatch('PAD2',false)
verify(macroRuns==before+1,'first combat Circle dispatch lost native Base owner')
combat=false trusted=true input:SetAttribute('state-combat',nil) trusted=false input:Release(heldOwner)
-- Native/user removal is respected: no Refresh or preparation installs bindings.
db.Layers:ReleaseAll('circle-character-bindings')
local routesBefore=C.Copy(overrides)
for _=1,5 do Circle:Refresh(circleApi,true) end
verify(C.Equal(routesBefore,overrides),'Circle refresh restored a removed binding')
verify(GetBindingAction('PAD2',true)~=Circle.BINDING,'manual Circle removal was undone')

-- Review proposal changes only an explicit empty Base face; all other native
-- state, modified actions, keyboard mappings and manual commands are retained.
local baseline={set=2,keys={PAD1='JUMP',PAD2='',PAD3='INTERACTTARGET',PAD4='TURNORACTION',
    ['SHIFT-PAD2']='ACTIONBUTTON2',['CTRL-PAD2']='MULTIACTIONBAR1BUTTON2',
    ['CTRL-SHIFT-PAD2']='MULTIACTIONBAR2BUTTON2',PADRSTICK='TOGGLEPINGLISTENER'},keyboard={ESCAPE='TOGGLEGAMEMENU',SPACE='JUMP'}}
local proposed,changed=Circle.Proposal(baseline)
verify(changed and proposed.keys.PAD2==Circle.BINDING,'empty Circle proposal omitted')
proposed.keys.PAD2=''
verify(C.Equal(proposed,baseline),'Circle proposal altered unrelated state')
for _,manual in ipairs({'TOGGLEGAMEMENU','CLICK Manual:LeftButton','ACTIONBUTTON9',Circle.BINDING}) do
    local edited=C.Copy(baseline) edited.keys.PAD2=manual
    local nextState,diff=Circle.Proposal(edited)
    verify(not diff and C.Equal(nextState,edited),'manual Circle binding overwritten')
end
local absent=C.Copy(baseline) absent.keys.PAD2=nil
local nextState,diff=Circle.Proposal(absent)
verify(not diff and C.Equal(nextState,absent),'absent/unreadable key inferred empty')
-- Real setup entry point marks the changed whole-state field for explicit review.
local account=assert(Addon.Store.EnsureSchema({},'CircleA'))
local record=Addon.Store.GetCharacter(account,'CircleA')
local bindingAdapter={mask={},native={api={CharacterSet=2}},read=function() return C.Copy(baseline) end}
for key in pairs(baseline.keys) do bindingAdapter.mask[key]=true end
local cp={api={version='3.3.10'},db={},read=function() return {children={}} end}
local originalProbe=Addon.SecureModes.Probe Addon.SecureModes.Probe=function() return false,'not part of Circle' end
circleApi.GetCVarDefault=function() return nil end
local macroAdapter=assert(Circle.NewMacroAdapter(circleApi))
local setupAdapters={bindings=bindingAdapter,consoleport=cp,circleMacro=macroAdapter,integrationReasons={}}
local fields=Addon.RuntimeSetup.Fields(account,'CircleA',setupAdapters,circleApi,18)
local field
for _,row in ipairs(fields) do if row.id=='CircleA/controller' then field=row end end
verify(field and field.requireReview==true and C.Decode(field.value).keys.PAD2==Circle.BINDING,'Circle bypassed explicit configuration review')
verify(field.label:find('together',1,true) and field.label:find('no Escape/menu',1,true),'review hid cancel-all difference')
local prior=Addon.RuntimeSetup.BindingProposal(account,'CircleA',bindingAdapter,{})
verify(prior.keys.PAD2=='','normal binding hydration auto-installed Circle')
local snapshot={bindings={state=prior}}
local managed={[field.id]={value=C.Encode(prior)}}
local plan=Addon.Plan.Build(snapshot,managed,{field})
verify(#plan.conflicts==1 and #plan.operations==0,'unchanged old baseline auto-applied Circle')
verify(not Addon.Plan.Accept(plan,{}),'unresolved Circle review applied')
verify(#assert(Addon.Plan.Accept(plan,{[field.id]='keep'}))==0,'Keep applied Circle anyway')
verify(#assert(Addon.Plan.Accept(plan,{[field.id]='accept'}))==1,'accepted Circle not available')
local reviews={[field.id]={decision='keep',revision=field.revision,current=field.value==nil and nil or C.Encode(prior),proposed=field.value}}
verify(#Addon.Plan.Build(snapshot,managed,{field},reviews).conflicts==0,'matching remembered Keep repeated Circle conflict')
-- Accept/capture persists shared Base only; later manual empty is not repaired.
account.shared.faceBindings=Addon.BindingPolicy.Split(C.Decode(field.value).keys).shared
verify(Addon.RuntimeSetup.BindingProposal(account,'CircleA',bindingAdapter,{}).keys.PAD2==Circle.BINDING,'accepted shared Circle not hydrated')
account.shared.faceBindings.PAD2=''
verify(Addon.RuntimeSetup.BindingProposal(account,'CircleA',bindingAdapter,{}).keys.PAD2=='','manual shared empty was restored')
baseline.keys.PAD2='CLICK Manual:LeftButton'
account.shared.faceBindings={}
fields=Addon.RuntimeSetup.Fields(account,'CircleA',setupAdapters,circleApi,18)
for _,row in ipairs(fields) do if row.id=='CircleA/controller' then field=row end end
verify(not field.requireReview and C.Decode(field.value).keys.PAD2=='CLICK Manual:LeftButton','setup replaced manual Circle')
Addon.SecureModes.Probe=originalProbe
-- Actual bootstrap caller prepares independently of suspended UI acquisition;
-- absence of adapters still runs the early preparation/readiness path.
--@CURRENT_CIRCLE_REFRESH
local order={}
local owner={BlizzardVisibility={Update=function() order[#order+1]='visibility' end},
    CircleCancel={Refresh=function(_,native,installed)
        verify(native==_G and installed==true,'bootstrap Circle readiness lost actual installation guard')
        order[#order+1]='circle'
    end},Cinematic={Refresh=function() order[#order+1]='cinematic' end},
    IsCharacterInstalled=function() return true end}
Addon.RefreshUI(owner)
verify(table.concat(order,',')=='visibility,circle,cinematic','bootstrap omitted/reordered Circle preparation')
-- The normal coordinator retains before-state, combat refusal, explicit Keep,
-- drift detection and restore semantics for the new reviewed value.
local durable=assert(Addon.Store.EnsureSchema({},'CircleJournal'))
local live=C.Copy(baseline) live.keys.PAD2=''
local writable=true
local selected,saves,writeKeys=2,0,{}
local saved={[1]={set=1,keys={PAD2='ACCOUNT-MANUAL'},keyboard={ESCAPE='TOGGLEGAMEMENU'}},[2]=C.Copy(live)}
local mask={} for key in pairs(live.keys) do mask[key]=true end
local function flat()
    local values=C.Copy(live.keyboard)
    for key,value in pairs(live.keys) do values[key]=value end
    return values
end
local native=Addon.NativeBindings.New({AccountSet=1,CharacterSet=2,
    GetCurrentBindingSet=function() return selected end,InCombatLockdown=function() return not writable end,
    GetNumBindings=function() local n=0 for _ in pairs(flat()) do n=n+1 end return n end,
    GetBinding=function(index) local n=0 for key,value in pairs(flat()) do n=n+1 if n==index then return value,'category',key end end end,
    GetBindingAction=function(key) return live.keys[key] or live.keyboard[key] or '' end,
    SetBinding=function(key,value)
        assert(writable) writeKeys[#writeKeys+1]=key
        if mask[key] then live.keys[key]=value or '' else live.keyboard[key]=value end
        return true
    end,
    LoadBindings=function(set) assert(writable) selected=set live=C.Copy(saved[set]) end,
    SaveBindings=function(set) assert(writable and set==selected) saves=saves+1 saved[set]=C.Copy(live) return true end})
local journalRecord=Addon.Store.GetCharacter(durable,'CircleJournal')
local adapter=Addon.BindingStateAdapter.New(native,mask,journalRecord)
local banks=Addon.BindingBanksAdapter.New(native,journalRecord,function() return writable end)
adapter.bankInspector=banks adapter.canWrite=function() return writable end
local coordinator=Addon.Coordinator.New(durable,'CircleJournal',{bindings=adapter,bindingBanks=banks},function() return writable end)
local desired=Circle.Proposal(live)
local proposal={id='CircleJournal/controller',scope='bindings',path={'state'},value=C.Encode(desired),revision=17,requireReview=true}
coordinator:Build({proposal},17)
writable=false
verify(not coordinator:Accept({[proposal.id]='accept'}) and live.keys.PAD2=='','combat review wrote Circle')
writable=true live.keys.PAD3='CLICK NewManual:LeftButton'
verify(not coordinator:Resume() and live.keys.PAD2=='' and live.keys.PAD3=='CLICK NewManual:LeftButton','stale review overwrote a later manual edit')
desired=Circle.Proposal(live) proposal.value=C.Encode(desired)
coordinator:Build({proposal},17)
verify(coordinator:Accept({[proposal.id]='accept'}) and live.keys.PAD2==Circle.BINDING,'reviewed journal did not apply Circle')
local journal=coordinator.lastJournal
verify(journal.status=='committed' and journal.steps[1].before.keys.PAD2=='','Circle lost journal before-state')
verify(journal.bindingDetails and #writeKeys==1 and writeKeys[1]=='PAD2' and saves==1,'Circle did not use a scoped native binding subjournal')
verify(saved[1].keys.PAD2=='ACCOUNT-MANUAL' and selected==2,'Circle changed inactive account bindings/selection')
verify(live.keys.PAD3=='CLICK NewManual:LeftButton' and live.keyboard.ESCAPE=='TOGGLEGAMEMENU','review changed other manual/keyboard commands')
verify(coordinator:Restore(journal.id) and live.keys.PAD2=='','Circle rollback did not restore original empty')
coordinator:Build({proposal},17) verify(coordinator:Accept({[proposal.id]='accept'}),'Circle second review failed')
local restoreId=coordinator.lastJournal.id live.keys.PAD2='CLICK LaterManual:LeftButton'
verify(not coordinator:Restore(restoreId) and live.keys.PAD2=='CLICK LaterManual:LeftButton','Circle restore erased newer manual binding')
verify(Circle.MACRO:find('/run',1,true)==nil and Circle.MACRO:find('TOGGLEGAMEMENU',1,true)==nil,'Circle contains insecure or Escape route')
-- Saved macro lifecycle uses the actual coordinator/transaction and Circle
-- adapter. The engine storage APIs are models, including reindexing and edits.
local originalMacros=C.Copy(macros)
macros={[1]={name='Manual',body='/cast Manual',icon=42},[121]={name='Personal',body='/say kept',icon=43}}
local untouched=C.Copy(macros)
local createdBefore,deletedBefore=macroCreates,macroDeletes
verify(Circle:Prepare(circleApi) and button:GetAttribute('type')==nil,'missing macro left cancellation active')
verify(macroCreates==createdBefore and C.Equal(macros,untouched),'preparation created/edited a saved macro')
local macroDB=assert(Addon.Store.EnsureSchema({},'MacroOwner'))
local mc=Addon.Coordinator.New(macroDB,'MacroOwner',{circleMacro=macroAdapter},function() return not combat and not editing end)
local mf={id='shared/circleMacro',scope='circleMacro',path={'state'},value=C.Encode(assert(macroAdapter:Proposal())),revision=18,requireReview=true}
local mp=mc:Build({mf},18)
verify(#mp.conflicts==1 and not mc:Accept({}),'missing macro bypassed explicit review')
verify(mc:Accept({[mf.id]='keep'}) and C.Equal(macros,untouched),'Keep created native macro')
verify(#mc:Build({mf},18).conflicts==0,'remembered macro Keep repeated same revision')
macroDB.reviews[mf.id]=nil -- Independent acceptance case, after Keep was proved.
mc:Build({mf},18) combat=true
verify(not mc:Accept({[mf.id]='accept'}) and C.Equal(macros,untouched),'combat created saved macro')
combat=false editing=true
verify(not macroAdapter:write({'state'},C.Decode(mf.value)),'Edit Mode wrote saved macro') editing=false
-- A collision appearing after review invalidates the plan, with no EditMacro.
macros[2]={name=Circle.MACRO_NAME,body='/cast Changed',icon=44}
verify(not mc:Resume() and macros[2].body=='/cast Changed','stale macro review overwrote user macro') macros[2]=nil
mc:Build({mf},18)
verify(mc:Accept({[mf.id]='accept'}),'reviewed native macro creation failed')
local mj=mc.lastJournal
verify(mj.status=='committed' and C.IsNil(mj.steps[1].before),'macro journal lost absent before-state')
verify(macroCreates==createdBefore+1 and macroDeletes==deletedBefore,'wrong macro lifecycle mutation count')
verify(C.Equal(macros[1],untouched[1]) and C.Equal(macros[121],untouched[121]),'native macro creation changed another macro')
verify(Circle:Prepare(circleApi) and button:GetAttribute('type')=='macro','reviewed macro did not activate cancellation')
local found,index=macroAdapter:read({'state'})
-- Native macro indices are unstable. Name dispatch survives harmless reorder.
macros[8]=macros[index] macros[index]=nil
verify(Circle:Prepare(circleApi) and button:GetAttribute('macro')==Circle.MACRO_NAME,'macro reindex changed cancellation identity')
state={cast=true} calls={} press(button,true,'LeftButton') press(button,false,'LeftButton')
verify(not state.cast,'name-based saved macro failed after reindex')
macros[8].body='/cast UserChanged'
verify(not Circle:Prepare(circleApi) and button:GetAttribute('type')==nil,'edited native macro retained cancellation route')
verify(not macroAdapter:Proposal() and not mc:Restore(mj.id),'manual macro edit was proposed over or deleted by restore')
verify(macros[8].body=='/cast UserChanged','restore destroyed edited macro')
macros[8].body=Circle.MACRO
verify(mc:Restore(mj.id) and not macroAdapter:read({'state'}),'reviewed macro restore did not delete exact created macro')
verify(C.Equal(macros,untouched),'macro restore altered unowned macros')
-- Full storage, duplicate names and character-only collisions fail closed.
for index=1,120 do macros[index]={name='Manual'..index,body='/say kept',icon=index} end
local full=C.Copy(macros)
verify(not macroAdapter:Proposal() and not macroAdapter:write({'state'},C.Decode(mf.value)),'full macro bank replaced an existing macro')
verify(C.Equal(full,macros),'full macro bank mutated')
macros=C.Copy(untouched)
macros[121]={name=Circle.MACRO_NAME,body=Circle.MACRO,icon=43}
verify(not pcall(macroAdapter.read,macroAdapter,{'state'}) and not Circle:Prepare(circleApi),'character macro collision accepted')
verify(button:GetAttribute('type')==nil,'character macro collision remained active')
macros[3]={name=Circle.MACRO_NAME,body=Circle.MACRO,icon=134400}
verify(not macroAdapter:Proposal(),'duplicate macro names accepted')
macros[121]=untouched[121] macros[4]=C.Copy(macros[3])
verify(not macroAdapter:Proposal(),'duplicate account macro names accepted')
macros[4]=nil
local secretApi=C.Copy(circleApi) secretApi.issecretvalue=function(value) return value==Circle.MACRO end
verify(not pcall(Circle.NewMacroAdapter(secretApi).read,Circle.NewMacroAdapter(secretApi),{'state'}),'secret macro content inferred public')
local badLimits=C.Copy(circleApi) badLimits.Constants={MacroConsts={MAX_ACCOUNT_MACROS=121,MAX_CHARACTER_MACROS=30}}
verify(not Circle.NewMacroAdapter(badLimits),'unknown native macro limits accepted')
verify(not pcall(macroAdapter.write,macroAdapter,{'other'},nil),'unowned macro field writable')
verify(not macroAdapter:write({'state'},{name='Foreign',body=Circle.MACRO}),'arbitrary macro payload writable')
-- Failure after macro creation compensates only the exact reviewed resource.
macros=C.Copy(untouched)
local failure={read=function() return false end,write=function() return false end}
local steps={{id='macro',scope='circleMacro',path={'state'},before=C.Encode(nil),value=mf.value,revision=18},
 {id='failure',scope='failure',path={'state'},before=false,value=true,revision=18}}
local rollback=Addon.Transactions.Prepare(macroDB,'MacroOwner',steps,{revision=18})
verify(not Addon.Transactions.Apply(rollback,{circleMacro=macroAdapter,failure=failure},function() return true end),'failing transaction unexpectedly committed')
verify(rollback.status=='rolled-back' and C.Equal(macros,untouched),'transaction compensation left macro or changed other macros')
-- Renaming/deleting a user resource does not trigger auto repair on refresh.
macros=originalMacros local row=macros[3] row.name='Renamed by user'
verify(Circle:Prepare(circleApi) and button:GetAttribute('type')==nil,'renamed macro remained active')
local afterRename=C.Copy(macros) createdBefore=macroCreates
for _=1,5 do Circle:Refresh(circleApi,true) end
verify(C.Equal(afterRename,macros) and macroCreates==createdBefore,'refresh repaired a user macro rename')
row.name=Circle.MACRO_NAME Circle:Prepare(circleApi)
SERIALIZED_STATE='Circle regression assertions: '..cases
Circle.BINDING=requestedBinding
TEST_SUCCESS=true
