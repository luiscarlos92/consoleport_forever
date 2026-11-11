local _, NS = ...
local Core, Rewards = NS.Core, {}
Rewards.__index = Rewards
NS.Rewards = Rewards

function Rewards.New(api)
    return setmetatable({api = api, generation = 0, pending = {}, confirmed = {}, links = {},
        arrows = setmetatable({}, {__mode = 'k'}), hooked = setmetatable({}, {__mode = 'k'}),
        queries = 0, attempts = 0}, Rewards)
end

function Rewards:Observe()
    local api = self.api
    if self.observed or not Core.Loaded(api, 'Pawn')
        or type(api.PawnInitializePlugins) ~= 'function' or type(api.PawnInitialize) ~= 'function'
        or type(api.hooksecurefunc) ~= 'function' or not api.C_Timer
        or type(api.C_Timer.After) ~= 'function' then return end
    self.observed = true
    api.hooksecurefunc('PawnInitializePlugins', function() self.initializing = true end)
    api.hooksecurefunc('PawnInitialize', function()
        if not self.initializing then return end
        self.initializing = nil
        api.C_Timer.After(0, function()
            self.ready = true
            self:Start()
        end)
    end)
end

function Rewards:Available()
    local api = self.api
    local frame = self.frame
    local rewards = frame and frame.TalkBox and frame.TalkBox.Elements
        and frame.TalkBox.Elements.Content and frame.TalkBox.Elements.Content.RewardsFrame
    return self.ready and self.installed and Core.Loaded(api, 'Pawn')
        and Core.Loaded(api, 'Immersion') and api.ImmersionFrame == self.frame
        and rewards and type(rewards.Buttons) == 'table'
        and type(api.PawnCommon) == 'table'
end

function Rewards:Identity(item)
    local api, frame = self.api, self.frame
    if not self.open or not self:Available() or not frame:IsVisible() or not item
        or type(item.IsVisible) ~= 'function' or not item:IsVisible()
        or (type(item.IsProtected) == 'function' and item:IsProtected())
        or not Core.Known(api, item.objectType) or item.objectType ~= 'item'
        or not Core.Known(api, item.type) or (item.type ~= 'choice' and item.type ~= 'reward')
        or type(item.GetID) ~= 'function' then return end
    local quest = api.GetQuestID()
    if not Core.Finite(api, quest) or quest <= 0 or not Core.Known(api, item.questID)
        or item.questID ~= quest or quest ~= self.quest then return end
    local rewards = frame.TalkBox.Elements.Content.RewardsFrame
    if rewards.Buttons ~= self.buttons then return end
    local owned = false
    for _, button in ipairs(self.buttons) do if item == button then owned = true; break end end
    if not owned then return end
    local id = item:GetID()
    if not Core.Finite(api, id) or id < 1 or id % 1 ~= 0 then return end
    local link = api.GetQuestItemLink(item.type, id)
    if Core.Known(api, link) and type(link) == 'string' and link ~= '' then return link, quest end
end

function Rewards:ClearArrow(item)
    if self.confirmed[item] then
        self.confirmed[item] = nil
        self.arrows[item]:Hide()
    end
end

function Rewards:Update(item)
    local arrow = self.arrows[item]
    local link = self:Identity(item)
    if link ~= self.links[item] then
        self.links[item] = link
        self.attempts = 0
    end
    self.pending[item] = nil
    if self.confirmed[item] ~= link then self:ClearArrow(item) end
    if not link then return end
    self.queries = self.queries + 1
    local verdict = self.api.PawnShouldItemLinkHaveUpgradeArrow(link, true)
    if not Core.Known(self.api, verdict) then
        self:ClearArrow(item)
        return
    end
    if verdict == nil then
        self.pending[item] = {link = link, generation = self.generation}
    elseif verdict == true then
        if not arrow then
            if type(item.CreateTexture) ~= 'function' or not item.Icon then return end
            arrow = item:CreateTexture(nil, 'OVERLAY', nil, 1)
            arrow:SetAtlas('bags-greenarrow', true)
            arrow:SetPoint('TOPLEFT', item.Icon, 'TOPLEFT', 0, 0)
            self.arrows[item] = arrow
        end
        if not self.confirmed[item] then
            self.confirmed[item] = link
            arrow:Show()
        end
    else
        self:ClearArrow(item)
    end
end

function Rewards:Schedule()
    if self.timer or not self.open or not next(self.pending) or self.attempts >= 8 then return end
    local generation = self.generation
    self.timer = self.api.C_Timer.NewTimer(.25, function()
        self.timer = nil
        if not self.open or self.generation ~= generation then return end
        self.attempts = self.attempts + 1
        local pending = self.pending
        self.pending = {}
        for item, record in pairs(pending) do
            if record.generation == generation and self:Identity(item) == record.link
                and self.api.PawnCommon.ShowQuestUpgradeAdvisor == true
                and type(self.api.PawnShouldItemLinkHaveUpgradeArrow) == 'function' then
                self:Update(item)
            else
                self:ClearArrow(item)
            end
        end
        self:Schedule()
    end)
end

function Rewards:ResetArrows()
    self.generation = self.generation + 1
    if self.timer then self.timer:Cancel(); self.timer = nil end
    for item in pairs(self.confirmed) do self:ClearArrow(item) end
    self.pending = {}
    self.attempts = 0
end

function Rewards:Close()
    self.open, self.quest, self.buttons = false, nil, nil
    self.dirty, self.contextChanged = nil, nil
    self.links = {}
    self:ResetArrows()
end

function Rewards:Start(contextChanged)
    if not self:Available() or not self.frame:IsVisible() then self:Close(); return end
    local quest = self.api.GetQuestID()
    if not Core.Finite(self.api, quest) or quest <= 0 then self:Close(); return end
    local buttons = self.frame.TalkBox.Elements.Content.RewardsFrame.Buttons
    if self.quest ~= quest or self.buttons ~= buttons then self:Close() end
    self.quest, self.buttons = quest, buttons
    self.open = true
    if self.api.PawnCommon.ShowQuestUpgradeAdvisor ~= true
        or type(self.api.PawnShouldItemLinkHaveUpgradeArrow) ~= 'function' then
        self:ResetArrows()
        return
    end
    if contextChanged then self:ResetArrows() end
    for item, link in pairs(self.confirmed) do
        if self:Identity(item) ~= link then self:ClearArrow(item) end
    end
    for _, item in ipairs(buttons) do self:Update(item) end
    self:Schedule()
end

function Rewards:Invalidate(contextChanged)
    if not self.open then return end
    self.contextChanged = self.contextChanged or contextChanged
    if self.dirty then return end
    local token = {}
    self.dirty = token
    self.api.C_Timer.After(0, function()
        if self.dirty ~= token then return end
        local changed = self.contextChanged
        self.dirty, self.contextChanged = nil, nil
        if not self.open then return end
        self:Start(changed)
        if changed and self.onContextChanged then self.onContextChanged() end
    end)
end

function Rewards:Install()
    local api, frame = self.api, self.api.ImmersionFrame
    local rewards = frame and frame.TalkBox and frame.TalkBox.Elements
        and frame.TalkBox.Elements.Content and frame.TalkBox.Elements.Content.RewardsFrame
    if not Core.Loaded(api, 'Immersion') or not rewards or type(rewards.Buttons) ~= 'table'
        or type(frame.UpdateItems) ~= 'function' or type(frame.HookScript) ~= 'function'
        or type(frame.IsVisible) ~= 'function' or type(api.hooksecurefunc) ~= 'function'
        or type(api.GetQuestID) ~= 'function' or type(api.GetQuestItemLink) ~= 'function'
        or not api.C_Timer or type(api.C_Timer.NewTimer) ~= 'function'
        or type(api.C_Timer.After) ~= 'function' then
        self:Close()
        self.installed = false
        return false
    end
    if self.frame ~= frame then self:Close() end
    self.frame, self.installed = frame, true
    if not self.hooked[frame] then
        self.hooked[frame] = true
        api.hooksecurefunc(frame, 'UpdateItems', function() if self.frame == frame then self:Start() end end)
        frame:HookScript('OnHide', function() if self.frame == frame then self:Close() end end)
    end
    if Core.Loaded(api, 'Pawn') then
        if not self.resetHooks then
            self.resetHooks = true
            for _, name in ipairs({'PawnResetTooltips', 'PawnInvalidateBestItems', 'PawnInvalidateBestItemsForScale'}) do
                if type(api[name]) == 'function' then
                    api.hooksecurefunc(name, function() self:Invalidate(true) end)
                end
            end
            if type(api.PawnResetBags) == 'function' then
                api.hooksecurefunc('PawnResetBags', function() self:Invalidate() end)
            end
        end
        local checkbox = api.PawnUIFrame_ShowQuestUpgradeAdvisorCheck
        if checkbox and self.advisorCheckbox ~= checkbox and type(checkbox.HookScript) == 'function' then
            self.advisorCheckbox = checkbox
            checkbox:HookScript('OnClick', function()
                if self.advisorCheckbox == checkbox then self:Invalidate() end
            end)
        end
    end
    return true
end

function Rewards:Event(event, id, success)
    if not self.open then return end
    local api = self.api
    if event == 'PLAYER_SPECIALIZATION_CHANGED' and (not Core.Known(api, id) or id ~= 'player') then return end
    if event == 'GET_ITEM_INFO_RECEIVED' or event == 'ITEM_DATA_LOAD_RESULT' then
        if not Core.Known(api, id) or not Core.Known(api, success) or success == false
            or not api.C_Item or type(api.C_Item.GetItemInfoInstant) ~= 'function' then return end
        local matches = false
        for _, item in ipairs(self.buttons or {}) do
            local link = self:Identity(item)
            local itemID = link and api.C_Item.GetItemInfoInstant(link)
            if Core.Known(api, itemID) and itemID == id then matches = true; break end
        end
        if not matches then return end
    end
    self:Invalidate(event == 'PLAYER_EQUIPMENT_CHANGED' or event == 'PLAYER_SPECIALIZATION_CHANGED')
end
