local _,Addon=...
local Core,Reference=Addon.Core,{}
Addon.EditModeReference=Reference
function Reference:Capture(owner,api)
    if owner.busy or not owner:IsCharacterInstalled() or api.InCombatLockdown()
        or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown()) then return false,'saved layout capture deferred' end
    local adapter=owner.adapters and owner.adapters.editmode
    if not adapter then return false,'native saved layouts unavailable' end
    local ok,snapshot=pcall(adapter.Capture,adapter)
    if not ok or not snapshot then return false,'native saved layout capture unavailable' end
    local active={layout=Core.Copy(snapshot.active),export=snapshot.export,activeLayout=snapshot.activeLayout,
        source='native-saved-layout'}
    if not Core.Equal(owner.record.knownEditModeActive,active) then owner.record.knownEditModeActive=active end
    -- The named, already-owned account copy is the default reference, even
    -- while another character experiments in a different active layout.
    local managedName=owner.db.shared.managedEditModeName
    local layout
    for _,candidate in ipairs(snapshot.layouts) do
        if managedName and candidate.layoutName==managedName and candidate.layoutType==adapter.api.AccountType then
            if layout then return false,'ambiguous managed layout reference' end
            layout=candidate
        end
    end
    if layout then
        local exported,value=pcall(adapter.api.ConvertLayoutInfoToString,layout)
        if not exported or type(value)~='string' or value=='' then return false,'native managed layout export unavailable' end
        local current={layout=Core.Copy(layout),export=value,source='native-saved-layout'}
        if not Core.Equal(owner.db.shared.knownEditModeDefault,current) then owner.db.shared.knownEditModeDefault=current end
    end
    return true,'latest saved layout retained; no layout save or selection change'
end
function Reference:Refresh(owner,api)
    local frame=api.EditModeManagerFrame
    self.hooked=self.hooked or setmetatable({},{__mode='k'})
    if frame and type(frame.HookScript)=='function' and not self.hooked[frame] then
        self.hooked[frame]=true
        frame:HookScript('OnHide',function()
            api.C_Timer.After(0,function() self:Capture(owner,api) end)
        end)
    end
    local captured,reason=self:Capture(owner,api)
    if not owner.db.shared.knownEditModeDefault and owner:IsCharacterInstalled() and not owner.busy
        and not api.InCombatLockdown() and not (frame and frame:IsShown()) then
        owner.db.shared.knownEditModeDefault=Core.Copy(Addon.SavedEditModeReference)
    end
    return captured,reason
end
