# ConsolePort / WoW Forever add-on compatibility and cleanup recommendation

Last researched: 2026-09-26  
Scope: compatibility basis for the approved 2026-09-26 implementation. Research was read-only; the later implementation uses the revised manifest below.

Implementation status: **executed offline on 2026-09-26**. All 80 approved folders were moved out of the live `Interface\AddOns` directory into `Removed AddOns 2026-09-26`; the live directory now contains exactly the 40 retained folders. This recoverable quarantine has the same runtime effect as deletion while preserving an easy rollback. No SavedVariables belonging to removed add-ons were deleted or moved.

## Executive conclusion

The installed add-on collection does not contain a broad, general incompatibility with ConsolePort. Most add-ons fall into one of three less dramatic categories:

1. they coexist safely but make the UI look or behave unlike the clean Forever controller baseline;
2. the installed copy is stale, retired, or orphaned even though the project may still exist;
3. they duplicate a controller-facing feature already handled by ConsolePort or a retained add-on.

Only one reviewed add-on has a strong, direct ownership overlap with controller back/cancel and panel navigation: **NoAutoClose**. It rewrites Blizzard panel opening/closing behavior and installs a high-priority Escape override, so it should not be present while validating ConsolePort navigation.

The recommended clean first-pass stack is:

- the complete ConsolePort suite;
- Immersion plus its compatible ExtraFade companion;
- DynamicCam, configured for controlled couch-style camera transitions;
- BetterBags;
- Plater;
- SharedMedia_Causese, because the current Plater profile directly references its sounds;
- the complete DBM suite;
- Masque, with ConsolePort groups left on a neutral/default skin;
- LiteMount, because it is current, compatible, and heavily configured, but with its action deliberately placed away from Forever's stick-click targeting/utility controls.

Everything else can be removed as add-on code for the first pass while preserving SavedVariables. That is a baseline/isolation recommendation, not a claim that every removed project is broken.

## Decision standard

Each family was checked against some combination of:

- installed TOC/version metadata;
- installed Lua/XML for bindings, secure buttons, cursor nodes, frame hooks, map/camera changes, or explicit ConsolePort integration;
- account and shared-character SavedVariables for evidence of real use and hidden dependencies;
- the official repository or authoritative project page;
- ConsolePort issues and controller-user reports where a meaningful report exists.

The labels in this document mean:

- **Keep** — directly integrates with the intended stack, supplies a retained dependency, or has controller-specific value.
- **Remove: conflict/overlap** — competes with controller input, panel semantics, or a ConsolePort-owned feature.
- **Remove: stale/orphaned** — the installed code is obsolete, retired, or missing its required main add-on.
- **Remove: clean baseline** — compatible software that is intentionally excluded so Forever-like behavior can be judged without other UI/camera/map replacements.
- **Optional later** — safe to reinstall or re-enable after the controller baseline works.

## Recommended first-pass keep set

### 1. ConsolePort suite — keep all modules

Exact folders:

- `ConsolePort`
- `ConsolePort_Bar`
- `ConsolePort_Config`
- `ConsolePort_Cursor`
- `ConsolePort_Keyboard`
- `ConsolePort_Menu`
- `ConsolePort_Rings`
- `ConsolePort_Target`
- `ConsolePort_World`

The Forever-like design needs the crossbar, cursor, menu, rings, targeting, keyboard, and world-interaction modules. Removing individual modules would undermine the configuration under evaluation.

### 2. Immersion and ExtraFade — keep

Exact folders: `Immersion`, `Immersion_ExtraFade`

This is an unusually strong compatibility case. Immersion declares ConsolePort as an optional dependency, has a dedicated ConsolePort controller/hint handler, and includes compatibility exclusions for ConsolePort cursor/mouse/hint frames. It shares ConsolePort's author and is designed to cooperate with it.

`Immersion_ExtraFade` is not by Immersion/ConsolePort author MunkDev; its installed TOC credits LudiusMaximus, also DynamicCam's current maintainer. It declares Immersion as a required dependency, is current for interface 120100, and does not bind PAD inputs. The user chose to retain its additional dialogue fading.

### 3. DynamicCam — keep and configure

Exact folder: `DynamicCam`

DynamicCam is current, does not compete for controller bindings, and its built-in NPC Interaction situation explicitly watches `ImmersionFrame`. It is retained with a restrained, saved-view-free profile: smooth situation zooms for interiors, combat, instances, mounts, flying, NPC dialogue, mailbox, fishing, gathering, and swimming; no automatic rotation; no enemy-focus steering; and no UI hiding. Full values are in `ConsolePort-Forever-Configuration-Plan.md`.

### 4. BetterBags — keep

Exact folder: `BetterBags`

BetterBags contains explicit ConsolePort integration. It registers backpack, bank, and context-menu frames with ConsolePort's interface cursor and supplies cursor nodes. That is substantially better evidence than merely being usable with a virtual mouse.

Removing Pawn will not break BetterBags. BetterBags has its own upgrade provider; only the source/calculation behind upgrade arrows will change.

### 5. Plater — keep

Exact folder: `Plater`

The installed Plater source contains a ConsolePort-specific workaround to avoid a stack-overflow path, and controller users report the pair working together. There is no normal-gameplay PAD binding ownership in Plater.

Recommended ownership split:

- Plater owns nameplate appearance and alerts.
- ConsolePort owns targeting.
- ConsolePort options that forcibly enable/alter nameplates should be tested separately. ConsolePort issue #159 demonstrates missing default health bars from ConsolePort's own nameplate/interact options, so such a symptom should not automatically be blamed on Plater.

### 6. SharedMedia_Causese — keep because Plater uses it

Exact folder: `SharedMedia_Causese`

The current Plater SavedVariables contain **164 direct file references** into `Interface\Addons\SharedMedia_Causese\sound\...`. Examples include `Front.ogg`, `CC.ogg`, and `Jump.ogg`.

Deleting this media pack would not necessarily generate an obvious startup failure; it would silently remove audible warnings from retained Plater scripts/mods. Reassess it only after replacing or auditing the Plater profile.

### 7. Deadly Boss Mods — keep the suite

Exact folders: every installed `DBM-*` folder, including Core, GUI, current and legacy encounter modules, tests, status bars, and VPVEM.

DBM is current and has positive controller-specific value: current source can invoke Blizzard gamepad vibration for supported warnings. Native encounter timelines overlap only part of DBM's value; they do not replace its encounter scripting, customized warnings, sounds, modules, reports, or vibration.

### 8. Masque — keep the engine

Exact folder: `Masque`

ConsolePort_Bar and its bundled LibActionButton deliberately detect Masque and register ConsolePort buttons/groups. BetterBags, DBM, Plater, and other installed add-ons also consume it.

The current SavedVariables do not show a custom skin forced onto ConsolePort groups. Keep Masque and choose the default/native appearance for those groups. Remove only the ancient optional `Masque_CleanIcons` skin.

### 9. LiteMount — keep, but assign its binding intentionally

Exact folder: `LiteMount`

LiteMount is current, does not continuously seize gamepad controls, and has a large customized local database with rules and mount priorities. Controller users bind it successfully through ConsolePort, including on rings.

Do not automatically reuse R3 just because some community profiles do so. Forever gives stick clicks and utility controls important duties. Put LiteMount on a normal action slot or a deliberate utility-ring slice after the final mapping exists.

## Approved first-pass removal manifest

This set was executed by moving add-on code directories out of the live AddOns tree. SavedVariables remained in place.

### A. Strong removal: direct ownership overlap

- `NoAutoClose`

Reason: it hooks the UI panel manager, changes panel attributes and `UISpecialFrames`, overrides close behavior, and installs a high-priority Escape binding. This can directly change what ConsolePort's Circle/B/back action closes and where focus returns.

### B. Strong removal: stale, retired, or orphaned installed code

- `Copybara`
- `ls_Glass`
- `Masque_CleanIcons`
- `Plumber`
- `RaiderIO`
- `RaiderIO_DB_EU_F`
- `RaiderIO_DB_EU_M`
- `RaiderIO_DB_EU_R`
- `RaiderIO_DB_KR_F`
- `RaiderIO_DB_KR_M`
- `RaiderIO_DB_KR_R`
- `RaiderIO_DB_TW_F`
- `RaiderIO_DB_TW_M`
- `RaiderIO_DB_TW_R`
- `RaiderIO_DB_US_F`
- `RaiderIO_DB_US_M`
- `RaiderIO_DB_US_R`
- `Simulationcraft`
- `TradeSkillMaster_AppHelper`
- `WeakAuras`
- `WeakAurasArchive`
- `WeakAurasCompanion`
- `WeakAurasModelPaths`
- `WeakAurasOptions`
- `WeakAurasTemplates`
- `WorldFlightMap`
- `ZenFishing`

Important distinctions:

- **ls_Glass** is officially retired and will not receive Midnight updates.
- **TSM AppHelper** is old and orphaned because the main TradeSkillMaster folder is absent.
- **WorldFlightMap** is a 9.0-era personal fork and full map/flight-map replacement.
- **Raider.IO** itself remains valuable and maintained, but this installed suite/databases are from July 2024. If wanted, reinstall the whole current suite later.
- **Simulationcraft** remains maintained, but the installed 11.0.2 exporter is stale. Reinstall current code later if `/simc` exports are used.
- **WeakAuras** is not controller-incompatible, but the installed 5.21.1 copy is behind and the 2.16 MB account database contains 341 mostly older-expansion displays, including War Within packages and Dragonriding UI. Update first and selectively restore only current auras later.
- **Plumber** is actively maintained, but the installed 1.3.6 build is old. Current controller users do combine Plumber and ConsolePort; the loot module is the part that should be tested last because it overlaps ConsolePort_World's loot presentation.

### C. User-nominated removals: current and safe, but not broken

- `Khesyc_iLvl`
- `Molinari`
- `Pawn`
- `PersistentWorldMap`
- `TomTom`

Consequences:

- **Khesyc_iLvl:** removes inspection/tooltip additions; no ConsolePort collision was found.
- **Molinari:** removes Alt+mouse-hover processing for disenchant/mill/prospect/etc.; controller contextual item handling remains.
- **Pawn:** BetterBags remains functional but its upgrade-arrow provider/calculation can change.
- **PersistentWorldMap:** returns world-map close/zoom/pan restoration behavior to the remaining stock UI.
- **TomTom:** removes `/way`, the crazy arrow, custom map pins/dropdowns, and integrations that expect TomTom. The ConsolePort ring is not dependent on TomTom.

### D. Remove to establish a stock/Forever-like baseline

- `BetterWardrobe`
- `BetterWardrobe_SourceData`
- `BlizzMove`
- `BlizzMove_Debug`
- `BtWQuests`
- every installed `BtWQuests*` expansion/prologue data folder
- every installed `Details*` folder
- `EditModeExpanded`
- `HandyNotes`
- `HandyNotes_TheWarWithin`
- `HandyNotes_TravelGuide`
- `HealthBarColor`
- `Leatrix_Maps`
- `Leatrix_Plus`
- `Myslot`
- every installed `Narcissus*` folder
- `OPie`
- `OPieMasque`
- `ParagonReputation`
- `tullaRange`
- `tullaRange_Config`
- `UnlimitedMapPinDistance`
- `WIM`

These are not a single risk class. Details are below.

## Complete family-by-family matrix

| Family | Installed condition | ConsolePort/controller evidence | Recommendation | Confidence |
|---|---|---|---|---|
| BetterBags | Current | Explicit ConsolePort cursor integration | **Keep** | High |
| BetterWardrobe + SourceData | Current | No explicit integration; custom collections UI relies on generic cursor | Remove for baseline; optional later | Medium-high |
| BlizzMove + Debug | Current | Moves frames; no binding ownership | Remove for stock positions; safe later | High |
| BtWQuests + packs | Current | Custom quest UI; known Edit Mode sequence can break dragonriding binds until reload | Remove for baseline; current packs only if restored | High |
| ConsolePort suite | Current | Target platform | **Keep all** | High |
| Copybara | Old | No input conflict; redundant with shared character template | Remove | High |
| DBM suite | Current | Direct controller vibration support | **Keep** | High |
| Details suite | Current | No PAD collision; native meter only partially duplicates it | Remove for clean baseline; safe later | High |
| DynamicCam | Current | Built-in NPC state explicitly detects ImmersionFrame; no PAD ownership | **Keep; use controlled couch profile** | High |
| EditModeExpanded | Current | Layout hooks only; no PAD ownership | Remove for stock layout; safe later | High |
| HandyNotes suite | Current base/plugins | Map pins only; no PAD ownership | Remove for stock map; safe later | High |
| HealthBarColor | Current | Unit-frame visual changes only | Remove for visual baseline | High |
| Immersion | Current | Dedicated ConsolePort integration | **Keep** | High |
| Immersion_ExtraFade | Current | Current required-dependency companion by DynamicCam maintainer; no PAD ownership | **Keep** | High |
| Khesyc_iLvl | Current | Tooltip/inspect additions; no PAD ownership | Remove as requested | High |
| Leatrix Maps | Current | Many active map behavior changes | Remove for map baseline | High |
| Leatrix Plus | Current | Many active camera/minimap/frame/chat changes; controller users coexist | Remove for baseline; selectively restore | High |
| LiteMount | Current, heavily configured | Common ConsolePort binding/ring use; no continuous ownership | **Keep; rebind deliberately** | High |
| ls_Glass | Retired | Full chat replacement | Remove | High |
| Masque | Current | Explicit ConsolePort_Bar integration | **Keep** | High |
| Masque_CleanIcons | Interface 7.2-era skin | Visual skin only | Remove | High |
| Molinari | Current | Mouse-modifier item action; no PAD collision | Remove as requested | High |
| MySlot | Current enough | Import can overwrite bars/binds; no runtime conflict | Remove or keep disabled externally; baseline says remove | High |
| Narcissus suite | Current | GamePad module supplies scoped Narcissus navigation; achievements asks ConsolePort to ignore its frame | Remove whole suite only; never retain base while deleting GamePad merely for compatibility | High |
| NoAutoClose | Current | Panel-manager hooks plus high-priority Escape override | **Remove: real ownership overlap** | High |
| OPie + OPieMasque | Current base; old skin bridge | Duplicates radial menu; no active OPie profile content found | Remove; retain independent ConsolePort ring | High |
| ParagonReputation | Current | Reputation bar/toast QoL only | Remove for baseline | High |
| Pawn | Current | Compatible; optional BetterBags provider | Remove as requested | High |
| PersistentWorldMap | Current | World-map state/scroll/close hooks | Remove as requested | High |
| Plater | Current | Explicit workaround and real-world coexistence | **Keep** | High |
| Plumber | Installed copy stale; project current | Current users coexist; loot UI can overlap | Remove installed copy; selectively reinstall current later | High |
| Raider.IO suite | Installed copy/databases from 2024; project current | No PAD collision | Remove stale suite; reinstall current if wanted | High |
| SharedMedia_Causese | Current enough as media | 164 direct retained Plater references | **Keep** | High |
| Simulationcraft | Installed copy stale; project current | Export command only | Remove stale copy; update if used | High |
| TomTom | Current | Compatible; map click/pins/dropdowns navigable via cursor | Remove as requested | High |
| TSM AppHelper | Old and orphaned | Main TSM absent | Remove | High |
| tullaRange + Config | Current | Targets Blizzard action buttons; no evidence it services ConsolePort_Bar buttons | Remove as redundant | Medium-high |
| UnlimitedMapPinDistance | Current | No PAD ownership; changes navigation rule | Remove for baseline | High |
| WeakAuras suite | Installed core behind; 341 older displays | Commonly coexists; major visual overlay | Remove installed suite for baseline; update/curate later | High |
| WIM | Current | Custom whisper UI; no explicit cursor nodes or PAD collision | Remove for controller-first baseline; uncertain navigation if restored | Medium |
| WorldFlightMap | Very old | Full map/flight replacement | Remove | High |
| ZenFishing | Old | Overrides mouse BUTTON2, not a PAD key | Remove | High |

## The interactions that matter most

### NoAutoClose is the clearest real conflict

Most UI add-ons merely draw or reposition something. NoAutoClose is different: it changes the mechanisms ConsolePort relies on when the controller's back/cancel input should close panels. Bugs could present as Circle/B doing nothing, several panels remaining open, or cursor focus returning to the wrong frame. It should be absent from the first test even though the add-on itself is current.

### Plater must keep SharedMedia_Causese

This is a local, data-backed dependency. It is not shown as a required dependency in Plater's TOC because the references live inside imported Plater scripts/mods. A generic add-on manager would not know that deleting the media pack breaks sounds.

### Pawn removal changes BetterBags output, not BetterBags stability

BetterBags detects Pawn as an optional upgrade provider. With Pawn gone, BetterBags should fall back to its own provider. The expected change is different or fewer upgrade arrows, not a broken bag UI.

### OPie is presently safer to remove than expected

The current OPie SavedVariables have no meaningful configured profile/ring contents. The separately saved ConsolePort ring named `OPie` contains five independent slices: Conjure Refreshment, Conjured Mana Bun, Time-Lost Artifact, Dalaran Hearthstone, and Eternal Traveler's Hearthstone. That ring belongs to ConsolePort and should survive removal of the OPie add-on folders.

The name is historical and can later be changed to something like `Utility` without changing its purpose.

### Narcissus should be kept or removed as a suite

Narcissus_GamePad is not a rogue global controller binder. It supplies temporary navigation inside Narcissus, clears its override bindings as context changes, and exits during combat. Narcissus Achievements specifically asks ConsolePort to ignore its root frame. Removing only GamePad while retaining the rest can make the retained custom UI less accessible. For the first baseline, remove all `Narcissus*`; if restored later, restore the GamePad module too.

### Current projects can still have stale installed copies

Raider.IO, Plumber, Simulationcraft, and WeakAuras are not dead projects. The recommendation is to remove the particular installed copies/configuration from the baseline, then reinstall current versions only when their value is wanted. This avoids mislabeling maintained projects as obsolete.

### Leatrix Plus is compatible but masks the target result

The active profile changes the minimap, addon buttons, unit-frame colors, camera zoom, macro text, chat controls, auto-repair/sell, and confirmation behavior. Any comparison with Forever would otherwise mix ConsolePort changes with Leatrix changes. Remove it first; later restore individual QoL features with intent.

### DynamicCam is about feel, not stability

DynamicCam does not fight ConsolePort for controls, and its NPC state includes explicit Immersion frame detection. The implementation therefore retains it but limits it to deterministic zoom and restrained interact focus. Automatic rotation, enemy-focus steering, AFK motion, and DynamicCam UI hiding remain off.

## What will be lost from the first-pass removal

The proposed cleanup intentionally gives up these functions until selectively restored:

- Details' historical segments, breakdowns, reporting, plugins, and death analysis;
- WeakAuras' imported displays;
- Raider.IO's richer score/history/recruitment information;
- TomTom's waypoint arrow and `/way` ecosystem;
- HandyNotes pins and travel markers;
- BtWQuests' curated quest-chain graph;
- BetterWardrobe's enhanced set/collection tools;
- Narcissus' character/studio/achievement presentation;
- WIM's separate whisper/history windows;
- Leatrix's broad QoL automation;
- OPie's second radial-menu system;
- Pawn's weighted item comparison;
- Molinari's modifier-click profession shortcuts.

This is why the SavedVariables should remain. The code can be reinstalled later without discarding the user's historical configuration.

## Runtime verification order

The offline inventory, junction repair, cleanup, and profile edits are complete. On first login, verify these controller paths:

1. Verify the following controller paths:
   - enter world and move/camera;
   - base, L2/LT, R2/RT, and both-trigger action layers;
   - friendly/enemy target cycling;
   - interaction and loot;
   - open/close bags and a BetterBags context menu;
   - world map zoom/pan/close;
   - quest dialogue in Immersion;
   - Game Menu and Settings back/cancel behavior;
   - Plater health bars plus audible alerts;
   - DBM test warning/vibration;
   - ConsolePort utility ring and LiteMount action.
2. Only after the baseline passes, restore optional add-ons one family at a time. Test navigation after each UI/camera/map family rather than restoring the entire old stack at once.

## Suggested optional restoration order

From least likely to obscure controller behavior to most likely:

1. Details
2. BlizzMove and EditModeExpanded
3. current Raider.IO
4. current Simulationcraft
5. BetterWardrobe or Narcissus, one at a time
6. selected HandyNotes/BtWQuests modules
7. current, curated WeakAuras
8. selected Leatrix Plus features
9. current Plumber, with its loot replacement tested last

NoAutoClose should remain last of all and should be restored only if its behavior is important enough to justify retesting every back/cancel path.

## Machine-checked exact first-pass manifest

The installed AddOns directory contained 120 folders when this report was written. The revised split accounts for all 120: **40 retained, 80 approved for removal**.

Retain exactly:

```text
BetterBags
ConsolePort
ConsolePort_Bar
ConsolePort_Config
ConsolePort_Cursor
ConsolePort_Keyboard
ConsolePort_Menu
ConsolePort_Rings
ConsolePort_Target
ConsolePort_World
DBM-Azeroth
DBM-Brawlers
DBM-BrokenIsles
DBM-Cataclysm
DBM-Challenges
DBM-Core
DBM-Draenor
DBM-GUI
DBM-Lairs-Midnight
DBM-Midnight
DBM-Pandaria
DBM-Raids-Cata
DBM-Raids-Legion
DBM-Raids-Midnight
DBM-Raids-MoP
DBM-Raids-Vanilla
DBM-Raids-WoD
DBM-Raids-WoTLK
DBM-Scenario-MoP
DBM-StatusBarTimers
DBM-Test
DBM-Test-Vanilla
DBM-VPVEM
DynamicCam
Immersion
Immersion_ExtraFade
LiteMount
Masque
Plater
SharedMedia_Causese
```

Proposed removal exactly:

```text
BetterWardrobe
BetterWardrobe_SourceData
BlizzMove
BlizzMove_Debug
BtWQuests
BtWQuestsBattleForAzeroth
BtWQuestsBattleForAzerothPrologue
BtWQuestsCataclysm
BtWQuestsDragonflightPrologue
BtWQuestsLegion
BtWQuestsMidnight
BtWQuestsMistsOfPandaria
BtWQuestsShadowlands
BtWQuestsShadowlandsPrologue
BtWQuestsTheBurningCrusade
BtWQuestsWarlordsOfDraenor
BtWQuestsWrathOfTheLichKing
Copybara
Details
Details_Compare2
Details_DataStorage
Details_EncounterDetails
Details_RaidCheck
Details_Streamer
Details_TinyThreat
Details_Vanguard
EditModeExpanded
HandyNotes
HandyNotes_TheWarWithin
HandyNotes_TravelGuide
HealthBarColor
Khesyc_iLvl
Leatrix_Maps
Leatrix_Plus
ls_Glass
Masque_CleanIcons
Molinari
Myslot
Narcissus
Narcissus_Achievements
Narcissus_BagFilter
Narcissus_Barbershop
Narcissus_Database_Item
Narcissus_Database_NPC
Narcissus_GamePad
NoAutoClose
OPie
OPieMasque
ParagonReputation
Pawn
PersistentWorldMap
Plumber
RaiderIO
RaiderIO_DB_EU_F
RaiderIO_DB_EU_M
RaiderIO_DB_EU_R
RaiderIO_DB_KR_F
RaiderIO_DB_KR_M
RaiderIO_DB_KR_R
RaiderIO_DB_TW_F
RaiderIO_DB_TW_M
RaiderIO_DB_TW_R
RaiderIO_DB_US_F
RaiderIO_DB_US_M
RaiderIO_DB_US_R
Simulationcraft
TomTom
TradeSkillMaster_AppHelper
tullaRange
tullaRange_Config
UnlimitedMapPinDistance
WeakAuras
WeakAurasArchive
WeakAurasCompanion
WeakAurasModelPaths
WeakAurasOptions
WeakAurasTemplates
WIM
WorldFlightMap
ZenFishing
```

This revised manifest was approved by the user for the implementation pass. SavedVariables remain out of scope for deletion.

## Source index

Primary/authoritative sources:

- ConsolePort: https://github.com/seblindfors/ConsolePort
- ConsolePort nameplate issue #159: https://github.com/seblindfors/ConsolePort/issues/159
- BetterWardrobe: https://github.com/SLOKnightfall/BetterWardrobe
- BlizzMove: https://github.com/Kiatra/BlizzMove
- BtWQuests, including its controller-relevant keybinding known issue: https://www.curseforge.com/wow/addons/btw-quests
- DBM releases/source: https://github.com/DeadlyBossMods/DeadlyBossMods/releases
- Details: https://github.com/Tercioo/Details-Damage-Meter
- DynamicCam: https://github.com/mpstark/DynamicCam
- HandyNotes: https://www.wowace.com/projects/handynotes
- Immersion: https://github.com/Seblindfors/Immersion
- Leatrix Maps: https://www.curseforge.com/wow/addons/leatrix-maps
- Leatrix Plus: https://www.curseforge.com/wow/addons/leatrix-plus
- LiteMount: https://www.curseforge.com/wow/addons/litemount
- ls_Glass retirement notice: https://github.com/ls-/ls_Glass
- Masque: https://github.com/SFX-WoW/Masque
- Molinari: https://github.com/p3lim-wow/Molinari
- MySlot: https://github.com/tg123/myslot
- NoAutoClose: https://github.com/NumyAddon/NoAutoClose
- OPie issues: https://www.townlong-yak.com/addons/opie/issues
- Pawn: https://github.com/vgermods/pawn
- Plumber files: https://www.curseforge.com/wow/addons/plumber/files/all
- Raider.IO: https://github.com/RaiderIO/raiderio-addon/releases
- Simulationcraft add-on: https://github.com/simulationcraft/simc-addon/releases
- TomTom: https://github.com/MURPHYENGINEERING/tomtom
- tullaRange: https://github.com/tullamods/tullaRange
- WeakAuras: https://github.com/WeakAuras/WeakAuras2/releases
- WorldFlightMap fork: https://github.com/AlternateFiction/WorldFlightMap

Community evidence used only as supporting context, not as sole proof:

- Controller/ConsolePort add-on stack examples: https://www.reddit.com/r/wow/comments/zfjhao/
- Steam Deck stack including Plumber: https://www.reddit.com/r/WowUI/comments/1pt2q9s/
- Plumber/ConsolePort loot overlap report: https://www.reddit.com/r/WowUI/comments/1kbu8kf/
- Plater controller coexistence example: https://www.reddit.com/r/wow/comments/1jg5nna/
- LiteMount on ConsolePort rings: https://www.reddit.com/r/wow/comments/uri746/
- Pawn in a ConsolePort UI: https://www.reddit.com/r/WowUI/comments/1rpf7c5/

The detailed evidence notes, including installed-source observations for each family, remain in `ConsolePort-Addon-Compatibility-Ledger.md`.
