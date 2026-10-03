local _, Addon = ...
local Capability = {}
Addon.Capability = Capability
function Capability.Probe(api)
    local result={modules={}, ready=true, pending={}, guid=api.UnitGUID("player")}
    if not result.guid then result.ready=false result.pending[#result.pending+1]="player GUID unavailable" end
    local version,build,_,interface = api.GetBuildInfo()
    result.game={version=version,build=build,interface=interface}
    for _,name in ipairs({"ConsolePort","ConsolePort_Bar","ConsolePort_Menu","ConsolePort_Cursor","ConsolePort_Rings","ConsolePort_Config","Immersion"}) do
        local installed = api.C_AddOns.GetAddOnInfo(name) ~= nil
        local loaded = installed and api.C_AddOns.IsAddOnLoaded(name) or false
        local enableState = installed and api.C_AddOns.GetAddOnEnableState(name,api.UnitName("player")) or 0
        local enabled = type(enableState)=="number" and enableState>0 or false
        result.modules[name]={installed=installed,enabled=enabled,loaded=loaded,
            version=installed and api.C_AddOns.GetAddOnMetadata(name,"Version") or nil}
        if name=="ConsolePort" or name=="ConsolePort_Bar" then
            if not loaded or not enabled then result.ready=false result.pending[#result.pending+1]=name.." not enabled/loaded" end
        end
    end
    local set=api.GetCurrentBindingSet()
    if set~=api.AccountSet and set~=api.CharacterSet then result.ready=false result.pending[#result.pending+1]="binding set not initialized" end
    result.bindingSet=set
    return result
end
