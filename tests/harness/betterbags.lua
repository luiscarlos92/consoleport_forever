-- Actual BetterBags item construction/integration, native container callbacks,
-- native module Demand and native ItemMenu.SetItem; host renders/stubs engine.
TEST_SUCCESS=nil
format=string.format
function Frame:SetID(id) self.id=id end
function Frame:GetID() return self.id end
function Frame:SetAlpha(value) self.alpha=value end
function Frame:SetAllPoints() end
function Frame:RegisterForDrag() end
function Frame:EnableMouseWheel() end
function Frame:CreateFontString() return CreateFrame('Frame',nil,self) end
function Frame:GetPushedTexture() return self.PushedTexture end
local carried,carriedID=nil,nil
function GetCursorInfo() return carried,carriedID end
function CursorHasItem() return carried=='item' end
local clears=0
function ClearCursor() assert(hardware) clears=clears+1 carried,carriedID=nil,nil end
local info={itemID=100,stackCount=5,isLocked=false,hasLoot=true}
local itemGUID='Item-one'
local pickups,uses,menuShows,splitOpens=0,0,0,0
ItemLocation={CreateFromBagAndSlot=function(_,bag,slot)
    return {IsValid=function() return true end,GetBagAndSlot=function() return bag,slot end}
end}
C_Item={GetItemGUID=function() return itemGUID end,DoesItemExist=function() return info~=nil end}
C_Container={GetContainerItemInfo=function() return info end,GetContainerNumSlots=function() return 20 end,
    GetContainerItemLink=function() return 'item:100' end,
    PickupContainerItem=function(bag,slot) assert(hardware and bag==0 and slot==1) pickups=pickups+1 end,
    UseContainerItem=function(bag,slot) assert(hardware and bag==0 and slot==1) uses=uses+1 end}
C_Cursor={GetCursorItem=function() return nil end}
C_AuctionHouse={IsSellItemValid=function() return false end}
C_ItemSocketInfo={IsArtifactRelicItem=function() return false end}
C_MountJournal={IsItemMountEquipment=function() return false end}
function MerchantFrame_ResetRefundItem() end
function MerchantFrame_SetRefundItem() end
function ContainerFrame_GetExtendedPriceString() return false end
function BankUtil_IsAccountBankDepositRefundable() return false end
function SpellCanTargetItem() return false end
function SpellCanTargetItemID() return false end
MerchantFrame=CreateFrame('Frame','MerchantFrame',UIParent) MerchantFrame:Hide() MerchantFrame.selectedTab=1
BankFrame=CreateFrame('Frame','BankFrame',UIParent) BankFrame:Hide() function BankFrame:GetActiveBankType() return 0 end
MailFrame=CreateFrame('Frame','MailFrame',UIParent) MailFrame:Hide()
TradeFrame=CreateFrame('Frame','TradeFrame',UIParent) TradeFrame:Hide()
local modified
function IsModifiedClick(kind) return kind and modified==kind or not kind and modified~=nil end
function HandleModifiedItemClick() return false end
SplitStack=function() end
ContainerFrameItemButtonMixin={}
--@NATIVE_CONTAINER_METHODS
local createFrame=CreateFrame
function CreateFrame(kind,name,parent,template)
    local button=createFrame(kind,name,parent,template)
    if template=='ContainerFrameItemButtonTemplate' then
        for key,value in pairs(ContainerFrameItemButtonMixin) do button[key]=value end
        button:SetScript('OnClick',button.OnClick)
        for _,key in ipairs({'BattlepayItemTexture','NewItemTexture','ItemContextOverlay'}) do button[key]=createFrame('Frame',nil,button) end
    end
    return button
end
local decoration=CreateFrame('Frame',nil,UIParent)
decoration.PushedTexture=CreateFrame('Frame',nil,decoration)
local addon={isRetail=true,Bags={Backpack={frame=paneA},Bank={frame=paneB}},modules={}}
local events={messages={},RegisterMessage=function(self,name,fn) self.messages[name]=fn end}
addon.modules.Events=events
addon.modules.Context={New=function() return {} end}
addon.modules.Themes={GetItemButton=function() return decoration end}
function addon:GetModule(name) self.modules[name]=self.modules[name] or {} return self.modules[name] end
function addon:NewModule(name) self.modules[name]={} return self.modules[name] end
local ace={GetAddon=function(_,name) assert(name=='BetterBags') return addon end}
LibStub=function(name) assert(name=='AceAddon-3.0') return ace end
--@NATIVE_BETTERBAGS_ITEM
local items=addon.modules.ItemFrame
items.buttonsBySlotkey={}
local item=items:_DoCreate(nil,0)
item.button:SetID(1) items.buttonsBySlotkey['0_1']=item
item.frame.parent=paneA
-- Native integration registers the actual bag and demand-created menu stack.
ConsolePort.AddInterfaceCursorFrame=function(_,frame) return nativeStack:SetFrame(frame,true) end
ConsolePort.SetCursorNode=function(_,frame) cursor:SetCurrentNode(frame) end
--@NATIVE_BETTERBAGS_INTEGRATION
addon.modules.ConsolePort:Init() addon.modules.ConsolePort:OnEnable()
local Modules={Providers={ItemMenu='Menu'}}
local enabled=true
CPAPI.GetAddOnEnableState=function() return enabled and 2 or 0 end
function Modules:GetEntry() return {addon='ConsolePort_Menu'} end
local ItemMenu=CreateFrame('Frame','ActualItemMenu',UIParent)
function ItemMenu:SetBagAndSlot(bag,slot) self.bag,self.slot=bag,slot end
function ItemMenu:SetItemLocation() end
function ItemMenu:IsItemEmpty() return false end
function ItemMenu:GetItemName() return 'native item' end
function ItemMenu:GetItemQualityColor() return {color={GetRGB=function() return 1,1,1 end}} end
function ItemMenu:GetItemIcon() return 100 end
function ItemMenu:GetQuality() return 1 end
ItemMenu.Name={SetText=function() end,SetTextColor=function() end}
ItemMenu.Portrait={Icon={SetTexture=function() end},Border={SetAtlas=function() end}}
local BORDER_ATLAS={[1]='native-border'}
function ItemMenu:ClearPickup() ClearCursor() end
function ItemMenu:SetTooltip() end
function ItemMenu:SetCommands() end
function ItemMenu:FixHeight() end
function ItemMenu:RedirectCursor() menuShows=menuShows+1 end
--@NATIVE_ITEM_MENU_SET
function Modules:Load() assert(not combat) db.ItemMenu=ItemMenu end
--@NATIVE_MODULE_DEMAND
db.Modules=Modules
local settings={['Settings/UICursorLeftClick']='PAD1',['Settings/UICursorRightClick']='PAD3',
    ['Settings/UICursorCancel']='PAD2',['Settings/UICursorSpecial']='PAD4'}
setmetatable(db,{__call=function(_,key) return settings[key] end})
api.C_AddOns={GetAddOnMetadata=function(name) assert(name=='BetterBags') return 'v0.5.14' end,IsAddOnLoaded=function() return true end}
api.LibStub=LibStub api.ContainerFrameItemButtonMixin=ContainerFrameItemButtonMixin
api.C_Container=C_Container api.GetCursorInfo=GetCursorInfo api.ClearCursor=ClearCursor
api.C_Item=C_Item api.ItemLocation=ItemLocation
api.MerchantFrame=MerchantFrame api.BankFrame=BankFrame api.MailFrame=MailFrame api.TradeFrame=TradeFrame
local closed=0
paneA.CloseButton=CreateFrame('Button','NativeBagClose',paneA)
paneA.CloseButton:SetScript('OnClick',function() assert(hardware) closed=closed+1 end)
contexts:Enable({db=db,api={version='3.3.3'}},api,true,true,true)
cursor:SetCurrentNode(item.button)
assert(contexts.context.token=='native-bag-item' and contexts.context.routes.PAD1==item.button)
press(input.Widgets.PAD1,true) press(input.Widgets.PAD1,false) assert(pickups==1)
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(uses==1,'Square did not delegate native RightButton')
MerchantFrame:Show() contexts:Refresh()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(uses==2)
MerchantFrame.selectedTab=2 contexts:Refresh()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(uses==2,'native buyback guard was bypassed')
MerchantFrame:Hide() contexts:Refresh()
-- Replacing the physical item without any notification still invalidates the
-- hardware release before frontend scripts or native secure delegate clicks.
press(input.Widgets.PAD3,true) itemGUID='Item-replaced' press(input.Widgets.PAD3,false)
assert(uses==2,'changed item GUID received a stale click')
contexts:Refresh() info.isLocked=true contexts:Refresh()
press(input.Widgets.PAD1,true) press(input.Widgets.PAD1,false) assert(pickups==1)
info.isLocked=false contexts:Refresh()
press(input.Widgets.PAD1,true) item.button:SetID(2) press(input.Widgets.PAD1,false)
assert(pickups==1,'recycled bag slot received a stale click')
item.button:SetID(1) contexts:Refresh()
carried,carriedID='item',101 contexts:Refresh()
press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false)
assert(clears==1 and closed==0,'Back closed the bag before clearing its carried item')
contexts:Refresh() press(input.Widgets.PAD2,true) press(input.Widgets.PAD2,false) assert(closed==1)
-- Native demand respects disabled modules and uses actual SetItem once ready.
enabled=false db.ItemMenu=nil
press(input.Widgets.PAD4,true) press(input.Widgets.PAD4,false) assert(menuShows==0)
enabled=true press(input.Widgets.PAD4,true) press(input.Widgets.PAD4,false)
assert(menuShows==1 and ItemMenu.bag==0 and ItemMenu.slot==1)
-- Exact loot hold is still pending; native modified autoloot click remains.
modified='AUTOLOOTTOGGLE' contexts:Refresh()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(uses==3)
modified=nil
local split=stack.OpenStackSplitFrame
stack.OpenStackSplitFrame=function(_,count,owner) splitOpens=splitOpens+1 assert(count==5 and owner==item.button) end
modified='SPLITSTACK' contexts:Refresh()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(splitOpens==1 and uses==3)
modified=nil stack.OpenStackSplitFrame=split
info=nil contexts:Refresh()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(uses==3)
info={itemID=100,stackCount=5,isLocked=false,hasLoot=true} contexts:Refresh()
press(input.Widgets.PAD3,true) cursor:SetCurrentNode(target) press(input.Widgets.PAD3,false)
assert(uses==3 and contexts.context.kind=='popup','popup takeover received a stale item action')
cursor:SetCurrentNode(item.button)
local oldGUID=itemGUID
itemGUID='opaque item'
api.issecretvalue=function(value) return value=='opaque item' end
contexts:Refresh()
press(input.Widgets.PAD3,true) press(input.Widgets.PAD3,false) assert(uses==3,'opaque item identity was clicked')
itemGUID=oldGUID api.issecretvalue=nil contexts:Refresh()
press(input.Widgets.PAD3,true) combat=true contexts:Refresh() press(input.Widgets.PAD3,false) assert(uses==3)
combat=false contexts:Refresh()
assert(Addon.Diagnostics.features.bagHold.status=='pending')
assert(contexts:Enable({db=db,api={version='3.3.3'}},api,false))
TEST_SUCCESS=true
