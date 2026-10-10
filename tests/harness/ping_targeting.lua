TEST_SUCCESS=nil
unpack=table.unpack
string.trim=function(text) return text:match('^%s*(.-)%s*$') end
math.atan2=math.atan2 or math.atan
-- Native secure wrappers, action/macro dispatch, ConsolePort Layers/Radial,
-- and Blizzard macro ping manager execute unchanged. The Retail engine APIs,
-- macro parser, cursor/CVar timing, art and hardware events are modeled.
local combat, trusted, hardware=false,false,false
local clock=0
function GetTime() return clock end
CPPieMenuMixin={}
local frames, overrides,allFrames={}, {},{}
local secureScripts=setmetatable({},{__mode='k'})
local Frame={}
local function fire(frame,event,...)
    local fn=frame.scripts[event]
    if not fn then return end
    local prior=trusted
    if fn~=SecureActionButton_OnClick and not secureScripts[fn] then trusted=false end
    local result={pcall(fn,frame,...)}
    trusted=prior assert(result[1],result[2])
    return table.unpack(result,2)
end
local function copy(...) local out={} for i=1,select('#',...) do for k,v in pairs(select(i,...)) do out[k]=v end end return out end
CreateFromMixins=copy
function Mixin(frame,...) for k,v in pairs(copy(...)) do frame[k]=v end return frame end
function InCombatLockdown() return combat end
function Frame:GetName() return self.name end
function Frame:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function Frame:IsProtected() return self.protected end
function Frame:IsForbidden() return false end
function Frame:Show()
    assert(not combat or not self.protected or trusted,'insecure protected Show')
    if not self.shown then self.shown=true fire(self,'OnShow') end
end
function Frame:Hide()
    assert(not combat or not self.protected or trusted,'insecure protected Hide')
    if self.shown then self.shown=false fire(self,'OnHide') end
end
function Frame:GetAttribute(key) return self.attrs[key] end
function Frame:SetAttribute(key,value)
    assert(not combat or not self.protected or trusted,'insecure protected attribute write')
    local old=self.attrs[key] self.attrs[key]=value
    if old~=value then fire(self,'OnAttributeChanged',key,value) end
end
function Frame:SetFrameRef(key,value) assert(not combat) self.refs[key]=value end
function Frame:GetFrameRef(key) return self.refs[key] end
function Frame:SetScript(key,fn) assert(not combat or not self.protected or trusted) self.scripts[key]=fn end
function Frame:GetScript(key) return self.scripts[key] end
function Frame:HookScript(key,fn)
    local before=self.scripts[key]
    self.scripts[key]=function(...) if before then before(...) end return fn(...) end
end
function Frame:HasScript(key)
    return ({OnShow=true,OnHide=true,OnUpdate=true,OnClick=true,OnLoad=true,OnEvent=true,
        OnGamePadStick=true,OnGamePadButtonDown=true,OnGamePadButtonUp=true,
        OnAttributeChanged=true,PreClick=true,PostClick=true})[key] or false
end
function Frame:RegisterForClicks(...) self.clicks={...} end
function Frame:SetSize(x,y) self.w,self.h=x,y end
function Frame:SetWidth(x) self.w=x end
function Frame:SetHeight(y) self.h=y end
function Frame:GetWidth() return self.w or 400 end
function Frame:GetHeight() return self.h or 400 end
function Frame:GetSize() return self:GetWidth(),self:GetHeight() end
function Frame:UpdateColorSettings() self.nativeColors=true end
function Frame:UpdatePieSlices(shown,count) self.nativeSlices=shown and (count or self:GetNumVisible()) or 0 end
function Frame:UpdateBackgroundFocus(index) self.nativeFocus=index end
function Frame:ReflectStickPosition(x,y,len,valid) self.nativeStick={x=x,y=y,len=len,valid=valid} end
function Frame:SetActiveSliceText(text) self.activeSliceText=text end
function Frame:SetScale(value) self.scale=value end
function Frame:SetPoint(...) self.point={...} end
function Frame:ClearAllPoints() end
function Frame:SetAlpha(value) self.alpha=value end
function Frame:EnableGamePadStick(value) self.stickEnabled=value end
function Frame:EnableGamePadButton(value) self.buttonEnabled=value end
function Frame:SetPropagateKeyboardInput(value) self.propagate=value end
function Frame:SetFrameStrata(value) self.strata=value end
local Region={SetAllPoints=function() end,SetPoint=function() end,SetAtlas=function(self,value) self.atlas=value end,
    SetSize=function(self,x,y) self.size={x,y} end,SetTexture=function(self,value) self.texture=value end,
    AddMaskTexture=function(self,mask) self.mask=mask end,SetAlpha=function(self,value) self.alpha=value end,
    SetRotation=function(self,value) self.rotation=value end,SetShown=function(self,value) self.shown=value end,
    SetVertexColor=function(self,r,g,b) self.color={r,g,b} end,SetText=function(self,value) self.text=value end}
function Frame:CreateTexture() return setmetatable({},{__index=Region}) end
function Frame:CreateMaskTexture() return setmetatable({},{__index=Region}) end
function Frame:CreateFontString() return setmetatable({},{__index=Region}) end
function Frame:RegisterEvent() end
function Frame:UnregisterEvent() end
local mapped={name='controller',buttons={[10]=false},sticks={[2]={x=0,y=0,len=0}}}
function GetGamePadState() return mapped end
C_GamePad={GetDeviceMappedState=function() return mapped end}
local units={}
function UnitExists(unit) return units[unit]~=nil end
function UnitGUID(unit) return units[unit] end
function SetGamePadCursorControl(value) end
local cvars={GamePadCursorCentering='0',ActionButtonUseKeyDown='1',ActionButtonUseKeyHeldSpell='0',pingMode='0'}
function GetCVar(key) return cvars[key] end
function GetCVarBool(key) return cvars[key]=='1' end
local cursorX,cursorY=10,10
local centeringSynchronous=true
function SetCVar(key,value)
    cvars[key]=tostring(value)
    if key=='GamePadCursorCentering' and centeringSynchronous and value=='1' then cursorX,cursorY=500,360 end
end
function GetCursorPosition() return cursorX,cursorY end
function GetScaledCursorPosition_Insecure() return cursorX,cursorY end
function securecallfunction(fn,...) return fn(...) end
function securecall(fn,...) return fn(...) end
local function SafeCallWrappedHandler(frame,fn,...)
    if not fn then return end
    local prior=trusted
    if fn~=SecureActionButton_OnClick then trusted=false end
    local result={pcall(fn,frame,...)}
    trusted=prior assert(result[1],result[2])
    return table.unpack(result,2)
end
local handleCache=setmetatable({},{__mode='k'})
local frameHandles=setmetatable({},{__mode='k'})
local proxy
proxy=function(frame)
    if not frame then return nil end
    if handleCache[frame] then return handleCache[frame] end
    local handle={}
    for _,name in ipairs({'GetName','IsProtected','GetAttribute','SetAttribute','IsShown','Show','Hide','GetWidth','GetHeight','SetWidth','SetHeight','SetPoint','SetScale','ClearAllPoints','RunAttribute'}) do
        handle[name]=function(_,...)
            assert(name=='GetName' or name=='IsProtected' or not combat or frame.protected,'restricted unprotected handle in combat')
            return frame[name](frame,...)
        end
    end
    handle.GetFrameRef=function(_,key) return proxy(frame:GetFrameRef(key)) end
    handle.CallMethod=function(_,name,...)
        local prior=trusted trusted=false
        local ok,error=pcall(frame[name],frame,...)
        trusted=prior assert(ok,error)
        -- Native CallMethod discards return values and forces callback insecure.
    end
    handle.SetBindingClick=function(_,priority,key,target,button) overrides[key]={action='CLICK '..target..':'..button,owner=frame} end
    handle.SetBinding=function(_,priority,key,action) overrides[key]={action=action,owner=frame} end
    handle.ClearBinding=function(_,key) if overrides[key] and overrides[key].owner==frame then overrides[key]=nil end end
    handle.ChildUpdate=function() end
    handleCache[frame]=handle frameHandles[handle]=true return handle
end
function newtable(...) return {...} end
function wipe(t) for key in pairs(t) do t[key]=nil end end
tremove=table.remove
local restricted={math=math,string=string,tonumber=tonumber,tostring=tostring,type=type,select=select,
    pairs=pairs,ipairs=ipairs,unpack=table.unpack,newtable=newtable,wipe=wipe,tremove=tremove,
    GetGamePadState=GetGamePadState,UnitExists=UnitExists,format=string.format,SecureCmdOptionParse=function() end}
-- Only the host's Lua 5.1 compatibility boundary is substituted. These helpers
-- are private to the fixture and absent from every restricted environment.
local loadstring_untainted=function(body) return load(body,'restricted-ping','t',{}) end
local setfenv=function(fn,env) return CPFSetFunctionEnvironment(fn,env) end
local IsFrameHandle=function(value) return frameHandles[value]==true end
local scrub=function(...) return ... end
--@NATIVE_RESTRICTED_COMPILER
local function restrictedCall(frame,signature,body,...)
    frame.secureEnv=frame.secureEnv or copy(restricted)
    local fn,reason=BuildRestrictedClosure(body,frame.secureEnv,signature)
    assert(fn,reason)
    local prior=trusted trusted=true
    local result={pcall(fn,...)} trusted=prior
    assert(result[1],result[2]) return table.unpack(result,2)
end
function Frame:Execute(body) assert(not combat) return restrictedCall(self,'self',body,proxy(self)) end
function Frame:RunAttribute(name,...) return restrictedCall(self,'self,...',assert(self:GetAttribute(name),'missing attribute '..name),proxy(self),...) end
local function SecureHandler_Other_Execute(header,frame,signature,body,...)
    local args={proxy(frame),...}
    args[select('#',...)+2]=proxy(header)
    return restrictedCall(header,signature..',control',body,table.unpack(args,1,select('#',...)+2))
end
local function IsWrapEligible(frame) return not combat or frame:IsProtected() end
--@NATIVE_WRAPPED_CLICK
--@NATIVE_WRAPPED_OTHER
function Frame:WrapScript(frame,event,pre,post)
    assert(not combat)
    local header=self local original=frame.scripts[event]
    if event=='PreClick' or event=='PostClick' then
        frame.scripts[event]=function(this,button,down) return Wrapped_Click(this,header,pre,post,original,button,down) end
    else
        local wrapper=event=='OnAttributeChanged' and Wrapped_Attribute or Wrapped_ShowHide
        frame.scripts[event]=function(this,...) return wrapper(this,header,pre,post,original,...) end
    end
    secureScripts[frame.scripts[event]]=true
end
local SECURE_ACTIONS={}
local function SecureButton_GetModifiedAttribute(frame,key) return frame:GetAttribute(key) end
local function SecureButton_GetAttribute(frame,key) return frame:GetAttribute(key) end
local function SecureButton_GetModifiedUnit() return nil end
local function SpellCanTargetItem() return false end
local function SpellCanTargetItemID() return false end
function forceinsecure() trusted=false end
--@NATIVE_ACTION_DISPATCH
function CreateFrame(kind,name,parent,template)
    local frame=setmetatable({name=name,parent=parent,attrs={},refs={},scripts={},shown=true,protected=template and template:find('Secure')~=nil or false},{__index=Frame})
    if name then frames[name]=frame _G[name]=frame end
    allFrames[#allFrames+1]=frame
    if kind=='PieMenu' then
        frame.isSlicedPie=true
        local function slice()
            local value={parent=frame,RectMask1=frame:CreateTexture(),RectMask2=frame:CreateTexture(),Separator1=frame:CreateTexture(),Separator2=frame:CreateTexture(),Slice=frame:CreateTexture()}
            function value:GetParent() return self.parent end
            function value:SetID(id) self.id=id end
            function value:SetSize(x,y) self.w,self.h=x,y end
            function value:SetPoint(...) self.point={...} end
            function value:SetOpacity(alpha) self.alpha=alpha end
            function value:Show() self.shown=true end
            function value:SetText() end function value:SetTextAlpha() end function value:SetTextSize() end
            function value:SynchronizeAnimation() end function value:RotateLines(angle) self.center=angle end
            return setmetatable(value,{__index=CPPieSliceMixin})
        end
        frame.ActiveSlice=slice()
        frame.SlicePool={active={}}
        function frame.SlicePool:ReleaseAll() self.active={} end
        function frame.SlicePool:Acquire() local value=slice() self.active[#self.active+1]=value return value,true end
        frame.UpdatePieSlices=function(self,shown,count)
            CPPieMenuMixin.UpdatePieSlices(self,shown,count)
            self.sliceCalls=(self.sliceCalls or '')..tostring(shown)..':'..tostring(count)..':'..tostring(#self.SlicePool.active)..';'
        end
    end
    frame.template=template
    if template and (template:find('SecureActionButton') or template:find('ConsolePortSecurePie')) then frame:SetScript('OnClick',SecureActionButton_OnClick) end
    return frame
end
UIParent=CreateFrame('Frame','UIParent')
ConsolePort=CreateFrame('Frame','ConsolePort',UIParent)
ConsolePortLayers=CreateFrame('Frame','ConsolePortLayers',UIParent,'SecureHandlerStateTemplate')
ConsolePortRadial=CreateFrame('Frame','ConsolePortRadial',UIParent,'SecureHandlerStateTemplate')
local db={Locale=setmetatable({},{__call=function(_,text) return text end}),table={mixin=Mixin},Gamepad={Index={Modifier={Active={},Prefix={},Blocked={}}}}}
local nativeSettings={radialScale=1,radialPreferredSize=360,radialActionDeadzone=.5,radialCosineDelta=-1,radialPrimaryStick='Camera',radialClearFocusMode=1,radialClearFocusDeadzone=.2,radialClearFocusTime=.1}
setmetatable(db,{__call=function(_,key) return nativeSettings[key] end})
function db:Register(key,value) self[key]=value return value end
function db:RegisterSafeCallback() end
function db:RegisterSafeCallbacks() end
function db:TriggerEvent() end
function db:For() return function() end end
function db.Gamepad:GetBindings() return {PADRSTICK={['']='TOGGLEPINGLISTENER',['CTRL-']='TOGGLEPINGLISTENER'}} end
function RegisterStateDriver(frame,id,driver)
    frame.stateDrivers=frame.stateDrivers or {} frame.stateDrivers[id]=driver
    frame:SetAttribute('state-'..id,combat and 'combat' or 'peace')
    if frame:GetAttribute('_onstate-'..id) then frame:RunAttribute('_onstate-'..id,id,combat and 'combat' or 'peace') end
end
function UnregisterStateDriver() end
function RegisterAttributeDriver() end
function UnregisterAttributeDriver() end
function tInvert(t) local out={} for key,value in pairs(t) do out[value]=key end return out end
function cos(a) return math.cos(math.rad(a)) end
function sin(a) return math.sin(math.rad(a)) end
function nop() end
C_Timer={NewTimer=function(_,fn) return {Cancel=function() end,fn=fn} end}
CPAPI={ActionPressAndHold='pressAndHoldAction',DataHandler=function(frame) return frame end,GetAsset=function(path) return 'Interface/AddOns/ConsolePort/Assets/'..path end}
--@CURRENT_PIE_STYLE
function CPAPI.Start(frame) for key,fn in pairs(frame) do if type(fn)=='function' and frame:HasScript(key) then frame:SetScript(key,fn) end end end
local dispatcher
local originalStart=CPAPI.Start
function CPAPI.Start(frame) if frame.OnGamePadStick and frame.RaiseBlocker then dispatcher=frame end return originalStart(frame) end
--@CURRENT_CONVERSION
--@CURRENT_SECURE_ENV
--@CURRENT_SCRIPT_MIXIN
--@CURRENT_LAYERS
--@CURRENT_RADIAL
db.Radial:OnDataLoaded()
db.Radial:Execute([[STIX.Right=2 STIX.Camera=2 BTNS.PADRSTICK=10 BTNS[10]='PADRSTICK' BTNS.PAD2=2 BTNS[2]='PAD2']])
db.Layers:Execute([[ENABLED=true]])
local function savedBinding(key) return (key=='PADRSTICK' or key=='CTRL-PADRSTICK' or key=='F2') and 'TOGGLEPINGLISTENER' or 'GAMEPLAY' end
function GetBindingAction(key,effective) return effective and overrides[key] and overrides[key].action or savedBinding(key) end
local boundKeys={'PADRSTICK','CTRL-PADRSTICK','F2'}
function GetBindingKey(action) assert(action=='TOGGLEPINGLISTENER') return table.unpack(boundKeys) end
local nativeOwners={Layers=db.Layers,Radial=db.Radial,Gamepad=db.Gamepad}
setmetatable(nativeOwners,{__call=function(_,key) return db(key) end})
for _,name in ipairs({'Cursor','Raid','TargetRing'}) do nativeOwners[name]=CreateFrame('Frame',name,UIParent,name~='Cursor' and 'SecureHandlerBaseTemplate' or nil) nativeOwners[name]:Hide() end
local bridge={api={version='3.3.10'},db=nativeOwners}
Addon.adapters={consoleport=bridge}
Enum={PingSetTargetState={Failed=0,Ok=1},PingResult={Success=0},PingSubjectType={Attack=0,Warning=1,OnMyWay=2,Assist=3,AlertNotThreat=4,AlertThreat=5}}
PING_FAILED_GENERIC="Can't ping this"
local sent,errors,uiChecks,hitTests={},0,0,{}
local worldValid=true
C_PingSecure={
    SetHitTestPingTarget=function(x,y,forcePoint)
        assert(trusted and hardware,'insecure privileged hit test')
        hitTests[#hitTests+1]={x=x,y=y,forcePoint=forcePoint}
        return worldValid and Enum.PingSetTargetState.Ok or Enum.PingSetTargetState.Failed
    end,
    SendUnitPing=function(guid,type) assert(trusted and hardware) sent[#sent+1]={guid=guid,type=type} return {result=0,type=type} end,
    SendHitTestPing=function(type) assert(trusted and hardware) sent[#sent+1]={type=type,point=true} return {result=0,type=type} end,
    DisplayError=function(message) assert(message==PING_FAILED_GENERIC) errors=errors+1 end,
    ClearHitTestPingInfo=function() end,
}
function GetPingResultString() return PING_FAILED_GENERIC end
function GetTargetPingReceiverInfo() uiChecks=uiChecks+1 return {frameFound=true,isPingable=false} end
PingManager={ShowPingSpot=function() end}
--@NATIVE_PING_METHODS
local securePingSlash
SlashCommandUtil={CheckAddSecureSlashCommand=function(_,_,fn) securePingSlash=fn end}
SLASH_COMMAND={PING=1} SLASH_COMMAND_CATEGORY={PING=1}
function strupper(text) return string.upper(text) end
PING_TYPE_ATTACK='Attack' PING_TYPE_WARNING='Warning' PING_TYPE_ON_MY_WAY='OnMyWay' PING_TYPE_ASSIST='Assist' PING_TYPE_NOT_THREAT='NonThreat' PING_TYPE_THREAT='Threat'
function SecureCmdOptionParse(text)
    local condition,type=text:match('^%[@([^%]]+)%]%s*(.*)$')
    if not condition then return nil,nil end
    local token=condition:match('^[^,]+')
    if condition:find(',exists',1,true) and not UnitExists(token) then return nil,nil end
    return type,token
end
C_Ping={SendMacroPing=function(info) assert(trusted and hardware,'ADDON_ACTION_FORBIDDEN: C_Ping.SendMacroPing') return PingManager:SendMacroPing(info) end}
--@NATIVE_PING_SLASH
C_Macro={RunMacroText=function(text)
    assert(trusted and hardware,'insecure macro execution')
    for line in text:gmatch('[^\n]+') do
        local value=line:match('^/console GamePadCursorCentering (%d)$')
        if value then SetCVar('GamePadCursorCentering',value)
        else local args=assert(line:match('^/ping (.*)$'),'unexpected macro line '..line) securePingSlash(args) end
    end
end}
local Ping=Addon.PingTargeting
-- The shipped candidate.24 failed before any input body could execute: its raw
-- owner list was a Lua table literal, forbidden by Blizzard's actual compiler.
local candidate24Pre=Ping.Pre:gsub("newtable%('Cursor','Raid','TargetRing'%)","{'Cursor','Raid','TargetRing'}")
local oldClosure,oldError=BuildRestrictedClosure(candidate24Pre,copy(restricted),'self,button,down')
assert(not oldClosure and oldError=='Direct table creation is not permitted','candidate24 forbidden raw-table input was not reproduced')
local fixedClosure,fixedError=BuildRestrictedClosure(Ping.Pre,copy(restricted),'self,button,down')
assert(fixedClosure and not fixedError,'current ping input rejected by native compiler: '..tostring(fixedError))
local keywordClosure,keywordError=BuildRestrictedClosure('function accidental() end',copy(restricted),'self')
assert(not keywordClosure and keywordError=='The function keyword is not permitted','native compiler accepted function keyword')
local signatureClosure,signatureError=BuildRestrictedClosure('return self',copy(restricted),'self; invalid')
assert(not signatureClosure and signatureError:find('Signature contains invalid characters',1,true),'native compiler accepted malformed signature')
-- Every factory starts in its own empty environment before the actual compiler
-- installs the restricted environment. Neither host shims nor globals escape.
local envA=copy(restricted,{probe='A'}) local envB=copy(restricted,{probe='B'})
local isolatedA=assert(BuildRestrictedClosure('return probe, CPFSetFunctionEnvironment, debug, load, _G',envA,'self'))
local isolatedB=assert(BuildRestrictedClosure('return probe',envB,'self'))
local valueA,shim,debugAccess,loader,globals=isolatedA(nil)
assert(valueA=='A' and isolatedB(nil)=='B' and isolatedA(nil)=='A','native compiler environments shared host state')
assert(not shim and not debugAccess and not loader and not globals,'host compiler adapter leaked into restricted environment')
local selfOnly=assert(BuildRestrictedClosure('return self',copy(restricted),'self'))
assert(selfOnly(UIParent)==nil and selfOnly(proxy(UIParent))==proxy(UIParent),'native SelfScrub accepted raw frame or rejected qualified handle')
local function click(key,down)
    hardware=true trusted=true
    local physical=key:match('([^%-]+)$')
    local id=physical=='PAD2' and 2 or 10
    if mapped and mapped.buttons then mapped.buttons[id]=down end
    local action=GetBindingAction(key,true)
    local target,button=action:match('^CLICK ([^:]+):(.+)$')
    if target then
        local frame=assert(frames[target])
        fire(frame,'PreClick',button,down)
        fire(frame,'OnClick',button,down,true,true)
        fire(frame,'PostClick',button,down)
    end
    trusted=false hardware=false
end
local function vector(index)
    if not index then mapped.sticks[2]={x=0,y=0,len=0} return end
    local angle=(index-1)*2*math.pi/6
    mapped.sticks[2]={x=math.sin(angle),y=math.cos(angle),len=1}
end
assert(not nativeOwners.Cursor:IsProtected(),'fixture incorrectly protected native UI cursor')
assert(Ping:Refresh(_G,true,bridge),'qualified unprotected UI cursor prevented ping startup')
for _,setting in ipairs({'layersTapLatch','layersDoubleBar','layersOrdered'}) do
    nativeSettings[setting]=true
    local ready,reason=Ping:Refresh(_G,true,bridge)
    assert(not ready and reason:find('standard native modifier layers',1,true),'unsupported native layer mode qualified: '..setting)
    assert(GetBindingAction('PADRSTICK',true)=='TOGGLEPINGLISTENER','unsupported layer mode claimed binding')
    nativeSettings[setting]=nil
end
assert(Ping:Refresh(_G,true,bridge),'standard native ping failed to resume after unsupported modes')
assert(not Ping.frame:IsShown() and dispatcher and not dispatcher.focusFrame and not dispatcher.stickEnabled,'setup stole stick focus')
assert(savedBinding('PADRSTICK')=='TOGGLEPINGLISTENER' and GetBindingAction('F2',true)=='TOGGLEPINGLISTENER')
click('PADRSTICK',true)
assert(Ping.frame.alpha==0,'tap displayed the ping ring on press')
clock=clock+.149 fire(Ping.frame,'OnUpdate',.149)
assert(Ping.frame.alpha==0,'ping ring appeared before hold threshold')
clock=clock+.002 fire(Ping.frame,'OnUpdate',.002)
assert(Ping.frame.alpha==1 and #Ping.frame.SlicePool.active==6 and Ping.frame.nativeColors,'hold did not display native ConsolePort sliced ring: '..tostring(Ping.frame.alpha)..'/'..tostring(#Ping.frame.SlicePool.active)..'/'..tostring(Ping.frame.sliceCalls))
for index,slice in ipairs(Ping.frame.SlicePool.active) do
    assert(slice.id==index and slice.RectMask1.shown and slice.RectMask2.shown and slice.w==Ping.frame:GetWidth()*512/300,'native six-slice geometry/masks missing')
end
assert(Ping.frame.template=='ConsolePortSecurePie,ConsolePortSlicedPie' and not Ping.frame.cpfHint,'floating custom selector retained')
assert(Ping.frame.cpfIcons[1].border.atlas=='ring-metallight' and Ping.frame.cpfIcons[1].selected.atlas=='ring-select' and Ping.frame.cpfIcons[1].icon.mask,'native ring icon skin missing')
assert(Ping.frame:IsShown() and cvars.GamePadCursorCentering=='0','holding ping changed cursor')
assert(dispatcher.focusFrame==Ping.frame and dispatcher.stickEnabled,'native radial did not own stick while held')
dispatcher:OnGamePadStick('Right',0,1,1)
assert(dispatcher.pending.Camera,'raw camera stick was not consumed')
local blocker
for _,candidate in ipairs(allFrames) do
    if candidate.strata=='TOOLTIP' and candidate.scripts.OnGamePadStick then blocker=candidate end
end
assert(blocker and blocker:IsShown(),'native virtual-stick blocker unavailable')
fire(blocker,'OnGamePadStick','Camera',0,1,1)
assert(not dispatcher.pending.Camera and not blocker:IsShown(),'native virtual Camera stick did not lower blocker')
dispatcher:OnFrameEnd()
assert(GetBindingAction('PAD2',true):find(':Cancel',1,true),'controller cancel not modal')
click('PADRSTICK',false)
assert(#sent==1 and sent[1].point and sent[1].type==nil,'contextual point tap not sent')
assert(hitTests[1].forcePoint and hitTests[1].x==500 and hitTests[1].y==360 and uiChecks==0,'point ping used parked UI receiver')
assert(cvars.GamePadCursorCentering=='0' and not Ping.frame:IsShown() and not Ping.frame:GetAttribute('cpf-trigger'),'release did not restore/clear')
assert(not dispatcher.focusFrame and not dispatcher.stickEnabled and next(dispatcher.pending)==nil,'native camera focus leaked after release')
for _,keydown in ipairs({'0','1'}) do
    for _,held in ipairs({'0','1'}) do
        cvars.ActionButtonUseKeyDown=keydown cvars.ActionButtonUseKeyHeldSpell=held
        local before=#sent
        click('PADRSTICK',true)
        assert(#sent==before,'ping dispatched on down with action-button CVar combination')
        click('PADRSTICK',false)
        assert(#sent==before+1 and sent[#sent].point and sent[#sent].type==nil,'native release lost/doubled ping with action-button CVar combination')
        assert(cvars.GamePadCursorCentering=='0' and not dispatcher.focusFrame,'action-button CVar combination leaked cursor/focus')
    end
end
cvars.ActionButtonUseKeyDown='1' cvars.ActionButtonUseKeyHeldSpell='0'
for index=1,6 do
    vector(index) local count=#sent
    click('PADRSTICK',true) click('PADRSTICK',false)
    assert(Ping.frame.alpha==0,'deflected-stick tap displayed selector')
    assert(#sent==count+1 and sent[#sent].type==index-1,'selected ping type not dispatched: '..index)
end
vector(nil)
units.softenemy='aimed-enemy' units.target='stale-offscreen-hard-target'
cursorX,cursorY=10,10
click('PADRSTICK',true) click('PADRSTICK',false)
assert(sent[#sent].guid=='aimed-enemy' and cursorX==10 and cvars.GamePadCursorCentering=='0','soft target used hard target or centered')
units.softenemy=nil units.softfriend='aimed-friend'
click('PADRSTICK',true) click('PADRSTICK',false)
assert(sent[#sent].guid=='aimed-friend','friendly aimed unit lost') units.softfriend=nil
-- Unit disappearance during the same hardware release must not reuse a prior
-- hit test. The macro conditional is reevaluated by the native dispatcher.
units.softenemy='ephemeral-enemy'
click('PADRSTICK',true)
local disappearedCount=#sent
mapped.buttons[10]=false hardware=true trusted=true
fire(Ping.frame,'PreClick','PADRSTICK',false)
units.softenemy=nil
fire(Ping.frame,'OnClick','PADRSTICK',false,true,true)
fire(Ping.frame,'PostClick','PADRSTICK',false)
hardware=false trusted=false
assert(#sent==disappearedCount,'vanished aimed unit fell back to stale hit test')
-- Invalid terrain is a real error, never fabricated success/fallback.
worldValid=false local count=#sent local beforeErrors=errors
click('PADRSTICK',true) click('PADRSTICK',false)
assert(#sent==count and errors==beforeErrors+1 and cvars.GamePadCursorCentering=='0','invalid terrain incorrectly accepted') worldValid=true
-- Circle cancel consumes down/up and a later R3 release emits nothing.
count=#sent click('PADRSTICK',true) click('PAD2',true) click('PAD2',false) click('PADRSTICK',false)
assert(#sent==count and not Ping.frame:IsShown(),'controller cancel sent delayed ping')
-- Foreign modal takeover securely cancels even after it releases its own claim.
click('PADRSTICK',true)
assert(db.Layers:Claim('foreign','MODAL','PADRSTICK','binding','FOREIGN_MODAL'))
assert(not Ping.frame:IsShown(),'foreign modal takeover did not cancel')
db.Layers:ReleaseAll('foreign') click('PADRSTICK',false)
assert(#sent==count,'stale modal release sent ping')
for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
    nativeOwners[name]:Show() click('PADRSTICK',true) click('PADRSTICK',false) nativeOwners[name]:Hide()
    assert(#sent==count and not Ping.frame:IsShown(),'active UI owner pinged world: '..name)
end
-- A different radial can take the shared right-stick dispatcher without owning
-- the ping key. Its selection must never be committed by a later R3 release.
local otherRadial=CreateFrame('Button','OtherNativeRadial',UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
Mixin(otherRadial,CPAPI.AdvancedSecureMixin) otherRadial:Hide()
db.Radial:Register(otherRadial,'OtherNative',{sticks={'Right','Camera'},sizer=[[local size=4;]]})
otherRadial:SetScript('OnShow',otherRadial.OnShow) otherRadial:SetScript('OnHide',otherRadial.OnHide)
assert(Ping:Refresh(_G,true,bridge))
click('PADRSTICK',true)
trusted=true otherRadial:Show() trusted=false
assert(not Ping.frame:IsShown(),'other native radial did not cancel ping gesture')
assert(dispatcher.focusFrame==otherRadial,'ping cleanup stole other radial focus')
click('PADRSTICK',false)
assert(#sent==count,'other radial selection committed as ping')
click('PADRSTICK',true) click('PADRSTICK',false)
assert(#sent==count and dispatcher.focusFrame==otherRadial,'ping started over another radial')
trusted=true otherRadial:Hide() trusted=false
otherRadial:ClearInstantly()
local otherShowHook=otherRadial:GetScript('OnShow')
assert(Ping:Refresh(_G,true,bridge))
assert(otherRadial:GetScript('OnShow')==otherShowHook,'radial ownership wrapper duplicated on refresh')
-- Closing the other ring before R3's old release must not resurrect the ping.
click('PADRSTICK',true)
trusted=true otherRadial:Show() otherRadial:Hide() trusted=false
otherRadial:ClearInstantly()
click('PADRSTICK',false)
assert(#sent==count and not Ping.frame:IsShown(),'closed other radial resurrected delayed ping')
-- The ownership transfer is secure in combat and does not clear the new native
-- owner's dispatcher focus. No public protected writes are permitted here.
combat=true trusted=true Ping.frame:SetAttribute('state-cpf-combat','combat') trusted=false
click('PADRSTICK',true)
hardware=true trusted=true otherRadial:Show() hardware=false trusted=false
assert(not Ping.frame:IsShown() and dispatcher.focusFrame==otherRadial,'combat radial takeover lost new owner or retained ping')
click('PADRSTICK',false) assert(#sent==count,'combat other radial committed ping')
hardware=true trusted=true otherRadial:Hide() hardware=false trusted=false
otherRadial:ClearInstantly()
combat=false trusted=true Ping.frame:SetAttribute('state-cpf-combat','peace') trusted=false
-- A lost Up never blocks refresh, and a fresh Down replaces the stale gesture.
click('PADRSTICK',true) click('PADRSTICK',true) click('PADRSTICK',false)
assert(#sent==count+1,'repeated/new down failed to replace stale gesture') count=#sent
click('PADRSTICK',true) assert(Ping:Refresh(_G,true,bridge)) click('PADRSTICK',false)
assert(#sent==count,'refresh did not cancel lost release')
-- A disconnected device cannot dispatch on release; fresh hardware arms anew.
click('PADRSTICK',true) local previous=mapped mapped=nil click('PADRSTICK',false) mapped=previous
assert(#sent==count and not Ping.frame:IsShown(),'disconnected release sent ping')
combat=true
trusted=true Ping.frame:SetAttribute('state-cpf-combat','combat') trusted=false
click('PADRSTICK',true) previous=mapped mapped=nil
assert(dispatcher.focusFrame==Ping.frame)
fire(Ping.frame,'OnUpdate',.01)
assert(not dispatcher.focusFrame and not dispatcher.stickEnabled,'disconnect watchdog retained camera in combat')
assert(Ping.frame:IsShown(),'disconnect watchdog mutated protected visibility in combat')
click('PADRSTICK',false)
assert(#sent==count and not Ping.frame:IsShown(),'disconnected combat release pinged')
mapped=previous combat=false
trusted=true Ping.frame:SetAttribute('state-cpf-combat','peace') trusted=false
click('PADRSTICK',true) mapped.name='new-device' click('PADRSTICK',false) mapped.name='controller'
assert(#sent==count,'changed controller dispatched stale gesture')
click('PADRSTICK',true)
hardware=true trusted=true
fire(Ping.frame,'PreClick','PADRSTICK',false)
fire(Ping.frame,'OnClick','PADRSTICK',false,true,true)
fire(Ping.frame,'PostClick','PADRSTICK',false)
hardware=false trusted=false
assert(#sent==count and not Ping.frame:IsShown(),'still-held spurious release dispatched')
-- Combat crossing cancels; gestures wholly within combat use native macros.
click('PADRSTICK',true) trusted=true Ping.frame:RunAttribute('_onstate-cpf-combat') trusted=false
combat=true trusted=true Ping.frame:SetAttribute('state-cpf-combat','combat') trusted=false
click('PADRSTICK',false) assert(#sent==count,'combat boundary sent stale gesture')
click('PADRSTICK',true)
assert(Ping.frame.alpha==0,'combat tap revealed ring')
clock=clock+.16 fire(Ping.frame,'OnUpdate',.16)
assert(Ping.frame.alpha==1,'combat hold artwork required public protected writes')
click('PADRSTICK',false) assert(#sent==count+1) combat=false
trusted=true Ping.frame:SetAttribute('state-cpf-combat','peace') trusted=false
count=#sent
-- Prefix changes cancel before release, including a changed logical layer
-- with the same physically held chord. No gesture is committed on the new row.
click('PADRSTICK',true)
trusted=true db.Layers:SetAttribute('prefix','CTRL-') trusted=false
assert(not Ping.frame:IsShown(),'logical prefix change failed to cancel')
click('PADRSTICK',false) assert(#sent==count,'prefix change committed old gesture')
trusted=true db.Layers:SetAttribute('prefix','') trusted=false
click('PADRSTICK',true)
trusted=true db.Layers:SetAttribute('chord','CTRL-') trusted=false
assert(not Ping.frame:IsShown(),'physical chord change failed to cancel')
click('PADRSTICK',false) assert(#sent==count)
trusted=true db.Layers:SetAttribute('chord','') trusted=false
-- Cursor restore is a same-click transaction, with no held-state CVar lease.
cvars.GamePadCursorCentering='1'
click('PADRSTICK',true) click('PADRSTICK',false)
assert(cvars.GamePadCursorCentering=='1','preexisting centering overwritten')
cvars.GamePadCursorCentering='0'
local originalSend=C_PingSecure.SendHitTestPing
C_PingSecure.SendHitTestPing=function(type)
    local result=originalSend(type)
    cvars.GamePadCursorCentering='2'
    return result
end
click('PADRSTICK',true) click('PADRSTICK',false)
assert(cvars.GamePadCursorCentering=='2','newer different centering writer overwritten')
C_PingSecure.SendHitTestPing=originalSend cvars.GamePadCursorCentering='0'
-- Rebinding removes transient claims, preserving the keyboard and other keys.
boundKeys={'F2'} function db.Gamepad:GetBindings() return {} end
assert(Ping:Refresh(_G,true,bridge))
assert(GetBindingAction('PADRSTICK',true)=='TOGGLEPINGLISTENER' and GetBindingAction('PAD2',true)=='GAMEPLAY','rebind retained stale override')
assert(Ping:Refresh(_G,false,bridge))
local originalResolver=db.Layers:GetAttribute('Resolve')
boundKeys={'PADRSTICK','F2'} assert(Ping:Refresh(_G,true,bridge))
local foreignResolver=[[local key=... self:RunAttribute('cpf-ping-original-resolve',key)]]
db.Layers:CreateEnvironment({Resolve=foreignResolver})
local ready=Ping:Refresh(_G,true,bridge)
assert(not ready and db.Layers:GetAttribute('Resolve')==foreignResolver,'later resolver writer replaced or recursively captured')
assert(GetBindingAction('PADRSTICK',true)=='TOGGLEPINGLISTENER','failclosed resolver retained override')
assert(Ping:Refresh(_G,false,bridge) and db.Layers:GetAttribute('Resolve')==foreignResolver,'disable overwrote later resolver writer')
-- A ping remapped to the usual cancel control presents an honest wedge-only
-- cancel hint and does not intercept its own release with Cancel.
db.Layers:CreateEnvironment({Resolve=originalResolver})
boundKeys={'PAD2','F2'} mapped.buttons[2]=false
db.Radial:Execute([[BTNS.PAD2=2 BTNS[2]='PAD2']])
assert(Ping:Refresh(_G,true,bridge))
hardware=true trusted=true mapped.buttons[2]=true
fire(Ping.frame,'PreClick','PAD2',true)
fire(Ping.frame,'OnClick','PAD2',true,true,true)
fire(Ping.frame,'PostClick','PAD2',true)
assert(not GetBindingAction('PAD2',true):find(':Cancel',1,true) and not Ping.frame.cpfHint,'remapped cancel control has false hint')
mapped.buttons[2]=false
fire(Ping.frame,'PreClick','PAD2',false) fire(Ping.frame,'OnClick','PAD2',false,true,true) fire(Ping.frame,'PostClick','PAD2',false)
trusted=false hardware=false
assert(not Ping.frame:IsShown(),'remapped ping failed release')
assert(Ping:Refresh(_G,false,bridge))
-- Public callbacks remain insecure even when native called them from hardware.
hardware=true trusted=false local ok,error=pcall(C_Ping.SendMacroPing,{targetToken='cursor'}) hardware=false
assert(not ok and tostring(error):find('ADDON_ACTION_FORBIDDEN',1,true),'hardware alone bypassed restricted API')
assert(uiChecks==0,'controller point branch hit blocking UI')
TEST_SUCCESS=true
