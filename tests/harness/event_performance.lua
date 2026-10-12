TEST_SUCCESS=nil
fire('PLAYER_LOGIN') flush()
local full,modes,rings,contexts=0,0,0,0
local oldFull,oldModes,oldRings,oldContexts=Addon.Refresh,Addon.RefreshModes,Addon.RefreshRings,Addon.RefreshContextPresentation
function Addon:Refresh(...) full=full+1 return oldFull(self,...) end
function Addon:RefreshModes(...) modes=modes+1 return oldModes(self,...) end
function Addon:RefreshRings(...) rings=rings+1 return oldRings(self,...) end
function Addon:RefreshContextPresentation(...) contexts=contexts+1 return oldContexts(self,...) end
local adapters=Addon.adapters
local observations=0
local recordObservation=Addon.CircleCancel.Record
function Addon.CircleCancel:Record(...) observations=observations+1 return recordObservation(self,...) end
for i=1,20 do fire('ACTIONBAR_SLOT_CHANGED') end
flush()
assert(full==0 and modes==1 and rings==0 and Addon.adapters==adapters,'action event rebuilt configuration/rings')
assert(observations==1,'scoped action refresh lost automatic route observations')
full,modes,rings,contexts=0,0,0,0
for i=1,20 do fire('CURSOR_CHANGED') fire('ITEM_LOCK_CHANGED') fire('MERCHANT_SHOW') end
flush()
assert(full==0 and modes==0 and rings==0 and contexts==1,'context event rebuilt configuration/modes/rings')
full,modes,rings,contexts=0,0,0,0
for i=1,20 do fire('BAG_UPDATE_DELAYED') end
flush()
assert(full==0 and modes==0 and rings==1 and contexts==1,'bag event lost ring invalidation or rebuilt configuration')
full,modes,rings,contexts=0,0,0,0
fire('ACTIONBAR_SLOT_CHANGED') fire('UPDATE_BINDINGS') fire('CURSOR_CHANGED') flush()
assert(full==1 and modes==1 and rings==1,'full refresh failed to subsume narrower requests')
full,modes,rings,contexts=0,0,0,0
Addon.runtimeReady=nil
fire('CURSOR_CHANGED') flush()
assert(full==1,'late readiness failed to retry full initialization')
full,modes,rings,contexts=0,0,0,0
-- Edit Mode can close without saving a layout; the next ordinary event must
-- resume a previously deferred review, rather than treating readiness as complete.
Addon.forcePrompt=true
fire('CURSOR_CHANGED') flush()
assert(full==1 and Addon.Prompt.active,'deferred review stranded behind scoped context refresh')
choose(2)
full,modes,rings,contexts=0,0,0,0
local pendingReload=Addon.record.pendingReload
Addon.record.pendingReload='pending-verification'
fire('CURSOR_CHANGED') flush()
assert(full==1,'pending reload verification skipped by scoped context refresh')
Addon.record.pendingReload=pendingReload
full,modes,rings,contexts=0,0,0,0
combat=true local before=writes
fire('ACTIONBAR_SLOT_CHANGED') flush()
assert(full==0 and modes==1 and writes==before,'narrow refresh mutated protected state in combat')
combat=false fire('PLAYER_REGEN_ENABLED') flush()
assert(full==1,'combat-end did not retry complete pending setup')
TEST_SUCCESS=true
