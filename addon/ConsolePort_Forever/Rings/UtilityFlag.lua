-- Keep the escape hatch independent of feature construction and normal setup.
local _,Addon=...
local Flag={sessions=setmetatable({},{__mode='k'})}
Addon.UtilityFlag=Flag
function Flag.Enabled(account)
    return type(account)=='table' and (account.sharedUtilityEnabled==nil or account.sharedUtilityEnabled==true)
end
function Flag.Start(account,eligible,factory)
    if eligible~=true or not Flag.Enabled(account) then return nil,'disabled or ineligible' end
    if account.sharedUtilityEnabled==nil then account.sharedUtilityEnabled=true end
    local session=Flag.sessions[account]
    if session then return session.feature,session.reason end
    session={} Flag.sessions[account]=session
    local ok,feature,reason=pcall(factory)
    if ok then session.feature=feature session.reason=reason
    else session.reason='initialization rejected; disable with /cpfutility off, then /reload' end
    return session.feature,session.reason
end
function Flag.Command(account,command)
    if type(account)~='table' then return false,'account storage is unavailable' end
    if command=='off' then account.sharedUtilityEnabled=false
    elseif command=='on' then account.sharedUtilityEnabled=true
    elseif command~='status' then return false,'Use /cpfutility off, on or status.' end
    return true,Flag.Enabled(account)
end
local function say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cff69ccf0ConsolePort Forever:|r '..message) end
end
SLASH_CPFUTILITY1='/cpfutility'
SlashCmdList.CPFUTILITY=function(input)
    local command=(input or ''):match('^%s*(%S*)'):lower()
    if command=='' then command='status' end
    ConsolePortForeverDB=ConsolePortForeverDB or {}
    local ok,enabled=Flag.Command(ConsolePortForeverDB,command)
    if not ok then say(enabled) return end
    if command=='off' then
        local feature=Addon.utilityRuntime
        if feature then pcall(feature.Disable,feature) end
        if Addon.RegisterUtilityEvents then Addon:RegisterUtilityEvents() end
        say('Shared utility disabled. Run /reload to restore native handling. Saved shared choices are retained.')
    elseif command=='on' then say('Shared utility enabled for next startup. Run /reload.')
    else
        local feature=Addon.utilityRuntime
        local session=Flag.sessions[ConsolePortForeverDB]
        say('Shared utility '..(enabled and 'enabled' or 'disabled')..'; '..
            (feature and feature:Status() or (session and session.reason or 'waiting for native readiness')))
    end
end
