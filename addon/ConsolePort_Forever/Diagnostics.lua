local _, Addon = ...
local Diagnostics = {limit=80, entries={}, features={}}
Addon.Diagnostics = Diagnostics
function Diagnostics:Log(kind, message)
    self.entries[#self.entries+1] = {kind=kind, message=tostring(message)}
    if #self.entries > self.limit then table.remove(self.entries,1) end
end
function Diagnostics:SetFeature(id, status, reason)
    self.features[id] = {status=status, reason=reason}
end
function Diagnostics:Summary()
    local lines={}
    for id,feature in pairs(self.features) do lines[#lines+1] = id .. ": " .. feature.status .. (feature.reason and " ("..feature.reason..")" or "") end
    table.sort(lines)
    return table.concat(lines,"\n")
end
