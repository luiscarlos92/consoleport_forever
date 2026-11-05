local _, Addon = ...
local function ready(self)
    local bb = self:GetAddon("BetterBags")
    local bag = bb and bb.Bags and bb.Bags.Backpack
    if not (bb and bag and type(bb.IsEnabled) == "function" and bb:IsEnabled()
        and type(bb.ToggleAllBags) == "function" and type(bag.IsShown) == "function"
        and type(bb._buttons) == "table") then return end
    return bb, bag
end

function Addon:InstallBagBridge()
    if not self.active or InCombatLockdown() or self.bagState then return end
    local bb = ready(self)
    if not bb or type(hooksecurefunc) ~= "function" then return end
    local state = {handled = 0, actions = 0, installed = true}
    self.bagState = state
    -- BetterBags already owns ToggleAllBags and CloseSpecialWindows. Cancel any
    -- nested native request when that owner has handled the same call chain.
    hooksecurefunc(bb, "ToggleAllBags", function() state.handled = state.handled + 1 end)
    if type(bb.CloseSpecialWindows) == "function" then
        hooksecurefunc(bb, "CloseSpecialWindows", function() state.handled = state.handled + 1 end)
    end
    local function request(mode)
        if InCombatLockdown() then return end
        local owner, requestedBag = ready(self)
        if owner ~= bb then return end
        if type(ContainerFrame_AllowedToOpenBags) == "function" and mode ~= "close"
            and not ContainerFrame_AllowedToOpenBags() then return end
        if state.pending then
            -- Post-hooks arrive inside-out: the final outer route wins, as does
            -- a genuinely newer explicit request in the same frame.
            state.pending.mode = mode
            state.pending.bag = requestedBag
            state.pending.handled = state.handled
            return
        end
        local pending = {mode = mode, handled = state.handled, owner = bb, bag = requestedBag}
        state.pending = pending
        C_Timer.After(0, function()
            if state.pending ~= pending then return end
            state.pending = nil
            if InCombatLockdown() or state.handled ~= pending.handled then return end
            local current, bag = ready(self)
            if current ~= pending.owner or bag ~= pending.bag then return end
            if pending.mode ~= "close" and type(ContainerFrame_AllowedToOpenBags) == "function"
                and not ContainerFrame_AllowedToOpenBags() then return end
            local shown = bag:IsShown()
            local wanted
            if pending.mode == "toggle" and type(IsAnyStandardHeldBagOpen) == "function" then
                -- Native local shown state survives BetterBags' hidden container
                -- parent. This also preserves two toggles arriving in one frame.
                wanted = self:PublicCall(IsAnyStandardHeldBagOpen)
            elseif pending.mode == "open" then wanted = true
            elseif pending.mode == "close" then wanted = false end
            if type(wanted) == "boolean" and wanted ~= shown then
                -- Use BetterBags' existing context/event and rendering owner.
                -- Never call or replace a protected Blizzard function here.
                current:ToggleAllBags()
                state.actions = state.actions + 1
            end
        end)
    end
    for name, mode in pairs({ToggleBackpack = "toggle", OpenBackpack = "open",
        CloseBackpack = "close", OpenAllBags = "open", CloseAllBags = "close"}) do
        if type(_G[name]) == "function" then
            local route = mode
            hooksecurefunc(name, function() request(route) end)
        end
    end
    if type(ToggleBag) == "function" then
        hooksecurefunc("ToggleBag", function(id)
            local inventory = Constants and Constants.InventoryConstants
            local count = inventory and inventory.NumBagSlots
            if type(id) == "number" and type(count) == "number" and id >= 0 and id <= count then request("toggle") end
        end)
    end
end
