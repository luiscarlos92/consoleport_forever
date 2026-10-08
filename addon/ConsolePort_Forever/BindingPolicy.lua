local _, Addon = ...
local Core, Policy = Addon.Core, {}
Addon.BindingPolicy = Policy
local buttons = {"PAD1", "PAD2", "PAD3", "PAD4", "PADDLEFT", "PADDUP", "PADDRIGHT", "PADDDOWN"}
local modifiers = {"", "SHIFT-", "CTRL-", "CTRL-SHIFT-"}
function Policy.Scope(key)
    if key=='CTRL-PADRSHOULDER' or key=='SHIFT-PADLSHOULDER' then return 'character' end
    for _, modifier in ipairs(modifiers) do
        for index, button in ipairs(buttons) do
            if key == modifier .. button then
                return modifier == "" and index <= 4 and "shared" or "character"
            end
        end
    end
    return "retained"
end
function Policy.Compose(shared, personal, retained)
    local result = Core.Copy(retained or {})
    if personal['CTRL-PADRSHOULDER']~=nil then result['CTRL-PADRSHOULDER']=personal['CTRL-PADRSHOULDER'] end
    if personal['SHIFT-PADLSHOULDER']~=nil then result['SHIFT-PADLSHOULDER']=personal['SHIFT-PADLSHOULDER'] end
    for _, modifier in ipairs(modifiers) do
        for _, button in ipairs(buttons) do
            local key = modifier .. button
            local source = Policy.Scope(key) == "shared" and shared or personal
            if source[key] ~= nil then result[key] = source[key] end
        end
    end
    return result
end
function Policy.Split(current)
    local scopes = {shared = {}, character = {}, retained = {}}
    for key, command in pairs(current) do scopes[Policy.Scope(key)][key] = command end
    return scopes
end
