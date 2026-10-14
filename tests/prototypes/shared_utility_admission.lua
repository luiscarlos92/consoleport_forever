-- Offline admission experiment. No runtime installer or protected dispatch.
local _,Addon=...
local Core,Admission=Addon.Core,{}
Addon.SharedUtilityAdmissionPrototype=Admission

local function manual(set)
    local result={}
    for _,action in ipairs(set) do
        if not action.autoassigned then result[#result+1]=Core.Copy(action) end
    end
    return result
end

function Admission.New(model,env,setID)
    local ids={}
    for _,id in ipairs(model.mapping) do if id~=0 then ids[#ids+1]=id end end
    return setmetatable({model=model,env=env,setID=setID,original=env.ValidateSet,
        counts={admissions=0,edits=0},last=manual(env.Frame.Data[setID]),lastIDs=ids}, {__index=Admission})
end

function Admission:Reconcile(set)
    if self.primed and set[0]==nil and #set==0 then
        self.model:Clear(self.model.archive.revision)
        self.last={} self.lastIDs={}
        return
    end
    local current=manual(set)
    if Core.Equal(current,self.last) then return end
    self.counts.edits=self.counts.edits+1
    local used,ids={},{}
    for _,action in ipairs(current) do
        local found
        for index,previous in ipairs(self.last) do
            if not used[index] and Core.Equal(action,previous) then
                used[index]=true found=self.lastIDs[index] break
            end
        end
        if not found then found=self.model:AddNative(action) end
        if found then ids[#ids+1]=found end
    end
    -- Only choices represented by the previous active view can be deleted here.
    -- Hidden choices are not native validation failures or implicit deletions.
    for index,id in ipairs(self.lastIDs or {}) do
        if not used[index] then self.model:Remove(id,self.model.archive.revision) end
    end
    self.model:Reorder(ids,self.model.archive.revision)
end

function Admission:Prepare(set)
    local model=self.model
    local now=model.api.context()
    self:Reconcile(set)
    if not model.owner or model.owner.guid~=now.guid then model:Mark()
    elseif not Core.Equal(model.owner,now) then model:Mark('spell') end
    for _,entry in ipairs(model.archive.entries) do
        if model.dirty[entry.entryID] then
            local ok,result=pcall(model.Classify,model,entry,now)
            model.cache[entry.entryID]=ok and result or {state='pending',reason='rejected read'}
        end
    end
    model:Index()
    if not Core.Equal(now,model.api.context()) then return nil,'stale context' end
    local desired,map=model:Build(set)
    return desired,map,now
end

function Admission:Install(markNativeEvents)
    local self=self
    self.env.ValidateSet=function(env,setID,set)
        if setID~=self.setID or set~=env.Frame.Data[self.setID] then
            return self.original(env,setID,set)
        end
        self.counts.admissions=self.counts.admissions+1
        local desired,map,now=self:Prepare(set)
        if not desired then return set end
        local qualified=self.original(env,setID,desired)
        Core.Replace(set,qualified)
        self.model.mapping=map self.model.owner=now self.model.dirty={}
        self.model.viewDirty=nil
        self.last=manual(set) self.lastIDs={} self.primed=true
        for _,id in ipairs(map) do if id~=0 then self.lastIDs[#self.lastIDs+1]=id end end
        return set
    end
    if markNativeEvents then
        self.spellEvent=self.env.Frame.SPELLS_CHANGED
        self.env.Frame.SPELLS_CHANGED=function(frame,...)
            self.model:Mark('spell')
            return self.spellEvent(frame,...)
        end
    end
end

function Admission:Uninstall()
    self.env.ValidateSet=self.original
    if self.spellEvent then self.env.Frame.SPELLS_CHANGED=self.spellEvent end
end
