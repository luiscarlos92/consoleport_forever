local _,Addon=...
local Bridge={};Bridge.__index=Bridge
local Integration={};Addon.PawnImmersion=Integration
local observed=setmetatable({},{__mode='k'})
local function known(api,value)
    return not api.issecretvalue or not api.issecretvalue(value)
end
local function version(api,name,value)
    return api.C_AddOns and api.C_AddOns.IsAddOnLoaded(name)
        and api.C_AddOns.GetAddOnMetadata(name,'Version')==value
end

-- Pawn's readiness flag is private. Observe its real initialization boundary:
-- PawnInitializePlugins is reached after that flag, then defer beyond the final
-- scale corrections. OptionalDeps puts this observer before PLAYER_LOGIN.
function Integration:Observe(api)
    if observed[api] or not version(api,'Pawn','2.13.17')
        or type(api.PawnInitializePlugins)~='function' or type(api.PawnInitialize)~='function'
        or type(api.hooksecurefunc)~='function'
        or not api.C_Timer or type(api.C_Timer.After)~='function' then return end
    local state={};observed[api]=state
    api.hooksecurefunc('PawnInitializePlugins',function()
        state.reached=true
    end)
    api.hooksecurefunc('PawnInitialize',function()
        if not state.reached then return end
        state.reached=nil
        api.C_Timer.After(0,function()
            state.ready=true
            local instance=self.instance
            if instance and instance.api==api and instance.installed then
                instance:Start(instance.frame.TalkBox.Elements.Content.RewardsFrame.Buttons)
            end
        end)
    end)
end
function Integration.New(owner,api)
    return setmetatable({owner=owner,api=api,generation=0,pending={},tips={},arrows={},
        layouts={},work={queries=0,annotations=0,refreshes=0}},Bridge)
end
function Bridge:Allowed()
    local owner=self.owner
    if not owner or owner.busy or not owner:IsCharacterInstalled() or not owner.db
        or not owner.record or owner.record.pendingBindingSelection then return false end
    for _,journal in pairs(owner.db.transactions or {}) do
        if journal.guid==owner.guid and (journal.status=='applying' or journal.status=='recovery-required') then return false end
    end
    return true
end
function Bridge:Available()
    local api=self.api
    return self:Allowed() and version(api,'Pawn','2.13.17') and version(api,'Immersion','1.4.61')
        and observed[api] and observed[api].ready and self.frame and self.inspector and self.pool
        and api.ImmersionFrame==self.frame
        and self.frame.Inspector==self.inspector and self.inspector.tooltipFramePool==self.pool
        and type(api.PawnShouldItemLinkHaveUpgradeArrow)=='function'
        and type(api.PawnGetItemData)=='function' and type(api.PawnCanItemHaveStats)=='function'
        and type(api.PawnUpdateTooltip)=='function'
end
function Bridge:Eligible(item)
    local quest=self.api.GetQuestID()
    if not self.open or not self:Available() or not self.frame:IsVisible()
        or not item or type(item.IsVisible)~='function' or not item:IsVisible() or item.objectType~='item'
        or (item.type~='choice' and item.type~='reward') or not known(self.api,item.questID)
        or not known(self.api,quest) or item.questID~=quest then return false end
    local rewards=self.frame.TalkBox.Elements.Content.RewardsFrame
    if rewards.Buttons~=self.buttons then return false end
    for _,button in ipairs(self.buttons) do if button==item then return true end end
    return false
end
function Bridge:Identity(item)
    if not self:Eligible(item) then return end
    local link=self.api.GetQuestItemLink(item.type,item:GetID())
    if not known(self.api,link) or type(link)~='string' then return end
    return link
end
function Bridge:Arrow(item)
    local arrow=self.arrows[item]
    if not arrow then
        arrow=item:CreateTexture(nil,'OVERLAY',nil,1)
        arrow:SetAtlas('bags-greenarrow',true)
        arrow:SetPoint('TOPLEFT',item.Icon,'TOPLEFT',0,0)
        arrow:Hide();self.arrows[item]=arrow
    end
    return arrow
end
function Bridge:BagUsesPawn()
    local api=self.api
    if not (version(api,'BetterBags','v0.5.14') or version(api,'BetterBags','v0.5.16'))
        or not api.LibStub then return false end
    local ace=api.LibStub('AceAddon-3.0',true)
    local bags=ace and ace:GetAddon('BetterBags',true)
    local items=bags and bags:GetModule('Items',true)
    return items and type(items.GetActiveUpgradeProvider)=='function'
        and items:GetActiveUpgradeProvider()=='Pawn'
end
function Bridge:UpdateArrow(item)
    local old=self.arrows[item];if old then old:Hide() end
    local link=self:Identity(item)
    if not link or not self:BagUsesPawn() then self.pending[item]=nil;return end
    self.work.queries=self.work.queries+1
    local verdict=self.api.PawnShouldItemLinkHaveUpgradeArrow(link,true)
    if verdict==nil then self.pending[item]={link=link,generation=self.generation};return end
    self.pending[item]=nil
    if verdict==true then self:Arrow(item):Show() end
end
function Bridge:TooltipOwned(tooltip)
    if not tooltip or not self.pool.active[tooltip] or not self.inspector:IsVisible()
        or not tooltip:IsVisible() then return false end
    local name=tooltip:GetName()
    return type(name)=='string' and name:match('^ImmersionGameTooltip%d+$')
        and self.api[name]==tooltip and type(tooltip.GetItem)=='function'
end
function Bridge:Annotate(tooltip,item)
    local link=self:Identity(item)
    if not link or not self:TooltipOwned(tooltip) then return end
    local _,shownLink=tooltip:GetItem()
    if not known(self.api,shownLink) or (shownLink~=nil and shownLink~=link) then return end
    local record=self.tips[tooltip]
    if record and record.link==link and record.annotated then return end
    record={item=item,link=link,generation=self.generation};self.tips[tooltip]=record
    if shownLink==nil then
        record.pending=true
        self.pending[item]={link=link,generation=self.generation};self:Schedule();return
    end
    if self.api.PawnCanItemHaveStats(link) then
        local data=self.api.PawnGetItemData(link)
        if not data or not data.Link then
            record.pending=true
            self.pending[item]={link=link,generation=self.generation};self:Schedule();return
        end
    end
    -- Supply the full quest link to Pawn; keep Immersion's SetQuestItem and all
    -- quest context, compare ownership, formatting and option handling intact.
    self.work.annotations=self.work.annotations+1
    self.api.PawnUpdateTooltip(tooltip:GetName(),'SetHyperlink',link)
    record.annotated=true
end
function Bridge:RetryTip(item)
    for tooltip,record in pairs(self.tips) do
        if record.item==item and record.pending and record.generation==self.generation
            and self:TooltipOwned(tooltip) then self:Repopulate(tooltip,item) end
    end
end
function Bridge:LayoutPending(tooltip,layout)
    layout.pending=true
    self.api.C_Timer.After(0,function() layout.pending=false end)
end
function Bridge:TrackLayout(tooltip)
    if self.layouts[tooltip] then return end
    local layout={onShow=tooltip:GetScript('OnShow')};self.layouts[tooltip]=layout
    -- The first native Show has already queued its icon padding before our
    -- population posthook. Later Shows keep the same native measurement owner.
    self:LayoutPending(tooltip,layout)
    tooltip:HookScript('OnShow',function() self:LayoutPending(tooltip,layout) end)
end
function Bridge:Repopulate(tooltip,item)
    self.frame:SetItemTooltip(tooltip,item)
    local layout=self.layouts[tooltip]
    if layout and not layout.pending and layout.onShow then
        -- Refreshing an already shown tooltip does not fire OnShow. Reuse its
        -- native padding handler once, without hiding it or disrupting L2.
        layout.onShow(tooltip);self:LayoutPending(tooltip,layout)
    end
end
function Bridge:Schedule()
    if self.timer or not next(self.pending) or self.attempts>=8 then return end
    local generation=self.generation
    self.timer=self.api.C_Timer.NewTimer(.25,function()
        self.timer=nil
        if generation~=self.generation or not self.open then return end
        self.attempts=self.attempts+1
        local pending=self.pending;self.pending={}
        for item,record in pairs(pending) do
            if generation==record.generation and self:Identity(item)==record.link then
                self:UpdateArrow(item);self:RetryTip(item)
            end
        end
        self:Schedule()
    end)
end
function Bridge:Close()
    self.open=false;self.generation=self.generation+1
    if self.timer then self.timer:Cancel();self.timer=nil end
    for _,arrow in pairs(self.arrows) do arrow:Hide() end
    self.pending={};self.tips={}
end
function Bridge:Start(buttons)
    local tips=self.tips
    self:Close();self.buttons=buttons;self.attempts=0
    if not self:Available() or not self.frame:IsVisible() then return end
    self.open=true
    for _,item in ipairs(buttons) do self:UpdateArrow(item) end
    -- Immersion also calls UpdateItems for events which retain its inspector.
    -- Carry only the same active tooltip/item/link into the new generation.
    for tooltip,record in pairs(tips) do
        if self:TooltipOwned(tooltip) and self:Identity(record.item)==record.link then
            local _,link=tooltip:GetItem()
            if known(self.api,link) and (link==record.link or (link==nil and record.pending)) then
                record.generation=self.generation;self.tips[tooltip]=record
                if record.pending then self.pending[record.item]={link=record.link,generation=self.generation} end
            end
        end
    end
    self:Schedule()
end
function Bridge:Invalidate()
    if not self.open or self.dirty then return end
    self.dirty=true;local generation=self.generation
    self.api.C_Timer.After(0,function()
        self.dirty=false
        if generation~=self.generation or not self.open then return end
        if not self:Available() or not self.frame:IsVisible() then self:Close();return end
        self.work.refreshes=self.work.refreshes+1;self.attempts=0;self.pending={}
        for _,item in ipairs(self.buttons) do self:UpdateArrow(item) end
        for tooltip,record in pairs(self.tips) do
            if self:TooltipOwned(tooltip) and self:Identity(record.item)==record.link then
                self:Repopulate(tooltip,record.item)
            end
        end
        self:Schedule()
    end)
end
function Bridge:Install()
    if self.installed then return true end
    local api=self.api;local frame=api.ImmersionFrame
    local inspector=frame and frame.Inspector
    if not version(api,'Pawn','2.13.17') or not version(api,'Immersion','1.4.61')
        or not inspector or not inspector.tooltipFramePool or not inspector.tooltipFramePool.active
        or not frame.TalkBox or not frame.TalkBox.Elements or not frame.TalkBox.Elements.Content
        or not frame.TalkBox.Elements.Content.RewardsFrame
        or type(frame.UpdateItems)~='function' or type(frame.SetItemTooltip)~='function'
        or type(frame.HookScript)~='function' or type(api.PawnResetTooltips)~='function'
        or type(api.hooksecurefunc)~='function' or type(api.CreateFrame)~='function'
        or type(frame.IsVisible)~='function' or type(inspector.IsVisible)~='function'
        or type(api.PawnResetBags)~='function' or not api.C_Timer or type(api.C_Timer.NewTimer)~='function'
        or type(api.GetQuestItemLink)~='function' or type(api.GetQuestID)~='function'
        or not api.C_Item or type(api.C_Item.GetItemInfoInstant)~='function' then return false end
    self.frame,self.inspector,self.pool=frame,inspector,inspector.tooltipFramePool
    self.installed=true
    api.hooksecurefunc(frame,'UpdateItems',function() self:Start(frame.TalkBox.Elements.Content.RewardsFrame.Buttons) end)
    frame:HookScript('OnHide',function() self:Close() end)
    api.hooksecurefunc(frame,'SetItemTooltip',function(_,tooltip,item)
        self.tips[tooltip]=nil;self:Annotate(tooltip,item)
        if self.tips[tooltip] then self:TrackLayout(tooltip) end
    end)
    api.hooksecurefunc('PawnResetTooltips',function() self:Invalidate() end)
    api.hooksecurefunc('PawnResetBags',function() self:Invalidate() end)
    self.eventFrame=api.CreateFrame('Frame')
    for _,event in ipairs({'GET_ITEM_INFO_RECEIVED','ITEM_DATA_LOAD_RESULT','PLAYER_EQUIPMENT_CHANGED','PLAYER_SPECIALIZATION_CHANGED'}) do self.eventFrame:RegisterEvent(event) end
    self.eventFrame:SetScript('OnEvent',function(_,event,id,success)
        if not self.open then return end
        if event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_DATA_LOAD_RESULT' then
            if not known(api,id) or not known(api,success) or success==false then return end
            local matches=false
            for _,item in ipairs(self.buttons or {}) do
                local link=self:Identity(item)
                if link and api.C_Item.GetItemInfoInstant(link)==id then matches=true;break end
            end
            if not matches then return end
        elseif event=='PLAYER_SPECIALIZATION_CHANGED' and id~='player' then return end
        self:Invalidate()
    end)
    return true
end
function Integration:Refresh(owner,api)
    self:Observe(api)
    if not self.instance then self.instance=self.New(owner,api) end
    local instance=self.instance
    if not instance:Allowed() then instance:Close();return false,'configuration not accepted or recovery pending' end
    if not instance:Install() then return false,'qualified optional Pawn/Immersion reward contract unavailable' end
    if not instance:Available() then instance:Close();return false,'waiting for observed Pawn initialization; reload if loaded after login' end
    instance:Start(instance.frame.TalkBox.Elements.Content.RewardsFrame.Buttons)
    return true,'Pawn owns reward verdicts and tooltip notes; BetterBags owns arrow provider selection'
end
function Integration:Status()
    return self.instance and self.instance:Available() and 'ready; Pawn reward presentation active'
        or 'pending optional addon initialization or accepted configuration'
end
Integration:Observe(_G)
