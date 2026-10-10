TEST_SUCCESS=nil
local unpack=table.unpack or unpack
-- Actual current ConsolePort Layers and Blizzard listener/manager methods;
-- Input callback order, pointer hit tests and API security are host models.
-- Hardware authority and untainted native-binding authority are independent.
local Ping=Addon.PingTargeting
local cvars={GamePadCursorCentering='0',pingMode='0'}
local freelook,freeCursor,ui=false,false,false
local errorCount,worldCount,centeredSamples=0,0,0
local foci={}
function GetCVar(name) return cvars[name] end
function SetCVar(name,value) cvars[name]=tostring(value) end
function IsGamePadFreelookEnabled() return freelook end
function IsGamePadCursorControlEnabled() return freeCursor end
function GetMouseFoci() return foci end
local prefix=''
local pingKeys={PADRSTICK=true,['CTRL-PADRSTICK']=true,F2=true}
local underlyingBinding=GetBindingAction
function GetBindingAction(key,effective)
 local action=underlyingBinding(key,effective)
 if action~='GAMEPLAY' then return action end
 return pingKeys[key] and 'TOGGLEPINGLISTENER' or 'GAMEPLAY'
end
CPAPI.CreateKeyChord=function(button) return prefix..button end
CPAPI.GetBindingAction=GetBindingAction
local function cursorPosition()
    if cvars.GamePadCursorCentering=='1' then centeredSamples=centeredSamples+1 return 500,400 end
    return 10,10 -- parked over an ordinary blocking dialog
end
function GetCursorPosition() return cursorPosition() end
function GetScaledCursorPosition_Insecure() return cursorPosition() end
function securecallfunction(fn,...) return fn(...) end
function securecopy(t) return t end
Enum.PingMode={KeyDown=0}
Enum.PingSetTargetState={Failed=0,Ok=1}
Enum.PingResult={Success=0}
PING_FAILED_GENERIC="Can't ping this"
local dialog={}
C_PingSecure={
 GetTargetPingReceiver=function(x,y) return x==10 and dialog or nil end,
 SetHitTestPingTarget=function() return Enum.PingSetTargetState.Ok end,
 SetHitTestTargetAndSendPing=function() worldCount=worldCount+1 return {result=Enum.PingResult.Success} end,
 DisplayError=function(message) assert(message==PING_FAILED_GENERIC) errorCount=errorCount+1 end,
}
PingManager={defaultWedgeInfo={}}
PingListenerFrameMixin={PingRadialKeyDownDuration=.15}
--@NATIVE_PING_METHODS
local listener=CreateFrame('Frame','CPFNativePingListener',UIParent)
for key,fn in pairs(PingListenerFrameMixin) do listener[key]=fn end
listener.enabledState=false
function listener:ClearPendingPingInfo() self.pendingPingInfo=nil end
local wheelStarts,wheelEnds=0,0
PingFrame={
 SelectionStart=function() wheelStarts=wheelStarts+1 end,
 EvaluateResult=function() wheelEnds=wheelEnds+1 end,
}
local timers={}
local deferred={}
C_Timer={}
C_Timer.After=function(_,fn) deferred[#deferred+1]=fn end
local function flush() local queued=deferred deferred={} for _,fn in ipairs(queued) do fn() end end
C_Timer.NewTimer=function(_,fn)
 local timer={fn=fn,Cancel=function(self) self.cancelled=true end}
 timers[#timers+1]=timer return timer
end
C_Ping={TogglePingListener=function(down)
 assert(hardware,'native ping entered without hardware binding')
 assert(trusted,'ADDON_ACTION_FORBIDDEN: C_Ping.TogglePingListener')
 listener:TogglePingListener(down)
end}
local mouse=CreateFrame('Frame','CPFNativeMouse',UIParent)
function mouse:ShouldSetFreeCursor() return false end
function mouse:ShouldSetCameraControl() return false end
function mouse:ShouldSetCenteredCursor() return false end
--@NATIVE_MOUSE_DOWN
mouse:SetScript('OnGamePadButtonDown',mouse.OnGamePadButtonDown)
local nativeDowns,nativeUps=0,0
mouse:HookScript('OnGamePadButtonDown',function() nativeDowns=nativeDowns+1 end)
mouse:SetScript('OnGamePadButtonUp',function() nativeUps=nativeUps+1 end)
local nativeOwners={Mouse=mouse,Cursor={IsShown=function() return ui end},Layers=db.Layers}
Addon.adapters={consoleport={api={version='3.3.10'},db=nativeOwners}}
local bridge=Addon.adapters.consoleport
--@NATIVE_PING_BINDING
local bindingCalls=0
local function dispatchPing(down,button)
 button=button or 'PADRSTICK'
 hardware=true trusted=false
 -- Native ConsolePort transforms cursor mode in the gamepad script; addons
 -- observe it without gaining authority. The engine then runs the native XML.
 fire(mouse,down and 'OnGamePadButtonDown' or 'OnGamePadButtonUp',button)
 if GetBindingAction(prefix..button,true)=='TOGGLEPINGLISTENER' then
  trusted=true bindingCalls=bindingCalls+1 nativeBinding(down and 'down' or 'up') trusted=false
 end
 hardware=false
end
freelook=true
assert(Ping:Refresh(_G,true,bridge))
assert(GetBindingAction('PADRSTICK',true)=='TOGGLEPINGLISTENER' and next(Ping.claims)==nil,'native ping binding was replaced')
local beforeErrors=errorCount
local beforeCalls=bindingCalls
dispatchPing(true) dispatchPing(false)
assert(worldCount==1 and errorCount==beforeErrors,'parked pointer blocked controller tap')
assert(cvars.GamePadCursorCentering=='1','pointer restored before native up sampled')
flush()
assert(cvars.GamePadCursorCentering=='0' and not Ping.held,'tap did not restore prior centering')
assert(bindingCalls==beforeCalls+2,'native ping dispatched twice or lost release')
-- Reproduce candidate.22's blocked call even with hardware authority.
hardware=true trusted=false
local allowed,reason=pcall(C_Ping.TogglePingListener,true)
hardware=false
assert(not allowed and tostring(reason):find('ADDON_ACTION_FORBIDDEN',1,true),'insecure hardware callback gained native privilege')
-- Native uncentered binding reproduces the original parked-pointer error.
hardware=true trusted=true nativeBinding('down') nativeBinding('up') trusted=false hardware=false
assert(errorCount==beforeErrors+1,'stale pointer failure was not reproduced')
beforeErrors=errorCount
dispatchPing(true)
trusted=true timers[#timers].fn() trusted=false
assert(listener.pendingPingInfo and wheelStarts==1,'hold lost native radial wheel')
dispatchPing(false) flush()
assert(wheelEnds==1 and errorCount==beforeErrors and cvars.GamePadCursorCentering=='0','hold release lost native wheel/restoration')
-- Repeated down, combat, and key modifiers changing while held.
dispatchPing(true)
local saved=Ping.before dispatchPing(true)
assert(Ping.before==saved and not Ping:Refresh(_G,true,bridge))
fire(mouse,'OnGamePadButtonUp','PAD1') flush() assert(Ping.held=='PADRSTICK')
prefix='CTRL-' dispatchPing(false) prefix='' flush()
assert(not Ping.held and cvars.GamePadCursorCentering=='0')
combat=true dispatchPing(true) dispatchPing(false) flush() combat=false
-- Rapid second press before the deferred restore must cancel the old restore.
dispatchPing(true) dispatchPing(false) dispatchPing(true) flush()
assert(Ping.held=='PADRSTICK' and cvars.GamePadCursorCentering=='1','rapid repress restored the active pointer')
dispatchPing(false) flush()
-- Existing centering and newer external changes retain their values.
cvars.GamePadCursorCentering='1' dispatchPing(true) dispatchPing(false) flush()
assert(cvars.GamePadCursorCentering=='1')
cvars.GamePadCursorCentering='0' dispatchPing(true) cvars.GamePadCursorCentering='0' dispatchPing(false) flush()
assert(cvars.GamePadCursorCentering=='0')
-- Mouse, free pointer and UI owners use their actual focus.
for _,mode in ipairs({'mouse','free','ui','raid','ring'}) do
 freelook=mode~='mouse' freeCursor=mode=='free' ui=mode=='ui'
 nativeOwners.Raid={IsShown=function() return mode=='raid' end}
 nativeOwners.TargetRing={IsShown=function() return mode=='ring' end}
 dispatchPing(true) assert(cvars.GamePadCursorCentering=='0','native input owner was centered: '..mode) dispatchPing(false) flush()
end
freelook=true freeCursor=false ui=false nativeOwners.Raid=nil nativeOwners.TargetRing=nil
-- Foreign modal priorities and rebound chords are observed, never overridden.
assert(db.Layers:Claim('foreign-ping-modal','MODAL','PADRSTICK','binding','FOREIGN_MODAL'))
beforeCalls=bindingCalls dispatchPing(true) dispatchPing(false) flush()
assert(GetBindingAction('PADRSTICK',true)=='FOREIGN_MODAL' and bindingCalls==beforeCalls and not Ping.held)
assert(cvars.GamePadCursorCentering=='0','foreign modal changed pointer')
assert(Ping:Refresh(_G,true,bridge))
db.Layers:ReleaseAll('foreign-ping-modal')
pingKeys.PADRSTICK=nil dispatchPing(true) dispatchPing(false) flush()
assert(not Ping.held and cvars.GamePadCursorCentering=='0')
pingKeys.PADRSTICK=true
prefix='CTRL-' dispatchPing(true) dispatchPing(false) flush() prefix=''
assert(cvars.GamePadCursorCentering=='0')
-- Keyboard F2 is entirely native: no gamepad pointer callback.
hardware=true trusted=true nativeBinding('down') nativeBinding('up') trusted=false hardware=false
assert(cvars.GamePadCursorCentering=='0')
-- Disable while held/queued restores only our cursor state; callbacks become inert.
dispatchPing(true) dispatchPing(false) assert(Ping:Refresh(_G,false,bridge)) flush()
assert(not Ping.held and cvars.GamePadCursorCentering=='0')
fire(mouse,'OnGamePadButtonDown','PADRSTICK') assert(not Ping.held)
assert(Ping:Refresh(_G,true,bridge))
local calls=nativeDowns dispatchPing(true) dispatchPing(false) flush()
assert(nativeDowns==calls+1 and nativeUps>0,'native input callbacks changed or duplicated')
local focus=CreateFrame('Frame','OrdinaryPingBlockingDialog',UIParent)
function focus:IsToplevel() return true end
foci={focus}
local snapshot=Ping:Observe(_G,"Can't ping this")
assert(snapshot.foci[1].name=='OrdinaryPingBlockingDialog' and Addon.Diagnostics.ping==snapshot)
assert(centeredSamples>0)
TEST_SUCCESS=true
