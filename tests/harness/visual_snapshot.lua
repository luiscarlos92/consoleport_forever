-- Observe real getter output; retain no secret values in saved diagnostics.
installed=true Addon.record={appliedRevision=17}
local nativeUsable,nativeMana=true,false
local token={}
function issecretvalue(value) return value==token end
local face=ConsolePortGroupL2.buttons.PAD1
face._state_type='action' face._state_action=7
function face:IsUsable() return nativeUsable,nativeMana end
function face.icon:GetVertexColor() return .4,token,.4,1 end
function face.icon:GetAlpha() return .5 end
function face.icon:GetEffectiveAlpha() return .225 end
function face.icon:IsDesaturated() return true end
function face.cooldown:IsShown() return true end
function face.cooldown:GetAlpha() return .65 end
combat=true Addon:SnapshotFaceVisuals(true)
local snapshot=Addon.record.lastRuntimeDiagnostics.visuals.combat
local row=snapshot.banks.L2.buttons.PAD1
assert(row.usable==true and row.icon.colour[1]==.4 and row.icon.colour[2]=='[opaque]' and row.icon.alpha==.5 and row.icon.desaturated==true,'snapshot replaced observation with expected presentation')
assert(row.layers.cooldown.shown==true and row.layers.cooldown.alpha==.65,'snapshot omitted cooldown shading')
local function check(value)
    assert(value~=token,'secret object retained in saved diagnostics')
    if type(value)=='table' then for _,v in pairs(value) do check(v) end end
end
check(Addon.record.lastRuntimeDiagnostics.visuals)
combat=false Addon:SnapshotFaceVisuals(true)
assert(Addon.record.lastRuntimeDiagnostics.visuals.combat and Addon.record.lastRuntimeDiagnostics.visuals.peace,'peace snapshot erased combat evidence')
issecretvalue=nil TEST_SUCCESS=true
