-- Offline cosmetic experiment only; no dispatch, hidden controls or TOC load.
local _,Addon=...
local Presentation={}
Addon.FollowerPresentationPrototype=Presentation
function Presentation.New(button,api)
    local icon=button.icon
    local before=icon.SetTexture
    local view={button=button,icon=icon,before=before,api=api}
    view.write=function(region,texture,...)
        if region.SetTexture==view.write and api.matches(button) and type(texture)~='function' then
            local ok,value=pcall(api.zoneIcon,426756)
            if ok and api.public(value) and (type(value)=='number' or type(value)=='string') then
                texture=value
            end
        end
        return before(region,texture,...)
    end
    icon.SetTexture=view.write
    return setmetatable(view,{__index=Presentation})
end
function Presentation:Refresh()
    if self.icon.SetTexture~=self.write then return false end
    self.icon:SetTexture(self.button:GetTexture())
    return true
end
function Presentation:Abort()
    if self.icon.SetTexture==self.write then self.icon.SetTexture=self.before return true end
    return false
end
