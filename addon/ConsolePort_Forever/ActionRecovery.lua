local _,Addon=...
local Recovery={}
Addon.ActionRecovery=Recovery
-- Spell/slot evidence retained by Forever's October 10 deployment backup.
-- No Copybara data, macros, item actions or other character's bindings.
local emergency={PALADIN={[70]={
    [1]=383328,[2]=53385,[3]=184575,[4]=20271,[6]=255937,[8]=375576,
    [10]=853,[12]=96231,[49]=1044,[50]=1022,[51]=6940,[52]=115750,
    [53]=7328,[55]=391054,[56]=62124,[61]=190784,[62]=19750,
    [63]=85673,[64]=403876,[66]=633,[68]=642,
}}}
local function public(api,value)
    return not api.issecretvalue or not api.issecretvalue(value)
end
local function ready(api)
    for _,name in ipairs({'InCombatLockdown','HasVehicleActionBar','HasOverrideActionBar','HasTempShapeshiftActionBar','GetBonusBarOffset','GetActionBarPage','GetCursorInfo','GetSpecialization','GetSpecializationInfo','GetActionInfo','UnitClass','ClearCursor'}) do
        if type(api[name])~='function' then return false end
    end
    if api.InCombatLockdown() or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown()) then return false end
    if api.HasVehicleActionBar() or api.HasOverrideActionBar() or api.HasTempShapeshiftActionBar()
        or api.GetBonusBarOffset()>0 or api.GetActionBarPage()~=1 then return false end
    if api.GetCursorInfo() then return false end
    return api.C_Spell and api.C_Spell.PickupSpell and api.IsPlayerSpell and api.PlaceAction
end
function Recovery:Refresh(addon,api)
    if self.busy or not addon:IsCharacterInstalled() or not ready(api) then return end
    local index=api.GetSpecialization()
    local spec=index and api.GetSpecializationInfo(index)
    if not spec then return end
    local _,class=api.UnitClass('player')
    local record=addon.record
    if record.actionRecoveryDisabled then return end
    record.actionRecovery=record.actionRecovery or {specs={}}
    local recovery=record.actionRecovery
    local saved=recovery.specs[spec]
    local seed=emergency[class] and emergency[class][spec]
    local baseline=saved and saved.slots or seed
    if not baseline then return end
    local current,known,missing={},0,0
    for slot,spell in pairs(baseline) do
        local kind,id,subtype=api.GetActionInfo(slot)
        if not public(api,kind) or not public(api,id) then return end
        current[slot]={kind=kind,id=id,subtype=subtype}
        if api.IsPlayerSpell(spell) then
            known=known+1
            if kind==nil then missing=missing+1 end
        end
    end
    -- Partial talent changes and ordinary player edits never trigger rescue.
    -- A missing majority of a previously populated layout is the emergency.
    if known<8 or missing*2<=known then self.pending=nil return end
    -- Require the same loss after the quest/login transition has settled.
    if api.GetTime and api.C_Timer and api.C_Timer.After then
        local now=api.GetTime()
        if not self.pending or self.pending.record~=record or self.pending.spec~=spec then
            self.pending={record=record,spec=spec,after=now+2}
            api.C_Timer.After(2,function()
                if addon.record==record then
                    local ok,error=pcall(addon.Refresh,addon)
                    if not ok then addon.Diagnostics:Log('action-recovery',tostring(error)) end
                end
            end)
            return
        end
        if now<self.pending.after then return end
    end
    local before=Addon.Core.Copy(current)
    recovery.lastAttempt={spec=spec,before=before,source=saved and 'GUID/spec snapshot' or 'Forever deployment backup',status='restoring',restored=0}
    self.busy=true
    local ok,error=pcall(function()
        -- Preflight before any pickup. Native cursor ownership belongs to the
        -- player; abort without consuming an existing cursor item/spell.
        for slot,spell in pairs(baseline) do
            if not ready(api) then error('action recovery deferred') end
            local original=current[slot]
            -- Preserve macros/items/flyouts; restore the recorded spell slots.
            local compatible=original.kind==nil or original.kind=='spell'
            if compatible and original.id~=spell and api.IsPlayerSpell(spell) then
                api.C_Spell.PickupSpell(spell)
                local kind,id=api.GetCursorInfo()
                if kind~='spell' or not public(api,id) then api.ClearCursor() error('spell pickup rejected') end
                api.PlaceAction(slot)
                api.ClearCursor()
                local placed,actual=api.GetActionInfo(slot)
                if placed~='spell' or actual~=spell then error('action restoration readback failed') end
                recovery.lastAttempt.restored=recovery.lastAttempt.restored+1
            end
        end
    end)
    self.busy=false
    recovery.lastAttempt.status=ok and 'restored' or 'pending'
    recovery.lastAttempt.error=not ok and tostring(error) or nil
    if ok then self.pending=nil end
    addon.Diagnostics:SetFeature('actionRecovery',ok and 'restored' or 'pending',ok and ('Restored '..recovery.lastAttempt.restored..' spell slots from retained layout; gameplay verification pending') or tostring(error))
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
    if count<8 then return end
    local record=addon.record
    record.actionRecovery=record.actionRecovery or {specs={}}
    local previous=record.actionRecovery.specs[spec]
    -- Never replace a good snapshot with a wipe or an incomplete spell load.
    if previous and count<previous.count then return end
    record.actionRecovery.specs[spec]={slots=slots,count=count}
end
