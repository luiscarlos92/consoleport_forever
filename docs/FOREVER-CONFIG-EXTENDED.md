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

## Native controller navigation

Version 0.1.2 attaches the visible BetterBags backpack and available bank windows
to their existing Blizzard controller through wrapped frame/extra-panel APIs.
Native navigation discovers the real item buttons; decorative copies are ignored.
Native item-action footers, context conditions, clicks, menus, held-item back
behavior and the input binding stack remain owned by Blizzard. The extension
creates no binding group, input proxy, custom item action or native footer.

Show/hide, draw completion, controller-mode transitions, design changes and combat
exit coalesce. Returning from a menu reattaches controls without a delayed focus
loss; redraws preserve another active window. Native bag-open state is synchronized
when closing so the next toggle reopens correctly. Login/combat/missing readiness
and stale logout work retain their guards. The read-only status command reports
the controller host and visible bag separately.

The stock search shortcut and footer visuals are not redirected. Selecting the
visible addon search field is a separate native edit-box acceptance case.
[Plan and scope](reference/BETTERBAGS-NATIVE-NAVIGATION-2026-11-05.md).
[Targeted qualification](../evidence/forever-config/2026-11-05/navigation-qualification.json)
passes eighteen defect controls and ten affected tooling tests. Controller use
in the actual client remains pending.

## Circle close follow-up

Version 0.1.1 is installed while playing; [delivery](../evidence/forever-config/2026-11-05/circle-delivery.json)
and [readback](../evidence/forever-config/2026-11-05/circle-readback.json) preserve
Retail, WTF, other addons, links and backups. It observes the native combined frame Hide method. The Circle
handler captured during native initialization bypasses global bag functions on
its close branch. The bridge queues a close through BetterBags without replacing
bindings, focus, native handlers or protected item actions. The regression calls
the captured native callback and rejects the old missing route.
[Scoped qualification](../evidence/forever-config/2026-11-05/circle-qualification.json).

A subsequent selected standalone repair can anchor its exact baseline report to
a retained qualified artifact receipt using the existing builder options
`--qualified-baseline-receipt` and `--qualified-baseline-report`. The artifact
report hash must agree, current tests/inventories must match, and unrelated addon
or tool changes remain rejected. This is targeted qualification, not a fresh
Retail suite.

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
