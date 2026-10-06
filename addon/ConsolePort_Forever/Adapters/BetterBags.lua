local _,Addon=...
local Bags={}
Addon.BetterBagsAdapter=Bags
local faces={PAD1=true,PAD2=true,PAD3=true,PAD4=true}
local function opaque(api,value) return api.issecretvalue and api.issecretvalue(value) end
function Bags.New(db,api,current)
    return setmetatable({db=db,api=api,current=current},{__index=Bags})
end
function Bags:Probe()
    local api=self.api
    if not api.C_AddOns or api.C_AddOns.GetAddOnMetadata('BetterBags','Version')~='v0.5.14'
        or not api.C_AddOns.IsAddOnLoaded('BetterBags') or not api.LibStub then return false,'audited BetterBags v0.5.14 required' end
    if not api.ContainerFrameItemButtonMixin or not api.C_Container or not api.C_Container.GetContainerItemInfo or not api.C_Container.GetContainerNumSlots
        or not api.GetCursorInfo or not api.ClearCursor or not api.C_Item or not api.C_Item.GetItemGUID or not api.ItemLocation then return false,'native item identity/container APIs unavailable' end
    local lib=api.LibStub('AceAddon-3.0',true)
    local addon=lib and lib:GetAddon('BetterBags',true)
    local items=addon and addon:GetModule('ItemFrame',true)
    if not items or type(items.buttonsBySlotkey)~='table' or not addon.Bags then return false,'native BetterBags physical item pool not initialized' end
    local left,right,cancel,special=self.db('Settings/UICursorLeftClick'),self.db('Settings/UICursorRightClick'),self.db('Settings/UICursorCancel'),self.db('Settings/UICursorSpecial')
    if not faces[left] or not faces[right] or not faces[cancel] or not faces[special] or left==right or left==cancel or right==cancel or special==left or special==right or special==cancel then return false,'native distinct face click/cancel keys unavailable' end
    self.addon,self.items,self.left,self.right,self.cancel,self.special=addon,items,left,right,cancel,special
    return true
end
function Bags:Identify(context)
    if not context or context.kind~='window' then return end
    local owned=false
    for _,bag in pairs(self.addon.Bags) do if bag.frame==context.frame then owned=true break end end
    if not owned then return end
    local node=context.data
    if not node or node.GetSlotAndBagID~=self.api.ContainerFrameItemButtonMixin.GetSlotAndBagID then return end
    local slot,bag=node:GetSlotAndBagID()
    if opaque(self.api,slot) or opaque(self.api,bag) or type(slot)~='number' or type(bag)~='number' or slot<1 or slot%1~=0 or bag%1~=0 then return end
    local item=self.items.buttonsBySlotkey[bag..'_'..slot]
    if not item or item.button~=node or item.isVirtual then return end
    return node,bag,slot
end
function Bags:Snapshot(node,bag,slot)
    local api=self.api
    local capacity=api.C_Container.GetContainerNumSlots(bag)
    if opaque(api,capacity) or type(capacity)~='number' or capacity~=capacity or capacity>=math.huge or capacity%1~=0 or slot>capacity then return end
    local info=api.C_Container.GetContainerItemInfo(bag,slot)
    local cursor,cursorID=api.GetCursorInfo()
    if opaque(api,cursor) or opaque(api,cursorID) or (cursor~=nil and type(cursor)~='string') or (cursorID~=nil and type(cursorID)~='string' and type(cursorID)~='number') then return end
    local token=bag..':'..slot..':'..tostring(cursor)..':'..tostring(cursorID)
    for _,name in ipairs({'MerchantFrame','BankFrame','MailFrame','TradeFrame','AuctionHouseFrame'}) do
        local frame=api[name]
        token=token..':'..tostring(frame and frame:IsShown() or false)
    end
    local merchantTab=api.MerchantFrame and api.MerchantFrame.selectedTab
    if opaque(api,merchantTab) then return end
    token=token..':'..tostring(merchantTab)
    if info==nil then return {token=token..':empty',empty=true,cursor=cursor} end
    if type(info)~='table' then return end
    for _,key in ipairs({'itemID','stackCount','isLocked','hasLoot'}) do if opaque(api,info[key]) then return end end
    if type(info.itemID)~='number' or info.itemID<1 or info.itemID>=math.huge or info.itemID%1~=0 or type(info.stackCount)~='number' or info.stackCount<1 or info.stackCount>=math.huge or info.stackCount%1~=0 or type(info.isLocked)~='boolean' or type(info.hasLoot)~='boolean' then return end
    local guid=api.C_Item.GetItemGUID(api.ItemLocation:CreateFromBagAndSlot(bag,slot))
    if opaque(api,guid) or type(guid)~='string' or guid=='' then return end
    return {token=token..':'..guid..':'..info.itemID..':'..info.stackCount..':'..tostring(info.isLocked)..':'..tostring(info.hasLoot),locked=info.isLocked,cursor=cursor,hasLoot=info.hasLoot}
end
function Bags:ClearButton()
    if self.clear then return self.clear end
    local button=self.api.CreateFrame('Button',nil,self.api.UIParent)
    button:RegisterForClicks('AnyDown','AnyUp') button:EnableMouse(false)
    button:SetScript('OnClick',function(_,_,down)
        if not down and not self.api.InCombatLockdown() and self.api.GetCursorInfo()=='item' then self.api.ClearCursor() end
    end)
    self.clear=button return button
end
function Bags:MenuButton()
    if self.menu then return self.menu end
    local button=self.api.CreateFrame('Button',nil,self.api.UIParent)
    button:RegisterForClicks('AnyDown','AnyUp') button:EnableMouse(false)
    button:SetScript('OnClick',function(_,_,down)
        if down or self.api.InCombatLockdown() then return end
        local node,bag,slot=self:Identify(self.current())
        local state=node and self:Snapshot(node,bag,slot)
        if not state or state.locked or state.empty then return end
        -- Same Demand/SetItem route as native Hooks; module enablement remains
        -- native. Do not invent an item menu or call its item actions.
        local menu=self.db.Modules:Demand('ItemMenu')
        if menu and type(menu.SetItem)=='function' then menu:SetItem(bag,slot) end
    end)
    self.menu=button return button
end
function Bags:CloseTarget(frame)
    if frame.CloseButton then return frame.CloseButton end
    -- BetterBags' Default/ElvUI themes put the native close button on a
    -- decoration child, not on the registered bag root. Resolve it afresh so
    -- a hidden decoration from a previous theme cannot receive Back.
    if not frame.GetChildren then return end
    for _,child in ipairs({frame:GetChildren()}) do
        local close=child.CloseButton
        if child:IsShown() and close and close:IsShown() and close:GetParent()==child then return close end
    end
end
function Bags:Enrich(context)
    if not self.enabled then return context end
    local ready,reason=self:Probe()
    if not ready then Addon.Diagnostics:SetFeature('bags','pending',reason) return context end
    Addon.Diagnostics:SetFeature('bags','offline-verified','native item clicks/menu; item identity guards and carried-item Back; Retail secure/hardware acceptance pending')
    Addon.Diagnostics:SetFeature('bagHold','pending','exact 0.5-second transient auto-loot route unproved: native UseContainerItem has no override argument; existing native modified click retained')
    local node,bag,slot=self:Identify(context)
    if not node then return context end
    local state=self:Snapshot(node,bag,slot)
    context.token='native-bag-item'
    context.data2=tostring(context.data2)..':'..(state and state.token or 'unqualified item')
    context.clicks={}
    context.routes[self.left]=state and not state.locked and node or false
    context.routes[self.right]=state and not state.locked and not state.empty and node or false
    context.clicks[self.right]='RightButton'
    if self.db.Modules and type(self.db.Modules.Demand)=='function' then context.routes[self.special]=state and not state.locked and not state.empty and self:MenuButton() or false end
    -- Preserve the existing native special/item-menu and bare Cancel rows.
    -- Clear carried items before the bag's close route can execute.
    if state and state.cursor=='item' then context.routes[self.cancel]=self:ClearButton()
    else context.routes[self.cancel]=self:CloseTarget(context.frame) or false end
    for key in pairs(context.routes) do for _,modifier in ipairs({'','SHIFT-','CTRL-','CTRL-SHIFT-'}) do context.chords[modifier..key]=nil end end
    local validate=function()
        local current=self.current()
        local currentNode,currentBag,currentSlot=self:Identify(current)
        if currentNode~=node or currentBag~=bag or currentSlot~=slot then return false end
        local now=self:Snapshot(node,bag,slot)
        return state and now and now.token==state.token
    end
    context.validators={[self.left]=validate,[self.right]=validate,[self.cancel]=validate,[self.special]=validate}
    return context
end
