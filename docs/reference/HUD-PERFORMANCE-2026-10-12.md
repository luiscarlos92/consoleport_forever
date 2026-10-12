# HUD performance investigation — October 12, 2026

Status: maintained
Reviewed: 2026-10-12
Evidence: [operation comparison](../../evidence/hud-performance/operations.json),
[research identities](../../evidence/hud-performance/research.json),
[baseline gates](../../evidence/test-results/hud-performance-baseline-runtime.json),
[final qualification](../../evidence/test-results/candidate35-hud-qualification.json),
[source](../../addon/ConsolePort_Forever/Skin.lua).

## Scope and evidence

The user requested an evidence-based repair of gameplay CPU spikes while
preserving every implemented feature, appearance, secure/native owner, manual
edit and time-critical input/visual update. Candidate.34 is the baseline;
candidate.35 retains StoreSchema 3 and configuration revision20. No upstream,
immutable reference, fixture, inactive ping fallback or TOC load order changes.
All nine official stable Retail dependency identities were freshly checked and
matched the lock; no package was refreshed or selected for delivery.

The supplied Numy AddonProfiler 1.4.37 Active-mode one-minute capture reports
364.155 ms peak, 1.508 ms average, 3,983.829 ms total, 37.21% of addon processing
and 6.64% of application time. Threshold counts are 91/81/50/11/10/0 above
1/5/10/50/100/500 ms. These are user-supplied aggregate measurements, not a new
capture or a function-level attribution. Other addons also have substantial
spikes. Secondary Passive/Performance windows and death context are not a
controlled before/after benchmark. The capture's loaded Forever candidate is
not recorded; candidate.34 is the inspected code baseline, not an asserted
identity for that live measurement.

Inspected [Numy's exact version](https://github.com/NumyAddon/AddonProfiler/blob/fc979feb52cffc1a2f19842d5c1b885069a5f186/AddonProfiler.lua)
stores per-tick LastTime samples in Active mode, filters history buckets, sums
samples and divides by the number of ticks. Threshold counts overlap; they are
not disjoint event counts. Spike Sum assigns the largest exceeded threshold to
each tick, so these counts produce 1,605 ms; it is not the exact sum of measured
spike durations. Performance mode omits sample history, while Passive mode uses
engine metrics. Keep mode/window/scenario consistent. The
[Blizzard-authored generated API](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnProfilerDocumentation.lua)
documents aggregate metrics in milliseconds; neither this mirror nor mocks
establish the user's live engine implementation.

## Confirmed avoidable work and corrective changes

| Priority | Files/functions | Reproduction and fix |
| --- | --- | --- |
| 1 | Diagnostics.lua: SetFeature/Persist; Circle.lua: Record; Skin.lua: SnapshotFaceVisuals; Targeting/Ping.lua: Observe | Every status update copied all feature/entry/visual/ping/Circle histories. A populated 32-button/80-row fixture copied 24,800 tables for 100 identical statuses. Identical public statuses now do no copy; changed features copy one detached row. Observation/log writers persist only their changed section immediately. New record/version/revision owners get a full snapshot. Existing Circle sessions and automatic logging remain. |
| 2 | Skin.lua: OnEvent, RequestSkinRefresh, RefreshFaceAvailability | Twenty same-frame usability events queued 21 callbacks and eventually performed two full skin/layout passes. Usability/target/group/slot notifications now update existing cosmetics in the event turn, without reanchoring. A public positive slot narrows queries to matching face buttons; zero/nil/opaque notices refresh all. Native local/art/size hooks still repair the affected surface. Structural bursts retain one immediate worker and one readiness retry. Pending/failed skin setup and combat-end still retry. |
| 3 | ConsolePort_Forever.lua: event callback, Refresh, RefreshEventWork, RefreshContextPresentation | Action-slot, cursor and bag batches each rebuilt store/adapters/coordinator, captured saved layouts/bindings, reconciled rings and rebuilt mode/UI setup. After successful readiness, slot/page notifications reconcile modes; cursor/lock/merchant notifications reconcile focus/context presentation; bags reconcile rings plus contexts; cinematic changes reconcile eligibility plus contexts. Full initialization wins mixed batches, remains the default for readiness/bindings/spells/spec/layout/recovery and is mandatory before readiness or outside native recovery. |
| 4 | Runtime.lua: Later; HUDPresentation.lua: MirrorBank | Visibility notifications could accumulate equivalent zero-delay callbacks. They now coalesce. Repeated structural skin passes replaced identical mirror OnUpdate closures; a follower now installs its callback once, keeps immediate alpha synchronization on rebinding and retains continuous native fades. |

These are demonstrated unnecessary operations. **They do not establish which
function produced the reported 364 ms tick, or that every gameplay freeze is
fixed.** Native button dispatch, cooldown animations, charge policy, restricted
snippets, secure frame setup guards and per-frame fade/ping timing remain.
No dynamic/secret action state is cached or compared to manufacture public data.

## Recurring work and lifecycle audit

| Location | Frequency/activation | Finding |
| --- | --- | --- |
| HUDPresentation.MirrorBank | Each rendered frame for shown peer trigger anchors/class badge | One native-alpha read/write; needed for continuous easing. Hidden frames receive no engine OnUpdate. One callback per follower; bank followers use weak keys and current-owner checks. |
| Targeting/Ping.Create monitor | Frames only during a held native account-ring gesture | Hold artwork and device-loss cosmetics; hidden on end. One monitor per adapter, no public timer authority for protected dispatch. Existing native ownership/repetition gates retained. |
| UI/Scroll.Create | Per-frame scroll/map repeat when custom contexts are enabled | Creation is idempotent; current native recovery leaves this custom path dormant. It must not be removed merely because dormant. |
| Skin request/retry | Zero-delay setup plus one one-second readiness retry per structural burst | Previously every gameplay event added a retry. Now bounded; routine ready visual events schedule none. Combat setup sets pending and resumes after combat. |
| Main event queue | Zero-delay, at most one worker per batch | Existing coalescing retained; work domains merge and full readiness/recovery takes precedence. No queue of individual events or protected-action delay. |
| Runtime visibility, Edit Mode close, hidden-access close | Zero-delay deferred public setup/capture | Visibility coalesced; EditMode/hidden-access callbacks remain ownership/guarded. Full hidden access is dormant under recovery. |
| TemporaryRouting/native mode callbacks and ring OnHide | Zero-delay native layout/binding/environment or wheel-close reconciliation | Existing per-owner registration guards; retained setup semantics. Individual equivalent mode callbacks can still repeat work and are a profiling hypothesis. |
| ImmersionProgress.Queue | Two next-frame callbacks after native Required Items measurement | Serial/quest/dialog/ownership guards reject stale results. Several requests can leave no-op callbacks pending; existing native correction retained, not arbitrarily throttled. |
| Prompt deferred review | Next-frame review progression | User-driven, not gameplay polling; unchanged. |
| Native action-button hooks | Native local/art/size, icon tint, cooldown swipe and late Show | Per-button installation/region ownership guards prevent duplicate hooks. Reuses frames/masks/regions; preserves native feedback. Button art repair can still repeat geometry for one button and remains a timing hypothesis. |

There are no active Forever NewTicker/NewTimer workers. Native Blizzard/CP
animations, range polling and cooldown mechanisms belong to their native owners.
Forever's hooks can incur work attributed to Forever across those call chains.
Routine events no longer enumerate/reposition all HUD decorations; necessary
structural changes still do. No speculative global frame/texture/API cache was
introduced. Configuration and native unit/action values retain existing guards.

## Reproducible before/after comparison

Measurements execute actual product Lua and pinned native presentation/bootstrap
functions with modeled engine setters. They count work, not elapsed Retail CPU.

| Controlled fixture | Candidate.34 | Candidate.35 |
| --- | ---: | ---: |
| 100 identical diagnostic statuses: tables copied | 24,800 | 0 |
| 20 usability notices: queued callbacks | 21 | 0 |
| Same burst: full skin / layout passes | 2 / 2 | 0 / 0 |
| Same burst: immediate visual refreshes | 0 (two deferred refreshes) | 20 |
| 20 action-slot notices: full setup / ring passes | 1 / 1 | 0 / 0; one mode reconciliation retained |
| 20 cursor notices: full setup / mode / ring passes | 1 / 1 / 1 | 0 / 0 / 0; context presentation retained |
| 20 bag notices: full setup / mode / ring passes | 1 / 1 / 1 | 0 / 0 / 1; ring invalidation retained |

No after-change in-game average, peak or threshold count exists yet. The supplied
1.508/364.155 ms baseline remains the only live metric. Expected lower processing
and allocation pressure follows from eliminated work; a percentage CPU reduction
or elimination of >50/>100 ms spikes is not inferred from these counters.

## Optional timing and scenario validation

`/cpf perf on` enables ten fixed inclusive callback scopes. `/cpf perf reset`
starts a fresh scenario; `/cpf perf report` prints and saves bounded aggregates
on the current GUID record; `/cpf perf off` disables and prints/saves the result.
It is off after login/reload, has no workers/history rows or console output while
collecting, and records only counts/public clock durations and >10/50/100 ms
callback counts. Disabled calls do not query the clock. Nested inclusive totals
overlap and cannot be added into a per-tick addon total. Failed callbacks retain
normal error propagation and do not yield completed timing samples. Other code
resetting the shared clock can invalidate timings; backward samples are rejected.
Profiler overhead itself must
be considered; do not globally enable legacy scriptProfile.

Use Numy's Active mode and the same one-minute window/client/addons/character/
settings/FPS for baseline and after-change scenarios. Reset once per scenario,
record actions/repetitions, average/peak/total/threshold counts, addon versions,
combat/death context and any taint/visual/input symptoms. Pair aggregate capture
with optional callback evidence to select the next repair rather than guessing.

| Scenario | Trace / observation needed in Retail |
| --- | --- |
| Idle; movement | Visible follower alpha and native polling; verify no unintended full refresh loop. |
| Mount/dismount; contextual banks | Native page/bonus/family events -> scoped mode reconciliation; native dispatch/ordinary-bank preservation and peak counts. |
| Enter/leave combat | Immediate native feedback; setup deferral and complete combat-end retry; no taint. |
| Repeated casts | Native usability/cooldown/art callbacks and automatic player Circle observations; callback vs aggregate peak, full visual fidelity. |
| Targets | Immediate TURNORACTION icon, native range feedback, no structural refresh. |
| Kill/loot | Cast observations, item/lock/cursor and bag invalidation; native quest/utility updates, ring/manual data preservation. |
| Accept/complete quests | Native CP auto-ring updates and Immersion hooks; bag/slot/readiness bursts. Forever has no direct QUEST_TURNED_IN listener. |
| L2/R2 changes | Native secure bank selection, native button hooks and continuous hint opacity; no added edge latency. |
| Action bank/form/stance | Native page events, structural learned-form/spell changes and class-badge refresh; icon/class chord correctness. |
| Vehicles/special actions | Scoped modes, native seat/overflow/ground routes; combat entry/return and held release. |
| Death/resurrection | Native usability and regen/world events; preserve death context when comparing supplied capture. No direct Forever death listener. |
| Login/reload | Full guarded initialization, readiness retries, GUID data, configuration review and automatic Circle evidence. |

These observations are user-owned: this task does not authorize game input.
No client was launched/operated and no direct live WTF writes occurred. Existing
fixtures qualify state/visual/input contracts offline; they cannot certify
rendered pixels, engine timing, taint or persisted engine authority.

## Regression protection and remaining risks

The baseline passed 72 runtime/source checks and 66 tooling tests. The complete
final gate passed 76 runtime/source checks and 66 tooling tests, with current
product/tool/test inventories and 38 maintained documentation files checked.
New T73–T76
cover detached immediate incremental diagnostics, unchanged-state copy counts,
per-slot and immediate target visuals, bounded structural retries, inactive and
combat setup, merged domains, readiness fallback, bag invalidation, and optional
profiling bounds/return transparency/public-value guards. Negative controls
restore candidate.34 copying/reconstruction/full-dispatch behavior and remove
bag invalidation; each must fail for its intended defect. Existing composed
Masque/native face, pressed/cooldown/resource/geometry, all-class routing, Circle,
ground placement, saved layout and ownership gates remain mandatory.
T71's retained missing-persistence negative control now removes the actual
incremental Circle writer; its automatic native-call assertion is unchanged.
T75 additionally rejects stranded deferred reviews after an unsaved Edit Mode
close and skipped pending reload verification; both force complete setup on the
next event. Removed-fallback controls must fail those assertions.
T74 also rejects repeated routine workers while geometry is pending in combat;
cosmetics remain immediate and structural work waits for combat-end. Structural
combat notifications mark pending directly instead of queuing doomed setup.

Remaining hypotheses include necessary full refreshes on SPELLS_CHANGED, repeated
mode setup/ground enumeration, individual native art reconstruction, passive
debugstack observations, Circle's two bounded history mirrors and Immersion
stale deferred requests. Do not patch secure setup/cache invalidation or remove
automatic evidence without timings and functional reproductions. External addon
spikes, profiler overhead and the death-state capture also remain unresolved.
K04 stays open for Retail performance acceptance; no severe live spike is declared
eliminated merely because offline operation invariants pass.

Future rules live in [development](../DEVELOPMENT.md#addon-performance) and
[testing](../TESTING.md), rather than duplicate independent workflows. Controller
specification, state contracts and dependency/native compatibility assumptions
are unchanged; architecture/presentation/diagnostic documentation describes the
new refresh implementation. Release records separately own installation and
current source validation.
