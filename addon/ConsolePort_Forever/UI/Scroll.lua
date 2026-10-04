local _,Addon=...
local Scroll={}
Addon.UIScroll=Scroll
local function visible(frame)
    return frame and frame.IsShown and frame:IsShown() and not (frame.IsForbidden and frame:IsForbidden())
end
function Scroll.New(db,api,current,changed)
    return setmetatable({db=db,api=api,current=current,changed=changed,blocked=true},{__index=Scroll})
end
function Scroll:Probe()
    return self.db.Radial and type(self.db.Radial.ToggleFocusFrame)=='function'
        and self.api.ScrollControllerMixin and self.api.ConsolePortUIScrollHandler
        and type(self.api.ConsolePortUIScrollHandler.IsValidScrollController)=='function'
        and type(self.api.IsGamePadCursorControlEnabled)=='function'
        and type(self.api.SetGamePadCursorControl)=='function'
        and type(self.db.Radial.VALID_VEC_LEN)=='number'
        and type(self.db('UIholdRepeatDelayFirst'))=='number'
        and self.db('UIholdRepeatDelayFirst')>=0 and self.db('UIholdRepeatDelayFirst')<math.huge
        and type(self.db('UIholdRepeatDelay'))=='number' and self.db('UIholdRepeatDelay')>0
        and self.db('UIholdRepeatDelay')<math.huge
end
function Scroll:Target(context)
    if not context or context.kind~='window' then return end
    local node=context.data
    for _=1,32 do
        if not node then return end
        if visible(node) and not (node.IsProtected and node:IsProtected())
            and self.api.ConsolePortUIScrollHandler:IsValidScrollController(node) then return node end
        if node==context.frame then return end
        node=node.GetParent and node:GetParent()
    end
end
function Scroll:Stop()
    self.direction=nil self.timer=nil
    self.vectors={} self.neutral={}
    if self.mapContext then self.mapContext.axisOwner:Stop() end
end
function Scroll:Qualified()
    local context=self.current()
    if self.mapContext then
        return self.owned and not self.api.InCombatLockdown() and context and context.kind=='map'
            and context.frame==self.owner and context.data==self.node and context.data2==self.mapContext.data2
            and context.scroll==self.target and context.axisOwner==self.mapContext.axisOwner
    end
    return self.owned and not self.api.InCombatLockdown() and context and context.kind=='window'
        and context.frame==self.owner and context.data==self.node and self:Target(context)==self.target
end
function Scroll:Step()
    if not self:Qualified() then self.blocked=true self:Stop() return end
    if self.target and self.direction then
        -- Audited native scroll-only callback. No arbitrary button clicks,
        -- item operations, secure actions or protected casts from axis/timers.
        self.api.ScrollControllerMixin.OnMouseWheel(self.target,self.direction)
    end
end
function Scroll:Input(x,y,len,stick)
    stick=stick or 'Right'
    if (self.api.issecretvalue and (self.api.issecretvalue(x) or self.api.issecretvalue(y) or self.api.issecretvalue(len)))
        or type(x)~='number' or type(y)~='number' or type(len)~='number'
        or x~=x or y~=y or len~=len or math.abs(x)>1 or math.abs(y)>1 or len<0 or len>2 then
        self.blocked=true self:Stop() return
    end
    if stick=='Left' then self.leftLen=len end
    if not self:Qualified() then self.blocked=true self:Stop() return end
    if self.mapContext then
        if len<=.2 then
            self.neutral[stick]=true self.vectors[stick]=nil
            if stick=='Right' then self.mapContext.axisOwner:Stop() end
            return
        end
        if self.neutral[stick] then self.vectors[stick]={x=x,y=y} end
        return
    end
    if stick=='Left' then if len<=.2 then self.frame.sticks.Left=nil end return end
    if len<=0.2 then self.blocked=false self:Stop() return end
    if self.blocked then return end
    local direction=math.abs(y)>0.2 and (y>0 and 1 or -1) or nil
    if direction~=self.direction then
        self:Stop() self.direction=direction
        if direction then self:Step() self.timer=-self.db('UIholdRepeatDelayFirst') end
    end
end
function Scroll:Create()
    if self.frame then return end
    local frame=self.api.CreateFrame('Frame',nil,self.api.UIParent)
    frame.sticks={Right=true}
    function frame:IsDominantStick(stick) return self.sticks[stick] end
    function frame.OnInput(_,x,y,len,stick) self:Input(x,y,len,stick) end
    frame:SetScript('OnUpdate',function(_,elapsed)
        if self.mapContext then
            if not self:Qualified() then self.blocked=true self:Stop() return end
            for stick,vector in pairs(self.vectors) do self.mapContext.axisOwner:Axis(self.mapContext,stick,vector.x,vector.y,elapsed) end
            return
        end
        if not self.direction then return end
        if not self:Qualified() then self.blocked=true self:Stop() return end
        self.timer=self.timer+elapsed
        if self.timer>self.db('UIholdRepeatDelay') then self.timer=0 self:Step() end
    end)
    self.frame=frame
    self.api.hooksecurefunc('SetGamePadCursorControl',function()
        if not self.changing then self.previousCursor=nil end
    end)
    self.api.hooksecurefunc(self.db.Radial,'ToggleFocusFrame',function(_,owner,enabled)
        if self.changing or owner==self.frame then return end
        if enabled then
            self.foreign=owner self.owned=nil self.previousCursor=nil self.blocked=true self:Stop()
        elseif owner==self.foreign then self.foreign=nil end
        self.changed()
    end)
end
function Scroll:Release()
    self.blocked=true self:Stop()
    if not self.owned then return end
    self.owned=nil
    self.changing=true
    self.db.Radial:ToggleFocusFrame(self.frame,false)
    if self.previousCursor==true and not self.api.IsGamePadCursorControlEnabled() then
        self.api.SetGamePadCursorControl(true)
    end
    self.changing=nil self.previousCursor=nil
end
function Scroll:Apply(context)
    if not self:Probe() then self:Release() return false,'audited native right-stick dispatcher/scroll APIs unavailable' end
    self:Create()
    if self.api.InCombatLockdown() or not context or (context.kind~='window' and context.kind~='map') or self.foreign then
        self:Release() return true
    end
    local isMap=context.kind=='map'
    local target=isMap and context.scroll or self:Target(context)
    if context.frame~=self.owner or context.data~=self.node or target~=self.target
        or isMap~=(self.mapContext~=nil) or (isMap and context.data2~=self.mapContext.data2) then
        self.blocked=true self:Stop()
        self.owner,self.node,self.target=context.frame,context.data,target
    end
    self.mapContext=isMap and context or nil
    self.frame.sticks.Left=isMap or (self.leftLen and self.leftLen>.2) or nil
    if not self.owned then
        self.previousCursor=self.api.IsGamePadCursorControlEnabled()
        self.changing=true self.db.Radial:ToggleFocusFrame(self.frame,true) self.changing=nil
        self.owned=true self.blocked=true
    end
    return true
end
