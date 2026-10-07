local _,Addon=...
local Access={classes={WARRIOR=true,PRIEST=true,ROGUE=true,DRUID=true,PALADIN=true}}
Addon.HiddenAccess=Access
Access.SEAT_BINDING='CLICK ConsolePortForeverVehicleSeatsToggle:LeftButton'
Access.Toggle=[[
    if down then return end;
    local panel=self:GetFrameRef('panel');
    local seat=self:GetFrameRef('seat');
    if panel:IsShown() then panel:Hide();
    elseif self:GetAttribute('cpf-enabled') and seat:IsShown() then panel:Show() end;
]]
local function clear(set)
    for index=#set,1,-1 do
        if set[index].cpfHiddenAccess then table.remove(set,index) end
    end
end
function Access:Refresh(api,enabled)
    self.stanceReady,self.vehicleReady=false,false
    if api.InCombatLockdown() then return false,'hidden controls update waits for combat to end' end
    local adapter=Addon.adapters and Addon.adapters.rings
    local ready=adapter and adapter:Probe()
    if not ready then
        if self.toggle then self.toggle:SetAttribute('cpf-enabled',nil) self.panel:Hide() end
        return false,'native rings unavailable; Blizzard controls retained'
    end
    local rings=adapter.rings
    if rings:IsShown() then return false,'current ring must close before hidden controls update' end
    self.watched=self.watched or setmetatable({},{__mode='k'})
    if not self.watched[rings] then
        self.watched[rings]=true
        rings:HookScript('OnHide',function() api.C_Timer.After(0,function() Addon.BlizzardVisibility:Update() end) end)
    end
    local wanted=enabled and Addon.record and Addon.record.ringAccepted
    local discovery=wanted and Addon.RingDiscovery.Capture(api,Addon.guid)
    local class=type(api.UnitClass)=='function' and select(2,api.UnitClass('player'))
    local classID=adapter.api.classSet
    local binding=classID and rings:GetBindingForSet(classID)
    local classReady=discovery and discovery.formsReady and self.classes[class] and classID
        and api.GetBindingAction('CTRL-PADFORWARD',true)==binding
    local old=Addon.Core.Copy(rings.Data)
    for _,set in pairs(rings.Data) do clear(set) end
    if classReady then
        local set=rings.Data[classID]
        if not set and not rings.Shared[classID] then
            set={[0]={name='Class abilities'}} rings.Data[classID]=set
        end
        if set then
            local present={}
            for _,entry in ipairs(set) do if entry.type=='spell' then present[entry.spell]=true end end
            for _,form in ipairs(discovery.forms) do
                if not present[form.spell] then
                    set[#set+1]={type='spell',spell=form.spell,autoassigned=true,cpfHiddenAccess=true}
                    present[form.spell]=true
                end
            end
            self.stanceReady=true
        end
    end
    local utility=rings.Data[adapter.api.defaultSet]
    local utilityBinding=rings:GetBindingForSet(adapter.api.defaultSet)
    local seat=api.VehicleSeatIndicator
    local seatReady=wanted and utility and api.GetBindingAction('SHIFT-PADFORWARD',true)==utilityBinding
        and seat and api.VehicleSeatIndicatorMixin and seat.UpdateShownState==api.VehicleSeatIndicatorMixin.UpdateShownState
        and Addon.UIWindows.CanUse(Addon.adapters.consoleport.db)
        and api.ConsolePort and type(api.ConsolePort.AddInterfaceCursorFrame)=='function'
        and Addon.adapters.consoleport.db.Bindings and type(Addon.adapters.consoleport.db.Bindings.Dynamic)=='table'
    if seatReady and (not self.panel or self.seat==seat) then
        if not self.panel then
            local panel=api.CreateFrame('Frame','ConsolePortForeverVehicleSeats',api.UIParent,'SecureHandlerBaseTemplate')
            panel:SetSize(128,128) panel:SetPoint('CENTER',api.UIParent,'CENTER') panel:Hide()
            self.panel,self.seat=panel,seat
            panel:WrapScript(seat,'OnHide',[[control:Hide()]])
            local toggle=api.CreateFrame('Button','ConsolePortForeverVehicleSeatsToggle',api.UIParent,'SecureHandlerClickTemplate')
            toggle:SetSize(1,1) toggle:SetPoint('TOPLEFT',api.UIParent,'TOPLEFT') toggle:EnableMouse(false)
            toggle:RegisterForClicks('AnyDown','AnyUp') toggle:SetAttribute('useOnKeyDown',false)
            toggle:SetFrameRef('panel',panel) toggle:SetFrameRef('seat',seat)
            toggle:SetAttribute('_onclick',self.Toggle)
            self.toggle=toggle
            local close=api.CreateFrame('Button',nil,panel,'UIPanelButtonTemplate,SecureHandlerClickTemplate')
            close:SetSize(80,24) close:SetPoint('TOP',seat,'BOTTOM',0,-4)
            close:SetText('Close') close:RegisterForClicks('AnyDown','AnyUp')
            close:SetAttribute('useOnKeyDown',false)
            close:SetFrameRef('panel',panel) close:SetAttribute('_onclick',[[if not down then self:GetFrameRef('panel'):Hide() end]])
            self.close=close
            api.ConsolePort:AddInterfaceCursorFrame(panel)
            local description={binding=self.SEAT_BINDING,name='Vehicle seats',desc='Show vehicle seats; select a seat with the interface cursor, then Close.',texture=132331}
            table.insert(Addon.adapters.consoleport.db.Bindings.Dynamic,description)
        end
        self.toggle:SetAttribute('cpf-enabled',true)
        utility[#utility+1]={type='custom',binding=self.SEAT_BINDING,autoassigned=true,cpfHiddenAccess=true}
        self.vehicleReady=true
    elseif self.toggle then self.toggle:SetAttribute('cpf-enabled',nil) self.panel:Hide() end
    if not Addon.Core.Equal(old,rings.Data) then rings:RefreshAll() end
    if self.stanceReady then
        local present={}
        for _,entry in ipairs(rings.Data[classID] or {}) do if entry.type=='spell' then present[entry.spell]=true end end
        for _,form in ipairs(discovery.forms) do if not present[form.spell] then self.stanceReady=false end end
    end
    return true,'Class ring: R2 + menu; vehicle seats: L2 + menu utility ring. Press, point, release; native confirmation setting retained.'
end
