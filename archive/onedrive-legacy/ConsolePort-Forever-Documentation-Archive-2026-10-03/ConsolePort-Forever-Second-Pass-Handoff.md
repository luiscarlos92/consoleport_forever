# ConsolePort / Forever offline cleanup — second-pass handoff

Updated: 2026-09-26 17:18 America/Toronto

## Why this handoff exists

The five-hour Codex allowance reached 92% used (8% remaining). Per the user's rule, a one-shot same-thread heartbeat named `resume-consoleport-offline-cleanup` was scheduled for 2026-09-26 at 18:23:29 America/Toronto, five minutes after the 18:18:29 reset. Do not spend this remaining window on partial configuration edits.

## User's current request

WoW is logged out. Fix everything possible offline so that the next login is clean and close to the World of Warcraft Forever controller presentation. Then report only the items that genuinely require the user to do something in-game.

## What the screenshot showed

- ConsolePort loaded successfully.
- Blizzard action bars still occupied the center and right edge.
- ConsolePort's Crossbar: Triggers layout was too small and showed unwanted empty trigger boxes.
- BetterBags printed `BetterBags: Masque integration enabled.`; this was informational, not an error.

## Second-pass edits already made

1. `_retail_/WTF/Config.wtf`
   - `SET alwaysShowActionBars "0"`
   - added `SET synchronizeBindings "0"`
   - added `SET synchronizeConfig "0"`

2. `_retail_/Interface/AddOns/ConsolePort_Bar/Controller/Blizzard/Mainline.lua`
   - Enabled ConsolePort's force-hide entries for `MultiBarLeft`, `MultiBarRight`, `MultiBar5`, `MultiBar6`, and `MultiBar7`.
   - `MainActionBar`, `MultiBarBottomLeft`, and `MultiBarBottomRight` were already hidden.
   - This is a local addon source patch and can be overwritten by a ConsolePort update.

3. `_retail_/Interface/AddOns/BetterBags/integrations/masque.lua`
   - Removed only the unconditional login-time chat print from the Masque integration.
   - The integration itself remains enabled.

4. `_retail_/WTF/Account/_template_/SavedVariables/ConsolePort_Bar.lua`
   - Replaced the prior trigger-heavy preset with `Forever: Compact`.
   - One active eight-button group: four face buttons plus four D-pad buttons.
   - Modifier paging order is base, `M2M1`, `M2`, `M1`.
   - Crossbar scale 135%, centered at y=75.
   - Only L1/R1 targeting prompts remain above it; empty L2/R2 trigger boxes are gone.
   - Toolbar, pet ring, and vehicle controls were retained and repositioned/scaled.

5. `_retail_/WTF/Account/_template_/SavedVariables/ConsolePort.lua`
   - The profiles `Fëlagund (Arcane) Grim Batol` and `Fëlagund (Arcane) Proudmoore` were normalized to the intended bindings.
   - The third profile, `Fëlagund (Arcanes) Grim Batol`, still needs the same normalization.
   - The active PlayStation 5 device generator still needs its modifier-layer mappings normalized so future profiles inherit the layout.

## Exact intended binding layout

Base:

- PAD1: JUMP
- PAD2: no global world binding; Immersion and ConsolePort handle it contextually as Back/Goodbye
- PAD3: INTERACTTARGET
- PAD4: TURNORACTION
- D-pad left/up/right/down: ACTIONBUTTON9/10/11/12
- L1 in every state: TARGETNEARESTFRIEND
- R1 in every state: TARGETSCANENEMY
- L2 and R2 in every state: empty; they act only as modifiers
- L3: TOGGLEAUTORUN
- R3: TOGGLEPINGLISTENER
- PADSYSTEM: `CLICK ConsolePortMenuTrigger:LeftButton`
- PADFORWARD: TOGGLEWORLDMAP
- PADSOCIAL: OPENALLBAGS

Modifier layers:

- SHIFT / L2: face buttons ACTIONBUTTON1–4; D-pad ACTIONBUTTON5–8
- CTRL / R2: face buttons MULTIACTIONBAR1BUTTON1–4; D-pad MULTIACTIONBAR1BUTTON5–8
- CTRL-SHIFT / L2+R2: face buttons MULTIACTIONBAR2BUTTON1–4; D-pad MULTIACTIONBAR2BUTTON5–8

## Remaining work after reset

1. Confirm no WoW process is running before writing.
2. Inspect and normalize the third `Fëlagund (Arcanes) Grim Batol` profile to the exact mapping above.
3. Normalize the `ConsolePortDevices["PlayStation 5"].Generator` binding layers and PADSYSTEM action to the same layout for future profiles.
4. Validate Lua syntax with `npx --yes luaparse@0.3.1` for:
   - `ConsolePort.lua`
   - `ConsolePort_Bar.lua`
   - `DynamicCam.lua`
   - `ConsolePort_Bar/Controller/Blizzard/Mainline.lua`
   - `BetterBags/integrations/masque.lua`
5. Check `Config.wtf` has one effective value for each edited CVar and that all expected gamepad CVars remain intact.
6. Programmatically verify all three character profile segments and the PS5 generator against the intended binding invariants.
7. Verify `Forever: Compact` contains eight Crossbar buttons, two Targeting buttons, and no L2/R2 trigger prompt buttons.
8. Update `ConsolePort-Forever-Implementation-Report.md` and, if needed, the configuration plan with a dated second-pass addendum.
9. Recheck usage. If again near 10% remaining, retarget this same heartbeat to five minutes after the next reset and refresh this handoff.
10. When complete, delete the heartbeat so it does not recur.

## Expected unavoidable in-game work

- The user must assign or rearrange actual spells/abilities in the three action layers; action-slot contents are character/server state and cannot be inferred safely offline.
- Blizzard Edit Mode cloud layout may still need a one-time save/selection if the user wants Blizzard-owned unit frames moved beyond what the local force-hide patch handles.
- Re-entering the world is required to confirm the exact visual fit at the TV's UI scale and to catch any runtime-only addon errors.

## Safety notes

- Do not delete SavedVariables for removed addons.
- Do not edit while WoW is running.
- Use `apply_patch` for edits.
- Preserve unrelated user changes.
