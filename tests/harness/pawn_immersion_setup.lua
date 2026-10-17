-- Modeled parsed/cached item records are the input boundary, not mocked upgrade answers.
UIParent:Show();ImmersionFrame:SetParent(UIParent);ImmersionFrame:Show()
if not RUNTIME then SetPawnInitialized(true) end;PawnPlayerFullName='Experiment-Character'
PawnCommon={Scales={},ShowUpgradesOnTooltips=true,ShowValuesForUpgradesOnly=true,
 ShowItemLevelUpgrades=false,ShowSpecIcons=true,ShowEnchanted=false,Digits=1,
 ColorTooltipBorder=true,ShowTooltipIcons=false,AlignNumbersRight=false}
PawnOptions={UpgradeTracking=true,ItemLevels={}}
function PawnGetItemData(link)local item=MODEL.items[link];return item and not item.pending and item or nil end
function PawnCanItemHaveStats(link)local i=MODEL.items[link];return i and i.hasStats~=false end
function PawnCanItemBeArtifactUpgrade()return false end
function PawnRecalculateItemValuesIfNecessary(item)return item.Values end
function PawnUnenchantItemLink(link)return link,false end
function PawnGetItemDataForInventorySlot(slot)local link=MODEL.equipped[slot];return MODEL.items[link],link~=nil end
function PawnGetMaxLevelItemIsUsefulHeirloom()return nil end
function PawnGetSpecializationInfoForClassID(_,spec)return spec,MODEL.specLabel or 'Protection' end
function PawnClearCacheValuesOnly()end
function NewScale(name,label)
 PawnCommon.Scales[name]={Values={},LocalizedName=label,Color='00ff00',UnenchantedColor='00aa00',
 IconTexturePath='spec-icon-'..name,PerCharacterOptions={[PawnPlayerFullName]={Visible=true,BestItems={}}}}
 return PawnCommon.Scales[name]
end
function NewItem(id,score,inv,level)
 local link='item:'..id..':0:0:0:0:0:0:0:80:0:0:2:1:901'
 local item={ID=id,Link=link,Name='Item '..id,InvType=inv or 'INVTYPE_CLOAK',Level=level or 183,Rarity=2,
 CanEquip=true,UnenchantedStats={},Values={{'primary',score,score,'Primary scale'}}}
 MODEL.items[link]=item;return item
end
local primary=NewScale('primary','Primary scale')
primary.ClassID=2;primary.SpecID=66;primary.Provider='Experiment'
local old=NewItem(1,100);primary.PerCharacterOptions[PawnPlayerFullName].BestItems.INVTYPE_CLOAK={100,old.Link}
MODEL.base=old
PawnRecreateAnnotationFormats()
if BAGS_FIRST then
 local actual=PawnGetItemData;PawnGetItemData=nil;BetterPawn:OnEnable()
 assert(not BetterPawn._registered and MODEL.lateRegister,'actual late Pawn registration missing')
 PawnGetItemData=actual;MODEL.lateRegister()
else BetterPawn:OnEnable()end
ImmersionL.Mixin(ImmersionFrame.Inspector,ImmersionL.AdjustToChildren)
ImmersionL.Mixin(ImmersionFrame.Inspector.Choices,ImmersionL.AdjustToChildren)
ImmersionL.Mixin(ImmersionFrame.Inspector.Extras,ImmersionL.AdjustToChildren)
local inspector=ImmersionFrame.Inspector
inspector.Choices:Show();inspector.Extras:Show()
inspector:SetScript('OnShow',inspector.OnShow);inspector:SetScript('OnHide',inspector.OnHide)
function NewReward(item,kind,id)
 local button=CreateFrame('Button',nil,UIParent);button:SetID(id);button.type=kind or 'choice';button.objectType='item'
 button.questID=MODEL.quest;button.Icon=button:CreateTexture();button.itemTexture='icon-'..item.ID
 button.Name=CreateFrame('Frame');button.QuestRewardContextIcon=button:CreateTexture()
 button.modelLink=item.Link
 button:Show();MODEL.rewards[button.type..id]=item.Link
 return button
end
local rewards=ImmersionFrame.TalkBox.Elements.Content.RewardsFrame
for _,name in ipairs({'Header','MoneyIcon','ArtifactXPFrame','MoneyFrame','XPFrame','SkillPointFrame','HonorFrame','PlayerTitleText','TitleFrame'})do
 rewards[name]=CreateFrame('Frame');rewards[name]:SetSize(100,20)
end
for _,name in ipairs({'spellRewardPool','followerRewardPool','spellHeaderPool'})do rewards[name]={ReleaseAll=function()end}end
-- RewardsFrame is a native frame in game; add only its modeled frame interface here.
local rewardsFrame=CreateFrame('Frame');for k,v in pairs(rewardsFrame)do rewards[k]=v end
setmetatable(rewards,getmetatable(rewardsFrame))
function SetRewards(buttons)
 for _,button in ipairs(buttons)do MODEL.rewards[button.type..button:GetID()]=button.modelLink end
 ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons=buttons
 ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.ItemChooseText:SetText('Choose reward')
 ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.ItemChooseText:Show()
 ImmersionFrame:UpdateItems()
end
