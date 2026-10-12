# Circle/B cancellation: research, implementation and proof boundary

Status: maintained
Reviewed: 2026-10-12
Evidence: [implementation](../../addon/ConsolePort_Forever/Circle.lua),
[native research snapshots](../../evidence/circle/research/sources.json),
[native dispatch/review tests](../../tests/harness/circle.lua),
[original Forever oracle](../../tests/harness/circle_reference.lua).

## Candidate.32 follow-up

The live diagnostic identifies ADDON_ACTION_FORBIDDEN: RunMacroText() while casting;
menu closure works. Candidate.32 replaces macrotext with reviewed saved-macro
RunMacro dispatch, retains inherited OnClick and restores revision-18 automatic
login review. The latest user instruction permits this Forever-only update while
WoW runs; no game input or WTF writes. Earlier qualification below describes
candidate.31 and its narrower model, not current live acceptance. Candidate.32 was
installed October 12 at 15:08:29 Toronto; [readback](../../evidence/delivery/candidate32-independent-readback.json) verifies preservation.
[Current investigation](CIRCLE-BLOCKED-ACTION-2026-10-12.md).

## Authorized scope and user decision

The October 11 request authorizes research and implementation of Circle only,
with extensive regression tests, and initially forbade deployment while the
user was playing. The user subsequently authorized deployment with WoW closed. After the secure-route research, the user instructed:
"Implement the best way you can without using the native Escape because that
opens the Options menu". That rules out mapping Circle to TOGGLEGAMEMENU.

The selected implementation is a reviewed, predeclared **cancel-all** action.
It cancels casting/channeling, ground-spell placement and the hard target on
button-down. It never invokes Escape, opens Options or installs its own cursor
handoff/window closure. Native reticle/cursor cleanup remains native, and
ConsolePort UI/ring input claims retain priority.

This is the feasible Retail version chosen within that instruction, **not exact
first-success Forever parity**. If casting and a hard target coexist, the cast
is cancelled and the target is also cleared. That tradeoff appears in the setup
review label and tests. The exact native priority remains an explicit gate.

Candidate.31/configuration revision 17 was installed through the authorized
Forever-only update on October 12 at 00:24:05 Toronto.
[Installation receipt](../../evidence/delivery/live-install-candidate31.json) and
[independent readback](../../evidence/delivery/candidate31-independent-readback.json)
verify source/artifact identity and preservation. Candidate.30's reported acceptance
remains historical. Candidate.31 Circle acceptance is not run; activation requires
explicit in-game review. Game input and live WTF writes remain outside this request.

## What native Forever actually does

The pinned Blizzard-authored `SetupNonBindableBack` installs an OnClick callback
that applies pressed art for both edges and calls its gameplay function only
on down. The function uses the actual success return values in the order
SpellStopCasting, SpellStopTargeting, ClearTarget, stopping at the first success.
It has no idle-menu fallback. Source:
[pinned MainActionBarFrame](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua).

This investigation also freshly queried the public `forever` branch. The latest
published snapshot returned **1.60.1 (70338)**, commit
`943764493e6b16d63ded3ab304150d1f05e58b57`, committed October 10 at 05:16:18 UTC.
The fetched complete `SetupNonBindableBack` function matches the original after
normalizing line endings. Its hash, URL/build and comparison result are retained
in the research manifest. [Latest inspected callback source](https://github.com/Gethe/wow-ui-source/blob/943764493e6b16d63ded3ab304150d1f05e58b57/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua).
This verifies source continuity for Circle, not the entire original UI catalog
or live engine behavior in that build.

T69 executes that unchanged original function from the retained snapshot against
all eight combinations of casting, reticle and hard target, plus the release
edge. Its negative control changes the chain to independent checks and must
fail. This is an oracle for source behavior; the modeled C results are not a
Retail permission grant to run that callback as addon code.

## Research findings and rejected routes

The newly fetched Retail snapshots are pinned to Gethe's inspected `live` commit
`09b9db7948abc9b9648dedaab51eb0cf3ee67b31`; the snapshot manifest retains URLs,
paths, bytes and hashes. Raw downloads remain in ignored `scratch/circle-research`;
only the manifest is tracked. The existing explicit CI network stage
`python -B tools/verify_pinned_sources.py` reconstructs and verifies the cache
before offline tests; it rejects cache drift instead of replacing it. No new
third-party source is published. Existing pinned source and upstream addons are unchanged.
Gethe mirrors Blizzard-authored implementation, rather than being a Blizzard
guarantee of support. The supplied October 10 reference remains unchanged.

| Route / clue | Evidence | Assessment |
| --- | --- | --- |
| Copy the Forever privileged OnClick callback. | Original source directly invokes protected C functions and branches on their results. | Addon Lua does not acquire Blizzard core authority by copying a function. No qualified Retail route was found for this exact callback. |
| Restricted secure snippet with the same C calls. | Inspected [Retail restricted environment](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua) exposes macro-safe functions and PlayerIsChanneling, but not those three protected calls or a general PlayerIsCasting/SpellIsTargeting branch. | Restricted compilation is necessary but does not make unavailable functions callable. Public cast/reticle observations cannot select protected operations in combat. |
| Native secure action types. | [SecureTemplates](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua) has macro dispatch, a reticle-stop type and target `none`; unknown function handlers call forceinsecure. | Useful authorized building blocks; no type implements the complete first-success return chain. |
| Native Escape / TOGGLEGAMEMENU. | [Bindings_Standard](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_FrameXML/Bindings_Standard.xml), [GameMenuEsc](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_GameMenuEsc/Blizzard_GameMenuEsc.lua), [shared Game](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_Game/Shared/Game.lua), [Retail Game](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_Game/Mainline/Game.lua). | Secure native route, but dialog/menu priorities, cursor handoff, native panel handling, charm/spectating cases and idle Game Menu differ. Explicitly rejected by the user. |
| Hook/suppress Escape's idle menu or copy its registry handler. | The current dispatcher calls registered handlers in ordered native priorities. | Would couple Circle to global Escape behavior and possibly other owners. Rejected; no hooks or registrations are installed. |
| Dynamic macro chosen by a timer/cast event/public getter. | Public callbacks cannot mutate protected configuration freely in combat; a state observation is not authority. | Rejected. No timer, cast observer, public protected call or late macro substitution. |
| `/run` calling protected APIs or simulated Click. | Native secure template dispatch and addon taint distinctions. | Rejected. Direct physical key â†’ native secure click â†’ registered secure slash handlers is required. |
| Channeling-only conditional or click sequence. | PlayerIsChanneling is available, but does not cover ordinary casts, queued casts and reticle state. | Cannot claim full priority. A click-count cycle invents a new gesture and is not implemented. |
| Fixed secure cancellation macro. | Native macro action invokes C_Macro.RunMacroText; [secure slash registrations](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua) expose stopcasting, stopspelltarget and cleartarget. | **Candidate.31 selection, superseded after the live forbidden RunMacroText report.** The replacement uses the native saved-macro branch; deliberately executes all three rather than the first successful one. |

## Other addons and forum research

These materials supplied clues and failure cases, not authority to bypass
Retail's secure restrictions:

- [ConsolePort source](../../evidence/consoleport-contracts/ConsolePort/Controller/Layers.lua)
  resolves native saved bindings, navigation and modal claims. Its Base bank
  proxy represents non-action commands cosmetically while Layers routes actual
  command/click ownership. We retain that architecture instead of claiming a
  new overriding layer or modifying ConsolePort.
- [ConsoleExperienceClassic's own control documentation](https://github.com/pepordev/ConsoleExperienceClassic/blob/main/docs/Keybindings.md)
  distinguishes system bindings from action slots and UI Back. Its different
  client assumptions, including external interaction support, make it unsuitable
  as proof that a Retail protected callback is allowed.
- [The firsthand controller discussion](https://us.forums.blizzard.com/en/wow/t/playing-with-a-controller-any-tips/1473302?page=2)
  suggests Toggle Game Menu as target-clear access and explicitly describes its
  idle menu effect. This was a practical clue for the native route, then rejected
  under the user's current no-Escape instruction.
- [The reported action-targeting problem](https://us.forums.blizzard.com/en/wow/t/action-targeting-issues/1487443)
  distinguishes controller soft targeting from hard-target clear behavior. It is
  a dated report, not a demonstrated current defect. Live acceptance must inspect
  the actual hard target; a soft target indicator can remain after clear.
- [The author's secure-button explanation](https://www.wowinterface.com/forums/showthread.php?t=59516)
  describes why a scripted Click cannot substitute for user hardware authority.
  The implementation does not perform scripted button clicks.
- [The addon author's ToggleGameMenu report](https://us.forums.blizzard.com/en/wow/t/protected-function-togglegamemenu-can-be-called-from-addons-or-script-in-a-limited-way/90156)
  shows why a callable UI helper is not proof its internal protected cancellation
  calls are authorized from addon code.
- [The casting-conditional discussion](https://us.forums.blizzard.com/en/wow/t/is-there-a-conditional-for-casting-a-spell/660153)
  and [channel macro report](https://us.forums.blizzard.com/en/wow/t/mw-stopcasting-macro/2278411)
  motivated checking native conditional availability and avoiding timing-dependent
  assumptions after `/stopcasting`. No forum macro claim substitutes for current
  native source or live qualification.

Current Blizzard-generated GamePad documentation describes device/configuration
and cursor APIs but provides no dedicated documented gameplay Back-chain API.
That is the inspected document's limit, not a claim that Blizzard can never add
one. The newly retained native source is the implementation evidence used here.

## Production path and ownership

`Circle.lua` prepares an inert one-pixel, non-mouse-enabled native
SecureActionButtonTemplate frame outside combat/Edit Mode. Its OnClick is the
original SecureActionButton_OnClick function; macro text is fixed before input.
The action uses down only, independently of the ordinary spell-keydown CVar;
release has no second cancellation. Its first command stops the macro for any
modifier, preventing Base cancellation from spilling into modified actions.

The new command is `CLICK ConsolePortForeverCircleCancel:LeftButton`.
`RuntimeSetup.Fields` offers it **only for an explicit empty unmodified PAD2**,
and marks the controller field `requireReview`. Nonempty manual commands,
missing/unreadable entries and all other bindings stay intact. Even a matching
old managed baseline cannot auto-apply this change without Use Proposed.

Crucially, `BindingProposal`/ordinary hydration do not call the Circle proposal
helper. Accepting review captures the shared Base face through the existing
native binding journal/ownership path. A subsequent manual removal is captured
normally and stays removed; preparing/refreshing the frame does not bind it.
Keep decisions retain their existing matching-review semantics. Configuration
revision stays 17 to preserve accepted first-login class repair and recovery
startup. Existing installed characters are not forced into a new full setup
prompt: `/cpf update` explicitly opens review for this optional command. New
configuration review also offers it when an eligible empty Base key exists.

The review uses the existing whole-controller adapter and its documented
native bank-selection/keyboard-view semantics. Preserving the outgoing keyboard
view is not a promise that both saved banks remain byte-identical after an
accepted projection; that pre-existing contract is described in
[runtime configuration](RUNTIME-CONFIGURATION.md).

Native ConsolePort Layers resolves the existing saved command. No Forever
priority claim, binding hook, cast observer or UI takeover is added. Native
navigation/modal/ring claims supersede Base normally, including held UI release
and combat handoff. Ground placement, temporary L2R2 routing, class access,
ping, skin, Immersion and saved layouts retain their existing ownership.

Preparation checks native APIs and rejects a foreign global frame name or a
changed owned script/attribute contract without overwriting it. Repeated prepared
refreshes perform no protected mutation. `circleCancel` readiness means the
native frame is prepared; it does not prove PAD2 was accepted/bound or tested
in Retail. `exactCircle` explicitly remains pending.

## Validation and remaining acceptance

T68 exercises actual pinned ConsolePort Layers/Input, native Blizzard modified
attribute lookup, SecureActionButton_OnClick, macro action and secure slash
callbacks. The engine's hardware/taint checks and macro conditional parser are
explicit host models. Coverage includes all cancellation-state combinations,
channels, down/up, both global keydown settings, combat/noncombat, other ordinary
chords, modified misrouting, foreign NAV/MODAL owners, held UI combat handoff,
API/frame collisions/drift, inert preparation, actual bootstrap caller, journal
apply/drift/restore, explicit review/Keep and manual removal/shared hydration.
Native skin lifecycle tests retain the new command's exit artwork/availability,
combat refresh and manual/modified/held icon ownership, including an art negative
control. Negative controls must reject missing cancellation,
incorrect edge, modifier spill, manual overwrite, automatic review, unsafe
creation/collision and insecure-script substitution.

T69 separately preserves the original Forever source's different result. Existing
full gates remain mandatory, including T41/T42/T61/T62/T64/T65/T66/T67 and the
visual/class/GUID coverage. Final results and exact source inventories are
retained separately; isolated Circle success is not full release qualification.

Retail acceptance is **not run**. Following the now-authorized installation, the user must verify actual native authority/taint, soft versus hard target,
physical key edges, ring/dialog cancellation, repeat/combat behavior and existing
accepted features. No offline result certifies these engine cases or exact stock
parity. Deployment authorization does not authorize game launch or input.

## Final offline qualification

The source used for installation passed **69 runtime/source checks and 50
tooling tests**. T68 contains 285 assertions; T69 contains 40 independent native
reference assertions. Fourteen new negative controls cover the cancellation,
ownership/review/creation/startup, exit art and stock-chain boundaries. Full
current inventories were independently rechecked: 62 product files (including
retained unloaded legacy files) and 125 tooling/test files. Nine freshly checked
official stable sources match the unchanged lock; no dependency refresh was needed.

[Qualification receipt](../../evidence/circle/qualification-2026-10-11.json),
[runtime receipt](../../evidence/test-results/candidate31-circle-runtime.json),
[tooling receipt](../../evidence/test-results/candidate31-circle-tooling.json).
These fingerprint the tested working tree. Installation and independent readback
are separate receipts; the qualification receipt describes the preparation stage.
No game input or live WTF write is authorized.

The later CI setup repair reconstructs exact pinned dependency cache/unpacked
inputs before tests, preserving the lock and rejecting cached drift. Seven
additional regression tests and the complete rerun passed: 69 runtime/source
checks and 57 tooling tests. Fresh Windows CI passed the same complete suites,
and its product/tooling inventories match the local reports.
The installed product is unchanged.
[Follow-up exact-source/CI qualification](../../evidence/test-results/candidate31-ci-inputs-qualification.json).
