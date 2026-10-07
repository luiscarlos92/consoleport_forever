local _,Addon=...
local Mount={}
Addon.LiteMountAdapter=Mount
local ids={'CLICK LM_B1:LeftButton','CLICK LM_B2:LeftButton'}
function Mount.New(db,api)
    local self=setmetatable({db=db,api=api},{__index=Mount})
    local ready,reason=self:Probe()
    if not ready then return nil,reason end
    self.bindings,self.icons=db.Bindings,db.Bindings.Icons
    return self
end
function Mount:Probe()
    local api,bindings=self.api,self.db.Bindings
    if not api.C_AddOns or api.C_AddOns.GetAddOnMetadata('ConsolePort','Version')~='3.3.10'
        or api.C_AddOns.GetAddOnMetadata('LiteMount','Version')~='12.1.0-1'
        or not api.C_AddOns.IsAddOnLoaded('LiteMount') then return false,'audited loaded LiteMount/ConsolePort required' end
    if not bindings or type(bindings.Icons)~='table' or type(bindings.GetIcon)~='function' or type(bindings.SetIcon)~='function' then return false,'native binding icon API not initialized' end
    if self.icons and (bindings~=self.bindings or bindings.Icons~=self.icons) then return false,'native binding icon table replaced; refresh review' end
    for _,name in ipairs({'LM_B1','LM_B2'}) do
        local button=api[name]
        if not button or not button.GetName or button:GetName()~=name then return false,'both distinct native LiteMount buttons must be initialized' end
    end
    return true
end
function Mount:Valid(value)
    if self.api.issecretvalue and self.api.issecretvalue(value) then return false end
    return value==nil or (type(value)=='number' and value>0 and value<math.huge and value%1==0)
        or (type(value)=='string' and value~='')
end
function Mount:read(path)
    assert(#path==1 and (path[1]==ids[1] or path[1]==ids[2]),'unowned mount icon')
    local ready,reason=self:Probe() assert(ready,reason)
    local value=rawget(self.icons,path[1])
    assert(self:Valid(value),'unsupported native mount icon')
    return value
end
function Mount:write(path,value)
    if self.api.InCombatLockdown() then return false end
    self:read(path)
    if not self:Valid(value) then return false end
    self.bindings:SetIcon(path[1],value)
    return self:read(path)==value
end
function Mount:Proposal()
    local ready,reason=self:Probe()
    if not ready then return nil,{reason} end
    local values,pending={},{}
    for _,id in ipairs(ids) do
        local ok,explicit=pcall(self.read,self,{id})
        local value=ok and (explicit or self.bindings:GetIcon(id))
        if ok and value==nil and id==ids[1] then value=tonumber(self.api.C_AddOns.GetAddOnMetadata('LiteMount','IconTexture')) end
        if ok and self:Valid(value) and value~=nil then values[id]=value
        else pending[#pending+1]=id..': current/declared icon unavailable or unsupported; distinct native action retained without a guessed dynamic mount icon' end
    end
    return values,pending
end
