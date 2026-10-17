# Pending deployment and cumulative acceptance

Status: candidate.41 installed October 16, 2026 at 20:45:48 Toronto.
Reviewed: 2026-10-16
Evidence: [independent readback](../evidence/delivery/candidate41-independent-readback.json),
[qualification](../evidence/test-results/candidate41-follower-qualification.json).

The Forever-only update passed all 102 runtime/source checks and 70 tooling
tests locally and in fresh Windows CI with complete matching inventories.
[CI](../evidence/test-results/candidate41-fresh-ci.json). Independent readback verifies
all 60 installed files and preservation of other addons, WTF, links/root anchors
and prior backups. Schema3/revision20 remain. No game input was sent. The user
confirmed the follower fix on October 16; K06 is resolved for the reported case.
K04/K05 and broader unreported cases remain open. Four qualified
dependency updates remain prepared and excluded from this delivery.

## Candidate.42 Pawn/Immersion checks

Candidate.42 integration is approved and under offline qualification. After its
separately recorded scoped delivery and user-owned reload:

1. Use the same reward/Pawn configuration as bags. Summary icons show only the
   native green arrow when BetterBags selects Pawn and Pawn says upgrade.
2. Open reward detail: compare Pawn's exact scale/spec, percentage and formatting
   with the bag tooltip. Hold/release L2, select the other reward and repeat.
3. Close/reopen, visit another quest and check a non-upgrade, no-stat/currency
   reward and asynchronous item loading. No duplicated notes, stale arrows or
   growing tooltip padding. Required Items, vendor/context markers and native
   selection/controller behavior remain.

Rendering, taint, controller timing, persistence and Retail CPU remain unaccepted.
[Runtime scope](reference/PAWN-IMMERSION-RUNTIME-2026-10-16.md).

## Candidate.41 follower activation and acceptance

Candidate.40's unchanged-behavior report exposed an unsupported startup API.
Candidate.41 corrected activation and added explicit `/cpf status` readiness.
After deployment and the test instructions, the user reports "done, fixed".
K06 is resolved for that reported problem. [Acceptance](../evidence/follower-dungeons/2026-10-16/candidate41-user-acceptance.json),
[activation diagnosis](reference/FOLLOWER-DUNGEON-ACTIVATION-2026-10-16.md).
The retained checklist below remains useful for regression testing; the brief
confirmation does not individually certify every listed transition or context.

## Retained follower regression checklist

The [candidate.40 runtime](reference/FOLLOWER-DUNGEON-RUNTIME-2026-10-16.md) documents the candidate and offline proof boundaries.
After the Forever-only deployment and user-owned reload:

1. Open the usual ring, select Dungeon Assistance and release. Wait for the
   native cooldown, select again and repeat. Verify alternating lead/stop,
   matching state artwork and one corresponding command per selection.
2. Verify the standalone follower control is absent with the owned ring ready;
   actual extra actions and other zone abilities remain visible/usable.
3. Check exit/re-entry, combat, Edit Mode and utility disable plus reload.
   Unknown/unready contexts retain the native fallback. No game input is automated.

BetterBags v0.5.16, Plater-v661, DynamicCam 2.21.4 and ExtraFade 1.18.1 are qualified in preparation;
dependency replacement requires closed WoW and is excluded from this update.
K06's candidate.41 user acceptance is recorded above; K04/K05 are unchanged.

## Previous candidate.38 diagnostic checkpoint

Candidate.38 retains revision20/schema3; accepted characters need no new setup
review. Ground placement and its Targeting tab remain retired. Local qualification
passed all 79 runtime/source checks and 66 tooling tests with complete inventories.
K04 performance and K05 native cooldown taint remain open. Automatic bounded
native-action transition/first blocked-call stacks collect during ordinary play
with engine logging off. First stacks survive aggregate eviction without
unbounded recapture. No prescribed combat sequence or additional engine logging
is requested, and no warning-resolution claim is made. All 115 LiteMount files
already match 12.1.5-1 on disk; only Forever was selected for this update.
[Audit](reference/COMBAT-ERROR-AUDIT-2026-10-13.md).

## Candidate.39 shared utility qualification and manual acceptance

Candidate.39 is installed; exact delivery is recorded in current status. All 90
runtime/source checks and 66 tooling tests pass with complete inventories locally
and in fresh Windows CI. The user owns next login/reload and these Retail checks:

**October 15 observation:** the user reports promising initial tests across specs
on one character. This does not yet establish complete acceptance of the spec
switch/return sequence or the cross-character/class and other cases below.
[Scoped record](../evidence/utility-ring/candidate39-user-observation-2026-10-15.json).

1. Open the Utility Ring with the existing L2 + Options binding; preserve manual
   binding choices and verify native menus/feedback.
2. Add Rite of Sanctification, change spec and return, then change character/class
   and return. Unavailable choices should disappear silently and return when known.
3. Verify an item disappearing at zero possession and returning on replenishment;
   bank-only items remain unavailable. Remove a visible choice while open and verify
   it stays deleted. Confirm Clear only if deliberately clearing the entire master.
4. Reload/change character and confirm saved choices persist. `/cpfutility off`
   then `/reload` must restore native handling; `/cpfutility on` then `/reload`
   must resume the retained master.
5. Observe unexpected chat, blocked-action errors and comparable CPU usage during
   ordinary play. Offline work bounds do not close K04 or K05.

[Implementation and limits](reference/SHARED-UTILITY-RING-RUNTIME-2026-10-14.md),
[qualification](../evidence/test-results/candidate39-shared-utility-qualification.json).

## Candidate.34 activation and acceptance

Candidate.35 performance validation additionally needs consistent one-minute
Active-mode captures for idle/movement, mount/combat/casts/target/loot/quests,
modifiers/banks/forms/vehicles, death/resurrection and login/reload. Preserve all
appearance/input/native feedback and watch taint. `/cpf perf on`, `reset`,
`report` and `off` provide optional bounded inclusive callback timings; off is the
default. Compare same client/configuration/scenario windows and retain average,
peak and threshold counts. Offline work reduction does not close K04.
[Scenario matrix](reference/HUD-PERFORMANCE-2026-10-12.md#optional-timing-and-scenario-validation).

**User-confirmed October 12:** Circle successfully interrupts casting. This
resolves the reported cast failure; earlier menu closure remains confirmed.
Ground-placement cancellation was not tried because the existing targeting
adapter intercepts those casts. The user accepts this untested case; do not count
it as a pass or require another diagnose command. Broader channel/target,
combat/modifier/character and edit/rollback cases remain individually unasserted.
[Acceptance](../evidence/circle/candidate34-live-acceptance-2026-10-12.json).

The pre-acceptance repair sequence below explains the installed migration:

Candidate.33 review committed revision19, but a changed-resource deferral retained
the legacy CLICK binding. Casting remains uninterrupted in that report. Review the
formatting-aware resource comparison and owned native migration; verify automatic
bounded format/cast/native-call logs. Standing permission allows qualified
Forever deployment while playing unless explicitly prohibited. After user reload,
automatic revision20 review must preserve the existing macro and change only the
reviewed Circle binding; native menus/rings/modified actions retain priority.
Read persisted session logs after normal reload/logout; do not ask for diagnose.
[Follow-up](reference/CIRCLE-MACRO-FORMAT-2026-10-12.md).

## Installed candidate.32 acceptance

The diagnose image confirms ADDON_ACTION_FORBIDDEN: RunMacroText(). The repair uses
native saved-macro RunMacro, inherited OnClick and revision-18 automatic review.
After reload outside combat/Edit Mode, review should offer one account CPF Circle
macro for an existing Forever binding or empty Base Circle. Use Proposed/Keep,
then Apply; no /cpf update command is required. Preserve accepted/manual data.
Check cast/channel/ground/target cancellation without a protected popup or Options,
down/release/modifier behavior, native menu/ring ownership and macro edit/deletion
preservation. Full local and fresh CI gates passed. These candidate.32 cases are
historical; the scoped candidate.34 casting acceptance above supersedes its open
cast report. Exact Forever first-success ordering remains gated.
[Investigation](reference/CIRCLE-BLOCKED-ACTION-2026-10-12.md).

The candidate.31 cases below are retained historical acceptance context.

## Ground-placement retirement validation

After candidate.36 reload, the Forever Targeting tab and ground-placement setup
option must be absent. Ordinary ground spells should expose the native reticle;
user macros remain unchanged. Test both cast edges and combat, R3 ping, Circle
cast/reticle cancellation, vehicle/skyriding/override L2+R2, held release, manual
drag/remove and HUD feedback. The assistant does not operate the game. Prior
ground-placement acceptance below is historical and superseded by this retirement.

## Installed candidate.31 Circle acceptance

Circle uses a native secure cancel-all click through explicit configuration
review for empty Base PAD2; it does not map Escape or open Options.
Exact first-success stock parity remains gated. After installation:

1. On an already installed character, `/cpf update` explicitly opens review;
   no configuration-revision bump forces a full prompt. Review before/after bindings.
   Use Proposed for the new Circle only if desired;
   Keep and existing manual Circle commands must remain unchanged. Confirm all
   other ordinary/modified/D-pad, keyboard, class, utility, mount and ping bindings.
2. With a hard target while casting/channeling or placing a ground spell, Circle
   cancels the spell/placement **and clears the hard target**. This is deliberate
   cancel-all behavior. Idle Circle opens no menu; release performs no second action.
3. Native ping/aura/utility rings and dialogs retain their own Circle cancel. Test
   held UI input into combat, repeated use, ground-placement fallback and all banks.
4. Remove/rebind Circle, reload/login and switch GUID: removal/manual command must
   persist without automatic restoration. Shared Base ownership remains explicit.
5. Recheck accepted HUD/power, ping, Required Items, saved layouts, class access,
   ordinary/temporary drag/remove and keyboard/foreign owner behavior. Inspect
   actual native authority/taint and distinguish hard target from soft indicators.

Source/offline proof is recorded in the
[Circle research](reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md); none of these
Retail cases has been performed for candidate.31.

## Accepted fixes and remaining layout acceptance

- Native ConsolePort account ring ForeverPings: aimed R3 release ping; no initial hold ping;
  no tap artwork; hold reveals the real native ring. Native release, stick,
  sticky, cancel and editor behavior. Six ping types; account data seeded once
  without overwriting later edits. Candidate.27 functional code retained as
  disabled backup outside the addon/TOC. See candidate.28 implementation notes.
- Immersion Required Items: deferred native offset recalculation owned by
  Forever, qualified for Immersion 1.4.61. One Forever policy field enabled on
  login for an accepted installation; no configuration revision bump/reinstall,
  Immersion update, ImmersionSetup change or filesystem WTF editing.
- Edit Mode: exact saved managed layout reference (52 systems), active saved
  layout captured per character and owned account layout captured as default.
  Future in-game saves remain authoritative. Existing Party/manual geometry
  retained by installer review; new-copy Party defaults remain available.

## Preserve installed, accepted repairs

- Candidate.27 action recovery stays passive; automatic action-slot restoration
  remains removed and cannot be re-enabled by the old toggle.
- Temporary action pages retain native drag/drop, clear stale direct-action
  caches/latches and avoid needless binding reapplication. L2+R2 temporary routing,
  class actions/rings and HUD stay intact; ground interception is retired.
- The original quest wipe's exact writer remains unconfirmed. Old Copybara
  backups are stale, and that addon is uninstalled; do not use them for recovery.

## Deployment procedure after authorization

1. Recheck every dependency's official stable Retail release for that session.
   Respect the user's prohibition on updating Immersion. Include only actual
   changed packages, otherwise copy only Forever through the tested scoped
   update builder/installer. Requalify source if dependencies change.
2. Confirm WoW closed, exact tested/pushed source and matching artifact hashes.
   Run the scoped preview/installer, verify backups and installed readback.
3. Verify unselected addons, WTF inventories and junctions unchanged. Never
   directly edit live WTF, prune CurseForge helpers or reship unchanged addons.
4. Record installed version/hash and retain previous package/code/config backups.

## Regression checklist (reported ring and Required Items defects accepted)

1. R3 neutral tap: one aimed unit/world ping on release with no menu. Holding must send no initial ping. Repeat holds without reload and during ordinary refreshes; each selected release sends once. A neutral hold release sends the aimed fallback.
   Hold: native ring artwork, readable icons and native selection/release/cancel
   behavior. Test all six types, combat/noncombat and account availability on DH.
   Edit/reorder/remove a ping entry and reload: edits persist without reseeding.
2. Open Paladin aura and ordinary utility rings after the ping ring. Confirm
   their context, artwork, bindings and pooled icon texture coordinates remain
   intact. Compare the ping ring appearance against these native rings.
3. Reopen a Required Items turn-in like The Dark Part of the Woods, including
   incomplete/complete progress, multiple items, money/currencies and item updates.
   The text moves up and the full item panel remains above the controller footer.
   Close/switch quests before the correction; no stale dialog movement.
4. Rewards, quest offers and gossip retain their existing position/animation.
   Test scale/base-offset edits, dynamic offset Off, top and nameplate anchors;
   those native preferences remain respected. Check combat/Edit Mode deferral
   and /cpf diagnose's immersionProgress status without a full install prompt.
5. Verify the currently chosen Edit Mode layout and breath/timer bar. Compare
   other newly positioned systems and Party frames. Save another small Edit Mode
   change, close, reload/login: Forever's known default tracks it, without moving
   anything back. Another character's different selection remains different.
6. Smoke-test ordinary bars, dragonriding/skyriding and quest/vehicle/possession
   overrides: rearrange/remove/add actions, transition in/out and reload/login.
   Edits persist and no removed action returns. Confirm L2+R2 temporary access,
   native exit controls, native ground reticles and personal class rings.

Automated offline passes do not substitute for these hardware/rendering tests.
