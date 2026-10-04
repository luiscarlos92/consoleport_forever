local _,Addon=...
local Cinematic={}
Addon.Cinematic=Cinematic
Cinematic.GATE='Exact held right-menu duration and authorized skip dispatch are unproved in the pinned Retail cinematic/movie Lua/XML. Native menu/confirmation access is retained; no timer skip or invented delay.'
function Cinematic.IsVisible(frame)
    return frame and frame.IsShown and frame:IsShown() and not (frame.IsForbidden and frame:IsForbidden()) or false
end
function Cinematic:Observe(api)
    -- Read-only observation is not permission to invoke any cancellation.
    if self.IsVisible(api.MovieFrame) then return 'movie: native key-up confirmation; held skip pending' end
    if not self.IsVisible(api.CinematicFrame) then return 'no visible native movie/cinematic' end
    local real=api.CinematicFrame.isRealCinematic
    if api.issecretvalue and api.issecretvalue(real) then return 'cinematic eligibility opaque' end
    if real==true then return 'real cinematic: native menu confirmation' end
    local function flag(name)
        if type(api[name])~='function' then return end
        local ok,value=pcall(api[name])
        if ok and not (api.issecretvalue and api.issecretvalue(value)) and type(value)=='boolean' then return value end
    end
    local scene=flag('IsInCinematicScene')
    if scene==true then
        local permitted=flag('CanCancelScene')
        return permitted==true and 'scene: native cancellation permitted; held skip pending'
            or (permitted==false and 'scene: native cancellation forbidden' or 'scene: cancellation eligibility unavailable')
    elseif scene==false then
        local permitted=flag('CanExitVehicle')
        return permitted==true and 'vehicle cinematic: native exit permitted; held skip pending'
            or (permitted==false and 'vehicle cinematic: native exit forbidden' or 'vehicle cinematic: exit eligibility unavailable')
    end
    return 'cinematic: native eligibility APIs unavailable'
end
function Cinematic:Refresh(api)
    local observed=self:Observe(api)
    Addon.Diagnostics:SetFeature('cinematicHold','pending',self.GATE..' '..observed)
    Addon.Diagnostics:SetFeature('exactCircle','pending','One-success stop-cast/stop-targeting/clear-target secure sequencing remains unproved; existing Circle binding retained, without combined cancellation.')
    Addon.Diagnostics:SetFeature('exactStickCommit','pending',Addon.RingSelectors.GATE)
    Addon.Diagnostics:SetFeature('activeEntryCancellation','pending','New class/pet selectors are inactive. Action-specific active-entry cancellation/close-and-continue still needs a separate authorized secure route; no generic cancellation substitute.')
    return observed
end
