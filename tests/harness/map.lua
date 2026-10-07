-- Appended after the pinned native dispatcher/window/scroll harness.
TEST_SUCCESS=nil
CallbackRegistryMixin={} MapCanvasDataProviderMixin={} MapCanvasPinMixin={}
SlashCommandUtil={CheckAddSlashCommand=function() end}
SLASH_COMMAND={MAPPIN=1} SLASH_COMMAND_CATEGORY={MAP=1}
--@NATIVE_MAP_CANVAS
--@NATIVE_MAP_SCROLL
--@NATIVE_QUEST_OWNER
WorldMapMixin={}
--@NATIVE_MAP_MAXIMIZED
--@NATIVE_WAYPOINT
api.MapCanvasMixin=MapCanvasMixin api.MapCanvasScrollControllerMixin=MapCanvasScrollControllerMixin
api.QuestLogOwnerMixin=QuestLogOwnerMixin api.WorldMapMixin=WorldMapMixin
api.WaypointLocationDataProviderMixin=WaypointLocationDataProviderMixin
api.MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH=MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH
api.MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL=MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL
local map=CreateFrame('Frame','WorldMapFrame',UIParent)
local canvas=CreateFrame('Frame','WorldMapCanvas',map)
local pin=CreateFrame('Button','QuestPOIPin',canvas)
map.ScrollContainer=canvas map.mapID=12 map.mapArtID=34 map.isMaximized=true
Mixin(map,MapCanvasMixin,QuestLogOwnerMixin,WorldMapMixin)
Mixin(canvas,MapCanvasScrollControllerMixin) canvas:OnLoad()
canvas.currentScale=2 canvas.targetScale=2 canvas.baseScale=1
canvas.zoomLevels={{scale=1},{scale=2},{scale=3}}
canvas.scrollXExtentsMin=.25 canvas.scrollXExtentsMax=.75 canvas.scrollYExtentsMin=.25 canvas.scrollYExtentsMax=.75
canvas.Child=CreateFrame('Frame',nil,canvas)
function canvas.Child:GetLeft() return 10 end function canvas.Child:GetTop() return 120 end
function canvas.Child:GetWidth() return 200 end function canvas.Child:GetHeight() return 100 end
local cx,cy=160,80
function cursor:GetCenter() return cx,cy end function cursor:GetEffectiveScale() return .5 end
function map:GetEffectiveScale() return .25 end
local cvwrites={}
function SetCVar(key,value) cvwrites[key]=value end
function map:ShouldShowQuestLogPanel() return false end
local states={}
function map:SetDisplayState(state) states[#states+1]=state self.isMaximized=false end
map.CloseButton=CreateFrame('Button','MapClose',map)
map.CloseButton:SetScript('OnClick',function() map:Hide() end)
api.WorldMapFrame=map
local provider=CreateFromMixins(WaypointLocationDataProviderMixin)
map.dataProviders={[provider]=true}
local disabled,allowed,waypoint=true,true,nil
local setCount,clearCount,superCount=0,0,0
api.Enum={GameRule={WorldMapTrackingPinDisabled=45}}
api.C_GameRules={IsGameRuleActive=function(rule) assert(rule==45) return disabled end}
api.UiMapPoint={CreateFromCoordinates=function(id,x,y) return {mapID=id,x=x,y=y} end}
api.C_Map={CanSetUserWaypointOnMap=function(id) assert(id==map.mapID) return allowed end,
    SetUserWaypoint=function(point) assert(hardware) setCount=setCount+1 waypoint=point return allowed end,
    ClearUserWaypoint=function() assert(hardware) clearCount=clearCount+1 waypoint=nil end}
api.C_SuperTrack={SetSuperTrackedUserWaypoint=function(value) assert(hardware and value==false) superCount=superCount+1 end}
settings['Settings/UICursorCancel']='PAD2'
assert(nativeStack:SetFrame(map,true)) flushWindows()
assert(contexts:Enable({db=db,api={version='3.3.10'}},api,true,true,false,true))
cursor:SetCurrentNode(pin)
assert(contexts.context.kind=='map' and axis.owned and axis.frame.sticks.Left and axis.frame.sticks.Right)
local function mapStick(stick,x,y,len) fire(nativeDispatcher,'OnGamePadStick',stick,x,y,len) end
mapStick('Left',1,0,1) tick(.1) assert(canvas.targetScrollX==.5,'held movement panned a newly focused map')
mapStick('Left',0,0,0) mapStick('Right',0,0,0)
mapStick('Left',1,-1,1) tick(.1)
assert(math.abs(canvas.targetScrollX-.55)<.0001 and math.abs(canvas.targetScrollY-.55)<.0001)
canvas.mouseWheelZoomMode=MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH
mapStick('Right',0,1,1) tick(.1)
assert(canvas.targetScale>2 and canvas.targetScrollX>.55,'independent sticks did not pan and zoom together')
mapStick('Left',0,0,0) mapStick('Right',0,0,0)
canvas.targetScrollX=.74 mapStick('Left',1,0,1) tick(.1) assert(canvas.targetScrollX==.75)
-- Map changes without a notification stop every ongoing vector.
map.mapID=13 local panBefore=canvas.targetScrollX local zoomBefore=canvas.targetScale
tick(.1) assert(canvas.targetScrollX==panBefore and canvas.targetScale==zoomBefore and next(axis.vectors)==nil)
contexts:Refresh() mapStick('Left',-1,0,1) tick(.1) assert(canvas.targetScrollX==panBefore)
mapStick('Left',0,0,0) mapStick('Left',-1,0,1) tick(.1) assert(canvas.targetScrollX<panBefore)
-- Native full/none zoom modes are preserved; no real-mouse recenter callback.
canvas.mouseWheelZoomMode=MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_NONE
mapStick('Right',0,0,0) mapStick('Right',0,1,1) tick(.1) assert(canvas.targetScale==zoomBefore)
canvas.mouseWheelZoomMode=MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL
mapStick('Left',0,0,0) tick(.2) mapStick('Left',0,0,0) tick(.2) assert(canvas.targetScale==3)
mapStick('Left',0,0,0) mapStick('Right',0,0,0)
-- Game-rule refusal, map refusal and controller UI-point transformation.
press(input.Widgets.PADLSTICK,true) press(input.Widgets.PADLSTICK,false) assert(setCount==0)
disabled=false contexts:Refresh()
press(input.Widgets.PADLSTICK,true) press(input.Widgets.PADLSTICK,false)
assert(setCount==1 and waypoint.mapID==13 and math.abs(waypoint.x-.75)<.001 and math.abs(waypoint.y+.6-1)<.001 and superCount==1)
allowed=false contexts:Refresh()
press(input.Widgets.PADLSTICK,true) press(input.Widgets.PADLSTICK,false) assert(setCount==1)
allowed=true contexts:Refresh()
press(input.Widgets.PADLSTICK,true) cx=cx+10 press(input.Widgets.PADLSTICK,false) assert(setCount==1,'stale waypoint release used a newer pointer')
local nativeWaypoint=CreateFrame('Button','NativeWaypointPin',canvas)
provider.pin=nativeWaypoint cursor:SetCurrentNode(nativeWaypoint)
press(input.Widgets.PADLSTICK,true) press(input.Widgets.PADLSTICK,false) assert(clearCount==1 and superCount==2)
-- Back performs exactly one native minimize, then closes on a later press.
cursor:SetCurrentNode(pin)
press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false)
assert(#states==1 and states[1]==2 and cvwrites.miniWorldMap==1 and map:IsShown())
press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false) assert(not map:IsShown() and not axis.owned)
-- Drain both sticks after leaving map focus; ordinary windows reclaim only Right.
map:Show() cursor:SetCurrentNode(pin)
mapStick('Left',0,0,0) mapStick('Left',1,0,1)
cursor:SetCurrentNode(leafB)
assert(contexts.context.kind=='window' and axis.frame.sticks.Left,'held movement was released before neutral')
mapStick('Left',0,0,0) assert(not axis.frame.sticks.Left)
local detail=CreateFrame('Button','QuestReward',map)
cursor:SetCurrentNode(detail) assert(contexts.context==nil and not axis.owned,'quest details acquired canvas axes')
QuestMapFrame=CreateFrame('Frame','QuestMapFrame',map)
QuestMapFrame.DetailsFrame=CreateFrame('Frame','QuestDetails',QuestMapFrame)
detail.parent=QuestMapFrame.DetailsFrame
QuestMapFrame.DetailsFrame.questID=88 QuestMapFrame.DetailsFrame.returnMapID=11
QuestMapFrame.QuestsFrame={ScrollFrame=CreateFrame('Frame',nil,QuestMapFrame)}
local cleared,updated,portrait,session=0,0,0,0
function map:SetMapID(id) self.mapID=id end
function map:ClearFocusedQuestID() cleared=cleared+1 end
function QuestMapFrame_UpdateAll() updated=updated+1 end
function QuestFrame_HideQuestPortrait() portrait=portrait+1 end
function QuestMapFrame_UpdateQuestSessionState() session=session+1 end
function StaticPopup_Hide() end
--@NATIVE_QUEST_BACK
api.QuestMapFrame=QuestMapFrame api.QuestMapFrame_ReturnFromQuestDetails=QuestMapFrame_ReturnFromQuestDetails
cursor:SetCurrentNode(detail)
assert(contexts.context.token=='native-map-details' and not axis.frame.sticks.Left)
map.isMaximized=true contexts:Refresh()
press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false)
assert(QuestMapFrame.DetailsFrame:IsShown() and map:IsShown() and #states==2)
press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false)
assert(not QuestMapFrame.DetailsFrame:IsShown() and map:IsShown() and map.mapID==11 and cleared==1 and updated==1 and portrait==1 and session==1)
map.mapID=13
local typing=false api.GetCurrentKeyBoardFocus=function() return typing and detail or nil end
cursor:SetCurrentNode(pin) typing=true contexts:Refresh() assert(contexts.context==nil and not axis.owned)
typing=false contexts:Refresh()
cursor:SetCurrentNode(pin) keyboard:Show() assert(not axis.owned)
keyboard:Hide() cursor:SetCurrentNode(target) assert(contexts.context.kind=='popup' and not axis.owned)
cursor:SetCurrentNode(pin) combat=true contexts:Refresh() tick(.1) assert(not axis.owned)
combat=false contexts:Refresh()
map.mapID={} contexts:Refresh() assert(contexts.context==nil and not axis.owned)
map.mapID=13 cursor:SetCurrentNode(pin)
assert(contexts:Enable({db=db,api={version='3.3.10'}},api,true,true,false,false))
assert(contexts.context==nil and not axis.owned)
TEST_SUCCESS=true
