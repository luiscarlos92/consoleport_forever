# ConsolePort and Immersion Final Polish — Autonomous Follow-up

> Superseded by the completed September 27 refinement pass. The current physical mapping is LEFT/PADBACK = world map and RIGHT/PADFORWARD = main radial menu; PADSYSTEM is a separate control. The user's newer Immersion Y=39.27963256835938 is authoritative. See the newest implementation-report section and do not replay this handoff.

## Primary objective

Make only the PAD1–PAD4 action-slot frames circular, matching the WoW Forever controller HUD as closely as ConsolePort permits. Preserve square D-pad slots. The user will not be present to test incremental changes, so investigate the actual runtime path thoroughly and verify as much as possible without user interaction.

## Additional requested finishing work

Complete these items in the same autonomous run after reading the newest sections of `ConsolePort-Forever-Implementation-Report.md`:

### Center the player cast/progress frame

The player casting/progress bar is currently attached above the player health frame. Resolve the active Retail global (`PlayerCastingBarFrame` or the current-version equivalent), detach it from the unit frame, and center it directly above the base/unmodified controller bank with a small gap. Preserve its current scale and appearance. Make the placement survive `PLAYER_ENTERING_WORLD`, reloads, and Edit Mode restoration, using the existing `ConsolePort_Forever` helper where appropriate. Do not move the approved player or target health frames.

### Split the DualSense trackpad-side buttons

- Left of trackpad, `PADBACK`: keep `CLICK ConsolePortMenuTrigger:LeftButton`.
- Right of trackpad, `PADSYSTEM`: change to `TOGGLEWORLDMAP`.

Apply the mapping consistently across modifier states. Update the stable `Forever Controller` preset, applicable current/snapshot binding tables, the account `bindings-cache.wtf`, and any durable generator or documentation source that actually exists. Do not change face, shoulder, trigger, stick, or D-pad gameplay bindings except for the separately requested LiteMount slot.

### Persist LiteMount and provide its icon

The live binding `CTRL-SHIFT-PADDUP = CLICK LM_B1:LeftButton` already works and corresponds to L2+R2+D-pad Up. It is missing from the stable `Forever Controller` preset. Add it to the durable preset and all required persistence copies so every character receives it. Add:

```lua
ConsolePortBindingIcons["CLICK LM_B1:LeftButton"] = 132247
```

Use LiteMount's static declared addon icon. Do not attempt a speculative dynamic chosen-mount icon unless the local LiteMount API provides a clearly supported, testable mechanism.

### Recenter and bottom-anchor Immersion correctly

Preserve the user's manually approved larger Immersion presentation and ExtraFade behavior. Current relevant values include `scale = 1.2`, `boxpoint = "Bottom"`, `boxoffsetX ≈ 12.37`, and `boxoffsetY ≈ 204.11`. Set the talk-box horizontal base offset to exactly zero and lower its resting Y position toward the native default of 150. Immersion already implements bottom anchoring and reward-sensitive upward movement through `TalkBox:SetExtraOffset()`; preserve that mechanism instead of reserving permanent blank space. Verify simple dialogue rests low while reward/objective dialogue moves upward. The title/choice panel is separately center-anchored; inspect it independently and do not blindly reset `titleoffset` or `titleoffsetY`.

## Approved baseline and non-regression rule

The approved controller-HUD state is screenshot `1000102993.jpg` and the `Approved baseline — 2026-09-26` section of `ConsolePort-Forever-Implementation-Report.md`. Screenshot `1000102996.jpg` and the report's newest section define the additional requested exceptions. Do not change action-bank geometry, scale, opacity, unit-frame positions, UI scale, chat, DynamicCam, addon inventory, or toolbar/menu hiding. Preserve the user's larger Immersion scale and ExtraFade choices. Before editing SavedVariables or binding caches, confirm WoW is closed.

## Current relevant files

- `_retail_/Interface/AddOns/ConsolePort_Bar/Widget/Cluster/Cluster.lua`
- `_retail_/Interface/AddOns/ConsolePort_Bar/Widget/Cluster/Skins.lua`
- `_retail_/Interface/AddOns/ConsolePort_Bar/Model/Database.lua`
- `_retail_/Interface/AddOns/ConsolePort_Bar/Widget/Cluster/Cluster.xml` if present
- `_retail_/Interface/AddOns/ConsolePort/Assets/Textures/Cursor/RoundBorder.blp`
- `_retail_/Interface/AddOns/ConsolePort/Assets/Textures/Cursor/RoundBorderHighlight.blp`
- `_retail_/WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua`
- `ConsolePort-Forever-Implementation-Report.md`

## Failed approaches already present

1. A custom helper attempted to discover generated face-button frames after login and restyle them. It did not affect the visible slots.
2. `Skins.lua` attempted to infer PAD1–PAD4 from fields available in the skin callback. It did not affect the visible slots.
3. `Cluster.lua` now tags unmodified PAD1–PAD4 buttons at factory creation using `button.isForeverFaceButton`, while `Skins.lua` applies a circle mask plus `RoundBorder`/`RoundBorderHighlight`. All edited Lua parses, but screenshot `1000102991.jpg` proves the visible frames remained square.

Do not stack another guess on these attempts. Establish why the visible texture is square after those functions execute. Trace button construction, `OnLoad`, `Skin`, reskin callbacks, Masque/skin-prevention behavior, modifier-group rendering, and any later texture reassignment. Determine whether the visible square belongs to the LibActionButton border, slot background, icon mask, hotkey overlay, empty-slot texture, or another frame.

## Investigation and verification requirements

1. Read the complete relevant ConsolePort/ConsolePort_Bar source path before changing it.
2. Identify the runtime frame/template and final writer of every visible layer for a populated PAD face slot and an empty PAD face slot.
3. Compare that path with a D-pad slot and explain the exact divergence the fix will introduce.
4. Prefer a small, deterministic source patch or a narrowly scoped helper hook. Avoid SavedVariables-only guesses.
5. Test syntax for every edited Lua file with `luaparse`.
6. Add an offline verification mechanism where practical: a focused Lua mock/harness, deterministic source assertion, or diagnostic instrumentation whose output proves PAD1–PAD4 reach the circular branch and D-pad buttons do not.
7. If safe unattended runtime testing is possible with the existing local installation and session, use it; do not require the user to make repeated small tests. Do not change account credentials, characters, gameplay state, or the approved UI configuration.
8. If visual runtime confirmation cannot be obtained autonomously, stop after one evidence-backed implementation, document precisely what was and was not verified, and leave the user one consolidated login check—not a series of speculative trials.
9. Update `ConsolePort-Forever-Implementation-Report.md` with the cause, patch, tests, update-overwrite risk, and rollback instructions.

## Acceptance criteria

- PAD1, PAD2, PAD3, and PAD4 visible action slots are circular in all four persistent banks.
- D-pad action slots remain square.
- Populated icons, empty slots, cooldown swipes, highlights, pushed states, and checked/proc presentation remain visually coherent.
- No approved-baseline position, scale, visibility, binding, or behavior changes.
- No Lua errors and no new addon conflicts.
- Player cast/progress frame is centered just above the base bank without moving either health frame.
- DualSense left trackpad-side button opens the radial menu; the right one opens the world map.
- L2+R2+D-pad Up invokes LiteMount with a visible static LiteMount icon on every character.
- Immersion simple dialogue rests lower and horizontally centered; reward/objective content uses native upward displacement without permanent reserved empty space.


## Disposition — final polish run

Implemented and offline-validated at 2026-09-27T03:48:05+00:00. The active slots were GroupButtons; the obsolete Cluster-only trial was removed. All five scoped changes are installed. Automation `fix-consoleport-circular-buttons` is PAUSED. See [the final implementation report](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Implementation-Report.md>) for the proven results, rollback, update risk, and the one consolidated visual/runtime check. The historical failed-approach list above describes the pre-run state.
