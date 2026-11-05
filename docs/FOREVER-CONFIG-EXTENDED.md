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

The user confirms Circle closes bags in 0.1.2 but D-pad selection fails. A delayed
live read shows ContainerFrameCombinedBags active, selection stuck on
GamepadBackpackButton, input enabled and an addon-blocked action. Passing an
addon-created extra-panel list through a native wrapper does not make the list's
contents secure; the previous offline wrapper model did not represent this.

Version 0.1.3 discovers the visible BetterBags frame directly through native
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
