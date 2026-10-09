fire('PLAYER_LOGIN') flush()
local native=Addon.adapters.bindings.native
local characterSet=native.api.CharacterSet
local accountSet=native.api.AccountSet
local chord=Addon.ClassActions.LEFT_CHORD
banks[characterSet][chord]='CLICK NativeUtility:Auras'
Addon.db.lastProjectedGUID=Addon.guid
bindingSet=characterSet Addon:CaptureControllerEdits()
local before=Addon.Core.Copy(Addon.record.controllerBindings)
local sharedBefore=Addon.Core.Copy(Addon.db.shared.faceBindings)
assert(before[chord]=='CLICK NativeUtility:Auras')
-- Native bank selection emits UPDATE_BINDINGS; it must not erase the GUID's
-- archive using account defaults (the source path absent from older tests).
bindingSet=accountSet banks[accountSet][chord]='TARGETNEARESTFRIEND'
Addon:CaptureControllerEdits()
assert(Addon.Core.Equal(Addon.record.controllerBindings,before),'account view erased character class binding')
assert(Addon.Core.Equal(Addon.db.shared.faceBindings,sharedBefore),'account view rewrote owned face bindings')
bindingSet=characterSet
banks[characterSet][chord]='PLAYER_EDIT'
Addon:CaptureControllerEdits()
assert(Addon.record.controllerBindings[chord]=='PLAYER_EDIT','legitimate character binding edit not retained')
TEST_SUCCESS=true
