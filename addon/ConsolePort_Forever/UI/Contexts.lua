local _,Addon=...
local Contexts={watched=setmetatable({},{__mode='k'})}
Addon.UIContexts=Contexts
local controls={'PAD1','PAD2','PAD3','PAD4','PADRSTICK','PADDLEFT','PADDRIGHT','PADDUP','PADDDOWN','PADLTRIGGER','PADRTRIGGER','PADLSHOULDER','PADRSHOULDER'}
local function visible(frame)
    return frame and frame.IsShown and frame:IsShown() and not (frame.IsForbidden and frame:IsForbidden())
end
function Contexts:Probe(bridge,api)
    local db=bridge.db
    if bridge.api.version~='3.3.3' or not db.Cursor or type(db.Cursor.GetCurrentNode)~='function'
        or not Addon.InputBridge.Probe(db.Input,api) or type(api.StaticPopup_ForEachShownDialog)~='function' then
        return false,'audited native popup/cursor/input APIs unavailable'
    end
    return true
end
function Contexts:Watch(frame,owner)
    if not frame or self.watched[frame] or not frame.HookScript then return end
    self.watched[frame]=true
    for _,event in ipairs({'OnShow','OnHide','OnEnable','OnDisable'}) do
        if not frame.HasScript or frame:HasScript(event) then frame:HookScript(event,function() self:Refresh(owner and event=='OnShow') end) end
    end
    if frame.SetText then self.api.hooksecurefunc(frame,'SetText',function() self:Refresh() end) end
    if frame==self.api.StackSplitFrame and frame.OpenStackSplitFrame then self.api.hooksecurefunc(frame,'OpenStackSplitFrame',function() self:Refresh(true) end) end
end
function Contexts:Current()
    local api,cursor=self.api,self.db.Cursor
    if not visible(cursor) or cursor.isCombatPaused then return nil end
    if api.ConsolePortKeyboard then self:Watch(api.ConsolePortKeyboard,false) end
    if visible(api.ConsolePortKeyboard) then return nil end
    if self.scroll and self.scroll.foreign then return nil end
    local shown={}
    api.StaticPopup_ForEachShownDialog(function(frame)
        if visible(frame) then shown[frame]=true self:Watch(frame,true) end
    end)
    local node=cursor:GetCurrentNode()
    local owner
    for _=1,16 do
        if not node then break end
        if shown[node] or node==api.StackSplitFrame then owner=node break end
        if node.GetOwningDialog then
            local dialog=node:GetOwningDialog()
            if shown[dialog] then owner=dialog break end
        end
        node=node.GetParent and node:GetParent()
    end
    if not visible(owner) then
        local window=self.windows and self.windows:Current()
        if window then
            self:Watch(window.frame,false)
            self:Watch(window.data,false)
            for _,target in pairs(window.routes) do if target then self:Watch(target,false) end end
        end
        return window
    end
    local routes={}
    for _,key in ipairs(controls) do routes[key]=false end
    local context={frame=owner,routes=routes}
    if owner==api.StackSplitFrame then
        context.kind='quantity' context.token='native-stack-split' context.data=owner.owner
        routes.PAD1=owner.OkayButton or false routes.PAD2=owner.CancelButton or false
        routes.PADDLEFT=owner.LeftButton or false routes.PADDRIGHT=owner.RightButton or false
    else
        if type(owner.GetButton)~='function' then return nil end
        context.kind='popup' context.token=owner.which context.data=owner.data context.data2=owner.data2
        routes.PAD1=owner:GetButton(1) or false routes.PAD2=owner:GetButton(2) or false
        routes.PAD3=owner:GetButton(3) or false routes.PAD4=owner:GetButton(4) or false
        routes.PADRSTICK=owner.ExtraButton or false
    end
    if api.issecretvalue and (api.issecretvalue(context.token) or api.issecretvalue(context.data) or api.issecretvalue(context.data2)) then return nil end
    self:Watch(owner,true)
    for _,target in pairs(routes) do if target then self:Watch(target,false) end end
    return context
end
function Contexts:Refresh(force)
    if self.refreshing or not self.input then return end
    self.refreshing=true
    local ok,result,reason=pcall(function()
        if not self.enabled or self.api.InCombatLockdown() then
            if self.scroll then self.scroll:Release() end
            return self.input:Release()
        end
        local context=self:Current()
        local applied,error=self.input:Apply(context,force)
        self.context=context
        if self.scroll then
            local scrolling,scrollError=self.scroll:Apply(context)
            Addon.Diagnostics:SetFeature('windowScroll',scrolling and 'offline-verified' or 'pending',scrollError or 'native right-stick dispatcher and audited ScrollController mouse-wheel callback; other widgets/Retail propagation pending')
        end
        return applied,error
    end)
    self.refreshing=nil
    if not ok or not result then
        self.input:Release()
        Addon.Diagnostics:SetFeature('uiContexts','recovery-required',tostring(reason or result))
        return false,reason or result
    end
    if self.enabled then
        Addon.Diagnostics:SetFeature('popups','offline-verified','focused native buttons 1–4/extra; Retail input/taint acceptance pending')
        Addon.Diagnostics:SetFeature('quantity',self.api.StackSplitFrame and 'offline-verified' or 'pending',self.api.StackSplitFrame and 'native quantity buttons/bounds; Retail input acceptance pending' or 'native StackSplitFrame not loaded')
        Addon.Diagnostics:SetFeature('windows',self.windows.enabled and 'offline-verified' or 'pending',self.windows.enabled and 'registered-window triggers, audited native tabs and focused tooltip; Retail input acceptance pending' or 'registered-window policy has not been accepted')
    end
    return true
end
function Contexts:Enable(bridge,api,enabled,windowsEnabled)
    self.enabled=not not enabled
    if not enabled then if self.input then return self:Refresh() end return true end
    local ready,reason=self:Probe(bridge,api)
    if not ready then return false,reason end
    self.api,self.db=api,bridge.db
    self.windows=self.windows or Addon.UIWindows.New(self.db,api,function() self:Refresh() end)
    self.windows.enabled=not not windowsEnabled
    self.scroll=self.scroll or Addon.UIScroll.New(self.db,api,function() return self:Current() end,function() self:Refresh() end)
    if not self.input then
        self.input=Addon.InputBridge.New(self.db.Input,api)
    end
    self.windows.inputOwner=self.input.owner
    if not self.registered then
        self.registered=true
        self:Watch(self.db.Cursor,false)
        for _,method in ipairs({'SetBasicControls','SetCurrentNode','OnEnterNode','OnLeaveNode','Release'}) do
            if type(self.db.Cursor[method])=='function' then api.hooksecurefunc(self.db.Cursor,method,function() self:Refresh() end) end
        end
        for _,method in ipairs({'SetButton','SetCommand','SetGlobal','SetMacro','Release'}) do
            if type(self.db.Input[method])=='function' then api.hooksecurefunc(self.db.Input,method,function()
                if not self.input.applying then self:Refresh() end
            end) end
        end
        api.hooksecurefunc('StaticPopup_Show',function() self:Refresh(true) end)
        if api.StackSplitFrame then
            self:Watch(api.StackSplitFrame,true)
        end
        if api.ConsolePortKeyboard then self:Watch(api.ConsolePortKeyboard,false) end
    end
    return self:Refresh()
end
