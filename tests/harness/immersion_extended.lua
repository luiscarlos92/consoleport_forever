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
local L=setmetatable({},{__call=function(_,key)return config[key]end})
local frame={shown=true,Inspector={Items={}}}
ImmersionFrame=frame
function frame:IsShown()return self.shown end
function frame:IsVisible()return self.shown end
function frame:HookScript(k,fn)
    local previous=self[k]
    self[k]=function(...)if previous then previous(...)end;fn(...)end
end
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
--@EXT_NATIVE_EVENTS
--@EXT_NATIVE_FRAME
frame.OnEvent=Frame.OnEvent;frame.UpdateItems=Frame.UpdateItems
PawnCommon={ShowQuestUpgradeAdvisor=true,ShowRelicUpgrades=false,ShowItemLevelUpgrades=false}
PawnOptions={}
local PawnIsInitialized=false
VgerCore={Fail=function()error('premature Pawn call')end,Message=function()end}
C_Item={GetItemInfo=function(link)return nil,nil,nil,nil,levels[link] or 1 end,
    GetItemInfoInstant=function(link)return tonumber(link:match('item:(%d+)'))end}
function UnitLevel()return 80 end
function PawnCanItemHaveStats()return true end
function PawnGetItemData(link)return {Link=not delayed[link] and link or nil}end
function PawnIsItemAnUpgrade(data)if verdicts[data.Link] then return {{PercentUpgrade=.1}} end end
--@EXT_NATIVE_PAWN
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
frame:OnEvent('QUEST_PROGRESS')
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
frame.shown=false;frame.OnHide();assert(not one.arrow.shown,'close retained upgrade arrow')
frame.shown=true;frame:UpdateItems()
PawnCommon.ShowQuestUpgradeAdvisor=false;PawnResetBags();flush();assert(not one.arrow.shown,'disabled quest advisor ignored')
PawnCommon.ShowQuestUpgradeAdvisor=true;frame:UpdateItems();assert(one.arrow.shown)
one.questID=999;frame:UpdateItems();assert(not one.arrow.shown,'foreign quest arrow')
one.questID=123;one.type='required';frame:UpdateItems();assert(not one.arrow.shown,'required item arrow')
one.type='choice';one.objectType='currency';frame:UpdateItems();assert(not one.arrow.shown,'currency arrow')
one.objectType='item';one.shown=false;frame:UpdateItems();assert(not one.arrow.shown,'hidden item arrow')
one.shown=true;quest=SECRET;frame:UpdateItems();assert(not one.arrow.shown,'secret quest compared')
quest=123;frame:UpdateItems();assert(one.arrow.shown)
-- Pending item data and stale button identities.
delayed['item:101']=true;frame:UpdateItems();assert(not one.arrow.shown)
delayed['item:101']=nil;flush(4);assert(one.arrow.shown,'delayed item data did not refresh')
delayed['item:101']=true;frame:UpdateItems();local before=runtime.rewards.queries
flush(40);assert(runtime.rewards.queries-before<=8,'unbounded pending retries')
local pendingTimer=runtime.rewards.timer;frame.shown=false;frame.OnHide()
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
ready=false;frame:OnEvent('QUEST_PROGRESS');flush();assert(talk.extraY==248,'Pawn absence disabled layout')
loaded.Pawn=true;frame:UpdateItems();assert(one.arrow.shown,'BetterBags absence blocked Pawn arrows')
local rewards=elements.Content.RewardsFrame;elements.Content.RewardsFrame=nil
runtime.rewards:Start();assert(not one.arrow.shown,'lost rewards contract did not fail closed')
elements.Content.RewardsFrame=rewards;frame:UpdateItems()
local setter=talk.SetExtraOffset;talk.SetExtraOffset=nil;runtime:Refresh();flush()
assert(not runtime.progress.frame,'lost layout capability still admitted')
talk.SetExtraOffset=setter;runtime:Refresh();flush()
-- Native transitions, burst scheduling, settings guards and deferred layout.
ready=false;child.height=230;frame:OnEvent('QUEST_PROGRESS')
advance();assert(talk.extraY==49,'repair ran before native second measurement')
advance();assert(talk.extraY==278)
local writes=runtime.progress.writes
for _=1,100 do runtime.progress:Queue()end
local queuedBefore=nextFrames;flush(6)
assert(nextFrames-queuedBefore<=3 and runtime.progress.writes==writes,'unbounded/redundant layout work')
for _,height in ipairs({28,75,150,310}) do
    child.height=height;config.elementscale=1.5;frame:OnEvent('QUEST_PROGRESS');flush()
    assert(talk.extraY==(height+48)*1.5,'scaled content measurement wrong')
end
config.elementscale=1;child.height=200
local function cancelled(change)
    frame.shown=true;config.boxpoint='Bottom';config.anidivisor=5;config.nameplatemode=false
    combat=false;editing=false;quest=123
    ready=false;frame:OnEvent('QUEST_PROGRESS');local before=runtime.progress.writes;change();flush()
    assert(runtime.progress.writes==before,'stale/ineligible layout write')
end
cancelled(function()frame:OnEvent('QUEST_COMPLETE')end);assert(talk.extraY==375,'stale progress moved reward dialog')
cancelled(function()frame.shown=false;frame.OnHide()end)
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
