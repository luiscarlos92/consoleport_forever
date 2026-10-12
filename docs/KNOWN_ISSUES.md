# Known issues, limitations and deferred proof

Status: maintained
Reviewed: 2026-10-12
Evidence: [current status](IMPLEMENTATION-STATUS.md),
[interaction analysis](TEMPORARY-MAIN-BANK-ANALYSIS-2026-10-11.md),
[candidate.27 diagnosis](../evidence/action-recovery/candidate27-diagnosis.json),
[pack gates](../tools/build_pack.py).

## Open reports

| ID | Status and established facts | Missing observation / next boundary |
| --- | --- | --- |
| K01: quest-object Square interaction | User-reported failure with triggers released and floating hand; mouse interaction worked. Source/offline main-command analysis does not establish blanket ordinary-bank disabling. | Quest identity and effective PAD3 binding/native interaction target during recurrence. INTERACTTARGET differs from unconditional pointer click. Do not patch a guessed cause. |
| K02: original Paladin quest action loss | Read-only evidence established lost/reassigned action storage. The exact original writer remains unconfirmed. Candidate.26 restoration was followed by editing regressions and removed in candidate.27. | Passive event/loadout/writer context on recurrence. Do not restore automatic pickup/place or use stale Copybara backups. |
| K04: gameplay HUD CPU spikes | User-supplied Active-mode capture reports 364.155 ms peak, repeated >100 ms ticks. Candidate.35 removes reproduced redundant diagnostic copies, routine skin reconstruction and broad routine event setup; offline counters establish reduced work. | Same-client/scenario/profiler before/after measurements, optional callback timing, and visual/input/taint observations. Exact live spike cause and improvement are unverified. [Investigation](reference/HUD-PERFORMANCE-2026-10-12.md). |

## Inactive or gated capabilities

These are explicit limits, not newly discovered failures:

- Full custom secure modes, UI context takeover and hidden-control replacement
  remain suspended under native recovery. Native combat-claim relinquishment,
  temporary routing and independent ground placement remain distinct active paths.
- Exact additional stick-return/close-and-continue and active-entry cancellation,
  one-success gameplay Circle, additional learned class/pet selector activation,
  transient 0.5-second loot hold and held cinematic skip remain proof gates.
- Candidate.34 supplies the installed, reviewed Circle cancel-all approximation;
  cast interruption is user-confirmed and ground cancellation remains untested.
  It clears a coexisting hard target when stopping a cast/reticle. Exact native
  first-success behavior remains unavailable; Escape was explicitly rejected.
  [Research/proof boundary](reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md).
- LM_B2 has no proven current default icon; preserve explicit/native data.
- Other unaudited scroll widgets retain native input. Offline UI/map/window tests
  do not assert that disabled custom context routes are enabled.
- Classic/native Forever client compatibility, public distribution and adaptive
  layouts/controllers/resolutions are outside current personal scope.

## Demonstrated source/document differences

The current focus-visual setup label still says it suppresses gameplay icons.
Actual FocusVisuals preserves icons/cooldowns and suppresses seven transient
feedback regions. Runtime feature strings may also continue to say Retail
acceptance is pending after the later user receipt accepted specific defects;
they report source readiness rather than ingesting acceptance records. The
maintained specifications describe actual code and scoped user observations.
This documentation pass changes neither source label nor runtime diagnostic text.

Preference history currently appends complete prior tables without a retention
cap or exposed restore-history command. Revert resets the draft, not that
history. Generic ring preservation also has a separate learned-form augmentation
path, so class-entry removal is not equivalent to action-slot removal. These are
established source limits, not new user defect reports. See
[configuration](reference/RUNTIME-CONFIGURATION.md) and the
[reconciliation record](reference/CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md).

## Resolved reported defects and acceptance limits

K03 Circle cast cancellation is **resolved for the user's reported candidate.34
Retail test** on October 12. Prior menu closure remains confirmed. Ground-placement
cancellation was not tested because the user reports targeting interception;
channel/independent target cancellation and exhaustive transitions remain unasserted.
The exact prior API formatting difference is still unknown.
[Acceptance](../evidence/circle/candidate34-live-acceptance-2026-10-12.json),
[investigation](reference/CIRCLE-MACRO-FORMAT-2026-10-12.md).

Candidate.30's native account ring/reopening and Required Items correction are
[user accepted](../evidence/forever-ui/candidate30-live-acceptance.json). Candidate.17
composition/HUD fixes have [scoped acceptance](../evidence/forever-ui/candidate17-live-acceptance.json).
Do not leave their old pending/rejected candidate notes as current open bugs.
The [cumulative checklist](NEXT-DEPLOYMENT-CHECKLIST.md) still lists broader
combat/account/preference/layout/persistence cases not individually claimed tested.

The Immersion options-list request was withdrawn. The parked UI reference and
older public roadmap are deferred, not a backlog authorization.

## Maintenance

Record reported symptom separately from demonstrated cause. Update status with
candidate/source/acceptance evidence; retain resolution links rather than hiding
the history. Do not open hypothetical bugs merely because offline testing has
limits. Required new observations stay explicit until available.
