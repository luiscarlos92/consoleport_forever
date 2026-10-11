# CurseForge addon cleanup inventory — 2026-10-06

Checked the seven screenshots against CurseForge's saved Retail inventory, the actual live addon folders, shared AddOns.txt, and cached dependency release packages. Old planning documents were used as historical evidence, not as new instructions.

**61 CurseForge entries: keep/reinstall 18; remove 43.** The live AddOns directory contains 40 folders: 39 third-party folders and the separate custom ConsolePort_Forever companion. "Keep" means part of the currently retained installed interface; this audit does not measure actual in-game execution. HideClassBars is installed and part of the retained pack, although it has no explicit entry in shared AddOns.txt.

No game files, addon files, WTF settings, CurseForge records, or backup archives were changed during this audit.

## Actual paths

- Live addon files: `C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/_retail_/Interface/AddOns`
- Removed addon code from the earlier cleanup: `C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/Removed AddOns 2026-09-26`
- Saved settings: `C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/_retail_/WTF`
- User backup: `C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/Backup_Addons_20261006.rar`

The game's Program Files Interface and WTF folders are junctions to these OneDrive folders. They are the same files, not separate copies.

The RAR's directory listing was readable and contained 16,586 Interface entries and 3,876 WTF entries. This was a listing check, not a full extraction/CRC test.

## Keep and reinstall/update through CurseForge — 18 entries

Reinstall every retained entry, including entries marked up to date, to align CurseForge's installation records with its own packages. The table shows currently present folders; a complete official package may also supply additional folders.

| CurseForge entry | Currently present corresponding addon folders |
|---|---|
| BetterBags | `BetterBags` |
| ConsolePort | `ConsolePort`, `ConsolePort_Bar`, `ConsolePort_Config`, `ConsolePort_Cursor`, `ConsolePort_Keyboard`, `ConsolePort_Menu`, `ConsolePort_Rings`, `ConsolePort_Target`, `ConsolePort_World` |
| DBM - Deadly Boss Mods (DBM-Core) | `DBM-Core`, `DBM-GUI`, `DBM-StatusBarTimers`, `DBM-Lairs-Midnight`, `DBM-Midnight`, `DBM-Raids-Midnight`, `DBM-Test` |
| DynamicCam | `DynamicCam` |
| Immersion ExtraFade | `Immersion_ExtraFade` |
| DBM - Cataclysm mods | `DBM-Cataclysm`, `DBM-Raids-Cata` |
| DBM - Legion | `DBM-BrokenIsles`, `DBM-Raids-Legion` |
| DBM - Mists of Pandaria (MoP) | `DBM-Pandaria`, `DBM-Raids-MoP`, `DBM-Scenario-MoP` |
| DBM - SoD and Vanilla | `DBM-Raids-Vanilla` |
| DBM - Warlords of Draenor (WoD) | `DBM-Draenor`, `DBM-Raids-WoD` |
| DBM - Wrath of the Lich King | `DBM-Raids-WoTLK` |
| HideClassBars | `HideClassBars` |
| Immersion | `Immersion` |
| LiteMount | `LiteMount` |
| Masque | `Masque` |
| Plater Nameplates | `Plater` |
| project-61621 (DBM-Challenges) | `DBM-Brawlers`, `DBM-Challenges` |
| SharedMedia_Causese | `SharedMedia_Causese` |

Keep `DBM-VPVEM` too: this installed DBM voice pack is not a separate entry in the screenshots. Do not delete individual ConsolePort or DBM modules simply because they do not have separate manager rows.

`project-61621` is the DBM-Challenges entry, identified by its recorded ZIP and the installed TOC project ID. It is part of the retained DBM setup.

## Remove from CurseForge — 43 entries

**Every entry below is already absent from live Interface/AddOns.** Forty-one have corresponding code in the earlier removal archive. BeQuiet and BlizzHUDTweaks have no corresponding folder in either location.

The folder names below refer to `Removed AddOns 2026-09-26`, not to active addon files. You can remove those archived code folders as part of your cleanup if you no longer want that earlier rollback copy.

| CurseForge entry | Corresponding archived code folders |
|---|---|
| BeQuiet - Suppress Talking Heads | Already absent; no folder found in live AddOns or the removal archive |
| BlizzMove | `BlizzMove`, `BlizzMove_Debug` |
| Details! Damage Meter | `Details`, `Details_Compare2`, `Details_DataStorage`, `Details_EncounterDetails`, `Details_RaidCheck`, `Details_Streamer`, `Details_TinyThreat`, `Details_Vanguard` |
| Edit Mode Expanded | `EditModeExpanded` |
| Leatrix Maps | `Leatrix_Maps` |
| Leatrix Plus | `Leatrix_Plus` |
| Molinari | `Molinari` |
| Myslot | `Myslot` |
| NoAutoClose | `NoAutoClose` |
| OPie | `OPie` |
| TomTom | `TomTom` |
| tullaRange | `tullaRange`, `tullaRange_Config` |
| WIM (WoW Instant Messenger) v3 | `WIM` |
| Better Wardrobe and Transmog | `BetterWardrobe`, `BetterWardrobe_SourceData` |
| BlizzHUDTweaks | Already absent; no folder found in live AddOns or the removal archive |
| BtWQuests | `BtWQuests` |
| BtWQuests: Battle for Azeroth | `BtWQuestsBattleForAzeroth` |
| BtWQuests: Battle for Azeroth Prologue | `BtWQuestsBattleForAzerothPrologue` |
| BtWQuests: Cataclysm | `BtWQuestsCataclysm` |
| BtWQuests: Dragonflight Prologue | `BtWQuestsDragonflightPrologue` |
| BtWQuests: Legion | `BtWQuestsLegion` |
| BtWQuests: Mists of Pandaria | `BtWQuestsMistsOfPandaria` |
| BtWQuests: Shadowlands | `BtWQuestsShadowlands` |
| BtWQuests: Shadowlands Prologue | `BtWQuestsShadowlandsPrologue` |
| BtWQuests: The Burning Crusade | `BtWQuestsTheBurningCrusade` |
| BtWQuests: Warlords of Draenor | `BtWQuestsWarlordsOfDraenor` |
| BtWQuests: Wrath of the Lich King | `BtWQuestsWrathOfTheLichKing` |
| Copybara chat settings copy | `Copybara` |
| HandyNotes | `HandyNotes` |
| HandyNotes: The War Within | `HandyNotes_TheWarWithin` |
| HandyNotes: TravelGuide | `HandyNotes_TravelGuide` |
| HealthBarColor - Health Bar Color | `HealthBarColor` |
| Khes'yc iLvl | `Khesyc_iLvl` |
| Masque: Clean Icons | `Masque_CleanIcons` |
| Narcissus | `Narcissus`, `Narcissus_Achievements`, `Narcissus_BagFilter`, `Narcissus_Barbershop`, `Narcissus_Database_Item`, `Narcissus_Database_NPC`, `Narcissus_GamePad` |
| OPie Masque | `OPieMasque` |
| Paragon Reputation | `ParagonReputation` |
| Pawn | `Pawn` |
| Persistent World Map | `PersistentWorldMap` |
| project-699896 (ls_Glass) | `ls_Glass` |
| Unlimited Map Pin Distance | `UnlimitedMapPinDistance` |
| WeakAuras | `WeakAuras`, `WeakAurasArchive`, `WeakAurasCompanion`, `WeakAurasModelPaths`, `WeakAurasOptions`, `WeakAurasTemplates` |
| Zen Fishing | `ZenFishing` |

`project-699896` is `ls_Glass`, identified by the recorded ZIP.

## Other unused archived folders not listed in the screenshots

These are also absent from the live interface:

- `BtWQuestsMidnight`
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
- `WorldFlightMap`

## File integrity and why the manager disagrees

Compared **3,595 installed third-party files** with the local unpacked release packages. All compared bytes matched; no extra files or unexpected missing individual files were found inside the present folders. The 18 cached release ZIP hashes also matched the dependency lock. This is verification against the cached releases, not a check of the newest releases available today.

Several entire DBM folders from those packages are absent:

- `DBM-Delves-Midnight` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Delves-WarWithin` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-BC` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-BfA` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Cataclysm` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Dragonflight` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Forever` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Legion` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Midnight` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-MoP` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Shadowlands` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-Vanilla` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-WarWithin` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-WoD` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Party-WotLK` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Test-Dungeons` (DeadlyBossMods/DBM-Dungeons)
- `DBM-WorldEvents` (DeadlyBossMods/DBM-Dungeons)
- `DBM-Azeroth` (DeadlyBossMods/DBM-Vanilla)
- `DBM-Test-Vanilla` (DeadlyBossMods/DBM-Vanilla)

Reinstalling the complete DBM packages can restore these missing modules. The installed pack had selected only some folders from DBM-Dungeons.

CurseForge's persisted records show `isModified=false` for all 61 entries, but the recorded versions and actual files disagree. Examples:

| Addon | CurseForge's recorded installed ZIP | Actual installed version |
|---|---|---|
| BetterBags | BetterBags-v0.5.11.zip | v0.5.14 |
| ConsolePort | ConsolePort-3.2.6.zip | 3.3.5 |
| DBM Core | DBM-Core-12.1.11.zip | 12.1.12 |
| DynamicCam | DynamicCam_2.20.3.zip | 2.21.1 |
| Immersion ExtraFade | Immersion_ExtraFade_1.17.35.zip | 1.18.0 |
| DBM-Challenges | DBM-Challenges-r172.zip | r264 |

The yellow icons in the screenshots alone do not establish that source files were edited. The manager also still records 43 addons whose code is absent from its live directory.

## Custom companion and saved settings

Keep `ConsolePort_Forever` separately for the interface currently in use. It is version `2.0.0-candidate.3`, a custom companion outside CurseForge's list. It can change the UI at runtime while the third-party addon files remain unmodified. Reinstalling ConsolePort does not remove this companion.

Keep WTF and the retained addons' SavedVariables when reinstalling so the current bindings, layouts, profiles, and preferences remain available. Source-file cleanup does not require resetting settings. CurseForge's saved Retail preference currently has automatic SavedVariables deletion disabled.

The archived unused addons' old SavedVariables can remain harmlessly as settings; they do not make absent addon code run. The deletion table targets addon code and manager entries. No SavedVariables deletion was performed.

The existing `.cpf-stage-*` directories under Interface are installer rollback material outside AddOns; the game does not load them as addon folders. They are also present in the user's RAR. No staging directories were deleted.

## Suggested order

1. Close WoW.
2. Remove the 43 unused CurseForge entries.
3. Reinstall/update the 18 retained entries, including those marked up to date; retain the separate ConsolePort_Forever companion.
4. If desired, delete the archived unused code folders listed above.
5. Check the interface in-game after reinstalling. This audit does not certify the custom companion against newer dependency versions.

