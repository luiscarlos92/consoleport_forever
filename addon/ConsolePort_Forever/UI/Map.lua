local _,Addon=...
local Map={}
Addon.UIMap=Map
local faces={PAD1=true,PAD2=true,PAD3=true,PAD4=true}
local function shown(frame)
    return frame and frame.IsShown and frame:IsShown() and not (frame.IsForbidden and frame:IsForbidden())
end
local function within(node,owner)
    for _=1,32 do
        if not node then return false end
        if node==owner then return true end
        node=node.GetParent and node:GetParent()
    end
    return false
end
function Map.New(db,api,windows,changed)
    return setmetatable({db=db,api=api,windows=windows,changed=changed,proxies={}},{__index=Map})
end
function Map:Number(value)
    return not (self.api.issecretvalue and self.api.issecretvalue(value)) and type(value)=='number'
        and value==value and math.abs(value)<math.huge
end
function Map:Probe()
    local api=self.api
    local map,scroll,mixin=api.WorldMapFrame,api.WorldMapFrame and api.WorldMapFrame.ScrollContainer,api.MapCanvasScrollControllerMixin
    if not map or not scroll or not mixin or not api.MapCanvasMixin or not api.WorldMapMixin or not api.QuestLogOwnerMixin then return false,'native world map not initialized' end
    if map.GetMapID~=api.MapCanvasMixin.GetMapID or map.IsMaximized~=api.WorldMapMixin.IsMaximized
        or map.HandleUserActionMinimizeSelf~=api.QuestLogOwnerMixin.HandleUserActionMinimizeSelf then return false,'audited map/quest owner methods unavailable' end
    for _,key in ipairs({'SetPanTarget','SetZoomTarget','ZoomIn','ZoomOut','CanPan','GetCanvasScale','NormalizeUIPosition','GetCurrentZoomRange','GetZoomLevelIndexForScale','ShouldZoomInstantly','InstantPanAndZoom'}) do
        if scroll[key]~=mixin[key] then return false,'audited map scroll method unavailable: '..key end
    end
    local cancel=self.db('Settings/UICursorCancel')
    if not faces[cancel] then return false,'native map Back face unavailable' end
    self.cancel=cancel
    return true
end
function Map:Raw()
    if not self.enabled or not self:Probe() or self.windows:NativeOverlay() then return end
    local map,scroll,node=self.api.WorldMapFrame,self.api.WorldMapFrame.ScrollContainer,self.db.Cursor:GetCurrentNode()
    if not shown(map) or not shown(node) or not within(node,map) then return end
    if self.api.GetCurrentKeyBoardFocus and self.api.GetCurrentKeyBoardFocus() then return end
    local canvas=within(node,scroll)
    local details=self.api.QuestMapFrame and self.api.QuestMapFrame.DetailsFrame
    if not canvas and not (shown(details) and within(details,map) and within(node,details)
        and type(self.api.QuestMapFrame_ReturnFromQuestDetails)=='function') then return end
    local registered=false
    for _,frame in ipairs(self.windows:Frames()) do if frame==map then registered=true end end
    if not registered or self.windows:IsMenu(node) or (scroll.IsProtected and scroll:IsProtected()) then return end
    local ancestor=node
    for _=1,32 do
        if self.windows:IsMenu(ancestor) then return end
        if ancestor.GetObjectType and ancestor:GetObjectType()=='EditBox' then return end
        if ancestor==map then break end
        ancestor=ancestor.GetParent and ancestor:GetParent()
        if not ancestor then return end
    end
    local id,art=map:GetMapID(),map.mapArtID
    if self.api.issecretvalue and self.api.issecretvalue(map.isMaximized) then return end
    if not self:Number(id) or id<1 or id%1~=0 or (art~=nil and not self:Number(art)) then return end
    local token=id..':'..tostring(art)..':'..tostring(map:IsMaximized())
    if not canvas then
        if not self:Number(details.questID) or details.questID<1 or (details.returnMapID~=nil and not self:Number(details.returnMapID)) then return end
        return {kind='window',frame=map,data=node,data2=token..':'..details.questID..':'..tostring(details.returnMapID),token='native-map-details',detail=details}
    end
    return {kind='map',frame=map,data=node,data2=token,token='native-map-canvas',axisOwner=self,scroll=scroll}
end
function Map:WaypointProvider(map)
    local mixin=self.api.WaypointLocationDataProviderMixin
    if not mixin or type(map.dataProviders)~='table' then return end
    for provider in pairs(map.dataProviders) do
        if provider.HandleClick==mixin.HandleClick and provider.CanPlacePin==mixin.CanPlacePin then return provider end
    end
end
function Map:Waypoint(context)
    local api,map=self.api,context.frame
    if not api.C_Map or not api.C_Map.CanSetUserWaypointOnMap or not api.C_Map.SetUserWaypoint or not api.C_Map.ClearUserWaypoint
        or not api.C_SuperTrack or not api.C_SuperTrack.SetSuperTrackedUserWaypoint or not api.UiMapPoint
        or not api.UiMapPoint.CreateFromCoordinates or not api.C_GameRules or not api.Enum or not api.Enum.GameRule then return end
    if api.C_GameRules.IsGameRuleActive(api.Enum.GameRule.WorldMapTrackingPinDisabled) then return end
    local provider=self:WaypointProvider(map)
    if not provider then return end
    if provider.pin and shown(provider.pin) and within(context.data,provider.pin) then return {remove=true,pin=provider.pin} end
    local id=map:GetMapID()
    if not api.C_Map.CanSetUserWaypointOnMap(id) then return end
    local cursor=self.db.Cursor
    if not cursor.GetCenter or not cursor.GetEffectiveScale or not map.GetEffectiveScale then return end
    local x,y=cursor:GetCenter()
    local a,b=cursor:GetEffectiveScale(),map:GetEffectiveScale()
    if not self:Number(x) or not self:Number(y) or not self:Number(a) or not self:Number(b) or a<=0 or b<=0 then return end
    if not self:Number(context.scroll.targetScale) or (context.scroll.currentScale~=nil and not self:Number(context.scroll.currentScale)) then return end
    x,y=context.scroll:NormalizeUIPosition(x*a/b,y*a/b)
    if not self:Number(x) or not self:Number(y) or x<0 or x>1 or y<0 or y>1 then return end
    return {id=id,x=x,y=y}
end
function Map:Proxy(kind)
    if self.proxies[kind] then return self.proxies[kind] end
    local button=self.api.CreateFrame('Button',nil,self.api.UIParent)
    button:RegisterForClicks('AnyDown','AnyUp') button:EnableMouse(false)
    button:SetScript('OnClick',function(_,_,down)
        if down or self.api.InCombatLockdown() then return end
        local context=self:Raw()
        if not context then return end
        if kind=='back' then
            if context.frame:IsMaximized() then context.frame:HandleUserActionMinimizeSelf() end
        elseif kind=='detailBack' then
            if context.frame:IsMaximized() then context.frame:HandleUserActionMinimizeSelf()
            else self.api.QuestMapFrame_ReturnFromQuestDetails() end
        else
            local state=self:Waypoint(context)
            if not state then return end
            if state.remove then self.api.C_Map.ClearUserWaypoint()
            else
                local point=self.api.UiMapPoint.CreateFromCoordinates(state.id,state.x,state.y)
                if not self.api.C_Map.SetUserWaypoint(point) then return end
            end
            self.api.C_SuperTrack.SetSuperTrackedUserWaypoint(false)
        end
        self.changed()
    end)
    self.proxies[kind]=button return button
end
function Map:Current()
    local context=self:Raw()
    if not context then return end
    context.routes={PADLTRIGGER=false,PADRTRIGGER=false,PADLSHOULDER=false,PADRSHOULDER=false,PADRSTICK=false}
    if context.kind=='map' then context.routes.PADLSTICK=self:Proxy('waypoint') end
    if context.detail then context.routes[self.cancel]=self:Proxy('detailBack')
    elseif context.frame:IsMaximized() then context.routes[self.cancel]=self:Proxy('back')
    else context.routes[self.cancel]=context.frame.CloseButton or (context.frame.BorderFrame and context.frame.BorderFrame.CloseButton) or false end
    context.chords=self.windows:Chords()
    for key in pairs(context.routes) do for _,modifier in ipairs({'','SHIFT-','CTRL-','CTRL-SHIFT-'}) do context.chords[modifier..key]=nil end end
    local token=context.data2
    local waypoint=context.kind=='map' and self:Waypoint(context)
    local function unchanged()
        local current=self:Raw()
        return current and current.frame==context.frame and current.data==context.data and current.data2==token
    end
    context.validators={[self.cancel]=unchanged,PADLSTICK=function()
        if not unchanged() then return false end
        return Addon.Core.Equal(waypoint,self:Waypoint(context)) and waypoint~=nil
    end}
    return context
end
function Map:Axis(context,stick,x,y,elapsed)
    local scroll=context.scroll
    if not self:Number(elapsed) or elapsed<=0 or elapsed>.25 then return end
    if not self:Number(scroll.targetScale) or (scroll.currentScale~=nil and not self:Number(scroll.currentScale)) then return end
    if not self:Number(scroll:GetCanvasScale()) then return end
    if stick=='Left' then
        if not self:Number(scroll.baseScale) or not scroll:CanPan() then return end
        local a,b=scroll.targetScrollX,scroll.targetScrollY
        local minX,maxX,minY,maxY=scroll.scrollXExtentsMin,scroll.scrollXExtentsMax,scroll.scrollYExtentsMin,scroll.scrollYExtentsMax
        for _,key in ipairs({'targetScrollX','targetScrollY','scrollXExtentsMin','scrollXExtentsMax','scrollYExtentsMin','scrollYExtentsMax'}) do if not self:Number(scroll[key]) then return end end
        if minX>maxX or minY>maxY then return end
        scroll:SetPanTarget(math.max(minX,math.min(maxX,a+x*elapsed*.5)),math.max(minY,math.min(maxY,b-y*elapsed*.5)))
    elseif math.abs(y)>.2 then
        if type(scroll.zoomLevels)~='table' or #scroll.zoomLevels<1 then return end
        for _,level in ipairs(scroll.zoomLevels) do if type(level)~='table' or not self:Number(level.scale) or level.scale<=0 then return end end
        if scroll.mouseWheelZoomMode==self.api.MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_SMOOTH then
            local zoom=scroll.targetScale or scroll:GetCanvasScale()
            if self:Number(zoom) then scroll:SetZoomTarget(zoom+y*elapsed*.75) end
        elseif scroll.mouseWheelZoomMode==self.api.MAP_CANVAS_MOUSE_WHEEL_ZOOM_BEHAVIOR_FULL then
            self.zoomTimer=(self.zoomTimer or 0)+elapsed
            if self.zoomTimer>=self.db('UIholdRepeatDelayFirst') then
                self.zoomTimer=0
                if y>0 then scroll:ZoomIn() else scroll:ZoomOut() end
            end
        end
    end
end
function Map:Stop() self.zoomTimer=nil end
