# ConsolePort / WoW Forever research handoff

Last updated: 2026-09-26  
Original scope: research and documentation only; the implementation restriction below is historical.

> Superseded on 2026-09-26: the user subsequently approved implementation. Offline implementation is complete. The authoritative current state is `ConsolePort-Forever-Implementation-Report.md`; the remainder of this file is retained as the historical research/continuation record.

## Continuation state (completed)

- The five-hour Codex window reached 90% used (10% remaining).
- The reported reset timestamp was `1790384299` (`2026-09-26T00:58:19Z`).
- The **Resume ConsolePort Forever guide** heartbeat fired at `2026-09-26T01:05:14Z`, after the scheduled post-reset continuation time.
- The five-hour window had reset and showed 6% used before the final review began.
- `ConsolePort-Forever-Configuration-Plan.md` was reviewed against the installed ConsolePort source and refreshed web results. The continuation automation was then removed so it would not run again the next day.

## Verified local structure

- Retail `Interface` and `WTF` under `C:\Program Files (x86)\World of Warcraft\_retail_` are NTFS junctions into this OneDrive tree.
- Of 42 current character directories, 39 are junctions to the shared `_template_` directory.
- Three are real directories containing only `AddOns.txt` and are not sharing template SavedVariables:
  - `Proudmoore\Fëanturï`
  - `Outland\Engwär`
  - `Outland\Ganymëdë`
- Do not blindly rerun the old scripts. The character-link script deletes character directories before recreating junctions. Plan a recoverable backup/rename and targeted repair later.

## Relevant local ConsolePort state

- ConsolePort suite version: 3.2.6, Interface 120100.
- Installed modules: core, Bar, Config, Cursor, Keyboard, Menu, Rings, Target, World.
- Active controller record: PS5.
- Current account overrides include analog movement enabled, travel/combat strafe angle 115, turn-with-camera in combat, crosshair disabled, keyboard enabled, radial press-and-hold disabled, and binding overlap disabled.
- Current modifiers in `WTF\Config.wtf`: Shift = left shoulder; Ctrl = left trigger. A Forever-like setup should instead reserve both triggers as the two action layers (L2/LT and R2/RT), freeing both bumpers for friend/enemy targeting.
- Shared template bar layout is ConsolePort `Default`, not a crossbar.
- ConsolePort ships a much closer built-in preset in `ConsolePort_Bar\Model\Presets.lua`: **Crossbar: Triggers**. It presents left and right eight-button groups plus a combined-trigger eight-button group. **Crossbar: Minimal** is the closest analogue to Forever's hidden compact-action-bar mode.
- Account settings live in `WTF\Account\119624169#1\SavedVariables\ConsolePort.lua`.
- Shared per-character bar state lives through `WTF\Account\_template_\SavedVariables\ConsolePort_Bar.lua` for linked characters.

## Research conclusion

- Blizzard officially announced native gamepad support, but its announcement does not specify the complete mapping.
- Current beta/community documentation consistently describes eight visible inputs (D-pad plus four face buttons), with base, LT, RT, and LT+RT layers; three switchable arrangements; bumper targeting; and a large right-stick radial menu.
- ConsolePort can closely reproduce the action-layer grammar and approximate targeting/menu behavior, but it cannot reproduce Blizzard's native controller widget navigation, exact context prompts, artwork, or all tap/hold semantics through configuration alone.
- No verified published ConsolePort profile matching Forever was found as of 2026-09-25. ConsolePort GitHub issue #227 asks about Forever support and has no maintainer solution. An exact Reddit request received one useful partial manual mapping, but no importable profile and no answer for the LB+RB utility layer.

## Sources already reviewed

- Blizzard announcement: https://worldofwarcraft.blizzard.com/en-gb/news/24303862/
- Current controls guide: https://nerdschalk.com/world-of-warcraft-forever-beta-controller-setup-bindings-and-controls/
- Icy Veins controller guide: https://www.icy-veins.com/wow-forever/playing-with-controller
- Blizzard beta feedback: https://us.forums.blizzard.com/en/wow/t/controller-support-feedback-beta-impressions-so-far/2353149?page=2
- Hidden compact bar report: https://www.reddit.com/r/wowforever/comments/1wmxyvp/some_hidden_features_on_controller_support/
- ConsolePort repository: https://github.com/seblindfors/ConsolePort
- ConsolePort Forever issue: https://github.com/seblindfors/ConsolePort/issues/227
- Request for a matching config: https://www.reddit.com/r/wownoob/comments/1wma74r/wow_forever_gamepad_settings_in_consoleport/

## Completed review

The final plan now includes the GUI sequence, PS5/Xbox mapping, exact installed ConsolePort setting keys, direct-file procedure, safe junction-repair prerequisite, rollback process, validation checklist, evidence confidence, and research sources. The final review also clarified Forever's 32-command model, press-to-toggle trigger option, ConsolePort's hold-modifier limitation, the current CurseForge flavor list, and the state of community attempts.

No WoW installation, junction, add-on setting, SavedVariables file, or `Config.wtf` value was changed.

## 2026-09-26 implementation pause and revised research request

The user stopped the implementation before add-on cleanup and requested a deeper compatibility review. Do not delete, disable, relink, or edit anything until that review has been returned and the user gives later approval.

### Filesystem status

- No add-on directories have been removed.
- No SavedVariables have been removed.
- No character directories have been replaced by junctions yet.
- A proposed patch to `ConsolePort.lua` and `ConsolePort_Bar.lua` failed atomically and changed neither file.
- Before the stop request arrived, `WTF\Config.wtf` had already been edited: Shift moved to `PADLTRIGGER`, Ctrl moved to `PADRTRIGGER`, Alt was cleared, travel/combat movement angles became 0/180, turn-with-camera became 2, and the researched gamepad soft-target CVars were added. Tell the user this clearly; do not make further changes or silently revert it.

### User decisions that now override the earlier cleanup proposal

- Keep base `Immersion`; the user noted that it shares ConsolePort's creator. `Immersion_ExtraFade` remains a separate candidate requiring investigation.
- Keep `Plater`; the user strongly prefers its nameplates to Blizzard's defaults.
- Keep DBM and its modules.
- Candidate removals explicitly named by the user: `Khesyc_iLvl`, `Molinari`, `Pawn`, `PersistentWorldMap`, and `TomTom`.
- Every other add-on previously proposed for removal remains only a candidate. None is approved for deletion yet, even if the user said it can go on a first pass.
- Previously proposed keepers not newly rejected remain provisional keepers, but the regenerated answer should still discuss meaningful interactions.

### Required next research

For every installed add-on under consideration, inspect the current official repository or authoritative project page, local TOC/source where relevant, ConsolePort-specific integration or issue reports, and credible user reports about coexistence with ConsolePort. Classify each add-on as one of:

1. verified conflict or duplicate input ownership;
2. benign coexistence with optional integration;
3. redundant with modern Retail but still useful;
4. stale/abandoned or orphaned;
5. no meaningful evidence either way.

Do not infer incompatibility merely because an add-on changes UI. In particular, separate visual differences from actual controller focus, keybinding, secure-frame, camera, targeting, or navigation conflicts. Regenerate the complete keep/remove/uncertain recommendation with source links and confidence labels. Do not modify the WoW tree during this research turn.

### Usage continuation

At the pause, the five-hour window was 87% used (13% remaining), reset timestamp `1790443243`. A one-time same-thread heartbeat named `resume-consoleport-compatibility-investigation` was created for 13:25:43 America/Toronto, five minutes after reset. Delete it after the researched recommendation has genuinely been delivered.

## 2026-09-26 compatibility research pass before reset

The user explicitly asked to use the remaining token window for research and to keep the continuation scheduled. No WoW files were changed. Findings were appended incrementally to `ConsolePort-Addon-Compatibility-Ledger.md`.

Completed evidence batches:

- Immersion: explicit optional ConsolePort dependency, dedicated ConsolePort controller/hint handler, compatibility guards. Strong keep.
- BetterBags: explicit ConsolePort cursor integration for bags/bank/context menus. Strong keep.
- Plater: installed source contains a specific ConsolePort stack-overflow workaround; positive controller-user reports. Strong keep, but test ConsolePort's own nameplate-forcing options because ConsolePort issue #159 reproduces missing default health bars without Plater.
- DynamicCam: installed Retail TOC is current (120100, v2.20.3). No direct ConsolePort conflict found; it changes camera behavior and should only be disabled for baseline/feel comparison.
- OPie/OPieMasque: overlapping radial-menu functionality and possible chord competition, but no proof of Retail+ConsolePort incompatibility. OPie's official warning concerns the Forever beta client. Inspect/migrate existing OPie-derived ConsolePort ring data before any removal.
- Narcissus suite: current; its load-on-demand GamePad module temporarily owns PAD input within Narcissus and clears context bindings. Narcissus Achievements explicitly tells ConsolePort to ignore its frame, so retaining Narcissus but deleting its GamePad module may reduce controller accessibility. Remove whole suite only by preference.
- Immersion_ExtraFade: current 120100 companion; no direct ConsolePort conflict found. Preference-based keep/remove.
- ZenFishing: stale 110100 and overrides right mouse `BUTTON2`, not a PAD binding. Removal case is age/utility, not proven ConsolePort conflict.
- WIM: current 120100 custom chat windows; no binding collision found, but cursor accessibility is still uncertain.
- MySlot: project remains current enough for Retail and acts at import/export time. It can overwrite action bars/bindings if used after configuration, but is not a continuous runtime controller conflict.

Remaining priority queue for the scheduled continuation:

1. BlizzMove/Debug, NoAutoClose, EditModeExpanded, ls_Glass, Masque/CleanIcons, WIM user reports.
2. Details, WeakAuras, RaiderIO, Simulationcraft, TSM AppHelper, Plumber, Copybara, WorldFlightMap, tullaRange, SharedMedia_Causese.
3. User-nominated candidates: Khesyc_iLvl, Molinari, Pawn, PersistentWorldMap, TomTom.
4. Confirm DBM keep status with current ConsolePort/user evidence, although the user has already decided to keep it.
5. Produce the final linked keep/remove/uncertain matrix only after all batches are checked.

Usage reached 93% used (7% remaining). Do not start another research batch in this window. The one-time `resume-consoleport-compatibility-investigation` heartbeat must remain active for the post-reset continuation.

## 2026-09-26 compatibility investigation completed

- The scheduled continuation ran after the usage reset and the entire installed add-on inventory was reviewed.
- Final report: `ConsolePort-Addon-Cleanup-Recommendation.md`.
- Evidence ledger: `ConsolePort-Addon-Compatibility-Ledger.md`.
- The live AddOns inventory contained 120 folders. The final report accounts for all of them with a proposed 38-folder keep set and 82-folder first-pass removal set.
- No add-on folders, SavedVariables, junctions, or additional WoW configuration values were changed during this research pass.
- Most removals are baseline simplification, not incompatibility claims. `NoAutoClose` is the clearest direct controller-navigation ownership overlap.
- Important dependency: the retained Plater profile has 164 direct `SharedMedia_Causese` sound references, so that media pack was moved into the keep set.
- Important preservation finding: the account's OPie profile is effectively empty, while the ConsolePort ring named `OPie` is independent and contains five utility items/spells; OPie code can therefore be removed without deleting that ConsolePort ring.
- Recommended first-pass keep families: all ConsolePort modules, base Immersion, BetterBags, Plater, SharedMedia_Causese, all DBM modules, Masque, and LiteMount with a deliberate non-conflicting binding.
- The compatibility continuation automation should be deleted after this completed report is delivered.
