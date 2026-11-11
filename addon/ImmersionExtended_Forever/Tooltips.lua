local _, NS = ...
local Core, Tooltips = NS.Core, {}
Tooltips.__index = Tooltips
NS.Tooltips = Tooltips

function Tooltips.New(api, rewards)
    return setmetatable({api = api, rewards = rewards, records = {},
        frames = setmetatable({}, {__mode = 'k'}),
        inspectors = setmetatable({}, {__mode = 'k'}),
        layouts = setmetatable({}, {__mode = 'k'}), annotations = 0}, Tooltips)
end

function Tooltips:Identity(tooltip, item)
    local api, frame, inspector = self.api, self.frame, self.inspector
    local button = tooltip and tooltip.Button
    local pool = inspector and inspector.tooltipFramePool
    if not frame or frame ~= api.ImmersionFrame or frame.Inspector ~= inspector
        or not pool or type(pool.active) ~= 'table' or not pool.active[tooltip]
        or not inspector:IsVisible() or type(tooltip.IsVisible) ~= 'function' or not tooltip:IsVisible()
        or (type(tooltip.IsProtected) == 'function' and tooltip:IsProtected())
        or not button or button.item ~= item or button.inspector ~= inspector or button.pool ~= pool
        or type(tooltip.GetName) ~= 'function' then return end
    local name = tooltip:GetName()
    if type(name) ~= 'string' or api[name] ~= tooltip then return end
    local link, quest = self.rewards:Identity(item)
    if link then return link, quest, name end
end

function Tooltips:DataReady(link)
    local api = self.api
    if not api.PawnCanItemHaveStats(link) then return true end
    local data = api.PawnGetItemData(link)
    return type(data) == 'table' and Core.Known(api, data.Link)
        and type(data.Link) == 'string' and data.Link ~= ''
end

function Tooltips:Available()
    local api = self.api
    return self.rewards:Available() and type(api.PawnCommon.Scales) == 'table'
        and type(api.PawnUpdateTooltip) == 'function'
        and type(api.PawnCanItemHaveStats) == 'function' and type(api.PawnGetItemData) == 'function'
end

function Tooltips:TrackLayout(tooltip)
    if self.layouts[tooltip] or type(tooltip.GetScript) ~= 'function'
        or type(tooltip.HookScript) ~= 'function' then return end
    local onShow = tooltip:GetScript('OnShow')
    if type(onShow) ~= 'function' then return end
    local layout = {onShow = onShow}
    self.layouts[tooltip] = layout
    local function pending()
        layout.pending = true
        self.api.C_Timer.After(0, function() layout.pending = false end)
    end
    -- Native Show has already queued its icon padding before the setter post-hook.
    pending()
    tooltip:HookScript('OnShow', pending)
end

function Tooltips:Repopulate(tooltip, item)
    self.frame:SetItemTooltip(tooltip, item)
    local layout = self.layouts[tooltip]
    if layout and not layout.pending then
        -- A visible tooltip does not run OnShow again during a native refresh.
        layout.onShow(tooltip)
        layout.pending = true
        self.api.C_Timer.After(0, function() layout.pending = false end)
    end
end

function Tooltips:Current(tooltip, record)
    local link, quest = self:Identity(tooltip, record.item)
    return link == record.link and quest == record.quest
end

function Tooltips:Schedule()
    if self.timer then return end
    for _, record in pairs(self.records) do
        if record.remaining > 0 then
            self.timer = self.api.C_Timer.NewTimer(.25, function()
                self.timer = nil
                if not self:Available() then self:Clear(); return end
                for tooltip, current in pairs(self.records) do
                    if not self:Current(tooltip, current) then
                        self.records[tooltip] = nil
                    elseif current.remaining > 0 then
                        current.remaining = current.remaining - 1
                        if self:DataReady(current.link) then self:Repopulate(tooltip, current.item) end
                    end
                end
                self:Schedule()
            end)
            return
        end
    end
end

function Tooltips:Populate(tooltip, item)
    if not tooltip then return end
    self.records[tooltip] = nil
    if not self:Available() then return end
    local link, quest, name = self:Identity(tooltip, item)
    if not link then return end
    self:TrackLayout(tooltip)
    local ready = self:DataReady(link)
    self.records[tooltip] = {item = item, link = link, quest = quest, remaining = ready and 0 or 8}
    if ready then
        -- The native setter identifies the item. GetItem need not echo the full quest link.
        self.api.PawnUpdateTooltip(name, 'SetHyperlink', link)
        self.annotations = self.annotations + 1
    else
        self:Schedule()
    end
end

function Tooltips:Refresh()
    if not self:Available() then self:Clear(); return end
    for tooltip, record in pairs(self.records) do
        if self:Current(tooltip, record) then
            self:Repopulate(tooltip, record.item)
        else
            self.records[tooltip] = nil
        end
    end
end

function Tooltips:Clear()
    if self.timer then self.timer:Cancel(); self.timer = nil end
    self.records = {}
end

function Tooltips:Install(frame)
    local inspector = frame and frame.Inspector
    if not inspector or type(frame.SetItemTooltip) ~= 'function'
        or type(inspector.IsVisible) ~= 'function' or type(inspector.HookScript) ~= 'function' then
        self.frame, self.inspector = nil, nil
        self:Clear()
        return
    end
    if self.frame ~= frame or self.inspector ~= inspector then self:Clear() end
    self.frame, self.inspector = frame, inspector
    if not self.frames[frame] then
        self.frames[frame] = true
        self.api.hooksecurefunc(frame, 'SetItemTooltip', function(_, tooltip, item)
            if self.frame == frame then self:Populate(tooltip, item) end
        end)
        frame:HookScript('OnHide', function() if self.frame == frame then self:Clear() end end)
    end
    if not self.inspectors[inspector] then
        self.inspectors[inspector] = true
        inspector:HookScript('OnHide', function() if self.inspector == inspector then self:Clear() end end)
    end
end
