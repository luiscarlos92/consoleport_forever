local _, Addon = ...
local Ping = {claims={}}
Addon.PingTargeting = Ping
local CENTER = 'GamePadCursorCentering'

-- Observe the existing native mouse input script. Never dispatch a ping from
-- addon Lua: even a hardware callback cannot call the restricted C_Ping API.
-- The engine keeps TOGGLEPINGLISTENER, including its native runOnUp behavior.
function Ping:ButtonDown(api, button)
    if not self.enabled then return end
    if self.releasing then
        self.generation=self.generation+1
        self.releasing=nil self.held=nil self:ReleaseCenter(api)
    end
    if self.held then return end
    local cp=api.CPAPI
    if cp.GetBindingAction(cp.CreateKeyChord(button),true)~='TOGGLEPINGLISTENER' then return end
    self.held=button
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
end
function Ping:ButtonUp(api, button)
    if self.held~=button then return end
    self.releasing=true
    -- The input script runs before the binding's native up action. Restore on
    -- the next frame, after Blizzard has sampled the pointer/sent the ping.
    local generation=self.generation
    api.C_Timer.After(0,function()
        if self.generation~=generation or self.held~=button then return end
        self.held=nil self.releasing=nil
        self:ReleaseCenter(api)
    end)
end
function Ping:ReleaseCenter(api)
    if self.before~=nil and api.GetCVar(CENTER)=='1' then api.SetCVar(CENTER,self.before) end
    self.before=nil
end
function Ping:Refresh(api, enabled, bridge)
    if self.held and enabled then return false,'ping cursor update deferred until native release' end
    self.generation=(self.generation or 0)+1
    self.enabled=false
    self.held=nil self.releasing=nil
    self:ReleaseCenter(api)
    if not enabled then return true,'native ping bindings retained' end
    local mouse=bridge and bridge.api.version=='3.3.10' and bridge.db.Mouse
    local cp=api.CPAPI
    if not mouse or type(mouse.HookScript)~='function' or not cp
        or type(cp.CreateKeyChord)~='function' or type(cp.GetBindingAction)~='function'
        or not api.C_Timer or type(api.C_Timer.After)~='function'
        or type(api.IsGamePadFreelookEnabled)~='function'
        or type(api.IsGamePadCursorControlEnabled)~='function' then
        return false,'native controller mouse input observer unavailable; native ping binding retained'
    end
    if self.mouse~=mouse then
        self.mouse=mouse
        mouse:HookScript('OnGamePadButtonDown',function(frame,button)
            if self.mouse==frame then self:ButtonDown(api,button) end
        end)
        mouse:HookScript('OnGamePadButtonUp',function(frame,button)
            if self.mouse==frame then self:ButtonUp(api,button) end
        end)
    end
    self.enabled=true
    return true,'native secure ping binding retained; passive pointer preparation/restoration; Retail hardware acceptance pending'
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
