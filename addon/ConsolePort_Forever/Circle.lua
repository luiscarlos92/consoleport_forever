local _,Addon=...
local Circle={NAME='ConsolePortForeverCircleCancel'}
Addon.CircleCancel=Circle
Circle.BINDING='CLICK '..Circle.NAME..':LeftButton'
-- A direct native secure click, never Escape or an insecure /run callback.
-- Retail exposes no qualified first-success result branch to addon snippets.
-- This deliberately cancels all three states; it does not claim exact parity.
Circle.MACRO='/stopmacro [mod]\n/stopcasting\n/stopspelltarget\n/cleartarget'

function Circle:Prepare(api)
    if type(api.CreateFrame)~='function' or type(api.InCombatLockdown)~='function'
        or type(api.SecureActionButton_OnClick)~='function'
        or not api.C_Macro or type(api.C_Macro.RunMacroText)~='function' then
        return false,'native secure click/macro dispatcher unavailable'
    end
    local current=api[self.NAME]
    if current and current~=self.frame then return false,'Circle frame name belongs to another owner' end
    if self.frame then
        local frame=self.frame
        if current~=frame or frame:GetScript('OnClick')~=api.SecureActionButton_OnClick
            or frame:GetAttribute('type')~='macro' or frame:GetAttribute('macrotext')~=self.MACRO
            or frame:GetAttribute('useOnKeyDown')~=true then
            return false,'Circle native frame contract changed; no overwrite'
        end
        return true,'native cancel-all click prepared; exact first-success parity remains gated'
    end
    if api.InCombatLockdown() or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown()) then
        return false,'Circle preparation waits for combat/Edit Mode to end'
    end
    local frame=api.CreateFrame('Button',self.NAME,api.UIParent,'SecureActionButtonTemplate')
    frame:SetSize(1,1) frame:SetPoint('TOPLEFT',api.UIParent,'TOPLEFT') frame:EnableMouse(false)
    frame:RegisterForClicks('AnyDown','AnyUp')
    frame:SetAttribute('type','macro') frame:SetAttribute('macrotext',self.MACRO)
    frame:SetAttribute('useOnKeyDown',true)
    frame:SetScript('OnClick',api.SecureActionButton_OnClick)
    self.frame=frame
    return true,'native cancel-all click prepared; exact first-success parity remains gated'
end

-- Only configuration review may offer the new command. Hydration never calls
-- this helper, so a later manual removal/empty binding is not restored.
function Circle.Proposal(state)
    local proposed=Addon.Core.Copy(state)
    if proposed.keys.PAD2~='' then return proposed,false end
    proposed.keys.PAD2=Circle.BINDING
    return proposed,true
end

function Circle:Refresh(api,installed)
    if not installed then return false,'character configuration not installed' end
    local ready,reason=self:Prepare(api)
    Addon.Diagnostics:SetFeature('circleCancel',ready and 'offline-verified' or 'pending',reason)
    return ready,reason
end
