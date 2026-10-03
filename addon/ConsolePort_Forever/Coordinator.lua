local _, Addon = ...
local Core, Coordinator = Addon.Core, {}
Addon.Coordinator = Coordinator
function Coordinator.New(db,guid,adapters,canWrite)
    local record,reason=Addon.Store.GetCharacter(db,guid)
    if not record then return nil,reason end
    return setmetatable({db=db,guid=guid,record=record,adapters=adapters,canWrite=canWrite},{__index=Coordinator})
end
function Coordinator:Build(fields,revision)
    local current,errors=Addon.Baseline.Capture(self.adapters,fields)
    local available={}
    local missing={}
    for _,error in ipairs(errors) do missing[error.id]=true end
    for _,field in ipairs(fields) do if not missing[field.id] then available[#available+1]=field end end
    local plan=Addon.Plan.Build(current,self.db.managedFields,available,self.db.reviews)
    for _,error in ipairs(errors) do plan.deferred[#plan.deferred+1]=error end
    plan.guid,plan.revision,plan.fields,plan.current=self.guid,revision,Core.Copy(available),current
    self.plan=plan
    return plan
end
function Coordinator:Accept(resolutions)
    local plan=self.plan
    if not plan or plan.guid~=self.guid then return false,"no current reviewed plan" end
    local steps,reason=Addon.Plan.Accept(plan,resolutions)
    if not steps then return false,reason end
    if not self.canWrite() then
        self.queued={plan=plan,resolutions=Core.Copy(resolutions or {})}
        return false,"accepted plan queued until protected writes are available"
    end
    -- Noops/kept fields are part of the reviewed view too. A change in any
    -- reviewed field invalidates the entire plan before the first write.
    for _,field in ipairs(plan.fields) do
        local expected=Core.Read(plan.current[field.scope],field.path)
        local ok,value=pcall(self.adapters[field.scope].read,self.adapters[field.scope],field.path)
        if not ok or not Core.Equal(Core.Encode(value),expected) then self.plan=nil return false,"reviewed field changed: "..field.id end
    end
    local journal=Addon.Transactions.Prepare(self.db,self.guid,steps,{revision=plan.revision,restores=plan.restores,resolutions=Core.Copy(resolutions or {})})
    self.lastJournal=journal
    local applied,error=Addon.Transactions.Apply(journal,self.adapters,self.canWrite)
    if not applied then return false,error end
    if plan.restores then
        journal.status="restored"
        self.record.appliedRevision=0
        self.record.pendingChanges=Core.Copy(plan.deferred)
        for _,step in ipairs(steps) do self.db.managedFields[step.id]=nil end
        self.plan,self.queued=nil,nil
        return true,journal
    end
    if not Addon.Transactions.Commit(self.db,journal,plan.revision) then return false,"transaction commit rejected" end
    for _,field in ipairs(plan.fields) do
        if resolutions and resolutions[field.id]=="keep" then
            self.db.reviews[field.id]={decision="keep",revision=field.revision,proposed=Core.Copy(field.value),current=Core.Read(plan.current[field.scope],field.path)}
        else
            -- Establish an accepted baseline for converged/default fields; a
            -- preserved manual edit retains its previous default baseline.
            for _,entry in ipairs(plan.noops) do
                if entry.id==field.id and entry.reason=="converged" then self.db.managedFields[field.id]={value=Core.Copy(field.value),revision=field.revision} end
            end
        end
    end
    self.record.pendingChanges=Core.Copy(plan.deferred)
    self.plan,self.queued=nil,nil
    return true,journal
end
function Coordinator:Resume()
    if not self.queued then return false,"no queued plan" end
    self.plan=self.queued.plan
    return self:Accept(self.queued.resolutions)
end
function Coordinator:BuildRestore(id)
    local original=self.db.transactions[id]
    if not original or original.guid~=self.guid or original.status~="committed" then return nil,"backup does not belong to this installed character" end
    local fields,baselines={},{}
    for i=#original.steps,1,-1 do
        local step=original.steps[i]
        fields[#fields+1]={id=step.id,scope=step.scope,path=Core.Copy(step.path),value=Core.Copy(step.before),revision=step.revision,label="Restore "..(step.label or step.id)}
        baselines[step.id]={value=Core.Copy(step.value)}
    end
    local current,errors=Addon.Baseline.Capture(self.adapters,fields)
    -- Restoration always exposes a newer edit as a conflict, even when it
    -- would count as a preserved edit during an ordinary default update.
    local plan={operations={},conflicts={},noops={},deferred=errors,fields={},current=current,guid=self.guid,revision=0,restores=id}
    local missing={}
    for _,entry in ipairs(errors) do missing[entry.id]=true end
    for _,field in ipairs(fields) do
        if not missing[field.id] then
            plan.fields[#plan.fields+1]=field
            local entry=Core.Copy(field)
            entry.before=Core.Read(current[field.scope],field.path)
            if Core.Equal(entry.before,entry.value) then plan.noops[#plan.noops+1]=entry
            elseif Core.Equal(entry.before,baselines[field.id].value) then plan.operations[#plan.operations+1]=entry
            else entry.reason="newer edit" plan.conflicts[#plan.conflicts+1]=entry end
        end
    end
    self.plan=plan
    return plan
end
function Coordinator:Restore(id,resolutions)
    local plan,reason=self:BuildRestore(id)
    if not plan then return false,reason end
    return self:Accept(resolutions)
end
