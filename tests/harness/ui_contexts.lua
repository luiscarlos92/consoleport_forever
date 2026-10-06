-- Full current ConsolePort Input, actual database script mixin, native click
-- wrapper/StaticPopup dispatch and StackSplit callbacks. Still no game engine.
local combat,trusted,hardware=false,false,false
local named,overrides,hooks={}, {}, {}
local wraps=0
local Frame={}
local function fire(frame,event,...)
    local script=frame.scripts[event]
    if script then script(frame,...) end
end
local function methodHook(object,key,fn)
    local original=object[key]
    object[key]=function(...)
        local result=original(...)
        fn(...)
        return result
    end
end
function hooksecurefunc(object,key,fn)
    if type(object)=='string' then
        fn=key key=object object=_G
        if key:match('^SetOverrideBinding') then
            local native=assert(object[key]) hooks[native]=hooks[native] or {}
            table.insert(hooks[native],fn) return
        end
    end
    assert(type(object[key])=='function','missing native hook method '..key)
    methodHook(object,key,fn)
end
function InCombatLockdown() return combat end
function Frame:Hide() local old=self.shown self.shown=false if old then fire(self,'OnHide') end end
function Frame:Show() local old=self.shown self.shown=true if not old then fire(self,'OnShow') end end
function Frame:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function Frame:IsForbidden() return false end
function Frame:IsProtected() return self.protected end
function Frame:GetName() return self.name end
function Frame:GetParent() return self.parent end
function Frame:HasScript(key) return ({OnShow=true,OnHide=true,OnEnable=true,OnDisable=true,OnMouseDown=true,OnMouseUp=true,OnClick=true,PostClick=true})[key] or false end
function Frame:GetScript(key) return self.scripts[key] end
function Frame:SetScript(key,fn) assert(not combat or not self.protected or trusted) self.scripts[key]=fn end
function Frame:HookScript(key,fn)
    local previous=self.scripts[key]
    self.scripts[key]=function(...) if previous then previous(...) end fn(...) end
end
function Frame:GetAttribute(key) return self.attributes[key] end
function Frame:SetAttribute(key,value) assert(not combat or not self.protected or trusted,'insecure protected attribute write') self.attributes[key]=value end
function Frame:SetFrameRef(key,value) assert(not combat) self.refs[key]=value end
function Frame:GetFrameRef(key) return self.refs[key] end
function Frame:RegisterForClicks(...) self.clicks={...} end
function Frame:SetButtonState(state) assert(not combat or not self.protected or trusted) self.buttonState=state end
function Frame:IsEnabled() return self.enabled end
function Frame:HasAccessConstraints() return false end
function Frame:HasAnyForbiddenAspects() return false end
function Frame:Click(button)
    assert(hardware,'protected click lacks hardware authority')
    if self:IsEnabled() then fire(self,'OnClick',button) end
end
function Frame:Enable() local was=self.enabled self.enabled=true if not was then fire(self,'OnEnable') end end
function Frame:Disable() local was=self.enabled self.enabled=false if was then fire(self,'OnDisable') end end
function Frame:SetText(text) self.text=text end
function Frame:GetText() return self.text end
function Frame:Clear() self.state=false end
function Frame:SetSize() end
function Frame:SetPoint() end
function Frame:ClearAllPoints() end
function Frame:SetShown(value) if value then self:Show() else self:Hide() end end
local rawFrames=setmetatable({},{__mode='k'})
local function proxy(frame)
    if not frame then return nil end
    -- No IsEnabled, mutable Lua fields or raw attribute frame userdata.
    local handle={GetAttribute=function(_,key)
        local v=frame:GetAttribute(key)
        if type(v)=='table' and v.attributes then return nil end
        return v
    end,SetAttribute=function(_,key,v) frame:SetAttribute(key,v) end,
        GetFrameRef=function(_,key) return proxy(frame:GetFrameRef(key)) end,
        IsShown=function() return frame:IsShown() end,
        Hide=function() frame:Hide() end,CallMethod=function(_,method) frame[method](frame) end,
        ChildUpdate=function(_,message,value)
            for _,child in ipairs(frame.children) do
                local body=child:GetAttribute('_childupdate-'..message)
                if body then
                    local fn=assert(load('return function(self,message) '..body..' end'))()
                    fn(proxy(child),value)
                end
            end
        end}
    rawFrames[handle]=frame
    return handle
end
local function SecureHandler_Other_Execute(header,frame,signature,body,...)
    if type(body)~='string' then return end
    local fn=assert(load('return function('..signature..',control) '..body..' end'))()
    local args={proxy(frame),...}
    local count=select('#',...)+2 args[count]=proxy(header)
    return fn(table.unpack(args,1,count))
end
local function IsWrapEligible() return true end
local function securecall(fn,...) return fn(...) end
local function SafeCallWrappedHandler(frame,fn,...) if fn then return fn(frame,...) end end
--@NATIVE_WRAPPED_CLICK
function Frame:WrapScript(frame,event,pre,post)
    assert(not combat) wraps=wraps+1
    local header=self
    local raw=frame:GetScript(event)
    frame:SetScript(event,function(self,button,down)
        local prior=trusted trusted=true
        local ok,reason=pcall(Wrapped_Click,self,header,pre,post,raw,button,down)
        trusted=prior assert(ok,reason)
    end)
end
function GetBindingAction(key,effective)
    if effective and overrides[key] then return overrides[key].action end
    return 'GAMEPLAY'
end
local invoking={}
local function invokeHooks(fn,...)
    if invoking[fn] then return end
    invoking[fn]=true
    for _,hook in ipairs(hooks[fn] or {}) do hook(...) end
    invoking[fn]=nil
end
function SetOverrideBindingClick(owner,priority,key,target,button)
    -- Native conflict hooks can reinstate their own row; suppress hook
    -- reentrance just as secure hook dispatch does in this host.
    overrides[key]={owner=owner,action='CLICK '..target..':'..button}
    invokeHooks(SetOverrideBindingClick,owner,priority,key,target,button)
end
for _,name in ipairs({'SetOverrideBinding','SetOverrideBindingItem','SetOverrideBindingMacro','SetOverrideBindingSpell'}) do
    local fn
    fn=function(owner,priority,key,action) overrides[key]={owner=owner,action=action} invokeHooks(fn,owner,priority,key,action) end
    _G[name]=fn
end
function ClearOverrideBindings(owner)
    for key,row in pairs(overrides) do if row.owner==owner then overrides[key]=nil end end
end
function IsBindingForGamePad(key) return key:find('PAD',1,true)~=nil end
function ExecuteFrameScript(frame,event,...) return fire(frame,event,...) end
local SECURE_ACTIONS={}
local Enum={ForbiddenAspect={ScriptedInput=1}}
local function SecureButton_GetModifiedAttribute(button,key) return button:GetAttribute(key) end
--@NATIVE_SECURE_CLICK
function CreateFrame(kind,name,parent,template)
    local frame=setmetatable({name=name,parent=parent,attributes={},refs={},scripts={},children={},enabled=true,shown=true,protected=template and template:find('Secure',1,true)~=nil or false},{__index=Frame})
    if name then named[name]=frame _G[name]=frame end
    if parent then parent.children[#parent.children+1]=frame end
    if template and template:find('SecureActionButtonTemplate',1,true) then
        frame:SetScript('OnClick',function(button,click,down)
            if not down and button:GetAttribute('typerelease')=='click' then
                local target=button:GetAttribute('clickbutton')
                assert(not rawFrames[target],'restricted handle used as native click delegate')
                SECURE_ACTIONS.click(button,nil,click)
            end
        end)
    end
    return frame
end
UIParent=CreateFrame('Frame','UIParent')
ConsolePort=CreateFrame('Frame','ConsolePort',UIParent)
function ConsolePort:ProcessInterfaceClickEvent() return false end
CPAPI={ActionTypeRelease='typerelease',ActionPressAndHold='pressAndHoldAction',
    CreateEventHandler=function(description,_,properties)
        local frame=CreateFrame(description[1],description[2],description[3],description[4])
        for key,value in pairs(properties) do frame[key]=value end
        return frame
    end}
local db={table={}}
function db:Register(key,value) self[key]=value end
function db:RegisterSafeCallback() end
function db:RegisterSafeCallbacks() end
function RegisterStateDriver() end
function UnregisterStateDriver() end
function RegisterAttributeDriver() end
function UnregisterAttributeDriver() end
function Mixin(target,other) for key,value in pairs(other) do target[key]=value end return target end
function newtable(...) return {...} end
function wipe(value) for key in pairs(value) do value[key]=nil end end
tremove=table.remove
format=string.format
string.trim=function(value) return value:match('^%s*(.-)%s*$') end
-- Full current Layers executes its own claim resolver. Only engine writes
-- and secure execution authority are host substitutes.
ConsolePortLayers=CreateFrame('Frame','ConsolePortLayers',UIParent,'SecureHandlerBaseTemplate')
CPAPI.DataHandler=function(frame) return frame end
CPAPI.SecureEnvironmentMixin={}
function CPAPI.SecureEnvironmentMixin:Execute(body)
    self.layerEnv=self.layerEnv or setmetatable({},{__index=_G})
    local fn=assert(load('return function(self,...) '..body..' end','native-claims','t',self.layerEnv))()
    local prior=trusted trusted=true
    local ok,result=pcall(fn,self)
    trusted=prior assert(ok,result) return result
end
function CPAPI.SecureEnvironmentMixin:CreateEnvironment()
    for key,body in pairs(self.Env) do self:SetAttribute(key,CPAPI.ConvertSecureBody(body)) end
end
function Frame:RunAttribute(key,...)
    local fn=assert(load('return function(self,...) '..self:GetAttribute(key)..' end','native-claim','t',self.layerEnv))()
    return fn(self,...)
end
function Frame:SetBindingClick(priority,key,target,button) SetOverrideBindingClick(self,priority,key,target,button) end
function Frame:SetBinding(priority,key,action) SetOverrideBinding(self,priority,key,action) end
function Frame:ClearBinding(key) if overrides[key] and overrides[key].owner==self then overrides[key]=nil end end
function Frame:CallMethod(key,...) return self[key](self,...) end
--@NATIVE_LAYER_CONVERSION
--@NATIVE_UI_LAYERS
--@CURRENT_SCRIPT_MIXIN
--@CURRENT_INPUT
local input=db.Input
local function press(widget,down,click)
    local prior=hardware hardware=true
    click=click or (widget:GetOverride(true) or widget:GetOverride(false) or {}).button or 'LeftButton'
    fire(widget,down and 'OnMouseDown' or 'OnMouseUp',click)
    fire(widget,'OnClick',click,down)
    fire(widget,'PostClick',click,down)
    hardware=prior
end
local parent=CreateFrame('Frame','ParentPanel',UIParent)
local parentClicks=0
input:SetCommand('PAD1',parent,true,'LeftButton','ParentControl',function(_,down) if not down then parentClicks=parentClicks+1 end end)
local nativeRow=input.Widgets.PAD1:GetOverride(true)
local api={CreateFrame=CreateFrame,UIParent=UIParent,CPAPI=CPAPI,hooksecurefunc=hooksecurefunc,
    InCombatLockdown=InCombatLockdown,GetBindingAction=GetBindingAction}
local bridge=Addon.InputBridge.New(input,api)
local popup=CreateFrame('Frame','Popup',UIParent)
local clicked,frontend=0,0
local target=CreateFrame('Button','PopupConfirm',popup)
target:SetScript('OnClick',function() assert(hardware) clicked=clicked+1 end)
target:SetScript('OnMouseUp',function() frontend=frontend+1 end)
local descriptor={frame=popup,token='first',routes={PAD1=target,PAD2=false}}
assert(bridge:Apply(descriptor))
local widget=input.Widgets.PAD1
assert(widget:GetOverride(true).owner==bridge.owner and widget:GetAttribute('typerelease')=='click')
press(widget,true) press(widget,false)
assert(clicked==1 and frontend==1 and parentClicks==0)
SetOverrideBindingClick(parent,true,'PAD1','Foreign','LeftButton')
assert(GetBindingAction('PAD1',true)=='CLICK '..widget:GetName()..':LeftButton','current CP conflict hook did not reinstate its native row')
local count=wraps assert(bridge:Apply(descriptor) and wraps==count,'repeated refresh duplicated wraps')
press(widget,true)
descriptor.token='reused-popup'
assert(bridge:Apply(descriptor))
press(widget,false)
assert(clicked==1 and frontend==1,'stale press activated reused popup')
press(widget,true)
assert(bridge:Release())
assert(widget:GetOverride(true)==nativeRow and widget:GetAttribute('owner')==parent,'same-priority parent row/owner was not restored')
press(widget,false)
assert(parentClicks==0,'delayed popup release reached the parent frontend')
press(widget,true) press(widget,false) assert(parentClicks==1)
assert(bridge:Apply(descriptor))
press(widget,true)
local newer=CreateFrame('Frame','KeyboardOwner',UIParent)
local newerClicks=0
input:SetCommand('PAD1',newer,true,'LeftButton','NewerControl',function(_,down) if not down then newerClicks=newerClicks+1 end end)
assert(bridge:Release())
press(widget,false) assert(newerClicks==0,'stale release reached a superseding owner')
assert(widget:GetOverride(true).owner==newer)
press(widget,true) press(widget,false) assert(newerClicks==1)
assert(bridge:Apply(descriptor))
press(widget,true) target:Disable() assert(bridge:Apply(descriptor)) press(widget,false)
assert(clicked==1,'disabled target activated')
target:Enable() assert(bridge:Apply(descriptor))
local nop=input.Widgets.PAD2 press(nop,true) press(nop,false)
assert(GetBindingAction('PAD2',true):find('CLICK',1,true) and parentClicks==1)

-- Insecure frontend and secure handler both stop during native combat pause.
press(widget,true)
combat=true trusted=true
input:SetAttribute('state-combat',true)
proxy(input):ChildUpdate('combat',true)
trusted=false
press(widget,false)
assert(clicked==1 and frontend==1)
assert(not bridge:Apply(descriptor))
assert(bridge:Release())
combat=false input:SetAttribute('state-combat',nil)

-- Context adapter selects the focused ancestry, never a merely visible frame.
local cursor=CreateFrame('Frame','NativeCursor',UIParent)
function cursor:GetCurrentNode() return self.node end
function cursor:SetCurrentNode(node) self.node=node end
function cursor:SetBasicControls() end
function cursor:Release() end
function cursor:OnEnterNode() end
function cursor:OnLeaveNode() end
db.Cursor=cursor
function StaticPopup_Show() end
local dialogs={}
StaticPopupDialogs={}
local atGlues=false
--@NATIVE_POPUP_CLICK
api.StaticPopup_ForEachShownDialog=function(fn) for _,dialog in ipairs(dialogs) do if dialog:IsShown() then fn(dialog) end end end
api.StackSplitFrame=CreateFrame('Frame','StackSplitFrame',UIParent)
local stack=api.StackSplitFrame StackSplitFrame=stack
--@NATIVE_STACK_SPLIT
for key,fn in pairs(StackSplitMixin) do stack[key]=fn end
stack.StackSplitText=CreateFrame('Frame',nil,stack)
function stack:UpdateStackText() self.StackSplitText:SetText(tostring(self.split)) end
stack.LeftButton=CreateFrame('Button','StackLeft',stack) stack.RightButton=CreateFrame('Button','StackRight',stack)
stack.OkayButton=CreateFrame('Button','StackOkay',stack) stack.CancelButton=CreateFrame('Button','StackCancel',stack)
stack.LeftButton:SetScript('OnClick',StackSplitLeftButton_OnClick) stack.RightButton:SetScript('OnClick',StackSplitRightButton_OnClick)
stack.OkayButton:SetScript('OnClick',StackSplitOkayButton_OnClick) stack.CancelButton:SetScript('OnClick',StackSplitCancelButton_OnClick)
stack:Hide()
popup.which='TEST' popup.data={} popup.data2=nil
popup.buttons={target,CreateFrame('Button','PopupCancel',popup),CreateFrame('Button','PopupThird',popup),CreateFrame('Button','PopupFourth',popup)}
popup.ExtraButton=CreateFrame('Button','PopupExtra',popup)
function popup:GetButton(index) return self.buttons[index] end
local semantic={0,0,0,0,0}
StaticPopupDialogs.TEST={selectCallbackByIndex=true}
for i=1,5 do
    local index=i
    local button=i==5 and popup.ExtraButton or popup.buttons[i]
    button:SetScript('OnClick',function() StaticPopup_OnClick(popup,index) end)
    StaticPopupDialogs.TEST[i==5 and 'OnExtraButton' or 'OnButton'..i]=function() semantic[index]=semantic[index]+1 return true end
end
dialogs={popup}
local contexts=Addon.UIContexts
contexts.input=bridge
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,true))
assert(not contexts.context,'visible nonfocused popup stole input')
cursor:SetCurrentNode(target)
assert(contexts.context.kind=='popup')
for index,key in ipairs({'PAD1','PAD2','PAD3','PAD4','PADRSTICK'}) do
    press(input.Widgets[key],true) press(input.Widgets[key],false)
    assert(semantic[index]==1,'semantic popup button index mismatch')
end
popup.buttons[3]:Hide()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(semantic[3]==1)
press(input.Widgets.PAD1,true)
popup.data={} contexts:Refresh()
press(input.Widgets.PAD1,false) assert(semantic[1]==1,'changed popup data accepted an old release')
local keyboard=CreateFrame('Frame','ConsolePortKeyboard',UIParent) api.ConsolePortKeyboard=keyboard
contexts:Refresh() assert(not contexts.context)
keyboard:Hide() assert(contexts.context.kind=='popup')
-- Modifiers retain semantic controls, with no saved-binding or gameplay path.
for _,modifier in ipairs({'SHIFT-','CTRL-','CTRL-SHIFT-'}) do
    press(input.Widgets[modifier..'PAD4'],true) press(input.Widgets[modifier..'PAD4'],false)
end
assert(semantic[4]==4)
-- A frontend callback can replace the popup while the button is held.
local before=semantic[1]
target:SetScript('OnMouseUp',function() popup.data={} contexts:Refresh() end)
press(input.Widgets.PAD1,true) press(input.Widgets.PAD1,false)
assert(semantic[1]==before,'frontend replacement leaked a secure click to its new owner')
target:SetScript('OnMouseUp',nil)
press(input.Widgets.PAD1,true) press(input.Widgets.PAD1,false) assert(semantic[1]==before+1)
-- Cursor loss cancels the press, then repeated reacquisition keeps one wrapper.
press(input.Widgets.PAD2,true) cursor:Hide()
press(input.Widgets.PAD2,false) assert(semantic[2]==1)
local acquiredWraps=wraps cursor:Show()
assert(wraps==acquiredWraps and contexts.context.kind=='popup')

local amount
stack.owner={SplitStack=function(_,value) assert(hardware) amount=value end}
stack.minSplit,stack.maxStack,stack.split=1,3,1
stack.LeftButton:Disable() stack.RightButton:Enable() stack:Show()
cursor:SetCurrentNode(stack.OkayButton)
assert(contexts.context.kind=='quantity')
for _=1,4 do press(input.Widgets.PADDRIGHT,true) press(input.Widgets.PADDRIGHT,false) end
assert(stack.split==3 and not stack.RightButton:IsEnabled())
for _=1,4 do press(input.Widgets.PADDLEFT,true) press(input.Widgets.PADDLEFT,false) end
assert(stack.split==1 and not stack.LeftButton:IsEnabled())
press(input.Widgets.PAD1,true) press(input.Widgets.PAD1,false)
assert(amount==1 and not stack:IsShown(),'quantity confirm did not use the actual native button callback')
cursor:SetCurrentNode(target) assert(contexts.context.kind=='popup','parent popup owner was not restored')
stack:Show() cursor:SetCurrentNode(stack.CancelButton)
press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false)
assert(amount==1 and not stack:IsShown(),'native cancel changed the selected amount')
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,false))
-- A partially rejected native update releases all installed CPF rows.
contexts.enabled=true cursor:SetCurrentNode(target)
local originalSetButton=input.SetButton
input.SetButton=function(self,key,...)
    if key=='CTRL-PAD4' then error('injected native input rejection') end
    return originalSetButton(self,key,...)
end
assert(not contexts:Refresh(true))
for _,state in pairs(bridge.states) do
    assert(not state.widget:HasOwner(bridge.owner),'rejected setup retained CPF ownership')
end
assert(Addon.Diagnostics.features.uiContexts.status=='recovery-required')
input.SetButton=originalSetButton
assert(contexts:Refresh(true))
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,false))
TEST_SUCCESS=true
