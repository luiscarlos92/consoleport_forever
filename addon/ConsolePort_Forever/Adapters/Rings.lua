local _,Addon=...
local Core,Bridge=Addon.Core,{}
Addon.RingsAdapter=Bridge
function Bridge.New(api,account,guid)
    return setmetatable({api=api,account=account,guid=guid},{__index=Bridge})
end
function Bridge:Probe()
    if self.api.version~='3.3.10' then return false,'ring version has not been audited' end
    if type(self.api.currentGUID)~='function' or self.api.currentGUID()~=self.guid then return false,'ring view belongs to another or unavailable GUID' end
    local record=self.account.characters[self.guid]
    if not record or type(record.rings)~='table' or (record.ringAccepted and type(record.rings.sets)~='table')
        or (record.rings.dormant~=nil and type(record.rings.dormant)~='table') then return false,'retained GUID ring data is malformed' end
    local env=self.api.getEnv()
    local db=self.api.getDB()
    local rings=db and db.Rings
    if type(env)~='table' or env.Frame~=rings or not env.IsDataReady or not env.IsSpellValidationReady
        or (type(rings)~='table' and type(rings)~='userdata') then return false,'native ring data/spell validation not initialized' end
    if type(self.api.defaultSet)~='number' or type(rings.Data)~='table' or type(rings.Shared)~='table' or type(rings.RefreshAll)~='function'
        or type(env.ValidateSet)~='function' or type(env.GetStarterSet)~='function'
        or not env.Attributes or env.Attributes.MetadataIndex~=0 then return false,'native ring bridge unavailable' end
    self.env,self.rings=env,rings
    return true
end
-- Auto-assigned utility entries belong to native ConsolePort events, not to a
-- GUID archive. Metadata, duplicates, custom actions and manual order survive.
local function manual(data)
    local sets={}
    for id,set in pairs(data) do
        assert((type(id)=='string' or type(id)=='number') and type(set)=='table','malformed personal ring set')
        local copy=Core.Copy(set)
        for i=#copy,1,-1 do if copy[i].autoassigned then table.remove(copy,i) end end
        sets[id]=copy
    end
    return sets
end
function Bridge:read(path)
    assert(path[1]=='state' and self:Probe(),'ring data unavailable')
    return {guid=self.account.shared.ringProjectionGUID,sets=manual(self.rings.Data)}
end
function Bridge:Proposal()
    local ready,reason=self:Probe()
    if not ready then return nil,reason end
    local record=self.account.characters[self.guid]
    local sets
    if type(record.rings.sets)=='table' and (record.ringAccepted or (self.account.shared.ringProjectionGUID and self.account.shared.ringProjectionGUID~=self.guid)) then
        self:CaptureEdits()
        sets=Core.Copy(record.rings.sets)
    elseif not self.account.shared.ringProjectionGUID or self.account.shared.ringProjectionGUID==self.guid then sets=manual(self.rings.Data)
    else
        -- A new GUID receives the current upstream starter utility. It never
        -- imports the prior character's personal spells or manual arrangement.
        sets={[self.api.defaultSet]=Core.Copy(self.env:GetStarterSet())}
        -- Keep an existing class opener address available, with empty contents.
        local classSet=self.api.classSet
        if classSet and classSet~=self.api.defaultSet and self.rings.Data[classSet] and not self.rings.Shared[classSet] then sets[classSet]={[0]={}} end
    end
    -- Native validation is applied to detached data only. The accepted proposal
    -- contains exactly the qualified view; unavailable actions stay archived.
    for id,set in pairs(sets) do sets[id]=self.env:ValidateSet(id,Core.Copy(set)) end
    return {guid=self.guid,sets=sets}
end
function Bridge:write(path,value)
    if path[1]~='state' or self.api.inCombat() or not self:Probe() or type(value)~='table' or type(value.sets)~='table' then return false end
    if self.rings:IsShown() then return false end
    if value.guid~=nil and (type(value.guid)~='string' or not self.account.characters[value.guid]) then return false end
    local sets=manual(value.sets)
    -- Preserve only the native runtime utility entries in their existing slots.
    -- RefreshAll and native quest/zone callbacks retain authority over them.
    local utility=self.rings.Data[self.api.defaultSet]
    local dest=sets[self.api.defaultSet]
    if utility and not dest then dest={[0]={}} sets[self.api.defaultSet]=dest end
    if utility then
        for i,action in ipairs(utility) do
            if action.autoassigned then table.insert(dest,math.min(i,#dest+1),Core.Copy(action)) end
        end
    end
    Core.Replace(self.rings.Data,sets)
    self.account.shared.ringProjectionGUID=value.guid
    self.rings:RefreshAll()
    return Core.Equal(self:read(path),value)
end
function Bridge:CaptureEdits()
    local record=self.account.characters[self.guid]
    if not record.ringAccepted or self.account.shared.ringProjectionGUID~=self.guid then return false end
    local ok,state=pcall(self.read,self,{'state'})
    if not ok then return false end
    local sets=state.sets
    local dormant={}
    -- A native refresh may hide an unavailable manual spell. Keep its archived
    -- position until it can project again; an explicit whole-set deletion wins.
    for id,previous in pairs(record.rings.sets or {}) do
        local current=sets[id]
        if current then
            local nativeEntries,matched=Core.Copy(current),{}
            for index,action in ipairs(previous) do
                local exists=false
                for slot,now in ipairs(nativeEntries) do
                    if not matched[slot] and Core.Equal(action,now) then exists=true matched[slot]=true break end
                end
                if not exists then
                    local wasDormant=false
                    for _,entry in ipairs((record.rings.dormant or {})[id] or {}) do if Core.Equal(entry,action) then wasDormant=true break end end
                    local qualified=self.env:ValidateSet(id,{[0]={},Core.Copy(action)})
                    if wasDormant or #qualified==0 then
                        table.insert(current,math.min(index,#current+1),Core.Copy(action))
                        dormant[id]=dormant[id] or {}
                        dormant[id][#dormant[id]+1]=Core.Copy(action)
                    end
                end
            end
        end
    end
    record.rings.sets=Core.Copy(sets)
    record.rings.dormant=dormant
    return true
end
