local _, Addon = ...
local Visibility = {names={"MultiBarLeft","MultiBarRight","MultiBar5","MultiBar6","MultiBar7","MicroButtonAndBagsBar","MicroMenuContainer","MicroMenu","BagsBar","StanceBar","VehicleSeatIndicator"}}
Addon.BlizzardVisibility = Visibility

function Visibility:Probe(api)
    local native=api.EditModeActionBarMixin
    if not native or type(native.UpdateVisibility)~="function" or type(api.hooksecurefunc)~="function" or not api.UIParent then
        return false,"native action-bar visibility lifecycle unavailable"
    end
    for index=1,5 do
        local frame=api[self.names[index]]
        if not frame or frame.UpdateVisibility~=native.UpdateVisibility or frame.SetShown~=native.SetShownOverride then
            return false,"native side-bar identity unavailable: "..self.names[index]
        end
    end
    return true
end
function Visibility:Release(frame,row)
    if frame:GetParent()==(row.hidden or self.hidden) then
        row.writing=true
        frame:SetParent(row.parent)
        row.writing=false
    end
    -- A newer parent belongs to its new owner. Neither shown state, action
    -- storage, events nor the native visibility methods were ever replaced.
end
function Visibility:Refresh(api,enabled)
    self.api,self.enabled=api,enabled==true
    self.rows=self.rows or {}
    if api.InCombatLockdown() then return false,"visibility update deferred until combat ends" end
    local editing=self.editing or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown())
    if not self.enabled or editing then
        for frame,row in pairs(self.rows) do self:Release(frame,row) end
        return true,editing and "native parents restored for Edit Mode" or "native parents restored"
    end
    local ready,reason=self:Probe(api)
    if not ready then
        for frame,row in pairs(self.rows) do self:Release(frame,row) end
        return false,reason
    end
    if not self.hidden then
        self.hidden=api.CreateFrame("Frame",nil,api.UIParent,"SecureHandlerBaseTemplate")
        self.hidden:Hide()
    end
    for frame,row in pairs(self.rows) do
        if api[row.name]~=frame then self:Release(frame,row) row.foreign=true end
    end
    local pending={}
    for _,name in ipairs(self.names) do
        local frame=api[name]
        local access=Addon.HiddenAccess
        local acquired=name~='StanceBar' and name~='VehicleSeatIndicator'
            or (access and (name=='StanceBar' and access.stanceReady or name=='VehicleSeatIndicator' and access.vehicleReady))
        if name=='StanceBar' and not (api.StanceBarMixin and frame and frame.ShouldShow==api.StanceBarMixin.ShouldShow) then acquired=false end
        if frame and not acquired then
            if self.rows[frame] then self:Release(frame,self.rows[frame]) end
            frame=nil
        end
        if frame and not (self.rows[frame:GetParent()] and frame:GetParent():GetParent()==self.hidden) then
            local row=self.rows[frame]
            if not row then
                -- Clean native containers start at UIParent. A different parent
                -- is evidence of another owner; do not absorb its subtree.
                row={parent=frame:GetParent(),name=name}
                row.foreign=row.parent~=api.UIParent
                self.rows[frame]=row
                api.hooksecurefunc(frame,"SetParent",function()
                    if row.writing or not self.enabled or self.editing then return end
                    if frame:GetParent()~=(row.hidden or self.hidden) then row.foreign=true end
                end)
            end
            if row.foreign then
                pending[#pending+1]=name..": newer or non-native parent retained"
            elseif frame:GetParent()==row.parent then
                row.writing=true
                row.hidden=name=='VehicleSeatIndicator' and Addon.HiddenAccess.panel or self.hidden
                frame:SetParent(row.hidden)
                row.writing=false
                if frame:GetParent()~=row.hidden then row.foreign=true pending[#pending+1]=name..": parent change rejected" end
            elseif frame:GetParent()~=(row.hidden or self.hidden) then
                row.foreign=true pending[#pending+1]=name..": newer parent retained"
            end
        end
    end
    return #pending==0, #pending>0 and table.concat(pending,"; ") or "native shown state/events retained behind hidden parent; Retail combat/rendering acceptance pending"
end
function Visibility:UpdatePlayerResource(api,enabled)
    -- The five Holy Power runes below PlayerFrame are not the StanceBar aura
    -- buttons. Own only this native instance; nameplate/PRD clones stay native.
    local bar,native=api.PaladinPowerBarFrame,api.PaladinPowerBar
    local editing=self.editing or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown())
    local class=api.UnitClass and select(2,api.UnitClass('player'))
    local wanted=enabled and not editing and class=='PALADIN' and bar and native
        and bar.UpdatePower==native.UpdatePower and type(bar.GetAlpha)=='function'
        and type(bar.SetAlpha)=='function' and type(bar.HookScript)=='function'
        and type(api.hooksecurefunc)=='function'
    local row=self.playerResourceRow
    if row and (row.frame~=bar or not wanted) then
        if row.active then
            row.active=false row.writing=true row.frame:SetAlpha(row.alpha) row.writing=false
        end
        if row.frame~=bar then self.playerResourceRow=nil row=nil end
    end
    if not wanted then return false,'native player resource strip retained outside the installed presentation or during Edit Mode' end
    if not row then
        if api.InCombatLockdown() then return false,'player resource presentation initializes after combat' end
        local alpha=bar:GetAlpha()
        if (api.issecretvalue and api.issecretvalue(alpha)) or type(alpha)~='number' then return false,'native resource opacity unavailable' end
        row={frame=bar,alpha=alpha} self.playerResourceRow=row
        local function Suppress()
            if row.active and not row.writing then
                row.writing=true bar:SetAlpha(0) row.writing=false
            end
        end
        api.hooksecurefunc(bar,'SetAlpha',function(_,value)
            if not row.writing then row.alpha=value Suppress() end
        end)
        bar:HookScript('OnShow',Suppress)
    elseif not row.active then row.alpha=bar:GetAlpha() end
    row.active=true row.writing=true bar:SetAlpha(0) row.writing=false
    -- Preserve resource events/values, native shown state, managed parent and
    -- geometry. Inheritance hides all five runes, even after a combat reshow;
    -- latest native opacity is restored on disable/editor/replacement.
    return true,'native five-rune player strip visually suppressed; resource updates and other resource displays retained'
end
function Visibility:Update()
    if Addon.ClassActions then
        local editing=self.editing or (EditModeManagerFrame and EditModeManagerFrame:IsShown())
        local ready,detail=Addon.ClassActions.UpdateNativeBar(Addon,_G,editing)
        if Addon.Diagnostics then Addon.Diagnostics:SetFeature('classBarPresentation',ready and 'offline-verified' or 'pending',detail) end
    end
    local enabled=Addon.IsCharacterInstalled and Addon:IsCharacterInstalled() and Addon.db and Addon.db.shared.runtimePolicy.blizzardVisibility
    local resourceReady,resourceDetail=self:UpdatePlayerResource(_G,enabled)
    if Addon.Diagnostics then Addon.Diagnostics:SetFeature('playerResourcePresentation',resourceReady and 'offline-verified' or 'pending',resourceDetail) end
    if Addon.HiddenAccess then
        local active=enabled and Addon.db.shared.runtimePolicy.hiddenAccessEnabled
            and not (self.editing or (EditModeManagerFrame and EditModeManagerFrame:IsShown()))
        local ready,detail=Addon.HiddenAccess:Refresh(_G,active)
        if Addon.Diagnostics then Addon.Diagnostics:SetFeature('hiddenAccess',ready and active and 'offline-verified' or 'pending',detail) end
    end
    local ok,reason=self:Refresh(_G,enabled)
    if Addon.Diagnostics then Addon.Diagnostics:SetFeature("blizzardVisibility",enabled and ok and "offline-verified" or "pending",reason) end
end
local function Later() C_Timer.After(0,function() Visibility:Update() end) end
if EventRegistry and type(EventRegistry.RegisterCallback)=="function" then
    EventRegistry:RegisterCallback("EditMode.Enter",function() Visibility.editing=true Visibility:Update() end,Addon)
    EventRegistry:RegisterCallback("EditMode.Exit",function() Visibility.editing=false Later() end,Addon)
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","EDIT_MODE_LAYOUTS_UPDATED","ADDON_LOADED","UPDATE_BINDINGS","UPDATE_SHAPESHIFT_FORMS","SPELLS_CHANGED","PLAYER_SPECIALIZATION_CHANGED","UNIT_ENTERED_VEHICLE","UNIT_EXITED_VEHICLE"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",Later)
