-- Offline candidate only. Not loaded by any addon TOC.
-- A borrowed native pooled button is safe only while its identity is current.
-- This conservative candidate disables on BOTH combat transitions and requires
-- public reconciliation outside combat before enabling again.
local _,Addon=...
local Proxy={}
Addon.FollowerProxyPrototype=Proxy
local CLEAR_ON_COMBAT_TRANSITION=[[
    self:SetAttribute('typerelease',nil)
    self:SetAttribute('clickbutton',nil)
]]
function Proxy.New(api)
    local name='CPFOfflineFollowerProxy'
    if api.find(name) then return nil,'name already owned' end
    if api.combat() then return nil,'combat' end
    local frame=api.create(name)
    frame:SetAttribute('pressAndHoldAction',true)
    frame:SetAttribute('_onstate-follower-combat',CLEAR_ON_COMBAT_TRANSITION)
    api.driver(frame,'follower-combat','[combat] combat; peace')
    return setmetatable({api=api,frame=frame,name=name,script=frame:GetScript('OnClick')},{__index=Proxy})
end
function Proxy:Owns()
    return self.api.find(self.name)==self.frame and self.frame:GetScript('OnClick')==self.script
end
function Proxy:Entry()
    return {type='custom',binding='CLICK '..self.name..':LeftButton',autoassigned=true}
end
function Proxy:Find()
    local context=self.api.context()
    if not self.api.public(context) or context~=true then return nil,'context unavailable' end
    local selected
    for _,frame in ipairs(self.api.pool()) do
        if frame:GetScript('OnClick')==self.api.nativeClick then
            local ok,id=pcall(frame.GetSpellID,frame)
            if ok and self.api.public(id) and type(id)=='number' and id==426756 then
                if selected then return nil,'ambiguous native buttons' end
                selected=frame
            end
        end
    end
    return selected,selected and 'native delegate' or 'native button unavailable'
end
function Proxy:Refresh()
    if not self:Owns() then return false,'proxy owner changed' end
    if self.api.combat() then return false,'combat; secure driver owns disable' end
    self.frame:SetAttribute('typerelease',nil)
    self.frame:SetAttribute('clickbutton',nil)
    local ok,delegate,reason=pcall(self.Find,self)
    if not ok or not delegate then return false,ok and reason or 'native read rejected' end
    self.frame:SetAttribute('clickbutton',delegate)
    self.frame:SetAttribute('typerelease','click')
    return true,reason
end
