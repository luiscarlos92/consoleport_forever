-- Appended to the actual Input/windows/native-stack harness. Executes full
-- pinned Dispatcher and Scroll modules plus Blizzard ScrollController.
TEST_SUCCESS=nil
function Mixin(target,...) for i=1,select('#',...) do for key,value in pairs(select(i,...)) do target[key]=value end end return target end
function CreateFromMixins(...) return Mixin({},...) end
local createFrame=CreateFrame
function CreateFrame(kind,name,parent,template)
    if name and name:find('$parent',1,true) then name=name:gsub('%$parent',parent:GetName()) end
    return createFrame(kind,name,parent,template)
end
function Saturate(value) return math.max(0,math.min(1,value)) end
function tInvert(t) local inverse={} for key,value in pairs(t) do inverse[value]=key end return inverse end
function wipe(t) for key in pairs(t) do t[key]=nil end end
local cursorControl=true
function IsGamePadCursorControlEnabled() return cursorControl end
function SetGamePadCursorControl(value) cursorControl=value end
api.IsGamePadCursorControlEnabled=IsGamePadCursorControlEnabled
api.SetGamePadCursorControl=function(value) SetGamePadCursorControl(value) end
function Frame:EnableGamePadStick(value) self.stickEnabled=value end
function Frame:SetFrameStrata(value) self.strata=value end
function Frame:SetPropagateKeyboardInput(value) assert(not combat) self.propagate=value end
local nativeDispatcher,nativeTimers
nativeTimers={}
function C_Timer.NewTimer(delay,callback)
    local timer={delay=delay,callback=callback,Cancel=function(self) self.cancelled=true end}
    nativeTimers[#nativeTimers+1]=timer return timer
end
function CPAPI.Start(frame)
    nativeDispatcher=frame
    frame:SetScript('OnGamePadStick',frame.OnGamePadStick)
end
ConsolePortRadial=CreateFrame('Frame','ConsolePortRadial',UIParent)
CPAPI.DataHandler=function(frame) return frame end
CPAPI.SecureEnvironmentMixin={Execute=function() end,CreateEnvironment=function(self,body) self.nativeEnvironment=body end}
function db:RegisterSafeCallback() end
function db:RegisterSafeCallbacks() end
local settings={radialActionDeadzone=.5,radialCosineDelta=1,radialClearFocusMode=1,
    radialClearFocusDeadzone=.2,radialClearFocusTime=1,UIholdRepeatDelayFirst=.3,UIholdRepeatDelay=.1}
setmetatable(db,{__call=function(_,key) return settings[key] end})
--@NATIVE_RADIAL
db.Radial:OnDataLoaded()
assert(nativeDispatcher and nativeDispatcher.enableDeadzone and nativeDispatcher.enableTimeout)
--@NATIVE_SCROLL_CONTROLLER
api.ScrollControllerMixin=ScrollControllerMixin
local controllerAPI=ConsolePort
ConsolePort=CreateFrame('Frame','ConsolePort',UIParent)
for key,value in pairs(controllerAPI) do if ConsolePort[key]==nil then ConsolePort[key]=value end end
function Clamp(value,min,max) return math.max(min,math.min(max,value)) end
LibStub=function(name) assert(name=='ConsolePortNode') return {} end
CPAPI.GetEnv=function() return {ExecuteScript=function(frame,script,...) fire(frame,script,...) end},db end
--@NATIVE_SCROLL
api.ConsolePortUIScrollHandler=assert(named.ConsolePortUIScrollHandler)
local scrollA=CreateFrame('Frame','ScrollA',paneA)
local scrollB=CreateFrame('Frame','ScrollB',paneB)
for _,frame in ipairs({scrollA,scrollB}) do
    Mixin(frame,ScrollControllerMixin) frame:OnLoad()
    frame:SetScrollPercentage(.5) frame:SetScript('OnMouseWheel',frame.OnMouseWheel)
end
leafA.parent=scrollA leafB.parent=scrollB
contexts:Enable({db=db,api={version='3.3.10'}},api,true,true)
cursor:SetCurrentNode(leafA)
local axis=contexts.scroll
assert(axis.owned and nativeDispatcher.focusFrame==axis.frame and not cursorControl)
local function stick(y,len) fire(nativeDispatcher,'OnGamePadStick','Right',0,y,len) end
local function tick(elapsed) fire(axis.frame,'OnUpdate',elapsed) end
stick(-1,1) assert(scrollA:GetScrollPercentage()==.5,'initial held stick scrolled a new owner')
stick(0,0) stick(-1,1)
assert(math.abs(scrollA:GetScrollPercentage()-.7)<.001)
tick(.2) assert(math.abs(scrollA:GetScrollPercentage()-.7)<.001,'repeat ignored the native initial delay')
tick(.21) assert(math.abs(scrollA:GetScrollPercentage()-.9)<.001)
stick(0,0) tick(1) assert(math.abs(scrollA:GetScrollPercentage()-.9)<.001)
stick(1,1) cursor:SetCurrentNode(leafB)
local afterA=scrollA:GetScrollPercentage()
tick(1) stick(-1,1)
assert(scrollA:GetScrollPercentage()==afterA and scrollB:GetScrollPercentage()==.5,'held scroll crossed owner generations')
stick(0,0) stick(-1,1) assert(math.abs(scrollB:GetScrollPercentage()-.7)<.001)
scrollB:SetScrollAllowed(false) tick(.5) assert(math.abs(scrollB:GetScrollPercentage()-.7)<.001)
scrollB:SetScrollAllowed(true)
-- Popup priority releases UI scroll and leaves native pending-axis drain.
cursor:SetCurrentNode(target)
assert(not axis.owned and nativeDispatcher.disabled and cursorControl)
stick(-1,1) assert(nativeDispatcher.focusFrame==axis.frame)
stick(0,0) assert(nativeDispatcher.focusFrame==nil and not nativeDispatcher.stickEnabled)
cursor:SetCurrentNode(leafA) assert(axis.owned)
-- A newer external focus is never cleared/restored over by the companion.
local foreign=CreateFrame('Frame','ForeignUIAxis',UIParent)
foreign.sticks={Right=true} function foreign:IsDominantStick() return true end
local externalInput=0 function foreign:OnInput() externalInput=externalInput+1 end
db.Radial:ToggleFocusFrame(foreign,true)
assert(not contexts.context and not axis.owned and nativeDispatcher.focusFrame==foreign)
contexts:Refresh() assert(nativeDispatcher.focusFrame==foreign and not cursorControl)
stick(0,0) assert(externalInput==1)
db.Radial:ToggleFocusFrame(foreign,false)
assert(axis.owned and nativeDispatcher.focusFrame==axis.frame)
-- Native registered wheels use the same dispatcher but enter directly through
-- their actual mixin. OnShow watcher cancels ordinary UI without clearing it.
local wheel=CreateFrame('Frame','NativeRegisteredWheel',UIParent)
wheel:Hide() db.Radial.Headers[wheel]=true
wheel.sticks={Right=true} function wheel:IsDominantStick() return true end function wheel:OnInput() end
wheel:SetScript('OnShow',function(self) nativeDispatcher:SetFocus(self) end)
contexts:Refresh()
wheel:Show()
assert(not axis.owned and nativeDispatcher.focusFrame==wheel)
wheel:Hide() contexts:Refresh() assert(axis.owned)
-- Newer mouse/cursor preference survives release, even if it writes false.
SetGamePadCursorControl(false)
keyboard:Show() assert(not axis.owned and not cursorControl)
keyboard:Hide() assert(axis.owned)
stick(0,0) stick(-1,1)
combat=true contexts:Refresh() tick(1)
assert(not axis.owned and not axis.direction)
combat=false contexts:Refresh()
-- Unrecognized/protected wheel scripts are consumed without being called.
scrollA:SetScript('OnMouseWheel',function() error('arbitrary wheel callback') end)
contexts:Refresh() stick(0,0) stick(-1,1) tick(1) assert(axis.target==nil)
assert(contexts:Enable({db=db,api={version='3.3.10'}},api,false))
assert(not axis.owned and not axis.direction)
TEST_SUCCESS=true
