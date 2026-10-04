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
    -- The user's Apply also authorizes temporary bank selection for scoped
    -- verification/recovery. Initial inactive-bank capture needs its own consent.
    if plan.bindingInspection then
        for _,set in ipairs(plan.bindingInspection.sets) do self.adapters.bindingBanks:Permit(set,plan.bindingInspection.backup) end
    end
    local journal=Addon.Transactions.Prepare(self.db,self.guid,steps,{revision=plan.revision,restores=plan.restores,viewRecovery=plan.viewRecovery,viewRecoveryBackup=plan.viewRecoveryBackup,bindingInspection=Core.Copy(plan.bindingInspection),resolutions=Core.Copy(resolutions or {})})
    self.lastJournal=journal
    local applied,error=Addon.Transactions.Apply(journal,self.adapters,self.canWrite)
    if not applied then return false,error end
    if plan.restores then
        journal.status="restored"
        self.record.appliedRevision=0
        self.record.pendingChanges=Core.Copy(plan.deferred)
        for _,step in ipairs(steps) do self.db.managedFields[step.ownerID or step.id]=nil end
        self.plan,self.queued=nil,nil
        return true,journal
    end
    if not Addon.Transactions.Commit(self.db,journal,plan.revision) then return false,"transaction commit rejected" end
    if plan.viewRecovery then
        local original=self.db.transactions[plan.viewRecoveryBackup]
        if original and original.guid==self.guid and original.status=="recovery-required" and original.bindingDetails then
            original.bindingOriginalViewReviewed=Core.Copy(self.adapters.bindingBanks.native:Capture().saved)
        end
        self.record.bindingViewRecovery=nil
        for _,step in ipairs(steps) do self.db.managedFields[step.id]=nil end
        self.plan,self.queued=nil,nil
        return true,journal
    end
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
    local bindingInspection
    for i=#original.steps,1,-1 do
        local step=original.steps[i]
        if step.scope=="bindings" and step.path[1]=="state" then
            local detail=original.bindingDetails
            if not detail then return nil,"binding backup has no target-bank subjournal; preserve current banks" end
            local adapter=self.adapters.bindingBanks
            if not adapter then return nil,"native binding bank restore adapter unavailable" end
            if adapter:NeedsInspection(detail.targetSet) or adapter:NeedsInspection(detail.originalSet) then return nil,"inactive binding bank inspection requires consent" end
            bindingInspection={sets={detail.targetSet},backup=id}
            if detail.originalSet~=detail.targetSet then bindingInspection.sets[#bindingInspection.sets+1]=detail.originalSet end
            for _,write in ipairs(detail.writes) do
                local fieldID=step.id.."/restore/"..detail.targetSet.."/"..write.key
                fields[#fields+1]={id=fieldID,ownerID=step.id,scope="bindingBanks",path={"key",detail.targetSet,write.key},value=Core.Encode(write.before),revision=step.revision,label="Restore native bank "..detail.targetSet.." key "..write.key}
                baselines[fieldID]={value=Core.Encode(write.value)}
            end
            if detail.originalSet~=detail.targetSet then
                -- The original bank was never written by installation. Its
                -- newer keys are conflicts, including a transient pre-install
                -- key that LoadBindings could have discarded. Uncaptured and
                -- newly added keys are left alone.
                local originalKeys=detail.originalBank and detail.originalBank.saved
                if not originalKeys then
                    originalKeys=Core.Copy(detail.original.keyboard)
                    for key,value in pairs(detail.original.keys) do originalKeys[key]=value end
                end
                local keys={} for key in pairs(originalKeys) do keys[#keys+1]=key end table.sort(keys)
                for _,key in ipairs(keys) do
                    local fieldID=step.id.."/original/"..detail.originalSet.."/"..key
                    local value=Core.Encode(originalKeys[key])
                    fields[#fields+1]={id=fieldID,ownerID=step.id,scope="bindingBanks",path={"key",detail.originalSet,key},value=value,revision=step.revision,label="Original native bank "..detail.originalSet.." key "..key}
                    baselines[fieldID]={value=Core.Copy(value)}
                end
            end
            local fieldID=step.id.."/restore/selection"
            fields[#fields+1]={id=fieldID,ownerID=step.id,scope="bindingBanks",path={"selection"},value=Core.Encode(detail.originalSet),revision=step.revision,label="Return to the originally selected native binding bank"}
            baselines[fieldID]={value=Core.Encode(detail.targetSet)}
        else
            fields[#fields+1]={id=step.id,scope=step.scope,path=Core.Copy(step.path),value=Core.Copy(step.before),revision=step.revision,label="Restore "..(step.label or step.id)}
            baselines[step.id]={value=Core.Copy(step.value)}
        end
    end
    local current,errors=Addon.Baseline.Capture(self.adapters,fields)
    if bindingInspection then
        for _,error in ipairs(errors) do
            for _,field in ipairs(fields) do
                if field.id==error.id and field.scope=="bindingBanks" then return nil,"binding bank review is incomplete: "..tostring(error.reason) end
            end
        end
    end
    -- Restoration always exposes a newer edit as a conflict, even when it
    -- would count as a preserved edit during an ordinary default update.
    local plan={operations={},conflicts={},noops={},deferred=errors,fields={},current=current,guid=self.guid,revision=0,restores=id,bindingInspection=bindingInspection}
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
function Coordinator:BuildBindingViewRecovery()
    local intent=self.record.bindingViewRecovery
    local adapter=self.adapters.bindingBanks
    if not intent or not adapter then return nil,"no retained transient binding view" end
    if type(intent.beforeView)~="table" then return nil,"retained transient view is malformed" end
    if not adapter:ValidSet(intent.beforeSet) or type(intent.backup)~="string" then return nil,"retained transient view identity is malformed" end
    if adapter.native.api.GetCurrentBindingSet()~=intent.beforeSet then return nil,"select the retained view's native bank before review" end
    local snapshot,reason=adapter.native:Capture()
    if not snapshot then return nil,reason end
    local keys,fields={},{}
    for key in pairs(snapshot.saved) do keys[key]=true end
    for key in pairs(intent.beforeView) do keys[key]=true end
    local ordered={} for key in pairs(keys) do ordered[#ordered+1]=key end table.sort(ordered)
    for _,key in ipairs(ordered) do
        fields[#fields+1]={id=self.guid.."/transient-view/"..key,scope="bindingBanks",path={"key",intent.beforeSet,key},value=Core.Encode(intent.beforeView[key] or ""),revision=self.record.appliedRevision,label="Retained pre-interruption key "..key}
    end
    local plan=self:Build(fields,self.record.appliedRevision)
    if #plan.deferred>0 then return nil,"transient binding view capture is incomplete" end
    -- No managed/default baseline is used for transient recovery. Every
    -- difference is a new ownership conflict for the user to accept or keep.
    plan=Addon.Plan.Build(plan.current,{},fields,{})
    plan.fields,plan.current=fields,self.plan.current
    plan.guid,plan.revision,plan.viewRecovery=self.guid,self.record.appliedRevision,true
    plan.viewRecoveryBackup=intent.backup
    plan.bindingInspection={sets={intent.beforeSet},backup=intent.backup}
    self.plan=plan
    return plan
end
function Coordinator:Restore(id,resolutions)
    local plan,reason=self:BuildRestore(id)
    if not plan then return false,reason end
    return self:Accept(resolutions)
end
