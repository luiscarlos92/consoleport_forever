local _,Addon=...
local Windows={}
Addon.UIWindows=Windows
local controls={'PADLTRIGGER','PADRTRIGGER','PADLSHOULDER','PADRSHOULDER','PADRSTICK'}
local fallbackControls={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDRIGHT','PADDUP','PADDDOWN','PADLSTICK'}
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}
local function shown(frame)
    return frame and frame.IsShown and frame:IsShown() and not (frame.IsForbidden and frame:IsForbidden())
end
local function within(node,ancestor)
    for _=1,32 do
        if not node then return false end
        if node==ancestor then return true end
        node=node.GetParent and node:GetParent()
    end
    return false
end
function Windows.New(db,api,changed)
    return setmetatable({db=db,api=api,changed=changed,order=setmetatable({},{__mode='k'}),
        watched=setmetatable({},{__mode='k'}),serial=0,proxies={}},{__index=Windows})
end
function Windows.CanUse(db)
    return db.Stack and type(db.Stack.GetVisibleCursorFrames)=='function'
        and db.Cursor and type(db.Cursor.SetCurrentNode)=='function'
end
function Windows:Probe()
    return self.enabled and Windows.CanUse(self.db)
end
function Windows:Watch(frame)
    if self.watched[frame] or not frame.HookScript then return end
    self.watched[frame]=true
    frame:HookScript('OnShow',function()
        self.serial=self.serial+1 self.order[frame]=self.serial self.changed()
    end)
    frame:HookScript('OnHide',self.changed)
end
function Windows:Frames()
    local listed={self.db.Stack:GetVisibleCursorFrames()}
    local present={}
    for _,frame in ipairs(listed) do
        if frame~=self.api.UIParent and shown(frame) then present[frame]=true self:Watch(frame) end
    end
    local roots={}
    for frame in pairs(present) do
        local parent,child=frame.GetParent and frame:GetParent(),false
        for _=1,32 do
            if not parent then break end
            if present[parent] then child=true break end
            parent=parent.GetParent and parent:GetParent()
        end
        if not child then roots[#roots+1]=frame end
    end
    table.sort(roots,function(a,b)
        local aa,bb=self.order[a],self.order[b]
        if aa and bb then return aa<bb end
        if aa or bb then return aa~=nil end
        return tostring(a.GetName and a:GetName() or a)<tostring(b.GetName and b:GetName() or b)
    end)
    for _,frame in ipairs(roots) do
        if not self.order[frame] then self.serial=self.serial+1 self.order[frame]=self.serial end
    end
    return roots
end
function Windows:NativeOverlay()
    for header in pairs(self.db.Radial and self.db.Radial.Headers or {}) do
        self:Watch(header)
        if shown(header) then return true end
    end
    if self.api.ColorPickerFrame then self:Watch(self.api.ColorPickerFrame) end
    return shown(self.api.ColorPickerFrame) or shown(self.api.ConsolePortKeyboard)
end
function Windows:IsMenu(frame)
    if frame==self.db.ItemMenu or frame==self.db.SpellMenu or frame==self.db.UnitMenu then return true end
    local name=frame.GetName and frame:GetName() or ''
    if name:match('^L_DropDownList%d+$') or name:match('^DropDownList%d+$') then return true end
    local menu=self.api.Menu
    local manager=menu and type(menu.GetManager)=='function' and menu.GetManager()
    return manager and type(manager.GetOpenMenu)=='function' and manager:GetOpenMenu()==frame or false
end
function Windows:Proxy(kind)
    if self.proxies[kind] then return self.proxies[kind] end
    local button=self.api.CreateFrame('Button',nil,self.api.UIParent)
    button:RegisterForClicks('AnyDown','AnyUp') button:EnableMouse(false)
    button:SetScript('OnClick',function(_,_,down)
        if down or self.api.InCombatLockdown() then return end
        local current=self:Current()
        if not current or current.kind~='window' then return end
        if kind=='previous' or kind=='next' then
            local frames=self:Frames()
            local index
            for i,frame in ipairs(frames) do if frame==current.frame then index=i break end end
            if not index then return end
            local direction=kind=='previous' and -1 or 1
            for offset=1,#frames-1 do
                local target=frames[(index-1+direction*offset)%#frames+1]
                if shown(target) and not self:IsMenu(target) and target~=self.api.WorldMapFrame then
                    self.db.Cursor:SetCurrentNode(target,true)
                    self.changed()
                    return
                end
            end
        elseif kind=='tooltip' then
            local node=current.data
            local tooltip=self.api.GameTooltip
            if not tooltip or not node or not node.GetScript or not node:GetScript('OnEnter') then return end
            if shown(tooltip) and tooltip:GetOwner()==node then tooltip:Hide()
            elseif self.db.Cursor.OnEnterNode then self.db.Cursor:OnEnterNode(node) end
        end
    end)
    self.proxies[kind]=button
    return button
end
function Windows:Tabs(node,owner)
    local mixin=self.api.TabSystemOwnerMixin
    if not mixin then return end
    for _=1,32 do
        if not node or not within(node,owner) then return end
        if node.GetTabSet==mixin.GetTabSet and node.GetTabButton==mixin.GetTabButton and node.GetTab==mixin.GetTab then
            local ids=node:GetTabSet()
            if type(ids)~='table' then return end
            for _,id in ipairs(ids) do if type(id)~='number' or id<1 or id%1~=0 then return end end
            table.sort(ids)
            local selected=node:GetTab()
            local index
            for i,id in ipairs(ids) do if id==selected then index=i break end end
            if not index then return end
            local function target(direction)
                for offset=1,#ids-1 do
                    local id=ids[(index-1+direction*offset)%#ids+1]
                    local button=node:GetTabButton(id)
                    if shown(button) and button.IsEnabled and button:IsEnabled() then return button end
                end
            end
            if not self.watched[node.tabSystem] and node.tabSystem then
                self.watched[node.tabSystem]=true
                self.api.hooksecurefunc(node.tabSystem,'SetTab',self.changed)
                self.api.hooksecurefunc(node,'SetTab',self.changed)
            end
            return target(-1),target(1),selected
        end
        node=node.GetParent and node:GetParent()
    end
end
function Windows:Current()
    if not self:Probe() or self:NativeOverlay() then return end
    local node=self.db.Cursor:GetCurrentNode()
    if not shown(node) then return end
    local owner
    for _,frame in ipairs(self:Frames()) do if within(node,frame) then owner=frame break end end
    if not owner or owner==self.api.WorldMapFrame then return end
    local menu=self:IsMenu(owner)
    local ancestor=node
    for _=1,32 do
        if not ancestor then break end
        if self:IsMenu(ancestor) then owner=ancestor menu=true break end
        if ancestor==owner then break end
        ancestor=ancestor.GetParent and ancestor:GetParent()
    end
    local strata=owner.GetFrameStrata and owner:GetFrameStrata()
    if not menu and (strata=='FULLSCREEN_DIALOG' or strata=='TOOLTIP') then return end
    local routes={}
    for _,key in ipairs(controls) do routes[key]=false end
    local context={kind=menu and 'menu' or 'window',frame=owner,token='native-window',data=node,routes=routes}
    -- Keep actual native priority UI rows. Consume only uncovered chords;
    -- GetBasicControls registers bare keys, unlike native face-click rows.
    -- Neither a saved spell nor a low-priority Bar row is a UI fallback.
    context.chords={}
    for _,key in ipairs(fallbackControls) do for _,modifier in ipairs(modifiers) do
        local chord=modifier..key
        local widget=self.db.Input.Widgets[chord]
        local row=widget and widget:GetOverride(true)
        if not row or row.owner==self.inputOwner then context.chords[chord]=false end
    end end
    if context.kind=='menu' then return context end
    routes.PADLTRIGGER=self:Proxy('previous') routes.PADRTRIGGER=self:Proxy('next')
    local left,right,selected=self:Tabs(node,owner)
    context.data2=selected
    routes.PADLSHOULDER=left or false routes.PADRSHOULDER=right or false
    if self.api.GameTooltip and type(self.api.GameTooltip.GetOwner)=='function' and node and node.GetScript and node:GetScript('OnEnter') and self.db.Cursor.OnEnterNode then
        routes.PADRSTICK=self:Proxy('tooltip')
    end
    return context
end
