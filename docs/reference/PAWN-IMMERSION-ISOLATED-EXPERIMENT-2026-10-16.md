# Pawn and Immersion isolated experiment

Status: maintained
Reviewed: 2026-10-16
Evidence: [full qualification](../../evidence/pawn-immersion/2026-10-16/qualification.json),
[installed-source dry run](../../evidence/pawn-immersion/2026-10-16/dry-run.json),
[prepared-source dry run](../../evidence/pawn-immersion/2026-10-16/dry-run-prepared.json),
[source pins](../../evidence/pawn-immersion/2026-10-16/experiment-inputs.json),
[staged plan](../plans/PAWN-IMMERSION-BRIDGE-2026-10-16.md).

The receipts below describe the completed isolated stage. The user subsequently
replied “Proceed” for [candidate.42 integration](PAWN-IMMERSION-RUNTIME-2026-10-16.md).
Later shared fixtures tighten pending-data modeling and add a summary assertion;
the retained stage receipts and their exact inventories remain unchanged.

## Authority and result

The October 16 continuation, "Proceeded to isolated experiment", authorizes the
isolated dry run. It does not authorize addon integration or installation.
The candidate is in `tests/prototypes/pawn_immersion.lua`, outside addon source,
TOC and startup. No game input, production/WTF writes, addon edits, package build,
deployment, commit or push occurred. This stage ends at review.

Both BetterBags source versions pass **246 assertions in 41 scenarios**, each
repeated in fresh VMs with Pawn-first and BetterBags-first provider loading.
Ten faulty variants fail their specifically expected assertions. T103/T104
retain the experiment in the normal offline runner. This supports source
behavior; it is not a shipping implementation or Retail result.

All 104 runtime/source checks and 74 tooling tests pass. Complete current
inventories match both receipts: 63 product files and 163 tool/test files.
All product bytes also match candidate.41's prior qualification. The final
close-transition correction was present before T103/T104 ran; the tooling suite
was rerun afterward to refresh its complete source inventory. No new remote CI
or release qualification is implied by these local checks.

## Source identity and reproduction

The fresh check finds all nine managed official stable dependency identities
current with the lock; no package refresh is needed. Official CurseForge
listing/file pages were reviewed before updating their observation timestamps.
[Discovery receipt](../../evidence/pawn-immersion/2026-10-16/dependency-discovery.json).
The optional installed Pawn release is independently observed as 2.13.17.
[Pawn metadata](../../evidence/pawn-immersion/2026-10-16/pawn-release.json).
Pawn remains outside the managed lock; capture does not authorize packaging it.

Twenty-five official source inputs are captured under ignored checkout scratch
storage and hash-pinned in a tracked manifest: Pawn 2.13.17, BetterBags v0.5.14
(installed) and v0.5.16 (prepared), Immersion 1.4.61 and the existing native UI
source pin. Original reference/fixtures and earlier pinned contracts are
unchanged. No vendor source is added to tracked product files. Four Python
checks exercise reconstruction, local/remote drift refusal and output guards.

Reproduce inside the checkout:

```powershell
python -B tools/capture_pawn_immersion_experiment.py
node tools/pawn_immersion_experiment.cjs
node tools/pawn_immersion_experiment.cjs --prepared
./tools/Test-All.ps1
```

Capture is an explicit network stage; execution verifies source hashes and has
no network access. Fresh Fengari VMs expose base, table, string and math only,
without disk, shell, package, debug or file-loading facilities. Runner receipts
go to `scratch/test-results`; reviewed copies are retained in dated evidence.
CI reconstruction and T103/T104 are configured, but no new remote CI run or
pushed-source proof is claimed.

## Actual-source execution and modeled boundaries

Pawn's actual main source and English localization execute. Its public budget
wrapper, upgrade arithmetic, best-item/history rules, scale visibility, armor
suitability, weapon/slot rules, tooltip updater and formatting functions run.
Parsed/cached item records and item values are explicit modeled inputs; upgrade
verdicts and percentages are not mocked. This does not test the complete stat
parser, cache population, startup, inventory scan or automatic scale selection.

Actual BetterBags provider registration, selection and upgrade resolution run.
The internal evaluator used by both versions agrees with the public API's
settled verdicts in the tested cases. The real late-registration callback runs
in bags-first VMs. All BetterBags modules and full startup are not exercised.

Actual Immersion summary population, reward collection, tooltip setter/pool,
inspector population, focus/unfocus, close/reopen and child-size measurement run.
The tooltip XML OnShow body uses a modeled scheduler. Native
`GameTooltip_ShowCompareItem` and the native comparison-item constructor execute
before a recording `C_TooltipComparison.CompareItem` boundary. The C comparison
engine and shopping-tooltip rendering are modeled. L2-facing
`ShowFocusedTooltip(true/false)` executes; hardware and the full controller
command parser do not.

Frame methods, text metrics, geometry, fades, timers and C API results are
models. These tests do not certify rendered pixels, secret-value/taint behavior,
hardware timing, persistence or measured Retail CPU.

## Findings and candidate behavior

### Summary arrow

BetterBags' normal item decoration inherits the native container button.
Its XML defines `UpgradeIcon` using `bags-greenarrow`, native atlas sizing,
overlay sublevel 1 and a top-left anchor. The candidate uses those properties
on Immersion's reward icon. This qualifies asset/layer/anchor selection, not
final appearance over a round icon or a different BetterBags theme's artwork.
Pawn's inline tooltip-arrow texture is a separate asset.

The candidate observes completed native `ImmersionFrame:UpdateItems`, scopes to
the actual reward list and current quest/type, and asks Pawn's public budgeted
API. Explicit BetterBags provider choices are respected. Currency and Required
Items are excluded. Native labels/context/vendor markers remain, with no scoring
fallback, new selection algorithm or configuration UI.

Verdict cases include upgrades, lower/equal items, Pawn's half-percent threshold,
player-level requirements, armor mismatch, two ring slots, excluded trinket stat
scoring, weapon handedness, no-stat rewards and the item-level option. Full
bonus-link variants sharing an item ID stay distinct. This is not exhaustive
item/class/unique-equip/relic coverage.

### Detail tooltip and L2

An additive observation after native `ImmersionFrame:SetItemTooltip` calls
`PawnUpdateTooltip` on the named pooled tooltip and full reward link. Pawn's
`SetHyperlink` argument resolves that link; it does not replace the native
`SetQuestItem` population or quest context.

All appended text, right-hand text and supplied colors are compared with the
same item processed through Pawn's bag-tooltip updater route. Cases vary decimal
precision, spec icons, alignment, upgrade/value options, custom/Unicode scale
and spec names. English localization runs; other translation files do not.
Pawn remains the text/math producer.

Ten native comparison focus/release cycles preserve the selected annotation
without another arrow query. Repeated opens reuse two tooltip frames with stable
modeled dimensions. Native context lines survive rebuilds. Shopping tooltips and
controller bindings are not rewritten by the candidate.

### Invalidation and pending work

Installation is idempotent. Narrow posthooks observe Pawn's real
`PawnResetTooltips` and `PawnResetBags`; Immersion is not registered as a bag,
and no global border override is installed. Refresh repopulates visible tooltips
through the native reward setter before annotation, avoiding text-stripping.

Budget nil stays pending. There are at most eight quarter-second retries per
generation, then no worker until a relevant event. Matching successful item-data
events can rearm reconciliation; unrelated/failed results cannot. Close cancels
work, and changed item/quest identity rejects stale results. Player equipment/
spec and Pawn reset events coalesce; other-unit spec events are ignored.
Missing/unsupported owners and modeled not-ready/opaque inputs are gated.

An extra close-transition test exposed an initial candidate defect: native
`UpdateItems` after dialog hide restarted one query (98 instead of 97 cumulative
queries in that reproduction). The corrected Start path checks effective dialog
visibility before activation, and eligibility uses effective item visibility.
Both direct hide and hidden-ancestor updates now stay inactive with zero added
queries. A retained control removes that guard and must reproduce the defect.

The candidate's readiness adapter is explicit: it does not establish shipping
bootstrap detection of Pawn's private initialized state. Initialized BetterBags
modules are supplied here; safe discovery when those modules are absent or late
also remains integration work. Full startup/load/event ordering is unproved.
The earlier dormant-follower lesson applies.

A comparable workload opens native details 12 times, compares ten times and
issues 240 Pawn reset notifications:

| Work | Native alone | With candidate |
| --- | --- | --- |
| Native reward-tooltip populations | 24 | 26 |
| Native comparison delegations | 10 | 10 |
| Native show-script invocations | 36 | 36 |
| Pooled tooltip frames | 2 | 2 |
| Added Pawn arrow queries | 0 | 50 |
| Added Pawn annotations | 0 | 26 |
| Coalesced bridge refresh batches | 0 | 1 |

The two extra populations refresh the visible rewards once after the burst.
Settled/closed sequences add zero retry queries. These are operation counts
under comparable modeled inputs, not Retail CPU measurements.

## Rejected defects and next gate

Ten controls must fail their intended assertion: always-upgrade arrows,
hardcoded text, item-level-only verdicts, budget nil cached as false, stale-widget
publication, duplicate annotations, text loss during comparison, unbounded
retries, Required Items scope leakage and hidden-dialog reactivation. An unrelated exception cannot count
as rejection; receipts name each expected assertion.

The source experiment supports minimal Forever integration after user approval.
That stage must qualify real startup/readiness and frame ownership, preserve the
independent Required Items policy, check native load/refresh order and recheck
optional Pawn contracts. Keep these controls and normal native/input/visual/
performance gates. Actual placement and longer-tooltip layout at the user's
scale, Retail restrictions/taint, controller timing and profiler cost remain
user-owned checks after separately authorized integration and delivery.
Current runtime/installed status is unchanged. Approval to integrate is next.
