local _, Addon = ...
local Core, Modes = Addon.Core, {}
Addon.ModePolicy = Modes
local temporary = {vehicle=true, override=true, temporary=true, skyriding=true, possess=true}
-- Pure semantic model. The secure driver must provide native family/page
-- evidence; mount/form/flight status is deliberately not a takeover signal.
function Modes.Resolve(ordinary, state)
    local resolved = Core.Copy(ordinary)
    local pending = {}
    if temporary[state.family] then
        if type(state.cells) ~= "table" then return resolved, {"temporary contents unavailable"} end
        resolved.L2R2 = {}
        for index = 1, 8 do resolved.L2R2[index] = Core.Copy(state.cells[index]) end
        if #state.cells > 8 then pending[#pending + 1] = "temporary actions exceed eight; retain native access" end
        if state.exitOutside then pending[#pending + 1] = "vehicle exit remains on native route" end
    end
    return resolved, pending
end
