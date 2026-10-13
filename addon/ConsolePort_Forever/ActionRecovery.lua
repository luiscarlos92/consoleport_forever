local _,Addon=...
local Recovery={}
Addon.ActionRecovery=Recovery
local function public(api,value)
    return not api.issecretvalue or not api.issecretvalue(value)
end
local function query(api,fn,...)
    if type(fn)~='function' then return false end
    local ok,value=pcall(fn,...)
    if not ok or not public(api,value) then return false end
    return true,value
end
local function read(api,fn,...)
    local ok,value=query(api,fn,...)
    if ok then return value end
end
local function number(value)
    return type(value)=='number' and value==value and value>-math.huge and value<math.huge
end
local function temporary(api)
    local unknown=false
    for _,name in ipairs({'HasVehicleActionBar','HasOverrideActionBar','HasTempShapeshiftActionBar'}) do
        local ok,value=query(api,api[name])
        if ok and value==true then return true end
        if not ok or type(value)~='boolean' then unknown=true end
    end
    if not unknown then return false end
end
local function configuration(api,spec)
    local talents=api.C_ClassTalents
    if not talents then return end
    local ok,active=query(api,talents.GetActiveConfigID)
    if not ok then return end
    local starter
    if talents.GetStarterBuildActive then
        ok,starter=query(api,talents.GetStarterBuildActive)
        if not ok or type(starter)~='boolean' then return end
    end
    if starter then
        if number(active) then return 'starter:'..tostring(active) end
        return
    end
    -- Retail can keep the same active working config while switching saved
    -- loadouts. Use the saved identity before that shared working config.
    local saved
    if spec and talents.GetLastSelectedSavedConfigID then
        ok,saved=query(api,talents.GetLastSelectedSavedConfigID,spec)
        if not ok then return end
    end
    if number(saved) then return saved end
    if saved==nil and number(active) then return active end
end
function Recovery:Record(addon,api,event,slot)
    if not addon.record or not addon:IsCharacterInstalled() then return end
    local record=addon.record
    record.actionRecovery=record.actionRecovery or {specs={}}
    local recovery=record.actionRecovery
    local now=read(api,api.GetTime)
    if not number(now) then now=nil end
    local index=read(api,api.GetSpecialization)
    local spec=number(index) and read(api,api.GetSpecializationInfo,index) or nil
    if not number(spec) then spec=nil end
    local config=configuration(api,spec)
    local bonus=read(api,api.GetBonusBarOffset)
    local page=read(api,api.GetActionBarPage)
    local stack=read(api,api.debugstack,3,6,0)
    if type(stack)~='string' then stack='' end
    local manual=stack:find('ConsolePort_Config',1,true) or stack:find('SpellMenu',1,true)
    if manual and now then recovery.manualUntil=now+2 end
    recovery.events=recovery.events or {}
    local row={event=public(api,event) and type(event)=='string' and event or 'unknown',time=now,combat=read(api,api.InCombatLockdown),config=config,
        bonusOffset=number(bonus) and bonus or nil,actionPage=number(page) and page or nil,
        previousConfig=read(api,function() return recovery.lastConfig end),temporary=temporary(api),
        writer=stack:match('Interface[/\\]AddOns[/\\]([^/\\:]+)') or 'engine/unknown',stack=stack:sub(1,1200)}
    if public(api,slot) and number(slot) and slot>0 and slot<=180 and slot%1==0 and api.GetActionInfo then
        local ok,kind,id=pcall(api.GetActionInfo,slot)
        if ok and public(api,kind) and public(api,id) then row.slot=slot row.kind=kind row.id=id end
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
    local bonus,page=read(api,api.GetBonusBarOffset),read(api,api.GetActionBarPage)
    if temporary(api)~=false or not number(bonus) or bonus~=0 or page~=1 then return false end
    local ok,cursor=query(api,api.GetCursorInfo)
    if not ok or cursor~=nil then return false end
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
    local index=read(api,api.GetSpecialization)
    local spec=number(index) and read(api,api.GetSpecializationInfo,index) or nil
    if not number(spec) then return end
    local slots,count={},0
    for _,bank in pairs(snapshot.banks) do
        for _,row in pairs(bank.buttons) do
            if public(api,row.kind) and public(api,row.slotKind) and public(api,row.action) and public(api,row.spell)
                and row.kind=='action' and row.slotKind=='spell' and number(row.action) and number(row.spell)
                and row.action>0 and row.action<=72 and row.action%1==0 and row.spell>0 and row.spell%1==0 then
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
    local now=read(api,api.GetTime)
    local manual=number(now) and recovery.manualUntil and now<=recovery.manualUntil
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
