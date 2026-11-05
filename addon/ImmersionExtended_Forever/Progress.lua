local _, NS = ...
local Core, Progress = NS.Core, {}
Progress.__index = Progress
NS.Progress = Progress

function Progress.New(api)
    return setmetatable({api = api, serial = 0, writes = 0,
        hooked = setmetatable({}, {__mode = 'k'})}, Progress)
end

function Progress:Eligible(frame)
    local api, cfg = self.api, self.api.ImmersionSetup
    local talk = frame and frame.TalkBox
    return frame == self.frame and api.ImmersionFrame == frame and Core.Writable(api)
        and Core.Loaded(api, 'Immersion') and frame:IsShown() and talk:IsVisible()
        and frame.lastEvent == 'QUEST_PROGRESS' and talk.lastEvent == 'QUEST_PROGRESS'
        and talk.Elements:IsShown() and talk.Elements.Progress:IsShown()
        and not (type(frame.IsProtected) == 'function' and frame:IsProtected())
        and type(cfg) == 'table' and Core.Known(api, cfg.boxpoint)
        and type(cfg.boxpoint) == 'string' and cfg.boxpoint:match('Bottom')
        and Core.Finite(api, cfg.anidivisor) and cfg.anidivisor > 0 and not cfg.nameplatemode
        and Core.Finite(api, cfg.elementscale) and cfg.elementscale > 0
end

function Progress:Queue()
    self.serial = self.serial + 1
    self.ticket = nil
    local api, frame = self.api, self.frame
    if not frame or not self:Eligible(frame) then return end
    local quest = api.GetQuestID()
    if not Core.Finite(api, quest) or quest <= 0 then return end
    self.ticket = {serial = self.serial, quest = quest, frame = frame}
    self:Schedule()
end

function Progress:Schedule()
    if self.queued or not self.ticket then return end
    self.queued = true
    local ticket, api = self.ticket, self.api
    -- Native Elements performs its own next-frame measurement. Run after it.
    api.RunNextFrame(function() api.RunNextFrame(function()
        self.queued = false
        if ticket ~= self.ticket then self:Schedule(); return end
        self.ticket = nil
        local frame = ticket.frame
        if ticket.serial ~= self.serial or not self:Eligible(frame) then return end
        local current = api.GetQuestID()
        if not Core.Known(api, current) or current ~= ticket.quest then return end
        local _, height = frame.TalkBox.Elements.Progress:GetSize()
        if not Core.Finite(api, height) or height <= 1 then return end
        local offset = (height + 48) * api.ImmersionSetup.elementscale
        if not Core.Finite(api, offset) then return end
        local old = frame.TalkBox.extraY
        if Core.Finite(api, old) and math.abs(old - offset) < .3 then return end
        frame.TalkBox:SetExtraOffset(offset)
        self.writes = self.writes + 1
    end) end)
end

function Progress:Install()
    local api, frame = self.api, self.api.ImmersionFrame
    local talk = frame and frame.TalkBox
    local elements = talk and talk.Elements
    local progress = elements and elements.Progress
    if not Core.Loaded(api, 'Immersion') or not frame
        or type(frame.QUEST_PROGRESS) ~= 'function' or type(frame.OnEvent) ~= 'function'
        or type(frame.HookScript) ~= 'function' or type(frame.IsShown) ~= 'function'
        or not talk or type(talk.SetExtraOffset) ~= 'function' or type(talk.IsVisible) ~= 'function'
        or not progress or type(progress.GetSize) ~= 'function' or type(progress.IsShown) ~= 'function'
        or type(elements.IsShown) ~= 'function' or type(api.RunNextFrame) ~= 'function'
        or type(api.GetQuestID) ~= 'function' or type(api.hooksecurefunc) ~= 'function' then
        self.frame, self.ticket = nil, nil
        self.serial = self.serial + 1
        return false
    end
    self.frame = frame
    if not self.hooked[frame] then
        self.hooked[frame] = true
        -- Immersion's mixin captures OnEvent in a separate frame-script slot.
        -- Hook that script after both lastEvent fields have been updated.
        -- One posthook also covers QUEST_ITEM_UPDATE without duplicate scheduling.
        frame:HookScript('OnEvent', function()
            if self.frame == frame then self:Queue() end
        end)
        frame:HookScript('OnHide', function() self.serial = self.serial + 1; self.ticket = nil end)
    end
    return true
end
