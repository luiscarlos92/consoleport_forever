local _, Addon = ...
local Core, Plan = Addon.Core, {}
Addon.Plan = Plan

-- Every field has an explicit scope, stable id, path, and encoded value.
-- Missing baseline differs from a baseline whose value is nil.
function Plan.Build(current, baselines, proposals, reviews)
    local result = {operations = {}, conflicts = {}, noops = {}, deferred = {}}
    for order, field in ipairs(proposals) do
        local now = Core.Read(assert(current[field.scope], "unknown scope"), field.path)
        local old = baselines[field.id]
        local proposed = Core.Copy(field.value)
        local entry = {id = field.id, scope = field.scope, path = Core.Copy(field.path),
                       before = now, value = proposed, revision = field.revision,label=field.label,order=order}
        local review = reviews and reviews[field.id]
        if field.deferred then
            entry.reason = field.deferred
            table.insert(result.deferred, entry)
        elseif Core.Equal(now, proposed) then
            entry.reason = "converged"
            table.insert(result.noops, entry)
        elseif review and review.decision == "keep" and review.revision == field.revision
            and Core.Equal(review.proposed, proposed) and Core.Equal(review.current, now) then
            entry.reason = "reviewed keep"
            table.insert(result.noops, entry)
        elseif old and Core.Equal(now, old.value) then
            table.insert(result.operations, entry)
        elseif old and Core.Equal(old.value, proposed) then
            entry.reason = "preserved manual edit"
            table.insert(result.noops, entry)
        else
            entry.reason = old and "competing manual edit" or "new field ownership"
            table.insert(result.conflicts, entry)
        end
    end
    return result
end

function Plan.Accept(plan, resolutions)
    local accepted = {}
    for _,entry in ipairs(plan.operations) do
        if not resolutions or resolutions[entry.id]~="keep" then accepted[#accepted+1]=Core.Copy(entry) end
    end
    for _, entry in ipairs(plan.conflicts) do
        local decision = resolutions and resolutions[entry.id]
        if decision == "accept" then table.insert(accepted, Core.Copy(entry))
        elseif decision ~= "keep" then return nil, "unresolved conflict: " .. entry.id end
    end
    -- Preparation/selection and reverse restore fields must retain the reviewed
    -- sequence even when some are ordinary operations and others are conflicts.
    local ordered=true
    for _,entry in ipairs(accepted) do if not entry.order then ordered=false break end end
    if ordered then table.sort(accepted,function(a,b) return a.order<b.order end) end
    return accepted
end
