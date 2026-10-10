TEST_SUCCESS=nil
local unpack=table.unpack or unpack
-- Actual current ConsolePort Layers and Blizzard listener/manager methods;
-- pointer hit tests, timers and protected API entry remain host services.
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
local pingKeys={'F2','PADRSTICK'}
function GetBindingKey(binding) assert(binding=='TOGGLEPINGLISTENER') return unpack(pingKeys) end
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
C_Timer={}
C_Timer.NewTimer=function(_,fn)
 local timer={fn=fn,Cancel=function(self) self.cancelled=true end}
 timers[#timers+1]=timer return timer
end
C_Ping={TogglePingListener=function(down)
 assert(hardware,'native ping entered without hardware binding')
 listener:TogglePingListener(down)
end}
local nativeOwners={Cursor={IsShown=function() return ui end},Layers=db.Layers}
Addon.adapters={consoleport={api={version='3.3.10'},db=nativeOwners}}
local bridge=Addon.adapters.consoleport
--@PRODUCT_PING_BINDING
local function dispatchPing(down)
 assert(GetBindingAction('PADRSTICK',true)=='CPF_GAMEPAD_PING','engine did not route controller ping through qualified binding')
 hardware=true bindingHardware(down and 'down' or 'up') hardware=false
end
freelook=true
assert(Ping:Refresh(_G,true,bridge))
assert(Ping.claims.PADRSTICK and not Ping.claims.F2,'keyboard binding was intercepted')
local beforeErrors=errorCount
dispatchPing(true) dispatchPing(false)
assert(worldCount==1 and errorCount==beforeErrors,'parked pointer blocked controller tap')
assert(cvars.GamePadCursorCentering=='0' and not Ping.held,'tap did not restore prior centering')
-- The original native binding reproduces the actual Blizzard error branch.
hardware=true C_Ping.TogglePingListener(true) C_Ping.TogglePingListener(false) hardware=false
assert(errorCount==beforeErrors+1,'pre-fix stale pointer failure was not reproduced')
beforeErrors=errorCount
dispatchPing(true)
timers[#timers].fn()
assert(listener.pendingPingInfo and wheelStarts==1,'hold lost native radial wheel')
dispatchPing(false)
assert(wheelEnds==1 and errorCount==beforeErrors and cvars.GamePadCursorCentering=='0','hold release did not use native wheel/restoration')
-- Repeated down does not create a second native timer or replace the backup.
dispatchPing(true) local timerCount=#timers dispatchPing(true)
assert(not Ping:Refresh(_G,true,bridge),'held native ping route was rebuilt')
assert(#timers==timerCount and Ping.before=='0') dispatchPing(false)
-- Existing centering, and a newer native CVar change, are retained.
cvars.GamePadCursorCentering='1' dispatchPing(true) dispatchPing(false)
assert(cvars.GamePadCursorCentering=='1')
cvars.GamePadCursorCentering='0' dispatchPing(true) cvars.GamePadCursorCentering='0' dispatchPing(false)
assert(cvars.GamePadCursorCentering=='0')
local nativeToggle=C_Ping.TogglePingListener
C_Ping.TogglePingListener=function() error('native restriction') end
hardware=true local allowed=pcall(bindingHardware,'down') hardware=false
assert(not allowed and not Ping.held and cvars.GamePadCursorCentering=='0','native refusal leaked pointer ownership')
C_Ping.TogglePingListener=nativeToggle
-- Mouse/free pointer and native UI owners continue to ping their actual focus.
for _,mode in ipairs({'mouse','free','ui','raid','ring'}) do
 freelook=mode~='mouse' freeCursor=mode=='free' ui=mode=='ui'
 nativeOwners.Raid={IsShown=function() return mode=='raid' end}
 nativeOwners.TargetRing={IsShown=function() return mode=='ring' end}
 dispatchPing(true) assert(cvars.GamePadCursorCentering=='0','native input owner was centered: '..mode) dispatchPing(false)
end
freelook=true freeCursor=false ui=false nativeOwners.Raid=nil nativeOwners.TargetRing=nil
-- The native arbiter, not a competing engine override, preserves modal owners.
assert(db.Layers:Claim('foreign-ping-modal','MODAL','PADRSTICK','binding','FOREIGN_MODAL'))
assert(GetBindingAction('PADRSTICK',true)=='FOREIGN_MODAL')
assert(Ping:Refresh(_G,true,bridge))
assert(GetBindingAction('PADRSTICK',true)=='FOREIGN_MODAL','refresh displaced foreign modal')
db.Layers:ReleaseAll('foreign-ping-modal')
assert(GetBindingAction('PADRSTICK',true)=='CPF_GAMEPAD_PING')
combat=true assert(not Ping:Refresh(_G,true,bridge))
dispatchPing(true) dispatchPing(false) combat=false
-- Rebinding/removal and disable release only this claimant.
pingKeys={'F2'} assert(Ping:Refresh(_G,true,bridge))
assert(not Ping.claims.PADRSTICK and GetBindingAction('PADRSTICK',true)~='CPF_GAMEPAD_PING')
pingKeys={'F2','PADRSTICK'} assert(Ping:Refresh(_G,true,bridge))
assert(Ping:Refresh(_G,false,bridge) and next(Ping.claims)==nil)
local focus=CreateFrame('Frame','OrdinaryPingBlockingDialog',UIParent)
function focus:IsToplevel() return true end
foci={focus}
local snapshot=Ping:Observe(_G,"Can't ping this")
assert(snapshot.foci[1].name=='OrdinaryPingBlockingDialog' and Addon.Diagnostics.ping==snapshot)
assert(centeredSamples>0)
TEST_SUCCESS=true
