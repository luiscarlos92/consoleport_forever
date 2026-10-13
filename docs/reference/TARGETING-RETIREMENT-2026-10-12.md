# Ground-placement and Targeting panel retirement

Status: maintained
Reviewed: 2026-10-12
Evidence: [requirements](../REQUIREMENTS.md), [runtime](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua),
[test runner](../../tools/test-all.cjs).

## Authority and measured scope

The user explicitly requests removal of Forever's Targeting tab and all of its
ground-placement behavior, followed by confirmation of the exact removal list.
R3 ping, Circle cancellation, temporary vehicle/skyriding/override routing and
HUD/native feedback remain. No replacement casting/macro feature is introduced.

Post-install [user callback evidence](../../evidence/performance/2026-10-12/mode-callbacks-before-retirement.png)
records runtime.modes: 19 calls, 1028.210 ms
total, 54.116 ms average, 139.041 ms peak, eight calls over 100 ms. skin.visual:
103 calls, 443.885 ms total, 4.310 ms average, 22.484 ms peak, 32 calls over 10 ms.
The cropped report does not show the loaded candidate identity. The user reports
smoother gameplay after candidate.35 delivery. Timings are inclusive, overlapping
and not paired to a specific Numy tick.
Repeated routing/placement setup was the leading source-supported hypothesis;
the evidence does not attribute all mode cost or the 189.575 ms engine peak to
ground placement. Retirement is a user scope decision, not a claimed diagnosis
of every remaining freeze.

## Removal and preservation

Delete the product Ground, Preferences, Registry and UI/Targeting modules and
their TOC entries. Remove activation/probe/setup fields, observation scans,
spell-load/CVar refresh listeners used exclusively by placement, and proof output.
Keep ping at its existing runtime path and preserve shared artwork used by HUD
prompts. No unrelated runtime module is relocated or unloaded.

Old saved tables, observations, flags, managed-field baselines and journals remain
inert. New stores do not create preference/history tables. Legacy unknown values
do not gate unrelated setup. Restore defers retired policy fields and continues
to review available unrelated fields. No filesystem WTF edits or schema/configuration
revision bump. Previously loaded wrappers disappear only after the user reloads.

## Regression evidence and limits

Baseline: 76 runtime/source checks and 66 tooling tests. Replacement T12 verifies
new-store absence, old-data preservation and unrelated restore; T38 rejects retired
modules/symbols in the full product inventory; T42 retains native binding dispatch
through the actual pinned CP/LAB/Blizzard source across all 32 chords, cast edges,
combat/focus cycles and foreign owners, with native reticles and macro slots.
T61 retains all-class temporary page/drag/cache/held-release coverage, replacing
the removed ground-interception assertion with native action-slot preservation.
The shared native fixture is extracted from the old test without relying on the
retired product. T42 executes the actual retained TemporaryRouting header-owner
initializer; a missing initializer fails native LAB click dispatch. T12 rejects
reintroduced placement modules and recreation of retired preference tables.
Other mandatory suites remain active.

Final local qualification passed all 76 runtime/source checks and 66 tooling tests.
Complete product/tool/test inventories match the tested reports. Four product
modules are removed, six product files changed, and 52 product files are unchanged.
All nine official stable Retail dependencies were freshly inspected and current;
no package refresh or dependency delivery is needed.
[Qualification](../../evidence/test-results/candidate36-purge-qualification.json),
[runtime](../../evidence/test-results/candidate36-purge-runtime.json),
[tooling](../../evidence/test-results/candidate36-purge-tooling.json).

Removal eliminates the ground observation, command preparation and secure wrapper
installation paths; temporary routing still has its existing cost. Offline tests
do not quantify a Retail speedup or certify hardware timing, taint/rendering.
After reload the user should validate tab/toggle absence, native reticles/macros,
R3, Circle, temporary families, editing and unchanged HUD feedback, then compare
runtime.modes under a consistent gameplay/profiler window.

## Delivery

Candidate.36 is qualified locally and awaiting scoped delivery. Installation
receipts will record completion. No game operation, direct WTF write or dependency
replacement is authorized by this removal; standing qualified Forever-only
delivery applies.
