local _,Addon=...
local Core,Runtime=Addon.Core,{}
Addon.SharedUtilityRuntime=Runtime
local function manual(set)
    local actions={}
    for _,action in ipairs(set or {}) do if not action.autoassigned then actions[#actions+1]=Core.Copy(action) end end
    return actions
end
function Runtime.New(model,env,setID,api)
    local self=setmetatable({model=model,env=env,frame=env.Frame,setID=setID,api=api,
        originalValidate=env.ValidateSet,originalRefresh=env.Frame.RefreshAll,
        last={},lastIDs={},counts={admissions=0,edits=0,deferredNative=0}}, {__index=Runtime})
    model.api.canWriteOwner=function() return self:Enabled() and self:Owns() end
    return self
end
function Runtime:Enabled()
    return not self.stopped and not self.seedOnly and self.api.enabled()
end
function Runtime:Owns()
    return self.env.Frame==self.frame and self.api.owner()==self.frame
        and self.env.ValidateSet==self.validateWrapper and self.frame.RefreshAll==self.refreshWrapper
end
function Runtime:Reconcile(set)
    if not self.model:Safe(set) then return false,'opaque native set' end
    if self.primed and set[0]==nil and #set==0 then
        self.model:Clear(self.model.archive.revision) self.last={} self.lastIDs={}
        return true
    end
    local current=manual(set)
    if Core.Equal(current,self.last) then return true end
    self.counts.edits=self.counts.edits+1
    local used,ids={},{}
    for _,action in ipairs(current) do
        local found
        for index,previous in ipairs(self.last) do
            if not used[index] and Core.Equal(action,previous) then used[index]=true found=self.lastIDs[index] break end
        end
        if not found then found=self.model:AddNative(action) end
        if not found then return false,'unqualified new native entry' end
        ids[#ids+1]=found
    end
    for index,id in ipairs(self.lastIDs) do if not used[index] then self.model:Remove(id,self.model.archive.revision) end end
    if #ids>0 then self.model:Reorder(ids,self.model.archive.revision) end
    return true
end
function Runtime:Remember(set,map,now)
    self.last=manual(set) self.lastIDs={} self.primed=true
    for _,id in ipairs(map) do if id~=0 then self.lastIDs[#self.lastIDs+1]=id end end
    self.model.mapping=map self.model.owner=now
end
function Runtime:RecoveryReady()
    local receipts=self.model.receipts
    local receipt=receipts[#receipts]
    if not receipt or receipt.status~='recovery-required' then return true end
    if self.model:Recover() then return true end
    self.fault='projection recovery pending; /cpfutility off then /reload'
    return false
end
function Runtime:Prepare(set)
    if not self:Enabled() or not self:Owns() then return nil,'inactive native owner' end
    if self.api.blocked() and not self.allowManual then self.pendingNative=true return nil,'deferred native refresh' end
    if not self:RecoveryReady() then return nil,'recovery pending' end
    local model=self.model
    local now=model:Context()
    if not now then model.pendingIdentity=true return nil,'identity pending' end
    if not model:Safe(set) then return nil,'opaque native set' end
    if self.primed and not self.writing then
        local ok,reason=self:Reconcile(set) if not ok then return nil,reason end
    end
    if not self.writing then
        if not model.owner or model.owner.guid~=now.guid then model:Mark()
        elseif not Core.Equal(model.owner,now) then model:Mark('spell') model:Mark('native') end
    end
    local revision=model.archive.revision
    for _,entry in ipairs(model.archive.entries) do
        if not self.writing and model.dirty[entry.entryID] then
            local ok,result=pcall(model.Classify,model,entry,now)
            model.cache[entry.entryID]=ok and result or {state='pending',reason='rejected read'}
        end
    end
    model:Index()
    if not Core.Equal(now,model:Context()) or revision~=model.archive.revision or (self.api.blocked() and not self.allowManual) then
        model:Mark() model.pending=true return nil,'stale or blocked projection'
    end
    local desired,map=model:Build(set)
    return desired,map,now
end
function Runtime:Validate(env,id,set)
    if id~=self.setID or set~=self.frame.Data[self.setID] or not self:Enabled() then
        return self.originalValidate(env,id,set)
    end
    self.counts.admissions=self.counts.admissions+1
    local desired,map,now=self:Prepare(set)
    if not desired then return set end
    local revision=self.model.archive.revision
    local qualified=self.originalValidate(env,id,Core.Copy(desired))
    if not Core.Equal(qualified,desired) then
        self.fault='native validation changed qualified payload' self.stopped=true
        return set
    end
    if not Core.Equal(now,self.model:Context()) or revision~=self.model.archive.revision or not self:Owns() then
        self.model:Mark() self.pendingNative=true return set
    end
    local receipt
    if not self.writing and not Core.Equal(set,qualified) then
        receipt={owner=Core.Copy(now),revision=revision,before=Core.Copy(set),desired=Core.Copy(qualified),status='attempting'}
        local receipts=self.model.receipts receipts[#receipts+1]=receipt
        if #receipts>2 then table.remove(receipts,1) end
    end
    Core.Replace(set,qualified)
    if receipt then
        if Core.Equal(self.frame.Data[self.setID],qualified) then receipt.status='verified'
        else receipt.status='recovery-required' self.stopped=true self.fault='projection readback rejected' return set end
    end
    self:Remember(set,map,now)
    self.model.dirty={} self.model.viewDirty=nil self.model.pending=nil
    return set
end
function Runtime:Refresh(frame,...)
    if not self:Enabled() then return self.originalRefresh(frame,...) end
    if not self:Owns() then self.fault='native owner changed' return end
    if not self:RecoveryReady() then return end
    local now=self.model:Context()
    local changedManual=false
    local current=frame.Data[self.setID]
    if self.primed and type(current)=='table' and self.model:Safe(current) then
        changedManual=(current[0]==nil and #current==0) or not Core.Equal(manual(current),self.last)
    end
    local manual=(changedManual or (self.manualDepth and self.manualDepth>0)) and self.api.hardBlocked
        and not self.api.hardBlocked() and now and Core.Equal(now,self.model.owner)
    if (self.api.blocked() and not manual) or not now then
        self.pendingNative=true self.counts.deferredNative=self.counts.deferredNative+1 return
    end
    -- Check before ClearAllActions: that native function rewrites compiled DATA.
    local set=frame.Data[self.setID]
    if type(set)~='table' or not self.model:Safe(set) then self.fault='native set unavailable' return end
    self.allowManual=manual
    local ok,result=pcall(self.originalRefresh,frame,...)
    self.allowManual=nil
    if not ok then self:Abort('native rebuild rejected; /cpfutility off then /reload') return end
    return result
end
function Runtime:Write(value)
    if not self:Enabled() or not self:Owns() or self.api.blocked() then return false end
    self.writing=true
    Core.Replace(self.frame.Data[self.setID],value)
    local ok=pcall(self.frame.RefreshAll,self.frame)
    self.writing=false
    if not ok or self.stopped then self.fault=self.fault or 'native rebuild failed' self.stopped=true return false end
    return Core.Equal(self.frame.Data[self.setID],value)
end
function Runtime:Resume()
    if not self:Enabled() or not self:Owns() or self.api.blocked() then return end
    if self.pendingNative then
        self.pendingNative=nil self.frame:RefreshAll()
    end
    self.model:Notify('resume')
end
function Runtime:Install()
    local self=self
    self.validateWrapper=function(...) return self:Validate(...) end
    self.refreshWrapper=function(...) return self:Refresh(...) end
    self.env.ValidateSet=self.validateWrapper self.frame.RefreshAll=self.refreshWrapper
    self.eventOriginals={} self.eventWrappers={}
    self.editOriginals={} self.editWrappers={}
    for _,method in ipairs({'AddAction','RemoveAction'}) do
        local original=self.frame[method]
        if type(original)=='function' then
            self.editOriginals[method]=original
            local wrapper=function(frame,setID,index,info)
                local action=method=='AddAction' and info or (self.env:GetSet(setID,true) or {})[index]
                local explicit=type(action)=='table' and self.model:Safe(action) and not action.autoassigned
                self.manualDepth=(self.manualDepth or 0)+(explicit and 1 or 0)
                local ok,result=pcall(original,frame,setID,index,info)
                self.manualDepth=self.manualDepth-(explicit and 1 or 0)
                if not ok then error(result,0) end
                return result
            end
            self.frame[method]=wrapper self.editWrappers[method]=wrapper
        end
    end
    for event,domains in pairs({SPELLS_CHANGED={'spell','native'},UPDATE_MACROS={'macro'},BAG_UPDATE_DELAYED={'item'},
        ACTIONBAR_SLOT_CHANGED={'native'}}) do
        local original=self.frame[event]
        local registeredEvent=event
        if type(original)=='function' then
            self.eventOriginals[event]=original
            self.frame[event]=function(frame,...)
                if self:Enabled() then
                    if registeredEvent=='ACTIONBAR_SLOT_CHANGED' then self.model:MarkNative('action',...)
                    else for _,domain in ipairs(domains) do self.model:Mark(domain) end end
                end
                return original(frame,...)
            end
            self.eventWrappers[event]=self.frame[event]
        end
    end
    self.frame:HookScript('OnHide',function()
        if self:Enabled() then self.api.defer(function() self:Resume() end) end
    end)
end
function Runtime:Abort(reason)
    self.stopped=true self.fault=reason
    if self.env.ValidateSet==self.validateWrapper then self.env.ValidateSet=self.originalValidate end
    if self.frame.RefreshAll==self.refreshWrapper then self.frame.RefreshAll=self.originalRefresh end
    for event,wrapper in pairs(self.eventWrappers or {}) do
        if self.frame[event]==wrapper then self.frame[event]=self.eventOriginals[event] end
    end
    for method,wrapper in pairs(self.editWrappers or {}) do
        if self.frame[method]==wrapper then self.frame[method]=self.editOriginals[method] end
    end
end
function Runtime:Notify(event,id)
    if not self:Enabled() then return end
    if event=='context' then self.model:Mark('native') end
    self.model:Notify(event,id)
    self:Resume()
end
function Runtime:SaveNativeSeed()
    if not self:Enabled() or not self:Owns() or not self.primed then return false end
    local set=self.frame.Data[self.setID]
    if not self.model:Safe(set) then return false end
    -- PLAYER_LOGOUT precedes engine serialization. Keep the shared master in
    -- Forever, but serialize only timeless native commands in the native seed.
    -- No protected write, native refresh or filesystem/WTF operation occurs.
    self.seedOnly=true
    local seed={[0]=Core.Copy(set[0] or {})}
    seed[0].sticky=nil
    for _,action in ipairs(set) do
        if not action.autoassigned and action.type=='custom' and action.binding then seed[#seed+1]=Core.Copy(action) end
    end
    Core.Replace(set,seed)
    return true
end
function Runtime:Disable()
    if self.api.saveFallback and self.model.owner and Core.Equal(self.model.owner,self.model:Context())
        and self.model:Safe(self.frame.Data[self.setID]) then
        self.api.saveFallback(manual(self.frame.Data[self.setID]),self.frame.Data[self.setID][0])
    end
    self.stopped=true
end
function Runtime:Status()
    if self.fault then return self.fault..'; /reload or /cpfutility off' end
    if self.stopped then return 'reload pending' end
    if self.model.pendingIdentity then return 'identity pending' end
    if self.pendingNative or self.model.pending then return 'waiting for native wheel/combat/editor to finish' end
    return tostring(#self.model.archive.entries)..' saved choices'
end
