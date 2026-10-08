# Candidate.13 repair — October 8, 2026

The user rejects candidate.12's visual result and reports controller casting
stops during combat in candidate.11/12 while mouse clicks still cast. Leaving
combat restores controller input. Keyboard input has not been tested. Earlier
chat history confirms cursor/player placement worked and native-only recovery
restored casting; the user explicitly requires repairing the interceptor and
keeping automatic placement enabled. Deployment is authorized once WoW is closed.
Preserve current HUD size and follow the Forever source/reference artwork.

## Demonstrated failure and repair

ConsolePort 3.3.10's ConsolePort_Cursor/View/Cursor.xml declares ConsolePortCursor
without secure inheritance. Its Lua handler pauses/releases interface control
on PLAYER_REGEN_DISABLED. Ground.Pre unconditionally inspected its frame handle
before every controller action. Blizzard RestrictedFrames.lua's
GetPossiblyForbiddenHandleFrame rejects an unprotected frame under lockdown,
even when hidden. T12 now runs the exact Blizzard handle validation and IsShown
body: candidate.12's expression reproduces Invalid frame handle on an ordinary
ability. A protected [combat] true; nil state driver now guards that inspection.
Protected Raid/TargetRing ownership checks remain active. Placement stays enabled,
with existing account preferences and native actions/pages intact. A live hardware
confirmation is still required; this reproduction does not prove every possible
client failure has been removed.

T42 now uses actual CP Manager.RegisterOverride, CPAPI.Parse, Manager.ApplyBindings,
Layers.SetRegistered, OnModifier/UpdatePrefix/ApplyRow and the engine binding
resolver before the CP/LAB/Manager/Blizzard click stack. All 32 chords run through
both cast edges, both supplied/omitted hardware flags and repeated UI/combat
transitions. Foreign modal owners remain intact; overflow/extra context commands,
manual placement, held cancellation and attribute restoration are covered.

## Artwork and geometry

Candidate.12 reset texture UV after SetAtlas and used whole controller glyph
fallbacks, drawing the full D-pad/circle glyph over assigned spells. Preserve atlas
coordinates. Exact fallback sprites come from already-retained Blizzard
FileDataID 6227336 / atlas 3024. Every rectangle is independently compared with the
original UiTextureAtlasMember export in sprite-regions.json (including the native
psquare spelling). No generated art/new bitmap or vendor changes. The original
empty images already include round face bevels and individual square D-pad arrows.
They show only for empty actions; native unbound icon textures are suppressed.
Spells/items/macros/custom actions hide the backdrop, including in combat.
Actual Normal/Pushed texture getters and fields are both styled. Nested VFX masks
are created in each texture's own parent, matching the WoW mask-parent contract.
The original sprite proof contact sheet was rendered from the BLP and inspected.

All bottom-anchored banks retain size/x/relative cross positions and move up
64 UI units without changing live saved data. Trigger prompts move inside the rail
(10 units above its bottom). Repeated refreshes cannot accumulate offsets. Class
badge uses an independent parent, below/outside the combined bank, scaled from
native PageUnit's +/-138,-50 coordinates against its 266x86 expanded rail.
Mock geometry checks require trigger/class prompt bottoms to stay above screen 0.
Retail UI-scale and final visual acceptance remain manual.

## Class chord and first login

Pinned Blizzard ClassSpellFlyout assigns PALADIN 270 and DRUID 262 to LeftClassAction:
L1+L2 / LB+LT. WARRIOR 269 uses RightClassAction: R1+R2 / RB+RT. The warrior reference
therefore does not establish right-side paladin behavior. The user confirms their existing R1+R2 opens a radial aura ring while held; it
closes on release or selection. Preserve that native ConsolePort selection
behavior, moving the paladin opener to the documented left chord. Do not claim
that the native CP radial artwork is Blizzard's exact class-popup artwork.

Accepted revision-14/15 characters migrate the actual class binding/ring to
revision 16 on first eligible login using in-game transaction backup/rollback.
Remove a matching opposite-side duplicate and legacy R2+menu class opener; preserve
unrelated commands/keyboard bindings and manually ordered ring contents. Bootstrap
regression covers all three classes from both prior revisions, repeated login,
backup and restore. No live WTF file writes. Native recovery for gameplay modes,
UI contexts and hidden controls remains; do not reactivate the old takeover paths.

## Qualification and delivery

Nine official stable Retail dependencies were freshly checked this work session:
all current, no download/update or reshipping. All 44 runtime/source suites and 39 tooling checks passed; exact reports are
retained in evidence/forever-ui/candidate13-runtime-tests.json and
candidate13-tooling-tests.json. Scoped package/preview/install/readback
receipts follow after source is pushed.
No live acceptance is inferred from offline tests. Manual next checks are ordinary
controller combat casting, then cursor/player/manual ground spells, all modifier
banks, aura/stance selection and the actual rendered empty/assigned slot shapes.
