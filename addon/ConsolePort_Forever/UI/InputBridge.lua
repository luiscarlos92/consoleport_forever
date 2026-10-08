local _, Addon = ...
local Bridge={}
Addon.InputBridge=Bridge
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}

-- Native Input hides its widgets in the protected combat state driver, but
-- Layers' public ReleaseAll refuses insecure calls after lockdown begins.
-- Release the native widget's UI claims from that same restricted transition.
-- Other owners' BASE/MODAL claims are resolved by Layers, never cleared here.
Bridge.CombatRelease=[[
    if message then
        local layers=self:GetFrameRef('cpf-ui-layers');
        if layers then layers:RunAttribute('ReleaseAll',self:GetName()) end;
        self:SetAttribute('cpf-ui-active',nil)
        self:SetAttribute('cpf-ui-held',nil)
        self:SetAttribute('cpf-ui-front',nil)
        self:SetAttribute('cpf-ui-allowed',nil)
    end;
]]

-- Native Input executes frontend mouse scripts before SecureActionButton's
-- OnClick. The Lua and restricted guards must agree on the press generation.
Bridge.ClickGuard=[[
    local active=self:GetAttribute('cpf-ui-active')
    local held=self:GetAttribute('cpf-ui-held')
    if not active and not held then return end
    if control:GetAttribute('state-combat') then
        self:SetAttribute('cpf-ui-held',nil)
        return false
    end
    local generation=self:GetAttribute('cpf-ui-generation')
    if down then
        local front=self:GetAttribute('cpf-ui-front')
        self:SetAttribute('cpf-ui-held',front)
        if not active and not front then return end
        if not active or front~=generation then return false end
    else
        self:SetAttribute('cpf-ui-held',nil)
        if not active or not held or held~=generation then return false end
    end
    local owner=self:GetFrameRef('cpf-ui-owner')
    local target=self:GetFrameRef('cpf-ui-target')
    if not self:GetAttribute('cpf-ui-allowed') or not owner or not owner:IsShown()
        or not target or not target:IsShown() then return false end
]]
Bridge.PostGuard=[[
    if self:GetAttribute('cpf-ui-active') and not control:GetAttribute('state-combat') then
        self:SetAttribute('typerelease',self:GetAttribute('cpf-ui-release'))
        -- Restricted frame handles are not native click delegates. Preserve
        -- the raw frame installed by Input:SetButton outside combat.
        if not self:GetAttribute('cpf-ui-allowed') then self:SetAttribute('clickbutton',nil) end
    end
]]

function Bridge.Probe(input,api,layers)
    return api and api.CPAPI and input and type(input.GetWidget)=='function' and type(input.SetButton)=='function'
        and type(input.SetCommand)=='function' and type(input.WrapScript)=='function'
        and type(api.GetBindingAction)=='function'
        and type(api.hooksecurefunc)=='function' and api.CPAPI.ActionTypeRelease=='typerelease'
        and api.CPAPI.ActionPressAndHold=='pressAndHoldAction'
        and layers and type(layers.GetAttribute)=='function' and type(layers:GetAttribute('ReleaseAll'))=='string'
end
function Bridge:WatchCombatWidget(widget)
    if widget.__cpfCombatRelease then return end
    assert(not self.api.InCombatLockdown(),'combat handoff setup requires out of combat')
    local native=widget:GetAttribute('_childupdate-combat')
    assert(type(native)=='string' and native:find("self:CallMethod('Clear')",1,true)
        and native:find("self:SetAttribute('clickbutton', nil)",1,true),'native Input combat lifecycle changed')
    widget:SetFrameRef('cpf-ui-layers',self.layers)
    widget:SetAttribute('_childupdate-combat',native..Bridge.CombatRelease)
    widget.__cpfCombatRelease=true
end
function Bridge.New(input,api,layers)
    assert(Bridge.Probe(input,api,layers),'audited ConsolePort Input/Layers combat handoff unavailable')
    local owner=api.CreateFrame('Frame',nil,api.UIParent)
    owner:Hide()
    local bridge=setmetatable({input=input,api=api,layers=layers,owner=owner,states={},serial=0},{__index=Bridge})
    for _,widget in pairs(input.Widgets) do bridge:WatchCombatWidget(widget) end
    api.hooksecurefunc(input,'GetWidget',function(_,id)
        local widget=input.Widgets[tostring(id):upper()]
        if widget then bridge:WatchCombatWidget(widget) end
    end)
    return bridge
end
function Bridge:Stamp(state,active)
    self.serial=self.serial+1
    state.generation=self.serial state.active=active
    if not self.api.InCombatLockdown() then
        state.widget:SetAttribute('cpf-ui-generation',state.generation)
        state.widget:SetAttribute('cpf-ui-active',active or nil)
    end
end
function Bridge:Validate(state)
    if not state.validator then return true end
    local ok,valid=pcall(state.validator)
    if ok and valid then return true end
    state.allowed=false
    if not self.api.InCombatLockdown() then
        state.widget:SetAttribute('cpf-ui-allowed',nil)
        self:Stamp(state,state.active)
    end
    return false
end
function Bridge:Widget(key)
    local state=self.states[key]
    if state then return state end
    -- GetWidget sets owner. Retain the previous owner attribute before calling
    -- it; a native row is kept by reference (it can contain frames/functions).
    local existing=self.input.Widgets[key]
    local previousOwner=existing and existing:GetAttribute('owner')
    local widget=self.input:GetWidget(key,self.owner)
    state={widget=widget,previousOwner=previousOwner}
    self.states[key]=state
    self:Stamp(state,false)
    local down,up=widget:GetScript('OnMouseDown'),widget:GetScript('OnMouseUp')
    widget:SetScript('OnMouseDown',function(button,...)
        if state.front and state.front.cpf and state.front.target and not self.api.InCombatLockdown() then state.front.target:SetButtonState('NORMAL') end
        local cpf=state.active
        local front={cpf=cpf,generation=state.generation,target=cpf and state.target or nil}
        state.front=front
        if cpf and (self.api.InCombatLockdown() or not state.allowed or not self:Validate(state)) then return end
        if not self.api.InCombatLockdown() then button:SetAttribute('cpf-ui-front',cpf and state.generation or nil) end
        if down then down(button,...) end
        if cpf and (not state.active or front.generation~=state.generation) then button.postreset=nil end
    end)
    widget:SetScript('OnMouseUp',function(button,...)
        local front=state.front state.front=nil
        if state.active and not self.api.InCombatLockdown() then self:Validate(state) end
        local stale=(front and front.cpf and (not state.active or front.generation~=state.generation))
            or (state.active and (not front or not front.cpf or not state.allowed))
        if stale or (state.active and self.api.InCombatLockdown()) then
            button.state=false button.postreset=nil
            if front and front.target and not self.api.InCombatLockdown() then front.target:SetButtonState('NORMAL') end
            return
        end
        if up then up(button,...) end
        if front and front.cpf and (not state.active or front.generation~=state.generation) then button.postreset=nil end
    end)
    self.input:WrapScript(widget,'OnClick',Bridge.ClickGuard)
    self.input:WrapScript(widget,'PostClick','return nil,true',Bridge.PostGuard)
    self.api.hooksecurefunc(widget,'SetOverride',function(_,data)
        if self.applying or data.owner==self.owner then return end
        if state.active then self:Stamp(state,false) end
    end)
    self.api.hooksecurefunc(widget,'ClearOverride',function()
        if not self.applying and state.active and not widget:HasOwner(self.owner) then self:Stamp(state,false) end
    end)
    return state
end
local function ownerAlive(row)
    return row and row.owner and row.owner.IsShown and row.owner:IsShown()
end
function Bridge:ReleaseKey(state)
    local widget=state.widget
    local current=widget:GetOverride(true)
    state.allowed=false
    if not self.api.InCombatLockdown() then widget:SetAttribute('cpf-ui-allowed',nil) end
    self.applying=true
    if current and current.owner==self.owner then
        widget:ClearOverride(self.owner)
        if not self.api.InCombatLockdown() then
            if ownerAlive(state.previous) then widget:SetOverride(state.previous) end
            local row=widget:GetOverride(true) or widget:GetOverride(false)
            widget:SetAttribute('owner',row and row.owner or state.previousOwner)
        end
    end
    self.applying=nil
    self:Stamp(state,false)
    state.previous=nil state.context=nil state.target=nil state.validator=nil
end
function Bridge:Release()
    local failures={}
    for key,state in pairs(self.states) do
        local ok,reason=pcall(self.ReleaseKey,self,state)
        if not ok then failures[#failures+1]=key..': '..tostring(reason) end
    end
    self.applying=nil
    self.context=nil
    if not self.api.InCombatLockdown() then self.owner:Hide() end
    return #failures==0,table.concat(failures,'; ')
end
function Bridge:Apply(context,force)
    if self.api.InCombatLockdown() then return false,'native UI context is paused in combat' end
    if not context then return self:Release() end
    local changed=force or not self.context or self.context.frame~=context.frame
        or self.context.token~=context.token or self.context.data~=context.data or self.context.data2~=context.data2
    local wanted,clicks={},{}
    for key,target in pairs(context.routes) do
        for _,modifier in ipairs(modifiers) do wanted[modifier..key]=target clicks[modifier..key]=(context.clicks or {})[key] end
    end
    for key,target in pairs(context.chords or {}) do wanted[key]=target end
    self.owner:Show()
    for chord,target in pairs(wanted) do
            local click=clicks[chord] or 'LeftButton'
            local state=self:Widget(chord)
            local row=state.widget:GetOverride(true)
            local allowed=target and target.IsShown and target:IsShown() and target.IsEnabled and target:IsEnabled() or false
            if target and target.IsForbidden and target:IsForbidden() then allowed=false end
            local label=target and target.GetText and target:GetText() or nil
            if self.api.issecretvalue and self.api.issecretvalue(label) then label='opaque native label' end
            state.validator=context.validators and context.validators[chord:match('[^%-]+$')] or context.validate
            if changed or not state.active or state.target~=target or state.allowed~=allowed or state.label~=label or state.click~=click or not row or row.owner~=self.owner then
                if row and row.owner~=self.owner then state.previous=row state.previousOwner=row.owner end
                self:Stamp(state,true)
                state.target,state.allowed,state.context,state.label=target,allowed,context.frame,label
                state.click=click
                local widget=state.widget
                widget:SetFrameRef('cpf-ui-owner',context.frame)
                widget:SetFrameRef('cpf-ui-target',allowed and target or self.owner)
                widget:SetAttribute('cpf-ui-allowed',allowed or nil)
                widget:SetAttribute('cpf-ui-release',allowed and 'click' or 'CPFConsume')
                self.applying=true
                if allowed then self.input:SetButton(chord,self.owner,target,true,click)
                else
                    widget:SetAttribute('clickbutton',nil)
                    self.input:SetCommand(chord,self.owner,true,'LeftButton','CPFConsume',function() end)
                end
                self.applying=nil
                local installed=widget:GetOverride(true)
                assert(installed and installed.owner==self.owner and widget:GetAttribute('owner')==self.owner,'native UI row readback rejected')
                assert(widget:GetAttribute('typerelease')==(allowed and 'click' or 'CPFConsume'),'native UI action readback rejected')
                if allowed then assert(widget:GetAttribute('clickbutton')==target,'native UI target readback rejected') end
                assert(self.api.GetBindingAction(chord,true)=='CLICK '..widget:GetName()..':'..(allowed and click or 'LeftButton'),'native effective UI route readback rejected')
            end
    end
    for key,state in pairs(self.states) do if wanted[key]==nil and state.active then self:ReleaseKey(state) end end
    self.context={frame=context.frame,token=context.token,data=context.data,data2=context.data2}
    return true
end
