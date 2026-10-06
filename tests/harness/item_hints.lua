-- Runs after native BetterBags/Windows contracts. Tooltip rendering and game
-- item availability are host substitutes; merchant callbacks/prompt art are
-- the pinned, unmodified Blizzard/ConsolePort functions.
TEST_SUCCESS=nil
local hintDevice={Colors={},GetIconForButton=function(_,key) return 'PS5_'..key,true end}
local GamepadMixin={}
--@NATIVE_TOOLTIP_PROMPT
hintDevice.GetTooltipButtonPrompt=GamepadMixin.GetTooltipButtonPrompt
local oldDBCall=getmetatable(db).__call
setmetatable(db,{__call=function(self,key)
    if key=='Gamepad/Active' then return hintDevice end
    return oldDBCall(self,key)
end})
local posts,pres={},{}
api.TooltipDataProcessor={
    AddTooltipPostCall=function(kind,fn) assert(kind==0) posts[#posts+1]=fn end,
    AddLinePreCall=function(kind,fn) assert(kind==0) pres[#pres+1]=fn end}
api.Enum={TooltipDataType={Item=0}}
api.ITEM_OPENABLE='<Right Click to Open>' api.OPEN='Open'
local rendered={}
function tooltip:NumLines() return #rendered end
function tooltip:AddLine(text)
    rendered[#rendered+1]=text
    local value=text
    api['GameTooltipTextLeft'..#rendered]={GetText=function() return value end}
end
function tooltip:SetOwner(node) self.owner=node end
local function tooltipItem(node,lines)
    rendered={} tooltip:SetOwner(node)
    for _,text in ipairs(lines or {'Ride Ticket Book'}) do
        local line={leftText=text}
        for _,fn in ipairs(pres) do fn(tooltip,line) end
        tooltip:AddLine(line.leftText)
    end
    for _,fn in ipairs(posts) do fn(tooltip,{id=100}) end
    tooltip:Show()
end
function tooltip:SetMerchantItem() tooltipItem(self.owner) end
function tooltip:SetBuybackItem() tooltipItem(self.owner) end
function GameTooltip_ShowCompareItem() end
function ShowBuybackSellCursor() end
local purchased,selected,confirmed,boughtBack=0,0,0,0
function BuyMerchantItem(index) assert(hardware and index==1) purchased=purchased+1 end
function PickupMerchantItem(index) assert(hardware and index==1) selected=selected+1 end
function BuybackItem(index) assert(hardware and index==1) boughtBack=boughtBack+1 end
function MerchantFrame_ConfirmExtendedItemCost() assert(hardware) confirmed=confirmed+1 end
MERCHANT_HIGH_PRICE_COST=1500000
--@NATIVE_MERCHANT_BUTTONS
api.MerchantItemButton_OnEnter=MerchantItemButton_OnEnter
api.GetMerchantItemLink=function(index) return index==1 and 'item:100' end
api.GetBuybackItemLink=function(index) return index==1 and 'item:100' end
local merchantRow=CreateFrame('Frame','MerchantItem1',MerchantFrame)
local merchantButton=CreateFrame('Button','MerchantItem1ItemButton',merchantRow)
merchantRow.ItemButton=merchantButton merchantButton:SetID(1)
MerchantItemButton_OnLoad(merchantButton)
merchantButton:SetScript('OnClick',MerchantItemButton_OnClick)
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,true,true,true))
assert(#posts==1 and #pres==1)
cursor:Show() MerchantFrame:Show() cursor:SetCurrentNode(merchantButton)
MerchantFrame.selectedTab=1 MerchantItemButton_OnEnter(merchantButton)
local selectHint=hintDevice:GetTooltipButtonPrompt('PAD1','Select',64)
local buyHint=hintDevice:GetTooltipButtonPrompt('PAD3','Buy',64)
assert(rendered[2]==selectHint and rendered[3]==buyHint,'merchant omitted configured Select/Buy hints')
contexts.hints:OnItem(tooltip)
assert(#rendered==3,'tooltip refresh duplicated prompts')
hardware=true merchantButton:Click('LeftButton') merchantButton:Click('RightButton') hardware=false
assert(selected==1 and purchased==1,'hint semantics disagree with native merchant click behavior')
merchantButton.extendedCost=true
hardware=true merchantButton:Click('RightButton') hardware=false
assert(confirmed==1 and purchased==1,'hint bridge bypassed native currency confirmation')
merchantButton.extendedCost=nil
MerchantFrame.selectedTab=2 MerchantItemButton_OnEnter(merchantButton)
assert(rendered[2]:find('Buy Back',1,true) and rendered[3]:find('Buy Back',1,true),'buyback was labelled Select/Buy')
hardware=true merchantButton:Click('RightButton') hardware=false assert(boughtBack==1)
MerchantFrame:Hide() cursor:SetCurrentNode(item.button)
local options='Native Triangle Options'
tooltipItem(item.button,{'Ride Ticket Book',api.ITEM_OPENABLE,options})
local openHint=hintDevice:GetTooltipButtonPrompt('PAD3','Open',64)
assert(rendered[2]==openHint and rendered[3]==options and #rendered==3,'container instruction or native Options was lost/duplicated')
tooltipItem(item.button,{'Ride Ticket Book',options})
assert(rendered[3]==openHint,'loot container without an item spell lost its Open hint')
tooltipItem(item.button,{'Ride Ticket Book','<Unrelated flavour text>',options})
assert(rendered[2]=='<Unrelated flavour text>','unrelated tooltip instruction was rewritten')
info.hasLoot=false tooltipItem(item.button)
assert(#rendered==1,'ordinary item advertised an unsupported Open action')
info.hasLoot=true info.isLocked=true tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE and #rendered==1,'locked item advertised Open')
info.isLocked=false
MerchantFrame:Show() tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE and #rendered==1,'merchant Sell context was labelled Open')
MerchantFrame:Hide()
-- Merely visible/background/comparison tooltips have no controller prompts.
cursor:SetCurrentNode(merchantButton) tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE and #rendered==1,'background owner acquired item hints')
cursor:SetCurrentNode(item.button) cursor:Hide() tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE and #rendered==1,'mouse-only tooltip was changed')
cursor:Show() combat=true tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE and #rendered==1,'combat-paused input advertised Open')
combat=false
api.issecretvalue=function(value) return value==api.ITEM_OPENABLE end
tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE,'opaque tooltip text was processed')
api.issecretvalue=nil
-- Current configured buttons/device determine the glyph, never PS5 literals.
settings['Settings/UICursorRightClick']='PAD4'
tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==hintDevice:GetTooltipButtonPrompt('PAD4','Open',64),'remapped button kept a stale Square hint')
settings['Settings/UICursorRightClick']='PAD3'
assert(contexts:Enable({db=db,api={version='3.3.9'}},api,false))
tooltipItem(item.button,{api.ITEM_OPENABLE})
assert(rendered[1]==api.ITEM_OPENABLE and #rendered==1,'disabled policy kept custom hints')
TEST_SUCCESS=true
