-- Actual bootstrap/event/persistence. Security-label C API is explicitly a
-- double; observing a label is not proof of an in-game causal taint chain.
TEST_SUCCESS=nil
fire=function(event,...)
    for _,frame in ipairs(frames) do if frame.events[event] then frame.event(frame,event,...) end end
end
fire('PLAYER_LOGIN') flush()
local beforeWrites=writes
local opaque={}
issecretvalue=function(value) return rawequal(value,opaque) end
local inspections=0
MultiBarLeftButton1=setmetatable({}, {__index=function() error('logger read native button field') end})
function issecurevariable(object,field)
    assert(object==MultiBarLeftButton1)
    inspections=inspections+1
    if field=='action' then return false,'WriterExample' end
    return true
end
function GetTime() return 12 end
local record=Addon.record
local total=Addon.Diagnostics.blocked and Addon.Diagnostics.blocked.total or 0
for i=1,1000 do fire('ADDON_ACTION_BLOCKED','ConsolePort','MultiBarLeftButton1:SetAttribute()') end
local log=record.lastRuntimeDiagnostics.blocked
assert(log and log.total==total+1000,'foreign-addon blocked event not retained automatically')
assert(#log.rows==1 and log.rows[1].count==1000,'repeated blocked events not aggregated')
local row=log.rows[1]
assert(row.addon=='ConsolePort' and row.fields.action.writer=='WriterExample' and row.fields.action.secure==false,
    'read-only security label lost')
assert(inspections==6000 and writes==beforeWrites,'diagnostic observer performed a game/configuration write')
local original=record.lastRuntimeDiagnostics.blocked.rows[1].count
Addon.Diagnostics.blocked.rows[1].count=1001
assert(record.lastRuntimeDiagnostics.blocked.rows[1].count==original,'saved blocked evidence aliases live aggregate')
fire('ADDON_ACTION_FORBIDDEN',opaque,opaque)
log=record.lastRuntimeDiagnostics.blocked
assert(log.rows[2].addon=='unknown' and log.rows[2].func=='unknown','opaque blocked payload leaked')
for i=1,50 do fire('ADDON_ACTION_BLOCKED','Addon'..i,'ProtectedCall'..i) end
assert(#record.lastRuntimeDiagnostics.blocked.rows==16,'blocked evidence rows unbounded')
assert(#Addon.Diagnostics.entries<=80 and writes==beforeWrites,'diagnostic event changed existing bounds/ownership')
local other={}
Addon.record=other
Addon.Diagnostics:Persist()
assert(not other.lastRuntimeDiagnostics.blocked.rows,'previous GUID blocked evidence copied by full snapshot')
fire('ADDON_ACTION_FORBIDDEN','ConsolePort_Forever','NativeCall')
assert(other.lastRuntimeDiagnostics.blocked.total==1 and #other.lastRuntimeDiagnostics.blocked.rows==1,
    'blocked evidence leaked between GUID owners')
Addon.record=record
TEST_SUCCESS=true
