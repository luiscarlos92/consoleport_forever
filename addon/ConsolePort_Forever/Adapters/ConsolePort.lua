local _, Addon = ...
local Core, Bridge = Addon.Core, {}
Addon.ConsolePortAdapter = Bridge
function Bridge.New(api)
    return setmetatable({api=api},{__index=Bridge})
end
function Bridge:Probe()
    if self.api.version ~= "3.3.3" then return false,"ConsolePort version has not been audited" end
    local db,bar=self.api.getDB(),self.api.getBar()
    if type(db)~="table" or not db.Settings or not db.Layers or type(db.Set)~="function" then return false,"ConsolePort DB/Layers not initialized" end
    if type(bar)~="table" or not bar.Layout or not bar.Manager or not bar.Manager.hasEnvironment then return false,"ConsolePort Bar not initialized" end
    if type(bar.ApplyPreset)~="function" then return false,"layout bridge unavailable" end
    self.db,self.bar=db,bar
    return true
end
function Bridge:read(path)
    assert(self:Probe())
    if path[1]=="settings" then return self.db:Get("Settings/"..assert(path[2])) end
    if path[1]=="layout" then return Core.Copy(self.bar.Layout) end
    error("unsupported ConsolePort path")
end
function Bridge:write(path,value)
    if self.api.inCombat() or not self:Probe() then return false end
    if path[1]=="settings" then return self.db:Set("Settings/"..assert(path[2]),value)==true end
    if path[1]=="layout" and type(value)=="table" then
        self.bar:ApplyPreset(Core.Copy(value))
        return Core.Equal(self.bar.Layout,value)
    end
    return false
end
function Bridge:Capture()
    if not self:Probe() then return nil,"ConsolePort data not ready" end
    return {settings=Core.Copy(self.db.Settings),layout=Core.Copy(self.bar.Layout)}
end
