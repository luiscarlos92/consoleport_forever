local _,Addon=...
local Routing={}
Addon.TemporaryRouting=Routing
local banks={'Base','L2','R2','L2R2'}
local cells={PAD1=1,PAD2=2,PAD3=3,PAD4=4,PADDLEFT=5,PADDUP=6,PADDRIGHT=7,PADDDOWN=8}
local function scoped(body) return body:gsub('cpf%-','cpf-temp-'):gsub('CPFContentsChanged','CPFTempContentsChanged') end
-- Use the audited native button extension independently of the suspended
-- SecureModes installer. Native Manager/Layers remain the only binding owners.
Routing.Before=scoped(Addon.SecureModes.Before)
    :gsub('local ordinaryPage = GetActionBarPage%(%)%;',[[local ordinaryPage = GetActionBarPage();
    local basePages = self:GetAttribute('cpf-temp-basepages');
    if ordinaryPage <= basePages then self:SetAttribute('cpf-temp-last-main-page',ordinaryPage)
    else ordinaryPage = self:GetAttribute('cpf-temp-last-main-page') or 1 end;
    local bonus = GetBonusBarOffset();
    if bonus > 0 and bonus ~= 5 then ordinaryPage = bonus + basePages end;]])
    :gsub('specialPage = 11',"specialPage = self:GetAttribute('cpf-temp-basepages') + 5")
    :gsub("if special then kind, value = 'action', special end;",[[if special then
        local limit = 12;
        if HasVehicleActionBar() or HasOverrideActionBar()
            or (not HasTempShapeshiftActionBar() and specialPage > self:GetAttribute('cpf-temp-basepages') + 5) then
            limit = self:GetAttribute('cpf-temp-limit')
        end;
        if special <= limit then kind, value = 'action', special else kind, value = 'empty', nil end;
    end;]])
    :gsub("local kind = self:GetAttribute",[[-- Native high pages also cover possession/quest variants whose controller
    -- flags differ. Ordinary main pages and class bonus pages 1-4 stay ordinary.
    if not specialPage then
        local nativePage = self:GetParent():GetAttribute('actionpage');
        if type(nativePage)=='number' and nativePage > self:GetAttribute('cpf-temp-basepages') + 4
            and GetActionBarPage() > self:GetAttribute('cpf-temp-basepages') + 4 then specialPage=nativePage end;
    end;
    local kind = self:GetAttribute]])
Routing.After=scoped(Addon.SecureModes.After)
Routing.PreClick=scoped(Addon.SecureModes.PreClick)
Routing.PostClick=scoped(Addon.SecureModes.PostClick)
Routing.OnHide=scoped(Addon.SecureModes.OnHide)
Routing.PageResponse=[[ self:ChildUpdate('cpf-temp-page', ...) ]]
Routing.ResolvedSpell=[[
    local kind,spellID,subType=GetActionInfo(...);
    if kind=='spell' and subType=='spell' then return spellID end;
]]

function Routing.Environment(button)
    local native=button.__cpfTemporary and button.__cpfTemporary.nativeEnv or button.Env
    if not native or type(native.UpdateState)~='string' or not native.UpdateState:find('ButtonContentsChanged',1,true)
        or not native.UpdateState:find('IsPressHoldReleaseSpell',1,true) then return nil end
    local environment={UpdateState=Routing.Before..native.UpdateState..Routing.After,
        ['_childupdate-cpf-temp-page']=scoped(Addon.SecureModes.ChildResponse)}
    -- Keep drag-to-bind updates in the ordinary model, never the temporary page.
    if native.OnReceiveDrag then
        environment.OnReceiveDrag=native.OnReceiveDrag:gsub('local buttonType, buttonAction =',[[self:SetAttribute('cpf-temp-held',nil)
            self:RunAttribute("UpdateState",state)
            -- A vehicle/quest page may expose fewer cells than the controller
            -- bank. An unavailable temporary cell must not consume a drop or
            -- turn that drop into a permanent ordinary binding.
            if self:GetAttribute('cpf-temp-enabled') and self:GetAttribute('cpf-temp-special-cell')
                and self:GetAttribute('type')=='empty'
                and (self:GetAttribute('actionpage') or 1)>(self:GetAttribute('cpf-temp-basepages') or 6)+4 then return false end;
            local buttonType, buttonAction =]]):gsub('self::UpdateState%(state%)',[[self:SetAttribute('cpf-temp-kind-'..tostring(state), kind)
            self:SetAttribute('cpf-temp-action-'..tostring(state), value)
            self::UpdateState(state)]])
    end
    -- Native removal of a direct spell/item/macro must clear the cached
    -- ordinary model too, or the next UpdateState resurrects that action.
    local dragStart=native.OnDragStart or button:GetAttribute('OnDragStart')
    if dragStart then
        environment.OnDragStart=dragStart:gsub('local type = self:GetAttribute%("type"%)',[[self:SetAttribute('cpf-temp-held',nil)
            self:RunAttribute("UpdateState",state)
            local type = self:GetAttribute("type")]]):gsub('self:RunAttribute%("UpdateState", state%)',[[self:SetAttribute('cpf-temp-kind-'..tostring(state), 'empty')
            self:SetAttribute('cpf-temp-action-'..tostring(state), nil)
            self:RunAttribute("UpdateState", state)]])
    end
    return environment
end
local function ordinaryDriver(value)
    if type(value)~='string' then return value end
    return value:gsub('%[vehicleui%]%[overridebar%]%s*[^;]+;%s*','')
end
function Routing:Probe(bridge,api)
    if not bridge or not bridge.api or bridge.api.version~='3.3.10' then return false,'ConsolePort version not qualified' end
    local ok,reason=bridge:Probe()
    if not ok then return false,reason end
    if not api.CPAPI or not api.hooksecurefunc or not Addon.TemporaryAccess:Probe(bridge,api) then return false,'native temporary access/page APIs unavailable' end
    if type(bridge.bar.Manager.Run)~='function' or type(bridge.bar.Manager.SetFrameRef)~='function' then return false,'native resolved-action assist bridge unavailable' end
    for _,name in ipairs(banks) do
        local group=api['ConsolePortGroup'..name]
        local definition=bridge.bar.Layout.children[name]
        if not group or not group.buttons or not definition or definition.type~='Group'
            or type(group.RegisterPageResponse)~='function' or type(group.RegisterVisibilityDriver)~='function'
            or type(group.RegisterDriver)~='function' or type(group.GetAttribute)~='function'
            or type(group:GetAttribute('_onstate-opacity'))~='string' then return false,'native temporary group drivers unavailable: '..name end
        for key in pairs(cells) do
            local button=group.buttons[key]
            if not button or button.header~=group or type(button.CreateEnvironment)~='function'
                or type(button.SetState)~='function' or not Routing.Environment(button) then return false,'native temporary button unavailable: '..name..'/'..key end
        end
    end
    return true
end
function Routing:Refresh(bridge,api,enabled)
    if api.InCombatLockdown() then return false,'temporary routing setup deferred during combat' end
    if not enabled then return self:Disable(bridge,api) end
    local ok,reason=self:Probe(bridge,api)
    if not ok then return false,reason end
    if not self.resolvedActions then
        self.resolvedActions=api.CreateFrame('Frame','ConsolePortForeverResolvedActions',api.UIParent,'SecureHandlerBaseTemplate')
        self.resolvedActions:Hide()
        self.resolvedActions:SetAttribute('GetSpellID',self.ResolvedSpell)
    end
    -- The native assist wrapper receives already resolved action slots. Its
    -- global pager would otherwise add page 11 a second time to ordinary slots
    -- 1-12 while L2+R2 owns dragonriding. This read-only helper keeps assistance
    -- on that button's actual spell; the native ring/click wrappers stay intact.
    bridge.bar.Manager:SetFrameRef('CPFTemporaryResolvedActions',self.resolvedActions)
    bridge.bar.Manager:Run([[pager = self:GetFrameRef('CPFTemporaryResolvedActions')]])
    for _,name in ipairs(banks) do
        local group=api['ConsolePortGroup'..name]
        group.__cpfTemporaryPage=group.__cpfTemporaryPage or group:GetAttribute('ActionPageChanged')
        -- LAB's native flyout click handler uses this header upvalue. It must
        -- also be present when ground placement is disabled for the character.
        group:Execute('owner = owner or self')
        for key,index in pairs(cells) do
            local button=group.buttons[key]
            if not button.__cpfTemporary then
                local native=Addon.Core.Copy(button.Env)
                native.OnDragStart=native.OnDragStart or button:GetAttribute('OnDragStart')
                local ordinary={}
                button.__cpfTemporary={nativeEnv=native,ordinary=ordinary}
                button.CPFTempContentsChanged=function(self,state,kind,value)
                    if kind=='custom' then value=ordinary[tostring(state)] elseif kind=='empty' then value=nil end
                    self:ButtonContentsChanged(state,kind,value)
                end
                api.hooksecurefunc(button,'SetState',function(self,state,kind,value)
                    state=tostring(state or self:GetAttribute('state'))
                    ordinary[state]=value
                    self:SetAttribute('cpf-temp-kind-'..state,kind)
                    self:SetAttribute('cpf-temp-action-'..state,type(value)~='table' and value or nil)
                    if self:GetAttribute('cpf-temp-enabled') then Addon.SecureModes.RefreshButton(self) end
                end)
                group:WrapScript(button,'PreClick',Routing.PreClick)
                group:WrapScript(button,'PostClick',Routing.PostClick)
                group:WrapScript(button,'OnHide',Routing.OnHide)
            end
            -- Before uses the scoped special-cell attribute, not main-bar IDs.
            button:SetAttribute('cpf-temp-special-cell',name=='L2R2' and index or nil)
            button:SetAttribute('cpf-temp-basepages',api.NUM_ACTIONBAR_PAGES or 6)
            button:SetAttribute('cpf-temp-limit',api.NUM_OVERRIDE_BUTTONS or 6)
            -- Re-capture unpaged native bindings, including per-character edits.
            local bindings=bridge.bar.Manager:GetBindings(key)
            if bindings and not Addon.Core.Equal(button.__cpfTemporary.bindings,bindings) then
                button:SetBindings(bindings)
                button.__cpfTemporary.bindings=Addon.Core.Copy(bindings)
            end
            button:CreateEnvironment(assert(Routing.Environment(button)))
            button:SetAttribute('cpf-temp-enabled',true)
            Addon.SecureModes.RefreshButton(button)
        end
        group:RegisterPageResponse(Routing.PageResponse)
        -- Runtime drivers only: preserve saved layouts/geometry and modifier fade.
        local definition=bridge.bar.Layout.children[name]
        group:RegisterVisibilityDriver(ordinaryDriver(definition.visibility))
        group:RegisterDriver('opacity',ordinaryDriver(definition.opacity),group:GetAttribute('_onstate-opacity'))
    end
    -- Retire only the native standalone override-page runtime claim. Its saved
    -- definition stays available for disable/restore and cursor-access overflow.
    if type(bridge.bar.Map)=='function' then
        bridge.bar:Map('Page',nil,function(page)
            local props=page.props
            if props and (props.page=='override' or props.page=='overiidebar') then
                page:RegisterVisibilityDriver('hide')
                page:RegisterDriver('override','false',page:GetAttribute('_onstate-override'))
            end
        end)
    end
    Addon.TemporaryAccess:Enable(bridge,api)
    if not self.callbacks and type(bridge.bar.RegisterSafeCallback)=='function' then
        self.callbacks=true
        local function changed() api.C_Timer.After(0,function() Addon:RefreshModes() end) end
        for _,event in ipairs({'OnLayoutChanged','OnNewBindings','OnEnvLoaded'}) do bridge.bar:RegisterSafeCallback(event,changed) end
    end
    return true,'native temporary/dragonriding actions use L2+R2 for every installed character; Retail acceptance pending'
end
function Routing:Disable(bridge,api)
    if self.resolvedActions and bridge and type(bridge.bar.Manager.Run)=='function' then
        bridge.bar.Manager:Run([[pager = self:GetFrameRef('Pager')]])
    end
    for _,name in ipairs(banks) do
        local group=api['ConsolePortGroup'..name]
        if group and group.buttons then
            for _,button in pairs(group.buttons) do
                if button.__cpfTemporary and button:GetAttribute('cpf-temp-enabled') then
                    button:SetAttribute('cpf-temp-enabled',nil)
                    button:SetAttribute('cpf-temp-held',nil)
                    button:CreateEnvironment(button.__cpfTemporary.nativeEnv)
                    local bindings=bridge and bridge.bar.Manager:GetBindings(button.id)
                    if bindings then button:SetBindings(bindings) end
                end
            end
            if group.__cpfTemporaryPage then
                group:RegisterPageResponse(group.__cpfTemporaryPage)
                local definition=bridge and bridge.bar.Layout.children[name]
                if definition then
                    group:RegisterVisibilityDriver(definition.visibility)
                    group:RegisterDriver('opacity',definition.opacity,group:GetAttribute('_onstate-opacity'))
                end
            end
        end
    end
    if bridge and type(bridge.bar.Map)=='function' then
        bridge.bar:Map('Page',nil,function(page)
            local props=page.props
            if props and (props.page=='override' or props.page=='overiidebar') then
                page:RegisterVisibilityDriver(props.visibility)
                page:RegisterDriver('override',props.override,page:GetAttribute('_onstate-override'))
            end
        end)
    end
    Addon.TemporaryAccess:Disable()
    return true,'native temporary paging restored'
end
