local _, Addon = ...
local Core, State = Addon.Core, {}
Addon.BindingStateAdapter = State
function State.New(native, mask,record)
    return setmetatable({native=native,mask=mask,record=record},{__index=State})
end
function State:Attach(journal) self.journal=journal end
function State:read(path)
    assert(path[1]=="state")
    local snapshot,reason=self.native:Capture()
    if not snapshot then error(reason) end
    local keys={}
    for key in pairs(self.mask) do keys[key]=self.native:read({key}) end
    return {set=snapshot.set,keys=keys,keyboard=Core.Copy(snapshot.keyboard)}
end
local function sortedKeys(source)
    local keys={}
    for key in pairs(source) do keys[#keys+1]=key end
    table.sort(keys)
    return keys
end
function State:Select(set)
    if self.native.api.InCombatLockdown() or (self.canWrite and not self.canWrite()) then return false end
    if set~=self.native.api.AccountSet and set~=self.native.api.CharacterSet then return false end
    self.native.api.LoadBindings(set)
    return self.native.api.GetCurrentBindingSet()==set
end
function State:Save(set)
    if self.native.api.InCombatLockdown() or (self.canWrite and not self.canWrite()) or self.native.api.GetCurrentBindingSet()~=set then return false end
    return self.native.api.SaveBindings(set)==true
end
function State:write(path,value)
    if not self.journal or self.native.api.InCombatLockdown() or (self.canWrite and not self.canWrite()) then return false end
    local before=self:read(path)
    local detail={originalSet=before.set,targetSet=value.set,writes={},saved=false,original=Core.Copy(before),originalBank=Core.Copy(self.native:Capture())}
    self.journal.bindingDetails=detail -- intent is retained before selecting.
    if before.set~=value.set and not self:Select(value.set) then return false end
    local target=self.native:Capture()
    if not target then return false end
    detail.targetBefore=Core.Copy(target)
    local writes={}
    for key in pairs(target.keyboard) do if value.keyboard[key]==nil then writes[key]="" end end
    for key,command in pairs(value.keyboard) do writes[key]=command end
    for key,command in pairs(value.keys) do
        if not self.mask[key] then return false end
        writes[key]=command
    end
    for _,key in ipairs(sortedKeys(writes)) do
        if self.native.api.InCombatLockdown() or (self.canWrite and not self.canWrite()) then return false end
        local old=self.native:read({key})
        if old~=writes[key] then
            detail.writes[#detail.writes+1]={key=key,before=old,value=writes[key]}
            if not self.native:write({key},writes[key]) then return false end
        end
    end
    if not Core.Equal(self:read(path),value) then return false end
    detail.saveAttempted=true
    if not self:Save(value.set) then return false end
    detail.saved=true
    return true
end
function State:compensate(step,journal,canWrite)
    local detail=journal.bindingDetails
    if not detail then return false,"binding journal unavailable" end
    if not canWrite() then return false,"binding recovery cannot select target" end
    local record=self.record or journal
    local inspector=self.bankInspector or Addon.BindingBanksAdapter.New(self.native,record,canWrite)
    inspector:Permit(detail.targetSet,journal.id)
    local failures={}
    local function restoreTarget()
        for index=#detail.writes,1,-1 do
            if not canWrite() then error("combat interrupted binding recovery") end
            local entry=detail.writes[index]
            local current=self.native:read({entry.key})
            if current==entry.before then
            elseif current==entry.value then
                local ok,restored=pcall(self.native.write,self.native,{entry.key},entry.before)
                if not ok or not restored then failures[#failures+1]=entry.key end
            else failures[#failures+1]=entry.key.." changed after application" end
        end
        if record.pendingBindingSelection then record.pendingBindingSelection.savedTarget=true end
        if not canWrite() or not self:Save(detail.targetSet) then failures[#failures+1]="target binding save rejected" end
    end
    local called,reason=pcall(inspector.InBank,inspector,detail.targetSet,restoreTarget)
    if not called then failures[#failures+1]=tostring(reason) end
    -- Save the selected original bank from its unchanged stored view before
    -- proposing any discarded transient keys. Never overwrite unknown source
    -- edits to make rollback look complete.
    if self.native.api.GetCurrentBindingSet()~=detail.originalSet then
        if not canWrite() or not self:Select(detail.originalSet) then failures[#failures+1]="original binding set selection rejected"
        elseif not self:Save(detail.originalSet) then failures[#failures+1]="original binding selection save rejected" end
    end
    if self.native.api.GetCurrentBindingSet()==detail.originalSet and detail.originalSet~=detail.targetSet then
        local current=self.native:Capture()
        local expected=journal.bindingOriginalViewReviewed or (detail.originalBank and detail.originalBank.saved)
        if current and not expected then
            expected=Core.Copy(current.saved)
            for key,value in pairs(detail.original.keyboard) do expected[key]=value end
            for key,value in pairs(detail.original.keys) do expected[key]=value end
        end
        if not current then failures[#failures+1]="original binding view unavailable"
        elseif not Core.Equal(current.saved,expected) then
            record.bindingViewRecovery={beforeSet=detail.originalSet,targetSet=detail.targetSet,beforeView=Core.Copy(expected),backup=journal.id,phase="original-view-review"}
            failures[#failures+1]="original transient view requires explicit review; /cpf recover-view"
        end
    end
    journal.bindingRecovery=failures
    return #failures==0,#failures==0 and nil or table.concat(failures,", ")
end
