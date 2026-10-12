-- Runs after actual ConsolePort Layers/Input/UI handlers. New macro execution,
-- key edges, modifier parsing, C cancellation results and engine trust are host
-- models; actual Blizzard attribute/secure-click/slash functions run below.
TEST_SUCCESS=nil
local Circle,C=Addon.CircleCancel,Addon.Core
local cases=0
local function verify(condition,message) cases=cases+1 assert(condition,message) end
local editing,keydown,mod=false,true,false
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
C_Macro={RunMacroText=function(text,button)
    assert(hardware and button=='LeftButton','Circle macro did not use native hardware click')
    macroRuns=macroRuns+1 stopped=false
    for line in text:gmatch('[^\n]+') do
        local command,msg=line:match('^/([a-z]+)%s*(.*)$')
        assert(commands[command],'unexpected non-cancellation macro command')
        commands[command](msg)
        if stopped then break end
    end
end}
local circleApi={CreateFrame=function(kind,name,parent,template)
        assert(not combat,'Circle attempted secure creation in combat')
        return CreateFrame(kind,name,parent,template)
    end,UIParent=UIParent,C_Macro=C_Macro,
    InCombatLockdown=InCombatLockdown,SecureActionButton_OnClick=SecureActionButton_OnClick,
    EditModeManagerFrame={IsShown=function() return editing end}}
setmetatable(circleApi,{__index=_G})
local originalName,originalFrame=Circle.NAME,Circle.frame
-- Preparation is inert and unavailable native APIs must not create a route.
Circle.NAME='CPFTestCircleUnavailable' Circle.frame=nil
local missing=C.Copy(circleApi) missing.C_Macro=nil
verify(not Circle:Prepare(missing),'unavailable API installed cancellation')
combat=true verify(not Circle:Prepare(circleApi),'created secure button in combat') combat=false
editing=true verify(not Circle:Prepare(circleApi),'created secure button in Edit Mode') editing=false
verify(not _G[Circle.NAME],'blocked preparation created a frame')
_G[Circle.NAME]={foreign=true}
verify(not Circle:Prepare(circleApi) and _G[Circle.NAME].foreign,'foreign frame name overwritten')
_G[Circle.NAME]=nil Circle.NAME=originalName Circle.frame=originalFrame
verify(Circle:Prepare(circleApi),'Circle native secure frame did not prepare')
local button=Circle.frame
verify(button:GetScript('OnClick')==SecureActionButton_OnClick and button.mouseEnabled==false,
    'native callback or invisible non-mouse route changed')
verify(macroRuns==0 and #calls==0,'preparation dispatched a game action')
combat=true
for _=1,5 do verify(Circle:Prepare(circleApi) and Circle.frame==button,'combat refresh mutated prepared action') end
combat=false
for _,attribute in ipairs({'type','macrotext','useOnKeyDown'}) do
    local previous=button:GetAttribute(attribute)
    button:SetAttribute(attribute,'foreign')
    verify(not Circle:Prepare(circleApi) and button:GetAttribute(attribute)=='foreign','foreign attribute overwritten')
    button:SetAttribute(attribute,previous)
end
local script=button:GetScript('OnClick') button:SetScript('OnClick',function() end)
verify(not Circle:Prepare(circleApi),'replaced native script accepted') button:SetScript('OnClick',script)
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
local fields=Addon.RuntimeSetup.Fields(account,'CircleA',{bindings=bindingAdapter,consoleport=cp,integrationReasons={}},circleApi,17)
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
local reviews={[field.id]={decision='keep',revision=17,current=field.value==nil and nil or C.Encode(prior),proposed=field.value}}
verify(#Addon.Plan.Build(snapshot,managed,{field},reviews).conflicts==0,'matching remembered Keep repeated Circle conflict')
-- Accept/capture persists shared Base only; later manual empty is not repaired.
account.shared.faceBindings=Addon.BindingPolicy.Split(C.Decode(field.value).keys).shared
verify(Addon.RuntimeSetup.BindingProposal(account,'CircleA',bindingAdapter,{}).keys.PAD2==Circle.BINDING,'accepted shared Circle not hydrated')
account.shared.faceBindings.PAD2=''
verify(Addon.RuntimeSetup.BindingProposal(account,'CircleA',bindingAdapter,{}).keys.PAD2=='','manual shared empty was restored')
baseline.keys.PAD2='CLICK Manual:LeftButton'
account.shared.faceBindings={}
fields=Addon.RuntimeSetup.Fields(account,'CircleA',{bindings=bindingAdapter,consoleport=cp,integrationReasons={}},circleApi,17)
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
SERIALIZED_STATE='Circle regression assertions: '..cases
TEST_SUCCESS=true
