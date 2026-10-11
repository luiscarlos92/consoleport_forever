# ConsolePort / WoW Forever offline implementation report

Date: 2026-09-26  
State: **final polish installed and offline validation passed; one consolidated in-game check remains. Automation is PAUSED. See the final section below.**

## Result

Retail is now configured around a 41-folder controller-first stack:

- a custom `Forever: Expanded Crosses` ConsolePort presentation with four persistent eight-button banks;
- L2 and R2 as the two action modifiers, including the combined layer;
- Forever-style base controls and bumper targeting;
- ConsolePort soft targeting, compact interact hints, cursor, keyboard, rings, and menu behavior;
- Plater as the only nameplate renderer;
- Immersion plus ExtraFade for dialogue;
- a purpose-built DynamicCam couch profile for world, interiors, combat, instances, mounts, flying/skyriding, NPC dialogue, mailbox, fishing, gathering, and swimming;
- BetterBags, DBM, LiteMount, Masque, Plater, and SharedMedia_Causese retained with their compatibility boundaries preserved.

Blizzard Edit Mode caches and the two existing account layouts (`RealUI` and `RealUI Acer`) were not changed. They are account/server-synchronized and remain the fallback for frames outside ConsolePort's ownership.

## Files changed

- `_retail_\WTF\Config.wtf`
  - Shift/M1 = `PADLTRIGGER`;
  - Ctrl/M2 = `PADRTRIGGER`;
  - Alt/M3 cleared;
  - analog travel/combat angles = 0°/180°;
  - turn with camera = Always;
  - enemy/friend soft targeting and target icons enabled;
  - mouse-style target tooltips disabled;
  - ConsolePort nameplate forcing disabled so Plater owns plates;
  - interaction soft targeting enabled.
  - Blizzard action-grid display disabled;
  - account binding/config synchronization disabled so the local shared profile is not replaced at login;
- `_retail_\WTF\Account\119624169#1\SavedVariables\ConsolePort.lua`
  - exact matching core overrides;
  - press-and-hold rings enabled, sticky selection off;
  - interface cursor and wrapping behavior enabled;
  - all three existing Arcane binding profiles updated;
  - active PS5 generator updated for future profiles.
- `_retail_\WTF\Account\_template_\SavedVariables\ConsolePort_Bar.lua`
  - changed to `Forever: Expanded` after the user supplied two clear references of Forever's full non-compact HUD;
  - four persistent cross-shaped banks show base, L2, R2, and L2+R2 simultaneously;
  - the active bank brightens and grows to 112%, while inactive banks remain visible at 45% opacity;
  - L1/R1 targeting prompts are not permanently rendered; two small L2/R2 modifier labels remain;
  - empty action slots remain visible, matching the expanded Forever presentation;
  - existing neutral bar options retained.
- `_retail_\Interface\AddOns\ConsolePort_Bar\Controller\Blizzard\Mainline.lua`
  - all seven Blizzard multi-action bars are force-hidden with the same path ConsolePort already uses for the main bar;
  - this local source adjustment may need reapplying after a ConsolePort update.
- `_retail_\Interface\AddOns\BetterBags\integrations\masque.lua`
  - removed the unconditional informational login message while leaving Masque integration enabled.
- `_retail_\WTF\Account\119624169#1\SavedVariables\DynamicCam.lua`
  - account `Default` profile configured with the situation values documented in `ConsolePort-Forever-Configuration-Plan.md`.
- `_retail_\WTF\Account\_template_\AddOns.txt`
  - rewritten to enable exactly the 41 retained add-on folders plus the two existing Blizzard entries.

## Final base controller map

| PS5 control | Retail/ConsolePort action |
|---|---|
| L2 | Shift / M1 modifier only |
| R2 | Ctrl / M2 modifier only |
| L1 | `TARGETNEARESTFRIEND` in every modifier state |
| R1 | `TARGETSCANENEMY` in every modifier state |
| Cross | `JUMP` |
| Circle | No global world action; contextual cancel/Goodbye in ConsolePort and Immersion UI |
| Square | `INTERACTTARGET` |
| Triangle | `TURNORACTION` |
| L3 | `TOGGLEAUTORUN` |
| R3 | `TOGGLEPINGLISTENER`; right-click while ConsolePort's cursor is active |
| Left trackpad-side / `PADBACK` | ConsolePort main radial menu in all four modifier states |
| Right trackpad-side / `PADSYSTEM` | World map in all four modifier states |
| L2+R2+D-pad Up | LiteMount (`CLICK LM_B1:LeftButton`), static icon 132247 |

Existing L2, R2, and L2+R2 class action-slot assignments were preserved. The implementation deliberately did not guess which spells belong in those server-backed slots.

## Add-on cleanup

The live `Interface\AddOns` directory now contains exactly 41 folders: the 40 retained upstream add-on folders plus the local `ConsolePort_Forever` compatibility layer. All 80 approved removals were moved to:

`C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\Removed AddOns 2026-09-26`

They are outside the AddOns directory and cannot load. This is a recoverable quarantine because the execution environment rejected irreversible recursive deletion. No SavedVariables file for any removed add-on was deleted or moved.

Dependency validation found zero missing required-dependency references among the retained folders. The shared `AddOns.txt` has exactly 41 custom enabled entries, with no missing retained folder and no stale removed entry.

## Character junction repair

The three formerly independent directories were moved into:

`C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\Former Character AddOns 2026-09-26`

Their original paths are now junctions to the exact shared `_template_` directory:

- `Proudmoore\Fëanturï`;
- `Outland\Engwär`;
- `Outland\Ganymëdë`.

Validation now reports 42 character directories, 42 junctions to `_template_`, and zero exceptions. The three original `AddOns.txt` files remain in the holding directory for reference.

## Offline validation passed

- No `Wow` process was running while SavedVariables were edited.
- All three edited Lua SavedVariables files pass a Lua 5.1-compatible parser:
  - `ConsolePort.lua`;
  - `ConsolePort_Bar.lua`;
  - `DynamicCam.lua`.
- All 16 critical `Config.wtf` values exist exactly once with their intended values.
- All three saved ConsolePort profiles pass the base binding and empty-trigger checks.
- The saved bar declares `Forever: Expanded Crosses` and contains 32 action buttons plus two small trigger labels.
- All seven Blizzard multi-action-bar frames are included in ConsolePort's local hide table.
- The BetterBags/Masque informational login print is absent.
- The retained add-on inventory is exactly 41 folders, including the local Forever HUD compatibility layer.
- Required-dependency closure has zero missing entries.
- The shared enablement list exactly matches the 41 retained folders.
- All 42 character directories resolve to the shared template.

## First-login runtime check

Offline checks cannot execute Blizzard's secure binding/UI runtime or confirm server-synchronized action-slot contents. On the first login, the useful checks are therefore experiential rather than setup work:

1. Confirm the `Forever: Expanded Crosses` HUD shows four banks; every bank should contain a D-pad plus and a face-button plus, and L2, R2, and L2+R2 should brighten/enlarge their respective banks while the others remain dim.
2. Confirm the base face/bumper/stick actions above.
3. Talk to an NPC: Immersion should open, ExtraFade should control surrounding UI, and DynamicCam should ease to 5.5 zoom without rotating the camera.
4. Mount and take off: zoom should move to 20 mounted, 26 airborne, and 30 while airborne skyriding.
5. Enter combat or an instance: camera should widen while Plater remains the only nameplate renderer.
6. Open bags, a vendor, map, settings, and the ConsolePort menu to confirm cursor focus and Circle/back behavior.

If WoW rewrites a file on logout, compare it with this report before treating that as a fault: Blizzard and AceDB normally expand sparse defaults and reorder serialized table keys.

## Changes prompted by the first-login screenshot

The screenshot proved that the add-ons loaded, but also showed that the built-in `Crossbar: Triggers` preset was visually too busy and that Blizzard's enabled action bars were still visible. The second offline pass therefore made the following deliberate changes:

- replaced three simultaneous action banks with one enlarged paging bank;
- removed the two empty trigger prompt boxes;
- retained only the two useful bumper targeting prompts;
- force-hid the center and right-side Blizzard action bars rather than relying only on their saved visibility state;
- normalized all three existing character profiles and the PS5 generator to the same sequential 1–8 action-layer scheme;
- made both trigger modifiers explicit in `Config.wtf`;
- disabled Blizzard synchronization of bindings/config so the account copy cannot silently restore the prior layout;
- suppressed BetterBags' harmless Masque status line.

The next login is a runtime/visual test, not another setup pass. Actual spell placement remains server-backed and character-specific, so the user may still need to arrange abilities on the three modifier layers in game.

## Expanded-HUD and 1080p scaling pass

Two user-provided Forever references established that the desired target is the full non-compact HUD, not the optional compact mode. The final offline pass therefore:

- created separate persistent base, L2, R2, and L2+R2 banks in the same broad upper-center/left/right/lower-center arrangement;
- retained all 32 slots on screen, including empty slots;
- added state-driven 45% inactive opacity and 112% active scaling;
- removed the permanent L1/R1 targeting display without changing the bindings;
- retained small L2/R2 labels to explain the left and right banks;
- changed `uiScale` from `1` to `0.711111`, the appropriate baseline for the detected 1920×1080 display.

The scale change applies to the whole Blizzard interface, so chat, objectives, minimap, unit frames, and the controller HUD should all be materially smaller on the next login.

### Television readability tuning

The first expanded-HUD screenshot showed that `0.711111` made quest and nameplate text too small while the saved General chat font was unusually large at 20. The follow-up tuning therefore:

- sets all ten chat windows to Blizzard's minimum font size, 12;
- raises global `uiScale` modestly to `0.76`;
- uses 101% inactive and 113% active controller-bank scale after the final modest size reduction;
- places the L2/R2 bank centers at x=±280 and y=115;
- places the base bank at y=185 and the combined L2+R2 bank at y=45, forming the four-cluster Forever diamond lower on screen.

On PlayStation glyphs, **Square** (`PAD3`) is bound to `INTERACTTARGET`: approach or face an NPC until it is the current/soft interaction target, then press Square.

### Binding persistence and cross-layout correction

Runtime testing revealed that the character-named Proudmoore snapshot was being rewritten from Blizzard's live binding set on logout. That live set had empty base actions on PAD1–PAD4, explaining why the face buttons worked for menu navigation but did nothing in the world.

The fix no longer relies on those character snapshots:

- a stable custom shared preset named `Forever Controller` now contains the complete base/L2/R2/L2+R2 map;
- `bindingPresetCondition = "[] Forever Controller"` loads that preset automatically every login;
- binding overlap is enabled so L1/R1 can retain the same targeting action in all modifier states;
- the account `bindings-cache.wtf` contains the same gamepad map as a startup fallback;
- Cross/PAD1 = Jump, Circle/PAD2 = contextual Back only, Square/PAD3 = Interact, and Triangle/PAD4 = Turn or Action;
- chat font was raised from 12 to the next Blizzard option, 14;
- each eight-button bank is now two compact adjacent crosses: D-pad on the left and PlayStation face buttons on the right.

### Circle contextual-cancel correction

The final runtime test showed that binding Circle/PAD2 globally to `TOGGLEGAMEMENU` caused one press to close an Immersion conversation and sometimes continue through to the underlying Game Menu. Circle's unmodified global binding is now deliberately empty in the PlayStation 5 generator, the stable `Forever Controller` preset, every existing character snapshot, and the account binding cache.

This does not remove contextual Back behavior: Immersion handles PAD2 directly as its configured Goodbye button, while ConsolePort uses PAD2 as cancel/right-click inside its own UI and unit menus. The Game Menu remains available from the controller's central menu/options buttons. The intended result is that Circle closes the active dialogue or controller UI, but never opens the Game Menu while standing in the world.

### Forever face-button skin and unit-frame clearance

Runtime screenshot comparison showed two details that the saved bar schema alone cannot express. ConsolePort normally applies the same square action-button skin to every physical input, whereas Forever uses square D-pad keycaps and circular face-button slots. The ConsolePort cluster factory now tags the unmodified PAD1–PAD4 buttons as they are created, and the cluster skin uses that deterministic tag to apply a circular icon mask, ring, highlight, and cooldown swipe. D-pad buttons retain their square skin. This replaces both failed approaches that tried to infer button identity from generated frames or from the skin callback alone.

The four action banks form a mathematically aligned diamond; after the final compact pass their positions are base `(0, 150)`, L2 `(-280, 80)`, R2 `(280, 80)`, and L2+R2 `(0, 10)`. Inside each bank, the D-pad and face-button crosses use exact 45-unit vertical/horizontal offsets. The local `ConsolePort_Forever` module places Blizzard's player and target frames at `(-310, -175)` and `(310, -175)` relative to screen center. It hides the Blizzard micro-menu/bag bar, and the ConsolePort toolbar's own `micromenu` flag is disabled; ConsolePort's radial menu remains the controller access path.

The last bottom-center icon identified by its `Action Bar Configuration` tooltip was ConsolePort's own toolbar configuration handle, not a remaining Blizzard micro-menu icon. That handle is now explicitly hidden. `clusterShowAll` and `clusterShowFlyoutIcons` are both disabled so pressing modifier controls does not reveal redundant empty modifier flyout slots alongside the four persistent banks.

### Final lower/compact pass and pinned circle follow-up

The successful runtime test confirmed that the Blizzard menu strip and ConsolePort configuration handle are gone. The controller banks now use 94% inactive and 106% active scale, and the whole diamond is lowered by 35 UI units: base `(0, 150)`, L2 `(-280, 80)`, R2 `(280, 80)`, and L2+R2 `(0, 10)`. This preserves the internal cross geometry while using nearly all safe space above the bottom edge. The separate modifier-label group is forced hidden, removing the remaining standalone `L2`/`R2` label remnants.

Circular face-button frames remain unresolved and are explicitly pinned for a later isolated investigation. The current source-level factory tag and skin override parse correctly but did not alter the runtime frames in screenshot `1000102991.jpg`; do not treat that implementation as verified. The next pass should inspect the live frame/template ownership and the final texture assignment order after `PLAYER_LOGIN`, rather than adding another SavedVariables or static-skin guess. Square action slots remain functional in the meantime.

### Toolbar divider and unit-frame finishing pass

Screenshot `1000102992.jpg` confirmed the remaining silver strip was ConsolePort's empty toolbar tint/divider, not an XP bar. `tintEnable` is now explicitly false in `ConsolePort_BarDB`, which hides both the toolbar background tint and `DividerLine`; the already-approved action-bank positions and scales are unchanged. The player and target frames retain x offsets of -310 and +310 but move from y=-110 to y=-175, bringing both roughly halfway closer to their corresponding enlarged side banks while remaining clear of the action slots.

## Approved baseline — 2026-09-26

Screenshot `1000102993.jpg` is the user-approved baseline. Preserve it unless the user later requests a specific change. Confirmed successful characteristics:

- four persistent action banks in the compact Forever-style diamond;
- base `(0, 150)`, L2 `(-280, 80)`, R2 `(280, 80)`, and L2+R2 `(0, 10)`;
- 94% inactive scale and 106% active scale;
- player frame `(-310, -175)` and target frame `(310, -175)` relative to screen center;
- no Blizzard micro-menu/bag strip, no ConsolePort configuration icon, no silver toolbar divider, and no standalone L2/R2 modifier-label remnants;
- approved global UI scale, chat size, minimap/objective sizing, action-bank spacing, DynamicCam behavior, and working controller bindings;
- Cross jumps, Square interacts, Circle performs contextual back without opening the Game Menu, L1/R1 target, and L2/R2 switch action banks.

The only deferred visual defect is that PAD1–PAD4 action slots still render with square frames instead of Forever-style circles. Any future fix must be isolated to face-button presentation and must not move, resize, hide, rebind, or otherwise change this approved baseline. See `ConsolePort-Circular-Buttons-Handoff.md`.

An independent one-time Codex automation, `fix-consoleport-circular-buttons`, is scheduled in the World of Warcraft project for 2026-09-26 at 11:24:37 PM America/Toronto—five minutes after the current five-hour usage reset. It will create a separate standalone task, use the dedicated handoff, investigate and verify autonomously, and will not continue in this chat.

## User tuning and queued finishing work — screenshot 1000102996

The user completed and approved two Immersion changes manually:

- increased the overall Immersion presentation size;
- configured Immersion ExtraFade to hide the desired surrounding interface.

These are now part of the approved baseline. Preserve `ImmersionSetup.scale = 1.2`, the user's other Immersion sizing choices, and the current `IEF_Config` visibility/fade choices unless a narrowly scoped position correction requires otherwise.

The following work is queued for the same one-time standalone automation that will investigate circular face buttons:

1. Move the player cast/progress frame away from the player health frame and center it immediately above the unmodified/base controller bank. Preserve its size and skin, and make the anchor survive login, reload, and Edit Mode resets.
2. Split the two DualSense buttons beside the trackpad: left `PADBACK` continues to open `CLICK ConsolePortMenuTrigger:LeftButton`; right `PADSYSTEM` opens `TOGGLEWORLDMAP`. Apply the intended action consistently across modifier states and persist it in the stable preset, current snapshots, and binding cache.
3. Make the user's existing L2+R2+D-pad Up LiteMount binding durable for every character by adding `CLICK LM_B1:LeftButton` to that layer of the `Forever Controller` preset and all required persistence copies. Add a static ConsolePort binding icon using LiteMount's declared addon icon file ID `132247`.
4. Correct Immersion's talk-box horizontal drift by changing `boxoffsetX` from approximately `12.37` to `0`. Keep `boxpoint = "Bottom"`, lower the base Y position from approximately `204.11` toward `150`, and rely on Immersion's native `SetExtraOffset()` behavior to raise the talk box only when objectives, requirements, or rewards need extra room. Preserve the user's scale and ExtraFade settings. Treat the separately anchored title/choice frame independently rather than resetting it blindly.

The queued run must preserve the approved action-bank geometry, scale, unit-frame positions, controller behavior, DynamicCam setup, and all other successful elements from screenshot `1000102993.jpg`.


## Final polish installed — 2026-09-26 evening / 2026-09-27 UTC

All five scoped changes are installed. **This is an offline-validated implementation, not a claimed in-game visual sign-off.** WoW was closed at the initial process check, the backup, and deployment; the deployment script refuses to write while any `Wow*` process exists. No game session was launched, no character was selected, and no gameplay state was changed. Native game UI inspection is unavailable in this session. The single consolidated login check at the end is the remaining acceptance step.

The automation `fix-consoleport-circular-buttons` was changed through the app to **PAUSED**, and its saved configuration confirms that state. Its existing one-occurrence schedule, project, model, and prompt were retained. It will not run again automatically.

### Why the previous circle changes missed the visible slots

The saved approved layout declares four **Group** banks (`Base`, `L2`, `R2`, `L2R2`) containing **32 GroupButton** children. It does not instantiate the Cluster/ClusterButton factory for these slots. The earlier `isForeverFaceButton` tag was set only inside the ClusterButton factory, and `Cluster/Skins.lua` was only installed by that factory's `Button:UpdateSkin`. Consequently neither function could change these visible GroupButtons. Parsing those files proved syntax, not reachability. The currently installed Forever helper also had no face-slot skin code; its remaining functions positioned unit frames and hid the menu bars.

The actual construction path is `CPGroupBar:UpdateButtons` → `GroupButton` factory → `LAB:CreateButton` → `ActionButtonTemplate, SecureActionButtonTemplate` → `Group Button:OnLoad` → `ProxyButton:OnLoad` → `SlotButton:OnLoad` → the ordinary Retail slot skin. That slot skin only installs a name-width update on Retail. The inherited Retail art stays square. LibActionButton's `Update` then restores the AddRow normal atlas for both populated and empty buttons, while Masque's two group enrollment paths can subsequently skin the same buttons.

Source cross-check: the downloaded Blizzard UI source is commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`, labeled **12.1.0 (69933)**, matching the local installation's `.build.info`. See the [Retail action-button template](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml). A copy and reference metadata are saved with the validation evidence.

### The new face-slot path and final writers

[Group.lua](<C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/ConsolePort_Bar/Widget/Group/Group.lua:5>) now tags PAD1–PAD4 only when their parent ID is one of the four approved banks. This reaches all **16 face slots**, independently of each bank's fixed modifier. D-pad slots and unrelated groups retain their original code path.

The tag is established before `OnLoad`. `PreventSkinning` sets `MasqueSkinned` to suppress LAB's native square reset; this flag alone is insufficient to stop Masque. Both `UpdateButtons` and `OnMasqueLoaded` now exclude tagged faces from Masque enrollment. After the ordinary ProxyButton initialization installs its default updater, the face skin installs the final `UpdateLocal` function, plus an art-refresh post-hook and size-change hook. The existing circular `RoundBorderHighlight` texture supplies the silver ring. Button dimensions, anchors, secure actions, hotkey glyphs, alpha and scale drivers are unchanged.

| Visible layer | Original writer | Final face-slot writer / behavior |
|---|---|---|
| Populated icon | LAB `Update` and ProxyButton texture provider | LAB still chooses and shows the icon; the face updater changes only its UVs and circular `IconMask`. |
| Empty fill | Template `SlotBackground`, then LAB/Masque visibility/art | A dark masked circular background remains available behind icons and in empty slots. |
| Empty slot rim/art | Template `SlotArt`, native art refresh, Masque | Face updater clears and hides `SlotArt`, removing the second square layer. |
| Normal border | Template atlas, LAB `SetNormalAtlas`, Masque normal skin | Face updater assigns the circular ring after initialization and art refresh. |
| Pushed, hover, checked, attack flash | Template textures; state visibility from LAB/native button | Circular ring textures replace these shapes; their state machinery remains intact. |
| Equipped, new-action and spell highlights | Native template textures, LAB visibility updates | `Border`, `NewActionTexture` and `SpellHighlightTexture` use circular art; obsolete `BorderShadow` texture is cleared. |
| Normal, charge and loss-of-control cooldowns | Retail template plus LAB timing updates | Circular swipe texture and edge, bounded by the circular fill; timing, colors, text and charge swipe settings remain native. |
| Proc overlay | ConsolePort's LibButtonGlow wrapper | Tagged slots dispatch to existing `RoundGlow.ShowOverlayGlow`/`HideOverlayGlow`; the group's alpha callback is retained. |
| Small controller glyph | `ProxyHotkey:OnIconsChanged` | Unchanged. A Square-button glyph may still be square inside/above a circular action slot. |

The obsolete Cluster-only tag and face-style override were removed from `Cluster.lua` and `Cluster/Skins.lua`; their ordinary Cluster skin remains. This eliminates the misleading dead trial rather than treating it as a second active solution. Masque remains installed and continues to own the same D-pad and other eligible buttons.

### Cast/progress frame

Retail's ConsolePort toolbar explicitly skips casting-bar ownership (`not CPAPI.IsRetailVersion`), so its saved `castbar.enabled` setting could not place this bar. The actual Retail global is **PlayerCastingBarFrame**. Blizzard's attachment and Edit Mode functions can restore its parent/anchor and change its look; see the matching-build [player-frame attachment code](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_UnitFrame/Shared/PlayerFrame.lua) and [Edit Mode cast-bar code](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua).

[ConsolePort_Forever.lua](<C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua:30>) now captures the bar's loaded width, height, effective scale, look and strata. It reparents the bar to UIParent and anchors its **BOTTOM to ConsolePortGroupBase TOP, x=0, gap=12**. The top row's slot bounds sit just below the group's top, leaving a small gap. The bar remains independently scaled while its anchor follows the bank's native 94%/106% rescaling.

Login/reload use the existing entering-world refresh. Native attachment, look/parent/scale changes, art positioning, OnShow and Edit Mode restoration schedule a guarded reanchor. Combat defers writes until `PLAYER_REGEN_ENABLED`. The helper uses Edit Mode's base point/scale methods for its own positioning, avoiding writes to saved `systemInfo` and snapped-frame bookkeeping. It preserves the loaded skin rather than calling the native detach operation, which also changes appearance. Existing player/target placement and menu-hiding functions are unchanged. No Edit Mode cache was edited.

### Binding and icon persistence

| Combination | Durable action |
|---|---|
| `PADBACK`, `SHIFT-PADBACK`, `CTRL-PADBACK`, `CTRL-SHIFT-PADBACK` | `CLICK ConsolePortMenuTrigger:LeftButton` |
| `PADSYSTEM`, `SHIFT-PADSYSTEM`, `CTRL-PADSYSTEM`, `CTRL-SHIFT-PADSYSTEM` | `TOGGLEWORLDMAP` |
| `CTRL-SHIFT-PADDUP` | `CLICK LM_B1:LeftButton` |

These are the four configured modifier states; the Alt emulator remains disabled. The mappings are now consistent in the stable **Forever Controller** preset, all **four current character snapshots**, the active saved PS5 generator, the PS5 source generator, the account binding cache, and the shared template's formerly empty character binding cache. Every other binding remains unchanged, including the other central buttons. Historical `.bak`/`.old` files are rollback history and were not rewritten.

The existing account setting `bindingPresetCondition = "[] Forever Controller"`, `useCharacterSettings = false`, and overlap-enabled binding loader remain intact. They apply the stable preset on login, including when the active binding set is character-scoped. All **42 character junctions** still resolve to the shared template. The mount icon is saved as `ConsolePortBindingIcons["CLICK LM_B1:LeftButton"] = 132247`, and the same ID is a default-icon fallback in the core binding source. ID 132247 was verified in the installed LiteMount TOC. No mount rules, dynamic-icon heuristics, or other gameplay actions were changed.

### Immersion

Only `ImmersionSetup.boxoffsetX` and `boxoffsetY` changed: **12.36656450478768 → 0**, **204.111328125 → 150**. Bottom anchoring, scale **1.2**, box/element/title scaling, animation divisor **5**, all ExtraFade choices, and title offsets **446.7689819335938 / -117.6884460449219** remain unchanged.

The native `TalkBox:SetExtraOffset` adds temporary height to the stored base Y only for Bottom anchoring. Reward/objective content supplies `(height + 32) * elementscale`; required-item progress supplies `(height + 48) * elementscale`. Native reset paths restore zero extra offset. No permanent reserved space was added. `Titles:OnUpdateOffset` and the initial title anchor operate separately relative to UIParent CENTER, so their offsets were deliberately retained. No Immersion addon source was edited.

### Validation and limits

- **All eight edited Lua files parse with luaparse 0.3.1 in Lua 5.1 mode.**
- A focused Fengari Lua harness executes the installed ConsolePort local action-button library and ProxyButton code, the actual patched Group factories, the extracted actual LAB `Update` body, the patched helper, and unchanged Immersion movement code. Frame/API mocks replace the game engine; this is not a WoW client simulation.
- Both early and late Masque loading, plus group rebuilds: exactly 16 face slots reach the round path; 16 D-pad slots remain square. Other groups are excluded. All state textures, masks and three cooldown shapes are asserted; proc dispatch points to the existing round-glow functions.
- **48 LAB update cases** cover action/custom/empty content across all 16 face slots, including a later native square-art refresh. The final updater retains the ring and circular empty fill.
- Cast harnesses cover fresh login and reload, native reattachment, Edit Mode look/scale/anchor resets, combat deferral and recovery, and unchanged unit positions. Captured effective size/skin are retained, with no additional Edit Mode bookkeeping writes.
- Native Immersion animation settles at **(0,150)**, rises to **282** for a representative 100-unit reward panel and **298** for required-item progress, then returns to **150**. The base Y stays 150 throughout.
- AST comparisons allow only requested binding/icon edits and exactly two Immersion setting edits. Both caches retain every unrelated line. Deployment hashes match the tested files.
- Preservation audit: **3,784 unchanged paths** (including aliases), **41 unchanged addon folders**, and **42 valid shared character junctions**. Bar geometry/scale/visibility, UI scale, chat, DynamicCam, ExtraFade, Masque settings, addon enablement and Edit Mode caches are unchanged.

**Unverified:** final pixels and ring weight on the television; actual GPU masking/animation; hardware button delivery; Blizzard secure/taint behavior and absence of in-game Lua errors; runtime conflicts; cast-bar gap during real spells/progress; real NPC panel overlap. No offline test can establish those visual/client results. There was one evidence-backed implementation and no sequence of in-game speculative trials.

Validation output: [installed-file tests](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/evidence/validation-live.txt>) and [preservation audit](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/evidence/preservation.json>). The readable [patch](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/changes.patch>) and [test harness](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/harness.lua>) are retained.

### Changed files, rollback, and updates

Ten game files changed: Group.lua; the two obsolete Cluster trial files; ConsolePort_Forever.lua; the PS5 source generator; the core binding-icon source; account ConsolePort and Immersion SavedVariables; and the account/template binding caches. Exact relative paths and original hashes are in the [backup manifest](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/manifest.json>). Originals are under the sibling `before` directory; documentation originals are under `before-docs`.

To undo this run while WoW is closed:

```powershell
python "C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\ConsolePort-Polish-2026-09-27\deploy.py" --rollback
```

The rollback script refuses to overwrite files that changed after deployment (including normal post-login SavedVariables rewrites or addon updates). If it refuses, compare the relevant original in `before` and restore only the intended settings/source portions. There is no need to restore the entire WTF directory. The unchanged approved bar-layout file is not part of rollback.

**Addon-update overwrite risk:** updates to ConsolePort/ConsolePort_Bar can replace the Group skin, PS5 generator, icon fallback, and retired Cluster trial files. The separate Forever helper and SavedVariables normally survive an upstream update; a device-version migration can replace a saved generator, while the separate Forever Controller preset should remain. Preserve this patch/evidence and recheck the new factory/template path after an update. Do not blindly copy an old full addon file over a newer version. A changed Retail frame name or anchor API can also require revisiting the helper.

### One consolidated login check

In one session, compare with screenshots 1000102993 and 1000102996:

1. Check all four banks: 16 circular face slots, 16 square D-pad slots; populated and empty appearances; hover/pressed/checked/cooldown/proc states when available. The bank geometry, scaling, unit frames and hidden toolbar should match the approved baseline.
2. Cast or use an ordinary progress action, then `/reload` and open/close Edit Mode: the same-sized bar should remain centered immediately above the base bank. Check for any Lua/blocked-action errors during this session.
3. Test left `PADBACK` for the radial menu and right `PADSYSTEM` for the world map with neither trigger, L2, R2, and both held. Confirm L2+R2+D-pad Up has the LiteMount icon and invokes LiteMount; confirm the same preset on another existing character when convenient.
4. Open simple NPC dialogue and dialogue with rewards/requirements: the talk box should rest centered at the lower position, move upward only as needed, then return. Scale, ExtraFade and the separate title/choice panel should retain the user's choices.

This is the sole remaining consolidated visual/runtime check; the automation is disabled and will not keep retrying.

## User follow-up and scheduled refinements — 2026-09-27

The user confirms the circles work in screenshot 1000103002. Immersion's bottom anchoring appears correct, and the cast bar's horizontal placement is approved. The user manually lowered Immersion further; that current vertical placement supersedes the earlier fixed Y=150.

The requested next pass is documented in [ConsolePort-Refinements-2026-09-27-Handoff.md](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Refinements-2026-09-27-Handoff.md>): identify/move the apparent player buffs to the right of the health frame; correct any new Immersion horizontal drift while preserving the new Y; separate square/circular crosses by roughly half a square in all banks; add green friendly/red enemy L1/R1 targeting prompts from the Forever reference; locate the exact four base-action images; correct physical LEFT-of-trackpad to WORLD MAP and RIGHT to MAIN RADIAL MENU; and raise the cast bar only a couple of pixels.

**The newest physical left-map/right-menu request supersedes the opposite mapping in the earlier sections.** Both physical buttons currently open the radial menu according to the user. Trace actual input IDs/overrides, including PADFORWARD; do not rely on the earlier PADBACK/PADSYSTEM assumption.

The user requested implementation in this same chat after the next usage reset. The observed reset is September 27 at 04:25:05 America/Toronto; the requested one-time continuation is 04:30:05, five minutes later. The original standalone automation remains paused. Only request documentation and scheduling were performed in this follow-up turn; game files were not changed.

Scheduling receipt: heartbeat `refine-consoleport-after-usage-reset` was created ACTIVE with one occurrence, targeting this existing chat (`01a0e0e4-ce9d-7851-8b83-70caa8d587be`). The saved schedule and target were verified. Pause the heartbeat after its continuation run.

## Scheduled refinement implementation — 2026-09-27

The seven authorized refinements are installed. WoW was confirmed closed before SavedVariables and binding caches were written. Fresh rollback material, the readable patch, source evidence, deterministic tests, and installation receipts are in [ConsolePort-Refinements-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Refinements-2026-09-27>).

### Player auras

The hovered **Illidari Reinforcements** item is a player aura, not a totem or the tooltip itself. Retail's `AuraButtonMixin:OnEnter` supplies exactly that tooltip through `SetUnitAura` for `PlayerFrame.unit`; `BuffFrame.AuraContainer` owns the corresponding icon layout. The initial scheduled pass anchored the native `BuffFrame` to the health frame's right. The post-login correction below supersedes that side: it is now anchored 12 UI units left of the complete `PlayerFrame` and forced to grow farther left, preserving icon size, padding, duration, consolidation, sorting and the user's health-frame position. The anchor follows the aura frame's native up/down wrap choice and is restored after native anchor, grid, Edit Mode and OnShow writes, with combat deferral and late-addon-load recovery.

### Immersion

The current post-login values proved that the user moved the talk box to **Y=39.27963256835938** and introduced a small horizontal offset of **X=7.797380447387695**. Only X changed, to **0**. The new Y, Bottom anchor, scale 1.2, title offsets, title/choice panel, element scale, animation divisor and all ExtraFade settings remain byte-for-byte unchanged. The native extra-offset harness now checks reward/objective rises of 132 and 148 units from the new base Y and a return to that same base.

### Action-bank gap

Each bank remains at its approved center, Y position, 94%/106% scale, visibility and opacity. The bank container widened from 250 to **277.5 UI units**. Because the bank is center-anchored, this shifts the D-pad cross 13.75 units left in screen space; the four face-button X positions also increased by 27.5 inside the wider bank, shifting that cross 13.75 right. Internal 45-unit cross spacing is unchanged. The resulting frame-edge gap is exactly **22.5 UI units**, or 21.15/23.85 screen units at the inactive/active scale. All four banks use the same geometry; the round face skin and square D-pad path remain unchanged.

### Forever targeting prompts and base-action art

The source of truth is Blizzard's Forever **1.60.1.70009** `Blizzard_GamepadActionBars/MainActionBarFrame.lua` and its atlas DB2 records. The helper adds two passive, mouse-disabled children around the base bank: the original green friendly and red hostile symbols with their original left/right shoulder backgrounds, plus ConsolePort's matching PlayStation L1/R1 glyphs. After visual approval, both prompt anchors were lowered 48 local UI units, from y=16 to y=-32, placing them beside the base controls as marked in screenshot 1000103018. They inherit the bank's scale, opacity and visibility and introduce no bindings. Existing mappings remain L1 `TARGETNEARESTFRIEND` and R1 `TARGETSCANENEMY` in every configured modifier state.

The four Base face slots use the same actions and artwork logic as Forever: Cross uses the original `gamepad-ability-icon-jump` atlas member extracted from Forever's FileDataID 6227336; Circle uses Retail's matching `128-redbutton-exit`; Square uses auto-attack spell texture 6603, which is Forever's no-target interact/attack state; Triangle uses Retail's matching `crosshair_inspect_32` / `crosshair_unableinspect_32` according to target presence. The artwork applies only while the corresponding base binding remains JUMP, empty contextual back, INTERACTTARGET or TURNORACTION. Modifier layers retain their native dynamic ability icons, and the empty Circle slot remains unbound globally. Hashes and exact atlas coordinates are recorded in [art-provenance.json](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Refinements-2026-09-27/evidence/art-provenance.json>).

### Physical map/menu split

The prior implementation changed PADSYSTEM, but ConsolePort's PlayStation metadata identifies it as a separate center control. The layout identifies the left trackpad-side button as **PADBACK** and the right as **PADFORWARD**; upstream SDL's DualSense driver likewise emits Back and Start as distinct buttons, while the PlayStation guide button is separate. This explains the observed behavior: the stable preset still had both PADBACK and PADFORWARD bound to the menu.

The installed result is:

| Physical control | ConsolePort ID | No modifier, L2, R2, L2+R2 |
|---|---|---|
| Left of trackpad | PADBACK | `TOGGLEWORLDMAP` |
| Right of trackpad | PADFORWARD | `CLICK ConsolePortMenuTrigger:LeftButton` |
| Separate system button | PADSYSTEM | Existing `TOGGLEWORLDMAP` retained |

The first two rows are identical in the stable Forever Controller preset, all four character snapshots, active saved PS5 generator, PS5 source generator, account binding cache and shared-template binding cache. The account's automatic stable-preset loader remains enabled. Every other binding is preserved, including empty base PAD2 and `CTRL-SHIFT-PADDUP` LiteMount with icon 132247.

### Cast bar

The accepted anchor and X position remain unchanged. The helper now adds **five physical screen pixels** to the previous 12-unit gap by dividing five by the cast frame's effective scale. This is three pixels above the visually tested two-pixel state. Size, effective scale, skin, look, strata, UIParent ownership, combat deferral and reload/Edit Mode restoration remain unchanged.

### Validation and preservation

- Six installed Lua/SavedVariable sources parse with luaparse in Lua 5.1 mode.
- AST comparisons permit only 36 PADBACK/PADFORWARD edits across five presets/snapshots and the saved generator, eight source-generator edits, the single Immersion X edit, and exactly 20 layout edits: four widths plus 16 face X positions.
- The actual installed ConsolePort local action-button library, ProxyButton and Group factories run in the focused Fengari harness. It retains the previously verified 16 round face / 16 square D-pad split, both Masque load orders and rebuilds, and 48 populated/custom/empty LAB updates. New checks cover base art after LAB/native refreshes, untouched modifier art, empty PAD2, and target-sensitive Triangle art.
- Login/reload frame mocks exercise native cast/buff reattachments, Edit Mode and grid writes, aura wrap direction, combat deferral, late BuffFrame creation, two noninteractive prompt children, and unchanged player/target positions.
- Ten installed files match their tested hashes. **7,263** unrelated paths, all **41** addon folders and **42** shared character junctions passed the final audit. WoW's documented reference-only `WTF/GamePadConfig_Default.json` was regenerated during the runtime attempt; its exact before/after hashes are separately recorded and no custom mapper file was introduced.

### Runtime limit and one consolidated login check

An unattended client launch was attempted after installation. The client exposed no targetable window and exited before character/login inspection. The crash was `0xC0000374 HEAP_CORRUPTION`; its stack includes `RzChromaSDK64.dll` and `RzChromatic64.dll`. An earlier September 26 crash has the same signature and Razer DLL stack, so the evidence does not attribute this startup failure to the Lua changes. No further launch attempts will be made. The raw summary is in [runtime-inspection.txt](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Refinements-2026-09-27/evidence/runtime-inspection.txt>).

At the next normal user login, one check covers all unverified runtime pixels and hardware input:

1. Confirm the aura row appears beyond the portrait at the outer left of the complete player frame and grows farther left; hover an aura to confirm its tooltip follows the icon and that no aura covers the health frame.
2. Confirm the four bank centers are unchanged, with about half a button of air between each square and round cross. Check the exact Base jump/cancel/interact/inspect symbols and the green L1 / red R1 prompts above the HUD.
3. Press left of the trackpad for the map and right for the main radial menu with no trigger, L2, R2 and both triggers. Confirm L2+R2+D-pad Up still mounts through LiteMount.
4. Cast once: the bar should remain centered and sit five physical screen pixels above the original approved anchor. Open a normal Immersion conversation and one with rewards/objectives: the box should rest at the user's lower Y, centered at X=0, rise natively, and return; the title/choice panel and ExtraFade should remain as chosen.
5. Check for Lua or blocked-action errors, then `/reload` and briefly enter/leave Edit Mode to confirm the cast and aura anchors restore.

### Rollback and update risk

With WoW closed, run:

```powershell
python "C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\ConsolePort-Refinements-2026-09-27\deploy.py" --rollback
```

Rollback restores the eight pre-refinement targets and removes the two locally added original-art sheets. It refuses if any installed target changed afterward, so it will not overwrite normal SavedVariable rewrites or addon updates silently. ConsolePort/ConsolePort_Bar updates can overwrite Group.lua, the PlayStation generator, and saved generator migrations; they can also change factory or binding paths that require retracing. The separate local Forever helper/assets are less likely to be overwritten but must be rechecked against changed Blizzard/ConsolePort APIs. Restore individual settings from `before` after an update instead of copying entire old addon files over new versions.

The one-time continuation `refine-consoleport-after-usage-reset` was deleted after this completed run, so it cannot run again. The original `fix-consoleport-circular-buttons` automation remains paused.

## Post-login visual approval corrections — 2026-09-27

Screenshots 1000103017 and 1000103018 confirm that the Forever base artwork, green/red L1/R1 artwork, cross spacing, Immersion placement and left-trackpad world-map behavior are approved. Those items were preserved exactly.

Three source-only adjustments were made with WoW closed:

- The centered cast bar moved three additional physical pixels upward, for **five total physical pixels** above the original approved 12-unit anchor. Its X position, size, scale, look, skin and persistence hooks are unchanged.
- The friendly/hostile targeting prompt pair moved from local y=16 to **y=-32**, a 48-unit downward shift that places it beside the upper base controls shown by the user's annotations. Prompt X positions, size, artwork, L1/R1 glyphs, inherited bank visibility/scale/alpha and bindings are unchanged.
- Player `BuffFrame` auras now anchor **12 UI units to the left** of the complete player frame, beyond the portrait. `addIconsToRight=false` forces additional icons to expand leftward, away from the health bar. Native sorting, wrap direction, grid updates and the existing login/reload/Edit Mode/combat restoration remain active.

The refreshed staged and installed harness passes Lua 5.1 parsing plus login/reload, native reanchor, Edit Mode, combat deferral and late-load simulations. It asserts the effective-scale cast calculation, both y=-32 prompts, right-edge aura anchoring to the health frame's left edge, and leftward aura growth. The installed ten-file state matches the exact semantically validated live hashes. The earlier whole-tree audit is retained as the pre-login baseline; it was not falsely replayed after the user's normal test session rewrote mutable WoW files such as `WTF/Config.wtf`. No game launch was attempted by Codex during this follow-up.

A focused pre-follow-up snapshot and hash-guarded rollback are in [ConsolePort-Followup-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Followup-2026-09-27>). With WoW closed, `python rollback.py` there restores only the prior helper state. The original full rollback package was also refreshed to recognize this tested final helper.

One normal user login check remains for these three adjusted pixels/anchors: confirm the cast bar's five-pixel clearance, the lowered prompt row, and player auras appearing beyond the portrait at the outer left edge and continuing left as more auras are added.

## Aura outer-edge correction — 2026-09-27

Screenshot 1000103019 showed that anchoring to `HealthBarsContainer` placed the first aura left of the green health bar but still over the player portrait. The aura row now anchors its right edge to the **outer left edge of the complete `PlayerFrame`**, with the same 12-unit gap. Native vertical wrap selection is retained and `addIconsToRight=false` continues to grow additional icons leftward. This changes only the relative anchor frame; the player frame, aura size, sorting, other approved HUD positions and all previous approvals remain unchanged.

WoW was closed for the source edit and was not launched by Codex. Staged and live validation passed, including login/reload, grid rewrite, Edit Mode, combat-deferral and late-load simulations. Exact evidence and a hash-guarded rollback to the immediately prior anchor are in [ConsolePort-Aura-Left-Followup-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Aura-Left-Followup-2026-09-27>).

## Proactive collision audit staged — usage handoff, 2026-09-27

Screenshot `1000103020.jpg` proves the remaining icon over the player health bars is `DebuffFrame`, a separate Retail Edit Mode aura system from the already corrected `BuffFrame`. Blizzard's matching source gives both frames distinct system indices and anchors; moving only the buff system could never move the harmful-aura layer.

A broader controller-aware layout policy is staged in [UI-Layout-Audit-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27>). Buffs now begin beyond the full player-frame left edge, grow left and wrap down. Debuffs attach below the changing buff-container bottom edge, grow left and wrap down. Target auras are directed above the approved low target frame. The policy protects the approved action bars, cast bar, player/target positions, chat, minimap, objective tracker, hidden micro menu/bags and all non-Edit Mode addon state. Every other registered Edit Mode system receives Blizzard's shipped Modern record at runtime, with a separate transient center rail for systems whose stock action-bar anchor would collide with ConsolePort. The serialized RealUI layouts remain untouched.

The staged helper and Lua harness parse in Lua 5.1 mode. The frame/Edit Mode harness and a conservative 1920x1080 expansion model both pass, including 32 buffs, 16 debuffs, protected-frame invariants, Edit Mode recovery, late registration and combat deferral. Staged SHA-256 is `589630C9A455DE87E13B8D8B32ADE1ADFAD9317D8DD5FBE41B84B40CE1A2A551`; live remains the pre-task `B77AD851A602CF1230A96724B043D1127B322F72A938EBB9F3AA90E356D1F6CB`.

No live file or SavedVariable was changed in this partial run. At exactly 90% five-hour usage, deployment stopped and a complete continuation handoff was written to [HANDOFF.md](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/HANDOFF.md>). The same-chat heartbeat `finish-proactive-wow-ui-collision-audit` is ACTIVE for 2026-09-27 16:23:09 America/Toronto, five minutes after the reported reset. It must finish hash-guarded deploy/rollback, installed validation, final documentation, and then delete itself. Codex will not launch WoW; normal-login visual coverage remains the final acceptance step.

### Deferred public-addon direction

The user identified a potential final evolution: consolidate the personal prototype into a distributable companion addon that can produce an adaptive Forever-inspired interface through a one-time setup action. This is documented in [ConsolePort-Forever-Public-Addon-Roadmap.md](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Public-Addon-Roadmap.md>). It covers eliminating direct dependency edits, generated Blizzard/ConsolePort profiles, adaptive collision-aware layout, controller glyph and binding choices, optional Immersion/LiteMount integration, backup/restore/uninstall, asset and naming review, compatibility tests, diagnostics, and publication packaging.

This is a deferred idea, not part of the active collision-audit scope. The scheduled continuation must complete the current personal UI work before any productization begins.

## Proactive collision policy installed — 2026-09-27

The scheduled continuation completed the proactive layout pass. WoW was closed at the final write and was never launched or terminated. Deployment changed exactly one file, the local [ConsolePort_Forever.lua](<C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua>). SavedVariables, Edit Mode caches, ConsolePort bindings and presets, Immersion, DynamicCam, LiteMount, action-bank definitions, artwork, and all other addon files were untouched.

### Independent harmful-aura cause and final lane

Retail implements `BuffFrame` and `DebuffFrame` as distinct `Enum.EditModeSystem.AuraFrame` entries. Each receives its own saved anchor and can be restored independently by Edit Mode. The earlier helper owned only `BuffFrame`, explaining the exact screenshot result: the beneficial aura moved left while the harmful aura remained over the health bars.

The final helper treats the two native systems as a coordinated lane without replacing their buttons, sorting, timers, tooltips, dispel treatment, private-aura anchors, icon sizing, or consolidation behavior:

- `BuffFrame TOPRIGHT` anchors to `PlayerFrame TOPLEFT` at `(-12, 5)`.
- `DebuffFrame TOPRIGHT` anchors to `BuffFrame BOTTOMRIGHT` at `(0, -6)`.
- Both containers grow left and wrap down.
- Because debuffs are relative to the buff frame's changing bottom edge, one or several buff rows push harmful auras downward while keeping both groups entirely outside the player frame.
- Size, grid, Edit Mode, OnShow and anchor writes queue a guarded repair; combat defers it to `PLAYER_REGEN_ENABLED`.

The target unit frame remains at its approved `(310, -175)` center offset. Its attached aura container is explicitly configured and reanchored above the frame, preventing target buffs/debuffs from growing into the controller banks. The player frame remains at `(-310, -175)`.

### Modern baseline and protected systems

The source baseline is Blizzard Retail commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`, including `BuffFrame.xml`, `BuffFrame.lua`, `EditModePresetLayouts.lua`, `EditModeManager.lua`, `EditModeSystemTemplates.lua`, and `TargetFrame.lua`. The installed helper obtains deep copies of Blizzard's current runtime Modern system records instead of embedding a stale copy of the complete preset.

These approved systems are excluded from the Modern reset policy: all Blizzard action bars, player cast bar, player and target frames, chat, minimap, objective tracker, micro menu, and bags. The helper continues their already approved behavior, including the hidden menu/bag strip. ConsolePort's four banks, their scale and centers, circular/square split, artwork, targeting prompts, controller mappings and the five-pixel cast-bar clearance are unchanged.

All other registered Edit Mode systems receive Blizzard's Modern position and settings. This covers late-loaded and newly registered focus, pet, party, raid, boss, arena, loot, durability, vehicle seat, warnings, timer, tooltip, personal-resource, encounter, damage-meter, status and other Retail systems. The policy reapplies after login/reload retries, late registration, Edit Mode exit, specialization changes, display changes, UI-scale changes and combat deferral. It does not write the serialized RealUI layouts; saving Edit Mode later can naturally capture the current visible arrangement.

### Controller-safe transient rail

Several stock Modern records deliberately use the bottom action-bar anchor, which conflicts with the ConsolePort HUD. Their Modern sizes, visibility and content settings remain intact, but their anchors use reserved transient lanes:

| System | Installed anchor relative to UIParent |
|---|---|
| Extra Abilities | `BOTTOM` to `CENTER`, `(0, -80)` |
| Vehicle Leave | `BOTTOM` to `CENTER`, `(92, -80)` |
| Encounter Bar | `BOTTOM` to `CENTER`, `(0, 0)` |
| Cooldown Utility | `BOTTOM` to `CENTER`, `(0, 55)` |
| Cooldown Essential | `BOTTOM` to `CENTER`, `(0, 110)` |
| Cooldown Buff Icon | `BOTTOM` to `CENTER`, `(0, 165)` |
| Cooldown Buff Bar | `BOTTOMRIGHT` to `CENTER`, `(-460, -40)` |
| Talking Head | `TOP` to `TOP`, `(-420, -220)` |
| Archaeology Bar | `TOP` to `TOP`, `(300, -225)` |

The conservative model reserves the full four-bank controller region, cast region, player/target frames and chat. It then models 32 buffs, 16 debuffs, target aura expansion, and transient boxes larger than the underlying Blizzard templates. No modeled expansion envelopes intersect.

### Validation and receipts

- The live helper and test harness parse in Lua 5.1 mode.
- The focused Fengari harness executes the installed helper through login retries and verifies the independent aura systems, dynamic buff-height following, left/down growth, explicit target-aura reanchor, protected-system exclusions, Modern updates, transient anchors, Edit Mode exit, late system registration and combat recovery.
- The installed SHA-256 `17766647CC94545DE3A17CD688495636138F4D0E7782AD46C3B36A06AA25A404` exactly matches the validated staged source.
- The pre-task backup SHA-256 is `B77AD851A602CF1230A96724B043D1127B322F72A938EBB9F3AA90E356D1F6CB`.
- Evidence and tools are in [UI-Layout-Audit-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27>): [manifest](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/manifest.json>), [source review](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/evidence/source-review.md>), [live validation](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/evidence/validation-live.txt>), [collision model](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/evidence/layout-collision-model.json>), [deployment receipt](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/evidence/deploy-receipt.json>) and [readable diff](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/UI-Layout-Audit-2026-09-27/changes.diff>).

### Rollback and update risk

With WoW closed, run:

```powershell
python "C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\UI-Layout-Audit-2026-09-27\rollback.py"
```

Rollback refuses while a WoW process is present, verifies the backup hash, and restores only the helper if the live file still matches this deployment. It refuses after an addon update or later manual edit rather than overwriting newer work. `deploy.py` provides the corresponding guarded reinstallation.

The local addon can be overwritten if an addon manager replaces the entire `ConsolePort_Forever` directory. Retail updates can rename Edit Mode systems or change frame mixins, while ConsolePort updates can change bank globals. Re-run syntax/source/harness checks after such updates. Do not copy the old helper over a newer incompatible API without review.

### One normal-login visual check

Offline validation proves the source paths, anchors, exclusions, recovery logic and conservative geometry. It cannot prove actual GPU pixels, secure/taint behavior or every situational frame in a running client. On the next normal user login, one check is sufficient:

1. Confirm buffs and harmful auras remain completely left of the player frame, with debuffs below the buff rows as either group expands.
2. Confirm target auras grow above the target frame; the approved four banks, cast bar, player/target health frames, chat, minimap and quests are unchanged.
3. When convenient, observe Extra Ability, Encounter Bar, Talking Head, Vehicle Leave, cooldown viewers, focus/group/boss/arena frames, loot, durability, warnings, tooltip and status bars in the contexts that make them appear.
4. Run `/reload`, enter and leave Edit Mode once, and check for Lua or blocked-action errors.

The public companion-addon direction remains documented separately in [ConsolePort-Forever-Public-Addon-Roadmap.md](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Public-Addon-Roadmap.md>) and was not started during this run.

The one-time heartbeat `finish-proactive-wow-ui-collision-audit` was deleted after completion, so it cannot run again. The older `fix-consoleport-circular-buttons` automation remains paused.

## Unit-frame secret-value taint correction — 2026-09-27

Runtime testing invalidated the unit-frame portion of the proactive collision policy. The first captured session contained 1,665 errors attributed to `ConsolePort_Forever`; its initiating stack entered `CompactPartyFrame:RefreshMembers` through the addon's `frame:UpdateSystem(info)` call. Protecting only player and target removed that path, but the next clean session still produced 785 errors in Blizzard's generic health updater. All were arithmetic/comparison failures on secret health values attributed to `ConsolePort_Forever`, with no active addon frame in the stack. This persistent pattern identified tainted state on the target frame rather than a transient callback.

The regression came from two additions in the collision pass: addon-driven `UpdateSystem` calls for non-player unit frames and the persistent `TargetFrame.buffsOnTop = true` write plus direct target aura refreshes. Blizzard's current target-frame source deliberately performs its health update before aura/configuration work to avoid taint. The correction therefore enforces a stricter boundary:

- every `Enum.EditModeSystem.UnitFrame` is excluded from addon-driven `UpdateSystem` calls;
- the addon writes no Lua fields on `PlayerFrame` or `TargetFrame`;
- the addon does not call target aura update/anchor methods;
- the addon installs no method or script hooks on player or target frames;
- the approved player and target coordinates remain `(-310, -175)` and `(310, -175)`, applied only through base region anchor methods outside combat.

The target aura direction is now owned by Blizzard's native saved Edit Mode setting. The addon no longer forces it, because forcing the Lua field is what contaminated later health updates. If the native layout has Buffs on Top disabled, it must be enabled once through Blizzard Edit Mode rather than by addon code.

The warning dialog's client-wide Disable AddOns action rewrote the shared `AddOns.txt`. The file was restored to exactly the 41 folders present in the curated live AddOns directory plus the two existing Blizzard entries; there are no missing, stale, or disabled custom entries. All character junctions resolve to that shared template.

Prevention was applied to the deployment artifacts as well as the live addon. The staged helper matches live hash `6B2B3FE9E60F6677F4D74F6FD83A696DECD4C2C9498FCBAB93C6036E4FDC0267`; the manifest, guarded deploy/rollback scripts, Fengari harness, and static policy were updated. Both live and staged harness runs pass and assert that all unit frames receive zero Modern updates, the target object receives no persistent writes or aura calls, target methods are not hooked, and the approved coordinates remain unchanged. Lua 5.1 parsing and the inventory/dependency-state checks also pass. The old `177666...` deployment and the prior claim that target auras were safely forced above the frame are superseded.

## Symmetric center-out spacing — 2026-09-27

Screenshot `1000103029.jpg` prompted a full horizontal re-evaluation. The crosses inside every bank were already centered around X=0, but the side banks at X=-280/+280 produced alternating inter-cluster gaps of 157.5 and 122.5 units. That compressed the inner side-bank gaps and made the otherwise symmetric L1/R1 row feel uneven.

The installed layout now uses a single 78.75-unit half-step from the centerline. The visible cluster centers are `-393.75, -236.25, -78.75, 78.75, 236.25, 393.75`, giving five identical 157.5-unit gaps. L1/R1 sit at `-157.5/+157.5`; L2/R2 bank centers and the player/target frames sit at `-315/+315`. The middle line remains exactly halfway between the central square and circular crosses. Vertical positions, 45-unit cross spacing, bank scale/opacity, actions, artwork, cast bar, aura rules, chat, minimap, objective tracker and transient rail are unchanged.

WoW was closed during the change. Both edited Lua files pass Lua 5.1 parsing. The focused frame harness passes login/retry, aura, Edit Mode, combat-deferral, prompt and unit-frame checks. The updated conservative 1920x1080 model reports no unexpected overlap among visible action art, unit frames, aura lanes, chat or managed transient systems. Backups, exact hashes, collision evidence and guarded rollback are in [ConsolePort-Centering-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Centering-2026-09-27>).

### Left-edge anchor correction

Screenshots `1000103032.jpg` and `1000103034.jpg` showed that L1/R1 and the unit frames were centered while the complete action-button panel remained right-shifted. The cause was an anchor-semantics error in the first center-out calculation: every 45-unit `GroupButton` uses `SetPoint('LEFT', ...)`, so its saved X coordinate is the button's left edge, not its center. Treating those values as centers displaced all 32 action buttons by half a button, exactly 22.5 UI units, while leaving their parent banks correctly centered.

All 32 child X anchors now move left by 22.5 units. The square and circle cross centers are therefore truly `-78.75/+78.75` inside every bank, with their gap midpoint at X=0. The corrected sequence remains `-393.75, -236.25, -78.75, 78.75, 236.25, 393.75`; L1/R1 at `-157.5/+157.5` are exactly 78.75 units from their nearest central cross and the nearest side-bank cross. Bank containers, player/target frames, cast bar and all vertical coordinates remain unchanged from the preceding pass. The manifest, guarded rollback and geometry validation were refreshed to the corrected installed hash.

## Edit Mode safety and narrower chat — 2026-09-27

Opening Edit Mode after the centering correction reproduced the secret-value failure. The freshly written client console proves the entry path: `EditModeManager:OnEditModeEnter` refreshed arena frames, then `CompactUnitFrame` rejected secret health-color, range, heal-prediction and max-health values because execution was tainted by `ConsolePort_Forever` (`Blizzard_Console.lua` lines 4162, 4166, 4170 and 4174).

The remaining source was the broad Modern-layout policy. Although its latest version excluded every unit-frame system, it still created replacement `systemInfo` tables and passed them to other registered frames through `UpdateSystem`. Blizzard stores those tables on its Edit Mode frames for later reuse, allowing addon taint to persist until the editor's unit-frame refresh. The entire policy is now removed: there is no registered-frame iteration, Modern-record copying, manager method hook, or addon-driven `UpdateSystem` call. The helper's isolated player/target, cast and aura positioning also returns immediately whenever `EditModeManagerFrame.editModeActive` is true. Native editor writes are therefore left untouched until the editor is inactive.

Chat width is reduced from 430 to **400 UI units**, while height remains 120. The native character chat cache and both account RealUI layout records carry the same 400x120 value, so opening or saving Edit Mode cannot restore the old width. With the chat's left edge unchanged, the conservative model leaves **95 UI units** between its right edge and the visible ConsolePort action HUD.

The live helper passes Lua 5.1 parsing. The focused harness proves zero `UpdateSystem` calls across protected, unit, aura and transient frames; no updates on late registration; complete suspension of unit/cast/aura rewrites while Edit Mode is active; post-exit restoration; and retained combat deferral. Static checks verify both native chat records, the cache terminator, and the absence of all taint-prone policy symbols. Evidence, before/after snapshots and guarded rollback are in [EditMode-Safety-Chat-2026-09-27](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/EditMode-Safety-Chat-2026-09-27>).
# Standalone addon migration — schema 1 (2026-09-27)

## First-login repair: controller and synchronous reload (version 1.1.1)

The first live attempt exposed two initialization constraints. Blizzard Edit Mode was not loaded when the original prompt appeared, and a reload deferred through `C_Timer` no longer retained the controller press's hardware-event authorization. Version 1.1.1 now loads Edit Mode and waits for a usable layout before showing the prompt. Cross/A invokes Install and Circle/B invokes Cancel; the button labels show both controller mappings. Installation, profile selection, binding save, and `ReloadUI()` then execute synchronously inside the accepted controller press.

The failed attempt was captured under `ConsolePort-Forever-Standalone-2026-09-27/failed-attempt-1`. With WoW closed, its account and character addon SavedVariables were removed from the live paths, and the pre-attempt Edit Mode cache, ConsolePort_Bar layout, and Immersion settings were restored byte-for-byte from the package backup. The next login is therefore a schema-1 clean install rather than an update.

An offline Lua harness now exercises the whole path: preload Blizzard Edit Mode, present a gamepad-enabled prompt, dispatch PAD1, save/select the named profile, install bar and Immersion data, record both schema scopes, and call reload synchronously. It passes, as do Lua parsing and the dependency-source restoration hashes. Runtime verification remains required because Retail's protected-action rules cannot be fully simulated offline; `ADDON_ACTION_BLOCKED` and `ADDON_ACTION_FORBIDDEN` are now captured into `/cpf status` if the client rejects another action.

`ConsolePort_Forever` is now version 1.1.0 and owns its install/update lifecycle. On first login (or a layout-schema increase) it shows **New interface to be installed**. Accepting the prompt, while out of combat, backs up the active Edit Mode layout, affected bindings/CVars, the current character's ConsolePort_Bar layout, and Immersion settings; creates or updates the account profile **Console Port - Forever**; installs the bundled **Forever: Expanded Crosses** bar layout; applies the approved Immersion geometry and trackpad bindings; then reloads the UI.

The taint boundary has changed materially. The addon no longer repositions Blizzard player, target, cast, aura, or chat frames at runtime and never sends addon-created `systemInfo` tables into live Edit Mode frames. It copies and patches layout data, then hands it to `C_EditMode.SaveLayouts`, allowing Blizzard to deserialize and own the profile. `/cpf status`, `/cpf install`, and `/cpf restore` provide diagnostics, explicit reinstallation, and conservative rollback.

The remaining round-button art and targeting prompts are implemented in `Skin.lua` and touch only ConsolePort-owned widgets. The approved action-bar layout is bundled in `Layout.lua`; no pre-edited WTF data is required for a new installation.

Direct source edits were removed from the dependencies. `ConsolePort_Bar/Widget/Group/Group.lua` and `ConsolePort/Model/Gamepad/PlayStation/PlayStation5.lua` exactly match their verified pre-prototype backups. Required dependencies are ConsolePort, ConsolePort_Bar, ConsolePort_Menu, and Immersion.

Validation completed offline: all three Lua files parse, the addon contains no live Edit Mode manager/frame mutation, chat width is 400, dependency source hashes match their backups, and WoW was closed during deployment. The remaining acceptance test is necessarily in game: accept the prompt, confirm the reload/profile, then open Edit Mode, move/save/revert a frame, and verify there is no secret-value error. The reversible package is `ConsolePort-Forever-Standalone-2026-09-27`.

## Schema 2 correction: combined Edit Mode indexing and restored presentation — 2026-09-27

The first successful schema-1 transaction installed the ConsolePort_Bar and Immersion data but did not activate the managed Blizzard profile. Screenshot `1000103044.jpg` showed the split: the four action banks were present, while Blizzard unit frames remained on an unrelated preset, the micro-menu/bag strip returned, Masque had restored square face buttons, and ConsolePort printed `No binding preset named Forever Controller exists.`

The Edit Mode root cause was an index-space error. `C_EditMode.GetLayouts().layouts` contains saved layouts only, but Blizzard's manager saves and activates a combined view: built-in presets followed by saved layouts. Schema 1 used the saved-list index directly, so it selected the wrong entry even though the named profile itself was correct. Schema 2 now preserves that complete managed profile, rebuilds the combined list for `SaveLayouts`, and activates `#presets + savedProfileIndex`. Clean accounts deserialize a bundled native export of the same approved profile; current Modern is only a compatibility fallback if a later client rejects that export. This retains the approved minimap, objectives, remaining Blizzard geometry, symmetric `-315/+315` frames, native cast/aura/chat changes, and unchanged ConsolePort layout.

The binding error was independent. The named preset was present in `ConsolePortShared`, but ConsolePort's conditional driver could evaluate `[] Forever Controller` before its Shared/Data table loaded. Schema 2 blanks that condition, registers the complete bundled preset in shared data, and applies every base/L2/R2/L2+R2 chord directly in the accepted controller hardware event. The old condition was also cleared offline with WoW closed so it cannot emit once before the update prompt.

The dependency source files remain stock. `Skin.lua` now removes only the companion's 16 face buttons from their existing Masque groups, then reapplies the round mask/ring; bank-rebuild and Masque-load post-hooks repeat the operation idempotently. `Runtime.lua` hides `MicroButtonAndBagsBar`, `MicroMenuContainer`, and `BagsBar` during play, restores their original shown state for `EditMode.Enter`, and hides them after `EditMode.Exit`. It never calls a Blizzard Edit Mode frame's `UpdateSystem` method.

The exact schema-1 installed result, SavedVariables, addon source, and screenshot are preserved under `ConsolePort-Forever-Standalone-2026-09-27/successful-install-1`. Offline validation now includes three executable Fengari harnesses:

- `installer_harness.lua` models two built-in presets plus saved layouts, retains an existing profile's unowned systems, tests a clean bundled-profile import before a character layout, selects the combined index, verifies symmetric anchors, installs the complete controller preset, reloads synchronously from PAD1, and proves a rejected Edit Mode save cannot partially change bars, Immersion, or bindings;
- `runtime_harness.lua` verifies menu hidden in play, restored in Edit Mode, and hidden again on exit;
- `skin_harness.lua` verifies Masque detachment, circular art, and recovery after Masque re-enrollment.

All three pass. All five addon Lua files parse, and the verified stock hashes remain `8C783C...` for ConsolePort_Bar's `Group.lua` and `8E259D...` for ConsolePort's `PlayStation5.lua`. Live verification is still required for rendered pixels and Retail protected-state behavior.
