# Make Retail ConsolePort resemble the WoW Forever controller UI

Status: **offline implementation complete — first-login runtime validation remains**  
Prepared: 2026-09-25  
Final consistency review: 2026-09-26, including retained-add-on interaction review and DynamicCam design  
Target: World of Warcraft Retail with ConsolePort 3.2.6, primarily a PS5 controller

> September 27 follow-up installed: the circles are user-confirmed. Each bank now has a half-square gap between its crosses; authentic Forever base art and L1/R1 targeting prompts are installed. LEFT of trackpad is **PADBACK → world map**, RIGHT is **PADFORWARD → main radial menu**. PADSYSTEM is the separate system button and retains its existing map binding. Immersion rests at the user's newer Y=39.27963256835938 with X=0. See the newest implementation-report section for validation and the single pending login check.

## Bottom line

The investigation initially identified ConsolePort's built-in **Crossbar: Triggers** layout as the closest shipped starting point. A compact custom pass proved the layer behavior, but later user-provided Forever references established that the desired target is the full expanded HUD. The implemented target is now **Forever: Expanded Crosses**: four persistent banks for base, L2/LT, R2/RT, and both-trigger states. Each bank contains two adjacent crosses—a D-pad cross and a PlayStation face-button cross—with the active bank enlarged and brightened while the others remain visible and dim.

> Final visual revision, 2026-09-26: references below to `Crossbar: Triggers` and compact mode describe earlier research stages. The installed target is `Forever: Expanded Crosses`, based directly on the supplied full-HUD Forever references and corrected after runtime screenshot comparison.

This can reproduce the important *control grammar*:

- eight directional/face inputs;
- an L2 layer, an R2 layer, and an L2+R2 layer;
- a crossbar-shaped HUD;
- bumper targeting;
- nearby-interact prompts;
- controller navigation and radial menus.

It cannot be pixel-identical or behavior-identical. Forever's controller UI is native Blizzard code with its own artwork, context-sensitive face buttons, party-target overlay, focus navigation, input legend, three-arrangement page system, and tap/hold rules. ConsolePort can approximate those concepts but cannot add every native Forever widget through configuration alone.

No verified ready-made Forever-style ConsolePort profile was found as of 2026-09-25. The ConsolePort repository has an open [Forever support request](https://github.com/seblindfors/ConsolePort/issues/227), with no assignee, maintainer response, linked branch, or pull request. The current [CurseForge release](https://www.curseforge.com/wow/addons/console-port) lists Retail and several Classic flavors but not Forever. A player asking for this exact kind of [matching ConsolePort setup](https://www.reddit.com/r/wownoob/comments/1wma74r/wow_forever_gamepad_settings_in_consoleport/) received a useful partial manual mapping—interact on X/Square, jump on A/Cross, friendly target on LB/L1, enemy target on RB/R1—but no importable profile and no solution for Forever's LB+RB utility layer. Searches of GitHub, CurseForge, Wago, Reddit, and general web results did not turn up a credible import string or profile.

## What was verified locally

### Folder and junction layout

Retail's live `Interface` and `WTF` directories under `C:\Program Files (x86)\World of Warcraft\_retail_` are NTFS junctions into the OneDrive copy in this directory. That means a change made through either path reaches the same files; it is not a second independent copy.

The account has 42 current character directories. Thirty-nine are junctions to the shared `_template_` character directory. Three are ordinary directories and therefore do not inherit the shared per-character ConsolePort files:

- `Proudmoore\Fëanturï`
- `Outland\Engwär`
- `Outland\Ganymëdë`

Each exception currently contains only `AddOns.txt`. The old character-link script deletes a character directory before creating its junction, so it should not be rerun blindly. A safe targeted repair is a prerequisite to a truly account-wide rollout; see **Prerequisite repair plan** below.

### ConsolePort data scope

| Scope | Important file/data | Consequence |
|---|---|---|
| Account-wide | `WTF\Account\119624169#1\SavedVariables\ConsolePort.lua` | Core settings, controller definitions, glyphs, and saved binding profiles affect the whole account. |
| Shared per-character | `WTF\Account\_template_\SavedVariables\ConsolePort_Bar.lua` | The 39 linked characters currently share one action-bar layout and bar settings. |
| Shared per-character | `_template_\SavedVariables\ConsolePort.lua`, `ConsolePort_Rings.lua`, `ConsolePort_Target.lua` | Character-scoped ConsolePort state is shared only for linked characters. |
| Game-wide | `WTF\Config.wtf` | Gamepad CVars such as modifiers, movement, and cursor clicks apply at the client level. |
| Server-side | Action slots and many spell placements | A local SavedVariables edit cannot reliably arrange every class spell; spell placement must be checked in game. |

The installed ConsolePort suite is version 3.2.6 and includes Core, Bar, Config, Cursor, Keyboard, Menu, Rings, Target, and World modules. The PS5 device definition is active.

### Current settings that materially differ from the target

| Area | Current state | Proposed direction |
|---|---|---|
| Bar layout | ConsolePort `Default` cluster | Use custom **Forever: Expanded**, derived from the built-in crossbar geometry and supplied Forever references. |
| Modifiers | Shift = L1; Ctrl = L2 | Shift/M1 = L2; Ctrl/M2 = R2; no Alt/M3. |
| Bumpers | L1 consumed as a modifier | Free L1 and R1 for friendly/enemy targeting. |
| Travel/combat strafe angle | 115° / 115° | Test ConsolePort defaults 0° / 180° for stronger controller-style facing. |
| Turn with camera | In Combat | Test Always; retain In Combat if Always feels too rigid. |
| Enemy soft target | Gamepad | Keep. |
| Friendly soft target | Off | Enable for Gamepad if healing/support targeting is desired. |
| Crosshair | Off | Keep off; Forever does not present a permanent aiming reticle in ordinary play. |
| Ring press-and-hold | Off | Enable for hold/select/release rings where it improves the console feel. |
| Interface keyboard | On | Keep; it is useful even though Forever's beta keyboard support is incomplete. |
| Show all cluster buttons | Off | Keep off; it supports the layered presentation. |
| Macro text | Hidden | Keep. |
| Cooldown numbers | On | Keep. |
| Bar border | Normal | Keep initially; adjust only after the control behavior is correct. |

## What the Forever beta currently does

The public Blizzard announcement confirms official gamepad support, but the detailed mapping below comes from current beta documentation and player testing, not a frozen Blizzard specification. The feature is still changing.

### Action HUD and layers

- The controller HUD is organized around eight inputs: four D-pad directions and four face buttons.
- The base state and the L2/LT, R2/RT, and both-trigger states form four input layers.
- Current guides describe four eight-command hotbars, for 32 commands in total.
- The trigger layers expose action slots; the unmodified face buttons retain prominent context/navigation roles.
- Players can cycle among three arrangements, producing a larger overall set of possible bars.
- Forever also exposes a press-to-toggle trigger option for players who do not want to hold a trigger. ConsolePort's ordinary Shift/Ctrl emulation is hold-based, so this should not be promised as an exact match without a separate accessibility/remapping solution.
- A reported beta CVar, `GamepadUseCompactActionBar`, reduces the native Forever presentation to the currently active eight-button bar. This CVar belongs to Forever's native implementation and should not be expected to restyle Retail ConsolePort.

### Base controls reported in beta

| Physical control | Forever behavior | Closest Retail/ConsolePort analogue |
|---|---|---|
| Left stick | Move | Native gamepad movement with analog enabled. |
| L3 | Autorun | Bind `TOGGLEAUTORUN`. |
| Right stick | Camera | Native camera stick. |
| R3 | Ping; hold for ping wheel | Retail binding `TOGGLEPINGLISTENER`. ConsolePort still uses R3 as right-click while its interface cursor is active. |
| Cross / A | Jump | Bind `JUMP`. |
| Square / X | Context action, interact, or attack | Bind `INTERACTTARGET`; allow ConsolePort's interact logic to supply targeting/context. |
| Triangle / Y | Inspect/context/right-click behavior | Approximate with `TURNORACTION` or ConsolePort's unit/context interaction. |
| Circle / B | Cancel/back | Leave the global world binding empty. Immersion handles PAD2 directly as Goodbye, and ConsolePort supplies contextual cancel while navigating its UI; this prevents the same press from closing dialogue and then opening the Game Menu. |
| R1 / RB | Enemy target/scan | Bind enemy target scan or nearest-enemy action. |
| L1 / LB | Friendly target; hold for party overlay | Bind friendly target/scan. ConsolePort Target can approximate party selection, but not reproduce the same native overlay exactly. |
| Trackpad-side buttons | Left map, right main radial menu | PADBACK opens the map; PADFORWARD opens ConsolePort's main menu in all four modifier states. PADSYSTEM is a separate central control. |

When both bumpers are held, Forever exposes a utility layer including bar-arrangement cycling, chat, quests, bags, weapon sheathing, buff viewing, camera zoom/recenter, and look-behind. ConsolePort can place most of these commands on a ring or modifier combinations, but a dedicated, visually identical bumper overlay is not a stock preset.

### Native behavior that ConsolePort settings cannot duplicate exactly

- Blizzard's precise HUD art, animation, input legend, and context glyphs.
- The exact three-arrangement switcher and its visual feedback.
- Native D-pad focus navigation across every Forever-converted window.
- Trigger-driven frame focus changes and PS5 touchpad behavior.
- The friendly-party overlay in which face buttons and D-pad directions correspond to specific party frames.
- Several context-sensitive actions sharing one face button through native secure code.
- Forever's native press-to-toggle trigger mode. The proposed ConsolePort setup assumes held L2/R2 modifiers.
- Beta-only bugs or limitations. They should not be deliberately emulated.

## Recommended target configuration

### 1. Action-bar foundation

Use **Forever: Expanded**, derived from the `Crossbar: Triggers` geometry shipped in `ConsolePort_Bar\Model\Presets.lua`. The final layout contains:

- an upper-center eight-button base/context group;
- a left eight-button L2/M1 group;
- a right eight-button R2/M2 group;
- a lower-center eight-button L2+R2 group;
- within every group, the four D-pad inputs form a plus on the left and the four face buttons form a plus/diamond on the right;
- two small L2/R2 modifier labels;
- state-driven opacity and scaling that communicate which bank is active;
- no persistent L1/R1 targeting boxes, although their targeting bindings remain active.

This is much closer to Forever than the current `Default` cluster and is safer than constructing a layout from scratch. Do not edit `Presets.lua`; an add-on update would overwrite it.

Use **Crossbar: Minimal** only if the desired priority is Forever's hidden compact mode: one visible eight-button group whose contents swap with the active modifier. It is visually cleaner but communicates fewer inactive layers at once.

Initial bar settings:

| ConsolePort label | Target | Reason |
|---|---:|---|
| Show Main Icons | On | Preserve the visible eight-input grammar. |
| Enable Cooldown Numbers | On | Matches modern native cooldown readability. |
| Hide Macro Text | On | Removes PC-centric labels and visual noise. |
| Always Show All Buttons | Off | Let modifier state drive visibility. |
| Show Modifier Icons | On | Important while learning L2/R2 layers. Revisit after muscle memory develops. |
| Full State Modifier | Off | Avoid an extra modifier state that does not exist in the Forever model. |
| Main Button Border Style | Normal | Closest neutral baseline; artwork will still differ. |
| Show Flyout Icons | On | Keeps contextual information visible. |
| XP bar | Off in ConsolePort bar | Avoid duplicating Blizzard's stock UI elements. |
| Bar scale | Begin at 100%, then tune | Screen resolution and Retail UI scale determine the visually correct value. |

Do not attempt pixel tuning until the bindings work. Once behavior is correct, compare screenshots at the same resolution and tune crossbar scale, vertical offset, spacing, opacity, and border style.

### 2. Modifier model

Use the following global gamepad modifiers:

| ConsolePort modifier | PS5 | Xbox | WoW gamepad token |
|---|---|---|---|
| Modifier 1 / Shift | L2 | LT | `PADLTRIGGER` |
| Modifier 2 / Ctrl | R2 | RT | `PADRTRIGGER` |
| Modifier 3 / Alt | Unassigned | Unassigned | none |

The exact M1/M2 order matters because the shipped Crossbar preset associates its left and right groups with those states. This change also frees L1/LB and R1/RB for the Forever-like targeting model.

### 3. Suggested base bindings

These are a target map, not a promise that every entry has a one-click binding in every Retail build. Confirm binding names in ConsolePort before committing them.

| Control | Suggested base binding | Notes |
|---|---|---|
| L2/LT | Shift / M1 only | Do not put an action on the bare trigger. |
| R2/RT | Ctrl / M2 only | Do not put an action on the bare trigger. |
| L1/LB | Target nearest friend or friendly-target scan | Enable friendly soft targeting for support play. |
| R1/RB | Target scan enemy or nearest enemy | Target scan tends to feel closer to directional controller targeting. |
| Cross/A | `JUMP` | Direct match. |
| Square/X | `INTERACTTARGET` | Closest general match for Forever's primary context action. |
| Triangle/Y | `TURNORACTION` or context/unit menu | Test both; no single Retail binding exactly matches Forever. |
| Circle/B | No global world binding; contextual cancel in Immersion and ConsolePort UI | Runtime testing showed that `TOGGLEGAMEMENU` can leak through after a dialogue closes. Keep the main radial menu on PADFORWARD instead. |
| L3 | `TOGGLEAUTORUN` | Direct match. |
| R3 | `TOGGLEPINGLISTENER` | Verified in the existing Retail binding cache; ConsolePort's cursor context continues to use the same physical button for right-click. |
| Left trackpad-side / PADBACK | World map | All four configured modifier states. |
| Right trackpad-side / PADFORWARD | ConsolePort Menu trigger | All four configured modifier states. |
| L2+R2+D-pad Up | LiteMount | CTRL-SHIFT-PADDUP = CLICK LM_B1:LeftButton; static icon 132247. |

Keep the unmodified D-pad available either for four high-frequency actions or for navigation/party targeting. A healer may prefer party targeting; a damage character may prefer interrupts, defensives, or movement skills. This is one of the places where a single shared binding profile may not suit every specialization.

### 4. Trigger-layer binding pattern

Use a consistent spatial grammar rather than copying spells blindly between classes:

| Position | L2/LT layer | R2/RT layer | L2+R2 layer |
|---|---|---|---|
| Face buttons | Core rotation | Secondary rotation / short cooldowns | Major cooldowns / rare combat actions |
| D-pad left/right | Movement and utility | Crowd control / dispel | Consumables / encounter utilities |
| D-pad up/down | Defensives / mobility | Targeted utilities | Mount, marker, or out-of-combat utilities |

The saved binding profile should map physical combinations to Blizzard action slots. The actual spells occupying those slots remain class/spec-specific and should be placed in game. Attempting to impose one spell map through shared local files would either fail or make the template unsuitable across classes.

### 5. Targeting and interaction

Recommended ConsolePort settings:

| Setting | Target | Effect |
|---|---:|---|
| Enemy Soft Targeting | Gamepad (`1`) | Looks at enemies to acquire a soft target while using the controller. |
| Friend Soft Targeting | Gamepad (`1`) | Enables the analogous friendly target behavior. Disable for DPS if it causes unwanted highlighting. |
| Enemy Target Icon | On | Makes the controller-selected enemy clearer. |
| Friend Target Icon | On initially | Useful while testing; disable later if visually noisy. |
| Enemy Nameplate | Off in ConsolePort | Plater remains the sole nameplate renderer. Soft targeting and the target icon remain enabled without asking ConsolePort to force an additional plate state. |
| Friend Nameplate | Off initially | Avoids excessive friendly plate noise. |
| Enemy/Friend Tooltip | Off initially | The current enemy tooltip is already off and Forever emphasizes the world/HUD more than mouse-style tooltips. |
| Show Interact Binding Hint | On | Closest match for Forever's context prompt. |
| Show Interact Tooltip on Nameplates | On | Provides feedback about the current interactable. |
| Minimal Interact Nameplate Tooltip | On after confirming readability | Removes the PC-style tooltip background and moves the look closer to Forever's compact prompt. |
| Player Interact | On | Allows context/unit-menu behavior when interacting with players. |
| `SoftTargetInteract` | On when `INTERACTTARGET` is used | Lets the interact key find nearby objects and creatures. Prefer allowing ConsolePort to manage it. |

ConsolePort's Target module may be used for party or raid selection, but first test its defaults. Forever's L1-hold party diagram should be treated as a conceptual target; reproducing the same face/D-pad overlay may require add-on development, not only configuration.

### 6. Movement and camera

Keep **Analog Movement** enabled. Test this baseline:

- Travel Strafe Angle: **0°**
- Combat Strafe Angle: **180°**
- Turn Character With Camera: **Always**
- Jump strafe-angle override: **Off**

Those are ConsolePort's own defaults and usually produce a more intentional controller distinction between free travel and combat facing than the current 115°/115° setup. If Always makes ordinary camera movement too coupled, use **In Combat** instead; feel is more important here than nominal similarity.

Keep the permanent ConsolePort crosshair disabled. Use the normal right-stick camera and interaction targeting instead.

### 7. Cursor, menu, rings, and keyboard

- Enable **Interface Cursor** and its normal focus navigation.
- Keep interface wrapping enabled by leaving ConsolePort's **Disable Wrapping** setting off, so D-pad movement can continue through edge items.
- Keep the ConsolePort on-screen keyboard enabled as a practical Retail advantage.
- Enable ConsolePort's custom/controller-friendly loot frame if it is not already active.
- Keep TOGGLEWORLDMAP on PADBACK and the ConsolePort Menu trigger on PADFORWARD in all four configured modifier states. Preserve the separate PADSYSTEM binding.
- Curate the menu/rings around Forever's categories: Character, Talents, Spellbook, Professions, Bags, Quests/Map, Group Finder, Collections, Social/Communities, PvP, Calendar/Clock, and Game Menu.
- Prefer **Press and Hold** for momentary utility rings that should close on release. For the main menu, test both press-and-hold and sticky selection; Forever's native menu interaction does not map perfectly to every ConsolePort ring mode.
- Keep Sticky Selection off initially.
- Keep the ConsolePort power-level gauge off; it is not part of the Forever target look.

## How to configure it through the game interface

Names may move slightly between ConsolePort releases, but the labels below are taken from the installed add-on.

1. Fully log in on one linked test character and type `/consoleport`.
2. Confirm that the active device is the PS5 controller and that PlayStation glyphs are displayed.
3. Open the advanced controller/modifier settings:
   - set **Modifier 1: Shift** to L2;
   - set **Modifier 2: Ctrl** to R2;
   - clear **Modifier 3: Alt**;
   - confirm L1 and R1 are no longer modifiers.
4. Open **Action Bars** and its layout/preset editor.
5. Apply **Forever: Expanded**. Its serialized form is installed in the shared character template.
6. Apply the initial bar settings from the table above: main icons and cooldowns on; macro text, always-show-all, full-state modifier, and ConsolePort XP bar off; modifier and flyout icons on; Normal border.
7. Open **Movement**:
   - keep Analog Movement on;
   - set travel/combat strafe angles to 0°/180°;
   - set Turn Character With Camera to Always for the first test.
8. Open **Targeting**:
   - Enemy Soft Targeting = Gamepad;
   - Friend Soft Targeting = Gamepad;
   - enable target icons and the enemy nameplate;
   - leave mouse-style target tooltips off initially.
9. Open interaction/world settings:
   - enable interact binding hints;
   - enable interact information on nameplates;
   - enable player interaction;
   - ensure `INTERACTTARGET` is placed on Square/X.
10. Open **Interface Cursor**, **Rings**, **Keyboard**, and **Quick Menu**:
    - enable the interface cursor and keyboard;
    - keep selection wrapping active;
    - configure PADBACK as the world map and PADFORWARD as the ConsolePort menu trigger;
    - populate menu categories to resemble the Forever radial menu;
    - enable press-and-hold on temporary utility rings, then test whether it feels natural.
11. Open **Bindings** and apply the base control table. Then map the L2, R2, and L2+R2 combinations to the intended action-bar slots.
12. Place class abilities into those slots in Blizzard's action-bar UI. Use the spatial pattern above consistently across specializations.
13. Save/export a named profile such as `Forever-like – PS5 – v1`. Do not rely only on ConsolePort's automatic spec/profile naming.
14. Log out normally so WoW writes a coherent SavedVariables snapshot. Exit the client before inspecting or copying it.

The safest route to a direct-file rollout is to perform steps 1–14 once on a test character, then use the resulting saved layout as the canonical template. That captures the exact serialized form expected by the installed ConsolePort version.

## How it can later be applied directly to saved files

This section describes a future operation by the assistant. It is not authorization to do it now.

### Safety rules

1. Exit WoW completely. `/reload` is not enough for external edits: the client can overwrite SavedVariables during logout or shutdown.
2. Confirm no Blizzard launcher process is relaunching the client.
3. Make timestamped copies of every file to be changed. Keep the backups outside the live `WTF` subtree so a bad junction operation or sync conflict cannot overwrite them.
4. Record hashes and junction targets before editing.
5. Edit only targeted Lua table fields; do not replace the whole account file with a generic sample.
6. Never edit `ConsolePort_Bar\Model\Presets.lua` to customize the profile.
7. Validate Lua syntax, launch one test character, log out normally, and diff the result before rolling out further.

### Target files

| File | Intended change |
|---|---|
| `_retail_\WTF\Config.wtf` | Change the modifier CVars to left and right triggers; preserve unrelated graphics, sound, and account settings. |
| `_retail_\WTF\Account\119624169#1\SavedVariables\ConsolePort.lua` | Update explicit core overrides, PS5 controller mappings if required, and the selected `ConsolePortShared` binding profile(s). |
| `_retail_\WTF\Account\_template_\SavedVariables\ConsolePort_Bar.lua` | Store the `Forever: Expanded` serialized layout and bar options. All linked character folders see this file. |
| `_template_\SavedVariables\ConsolePort_Rings.lua` | Populate only the rings chosen for the Forever-style menu/utility design. |
| `_template_\SavedVariables\ConsolePort_Target.lua` | Store Target-module settings only after in-game testing proves they help. |

### Intended `Config.wtf` modifier lines

The future edit should make these lines effective, replacing the current left-shoulder/left-trigger pair:

```text
SET GamePadEmulateShift "PADLTRIGGER"
SET GamePadEmulateCtrl "PADRTRIGGER"
```

Do not create two copies of the same CVar. Update the existing line or remove stale duplicates after verifying which value WoW retains.

Movement and soft-target CVars may be serialized by ConsolePort when settings are changed. Prefer letting ConsolePort write them from the UI once. If direct editing is required, derive exact CVar names and representations from the installed add-on rather than assuming that every ConsolePort table key belongs in `Config.wtf`.

### Intended core overrides

The target account table should contain the equivalent of the following values while preserving every unrelated key and nested profile:

```lua
ConsolePortSettings = {
    mvmtAnalog = true,
    mvmtStrafeAngleTravel = 0,
    mvmtStrafeAngleCombat = 180,
    mvmtTurnWithCamera = 2, -- Always; use 1 for In Combat if preferred after testing
    trgtEnemy = 1,          -- Gamepad
    trgtFriend = 1,         -- Gamepad
    trgtEnemyTooltip = false,
    trgtFriendTooltip = false,
    trgtEnemyIcon = true,
    trgtFriendIcon = true,
    trgtEnemyNameplate = true,
    trgtFriendNameplate = false,
    trgtShowInteractHint = true,
    trgtShowInteractNameplate = true,
    trgtShowMinimalInteractNamePlate = true,
    trgtEnablePlayerInteract = true,
    crosshairEnable = false,
    keyboardEnable = true,
    UIenableCursor = true,
    UIWrapDisable = false,
    ringPressAndHold = true,
    ringStickySelect = false,
    bindingShowExtraBars = false,
    bindingOverlapEnable = false,
    powerLevelShow = false,
    -- Preserve tutorial state and all unrelated existing fields.
}
```

This is a field-level target, not a replacement file. Replacing the complete table with this excerpt would destroy unrelated settings.

### Bar layout strategy

There are two safe approaches:

1. **Implemented:** the shared `_template_` file contains the reviewed `Forever: Expanded` layout, based on the saved crossbar schema and supplied Forever references.
2. **Fully direct:** programmatically construct the serialized layout from the installed preset definition, using ConsolePort's own preset schema, and write it into `ConsolePort_BarLayout`.

The first approach is less brittle because ConsolePort may transform preset definitions into runtime/saved-layout fields. Either approach must preserve or deliberately replace `ConsolePort_BarDB` with reviewed values equivalent to:

```lua
ConsolePort_BarDB = {
    clusterFullStateModifier = false,
    enableXPBar = false,
    clusterShowAll = false,
    clusterBorderStyle = "Normal",
    fadeXPBar = false,
    showMainIcons = true,
    clusterShowFlyoutIcons = true,
    LABhideElementsMacro = true,
    showCooldownText = true,
}
```

Only add the setting responsible for modifier icons after confirming its exact serialized key in the UI-generated result.

### Binding-profile implementation

`ConsolePortShared` contains three Arcane profiles for Fëlagund on Grim Batol/Proudmoore. All three were patched, and the active PS5 device generator was patched for characters that do not yet have a saved profile. L2/R2 bare actions were cleared; base face, bumper, stick-click, map, bag, and menu behavior was normalized. Existing modifier-layer action-slot bindings were preserved so class spell placement was not guessed or destroyed. The PS5 device record remains active and its glyph mapping is unchanged.

## Prerequisite repair plan for the three character folders

Do this only when explicitly authorized, while WoW is closed:

1. Reconfirm that the three paths are ordinary directories and that their only file is `AddOns.txt`.
2. Compare each `AddOns.txt` with the template version and decide whether its enabled/disabled add-on choices should be merged or intentionally replaced.
3. Create a dated backup outside the live account tree.
4. Rename each real character directory to a dated, recoverable holding name rather than deleting it immediately.
5. Create a directory junction at the original character path pointing to the exact `_template_` path.
6. Verify the reparse-point type and resolved target for each path.
7. Launch one formerly unlinked character, verify add-on enablement and ConsolePort state, then log out.
8. Keep the holding directories until the complete ConsolePort rollout has survived at least one clean restart and OneDrive sync.

This targeted procedure avoids the destructive behavior of the old bulk script and preserves the three `AddOns.txt` files for comparison.

## Validation checklist

### Layout and bindings

- [ ] PS5 glyphs are shown; Xbox glyphs appear correctly if an Xbox controller is connected.
- [ ] L2 alone exposes the left eight-button layer.
- [ ] R2 alone exposes the right eight-button layer.
- [ ] L2+R2 exposes the combined eight-button layer regardless of press order.
- [ ] L1 and R1 do not trigger modifier states.
- [ ] No base, L2, R2, or combined binding conflicts are reported.
- [ ] Vehicle, possess, override, and extra-action bars remain usable.
- [ ] Cooldown text, flyout indicators, and modifier glyphs remain readable at the chosen UI scale.

### World controls

- [ ] Cross/A jumps.
- [ ] Square/X reliably interacts with NPCs, objects, loot, quest items, and dead targets.
- [ ] Enemy bumper targeting behaves predictably while moving the camera.
- [ ] Friendly bumper targeting is useful rather than distracting on both DPS and healer specs.
- [ ] L3 autorun and R3 ping/utility do not interfere with cursor clicks.
- [ ] Soft target becomes a hard target through the intended action.
- [ ] No permanent crosshair appears during ordinary play.

### UI and menus

- [ ] Left/PADBACK opens the world map; right/PADFORWARD opens the ConsolePort main radial menu across all four configured modifier states.
- [ ] Character, Talents, Spellbook, Bags, Map/Quests, Group Finder, Collections, Social, and Game Menu are reachable without a mouse.
- [ ] D-pad/interface-cursor navigation works in inventory, vendors, quests, talents, group finder, and settings.
- [ ] Cancel/back works without opening unwanted menus in the world.
- [ ] The on-screen keyboard can be opened and dismissed.
- [ ] The radial ring selection mode is comfortable and does not cast on accidental release.

### Persistence and shared-folder behavior

- [ ] Test character is one of the 39 linked characters.
- [ ] After targeted repair, each of the three former exceptions resolves to `_template_`.
- [ ] Settings survive `/reload`, logout/login, and a complete client restart.
- [ ] A second class/spec does not inherit inappropriate spell placement.
- [ ] OneDrive has finished syncing and has not produced conflict copies.
- [ ] Backups can restore the original `Config.wtf`, core SavedVariables, bar layout, and ring files independently.
- [ ] `Blizzard_Console.lua` contains no new ConsolePort-related errors after the test session.

## Rollback

If the UI or controls become unusable:

1. Exit WoW fully.
2. Restore `Config.wtf` and the ConsolePort SavedVariables from the timestamped backup, preserving the existing junctions.
3. If only the bar is wrong, restore just `_template_\SavedVariables\ConsolePort_Bar.lua`.
4. If a ring or menu is wrong, restore only its module file.
5. Launch on the test character and verify before restoring or touching anything else.

Do not delete `WTF` wholesale. The account-wide and template-based structure makes a blanket reset far more destructive than necessary.

## Evidence and confidence

| Conclusion | Confidence | Basis |
|---|---|---|
| Crossbar: Triggers is the closest shipped source layout; `Forever: Expanded` is the desired final presentation | High | Direct inspection of the preset source plus two user-provided Forever references. |
| L2/R2 should be the two modifiers | High | Matches Forever's documented four-layer input model and the preset's M1/M2 structure. |
| Bumpers should be freed for targeting | High | Repeated across current Forever guides and testing reports. |
| Exact visual parity is impossible through settings alone | High | The Forever UI is native Blizzard code; ConsolePort exposes different frames and schemas. |
| No public matching profile currently exists | Medium-high | Broad search found requests but no verifiable profile; absence can never be proven exhaustively. |
| 0°/180° movement angles will feel most Forever-like | Medium | They are ConsolePort defaults and fit the control model, but this is subjective and must be play-tested. |
| Friendly soft targeting should remain enabled for every spec | Medium-low | Helpful for support play, potentially noisy for DPS; make it profile-dependent if necessary. |

## Sources

- Blizzard, [The Next Chapter Begins with World of Warcraft: Midnight and World of Warcraft: Forever](https://worldofwarcraft.blizzard.com/en-gb/news/24303862/) — official confirmation of gamepad support, published 2026-09-12.
- NerdsChalk, [World of Warcraft Forever beta controller setup, bindings, and controls](https://nerdschalk.com/world-of-warcraft-forever-beta-controller-setup-bindings-and-controls/) — detailed current mapping and UI behavior, updated 2026-09-23.
- Icy Veins, [Playing With a Controller in WoW Forever](https://www.icy-veins.com/wow-forever/playing-with-controller) — controller layers, targeting, and menu overview.
- Blizzard Beta Forums, [Controller Support Feedback: Beta Impressions So Far](https://us.forums.blizzard.com/en/wow/t/controller-support-feedback-beta-impressions-so-far/2353149?page=2) — player-observed beta options and behavior.
- Reddit / r/wowforever, [Some hidden features on controller support](https://www.reddit.com/r/wowforever/comments/1wmxyvp/some_hidden_features_on_controller_support/) — community report of the compact-action-bar CVar; treat as beta/community information.
- Windows Central, [Blizzard discussion of Warcraft and controller direction](https://www.windowscentral.com/gaming/blizzard/i-asked-if-warcraft-3-wow-forever-and-heroes-of-the-storm-will-come-to-xbox) — context on the 32-bind approach, radial menu, and ConsolePort community influence.
- ConsolePort, [official GitHub repository](https://github.com/seblindfors/ConsolePort) and [CurseForge project](https://www.curseforge.com/wow/addons/console-port) — add-on source and release information.
- ConsolePort issue [#227: support for World of Warcraft Forever](https://github.com/seblindfors/ConsolePort/issues/227) — open request with no assignee, maintainer response, linked branch, or pull request at time of research.
- Reddit / r/wownoob, [WoW Forever gamepad settings in ConsolePort](https://www.reddit.com/r/wownoob/comments/1wma74r/wow_forever_gamepad_settings_in_consoleport/) — request for essentially the same configuration; a reply confirms the same base face/bumper map but provides no profile or LB+RB-layer solution.

All beta-specific observations were checked on 2026-09-25. Revalidate them before implementation because Forever's controller UI is still under active development.

## Approved implementation addendum — 2026-09-26

The user approved the first-pass cleanup and direct configuration after the compatibility investigation, with two additions: retain `Immersion_ExtraFade` and retain/configure `DynamicCam`. The intended result is a ready-to-play offline rollout rather than a list of manual chores.

### Final retained add-on set

Retain these 40 installed directories:

- `BetterBags`;
- `ConsolePort`, `ConsolePort_Bar`, `ConsolePort_Config`, `ConsolePort_Cursor`, `ConsolePort_Keyboard`, `ConsolePort_Menu`, `ConsolePort_Rings`, `ConsolePort_Target`, and `ConsolePort_World`;
- every installed `DBM-*` directory;
- `DynamicCam`;
- `Immersion` and `Immersion_ExtraFade`;
- `LiteMount`;
- `Masque`;
- `Plater`;
- `SharedMedia_Causese`.

`Immersion_ExtraFade` is not by Immersion/ConsolePort author MunkDev. Its installed TOC credits LudiusMaximus, who is also DynamicCam's current maintainer. It declares `Immersion` as a required dependency, is current for interface 120100, and does not claim controller input. It is therefore retained as a compatible Immersion extension.

The exact 80-directory removal manifest is recorded in `ConsolePort-Addon-Cleanup-Recommendation.md`. Removal means add-on code directories only. All SavedVariables are deliberately preserved so any package can be restored later without losing its old profile.

### Retained-add-on ownership boundaries

| Add-on | Retained role | Boundary used to avoid conflict |
|---|---|---|
| ConsolePort suite | Controller bindings, cursor, rings, menus, targeting, and action HUD | Owns all PAD navigation and the controller action HUD. |
| Plater | Enemy/friendly nameplate presentation | ConsolePort soft targeting remains on, but ConsolePort's `trgtEnemyNameplate` and `trgtFriendNameplate` forcing are off. Interact hints remain on. |
| Immersion + ExtraFade | Dialogue presentation and fading | DynamicCam changes camera distance only; it does not hide the dialogue UI. |
| DynamicCam | Contextual camera transitions | Enemy-focus camera steering and automatic rotation remain off so right-stick control and soft targeting stay predictable. |
| BetterBags | Bag and bank UI | Its source-detected ConsolePort integration supplies cursor nodes automatically. |
| DBM | Encounter warnings and vibration | No controller bindings are reassigned. All installed encounter modules remain together. |
| Masque | Skinning support | Retained because ConsolePort_Bar exposes Masque support; no forced skin is imposed during this pass. |
| LiteMount | Existing personalized mount rules | Database is preserved. CTRL-SHIFT-PADDUP invokes CLICK LM_B1:LeftButton through the stable Forever Controller preset, with static icon 132247. |
| SharedMedia_Causese | Media dependency for Plater | Retained because the existing Plater profile directly references its sounds. |

### DynamicCam couch/console profile

The account-wide `Default` DynamicCam profile is configured directly. It uses DynamicCam's built-in situation IDs and `zoom` transitions instead of saved camera views, so it does not require `/saveview` or any manual setup.

Global camera behavior:

- adaptive zoom restoration;
- reactive zoom enabled;
- 1-unit ordinary zoom increments, with 2.5 extra units for quick zoom;
- 1.2 quick-zoom threshold;
- maximum reactive transition time raised from 0.1 to 0.35 seconds for smoother controller-camera motion;
- camera zoom speed 12;
- a subtle 0.8 over-the-shoulder offset in ordinary exploration;
- enemy-focus steering disabled globally;
- interaction-focus steering enabled only during NPC interaction, with restrained yaw/pitch strengths;
- no automated rotation, AFK spin, or global UI hiding.

Enabled situation targets:

| Situation | Zoom | Enter/exit | Other behavior |
|---|---:|---:|---|
| City | 12 | 0.6 / 0.6 s | Subtle 0.8 shoulder offset. |
| City indoors | 7 | 0.45 / 0.6 s | Centered camera for walls and doorways. |
| World | 14 | 0.6 / 0.6 s | Subtle 0.8 shoulder offset. |
| World indoors | 8 | 0.45 / 0.6 s | Centered camera. |
| World combat | 18 | 0.35 / 0.6 s | Centered; enemy focus remains off. |
| Dungeon/scenario and outdoor variant | 17 | 0.5 / 0.6 s | Centered. |
| Dungeon trash/boss combat | 20 / 22 | 0.3 / 0.5 s | Wider tactical field, centered. |
| Raid and outdoor variant | 20 | 0.5 / 0.6 s | Centered. |
| Raid trash/boss combat | 24 / 28 | 0.3 / 0.5 s | Widest tactical field, centered. |
| Mounted | 20 | 0.55 / 0.6 s | Subtle 0.6 shoulder offset. |
| Flying/airborne | 26 | 0.55 / 0.6 s | Centered. |
| Skyriding airborne | 30 | 0.4 / 0.6 s | Centered, wide field. |
| Taxi | 28 | 0.8 / 0.8 s | Cinematic travel distance. |
| Vehicle | 24 | 0.5 / 0.6 s | Centered for vehicle controls. |
| NPC interaction / Immersion dialogue | 5.5 | 0.75 / 0.6 s | Centered; interaction focus only; UI remains visible. |
| Mailbox | 7 | 0.65 / 0.6 s | Centered. |
| Fishing | 10 | 0.7 / 0.7 s | Gentle activity framing. |
| Gathering | 8 | 0.45 / 0.6 s | Brief close activity framing. |
| Swimming | 16 | 0.55 / 0.6 s | Centered. |

Overlapping mounted situations are intentional: DynamicCam priority makes the more specific flying/skyriding state override generic mounted zoom. Hearth/teleport, AFK, and pet-battle automation remain disabled to avoid surprise motion. All situation UI-fade switches remain disabled because Immersion and ExtraFade own the dialogue presentation.

### Blizzard Edit Mode decision

Do not edit `edit-mode-cache-account.txt`, `edit-mode-cache-character.txt`, or `layout-local.txt`. This account currently has layouts named `RealUI` and `RealUI Acer`. Blizzard account layouts are synchronized through the Edit Mode API/server state, while the local files are opaque caches that can be replaced by synchronization. ConsolePort_Bar will provide the controller HUD and suppress/replace the relevant action presentation; the existing Blizzard layout remains a safe fallback for frames outside ConsolePort's ownership.

### Direct-file implementation targets

- `WTF\Config.wtf`: L2/R2 modifier CVars, movement, camera coupling, and soft-target CVars.
- `WTF\Account\119624169#1\SavedVariables\ConsolePort.lua`: exact core overrides and retained binding profiles.
- `WTF\Account\_template_\SavedVariables\ConsolePort_Bar.lua`: fully rendered `Forever: Expanded` layout plus existing neutral bar options.
- `WTF\Account\119624169#1\SavedVariables\DynamicCam.lua`: the couch/console profile above.
- Three ordinary character folders: replace only after verifying they contain only `AddOns.txt`, then create junctions to the exact `_template_` directory.
- `Interface\AddOns`: remove only the approved 80-directory manifest; do not touch any SavedVariables file.

Validation is necessarily two-stage. Offline validation can prove file syntax/shape, exact directory inventory, junction targets, dependency closure, and absence of stale references in retained add-on code. The first login remains the runtime test for protected bindings, Blizzard server-synchronized action-slot contents, and subjective camera feel; no offline tool can execute WoW's Lua runtime or Blizzard's secure-frame state.


Final polish implementation and the single remaining login check are recorded in [the implementation report](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Implementation-Report.md>). Automation `fix-consoleport-circular-buttons` is PAUSED after offline validation.
