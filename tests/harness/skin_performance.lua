TEST_SUCCESS=nil
combat=false installed=true flush()
Addon:RefreshConsolePortSkin()
local full,layout,visual=0,0,0
local oldFull,oldLayout,oldVisual=Addon.RefreshConsolePortSkin,Addon.HUDPresentation.LayoutGuard,Addon.RefreshFaceAvailability
function Addon:RefreshConsolePortSkin(...) full=full+1 return oldFull(self,...) end
Addon.HUDPresentation.LayoutGuard=function(...) layout=layout+1 return oldLayout(...) end
function Addon:RefreshFaceAvailability(...) visual=visual+1 return oldVisual(self,...) end
for i=1,100 do fire('ACTIONBAR_UPDATE_USABLE') end
assert(#timers==0 and full==0 and layout==0 and visual==100,'usability event queued structural refresh or delayed feedback')
flush()
assert(full==0 and layout==0,'routine availability rebuilt layout')
-- The target-dependent command icon must change in the event turn.
local face=ConsolePortGroupL2.buttons.PAD4
face._state_type='custom' face.attributes.state=''
function UnitExists() return true end
local handler
for _,frame in ipairs(eventFrames) do
    if frame.events and frame.events.ACTIONBAR_UPDATE_USABLE then handler=frame.OnEvent break end
end
assert(handler,'registered skin event handler unavailable')
handler(nil,'PLAYER_TARGET_CHANGED')
assert(face.icon.atlas=='crosshair_inspect_32' and #timers==0,'target icon stale until layout timer')
-- A slot notification must not repaint unrelated faces. All-zero/nil is global.
local chosen=ConsolePortGroupL2.buttons.PAD1
local unrelated=ConsolePortGroupR2.buttons.PAD1
chosen._state_type='action' chosen._state_action=17
unrelated._state_type='action' unrelated._state_action=18
local chosenCalls,otherCalls=0,0
function chosen:IsUsable() chosenCalls=chosenCalls+1 return true,false end
function unrelated:IsUsable() otherCalls=otherCalls+1 return true,false end
handler(nil,'ACTIONBAR_SLOT_CHANGED',17)
assert(chosenCalls>0 and otherCalls==0 and #timers==0,'single slot repainted unrelated faces')
-- Structural requests retain a bounded readiness retry, not one per event.
for i=1,20 do fire('UPDATE_BINDINGS') end
assert(#timers<=2,'structural event retry workers accumulated')
flush()
assert(full<=2 and layout<=2,'structural burst repeated layout per event')
-- Native art reset still repairs the affected face synchronously.
chosen:UpdateLocal()
assert(chosen.__cpfFaceMask and chosen.NormalTexture.shown,'native local art repair was skipped')
local before=full
combat=true fire('PLAYER_REGEN_DISABLED')
assert(#timers==0,'combat transition scheduled protected layout')
chosen:UpdateLocal()
assert(Addon.skinRefreshPending,'combat native art repair did not retain deferred geometry')
for i=1,20 do fire('ACTIONBAR_UPDATE_USABLE') end
assert(#timers==0,'pending combat geometry caused routine timer loop')
fire('UPDATE_BINDINGS')
assert(#timers==0 and Addon.skinRefreshPending,'combat structural event queued doomed workers')
Addon:RequestSkinRefresh() flush()
assert(Addon.skinRefreshPending,'combat structural deferral lost')
combat=false fire('PLAYER_REGEN_ENABLED') flush()
assert(not Addon.skinRefreshPending and full>before,'deferred skin setup did not resume')
installed=false
for i=1,20 do fire('ACTIONBAR_UPDATE_USABLE') end
assert(#timers==0,'inactive skin accumulated workers')
installed=true
TEST_SUCCESS=true
