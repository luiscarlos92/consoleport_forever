-- Runs the actual current CP snippets/conversion and LAB state methods with a
-- restricted frame double. This checks contracts, not Retail secure execution.
CPAPI={SecureEnvironmentMixin={}}
local env={Attributes={Update=function(name) return '_childupdate-'..name end},RegisterCallback=function() end}
local nativeDB={SetCVar=function() end}
function CPAPI.GetEnv() return env,nativeDB end
function Mixin(base,...)
    for i=1,select('#',...) do for k,v in pairs(select(i,...)) do base[k]=v end end
    return base
end
function CreateFromMixins(...) return Mixin({},...) end
string.trim=function(s) return s:match('^%s*(.-)%s*$') end
NUM_ACTIONBAR_BUTTONS=12
--@CURRENT_CP
assert(env.SlotButton.Env.UpdateState:find('IsPressHoldReleaseSpell',1,true))
local nativeBody=env.SlotButton.Env.UpdateState
local state={page=1,bonus=0,family=nil,specialPage=12,empowered=73}
function GetActionBarPage() return state.page end
function GetBonusBarOffset() return state.family=='skyriding' and 5 or state.bonus end
function HasVehicleActionBar() return state.family=='vehicle' end
function HasOverrideActionBar() return state.family=='override' end
function HasTempShapeshiftActionBar() return state.family=='temporary' end
function GetVehicleBarIndex() return state.specialPage end
function GetOverrideBarIndex() return state.specialPage end
function GetTempShapeshiftBarIndex() return state.specialPage end
function GetActionInfo(slot) return 'spell',slot end
function IsPressHoldReleaseSpell(id) return id==state.empowered end
format,tostring=string.format,tostring
local Generic={}
local lib={callbacks={Fire=function() end}}
--@CURRENT_LAB
local trusted,combat=false,false
local function run(frame,body,...)
    local fn=assert(load('return function(self,control,...) '..CPAPI.ConvertSecureBody(body)..' end','snippet','t',_G))()
    local prior=trusted trusted=true
    local ok,value=pcall(fn,frame,frame,...)
    trusted=prior
    assert(ok,value)
    return value
end
local function make(kind,value,cell)
    local button={Env=Addon.Core.Copy(env.SlotButton.Env),attributes={state='SHIFT-',['cpf-kind-SHIFT-']=kind,
        ['cpf-action-SHIFT-']=type(value)~='table' and value or nil,['cpf-special-cell']=cell},state_types={},state_actions={}}
    Mixin(button,Generic)
    function button:GetAttribute(k) return self.attributes[k] end
    function button:SetAttribute(k,v) assert(not combat or trusted,'untrusted protected mutation') self.attributes[k]=v end
    function button:SetID(v) assert(trusted) self.id=v end
    function button:GetID() return self.id end
    function button:CallMethod(name,...) assert(trusted) return self[name](self,...) end
    function button:RunAttribute(name,...) return run(self,self.attributes[name] or self.Env[name],...) end
    function button:UpdateAction() self._state_type,self._state_action=self:GetAction(self:GetAttribute('state')) end
    function button:OnTypeChanged() end
    function button:IsVisible() return true end
    local ordinary=value
    function button:CPFContentsChanged(s,k,v)
        if k=='custom' then v=ordinary elseif k=='empty' then v=nil end
        self:ButtonContentsChanged(s,k,v)
    end
    button.attributes.IsFlyoutActive='return false'
    button.attributes.UpdateState=Addon.SecureModes.Environment(button).UpdateState
    return button
end
local main=make('action',1)
local fixed=make('action',73)
local special=make('action',61,5)
local customAction={func=function() end,texture='BASE'}
local face=make('custom',customAction)
for _,button in ipairs({main,fixed,special,face}) do button:SetAttribute('cpf-enabled',true) end
combat=true
assert(not pcall(main.SetAttribute,main,'action',999))
for _,family in ipairs({'normal','form','stealth','mount','vehicle','override','temporary','skyriding'}) do
    state.family=family
    main:RunAttribute('UpdateState','SHIFT-')
    fixed:RunAttribute('UpdateState','SHIFT-')
    special:RunAttribute('UpdateState','SHIFT-')
    face:RunAttribute('UpdateState','SHIFT-')
    assert(main:GetAttribute('action')==1 and main._state_action==1)
    assert(fixed:GetAttribute('action')==73 and fixed:GetAttribute('pressAndHoldAction')==true)
    assert(face._state_type=='custom' and face._state_action==customAction)
    local temporary=family=='vehicle' or family=='override' or family=='temporary'
    assert(special:GetAttribute('action')==(family=='skyriding' and 125 or temporary and 137 or 61))
    assert(special._state_action==special:GetAttribute('action'),'display/click disagreed')
end
state.family='vehicle'
run(special,'local button,down=...; '..Addon.SecureModes.PreClick,'ControllerInput',true)
assert(special:GetAttribute('cpf-held') and special:GetAttribute('action')==137)
state.family=nil
special:RunAttribute('UpdateState','CTRL-SHIFT-')
assert(special:GetAttribute('action')==137,'mode change switched a held action')
run(special,'local button,down=...; '..Addon.SecureModes.PostClick,'ControllerInput',false)
assert(not special:GetAttribute('cpf-held') and special:GetAttribute('type')=='empty')
state.page=2
main:RunAttribute('UpdateState','SHIFT-')
assert(main:GetAttribute('action')==13 and main._state_action==13)
combat=false
local geometry={children={Base={visibility='show'},L2={visibility='[vehicleui][overridebar] hide; show',opacity='[vehicleui][overridebar] 0; [mod:M1] 100; 45',pos={x=-270}},R2={},L2R2={},['Override Action Bar']={type='Page',page='overiidebar'}}}
local proposed=Addon.SecureModes.LayoutProposal(geometry)
assert(proposed.children.L2.visibility=='show' and proposed.children.L2.pos.x==-270)
assert(proposed.children.L2.opacity=='[mod:M1] 100; 45' and not proposed.children['Override Action Bar'])
assert(geometry.children['Override Action Bar'],'proposal mutated runtime source')
assert(Addon.SecureModes.Environment({Env={UpdateState='changed'}})==nil)
-- Exercise the extension installer, native header ownership, refresh hooks,
-- idempotent wrapping, route guards and deactivation, using actual LAB methods.
local api={CPAPI=CPAPI,InCombatLockdown=function() return combat end}
function api.hooksecurefunc(object,name,callback)
    local native=object[name]
    object[name]=function(self,...)
        local result=native(self,...)
        callback(self,...)
        return result
    end
end
local routes=true
api.GetBindingKey=function(command) if routes then return command=='VEHICLEEXIT' and 'V' or command:sub(-1) end end
local wrapCount=0
local definitions,buttonsByGroup={},{}
local bridge={Probe=function() return true end,bar={Layout={children=definitions},Manager={}}}
function bridge.bar.Manager:GetBindings(key) return {['SHIFT-']=1,['CTRL-SHIFT-']=61} end
for _,name in ipairs({'Base','L2','R2','L2R2'}) do
    definitions[name]={type='Group'}
    local group={buttons={},attrs={actionpage=12,ActionPageChanged="native-page"},refs={}}
    api['ConsolePortGroup'..name]=group
    function group:GetAttribute(k) return self.attrs[k] end
    function group:SetFrameRef(k,v) assert(not combat) self.refs[k]=v end
    function group:Execute(body)
        assert(not combat)
        local target=assert(body:find('cpfUpdateButton',1,true) and self.refs.cpfUpdateButton or self.refs.updateButton)
        target:RunAttribute('UpdateState',target:GetAttribute('state'))
    end
    function group:WrapScript(target,name,body)
        assert(not combat)
        assert(name=='PreClick' or name=='PostClick' or name=='OnHide')
        wrapCount=wrapCount+1
    end
    function group:RegisterPageResponse(body) assert(not combat) self.attrs.ActionPageChanged=body end
    function group:RunAttribute(name,page) assert(name=='ActionPageChanged' and page==12) end
    for _,key in ipairs({'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}) do
        local button=make('action',1)
        button.id,button.header=key,group
        button.attributes.UpdateState=nil
        function button:CreateEnvironment(newEnv)
            assert(not combat)
            self.Env=CreateFromMixins(self.Env,newEnv)
            for k,body in pairs(self.Env) do self:SetAttribute(k,CPAPI.ConvertSecureBody(body)) end
        end
        function button:SetStateFromHandlerInsecure(s,k,v) self.state_types[s],self.state_actions[s]=k,v end
        function button:RefreshBinding(s,command) self:SetState(s,'action',command) end
        function button:SetBindings(bindings) for s,command in pairs(bindings) do self:RefreshBinding(s,command) end end
        button:CreateEnvironment({IsFlyoutActive='return false'})
        group.buttons[key]=button
    end
end
routes=false
assert(not Addon.SecureModes.Install(bridge,api) and wrapCount==0,'missing exit route did not preserve baseline')
routes=true
assert(Addon.SecureModes.Install(bridge,api))
assert(wrapCount==96)
assert(Addon.SecureModes.Install(bridge,api) and wrapCount==96,'duplicated wrappers')
state.family='vehicle'
local updated=api.ConsolePortGroupL2R2.buttons.PADDLEFT
updated:RefreshBinding('SHIFT-',82)
assert(updated:GetAttribute('cpf-action-SHIFT-')==82 and updated:GetAttribute('action')==137)
state.family=nil
updated:RunAttribute('UpdateState','SHIFT-')
assert(updated:GetAttribute('action')==82,'rebinding lost the ordinary slot')
combat=true
assert(not Addon.SecureModes.Install(bridge,api) and not Addon.SecureModes.Disable(api,bridge))
combat=false
assert(Addon.SecureModes.Disable(api,bridge))
assert(updated.Env.UpdateState==nativeBody and not updated:GetAttribute('cpf-enabled'))
assert(api.ConsolePortGroupL2R2.attrs.ActionPageChanged=='native-page')
assert(Addon.SecureModes.Install(bridge,api) and wrapCount==96)
-- Real-world controller-only configuration has no keyboard exit or overflow
-- bindings. Verify the supplemental native secure surface instead of allowing
-- the whole mode feature to silently remain disabled.
local created,registered,cursorFrames,removedFrames=0,0,0,0
local usable,canExit=true,true
function HasAction(action) return usable and action>=129 and action<=132 end
function CanExitVehicle() return canExit end
api.UIParent={}
api.NUM_OVERRIDE_BUTTONS=12 -- Model a genuine expanded native overflow page.
api.GetActionTexture=function(action) return 'native:'..tostring(action) end
api.ConsolePort={AddInterfaceCursorFrame=function(_,frame) assert(frame==Addon.TemporaryAccess.frame) cursorFrames=cursorFrames+1 end,
    RemoveInterfaceCursorFrame=function(_,frame) assert(frame==Addon.TemporaryAccess.frame) removedFrames=removedFrames+1 end}
function api.CreateFrame(kind,name,parent,template)
    assert(not combat)
    assert(template=='SecureHandlerBaseTemplate' or template=='SecureActionButtonTemplate')
    created=created+1
    local frame={attributes={},refs={},scripts={},shown=true}
    function frame:SetSize() end
    function frame:SetPoint() end
    function frame:RegisterForClicks(first,second) assert(first=='AnyDown' and second=='AnyUp') end
    function frame:WrapScript(button,event,body)
        assert(event=='PreClick' or event=='PostClick' or event=='OnHide')
        button.wrapped=button.wrapped or {} button.wrapped[event]=body
    end
    function frame:SetAttribute(key,value)
        assert(not combat or trusted,'untrusted access mutation')
        self.attributes[key]=value
        if self.scripts.OnAttributeChanged then self.scripts.OnAttributeChanged(self,key,value) end
    end
    function frame:GetAttribute(key) return self.attributes[key] end
    function frame:SetFrameRef(key,value) assert(not combat) self.refs[key]=value end
    function frame:GetFrameRef(key) return self.refs[key] end
    function frame:Execute(body) return run(self,body) end
    function frame:SetScript(key,value) self.scripts[key]=value end
    function frame:Show() assert(not combat or trusted) self.shown=true if self.scripts.OnShow then self.scripts.OnShow(self) end end
    function frame:Hide() assert(not combat or trusted) self.shown=false end
    function frame:CreateTexture() return {SetAllPoints=function() end,SetTexture=function(t,v) t.texture=v end} end
    function frame:CreateFontString() return {SetPoint=function() end,SetText=function(t,v) t.text=v end} end
    return frame
end
bridge.db={Pager={RegisterHeader=function(_,header)
    registered=registered+1
    assert(header:GetAttribute('ActionPageChanged')==Addon.TemporaryAccess.Response)
end}}
routes=false
state.family='skyriding'
assert(Addon.SecureModes.Install(bridge,api),'unbound keyboard routes blocked actual controller-only setup')
local access=Addon.TemporaryAccess.frame
assert(created==6 and registered==1 and cursorFrames==0 and removedFrames==1,'supplemental controls claimed or retained interface-cursor registration')
assert(not access.shown and not access.refs.action9.shown and not access.refs.exit.shown,
    'editable skyriding slots produced a side bar or an empty cursor owner')
state.family='vehicle' state.specialPage=11
access:Execute(Addon.TemporaryAccess.Response)
assert(access.shown,'real temporary overflow parent was not shown')
for _,family in ipairs({'override','temporary','vehicle'}) do
    state.family=family
    access:Execute(Addon.TemporaryAccess.Response)
    assert(access.shown and access.refs.action9.shown,'genuine temporary family lost retained overflow access: '..family)
end
assert(access.refs.action9:GetAttribute('action')==129 and access.refs.action12:GetAttribute('action')==132)
assert(access.refs.exit.shown and access.refs.exit:GetAttribute('type')=='leavevehicle')
assert(access.refs.action9:GetAttribute('useOnKeyDown')==false)
-- HasAction alone can report occupied slots that have no exposed temporary
-- action identity. A one-button Darkmoon override must not show ghost 9/10.
local nativeActionInfo=GetActionInfo
state.family='override' canExit=false
access:SetAttribute('cpf-override-limit',6)
access:Execute(Addon.TemporaryAccess.Response)
assert(not access.shown,'occupied backing slots outside native override capacity produced ghost 9/10')
access:SetAttribute('cpf-override-limit',12)
function GetActionInfo(action)
    if action>=129 and action<=132 then return nil end
    return nativeActionInfo(action)
end
access:Execute(Addon.TemporaryAccess.Response)
assert(not access.shown and not access.refs.action9.shown and not access.refs.action10.shown,'unqualified Darkmoon overflow remained visible')
function GetActionInfo(action) return 'spell',0 end
access:Execute(Addon.TemporaryAccess.Response)
assert(not access.shown,'zero spell identity qualified ghost overflow')
GetActionInfo=nativeActionInfo canExit=true state.family='vehicle'
access:Execute(Addon.TemporaryAccess.Response)
assert(Addon.SecureModes.Install(bridge,api) and created==6 and wrapCount==96,'access or native hooks duplicated')
combat=true
access:Execute([[local button=self:GetFrameRef('action9'); button:SetAttribute('cpf-held',true)]])
state.family='form' state.bonus=1
access:Execute(Addon.TemporaryAccess.Response)
assert(access.refs.action9.shown and access.refs.action9:GetAttribute('action')==129,'held action changed across mode transition')
access:Execute([[local button=self:GetFrameRef('action9'); button:SetAttribute('cpf-held',nil)]])
access:Execute(Addon.TemporaryAccess.Response)
assert(not access.refs.action9.shown and not access.refs.exit.shown,'ordinary form displayed temporary controls after release')
assert(not access.shown,'empty temporary parent remained a registered visible window')
state.family='vehicle' usable=false canExit=false
access:Execute(Addon.TemporaryAccess.Response)
assert(not access.refs.action9.shown and not access.refs.exit.shown,'empty overflow or unavailable exit was exposed')
assert(not access.shown)
access:Execute([[local button=self:GetFrameRef('exit'); button:SetAttribute('cpf-held',true)]])
access:Execute(Addon.TemporaryAccess.Response)
assert(access.shown,'held exit owner vanished before release')
access:Execute([[local button=self:GetFrameRef('exit'); button:SetAttribute('cpf-held',nil)]])
access:Execute(Addon.TemporaryAccess.Response)
assert(not access.shown,'released exit left an empty parent shown')
assert(not Addon.SecureModes.Disable(api,bridge),'combat performed insecure cleanup')
combat=false state.bonus=0
assert(Addon.SecureModes.Disable(api,bridge) and not access:GetAttribute('cpf-enabled'))
TEST_SUCCESS=true
