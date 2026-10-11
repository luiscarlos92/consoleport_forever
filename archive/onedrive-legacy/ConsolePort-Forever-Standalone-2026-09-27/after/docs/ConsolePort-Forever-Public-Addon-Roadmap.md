# ConsolePort Forever-inspired public addon roadmap

## Status

Productization was authorized on 2026-09-27 and is now active. The implementation source of truth is `ConsolePort-Forever-Standalone-Architecture.md`. The direct dependency edits used by the personal prototype are being migrated into `ConsolePort_Forever`, and Blizzard-owned frame placement is moving from runtime overrides to a versioned native Edit Mode profile.

## Product vision

Turn the current personal controller interface into a distributable companion addon that other World of Warcraft Retail players can install and apply with one guided action. The intended experience is:

1. Install ConsolePort and the companion addon.
2. Log in and click **Apply Forever Layout** while out of combat.
3. Reload the interface if required.
4. Receive the same coherent controller-oriented design, adapted to the player's display, controller glyphs, class, and installed optional addons.

The public result should reproduce the design language and behavior rather than blindly copying one account's coordinates and SavedVariables.

## Current prototype

The local `ConsolePort_Forever` addon is the product root. Its former runtime placement code is now considered migration input, not the long-term architecture: native Edit Mode data owns Blizzard frames, while the addon owns only its installer, migrations, assets, ConsolePort widget styling, targeting prompts, diagnostics, and restore data.

The schema-2 personal build is now portable as one companion addon for the approved 16:9 setup. The following work remains before a broad public release:

- compatibility testing of the addon-owned Masque detachment and ConsolePort_Bar hooks across dependency versions;
- local artwork files and references to Blizzard and ConsolePort assets;
- controller-family selection beyond the currently bundled PlayStation 5 glyph/preset presentation;
- Immersion settings tailored to this account's chosen scale, anchor, vertical position, title panel, and ExtraFade behavior;
- optional LiteMount bindings and icon metadata;
- exact UI scale, screen proportions, action-bank centers, and unit-frame positions chosen for this installation.

These dependencies are acceptable for the personal prototype but should not be shipped as direct edits to another addon or as copies of a player's SavedVariables.

## Required engineering work

### Self-contained integration

- Keep the completed ConsolePort_Bar integration inside runtime hooks or supported extension points owned by the companion addon.
- Avoid replacing or patching ConsolePort, ConsolePort_Bar, Immersion, or LiteMount files.
- Detect supported dependency versions and disable only incompatible features when APIs change.
- Keep all secure-action and binding work outside combat and respect Retail's protected-frame restrictions.
- Make repeated application idempotent so login, reload, Edit Mode, specialization changes, and addon updates do not accumulate hooks, duplicate frames, or drift.

### Setup and rollback

- Provide a small first-login panel with **Apply Forever Layout**, **Preview**, **Restore Previous Layout**, and **Reset Companion Settings** actions.
- Capture a reversible backup of the player's active Blizzard Edit Mode layout and relevant ConsolePort profile before applying anything.
- Create a separately named Blizzard Edit Mode layout and ConsolePort preset instead of overwriting the player's existing profiles.
- Explain which optional changes affect bindings, Immersion, and LiteMount, and let the player opt into those modules independently.
- Require a reload only when WoW's APIs or secure state make it necessary.
- Provide a clean uninstall path that restores the selected prior profiles and removes companion-owned data.

### Adaptive layout engine

- Treat the four ConsolePort banks, cast bar, player/target frames, chat, minimap, and objective tracker as reserved regions.
- Compute positions from UIParent dimensions, effective UI scale, safe margins, and aspect ratio rather than assuming this user's screen.
- Support common 16:9, 16:10, ultrawide, television, handheld, and high-DPI layouts.
- Model maximum expansion envelopes for buffs, debuffs, target auras, party/raid frames, boss/arena frames, cooldown viewers, encounter warnings, extra abilities, vehicle controls, loot, talking head, tooltip, durability, status bars, and other Edit Mode systems.
- Bundle a native export of the approved profile for deterministic clean installs, preserve that managed profile during migrations, and retain Blizzard's current Modern preset only as a forward-compatibility fallback when an export can no longer be deserialized.
- Offer compact and spacious variants while keeping the same visual hierarchy.

### Controller and binding portability

- Detect the active controller family and select PlayStation, Xbox, Nintendo-style, or generic glyphs.
- Extend the implemented companion-owned `Forever Controller` preset with opt-in variants rather than editing source files or shipping binding caches.
- Preserve existing player bindings unless the player explicitly chooses the full recommended mapping.
- Include the left map/right radial-menu behavior, modifier consistency, and optional LiteMount action as selectable features.
- Handle characters, specializations, and account-wide versus character-specific profiles predictably.

### Visual assets

- Inventory every bundled and referenced texture, atlas, icon, font, and controller glyph.
- Prefer Blizzard atlas and FileData references where they provide the required appearance without redistribution.
- Determine the licenses and redistribution terms for ConsolePort-derived or third-party assets before publishing.
- Replace any non-redistributable source material with original compatible artwork.
- Review the addon name, presentation, and store-page wording for Blizzard and third-party trademark concerns before release.

### Compatibility and quality

- Test clean installs, upgrades, dependency absence, dependency version changes, new characters, multiple specializations, combat lockdown, vehicles, pet battles, raids, arenas, encounters, Edit Mode save/revert, UI-scale changes, and different aspect ratios.
- Maintain deterministic Lua syntax checks, frame mocks, binding assertions, asset provenance, collision-envelope tests, and rollback tests.
- Add an in-game diagnostic page that reports detected dependencies, selected profiles, protected-frame deferrals, and any feature that could not be applied.
- Never automate gameplay, movement, combat, targeting decisions, or game launching. The addon should only configure and present the user interface.

## Publishing path

After the personal version is stable, treat public release as a separate project:

1. Freeze and document the approved personal behavior.
2. Remove all direct edits to dependencies.
3. Build the adaptive layout and profile generators.
4. Add setup, preview, backup, restore, diagnostics, and uninstall flows.
5. Complete asset and naming review.
6. Test across clean WoW accounts, controller families, resolutions, classes, and group content.
7. Package for GitHub and, if desired, CurseForge or Wago with clear dependency and compatibility information.

The desirable end state is “install, log in, click once, and receive the Forever-inspired controller interface,” with enough adaptation and rollback support to make that safe for players whose systems differ from the original setup.
