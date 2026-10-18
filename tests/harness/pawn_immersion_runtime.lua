if WORKLOAD_ONLY then return end
local nativeAssert=assert
local function assert(value,message)RUNTIME_ASSERTIONS=RUNTIME_ASSERTIONS+1;return nativeAssert(value,message)end
-- Additional integration ownership and startup cases, beyond shared parity.
local bridge=Addon.PawnImmersion.instance
local reward=NewReward(NewItem(800,128),'choice',1)
local inspector=ImmersionFrame.Inspector
local function open()
 ImmersionFrame:Show();inspector:Hide();SetRewards({reward});ImmersionFrame:ShowItems();RunTimers()
end
open()
local tip=inspector.Active[1]:GetParent()
local n=#tip.lines
local foreign=CreateFrame('GameTooltip','ForeignTooltip',UIParent)
foreign:SetQuestItem('choice',1);foreign:Show()
bridge:Annotate(foreign,reward)
assert(#foreign.lines==3,'foreign reward tooltip annotated without native pool membership')
bridge.pool.active[tip]=nil
bridge.tips[tip]=nil;bridge:Annotate(tip,reward)
assert(#tip.lines==n,'released tooltip received duplicate Pawn output')
bridge.pool.active[tip]=true
local function blocked(change,undo,label)
 change();bridge:Invalidate();RunTimers()
 assert(not bridge.arrows[reward]:IsShown(),label..' retained arrow')
 assert(not bridge.open,label..' retained worker')
 undo();open();assert(bridge.arrows[reward]:IsShown(),label..' failed recovery')
end
blocked(function()TEST_OWNER.busy=true end,function()TEST_OWNER.busy=nil end,'active configuration review')
blocked(function()TEST_OWNER.record.appliedRevision=0 end,function()TEST_OWNER.record.appliedRevision=20 end,'restored configuration')
blocked(function()TEST_OWNER.record.pendingBindingSelection=true end,function()TEST_OWNER.record.pendingBindingSelection=nil end,'binding recovery')
blocked(function()TEST_OWNER.db.transactions.x={guid=TEST_OWNER.guid,status='recovery-required'}end,
 function()TEST_OWNER.db.transactions.x=nil end,'interrupted journal')
local pool=inspector.tooltipFramePool
blocked(function()inspector.tooltipFramePool={}end,function()inspector.tooltipFramePool=pool end,'replaced pool owner')
local original=ImmersionFrame
blocked(function()ImmersionFrame={}end,function()ImmersionFrame=original end,'replaced frame owner')
-- Cosmetic presentation remains permitted in combat/Edit Mode; input and C APIs
-- are not called by this module. Native comparison stays the same route.
InCombatLockdown=function()return true end
EditModeManagerFrame={IsShown=function()return true end}
open();assert(bridge.arrows[reward]:IsShown(),'cosmetic arrow incorrectly gated by combat/Edit Mode')
local calls=MODEL.counts.compare;inspector:ShowFocusedTooltip(true);inspector:ShowFocusedTooltip(false)
assert(MODEL.counts.compare==calls+1,'combat comparison lost native ownership')
-- Repeated settings/equipment refresh uses actual native XML padding, once per
-- new population, while keeping the visible selected reward and L2 focus.
local width,height=tip:GetSize()
tip=inspector.Active[1]:GetParent();width,height=tip:GetSize()
local lines=#tip.lines
ImmersionFrame:UpdateItems();RunTimers()
assert(bridge.tips[tip] and bridge.tips[tip].item==reward,'retained inspector lost annotation owner on UpdateItems')
inspector:ShowFocusedTooltip(true)
for i=1,12 do
 PawnResetTooltips();PawnResetBags();RunTimers();RunTimers()
 assert(tip:GetWidth()==width and tip:GetHeight()==height,'native tooltip padding lost or accumulated on refresh')
 assert(#tip.lines==lines,'refreshed tooltip duplicated Pawn text')
 assert(GameTooltip.shoppingTooltips[1]:IsShown(),'visible tooltip refresh disrupted held L2 comparison')
end
inspector:ShowFocusedTooltip(false)
-- Both choices must refresh. Native repopulation replaces the bridge record;
-- iterating that same mutable table can silently skip the next tooltip.
local other=NewReward(NewItem(801,140),'choice',2)
inspector:Hide();SetRewards({reward,other});ImmersionFrame:ShowItems();RunTimers()
local first,second=inspector.Active[1]:GetParent(),inspector.Active[2]:GetParent()
assert(#first.lines>3 and #second.lines>3,'two-upgrade setup missing Pawn notes')
local best=PawnCommon.Scales.primary.PerCharacterOptions[PawnPlayerFullName].BestItems
best.INVTYPE_CLOAK={200,MODEL.base.Link}
PawnResetTooltips();RunTimers();RunTimers()
assert(#first.lines==3 and #second.lines==3,'refresh skipped one of two reward tooltips')
best.INVTYPE_CLOAK={100,MODEL.base.Link}
open();tip=inspector.Active[1]:GetParent()
-- The real native GetItem delegates to TooltipUtil and can expose the primary
-- data hyperlink (an item string), or no hyperlink. It does not round-trip the
-- decoration returned by GetQuestItemLink. The native setter and SetReferences
-- identify this reward; neither getter representation may suppress Pawn.
local plain=reward.modelLink
local decorated='|cff1eff00|H'..plain..'|h[Quest reward]|h|r'
MODEL.items[decorated]=MODEL.items[plain];reward.modelLink=decorated
MODEL.tooltipHyperlinkMode='bare';open();tip=inspector.Active[1]:GetParent()
local _,displayed=tip:GetItem()
assert(displayed==plain and GetQuestItemLink('choice',1)==decorated,'native getter representation case not established')
assert(#tip.lines>3,'decorated quest link suppressed focused Pawn note')
local expected=#tip.lines
inspector:ShowFocusedTooltip(true)
assert(#tip.lines==expected,'decorated focused note lost on L2 press')
inspector:ShowFocusedTooltip(false)
assert(#tip.lines==expected,'decorated focused note lost on L2 release')
ImmersionFrame:UpdateItems();RunTimers()
assert(bridge.tips[tip] and bridge.tips[tip].annotated,'getter representation lost retained tooltip ownership')
MODEL.tooltipHyperlinkMode='missing';open();tip=inspector.Active[1]:GetParent()
local _,absent=tip:GetItem()
assert(absent==nil,'native absent getter case not established')
assert(#tip.lines>3,'missing getter hyperlink suppressed focused Pawn note')
inspector:ShowFocusedTooltip(true);inspector:ShowFocusedTooltip(false)
assert(#tip.lines==expected,'missing getter note lost during L2 cycle')
local annotated=bridge.work.annotations
local savedItem=tip.Button.item;tip.Button.item=other;bridge.tips[tip]=nil
bridge:Annotate(tip,reward)
assert(bridge.work.annotations==annotated,'reused tooltip references authorized stale reward annotation')
bridge.tips[tip]={item=reward,link=decorated,generation=bridge.generation,annotated=true}
local populated=MODEL.counts.nativeSets
PawnResetTooltips();RunTimers()
assert(MODEL.counts.nativeSets==populated,'reused tooltip references allowed stale native repopulation')
tip.Button.item=savedItem
MODEL.tooltipHyperlinkMode=nil;reward.modelLink=plain;open();tip=inspector.Active[1]:GetParent()
-- Secret event identities and authoritative quest links fail closed.
local q=bridge.work.queries
bridge.eventFrame:GetScript('OnEvent')(nil,'ITEM_DATA_LOAD_RESULT',{secret=true},true);RunTimers()
assert(bridge.work.queries==q,'secret item event caused bridge queries')
tip=inspector.Active[1]:GetParent();MODEL.rewards.choice1={secret=true};bridge.tips[tip]=nil
n=#tip.lines;bridge:Annotate(tip,reward);assert(#tip.lines==n,'secret quest identity annotated')
MODEL.rewards.choice1=plain
-- Real event dispatch, QUEST_* handlers and PlayIntro establish first-show
-- ordering. Animation, focus acquisition, talking-head content and quest
-- template dispatch below are explicit UI subsystem models.
setmetatable(ImmersionL,{__call=function(_,key)if key=='disableglowani' then return true end;return 0 end})
local function nothing()end
ImmersionFrame.IgnoreResetEvent={}
ImmersionFrame.TalkBox.Elements.Reset=nothing
ImmersionFrame.SetBackground=nothing;ImmersionFrame.HandleGossipQuestOverlap=nothing
ImmersionFrame.UpdateBackground=nothing;ImmersionFrame.UpdateTalkingHead=nothing
ImmersionFrame.SetImmersionFocus=nothing;ImmersionFrame.ClearImmersionFocus=nothing
ImmersionFrame.EnableKeyboard=nothing;ImmersionFrame.FadeIn=nothing
ImmersionFrame.TalkBox.ClearAllPoints=nothing;ImmersionFrame.TalkBox.SetOffset=nothing
ImmersionFrame.IsQuestAutoAccepted=function()return false end
ImmersionFrame.AddQuestInfo=function(self)ImmersionL.ElementsMixin.ShowRewards(self.TalkBox.Elements)end
ImmersionAPI.GetTitleText=function()return 'Quest'end
ImmersionAPI.GetRewardText=function()return 'Rewards'end
ImmersionAPI.GetQuestText=function()return 'Detail'end
IsOptionFrameOpen=function()return false end
MODEL.numChoices=1;SetRewards({reward});ImmersionFrame:Hide()
for _,event in ipairs({'QUEST_COMPLETE','QUEST_ITEM_UPDATE','QUEST_DETAIL'})do
 ImmersionFrame:OnEvent(event);RunTimers()
 assert(ImmersionFrame:IsVisible(),'native intro failed to show reward dialog')
 assert(bridge.arrows[reward]:IsShown(),'first native quest event missed summary upgrade')
 assert(not inspector:IsShown(),'native reset failed to close old inspector')
 ImmersionFrame:ShowItems();RunTimers()
 tip=inspector.Active[1]:GetParent();n=#tip.lines
 assert(n>3,'native event did not reach Pawn reward annotation')
 inspector:ShowFocusedTooltip(true);inspector:ShowFocusedTooltip(false)
 assert(#tip.lines==n,'native event comparison lost Pawn annotation')
end
RUNTIME_RESULT='{"additionalAssertions":'..RUNTIME_ASSERTIONS..',"nativeQuestEvents":3,"refreshComparisons":12}'
