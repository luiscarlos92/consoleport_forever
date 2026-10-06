local _,Addon=...
local Hints={}
Addon.ItemHints=Hints
local function opaque(api,value) return api.issecretvalue and api.issecretvalue(value) end
local function shown(frame)
    return frame and frame.IsShown and frame:IsShown() and not (frame.IsForbidden and frame:IsForbidden())
end
local function within(node,frame)
    for _=1,32 do
        if not node then return false end
        if node==frame then return true end
        node=node.GetParent and node:GetParent()
    end
    return false
end
function Hints.New(db,api)
    return setmetatable({db=db,api=api},{__index=Hints})
end
function Hints:Owner(tooltip)
    local api,cursor=self.api,self.db.Cursor
    if not self.enabled or api.InCombatLockdown() or not shown(cursor) or cursor.isCombatPaused
        or shown(api.ConsolePortKeyboard) or tooltip~=api.GameTooltip
        or not tooltip.GetOwner or (tooltip.IsForbidden and tooltip:IsForbidden()) then return end
    local node=tooltip:GetOwner()
    if not shown(node) or cursor:GetCurrentNode()~=node or (node.IsEnabled and not node:IsEnabled()) then return end
    if api.GetCursorInfo then
        local carried=api.GetCursorInfo()
        if opaque(api,carried) or carried~=nil then return end
    end
    return node
end
function Hints:Prompt(setting,text)
    local device=self.db('Gamepad/Active')
    local button=self.db('Settings/'..setting)
    if not device or type(device.GetTooltipButtonPrompt)~='function' or type(button)~='string' or button=='' then return end
    return device:GetTooltipButtonPrompt(button,text,64)
end
function Hints:Add(tooltip,setting,text)
    local prompt=self:Prompt(setting,text)
    if not prompt or not tooltip.NumLines or not tooltip.GetName then return end
    local name=tooltip:GetName()
    if not name then return end
    -- Native ConsolePort may already have supplied this action. Inspect the
    -- rendered lines instead of caching by item: pooled tooltips are rebuilt.
    for index=1,tooltip:NumLines() do
        local line=self.api[name..'TextLeft'..index]
        local value=line and line:GetText()
        if opaque(self.api,value) then return end
        if value==prompt then return end
    end
    tooltip:AddLine(prompt)
    tooltip:Show()
end
function Hints:Merchant(node)
    local api=self.api
    local frame=api.MerchantFrame
    if not self.windowsEnabled or not shown(frame) or not within(node,frame)
        or not api.MerchantItemButton_OnEnter or node.UpdateTooltip~=api.MerchantItemButton_OnEnter then return end
    local parent=node:GetParent()
    if not parent or parent.ItemButton~=node then return end
    local index=node:GetID()
    local tab=frame.selectedTab
    if opaque(api,index) or opaque(api,tab) or type(index)~='number' or index<1 or index%1~=0 then return end
    if tab==1 and api.GetMerchantItemLink and api.GetMerchantItemLink(index) then return 'merchant' end
    if tab==2 and api.GetBuybackItemLink and api.GetBuybackItemLink(index) then return 'buyback' end
end
function Hints:Bag(node)
    local api=self.api
    if not self.bagsEnabled or not api.ContainerFrameItemButtonMixin
        or node.GetSlotAndBagID~=api.ContainerFrameItemButtonMixin.GetSlotAndBagID
        or not api.C_Container or not api.C_Container.GetContainerItemInfo then return end
    local slot,bag=node:GetSlotAndBagID()
    if opaque(api,slot) or opaque(api,bag) or type(slot)~='number' or type(bag)~='number'
        or slot<1 or slot%1~=0 or bag%1~=0 then return end
    local info=api.C_Container.GetContainerItemInfo(bag,slot)
    if type(info)~='table' or opaque(api,info.itemID) or opaque(api,info.isLocked)
        or opaque(api,info.hasLoot) or not info.itemID or info.isLocked then return end
    return info
end
function Hints:OnItem(tooltip)
    local node=self:Owner(tooltip)
    if not node then return end
    local kind=self:Merchant(node)
    if kind then
        local buyback=self.api.BUYBACK or 'Buy Back'
        self:Add(tooltip,'UICursorLeftClick',kind=='merchant' and (self.api.SELECT or 'Select') or buyback)
        self:Add(tooltip,'UICursorRightClick',kind=='merchant' and (self.api.BUY or 'Buy') or buyback)
        return
    end
    local item=self:Bag(node)
    if item and item.hasLoot and not shown(self.api.MerchantFrame) and not shown(self.api.BankFrame)
        and not shown(self.api.MailFrame) and not shown(self.api.TradeFrame) and not shown(self.api.AuctionHouseFrame) then
        self:Add(tooltip,'UICursorRightClick',self.api.OPEN or 'Open')
    end
end
function Hints:OnLine(tooltip,line)
    local node=self:Owner(tooltip)
    local text=line and line.leftText
    if not node or opaque(self.api,text) or type(text)~='string' then return end
    local item=self:Bag(node)
    if not item or not item.hasLoot or shown(self.api.MerchantFrame) or shown(self.api.BankFrame)
        or shown(self.api.MailFrame) or shown(self.api.TradeFrame) or shown(self.api.AuctionHouseFrame) then return end
    -- Replace only Blizzard's container-open instruction. Preserve item names,
    -- flavour text, comparisons and unrelated angle-bracket instructions.
    if text==(self.api.ITEM_OPENABLE or '<Right Click to Open>') then
        line.leftText=self:Prompt('UICursorRightClick',self.api.OPEN or 'Open') or text
    end
end
function Hints:Enable(enabled,windowsEnabled,bagsEnabled)
    self.enabled,self.windowsEnabled,self.bagsEnabled=not not enabled,not not windowsEnabled,not not bagsEnabled
    if not enabled or self.registered then return true end
    local processor=self.api.TooltipDataProcessor
    local types=self.api.Enum and self.api.Enum.TooltipDataType
    if not processor or not types or not types.Item or not processor.AddTooltipPostCall or not processor.AddLinePreCall then
        return false,'native item tooltip processor unavailable'
    end
    self.registered=true
    processor.AddTooltipPostCall(types.Item,function(tooltip) self:OnItem(tooltip) end)
    processor.AddLinePreCall(types.Item,function(tooltip,line) self:OnLine(tooltip,line) end)
    return true
end
