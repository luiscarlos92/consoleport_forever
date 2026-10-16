-- Follower-specific compilation and cosmetics. Native ring input/secure spell
-- dispatch, LAB feedback and authoritative saved entries retain their owners.
local _,Addon=...
local Follower,ID={},426756
Addon.FollowerDungeon=Follower
local function public(api,value) return not (api.issecretvalue and api.issecretvalue(value)) end
local function call(fn,...)
    if type(fn)~='function' then return end
    local ok,value=pcall(fn,...)
    if ok then return value end
end
function Follower.New(env,api,enabled,blocked)
    if type(env.GetKindAndAction)~='function' or not env.Frame or type(env.Frame.AddSecureAction)~='function'
        or type(env.Frame.ClearAllActions)~='function' or not api.C_PartyInfo or type(api.C_PartyInfo.IsPartyInFollowerDungeon)~='function'
        or not api.C_ZoneAbility or type(api.C_ZoneAbility.GetActiveAbilities)~='function'
        or type(api.C_ZoneAbility.GetZoneAbilityIcon)~='function' or not api.C_Spell
        or type(api.C_Spell.GetSpellName)~='function' or not api.C_SpellBook
        or type(api.C_SpellBook.FindSpellOverrideByID)~='function'
        or type(api.hooksecurefunc)~='function' or blocked() or not enabled() then return end
    local self=setmetatable({env=env,frame=env.Frame,api=api,enabled=enabled,blocked=blocked,
        views=setmetatable({},{__mode='k'}),hidden={},counts={workers=0,compiles=0,icons=0}}, {__index=Follower})
    self.beforeMap,self.beforeAdd=env.GetKindAndAction,env.Frame.AddSecureAction
    self:ReadContext()
    self.map=function(owner,info)
        local kind,action,extra=self.beforeMap(owner,info)
        if self:Owns() and self.active and self.name and (self.set==1 or self.set=='1')
            and type(info)=='table' and public(api,info.type) and info.type=='spell'
            and public(api,info.spell) and info.spell==ID and public(api,kind) and kind=='spell'
            and public(api,extra) and extra==nil then
            local route={}
            route.spell=self.name -- secure CastSpellByName route; LAB keeps ID.
            self.mapped=true
            return kind,action,route
        end
        return kind,action,extra
    end
    self.add=function(owner,set,index,info)
        local previous,previousMapped=self.set,self.mapped
        self.set,self.mapped=set,false
        local ok,result=pcall(self.beforeAdd,owner,set,index,info)
        local mapped=self.mapped
        self.set,self.mapped=previous,previousMapped
        if not ok then error(result) end
        if mapped then self.compiled=true self.counts.compiles=self.counts.compiles+1 end
        self:Queue(false)
        return result
    end
    env.GetKindAndAction=self.map env.Frame.AddSecureAction=self.add
    api.hooksecurefunc(self.frame,'ClearAllActions',function() self.compiled=false self:Queue(false) end)
    self.frame:HookScript('OnHide',function() self:Queue(false) end)
    env:RegisterCallback('OnButtonUpdated',function(_,button) self:View(button) self:Queue(false) end,self)
    self.events=api.CreateFrame('Frame')
    self.events:SetScript('OnEvent',function(_,event,arg)
        if event=='UNIT_AURA' and (not public(api,arg) or arg~='player') then return end
        if event=='ADDON_LOADED' and arg~='Blizzard_ZoneAbility' then return end
        self:Queue(event~='UNIT_AURA' and event~='SPELL_UPDATE_COOLDOWN' and event~='SPELL_UPDATE_CHARGES' and event~='SPELL_UPDATE_USABLE')
    end)
    for _,event in ipairs({'PLAYER_ENTERING_WORLD','ZONE_CHANGED_NEW_AREA','SPELLS_CHANGED',
        'PLAYER_REGEN_ENABLED','ADDON_LOADED'}) do self.events:RegisterEvent(event) end
    if api.EventRegistry and type(api.EventRegistry.RegisterCallback)=='function' then
        for _,event in ipairs({'EditMode.Enter','EditMode.Exit'}) do
            api.EventRegistry:RegisterCallback(event,function() self:Queue(false) end,self)
        end
    end
    self:Listen() self:HookZone() self:Queue(true)
    return self
end
function Follower:Owns()
    return self.enabled() and self.env.Frame==self.frame and self.env.GetKindAndAction==self.map
        and self.frame.AddSecureAction==self.add
end
function Follower:ReadContext()
    local api=self.api
    local inside=call(api.C_PartyInfo.IsPartyInFollowerDungeon)
    local abilities=call(api.C_ZoneAbility.GetActiveAbilities)
    local active=false
    if public(api,inside) and inside==true and public(api,abilities) and type(abilities)=='table' then
        for _,info in ipairs(abilities) do
            if public(api,info) and type(info)=='table' and public(api,info.spellID) and info.spellID==ID then active=true break end
        end
    end
    local name=call(api.C_Spell.GetSpellName,ID)
    if not public(api,name) or type(name)~='string' or name=='' or tonumber(name) then name=nil end
    local changed=self.active~=active or self.name~=name
    self.active,self.name=active,name
    return changed
end
function Follower:Listen()
    if not self.events then return end
    local wanted=self.active and self:Owns()
    if self.listening==wanted then return end
    self.listening=wanted
    if wanted then self.events:RegisterUnitEvent('UNIT_AURA','player')
    else self.events:UnregisterEvent('UNIT_AURA') end
    for _,event in ipairs({'SPELL_UPDATE_COOLDOWN','SPELL_UPDATE_CHARGES','SPELL_UPDATE_USABLE'}) do
        if wanted then self.events:RegisterEvent(event) else self.events:UnregisterEvent(event) end
    end
end
function Follower:Queue(context)
    self.contextPending=self.contextPending or context
    if self.queued then return end
    self.queued=true
    self.api.C_Timer.After(0,function()
        self.queued=false self.counts.workers=self.counts.workers+1
        local reconcile=self.contextPending self.contextPending=false
        if reconcile then
            local changed=self:ReadContext()
            if changed then self.recompile=true end
        end
        self:Listen()
        self:HookZone()
        if self.recompile and self:Owns() and not self.blocked() then
            self.recompile=false
            self.frame:RefreshAll()
        end
        self:Cosmetics()
    end)
end
function Follower:Matches(button)
    if not self:Owns() or not self.active or button:GetParent()~=self.frame then return false end
    local set=self.frame:GetAttribute('state')
    local kind,spell=button:GetStateType(),button:GetStateAction()
    return public(self.api,set) and (set==1 or set=='1') and public(self.api,kind) and kind=='spell'
        and public(self.api,spell) and tonumber(spell)==ID
end
function Follower:Icon()
    local api=self.api
    local override=call(api.C_SpellBook.FindSpellOverrideByID,ID)
    if override==nil then override=ID end
    if not public(api,override) or type(override)~='number' then return end
    local icon=call(api.C_ZoneAbility.GetZoneAbilityIcon,override)
    if public(api,icon) and type(icon)=='number' and icon>0 then return icon end
end
function Follower:View(button)
    if not button or button:GetParent()~=self.frame or not button.icon or self.views[button] then return end
    local icon=button.icon
    local view={before=icon.SetTexture}
    view.write=function(region,texture,...)
        if region.SetTexture==view.write and type(texture)~='function' and self:Matches(button) then
            texture=self:Icon() or texture
        end
        return view.before(region,texture,...)
    end
    icon.SetTexture=view.write self.views[button]=view
end
function Follower:HookZone()
    local zone=self.api.ZoneAbilityFrame
    if zone==self.zone then return end
    self.zone=zone
    if zone and type(zone.UpdateDisplayedZoneAbilities)=='function' then
        self.api.hooksecurefunc(zone,'UpdateDisplayedZoneAbilities',function() self:Queue(true) end)
    end
end
function Follower:Cosmetics()
    for button,view in pairs(self.views) do
        if button.icon.SetTexture==view.write and button:IsShown() and type(button.GetTexture)=='function' then
            button.icon:SetTexture(button:GetTexture()) self.counts.icons=self.counts.icons+1
        end
    end
    local zone=self.zone
    local container=zone and zone.SpellButtonContainer
    if not container or type(container.EnumerateActive)~='function' then return end
    local active,targets,count={}, {},0
    for button in container:EnumerateActive() do
        active[button]=true count=count+1
        local id=type(button.GetSpellID)=='function' and call(button.GetSpellID,button)
        if public(self.api,id) and id==ID then targets[#targets+1]=button end
    end
    local edit=self.api.EditModeManagerFrame and self.api.EditModeManagerFrame:IsShown()
    local suppress=self:Owns() and self.active and self.compiled and self.name and self:Icon()~=nil and not edit and #targets==1
    local target=suppress and targets[1]
    if target and target:IsProtected() then target=nil end
    for button in pairs(self.hidden) do
        if button~=target then
            local deferred=active[button] and button:IsProtected() and self.api.InCombatLockdown() and not button:IsShown()
            if not deferred then
                if active[button] and not button:IsShown() then button:Show() end
                self.hidden[button]=nil
            end
        end
    end
    if target then
        if target:IsShown() then target:Hide() self.hidden[target]=true end
    end
    local style=zone.Style
    if style then
        if target and count==1 and self.hidden[target] then
            if self.styleAlpha==nil then
                local alpha=style:GetAlpha()
                if public(self.api,alpha) and type(alpha)=='number' then self.styleAlpha=alpha end
            end
            style:SetAlpha(0)
        elseif self.styleAlpha~=nil then
            local alpha=style:GetAlpha()
            if public(self.api,alpha) and alpha==0 then style:SetAlpha(self.styleAlpha) end
            self.styleAlpha=nil
        end
    end
end
