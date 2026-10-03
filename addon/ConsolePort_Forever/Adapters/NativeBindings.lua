local _, Addon = ...
local Native = {}
Addon.NativeBindings = Native
-- API injection is only for deterministic tests. Production callers supply
-- actual native functions; wrappers must not clear keys outside the mask.
function Native.New(api)
    return setmetatable({api=api}, {__index=Native})
end
function Native:Ready()
    local set = self.api.GetCurrentBindingSet()
    return set == self.api.AccountSet or set == self.api.CharacterSet
end
function Native:Capture()
    if not self:Ready() then return nil, "bindings not initialized" end
    local saved, keyboard, effective = {}, {}, {}
    for index=1,self.api.GetNumBindings() do
        local binding = {self.api.GetBinding(index)}
        for keyIndex=3,#binding do
            local key = binding[keyIndex]
            if key then
                saved[key] = self.api.GetBindingAction(key, false)
                effective[key] = self.api.GetBindingAction(key, true)
                if not key:match("PAD") then keyboard[key] = saved[key] end
            end
        end
    end
    return {set=self.api.GetCurrentBindingSet(), saved=saved, keyboard=keyboard, effective=effective}
end
function Native:read(path)
    assert(#path==1, "binding path requires one physical key")
    if not self:Ready() then error("bindings not initialized") end
    return self.api.GetBindingAction(path[1], false) or ""
end
function Native:write(path, command)
    assert(#path==1, "binding path requires one physical key")
    if self.api.InCombatLockdown() or not self:Ready() then return false end
    -- SetBinding has a native success result and leaves unrelated chords alone.
    local action = command
    if action == "" then action = nil end
    local context = self.api.GetBindingContextForAction and action and self.api.GetBindingContextForAction(action)
    if self.api.SetBinding(path[1], action, context) ~= true then return false end
    return (self.api.GetBindingAction(path[1], false, context) or "") == (command or "")
end
function Native:SelectCharacter(snapshot)
    if self.api.InCombatLockdown() or not self:Ready() then return false, "binding set not ready" end
    self.api.LoadBindings(self.api.CharacterSet)
    if self.api.GetCurrentBindingSet() ~= self.api.CharacterSet then return false, "character set selection rejected" end
    local target = self:Capture()
    -- Remove keyboard keys unique to the newly selected set, then restore the
    -- outgoing keyboard view. Controller composition is a separate step.
    for key in pairs(target.keyboard) do
        if snapshot.keyboard[key] == nil and not self:write({key}, "") then return false, "keyboard clear rejected" end
    end
    for key, command in pairs(snapshot.keyboard) do
        if not self:write({key}, command) then return false, "keyboard restoration rejected" end
    end
    return true
end
function Native:SaveCharacter()
    if self.api.InCombatLockdown() or self.api.GetCurrentBindingSet() ~= self.api.CharacterSet then return false end
    -- CPAPI.SaveBindings validates the explicit set and returns true/false.
    return self.api.SaveBindings(self.api.CharacterSet) == true
end
