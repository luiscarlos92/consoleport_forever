# Forever Config Extended

Status: maintained
Reviewed: 2026-11-11
Evidence: [plan](reference/FOREVER-SETTINGS-REPAIR-2026-11-05.md),
[runtime](../addon/ForeverConfig_Extended/ForeverConfig_Extended.toc),
[native regression](../tools/forever_config_experiment.cjs).

## Version 0.1.4

The completed Plater migration and BetterBags bridge are retired from the
load path. The applied Plater scale and saved migration history stay in
place. DynamicCam owns its profile and camera behavior. `/foreverconfig`
continues to report presentation, camera and addon diagnostics. Restoring
BetterBags later cannot reactivate the bridge. Its open/close, Circle, input
and focus routes are absent from the version 0.1.4 payload.
[Revised scope](reference/FOREVER-IMMERSION-REPAIR-PLAN-2026-11-11.md).

## Retained history through 0.1.3

The original Forever-only addon corrected the audited shared Default Plater
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

The user confirms Circle closes bags in 0.1.2 but D-pad selection fails. A delayed
live read shows ContainerFrameCombinedBags active, selection stuck on
GamepadBackpackButton, input enabled and an addon-blocked action. Passing an
addon-created extra-panel list through a native wrapper does not make the list's
contents secure; the previous offline wrapper model did not represent this.

Version 0.1.3 is installed while playing. Its six payload files match the qualified
artifact; Retail, other addons, WTF, links and retained backups are preserved.
[Delivery](../evidence/forever-config/2026-11-05/selection-delivery.json),
[readback](../evidence/forever-config/2026-11-05/selection-readback.json).
It discovers the visible BetterBags frame directly through native
HandlePanelOpen/RefreshButtonGroups calls with frame references only. The stock
controller remains registered and keeps the original footer, input stack, item
actions and held-item back behavior. Menu return redirects to the visible frame.
A close callback on the addon window, only when none exists, queues the current
BetterBags owner's Hide method. No native handler or foreign close callback is
replaced, and no input binding group or footer is constructed by the extension.

Lifecycle guards and coalescing remain. A hidden/disabled/replaced addon panel is
removed through the native API. Status reports the visible window independently
of focus, plus its controller, selection and enabled input.

The stock search shortcut and footer visuals remain stock-owned. Current source
qualification passes twenty defect controls and ten affected tooling tests;
actual engine security, rendering and controller acceptance remain pending.
[Qualification](../evidence/forever-config/2026-11-05/selection-qualification.json),
[plan and scope](reference/BETTERBAGS-NATIVE-NAVIGATION-2026-11-05.md).

## Circle close follow-up

The earlier version 0.1.1 was installed while playing; [delivery](../evidence/forever-config/2026-11-05/circle-delivery.json)
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

The applied Plater scale is now a normal Plater preference. Existing backups
and the migration receipt record the earlier value.

## Validation boundary

The historical native regression executed the pinned Forever bag dispatch and
BetterBags handlers. The current retirement regression exercises startup,
late BetterBags load, diagnostic reads and logout. Its fault controls reject
a Plater profile write and a native bag hook. Engine taint, rendering, hardware
navigation, real camera movement and item actions still require user observation.
