# Current implementation and acceptance

Status: maintained
Reviewed: 2026-10-12
Evidence: [candidate.32 install](../evidence/delivery/live-install-candidate32.json),
[independent readback](../evidence/delivery/candidate32-independent-readback.json),
[user acceptance](../evidence/forever-ui/candidate30-live-acceptance.json).

## Installed checkpoint

Candidate `2.0.0-candidate.32` was installed October 12, 2026 at 15:08:29 Toronto
from tested/pushed source `dce5c5016344fbc8df1e72d98063f898cae294a3`.
The user explicitly authorized this Forever-only update while WoW was running.
Independent readback verifies 59 files, 2,617 unselected addon files and 308 WTF
files unchanged, 42 links/root anchors preserved and 22,504 prior backup files
unchanged. Candidate.31 code and current configuration have a new verified backup.
[Installation](../evidence/delivery/live-install-candidate32.json),
[independent readback](../evidence/delivery/candidate32-independent-readback.json).
This authorization is fulfilled and grants no later installation or game input.

Candidate.32/revision 18 replaces forbidden RunMacroText dispatch with native
saved-macro RunMacro and preserves inherited OnClick. The automatic login review
returns for accepted revision-17 characters; one account CPF Circle macro needs
Use Proposed and Apply. Macro names/bodies, manual bindings and accepted features
retain guarded ownership; StoreSchema remains 3. No dependency or WTF writes.
Full local and fresh Windows CI passed 70 runtime checks and 66 tooling tests,
including 328 Circle assertions. Retail repair acceptance remains user-owned.
[Investigation](reference/CIRCLE-BLOCKED-ACTION-2026-10-12.md),
[fresh CI](../evidence/test-results/candidate32-fresh-ci.json).

## Acceptance

Candidate.31/configuration revision 17 implements the user's Circle-only request.
An explicitly reviewed empty Base PAD2 can use a native secure cancel-all click
without Escape/Options. Cast, placement and hard target cancel together, unlike
stock first-success behavior. Manual bindings/removals and native UI/ring priority
remain. Deployment does not activate the new binding automatically: existing
characters use `/cpf update` and review the proposed binding outside combat/Edit Mode.
Candidate.31 is installed but **not Retail accepted**.
[Research and proof](reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md).
The installed source passed 69 runtime/source checks and 50 tooling tests,
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

- Store schema 3; installed configuration revision 17, prepared revision 18.
- Native ConsolePort input recovery enabled. Full custom modes/UI takeover and
  hidden-control replacement remain suspended.
- Temporary native-family routing uses L2+R2, preserving ordinary banks.
- Ground placement is a separate active adapter.
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
- The Targeting panel remains available in recovery. Accepted stored policy
  flags alone do not prove the corresponding dormant UI path is enabled.

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
