local _,Addon=...
local Class={CHORD='CTRL-PADRSHOULDER',LEFT_CHORD='SHIFT-PADLSHOULDER',LEGACY='CTRL-PADFORWARD',SET='CPFClass'}
Addon.ClassActions=Class
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
    if rings.Data and type(rings.Data.Auras)=='table' and not (rings.Shared and rings.Shared.Auras) then return 'Auras' end
    return Class.SET
end
function Class.Bindings(state,adapter)
    if not adapter or not adapter:Probe() then return state end
    local id=adapter.api.classSet
    if not id then return state end
    local command=adapter.rings:GetBindingForSet(id)
    if type(command)~='string' then return state end
    state.keys[adapter.api.classChord or Class.CHORD]=command
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
    state.sets[id]=adapter.env:ValidateSet(id,set)
    return state
end
function Class.Migrate(addon,api,canWrite)
    local record=addon.record
    if not record or record.appliedRevision~=14 or not record.bindingAccepted or not record.ringAccepted then return false end
    if addon.busy or (addon.Prompt and addon.Prompt.active) or not canWrite() then return false end
    local adapters=addon.adapters
    local rings=adapters and adapters.rings
    if not rings or not rings:Probe() or rings.rings:IsShown() or addon.db.shared.ringProjectionGUID~=addon.guid then return false end
    local current=adapters.bindings:read({'state'})
    if current.set~=adapters.bindings.native.api.CharacterSet then return false end
    local desired=Class.Bindings(addon.Core.Copy(current),rings)
    local ringBefore=rings:read({'state'})
    local ringAfter=Class.RingProposal(addon.Core.Copy(ringBefore),rings,api)
    if not ringAfter.sets[rings.api.classSet] then return false end
    local steps={}
    for _,entry in ipairs({{'controller','bindings',current,desired},{'rings','rings',ringBefore,ringAfter}}) do
        if not addon.Core.Equal(entry[3],entry[4]) then
            steps[#steps+1]={id=addon.guid..'/'..entry[1],scope=entry[2],path={'state'},before=entry[3],value=entry[4],revision=15}
        end
    end
    -- Explicitly authorized first-login migration, scoped to the class chord
    -- and its native ring. Existing transaction machinery owns backup/rollback.
    local journal=addon.Transactions.Prepare(addon.db,addon.guid,steps,{revision=15,foreverClassMigration=true})
    addon.busy=true
    local ok,result,reason=pcall(addon.Transactions.Apply,journal,adapters,canWrite)
    addon.busy=false
    if not ok or not result then
        addon.Diagnostics:SetFeature('classFlyout','recovery-required',tostring(reason or result)) return false
    end
    assert(addon.Transactions.Commit(addon.db,journal,15))
    addon:CaptureControllerEdits()
    rings:CaptureEdits()
    record.lastInstallTransaction=journal.id
    record.pendingReload=journal.id
    addon.reloadAppliedInSession=journal.id
    addon.Diagnostics:SetFeature('classFlyout','offline-verified','First-login class shoulder+trigger binding and ring contents saved; backup '..journal.id..'; Retail hardware acceptance pending')
    return true
end
