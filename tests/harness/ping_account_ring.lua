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
function Frame:GetAlpha() return self.alpha or 1 end
function Frame:HasAccessConstraints() return false end
function Frame:HasAnyForbiddenAspects() return false end
function Frame:Click(button) fire(self,'PreClick',button,nil) fire(self,'OnClick',button,nil,nil,nil) fire(self,'PostClick',button,nil) end
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
    handle.SetBindingClick=function(_,priority,key,target,button) overrides[key]={action='CLICK '..target..':'..(button or 'LeftButton'),owner=frame} end
    handle.SetBinding=function(_,priority,key,action) overrides[key]={action=action,owner=frame} end
    handle.ClearBinding=function(_,key) if overrides[key] and overrides[key].owner==frame then overrides[key]=nil end end
    handle.ChildUpdate=function(_,kind,value) if frame.ChildUpdate then frame:ChildUpdate(kind,value) end end
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
--@NATIVE_CLICK_ACTION
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
--@NATIVE_ACCOUNT_RING_HOST
local nativeOwners={Rings=ring,Layers=db.Layers,Radial=db.Radial,Gamepad=db.Gamepad}
setmetatable(nativeOwners,{__call=function(_,key) return db(key) end})
for _,name in ipairs({'Cursor','Raid','TargetRing'}) do nativeOwners[name]=CreateFrame('Frame',name,UIParent,name~='Cursor' and 'SecureHandlerBaseTemplate' or nil) nativeOwners[name]:Hide() end
local bridge={api={version='3.3.10'},db=nativeOwners}
Addon.adapters={consoleport=bridge}
Enum={ForbiddenAspect={ScriptedInput=1},PingSetTargetState={Failed=0,Ok=1},PingResult={Success=0},PingSubjectType={Attack=0,Warning=1,OnMyWay=2,Assist=3,AlertNotThreat=4,AlertThreat=5}}
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
    SendHitTestPing=function(type) assert(trusted and hardware) sent[#sent+1]={type=type,point=true,nativeRingShown=ring:IsShown()} return {result=0,type=type} end,
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
    local suffix=text:gsub('^%b[]','')
    while suffix:match('^%[') do suffix=suffix:gsub('^%b[]','') end
    for condition in text:gmatch('%[@([^%]]+)%]') do
        local token=condition:match('^[^,]+')
        if not condition:find(',exists',1,true) or UnitExists(token) then return suffix:match('^%s*(.-)%s*$'),token end
    end
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

--@NATIVE_ACCOUNT_RING_CHECKS
