# Runtime configuration, persistence and recovery

Status: maintained
Reviewed: 2026-10-12
Evidence: [bootstrap](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua),
[setup proposals](../../addon/ConsolePort_Forever/RuntimeSetup.lua),
[store](../../addon/ConsolePort_Forever/Store.lua),
[coordinator](../../addon/ConsolePort_Forever/Coordinator.lua).

This describes current source behavior. Configuration review inside WoW is
separate from checkout/package installation. [Architecture](../ARCHITECTURE.md)
owns lifecycle and activation; [requirements](../REQUIREMENTS.md) owns intent.

## What setup actually offers

Revision 19 offers direct native MACRO migration for previously accepted revision-18
characters, preserving the earlier automatic update review. Current acceptance/decline suppresses repeat prompts; older declines
do not accept a newer update. Combat/Edit Mode defers review. The popup itself
does not apply settings, and prior accepted feature scope stays active.

Setup captures current native state, builds sorted field proposals and defers
unavailable contracts. Use Proposed/Keep decisions and final confirmation precede
writes. It does not replay every field in the original reference or manufacture
settings for missing integrations.

Runtime journals/backups are recorded in SavedVariables tables, not flushed to
disk by Forever at each step. Cross-addon apply is compensating, not an engine
atomic transaction; a crash before the game persists data can lose recent saved
entries. Separately verified disk deployment/configuration backups have a
different scope and do not turn a runtime journal into immediate disk durability.

| Scope | Proposal and ownership contract |
| --- | --- |
| Circle evidence | Automatic native call, player spell/channel, modifier and binding observations plus public macro length/CRLF/final newline/matching-command evidence; unknown secret values, bounded four sessions/80 rows per GUID. WoW persists through reload/logout, without /cpf diagnose or direct file I/O. |
| Controller bindings | Shared base-face archive plus current GUID's personal archive, or qualified current/reference fallback; normalize the scoped mask and propose native Character selection. Preserve explicit empty values. |
| Circle cancel-all | Candidate.34 automatic login update review (revision20) or explicit review offers native MACRO binding for empty or owned legacy Base PAD2. The changed controller field requires explicit Use Proposed. A separate circleMacro state field reviews one account CPF Circle macro through native CreateMacro/readback/guarded deletion; identical commands allow CRLF/final LF comparison without editing native bytes. Duplicate/edited/full resources defer without overwrite. No auto recreation or RunMacroText fallback. Other nonempty/missing values, Keep and subsequent manual removals retain ownership; ordinary hydration never makes this proposal. |
| ConsolePort layout | Start from captured current layout. The qualified proposal removes legacy special vehicle visibility/opacity and the standalone override-page declaration; runtime temporary routing is separate. |
| Preset condition | Propose an empty `bindingPresetCondition`, disabling the old automatic preset condition. |
| Runtime policies | Offer modes, ground, focus, context/window/bag/map, sidebar visibility and hidden-access fields only where their probes allow. Saved true fields may remain dormant under native recovery. |
| Trigger CVars | Only reviewed `GamePadEmulateShift=PADLTRIGGER` and `GamePadEmulateCtrl=PADRTRIGGER`, with registered-native-CVar checks. This is not a bulk CVar import. |
| Mount icons | Native LiteMount button/icon fields through audited adapters; preserve explicit icons and avoid guessing LM_B2's default. No mount-rule rewrite. |
| Personal rings | Native validated, GUID-owned personal projection plus learned class augmentation; Shared account rings remain separate. A foreign projection requires review. |
| Edit Mode | Managed account copy of the active saved layout when needed; reuse an already owned copy without resetting manual systems. Party defaults apply only to a newly created copy. |
| Immersion / ExtraFade | Preserve existing publicly typed allowed settings as reviewable fields. Missing defaults, unknown fields and transient ExtraFade `UIParentAlpha` are excluded. |
| DynamicCam | Copy the actual current profile/settings/situations into an owned managed profile, then select through native lifecycle. No generated couch-camera preset. |

The original `Reference.lua` remains preset data. Unloaded `Bindings.lua`,
`Layout.lua` and `Profile.lua` are legacy inputs, not additional runtime installers.
The focus field's existing review label says “Suppress gameplay icons and
highlights”; [actual FocusVisuals](../../addon/ConsolePort_Forever/UI/FocusVisuals.lua)
preserves icons and suppresses seven transient feedback regions. That stale label
is a source/document discrepancy retained explicitly; this pass changes no code.

## Binding banks and GUID archives

[BindingPolicy](../../addon/ConsolePort_Forever/BindingPolicy.lua) separates only
unmodified PAD1–PAD4 as shared face commands. D-pad/modified chords and other
scoped personal commands are GUID-owned. A newly encountered character after
another projection uses the character reference fallback rather than inheriting
the previous character's actions. A missing class-access mask entry may be
recovered from that GUID's committed transaction; an explicit empty entry is
not the same as absence.

Projection is not action-slot restoration. It declares native commands, preserves
the currently selected keyboard view and saves the accepted target bank through
native APIs. Copying that keyboard view into Character can clear target-only
keyboard keys absent from the outgoing view. Do not promise both saved banks
remain byte-identical after an accepted projection.

[BindingBanks](../../addon/ConsolePort_Forever/Adapters/BindingBanks.lua) needs
explicit review permission before reading an inactive bank: native `LoadBindings`
can discard unsaved in-memory edits even for inspection. It records durable
selection intent and the transient view first, guards returning to the original
selection/view, and saves only within accepted write/compensation rules. An
interrupted selection and its saved transient view have separate recovery paths.
No disk SavedVariables or bindings-cache editing is involved.

## Ring preservation and class augmentation

[Rings](../../addon/ConsolePort_Forever/Adapters/Rings.lua) captures manual order,
duplicates and metadata; native autoassigned utility entries are not archived as
manual content. Unavailable entries can remain dormant in the GUID archive and
return when natively valid. A generic whole-set deletion is recorded. Native
Shared account data is not the personal GUID projection.

[ClassActions](../../addon/ConsolePort_Forever/ClassActions.lua) is a separate
augmentation path: it retains current entries and appends missing learned forms
to the resolved personal class set. Therefore deleting a currently learned class
entry, or its class set, is not an unconditional promise that it stays absent.
This distinction does not reintroduce automatic action-bar spell restoration.
Foreign class tags and personal/Shared name collisions fail guarded projection.

The class chord is left L1+L2 for Paladin/Druid, right R1+R2 otherwise. The explicit
Paladin/Druid/Warrior `Supported` guard controls revision-17 repair and native
StanceBar suppression; it is not a universal guard around `Chord`, `Bindings` or
`RingProposal`. Discovery must still supply valid learned data. The later selector
preview ledger remains inactive, including its older class/pet preview chords.

Class migration requires accepted bindings/rings, own projection, native
Character selection, closed wheel, no active prompt/busy state and writable
state. It covers revisions 14–16, plus the one-time revision-17 repair for the
three supported classes with learned forms. Changed chord/ring fields use the
normal journal/readback/commit path and retain reload verification; the repair
marker prevents ordinary repeated revision-17 repair. It does not replay full setup.

## Ground preferences

[Preferences](../../addon/ConsolePort_Forever/Targeting/Preferences.lua) stores
account-wide `spells`, `contexts` and `contextSpells`; these do not change by GUID
or spec. Contexts are vehicle, override, temporary and extra. Resolution skips
`default` entries and tries context spell, general spell, context, then built-in
default. General player defaults are spell IDs 43265, 152280 and 121536; contextual
defaults use cursor. Registry membership or explicit per-spell cursor/player is
required for qualification; a context-wide cursor preference alone is insufficient.

The native ConsolePort Targeting panel offers draft choices, context selection,
Add Spell ID, Apply, Revert and Defaults. Adding an ID with `default` does not
qualify it. Revert resets the draft to saved state. Defaults resets current-class
curated general entries and all context/context-spell maps; it is not a rollback
of recorded history. Apply validates and copies the draft, appending the entire
previous preference table to `groundTargetingHistory`, which currently has no
retention cap or exposed history-restore command.

Apply rejects combat but has no Edit Mode check. It can save preferences during
Edit Mode while protected mode refresh still defers through `CanWrite`. The
panel can exist before character installation; saving a choice does not set the
ground activation policy. Manual/unqualified/native press-hold-release or
assisted-combat actions retain native handling. Secure placement uses the actual
localized spell name and preserves the pressed command until release; no saved
ability macro, pickup/place or action-storage write is created.

## Integration and saved-layout details

[Flat integrations](../../addon/ConsolePort_Forever/Adapters/Integrations.lua)
qualify loaded versions, public finite values and allowed field shapes. They
retain native tables and unknown settings. Their setup proposal preserves current
explicit values rather than imposing guessed defaults.
[DynamicCam](../../addon/ConsolePort_Forever/Adapters/DynamicCam.lua) rejects
unsupported namespaces/wildcard defaults and foreign name collisions. It prepares
an inactive copy before one native profile selection callback; updates to the
owned active copy use native refresh, and removal is limited to inactive owned copies.

[ImmersionProgress](../../addon/ConsolePort_Forever/UI/ImmersionProgress.lua)
initializes only its missing, unowned policy field through a journal, using the
character's existing applied revision. A disabled/restored owned policy is not
silently enabled again. Exact 1.4.61 loaded frame/method identity is required.
Two native deferred callbacks follow measurement; dialog/quest/serial checks
reject stale work. Eligible visible bottom-anchored, animated, non-nameplate
progress uses `(height + 48) * elementScale` through native `SetExtraOffset`.
Manual non-bottom/dynamic-disabled settings, combat/Edit Mode and close changes
prevent correction. No ImmersionSetup or upstream file changes occur.

[EditModeReference](../../addon/ConsolePort_Forever/UI/EditModeReference.lua)
captures the active saved layout/export/index per GUID, and the uniquely named
already-owned account layout as the shared known default even if it is inactive.
Ambiguous matches are rejected; missing matches retain the previous default.
When no known default exists, the read-only packaged 52-system reference can seed
the stored reference, without applying it. Tracking never saves/selects/imports.
The separate reviewed adapter can save/select a newly created managed account
copy, guarding capacity/ownership and native export precision. New-copy Party
defaults place compact vertical Party beneath Raid without moving Raid; existing
Party/manual edits are not reapplied.

## Commands and diagnostic retention

| Command | Actual behavior |
| --- | --- |
| `/cpf`, `/cpf status`, unknown command | Print version/GUID/revision, selected bank, features, module readiness and recent journal IDs. |
| `/cpf install`, `/cpf update` | Force in-game configuration review. Neither downloads nor installs addon code. |
| `/cpf restore [id]` | Review restoration for this GUID; empty ID uses its last install transaction. Newer edits become conflicts. |
| `/cpf recover <id>` | Guarded rollback of this GUID's applying/recovery-required journal. Resolve pending binding selection first. |
| `/cpf recover-selection` | Recover interrupted native bank selection; retained transient-view changes may still need review. |
| `/cpf recover-view` | Review retained pre-interruption in-memory binding view; no silent replay over newer bindings. |
| `/cpf action-recovery` with any argument | Set the compatibility disabled flag. An `on` argument cannot restore the removed action writer. |
| `/cpf proof` | Open the scrollable source/state/diagnostic panel outside combat. |
| `/cpf diagnose` | Refresh ping/visual observations and print status plus diagnostic entries. |
| `/cpf perf on`, `off`, `reset`, `report` | Optional fixed-scope inclusive callback timing, off by default each login/reload. Reset counters; report/off prints and stores aggregates in the current GUID's lastPerformanceEvidence. No worker, payload history, restricted data or automatic output. |

[ActionRecovery](../../addon/ConsolePort_Forever/ActionRecovery.lua) is passive
toward game actions, not read-only toward its own saved evidence. Hooks observe
native PickupAction/PlaceAction and talent-loadout calls without invoking them.
It retains up to 40 event rows with bounded stack text, GUID/spec/loadout snapshots
and anomaly context; partial wipes do not replace retained good snapshots.
[Diagnostics](../../addon/ConsolePort_Forever/Diagnostics.lua) retains up to 80
entries and latest runtime/visual/ping summaries. Transactions, preference history
and loadout archives have separate retention behavior; do not call all saved
evidence globally bounded.

Candidate.35 keeps automatic snapshots immediate but copies only changed
diagnostic sections/feature rows; identical public feature statuses do no copy.
New record/version/revision ownership forces a full detached snapshot. Optional
performance evidence has ten fixed scope aggregates; nested totals overlap and
do not substitute for per-tick AddonProfiler results.
[Procedure and limits](HUD-PERFORMANCE-2026-10-12.md).

Feature strings such as `offline-verified` or “Retail acceptance pending” are
runtime readiness text. They do not automatically ingest the user's later
acceptance receipt. [Current status](../IMPLEMENTATION-STATUS.md) owns reported
Retail acceptance; the proof panel does not certify hardware, taint or pixels.
