# ConsolePort add-on compatibility evidence ledger

Research date: 2026-09-26

Status: research only. No add-on deletion or configuration change is authorized by this document.

## Evidence standard

Each entry separates direct source-code evidence, authoritative project documentation, community reports, and inference. A UI-changing add-on is not classified as incompatible unless there is evidence of overlapping controller input, secure-frame ownership, camera control, targeting/nameplate interference, or broken interface-cursor navigation.

## Verified findings

### Immersion — strong keep

- The installed `Immersion.toc` declares `ConsolePort` as an optional dependency.
- `Immersion/Logic/Controller.lua` describes itself as the ConsolePort controller input and on-screen-hint handler. It uses ConsolePort's UI handle, temporarily takes hint-bar focus during NPC interaction, translates configured gamepad buttons, and contains an explicit edge-case check so the ConsolePort cursor can take precedence.
- `Immersion/Compat.lua` explicitly excludes ConsolePort's cursor/mouse/hint frames from Immersion's frame processing.
- Immersion's settings disable mouse-only behavior when ConsolePort is loaded and provide gamepad assignments whose hints are displayed by ConsolePort.
- The same GitHub maintainer, Sebastian Lindfors (`seblindfors`), maintains both projects.
- Classification: intentional integration, not a conflict. Keep the base add-on.
- Sources: local installed source; https://github.com/seblindfors/Immersion ; https://github.com/seblindfors/ConsolePort

### BetterBags — strong keep

- Its TOC lists ConsolePort as an optional dependency.
- The installed `integrations/consoleport.lua` detects ConsolePort, registers the backpack, bank, and dynamically created context-menu frames with `ConsolePort:AddInterfaceCursorFrame`, and explicitly selects context-menu nodes with `ConsolePort:SetCursorNode`.
- Classification: intentional interface-cursor integration. Keep.
- Source: local installed source and the BetterBags project repository.

### Plater / nameplate behavior — keep pending deeper Plater-specific review

- ConsolePort issue #159 reports missing enemy health bars under Midnight when ConsolePort's own `show enemy nameplate`, `show interact hint`, and `use interact nameplate tooltip` options are enabled.
- The reporter reproduced it with only ConsolePort modules enabled. Therefore, a missing-health-bar symptom cannot automatically be attributed to Plater.
- Practical implication: with Plater retained, ConsolePort's nameplate-forcing and interact-nameplate options require testing individually. It may be safer to let Plater own visual nameplates while ConsolePort owns soft targeting and interaction hints that do not forcibly alter nameplates.
- Classification: user-directed keep; possible settings-level interaction, not evidence that Plater itself is incompatible.
- Source: https://github.com/seblindfors/ConsolePort/issues/159

### ConsolePort baseline observations

- ConsolePort's current repository documents separate modules for interface cursor, targeting, rings, bars, menus, and world interaction.
- Current open Retail/Midnight reports include taint or Secret Value errors in Blizzard UI widgets and tooltips caused by ConsolePort itself. These establish that some observed UI faults may be ConsolePort/12.x compatibility issues rather than third-party conflicts.
- Source: https://github.com/seblindfors/ConsolePort/issues and individual issues including #186.

## Still to investigate

- Direct overlap: OPie/OPieMasque, DynamicCam, Narcissus GamePad, Myslot, NoAutoClose, BlizzMove, EditModeExpanded, Immersion_ExtraFade, Masque, ls_Glass, WIM, ZenFishing.
- Redundancy/currentness: Details, WeakAuras, RaiderIO, Simulationcraft, TSM AppHelper, Copybara, Plumber, WorldFlightMap, tullaRange, SharedMedia_Causese.
- User-nominated removals: Khesyc_iLvl, Molinari, Pawn, PersistentWorldMap, TomTom.
- Confirmed user keeps: Immersion base, Plater, DBM.

## Batch 2 findings

### Plater — strong keep, with one ConsolePort setting caveat

- Plater's installed source contains an explicit ConsolePort workaround in its dropdown implementation: it avoids adding that dropdown to `UISpecialFrames` because doing so causes ConsolePort hide/stack-overflow behavior.
- This is evidence that Plater's maintainers have deliberately accounted for ConsolePort coexistence.
- Community evidence is positive: controller players report using ConsolePort together with Plater for aggro, cast, and mob-type visibility, including a player reporting repeated Keystone Master achievements with that combination.
- No installed Plater code attempts to own normal gameplay gamepad bindings. The only generic gamepad code found is the bundled AceGUI keybinding widget used while capturing settings input.
- ConsolePort issue #159 still means its own enemy-nameplate/interact-nameplate toggles should be tested separately. Recommended ownership split: Plater controls nameplate appearance; ConsolePort controls targeting, with nameplate-forcing options enabled only if testing shows no missing-health-bar behavior.
- Classification: intentional compatibility workaround plus positive real-world coexistence. Keep.
- Sources: local `Plater/libs/DF/dropdown.lua`; https://github.com/seblindfors/ConsolePort/issues/159 ; https://www.reddit.com/r/wow/comments/1jg5nna/

### DynamicCam — compatible in principle, but changes the target feel

- Correction to the earlier assessment: the installed package contains a Retail TOC for interface 120100 and is version 2.20.3. It is not simply an obsolete 2.5-era add-on; the directory contains TOCs for several WoW flavors.
- Its official repository says it automates camera transitions and settings by gameplay situation.
- Installed source manages zoom, yaw, pitch, shoulder offset, dynamic pitch, head movement, and optional target/interact camera-focus CVars. It lists Immersion and Immersion_ExtraFade as optional dependencies.
- No direct ConsolePort API integration or binding ownership was found. Community posts describe people installing ConsolePort, DynamicCam, and Immersion together, which is evidence of coexistence rather than proof of perfect compatibility.
- The real concern is behavioral, not technical: DynamicCam can make camera motion differ substantially from Forever's comparatively stable controller camera, and its target-focus CVars could complicate evaluation of ConsolePort targeting.
- Classification: not a verified conflict. For an exact Forever-like baseline, disable/remove temporarily; retain if the user values cinematic camera behavior after baseline testing.
- Sources: local source; https://github.com/mpstark/DynamicCam ; https://www.reddit.com/r/classicwow/comments/1tdxy3m/

### OPie / OPieMasque — functional overlap, not yet a proven ConsolePort conflict

- OPie's authoritative issue page currently says OPie is incompatible with the separate WoW Forever beta client, with future support planned. That does not by itself make OPie incompatible with Retail 12.1 plus ConsolePort.
- ConsolePort Rings and OPie both provide radial action menus. Their overlap creates duplicated UI concepts and potential binding competition only if assigned to the same gamepad chord; separate bindings can coexist.
- The installed ConsolePort saved data contains an OPie-derived shared-ring reference, indicating the user has previously bridged or reproduced OPie content in ConsolePort. This requires careful migration if OPie is removed.
- OPieMasque has separately reported cooldown-text flickering on OPie's official issue page; OPie states that third-party appearance providers are responsible when a non-default appearance is selected.
- Classification: removal is reasonable for a single-ring-system Forever-like baseline, but current evidence supports redundancy/binding overlap—not blanket incompatibility. Inspect ring contents and bindings before deciding.
- Source: https://www.townlong-yak.com/addons/opie/issues and local SavedVariables.

## Batch 3 findings

### Narcissus suite / Narcissus_GamePad — context-specific controller ownership, not a blanket conflict

- The installed Narcissus base and GamePad module both target Retail interface 120100. The GamePad module is load-on-demand and explicitly exists to navigate Narcissus UI.
- `Narcissus_GamePad/Main.lua` listens for gamepad buttons/sticks and applies temporary override bindings such as PAD3 for click/use and PAD2 for cancel. It clears override bindings as its navigation context changes and exits its gamepad mode during combat lockdown.
- The implementation credits Munk, developer of ConsolePort and Immersion, for its click-proxy technique. This suggests informed coexistence, though it is not a ConsolePort API integration.
- Narcissus Achievements marks its root frame `nodeignore` specifically so ConsolePort will ignore it. Therefore, removing only Narcissus_GamePad while retaining the custom Narcissus UI may make that UI less controller-accessible, not more.
- The base add-on also controls camera zoom/orbit while its character/studio UI is open, but this is scoped to Narcissus presentation rather than general gameplay.
- Classification: the suite is optional and visually unlike Forever, but it is current and deliberately handles gamepad navigation. If Narcissus is kept, keep its GamePad module. Remove the whole suite only because the user does not want its alternate character/achievement/studio UI—not because it is proven incompatible.
- Sources: local installed source; community explanation that Narcissus gamepad support navigates Narcissus itself: https://www.reddit.com/r/wow/comments/tworeo/

### Immersion_ExtraFade — compatible companion, preference-based decision

- Installed version 1.17.35 targets interface 120100, requires Immersion, and optionally recognizes Bartender4/GW2_UI.
- It changes which additional UI frames fade while Immersion hides the interface during NPC conversations. No ConsolePort binding ownership or ConsolePort API conflict was found.
- Because base Immersion intentionally integrates with ConsolePort, ExtraFade inherits that interaction context but does not appear to replace its controller handler.
- Classification: current companion, no verified ConsolePort conflict. Keep if the user likes deeper UI fading; remove only for a closer default/Forever presentation.
- Source: local installed TOC and source.

### ZenFishing — stale but not a direct gamepad-binding conflict

- Installed version 0.0.11 targets up to interface 110100.
- It installs an override binding for `BUTTON2` (right mouse button) to cast fishing. It does not directly bind a PAD button in the installed source.
- ConsolePort can synthesize mouse actions through gamepad bindings, so indirect interaction is possible, but no direct collision with the planned PAD mappings is established.
- Classification: stale and very narrow utility. Reasonable removal if unused; evidence supports age/utility cleanup rather than a verified ConsolePort conflict.
- Source: local `ZenFishing.lua` and TOC.

### WIM — current custom chat UI, controller accessibility uncertain

- Installed WIM 3.17.6 targets interface 120100.
- It creates custom instant-message windows and places several windows/monitors in `UISpecialFrames` for Escape-to-close behavior. No ConsolePort integration or direct gamepad override binding was found.
- ConsolePort can sometimes navigate generic frames, but custom frames without registered cursor nodes may be mouse-oriented. Current evidence is insufficient to claim breakage.
- Classification: current; removal would simplify chat/navigation, but compatibility remains uncertain pending repository/user reports.

### MySlot — import/export risk, not a runtime controller conflict

- The project remains available for Retail and its current repository contains modern `C_AddOns` handling. Its purpose is transferring action bars, macros, and related settings between accounts.
- It does not need to continuously own controller input. The concern is operational: importing a profile can overwrite bindings/action-bar state after ConsolePort is configured.
- Classification: safe to retain disabled as an occasional migration tool; remove if no longer used. Do not call it a runtime ConsolePort incompatibility.
- Sources: https://github.com/tg123/myslot ; https://www.curseforge.com/wow/addons/myslot and local files.

## Batch 4 findings: frame, navigation, and skinning add-ons

### NoAutoClose — high-confidence removal for a clean controller navigation baseline

- Installed version 1.3.45 targets Retail 120100 and is actively maintained. Age is not the issue.
- The installed source hooks `ShowUIPanel`, `HideUIPanel`, `RegisterUIPanel`, `RestoreUIPanelArea`, and `CloseWindows`; clears Blizzard `UIPanelLayout-*` attributes; adds frames to `UISpecialFrames`; and installs a high-priority `SetOverrideBindingClick(..., true, 'ESCAPE', ...)` handler.
- ConsolePort's interface cursor and controller back/cancel behavior ultimately depend on Blizzard panel visibility and close semantics. NoAutoClose deliberately rewrites those semantics, so this is a genuine ownership overlap even though the source has no literal ConsolePort reference.
- This does not mean the two always fail together. It means failures such as B/Circle not backing out, multiple panels remaining active, or focus returning to an unexpected frame become harder to distinguish from ConsolePort configuration faults.
- Classification: current but materially overlapping. Remove/disable for the first clean controller baseline. Reintroduce only after validating back/cancel navigation.
- Sources: local source; https://github.com/NumyAddon/NoAutoClose ; https://www.curseforge.com/wow/addons/no-auto-close

### BlizzMove / BlizzMove_Debug — compatible; optional baseline simplification

- Installed v3.8.2 targets Retail 120100 and is current.
- The source makes Blizzard frames movable, stores/reapplies anchors, and hooks `SetPoint`. It does not install gameplay gamepad bindings or use ConsolePort APIs.
- ConsolePort cursor navigation is based on visible frame/node geometry, so moving an otherwise supported frame is not inherently incompatible. A badly positioned or off-screen frame can still be inconvenient, and forced positioning may complicate UI debugging.
- `BlizzMove_Debug` is load-on-demand diagnostic support for BlizzMove, not a separate always-running UI replacement.
- Classification: no verified ConsolePort conflict. Keep if movable panels are valued; disable temporarily only to establish a stock-position baseline. Do not delete Debug while retaining BlizzMove unless the user specifically wants to remove diagnostic tooling.
- Sources: local source; https://github.com/Kiatra/BlizzMove

### EditModeExpanded — compatible layout extension; optional baseline simplification

- Installed 12.1-013 targets Retail 120100.
- It hooks and repositions many Blizzard frames through Edit Mode, including `GameMenuFrame`, tooltip anchors, unit-frame auras, raid frames, micro menu, and managed-frame containers. No persistent controller binding ownership or ConsolePort-specific code was found.
- ConsolePort_Menu is a separate menu replacement; EditModeExpanded's `GameMenuFrame` hooks could affect the underlying Blizzard menu but are not evidence of input conflict.
- Classification: current and compatible in principle. Disable for the first baseline only if exact layout comparison matters; keep otherwise. If layout anomalies occur, test this before deleting it.
- Sources: local source and authoritative project metadata (Curse project 695703).

### Masque — explicit ConsolePort integration; keep

- Installed Masque 12.1.0 targets Retail 120100.
- ConsolePort's bundled LibActionButton detects Masque; ConsolePort_Bar listens for Masque loading, creates groups, and registers its group/page buttons with Masque. This is intentional integration, not incidental coexistence.
- BetterBags, DBM, Plater, WeakAuras, OPieMasque, and ConsolePort are local Masque consumers, so removing the engine would affect several retained add-ons.
- The current `Masque.lua` SavedVariables contains ConsolePort groups but no explicit custom skin identifier for them. This provides no evidence that Masque is presently overriding the intended ConsolePort look.
- Classification: keep. For Forever-like visuals, configure the ConsolePort Masque group to use the default/native appearance rather than removing Masque globally.
- Sources: local ConsolePort_Bar and LibActionButton source; https://github.com/SFX-WoW/Masque

### Masque_CleanIcons — obsolete optional skin; safe removal candidate

- Installed version 1.5 declares interface 70200 and only registers an optional Masque skin.
- It does not own input or frame navigation. Its risk is visual divergence or incompatibility with modern Masque skin metadata, not controller failure.
- Classification: safe candidate for removal because it is obsolete and unnecessary for the target appearance. Low urgency if not selected by any group.

### ls_Glass — authoritative retirement; remove

- Installed version 110207.02 is behind Retail 12.1.
- The official repository explicitly states that the add-on is retired and will not receive Midnight updates. It fully replaces default chat output rather than merely reskinning it.
- Classification: remove on maintenance grounds. This is independent of ConsolePort compatibility.
- Source: https://github.com/ls-/ls_Glass

### WIM — current, but custom-window controller navigation remains uncertain

- Installed WIM 3.17.6 targets Retail 120100.
- It creates movable custom whisper/history/filter windows, custom controls, and its own `UISpecialFrames` entries. No gamepad override binding or ConsolePort node registration was found.
- There is no verified incompatibility report in the sources reviewed. Conversely, there is no explicit ConsolePort navigation integration comparable to BetterBags or Immersion.
- Classification: uncertain rather than incompatible. For a controller-first clean baseline, disable/remove if instant-message windows are not important. If retained, specifically test opening a whisper, selecting history/tabs, focusing the text box/keyboard, sending, and closing with Circle/B.

## Batch 5 findings: combat information add-ons

### DBM — strong keep; it has direct gamepad value

- Installed DBM Core 12.1.11 targets Retail 120100 and exactly matches the latest official release reviewed on 2026-09-25.
- Current DBM source includes `DBM:VibrateController()` and calls Blizzard's `C_GamePad.SetVibration` for supported warnings. This is a positive controller feature rather than an input conflict.
- DBM focuses on actionable encounter instructions and timers. Blizzard's native encounter timeline overlaps part of that function but does not erase DBM's custom warnings, sounds, modules, per-mechanic configuration, or controller vibration.
- The release history contains multiple Forever-beta fixes, showing active maintenance across the relevant client changes.
- Classification: keep, consistent with the user's decision. No evidence of a ConsolePort collision was found.
- Sources: https://github.com/DeadlyBossMods/DeadlyBossMods/releases ; https://github.com/DeadlyBossMods/DeadlyBossMods/blob/master/DBM-Core/DBM-Core.lua

### Details! — compatible and fully current; removal is a simplicity choice

- Installed Details build `#Details.20260918.15280.172` targets interface 120100 and is current for the present client.
- Current source explicitly references Blizzard's `C_DamageMeter`, showing that the project has adapted to the native meter rather than becoming abandoned because of it.
- No ConsolePort/gamepad binding ownership was found. Its normal combat windows are passive displays; deeper breakdown/configuration screens may still be mouse/cursor-heavy.
- The built-in meter makes Details optional for basic damage/healing viewing, but Details retains breakdowns, segments, death analysis, reporting, plugins, charts, and DBM timer integration not established as equivalent in the native meter.
- Classification: no compatibility reason to remove. For the user's deliberately clean first pass, removal is reasonable if basic native statistics are sufficient; otherwise keep. Label as optional/redundant, not obsolete.
- Sources: https://github.com/Tercioo/Details-Damage-Meter and installed source.

### WeakAuras — no ConsolePort conflict, but the installed package/configuration is a poor baseline fit

- Installed WeakAuras is 5.21.1 with interface 110207, while the official project has advanced through multiple 5.21.x releases and now lists 5.22.0. The installed copy is behind.
- The account SavedVariables file is about 2.16 MB and contains 341 display IDs. Identified imports include Luxthos Mage/Paladin War Within packages, an M+ timer/key-info package, an experience bar, and a Dragonriding UI.
- Those auras were built around an earlier expansion/UI and would substantially overlay or duplicate the Forever-like action/cooldown presentation. Some combat logic is also constrained by Midnight's Secret Values restrictions.
- Community controller users do successfully pair WeakAuras with ConsolePort; no direct controller binding collision was found. The reason to remove it from the initial test is visual/behavioral isolation and stale imported content, not incompatibility.
- Classification: remove/disable for the first Forever-like baseline while preserving SavedVariables. If later restored, update WeakAuras first and review/import only 12.x-compatible auras rather than automatically reviving all 341 displays.
- Sources: local saved configuration; https://github.com/WeakAuras/WeakAuras2/releases ; https://github.com/WeakAuras/WeakAuras2/issues/6138

### Raider.IO — installed copy is obsolete, but the project itself is not redundant

- Installed version is `10.2.7 (v202407302021)`, targeting interface 110000/110002. Its regional databases are likewise from July 2024.
- The official repository remains active; a current release reviewed is dated 2026-09-08. Raider.IO provides current/previous-season score context, raid progress, recruitment status, detailed dungeon history, tooltips, and group-search features beyond Blizzard's base rating.
- Its primary interaction is adding information to tooltips, Group Finder, unit-frame context menus, and search windows. No gamepad binding ownership or direct ConsolePort conflict was found.
- Stale score databases defeat the add-on's main purpose and may add mouse-oriented tooltip/UI clutter without trustworthy current data.
- Classification: remove the installed stale suite for the clean baseline. If the user wants its richer group-selection data later, reinstall/update the complete current suite rather than retaining this snapshot.
- Sources: https://github.com/RaiderIO/raiderio-addon ; https://github.com/RaiderIO/raiderio-addon/releases

## Batch 6 findings: maintenance and utility add-ons

### Simulationcraft — useful export tool, but the installed copy is stale

- Installed version `11.0.2-02` targets interface 110002. The maintained project has a 12.1-era release (`12.1.0-04`, reviewed 2026-09-26).
- Its purpose is deliberately narrow: `/simc` serializes the character, equipped gear, talents, bags, and related data for external simulation. It does not continuously own gamepad input and no ConsolePort integration or collision was found.
- No Simulationcraft SavedVariables were found, so removing this installed folder does not discard a local profile.
- Classification: remove the stale installed copy for the clean baseline. Reinstall the current release later if the user actively uses Raidbots/SimulationCraft. This is maintenance cleanup, not a controller-compatibility fix.
- Sources: local TOC/source; https://github.com/simulationcraft/simc-addon/releases

### TradeSkillMaster_AppHelper — orphaned companion; remove

- Installed AppHelper is version 4.13 for interface 100105. The main `TradeSkillMaster` add-on folder is absent.
- AppHelper is a data bridge used with the TSM desktop application and base TSM add-on. Alone, it does not provide the normal TSM UI or workflow.
- No ConsolePort input conflict is needed to justify removal: this is an old orphan whose required consumer is missing.
- Classification: remove `TradeSkillMaster_AppHelper`. Preserve its SavedVariables per the user's instruction even though they are unlikely to be useful without the matching main add-on.
- Source: local folder inventory and TOC; https://support.tradeskillmaster.com/en_US/addon/which-addon-folders-are-included-in-tradeskillmaster

### Plumber — project is active, but this installed copy is stale and the loot replacement overlaps ConsolePort

- Installed Plumber is 1.3.6 for interface 110002. The authoritative project page lists 1.9.6 for current Retail/Forever, so the installed code predates the present client by a large margin.
- Plumber is a collection of optional UI modules rather than one atomic feature. Community Steam Deck users do combine it with ConsolePort, especially for its loot replacement, so the add-ons are not categorically incompatible.
- A separate user report describes both the Blizzard/ConsolePort loot presentation and Plumber loot presentation appearing together. That is anecdotal but consistent with functional overlap: `ConsolePort_World` already supplies controller-aware world/loot interaction, while current Plumber can replace loot UI.
- The installed 1.3.6 copy predates the current loot module and contains older expansion-specific features; its saved settings enable many War Within-era modules. Keeping it would not be a fair test of current Plumber or a clean Forever-like baseline.
- Classification: remove the stale installed folder. If restored, install current Plumber and enable only individually wanted modules, testing the loot module last against `ConsolePort_World`.
- Sources: local TOC/source and SavedVariables; https://www.curseforge.com/wow/addons/plumber/files/all ; https://www.reddit.com/r/WowUI/comments/1pt2q9s/ ; https://www.reddit.com/r/WowUI/comments/1kbu8kf/

### Copybara — redundant with the shared-template design; remove

- Installed 1.1.2 targets interface 100107. Its purpose is copying chat tabs and chat settings between characters.
- The account already uses a shared `_template_` character SavedVariables target for almost all characters. Copybara therefore solves a problem the junction strategy was designed to remove, while the three unlinked characters should be repaired at the filesystem layer rather than periodically copied.
- No gamepad or ConsolePort input ownership was found.
- Classification: remove. The reason is architectural redundancy plus age, not a controller collision.
- Sources: local TOC/source; https://github.com/MickeyPickey/Copybara

### WorldFlightMap — very old full map replacement; remove

- Installed version 9.0.2.1 targets interface 90002.
- The repository describes this as a personal fork of Semlar's older add-on. It replaces the modern flight map with a WorldMapFrame-based presentation, so it modifies one of the interfaces most likely to be navigated with ConsolePort's cursor.
- No current ConsolePort compatibility layer or active modern maintenance evidence was found.
- Classification: stale/unsupported and a large UI replacement. Remove for the baseline.
- Source: local source; https://github.com/AlternateFiction/WorldFlightMap

### tullaRange / tullaRange_Config — current enough, but it does not appear to service ConsolePort's own buttons

- Installed 12.2.0 supports 120100/120105 and the upstream project is maintained.
- Local source registers Blizzard action buttons through `ActionBarButtonEventsFrame`, hooks `ActionButton_UpdateRangeIndicator`, and disables the Blizzard `ActionBarButtonUpdateFrame` OnUpdate handler.
- ConsolePort_Bar uses its bundled LibActionButton objects with its own usable/range update path and `LABcolorsRange` setting. No registration of ConsolePort buttons with the Blizzard frame used by tullaRange was found.
- This means tullaRange is unlikely to add value to the ConsolePort crossbar itself. It can still color retained Blizzard bars, but that is redundant for a controller-first layout built around ConsolePort_Bar.
- Classification: remove `tullaRange` and `tullaRange_Config` for the clean baseline. This is functional redundancy, not a proven breakage.
- Sources: local source; https://github.com/tullamods/tullaRange

### SharedMedia_Causese — hard practical dependency of the retained Plater profile; keep

- This package registers a large library of encounter and utility sounds through LibSharedMedia. It does not own controller input.
- The retained account Plater SavedVariables contain 164 direct paths into `Interface\\Addons\\SharedMedia_Causese\\sound\\...`, including `Front.ogg`, `CC.ogg`, and `Jump.ogg` across spell alerts.
- Deleting it would leave Plater installed and apparently functional while silently breaking those audible cues. That local dependency is stronger evidence than whether the media pack is visually related to Forever.
- Classification: keep. If Plater's imported scripts/mods are later replaced, re-audit the references before considering removal.
- Sources: local Plater SavedVariables and SharedMedia_Causese source; https://www.curseforge.com/wow/addons/sharedmedia_causese

### UnlimitedMapPinDistance — compatible QoL, but changes the target navigation baseline

- Installed 1.4.18 supports the present Retail interface and the project is current.
- It removes Blizzard's distance limit for user waypoints/map pins. If TomTom is absent, it can also provide a `/way` fallback.
- It does not own gamepad buttons or ConsolePort cursor nodes. The reason to remove it is that it changes map/navigation rules while the target is the stock Forever feel.
- Classification: compatible but optional. Remove on the first baseline pass; restore later if unlimited map pins are desired. If both it and TomTom are removed, the extra `/way` workflow also disappears.
- Source: local source; https://www.curseforge.com/wow/addons/unlimited-map-pin-distance/files/all

## Batch 7 findings: user-nominated removal candidates

### Khesyc_iLvl — current utility, safe user-requested removal

- Installed `5.4.260717` targets interface 120007 and is recent enough that it should not be described as abandoned.
- It hooks tooltip/character update paths and calls `NotifyInspect` to add specialization, item level, weapons, durability, gems, and Mythic+ rating to player information.
- No PAD binding, secure action ownership, or ConsolePort integration was found. Searches found no meaningful ConsolePort-specific user report.
- Classification: compatible tooltip enhancement, but removable at the user's request. Its information overlaps native character/item-level/rating presentation and adds mouseover-oriented detail that is not needed for a clean controller UI.
- Source: local source; https://www.curseforge.com/wow/addons/khesyc-ilvl/files/all

### Molinari — maintained, but its mouse-modifier interaction is redundant with ConsolePort item actions

- Installed `120100.147` is current for Retail and the official repository is active.
- It creates a secure action button over the currently hovered bag item and invokes milling, prospecting, disenchanting, lockpicking, or salvage through Alt+left-click (optionally another keyboard modifier).
- No PAD binding collision was found. However, the core interaction is explicitly mouse-hover plus modifier, while ConsolePort/BetterBags provide controller cursor and contextual item actions. That makes Molinari awkward rather than technically incompatible.
- Classification: safe user-requested removal. This consolidates item handling into the controller-native path.
- Sources: local source; https://github.com/p3lim-wow/Molinari ; https://www.pcgamer.com/games/world-of-warcraft/playing-world-of-warcraft-with-a-controller-might-become-my-preferred-playstyle-thanks-to-this-excellent-gamepad-friendly-addon-thats-letting-me-enjoy-azeroth-from-my-couch/

### Pawn — maintained and compatible, but not required by BetterBags

- Installed 2.13.16 is current and Pawn remains actively maintained.
- No gamepad ownership or ConsolePort conflict was found. A controller UI shared by a community user includes Pawn, supporting coexistence.
- BetterBags contains explicit optional Pawn integration and will prefer Pawn as an upgrade provider when Pawn is installed. BetterBags also has its own built-in upgrade provider, so removing Pawn does not break BetterBags; it changes how upgrade arrows are calculated.
- The current BetterBags SavedVariables do not pin an explicit `upgradeIconProvider`, so Pawn is likely being selected automatically while present.
- Classification: safe user-requested removal, with one visible consequence: BetterBags upgrade indicators may change. Pawn is not literally baked into Retail; its weighted stat comparison is richer than native item-level cues, but it is optional for this goal.
- Sources: local BetterBags/Pawn source and SavedVariables; https://github.com/vgermods/pawn ; https://www.curseforge.com/wow/addons/pawn/files/7451253 ; https://www.reddit.com/r/WowUI/comments/1rpf7c5/

### PersistentWorldMap — maintained but directly changes controller-visible map behavior

- Installed 1.17.8 is current.
- It hooks WorldMapFrame scrolling, zooming, panning, hide behavior, side-panel clicks, and restoration of map state. No gamepad binding ownership was found.
- It overlaps Leatrix Maps in the same interface and changes exactly the map state/close behavior that should remain stock while comparing ConsolePort with Forever.
- Classification: safe user-requested removal. The reason is behavioral overlap and baseline fidelity, not incompatibility.
- Source: local source; https://www.curseforge.com/wow/addons/persistent-world-map

### TomTom — maintained and ConsolePort-compatible, but removable for a stock navigation baseline

- Installed v4.3.11 is current and its changelog includes Forever support in the preceding v4.3.10 release.
- It adds `/way`, a directional arrow, map pins, modifier-click map handling, and map-dropdown entries. It does not bind PAD inputs.
- ConsolePort cursor SavedVariables contain TomTom dropdown/frame history, showing the two add-ons have been used together rather than proving a conflict.
- Removing TomTom loses its waypoint arrow and integrations used by other add-ons/macros. If `UnlimitedMapPinDistance` remains it can supply a simpler `/way` fallback; if both are removed, that workflow is intentionally gone.
- Classification: safe user-requested removal for a closer stock/Forever map experience. Preserve its SavedVariables as requested.
- Sources: local source and ConsolePort SavedVariables; https://github.com/MURPHYENGINEERING/tomtom

## Batch 8 findings: map, collection, and visual suites

### BetterWardrobe / BetterWardrobe_SourceData — current, not controller-integrated, optional removal

- Installed 6.12.3 targets interface 120100 and upstream development is active.
- It substantially replaces/extends collections and transmog UI, adding custom sets, previews, mouse actions, and data. No ConsolePort API integration or gamepad bindings were found.
- The project can share its sets pool with Narcissus when Narcissus is installed, but each add-on has a fallback and this is not a hard dependency.
- Its custom collection controls may rely on ConsolePort's generic cursor rather than explicit nodes. Current upstream issues show continuing UI bugs, but none reviewed establishes a ConsolePort-specific incompatibility.
- Classification: remove both folders for the first stock/Forever-like baseline if the user does not need the collection enhancements. It is current and useful, so call this optional simplification—not retirement.
- Sources: local source; https://github.com/SLOKnightfall/BetterWardrobe ; https://github.com/SLOKnightfall/BetterWardrobe/issues

### BtWQuests and all data packs — useful but large, custom, and unnecessary for the baseline

- Installed base 2.63.2 supports current Retail, and the installed data packs cover many old expansions plus Midnight.
- It provides a custom quest-chain browser, map pins, and navigation frame. No ConsolePort API integration or PAD binding ownership was found; the ConsolePort cursor has previously tracked its main frame.
- The project documents a known sequence in which opening the quest log from BtWQuests and then Edit Mode can disturb dragonriding keybindings until reload/logout. This is not specifically a ConsolePort defect, but it is relevant when evaluating controller bindings.
- Classification: remove the base and all packs for the first clean baseline. If the user values quest-chain tracking, reinstall/retain only the base plus currently relevant expansion packs and retest that known sequence.
- Source: local source/metadata and authoritative project page: https://www.wowinterface.com/downloads/info24680

### HandyNotes / TravelGuide / TheWarWithin — compatible map overlays, optional removal

- HandyNotes base 1.6.31 and TravelGuide 2.26.0 are maintained. The War Within pack is old-expansion content in the present client.
- These add pins and tooltips to maps. They do not own gamepad input and no ConsolePort-specific conflict was found.
- Local HandyNotes SavedVariables include custom notes; preserving SavedVariables therefore matters even if code is removed.
- Classification: remove all three for an uncluttered stock-map baseline. If restored, keep base plus only the travel/current-expansion modules actually wanted.
- Sources: local source/SavedVariables; https://www.wowace.com/projects/handynotes

### HealthBarColor — current visual customization, overlapping with Leatrix Plus

- The installed package supports Retail 120100 and the project remains current.
- It changes colors/textures of Blizzard player, target, focus, boss, pet, and party frames. It does not bind controller input.
- Leatrix Plus is also configured to class-color several frames, producing duplicated visual ownership. Neither is needed to test the intended Forever-like presentation.
- Classification: remove for the first baseline. This is a visual-fidelity decision, not an incompatibility claim.
- Source: local source; https://www.curseforge.com/wow/addons/healthbarcolor

### Leatrix Maps — compatible, but configured to change many map behaviors

- Installed 12.1.06 is current.
- Current saved settings enable no map fade, movement/resizing features, coordinates, revealed unexplored map areas, extra icons, hidden town/city art, and several filter/interaction changes.
- It does not own gamepad input, but it overlaps PersistentWorldMap and materially changes the map experience being compared.
- Classification: remove for the clean baseline. It can be reintroduced feature-by-feature later.
- Sources: local SavedVariables/source; https://www.curseforge.com/wow/addons/leatrix-maps

### Leatrix Plus — compatible multipurpose QoL, but it currently changes the entire baseline

- Installed 12.1.06 is current.
- Enabled settings include a square/minimally modified minimap and button bag, hidden UI buttons, class-colored unit frames, maximum camera zoom, hidden action-bar macro text, chat-button changes, auto-sell/repair, auto-resurrection/summon acceptance, and more.
- No direct PAD binding ownership was found, and controller users publicly report pairing Leatrix Plus/Maps with ConsolePort. The concern is not compatibility; it is that camera, minimap, frame colors, chat, and several behaviors would all differ during the comparison.
- Classification: remove for the first baseline, then selectively restore only desired QoL after ConsolePort is validated.
- Sources: local SavedVariables/source; https://www.curseforge.com/wow/addons/leatrix-plus ; https://www.reddit.com/r/wow/comments/zfjhao/

### LiteMount — active user configuration and positive ConsolePort use; keep conditionally

- Installed 12.1.0-1 is current. The account has a large customized LiteMount database with rules, priorities, and backups, showing substantive use.
- LiteMount supplies a secure callable mount action but does not continuously seize PAD inputs. Community ConsolePort users bind it directly, including to R3 or a ConsolePort ring.
- Forever uses important stick-click/utility mappings, so retaining LiteMount should not mean blindly keeping an R3 binding. Place its action on an explicit action slot or utility ring after the target mapping is established.
- Classification: keep unless the user prefers native random-favorite mount behavior and is willing to discard the add-on's runtime functionality. It is compatible and actively configured; the only issue is deliberate binding placement.
- Sources: local SavedVariables/source; https://www.curseforge.com/wow/addons/litemount ; https://www.reddit.com/r/wow/comments/zfjhao/ ; https://www.reddit.com/r/wow/comments/uri746/

### ParagonReputation — current minor QoL, optional removal

- Installed 1.78 targets current Retail.
- It alters reputation bars and can add paragon-related notification/toast behavior. No ConsolePort integration or binding ownership was found.
- Classification: remove for the clean baseline because it is a small, nonessential native-UI enhancement. It is not obsolete or incompatible.
- Source: local source; https://www.curseforge.com/wow/addons/paragon-reputation
