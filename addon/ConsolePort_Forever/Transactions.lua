local _, Addon = ...
local Core, Transactions = Addon.Core, {}
Addon.Transactions = Transactions

local function Read(adapter, step)
    if not adapter or type(adapter.read) ~= "function" then return false, "adapter unavailable" end
    local ok, value = pcall(adapter.read, adapter, step.path)
    if not ok then return false, value end
    return true, Core.Encode(value)
end
local function Equal(adapter,a,b)
    if adapter and type(adapter.equal)=='function' then
        local ok,result=pcall(adapter.equal,adapter,Core.Decode(a),Core.Decode(b))
        return ok and result==true
    end
    return Core.Equal(a,b)
end
local function Write(adapter, step, value)
    local ok, result = pcall(adapter.write, adapter, step.path, Core.Decode(value))
    if not ok or result ~= true then return false, "write rejected" end
    local readOK, actual = Read(adapter, step)
    if not readOK or not Equal(adapter,actual,value) then return false, "readback mismatch" end
    return true
end

function Transactions.Prepare(db, guid, steps, context)
    if not db.characters[guid] then return nil, "unknown character" end
    repeat db.nextTransactionID = db.nextTransactionID + 1
    until not db.transactions[tostring(db.nextTransactionID)] and not db.backups[tostring(db.nextTransactionID)]
    local id = tostring(db.nextTransactionID)
    local journal = {id = id, guid = guid, status = "prepared", steps = Core.Copy(steps),
                     context = Core.Copy(context or {}), attempted = 0, verified = {}, recovery = {}}
    db.transactions[id] = journal
    -- Independent retained snapshots for every transaction, including retries.
    db.backups[id] = Core.Copy(journal)
    table.insert(db.characters[guid].transactionIDs, id)
    return journal
end

function Transactions.Recover(journal, adapters, canWrite)
    if not canWrite or not canWrite() then journal.status = "recovery-required" return false end
    journal.recovery = {}
    for index = journal.attempted, 1, -1 do
        if not canWrite() then journal.status = "recovery-required" return false end
        local step = journal.steps[index]
        local adapter = adapters[step.scope]
        local ok, actual = Read(adapter, step)
        if adapter and type(adapter.compensate)=="function" then
            local called,restored,reason=pcall(adapter.compensate,adapter,step,journal,canWrite)
            if not called or not restored then table.insert(journal.recovery,{id=step.id,reason=reason or "adapter compensation failed"}) end
        elseif ok and Equal(adapter,actual,step.before) then
            -- A rejecting writer may not have changed this field.
        elseif ok and Equal(adapter,actual,step.value) then
            local restored, reason = Write(adapter, step, step.before)
            if not restored then table.insert(journal.recovery, {id = step.id, reason = reason}) end
        else
            table.insert(journal.recovery, {id = step.id, reason = "current value changed; review required"})
        end
    end
    journal.status = #journal.recovery == 0 and "rolled-back" or "recovery-required"
    return #journal.recovery == 0
end

function Transactions.Apply(journal, adapters, canWrite)
    if journal.status ~= "prepared" then return false, "transaction is not prepared" end
    if not canWrite() then return false, "protected writes unavailable" end
    -- Validate the entire reviewed plan before the first mutation.
    for _, step in ipairs(journal.steps) do
        local adapter = adapters[step.scope]
        if not adapter then return false, "adapter unavailable: " .. step.scope end
        local ok, actual = Read(adapter, step)
        if not ok or not Equal(adapter,actual,step.before) then
            journal.status = "stale"
            return false, "reviewed plan changed: " .. step.id
        end
    end
    journal.status = "applying"
    for _, adapter in pairs(adapters) do if adapter.Attach then adapter:Attach(journal) end end
    for index, step in ipairs(journal.steps) do
        if not canWrite() then
            journal.error = "protected writes became unavailable"
            journal.status = "recovery-required"
            return false, journal.error
        end
        journal.attempted = index -- Persist intent before even a throwing writer.
        local ok, reason = Write(adapters[step.scope], step, step.value)
        if not ok then
            journal.error = reason
            Transactions.Recover(journal, adapters, canWrite)
            return false, reason
        end
        journal.verified[index] = true
    end
    for _, step in ipairs(journal.steps) do
        local ok, actual = Read(adapters[step.scope], step)
        if not ok or not Equal(adapters[step.scope],actual,step.value) then
            journal.error = "final scope verification failed"
            Transactions.Recover(journal, adapters, canWrite)
            return false, journal.error
        end
    end
    journal.status = "verified"
    return true
end

function Transactions.Commit(db, journal, revision)
    if journal.status ~= "verified" then return false, "transaction not verified" end
    for _, step in ipairs(journal.steps) do
        db.managedFields[step.id] = {value = Core.Copy(step.value), revision = step.revision}
    end
    db.characters[journal.guid].appliedRevision = revision
    journal.status = "committed"
    return true
end

function Transactions.RestorePlan(journal, adapters)
    local steps, conflicts = {}, {}
    for index = #journal.steps, 1, -1 do
        local applied = journal.steps[index]
        local ok, actual = Read(adapters[applied.scope], applied)
        if ok and Equal(adapters[applied.scope],actual,applied.before) then
            -- Already restored.
        elseif ok and Equal(adapters[applied.scope],actual,applied.value) then
            steps[#steps + 1] = {id=applied.id, scope=applied.scope, path=Core.Copy(applied.path),
                                before=actual, value=Core.Copy(applied.before), revision=applied.revision}
        else
            conflicts[#conflicts + 1] = {id=applied.id, reason="newer edit or unavailable scope", current=actual}
        end
    end
    return steps, conflicts
end
