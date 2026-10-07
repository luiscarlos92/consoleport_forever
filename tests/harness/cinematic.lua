-- Native cinematic key and movie confirmation contracts, appended to the
-- actual UI/dispatcher harness. No candidate hold/skip route is installed.
TEST_SUCCESS=nil
--@NATIVE_CINEMATIC_KEYS
--@NATIVE_MOVIE
local realScene,cancelScene,exitVehicle,gm=false,false,false,false
local stopped,cancelled,exited,ran=0,0,0,0
function GetBindingFromClick(key) return key=='PADFORWARD' and 'TOGGLEGAMEMENU' or key=='MUSIC' and 'TOGGLEMUSIC' end
function IsGMClient() return gm end
function IsInCinematicScene() return realScene end
function CanCancelScene() return cancelScene end
function CanExitVehicle() return exitVehicle end
function StopCinematic() assert(hardware) stopped=stopped+1 end
function CancelScene() assert(hardware and cancelScene) cancelled=cancelled+1 end
function VehicleExit() assert(hardware and exitVehicle) exited=exited+1 end
function RunBinding(binding) assert(binding=='TOGGLEMUSIC') ran=ran+1 end
CinematicFrame=CreateFrame('Frame','CinematicFrame',UIParent)
CinematicFrame.closeDialog=CreateFrame('Frame',nil,CinematicFrame)
CinematicFrame.closeDialog:Hide() CinematicFrame:Hide()
api.CinematicFrame=CinematicFrame
api.IsInCinematicScene=IsInCinematicScene api.CanCancelScene=CanCancelScene api.CanExitVehicle=CanExitVehicle
MovieFrame=CreateFrame('Frame','MovieFrame',UIParent) Mixin(MovieFrame,MovieFrameMixin)
MovieFrame.CloseDialog=CreateFrame('Frame',nil,MovieFrame)
MovieFrame.CloseDialog.Summary=CreateFrame('Frame',nil,MovieFrame.CloseDialog)
function MovieFrame.CloseDialog:Layout() end
function GetCurrentCinematicSummary() return nil end
local movieStopped,finished=0,0
function MovieFrame:StopMovie() assert(hardware) movieStopped=movieStopped+1 end
function CinematicFinished(kind) assert(kind==7) finished=finished+1 end
Enum={CinematicType={GameMovie=7}}
EventRegistry={TriggerEvent=function() end}
MovieFrame:Hide() api.MovieFrame=MovieFrame
contexts:Enable({db=db,api={version='3.3.10'}},api,true,true)
cursor:SetCurrentNode(leafB) assert(axis.owned)
CinematicFrame:Show()
assert(contexts.context==nil and not axis.owned,'cinematic display kept ordinary UI ownership')
local observer=Addon.Cinematic
assert(observer:Observe(api):find('forbidden',1,true))
CinematicFrame_OnKeyDown(CinematicFrame,'PADFORWARD')
assert(not CinematicFrame.closeDialog:IsShown() and stopped+cancelled+exited==0)
realScene=true
assert(observer:Observe(api):find('forbidden',1,true))
cancelScene=true
assert(observer:Observe(api):find('permitted',1,true))
CinematicFrame_OnKeyDown(CinematicFrame,'PADFORWARD')
assert(CinematicFrame.closeDialog:IsShown() and stopped+cancelled+exited==0)
-- Repeated menu/axis/timer observations never cancel the permitted scene.
for _=1,5 do observer:Refresh(api) CinematicFrame_OnKeyDown(CinematicFrame,'PADFORWARD') tick(.2) end
assert(stopped+cancelled+exited==0 and Addon.Diagnostics.features.cinematicHold.status=='pending')
hardware=true CinematicFrame_CancelCinematic() hardware=false assert(cancelled==1)
realScene=false cancelScene=false exitVehicle=true CinematicFrame.closeDialog:Hide()
CinematicFrame_OnKeyDown(CinematicFrame,'PADFORWARD')
assert(CinematicFrame.closeDialog:IsShown() and observer:Observe(api):find('exit permitted',1,true))
hardware=true CinematicFrame_CancelCinematic() hardware=false assert(exited==1)
CinematicFrame.isRealCinematic=true CinematicFrame.closeDialog:Hide()
CinematicFrame_OnKeyDown(CinematicFrame,'PADFORWARD') assert(CinematicFrame.closeDialog:IsShown() and stopped==0)
hardware=true CinematicFrame_CancelCinematic() hardware=false assert(stopped==1)
CinematicFrame_OnKeyDown(CinematicFrame,'MUSIC') assert(ran==1)
CinematicFrame:Hide() assert(contexts.context.kind=='window' and axis.owned)
MovieFrame:Show() assert(contexts.context==nil and not axis.owned)
assert(observer:Observe(api):find('native key-up',1,true))
MovieFrame:OnKeyUp('PADFORWARD') assert(MovieFrame.CloseDialog:IsShown() and movieStopped==0)
MovieFrame:OnKeyUp('MUSIC') assert(ran==2)
observer:Refresh(api) tick(.2) assert(movieStopped==0)
hardware=true MovieFrame:FinishMovie() hardware=false
assert(movieStopped==1 and finished==1 and contexts.context.kind=='window' and axis.owned)
assert(observer:Observe(api)=='no visible native movie/cinematic')
CinematicFrame.isRealCinematic={} CinematicFrame:Show()
api.issecretvalue=function(value) return type(value)=='table' end
assert(observer:Observe(api)=='cinematic eligibility opaque')
api.issecretvalue=nil
api.IsInCinematicScene=function() error('native state not ready') end
assert(observer:Observe(api):find('unavailable',1,true))
assert(Addon.Diagnostics.features.exactCircle.status=='pending' and Addon.Diagnostics.features.exactStickCommit.status=='pending' and Addon.Diagnostics.features.activeEntryCancellation.status=='pending')
TEST_SUCCESS=true
