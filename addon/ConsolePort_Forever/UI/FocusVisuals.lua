local _, Addon = ...
local Visuals={regions=setmetatable({},{__mode='k'}),focused=false}
Addon.FocusVisuals=Visuals
local banks={'Base','L2','R2','L2R2'}
-- Keep action identity visible while UI owns input. Only transient gameplay
-- feedback yields to the cursor; hiding icons made the entire HUD look empty.
local regions={'HighlightTexture','CheckedTexture','PushedTexture','Flash','Border','SpellHighlightTexture','NewActionTexture'}
function Visuals:Probe(bridge,api)
    return bridge.db.Cursor and type(bridge.db.RegisterCallback)=='function'
        and type(api.hooksecurefunc)=='function' or false
end
function Visuals:Region(region,api)
    if not region or type(region.GetAlpha)~='function' or type(region.SetAlpha)~='function' then return end
    local state=self.regions[region]
    if not state then
        state={alpha=region:GetAlpha()}
        self.regions[region]=state
        api.hooksecurefunc(region,'SetAlpha',function(_,alpha)
            if state.internal then return end
            state.alpha=alpha
            if self.focused then state.internal=true region:SetAlpha(0) state.internal=nil end
        end)
    end
    state.internal=true
    region:SetAlpha(self.focused and 0 or state.alpha)
    state.internal=nil
end
function Visuals:Refresh(api)
    for _,name in ipairs(banks) do
        local bank=api['ConsolePortGroup'..name]
        if bank and bank.buttons then
            for _,button in pairs(bank.buttons) do
                for _,key in ipairs(regions) do self:Region(button[key],api) end
            end
        end
    end
end
function Visuals:SetFocus(focused,api)
    self.focused=not not (self.enabled and focused)
    for region,state in pairs(self.regions) do
        state.internal=true region:SetAlpha(self.focused and 0 or state.alpha) state.internal=nil
    end
    self:Refresh(api)
end
function Visuals:Enable(bridge,api,enabled)
    self.enabled=not not enabled
    if enabled and not self:Probe(bridge,api) then return false,'native interface cursor unavailable' end
    if not self.registered and enabled then
        self.registered=true
        bridge.db:RegisterCallback('OnCursorShow',function() self:SetFocus(true,api) end)
        bridge.db:RegisterCallback('OnCursorHide',function() self:SetFocus(false,api) end)
        bridge.bar:RegisterSafeCallback('OnLayoutChanged',function() self:Refresh(api) end)
        api.hooksecurefunc(bridge.db.Cursor,'SetBasicControls',function(cursor)
            self:SetFocus(cursor:IsShown() and not api.InCombatLockdown(),api)
        end)
    end
    local cursor=bridge.db.Cursor
    -- The native interface cursor owns ordinary UI input. Gameplay rings use
    -- their own radial handler and do not announce these callbacks.
    self:SetFocus(cursor and cursor:IsShown() and not cursor.isCombatPaused,api)
    return true
end
