local _, Addon = ...
local Ping = {claims={}}
Ping.HOLD_SECONDS=.15
Ping.RING_ID='ForeverPings'
Addon.PingTargeting = Ping
local CENTER = 'GamePadCursorCentering'
local OWNER = 'ConsolePortForeverPing'
local kinds={'Attack','Warning','OnMyWay','Assist','NonThreat','Threat'}
local labels={'ATTACK','WARNING','ON_MY_WAY','ASSIST','NOT_THREAT','THREAT'}

-- No separate pie/buttons/slices are created here. Shared is ConsolePort's
-- account SavedVariable, outside Forever's per-character ring projection.
function Ping:PrepareAccountRing(api,bridge)
    local lib=api.LibStub('RelaTable',true)
    local env=lib and rawget(lib,'ConsolePort_Rings')
    local ring=bridge.db.Rings
    if not env or env.Frame~=ring or not env.IsDataReady or not env.IsSpellValidationReady
        or type(ring.Shared)~='table' or type(ring.Data)~='table'
        or type(env.CreateSet)~='function' or type(env.ValidateSet)~='function'
        or not env.KindAndActionMap or type(env.KindAndActionMap.custom)~='function'
        or type(ring.RefreshAll)~='function' or not ring:IsProtected() then
        return false,'native account ring not initialized; native ping binding retained'
    end
    local id=self.RING_ID
    if ring:IsShown() then return false,'native ring in use; ping update deferred' end
    if ring.Data[id] or (ring.Shared[id] and not (ring.Shared[id][0] or {}).cpfPingVersion) then
        return false,'ForeverPings ring name belongs to another ring; native ping binding retained'
    end
    if not self.nativeCustom then
        self.nativeCustom=env.KindAndActionMap.custom
        local nativeCustom=self.nativeCustom
        -- An owned custom action adapter supplies only data for native LAB
        -- buttons and native secure macro slots; the renderer is unmodified.
        env.KindAndActionMap.custom=function(data)
            local index=data.cpfPing
            if index==nil then return nativeCustom(data) end
            if type(index)~='number' or index%1~=0 or not kinds[index] then return end
            local text=api['PING_TYPE_'..labels[index]] or kinds[index]
            local secure={type='macro',macro=false,
                macrotext='/console GamePadCursorCentering 1\n/ping [@softenemy,exists][@softfriend,exists][@cursor] '..index}
            return {func=api.CPAPI.Static(secure),text=text,tooltip=text,
                texture=function(icon)
                    icon:SetAtlas('Ping_Marker_Icon_'..kinds[index],false)
                    -- Native LAB pool widgets serve other rings too. Follow
                    -- CP's atlas-action unmount contract to restore full UVs.
                    return function(texture) texture:SetTexCoord(0,1,0,1) end
                end},secure
        end
    end
    if not ring.Shared[id] then
        if env:CreateSet(id,ring.Shared)~=id then return false,'native account ring creation rejected' end
        local set=ring.Shared[id]
        set[0].cpfPingVersion=1
        for index=1,6 do set[index]={type='custom',cpfPing=index} end
        env:ValidateSet(id,set)
    end
    -- Existing order/removals/user edits remain account owned. Never reseed it.
    ring:RefreshAll()
    self.ring,self.env=ring,env
    return true
end

Ping.Cancel = [[
    local trigger=self:GetAttribute('cpf-trigger')
    self:SetAttribute('cpf-trigger',nil)
    self:SetAttribute('cpf-key',nil)
    self:SetAttribute('cpf-device',nil)
    self:SetAttribute('cpf-chord',nil)
    self:SetAttribute('cpf-prefix',nil)
    self:SetAttribute('type',nil)
    self:SetAttribute('typerelease',nil)
    self:SetAttribute('macrotext',nil)
    local ring=self:GetFrameRef('ring')
    if trigger and ring:GetAttribute('state')==self:GetAttribute('cpf-ring-id') then
        ring:RunAttribute('Disable')
    end
    self:CallMethod('EndArtwork')
    self:Hide()
]]
Ping.Pre = [[
    self:SetAttribute('type',nil)
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
    for _,name in ipairs(newtable('Cursor','Raid','TargetRing')) do
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
        return
    end
    if self:GetAttribute('cpf-trigger')~=button or not self:IsShown()
        or not state or not state.buttons or state.name~=self:GetAttribute('cpf-device')
        or radial:RunAttribute('IsButtonHeld',physical) then
        self:RunAttribute('cpf-cancel')
        return
    end
    -- Delegate the release click to the actual ConsolePort account ring.
    -- Its existing Main/Commit/index/sticky/cancel handling remains untouched.
    if self:GetFrameRef('ring'):IsShown() then
        self:SetAttribute('typerelease','click')
    else self:RunAttribute('cpf-cancel') end
]]
Ping.Post = [[
    self:SetAttribute('type',nil)
    self:SetAttribute('typerelease',nil)
    self:SetAttribute('macrotext',nil)
    self:CallMethod('RestoreCenter')
    -- Press only arms the native ring. All sends happen on hardware release.
    if down and self:GetAttribute('cpf-trigger') then
        local ring=self:GetFrameRef('ring')
        -- This opener always uses the native default hold mode. Global ring
        -- preferences, sticky selection, stick routing and controls stay native.
        ring:RunAttribute('SetContextAttribute','pressAndHold',true)
        ring:RunAttribute('Main',self:GetAttribute('cpf-ring-id'),true)
        self:CallMethod('BeginArtwork')
    elseif not down and not self:GetFrameRef('ring'):IsShown() then self:RunAttribute('cpf-cancel') end
]]
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
function Ping:Create(api,bridge)
    local cp,radial,layers=api.CPAPI,bridge.db.Radial,bridge.db.Layers
    local ring=self.ring
    local frame=api.CreateFrame('Button',OWNER,api.UIParent,'SecureActionButtonTemplate,SecureHandlerStateTemplate')
    api.Mixin(frame,cp.AdvancedSecureMixin)
    frame:Hide() frame:SetAlpha(0)
    frame:SetAttribute(cp.ActionPressAndHold,true)
    frame:RegisterForClicks('AnyDown','AnyUp')
    frame:SetFrameRef('ring',ring)
    frame:SetFrameRef('radial',radial)
    frame:SetFrameRef('layers',layers)
    frame:SetAttribute('clickbutton',ring)
    frame:SetAttribute('cpf-ring-id',self.RING_ID)
    frame:SetAttribute('cpf-cancel',self.Cancel)
    frame:SetAttribute('_onstate-cpf-combat',[[self:RunAttribute('cpf-cancel')]])
    local function capture(owner) owner.cpfCenterBefore=api.GetCVar(CENTER) end
    local function restore(owner)
        if owner.cpfCenterBefore~=nil and api.GetCVar(CENTER)=='1' then api.SetCVar(CENTER,owner.cpfCenterBefore) end
        owner.cpfCenterBefore=nil
    end
    frame.CaptureCenter,frame.RestoreCenter=capture,restore
    -- A separate unprotected timer owns only visibility. Never depend on the
    -- shared ring's OnUpdate, or turn cosmetic timing into secure input state.
    local monitor=api.CreateFrame('Frame',nil,api.UIParent)
    monitor:Hide()
    frame.EndArtwork=function()
        monitor:Hide()
        monitor.cpfMissingSince=nil
        ring.cpfVisibleAt=nil
        if ring.cpfAlphaBefore~=nil then
            ring:SetAlpha(ring.cpfAlphaBefore) ring.cpfAlphaBefore=nil
        end
    end
    frame.BeginArtwork=function()
        frame.EndArtwork()
        local alpha=ring:GetAlpha()
        ring.cpfAlphaBefore=alpha>0 and alpha or 1
        ring.cpfVisibleAt=api.GetTime()+self.HOLD_SECONDS
        ring:SetAlpha(0)
        monitor:Show()
    end
    monitor:SetScript('OnUpdate',function()
        if not frame:GetAttribute('cpf-trigger') or not ring:IsShown()
            or ring:GetAttribute('state')~=self.RING_ID then return frame.EndArtwork() end
        if ring.cpfVisibleAt and api.GetTime()>=ring.cpfVisibleAt then
            ring:SetAlpha(ring.cpfAlphaBefore or 1) ring.cpfVisibleAt=nil
        end
        -- Only a definitive device change suppresses artwork. A transient nil
        -- sample cannot strand the shared header at alpha zero indefinitely.
        local state=api.C_GamePad.GetDeviceMappedState()
        if not state then monitor.cpfMissingSince=monitor.cpfMissingSince or api.GetTime()
        else monitor.cpfMissingSince=nil end
        if (state and state.name~=frame:GetAttribute('cpf-device'))
            or (monitor.cpfMissingSince and api.GetTime()-monitor.cpfMissingSince>=.25) then
            ring:ClearInstantly()
            frame.EndArtwork()
            if not api.InCombatLockdown() then frame:Execute([[self:RunAttribute('cpf-cancel')]]) end
        end
    end)
    self.monitor=monitor
    ring.CPFCaptureCenter,ring.CPFRestoreCenter=capture,restore
    ring:SetAttribute('cpf-ping-ring-id',self.RING_ID)
    ring:SetFrameRef('cpf-ping',frame)
    -- Native account ring can also be opened normally through CP settings.
    -- Capture/restore its inline cursor centering without dispatching publicly.
    ring:WrapScript(ring,'PreClick',[[
        self:SetAttribute('cpf-ping-release',nil)
        local id=self:GetAttribute('cpf-ping-ring-id')
        local ping=self:GetFrameRef('cpf-ping')
        if button==id or self:GetAttribute('state')==id then self:CallMethod('CPFCaptureCenter') end
        -- Alias only this opener's release for native LAST matching. Do not
        -- override the shared header's state: other rings must choose their set.
        if ping and ping:GetAttribute('cpf-trigger')==button and self:GetAttribute('state')==id then
            local index=self:RunAttribute('GetIndex')
            if not index and self:RunAttribute('GetContextAttribute','stickySelect') then
                index=self:RunAttribute('GetStickyIndex')
            end
            self:SetAttribute('cpf-ping-release',not index)
            return id,true
        end
    ]],[[
        -- Native Main/Commit has already selected its action. With no selected
        -- type, this opener supplies a contextual aimed release action. Never
        -- add a second ping to a selected/sticky/native custom ring action.
        if self:GetAttribute('cpf-ping-release') and not self:IsShown() and not self:GetAttribute('typerelease') then
            local unit;
            if UnitExists('softenemy') then unit='softenemy'
            elseif UnitExists('softfriend') then unit='softfriend' end
            local body=unit and ('/ping [@'..unit..',exists]')
                or '/console GamePadCursorCentering 1\n/ping [@cursor]'
            self:SetAttribute('macrotext',body)
            self:SetAttribute('typerelease','macro')
            self:SetAttribute('cpf-ping-fallback',true)
        end
    ]])
    ring:WrapScript(ring,'PostClick',[[
        self:CallMethod('CPFRestoreCenter')
        self:SetAttribute('cpf-ping-release',nil)
        if self:GetAttribute('cpf-ping-fallback') then
            self:SetAttribute('cpf-ping-fallback',nil)
            self:SetAttribute('typerelease',nil)
            self:SetAttribute('macrotext',nil)
        end
    ]])
    frame:WrapScript(frame,'PreClick',self.Pre)
    frame:WrapScript(frame,'PostClick',self.Post)
    frame:WrapScript(frame,'OnHide',[[self:RunAttribute('cpf-cancel')]])
    frame:WrapScript(ring,'OnHide',[[
        if control:GetAttribute('cpf-trigger') then control:RunAttribute('cpf-cancel') end
    ]])
    ring:HookScript('OnHide',frame.EndArtwork)
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
    api.RegisterStateDriver(frame,'cpf-combat','[combat] combat; peace')
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
        if header~=self.frame and header~=self.ring then
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
    local function release()
        if self.frame then
            self.frame:Execute([[self:SetAttribute('cpf-commit',nil) self:RunAttribute('cpf-cancel')]])
            self.frame:SetAttribute('cpf-enabled',nil)
            self.layers:ReleaseAll(OWNER)
            self.claims={}
        end
    end
    local function unavailable(reason) release() return false,reason end
    if not enabled then
        release()
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
        or type(api.SetCVar)~='function' or type(api.RegisterStateDriver)~='function' or type(api.GetTime)~='function'
        or type(cp.Static)~='function'
        or (type(api.LibStub)~='function' and (type(api.LibStub)~='table'
            or type((getmetatable(api.LibStub) or {}).__call)~='function'))
        or not api.C_GamePad or type(api.C_GamePad.GetDeviceMappedState)~='function' then
        return unavailable('qualified native secure ping selector unavailable; native binding retained')
    end
    for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
        local owner=bridge.db[name]
        if not owner or type(owner.IsShown)~='function' or type(owner.IsProtected)~='function'
            or (name~='Cursor' and not owner:IsProtected()) then
            return unavailable('qualified native ping owner unavailable: '..name..'; native binding retained')
        end
    end
    if bridge.db('layersTapLatch') or bridge.db('layersDoubleBar') or bridge.db('layersOrdered') then
        return unavailable('secure ping selector requires standard native modifier layers; native binding retained')
    end
    local keys={}
    for _,key in ipairs({api.GetBindingKey('TOGGLEPINGLISTENER')}) do if key:match('PAD') then keys[key]=true end end
    local gamepad=bridge.db.Gamepad
    if gamepad and type(gamepad.GetBindings)=='function' then
        for button,row in pairs(gamepad:GetBindings()) do
            for prefix,binding in pairs(row) do if binding=='TOGGLEPINGLISTENER' then keys[prefix..button]=true end end
        end
    end
    if self.frame and self.frame:GetAttribute('cpf-enabled') and self.ring==bridge.db.Rings
        and self.layers==bridge.db.Layers and self.layers:GetAttribute('Resolve')==self.Resolve
        and self.env.IsDataReady and self.env.IsSpellValidationReady and not self.ring.Data[self.RING_ID]
        and self.ring.Shared[self.RING_ID] and (self.ring.Shared[self.RING_ID][0] or {}).cpfPingVersion
        and Addon.Core.Equal(self.claims,keys) then
        self:CaptureRadialOwners(bridge)
        return true,'secure release-only ping; native account ring gesture preserved'
    end
    release()
    local ready,reason=self:PrepareAccountRing(api,bridge)
    if not ready then return false,reason end
    if not self.frame then self:Create(api,bridge) end
    self:CaptureRadialOwners(bridge)
    if not self:InstallResolver() then return false,'native resolver changed by another owner; native ping binding retained' end
    self.frame:SetAttribute('cpf-enabled',true)
    for key in pairs(keys) do
        if self.layers:Claim(OWNER,'OVERRIDE',key,'click',self.frame,key) then self.claims[key]=true end
    end
    return true,'R3 release aimed/selected ping; no button-down ping; hold-only native account ring; Retail acceptance pending'
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
