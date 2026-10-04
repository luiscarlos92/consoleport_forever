local _, Addon = ...
local Core, Flat = Addon.Core, {}
Addon.FlatConfigAdapter = Flat
function Flat.New(getTable,allowed,inCombat)
    return setmetatable({getTable=getTable,allowed=allowed,inCombat=inCombat},{__index=Flat})
end
function Flat:read(path)
    assert(#path==1 and self.allowed[path[1]],"unowned flat field")
    local live=self.getTable()
    if type(live)~="table" then error("integration not initialized") end
    if self.validate then assert(self.validate(path,live[path[1]]),'unsupported integration value') end
    return Core.Copy(live[path[1]])
end
function Flat:write(path,value)
    if self.inCombat() then return false end
    assert(#path==1 and self.allowed[path[1]],"unowned flat field")
    if self.validate then assert(self.validate(path,value),'unsupported integration value') end
    local live=self.getTable()
    if type(live)~="table" then return false end
    if type(live[path[1]])=="table" and type(value)=="table" then Core.Replace(live[path[1]],value)
    else live[path[1]]=Core.Copy(value) end
    return true
end
