local _, Addon = ...
local Core, Banks = Addon.Core, {}
Addon.BindingBanksAdapter = Banks

function Banks.New(native,record,canWrite,busy)
    return setmetatable({native=native,record=record,canWrite=canWrite,busy=busy,permits={}},{__index=Banks})
end
function Banks:ValidSet(set)
    return set==self.native.api.AccountSet or set==self.native.api.CharacterSet
end
function Banks:Permit(set,id)
    assert(self:ValidSet(set) and type(id)=="string")
    self.permits[set]=id
end
function Banks:Attach(journal)
    self.journal=journal
    local consent=journal.context and journal.context.bindingInspection
    if consent then
        for _,set in ipairs(consent.sets or {consent.set}) do self:Permit(set,consent.backup) end
    end
end
function Banks:NeedsInspection(set)
    return self.native.api.GetCurrentBindingSet()~=set and not self.permits[set]
end
function Banks:Select(set)
    if not self.canWrite() or not self:ValidSet(set) then return false end
    self.native.api.LoadBindings(set)
    return self.native.api.GetCurrentBindingSet()==set
end
function Banks:ReturnView(intent)
    local snapshot=assert(self.native:Capture())
    intent.returnedView=intent.returnedView or Core.Copy(snapshot.saved)
    local keys={}
    for key in pairs(snapshot.saved) do keys[key]=true end
    for key in pairs(intent.beforeView) do keys[key]=true end
    local failures={}
    for key in pairs(keys) do
        if not self.canWrite() then return false end
        local current=self.native:read({key})
        local desired=intent.beforeView[key] or ""
        local returned=intent.returnedView[key] or ""
        if current~=desired then
            if current~=returned then failures[#failures+1]=key.." has a newer edit"
            else
                intent.viewWrites=intent.viewWrites or {}
                intent.viewWrites[key]={before=returned,value=desired}
                local ok,result=pcall(self.native.write,self.native,{key},desired)
                if not ok or not result then failures[#failures+1]=key.." could not return to its previous view" end
            end
        end
    end
    if #failures>0 then intent.failures=failures return false end
    -- LoadBindings can discard unsaved native keys. Restore the exact outgoing
    -- view in memory, and save only after an accepted bank write saved a target.
    if intent.savedTarget and (not self.canWrite() or self.native.api.SaveBindings(intent.beforeSet)~=true) then return false end
    return true
end
function Banks:InBank(set,callback)
    assert(self:ValidSet(set),"invalid binding bank")
    local api=self.native.api
    local previous=api.GetCurrentBindingSet()
    assert(self:ValidSet(previous),"binding bank unavailable")
    assert(not self.record.pendingBindingSelection,"binding selection recovery required")
    if previous==set then return callback() end
    assert(self.permits[set],"inactive bank inspection requires explicit consent")
    assert(self.canWrite(),"binding bank inspection is deferred")
    -- Persist selection intent before LoadBindings, including read-only review.
    local snapshot=assert(self.native:Capture())
    local intent={beforeSet=previous,targetSet=set,beforeView=Core.Copy(snapshot.saved),backup=self.permits[set],phase="selecting"}
    self.record.pendingBindingSelection=intent
    if self.busy then self.busy(true) end
    local ok,value=pcall(function()
        assert(self:Select(set),"binding bank selection rejected")
        intent.phase="inspecting"
        return callback()
    end)
    intent.phase="returning"
    local restored=api.GetCurrentBindingSet()==previous
    if not restored then
        local called,result=pcall(self.Select,self,previous)
        restored=called and result
    end
    if restored then
        local called,result=pcall(self.ReturnView,self,intent)
        restored=called and result
    end
    if restored then
        self.record.pendingBindingSelection=nil
        self.record.bindingSelectionHistory=self.record.bindingSelectionHistory or {}
        intent.phase=ok and "returned" or "failed-returned"
        table.insert(self.record.bindingSelectionHistory,Core.Copy(intent))
    end
    if self.busy then self.busy(false) end
    assert(restored,"binding selection recovery required; /cpf recover-selection")
    if not ok then error(value) end
    return value
end
function Banks:read(path)
    if path[1]=="selection" then return self.native.api.GetCurrentBindingSet() end
    assert(path[1]=="key" and type(path[3])=="string")
    return self:InBank(path[2],function() return self.native:read({path[3]}) end)
end
function Banks:write(path,value)
    if not self.journal or not self.canWrite() or self.record.pendingBindingSelection then return false end
    if path[1]=="selection" then
        return self:Select(value) and self.native.api.SaveBindings(value)==true
    end
    assert(path[1]=="key" and type(value)=="string")
    return self:InBank(path[2],function()
        if not self.native:write({path[3]},value) then return false end
        if self.native:read({path[3]})~=value then return false end
        if self.record.pendingBindingSelection then self.record.pendingBindingSelection.savedTarget=true end
        local saved=self.native.api.SaveBindings(path[2])==true
        return saved
    end)
end
function Banks:compensate(step,journal,canWrite)
    if not canWrite() then return false,"protected binding recovery deferred" end
    self:Attach(journal)
    local current=self:read(step.path)
    if Core.Equal(Core.Encode(current),step.before) then return true end
    if not Core.Equal(Core.Encode(current),step.value) then return false,"newer native binding edit retained" end
    return self:write(step.path,Core.Decode(step.before))
end
function Banks:RecoverSelection()
    local intent=self.record.pendingBindingSelection
    if not intent then return true end
    if not self.canWrite() then return false,"protected binding recovery deferred" end
    if not self:ValidSet(intent.beforeSet) or not self:ValidSet(intent.targetSet) then return false,"invalid selection recovery record" end
    local called,result=true,self.native.api.GetCurrentBindingSet()==intent.beforeSet
    if not result then called,result=pcall(self.Select,self,intent.beforeSet) end
    if not called or not result then return false,"binding selection recovery deferred" end
    if not intent.returnedView then
        -- Following a crash there is no known return view to distinguish a
        -- newer bank edit. Keep that view and retain the old snapshot for review.
        self.record.bindingViewRecovery=Core.Copy(intent)
    else
        local restored,reason=pcall(self.ReturnView,self,intent)
        if not restored or not reason then return false,"newer binding view retained; recovery requires review" end
    end
    self.record.pendingBindingSelection=nil
    return true
end
