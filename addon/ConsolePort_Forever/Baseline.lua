local _, Addon = ...
local Core, Baseline = Addon.Core, {}
Addon.Baseline = Baseline
function Baseline.Capture(adapters, fields)
    local current,errors={},{}
    for _,field in ipairs(fields) do
        current[field.scope]=current[field.scope] or {}
        local adapter=adapters[field.scope]
        local ok,value=false,nil
        if adapter then ok,value=pcall(adapter.read,adapter,field.path) end
        if ok then Core.Write(current[field.scope],field.path,Core.Encode(value))
        else errors[#errors+1]={id=field.id,reason=adapter and tostring(value) or "adapter unavailable"} end
    end
    return current,errors
end
