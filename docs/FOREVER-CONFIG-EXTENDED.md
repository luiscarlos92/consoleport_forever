# Forever Config Extended

Status: maintained
Reviewed: 2026-11-05
Evidence: [plan](reference/FOREVER-SETTINGS-REPAIR-2026-11-05.md),
[runtime](../addon/ForeverConfig_Extended/ForeverConfig_Extended.toc),
[native regression](../tools/forever_config_experiment.cjs).

This independent Forever-only addon corrects the audited shared Default Plater
scale from 1.0 to Retail's 1.428571452899855 through Plater's current profile and
RefreshConfig method. It applies once, only to the exact prior state; a different
profile, newer manual scale or disabled UIParent mode is preserved. A failed
refresh restores only its own value and retains an error for later inspection.
No third-party version number admits or rejects an integration.

BetterBags retains its own window, context, rendering and item actions. The bridge
securely observes native backpack/bag open and close functions that BetterBags
does not hook itself, then coalesces a missing request into BetterBags' existing
ToggleAllBags method. A native local bag-open state supplies toggle parity.
BetterBags handling of the same call chain cancels the queued request. Later
same-frame requests replace earlier intent; a replaced bag design cancels stale work. Missing
initialization, combat, ownership loss, forbidden native opening and logout cancel
or reject work. No native function is replaced by addon code and no controller
binding, protected item action or focus route is claimed.

`/foreverconfig` prints actual Plater profile/scale, UI effective scale,
DynamicCam enabled/evaluated/current-situation status and BetterBags construction,
window and bridge state. A bounded snapshot is stored in ForeverConfigExtendedDB
after login/relevant addon readiness/combat exit, on demand and on logout. It does
not poll, continuously reset settings, force camera motion or claim an inactive
addon has worked. It does not alter Immersion or Retail.

## Delivery and rollback

Use the existing builder with `--standalone-addon ForeverConfig_Extended` and the
scoped installer with an explicit `--forever-root`. The November 5 user request
authorizes `--allow-running-forever` for a qualified selected standalone addon.
That mode cannot install dependencies, select Retail, perform a full install or
restore WTF. Artifact scope, backups, drift refusal, atomic code replacement and
independent readback remain required. New addon discovery may require a client
restart rather than a reload.

Disabling the addon removes its future bag bridging and diagnostics. The Plater
scale is a normal persisted user preference after application; restore that
single field to the receipt's before value through Plater, or use the retained
WTF backup with the game closed after checking for later user changes.

## Validation boundary

The native regression executes the pinned Forever bag dispatch and actual
BetterBags toggle/event handler with modeled leaf frames/C APIs. It reproduces the
old bypass, exercises nested/repeated routes, protects later native-owner changes,
and rejects mutations removing the repair or guards. Offline tests also protect
manual scale edits and stale logout callbacks. Engine taint, rendering, hardware
navigation, real camera movement and item actions still require user observation.
