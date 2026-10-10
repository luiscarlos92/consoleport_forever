# Candidate.21 ping targeting — prepared, DO NOT DEPLOY

The user requests diagnosis and a fix for "Can't ping this", with no deployment.
All changes are confined to the product checkout. Candidate.20 stays installed.
No live AddOns/WTF write, installer, game launch, reload or client interaction is
authorized. Configuration revision 17 and accepted rendering/class/casting remain.

## Diagnosis and evidence boundary

Read-only binding inspection finds both PADRSTICK and keyboard F2 assigned to
TOGGLEPINGLISTENER. Forever's reference and current ConsolePort data agree: this
is not a missing ping command. The native hardware binding calls
C_Ping.TogglePingListener on both down and up.

Blizzard's actual PingListenerFrameMixin samples GetCursorPosition. ConsolePort's
Crosshair:Move draws its separate camera reticle at CursorCenteredYPos; it does
not move the pointer. ConsolePort Mouse:SetCameraControl turns off cursor
centering unless mouseAlwaysCentered is selected. The native R3 ping binding
does not center that parked pointer before sampling. A pointer left over a
blocking UI frame can therefore produce "Can't ping this" while the visible
camera reticle points at a valid world location.

Blizzard PingManager first asks its secure UI receiver hit test. A blocking,
non-pingable frame stops further world tests and emits PING_FAILED_GENERIC.
The native manager also uses that generic error for certain invalid world targets.
The test reproduces the blocking-frame branch using the actual manager and
listener methods, with the engine pointer/UI hit test substituted as host services.
This establishes a concrete controller targeting defect and matching error path.
It does **not** identify the user's actual blocking frame or prove that every
instance of the generic message has this cause. No live frame capture is available.

The ConsolePort quick-menu ping commands are a separate route. Its explicit
target/player pings already select units, and its world route already toggles
centering. These commands are not modified. Blizzard eligibility, group-leader
policy, cooldowns and invalid targets remain game-owned. No addon is blamed solely
from the presence of the error or from a toplevel declaration in its source.

## Repair

Targeting/Ping.lua registers only gamepad chords currently bound to the native
ping command through ConsolePort 3.3.10 Layers:Claim at OVERRIDE. NAV and MODAL
claims remain higher priority. Keyboard F2, other saved bindings and action cells
are retained. A dedicated runOnUp hardware Binding XML delegates to the native
C_Ping.TogglePingListener, preserving tap and hold/radial behavior.

In camera freelook, with no free mouse pointer or Cursor/Raid/TargetRing owner,
the hardware press saves GamePadCursorCentering and sets it to 1 before the
native listener samples coordinates. Release delegates first, then restores the
prior value if it still owns the centering value. Repeated down cannot replace
the backup; a newer native CVar change survives. Native API refusal releases the
temporary CVar ownership and propagates the error. Routing rebuilds defer during
combat or a held native ping. Disable/rebinding releases only Forever's claimant.
No Blizzard method, privileged callback, ping eligibility or dependency source
is replaced. C_PingSecure is SecureOnly and is never called by this addon.

PING_SYSTEM_ERROR and /cpf diagnose capture bounded public mouse-focus names,
toplevel state, ping mode and centering in the character's runtime diagnostics.
This public focus evidence is not asserted to be the privileged receiver result.
Normal in-game save owns all persistence; no filesystem SavedVariables edit.

## Dependency refresh

All nine official stable Retail sources were freshly checked in this work session.
Official CurseForge latest listings/file pages confirm DynamicCam 2.21.1/file
8995535 and ExtraFade 1.18.0/file 8995675. GitHub discovery finds one change:
Plater-v656 -> Plater-v657, released October 9. Only Plater's new official Retail
archive is downloaded/extracted. Old caches and source evidence remain retained.

Plater's selected Retail TOC, full archive/file integrity and dependency closure
are qualified; all 189 Lua files pass Lua 5.1 syntax parsing. The upstream diff
covers nameplate/aura/resource fixes, performance, designer/DF changes and moved
LibCompress packaging. Forever has no Plater profile adapter/version override.
No ping-receiver implementation is introduced by Plater. Native unit-hit testing
and all actual rendering remain client checks, not inferred from syntax/closure.
Coverage, notices and stable-release evidence are refreshed for the new lock.
A later separately authorized scoped deployment must include Forever and this
changed Plater package; do not ship the eight unchanged dependencies.

## Validation and pending client test

T60 executes actual ConsolePort Layers resolution, the exact new hardware XML
body, and native Blizzard ping-listener/manager methods. It covers parked-pointer
failure, tap and hold, repeated press, prior centering/newer writes, native refusal,
mouse/UI/raid/ring ownership, foreign modal priority, combat dispatch, rebinding,
disable and public diagnostics. Removing centering or restoration must fail the
regression. T41/T42 and every existing required runtime/source and tooling gate
remain mandatory. Exact final reports are retained under evidence/test-results.

The host models movement of the pointer when centering changes. Actual Retail
CVar timing, custom hardware-binding API permission, unit/world hit tests,
radial positioning, combat, taint and controller behavior are **pending**. Passing
offline tests does not certify them. No deployment is authorized by this record.

After a separately authorized installation, manual case 48:

1. Park the mouse over a dialog/HUD area, return to controller camera freelook,
   and tap R3 aimed at a valid world location/unit. Confirm the intended ping.
2. Hold R3, select a radial ping and release; repeat in/out of combat. Confirm
   placement and that the original centering preference returns.
3. Repeat with free pointer, native UI navigation, raid cursor and target ring;
   verify their owners and keyboard F2 retain native behavior. Change bindings
   and enter/leave a modal while holding R3; verify no orphaned listener/centering.
4. Try a deliberately invalid target and leader-disabled/cooldown cases; retain
   native errors. If the reported failure remains, /cpf diagnose and a normal
   in-game save provide public focus/CVar evidence for the next read-only audit.

Final result: all 60 runtime/source suites and all 39 tooling checks pass, with
no source-hash drift. Read-only comparison verifies every one of the 52 installed
candidate.20 Forever files still matches its prior source; no deployment.
Receipts: evidence/test-results/candidate21-runtime.json, candidate21-tooling.json,
candidate21-ping-focused.json and candidate21-live-code-readback.json;
evidence/delivery/prepared-candidate21.json.
