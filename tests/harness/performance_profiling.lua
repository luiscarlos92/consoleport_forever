TEST_SUCCESS=nil
local D=Addon.Diagnostics
local clockCalls,tick=0,0
function debugprofilestop() clockCalls=clockCalls+1 tick=tick+1 return tick end
local function results() return false,nil,'third' end
local a,b,c=D:Measure('skin.full',results)
assert(a==false and b==nil and c=='third' and clockCalls==0,'disabled profiler changed callback or called clock')
assert(D:SetPerformance(true))
a,b,c=D:Measure('skin.full',results)
assert(a==false and b==nil and c=='third','enabled profiler lost return values')
local row=D.performance.scopes['skin.full']
assert(row.count==1 and row.totalMs==1 and row.peakMs==1,'scope aggregation incorrect')
for i=1,1000 do D:Measure('skin.full',results) end
assert(row.count==1001,'scope counter failed repeated calls')
local count=0 for _ in pairs(D.performance.scopes) do count=count+1 end
assert(count==1,'scope storage grew per invocation')
for i=1,100 do D:Measure('unknown-'..i,results) end
count=0 for _ in pairs(D.performance.scopes) do count=count+1 end
assert(count==1,'dynamic labels created unbounded profiler storage')
local oldSecret=issecretvalue local opaque={}
issecretvalue=function(v) return v==opaque end
debugprofilestop=function() return opaque end
D:Measure('runtime.full',results)
assert(not D.performance.scopes['runtime.full'],'opaque clock entered public timing')
issecretvalue=oldSecret
local backwards=2
debugprofilestop=function() local value=backwards backwards=backwards-1 return value end
a,b,c=D:Measure('runtime.full',results)
assert(a==false and c=='third' and not D.performance.scopes['runtime.full'],'backward clock manufactured a zero-cost sample')
debugprofilestop=function() clockCalls=clockCalls+1 tick=tick+1 return tick end
Addon.record={}
local summary=D:PerformanceSummary()
assert(summary:find('skin.full',1,true) and Addon.record.lastPerformanceEvidence.scopes['skin.full'].count==1001,'profile report not retained')
assert(D:SetPerformance(false))
local before=clockCalls D:Measure('skin.full',results)
assert(clockCalls==before,'disabled profiler retained clock overhead')
D:ResetPerformance()
assert(not D.performance.enabled and next(D.performance.scopes)==nil,'reset enabled profiling or retained counters')
TEST_SUCCESS=true
