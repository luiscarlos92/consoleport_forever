local _, NS = ...
local Core = {}
NS.Core = Core

function Core.Known(api, value)
    return not api.issecretvalue or not api.issecretvalue(value)
end

function Core.Finite(api, value)
    return Core.Known(api, value) and type(value) == 'number'
        and value == value and value > -math.huge and value < math.huge
end

function Core.Loaded(api, name)
    return api.C_AddOns and type(api.C_AddOns.IsAddOnLoaded) == 'function'
        and api.C_AddOns.IsAddOnLoaded(name)
end

function Core.Client(api)
    return api.WOW_PROJECT_CAMELOT ~= nil and api.WOW_PROJECT_ID == api.WOW_PROJECT_CAMELOT
end

function Core.Writable(api)
    local editor = api.EditModeManagerFrame
    return type(api.InCombatLockdown) == 'function' and not api.InCombatLockdown()
        and (not editor or (type(editor.IsShown) == 'function' and not editor:IsShown()))
end

function NS.New(api)
    if not Core.Client(api) then return nil, 'Forever client required' end
    local runtime = {api = api}
    runtime.rewards = NS.Rewards.New(api)
    runtime.progress = NS.Progress.New(api)
    function runtime:Refresh()
        self.rewards:Observe()
        self.rewards:Install()
        self.progress:Install()
        self.progress:Queue()
        local editor = api.EditModeManagerFrame
        if editor and type(editor.HookScript) == 'function' and self.editor ~= editor then
            self.editor = editor
            editor:HookScript('OnHide', function() self.progress:Queue() end)
        end
    end
    function runtime:Status()
        local r, p = self.rewards, self.progress
        return ('Immersion Extended: arrows=%s; layout=%s; queries=%d; layouts=%d'):format(
            r.ready and r.installed and 'ready' or 'waiting for Pawn/Immersion',
            p.frame and 'available' or 'unavailable', r.queries, p.writes)
    end
    return runtime
end
