# Code/document reconciliation — October 11, 2026

Status: maintained
Reviewed: 2026-10-11
Evidence: [source/hash receipt](../../evidence/organization/2026-10-11/code-documentation-reconciliation.json),
[TOC](../../addon/ConsolePort_Forever/ConsolePort_Forever.toc),
[preserved older plan](../archive/ai-native-2026-10-11/MASTER-PLAN.pre-restructure.md),
[preserved older status](../archive/ai-native-2026-10-11/IMPLEMENTATION-STATUS.pre-restructure.md).

The user requested a deeper documentation pass driven by implementation, including
behavior old documents never captured. This review follows loaded modules,
bootstrap callers, policy/acceptance flags, native ownership and event order.
It reconciles both older plans/checkpoints and overbroad summaries introduced in
the initial restructure. It does not infer new intent or repair code to fit prose.

## Findings and corrections

| ID | Older or incomplete description | Actual source contract and updated guidance |
| --- | --- | --- |
| D01 | A loaded/tested module or accepted flag implies enabled functionality. | Bootstrap recovery disables full modes/custom context/full hidden access even when their saved flags are true. TemporaryRouting instead uses installed-character readiness independently of `modesEnabled`. [RefreshModes/RefreshUI](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua); [architecture gates](../ARCHITECTURE.md#native-execution-and-refresh). |
| D02 | Every write/refresh waits outside combat and Edit Mode. | Main reviewed/protected writes use `CanWrite`; ping refresh has its own combat guard, and saved bookkeeping/diagnostics have independent rules. [Ping.Refresh](../../addon/ConsolePort_Forever/Targeting/Ping.lua); [state matrix](../STATE_MATRIX.md). |
| D03 | Generic helper architecture coordinates all current live hydration/ownership. | ModePolicy.Resolve, Store.Hydrate/CaptureOwnedEdits and UI Ownership.New are pure helpers without current bootstrap call sites. Actual paths use HydrateController, native ring adapters and InputBridge/Layers. [bootstrap](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua); [architecture](../ARCHITECTURE.md). |
| D04 | Setup installs all original layout/CVar/profile defaults. | RuntimeSetup starts from captured current fields, scoped archives/fallbacks and readiness. Only two trigger CVars are offered; legacy unloaded files are not installers. [RuntimeSetup.Fields](../../addon/ConsolePort_Forever/RuntimeSetup.lua); [setup contract](RUNTIME-CONFIGURATION.md#what-setup-actually-offers). |
| D05 | Configuration apply has generic rollback with no further detail. | Coordinator revalidates every reviewed field including no-ops/Keep; journals record attempted steps before writing, read back immediately/finally and recover only still-owned values. Newer edits survive as conflicts/recovery-required. [Coordinator.Accept](../../addon/ConsolePort_Forever/Coordinator.lua), [Transactions](../../addon/ConsolePort_Forever/Transactions.lua); [architecture](../ARCHITECTURE.md#review-apply-and-recovery). |
| D06 | Binding-bank inspection is harmless/read-only or both saved banks always stay unchanged. | Native inactive-bank inspection can discard unsaved view; explicit consent, durable selection intent and separate transient-view review are required. Accepted target projection copies the outgoing keyboard view and may clear target-only keys. [BindingBanks](../../addon/ConsolePort_Forever/Adapters/BindingBanks.lua), [BindingState](../../addon/ConsolePort_Forever/Adapters/BindingState.lua); [bank contract](RUNTIME-CONFIGURATION.md#binding-banks-and-guid-archives). |
| D07 | All manual ring removals remain absent, so removed restoration means no automatic class repair. | Generic manual capture preserves order/duplicates/metadata/deletion and dormant entries; separate learned-form augmentation appends missing forms, and narrow accepted class migration/repair remains journaled. Action-slot pickup/place restoration stays removed. [Rings](../../addon/ConsolePort_Forever/Adapters/Rings.lua), [Class.RingProposal/Migrate](../../addon/ConsolePort_Forever/ClassActions.lua); [decision scope](../decisions/0003-character-state-and-manual-edits.md). |
| D08 | The three-class Supported guard controls every class proposal/chord. | Supported gates revision-17 repair and native row suppression. Generic chord/proposal helpers have distinct prerequisites and a right-side fallback for other classes. Later selector previews remain inactive. [ClassActions](../../addon/ConsolePort_Forever/ClassActions.lua); [controller class scope](../CONTROLLER_SPEC.md#class-and-utility-access). |
| D09 | R3 is the only hardcoded ping route; all taps must use aimed fallback. | Qualified gamepad keys bound to TOGGLEPINGLISTENER are claimed; native selection is armed on down, so deflected/sticky release can select before artwork. Only empty/neutral release falls back. No down dispatch. [Ping.Refresh/key collection and secure snippets](../../addon/ConsolePort_Forever/Targeting/Ping.lua); [ping contract](../CONTROLLER_SPEC.md#ping-gesture). |
| D10 | Ping hold timing controls protected send or refresh can rebuild each gesture. | 0.15-second hold is artwork only; stable declarations preserve active gestures. Modifier/combat/owner/device changes cancel; brief missing input has cosmetic tolerance. Native release/macro dispatch remains independent. [Ping artwork/owner lifecycle](../../addon/ConsolePort_Forever/Targeting/Ping.lua); [controller](../CONTROLLER_SPEC.md). |
| D11 | Eight visible temporary cells imply all native actions/overflow are controller accessible. | Declared capacity matters: default vehicle/override six can leave cells 7–8 empty. Slots 9–12/exit use eligible native mouse-accessible supplemental buttons without a new controller key/cursor takeover. Ordinary bonus appearance is not overflow evidence. [TemporaryRouting](../../addon/ConsolePort_Forever/TemporaryRouting.lua), [TemporaryAccess](../../addon/ConsolePort_Forever/TemporaryAccess.lua); [controller](../CONTROLLER_SPEC.md#priority-and-state). |
| D12 | Focus mode suppresses gameplay icons, as the setup label still says. | Actual FocusVisuals preserves icons/cooldowns, suppresses seven transient regions and restores later external alpha requests. Source label remains stale; no code change in this pass. [FocusVisuals](../../addon/ConsolePort_Forever/UI/FocusVisuals.lua), [RuntimeSetup](../../addon/ConsolePort_Forever/RuntimeSetup.lua); [known discrepancy](../KNOWN_ISSUES.md#demonstrated-sourcedocument-differences). |
| D13 | Suspended hidden replacement means all native class/side UI stays visible. | Reviewed sidebar/bag/micro suppression and independent qualified StanceBar suppression remain active paths, with owned-parent/Edit Mode restoration. Native power UI is retained. [Runtime](../../addon/ConsolePort_Forever/Runtime.lua), [Class.UpdateNativeBar](../../addon/ConsolePort_Forever/ClassActions.lua); [presentation](PRESENTATION-AND-UI.md#focus-effects-and-hidden-native-frames). |
| D14 | Visual correctness can be summarized by white icon getters or replacing all surfaces. | Actual skin distinguishes faces/D-pad, empty/filled composition, native range/resource/secret sinks, charge/GCD/LoC feedback and late Masque recreation. HUD geometry is runtime guarded, not a saved preset rewrite. [Skin](../../addon/ConsolePort_Forever/Skin.lua), [HUDPresentation](../../addon/ConsolePort_Forever/HUDPresentation.lua); [visual contract](PRESENTATION-AND-UI.md#active-hud-and-native-feedback). |
| D15 | Targeting preferences depend on custom UI takeover, or Defaults/Revert restore prior history. | Historical panel behavior is superseded by explicit ground-placement retirement; its UI/model are removed and saved data remain inert. [Retirement](TARGETING-RETIREMENT-2026-10-12.md). |
| D16 | Optional integrations impose newly invented settings/couch camera situations. | Flat adapters preserve current allowed explicit typed values; DynamicCam clones the actual current profile/situations through guarded native lifecycle. No bulk upstream profile rewrite. [Integrations](../../addon/ConsolePort_Forever/Adapters/Integrations.lua), [DynamicCam](../../addon/ConsolePort_Forever/Adapters/DynamicCam.lua); [integration contract](RUNTIME-CONFIGURATION.md#integration-and-saved-layout-details). |
| D17 | Required Items repair needs replaying installer/settings or always re-enables itself. | Only a missing unowned policy initializes through a narrow journal. Exact eligible native dialog gets deferred measured offset; existing disable/restore and native preferences remain guarded. [ImmersionProgress](../../addon/ConsolePort_Forever/UI/ImmersionProgress.lua); [configuration](RUNTIME-CONFIGURATION.md#integration-and-saved-layout-details). |
| D18 | Saved default is always the active layout or packaged reference is applied automatically. | Tracker captures active per GUID and unique owned account default separately, including inactive default. Packaged reference may seed only absent stored default; tracking does not save/select. Party defaults only belong to new-copy review. [EditModeReference](../../addon/ConsolePort_Forever/UI/EditModeReference.lua), [EditMode adapter](../../addon/ConsolePort_Forever/Adapters/EditMode.lua); [layout decision](../decisions/0006-native-saved-layout-authority.md). |
| D19 | `/cpf update` updates code; old action-recovery toggle can enable restoration. | Install/update are review aliases. Restore/recover/selection/view paths differ; any action-recovery argument disables the removed writer. [slash handler](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua); [commands](RUNTIME-CONFIGURATION.md#commands-and-diagnostic-retention). |
| D20 | Passive ActionRecovery means no saved writes, or all evidence is bounded. | Passive hooks/snapshots save own diagnostic state without invoking action writes. Event/diagnostic rows are capped; transactions/history/loadout archives have different retention. Runtime “offline-verified/pending” strings are not live acceptance receipts. [ActionRecovery](../../addon/ConsolePort_Forever/ActionRecovery.lua), [Diagnostics](../../addon/ConsolePort_Forever/Diagnostics.lua), [Proof](../../addon/ConsolePort_Forever/UI/Proof.lua); [retention](RUNTIME-CONFIGURATION.md#commands-and-diagnostic-retention). |
| D21 | Tested popup/window/map/bag/selector/cinematic modules imply completed enabled parity. | Native recovery disables custom context parent gate; exact loot hold, additional selector gestures and held skip remain gated. Native guarded dormant routes are documented individually without claiming activation. [Contexts](../../addon/ConsolePort_Forever/UI/Contexts.lua), [BetterBags](../../addon/ConsolePort_Forever/Adapters/BetterBags.lua), [Selectors](../../addon/ConsolePort_Forever/Rings/Selectors.lua), [Cinematic](../../addon/ConsolePort_Forever/Cinematic.lua); [dormant routes](PRESENTATION-AND-UI.md#dormant-ui-implementation). |

## Historical records and unresolved scope

Older candidate designs, acceptance checklists and the original combined plan
remain dated evidence. Their immediate-down ping, emergency restoration,
pre-recovery UI or old pending-acceptance statements are not current behavior.
Exact archived bytes are preserved; current specifications and this correction
map provide the current reading. Scoped acceptance is recorded separately in
[current status](../IMPLEMENTATION-STATUS.md).

No new Retail acceptance is inferred from this audit. The original Paladin
action-loss writer and quest-object interaction cause remain unresolved. The
stale focus review label and runtime readiness wording are documented differences,
not silently fixed executable code. Further runtime changes need their own scope
and appropriate qualification.

## Verification boundary

The separate JSON receipt fingerprints the pre-pass product/doc state, lists
changed documents, locates source anchors and records the documentation check
plus unchanged product/executable-test inventories. The prior restructure
receipt remains a record of its earlier checkpoint, not a rewritten receipt for
this later prose. This pass changes no runtime, tools, tests, dependencies,
immutable evidence or production state; it does not package or deploy.
