-- Real native functions are injected below. C APIs, geometry and scheduling are models.
local NS, queue, timers, hooks = {}, {}, {}, {}
unpack=table.unpack
local clock, nextFrames, ready, combat, editing, initialized = 0, 0, false, false, false, false
local loaded = {Immersion=true, Pawn=true} -- Deliberately no BetterBags or ConsolePort.
local quest, SECRET = 123, {}
function issecretvalue(v) return rawequal(v, SECRET) end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
function abs(v) return math.abs(v) end
function GetTime() return clock end
function GetTimePreciseSec() return clock end
function RunNextFrame(fn) nextFrames=nextFrames+1;queue[#queue+1]=fn end
C_Timer={}
function C_Timer.After(_,fn) queue[#queue+1]=fn end
function C_Timer.NewTimer(delay,fn)
    local t={due=clock+delay,fn=fn};function t:Cancel()self.cancelled=true end
    timers[#timers+1]=t;return t
end
local function advance()
    ready=true;clock=clock+.1
    local current=queue;queue={}
    for _,fn in ipairs(current) do fn() end
    local due=timers;timers={}
    for _,t in ipairs(due) do
        if not t.cancelled then if t.due<=clock then t.fn() else timers[#timers+1]=t end end
    end
end
local function flush(n) for _=1,n or 6 do advance() end end
function hooksecurefunc(object,name,fn)
    if type(object)=='string' then fn,name,object=name,object,_G end
    assert(type(object[name])=='function','unsupported native posthook')
    local original=object[name]
    object[name]=function(...)
        local result={original(...)};fn(...);return table.unpack(result)
    end
    hooks[#hooks+1]=name
end
C_AddOns={IsAddOnLoaded=function(n)return loaded[n] end,
    GetAddOnMetadata=function()error('version admission attempted')end}
WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
function InCombatLockdown() return combat end
EditModeManagerFrame={IsShown=function()return editing end,HookScript=function(self,k,v)self[k]=v end}
local created=0
function CreateFrame()
    created=created+1
    return {RegisterEvent=function(self,k)self[k]=true end,SetScript=function(self,k,v)self[k]=v end}
end
SlashCmdList={};DEFAULT_CHAT_FRAME={AddMessage=function()end}
UIParent={GetBottom=function(f)return f.bottom or 0 end}
ImmersionSetup={boxpoint='Bottom',anidivisor=5,elementscale=1,boxoffsetX=17,boxoffsetY=39,scale=1.2}
local config=ImmersionSetup
config.padinspect, config.inspect='PAD4','SHIFT'
local L=setmetatable({
    Mixin=function(target,mixin) for key,value in pairs(mixin) do target[key]=value end end,
    UIFrameFadeIn=function() end, UIFrameFadeOut=function() end,
},{__call=function(_,key)return config[key]end})
local frame={shown=true,Inspector={Items={}}}
ImmersionFrame=frame
function frame:IsShown()return self.shown end
function frame:IsVisible()return self.shown end
function frame:HookScript(k,fn)
    self.scripts = self.scripts or {}
    local previous=self.scripts[k]
    self.scripts[k]=function(...)if previous then previous(...)end;fn(...)end
end
function frame:RunScript(k,...) if self.scripts[k] then return self.scripts[k](self,...) end end
function frame:DispatchEvent(...) return self:RunScript('OnEvent',...) end
function frame:PlayIntro()self.shown=true end
function frame:AddHint()end
function frame:RemoveHint()end
function frame:ToggleHintState()end
function frame:HandleGossipQuestOverlap()end
function frame:UpdateBackground()end
local function measured(children)
    local f={shown=true,height=403,width=570,children=children or {},Buttons={}}
    function f:GetChildren()return table.unpack(self.children)end
    function f:GetRegions()end
    function f:IsShown()return self.shown end
    function f:SetSize(w,h)self.width,self.height=w,h end
    function f:SetWidth(w)self.width=w end
    function f:SetHeight(h)self.height=h end
    function f:GetSize()return self.width,self.height end
    function f:GetTop()return 1000 end
    function f:GetBottom()return 1000-self.height end
    function f:GetLeft()return 0 end
    function f:GetRight()return self.width end
    return f
end
local child={height=200,shown=true}
function child:IsShown()return self.shown end
function child:GetTop()return ready and 1000 or nil end
function child:GetBottom()return ready and 1000-self.height or nil end
function child:GetLeft()return ready and 0 or nil end
function child:GetRight()return ready and 120 or nil end
local progress=measured({child})
local elements=measured({progress});elements.Progress=progress
local AdjustMixin={}
--@EXT_NATIVE_ADJUST
for k,v in pairs(AdjustMixin)do elements[k]=v;progress[k]=v end
local Elements={}
--@EXT_NATIVE_BOUNDARIES
elements.UpdateBoundaries=Elements.UpdateBoundaries
function elements:ShowProgress()self.shown=true;progress.shown=self.hasItems~=false;return progress.shown end
local talk={Elements=elements,extraY=0,bottom=39}
local TalkBox={}
--@EXT_NATIVE_OFFSETS
for k,v in pairs(TalkBox)do talk[k]=v end
function talk:IsVisible()return frame.shown end
function talk:SetPoint(point,_,x,y)self.point,self.bottom=point,y end
function talk:SetScript(k,v)self[k]=v end
frame.TalkBox=talk
function frame:UpdateTalkingHead()talk:SetExtraOffset(0)end
function frame:ResetElements()elements.shown=false;progress.shown=false end
function frame:AddQuestInfo()talk:SetExtraOffset(375)end
local Frame,Events={},frame
local API={IsQuestCompletable=function()return true end,GetTitleText=function()return 'Required Items' end,
    GetProgressText=function()return 'Progress' end,GetRewardText=function()return 'Rewards' end}
local verdicts, delayed, levels = {['item:101']=true}, {}, {}
local links={'item:101','item:102'}
function GetQuestID()return quest end
function GetQuestItemLink(_,id)return links[id] end
local function item(id)
    local b={questID=123,type='choice',objectType='item',Icon={},id=id,shown=true}
    function b:IsVisible()return self.shown end
    function b:GetID()return self.id end
    function b:CreateTexture(_,layer)
        assert(layer=='OVERLAY');local t={shown=false}
        function t:SetAtlas(atlas)assert(atlas=='bags-greenarrow')end
        function t:SetPoint(point,icon)assert(point=='TOPLEFT' and icon==b.Icon)end
        function t:Show()self.shown=true end
        function t:Hide()self.shown=false end
        self.arrow=t;return t
    end
    return b
end
local one,two=item(1),item(2)
elements.Content={RewardsFrame={Buttons={one,two}}}
local function textRegion()
    return {Show=function()end,Hide=function()end,IsVisible=function()return false end}
end
elements.Content.RewardsFrame.ItemChooseText=textRegion()
elements.Content.RewardsFrame.ItemReceiveText=textRegion()
progress.ReqText=textRegion()
local Inspector=frame.Inspector
local Tooltip={}
--@EXT_NATIVE_INSPECTOR
L.TooltipMixin=Tooltip
local compared, cleared
function GameTooltip_ShowCompareItem(tip) compared=tip end
function Inspector:IsVisible() return self.shown end
Inspector.HookScript,Inspector.RunScript=frame.HookScript,frame.RunScript
function Inspector:Show() self.shown=true;frame.isInspecting=true end
function Inspector:Hide()
    self.shown=false
    frame.isInspecting=false
    for tip in pairs(self.tooltipFramePool.active) do tip.shown=false end
    wipe(self.tooltipFramePool.active)
    self:RunScript('OnHide')
end
function Inspector:AdjustToChildren() end
function Inspector:SetFocus(index) self.focus=self.Active[index] end
function Inspector:GetFocus() return self.focus end
Inspector.Active={}
Inspector.Choices={Text=textRegion()}
Inspector.Extras={Text=textRegion()}
local tooltips={}
local pool={active={}}
Inspector.tooltipFramePool=pool
function pool:EnumerateActive() return pairs(self.active) end
function pool:Acquire()
    local id=1
    while tooltips[id] and self.active[tooltips[id]] do id=id+1 end
    local tip=tooltips[id]
    if not tip then
        local name='ImmersionGameTooltip'..id
        tip={Icon={Texture={SetTexture=function()end}},scripts={OnShow=tooltipOnShow},populations=0,
            shoppingTooltips={{Hide=function()cleared=true end}}}
        tip.Button={SetID=function()end,GetParent=function()return tip end}
        function tip:GetName() return name end
        function tip:GetItem() return 'Item', self.getter end
        function tip:IsVisible() return self.shown end
        function tip:SetParent(parent) self.parent=parent end
        function tip:SetOwner() end
        function tip:SetPoint() end
        function tip:GetAlpha() return 1 end
        function tip:GetSize() return self.width,self.height end
        function tip:SetSize(w,h) self.width,self.height=w,h end
        function tip:Show()
            if self.shown then return end
            self.shown=true
            self:RunScript('OnShow')
        end
        function tip:SetQuestItem(_, itemID)
            self.populations=self.populations+1
            self.getter=itemID==1 and 'item:bare' or nil
            self.lines={'Native item card'}
            self.width,self.height=110,40
        end
        function tip:AddLine(line) self.lines[#self.lines+1]=line end
        function tip:NumLines() return #self.lines end
        function tip:GetScript(event) return self.scripts[event] end
        tip.HookScript,tip.RunScript=frame.HookScript,frame.RunScript
        tooltips[id],_G[name]=tip,tip
    end
    self.active[tip]=true
    return tip
end
function frame:GetItemColumn() return {} end
function one.Icon:GetTexture() return 'icon' end
function two.Icon:GetTexture() return 'icon' end
local NPC, controllerInterrupt, popupCounter = frame, true, 0
local KEY_SETTING, KEY_FIXED = {CIRCLE='padinspect'}, {}
local function IsGamePadButton(button) return button:match('^PAD') end
function GetBindingAction() end
function frame:SetPropagateKeyboardInput() end
--@EXT_NATIVE_CONTROLLER
--@EXT_NATIVE_EVENTS
--@EXT_NATIVE_FRAME
frame.OnEvent=Frame.OnEvent;frame.UpdateItems=Frame.UpdateItems
frame.ShowItems=Frame.ShowItems;frame.SetItemTooltip=Frame.SetItemTooltip
frame.OnKeyDown=Frame.OnKeyDown;frame.IsInspectModifier=Frame.IsInspectModifier
-- Immersion's real L.Mixin captures Frame.OnEvent in the frame script slot.
-- A later hook of frame.OnEvent does not change this registered callback.
frame.scripts={OnEvent=frame.OnEvent}
PawnCommon={ShowQuestUpgradeAdvisor=true,ShowRelicUpgrades=false,ShowItemLevelUpgrades=false,
    ShowUpgradesOnTooltips=true,ShowValuesForUpgradesOnly=true,Scales={Test={}}}
PawnOptions={}
local PawnIsInitialized=false
VgerCore={Fail=function()error('premature Pawn call')end,Message=function()end,Assert=assert}
C_Item={GetItemInfo=function(link)return nil,nil,nil,nil,levels[link] or 1 end,
    GetItemInfoInstant=function(link)return tonumber(link:match('item:(%d+)'))end}
function UnitLevel()return 80 end
function UnitClass()return 'Test','TEST',1 end
function PawnCanItemHaveStats()return true end
function PawnGetItemData(link)
    return {Link=not delayed[link] and link or nil, Values={{'Test',20,20,'Test Scale'}}}
end
local budgetCost=0
function PawnIsItemAnUpgrade(data)
    clock=clock+budgetCost
    if verdicts[data.Link] then return {{PercentUpgrade=.1,ScaleName='Test'}} end
end
function PawnCanItemBeArtifactUpgrade() return false end
function PawnIsScaleVisible() return true end
function PawnGetScaleColor() return '' end
local format, PawnNoValueAnnotationFormat, PawnBigUpgradeThreshold = string.format, '%s%s:', 100
--@EXT_NATIVE_PAWN
local advisorChecked=true
PawnUIFrame_ShowQuestUpgradeAdvisorCheck={
    GetChecked=function()return advisorChecked end, HookScript=frame.HookScript, RunScript=frame.RunScript,
    scripts={OnClick=PawnUIFrame_ShowQuestUpgradeAdvisorCheck_OnClick},
}
local function setAdvisor(value)
    advisorChecked=value
    PawnUIFrame_ShowQuestUpgradeAdvisorCheck:RunScript('OnClick')
end
function PawnInitializePlugins()end
local abortInitialization=false
function PawnInitialize()
    if abortInitialization then return end
    PawnIsInitialized=true
    PawnInitializePlugins()
    initialized=true -- models the final scale corrections after plugin initialization
end
function PawnResetTooltips()end
function PawnResetBags()end
frame:DispatchEvent('QUEST_PROGRESS')
assert(talk.extraY==49,'native stale-height defect did not reproduce')
advance();assert(progress.height==200 and talk.extraY==49)
assert(not one.arrow,'baseline unexpectedly supplies upgrade arrows')
--@EXT_ADDON_SOURCE
local runtime=assert(NS.runtime)
frame:UpdateItems();assert(runtime.rewards.queries==0,'premature Pawn query')
abortInitialization=true;PawnInitialize();flush(1)
assert(not runtime.rewards.ready,'failed Pawn initialization marked ready')
abortInitialization=false
PawnInitialize()
assert(initialized and runtime.rewards.queries==0,'Pawn completion was not deferred')
flush()
assert(one.arrow and one.arrow.shown and not (two.arrow and two.arrow.shown),'Pawn verdict parity')
assert(talk.extraY==248,'post-layout Required Items correction failed')
assert(talk.offsetX==17 and talk.offsetY==39 and config.scale==1.2,'saved/resting positions changed')
assert(NS.Core.Client(_G) and runtime:Status():find('ready'))
-- Native reward ownership, level checks and preference remain authoritative.
levels['item:101']=90;frame:UpdateItems();assert(not one.arrow.shown,'level restriction ignored')
levels['item:101']=1;frame:UpdateItems();assert(one.arrow.shown)
frame.shown=false;frame:RunScript('OnHide');assert(not one.arrow.shown,'close retained upgrade arrow')
frame.shown=true;frame:UpdateItems()
setAdvisor(false);flush();assert(not one.arrow.shown,'Pawn checkbox left a stale arrow')
setAdvisor(true);flush();assert(one.arrow.shown,'Pawn checkbox failed to restore the arrow')
one.questID=999;frame:UpdateItems();assert(not one.arrow.shown,'foreign quest arrow')
one.questID=123;one.type='required';frame:UpdateItems();assert(not one.arrow.shown,'required item arrow')
one.type='choice';one.objectType='currency';frame:UpdateItems();assert(not one.arrow.shown,'currency arrow')
one.objectType='item';one.shown=false;frame:UpdateItems();assert(not one.arrow.shown,'hidden item arrow')
one.shown=true;quest=SECRET;frame:UpdateItems();assert(not one.arrow.shown,'secret quest compared')
quest=123;frame:UpdateItems();assert(one.arrow.shown)
-- A second native refresh can hit Pawn's real time budget for the same reward.
clock=clock+.25;budgetCost=.02;frame:UpdateItems();assert(one.arrow.shown)
frame:UpdateItems();assert(one.arrow.shown,'pending budget result hid confirmed arrow')
runtime.rewards:Event('PLAYER_EQUIPMENT_CHANGED');flush(1)
assert(not one.arrow.shown,'previous equipment verdict survived invalidation')
budgetCost=0;flush(4);assert(one.arrow.shown)
-- Pending item data and stale button identities.
delayed['item:101']=true;frame:UpdateItems();assert(one.arrow.shown)
delayed['item:101']=nil;flush(4);assert(one.arrow.shown,'delayed item data did not refresh')
delayed['item:101']=true;frame:UpdateItems();local before=runtime.rewards.queries
flush(40);assert(runtime.rewards.queries-before<=8,'unbounded pending retries')
local pendingTimer=runtime.rewards.timer;frame.shown=false;frame:RunScript('OnHide')
assert(not one.arrow.shown and not runtime.rewards.timer and not next(runtime.rewards.pending))
if pendingTimer then assert(pendingTimer.cancelled)end
delayed['item:101']=nil;frame.shown=true;links[1]='item:102';frame:UpdateItems();flush()
assert(not one.arrow.shown,'reused button retained upgrade')
links[1]='item:101';frame:UpdateItems();assert(one.arrow.shown)
before=runtime.rewards.queries
local queuedCallbacks=#queue
for _=1,100 do PawnResetTooltips()end
assert(#queue-queuedCallbacks<=1,'event burst created unbounded callbacks')
flush(1);assert(runtime.rewards.queries-before==2,'event burst was not coalesced')
runtime.rewards:Event('GET_ITEM_INFO_RECEIVED',999,true);assert(not runtime.rewards.dirty,'unrelated item event queued work')
loaded.Pawn=false;frame:UpdateItems();assert(not one.arrow.shown and not runtime.rewards:Available())
ready=false;frame:DispatchEvent('QUEST_PROGRESS');flush();assert(talk.extraY==248,'registered event script bypassed layout')
loaded.Pawn=true;frame:UpdateItems();assert(one.arrow.shown,'BetterBags absence blocked Pawn arrows')
-- Immersion owns the inspector and comparison. Pawn formats the current reward link.
local function upgradeLines(tooltip)
    local count=0
    for _,line in ipairs(tooltip.lines) do if line:find('+10% upgrade',1,true) then count=count+1 end end
    return count
end
frame:OnKeyDown('PAD4')
local tip,other=tooltips[1],tooltips[2]
assert(Inspector:GetFocus()==tip.Button and tip.shown,'native inspector card did not open')
assert(upgradeLines(tip)>0,'inspector Pawn percentage absent')
assert(upgradeLines(tip)==1,'duplicate inspector Pawn line')
assert(upgradeLines(other)==0,'non-upgrade tooltip got a percentage')
Inspector:ShowFocusedTooltip(true);assert(compared==tip)
Inspector:ShowFocusedTooltip(false);assert(cleared and upgradeLines(tip)==1,'comparison lost or duplicated note')
flush()
assert(tip.width==140,'native inspector padding missing')
PawnResetTooltips();flush(2)
assert(tip.width==140,'refreshed tooltip lost native padding')
assert(upgradeLines(tip)==1,'duplicate inspector Pawn line after refresh')
setAdvisor(false);flush();frame:SetItemTooltip(tip,one)
assert(not one.arrow.shown and upgradeLines(tip)==1,'arrow preference changed tooltip preferences')
setAdvisor(true);flush()
frame:OnKeyDown('PAD4');assert(not Inspector:IsVisible(),'native inspector card did not close')
delayed['item:101']=true;frame:ShowItems();assert(upgradeLines(tip)==0)
delayed['item:101']=nil;flush(5)
assert(upgradeLines(tip)==1,'delayed Pawn tooltip was not annotated')
Inspector:Hide();delayed['item:101']=true;frame:ShowItems()
local priorPopulations=tip.populations
links[1]='item:102';delayed['item:101']=nil;flush(5)
assert(tip.populations==priorPopulations,'stale inspector callback annotated a reused tooltip')
Inspector:Hide();links[1]='item:101';frame:UpdateItems()
delayed['item:101']=true;frame:ShowItems()
local timer=assert(runtime.tooltips.timer)
Inspector:Hide();assert(timer.cancelled and not runtime.tooltips.timer,'inspector close retained retry')
delayed['item:101']=nil;frame:UpdateItems()
local rewards=elements.Content.RewardsFrame;elements.Content.RewardsFrame=nil
runtime.rewards:Start();assert(not one.arrow.shown,'lost rewards contract did not fail closed')
elements.Content.RewardsFrame=rewards;frame:UpdateItems()
local setter=talk.SetExtraOffset;talk.SetExtraOffset=nil;runtime:Refresh();flush()
assert(not runtime.progress.frame,'lost layout capability still admitted')
talk.SetExtraOffset=setter;runtime:Refresh();flush()
-- Native transitions, burst scheduling, settings guards and deferred layout.
ready=false;child.height=230;frame:DispatchEvent('QUEST_PROGRESS')
advance();assert(talk.extraY==49,'repair ran before native second measurement')
advance();assert(talk.extraY==278)
local writes=runtime.progress.writes
for _=1,100 do runtime.progress:Queue()end
local queuedBefore=nextFrames;flush(6)
assert(nextFrames-queuedBefore<=3 and runtime.progress.writes==writes,'unbounded/redundant layout work')
for _,height in ipairs({28,75,150,310}) do
    child.height=height;config.elementscale=1.5;frame:DispatchEvent('QUEST_PROGRESS');flush()
    assert(talk.extraY==(height+48)*1.5,'scaled content measurement wrong')
end
config.elementscale=1;child.height=200
local function cancelled(change)
    frame.shown=true;config.boxpoint='Bottom';config.anidivisor=5;config.nameplatemode=false
    combat=false;editing=false;quest=123
    ready=false;frame:DispatchEvent('QUEST_PROGRESS');local before=runtime.progress.writes;change();flush()
    assert(runtime.progress.writes==before,'stale/ineligible layout write')
end
cancelled(function()frame:DispatchEvent('QUEST_COMPLETE')end);assert(talk.extraY==375,'stale progress moved reward dialog')
cancelled(function()frame.shown=false;frame:RunScript('OnHide')end)
cancelled(function()quest=999 end)
cancelled(function()combat=true end);local old=talk.extraY;assert(old~=248)
combat=false;runtime:Refresh();flush();assert(talk.extraY==248,'combat deferral did not recover')
cancelled(function()editing=true end);editing=false;EditModeManagerFrame.OnHide();flush();assert(talk.extraY==248,'Edit Mode deferral did not recover')
cancelled(function()config.boxpoint='Top' end);assert(talk.extraY~=248,'top anchor repaired')
cancelled(function()config.anidivisor=0 end);assert(talk.extraY~=248,'disabled offset repaired')
cancelled(function()config.nameplatemode=true end);assert(talk.extraY~=248,'nameplate anchor repaired')
cancelled(function()config.elementscale=math.huge end);assert(talk.extraY~=248,'invalid scale repaired')
config.elementscale=1;config.nameplatemode=false
-- Client gate stops bootstrap side effects; metadata is never read for admission.
local oldCreated,oldHooks=created,#hooks
WOW_PROJECT_ID=1
--@EXT_BOOTSTRAP_AGAIN
assert(created==oldCreated and #hooks==oldHooks,'Retail activated standalone addon')
WOW_PROJECT_ID=18
assert(config.boxoffsetX==17 and config.boxoffsetY==39 and config.scale==1.2,'persistent preferences changed')
assert(PawnCommon.ShowQuestUpgradeAdvisor and PawnOptions.DebugBagArrows==nil)
TEST_SUCCESS=true
