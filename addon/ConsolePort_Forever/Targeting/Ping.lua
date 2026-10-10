local _, Addon = ...
local Ping = {claims={}}
Addon.PingTargeting = Ping
local CENTER = 'GamePadCursorCentering'
local OWNER = 'ConsolePortForeverPing'

-- Only the native secure macro dispatcher executes /ping. Public callbacks
-- prepare and restore the cursor within that single click; they never ping.
Ping.Cancel = [[
    self:SetAttribute('cpf-trigger',nil)
    self:SetAttribute('cpf-key',nil)
    self:SetAttribute('cpf-device',nil)
    self:SetAttribute('cpf-chord',nil)
    self:SetAttribute('cpf-prefix',nil)
    if not self:GetAttribute('cpf-commit') then
        self:SetAttribute('typerelease',nil)
        self:SetAttribute('macrotext',nil)
    end
    self:GetFrameRef('layers'):RunAttribute('ReleaseAll','ConsolePortForeverPingCancel')
    self:Hide()
]]
Ping.Pre = [[
    self:SetAttribute('typerelease',nil)
    self:SetAttribute('macrotext',nil)
    self:SetAttribute('cpf-commit',nil)
    if button=='Cancel' then
        if down then self:RunAttribute('cpf-cancel') end
        return
    end
    local radial=self:GetFrameRef('radial')
    local layers=self:GetFrameRef('layers')
    local physical=button:match('([^%-]+)$')
    local state=GetGamePadState()
    for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
        local owner=self:GetFrameRef(name)
        -- Cursor is natively unprotected and relinquishes input in combat.
        -- Restricted handles may only inspect its visibility out of combat.
        if owner and (owner:IsProtected() or self:GetAttribute('state-cpf-combat')~='combat')
            and owner:IsShown() then self:RunAttribute('cpf-cancel') return end
    end
    for index=1,(self:GetAttribute('cpf-radial-owner-count') or 0) do
        local owner=self:GetFrameRef('cpf-radial-owner-'..index)
        if owner and (owner:IsProtected() or self:GetAttribute('state-cpf-combat')~='combat')
            and owner:IsShown() then self:RunAttribute('cpf-cancel') return end
    end
    if down then
        self:RunAttribute('cpf-cancel')
        if not self:GetAttribute('cpf-enabled') or not state or not state.buttons
            or not radial:RunAttribute('IsButtonHeld',physical) then return end
        self:SetAttribute('cpf-trigger',button)
        self:SetAttribute('cpf-key',button)
        self:SetAttribute('cpf-device',state.name)
        self:SetAttribute('cpf-chord',layers:GetAttribute('chord') or '')
        self:SetAttribute('cpf-prefix',layers:GetAttribute('prefix') or '')
        self:Show()
        local chord=layers:GetAttribute('chord') or ''
        if physical~='PAD2' then
            layers:RunAttribute('Claim','ConsolePortForeverPingCancel','MODAL',chord..'PAD2','click',self:GetName(),'Cancel')
        end
        return
    end
    if self:GetAttribute('cpf-trigger')~=button or not self:IsShown()
        or not state or not state.buttons or state.name~=self:GetAttribute('cpf-device')
        or radial:RunAttribute('IsButtonHeld',physical) then
        self:RunAttribute('cpf-cancel')
        return
    end
    -- GetIndex reads the native mapped stick directly in restricted execution,
    -- rather than relying on public cursor movement or visual highlight state.
    local index=self:RunAttribute('GetIndex',nil,7)
    if index==7 then self:RunAttribute('cpf-cancel') return end
    local suffix=index and (' '..index) or ''
    local unit;
    if UnitExists('softenemy') then unit='softenemy'
    elseif UnitExists('softfriend') then unit='softfriend' end
    local body;
    if unit then body='/ping [@'..unit..',exists]'..suffix
    else
        -- @cursor bypasses non-pingable UI and forces a world point. Inline
        -- centering follows ConsolePort World's secure ping macro approach.
        self:CallMethod('CaptureCenter')
        body='/console GamePadCursorCentering 1\n/ping [@cursor]'..suffix
    end
    self:SetAttribute('macrotext',body)
    self:SetAttribute('typerelease','macro')
    self:SetAttribute('cpf-commit',true)
    self:RunAttribute('cpf-cancel')
]]
Ping.Post = [[
    if not down then
        self:SetAttribute('typerelease',nil)
        self:SetAttribute('macrotext',nil)
        self:SetAttribute('cpf-commit',nil)
        self:CallMethod('RestoreCenter')
    end
]]
-- Keep the exact native resolver as an attribute. Its early returns only exit
-- that invocation, and every resolved winner is then checked for ownership.
Ping.Resolve = [[
    local key=...;
    self:RunAttribute('cpf-ping-original-resolve',key)
    local ping=self:GetFrameRef('cpf-ping')
    if not ping or not ping:IsShown() then return end
    local trigger=ping:GetAttribute('cpf-key')
    if not trigger then return end
    local list,best=CLAIMS[trigger];
    if list then
        for i=1,#list do
            if not best or list[i][2]>=best[2] then best=list[i] end
        end
    end
    if not best or best[1]~='ConsolePortForeverPing' or best[3]~='click'
        or best[4]~=ping:GetName() then ping:RunAttribute('cpf-cancel') end
]]
local kinds={'Attack','Warning','OnMyWay','Assist','NonThreat','Threat'}
local labels={'ATTACK','WARNING','ON_MY_WAY','ASSIST','NOT_THREAT','THREAT'}
function Ping:Create(api,bridge)
    local cp,radial,layers=api.CPAPI,bridge.db.Radial,bridge.db.Layers
    local frame=api.CreateFrame('Button',OWNER,api.UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
    api.Mixin(frame,cp.AdvancedSecureMixin)
    frame:Hide()
    frame:SetPoint('CENTER',api.UIParent,'CENTER',0,0)
    frame:SetAttribute(cp.ActionPressAndHold,true)
    frame:RegisterForClicks('AnyDown','AnyUp')
    frame:SetAttribute('cpf-cancel',self.Cancel)
    frame:SetAttribute('_onstate-cpf-combat',[[self:RunAttribute('cpf-cancel')]])
    function frame:CaptureCenter() self.cpfCenterBefore=api.GetCVar(CENTER) end
    function frame:RestoreCenter()
        if self.cpfCenterBefore~=nil and api.GetCVar(CENTER)=='1' then api.SetCVar(CENTER,self.cpfCenterBefore) end
        self.cpfCenterBefore=nil
    end
    function frame:OnInput(x,y,len)
        local index=self:GetIndexForPos(x,y,len,7)
        for i,item in ipairs(self.cpfIcons or {}) do
            local bright=index==i and 1 or .55
            item.icon:SetVertexColor(bright,bright,bright)
        end
    end
    radial:Register(frame,'ForeverPing',{sticks={'Right','Camera'},sizer=[[local size=7;]]})
    frame:SetScript('OnShow',frame.OnShow)
    frame:SetScript('OnHide',frame.OnHide)
    frame:HookScript('OnHide',function() frame:ClearInstantly() end)
    frame:HookScript('OnShow',function()
        frame:SetAlpha(1) frame:OnInput(0,0,0)
        if frame.cpfHint then
            local physical=(frame:GetAttribute('cpf-trigger') or ''):match('([^%-]+)$')
            frame.cpfHint:SetText('Release: ping\nRight stick: type\n'..(physical=='PAD2' and 'Cancel: select cancel wedge' or 'Circle / B: cancel'))
        end
    end)
    frame:HookScript('OnUpdate',function()
        local state=api.C_GamePad.GetDeviceMappedState()
        if not state or state.name~=frame:GetAttribute('cpf-device') then
            -- Native Dispatcher is unprotected: release camera input even
            -- during combat. Protected gesture cancellation waits for a
            -- secure release/owner/state transition or an out-of-combat tick.
            frame:ClearInstantly()
            if not api.InCombatLockdown() then frame:Execute([[self:RunAttribute('cpf-cancel')]]) end
        end
    end)
    frame:WrapScript(frame,'PreClick',self.Pre)
    frame:WrapScript(frame,'PostClick',self.Post)
    frame:WrapScript(frame,'OnHide',[[self:RunAttribute('cpf-cancel')]])
    layers:WrapScript(layers,'OnAttributeChanged',[[
        local ping=self:GetFrameRef('cpf-ping')
        if ping and ping:IsShown() and (name=='chord' or name=='prefix')
            and value~=(ping:GetAttribute('cpf-'..name) or '') then ping:RunAttribute('cpf-cancel') end
    ]])
    for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
        local owner=bridge.db[name]
        if owner then
            frame:SetFrameRef(name,owner)
            frame:WrapScript(owner,'OnShow',[[control:RunAttribute('cpf-cancel')]])
        end
    end
    -- Initial state-driver evaluation is synchronous, so every referenced
    -- frame and cancellation wrapper must already exist before registration.
    api.RegisterStateDriver(frame,'cpf-combat','[combat] combat; peace')
    frame.cpfIcons={}
    local radius=frame:GetWidth()/2
    for index=1,7 do
        local item=api.CreateFrame('Frame',nil,frame)
        item:SetSize(48,48)
        local x,y=radial:GetPointForIndex(index,7,radius)
        item:SetPoint('CENTER',frame,'CENTER',x,y)
        item.icon=item:CreateTexture(nil,'ARTWORK') item.icon:SetAllPoints()
        item.icon:SetAtlas(index==7 and 'Radial_Wheel_Icon_Close' or 'Ping_Marker_Icon_'..kinds[index])
        local label=item:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
        label:SetPoint('TOP',item,'BOTTOM',0,-2)
        label:SetText(index==7 and (api.CANCEL or 'Cancel') or (api['PING_TYPE_'..labels[index]] or kinds[index]))
        frame.cpfIcons[index]=item
    end
    local hint=frame:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
    hint:SetPoint('CENTER',frame,'CENTER',0,0)
    hint:SetText('Release: ping\nRight stick: type\nCircle / B: cancel')
    frame.cpfHint=hint
    self.frame,self.layers,self.api=frame,layers,api
end
function Ping:InstallResolver()
    local layers=self.layers
    if layers:GetAttribute('Resolve')==self.Resolve then return true end
    if self.originalResolve and layers:GetAttribute('Resolve')~=self.originalResolve then return false end
    self.originalResolve=layers:GetAttribute('Resolve')
    layers:SetAttribute('cpf-ping-original-resolve',self.originalResolve)
    layers:SetFrameRef('cpf-ping',self.frame)
    layers:CreateEnvironment({Resolve=self.Resolve})
    return true
end
function Ping:CaptureRadialOwners(bridge)
    self.radialOwners=self.radialOwners or {}
    local count=0
    for header in pairs(bridge.db.Radial.Headers) do
        if header~=self.frame then
            count=count+1
            self.frame:SetFrameRef('cpf-radial-owner-'..count,header)
            if not self.radialOwners[header] then
                self.frame:WrapScript(header,'OnShow',[[control:RunAttribute('cpf-cancel')]])
                self.radialOwners[header]=true
            end
        end
    end
    self.frame:SetAttribute('cpf-radial-owner-count',count)
end
function Ping:Refresh(api,enabled,bridge)
    if api.InCombatLockdown() then return false,'secure ping update deferred until combat ends' end
    if self.frame then
        self.frame:Execute([[self:SetAttribute('cpf-commit',nil) self:RunAttribute('cpf-cancel')]])
        self.frame:SetAttribute('cpf-enabled',nil)
        self.layers:ReleaseAll(OWNER)
        self.claims={}
    end
    if not enabled then
        if self.layers and self.layers:GetAttribute('Resolve')==self.Resolve then
            self.layers:CreateEnvironment({Resolve=self.originalResolve})
            self.originalResolve=nil
        end
        return true,'native ping bindings restored'
    end
    local cp=api.CPAPI
    if not bridge or not bridge.api or bridge.api.version~='3.3.10' or not bridge.db
        or not bridge.db.Radial or type(bridge.db.Radial.Register)~='function'
        or type(bridge.db.Radial.Headers)~='table'
        or not bridge.db.Layers or type(bridge.db.Layers.Claim)~='function'
        or type(bridge.db.Layers.ReleaseAll)~='function' or type(bridge.db.Layers.CreateEnvironment)~='function'
        or not cp or not cp.AdvancedSecureMixin or type(api.Mixin)~='function'
        or type(api.GetBindingKey)~='function' or type(api.GetCVar)~='function'
        or type(api.SetCVar)~='function' or type(api.RegisterStateDriver)~='function'
        or not api.C_GamePad or type(api.C_GamePad.GetDeviceMappedState)~='function' then
        return false,'qualified native secure ping selector unavailable; native binding retained'
    end
    for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
        local owner=bridge.db[name]
        if not owner or type(owner.IsShown)~='function' or type(owner.IsProtected)~='function'
            or (name~='Cursor' and not owner:IsProtected()) then
            return false,'qualified native ping owner unavailable: '..name..'; native binding retained'
        end
    end
    if bridge.db('layersTapLatch') or bridge.db('layersDoubleBar') or bridge.db('layersOrdered') then
        return false,'secure ping selector requires standard native modifier layers; native binding retained'
    end
    if not self.frame then self:Create(api,bridge) end
    self:CaptureRadialOwners(bridge)
    if not self:InstallResolver() then return false,'native resolver changed by another owner; native ping binding retained' end
    local keys={}
    for _,key in ipairs({api.GetBindingKey('TOGGLEPINGLISTENER')}) do if key:match('PAD') then keys[key]=true end end
    local gamepad=bridge.db.Gamepad
    if gamepad and type(gamepad.GetBindings)=='function' then
        for button,row in pairs(gamepad:GetBindings()) do
            for prefix,binding in pairs(row) do if binding=='TOGGLEPINGLISTENER' then keys[prefix..button]=true end end
        end
    end
    self.frame:SetAttribute('cpf-enabled',true)
    for key in pairs(keys) do
        if self.layers:Claim(OWNER,'OVERRIDE',key,'click',self.frame,key) then self.claims[key]=true end
    end
    return true,'secure macro ping: native right-stick selector; aimed units/forced world points; Retail acceptance pending'
end
function Ping:Observe(api,error)
    local snapshot={error=type(error)=='string' and error or 'ping target diagnostic',centering=api.GetCVar(CENTER),pingMode=api.GetCVar('pingMode'),foci={}}
    if api.GetMouseFoci then
        for index,frame in ipairs(api.GetMouseFoci()) do
            if index>8 then break end
            if not (frame.IsForbidden and frame:IsForbidden()) then
                snapshot.foci[#snapshot.foci+1]={name=frame:GetName() or '<unnamed>',topLevel=frame.IsToplevel and frame:IsToplevel() or false}
            end
        end
    end
    if Addon.Diagnostics then
        Addon.Diagnostics.ping=snapshot
        Addon.Diagnostics:Log('ping',snapshot.error..'; centering='..tostring(snapshot.centering)..'; public focus='..(#snapshot.foci>0 and snapshot.foci[1].name or '<world>'))
    end
    return snapshot
end
