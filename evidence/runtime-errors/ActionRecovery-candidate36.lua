local _,Addon=...
local Recovery={}
Addon.ActionRecovery=Recovery
local function public(api,value)
    return not api.issecretvalue or not api.issecretvalue(value)
end
local function configuration(api,spec)
    local talents=api.C_ClassTalents
    if not talents then return end
    local active=talents.GetActiveConfigID and talents.GetActiveConfigID()
    if active and not public(api,active) then return end
    if talents.GetStarterBuildActive and talents.GetStarterBuildActive() then
        return 'starter:'..tostring(active)
    end
    -- Retail can keep the same active working config while switching saved
    -- loadouts. Use the saved identity before that shared working config.
    local saved=spec and talents.GetLastSelectedSavedConfigID and talents.GetLastSelectedSavedConfigID(spec)
    if saved and not public(api,saved) then return end
    return saved or active
end
function Recovery:Record(addon,api,event,slot)
    if not addon.record or not addon:IsCharacterInstalled() then return end
    local record=addon.record
    record.actionRecovery=record.actionRecovery or {specs={}}
    local recovery=record.actionRecovery
    local now=api.GetTime and api.GetTime() or 0
    local index=api.GetSpecialization and api.GetSpecialization()
    local spec=index and api.GetSpecializationInfo and api.GetSpecializationInfo(index)
    local config=configuration(api,spec)
    local bonus=api.GetBonusBarOffset and api.GetBonusBarOffset()
    local page=api.GetActionBarPage and api.GetActionBarPage()
    local stack=api.debugstack and api.debugstack(3,6,0) or ''
    local manual=stack:find('ConsolePort_Config',1,true) or stack:find('SpellMenu',1,true)
    if manual then recovery.manualUntil=now+2 end
    recovery.events=recovery.events or {}
    local row={event=event,time=now,combat=api.InCombatLockdown(),config=public(api,config) and config or nil,
        bonusOffset=public(api,bonus) and bonus or nil,actionPage=public(api,page) and page or nil,
        previousConfig=recovery.lastConfig,temporary=(api.HasVehicleActionBar and api.HasVehicleActionBar()) or (api.HasOverrideActionBar and api.HasOverrideActionBar()) or (api.HasTempShapeshiftActionBar and api.HasTempShapeshiftActionBar()) or false,
        writer=stack:match('Interface[/\\]AddOns[/\\]([^/\\:]+)') or 'engine/unknown',stack=stack:sub(1,1200)}
    if type(slot)=='number' and slot>0 and slot<=180 and api.GetActionInfo then
        local kind,id=api.GetActionInfo(slot)
        if public(api,kind) and public(api,id) then row.slot=slot row.kind=kind row.id=id end
    end
    recovery.events[#recovery.events+1]=row
    if #recovery.events>40 then table.remove(recovery.events,1) end
end
function Recovery:InstallObservers(addon,api)
    if self.observers or type(api.hooksecurefunc)~='function' then return end
    self.observers=true
    for _,name in ipairs({'PickupAction','PlaceAction'}) do
        if type(api[name])=='function' then
            api.hooksecurefunc(name,function(slot) self:Record(addon,api,name,slot) end)
        end
    end
    if api.C_ClassTalents then
        for _,name in ipairs({'LoadConfig','SwitchToLoadoutByIndex','SwitchToLoadoutByName','SetLastSelectedSavedConfigID','SetStarterBuildActive','SetUsesSharedActionBars'}) do
            if type(api.C_ClassTalents[name])=='function' then
                api.hooksecurefunc(api.C_ClassTalents,name,function() self:Record(addon,api,'C_ClassTalents.'..name) end)
            end
        end
    end
end
local function ready(api)
    for _,name in ipairs({'InCombatLockdown','HasVehicleActionBar','HasOverrideActionBar','HasTempShapeshiftActionBar','GetBonusBarOffset','GetActionBarPage','GetCursorInfo','GetSpecialization','GetSpecializationInfo','GetActionInfo','UnitClass'}) do
        if type(api[name])~='function' then return false end
    end
    if api.InCombatLockdown() or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown()) then return false end
    if api.HasVehicleActionBar() or api.HasOverrideActionBar() or api.HasTempShapeshiftActionBar()
        or api.GetBonusBarOffset()>0 or api.GetActionBarPage()~=1 then return false end
    if api.GetCursorInfo() then return false end
    return true
end
-- Historical recovery data stays available for diagnosis. Restoration was
-- removed after the user reported that edited bars were being reverted.
-- This compatibility entry point is deliberately read-only toward action slots.
function Recovery:Refresh(addon,api)
    self.pending=nil
    if addon.record then addon.record.actionRecoveryDisabled=true end
    addon.Diagnostics:SetFeature('actionRecovery','disabled','Automatic action-slot restoration removed; bar edits remain game-owned')
end
function Recovery:Observe(addon,api,snapshot)
    if self.busy or not addon:IsCharacterInstalled() or not ready(api) then return end
    local index=api.GetSpecialization()
    local spec=index and api.GetSpecializationInfo(index)
    if not spec then return end
    local slots,count={},0
    for _,bank in pairs(snapshot.banks) do
        for _,row in pairs(bank.buttons) do
            if row.kind=='action' and row.slotKind=='spell' and type(row.action)=='number' and type(row.spell)=='number'
                and public(api,row.spell) and row.action<=72 then
                if not slots[row.action] then count=count+1 end
                slots[row.action]=row.spell
            end
        end
    end
    local record=addon.record
    record.actionRecovery=record.actionRecovery or {specs={}}
    local previous=record.actionRecovery.specs[spec]
    -- Never replace a good snapshot with a wipe or an incomplete spell load.
    local recovery=record.actionRecovery
    local now=api.GetTime and api.GetTime() or 0
    local manual=recovery.manualUntil and now<=recovery.manualUntil
    if count<8 and not manual then return end
    local config=configuration(api,spec)
    recovery.lastConfig=public(api,config) and config or nil
    if previous and previous.config and config and previous.config~=config then
        recovery.loadouts=recovery.loadouts or {}
        recovery.loadouts[tostring(spec)..':'..tostring(previous.config)]=Addon.Core.Copy(previous)
        previous=recovery.loadouts[tostring(spec)..':'..tostring(config)]
        if previous then recovery.specs[spec]=Addon.Core.Copy(previous) else
            -- An unrecorded loadout is captured separately after ordinary state
            -- is ready. It must never inherit another loadout's spell layout.
            recovery.specs[spec]=nil
        end
    end
    if previous and not manual then
        local changed=0
        for slot,spell in pairs(previous.slots) do if slots[slot]~=spell then changed=changed+1 end end
        if count<previous.count or changed*2>previous.count then
            recovery.anomaly={spec=spec,config=config,changed=changed,count=count,previousCount=previous.count}
            return
        end
    end
    recovery.specs[spec]={slots=slots,count=count,config=public(api,config) and config or nil}
end
