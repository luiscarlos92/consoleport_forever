-- Offline experiment only. Not in the addon TOC and not a native hook installer.
local _, Addon = ...
local Core, Prototype = Addon.Core, {}
Addon.SharedUtilityPrototype = Prototype
local function public(api, value)
    return not (api.issecretvalue and api.issecretvalue(value))
end
local function integer(api, value)
    return public(api, value) and type(value)=='number' and value>0 and value%1==0
end
local function safeTable(api, value, seen)
    if not public(api,value) then return false end
    if type(value)~='table' then
        local kind=type(value) return kind=='nil' or kind=='boolean' or kind=='number' or kind=='string'
    end
    seen=seen or {} if seen[value] then return false end seen[value]=true
    for key,item in pairs(value) do if not safeTable(api,key,seen) or not safeTable(api,item,seen) then return false end end
    seen[value]=nil return true
end
local function context(api)
    local ok,value=pcall(api.context)
    if not ok or not safeTable(api,value) or type(value)~='table'
        or type(value.guid)~='string' or value.guid=='' or not integer(api,value.spec) then return end
    return Core.Copy(value)
end
function Prototype.New(api, archive)
    archive=archive or {version=1,revision=0,nextID=1,entries={}}
    assert(safeTable(api,archive) and archive.version==1 and type(archive.entries)=='table'
        and integer(api,archive.nextID) and type(archive.revision)=='number' and archive.revision>=0,'invalid prototype archive')
    archive.receipts=archive.receipts or {}
    local self=setmetatable({api=api,archive=archive,dirty={},cache={},requests={},receipts=archive.receipts,mapping={},
        counts={workers=0,spell=0,item=0,other=0,rebuilds=0,noops=0,queued=0}}, {__index=Prototype})
    self:Index()
    return self
end
function Prototype:Index()
    self.byID,self.byDependency={},{}
    for index,entry in ipairs(self.archive.entries) do
        assert(integer(self.api,entry.entryID) and not self.byID[entry.entryID]
            and type(entry.kind)=='string' and integer(self.api,entry.id)
            and entry.entryID<self.archive.nextID,'duplicate/invalid stable entry ID')
        self.byID[entry.entryID]=index
        local dependency=entry.kind..':'..tostring(entry.id)
        self.byDependency[dependency]=self.byDependency[dependency] or {}
        table.insert(self.byDependency[dependency],entry.entryID)
        local cached=self.cache and self.cache[entry.entryID]
        if cached and cached.dependency and cached.dependency~=entry.id then
            local resolved=entry.kind..':'..tostring(cached.dependency)
            self.byDependency[resolved]=self.byDependency[resolved] or {}
            table.insert(self.byDependency[resolved],entry.entryID)
        end
    end
end
function Prototype:Mark(kind, id)
    for _,entry in ipairs(self.archive.entries) do
        if not kind or (entry.kind==kind and (not id or entry.id==id)) then self.dirty[entry.entryID]=true end
    end
end
function Prototype:Queue()
    if self.queued or (not next(self.dirty) and not self.viewDirty) then return end
    self.queued=true self.counts.queued=self.counts.queued+1
    self.api.defer(function() self.queued=false self:Flush() end)
end
function Prototype:Notify(event, id)
    if event=='context' then
        local now=context(self.api)
        if not now then self.pendingIdentity=true return end
        if not self.owner or self.owner.guid~=now.guid then self:Mark()
        else self:Mark('spell') end
    elseif event=='item' or event=='spell' or event=='macro' then
        if id then
            if not integer(self.api,id) then return end
            for _,entryID in ipairs(self.byDependency[event..':'..tostring(id)] or {}) do self.dirty[entryID]=true end
        else self:Mark(event) end
    elseif event~='resume' then return end
    self:Queue()
end
function Prototype:Add(kind, id, extra)
    assert(type(kind)=='string' and integer(self.api,id),'qualified identity required')
    assert(extra==nil or safeTable(self.api,extra),'opaque entry metadata')
    local entry=Core.Copy(extra or {}) entry.kind,entry.id=kind,id
    entry.entryID=self.archive.nextID self.archive.nextID=self.archive.nextID+1
    self.archive.entries[#self.archive.entries+1]=entry
    self.archive.revision=self.archive.revision+1 self:Index()
    self.dirty[entry.entryID]=true self:Queue()
    return entry.entryID
end
function Prototype:AddNative(action, extra)
    assert(safeTable(self.api,action) and type(action)=='table','opaque native entry')
    if action.autoassigned then return nil,'native transient' end
    if action.type=='spell' then
        local id=type(action.spell)=='number' and action.spell
            or (type(action.link)=='string' and tonumber(action.link:match('spell:(%d+)')))
        if not integer(self.api,id) then return nil,'unqualified spell identity' end
        return self:Add('spell',id,extra)
    elseif action.type=='item' then
        local id=tonumber(action.item) or (type(action.link)=='string' and tonumber(action.link:match('item:(%d+)')))
        if not integer(self.api,id) then return nil,'unqualified item identity' end
        return self:Add('item',id,extra)
    end
    return nil,'native kind not qualified by this experiment'
end
function Prototype:Remove(entryID, revision)
    if revision~=self.archive.revision or not self.byID[entryID] then return false end
    local index=self.byID[entryID]
    table.remove(self.archive.entries,index)
    self.cache[entryID]=nil self.dirty[entryID]=nil
    self.archive.revision=self.archive.revision+1 self:Index() self.viewDirty=true self:Queue()
    return true
end
function Prototype:Reorder(ids, revision)
    if revision~=self.archive.revision then return false end
    local positions,entries,seen={},{},{}
    for _,id in ipairs(ids) do
        if seen[id] or not self.byID[id] then return false end
        seen[id]=true positions[#positions+1]=self.byID[id] entries[#entries+1]=self.archive.entries[self.byID[id]]
    end
    table.sort(positions)
    for index,pos in ipairs(positions) do self.archive.entries[pos]=entries[index] end
    self.archive.revision=self.archive.revision+1 self:Index()
    -- Ordering invalidates the view, not every availability query.
    self.viewDirty=true self:Queue()
    return true
end
function Prototype:Request(kind, id)
    local key=kind..':'..tostring(id)
    if self.requests[key] or not self.api.requestData then return end
    self.requests[key]=true self.api.requestData(kind,id)
end
function Prototype:Classify(entry, now)
    if entry.guid and entry.guid~=now.guid then return {state='unavailable',reason='other character'} end
    if entry.kind=='spell' then
        self.counts.spell=self.counts.spell+1
        local known=self.api.spellKnown(entry.id)
        if not public(self.api,known) or type(known)~='boolean' then return {state='pending',reason='unknown learned status'} end
        local resolved=self.api.overrideSpell(entry.id)
        if not integer(self.api,resolved) then return {state='pending',reason='unknown override'} end
        if resolved~=entry.id then
            known=self.api.spellKnown(resolved)
            if not public(self.api,known) or type(known)~='boolean' then return {state='pending',reason='unknown override learned status'} end
        end
        if not known then return {state='unavailable',reason='not learned'} end
        local info=self.api.spellInfo(resolved)
        if not safeTable(self.api,info) or type(info)~='table' or not integer(self.api,info.spellID) then
            self:Request('spell',resolved) return {state='pending',reason='spell data',dependency=resolved}
        end
        return {state='available',payload={type='spell',spell=resolved},dependency=resolved}
    elseif entry.kind=='item' then
        self.counts.item=self.counts.item+1
        local count=self.api.itemCount(entry.id,false,false,false,false)
        if not public(self.api,count) or type(count)~='number' then return {state='pending',reason='unknown item count'} end
        if count<=0 then return {state='unavailable',reason='not carried'} end
        local ready=self.api.itemReady(entry.id)
        if not public(self.api,ready) or type(ready)~='boolean' then return {state='pending',reason='unknown item metadata'} end
        if not ready then self:Request('item',entry.id) return {state='pending',reason='item data'} end
        return {state='available',payload={type='item',item=tostring(entry.id)}}
    elseif entry.kind=='macro' then
        self.counts.other=self.counts.other+1
        local current=self.api.macroInfo(entry.id)
        if not safeTable(self.api,current) then return {state='pending',reason='opaque macro'} end
        if not current or type(entry.name)~='string' or type(entry.body)~='string'
            or current.name~=entry.name or current.body~=entry.body then return {state='pending',reason='macro drift'} end
        return {state='available',payload={type='macro',macro=entry.id,name=current.name,body=current.body,icon=current.icon,macrotext=false}}
    end
    return {state='pending',reason='unqualified kind'}
end
function Prototype:Build(current)
    local desired={[0]=Core.Copy(current[0] or {})}
    local map={}
    for _,entry in ipairs(self.archive.entries) do
        local result=self.cache[entry.entryID]
        if result and result.state=='available' then
            desired[#desired+1]=Core.Copy(result.payload) map[#desired]=entry.entryID
        end
    end
    for index,action in ipairs(current) do
        if action.autoassigned then
            local position=math.min(index,#desired+1)
            table.insert(desired,position,Core.Copy(action))
            table.insert(map,position,0)
        end
    end
    local oldSticky=current[0] and current[0].sticky
    local selected=oldSticky and self.mapping[oldSticky]
    if oldSticky then
        desired[0].sticky=nil
        for index,id in ipairs(map) do if selected and selected~=0 and id==selected then desired[0].sticky=index end end
    end
    return desired,map
end
function Prototype:Flush()
    if not next(self.dirty) and not self.viewDirty then return false,'unchanged' end
    if self.api.blocked() then self.pending=true return false,'deferred' end
    if self.receipts[#self.receipts] and self.receipts[#self.receipts].status=='recovery-required' then return false,'recovery required' end
    local now=context(self.api)
    if not now then self.pendingIdentity=true return false,'identity pending' end
    if not self.owner or self.owner.guid~=now.guid then self:Mark()
    elseif self.owner.spec~=now.spec or self.owner.config~=now.config then self:Mark('spell') end
    local revision=self.archive.revision
    self.counts.workers=self.counts.workers+1
    local changed=Core.Copy(self.dirty)
    for _,entry in ipairs(self.archive.entries) do
        if changed[entry.entryID] then
            local ok,result=pcall(self.Classify,self,entry,now)
            self.cache[entry.entryID]=ok and result or {state='pending',reason='rejected read'}
        end
    end
    self:Index()
    if not Core.Equal(now,context(self.api)) then self:Mark() self.pending=true return false,'stale context' end
    if revision~=self.archive.revision then self:Mark() self.pending=true return false,'stale edit revision' end
    local readable,current=pcall(self.api.readView)
    if not readable or not safeTable(self.api,current) or type(current)~='table' then self.pending=true return false,'opaque view' end
    if not Core.Equal(now,context(self.api)) then self:Mark() self.pending=true return false,'stale context' end
    if self.api.blocked() then self.pending=true return false,'deferred' end
    local desired,map=self:Build(current)
    if Core.Equal(current,desired) then
        self.counts.noops=self.counts.noops+1
    else
        local receipt={owner=Core.Copy(now),revision=self.archive.revision,before=Core.Copy(current),desired=Core.Copy(desired),status='attempting'}
        self.receipts[#self.receipts+1]=receipt
        if #self.receipts>2 then table.remove(self.receipts,1) end
        local ok,result=pcall(self.api.writeView,desired)
        local readOK,actual=pcall(self.api.readView)
        if not ok or result~=true or not readOK or not safeTable(self.api,actual) or not Core.Equal(actual,desired) then
            receipt.status='recovery-required' self.pending=true return false,'readback rejected'
        end
        receipt.status='verified' self.counts.rebuilds=self.counts.rebuilds+1
    end
    self.mapping=map self.owner=now self.dirty={} self.viewDirty=nil self.pending=nil self.pendingIdentity=nil
    return true
end
function Prototype:Recover()
    local receipt=self.receipts[#self.receipts]
    if not receipt or receipt.status~='recovery-required' or self.api.blocked() then return false end
    local now=context(self.api)
    if not now or not Core.Equal(now,receipt.owner) then return false end
    local readOK,actual=pcall(self.api.readView)
    if not readOK or not safeTable(self.api,actual) then return false end
    if Core.Equal(actual,receipt.before) then receipt.status='rolled-back' return true end
    if not Core.Equal(actual,receipt.desired) then return false end
    -- A successful write followed by an exception can be recognized by readback.
    -- Never re-install an old spec's before-view merely to undo a completed projection.
    receipt.status='verified-recovered' return true
end
function Prototype:Clear(revision)
    if revision~=self.archive.revision then return false end
    self.archive.entries={} self.cache={} self.dirty={}
    self.archive.revision=self.archive.revision+1 self:Index() self.viewDirty=true self:Queue()
    return true
end
function Prototype:ResetAfterReload()
    self.cache={} self.owner=nil self:Mark() self:Queue()
end
