# Presentation and implemented UI routes

Status: maintained
Reviewed: 2026-10-11
Evidence: [skin](../../addon/ConsolePort_Forever/Skin.lua),
[HUD](../../addon/ConsolePort_Forever/HUDPresentation.lua),
[visibility](../../addon/ConsolePort_Forever/Runtime.lua),
[contexts](../../addon/ConsolePort_Forever/UI/Contexts.lua).

The active presentation and dormant input routes have different activation
boundaries. [Architecture](../ARCHITECTURE.md) owns those gates; source/test
presence does not establish live enablement or Retail parity.

## Active HUD and native feedback

The four banks contain 32 native cells; the 16 face surfaces are round. D-pad
cells receive Forever empty art while retaining their native square treatment.
Face skinning detaches the relevant Masque surface rather than disabling Masque
globally. Filled icons stay on ARTWORK above empty-only background mattes;
obsolete `Normal_Custom` square overlays retire. Native atlas UVs are preserved,
and owned non-atlas replacements reset UVs correctly. Matching tint/alpha getters
alone cannot establish that the composed center pixel is visible.

Native range/resource restrictions, party-sync locks and zone-disabled states
remain. Secret values use qualified native sinks rather than public boolean
coercion. Round cooldowns retain duration/GCD/charge/loss-of-control distinctions;
nonzero overlay alpha is capped at 0.65 while native zero remains zero. Cooldown
frames sit above the icon and native charge swipe policy remains intact. Native
button press drives the gold pushed overlay even when a cast fails; casting and
interrupt reticles retain their local mask/parent behavior.

Original BLP sheets plus native atlas fallback supply device-resolved glyphs.
Stationary 22-pixel trigger prompts mirror bank visibility/alpha. Geometry uses
native frame hierarchy and screen/collision guards; old 150/10 bank geometry may
receive the qualified runtime base-bank lift, while current 160/5 geometry is
retained. The decoration fitter searches bounded offsets with a four-pixel gap;
it does not shift protected spell cells to fit labels. This is runtime geometry,
not rewriting the saved preset.

The 26-pixel class badge is a peer of the bank, below the matching side's D-pad
Down cell. It needs an actual matching class chord, native ring/learned icon and
device glyph. Public active-form icon wins, otherwise qualified ring content is
used. It continuously mirrors bank opacity; unavailable glyph/content hides it.
The Circle empty-cell exit art is cosmetic and does not install gameplay cancel.

Creation/geometry waits out combat; existing cosmetic surfaces can refresh in
combat. Native local/art/size/Masque lifecycle hooks and deferred refreshes repair
late recreation. Saved visual snapshots retain separate recent combat/peace
observations and opaque markers; ordinary snapshots are throttled, diagnosis can
force one. They remain source-state observations, not screenshots or live proof.

## Focus effects and hidden native frames

[FocusVisuals](../../addon/ConsolePort_Forever/UI/FocusVisuals.lua) suppresses only
HighlightTexture, CheckedTexture, PushedTexture, Flash, Border, SpellHighlightTexture
and NewActionTexture while qualified ordinary interface-cursor focus owns input.
Icons and cooldowns remain. Hooks remember later external alpha writes and
restore the latest requested values on release, including combat handoff.

Reviewed sidebar visibility remains active independently of custom UI takeover.
It reparents five native side bars and qualified bag/micro containers to an owned
hidden parent. Edit Mode/disable restores parents only if still owned; foreign
parent drift and frame replacement are guarded. It does not replace native
Show/Hide methods or unregister events.

[ClassActions](../../addon/ConsolePort_Forever/ClassActions.lua) separately hides
native StanceBar only for Paladin/Druid/Warrior with accepted complete learned
class-ring access and the actual matching opener. It restores for Edit Mode or
lost eligibility. The full HiddenAccess class/vehicle-seat replacement remains
disabled under recovery. Native power/resource UI is not in the hidden list.
Thus “hidden-control replacement disabled” does not mean every native class row
is always visible, or that native sidebars are never suppressed.

## Dormant UI implementation

`NATIVE_INPUT_RECOVERY=true` disables custom context acquisition, even if saved
UI/window/bag/map flags are accepted. InputBridge's qualified native combat
release bridge can remain: it releases the named widget's own native Layers
claims, including late widgets, while retaining foreign ownership. The following
routes describe implemented guarded code, not currently enabled behavior.

| Route | Implemented contract and limits |
| --- | --- |
| Popup / quantity | Highest focused native popup/quantity ancestor takes priority. Popup PAD1–PAD4 map to buttons 1–4 and R3 to extra; quantity uses PAD1 accept/PAD2 cancel and left/right adjustment. Missing routes explicitly do not consume actions. |
| Registered windows | Descendant-aware show order; L2/R2 focus windows, L1/R1 use audited native tabs, R3 uses focused tooltip. Keyboard, color picker, menu, radial and higher-priority popup/quantity owners yield. |
| Scroll | Audited native scroll-controller callbacks only; unprotected focused owner, 0.2 deadzone, neutral acquisition and native first/repeat delays. Unknown scroll widgets retain native behavior. |
| Map | Audited native Map/QuestScroll identity; left stick pan/right stick zoom. Hardware L3 waypoint/remove/supertrack operation revalidates map/coordinates/owner token. Back minimizes before closing or leaves quest detail as appropriate. Search/text/keyboard/foreign owners yield. |
| BetterBags | Exact v0.5.14 physical native pool and four distinct configured face keys. Native left/right clicks, native demanded ItemMenu, carried-item clear before bag close. Bag/slot/item GUID/stack/lock/context token must still match at dispatch; virtual items and stale themes are rejected. |
| Item hints | Focused native tooltip only; merchant Select/Buy/Buy Back or eligible loot-container Open glyphs. Avoid duplicate rendered prompts, replace only the native open instruction, preserve item names/comparisons and foreign instructions. No carried-item/combat/keyboard takeover. |

BetterBags does not implement the exact transient 0.5-second auto-loot override;
native modified click remains. Timer-driven scroll/map callbacks do not press
protected item/action buttons. InputBridge validates context generations and
restores prior claims only while still owned; its helper lease tests are distinct
from actual native Layers dispatch.

Read-only class/pet discovery validates GUID identity before/after capture and
public learned/form data. Pet commands are scoped to the current pet, not a
previous one. Selector reconciliation retains manual edits/duplicates and guards
name collisions, but preview `active=false` installs no class/pet controls.
[Cinematic](../../addon/ConsolePort_Forever/Cinematic.lua) observes real native
skip eligibility/confirmation; it does not supply held-skip or one-success
gameplay Circle cancellation. Those directions remain in
[requirements](../REQUIREMENTS.md) and [known issues](../KNOWN_ISSUES.md).
