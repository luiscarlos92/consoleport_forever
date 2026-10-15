# Current implementation and acceptance

Status: maintained
Reviewed: 2026-10-15
Evidence: [candidate.39 install](../evidence/delivery/live-install-candidate39.json),
[independent readback](../evidence/delivery/candidate39-independent-readback.json),
[fresh Windows CI](../evidence/test-results/candidate39-fresh-ci.json),
[Circle acceptance](../evidence/circle/candidate34-live-acceptance-2026-10-12.json).

## Installed checkpoint

Candidate.39 was installed October 14 at **13:47:40 Toronto** from tested/pushed
source `80bbaf1dfb7624f56ef8b30e55ce7f943574c0c1`. It implements the shared default
Utility Ring with first eligible
activation, retained unavailable choices and independent `/cpfutility off` plus
reload. All 90 runtime/source checks and 66 tooling tests pass against complete
62-product-file and 145-tool/test-file inventories. Native admission, open-wheel
editing/deferral, safe next-startup seed, GUID isolation and failure containment
are exercised with locked native source; five defect controls are rejected.
Schema3/revision20 and native controller/class/Ping ownership remain.
[Qualification](../evidence/test-results/candidate39-shared-utility-qualification.json),
[implementation and manual boundary](reference/SHARED-UTILITY-RING-RUNTIME-2026-10-14.md).
Fresh clean Windows CI passes the same 90/66 checks with matching complete
inventories. Only Forever was selected with WoW closed. Independent readback
verifies 59 installed files, 2,847 other addon files, 313 WTF files, 42 links/root
anchors and all 25,824 prior backup files/2,360 directories. No dependencies or
live WTF were written; no game input occurred. The user owns next login/reload
and manual spec/character/item/edit/persistence/disable checks. Accepted revision20
needs no new setup review. Retail CPU, taint, timing, rendering and persistence
acceptance remain open; K04/K05 are unchanged.
[Delivery](../evidence/delivery/candidate39-independent-readback.json).

On October 15 the user reports promising initial shared Utility Ring tests across
different specs on one character. This is preliminary positive Retail feedback;
exact abilities/specs, silent hide/return behavior and loaded version were not
independently verified. Cross-character/class, item, editing, persistence,
disable/re-enable, measured CPU and taint cases remain individually unasserted.
K04/K05 remain open.
[User observation](../evidence/utility-ring/candidate39-user-observation-2026-10-15.json).

### Previous candidate.38 checkpoint

The final bounded candidate.38 build was installed October 14 at **00:02:27
Toronto** from tested/pushed source `b89fa7dfa2d5837235a97e6ef411783f6ea7b9b8`.
It automatically collects native action-label transition and first blocked-call
stacks, with independent retention/work bounds. It also recognizes the qualified
LiteMount 12.1.5-1 identity: all 115 vendor files already matched on disk before
this deployment and were not replaced. Schema3/revision20, native input/feedback
and permanent ground-placement retirement remain unchanged; no new setup review.
All 79 runtime/source checks and 66 tooling tests pass with exact current
inventories. [Qualification](../evidence/test-results/candidate38-trace-qualification.json).
Only Forever was selected while WoW remained open. Independent readback verifies
55 files, 2,252 other addon files, 311 WTF files, 42 links/root anchors and all
25,456 prior backup files/2,342 directories.
A refused staging attempt preserved 53 game-written WTF changes before retrying
from a fresh snapshot. No direct WTF/vendor writes or game input occurred.
[Delivery](../evidence/delivery/candidate38-independent-readback.json).
The user owns reload/ordinary play; engine logging must stay off for new trace
hooks. K05 remains open: this is diagnostic collection, not a Retail error fix.
[Investigation](reference/COMBAT-ERROR-AUDIT-2026-10-13.md).

### Previous candidate.37 checkpoint

Candidate.37 was installed October 13 at **00:58:18 Toronto** from tested/pushed
source `4146195e5b126c6e4e1a606d21512e1e7ee8b26f`. It repairs
demonstrated passive-observer read safety and blocked-event attribution coverage.
The native cooldown taint cascade recurred during ordinary combat on candidate.37.
Saved blocked-event security labels now identify `ConsolePort_Bar`-attributed
stock-button `action` taint; the first write/callback remains unknown and K05 is
open. [Recurrence evidence](../evidence/runtime-errors/recurrence-2026-10-13.json).
Schema3/revision20, native input/feedback and the permanent targeting
retirement remain unchanged. [Audit](reference/COMBAT-ERROR-AUDIT-2026-10-13.md).
All 78 runtime/source checks and 66 tooling tests pass with complete current
inventories. [Qualification](../evidence/test-results/candidate37-errors-qualification.json).
Independent readback verifies 55 installed files/four product changes, 2,252 other
addon files, 310 installer-start WTF files, 42 links/root anchors and all 24,353
prior backup files. The game's 67 preflight-to-install WTF changes were retained.
WoW was closed; no dependency/WTF writes or game input occurred. The code loads
on next login or user-owned reload; accepted revision20 needs no new review.
No Retail error resolution, CPU improvement or blanket input/visual acceptance
is claimed. [Delivery](../evidence/delivery/candidate37-independent-readback.json).

### Previous candidate.36 checkpoint

Candidate `2.0.0-candidate.36` was installed October 12 at **21:50:35 Toronto** from
tested/pushed source `61a50ccb9a63e3275f1f708657de681bcae8292c`. The user's explicit
purge removes the Targeting tab, placement adapter/preferences/registry, setup
policy, scans and diagnostic hooks. Ping, Circle, temporary routing and HUD remain;
old saved preferences stay inert. StoreSchema 3/configuration revision20 are
unchanged. Local and fresh Windows CI passed all 76 runtime/source checks and 66
tooling tests with matching complete inventories. Independent verification confirms
55 installed files, four removed modules, 2,252 other addon files, 310 WTF files,
42 links/root anchors and all 23,982 prior backup files preserved. No dependency
or WTF writes or game input. User owns reload; no new setup review is required.
The user subsequently reports "generally seems to be working" after delivery.
This is general gameplay feedback; measured CPU improvement and individual
input/visual/taint cases remain unverified.
[Observation](../evidence/targeting/retirement-user-observation-2026-10-12.json).
Ground placement is a standing exclusion under
[decision 0007](decisions/0007-ground-placement-retirement.md), not pending parity work.
[Retirement](reference/TARGETING-RETIREMENT-2026-10-12.md),
[qualification](../evidence/test-results/candidate36-purge-qualification.json),
[fresh CI](../evidence/test-results/candidate36-fresh-ci.json).

### Previous candidate.35 performance checkpoint

Candidate `2.0.0-candidate.35` was installed October 12, 2026 at **19:52:51 Toronto**
from tested/pushed source `5359b52b92b5f4fb97178327f902f1203e31e9eb`, retaining
StoreSchema 3/configuration revision20 and native behavior. It reduces reproduced
diagnostic copying, routine skin/layout work and broad event initialization, and
adds disabled-by-default bounded callback timing. Final qualification passed all
76 runtime/source checks and 66 tooling tests, retaining the 72/66 baseline and
new defect/fallback controls. Independent readback verifies all 59 selected files,
2,252 unselected addon files, 310 WTF files, 42 links, all root anchors and all 23,611
prior backup files preserved. Eight runtime files changed; no dependency/WTF
writes or game input. User owns reload; an accepted revision20 character needs
no new setup review. Retail CPU/visual/input/taint acceptance remains unverified;
K04 remains open. Delivery is separate from performance acceptance.
[Qualification](../evidence/test-results/candidate35-hud-qualification.json).
[Investigation](reference/HUD-PERFORMANCE-2026-10-12.md).
Fresh Windows CI passed the same 76 runtime/source checks and 66 tooling tests;
complete product/tool/test and lock inventories match the local qualification.
[CI receipt](../evidence/test-results/candidate35-fresh-ci.json).

### Previous candidate.34 checkpoint and scoped acceptance

Candidate `2.0.0-candidate.34` was installed October 12, 2026 at 17:08:57 Toronto
from tested/pushed source `36466db91a88a97c4627cdf5863d8dbdd23de6ab`.
Standing user permission authorizes qualified Forever updates while playing
unless explicitly prohibited; it remains active until revoked.
Independent readback verifies 59 files, 2,617 unselected addon files and 308 WTF
files unchanged from installer start, 42 links/root anchors preserved and 23,242
prior backup files unchanged. Candidate.33 code and current configuration have a
new verified backup. Three runtime files changed; no game input or direct WTF
writes occurred.
[Installation](../evidence/delivery/live-install-candidate34.json),
[independent readback](../evidence/delivery/candidate34-independent-readback.json).

Candidate.32/revision 18 replaces forbidden RunMacroText dispatch with native
saved-macro RunMacro and preserves inherited OnClick. The automatic login review
returns for accepted revision-17 characters; one account CPF Circle macro needs
Use Proposed and Apply. Macro names/bodies, manual bindings and accepted features
retain guarded ownership; StoreSchema remains 3. No dependency or WTF writes.
Full local and fresh Windows CI passed 70 runtime checks and 66 tooling tests,
including 328 Circle assertions. Retail repair acceptance remains user-owned.
[Investigation](reference/CIRCLE-BLOCKED-ACTION-2026-10-12.md),
[fresh CI](../evidence/test-results/candidate32-fresh-ci.json).

## Candidate.33 migration deferred and installed candidate.34

The user reports no error but continued lack of interruption. Saved revision19
retains legacy CLICK with a macro-edited resource deferral, so the direct native
binding was not active in that session. Cached commands match the intended body;
exact API format remains unknown. Candidate.34/revision20 tolerates CRLF/final LF
only for identical commands, preserves native bytes and restores reviewed owned
migration. Automatic format/cast/native-call logs require no diagnose command.
Retail cast interruption is now user-confirmed on candidate.34. The exact
candidate.33 API body difference remains unconfirmed; successful repair does not
independently establish those earlier bytes.
[Investigation](reference/CIRCLE-MACRO-FORMAT-2026-10-12.md).
The full candidate.34 gate passed 72 runtime checks and 66 tooling tests, with
328 retained legacy Circle assertions and 94 native binding/log assertions.
[Qualification](../evidence/test-results/candidate34-circle-format-qualification.json).
Fresh Windows CI passed the same 72 runtime checks and 66 tooling tests with
matching source inventories. [CI receipt](../evidence/test-results/candidate34-fresh-ci.json).
The user's standing permission authorizes qualified updates while playing unless
explicitly prohibited; it supersedes one-off authorization expiry.

## Acceptance

On October 12 the user confirmed candidate.34: "it worked", resolving the reported
Circle cast-interruption failure. Menu closure was confirmed in earlier reports.
Ground-placement cancellation was **not tested**: the user reports the existing
ground-targeting adapter intercepts those casts and accepts leaving this case
untested. Channel cancellation, independent hard-target clearing and broader
combat/modifier/character cases are not individually asserted. Exact Forever
first-success ordering remains gated.
[Acceptance record](../evidence/circle/candidate34-live-acceptance-2026-10-12.json).

### Historical Circle implementation and qualification

Candidate.31/configuration revision 17 implements the user's Circle-only request.
An explicitly reviewed empty Base PAD2 can use a native secure cancel-all click
without Escape/Options. Cast, placement and hard target cancel together, unlike
stock first-success behavior. Manual bindings/removals and native UI/ring priority
remain. Deployment does not activate the new binding automatically: existing
characters use `/cpf update` and review the proposed binding outside combat/Edit Mode.
Candidate.31 was installed and subsequently replaced; it was **not Retail accepted**.
[Research and proof](reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md).
That candidate's source passed 69 runtime/source checks and 50 tooling tests,
including 285 Circle assertions and 40 native-reference assertions.
[Preparation qualification](../evidence/circle/qualification-2026-10-11.json)
describes the tested preparation stage; installation/readback are separate records.

The later repository-only CI input repair reconstructs missing pinned dependency
archives/files from the explicit verification stage, rejecting existing drift.
It changes no installed product or lock. Complete local checks and fresh Windows
CI passed 69 runtime/source suites and 57 tooling tests, with matching complete
source inventories. The CI run and retained reports are recorded in the
[follow-up qualification](../evidence/test-results/candidate31-ci-inputs-qualification.json).

On October 10 the user reported: "all fixed on ring and required item frame".
The native account ping ring's reported behavior/reopening defect and Forever's
Immersion Required Items correction are accepted in Retail. Broader combat,
account, editing and preference cases are not individually asserted.

Earlier acceptance covers reported candidate.17 face-composition/HUD defects
and Paladin/DH ground casting, as recorded in [manual cases](MANUAL-TEST-CASES.md).
These are scoped observations; later changes still require regression gates.

## Current execution boundaries

- Store schema 3; installed code offers configuration revision20. Circle cast
  interruption is user-confirmed. Last independently read saved acceptance was
  revision19 before that confirmation; appliedRevision20 was not separately read.
- Native ConsolePort input recovery enabled. Full custom modes/UI takeover and
  hidden-control replacement remain suspended.
- Temporary native-family routing uses L2+R2, preserving ordinary banks.
- Ground placement and its Targeting panel remain retired under decision 0007.
- Automatic action restoration removed; diagnostic observers remain passive.
- Native-bound gamepad ping keys (preset R3) send on release through native
  secure machinery. Native selection is armed immediately; neutral/empty tap
  falls back, deflected/sticky early release can select. Hold artwork uses a
  cosmetic monitor and actual ConsolePort account-ring data.
- Saved Edit Mode layouts are authoritative. Capture does not save/import/select
  layouts; existing manual/Party edits remain owned by the user.
- Personal class-ring augmentation and scoped class-access repair remain distinct
  from removed action-slot restoration. Generic proposal helpers are not limited
  by every three-class presentation/repair guard.
- Reviewed sidebar/bag/micro visibility, qualified class-row suppression and
  focus-feedback cosmetics have independent activation; native power remains.
- Stored targeting policy flags are inert; recovery does not expose its retired
  panel or reactivate ground-placement interception.

[Architecture](ARCHITECTURE.md) records prerequisites;
[known issues](KNOWN_ISSUES.md) records open reports and gated features.

## Validation and repository work

Candidate.30 retains [67 runtime/source passes](../evidence/test-results/candidate30-runtime.json)
and [39 tooling passes](../evidence/test-results/candidate30-tooling.json).
These are historical exact-source receipts; changed inventories need current
checks. Restructure verification is retained in the
[repository receipt](../evidence/organization/2026-10-11/ai-native-restructure.json).
Offline checks do not certify Retail authority, hardware or rendering.

The October 11 restructure changes no runtime/installed state. The complete
previous chronology is preserved in the
[historical snapshot](archive/ai-native-2026-10-11/IMPLEMENTATION-STATUS.pre-restructure.md).
Use the [cumulative checklist](NEXT-DEPLOYMENT-CHECKLIST.md) for later Retail tests.

Restructure qualification: [67 runtime/source passes](../evidence/test-results/ai-native-restructure-runtime-2026-10-11.json)
and [45 tooling passes](../evidence/test-results/ai-native-restructure-tooling-2026-10-11.json),
including six new documentation-checker tests. All 30 maintained page/skill files
pass navigation/structure checks; three skills pass the standard Skill Creator
validator. Current inventories include the imported provisioning scripts as
data, without executing them. Nine exact historical snapshots and seven preserved
source/reference/fallback trees are verified unchanged. These are repository
qualification results, not a new Retail test or deployment.

The subsequent October 11 [code/document reconciliation](reference/CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md)
expands actual initialization, configuration, ownership, visuals and dormant UI
contracts. It corrects stale/overbroad statements without changing product,
tooling, dependency or installed state. Historical restructure counts above
describe that earlier checkpoint; current navigation checks and preserved-source
verification are recorded in the separate
[reconciliation receipt](../evidence/organization/2026-10-11/code-documentation-reconciliation.json).
