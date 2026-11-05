# BetterBags native controller navigation repair

Status: maintained
Reviewed: 2026-11-05
Evidence: [extension](../FOREVER-CONFIG-EXTENDED.md), [native capture](../../tools/capture_forever_config.py).

## Report and pre-implementation plan

The user reports that no controller navigation works while BetterBags is open,
including Circle. The prior bag-route adapters cover opening/closing but never
register the visible addon window with Forever's native FrameControlsManager.
Blizzard's container event registers its own combined window, hidden by BetterBags.
The Circle-only source regression did not establish live native window focus.

1. Verify current installed extension and relevant BetterBags source before any
   replacement. Retain the native 1.60.1 source revision and exact input hashes.
2. Observe BetterBags' real OnShow/OnHide scripts and register the corresponding
   native bag-controller window through wrapped FrameShown/FrameHidden APIs.
   Attach the visible addon window with native extra-panel/button-group APIs.
   Never replace gamepad bindings, the cursor, native navigation or clicks.
3. Let native SmartNavigation discover the existing controls and perform direction
   selection, tooltip focus, left/right clicks, scrolling and context-menu focus.
   Keep Blizzard's original item-action footer, callbacks and binding stack in
   charge. Observe native close and use the bag's own Hide owner to finish closing.
   Preserve foreign addon-window handlers. Do not construct or activate an addon
   footer through the internal raw binding-stack helpers.
4. Refresh native button groups after actual BetterBags draw completion; item
   redraws must not steal focus from another window or context menu. Mark the
   known decorative copy of each item ignored through the native public helper,
   leaving the real interaction button and its native item contracts intact.
5. Coalesce event work and cancel it on logout. Missing APIs, disabled addons,
   mouse UI, combat and changed window ownership must not manipulate native focus.
   Retry still-open windows after readiness/combat/interface transitions. Keep
   registration state accurate through close/reopen and bag-design replacement.
6. Extend the regression with actual native FrameControlsManager, SmartNavigation
   and button discovery source. Exercise captured direction/click/close bindings,
   tooltip selection, redraws, other UI owners, missing readiness, combat,
   transitions, hidden ancestors, design switching, event bursts and stale logout.
   Retain the reproduced missing registration and meaningful fault controls.
7. Run only affected Forever and package checks per current user instruction.
   Anchor the scoped artifact to the previous qualified report/receipt; do not
   claim a fresh Retail suite or hardware/taint proof from modeled leaf APIs.
8. Commit/push exact tested source, preview the existing scoped installer, back up
   current data, replace only ForeverConfig_Extended while playing if needed, and
   independently verify payload, other addons, WTF, links and retained backups.
   Tell the user to reload and distinguish source tests from real game acceptance.

The stock search shortcut and footer visuals remain stock-owned; this repair
does not redirect text entry or relocate the native footer. The visible addon
search field is a separate native edit-box acceptance case.

## Superseding live-selection repair plan

The 0.1.2 delivery did not fix D-pad use. The user confirms Circle works. Live
screenshots show the visible BetterBagsBagBackpack, stock controller shown and
active, input true, cursor alpha 1, no suspension, selection GamepadBackpackButton
and an addon-blocked action. The earlier tests treated wrapped calls with
addon-created panel lists as secure; this was not engine proof.

1. Preserve Circle and native item/binding ownership. Remove addon-created
   extra-panel collections from every call into native navigation.
2. Keep FrameControlsManager's stock controller, but use the visible addon frame
   itself as SmartNavigation's panel. Native discovery creates its own collections.
   On native controller refocus, immediately reattach the visible panel.
3. Route native AttemptClose through an addon-window close callback only if the
   window has no handler. It queues the current BetterBags Hide owner; native
   held-item back is still handled before AttemptClose. Preserve foreign handlers.
4. Remove hidden/disabled/replaced panel info with the wrapped native API. Keep
   event bursts bounded and stale/combat/mouse work blocked.
5. Execute the actual stock initial-target callback, reproduce its backpack-button
   selection, and require direct visible-frame selection. Add a conservative
   collection-boundary negative control. This guard does not emulate WoW taint.
   Recheck native item actions, captured Circle, menu return and lifecycle cases.
6. Qualify only affected Forever/package checks, build from exact pushed source,
   snapshot/preview and replace only the selected extension, then independently
   verify current code, WTF, other addons, roots/links and retained backups.

Native SecureHelper preserves nested values rather than laundering their taint;
see [pinned source](https://github.com/Gethe/wow-ui-source/blob/eac30af597e5aaa43a60f6675ef5fdcea100375f/Interface/AddOns/Blizzard_GamepadSmartNavigation/SecureHelper.lua).
The screenshots establish the blocked action and wrong selected frame, not the
engine's original taint writer. The direct-frame change avoids the implicated
collection route; successful real D-pad behavior remains user-owned acceptance.
