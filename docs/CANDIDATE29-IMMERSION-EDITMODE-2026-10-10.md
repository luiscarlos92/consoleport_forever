# Candidate.29 preparation: Required Items and current Edit Mode reference

The user authorized a Forever-owned runtime correction, reference capture and
package preparation. Deployment remains forbidden while the user plays.
Installed candidate.27 stays intact. Candidate.29 carries forward the prepared
candidate.28 native account ping ring and its inactive candidate.27 fallback.

## Required Items

Immersion 1.4.61 has no Required Items-specific SavedVariable. Existing account
settings already use Bottom, Dynamic offset 5, base Y 39.27963256835938, overall
scale 1.2. These settings and Immersion's files are not modified or updated.

The pinned QUEST_PROGRESS handler reads Progress height after UpdateBoundaries.
UpdateBoundaries measures children again next frame without recalculating that
offset. T66 executes the exact pinned event handler, child measurement and native
offset/animation methods: an unresolved first geometry produces height 1 and
extra offset 49; the next-frame height becomes 200 but its offset remains 49.
This reproduces a source defect consistent with the screenshots. Retail visual
acceptance is still needed to confirm it resolves the reported quest.

Forever uses additive secure post-hooks, not replacement event methods. After
two frame boundaries it checks the same visible QUEST_PROGRESS dialog, quest ID,
known dependency version, enabled policy, Bottom anchor and nonzero dynamic
offset. It reapplies the native (measured height + 48) * elementscale through
SetExtraOffset only if it differs. The native base offsets, animation, rewards,
gossip, top/nameplate anchors and dynamic-off choice remain. A changed dialog,
close, combat, Edit Mode, busy operation or disabled policy cancels the callback.
The login diff path seeds only Forever's integrationPolicy repair version through
a one-field backed-up transaction; revision17 stays and the full installer never
replays. A restored/disabled policy is not silently enabled again.

## Edit Mode

The user confirmed their latest edits are saved. Read-only capture of the saved
account cache retains the complete named Console Port - Forever (Managed) layout:
52 system records, exact export, file hash and UTC capture time. The cache was
last written at 2026-10-10 22:28:50 UTC. Filesystem evidence represents that disk
save; the next in-game capture uses the current native saved layouts and includes
any later saves made while the user keeps playing.

SavedEditModeReference.lua is an inert fallback reference, not an import or a
replacement layout. UI/EditModeReference.lua uses the existing native Capture
adapter at refresh/login/layout events and after Edit Mode closes. It stores
the active saved layout per GUID and the already-owned named account layout as
the known default. It copies every system/settings/anchor, including timer bars
and newly introduced systems, without hardcoded system filtering. It never calls
SaveLayouts, SetActiveLayout, ImportLayout or a live frame UpdateSystem.

The normal review path now offers Party defaults only when creating a new copy.
An existing owned copy preserves the player's full current layout and selection,
including manual Party changes. Accepted transaction baselines/backups remain
historical and are not rewritten by reference capture. Other characters' active
layout choices do not replace the owned account reference.

## Scope and validation

All nine dependencies were freshly checked against official stable Retail
sources this session; no package changed. Immersion is explicitly excluded from
updates. No dependency bytes will be reshipped in this scoped preparation.
T66 includes missing-correction negative control, native animation, measured
heights/scales, stale/closed/changed dialogs, native item updates, protected-state
deferral, future-version refusal, disabled/restored policy and one-field backup.
T67 checks full saved layout capture, deferred edits, account/per-GUID separation,
unchanged accepted baselines, zero native save/selection calls and preserving
existing Party/manual geometry in actual RuntimeSetup field construction.

Run the complete runtime/source and tooling gates on frozen source before the
builder. See NEXT-DEPLOYMENT-CHECKLIST.md for the cumulative Retail acceptance
work. No game input, reload, restart, installer preview or deployment is authorized.

All 67 runtime/source suites and 39 tooling checks passed on frozen source.
The user withdrew the later gossip/options-list request after read-only inspection;
no options-list code, scale, anchor, scrolling or settings changes were made.
