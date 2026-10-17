local hiddenArrow={IsShown=function()return false end}
local function Arrow(item)return ACTIVE_BRIDGE and ACTIVE_BRIDGE.arrows and ACTIVE_BRIDGE.arrows[item] or item.pawnArrow or hiddenArrow end
if WORKLOAD_ONLY then
 local item=NewItem(2,128);local other=NewItem(3,90)
 local a,b=NewReward(item,'choice',1),NewReward(other,'choice',2)
 local bridge=NewBridge();ACTIVE_BRIDGE=bridge;if BRIDGE_ENABLED then bridge:Install()end
 MODEL.numChoices=2
 for _=1,12 do
  ImmersionFrame.Inspector:Hide();SetRewards({a,b})
  ImmersionL.ElementsMixin.ShowRewards(ImmersionFrame.TalkBox.Elements);ImmersionFrame:UpdateItems()
  ImmersionFrame:ShowItems();RunTimers();ImmersionFrame.Inspector:OnUpdate(.11)
 end
 for _=1,10 do ImmersionFrame.Inspector:ShowFocusedTooltip(true);ImmersionFrame.Inspector:ShowFocusedTooltip(false)end
 for _=1,120 do PawnResetBags();PawnResetTooltips()end
 RunTimers();RunTimers()
 EXPERIMENT_RESULT='{"nativeTooltipSets":'..MODEL.counts.nativeSets..',"nativeCompareCalls":'..MODEL.counts.compare..
  ',"showEvents":'..MODEL.counts.showEvents..',"bridgeQueries":'..bridge.work.queries..',"bridgeAnnotations":'..bridge.work.annotations..
  ',"bridgeRefreshes":'..bridge.work.refreshes..',"poolFrames":'..ImmersionFrame.Inspector.tooltipFramePool.count..'}'
 return
end
local count,scenarios=0,0
local function check(v,msg)count=count+1;assert(v,msg)end
local function equal(a,b,msg)check(a==b,(msg or 'equal')..': '..tostring(a)..' ~= '..tostring(b))end
local function signature(t,start)
 local out={};for i=start or 1,#t.lines do local l=t.lines[i];out[#out+1]=table.concat({l.left or '',l.right or '',tostring(l.r),tostring(l.g),tostring(l.b)},'~')end
 return table.concat(out,'\n')
end
local function settle(n)for _=1,n or 1 do RunTimers()end end
local bridge=NewBridge();ACTIVE_BRIDGE=bridge;bridge:Install();bridge:Install()
local primary=PawnCommon.Scales.primary
local base=primary.PerCharacterOptions[PawnPlayerFullName].BestItems
local upgrade=NewItem(2,128)
local lesser=NewItem(3,90)
local reward=NewReward(upgrade,'choice',1)
local reward2=NewReward(lesser,'choice',2)
local inspector=ImmersionFrame.Inspector
local function open(buttons)
 inspector:Hide();SetRewards(buttons);ImmersionFrame:ShowItems();settle();inspector:OnUpdate(.11)
end
local function currentTip(index)return inspector.Active[index or 1]:GetParent()end
local function bagSuffix(item)
 -- Same entry point as Pawn's real GameTooltip:SetBagItem posthook; C population modeled.
 MODEL.rewards.bag1=item.Link;GameTooltip:SetQuestItem('bag',1)
 local n=#GameTooltip.lines;PawnUpdateTooltip('GameTooltip','SetBagItem')
 return signature(GameTooltip,n+1)
end
local function parity(item,index)
 local tooltip=currentTip(index);local prefix=item.context and 5 or 3
 equal(signature(tooltip,prefix+1),bagSuffix(item),'Pawn generated output parity item='..item.ID..' scenario='..scenarios..' population='..tostring(tooltip.population))
 return tooltip
end
open({reward,reward2})
check(Arrow(reward):IsShown(),'summary upgrade arrow')
equal(Arrow(reward).atlas,'bags-greenarrow','actual native bag atlas')
equal(Arrow(reward).useAtlasSize,true,'native atlas supplies dimensions')
equal(Arrow(reward).drawLayer,'OVERLAY','native arrow layer')
equal(Arrow(reward).subLevel,1,'native arrow sublevel')
check(Arrow(reward):IsShown(),'summary upgrade arrow')
check(not Arrow(reward2):IsShown(),'non-upgrade summary has no arrow')
equal(Arrow(reward).anchor[1],'TOPLEFT','native icon corner')
equal(reward.Name:GetText(),nil,'bridge adds no summary text')
local t=parity(upgrade);parity(lesser,2)
local initial=signature(t)
bridge:Annotate(t,reward);equal(signature(t),initial,'repeated hook cannot duplicate annotation')
local beforeQueries=bridge.work.queries
for _=1,10 do inspector:ShowFocusedTooltip(true);equal(signature(t),initial,'L2 selected note retained');check(GameTooltip.shoppingTooltips[1]:IsShown(),'equipped comparison shown')
 inspector:ShowFocusedTooltip(false);equal(signature(t),initial,'L2 release selected note retained');check(not GameTooltip.shoppingTooltips[1]:IsShown(),'comparison closes')end
equal(bridge.work.queries,beforeQueries,'L2 does not reevaluate arrows')
equal(MODEL.counts.compare,10,'actual native compare delegation count')
scenarios=scenarios+1
-- Execute actual native summary population, retaining the independent vendor marker.
MODEL.numChoices=2;upgrade.price=100;lesser.price=300
local elements=ImmersionFrame.TalkBox.Elements
elements.chooseItems=true
ImmersionL.ElementsMixin.ShowRewards(elements);ImmersionFrame:UpdateItems()
equal(reward.Name:GetText(),upgrade.Name,'actual summary item label')
equal(reward2.Name:GetText(),lesser.Name,'second summary label')
check(Arrow(reward):IsShown(),'actual summary upgrade')
check(not Arrow(reward2):IsShown(),'actual summary non-upgrade')
check(elements.Content.RewardsFrame.MoneyIcon:IsShown(),'native vendor marker retained')
equal(elements.Content.RewardsFrame.MoneyIcon.anchor[2],reward2,'native vendor marker on higher vendor item')
equal(elements.itemChoice,0,'no reward auto-selection')
MODEL.numChoices=1
ImmersionL.ElementsMixin.ShowRewards(elements);ImmersionFrame:UpdateItems()
check(not reward2:IsShown(),'native population hides old pooled reward')
check(not Arrow(reward2):IsShown(),'hidden pooled reward arrow cleared')
MODEL.numChoices=2;ImmersionL.ElementsMixin.ShowRewards(elements);ImmersionFrame:UpdateItems()
check(reward2:IsShown(),'native population restores second reward')
scenarios=scenarios+1
local poolCount=inspector.tooltipFramePool.count
local stableWidth,stableHeight=t:GetSize()
for _=1,12 do
 open({reward,reward2});local tip=parity(upgrade)
 equal(signature(tip),initial,'reopen annotation matches');equal(tip:GetWidth(),stableWidth,'no width growth');equal(tip:GetHeight(),stableHeight,'no height growth')
 equal(inspector.tooltipFramePool.count,poolCount,'pool frames reused')
end
check(inspector:GetWidth()>=stableWidth,'actual adjust mixin uses tooltip bounds')
scenarios=scenarios+1
-- Actual Pawn arithmetic with modeled parsed/cached item data, never preset verdicts.
local cases={
 {'upgrade',128,'INVTYPE_CLOAK',183,true}, {'lower',70,'INVTYPE_CLOAK',204,false},
 {'equal',100,'INVTYPE_CLOAK',183,false}, {'below half-percent threshold',100.4,'INVTYPE_CLOAK',183,false},
 {'over threshold',100.6,'INVTYPE_CLOAK',183,true}, {'high-level requirement',150,'INVTYPE_CLOAK',200,false},
 {'wrong armor',140,'INVTYPE_CHEST',183,false}, {'ring weaker-slot upgrade',85,'INVTYPE_FINGER',183,true},
 {'trinket excluded from stat-score upgrade',300,'INVTYPE_TRINKET',183,false},
 {'2H vs equipped 1H',180,'INVTYPE_2HWEAPON',183,false}, {'no-stat reward',0,'',183,false},
}
base.INVTYPE_FINGER={120,'item:ring-best',nil,80,'item:ring-second'}
MODEL.equipped[16]=MODEL.base.Link
for id,c in ipairs(cases)do
 local item=NewItem(100+id,c[2],c[3],c[4]);if id==6 then item.MinLevel=90 end
 if id==7 then item.UnenchantedStats.IsCloth=true end
 if id==11 then item.hasStats=false;item.Values={}end
 local b=NewReward(item,'choice',1);open({b});MODEL.clock=MODEL.clock+1
 local provider=BetterItems:ResolveUpgrade({itemInfo={itemLink=item.Link}})
 local public=PawnShouldItemLinkHaveUpgradeArrow(item.Link,true)
 equal(public,provider,c[1]..' public/provider verdict');equal(public,c[5],c[1]..' actual Pawn result')
 equal(Arrow(b):IsShown(),c[5],c[1]..' bridge result');parity(item);scenarios=scenarios+1
end
MODEL.equipped[16]=nil
local lowStatsHighLevel=NewItem(220,70,'INVTYPE_CLOAK',204)
PawnOptions.ItemLevels[15]={Level=183,Link=MODEL.base.Link}
for _,enabled in ipairs({true,false})do
 PawnCommon.ShowItemLevelUpgrades=enabled
 local b=NewReward(lowStatsHighLevel,'choice',1);open({b});equal(Arrow(b):IsShown(),enabled,'Pawn item-level option');parity(lowStatsHighLevel)
end
scenarios=scenarios+1
local secondary=NewScale('custom','Équilibre personnalisé')
secondary.PerCharacterOptions[PawnPlayerFullName].BestItems.INVTYPE_CLOAK={80,MODEL.base.Link}
upgrade.Values[2]={'custom',105.25,103.125,'Équilibre personnalisé'}
for _,digits in ipairs({0,1,3})do for _,icons in ipairs({true,false})do for _,align in ipairs({true,false})do
 PawnCommon.Digits=digits;PawnCommon.ShowSpecIcons=icons;PawnCommon.AlignNumbersRight=align
 PawnRecreateAnnotationFormats();MODEL.specLabel=digits==3 and 'Spécialisation de test' or 'Protection'
 local b=NewReward(upgrade,'choice',1);open({b});parity(upgrade);scenarios=scenarios+1
end end end
for _,valuesOnly in ipairs({true,false})do for _,showUpgrades in ipairs({true,false})do
 PawnCommon.ShowValuesForUpgradesOnly=valuesOnly;PawnCommon.ShowUpgradesOnTooltips=showUpgrades
 local b=NewReward(upgrade,'choice',1);open({b});parity(upgrade);scenarios=scenarios+1
end end
PawnCommon.ShowValuesForUpgradesOnly=true;PawnCommon.ShowUpgradesOnTooltips=true
PawnCommon.Digits=1;PawnCommon.ShowSpecIcons=true;PawnCommon.AlignNumbersRight=false;PawnRecreateAnnotationFormats()
primary.PerCharacterOptions[PawnPlayerFullName].Visible=false
local customOnly=NewReward(upgrade,'choice',1);open({customOnly});check(Arrow(customOnly):IsShown(),'custom visible scale upgrades');parity(upgrade)
primary.PerCharacterOptions[PawnPlayerFullName].Visible=true;secondary.PerCharacterOptions[PawnPlayerFullName].Visible=false
scenarios=scenarios+1
open({reward});local before=bridge.work.refreshes
for _=1,120 do PawnResetBags();PawnResetTooltips()end
settle();equal(bridge.work.refreshes,before+1,'240 invalidations coalesce into one refresh');parity(upgrade)
base.INVTYPE_CLOAK={150,MODEL.base.Link};PawnResetBags();settle();check(not Arrow(reward):IsShown(),'changed equipment/history invalidates verdict');parity(upgrade)
base.INVTYPE_CLOAK={100,MODEL.base.Link};PawnResetBags();settle();check(Arrow(reward):IsShown(),'upgrade restored by Pawn baseline');parity(upgrade)
local unchanged=signature(currentTip());local q=bridge.work.queries;settle(15)
equal(signature(currentTip()),unchanged,'settled text stable');equal(bridge.work.queries,q,'zero settled query work')
before=bridge.work.refreshes
bridge.eventFrame:GetScript('OnEvent')(nil,'PLAYER_SPECIALIZATION_CHANGED','party1');settle()
equal(bridge.work.refreshes,before,'other-unit spec event filtered')
for _=1,30 do bridge.eventFrame:GetScript('OnEvent')(nil,'PLAYER_EQUIPMENT_CHANGED',15)end
bridge.eventFrame:GetScript('OnEvent')(nil,'PLAYER_SPECIALIZATION_CHANGED','player');settle()
equal(bridge.work.refreshes,before+1,'equipment and player spec events coalesce');parity(upgrade)
scenarios=scenarios+1
local delayed=NewItem(300,135);delayed.pending=true
local pending=NewReward(delayed,'choice',1);open({pending})
check(not Arrow(pending):IsShown(),'pending no invented arrow');check(bridge.timer~=nil,'pending has bounded retry')
delayed.pending=false;settle(2);check(Arrow(pending):IsShown(),'data completion resolves pending');parity(delayed)
MODEL.clock=MODEL.clock+1;MODEL.cost=.02
PawnShouldItemLinkHaveUpgradeArrow(upgrade.Link,true) -- spend actual public wrapper budget
MODEL.cost=0
assert(PawnShouldItemLinkHaveUpgradeArrow(upgrade.Link,true)==nil,'public budget not spent clock='..MODEL.clock)
local budgeted=NewReward(upgrade,'choice',1);SetRewards({budgeted});bridge:Start(ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons)
check(bridge.timer~=nil,'budget exhaustion schedules retry queries='..bridge.work.queries..' open='..tostring(bridge.open)..' available='..tostring(bridge:Available())..' uses='..tostring(RUNTIME and bridge:BagUsesPawn()));check(not Arrow(budgeted):IsShown(),'budget pending hidden')
settle(2);check(Arrow(budgeted):IsShown(),'budget retry resolves')
scenarios=scenarios+1
delayed.pending=true;pending=NewReward(delayed,'choice',1);open({pending})
MODEL.rewards.choice1=lesser.Link;delayed.pending=false
settle();check(not Arrow(pending):IsShown(),'stale generation/link result rejected')
local variant=NewItem(2,80);variant.Link=variant.Link:gsub(':901$',':902');MODEL.items[variant.Link]=variant;MODEL.items[upgrade.Link]=upgrade
local vb=NewReward(variant,'choice',1);open({vb});check(not Arrow(vb):IsShown(),'full bonus link distinct');parity(variant)
scenarios=scenarios+1
for _,provider in ipairs({'None','BetterBags','Pawn'})do
 MODEL.providerSet=true;MODEL.provider=provider
 open({reward});equal(Arrow(reward):IsShown(),provider=='Pawn','explicit bag provider');parity(upgrade)
end
MODEL.providerSet=false;MODEL.provider=nil
scenarios=scenarios+1
local required=NewReward(upgrade,'required',1);SetRewards({reward});bridge:Start(ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons)
local foreign=CreateFrame('GameTooltip','ForeignTooltip',UIParent);foreign:SetQuestItem('required',1);foreign:Show()
local original=signature(foreign);bridge:Annotate(foreign,required);equal(signature(foreign),original,'Required Items unchanged')
local currency=NewReward(upgrade,'choice',2);currency.objectType='currency'
SetRewards({reward,currency});bridge:Start(ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons);ImmersionFrame:SetItemTooltip(foreign,currency)
equal(#foreign.lines,1,'currency untouched');check(not Arrow(currency):IsShown(),'currency has no arrow')
check(not PawnIsAThirdPartyBagRegistered,'no global third-party bag side effect')
check(not PawnIsAThirdPartyTooltipRegistered,'no global tooltip border override')
scenarios=scenarios+1
reward.rewardContextLine='Native reward context';upgrade.context=true
open({reward});parity(upgrade);equal(currentTip().lines[5].left,'Native reward context','context line preserved')
PawnResetBags();settle();parity(upgrade);equal(currentTip().lines[5].left,'Native reward context','context survives reset')
reward.rewardContextLine=nil;upgrade.context=nil
scenarios=scenarios+1
delayed.pending=true;pending=NewReward(delayed,'choice',1);open({pending});settle(12)
check(bridge.attempts<=8,'finite pending attempts');check(bridge.timer==nil,'retry stops at bound')
local refreshes=bridge.work.refreshes
bridge.eventFrame:GetScript('OnEvent')(nil,'ITEM_DATA_LOAD_RESULT',99999,true);settle()
equal(bridge.work.refreshes,refreshes,'unrelated item result filtered')
bridge.eventFrame:GetScript('OnEvent')(nil,'ITEM_DATA_LOAD_RESULT',delayed.ID,false);settle()
equal(bridge.work.refreshes,refreshes,'failed item result filtered')
delayed.pending=false
bridge.eventFrame:GetScript('OnEvent')(nil,'ITEM_DATA_LOAD_RESULT',delayed.ID,true);settle()
check(Arrow(pending):IsShown(),'matching data event resolves after retry bound');parity(delayed)
delayed.pending=true
open({pending});q=bridge.work.queries;bridge:Close();settle(10)
equal(bridge.work.queries,q,'closed zero query work');check(not Arrow(pending):IsShown(),'close clears overlay')
for _,name in ipairs({'Pawn','Immersion'})do
 MODEL.loaded={[name]=false};open({reward});check(not Arrow(reward):IsShown(),'missing addon gated');MODEL.loaded=nil
end
local metadata=C_AddOns.GetAddOnMetadata
C_AddOns.GetAddOnMetadata=function()return 'unsupported' end
open({reward});check(not Arrow(reward):IsShown(),'unsupported contract gated')
C_AddOns.GetAddOnMetadata=metadata
MODEL.rewards.choice1={secret=true};SetRewards({reward});MODEL.rewards.choice1={secret=true}
bridge:Start(ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons);check(not Arrow(reward):IsShown(),'opaque item link rejected')
MODEL.quest=101;bridge:Start(ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons);check(not Arrow(reward):IsShown(),'changed quest identity rejected');MODEL.quest=100
if not RUNTIME then
 bridge.ready=false;SetPawnInitialized(false);open({reward});check(not Arrow(reward):IsShown(),'uninitialized readiness gated')
 SetPawnInitialized(true);bridge.ready=true;open({reward});check(Arrow(reward):IsShown(),'late readiness retry at next open')
end
bridge:Close();q=bridge.work.queries;PawnResetBags();PawnResetTooltips();settle(8);equal(bridge.work.queries,q,'closed invalidations no work')
scenarios=scenarios+1
-- Native reward updates can arrive after the dialog's hide transition.
ImmersionFrame:Show();open({reward});ImmersionFrame:Hide();q=bridge.work.queries
ImmersionFrame:UpdateItems();settle()
equal(bridge.work.queries,q,'hidden native refresh cannot restart queries')
check(not bridge.open,'hidden native refresh must remain inactive')
scenarios=scenarios+1
ImmersionFrame:Show();open({reward});UIParent:Hide();q=bridge.work.queries
ImmersionFrame:UpdateItems();settle()
equal(bridge.work.queries,q,'hidden ancestor refresh cannot restart queries')
check(not bridge.open,'hidden ancestor remains inactive');UIParent:Show()
scenarios=scenarios+1
EXPERIMENT_RESULT='{"assertions":'..count..',"scenarios":'..scenarios..',"poolFrames":'..inspector.tooltipFramePool.count..
 ',"queries":'..bridge.work.queries..',"annotations":'..bridge.work.annotations..',"coalescedRefreshes":'..bridge.work.refreshes..
 ',"compareDelegations":'..MODEL.counts.compare..'}'
