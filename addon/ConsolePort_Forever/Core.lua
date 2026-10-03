local _, Addon = ...
local Core = {}
Addon.Core = Core

-- A serializable value, distinguished from false and from no proposal.
Core.NIL = {__cpfNil = true}
function Core.IsNil(value)
    if type(value) ~= "table" or value.__cpfNil ~= true then return false end
    for key in pairs(value) do if key ~= "__cpfNil" then return false end end
    return true
end
function Core.Copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do copy[Core.Copy(key, seen)] = Core.Copy(item, seen) end
    return copy
end
function Core.Equal(a, b, seen)
    if a == b then return true end
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    seen = seen or {}
    if seen[a] == b then return true end
    seen[a] = b
    for key, value in pairs(a) do if not Core.Equal(value, b[key], seen) then return false end end
    for key in pairs(b) do if a[key] == nil then return false end end
    return true
end
function Core.Replace(target, source)
    assert(type(target) == "table" and type(source) == "table", "table replacement required")
    for key in pairs(target) do if source[key] == nil then target[key] = nil end end
    for key, value in pairs(source) do
        if type(value) == "table" and type(target[key]) == "table" then Core.Replace(target[key], value)
        else target[key] = Core.Copy(value) end
    end
    return target
end
function Core.Encode(value)
    if value == nil then return Core.Copy(Core.NIL) end
    return Core.Copy(value)
end
function Core.Decode(value)
    if Core.IsNil(value) then return nil end
    return Core.Copy(value)
end
function Core.Read(root, path)
    local value = root
    for _, key in ipairs(path) do
        if type(value) ~= "table" then return Core.Encode(nil) end
        value = value[key]
    end
    return Core.Encode(value)
end
function Core.Write(root, path, value)
    assert(#path > 0, "empty field path")
    for index = 1, #path - 1 do
        local key = path[index]
        if root[key] == nil then root[key] = {} end
        assert(type(root[key]) == "table", "field parent is not a table")
        root = root[key]
    end
    root[path[#path]] = Core.Decode(value)
end
