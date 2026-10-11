# ConsolePort Forever standalone architecture

Status: schema 2 implemented; live visual verification pending  
Target addon: `ConsolePort_Forever`  
Bundled layout schema: `2`  
Profile name: `Console Port - Forever`

## Product contract

`ConsolePort_Forever` is a companion addon, not a patch set. A player installs it beside its declared dependencies, logs in, accepts one install/update prompt, and receives a versioned Blizzard Edit Mode profile plus the controller HUD presentation. It must never write into another addon's source directory and must not require pre-edited WTF files.

Required dependencies are ConsolePort, ConsolePort_Bar, ConsolePort_Menu, and Immersion. The menu module owns the radial-menu trigger installed on PADFORWARD. Future integrations remain optional and are reported without blocking the core UI.

## Safety boundary

The addon may read, copy, and save Edit Mode layouts through `C_EditMode`. It must not pass addon-created `systemInfo` tables to live Edit Mode frames, call their `UpdateSystem` methods, or replace Blizzard frame methods. The saved profile is the source of truth for Blizzard-owned frame positions. This is the critical fix for the secret-value failure previously triggered when Edit Mode refreshed compact arena frames.

ConsolePort presentation that Blizzard Edit Mode does not own—round face buttons, local artwork, bank geometry, and targeting prompts—may be applied after ConsolePort_Bar loads. Those hooks may alter only ConsolePort-owned widgets and must be idempotent. The four circular face-button sets are removed from their ConsolePort Masque groups before the companion applies its round mask and ring. Post-hooks repeat that detachment after a bank rebuild or Masque reload. The stock ConsolePort and ConsolePort_Bar files remain unchanged.

The Blizzard micro-menu/bag strip is hidden only during normal play. It is restored for `EditMode.Enter` and hidden again after `EditMode.Exit`, allowing Blizzard to manage and save its own frames while the editor is active. No Edit Mode frame receives an addon-created `systemInfo` table and no `UpdateSystem` method is called.

## Install and update transaction

1. On `PLAYER_LOGIN`, compare the bundled layout schema with `ConsolePortForeverDB.installedSchema`.
2. If installation or migration is needed, show one prompt: **New interface to be installed** or **Interface update available**.
3. On acceptance, require out-of-combat execution and take an in-game backup:
   - serialized active Edit Mode layout;
   - active layout index and name;
   - each binding the addon will change;
   - selected CVars changed by the installer.
4. On migration, preserve the complete existing managed profile so the already approved minimap, objectives, action-bar records, status systems, and other Blizzard geometry are not replaced by a generic preset. On a clean account, deserialize the bundled native Edit Mode export of that same approved profile. If a future client rejects the export, fall back to Blizzard's current Modern preset and apply the schema-owned anchors.
5. Treat `C_EditMode.GetLayouts().layouts` as saved layouts only, but pass `C_EditMode.SaveLayouts` the combined list Blizzard's own manager uses: built-in presets followed by saved layouts. The activation index is `presetCount + savedProfileIndex`. Complete and verify the Edit Mode save/selection before touching ConsolePort_Bar, Immersion, or binding SavedVariables; then install those data, record both indices for diagnostics, and reload the UI.
6. An update replaces the existing named profile in place after refreshing the backup. Migrations are monotonic and idempotent; the same schema is never reapplied on every login.

The installer fails closed. If the Edit Mode API, current preset data, enum data, profile capacity, or a writable saved-layout list is unavailable, it makes no controller/bar/Immersion change and presents an actionable error. If profile selection fails after a successful save, the named profile is left recoverably present and the schema remains pending for an explicit retry.

Schema 2 owns the complete `Forever Controller` mapping. It registers a named copy in ConsolePort's shared data and applies every chord directly during the accepted hardware event. ConsolePort's conditional preset expression is intentionally blank: that dependency can evaluate the expression before its Shared/Data table has loaded, producing a false “preset not found” error. The named preset remains available for inspection without using that racy login path.

## Layout geometry

The horizontal origin is the screen center and the gap between the inner square and circle columns. The shared rhythm is 78.75 UI units:

- inner cross centers: -78.75 and +78.75;
- L1/R1 prompt centers: -157.5 and +157.5;
- side bank and player/target frame centers: -315 and +315.

The first public schema uses screen-relative anchors so Edit Mode can own, display, move, save, and revert them normally. Chat width is 400 and height is 120. Player and target auras grow left/down in bounded lanes.

## Saved state

`ConsolePortForeverDB` is account-wide and contains:

- `installedSchema`, `installedAddonVersion`, and `profileName`;
- `backup.editMode` and `backup.bindings`;
- `lastInstallAt`, `lastError`, and dependency diagnostics;
- per-feature migration flags reserved for later schemas.

No character name, account ID, or absolute filesystem path is embedded in the addon.

## Player controls

- `/cpf install` shows or runs the pending install/update flow.
- `/cpf status` reports schema, profile, dependency, and pending-combat state.
- `/cpf restore` restores the captured Edit Mode layout and changed bindings after confirmation.

The initial build intentionally keeps restore conservative and never deletes unrelated player profiles.

## Versioning and future publishing

Addon version and layout schema are separate. A code-only patch does not force a profile rewrite. A layout change increments the schema and produces an update prompt. Before public signing/publishing, complete clean-account tests across resolutions, controller families, classes, combat states, vehicles, pet battles, raids/arenas, Edit Mode save/revert, missing optional dependencies, and dependency upgrades; also complete asset licensing and trademark review.

## Acceptance checks for schema 2

- No file under `ConsolePort`, `ConsolePort_Bar`, or Immersion differs from its pre-prototype source because of this addon.
- The prompt appears once for schema 2 and reappears only when the schema increases or the player explicitly invokes install.
- Accepting creates or updates exactly one account layout named `Console Port - Forever`, activates it, and reloads.
- `SaveLayouts` receives presets plus saved layouts, and the active index equals the number of Blizzard presets plus the saved profile's index; the profile contains player/target anchors at -315/+315.
- Migrating schema 1 retains the complete existing managed layout; a clean install deserializes the bundled 2,560-byte native profile export (SHA-256 `B8A123DAE338B118083B7DCA679BF8E19966B1578B61354C3750486193ECA497`).
- A simulated Edit Mode save rejection leaves the ConsolePort bar, Immersion settings, and bindings untouched.
- The complete named controller preset is registered, applied, and produces no conditional-preset chat error on reload.
- Face buttons remain circular after Masque initializes or the ConsolePort banks rebuild.
- The Blizzard micro-menu/bag strip is absent during play, available while Edit Mode is open, and absent again after closing it.
- Opening, moving a frame in, saving, reverting, and closing Edit Mode produces no secret-value or taint error.
- Repeated login/reload creates no duplicate frames, profiles, hooks, or prompts.
- Declining leaves the current UI untouched and `/cpf install` remains available.
