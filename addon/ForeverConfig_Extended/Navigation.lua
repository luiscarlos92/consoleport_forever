local _, Addon = ...
local kinds = {"Backpack", "Bank", "GuildBank"}
local function module(bb, name)
    if bb and type(bb.GetModule) == "function" then return bb:GetModule(name, true) end
end
local function owner(self)
    local bb = self:GetAddon("BetterBags")
    if bb and type(bb.IsEnabled) == "function" and bb:IsEnabled() and type(bb.Bags) == "table" then return bb end
end
local function visible(frame)
    return frame and type(frame.IsVisible) == "function" and frame:IsVisible()
end
local function hostFor(kind)
    if kind == "Backpack" then return ContainerFrameCombinedBags
    elseif kind == "Bank" then return BankFrame
    elseif kind == "GuildBank" then return GuildBankFrame end
end
local function listed(manager, frame)
    for _, entry in ipairs(manager.shownFrames or {}) do if entry == frame then return true end end
end
local function inside(button, frame)
    for _ = 1, 64 do
        if button == frame then return true end
        if not button or type(button.GetParent) ~= "function" then return false end
        button = button:GetParent()
    end
    return false
end

function Addon:AttachBagPanel(host)
    local state, bb, nav = self.navigation, owner(self), SmartNavigation
    if not self.active or not state or state.stopped or InCombatLockdown() or not bb or not nav
        or type(nav.GetActiveFrame) ~= "function" or type(nav.GetCurrentButton) ~= "function"
        or type(nav.SetUseGridNavigation) ~= "function" or type(nav.RefreshButtonGroups) ~= "function"
        or type(nav.SetScrollFrameForFrame) ~= "function" or type(nav.SelectTopLeftButton) ~= "function"
        or nav:GetActiveFrame() ~= host then return end
    for frame, record in pairs(state.frames) do
        if record.host == host and bb.Bags[record.kind] == record.bag and visible(frame) and not record.closed then
            nav:SetUseGridNavigation(host, false)
            nav:RefreshButtonGroups(host, {frame})
            local scroll = record.bag.scrollBox
            if scroll and (type(scroll.GetDerivedScrollRange) == "function"
                or type(scroll.GetVerticalScrollRange) == "function") then nav:SetScrollFrameForFrame(host, scroll) end
            local button = nav:GetCurrentButton()
            if not visible(button) or not inside(button, frame) then nav:SelectTopLeftButton() end
            return
        end
    end
end

function Addon:QueueBagNavigation()
    local state = self.navigation
    if not state or state.stopped or state.queued then return end
    state.queued = true
    local generation = state.generation
    C_Timer.After(0, function()
        if state.generation ~= generation or state.stopped then return end
        state.queued = false
        self:RefreshBagNavigation()
    end)
end

function Addon:StopBagNavigation()
    local state = self.navigation
    if state then
        state.stopped = true
        state.generation = state.generation + 1
        state.queued = false
    end
end

function Addon:RefreshBagNavigation()
    local state = self.navigation
    if not self.active or not state or state.stopped or InCombatLockdown() then return end
    local bb = owner(self)
    local manager = GamepadMode and GamepadMode.FrameControlsManager
    local nav = SmartNavigation
    if not (manager and type(manager.FrameShown) == "function" and type(manager.FrameHidden) == "function"
        and nav and type(nav.GetActiveFrame) == "function" and type(nav.RefreshButtonGroups) == "function"
        and type(nav.HandlePanelOpen) == "function" and type(nav.SetUseGridNavigation) == "function"
        and type(nav.SelectTopLeftButton) == "function" and type(nav.SetScrollFrameForFrame) == "function"
        and type(nav.GetCurrentButton) == "function"
        and type(SmartNavigation_MarkFrameIgnored) == "function"
        and type(OpenBackpack) == "function" and type(CloseBackpack) == "function"
        and InputUtil and type(InputUtil.IsGamepadUIEnabled) == "function") then
        state.reason = "native navigation not ready"
        return
    end
    if not InputUtil.IsGamepadUIEnabled() then
        for _, record in pairs(state.frames) do record.registered = nil; record.open = true end
        state.reason = "mouse interface"
        return
    end
    state.reason = bb and "ready" or "BetterBags disabled"
    local current = {}
    for _, kind in ipairs(kinds) do
        local bag = bb and bb.Bags[kind]
        local frame, host = bag and bag.frame, hostFor(kind)
        if frame and host and type(frame.HookScript) == "function" and type(bag.Hide) == "function"
            and type(host.IsShown) == "function" and type(host.HookScript) == "function" then
            current[frame] = bag
            local record = state.frames[frame]
            if not record then
                state.sequence = (state.sequence or 0) + 1
                record = {open = true, host = host, sequence = state.sequence}
                state.frames[frame] = record
                frame:HookScript("OnShow", function()
                    state.sequence = state.sequence + 1; record.sequence = state.sequence
                    record.open = true; record.closed = nil; self:QueueBagNavigation()
                end)
                frame:HookScript("OnHide", function() self:QueueBagNavigation() end)
            end
            record.bag, record.kind = bag, kind
            if not state.hosts[host] then
                state.hosts[host] = true
                host:HookScript("OnHide", function()
                    if not host:IsShown() then
                        for _, watched in pairs(state.frames) do
                            if watched.host == host and watched.registered and not watched.open then watched.closed = true end
                        end
                        self:QueueBagNavigation()
                    end
                end)
            end
        end
    end
    -- Exclude BetterBags' decorative copy, not the real native item button.
    for decoration, item in pairs(state.decorations) do
        if bb and item.button ~= decoration and item.frame and type(decoration.GetParent) == "function"
            and decoration:GetParent() == item.frame then SmartNavigation_MarkFrameIgnored(decoration) end
        state.decorations[decoration] = nil
    end
    for frame, record in pairs(state.frames) do
        if record.registered and (not current[frame] or not visible(frame)) then
            record.registered:FrameHidden(record.host)
            record.registered = nil
            if record.kind == "Backpack" and not frame:IsShown() then CloseBackpack() end
        end
    end
    local ordered = {}
    for frame in pairs(current) do ordered[#ordered + 1] = frame end
    table.sort(ordered, function(a, b) return state.frames[a].sequence < state.frames[b].sequence end)
    for _, frame in ipairs(ordered) do
        local bag = current[frame]
        local record, host = state.frames[frame], state.frames[frame].host
        if visible(frame) then
            if record.closed and not record.open then
                local context = module(bb, "Context")
                if context and type(context.New) == "function" then bag:Hide(context:New("ForeverConfig_NativeClose")) end
            else
                if record.open or not record.registered or not listed(manager, host) then
                    local active = nav:GetActiveFrame()
                    local focus = record.open or active == nil or active == host
                    if record.kind == "Backpack" and not host:IsShown() and focus then OpenBackpack() end
                    if host:IsShown() then
                        if record.open and listed(manager, host) then manager:FrameHidden(host) end
                        if listed(manager, host) or manager:FrameShown(host, false, focus) then record.registered = manager end
                        record.open = nil
                        if nav:GetActiveFrame() == host then
                            -- Keep Blizzard's native controller, footer, actions and
                            -- binding stack. The visible addon is an extra panel.
                            nav:HandlePanelOpen(host, {frame})
                            self:AttachBagPanel(host)
                        end
                    else
                        state.reason = "waiting for native bag controller"
                    end
                elseif nav:GetActiveFrame() == host then
                    -- Drawing items must not take focus back from a menu/window.
                    self:AttachBagPanel(host)
                end
            end
        end
    end
end

function Addon:GetBagNavigationStatus()
    local state, bb, nav = self.navigation, owner(self), SmartNavigation
    local active
    if nav and type(nav.GetActiveFrame) == "function" then
        local ok, value = pcall(nav.GetActiveFrame, nav)
        if ok and not (issecretvalue and issecretvalue(value)) and type(value) == "table" then active = value end
    end
    local focused, window = false, nil
    for _, kind in ipairs(kinds) do
        local bag = bb and bb.Bags[kind]
        if bag and visible(bag.frame) and active == hostFor(kind) then focused, window = true, bag.frame end
    end
    return {reason = state and state.reason or "waiting for BetterBags", focused = focused,
        itemActions = focused and active.gamepadFooter and active.gamepadFooter.isShown == true or false,
        frame = active and self:PublicCall(active.GetName, active),
        window = window and self:PublicCall(window.GetName, window)}
end

function Addon:InstallBagNavigation()
    if not self.active or InCombatLockdown() then return end
    local bb = owner(self)
    if not bb then return end
    local state = self.navigation
    if not state then
        state = {generation = 0, frames = setmetatable({}, {__mode = "k"}),
            hosts = setmetatable({}, {__mode = "k"}), decorations = setmetatable({}, {__mode = "kv"})}
        self.navigation = state
    end
    state.stopped = false
    local nav = SmartNavigation
    if nav and type(nav.HandlePanelOpen) == "function" and state.navHook ~= nav then
        state.navHook = nav
        hooksecurefunc(nav, "HandlePanelOpen", function(_, host) self:AttachBagPanel(host) end)
        if type(nav.HandlePanelClose) == "function" then
            hooksecurefunc(nav, "HandlePanelClose", function() self:QueueBagNavigation() end)
        end
    end
    local events = module(bb, "Events")
    if events and type(events.RegisterMessage) == "function" and state.events ~= events then
        state.events = events
        events:RegisterMessage("item/Updated", function(_, item, decoration)
            if type(item) == "table" and decoration then state.decorations[decoration] = item end
            self:QueueBagNavigation()
        end)
        for _, kind in ipairs(kinds) do events:RegisterMessage("bags/Draw/" .. kind .. "/Done", function() self:QueueBagNavigation() end) end
    end
    if not state.transitions and InputUtil and type(InputUtil.RegisterGamepadInit) == "function" then
        state.transitions = true
        InputUtil.RegisterGamepadInit(self, function()
            if state.stopped then return end
            for _, record in pairs(state.frames) do record.registered = nil end
            self:InstallBagNavigation()
        end)
    end
    if not state.designHook and type(bb.WatchBackpackFrame) == "function" then
        state.designHook = true
        hooksecurefunc(bb, "WatchBackpackFrame", function() self:QueueBagNavigation() end)
    end
    local items = module(bb, "ItemFrame")
    for item in pairs(items and items.activeItems or {}) do if item._decoration then state.decorations[item._decoration] = item end end
    self:QueueBagNavigation()
end
