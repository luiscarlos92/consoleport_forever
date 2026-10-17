-- Explicit modeled C/frame boundary. No actual game globals or saved data enter this VM.
unpack=table.unpack; format=string.format; gsub=string.gsub; strfind=string.find
strsub=string.sub; strlower=string.lower; strlen=string.len
sort=table.sort; tinsert=table.insert; abs=math.abs; max=math.max
mod=function(a,b)return a%b end
QUEST_KING_VARIAN_WRYNN='King';QUEST_WARCHIEF_VOLJIN='Warchief';QUEST_KHADGAR='Khadgar'
REWARD_CHOOSE='Choose reward';REWARD_CHOICES='Choices';REWARD_ITEMS_ONLY='You will receive'
function GetMaterialTextColors()return {},{}end
ITEM_LEVEL='Item Level %d'; ITEM_LEVEL_PLUS='Item Level %d+'
PawnDiamondTexture='|TInterface\\AddOns\\Pawn\\Textures\\Diamond:0|t'
PawnUpgradeTexture='|TInterface\\AddOns\\Pawn\\Textures\\UpgradeArrow:0|t'
PawnQuestionTexture='?'; PawnBestArmorMinimumLevel=0; PawnArmorSpecializationLevel=27
PawnNeverShowUpgradesFor={}; INVSLOT_MAINHAND=16; INVSLOT_OFFHAND=17
QUEST_REWARD_CONTEXT_FONT_COLOR={r=1,g=1,b=0}; INSPECT='Inspect'
Enum={TooltipDataType={Item=0},ItemClass={Armor=4}}
VgerCore={IsMainline=true,IsDraenorOrLater=true,RangedSlotExists=false,
 Color={Blue='|cff66c0ff',DarkBlue='|cff4488aa',OrangeR=1,OrangeG=.5,OrangeB=0},
 Fail=function(s) error(s) end,Assert=assert,
 StringFindReverse=function(s,needle) local p,last=1; while true do local at=string.find(s,needle,p,true);if not at then return last end;last=at;p=at+1 end end}
function wipe(t) for k in pairs(t) do t[k]=nil end end
function UnitLevel() return MODEL.level end
function UnitClass() return 'Paladin','PALADIN',2 end
function GetInventoryItemLink(_,slot) return MODEL.equipped[slot] end
function GetQuestID() return MODEL.quest end
function GetQuestItemLink(kind,id) return MODEL.rewards[kind..id] end
function GetTimePreciseSec() MODEL.clock=MODEL.clock+(MODEL.cost or 0);return MODEL.clock end
function GetTime()return MODEL.clock end
function issecretvalue(v) return type(v)=='table' and v.secret==true end
MODEL={level=80,clock=1,cost=0,quest=100,equipped={},rewards={},items={},timers={},counts={compare=0,nativeSets=0,showEvents=0}}
C_Item={GetItemInfo=function(link) local i=MODEL.items[link];if not i or i.pending then return end;return i.Name,link,i.Rarity,i.Level,i.MinLevel or 1,nil,nil,nil,nil,nil,i.price end}
function C_Item.GetItemInfoInstant(link)local i=MODEL.items[link];return i and i.ID end
C_AddOns={IsAddOnLoaded=function(name) return MODEL.loaded==nil or MODEL.loaded[name]~=false end,
 GetAddOnMetadata=function(name) return ({Pawn='2.13.17',Immersion='1.4.61'})[name] end}
C_Timer={}
function C_Timer.NewTimer(delay,fn)
 local t={at=MODEL.clock+delay,fn=fn,cancelled=false};function t:Cancel()self.cancelled=true end
 MODEL.timers[#MODEL.timers+1]=t;return t
end
function C_Timer.After(delay,fn) return C_Timer.NewTimer(delay,fn) end
function RunTimers()
 local q=MODEL.timers;MODEL.timers={}
 for _,t in ipairs(q)do if not t.cancelled then MODEL.clock=math.max(MODEL.clock,t.at);t.fn()end end
end
function hooksecurefunc(obj,key,fn)
 if type(obj)=='string' then fn=key;key=obj;obj=_G end
 local original=assert(obj[key],key)
 obj[key]=function(...) local ret={original(...)};fn(...);return unpack(ret) end
end
local methods={}
function methods:SetScript(k,f)self.scripts[k]=f end
function methods:GetScript(k)return self.scripts[k]end
function methods:HookScript(k,f)local old=self.scripts[k];self.scripts[k]=function(...)if old then old(...)end;f(...)end end
function methods:SetParent(p)
 if self.parent then for i,c in ipairs(self.parent.children)do if c==self then table.remove(self.parent.children,i);break end end end
 self.parent=p;if p then p.children[#p.children+1]=self end
end
function methods:GetParent()return self.parent end
function methods:GetName()return self.name end
function methods:SetOwner(p,anchor)self.owner=p;self.anchorType=anchor end
function methods:SetSize(w,h)self.w=w;self.h=h end
function methods:SetWidth(w)self.w=w end
function methods:SetHeight(h)self.h=h end
function methods:GetWidth()return self.w end
function methods:GetHeight()return self.h end
function methods:GetSize()return self.w,self.h end
function methods:SetPoint(point,other,relative,x,y)
 if type(other)~='table' then self.anchor=nil;return end
 self.anchor={point,other,relative,x or 0,y or 0}
end
function methods:GetLeft()
 local a=self.anchor;if not a then return self.x or 0 end
 local left=a[2]:GetLeft();if a[3]=='TOPRIGHT' then left=left+a[2]:GetWidth()end
 return left+a[4]
end
function methods:GetTop()
 local a=self.anchor;if not a then return self.y or 600 end
 local top=a[2]:GetTop();if a[3]=='BOTTOM' then top=top-a[2]:GetHeight()end
 return top+a[5]
end
function methods:GetBottom()return self:GetTop()-self.h end
function methods:GetRight()return self:GetLeft()+self.w end
function methods:GetChildren()return unpack(self.children)end
function methods:GetRegions()return end
function methods:ClearAllPoints()self.anchor=nil end
function methods:SetAllPoints()end
function methods:SetFrameStrata(v)self.strata=v end
function methods:SetFrameLevel(v)self.frameLevel=v end
function methods:SetID(v)self.id=v end
function methods:GetID()return self.id end
function methods:SetScale(v)self.scale=v end
function methods:GetScale()return self.scale or 1 end
function methods:SetAlpha(v)self.alpha=v end
function methods:GetAlpha()return self.alpha or 1 end
function methods:SetTexture(v)self.texture=v end
function methods:GetTexture()return self.texture end
function methods:SetAtlas(v,useAtlasSize)self.atlas=v;self.useAtlasSize=useAtlasSize end
function methods:SetShown(v)if v then self:Show()else self:Hide()end end
function methods:Show()local old=self.shown;self.shown=true;if not old and self.scripts.OnShow then MODEL.counts.showEvents=MODEL.counts.showEvents+1;self.scripts.OnShow(self)end end
function methods:Hide()local old=self.shown;self.shown=false;if old and self.scripts.OnHide then self.scripts.OnHide(self)end end
function methods:IsShown()return self.shown==true end
function methods:IsVisible()return self:IsShown() and (not self.parent or self.parent:IsVisible())end
function methods:EnableMouse()end
function methods:RegisterEvent(name)self.events=self.events or {};self.events[name]=true end
function methods:SetColorTexture()end
function methods:SetText(v)self.text=v end
function methods:GetText()return self.text end
function methods:SetTextColor()end
local function NewFrame(name,parent)
 local t=setmetatable({name=name,w=1,h=1,shown=false,children={},scripts={}}, {__index=methods})
 t:SetParent(parent);if name then _G[name]=t end;return t
end
function methods:CreateTexture(_,layer,_,subLevel)local t=NewFrame(nil,self);t.drawLayer=layer;t.subLevel=subLevel;return t end
local function visibleText(s)return (s:gsub('|T.-|t','*'):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''))end
local function measure(t)
 local longest=0;for _,line in ipairs(t.lines)do longest=math.max(longest,#visibleText(line.left or '')+#visibleText(line.right or ''))end
 -- Deliberately modeled metrics, not a font/pixel assertion.
 t.w=math.max(150,longest*6+16);t.h=#t.lines*14+16
end
function methods:AddLine(s,r,g,b)
 self.lines[#self.lines+1]={left=s,r=r,g=g,b=b};measure(self)
 local row=NewFrame(nil);function row:GetText()return self.text end
 row.text=s;_G[self.name..'TextLeft'..#self.lines]=row
end
function methods:AddDoubleLine(left,right,r,g,b)self.lines[#self.lines+1]={left=left,right=right,r=r,g=g,b=b};measure(self)end
function methods:NumLines()return #self.lines end
function methods:GetItem()
 local i=MODEL.items[self.link]
 if RUNTIME and i and i.pending then return nil,nil end
 return i and i.Name,self.link
end
function methods:GetPrimaryTooltipData()return {type=0,hyperlink=self.link}end
function methods:SetQuestItem(kind,index)
 MODEL.counts.nativeSets=MODEL.counts.nativeSets+1
 self.link=GetQuestItemLink(kind,index);self.lines={};local i=MODEL.items[self.link]
 if i then self:AddLine(i.Name);self:AddLine('Item Level '..i.Level);self:AddLine(i.InvType)end
 self.kind=kind;self.questIndex=index
end
function methods:SetQuestCurrency()self.lines={};self.link=nil;self:AddLine('Currency')end
function CreateFrame(kind,name,parent,template)
 local t=NewFrame(name,parent)
 if kind=='GameTooltip' then
  t.lines={};t.Icon=NewFrame(nil,t);t.Icon.Texture=NewFrame(nil,t.Icon)
  t.Hilite=NewFrame(nil,t);t.Button=NewFrame(nil,t);t.shoppingTooltips=GameTooltip.shoppingTooltips
  t.NineSlice={SetBorderColor=function(_,r,g,b,a)t.border={r,g,b,a}end}
  t:SetScript('OnShow',NativeTooltipOnShow)
 end
 return t
end
function GameTooltip_AddBlankLineToTooltip(t)t:AddLine(' ')end
function GameTooltip_AddColoredLine(t,text,color)t:AddLine(text,color.r,color.g,color.b)end
UIParent=NewFrame('UIParent');GameTooltip=NewFrame('GameTooltip');GameTooltip.lines={}
GameTooltip.NineSlice={SetBorderColor=function()end}
GameTooltip.shoppingTooltips={NewFrame('ShoppingTooltip1'),NewFrame('ShoppingTooltip2')}
C_TooltipComparison={CompareItem=function(item,tooltip)
 assert(item.hyperlink==tooltip.link,'native comparison identity');MODEL.counts.compare=MODEL.counts.compare+1
 GameTooltip.shoppingTooltips[1]:Show()
 if MUTATION=='lose-on-compare' then tooltip.lines={}end
end}
ImmersionFrame=NewFrame('ImmersionFrame');ImmersionFrame.Inspector=NewFrame('Inspector')
local inspector=ImmersionFrame.Inspector;inspector.parent=ImmersionFrame;inspector.Items={};inspector.Active={}
inspector.tooltipFramePool={count=0,active={},inactive={}}
for _,name in ipairs({'Choices','Extras'})do inspector[name]=NewFrame(nil,inspector);inspector[name].Columns={};inspector[name].Text=NewFrame(nil)end
ImmersionFrame.TalkBox={Elements={Content={RewardsFrame={Buttons={},ItemChooseText=NewFrame(nil),ItemReceiveText=NewFrame(nil)}},Progress={Buttons={},ReqText=NewFrame(nil)}}}
ImmersionFrame.TalkBox.Dim=function()end;ImmersionFrame.TalkBox.Undim=function()end
function ImmersionFrame:AddHint()end;function ImmersionFrame:RemoveHint()end
function inspector:SetFocus(index)self.focus=self.Active[index]end
function inspector:GetFocus()return self.focus end
ImmersionL={Backdrops={TOOLTIP_HILITE={}},SetBackdrop=function()end}
function ImmersionL.Mixin(obj,...)for _,src in ipairs({...})do for k,v in pairs(src)do obj[k]=v end end end
function ImmersionL.UIFrameFadeIn(obj,_,_,alpha)obj:SetAlpha(alpha)end
function ImmersionL.UIFrameFadeOut(obj,_,_,alpha)obj:SetAlpha(alpha)end
ImmersionAPI={}
function ImmersionAPI:GetNumQuestRewards()return 0 end
function ImmersionAPI:GetNumQuestChoices()return MODEL.numChoices or 0 end
function ImmersionAPI:GetNumRewardCurrencies()return 0 end
function ImmersionAPI:GetRewardMoney()return 0 end
function ImmersionAPI:GetRewardSkillPoints()return nil,nil,0 end
function ImmersionAPI:GetRewardXP()return 0 end
function ImmersionAPI:GetRewardArtifactXP()return 0 end
function ImmersionAPI:GetRewardHonor()return 0 end
function ImmersionAPI:GetRewardTitle()return nil end
function ImmersionAPI:GetQuestRewardSpells()return {}end
function ImmersionAPI:GetQuestItemInfoLootType()return 0 end
function GetQuestItemInfo(kind,id)
 local i=MODEL.items[GetQuestItemLink(kind,id)];if not i then return end
 return i.Name,'texture-'..i.ID,1,i.Rarity,true,i.ID,0
end
function SetItemButtonCount(b,v)b.count=v end
function SetItemButtonTexture(b,v)b.Icon:SetTexture(v)end
function SetItemButtonTextureVertexColor(b,r,g,blue)b.textureColor={r,g,blue}end
function SetItemButtonNameFrameVertexColor(b,r,g,blue)b.nameColor={r,g,blue}end
FlagsUtil={IsSet=function(value,flag)return value%(2*flag)>=flag end}
BetterItems={};BetterDatabase={}
function BetterDatabase:GetUpgradeIconProvider()return MODEL.provider or 'None'end
function BetterDatabase:GetUpgradeIconProviderUserSet()return MODEL.providerSet or false end
local pawnModule={};BetterPawn=pawnModule
local addon={GetModule=function(_,name)return ({Items=BetterItems,Events={RegisterEvent=function(_,_,fn)MODEL.lateRegister=fn end,SendMessage=function()end}})[name]end,
 NewModule=function()return pawnModule end}
function LibStub()return {GetAddon=function()return addon end}end
-- Suppress upstream informational prints; receipt is emitted by the runner.
print=function()end
