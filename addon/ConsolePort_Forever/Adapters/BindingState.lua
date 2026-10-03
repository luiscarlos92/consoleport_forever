local _, Addon = ...
local Core, State = Addon.Core, {}
Addon.BindingStateAdapter = State
function State.New(native, mask)
    return setmetatable({native=native,mask=mask},{__index=State})
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
    if self.native.api.InCombatLockdown() then return false end
    if set~=self.native.api.AccountSet and set~=self.native.api.CharacterSet then return false end
    self.native.api.LoadBindings(set)
    return self.native.api.GetCurrentBindingSet()==set
end
function State:Save(set)
    if self.native.api.InCombatLockdown() or self.native.api.GetCurrentBindingSet()~=set then return false end
    return self.native.api.SaveBindings(set)==true
end
function State:write(path,value)
    if not self.journal or self.native.api.InCombatLockdown() then return false end
    local before=self:read(path)
    local detail={originalSet=before.set,targetSet=value.set,writes={},saved=false,original=Core.Copy(before)}
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
        if self.native.api.InCombatLockdown() then return false end
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
    if not canWrite() or not self:Select(detail.targetSet) then return false,"binding recovery cannot select target" end
    local failures={}
    for index=#detail.writes,1,-1 do
        if not canWrite() then return false,"combat interrupted binding recovery" end
        local entry=detail.writes[index]
        local current=self.native:read({entry.key})
        if current==entry.before then
        elseif current==entry.value then
            local ok,restored=pcall(self.native.write,self.native,{entry.key},entry.before)
            if not ok or not restored then failures[#failures+1]=entry.key end
        else failures[#failures+1]=entry.key.." changed after application" end
    end
    if not self:Save(detail.targetSet) then failures[#failures+1]="target binding save rejected" end
    if not self:Select(detail.originalSet) then failures[#failures+1]="original binding set selection rejected" end
    journal.bindingRecovery=failures
    return #failures==0,#failures==0 and nil or table.concat(failures,", ")
end
