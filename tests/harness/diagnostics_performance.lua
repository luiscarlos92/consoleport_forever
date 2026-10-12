TEST_SUCCESS=nil
local D,C=Addon.Diagnostics,Addon.Core
Addon.record={} Addon.VERSION='performance-test' Addon.CONFIG_REVISION=20
D.features={} D.entries={} D.visuals={banks={}} D.circle={rows={}} D.ping={}
for i=1,80 do D.circle.rows[i]={event='player-spellcast',sequence=i,time=i} end
for i=1,32 do D.visuals.banks[i]={icon={colour={1,1,1}},layers={cooldown={shown=true}}} end
D:SetFeature('test','ready','unchanged')
local saved=Addon.record.lastRuntimeDiagnostics
local circle,visuals=saved.circle,saved.visuals
local copy=C.Copy local tables=0
C.Copy=function(value,seen) if type(value)=='table' then tables=tables+1 end return copy(value,seen) end
for i=1,100 do D:SetFeature('test','ready','unchanged') end
assert(tables==0,'unchanged diagnostics copied history')
D:SetFeature('test','pending','new evidence')
assert(tables==1 and saved.circle==circle and saved.visuals==visuals,'one feature copied unrelated diagnostics')
assert(saved.features.test.status=='pending' and saved.features.test~=D.features.test,'feature persistence stale or aliased')
D.circle.rows[1].event='updated' D:Persist('circle')
assert(saved.circle.rows[1].event=='updated' and saved.visuals==visuals,'section persistence lost observation or copied visuals')
D.circle.rows[1].event='later'
assert(saved.circle.rows[1].event=='updated','persisted circle aliases mutable runtime')
D:Log('test','automatic log')
assert(saved.entries[#saved.entries].message=='automatic log','entries no longer persist immediately')
D.ping={error='new ping'} D:Persist('ping')
assert(saved.ping.error=='new ping','ping observation lost')
local oldRecord=Addon.record
Addon.record={}
D:SetFeature('test','pending','new evidence')
assert(Addon.record.lastRuntimeDiagnostics and Addon.record.lastRuntimeDiagnostics~=saved,'same feature suppressed a new owner snapshot')
assert(oldRecord.lastRuntimeDiagnostics==saved,'new owner overwrote prior diagnostic record')
C.Copy=copy
TEST_SUCCESS=true
