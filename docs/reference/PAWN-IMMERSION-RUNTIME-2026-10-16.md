# Pawn feedback in Immersion rewards

Status: maintained
Reviewed: 2026-10-16
Evidence: [shipping bridge](../../addon/ConsolePort_Forever/UI/PawnImmersion.lua),
[runtime source pins](../../evidence/pawn-immersion/2026-10-16/runtime-inputs.json),
[staged plan](../plans/PAWN-IMMERSION-BRIDGE-2026-10-16.md).

The user approved the isolated experiment and subsequently replied “Proceed”
for Forever integration. Candidate.42 adds summary reward arrows and Pawn's own
tooltip notes to Immersion's detailed reward inspector. The selected reward keeps
its note through native L2 equipped comparison and release. Current status owns
the exact installed checkpoint; this page describes the source contract.

## Owners and activation

Pawn 2.13.17 remains external and optional. Forever never packages or modifies it.
Immersion 1.4.61 owns quest links, summary population, inspector pooling, selection,
focus and comparison. BetterBags v0.5.14 / v0.5.16 owns arrow-provider selection:
Forever resolves its real AceAddon Items module and asks GetActiveUpgradeProvider.
Only Pawn selection permits summary arrows. Tooltip notes independently respect
Pawn's tooltip options, as bag tooltips do. No new preference or persisted field.

OptionalDeps loads Pawn before Forever's observer. Pawn's readiness flag is
private: Forever observes PawnInitializePlugins after that private flag is set,
then a normally completed PawnInitialize and its deferred scale phase. It never
sets or guesses the private flag and never calls initialization itself. Missing,
unsupported, failed or unobserved late initialization stays dormant; reload is
required for a Pawn load after the login initialization opportunity. Both normal
provider load orders are covered. On-demand `/cpf status` includes Pawn readiness.

The main accepted-character Refresh installs the bridge after configuration
recovery checks, beside the independent Required Items repair. Busy reviews,
unaccepted/restored configuration, binding recovery and interrupted same-character
journals block presentation. Combat/Edit Mode do not block these unprotected
cosmetics; the bridge has no protected dispatch, settings or input writes.
Schema3/revision20 and existing Required Items policy remain unchanged.

## Presentation and lifecycle

After native UpdateItems, current visible reward/choice buttons are checked against
the real rewards array and current quest. Full quest links preserve bonus/scaling
identity. PawnShouldItemLinkHaveUpgradeArrow supplies the budgeted bag-equivalent
verdict. Nil stays pending; no item-level or class/spec fallback exists. An owned
texture uses native bags-greenarrow atlas dimensions, OVERLAY sublevel1 and the
native top-left icon anchor. Vendor/context markers remain independent.

After native SetItemTooltip, only named ImmersionGameTooltip entries in the
current active pool are eligible. GetItem must identify the current full quest
link before annotation. PawnUpdateTooltip receives that link; Immersion keeps
SetQuestItem and native context. Once per native population avoids duplicate
lines. Nothing parses or constructs Pawn's text, percentages, scales or icons.
Equipped shopping tooltips retain Pawn's existing hooks.

An unknown item remains pending. Retry repopulates through the native quest
setter before annotation; a foreign/secret/conflicting link receives no output.
When an already shown tooltip is repopulated, Forever reuses its original native
OnShow padding handler once after the new population. It tracks pending native
measurement so initial Show and a same-frame refresh cannot add padding twice.
It never hides the selected tooltip to resize it or changes comparison focus.

Close/population replacement cancels owned retry timers and clears owned arrows.
Current frame, inspector, pool, reward array, quest and full link must still match
before publishing a delayed result. Pending retries stop after eight quarter-second
attempts per generation. Matching successful item events can restart a batch.
PawnResetBags/Tooltips and equipment/player-spec events coalesce through one
zero-delay refresh. No bag/tooltip registration side effects, idle polling,
per-frame worker or scan across inventory. Work counters are volatile, with no
per-item diagnostic persistence.

## Qualification and limits

T105/T106 execute the shipping module with installed/prepared BetterBags source,
the shared scoring/formatting/comparison cases and real Pawn initialization,
Immersion quest handlers and PlayIntro. Locked AceAddon lookup bodies execute.
Sixteen faulty variants must fail their intended assertions. Extra cases cover
failed initialization, readiness ordering, lost pool/frame, review/restore/recovery,
opaque identities, two simultaneous choice tooltips, three native quest events
and twelve visible refreshes during
held comparison with stable text/size. Workload receipts compare equivalent native
sequences and require unchanged comparison/pool bounds and one coalesced batch.

The frame engine, text metrics, timing and C item/compare APIs are explicit models.
Pawn option migration, keybinding/UI startup and stat parsing are modeled
subsystems; cached input statistics feed actual Pawn arithmetic and formatting.
This is not a complete addon-stack startup or Retail pixels, taint, hardware,
persistence or CPU certification. User-owned checks compare the same item and
configuration in bags, summary, detail and L2 hold/release, then another choice,
close/reopen, a second quest, a non-upgrade and currency/no-stat rewards.

Runtime/TOC/bootstrap, architecture, compatibility, controller/state requirements,
test entry points and current delivery documents are the affected maintenance
surfaces. Dependency lock, native input, saved schema and configuration revision
need no change. Isolated-stage receipts and immutable source evidence are retained.


The two-choice refresh reproduction found that deleting/replacing a record while
iterating the live tracking table could skip the other tooltip. The shipping
bridge snapshots that small table before native repopulation. A negative control
restores live-table iteration and must fail with a stale note on one choice.
This extends the isolated experiment’s earlier single-tooltip refresh coverage.
