local _, Addon = ...
local Ping = {claims={}}
Addon.PingTargeting = Ping
local CENTER = 'GamePadCursorCentering'

-- Called only by our runOnUp hardware binding. The native listener still owns
-- tap, hold, radial selection, target eligibility, cooldowns and errors.
function Ping:Hardware(api, down)
    if down then
        if self.held then return end
        self.held=true
        local db=Addon.adapters and Addon.adapters.consoleport and Addon.adapters.consoleport.db
        local busy=false
        for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
            local frame=db and db[name]
            busy=busy or (frame and frame:IsShown())
        end
        if api.IsGamePadFreelookEnabled() and not api.IsGamePadCursorControlEnabled()
            and not busy then
            self.before=api.GetCVar(CENTER)
            api.SetCVar(CENTER, '1')
        end
        local ok,reason=pcall(api.C_Ping.TogglePingListener,true)
        if not ok then
            self.held=nil self:ReleaseCenter(api)
            error(reason)
        end
    elseif self.held then
        -- Releasing must use the same centered pointer as the initial press.
        local ok,reason=pcall(api.C_Ping.TogglePingListener,false)
        self.held=nil
        self:ReleaseCenter(api)
        if not ok then error(reason) end
    end
end
function Ping:ReleaseCenter(api)
    if self.before~=nil and api.GetCVar(CENTER)=='1' then api.SetCVar(CENTER,self.before) end
    self.before=nil
end
function Ping:Refresh(api, enabled, bridge)
    if api.InCombatLockdown() then return false,'ping route update deferred until combat ends' end
    if self.held then return false,'ping route update deferred until native release' end
    local layers=bridge and bridge.api.version=='3.3.10' and bridge.db.Layers
    if self.layers then self.layers:ReleaseAll(self.owner) end
    self.claims={}
    if not enabled then self:ReleaseCenter(api) return true,'native ping bindings retained' end
    if not layers or type(layers.Claim)~='function' or type(layers.ReleaseAll)~='function'
        or not api.C_Ping or type(api.C_Ping.TogglePingListener)~='function'
        or type(api.GetBindingKey)~='function' or type(api.IsGamePadFreelookEnabled)~='function'
        or type(api.IsGamePadCursorControlEnabled)~='function' then
        return false,'native controller layers/ping listener unavailable'
    end
    self.owner=self.owner or api.CreateFrame('Frame','ConsolePortForeverPingOwner',api.UIParent)
    self.layers=layers
    -- Use ConsolePort's arbiter: NAV/MODAL continue to outrank this OVERRIDE.
    -- Only actual native ping gamepad chords qualify. Keyboard F2 stays native.
    for _,key in ipairs({api.GetBindingKey('TOGGLEPINGLISTENER')}) do
        if type(key)=='string' and key:match('PAD[%w]+$') then
            if layers:Claim(self.owner,'OVERRIDE',key,'binding','CPF_GAMEPAD_PING') then self.claims[key]=true end
        end
    end
    return true,'controller ping pointer centered before native tap/hold sampling; Retail hardware acceptance pending'
end
function Ping:Observe(api, error)
    local snapshot={error=type(error)=='string' and error or 'ping target diagnostic',
        centering=api.GetCVar(CENTER),pingMode=api.GetCVar('pingMode'),foci={}}
    -- C_PingSecure is SecureOnly. Never call it or replace Blizzard callbacks.
    -- Public focus data is supporting evidence, not its privileged hit test.
    if api.GetMouseFoci then
        for index,frame in ipairs(api.GetMouseFoci()) do
            if index>8 then break end
            if not (frame.IsForbidden and frame:IsForbidden()) then
                snapshot.foci[#snapshot.foci+1]={name=frame:GetName() or '<unnamed>',
                    topLevel=frame.IsToplevel and frame:IsToplevel() or false}
            end
        end
    end
    if Addon.Diagnostics then
        Addon.Diagnostics.ping=snapshot
        Addon.Diagnostics:Log('ping',snapshot.error..'; centering='..tostring(snapshot.centering)..'; public focus='..(#snapshot.foci>0 and snapshot.foci[1].name or '<world>'))
    end
    return snapshot
end
BINDING_NAME_CPF_GAMEPAD_PING='Forever controller ping'
function ConsolePortForever_GamepadPing(down) Ping:Hardware(_G,down) end
