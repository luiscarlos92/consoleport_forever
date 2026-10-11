local callbacks = {}
local frames = {}

local function newFrame(name)
    local frame = {shown=true, name=name, hides=0, shows=0}
    function frame:IsShown() return self.shown end
    function frame:Hide() self.shown=false self.hides=self.hides+1 end
    function frame:Show() self.shown=true self.shows=self.shows+1 end
    frames[name]=frame
    _G[name]=frame
end

newFrame("MicroButtonAndBagsBar")
newFrame("MicroMenuContainer")
newFrame("BagsBar")

ConsolePortForeverDB = {installedSchema=2}
C_Timer = {After=function(_, callback) callback() end}
function InCombatLockdown() return false end
function CreateFrame()
    local frame = {events={}}
    function frame:RegisterEvent(event) self.events[event]=true end
    function frame:SetScript(kind, script) self[kind]=script end
    _G.__runtimeEventFrame=frame
    return frame
end
EventRegistry = {
    RegisterCallback=function(_, event, callback) callbacks[event]=callback end,
}

local Addon = {SCHEMA=2}
assert(loadfile("_retail_/Interface/AddOns/ConsolePort_Forever/Runtime.lua"))("ConsolePort_Forever", Addon)
__runtimeEventFrame.OnEvent(__runtimeEventFrame, "PLAYER_ENTERING_WORLD")
for name, frame in pairs(frames) do assert(not frame.shown and frame.hides > 0, name.." was not hidden") end

callbacks["EditMode.Enter"]()
for name, frame in pairs(frames) do assert(frame.shown and frame.shows == 1, name.." was not restored for Edit Mode") end

callbacks["EditMode.Exit"]()
for name, frame in pairs(frames) do assert(not frame.shown and frame.hides > 1, name.." was not hidden after Edit Mode") end

print("PASS menu hidden normally -> restored for Edit Mode -> hidden on exit")
