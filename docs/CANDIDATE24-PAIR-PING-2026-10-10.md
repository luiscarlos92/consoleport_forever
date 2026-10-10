# Candidate.24 ping pair review

This continues the user's authorized ping repair. The user explicitly asked for
an implementer and an independent reviewer to challenge each other until both
agree and the tests are green. The root agent reviews; ping_implementer owns the
implementation and its fixture. Approval means ready for the user's Retail test.
Neither agent can certify WoW's actual hardware, secure engine or cursor timing
with an offline Lua host.

## Rubber duck explanation: what failed and what changed

Imagine the controller crosshair and the mouse pointer as two different things.
You aim the camera at a monster, but the mouse pointer may still be parked over
a window. Blizzard's ordinary ping listener looks up what is under that pointer.
Its manager can find a UI frame which does not accept pings and return exactly
"Can't ping this". We reproduced that branch in Blizzard's source; we have not
identified the exact frame involved in the user's original live error.

Candidate.22 tried to prepare the pointer and invoke the listener from addon Lua.
The screenshot shows why that was wrong: a real button press is not sufficient
permission for an addon to invoke a restricted ping API. Blizzard also requires
the call to originate from its trusted action machinery. The custom binding and
restricted addon call were removed in candidate.23.

Candidate.23 let Blizzard's native binding perform the restricted action. This
addressed the authority problem, but left two assumptions unresolved. Its passive
observer needed to run before Blizzard sampled the pointer. Keeping the pointer
centered throughout a hold also conflicted with selecting the native mouse radial:
the centre of that radial selects Cancel, rather than a ping type. Its earlier
test counted entry into radial handling without verifying each selected result.
That is why simply reverting to that listener is not a complete repair.

Candidate.24 changes the controller route. It does not call a restricted API from
addon callbacks. Instead, it creates a protected action button before combat and
temporarily routes the existing controller ping bindings to that button through
ConsolePort's native Layers arbiter. Saved bindings remain owned by the game.
The keyboard F2 binding continues to use Blizzard's ordinary listener.

Pressing R3 starts one gesture and immediately shows seven choices. ConsolePort's
native Radial dispatcher consumes right-stick camera input while this selector
is shown. The visual callback highlights a choice; the secure release does not
trust that callback to choose the action. It reads the mapped stick through
ConsolePort's original restricted GetIndex code. Choices 1-6 become Blizzard's
six ping types; choice 7 cancels. Neutral release sends a contextual ping. Circle/B
cancels; when the ping itself is rebound to Circle/B, the hint instead says to use
the Cancel wedge. Returning the stick to neutral means contextual ping, even
after pointing at a wedge; it is not Blizzard's native centre-to-cancel gesture.

Release first checks that it matches the armed button and device, that the
physical button is no longer held, and that the selector still owns the gesture.
It rejects a missing device or a changed controller name. A new down replaces a
lost prior gesture. A settings refresh cancels a held gesture instead of refusing
to refresh indefinitely. Native UI ownership, a foreign higher binding claim,
modifier/prefix changes, hiding the selector and crossing combat boundaries
cancel without sending a delayed ping.

The target choice is deliberate. An available soft enemy or soft friend is an
aimed unit, so the macro uses that unit with an `exists` conditional. A saved hard
target is not used: it can be stale or offscreen. If the aimed unit disappears
before the macro parser evaluates the conditional, the parser declines to send;
it does not fall through to a stale hit-test point. With no aimed unit, the macro
is `/console GamePadCursorCentering 1` followed by `/ping [@cursor]` and an optional
numeric type. This follows ConsolePort World's inline secure macro approach.

The `@cursor` is essential. Blizzard's actual SendMacroPing implementation passes
`forcePointPing=true` for it, bypasses UI receiver lookup and ignores units for that
branch. So an overlay at the pointer cannot produce the old non-pingable-UI error.
Ordinary invalid terrain, cooldown, permissions and server eligibility failures
remain ordinary errors. We do not invent success when the game rejects a point.

Before the ground macro, a public callback records the current centering CVar.
Blizzard's native SecureActionButton macro dispatcher executes the macro on that
same hardware release. The secure PostClick calls a public restore callback.
That callback restores the recorded value only if centering still has the value
we set. Unit pings and cancellation do not change centering. There is no centering
lease across the whole hold, and public callbacks never send pings or macros.

The native Radial dispatcher releases camera focus immediately when this selector
hides. A read-only disconnect watchdog also releases that unprotected dispatcher
if the device disappears while held. Outside combat it cancels the protected
gesture too; in combat it waits for a secure release, owner/state transition or
the next out-of-combat tick to clear protected state. A controller reconnecting
with the same name does not provide a secure device epoch. We cannot prove every
possible ordering of disconnect/reconnect/stale hardware events from these APIs.

## Errors the two reviewers found in each other's work

1. A cancellation claim release recursively re-entered the resolver. Clearing the
   trigger before releasing claims, and ignoring a shown header without a trigger,
   removes that recursion. The original resolver remains a separate invocation,
   so its early return cannot skip our ownership check.
2. The initial combat state driver evaluated before Radial installed required
   frame references. Registration now follows complete setup. The fixture models
   immediate initial evaluation rather than treating registration as a no-op.
3. The initial fixture checked stick focus on the selector instead of the actual
   native Dispatcher. It now checks the dispatcher's ownership and cleanup, and
   exercises its actual raw and virtual camera-stick handling.
4. The reviewer incorrectly requested that every UI owner be protected. The real
   ConsolePort UI cursor is unprotected. That requirement would prevent startup.
   Its XML is now pinned and checked. Secure code reads its visibility only out of
   combat; protected Raid/TargetRing remain readable. The host rejects unprotected
   frame visibility/attribute reads during combat.
5. Recapturing a later third-party resolver could form a wrapper cycle. Refresh
   now fails closed, releases our routes and preserves the later writer. Disable
   restores the original only when our wrapper is still the current owner.
6. A static Circle/B hint lied when ping itself was rebound there. The hint now
   describes the available Cancel wedge for that case; remapping is tested.
7. Physical claims cannot faithfully stand in for native latched/doubled/ordered
   modifier rows. These modes report pending and keep native ping, rather than
   claiming a qualified repair. The user's standard modifier layout is supported.
8. A unit disappearing before the macro executes could leave a nil GUID and allow
   Blizzard's unit branch to fall back to prior hit-test information. The macro
   now has an `exists` condition and the fixture tests disappearance at that boundary.
9. Public script callbacks needed a separate insecure trust model even when called
   within a secure input event. That distinction is now tested; hardware presence
   alone cannot qualify addon dispatch or protected callback writes.
10. Another native radial can take the right stick using a different button,
    without claiming R3. The first implementation could commit that ring's stick
    choice as a ping. The independent reviewer reproduced it and both agents
    withdrew their earlier provisional acceptance. Out-of-combat refresh now
    captures native registered radial headers, wraps their Show securely, and
    refuses a new ping over a shown header. Tests cover opening/closing the other
    ring before R3 release, combat transfer, preservation of its camera focus and
    refresh without duplicate wrappers. Newly registered headers are captured on
    the next out-of-combat refresh; arbitrary late third-party header creation
    before that refresh is outside this qualified native-module contract.

An offscreen hover watchdog was also investigated and rejected: Blizzard's actual
hover driver does not start an exit countdown when registration begins outside
the frame. It would not solve a lost release. No such workaround is shipped.

## What green tests do and do not establish

T60 executes unchanged pinned ConsolePort Layers/Radial/secure utilities and
Blizzard wrapped handlers, action-button macro dispatcher, secure ping slash
parser and ping manager. It verifies actual selected type outcomes, forced-point
UI bypass, aimed units, terrain rejection, cancel and stale releases, native
camera cleanup, combat, remapping, ownership, restoration and unsupported modes.
Mandatory mutations reintroduce known flaws and must fail for their intended
reason. Removing `@cursor`, for example, reaches the native blocking-UI branch.
Four ActionButtonUseKeyDown/ActionButtonUseKeyHeldSpell combinations execute the
original native dispatcher and send exactly one ping on release, none on down.

The host models the engine's C APIs, cursor movement, macro option parsing and
hardware event ordering. It assumes the inline centering CVar moves the pointer
before the next macro command. That assumption follows the existing native
ConsolePort ping macro but still requires Retail testing. Distinct writers which
both choose centering=1 cannot be distinguished by a CVar equality check. The
same-click restoration substantially narrows that window; it does not establish
a general ownership token for other addons.

TemporaryRouting.lua and Ground.lua remain byte-identical to the installed
candidate.23 baseline. The user-confirmed dragonriding repair is preserved.
The full T61 regression continues to cover all installed classes and dragonriding,
possession, quest override, vehicle UI and other temporary replacement pages on
L2+R2. Actual acceptance of the other families still needs the user's scenarios.
Revision 17, class rings, saved layouts and accepted action rendering remain.

All nine official stable Retail dependencies were freshly checked this session;
none changed or needs copying. Build/install scope is Forever only, with the
tested installer, closed-WoW checks, preserved backups, unchanged unselected
addons, WTF and junctions. No game launch or live WTF edit is authorized here.

Final exact-source reports and both agents' verdicts are recorded separately in
`evidence/test-results/candidate24-pair-review.json`, `candidate24-runtime.json`
and `candidate24-tooling.json`. Retail acceptance remains manual case 51.

## Source references

- Blizzard-authored [secure ping parser](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/SlashCommandsOverrides.lua)
  and [macro ping manager](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_PingUI/Blizzard_PingManager.lua).
- Exact ConsolePort 3.3.10 official release contracts are retained unmodified in
  `evidence/consoleport-contracts`, with package/file hashes in its manifest.
- The shipped implementation is `addon/ConsolePort_Forever/Targeting/Ping.lua`;
  its independent source-injection and mutation tests are in `tools/test-all.cjs`
  and `tests/harness/ping_targeting.lua`.

Final qualification: all 62 runtime/source suites and 39 tooling tests pass for
the exact frozen source. T60 includes 14 mandatory adversarial mutations. Both
agents independently verified the reports/hashes and recorded ACCEPT for user
Retail testing. No remaining known source blocker in the qualified native contract.

Authorized installation completed 2026-10-10 03:12:45 Toronto from source
28429e5db4cf7fe66d83aa485fa1d3d5c7cd1058. Scoped Forever-only package SHA256:
752ccd1738017f1dc7ec63f4a0c5780d763f12dd733dfae86876fc389ab06328. Independent readback confirms all 54 installed
files, 2498 other addon files and 306 WTF files unchanged, 42 junctions/anchors
preserved, and prior code/configuration backups verified at
C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261010T071208Z-8710da38c2df. Reports are retained under
evidence/delivery/*candidate24*.json. All 54 installed native ConsolePort source
contracts were also checked against the tested official source before installation.
No game launch or hardware test was performed.
