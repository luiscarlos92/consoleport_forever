local _, Addon = ...
local Diagnostics = {limit=80, entries={}, features={}}
Addon.Diagnostics = Diagnostics
function Diagnostics:Persist()
    -- Bounded last-session evidence for read-only WTF audits. This is runtime
    -- bookkeeping, never proof that a controller or protected action passed.
    if not Addon.record or not Addon.Core then return end
    Addon.record.lastRuntimeDiagnostics = {
        codeVersion=Addon.VERSION, configRevision=Addon.CONFIG_REVISION,
        features=Addon.Core.Copy(self.features), entries=Addon.Core.Copy(self.entries),
        visuals=Addon.Core.Copy(self.visuals or {}),
        ping=Addon.Core.Copy(self.ping or {}),
    }
end
function Diagnostics:Log(kind, message)
    self.entries[#self.entries+1] = {kind=kind, message=tostring(message)}
    if #self.entries > self.limit then table.remove(self.entries,1) end
    self:Persist()
end
function Diagnostics:SetFeature(id, status, reason)
    self.features[id] = {status=status, reason=reason}
    self:Persist()
end
function Diagnostics:Summary()
    local lines={}
    for id,feature in pairs(self.features) do lines[#lines+1] = id .. ": " .. feature.status .. (feature.reason and " ("..feature.reason..")" or "") end
    table.sort(lines)
    return table.concat(lines,"\n")
end
