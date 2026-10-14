-- Security labels, stack API and the C posthook mechanism are fault-injection
-- doubles. This executes actual bootstrap installation/persistence, not engine taint.
TEST_SUCCESS=nil
fire=function(event,...)
    for _,frame in ipairs(frames) do if frame.events[event] then frame.event(frame,event,...) end end
end
fire('PLAYER_LOGIN') flush()
local originalRecord=Addon.record
local beforeWrites=writes
local labels,hooks={},{}
local inspections,stacks=0,0
local opaque={}
issecretvalue=function(value) return rawequal(value,opaque) end
ActionBarActionButtonMixin={UpdateAction=function() return 'native-result',false end}
local expected={}
for _,prefix in ipairs({'ActionButton','MultiBarBottomLeftButton','MultiBarBottomRightButton',
    'MultiBarLeftButton','MultiBarRightButton','MultiBar5Button','MultiBar6Button','MultiBar7Button','OverrideActionBarButton'}) do
    for i=1,(prefix=='OverrideActionBarButton' and 6 or 12) do
        local name=prefix..i
        local object=setmetatable({UpdateAction=ActionBarActionButtonMixin.UpdateAction},{
            __index=function(_,key) if key=='action' then error('native action value read') end end,
            __newindex=function(_,key) error('native object field write: '..key) end})
        _G[name]=object expected[#expected+1]=object labels[object]=true
    end
end
function issecurevariable(object,field)
    assert(field=='action','unexpected native field read')
    inspections=inspections+1
    if labels[object]=='throw' then error('unavailable label') end
    if labels[object]==opaque then return opaque,opaque end
    return labels[object],labels[object]==false and 'InjectedWriter' or nil
end
function debugstack(start,head,tail)
    assert(start==3 and head==12 and tail==6)
    stacks=stacks+1
    return string.rep('caller-source:10\n',500)
end
function hooksecurefunc(object,method,callback)
    assert(method=='UpdateAction' and not hooks[object],'duplicate/foreign native posthook')
    hooks[object]=callback
end
local function nativeCall(object)
    local a,b=object.UpdateAction(object,true)
    if hooks[object] then hooks[object](object,true) end
    assert(a=='native-result' and b==false,'native return changed')
end
-- A foreign method is skipped, not replaced or invoked.
local foreign=ActionButton12
foreign.UpdateAction=function() error('foreign owner invoked') end
local previousGetCVar=GetCVar
local logging='2'
GetCVar=function(name) if name=='taintLog' then return logging end return previousGetCVar(name) end
assert(Addon:InitializeStore())
assert(not next(hooks),'diagnostic hooks installed while engine taint logging enabled')
logging=opaque assert(Addon:InitializeStore())
assert(not next(hooks),'diagnostic hooks installed with unknown engine logging state')
logging='0'
assert(Addon:InitializeStore())
assert(hooks[expected[1]] and not hooks[foreign],'native posthook not installed by bootstrap')
assert(stacks==0,'clean startup collected stacks')
local before=inspections
assert(Addon:InitializeStore())
assert(inspections==before,'repeated store initialization rescanned native buttons')
labels[expected[1]]=false nativeCall(expected[1])
local log=Addon.record.lastRuntimeDiagnostics.actionTrace
assert(log and #log.rows==1,'first observed taint transition not retained automatically')
local row=log.rows[1]
assert(row.object=='ActionButton1' and row.phase=='after-update' and row.previousSecure==true
    and row.writer=='InjectedWriter' and #row.stack==3072,'transition labels/stack missing or unbounded')
local detached=row.stack
Addon.Diagnostics.actionTrace.rows[1].stack='changed'
assert(log.rows[1].stack==detached,'saved action trace aliases live rows')
for i=1,1000 do nativeCall(expected[1]) end
assert(stacks==1 and #Addon.Diagnostics.actionTrace.rows==1,'unchanged taint repeatedly collected stacks')
labels[expected[2]]='throw' nativeCall(expected[2])
labels[expected[3]]=opaque nativeCall(expected[3])
assert(#Addon.Diagnostics.actionTrace.rows==1,'failed/opaque labels retained')
labels[expected[2]]=true labels[expected[3]]=true
for i=2,#expected do if hooks[expected[i]] then labels[expected[i]]=false nativeCall(expected[i]) end end
assert(#Addon.Diagnostics.actionTrace.rows==16 and stacks==16,'first-transition evidence bound failed')
before=inspections
for i=1,1000 do nativeCall(expected[1]) end
assert(inspections==before,'full trace did not stop inspections')
assert(writes==beforeWrites,'passive tracing wrote game/configuration state')
Addon.record={}
Addon.Diagnostics:Persist()
assert(not Addon.record.lastRuntimeDiagnostics.actionTrace.rows,'trace copied between GUID owners')
-- Initial contamination is labeled separately, limited to four snapshots, and
-- never presented as a captured clean-to-tainted transition.
Addon.Diagnostics:InstallNativeActionTrace(_G)
log=Addon.record.lastRuntimeDiagnostics.actionTrace
assert(log and #log.rows==4,'initial contaminated snapshot bound failed')
assert(log.rows[1].phase=='initial' and log.rows[1].previousSecure==nil,'initial snapshot mislabeled as transition')
Addon.record=originalRecord
TEST_SUCCESS=true
