local _,Addon=...
local Core,Adapter=Addon.Core,{}
Addon.DynamicCamAdapter=Adapter
local function supportedDefaults(defaults,seen)
    if type(defaults)~='table' then return true end
    seen=seen or {} if seen[defaults] then return false end seen[defaults]=true
    for key,value in pairs(defaults) do
        if key=='*' or key=='**' or not supportedDefaults(value,seen) then return false end
    end
    seen[defaults]=nil
    return true
end
local function effective(value,defaults)
    local result=Core.Copy(value)
    if type(result)~='table' or type(defaults)~='table' then return result end
    for key,default in pairs(defaults) do
        if result[key]==nil then result[key]=Core.Copy(default)
        elseif type(result[key])=='table' and type(default)=='table' then result[key]=effective(result[key],default) end
    end
    return result
end
function Adapter.New(api,owned)
    return setmetatable({api=api,owned=owned},{__index=Adapter})
end
function Adapter:Probe()
    local addon=self.api.addon()
    local db=addon and addon.db
    if self.api.version~='2.21.1' or type(db)~='table' or type(db.profiles)~='table'
        or type(db.GetCurrentProfile)~='function' or type(db.SetProfile)~='function'
        or type(db.DeleteProfile)~='function' or type(addon.RefreshConfig)~='function'
        or type(db.profile)~='table' then return false,'audited DynamicCam/AceDB not initialized' end
    -- Copying only the main profile cannot preserve namespace profiles.
    if (db.children and next(db.children)) or (db.sv.namespaces and next(db.sv.namespaces)) then
        return false,'DynamicCam namespace cloning has not been qualified'
    end
    if not supportedDefaults(db.defaults and db.defaults.profile) then return false,'DynamicCam wildcard defaults are not qualified' end
    self.addon,self.db=addon,db
    for name,record in pairs(self.owned) do
        if type(name)~='string' or type(record)~='table' or record.created~=true then return false,'invalid managed DynamicCam ownership' end
    end
    return true
end
function Adapter:Proposal(base)
    local ready,reason=self:Probe()
    if not ready then return nil,reason end
    local active=self.db:GetCurrentProfile()
    if self.owned[active] and not self.owned[active].removed then return active,Core.Copy(self.db.profile) end
    if self.db.profiles[base] then return nil,'managed DynamicCam name belongs to an existing profile' end
    self.candidate=base
    return base,Core.Copy(self.db.profile)
end
function Adapter:read(path)
    local ready,reason=self:Probe() assert(ready,reason)
    if path[1]=='selected' then return self.db:GetCurrentProfile() end
    assert(path[1]=='profile' and type(path[2])=='string','unsupported DynamicCam field')
    return effective(self.db.profiles[path[2]],self.db.defaults and self.db.defaults.profile)
end
function Adapter:write(path,value)
    if self.api.inCombat() then return false end
    local ready=self:Probe() if not ready then return false end
    local db=self.db
    if path[1]=='selected' then
        if type(value)~='string' or not db.profiles[value] then return false end
        if db:GetCurrentProfile()==value then return true end
        db:SetProfile(value) -- DynamicCam's native OnProfileChanged refreshes once.
        return db:GetCurrentProfile()==value
    end
    assert(path[1]=='profile' and type(path[2])=='string','unsupported DynamicCam field')
    local name=path[2]
    if self.owned[name] and self.owned[name].removed and db.profiles[name]~=nil then return false end
    if not self.owned[name] or self.owned[name].removed then
        if value==nil and db.profiles[name]==nil then return true end
        if name~=self.candidate or db.profiles[name]~=nil or type(value)~='table' then return false end
        -- Persist intent before preparing an inactive profile. A later recovery
        -- may touch only this exact retained owned name, never a prefix match.
        self.owned[name]={created=true}
    end
    if value==nil then
        if db:GetCurrentProfile()==name then return false end
        if db.profiles[name] then db:DeleteProfile(name,true) end
        if db.profiles[name]==nil then self.owned[name].removed=true return true end
        return false
    end
    if type(value)~='table' then return false end
    if db:GetCurrentProfile()==name then
        Core.Replace(db.profile,value)
        self.addon:RefreshConfig()
    else
        -- AceDB SetProfile lazily initializes this documented profile store.
        -- Prepare the clone before selection, avoiding SetProfile+CopyProfile's
        -- two refresh callbacks and preserving every original profile.
        db.profiles[name]=Core.Copy(value)
    end
    return Core.Equal(self:read(path),value)
end
