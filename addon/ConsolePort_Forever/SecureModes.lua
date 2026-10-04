local _, Addon = ...
local Core, Modes = Addon.Core, {}
Addon.SecureModes = Modes
local cells={PAD1=1,PAD2=2,PAD3=3,PAD4=4,PADDLEFT=5,PADDUP=6,PADDRIGHT=7,PADDDOWN=8}
local banks={"Base","L2","R2","L2R2"}

-- These snippets execute only through ConsolePort's native secure environment.
-- They never place spells, copy action storage, or replace Layers bindings.
Modes.Before=[[
    local requested = ...;
    self:SetAttribute('cpf-pending-state', requested)
    if self:GetAttribute('cpf-held') then return end;
    if self:RunAttribute('IsFlyoutActive') then return end;
    local ordinaryPage = GetActionBarPage();
    local specialPage;
    if HasVehicleActionBar() then specialPage = GetVehicleBarIndex()
    elseif HasOverrideActionBar() then specialPage = GetOverrideBarIndex()
    elseif HasTempShapeshiftActionBar() then specialPage = GetTempShapeshiftBarIndex() end;
    local kind = self:GetAttribute('cpf-kind-'..tostring(requested)) or 'empty';
    local value = self:GetAttribute('cpf-action-'..tostring(requested));
    local special = specialPage and self:GetAttribute('cpf-special-cell');
    if special then kind, value = 'action', special end;
    self:SetAttribute('labtype-'..tostring(requested), kind)
    self:SetAttribute('labaction-'..tostring(requested), value)
    self:SetAttribute('actionpage', special and specialPage or ordinaryPage)
]]
Modes.After=[[
    local resolvedType = self:GetAttribute('type');
    local resolvedField = self:GetAttribute('action_field');
    local resolvedAction = resolvedField and self:GetAttribute(resolvedField);
    self:CallMethod('CPFContentsChanged', self:GetAttribute('state'), resolvedType, resolvedAction)
]]
Modes.PreClick=[[
    if not self:GetAttribute('cpf-enabled') then return end;
    if down then
        -- A fresh press also clears a latch left by a vanished input device.
        self:SetAttribute('cpf-held', nil)
        self:RunAttribute('UpdateState', self:GetAttribute('cpf-pending-state') or self:GetAttribute('state'))
        self:SetAttribute('cpf-held', true)
    end;
]]
Modes.PostClick=[[
    if not self:GetAttribute('cpf-enabled') then return end;
    if not down then
        self:SetAttribute('cpf-held', nil)
        self:RunAttribute('UpdateState', self:GetAttribute('cpf-pending-state') or self:GetAttribute('state'))
    end;
]]
Modes.OnHide=[[ self:SetAttribute('cpf-held', nil) ]]
Modes.PageResponse=[[ self:ChildUpdate('cpfpage', ...) ]]
Modes.ChildResponse=[[ self:RunAttribute('UpdateState', self:GetAttribute('state')) ]]

function Modes.Environment(button)
    local nativeEnv=button.__cpfMode and button.__cpfMode.nativeEnv or button.Env
    local native=nativeEnv and nativeEnv.UpdateState
    if type(native)~="string" or not native:find("ButtonContentsChanged",1,true)
        or not native:find("IsPressHoldReleaseSpell",1,true) then return nil,"native button contract changed" end
    local result={UpdateState=Modes.Before..native..Modes.After,
        ["_childupdate-cpfpage"]=Modes.ChildResponse}
    -- Preserve native drag conversion while updating the ordinary slot model.
    local drag=nativeEnv.OnReceiveDrag
    if drag then
        local replacement=[[self:SetAttribute('cpf-kind-'..tostring(state), kind)
            self:SetAttribute('cpf-action-'..tostring(state), value)
            self::UpdateState(state)]]
        result.OnReceiveDrag=drag:gsub("self::UpdateState%(state%)",replacement)
    end
    return result
end

local function keyboardRoute(api,command)
    if type(api.GetBindingKey)~="function" then return false end
    local keys={api.GetBindingKey(command)}
    for _,key in ipairs(keys) do if not key:find("PAD",1,true) then return true end end
    return false
end
function Modes.Probe(bridge,api)
    local ok,reason=bridge:Probe()
    if not ok then return false,reason end
    if not api.CPAPI or type(api.CPAPI.ConvertSecureBody)~="function" or type(api.hooksecurefunc)~="function" then return false,"secure CP helpers unavailable" end
    for name,definition in pairs(bridge.bar.Layout.children or {}) do
        if definition.type=='Page' and not (name=='Override Action Bar' and definition.page=='overiidebar') then
            return false,'an additional native Page widget requires coexistence proof; current layout retained'
        end
    end
    for _,id in ipairs(banks) do
        local group=api["ConsolePortGroup"..id]
        local definition=bridge.bar.Layout.children and bridge.bar.Layout.children[id]
        if not group or not group.buttons or not definition or definition.type~="Group"
            or type(group.RegisterPageResponse)~="function" then return false,"current four-group layout not ready" end
        for key in pairs(cells) do
            local button=group.buttons[key]
            if not button or type(button.CreateEnvironment)~="function" or not button.header or type(button.header.WrapScript)~="function"
                or type(button.RefreshBinding)~="function" or type(button.SetState)~="function" then return false,"native main-bank buttons unavailable" end
            if not button.__cpfMode and not Modes.Environment(button) then return false,"native button contract changed" end
        end
    end
    -- Native CP hides the Blizzard override/possess bars. Do not remove the
    -- legacy access surface until an actual remaining native route is known.
    if not keyboardRoute(api,"VEHICLEEXIT") then return false,"native vehicle-exit route unavailable; baseline preserved" end
    for i=9,12 do
        if not keyboardRoute(api,"ACTIONBUTTON"..i) then return false,"native overflow route unavailable for action "..i.."; baseline preserved" end
    end
    return true
end
local function removeLegacyClause(driver)
    if type(driver)~="string" then return driver end
    return (driver:gsub("%[vehicleui%]%[overridebar%]%s*[^;]+;%s*",""))
end
function Modes.LayoutProposal(layout)
    local proposal=Core.Copy(layout)
    for _,id in ipairs(banks) do
        local group=proposal.children[id]
        group.visibility=removeLegacyClause(group.visibility)
        group.opacity=removeLegacyClause(group.opacity)
    end
    local old=proposal.children["Override Action Bar"]
    if old and old.type=="Page" and old.page=="overiidebar" then proposal.children["Override Action Bar"]=nil end
    return proposal
end
function Modes.Install(bridge,api)
    if api.InCombatLockdown() then return false,"mode setup deferred during combat" end
    local ok,reason=Modes.Probe(bridge,api)
    if not ok then return false,reason end
    for _,id in ipairs(banks) do
        local group=api["ConsolePortGroup"..id]
        for key,index in pairs(cells) do
            local button=group.buttons[key]
            if not button.__cpfMode then
                local environment=assert(Modes.Environment(button))
                local ordinary={}
                button.__cpfMode={ordinary=ordinary,nativeEnv=Core.Copy(button.Env)}
                button.CPFContentsChanged=function(self,state,kind,value)
                    if kind=="custom" then value=ordinary[tostring(state)] end
                    if kind=="empty" then value=nil end
                    self:ButtonContentsChanged(state,kind,value)
                end
                api.hooksecurefunc(button,"SetState",function(self,state,kind,action)
                    state=tostring(state or self:GetAttribute('state'))
                    ordinary[state]=action
                    self:SetAttribute('cpf-kind-'..state,kind)
                    self:SetAttribute('cpf-action-'..state,type(action)~='table' and action or nil)
                    if self.__cpfMode.ready and self:GetAttribute('cpf-enabled') and state==tostring(self:GetAttribute('state')) then Modes.RefreshButton(self) end
                end)
                -- Capture the unpaged native SetState arguments before installing
                -- our snippet, since LAB's cosmetic maps contain resolved slots.
                local bindings=bridge.bar.Manager:GetBindings(key)
                if bindings then button:SetBindings(bindings) end
                button:SetAttribute('cpf-special-cell',id=="L2R2" and index or nil)
                button:CreateEnvironment(environment)
                button.header:WrapScript(button,'PreClick',Modes.PreClick)
                button.header:WrapScript(button,'PostClick',Modes.PostClick)
                button.header:WrapScript(button,'OnHide',Modes.OnHide)
                button.__cpfMode.ready=true
            end
            button:CreateEnvironment(assert(Modes.Environment(button)))
            button:SetAttribute('cpf-enabled',true)
            Modes.RefreshButton(button)
        end
        group.__cpfPageResponse=group.__cpfPageResponse or group:GetAttribute('ActionPageChanged')
        group:RegisterPageResponse(Modes.PageResponse)
    end
    return true
end
function Modes.RefreshButton(button)
    button.header:SetFrameRef('cpfUpdateButton',button)
    button.header:Execute([[local target=self:GetFrameRef('cpfUpdateButton'); control:RunFor(target,target:GetAttribute('UpdateState'),target:GetAttribute('state'))]])
end
function Modes.Disable(api,bridge)
    if api.InCombatLockdown() then return false end
    for _,id in ipairs(banks) do
        local group=api['ConsolePortGroup'..id]
        if group and group.buttons then
            local changed=false
            for _,button in pairs(group.buttons) do
                if button.__cpfMode and button:GetAttribute('cpf-enabled') then
                    changed=true
                    button:SetAttribute('cpf-enabled',false)
                    button:SetAttribute('cpf-held',nil)
                    button:CreateEnvironment(button.__cpfMode.nativeEnv)
                    if bridge then
                        local bindings=bridge.bar.Manager:GetBindings(button.id)
                        if bindings then button:SetBindings(bindings) end
                    end
                end
            end
            if changed and group.__cpfPageResponse then
                group:RegisterPageResponse(group.__cpfPageResponse)
                group:RunAttribute('ActionPageChanged',group:GetAttribute('actionpage'))
            end
        end
    end
    return true
end
