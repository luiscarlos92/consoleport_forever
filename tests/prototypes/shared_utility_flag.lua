-- Standalone offline flag contract. No addon TOC entry or runtime command.
local _,Addon=...
local Flag={}
local sessions=setmetatable({},{__mode='k'})
Addon.SharedUtilityFlagPrototype=Flag

function Flag.Enabled(account)
    if type(account)~='table' then return false end
    return account.sharedUtilityEnabled==true
end

-- Called only after native eligibility/import qualification, not during module
-- parsing. An explicit false survives subsequent first-use and reload checks.
function Flag.FirstEligibleUse(account)
    if type(account)~='table' then return false,'invalid account' end
    if account.sharedUtilityEnabled==nil then account.sharedUtilityEnabled=true end
    return Flag.Enabled(account)
end

-- Deliberately independent of feature construction, archive schema, GUID/spec,
-- ring readiness, protected dispatch and any feature-owned method.
function Flag.Command(account,command)
    if type(account)~='table' then return false,'invalid account' end
    if command=='off' then account.sharedUtilityEnabled=false
    elseif command=='on' then account.sharedUtilityEnabled=true
    elseif command~='status' then return false,'use off, on or status' end
    return true,Flag.Enabled(account)
end

function Flag.TryStart(account,eligible,factory)
    if eligible~=true or not Flag.FirstEligibleUse(account) then return nil,'disabled or ineligible' end
    local session=sessions[account]
    if session then return session.feature,session.reason end
    session={} sessions[account]=session
    local ok,feature=pcall(factory)
    if not ok then session.reason='feature initialization rejected' return nil,session.reason end
    session.feature=feature
    return feature
end
