# Validation and proof boundaries

Status: maintained
Reviewed: 2026-10-12
Evidence: [runner](../tools/test-all.cjs), [tool tests](../tools/run_tool_tests.py),
[CI](../.github/workflows/tests.yml), [test instructions](../tests/AGENTS.md).

## Entry points

```powershell
python -B tools/check_documentation.py
./tools/Test-All.ps1
```

The documentation checker reads maintained files only and emits no receipt or
live write. The complete entry point runs Python tooling tests followed by the
Node/Lua runner and writes exact-source reports under `scratch/test-results`.
`npm test` runs the Node runner only; it is not the full release gate.

CI separately retrieves/verifies pinned official dependency archives, then runs
the same full checks. Local tests assume qualified cached inputs and do not fetch
network packages or use live game configuration. Simulations use guarded fresh
scratch copies. `tools/local` scripts can be hashed/parsed; they must not execute.

## Relevant suites and mandatory gates

Ground-placement retirement is a standing exclusion under
[decision 0007](decisions/0007-ground-placement-retirement.md). T12, T38 and T42
remain mandatory; old placement fixtures/acceptance do not justify restoring
the feature or weakening these gates. A renamed or macro-based replacement also
requires a new explicit user request authorizing ground placement.

| Change | Required proof / existing gate |
| --- | --- |
| Any runtime/executable tool or release qualification | Full `Test-All.ps1`, complete current product/tool/test hashes; no failed/skipped required checks. |
| Binding/input/UI ownership | T41 actual native Layers/Input combat handoff and engine UseAction dispatch for all 32 chords; held UI release, late widgets, foreign modals, repeated cycles. |
| Ground-placement retirement | T12 retains inert legacy data and restores unrelated journal fields; T38 rejects retired product modules/symbols/tab; T42 actual native CP/LAB/Blizzard binding-to-action dispatch for all 32 chords, both cast edges, combat/focus/foreign owners, reticles and macro slots. T61 retains temporary routing and native editing coverage. |
| Temporary routing/pages/editing | T61's 4,160 all-class/family/chord cases, native drag/cache/latch persistence; T62 actual recovery startup; T64 no slot restoration. |
| Round surfaces/background/usability or related dependency | T24/T49/T53 with actual native/Masque composition and negative controls; all faces, late Show, empty/refill and real range/resource restrictions. |
| HUD geometry/class placement | T45/T50/T51 with actual unanchored native hierarchy, onscreen/collision, stationary labels, chord side and continuous bank opacity. |
| Press/cooldown/resource feedback | T54/T55/T56/T57; preserve native effects and power rather than suppressing the wrong class UI. |
| Class bindings/GUID persistence | T43/T47/T58/T59/T63 plus binding/ring ownership, restore and sequential-VM tests. |
| Account ping ring | T65 native wrappers/backend/frontend/compiler/macro dispatch, repeated opens/refreshes, release-only sends, other-ring/UV/account/owner negative controls. T60 separately retains inactive candidate.27 fallback. |
| Immersion Required Items | T66 native measurement defect reproduction, additive correction and missing-correction negative control. |
| Saved Edit Mode tracking | T67 native saved capture, no tracking save/select, preservation of Party/manual edits. Initial installer adapter is a separate contract. |
| Automatic Circle update review | T70 actual bootstrap/event/setup/prompt integration: revision-17 login offer, no writes, accepted/manual state, duplicate events, decline/acceptance and combat/Edit Mode deferral. Macro-only automatic Apply and synchronous edit/deletion invalidation; old-revision negative control. |
| Native Circle binding and logs | T71 actual saved command mirror/ApplyRow/Resolve, C macro dispatch model, owned migration, native UI/modified priority, bounded/secret/false/session/GUID logging and negative controls. Formatting-only reuse preserves native bytes; real edits remain rejected, with strict-comparison negative control and secret/format evidence. T72 actual bootstrap/event persistence without diagnose. T70 preserves a final-LF macro during accepted revision19 legacy binding migration. |
| HUD/event performance | T73 unchanged/changed diagnostic copy counts, detached immediate sections and owner change; T74 immediate target/per-slot visuals, zero routine layout workers, bounded structural retries, pending combat/inactive behavior; T75 actual bootstrap domain merging/readiness/ownership, bag invalidation, deferred-review/reload retries and combat guards; T76 disabled clock overhead, fixed aggregates, public-only/backward-clock timing and callback return transparency. Candidate.34 behavior, missing-invalidation and removed-fallback negative controls must fail. Retain T24/T45/T49–T57/T61–T72 as applicable. Work counts and inclusive timings do not establish Retail per-tick CPU improvement. |
| Circle cancel-all | T68 native Layers/Input, template XML inheritance and modeled secure script provenance independent of hardware/pointer equality, candidate.31 forbidden RunMacroText reproduction, saved-macro/editor/slash dispatch, edges/modifiers/owners, explicit resource review/Keep/rollback, duplicate/full/secret failures, index changes and manual preservation, with macrotext and script-replacement negative controls. T69 independently retains original Forever first-success semantics; passing T68 is not exact parity. |
| Running-game companion update | Nine tooling tests qualify the explicit exception: unchanged schema/exact prior receipt, read-only preview, exclusive Forever scope, preserved WTF/vendors/backups, refusal of full install/dependencies/restore, concurrent drift, anchor identity and KeyboardInterrupt rollback. Game loading/reload timing remains unmodeled. |
| Executable tooling | Python simulations: scope/path/link/archive/hash checks, preview/backup/promotion/readback, interruption/rollback and preserved later edits. |
| Research source cache | Five tooling tests cover verified fetch/cache reuse, size/hash drift, preservation of drifted cached inputs, unsafe paths/URLs/identities, failed downloads and redirects. The explicit CI download stage reconstructs ignored inputs from the tracked Circle manifest before offline tests. |
| Pinned dependency inputs | Seven tooling tests reproduce a fresh checkout's absent unpacked inputs and verify reconstruction of exact pinned archives/files, source-root normalization, read-only reuse, missing-file recovery, rejection/preservation of drift or foreign files, invalid payloads and escaping destinations. No lock refresh or installed-addon change. |
| Maintained docs/skills | Checker and its missing-target/anchor/escape/manifest cases; manual semantic review. |

The runner's check IDs and build validator determine required suite membership;
do not maintain a competing fixed pass-count rule. Candidate.30's historical
67/39 receipts describe that inventory, not all future inventories.

## What passing establishes

Lua 5.1 syntax parsing catches language incompatibility. Fengari runs Lua 5.3
semantics with narrowly scoped compatibility adapters. Pinned unmodified native
functions improve source realism, but the host still models C APIs, frame
behavior, taint/secret tagging, option parsing, input sampling and cursor timing.
Neither mocked hardware nor the actual restricted compiler proves the complete
Retail engine authority boundary.

Regression checks should execute the actual relevant implementation and reject
the old defect. White getters, shown buttons, matching attributes or a large case
count alone do not prove composed pixels or effective native input dispatch.
Loaded/tested code may be disabled by current policy: test coverage is not feature
activation. See [architecture](ARCHITECTURE.md).

Pure helper tests for ModePolicy, Store hydration and UI Ownership do not establish
that the current bootstrap calls those helpers. Actual main hydration, binding
banks, native Layers and recovery startup need their own integration paths.
Likewise ordinary tap fixtures cannot prove every pre-artwork stick/sticky ping
release is empty, and generic ring-removal tests do not disable learned-form
augmentation. The [code reconciliation](reference/CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md)
records these distinctions. Documentation-only semantic changes use source review,
navigation checks and source-inventory verification; unchanged runtime/tooling
reports need not be rerun merely to update prose.

## Retail acceptance

User hardware/rendering/persistence acceptance is separate from source and
installation verification. Record exact candidate, class/spec/context, steps,
observed result and limitations. Do not mark untouched cases passed from a broad
confirmation. Use [current cumulative cases](NEXT-DEPLOYMENT-CHECKLIST.md) and
[historical manual cases](MANUAL-TEST-CASES.md); read historical dates/statuses.

The temporary main-command probe is retained in
[analysis evidence](../evidence/test-results/temporary-main-bank-analysis-2026-10-11.json).
T61 uses action-slot main-face fixtures and does not alone establish Jump/Interact
target selection. The quest's live effective binding/object state remains unknown.

Update this map when suite responsibilities or proof limits change. Preserve
negative controls and fixtures instead of weakening tests to produce green results.
