# Forever settings and bag regression repair

Status: maintained
Reviewed: 2026-11-05
Evidence: [current status](../IMPLEMENTATION-STATUS.md), [requirements](../REQUIREMENTS.md).

## Authority and observations

The November 5 follow-up authorizes repairing the Forever configuration and,
where needed, an independent bag extension, including deployment while the user
plays and user-owned reload. Retail and ConsolePort remain outside the payload.
No game launch or game input is requested. Prior backups remain retained.

The user reports small Plater plates, BetterBags still failing to open, uncertain
DynamicCam activation and incomplete testing of other migrated settings. Immersion
has visibly moved; its full option/reward acceptance is still incomplete.

## Pre-implementation plan

1. Snapshot both current WTF trees and their link topology, verify every copied
   file, and inventory both addon trees. Keep private snapshots and raw saved
   preferences under ignored scratch, never in the public repository.
2. Audit all 108 previous changes against current persistence and upstream
   defaults. Distinguish AceDB default stripping from failed persistence. Compare
   active identities, presentation, startup and later native writes.
3. Qualify the currently published sources before runtime changes. Inspect only
   changed packages; do not deploy unchanged dependencies.
4. Correct Plater's missing overall scale multiplier using its native profile and
   refresh route. Both profiles save 112 by 12 global bars, but Retail saves
   1.428571452899855 while Forever saves 1.0. Preserve other profile fields,
   identity-owned data and later manual edits.
5. Trace Forever's native bag dispatch and current BetterBags construction. The
   old captured SetID failure is historical: the installed release already has
   the Forever three-argument Initialize adaptation. Do not patch it again.
   Reproduce any missing direct native open/close route before adding an adapter.
   Keep native protected functions intact; an adapter may operate only the
   existing unprotected BetterBags window, with readiness and combat guards,
   cancellation of stale work and deduplication against BetterBags' own route.
6. Run actual DynamicCam defaults, startup and situation-selection source against
   current saved data. Preserve native conditions/events, supported contexts and
   camera ownership. If settings already match, report that instead of fabricating
   a camera patch. Add bounded on-demand/live-state diagnostics for unresolved
   engine observations, never continuous forced reapplication.
7. Audit Blizzard scaling/camera/nameplate preferences and all remaining shared
   addon preferences. Preserve client-specific content, native controller bindings,
   progress, caches and manual choices. Apply a finite migration only for verified
   presentation differences; later reloads must not repeatedly reset the user.
8. Use separate Forever-only runtime code if applying corrections during play;
   never edit a live SavedVariables file underneath a loaded session. Extend the
   existing scoped package/installer only as needed for an explicit selected
   standalone addon and the newly authorized running-game route. Preserve Retail,
   other addons, WTF, links and backups. New addon discovery may require a client
   restart; do not claim a reload discovers an unregistered folder.
9. Retain old-defect reproduction, native dispatch execution, duplicate/nested
   routes, missing dependencies, manual-change ownership, combat, stale callbacks,
   logout/default stripping and package/rollback negative controls. Run complete
   Test-All and documentation checks, commit/push exact tested source, preview and
   rehearse the artifact, install, and independently read back preservation.

## Audited findings and implemented scope

The private fresh snapshots verify 316 Retail and 104 Forever files. Of 108
previous operations, 89 remain explicitly equal and 17 match verified addon
defaults after AceDB stripping. Whisper mode and the native modifier-toggle CVar
need effective runtime/default reads; they are captured by the extension rather
than guessed. All eight prior chat edits and the bag enable entry persist.
The 17 shared account saved-variable files and 11 shared character files are
compared. Seven character files match exactly; remaining character differences
are profession/quest data, gear and class/GUID markers, not presentation presets.

The implementation is one separate ForeverConfig_Extended addon containing the
finite Plater correction, BetterBags bridge and runtime status. It does not
transplant obsolete per-actor Plater tables, reapply settings every reload, copy
Retail character data, hide native bag buttons, introduce mouse-driven bag fading,
or force a speculative DynamicCam restart. The native dispatch model reproduces
the old direct-backpack bypass with a fully initialized BetterBags, then exercises
the repair against its actual toggle/event handler. The same failure is not yet
confirmed as the user's complete live cause; readiness diagnostics expose any
remaining initialization failure rather than fabricating it away.

DynamicCam's native startup, 20 supported contexts, seven modeled environment
transitions and actual AceDB logout/reinitialization pass. Camera movement and
the native gamepad camera's later writes still require an engine observation.
[Saved-data audit](../../evidence/forever-config/2026-11-05/settings-audit.json),
[installed source parity](../../evidence/forever-config/2026-11-05/installed-source-parity.json),
[targeted qualification](../../evidence/forever-config/2026-11-05/targeted-qualification.json).

## Limits

Saved data and offline source execution do not certify live camera movement,
gamepad navigation, item actions, rendering, taint or persistence. Installed,
configured, observed and accepted remain separate outcomes. Respect the requested
5 percent remaining five-hour usage stop, with continuation at reset plus ten
minutes if needed.
