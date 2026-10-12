-- Real bootstrap/event/Persist calls; native hook engine is modeled.
TEST_SUCCESS=nil
ConsolePortForeverDB.characters.A.appliedRevision=18
ConsolePortForeverDB.characters.A.declinedRevision=nil
local nativeCalls=0
function SpellStopCasting() nativeCalls=nativeCalls+1 return true end
function hooksecurefunc(target,method,callback)
    if type(target)=='string' then
        callback=method method=target target=_G
    end
    local fn=assert(target[method])
    target[method]=function(...)
        local result=table.pack(fn(...)) callback(...)
        return table.unpack(result,1,result.n)
    end
end
fire=function(event,...)
    for _,frame in ipairs(frames) do if frame.events[event] then frame.event(frame,event,...) end end
end
fire('PLAYER_LOGIN') flush()
assert(nativeCalls==0,'automatic observer attempted game action')
local record=Addon.record
assert(record.lastRuntimeDiagnostics.circle and #record.lastRuntimeDiagnostics.circle.rows>0,'login did not persist automatic Circle snapshot')
fire('UNIT_SPELLCAST_START','player',{}, {})
SpellStopCasting() -- Modeled engine/native command, not a product call.
fire('UNIT_SPELLCAST_INTERRUPTED','player',{}, {})
local log=record.lastRuntimeDiagnostics.circle
assert(log.calls.SpellStopCasting==1,'automatic native cancel call observation not installed')
assert(log.rows[#log.rows].event=='UNIT_SPELLCAST_INTERRUPTED','bootstrap omitted player spell log event')
assert(nativeCalls==1,'logger duplicated native cancellation')
local prior=log.sequence
fire('UNIT_SPELLCAST_START','target',{}, {})
assert(record.lastRuntimeDiagnostics.circle.sequence==prior,'bootstrap logged other unit spell details')
assert(shown and shown.name=='CPF_PLAN_REVIEW','logging disrupted automatic update review')
choose(2)
fire('PLAYER_LOGOUT')
assert(record.lastRuntimeDiagnostics.circle.rows[#record.lastRuntimeDiagnostics.circle.rows].event=='PLAYER_LOGOUT','logout did not retain Circle evidence')
TEST_SUCCESS=true
