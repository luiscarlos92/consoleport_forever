# Proactive WoW UI collision audit handoff

> **Taint correction, 2026-09-27:** Runtime testing disproved the target/unit-frame portion of this handoff. The deployed helper produced secret-value error storms because it wrote `TargetFrame.buffsOnTop` and invoked Edit Mode `UpdateSystem` on other Blizzard unit frames. The live and staged helpers now protect every `UnitFrame`, perform no target-frame Lua-field writes, aura update calls, or unit-frame method hooks, and share SHA-256 `6B2B3FE9E60F6677F4D74F6FD83A696DECD4C2C9498FCBAB93C6036E4FDC0267`. The harness and static policy now forbid the unsafe behavior. Any statement below that target auras are addon-forced above the frame, that focus/group/boss/arena unit frames receive Modern records, or that hash `177666...` remains deployed is superseded by this correction.

## Completed continuation — 2026-09-27 20:25 UTC

The scheduled continuation completed. Only `Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua` was deployed. WoW was closed at deployment, was not launched or terminated, and no SavedVariables or binding caches changed. The installed and staged SHA-256 is `17766647CC94545DE3A17CD688495636138F4D0E7782AD46C3B36A06AA25A404`; the pre-task backup remains `B77AD851A602CF1230A96724B043D1127B322F72A938EBB9F3AA90E356D1F6CB`.

Live Lua parsing, the focused Fengari frame/Edit Mode harness, exact installed-hash comparison, and the conservative collision model all pass. Deployment and rollback are hash guarded by `deploy.py` and `rollback.py`. Visual/runtime acceptance still requires the user's next normal login because Codex did not start the game. The one-time heartbeat `finish-proactive-wow-ui-collision-audit` was deleted after final documentation and cannot repeat.

## State at the usage handoff

The user asked for a full collision lookahead after screenshot `1000103020.jpg` showed a harmful aura over the player health bars. Codex must never launch or terminate WoW. The five-hour window reached exactly 90% used, so work stopped before deployment and the continuation heartbeat `finish-proactive-wow-ui-collision-audit` was created ACTIVE for 2026-09-27 16:23:09 America/Toronto, five minutes after the reported reset.

WoW was closed when the backup and staged source were created. No SavedVariables, Edit Mode cache, bindings, addon settings, or live addon files were changed during this partial run.

## Proven cause

Retail defines `BuffFrame` and `DebuffFrame` as separate `Enum.EditModeSystem.AuraFrame` systems. `BuffFrame.xml` gives `DebuffFrame` its own anchor, and each frame has its own saved Edit Mode system record. The previous helper moved only `BuffFrame`, so the beneficial aura correctly appeared beyond the portrait while the harmful aura retained its independent saved anchor over the health bars. This exactly matches the screenshot.

Blizzard source is sparse-cloned at `source/wow-ui-source`, commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`. Relevant files include:

- `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.xml`
- `Interface/AddOns/Blizzard_BuffFrame/BuffFrame.lua`
- `Interface/AddOns/Blizzard_EditMode/Mainline/EditModePresetLayouts.lua`
- `Interface/AddOns/Blizzard_EditMode/Shared/EditModeManager.lua`
- `Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua`
- `Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua`

## Staged implementation

Only the local helper is staged:

`staged/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua`

Final staged/deployed SHA-256: `17766647CC94545DE3A17CD688495636138F4D0E7782AD46C3B36A06AA25A404`

Pre-task backup SHA-256: `B77AD851A602CF1230A96724B043D1127B322F72A938EBB9F3AA90E356D1F6CB`

The staged helper:

- manages `BuffFrame` and `DebuffFrame` together;
- anchors buffs `TOPRIGHT` to the full `PlayerFrame` `TOPLEFT` at `(-12, 5)`;
- anchors debuffs `TOPRIGHT` to `BuffFrame` `BOTTOMRIGHT` at `(0, -6)`, so a resized or multi-row buff container automatically pushes debuffs below it;
- forces both containers to grow left and wrap down;
- keeps target-frame auras above the approved low target frame, preventing them from expanding into the controller HUD;
- restores the approved player and target frame anchors through Edit Mode/native rewrites using base point methods;
- applies Blizzard's runtime Modern records to every registered Edit Mode frame except the explicitly protected systems: all action bars, cast bar, player/target frames, chat, minimap, objective tracker, micro menu, and bags;
- leaves the serialized RealUI layouts untouched;
- derives a controller-safe transient rail for Extra Abilities, Encounter Bar, Talking Head, Vehicle Leave, Archaeology, and all four Cooldown Viewer groups because Blizzard Modern normally anchors several of these on the action bar;
- reapplies after login/reload retries, late system registration, Edit Mode exit, specialization/display/UI-scale changes, and combat deferral.

All prior approved helper behavior remains in the staged file: bank geometry, circular face slots, square D-pad, base art, prompt positions, cast bar with five-pixel clearance, player/target positions, hidden menu/bag strip, bindings, and controller behavior. Immersion, DynamicCam, LiteMount, chat, minimap, quests, SavedVariables, and binding caches are outside this patch.

## Validation already passing

Commands were run against the staged tree after the final target-aura patch:

- Lua 5.1 parsing of the helper and harness: PASS.
- Fengari frame/Edit Mode harness: PASS.
  - independent buff/debuff frames form one dynamic lane;
  - both grow left and wrap down;
  - protected systems receive zero Modern updates;
  - representative unprotected systems receive Modern records;
  - controller-safe anchors survive repeated login refreshes, Edit Mode exit, late registration, and combat deferral;
  - target auras restore above after an Edit Mode setting rewrite;
  - approved unit-frame and cast anchors remain unchanged.
- `layout_assert.py`: PASS.
  - models a 1920x1080 UIParent-centered canvas;
  - reserves the full four-bank HUD, player/target frames, and chat;
  - models 32 buffs, 16 debuffs, target auras, and deliberately oversized transient boxes;
  - reports no overlapping expansion envelopes.

Evidence: `evidence/layout-collision-model.json`.

## Required continuation steps

1. Re-read the staged helper and test files; do not redesign from scratch.
2. Review the final custom anchors once against the Blizzard Modern source and the collision JSON.
3. Create `manifest.json`, `deploy.py`, and `rollback.py`. Both deployment directions must refuse if any WoW process is present. Deployment must require live hash `B77AD...`; rollback must require the final deployed hash.
4. Confirm WoW is closed immediately before deployment.
5. Copy only the staged helper into `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\ConsolePort_Forever\ConsolePort_Forever.lua`.
6. Validate the installed hash, Lua syntax, focused harness against a live-root stage or copied live helper, and collision model. Save receipts in `evidence`.
7. Append the completed section to `ConsolePort-Forever-Implementation-Report.md`, including source trace, protected systems, transient lane, validation, rollback, visual limitation, and addon-update risk.
8. Leave one consolidated normal-login check: buffs and debuffs remain entirely left of the player frame; target auras appear above; approved regions remain unchanged; situational Extra Ability, Encounter Bar, Talking Head, Vehicle Leave, cooldown viewers, group/boss/arena/focus frames, loot, durability, warnings, tooltip and status bars are tidy when they appear; reload/Edit Mode restores policy; no Lua/blocked-action errors.
9. Delete `finish-proactive-wow-ui-collision-audit` after successful completion so it cannot repeat. Keep old `fix-consoleport-circular-buttons` paused.

## Deferred product evolution

The user would eventually like this personal prototype to become a public, nearly one-click companion addon: install dependencies, log in, press **Apply Forever Layout**, and receive an adaptive version of this interface with backup and rollback. The concept, current portability gaps, engineering work, asset review, setup flow, testing, and publishing path are recorded in [ConsolePort-Forever-Public-Addon-Roadmap.md](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Public-Addon-Roadmap.md>).

This roadmap is explicitly deferred. The scheduled continuation must finish the current aura/collision implementation, validation, deployment, rollback, and documentation first. It must not start public-addon refactoring or publishing work.

## Screenshot

`C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\.codex-remote-attachments\01a0e0e4-ce9d-7851-8b83-70caa8d587be\a2e438ad-249d-4661-831d-beef63ff6339\1-1000103020.jpg`
