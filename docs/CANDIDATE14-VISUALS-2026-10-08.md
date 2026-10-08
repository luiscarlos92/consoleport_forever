# Candidate.14 visual correction — October 8, 2026

The user confirms candidate.13 normal controller spells and cursor/player ground
placement work in combat on paladin and demon hunter. Retain that interceptor:
Targeting/Ground.lua is byte-identical to source 21a3859. The new request is visual:
restore pre-candidate.13 bank heights, make the face silhouettes round, place a
smaller aura/stance group under R2, move trigger prompts closer to the D-pad and
put the combined-trigger label in the vacated aura-row area without clipping.
The attached paint mock supersedes native left/right class badge positioning;
the actual installed class chord and native hold/release ring behavior remain.

## Square silhouette reproduction

Masque RemoveButton applies its default skin. Native Core.Skin_Normal with
UseStates=false creates a separate Normal_Custom region, hides the engine's
normal texture and leaves the custom square displayed. Normal_Custom remains
in _MSQ_CFG after the group registry is removed. Candidate.13 only styled the
native field/getter and therefore missed this independently drawn square.
Retire that texture (clear, alpha zero, hidden), restore the native normal
visibility/alpha and use the original round Forever frame artwork. Native CircleMask
atlas is explicitly shown, with the known portrait-alpha file fallback. The normal,
pressed, highlight, checked, flash and other face textures remain round; combat
art refresh restores images only and hides native square SlotArt without changing
protected frame geometry, bindings or casting. The native CP 3.3.10/Masque 12.1.0
packages stay unmodified.

T24 runs actual Masque Update_Normal, Hook_SetNormal, Skin_Normal and RemoveButton,
then the actual CP group lifecycle and product skin. A negative control removing
RetireMasqueNormal must reproduce the visible private square. Tests also enforce
no combat geometry/membership changes and reproduce a square atlas/SlotArt redraw
in combat before verifying restoration. Actual client rendering remains pending.

## Positions and collision coverage

Current saved Base/L2/R2/L2R2 positions (160/80/80/5 in the shared layout) are
restored without rewriting saved layout data. The older retained 150/80/80/10
layout needed a small runtime Base separation correction to keep the expanded
combined bank clear at native 94/106 percent scale extremes. The current shared
positions need no correction. L2/R2 labels anchor beside the bottom-right D-pad
cell rather than below the entire bank. The combined label sits in the open lower
gap between its crosses. The class icon is 26 units, with 18-unit chord glyphs,
anchored below R2's D-pad bottom cell. The label still displays the real class chord:
paladin/druid L1+L2, warrior R1+R2.

The native three-aura/form bar is hidden behind a secure parent only when the
accepted class ring has a verified installed chord and contains every learned
form. Incomplete/missing access retains the native bar. Edit Mode restores its
native parent; foreign ownership is respected. No UI input layer is acquired.

T45 runs the actual presentation/layout guard and CP GetHitRectScaled contract
with a physical anchor/scale model: 120 combinations of 5 resolutions, 3 UI
scales, 2 captured layouts and all 4 active-bank scale states. It checks full
spell rectangles, shadows, icon and complete chord labels, spell/hint and
hint/hint collisions, native bank collisions, clipped lower labels and deliberate
collisions. Fitting only decorative groups must not move gameplay cells. The
Blizzard ActionButtonTemplate is freshly pinned and its actual 45x45 dimensions
replace the earlier invented 50-unit mock. A runtime guard fits decorative
rectangles inside screen bounds and away from native spell cells, accounting for
effective scale; geometry diagnostics report when no nearby fit exists. UI-scale
and display-size changes request an out-of-combat refresh.

T46 runs the actual native stance visibility predicate, complete/incomplete ring
access, binding loss, repeated refresh, combat deferral, Edit Mode restoration
and foreign-parent preservation. All 46 runtime/source suites and 39 tooling checks passed. Exact reports are
retained in evidence/forever-ui/candidate14-runtime-tests.json and
candidate14-tooling-tests.json. Scoped delivery qualification follows. Offline geometry models are not live renderer acceptance.

## WTF and installer boundary

No live WTF file has been edited through filesystem tools. Only read-only inspection
and verified backup copies were performed. Previously accepted revision-14/15
characters updated bindings/rings to revision 16 through the in-game transaction
updater at login, which accounts for the lack of another confirmation prompt.
That first-login application had been explicitly requested by the user. Candidate.14
retains revision 16 and does not introduce saved binding/configuration changes:
these appearance and visibility updates initialize through addon runtime in game.
Deployment continues to copy only addon files; game-owned saving remains in game.

All nine official stable Retail dependencies were freshly checked this session:
all current, no packages downloaded or recopied. Closed-WoW scoped deployment is
already authorized. Never write live WTF or prune unrelated addons. Retain exact
source/test/build/install/readback receipts and backups.
