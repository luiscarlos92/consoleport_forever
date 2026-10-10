# Candidate.28 native account ping ring — prepared source only

The user confirms candidate.27 fixes the bar editing and sends/chooses pings,
but rejects the separate frame's broken appearance. The user requests retaining
that functional code as an inactive backup and using the real ConsolePort
account ring, with immediate button-down ping and hold-only selector artwork.
Deployment is explicitly forbidden while the user plays.

## Change

`Targeting/Ping.lua` seeds `ForeverPings` once through native `CreateSet` into
`ConsolePortUtilityToggle.Shared`, saved by ConsolePort as the account-wide
`ConsolePortRingsShared`. Native settings enumerate it as an account ring.
The six owned custom actions supply Blizzard ping atlas icons, localized text,
and secure macro data to ConsolePort's existing LAB action map. Other custom
actions delegate to the original native map. No separate PieMenu, textures,
masks, borders, slice layout, focus code or selector is created by Forever.
ConsolePort's full UtilityToggle frontend, pool, native round button skin,
colours, animations, highlights and settings provide the presentation.
The atlas action returns a native texture-unmount cleanup that restores full
UV coordinates before the pooled widget displays another ring's spell icon.

R3 button-down sends the aimed contextual ping immediately through the native
secure macro dispatcher before the ring captures the camera. Its secure
PostClick then enters the native ring's default hold context;
only the ring's artwork is suppressed for the first 0.15 seconds. A public
clock changes alpha only, including in combat; it never gates privileged input
or writes protected attributes. On a hold, the actual native ring becomes
visible. Release delegates a secure click to UtilityToggle; native Main/Commit,
stick configuration, sticky selection, editing, nested rings and cancel controls
retain authority. The opener requests native hold mode for this context only,
without changing the user's global ring toggle preference. There is no custom
Circle/B cancel claim or replacement selection algorithm.

Literal immediate-on-press means a hold also sends the initial contextual ping.
Releasing a selected native ring entry sends that typed ping as a separate
native action. A neutral tap with standard non-sticky settings sends one ping
and shows no ring. Native sticky selection or a deflected stick can commit an
entry on a quick release before artwork is visible; there is no claimed secure
clock gate. This follows the user's priority for immediate press and unchanged
native release behavior. Retail ping throttling/hardware/rendering remain
manual acceptance, not certified by the offline model.

Existing account ring order/removals/manual edits survive refresh and character
changes. Personal/shared naming collisions fail closed rather than overwrite.
The account ring is outside Forever's per-GUID personal ring projection.
No account macros are created and no live WTF filesystem writes are performed;
ConsolePort saves the shared ring through its normal in-game saved variables
when the prepared version is later installed.

## Inactive fallback and preserved bar repair

`fallbacks/ping-candidate27/Ping.lua.disabled` and the original restricted
compiler/native dispatcher harness retain the exact accepted functional code.
The manifest records SHA256 and candidate.27 source identity. Neither file is
in the addon or TOC; there is no automatic runtime reactivation. T60 continues
qualifying this inactive fallback against the pinned native contracts.

ActionRecovery, TemporaryRouting, Ground, class actions, personal Rings adapter,
main addon and revision17 remain byte-identical to installed candidate.27.
`evidence/ping-account-ring/preservation.json` records those hashes. Automatic
slot restoration remains removed. The original quest-loss writer is still
unconfirmed; this change does not revisit the accepted bar repair.

## Verification scope

T65 executes unchanged ConsolePort ring Database, Map, Container and Secure
source, full ring/button frontend and native texture adapter, plus the unchanged
Blizzard restricted closure compiler, macro dispatcher, /ping manager and native
Layers/Radial. The real pinned LibStub source supplies its callable-table
library registry; the startup guard accepts that native object. A mandatory
function-only guard mutation rejects the former simplified-fixture mistake.
A pool-reuse mutation also rejects atlas coordinates leaking into the aura ring.
Host models frame primitives, hardware, LAB storage/pool and
skinning engine; actual Retail pixels and taint are not offline proof.
Checks include immediate press, no tap artwork, all six typed releases in/out
of combat, native focus/text/icon adapters, account namespace/persistence,
sticky defaults, context/global preference isolation, native owner/prefix/device
handoffs, same-header aura opener replacement, cursor restoration and
collision/disable preservation. Mandatory
mutations reject missing press dispatch, tap artwork, personal storage, missing
release delegation, reseeding edits, bad centering, camera capture before immediate dispatch and bypassed native skin
initialization and state-context hijacking of a different native ring.
The release wrapper aliases only the active ping opener to the native set ID
for LAST matching, without overriding the shared header's set selection.
Full runtime/tooling gates and package details are recorded in
the retained candidate.28 reports and preparation receipt when complete.

All nine official stable Retail dependencies were freshly checked this session:
none changed or downloaded. Only Forever is eligible for a future scoped update.
No deployment, installer preview, game input, restart or reload is authorized.
Installed candidate.27 stays in place.

Qualification complete: all 65 runtime/source suites and 39 tooling checks pass
on exact frozen source hashes. Reports: evidence/test-results/candidate28-runtime.json
and candidate28-tooling.json. No deployment or installer preview ran.
