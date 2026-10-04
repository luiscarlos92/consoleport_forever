local _,Addon=...
local Integrations={}
Addon.FlatIntegrations=Integrations
local definitions={
    immersion={addon='Immersion',version='1.4.61',variable='ImmersionSetup',types={
        number='scale titlescale titleoffset titleoffsetY elementscale boxscale boxoffsetX boxoffsetY delaydivisor anidivisor ttsrate ttsvolume ttsvoice ttsmalevoice ttsfemalevoice',
        string='strata boxpoint inspect',
        boolean='hideui boxlock titlelock disableprogression flipshortcuts ttsenabled showprogressbar immersivemode hideminimap hidetracker hidetooltip onthefly supertracked movetalkinghead enablenumbers solidbackground disablebgtextures disableglowani disableportrait disableanisequence disableboxhighlight gossipatcursor',
        binding='accept goodbye reset padaccept padinspect padnext padgoodbye padup paddown padleft padright'}},
    extrafade={addon='Immersion_ExtraFade',version='1.18.0',variable='IEF_Config',types={
        number='trackingBarAlpha',
        boolean='keepAlertFrames keepChatFrame keepPartyRaidFrame keepTrackingBar keepCustomFrames hideNpcPortrait hideFrameRate hideFrameRateCinematic',
        frameMap='customFramesToKeep'}},
}
function Integrations.Types(kind)
    local types={}
    for shape,keys in pairs(assert(definitions[kind]).types) do for key in keys:gmatch('%S+') do types[key]=shape end end
    return types
end
local function valid(value,shape,api)
    if api.issecretvalue and api.issecretvalue(value) then return false end
    if value==nil then return true end
    if shape=='binding' then return type(value)=='string' or value==false end
    if shape=='frameMap' then
        if type(value)~='table' or getmetatable(value) then return false end
        for key,enabled in pairs(value) do
            if type(key)~='string' or type(enabled)~='boolean' or (api.issecretvalue and (api.issecretvalue(key) or api.issecretvalue(enabled))) then return false end
        end
        return true
    end
    return type(value)==shape and (shape~='number' or (value==value and value>-math.huge and value<math.huge))
end
function Integrations.New(kind,api)
    local definition=assert(definitions[kind])
    if api.C_AddOns.GetAddOnMetadata(definition.addon,'Version')~=definition.version then return nil,'audited '..definition.addon..' '..definition.version..' required' end
    if not api.C_AddOns.IsAddOnLoaded(definition.addon) or type(api[definition.variable])~='table' then return nil,definition.addon..' settings not initialized' end
    local live,allowed,pending=api[definition.variable],{},{}
    local types=Integrations.Types(kind)
    for key,shape in pairs(types) do
        if live[key]~=nil then
            if valid(live[key],shape,api) then allowed[key]=true
            else pending[#pending+1]=definition.addon..' '..key..' has an unsupported value' end
        end
    end
    -- Capture explicit current data only. Native missing/default values, theme
    -- fonts, unknown fields and ExtraFade's transient UIParentAlpha are retained
    -- without adopting them as companion settings. Flat restores need Reload.
    local adapter=Addon.FlatConfigAdapter.New(function()
        if api.C_AddOns.GetAddOnMetadata(definition.addon,'Version')~=definition.version then error('integration version changed') end
        local current=api[definition.variable]
        if current~=live then error('integration settings table replaced; refresh readiness before review') end
        return current
    end,allowed,api.InCombatLockdown)
    adapter.pending=pending adapter.reloadRequired=true
    adapter.validate=function(path,value) return valid(value,types[path[1]],api) end
    return adapter
end
