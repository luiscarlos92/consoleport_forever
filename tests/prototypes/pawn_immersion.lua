-- Isolated candidate only: not an addon module and never loaded by its TOC.
Bridge={};Bridge.__index=Bridge
function Bridge.New()
 return setmetatable({generation=0,ready=true,pending={},attempts=0,work={queries=0,annotations=0,refreshes=0},tips={}},Bridge)
end
function Bridge:Available()
 return self.ready and C_AddOns.IsAddOnLoaded('Pawn') and C_AddOns.IsAddOnLoaded('Immersion')
  and C_AddOns.GetAddOnMetadata('Pawn','Version')=='2.13.17'
  and C_AddOns.GetAddOnMetadata('Immersion','Version')=='1.4.61'
end
function Bridge:Eligible(item)
 if not self.open or not self:Available() or not item or not item:IsVisible() then return false end
 if MUTATION~='scope-leak' then
  if item.objectType~='item' or (item.type~='reward' and item.type~='choice') or item.questID~=GetQuestID() then return false end
  local member=false;for _,b in ipairs(self.buttons)do if b==item then member=true;break end end
  if not member then return false end
 end
 return true
end
function Bridge:Identity(item)
 if not self:Eligible(item) then return end
 local link=GetQuestItemLink(item.type,item:GetID())
 if type(link)~='string' or issecretvalue(link) then return end
 return link
end
function Bridge:Arrow(item)
 if not item.pawnArrow then
  item.pawnArrow=item:CreateTexture(nil,'OVERLAY',nil,1);item.pawnArrow:SetAtlas(NATIVE_BAG_ARROW,true)
  item.pawnArrow:SetPoint(NATIVE_BAG_ANCHOR,item.Icon,NATIVE_BAG_ANCHOR,0,0)
 end
 return item.pawnArrow
end
function Bridge:Verdict(link)
 self.work.queries=self.work.queries+1
 if MUTATION=='hardcoded' then return true end
 if MUTATION=='itemlevel' then return MODEL.items[link].Level>MODEL.base.Level end
 local verdict=PawnShouldItemLinkHaveUpgradeArrow(link,true)
 if MUTATION=='pending-false' then return verdict or false end
 return verdict
end
function Bridge:UpdateArrow(item)
 local arrow=self:Arrow(item);arrow:Hide()
 local link=self:Identity(item)
 if not link or BetterItems:GetActiveUpgradeProvider()~='Pawn' then return end
 local result=self:Verdict(link)
 if result==nil then self.pending[item]={link=link,generation=self.generation};return end
 self.pending[item]=nil;arrow:SetShown(result)
end
function Bridge:Schedule()
 if self.timer or next(self.pending)==nil then return end
 if self.attempts>=8 and MUTATION~='unbounded-retry' then return end
 local generation=self.generation
 self.timer=C_Timer.NewTimer(.25,function()
  self.timer=nil;if generation~=self.generation or not self.open then return end
  self.attempts=self.attempts+1
  local pending=self.pending;self.pending={}
  for item,record in pairs(pending)do
   if MUTATION=='stale-widget' or (generation==record.generation and self:Identity(item)==record.link) then
    if MUTATION=='stale-widget' and self:Identity(item)~=record.link then
     self:Arrow(item):SetShown(self:Verdict(record.link))
    else self:UpdateArrow(item);self:RetryTip(item)end
   end
  end
  self:Schedule()
 end)
end
function Bridge:Start(buttons)
 self:Close();self.buttons=buttons
 if not ImmersionFrame:IsVisible() and MUTATION~='hidden-refresh' then return end
 self.generation=self.generation+1;self.open=true;self.attempts=0;self.tips={}
 for _,item in ipairs(buttons)do self:UpdateArrow(item)end;self:Schedule()
end
function Bridge:Close()
 self.open=false;self.generation=self.generation+1
 if self.timer then self.timer:Cancel();self.timer=nil end
 for _,item in ipairs(self.buttons or {})do if item.pawnArrow then item.pawnArrow:Hide()end end
 self.pending={};self.tips={}
end
function Bridge:Annotate(tooltip,item)
 local link=self:Identity(item)
 if not link or not tooltip:IsShown() or tooltip.link~=link then return end
 if self.tips[tooltip] and self.tips[tooltip].link==link and self.tips[tooltip].pop==tooltip.population and MUTATION~='duplicate-lines' then return end
 local data=PawnGetItemData(link)
 if not data or not data.Link or data.pending then
  self.pending[item]={link=link,generation=self.generation};self.tips[tooltip]={item=item,link=link,pending=true};self:Schedule();return
 end
 self.work.annotations=self.work.annotations+1
 if MUTATION=='hardcoded-text' then tooltip:AddLine('Protection: +28% upgrade')
 else PawnUpdateTooltip(tooltip:GetName(),'SetHyperlink',link)end
 self.tips[tooltip]={item=item,link=link,pop=tooltip.population}
end
function Bridge:RetryTip(item)
 for tooltip,record in pairs(self.tips)do if record.item==item and record.pending then self:Annotate(tooltip,item)end end
end
function Bridge:Invalidate()
 if not self.open or self.dirty then return end
 self.dirty=true;local generation=self.generation
 C_Timer.After(0,function()
  self.dirty=false;if generation~=self.generation or not self.open then return end
  self.work.refreshes=self.work.refreshes+1;self.attempts=0;self.pending={}
  for _,item in ipairs(self.buttons)do self:UpdateArrow(item)end
  for tooltip,record in pairs(self.tips)do
   if tooltip:IsShown() and self:Identity(record.item)==record.link then ImmersionFrame:SetItemTooltip(tooltip,record.item)end
  end
  self:Schedule()
 end)
end
function Bridge:Install()
 if self.installed then return end;self.installed=true
 hooksecurefunc(ImmersionFrame,'UpdateItems',function()
  self:Start(ImmersionFrame.TalkBox.Elements.Content.RewardsFrame.Buttons)
 end)
 ImmersionFrame:HookScript('OnHide',function()self:Close()end)
 hooksecurefunc(ImmersionFrame,'SetItemTooltip',function(_,tooltip,item)
  tooltip.population=(tooltip.population or 0)+1;self:Annotate(tooltip,item)
 end)
 hooksecurefunc('PawnResetTooltips',function()self:Invalidate()end)
 hooksecurefunc('PawnResetBags',function()self:Invalidate()end)
 self.eventFrame=CreateFrame('Frame')
 for _,event in ipairs({'GET_ITEM_INFO_RECEIVED','ITEM_DATA_LOAD_RESULT','PLAYER_EQUIPMENT_CHANGED','PLAYER_SPECIALIZATION_CHANGED'})do self.eventFrame:RegisterEvent(event)end
 self.eventFrame:SetScript('OnEvent',function(_,event,id,success)
  if event=='GET_ITEM_INFO_RECEIVED' or event=='ITEM_DATA_LOAD_RESULT' then
   if success==false then return end
   local matches=false
   for _,item in ipairs(self.buttons or {})do
    local link=self:Identity(item)
    if link and C_Item.GetItemInfoInstant(link)==id then matches=true;break end
   end
   if not matches then return end
  elseif event=='PLAYER_SPECIALIZATION_CHANGED' and id~='player' then return end
  self:Invalidate()
 end)
end
