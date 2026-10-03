local _, Addon = ...
local Ownership = {}
Addon.Ownership = Ownership
function Ownership.New()
    return setmetatable({stack = {}, presses = {}, generation = 0}, {__index=Ownership})
end
function Ownership:Push(id, kind)
    self:Remove(id)
    self.generation = self.generation + 1
    local owner = {id=id, kind=kind, generation=self.generation}
    self.stack[#self.stack + 1] = owner
    return owner
end
function Ownership:Remove(id)
    for index = #self.stack, 1, -1 do
        if self.stack[index].id == id then table.remove(self.stack, index) end
    end
end
function Ownership:Begin(key)
    if self.presses[key] then return nil, "press already owned" end
    local owner = self.stack[#self.stack]
    if not owner then return nil, "no input owner" end
    self.presses[key] = {id=owner.id, generation=owner.generation}
    return owner
end
function Ownership:Finish(key)
    local press = self.presses[key]
    self.presses[key] = nil
    if not press then return nil, "unowned release" end
    for _, owner in ipairs(self.stack) do
        if owner.id == press.id and owner.generation == press.generation then return owner end
    end
    return nil, "owner vanished; cancel release"
end
function Ownership:Disconnect()
    self.presses = {}
end
