local _,Addon=...
local Core,Party=Addon.Core,{}
Addon.PartyLayout=Party
function Party.Contract(api)
    local enum=api.Enum or {}
    local system,indices,settings=enum.EditModeSystem,enum.EditModeUnitFrameSystemIndices,enum.EditModeUnitFrameSetting
    local party,raid=api.PartyFrame,api.CompactRaidFrameContainer
    if not system or not indices or not settings or not system.UnitFrame or not indices.Party or not indices.Raid
        or not settings.UseHorizontalGroups or not settings.UseRaidStylePartyFrames
        or not party or not raid or party.system~=system.UnitFrame or raid.system~=system.UnitFrame
        or party.systemIndex~=indices.Party or raid.systemIndex~=indices.Raid
        or type(party.GetName)~='function' or type(raid.GetName)~='function'
        or party:GetName()~='PartyFrame' or raid:GetName()~='CompactRaidFrameContainer' then
        return nil,'native Party/Raid Edit Mode frame contract unavailable'
    end
    return {system=system.UnitFrame,party=indices.Party,raid=indices.Raid,
        horizontal=settings.UseHorizontalGroups,raidStyle=settings.UseRaidStylePartyFrames,
        partyName=party:GetName(),raidName=raid:GetName()}
end
function Party.Proposal(snapshot,api,managedName)
    local contract=api.partyContract
    if not contract then return nil,'native Party/Raid Edit Mode frame contract unavailable' end
    local index=snapshot.activeLayout-snapshot.presetCount
    if managedName then
        local found
        for saved,layout in ipairs(snapshot.layouts) do
            if layout.layoutName==managedName then
                if found then return nil,'duplicate managed Edit Mode layout identity' end
                found=saved
            end
        end
        if not found then return nil,'managed Edit Mode layout identity unavailable' end
        index=found
    end
    if index<1 or not snapshot.layouts[index] then return nil,'managed saved Edit Mode layout unavailable' end
    local result=Core.Copy(snapshot)
    local layout=result.layouts[index]
    local party,raid
    for _,info in ipairs(layout.systems or {}) do
        if info.system==contract.system then
            if info.systemIndex==contract.party then
                if party then return nil,'duplicate native Party frame record' end
                party=info
            elseif info.systemIndex==contract.raid then
                if raid then return nil,'duplicate native Raid frame record' end
                raid=info
            end
        end
    end
    if not party or not raid or type(party.settings)~='table' then return nil,'native Party/Raid layout records unavailable' end
    for _,anchor in pairs({raid.anchorInfo,raid.anchorInfo2}) do
        if anchor.relativeTo==contract.partyName or anchor.relativeTo=='CompactPartyFrame' then
            return nil,'Raid is anchored to Party; native anchor cycle retained for review'
        end
    end
    local function setting(id,value)
        local found
        for _,entry in ipairs(party.settings) do
            if entry.setting==id then
                if found then return false end
                found=entry
            end
        end
        if found then found.value=value else party.settings[#party.settings+1]={setting=id,value=value} end
        return true
    end
    if not setting(contract.horizontal,0) or not setting(contract.raidStyle,1) then return nil,'duplicate native Party orientation/style setting' end
    -- Use the native frame relationship, rather than copying screenshot pixels.
    -- Only Party changes: the current Raid position and other experiments remain.
    party.anchorInfo={point='TOPLEFT',relativeTo=contract.raidName,relativePoint='BOTTOMLEFT',offsetX=0,offsetY=-8}
    party.anchorInfo2=nil
    party.isInDefaultPosition=false
    if index==snapshot.activeLayout-snapshot.presetCount then result.active=layout end
    result.export=api.ConvertLayoutInfoToString(result.active)
    if type(result.export)~='string' or result.export=='' then return nil,'native Party layout export rejected' end
    return result
end
