local _,Addon=...
local Class={CHORD='CTRL-PADRSHOULDER',LEFT_CHORD='SHIFT-PADLSHOULDER',LEGACY='CTRL-PADFORWARD',SET='CPFClass'}
Addon.ClassActions=Class
function Class.Supported(api)
    local class=api.UnitClass and select(2,api.UnitClass('player'))
    return class=='PALADIN' or class=='DRUID' or class=='WARRIOR'
end
function Class.FilterOwnedSets(sets,guid,class)
    for id,set in pairs(sets) do
        local meta=set[0] or {}
        local owner=meta.cpfForeverClassOwner
        if owner and (owner~=guid or (class and meta.cpfForeverClass~=class)) then
            sets[id]=nil
        elseif class and class~='PALADIN' and class~='DRUID' and class~='WARRIOR'
            and id=='Auras' and #set==0 and not next(meta) then
            -- Old starter projection synthesized this empty relic on other
            -- characters. Never delete a player's populated/named manual ring.
            sets[id]=nil
        end
    end
    return sets
end
function Class.Chord(api)
    local class=api.UnitClass and select(2,api.UnitClass('player'))
    return (class=='DRUID' or class=='PALADIN') and Class.LEFT_CHORD or Class.CHORD
end
-- The reference's RB+RT class opener uses native ConsolePort's secure ring.
-- It does not acquire a UI layer or replace any of the 32 action-bank routes.
function Class.ResolveSet(rings,api)
    if not rings or not rings.GetSetForBindingSuffix or not rings.GetName then return end
    for _,key in ipairs({Class.Chord(api),Class.LEGACY}) do
        local command=api.GetBindingAction(key)
        if type(command)=='string' then
            local name,suffix=command:match('^CLICK ([^:]+):(.+)$')
            if name==rings:GetName() then return rings:GetSetForBindingSuffix(suffix) end
        end
    end
    if Class.Supported(api) and rings.Data and type(rings.Data.Auras)=='table' and not (rings.Shared and rings.Shared.Auras) then return 'Auras' end
    return Class.SET
end
function Class.Bindings(state,adapter)
    if not adapter or not adapter:Probe() then return state end
    local id=adapter.api.classSet
    if not id then return state end
    local command=adapter.rings:GetBindingForSet(id)
    if type(command)~='string' then return state end
    local chord=adapter.api.classChord or Class.CHORD
    state.keys[chord]=command
    local other=chord==Class.LEFT_CHORD and Class.CHORD or Class.LEFT_CHORD
    local obsolete=adapter.rings:GetBindingForSet('Auras')
    if state.keys[other]==command or (id==Class.SET and state.keys[other]==obsolete) then state.keys[other]='' end
    -- Free only our replaced menu opener, preserving a player's unrelated menu binding.
    if state.keys[Class.LEGACY]==command then state.keys[Class.LEGACY]='' end
    return state
end
function Class.RingProposal(state,adapter,api)
    local id=adapter.api.classSet
    if not id or adapter.rings.Shared[id] then return state end
    local snapshot=Addon.RingDiscovery.Capture(api,Addon.guid)
    if not snapshot or not snapshot.formsReady then return state end
    local current=state.sets[id] or {[0]={name='Class abilities'}}
    local set,spells={},{}
    for key,value in pairs(current) do if type(key)~='number' or key<1 then set[key]=Addon.Core.Copy(value) end end
    for _,entry in ipairs(current) do
        set[#set+1]=Addon.Core.Copy(entry)
        if entry.type=='spell' then spells[entry.spell]=true end
    end
    for _,form in ipairs(snapshot.forms) do
        if not spells[form.spell] then
            set[#set+1]={type='spell',spell=form.spell,cpfForeverClass=true}
            spells[form.spell]=true
        end
    end
    if id==Class.SET then
        set[0]=set[0] or {name='Class abilities'}
        if not state.sets[id] and api.UnitClass and select(2,api.UnitClass('player'))=='PALADIN' then set[0].name='Auras (Forever)' end
        set[0].cpfForeverClassOwner=Addon.guid
        set[0].cpfForeverClass=api.UnitClass and select(2,api.UnitClass('player'))
    end
    state.sets[id]=adapter.env:ValidateSet(id,set)
    return state
end
function Class.UpdateNativeBar(addon,api,editing)
    if api.InCombatLockdown() then return false,'class bar update waits for combat to end' end
    local bar=api.StanceBar
    local native=api.StanceBarMixin
    if not bar or not native or bar.ShouldShow~=native.ShouldShow then return false,'native stance bar identity unavailable' end
    local record=addon.record
    local adapter=addon.adapters and addon.adapters.rings
    local wanted=not editing and addon:IsCharacterInstalled() and record and record.ringAccepted
        and adapter and adapter:Probe()
    local class=api.UnitClass and select(2,api.UnitClass('player'))
    wanted=wanted and (class=='PALADIN' or class=='DRUID' or class=='WARRIOR')
    local set=wanted and adapter.rings.Data[adapter.api.classSet]
    local command=wanted and adapter.rings:GetBindingForSet(adapter.api.classSet)
    wanted=wanted and set and api.GetBindingAction(adapter.api.classChord or Class.Chord(api))==command
    local forms=wanted and api.GetNumShapeshiftForms()
    wanted=wanted and forms and forms>0
    for slot=1,wanted and forms or 0 do
        local _,_,_,spell=api.GetShapeshiftFormInfo(slot)
        local present=false
        if not (api.issecretvalue and api.issecretvalue(spell)) then
            for _,entry in ipairs(set) do if entry.type=='spell' and entry.spell==spell then present=true break end end
        end
        if not present then wanted=false break end
    end
    local row=Class.nativeBar
    if row and row.frame~=bar then
        if row.frame:GetParent()==Class.hiddenBar then row.frame:SetParent(row.parent) end
        Class.nativeBar=nil row=nil
    end
    if not wanted then
        if row and bar:GetParent()==Class.hiddenBar then bar:SetParent(row.parent) end
        return false,editing and 'native class bar restored for Edit Mode' or 'native class bar retained until complete ring access is ready'
    end
    if not row then
        if bar:GetParent()~=api.UIParent then return false,'foreign class bar parent retained' end
        row={frame=bar,parent=bar:GetParent()} Class.nativeBar=row
    end
    if bar:GetParent()~=row.parent and bar:GetParent()~=Class.hiddenBar then return false,'foreign class bar parent retained' end
    if not Class.hiddenBar then
        Class.hiddenBar=api.CreateFrame('Frame',nil,api.UIParent,'SecureHandlerBaseTemplate')
        Class.hiddenBar:Hide()
    end
    bar:SetParent(Class.hiddenBar)
    return true,'native aura/form row hidden; every learned form is available through the installed secure class ring'
end
function Class.Migrate(addon,api,canWrite)
    local record=addon.record
    if not record or not record.bindingAccepted or not record.ringAccepted then return false end
    local legacy=record.appliedRevision==14 or record.appliedRevision==15 or record.appliedRevision==16
    local repair=record.appliedRevision==17 and record.classAccessRepair~=1 and Class.Supported(api)
    if not legacy and not repair then return false end
    if addon.busy or (addon.Prompt and addon.Prompt.active) or not canWrite() then return false end
    local adapters=addon.adapters
    local rings=adapters and adapters.rings
    if not rings or not rings:Probe() or rings.rings:IsShown() or addon.db.shared.ringProjectionGUID~=addon.guid then return false end
    if repair then
        local snapshot=Addon.RingDiscovery.Capture(api,addon.guid)
        if not snapshot or not snapshot.formsReady or #snapshot.forms==0 then return false end
    end
    local current=adapters.bindings:read({'state'})
    if current.set~=adapters.bindings.native.api.CharacterSet then return false end
    local desired=Class.Bindings(addon.Core.Copy(current),rings)
    local ringBefore=rings:read({'state'})
    local ringAfter=Class.RingProposal(addon.Core.Copy(ringBefore),rings,api)
    if not ringAfter.sets[rings.api.classSet] then return false end
    local steps={}
    for _,entry in ipairs({{'controller','bindings',current,desired},{'rings','rings',ringBefore,ringAfter}}) do
        if not addon.Core.Equal(entry[3],entry[4]) then
            steps[#steps+1]={id=addon.guid..'/'..entry[1],scope=entry[2],path={'state'},before=entry[3],value=entry[4],revision=17}
        end
    end
    if repair and #steps==0 then record.classAccessRepair=1 return false end
    -- Explicitly authorized first-login migration, scoped to the class chord
    -- and its native ring. Existing transaction machinery owns backup/rollback.
    local journal=addon.Transactions.Prepare(addon.db,addon.guid,steps,{revision=17,foreverClassMigration=true,classAccessRepair=repair and true or nil})
    addon.busy=true
    local ok,result,reason=pcall(addon.Transactions.Apply,journal,adapters,canWrite)
    addon.busy=false
    if not ok or not result then
        addon.Diagnostics:SetFeature('classFlyout','recovery-required',tostring(reason or result)) return false
    end
    assert(addon.Transactions.Commit(addon.db,journal,17))
    record.classAccessRepair=1
    addon:CaptureControllerEdits()
    rings:CaptureEdits()
    record.lastInstallTransaction=journal.id
    record.pendingReload=journal.id
    addon.reloadAppliedInSession=journal.id
    addon.Diagnostics:SetFeature('classFlyout','offline-verified','First-login class shoulder+trigger binding and ring contents saved; backup '..journal.id..'; Retail hardware acceptance pending')
    return true
end
