# Implementation architecture

Status: maintained
Reviewed: 2026-10-16
Evidence: [TOC](../addon/ConsolePort_Forever/ConsolePort_Forever.toc),
[bootstrap](../addon/ConsolePort_Forever/ConsolePort_Forever.lua),
[runtime setup](../addon/ConsolePort_Forever/RuntimeSetup.lua).

## Loading and initialization

The TOC requires ConsolePort and ConsolePort_Bar, declares optional integrations
and loads 61 Lua files in order. There is no current Forever XML entry point.
Modules share the addon namespace supplied through `...`. `Core`, storage,
planning, transactions and capability modules precede policies and adapters;
the main addon file loads last. `Bindings.lua`, `Layout.lua` and `Profile.lua`
are retained legacy files, unloaded and omitted by the package builder.

`PLAYER_LOGIN` and deferred refresh events reach the main addon. `Refresh`
initializes GUID-owned state, probes native readiness, constructs adapters,
checks interrupted transactions, verifies prior reloads and refreshes the active
features. `ADDON_LOADED` supports late readiness. Combat/Edit Mode postpone
reviewed configuration writes through `CanWrite`; protected click snippets
separately retain their qualified secure execution. Saved bookkeeping and each
feature's public refresh have their own guards; there is no universal prohibition
on all saved-data changes during combat/Edit Mode. `/cpf` exposes configuration
review, status, diagnosis and guarded restore/recovery paths, not a code updater.

Refresh ordering matters. Passive observers and ping are
initialized before coordinator recovery checks. An interrupted binding-bank
selection or configuration journal stops subsequent normal refresh work.
Otherwise reload verification precedes Immersion correction, saved-layout
tracking, passive action recovery, binding hydration, ring projection, class
migration, modes/UI and optional setup review. `ADDON_LOADED` and state changes
retry readiness; ordinary events coalesce through a zero-delay callback and
pause while a review is active. Logout captures owned binding/ring edits.

Candidate.35 retains that complete initialization for readiness, bindings,
spells/specs, layouts and recovery. After a successful full refresh in native
recovery, event batches merge modes (slot/page), contexts (cursor/locks/merchant),
bags (rings plus contexts), or cinematic (eligibility plus contexts); full work
takes precedence. Incomplete readiness, a deferred review or pending reload
verification falls back to full setup. Native
button feedback is immediate; these zero-delay batches reconcile public setup
with existing protected-write guards. Skin separates immediate cosmetic events
from structural geometry/readiness work. Diagnostic persistence copies only the
changed detached section/feature, with a full snapshot for new record/version/
revision owners. Optional fixed-scope inclusive timing is off by default.
[Evidence and limits](reference/HUD-PERFORMANCE-2026-10-12.md).

Candidate.40 adds FollowerDungeon immediately before the existing utility runtime
initializer. Qualified shared-ring startup installs its narrow mapping/presentation
adapter once. Only follower spell 426756 in the default ring receives compiled
localized-name dispatch; numeric source/LAB state stay native. Coalesced cosmetics
reconcile owned follower-child suppression and zone artwork. No public casting,
pooled-frame proxy, input replacement or new persistence is introduced. See the
[candidate.40 runtime](reference/FOLLOWER-DUNGEON-RUNTIME-2026-10-16.md).

## Configuration and ownership

Candidate.39 adds an independent UtilityFlag bootstrap after Core and public
utility model/native adapter/integration after Rings. The shared master is
account owned; the derived default remains a native ring. Personal class rings,
Ping, input and dispatch retain ownership. Native automatic rebuilds defer while
held/blocked; qualified explicit editing stays immediate. Logout saves a native
seed without protected changes; disabled reload installs no utility work.
Schema3/revision20 remain. [Ownership decision](decisions/0008-shared-utility-ring.md),
[runtime qualification](reference/SHARED-UTILITY-RING-RUNTIME-2026-10-14.md).

| Layer | Contract |
| --- | --- |
| [Core](../addon/ConsolePort_Forever/Core.lua) | Copy/equality, serializable NIL and field operations. |
| [Store](../addon/ConsolePort_Forever/Store.lua) | Schema 3 account store, GUID character records and retained ambiguous legacy data. |
| [Plan](../addon/ConsolePort_Forever/Plan.lua) | Compare proposals to current/managed values and expose conflicts. |
| [Transactions](../addon/ConsolePort_Forever/Transactions.lua) | Before-state journals, guarded apply/readback, commit and drift-aware recovery. |
| [Coordinator](../addon/ConsolePort_Forever/Coordinator.lua) / Prompt | Build review and restore plans; apply accepted resolutions. |
| [Adapters](../addon/ConsolePort_Forever/Adapters) | Native read/write/capture contracts for owned fields; preserve foreign fields and table identity. |

`ConsolePortForeverDB` owns shared geometry/policies, shared base face commands,
GUID-specific action bindings/rings, managed fields, transactions and backups.
The TOC retains a per-character saved-variable declaration, but shared physical
files cannot prove character ownership; migration retains ambiguous legacy data.
`lastProjectedGUID` and ring projection identity prevent capturing the previous
character's view into the current archive. Account/native binding-bank views
must not overwrite GUID character archives.

Reviewed in-game configuration may use native save APIs. That is separate from
the disk installer, which must not modify live WTF. Store schema, configuration
revision and code candidate version are separate identities.

Shared state retains integration/runtime policies, managed profile/layout
ownership and the known saved-layout
default. Character records retain acceptance flags, field baselines, kept review
decisions, transaction IDs, reload work and diagnostic/layout
snapshots. Transactions and independent before-state backups remain in the
account store. Schema migration retains legacy account/ambiguous character
material; an unsupported future schema is rejected rather than downgraded.

`IsCharacterInstalled` means `appliedRevision > 0`. It does not mean every offered
policy was accepted or every feature is enabled. `bindingAccepted`,
`ringAccepted`, shared policy fields, exact native probes and per-feature
ownership checks provide additional independent gates. See the
[configuration contract](reference/RUNTIME-CONFIGURATION.md).

## Review, apply and recovery

The planner distinguishes convergence, unchanged owned fields, competing manual
edits and new ownership. A remembered Keep decision applies only to its matching
reviewed revision/proposal/current value. Conflicts need Use Proposed or Keep;
unresolved conflicts cannot be applied. Unreadable optional fields are deferred.
Before applying, the coordinator re-reads **every reviewed field**, including
kept/no-op fields; any drift invalidates that review.

| Journal state | Meaning |
| --- | --- |
| `prepared` / `stale` | Durable before-state exists; apply has not succeeded or its baseline changed. |
| `applying` | Each attempted step is recorded before writing; immediate and final readback are required. |
| `verified` / `committed` | Readback passed; commit updates managed ownership and character revision. |
| `rolled-back` | Reverse recovery restored attempted owned writes. |
| `recovery-required` | Recovery could not safely finish; newer/foreign edits are retained. |
| `restored` | Reviewed restore verified its accepted reverse operations; character install revision is reset and reload verification retained. |

Recovery restores a step only when its current value still matches the attempted
write, or recognizes that the original value is already restored. Native binding
adapters additionally compensate granular writes and selected-bank changes.
Reviewed restore runs in reverse order and exposes newer edits as conflicts;
it is not an unconditional whole-profile reset. Reload verification compares the
committed/restored journal after a later session and keeps pending work on failure.

## Runtime responsibility map

| Modules | Responsibility and activation boundary |
| --- | --- |
| BindingPolicy, NativeBindings, BindingState, BindingBanks | Shared/character masks, native selected-bank capture, reviewed projection and bank recovery. |
| SecureModes, TemporaryRouting, TemporaryAccess | Native secure button extensions. Full SecureModes installer is disabled by native recovery; TemporaryRouting reuses qualified snippets independently. |
| Targeting/Ping | Actual ConsolePort account ring, native secure release dispatch, cosmetic hold visibility and owner/collision guards. |
| Circle | Candidate.34 offers native MACRO binding for empty or managed legacy Base PAD2 through normal review; reuses the account resource with identical commands, allowing CRLF/final LF normalization without writing native macro bytes. Legacy inherited helper remains for Keep. Automatic bounded observations and macro format evidence persist across four GUID-owned sessions; no observer selects protected actions. No macrotext fallback or automatic macro repair. No custom layer/takeover or hydration rebinding. Exact stock first-success remains gated. |
| ClassActions, Rings/Discovery, Rings/Selectors, Adapters/Rings | Class chord/access repair, learned read-only discovery, GUID projection and privately prepared selectors. Preparation is not activation. |
| HUDPresentation, Skin | Original art, round state surfaces, glyphs, feedback, geometry and late native refresh repair. |
| Runtime, ClassActions, UI/HiddenAccess | Owned sidebar/bag/micro visibility and separately qualified StanceBar suppression remain possible. Full hidden-control replacement is suspended; native power UI retained. |
| UI/InputBridge, Contexts; UI/Ownership | Current native combat-claim relinquishment and dormant custom UI routes. Ownership is a pure helper model, not the live context coordinator. |
| UI/Windows, Scroll, Map, ItemHints, Adapters/BetterBags | Tested custom UI routes behind the disabled context path; presence in the TOC does not make them active. |
| UI/FocusVisuals, Proof, Diagnostics | Reviewed transient-feedback suppression while preserving icons; bounded diagnostics and user-readable source/readiness status. |
| UI/ImmersionProgress | Additive deferred native Required Items measurement correction under Forever policy and exact integration guards. |
| UI/EditModeReference, SavedEditModeReference, Adapters/EditMode, PartyLayout | Saved reference capture; native saved selections remain authoritative; initial managed-copy setup is distinct from later capture. |
| Adapters/DynamicCam, LiteMount, Integrations, FlatConfig | Qualified managed copies/settings/icons, with native behavior and foreign/manual data preserved. |
| ActionRecovery | Passive bounded action/loadout diagnostics; compatibility refresh disables automatic restoration. |
| Cinematic | Eligibility observation; exact held skip and gameplay cancellation remain gated. |

## Native execution and refresh

Native ConsolePort Manager/Layers own binding priority and dispatch. Ordinary
commands, stored action slots and rendered buttons are distinct. Temporary
routing qualifies native family/page evidence and overlays L2+R2; mount or form
appearance alone is not a takeover signal. Unchanged refreshes preserve active
gestures and editing caches. Native drag/drop remains authoritative.

`NATIVE_INPUT_RECOVERY=true` routes `RefreshModes` through temporary routing and
disables the full custom mode installer.
`RefreshUI` disables custom context acquisition, while Contexts can retain the
native combat-claim relinquishment bridge. See [states](STATE_MATRIX.md).

| Feature | Current activation prerequisites |
| --- | --- |
| Binding hydration | Accepted character bindings, writable state, ready native adapters and own GUID capture/projection rules. Account-selected views are not archived as character edits. |
| Personal rings/class refresh | Accepted rings, exact native ring readiness, closed wheel, writable state and owned projection. Class augmentation may append missing learned forms. |
| Temporary routing | Installed character and writable refresh/native readiness. In recovery it does **not** require `modesEnabled`. |
| Account ping | Installed character, audited native ring/layers and gamepad keys actually bound to `TOGGLEPINGLISTENER`; refresh defers in combat. No separate ping policy flag. |
| Circle cancel-all | Exact account CPF Circle macro plus accepted/current native MACRO binding. Native engine owns execution; retained legacy click alone uses the helper. Macro creation and binding changes require Use Proposed; existing binding is not automatically installed/restored by frame refresh. Native UI/ring Layers priority remains. |
| Skin/HUD | Installed character and native button/device readiness; protected geometry work defers while existing cosmetic surfaces can refresh. |
| Focus feedback | Installed character plus `focusVisuals`, qualified ordinary interface-cursor ownership; released in combat. |
| Sidebar/bag/micro visibility | Installed character plus `blizzardVisibility` and native identity/parent guards; released for Edit Mode. |
| Native class row suppression | Independent ClassActions path: supported class, accepted/complete learned ring and matching actual opener; released for Edit Mode. |
| Immersion correction | Installed character, exact loaded 1.4.61 contract, owned enabled integration policy, eligible dialog/preferences and ordinary writable state. |
| Saved Edit Mode tracking | Installed character, ready native capture, outside combat/Edit Mode and not busy; capture does not save/select. |
| Custom UI/modes/hidden access | Recovery suppresses execution even if accepted saved policy fields are true. Individual window/bag/map flags do not bypass this parent gate. |

Ground placement and its Targeting panel are retired. Old saved preferences and
observations are ignored without deleting historical data or changing schema.

Only the main runtime paths above determine activation. `ModePolicy.Resolve`,
`Store.Hydrate`/`CaptureOwnedEdits` and `UI/Ownership.New` are retained pure helper
APIs exercised separately by tests; the current bootstrap does not call them.
Actual hydration uses `HydrateController` and the native adapters; actual UI
claims use InputBridge generations and native Layers.

Ping restricted dispatch uses native click/macro machinery. Its hold timer
changes artwork only; it cannot decide protected action permission. Immersion's
post-hooks defer native offset calculation and guard dialog identity, ownership,
preferences, combat/Edit Mode and close transitions. Unknown contracts fail
closed rather than rewriting upstream methods or widening version guards.

Two narrow journaled migrations also run without replaying full setup review:
the authorized class-access migration/one-time revision-17 repair, and the first
eligible Immersion progress policy initialization. They preserve their own
acceptance/ownership guards and backups. Restored/disabled Immersion policy is
not automatically re-enabled. Their detailed scope is in the
[configuration contract](reference/RUNTIME-CONFIGURATION.md).

Skin/HUD composition, owned parent restoration and the implemented but dormant
UI routes are described in [presentation and UI](reference/PRESENTATION-AND-UI.md).

## Change boundaries

Candidate.38 additionally installs native `UpdateAction` posthooks once
per existing stock button after character-store initialization outside combat.
Installation requires engine `taintLog` to be known off; the addon never changes it.
Only matching native methods qualify; existing foreign methods are skipped.
At most 102 buttons are considered, with no polling worker. Security labels are
inspected after completed calls; initial taint and later observed transitions are
separate, with at most 16 records/four initial records and 3072-character stacks.
Full trace stops further inspections. Blocked events retain at most 16 first
stack attempts separately from their rolling aggregate rows, so eviction neither
loses the first callers nor restarts stack collection. They share the stack-length
bound. Data remain detached and GUID-scoped, and no error handler/CVar, action
value, native script or native dispatch is changed. This is collection for K05,
not a taint repair; aborted calls and earlier writers may evade the posthook.

Candidate.37 adds read-only blocked-event evidence for all addon attributions,
bounded to16 aggregate rows in the current GUID's runtime diagnostic snapshot.
Native field security labels are queried without reading protected values or
replacing native handlers. ActionRecovery passive reads now reject opaque and
failed queries before forwarding or persistence. No schema, route, configuration
review or action-slot ownership changes. [Combat error audit](reference/COMBAT-ERROR-AUDIT-2026-10-13.md).

Document architecture changes here and rationale in [decisions](decisions/README.md).
Controller behavior belongs in [CONTROLLER_SPEC](CONTROLLER_SPEC.md); approved
intent belongs in [requirements](REQUIREMENTS.md). Historical designs and
unactivated policies must not be described as current implementation.
