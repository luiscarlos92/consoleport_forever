# Source and anchor review

Retail source commit: `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`.

- `BuffFrame` and `DebuffFrame` are separate `AuraFrame` Edit Mode systems. The XML gives `DebuffFrame` its own initial anchor below `BuffFrame`; saved Edit Mode records can subsequently position each independently.
- Blizzard Modern configures both aura systems horizontally, growing left and wrapping down, with limits 11 buffs and 8 debuffs per row. The helper keeps those Modern settings and supplies a shared left-of-player anchor chain.
- `TargetFrameMixin:ConfigureAuraContainer` mirrors the flow vertically when `buffsOnTop` is true. `UpdateAuraContainerAnchors` explicitly reapplies the above/below anchor after the direction change.
- Modern anchors Encounter Bar, Extra Abilities, Talking Head, Vehicle Leave, and Archaeology at the bottom action-bar region. That region is occupied by ConsolePort in this layout, so these systems receive controller-safe derivative anchors.
- Modern Cooldown Viewer positions Utility at bottom y=240 and Essential at y=310, inside or directly above the four-bank envelope. The derivative center rail moves the four viewer groups above the approved HUD without changing Modern sizes, limits, visibility, opacity, or content settings.
- Player/target positions, cast bar, action bars, chat, minimap, objective tracker, micro menu and bags are excluded from the Modern update policy. The helper continues to own only their already approved behavior.
- All other registered Edit Mode systems consume deep copies of Blizzard's current runtime Modern records. The user's serialized RealUI layouts and SavedVariables are not edited by deployment.

The conservative collision model is recorded in `layout-collision-model.json`; it includes the approved action-bank envelope, unit frames, chat, 32 buffs, 16 debuffs, target auras, and oversized transient-frame boxes.
