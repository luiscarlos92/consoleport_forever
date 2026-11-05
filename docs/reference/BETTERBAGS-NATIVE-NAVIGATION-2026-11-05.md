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
