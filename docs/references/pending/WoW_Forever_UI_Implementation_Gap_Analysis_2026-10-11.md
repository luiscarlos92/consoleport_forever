# WoW Forever UI versus ConsolePort Forever: implementation and gap analysis

Status: maintained
Reviewed: 2026-10-11
Evidence: [native UI reference](WoW_Forever_Native_Gamepad_UI_Complete_Reference_2026-10-10.md),
[current implementation](../../IMPLEMENTATION-STATUS.md),
[approved requirements](../../REQUIREMENTS.md),
[source activation](../../../addon/ConsolePort_Forever/ConsolePort_Forever.lua),
[code/document reconciliation](../../reference/CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md).

For navigation: [coverage summary](#2-feature-coverage-at-a-glance),
[bindings/base faces](#3-controls-action-banks-pages-and-base-face-behavior),
[targeting/shortcuts](#4-shoulder-targeting-and-hud-shortcuts),
[class/pets](#5-class-and-pet-access),
[temporary actions](#6-temporary-actions-forms-vehicles-and-special-pages),
[menus/ping](#7-ping-radial-menus-emotes-and-buffs),
[focus/windows](#8-focus-contextual-legend-windows-and-dialogs),
[panel workflows](#9-bags-spellbook-npcs-crafting-and-other-panel-workflows),
[map conflicts](#10-world-map-and-quest-log-an-existing-implementation-that-would-change),
[art](#11-artwork-geometry-composition-and-visual-states),
[settings](#12-settings-persistence-and-edit-mode),
[decisions](#13-conflict-and-decision-register),
[research gaps](#14-native-unknowns-and-research-still-needed),
[next-work choices](#15-choosing-the-next-implementation-work).

## 1. Purpose, baseline and reading rules

**Later Circle-only implementation:** the user selected Circle and rejected native
Escape/Options. Uninstalled candidate.31 now offers a reviewed native cancel-all
approximation; exact first-success parity remains gated. The tables below retain
the candidate.30 comparison baseline. Current findings and proof are in the
[Circle research record](../../reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md).

This is the companion analysis requested by the user: what native WoW Forever
offers, what this Retail addon already provides, what is missing, what exists but
is incomplete, and what would require changing our current implementation or
approved policy. It supports selecting future work. It does not approve those
changes, activate suspended code, or replace the original descriptive reference.

The comparison baseline is checkout commit
`4cfa324312222eb352dddc64dfdb3679051820a0`, inspected October 11, 2026, and the
loaded candidate.30 product. The separately recorded installed checkpoint is
candidate.30 from `dcc0fbabebe701af138b98c98633274c18875a32`. Checkout analysis,
installation readback and live acceptance are different evidence.

**Native baseline:** the supplied reference has an October 10 cutoff, September
visuals/guides, dated official changes through October 8, and pinned UI source
`15666a6e67938a1ab5caf041406464251db111ca`. Native statements below are derived
from that document, carrying its B/S/V/G/P/U qualifications. External links and
the latest beta client were not freshly checked in this comparison. In
particular, source geometry is not a verified October 10 screen measurement.

**Addon baseline:** TOC-loaded modules, actual refresh callers, current policy
gates, binding/reference declarations, source art handling, maintained
specifications and retained acceptance. Source presence is not activation;
activation is not exhaustive Retail correctness; similar output is not exact
behavioral parity. No game operation, dependency refresh or deployment is part
of this documentation-only review.

In the tables, **N §x** means section x of the
[native reference](WoW_Forever_Native_Gamepad_UI_Complete_Reference_2026-10-10.md).
Bracketed **C** identifiers resolve to local source links in section 16. All
proposed completion criteria and priorities are analysis recommendations, not
new approved requirements.

### 1.1 Classification vocabulary

| Classification | Meaning in this analysis | What it does not imply |
| --- | --- | --- |
| **Implemented / active** | A current production path exists and can run under its documented policy/readiness gates. | Every character has accepted it, or every live case is certified. |
| **Partial** | A related capability works, but important semantics, states, art or coverage differ or remain absent. | The working part should be discarded. |
| **Dormant** | Implementation or preparation exists, but the present parent gate prevents activation. | Flipping a flag is safe or sufficient. |
| **Missing** | No dedicated implementation of the specified native feature was found in the loaded Forever product. | The base game or ConsolePort cannot provide a related feature. |
| **Conflict** | Adopting the native behavior would collide with existing binding, ownership, layout or approved policy. | The current implementation is a defect. |
| **Deliberate difference** | Current requirements explicitly choose a different behavior or Retail-specific solution. | Native behavior is fully known or preferable. |
| **Delegated / unverified** | Native Retail or ConsolePort owns the broader capability; this pass does not establish exact stock Forever equivalence. | Missing from the user's complete setup. |
| **Native unknown** | The reference itself lacks sufficient evidence to define the desired behavior. | A default can be invented, or the function is unused. |
| **Outside addon scope** | Client/platform capability or excluded product direction, not a normal addon task. | A new user request could never change scope. |

A row can carry more than one classification. For example, the map adapter is
both **dormant** and **conflicting**: it exists, is disabled, and uses controls
different from the documented native map. An active native ConsolePort menu can
also coexist with a **missing** Forever-style three-section menu.

### 1.2 Main conclusions

1. **Our strongest foundation is the four-bank HUD and preservation of native
   execution.** We have 32 displayed cells, 28 ordinary assignable positions,
   round face treatment, D-pad empty art, trigger prompts, learned class access,
   native account ping selection, and separate accepted ground placement.
2. **The largest interaction gap is the shoulder-mode system.** Friendly/hostile
   hold overlays, their face/D-pad actions, both-shoulder shortcuts and their
   settings are not implemented as a complete active Forever system. Existing
   shoulder targeting commands and artwork cover only part of that experience.
3. **Several apparent gaps are implemented but suspended.** Popup/quantity,
   window switching, scrolling, custom map routing, BetterBags routes and item
   hints must be reviewed through their actual activation boundary. They cannot
   be counted as delivered controller parity.
4. **The clearest visible/action mismatch is Base Circle.** The preset is empty,
   exit artwork is cosmetic, and exact stop-cast → stop-ground-target →
   clear-target behavior remains gated. A familiar icon currently promises more
   than the Forever layer supplies.
5. **Exact cloning would require explicit policy changes.** Static native input,
   three numbered arrangements, stock class flyout lists, native map controls and
   Compact mode intersect our editable bindings, manual rings, accepted expanded
   layout, temporary L2R2 routing and recovery boundary.
6. **The reference is insufficient to specify every exact gesture.** Pet flyout
   side/content, class selection/cancellation, special-page arbitration and
   several updated hold/menu constants remain research tasks. They should not
   become implementation defaults by assumption.

## 2. Feature coverage at a glance

| Area | What we already have | Principal gap / classification | Recommended disposition |
| --- | --- | --- | --- |
| Four ordinary banks | Base/L2/R2/L2R2, native button ownership, 32 cells / 28 ordinary assignable. | **Implemented**, with different Retail storage and geometry. | Preserve the foundation. |
| Base faces | Jump and interact commands; native camera/action Triangle; Circle exit art. | Circle **missing** exact action; Triangle **partial/conflict**. | Investigate one coherent base-face contract. |
| Shoulder targeting | Native friend/enemy binding declarations and fixed friendly/hostile prompts. | Full hold-mode overlays/actions/settings **missing**. | High-value future behavior project. |
| Both-shoulder shortcuts | Some functions accessible through other preset/menu routes. | L1+R1 mode and documented mapping **missing/conflict**. | Design after shoulder arbitration is understood. |
| Numbered arrangements | Native Retail paging and fixed bank declarations. | Native 1/2/3 tracker/cycling **missing/conflict**. | Separate product choice; not a cosmetic addition. |
| Compact / empty-bank options | Expanded composition and native opacity/scale behavior. | Dedicated Forever Compact/settings **missing/conflict**. | Optional later project after layout decision. |
| Class flyouts | Learned class ring and correct Paladin/Druid/Warrior chord side; badge. | Flyout shape/gesture **partial**; later selectors **dormant**. | Retain working ring, qualify precise changes. |
| Hunter/Warlock pet flyouts | Read-only pet discovery; inactive selector proposal. | Two active pet flyout categories **missing/dormant/native unknown**. | Research first, then scoped access. |
| Temporary actions | Qualified native temporary families on L2R2; other banks retained. | Native exact parity **unknown**; >8/exit controller access **partial**. | Preserve policy; solve actual access cases separately. |
| Ping | Release-only native secure send and real account ring; reported defects accepted. | Exact stock order/radius/timing **native unknown**. | Preserve; broader regression qualification only as needed. |
| Main menu / emotes | Native ConsolePort menu route in preset and native/manual UI. | Dedicated three-section Forever menu and emote route **missing/unverified**. | Independent navigation/presentation project. |
| Context legend / focus | ConsolePort cursor ownership, device glyphs, active focus cosmetics. | Complete Forever contextual legend/style choices **missing/delegated**. | Audit upstream behavior before adding duplicate prompts. |
| Popup/window/quantity/scroll | Guarded native adapters and ownership handoff code. | **Dormant**, plus exact per-panel parity unverified. | Qualify narrow contexts; do not enable all at once. |
| Bags / items / binding | Native editing preserved; guarded BetterBags/item hints. | Custom routes **dormant**; hold loot and explicit Bind flow **missing**. | Audit existing workflow before intervention. |
| Map / quests | Native map access; custom map adapter. | Adapter **dormant/conflict** with stock input and focus behavior. | Requires concrete control/focus decision. |
| HUD artwork / feedback | Original BLPs, round face state surfaces, native cooldown/range/press. | Full square states, stock geometry and mode art **partial**. | Choose the art target rather than reskin indiscriminately. |
| Settings / Edit Mode | Reviewed configuration, ground panel, native saved-layout tracking. | Dedicated stock settings surface/UI-type layout switching **missing/partial**. | Preserve manual layouts; expose only actual working controls. |
| Text / login / platform | Native/manual interfaces retained. | Login UI outside ordinary addon scope; custom typing deferred. | Do not treat as a runtime HUD task. |

### 2.1 Already implemented and worth preserving

The active foundation includes ordinary banks/action editing (A01–A04), normal
Jump and native interaction (F01/F03), supported three-class access and learned
augmentation, qualified temporary routing/edit protection (S01–S03/S06–S08),
candidate.30 native account ping, round face and empty-slot composition
(V01–V03/V05–V09), guarded native visibility (V17/V18), accepted Required Items
correction (W13), and native saved-layout authority. These have differing policy
gates and acceptance scopes; they are not all unconditional features.

### 2.2 Outright missing from the Forever layer

No dedicated production implementation was found for the coordinated 1/2/3
arrangement tracker/cycler (A05/A06), stock Compact and whole-empty-bank choices
(A07/A08), exact world Circle cancellation (F02), the complete shoulder-targeting
and both-shoulder shortcut modes, the three-section stock main radial and its
emote entry, or the unified stock context legend. Some underlying functions are
available through native ConsolePort/other keys; these are missing **specific
Forever systems**, not a claim that the user's setup lacks bags, menus or targets.

### 2.3 Present but incomplete or different

Base Triangle (F04), Square hold interaction (F03/W10), class flyout presentation
and precise gestures (CL04–CL08), gamepad-only temporary overflow/exit (S04/S05),
filled-square/channel/autocast stock art (V04/V08/V10), held shoulder visual
state (V11–V13), and stock Edit Mode/input-type settings need more work or a
deliberate design choice. “Partial” here includes existing useful functionality;
it does not identify a regression without evidence.

### 2.4 Present but inactive

Popup/quantity, custom window/tab/tooltip navigation, audited scrolling,
BetterBags native action routing, item hints and custom map controls are dormant
under native recovery. Learned class/pet selector reconciliation is inactive
preparation. Hidden vehicle-seat replacement and exact cinematic hold are also
not active delivered controls. The appropriate next step is qualification or
research for selected routes, rather than treating all of these as blank modules.

### 2.5 Existing behavior that would have to change

The main change decisions are editable bindings versus stock static input (D01),
Triangle camera/action versus inspect (D02), numbered arrangement storage (D04),
expanded layout versus Compact (D06), shoulders versus class/ping/camera owners
(D07), native ring editing versus stock lists (D08/D09), map axes/marker/focus
(D10/D11), native menu versus stock menu (D12), recovery versus new UI takeover
(D13), and manual layout authority versus automatic input-type switching (D15).
Section 13 gives recommendations and alternatives for each.

## 3. Controls, action banks, pages and base-face behavior

Source anchors: [C01], [C02], [C03], [C04], [C05], [C15]. Native comparison:
N §§1–3, 5, 7, 11, 13.

### 3.1 Bank model and action storage

| ID | Native reference | Actual addon implementation | Assessment / implication |
| --- | --- | --- | --- |
| A01 | Four eight-position clusters, with square D-pad and circular faces; only base faces reserved. N §2.1, S/G/V. | Four native ConsolePort groups and 16 round face surfaces; base-face commands shared; ordinary D-pad/modified chords GUID-owned. | **Implemented structurally.** Native command, action storage and rendered button remain separate. |
| A02 | 28 customizable positions per ordinary arrangement. | 4 base D-pad + 8 L2 + 8 R2 + 8 L2R2 ordinary positions in our model. | **Implemented count**, not native three-arrangement capacity. Do not describe our current product as 84 slots. |
| A03 | Native relative indices: left/up/right/down D-pad 1–4; left/top/right/bottom face 5–8. | Base D-pad binds ACTIONBUTTON9–12. Modified banks use face buttons 1–4 and D-pad 5–8; R2/L2R2 use MultiActionBar1/2. | **Different storage, not by itself incorrect.** Compare physical destination and effective action, not identical numeric index. Importing native index numbers would change existing content. |
| A04 | Native trigger combinations select L2/R2/both layers. | Preset emulates SHIFT/CTRL; native ConsolePort modifier/input machinery owns dispatch. | **Implemented conceptual behavior.** Preserve user edits and qualified native modifier contract. |
| A05 | Three numbered arrangements, wrap cycling, active/populated/empty markers. N §2.2. | No dedicated Forever arrangement manager/tracker found. Native Retail action pages can change, but fixed multi-bar declarations are not three coordinated 28-position arrangements. | **Missing/conflict.** Requires page/storage design and preservation rules, not three labels attached to current banks. |
| A06 | Special `S` marker separate from regular numbered arrangements. | Temporary routing and native pages exist; no native-style `S` tracker. | **Missing visual; native semantics unknown.** An L2R2 temporary badge could be a useful separate addon design, but calling it exact stock `S` needs evidence. |
| A07 | Expanded banks emphasize active layer; Compact shows only active cluster. | Accepted expanded HUD retains native bank scale/opacity behavior, stationary prompts and collision fitting. | **Partial visual match.** Dedicated Compact choice is absent; an upstream layout capability is not this delivered option. |
| A08 | Hide/show entirely empty clusters, not individual empty cells. | Per-cell occupied/empty composition is implemented; no Forever whole-empty-bank preference found. | **Missing.** Empty-art repair must not be confused with bank visibility policy. |
| A09 | Ability/item bind workflow asks for physical destination chord; macros movable. | Native action editing/drag/drop preserved; custom restoration removed. No dedicated stock-style bind-mode workflow in Forever. | **Delegated/unverified.** Test ConsolePort's existing workflow before adding one. Preservation is implemented; exact menu sequence is not. |
| A10 | Stock physical UI bindings static after Oct 1; action contents remain configurable. | Native/user binding edits and GUID-owned projections preserved; planner exposes conflicts, captures edits and keeps explicit empties. | **Deliberate difference/conflict.** Static stock parity would change R02/R04 and the user's current editing contract. |

### 3.2 Base faces: appearance must match the effective command

| ID | Physical button | Native reference behavior | Current behavior / limitation | Classification |
| --- | --- | --- | --- | --- |
| F01 | Cross / A, PAD1 | Jump down/up; while both shoulders active, Sit/Stand/Descend with appropriate release cleanup. S-04. | Preset `JUMP`, native dispatch retained. No active both-shoulder branch supplied by Forever. | **Implemented normal Jump; missing shortcut branch.** |
| F02 | Circle / B, PAD2 | World priority: stop casting, otherwise cancel ground targeting, otherwise clear hard target. Focused UI handles its own Back. S-04. | Preset command empty; `HUD.EmptyVisibility` treats Base Circle as occupied for cosmetic Exit; Cinematic diagnostics explicitly say exact one-success sequencing unproved. | **Missing semantic action / incomplete appearance.** Native/user edits may supply something else; this is a preset/source finding, not proof every live Circle fails. |
| F03 | Square / X, PAD3 | Context interaction/attack/loot; source 0.5s hold alternate path with press styling. S-04. | Preset `INTERACTTARGET`, native interaction target retained. No dedicated 0.5s interaction/loot hold supplied. K01 reports one quest-object failure, cause unknown. | **Partial and open reported case.** Neither unconditional cursor-click nor guessed quest-specific substitution is justified. |
| F04 | Triangle / Y, PAD4 | On ordinary world release opens target unit menu when target exists; context icon changes under targeting. S-04. | Preset `TURNORACTION`; native ConsolePort/base-game ownership. No matching Forever target-menu callback or targeting icon state machine found. | **Partial/conflict.** Changing to target menu could remove existing camera/action behavior. |
| F05 | Faces under triggers | Ordinary assignable actions; base reservation does not apply. | Native modified action routes already exist. | **Implemented.** Any face behavior repair must be limited to unmodified context. |
| F06 | Faces with focused UI | Select, More, Back, confirm according to actual owner. | Native ConsolePort cursor remains; custom context routes disabled by recovery. | **Delegated**, with **dormant** supplemental routes. Do not install a global Circle callback over native dialogs. |

**Candidate next task:** first define and qualify F02, with separate world and
focused-UI owners. Completion means a current authorized secure route performs
one applicable cancellation, leaves lower-priority states intact when an earlier
operation succeeds, respects modified actions, and releases correctly on combat
or focus changes. A macro that performs all three operations does not establish
the requested one-success semantics. The artwork should describe the proven
behavior; changing the icon alone does not close the gap.

For F03, investigate the existing quest report as a regression, not as a reason
to redesign every interaction. Capture quest/object identity, effective input
owner, PAD3 command, trigger state and native soft/hard interaction target at
recurrence. Saved bindings and a floating hand alone do not identify the failure.

### 3.3 Utility, menu and device inputs

| Input / function | Native baseline | Our preset/source | Planning consequence |
| --- | --- | --- | --- |
| L3 autorun | Ordinary autorun. | `PADLSTICK=TOGGLEAUTORUN`. | **Implemented** preset agreement. |
| R3 ping | Tap ping / hold picker; exact stock thresholds unknown. | Native listener binding with candidate.30 secure release-only wrapper. | **Implemented functional family**; details in section 7. |
| Options/Menu radial | Opens native main radial. | `PAD6=CLICK ConsolePortMenuTrigger:LeftButton`; `PADSOCIAL=TOGGLEGAMEMENU`; actual physical translation depends on device. | **Related access**, not established one-to-one physical Menu mapping or stock wheel. |
| Map access | Quest shortcut and contextual radial routes. | `PADSYSTEM=TOGGLEWORLDMAP`. | Function exists through a different logical key. Device mapping must be checked before assigning a physical label. |
| Bags / character / spellbook | Main menu and shoulder shortcuts. | SHIFT-PADBACK/PADSOCIAL bags; CTRL variants character; CTRL-SHIFT variants spellbook. | **Alternative routes/conflict** if new modes reuse them. |
| Utility/class rings | Stock does not substantiate arbitrary utility wheels. | SHIFT-PADFORWARD utility ring; class opener repaired through native ring bindings; reference has legacy CTRL-PADFORWARD Auras. | Preserve current utility use; legacy declaration is not the active class-side authority. |
| Trigger + L3 mounts | No stock mount wheel/chords established here. | L2+L3 LM_B1; R2+L3 LM_B2. | **Retail-specific addition**; preserve native LiteMount rules/icons. |
| L2+R3 extra action | No universal stock mapping established. | `SHIFT-PADRSTICK=EXTRAACTIONBUTTON1`. | Existing useful access; do not overwrite during shortcut/ping work. |
| Share/touchpad/Home/paddles | Driver/platform dependent or unknown. | Logical PAD entries in preset; device-resolved glyphs. | **Unverified physical mapping.** No new universal promises; adaptive controller work remains deferred. |

## 4. Shoulder targeting and HUD shortcuts

Source anchors: [C02], [C03], [C06], [C07], [C08], [C09]. Native comparison:
N §§4–5, 6.1, 7.4, 13.

### 4.1 What is actually active today

The preset assigns L1's logical shoulder to `TARGETNEARESTFRIEND` and R1 to
`TARGETSCANENEMY`. `Skin.Prompts` draws separate Friendly and Hostile decorations
above Base, using fixed left/right art and logical shoulder glyphs. This is
useful orientation, but it is not a held targeting mode. The implementation
does not derive those roles from swapped bindings/settings or supply the stock
pressed-shoulder state machine.

The loaded Forever source has no complete active system that acquires those
shoulders, replaces the center display with friendly/hostile/shortcuts actions,
and transfers right-stick camera input to native target aiming. ConsolePort or
Retail may provide related target behavior; exact total-setup equivalence was
not audited here. The separate **Targeting settings panel** in our addon is for
ground-placement preferences, not proof of a stock shoulder-targeting panel.

### 4.2 Friendly/hostile coverage

| ID | Native capability | Current coverage | Gap / completion requirements |
| --- | --- | --- | --- |
| TG01 | Tap suitable friend/enemy; hold enters corresponding overlay. | Related native targeting bindings; fixed prompts. | **Partial.** Demonstrate tap/down/hold/release and target acquisition before adding a mode. Exact stock hold threshold remains unknown. |
| TG02 | Right stick aims targets while held; camera ownership changes. | No dedicated Forever shoulder aiming adapter. | **Missing/delegated unverified.** Must restore camera on release, lost device, modal and combat transitions; no public imitation of protected target selection. |
| TG03 | Friendly faces: Cross self, Square pet, Circle assist, Triangle marker. | No matching active Forever overlay/routes. | **Missing.** Qualify no-pet, no-target, dead/out-of-range and raid privilege outcomes separately. |
| TG04 | Friendly D-pad traverses party/raid spatially. | Native/manual targeting and saved Party/Raid layout retained; no custom shoulder grid traversal found. | **Missing/delegated.** Layout tracking is not traversal. Spatial order must come from actual native frames. |
| TG05 | Fixed Party Targeting: four member directions in non-raid only. | No delivered Forever preference/router. | **Missing/native mapping unknown.** Obtain actual direction/member mapping and transitions to raid before implementation. |
| TG06 | Hostile faces: last enemy, ranged attack, assist, marker. | No matching active overlay/routes. | **Missing**, with class/weapon availability qualifications for ranged attack. |
| TG07 | Hostile D-pad actions. | Ordinary D-pad action bindings remain; no custom hostile layer. | **Native unknown.** Do not invent four hostile actions or mark them unused. |
| TG08 | Swap friendly/hostile shoulder roles. | Prompt roles fixed; editable native binds can differ. | **Missing setting / potential display conflict.** Current art can disagree with manually changed shoulder bindings; this is a source risk, not a reproduced live report. |
| TG09 | Swap D-pad/face action groups separately per target mode. | No corresponding active model or preference. | **Missing.** Requires overlay/dispatch changes as a group, not global remapping. |
| TG10 | Raid hover mode distinguishes cast recipient and hard target. | Native target/ground policies remain separate; no matching preference. | **Missing/native semantics qualified.** Need target versus recipient observation; an English “hover” label is insufficient. |
| TG11 | Press-to-toggle shoulder/HUD mode. | No dedicated stock toggle state machine. | **Missing/conflict.** Native exact arbitration unknown; ping rejects alternate nonstandard modifier-layer policies. Shoulder toggling must not be confused with trigger latching. |
| TG12 | Pressed shoulders, targeting action artwork, feet aiming circle. | Fixed decorative shoulder icons only. | **Partial/missing visual state.** Ground AoE reticles are not this target-aim indicator. |

### 4.3 Both-shoulder shortcut coverage

None of the following is established as an active **L1+R1** Forever shortcut
layer in the loaded product. Equivalent functions elsewhere do not close the
mode/gesture gap.

| Native L1+R1 input | Native action | Our current related route | Status / collision |
| --- | --- | --- | --- |
| D-pad Up | Quest Log. | Native map/menu access; no identical chord. | **Missing** shoulder shortcut. |
| D-pad Down | Chat. | Native/manual chat interfaces. | **Missing/delegated**; opening chat is distinct from typing. |
| D-pad Left/Right | Previous/next arrangement. | Native Retail pages, no coordinated three-arrangement system. | **Missing**, depends on A05 storage decision. |
| Square | Sheathe weapons. | No matching chord found. | **Missing** shortcut; avoid capturing modified spell input. |
| Triangle | Buff viewer. | Native/manual UI/menu capability not audited. | **Missing/delegated unverified**. |
| Circle | Bags. | Existing SHIFT-PADBACK/PADSOCIAL bags routes. | **Alternative access**, exact mode missing. |
| Cross | Sit/Stand/Descend. | Ordinary Jump; no matching shoulder branch. | **Missing**, must preserve release cleanup. |
| Right stick Up/Down | World camera zoom. | Preset SHIFT/CTRL-PADSYSTEM zoom commands; DynamicCam native profile preservation. | **Different controls/conflict** with camera/target aim/radials. |
| L3 | Recenter camera. | L3 autorun and trigger+L3 LiteMount. | **Missing/context collision**; preserve ordinary autorun and mounts. |
| Hold R3 | Look behind. | R3 native ping and L2+R3 extra action. | **Missing/context collision**; must cancel or yield ping before shortcut ownership. |
| Right stick Left/Right | No universal native action established. | No stock shortcut implementation. | **Native unknown**, not a required invented feature. |

### 4.4 Why this must be one ownership design

L1/R1 participate in individual target modes, the joint shortcuts mode and
same-side class chords. L2/R2 also select ordinary banks, focus windows in some
contexts, and open class access when combined with a shoulder. Right stick can
mean camera, target aim, radial selection or map pan. A mode cannot be designed
by attaching a command to each key independently.

A future design needs a documented transition table for: first shoulder down;
second shoulder down; trigger down while shoulder held; class wheel acquiring
input; shoulder release in either order; trigger release; panel/modal ownership;
combat handoff; held face release; device loss; and any optional toggle mode.
It must distinguish key-down acquisition from key-up action dispatch and cancel
stale held actions. Existing native Manager/Layers priority, class rings, ping,
ground placement and ordinary banks are prerequisites to preserve.

**Recommendation:** treat targeting plus shoulder arbitration as a major future
project, with shortcut/page work staged behind it. The payoff is high, but
reactivating the full suspended SecureModes installer is not a justified shortcut.

## 5. Class and pet access

Source anchors: [C04], [C07], [C10], [C11], [C12]. Native comparison:
N §§6–7, 10.2, 10.7, 14.

### 5.1 Current class-by-class comparison

| Class / family | Native reference | Current implementation | Assessment |
| --- | --- | --- | --- |
| Paladin | Learned aura flyout, left L1+L2, pinned flyout 270. | Left `SHIFT-PADLSHOULDER`, qualified native class ring, learned augmentation, GUID ownership and scoped repair. | **Implemented access family**, not identical native flyout frame/list/gesture. |
| Druid | Learned form flyout, left L1+L2, pinned 262. | Left class chord; learned public form discovery/ring content; ordinary class pages remain native. | **Implemented access family / partial** selection and exact form-page behavior. |
| Warrior | Learned stance flyout, right R1+R2, pinned 269. | Right `CTRL-PADRSHOULDER`; class access/ring and right badge. | **Implemented side/access family**; exhaustive Retail stance coverage unclaimed. |
| Hunter | Official pet control and pet spell flyout categories; exact side/content unresolved. | Current-pet discovery and prepared `CPFPet` proposal; `active=false`; no delivered dual pet flyout implementation. | **Dormant preparation / missing active categories / native unknown details.** |
| Warlock | Same pet categories and evidence limit. | Same discovery/preview boundary; retain native/manual pet controls. | Same assessment; do not assume identical pets, ranks, icons or no-pet behavior. |
| Rogue | No dedicated stock poison/stealth flyout established; dated partial stealth paging report. | Native ordinary/bonus page ownership; no blanket custom replacement. | **Appropriate retained native scope.** A new poison wheel would be an addon addition. |
| Priest/Mage/Shaman | No stock dedicated class wheel substantiated in reference. | Generic class proposal helpers may operate only with actual qualified learned data; later preview remains inactive. | No universal missing-wheel requirement. Absence in native reference is not proof of a forbidden feature. |
| Other Retail classes | Outside the reference's complete class-flyout evidence. | Shared temporary routing policy plus native/manual class controls. | **Retail-specific scope/native unknown**, not automatic all-class parity. |

`ClassActions.Supported` gates the three-class repair and native StanceBar
suppression. It does **not** globally prohibit every generic chord/ring proposal
on other classes. Conversely, a generic right-side fallback does **not** prove
two stock pet flyouts exist. Older CTRL-PADFORWARD/CTRL-SHIFT-PADFORWARD selector
preview keys are inactive preparation data, not an alternative active control map.

### 5.2 Content, gesture and presentation gaps

| ID | Aspect | What we have | Remaining issue |
| --- | --- | --- | --- |
| CL01 | Learned-only eligibility. | Qualified public forms/pet discovery and learned ring augmentation. | **Partial match.** Native flyout enumerates its own known entries; our native form discovery is not proof of identical stock list, ordering or ranks. |
| CL02 | Visibility. | Badge requires matching actual class chord, available content/icon and glyph; native class row hidden only with complete qualified access. | Strong safety/presentation foundation; exact stock level/no-entry visibility still needs class cases. |
| CL03 | Two independent class sides. | One resolved personal class ring/opener with the supported class's correct side. | **Missing** two independently populated pet categories; do not duplicate the same ring on both sides. |
| CL04 | Class opener art/geometry. | 26×26 cosmetic badge below matching side D-pad Down; prompt icons 18px, overall 46×18 for a two-key prompt. | **Different geometry**, versus pinned 38×38 opener and 72×24 prompt at ±138 offsets. Accepted personal layout takes precedence until changed by decision. |
| CL05 | Interactive opener. | Actual action goes through native chord-bound ConsolePort ring; badge is a `Frame`, presentation only. | **Partial** versus stock interactive/pressed class button. Do not infer clicking the badge can cast/open a flyout. |
| CL06 | Popup/ring shape. | Existing ConsolePort renderer and hold/release selection retained. | **Different native owner/appearance** from side-attached stock flyout; exact radial angles and thresholds are unknown in supplied reference. |
| CL07 | Stick-return / close-and-continue. | Explicit gate; selector preparation inactive. | **Not delivered.** Approved desired gesture needs its own audited Retail route. The reference does not prove that every stock flyout uses it. |
| CL08 | Active-entry cancellation. | Explicit separate action-type gate. | **Not delivered.** Re-selecting a form/aura/pet action is not universally a cancellation. |
| CL09 | Manual content ownership. | Generic ring capture preserves order, duplicates, metadata and dormant unavailable entries; class augmentation appends missing learned forms separately. | **Deliberate difference/conflict** with stock learned flyout lists. A deleted learned class entry can return through augmentation; it is not an action-slot restoration bug. |
| CL10 | Current pet identity and autocast. | Discovery validates current pet GUID; preview rejects old/colliding sets. | **Foundation only.** Live pet control/spell separation, autocast UI and pet-swap dispatch not delivered by preparation. |
| CL11 | Form/stance changes after selection. | Native pages retained; no inferred universal 28-slot form replacement. | **Deliberate policy/native uncertainty.** Need dated stock truth table before claiming exact paging parity. |

**Recommendation:** keep the working three-class access. If pet access becomes
the selected priority, first collect source/capture defining the two categories,
side assignments, no-pet handling and protected autocast operations. A useful
Retail pet selector can be specified independently, but it must be described as
an addon design where stock details remain unknown.

## 6. Temporary actions, forms, vehicles and special pages

Source anchors: [C05], [C13], [C14], [C15]. Native comparison: N §§2.2, 6.5, 7.

| ID | Context / behavior | Current result | Comparison and planning consequence |
| --- | --- | --- | --- |
| S01 | Vehicle, possess, quest override, skyriding, temporary high page. | Qualified native family/page evidence replaces L2R2 only; Base/L2/R2 ordinary models retained. | **Implemented approved difference.** Stock exact bank arbitration is not universally established, so this is not a demonstrated native conflict. Changing it requires R03 decision. |
| S02 | Ordinary form/stance/stealth. | Native ordinary/bonus pages remain; appearance alone never qualifies temporary takeover. | **Implemented preservation policy.** Do not copy a historical beta paging bug or extrapolate one Rogue report to all classes. |
| S03 | Temporary action capacity. | Eight displayed combined cells; native declared capacities respected. Vehicle/override often six; unavailable cells remain empty. | **Partial access**, not missing restoration. Native exact slot capacity varies by context. |
| S04 | Native temporary slots 9–12 and exit. | `TemporaryAccess` exposes eligible overflow/exit through mouse-accessible native buttons; no added controller key/cursor acquisition. | **Controller access gap** when a real context needs these actions. Mouse access does not satisfy a gamepad-only goal. |
| S05 | Vehicle seats. | Native seat controls retained; custom hidden-access panel disabled under recovery. | **Delegated/dormant**; not a delivered replacement. Prioritize only after identifying an actual required seat workflow. |
| S06 | Held action during page transition. | Preserve pressed action for release, then resolve current native page; editing caches cleared appropriately. | **Implemented regression protection.** Preserve through future paging or overlay changes. |
| S07 | Drag/drop/remove on temporary cells. | Native edits retained; unavailable drops do not spill into ordinary bindings; stale temporary caches cleared. | **Implemented important correctness**, independent of stock menu appearance. |
| S08 | Return to normal state. | Authoritative native return removes stale family/header takeover; no automatic spell placement/restoration. | **Implemented**; retain meaningful old-failure controls. |
| S09 | Extra action / scenario action. | Preset L2+R3 access and independent ground context preference for extra. | Useful access, but **not proof** all scenario actions fit a universal stock bank or key. |
| S10 | Pet bar does not replace bottom normal bar. | No blanket pet-driven replacement in current temporary family policy; native pet/manual controls retained. | Broadly compatible policy; not exact two-flyout delivery or every-pet live acceptance. |
| S11 | `S` marker and override priority display. | No stock tracker; actual routing state appears through diagnostics. | **Missing user-facing stock tracker; native exact `S` semantics unknown.** |

**Best bounded follow-up:** inventory one real vehicle/quest requiring overflow
or exit without a mouse, then select a native secure access route that preserves
the eight combined cells and ordinary banks. Do not redesign every special page
to reproduce behavior the reference itself cannot establish.

## 7. Ping, radial menus, emotes and buffs

Source anchors: [C02], [C03], [C16], [C17]. Native comparison: N §§8–9.6, 10.8, 14.

### 7.1 Ping is a delivered feature with limited native-parity claims

| Aspect | Actual candidate.30 behavior | Native comparison |
| --- | --- | --- |
| Down | Arm native account-ring selection; send nothing; artwork initially hidden. | Fits tap/hold family; reference lacks exact stock down-phase contract. |
| Neutral/empty tap release | One contextual aimed fallback; no tap art. | Functional stock-like tap, not proved identical stock target arbitration. |
| Deflected/sticky early release | May select native entry before art appears because selection is armed immediately. | Important current behavior; do not promise all short presses are empty fallback. |
| Hold | Reveal real ConsolePort ring at our cosmetic 0.15s threshold. | **Our threshold**, not a sourced stock default. Timer authorizes no protected action. |
| Selection/release | Native secure ring backend/frontend handles selected release once. | Preserve actual native machinery; no replica wheel or public `C_Ping` dispatch. |
| Empty fallback target | Soft enemy, soft friend, then centered world cursor. | Addon-defined qualified path; stock exhaustive precedence remains unknown. |
| Contents | Attack, Warning, On My Way, Assist, Non-threat, Threat initially. Shared account seed once; later order/removal/editing retained. | Native stock list/order not fully established; our six entries must not fill the reference's U as stock evidence. |
| Keys | Qualified gamepad keys actually bound to `TOGGLEPINGLISTENER`, not only hardcoded R3. | **Deliberate editable-binding difference** from stock static UI. |
| Arbitration | Modifier/combat/foreign cursor or radial owner cancels; device/sample loss unwinds through guarded native state. | Preserve during shoulder/menu projects; broader account/combat cases not individually accepted. |
| Acceptance | User accepted reported ring/reopening and Required Items defects in candidate.30. | This is addon acceptance, not native client comparison or all ping scenarios. |

No new ping redesign is justified solely to match an unknown stock wheel radius,
icon order or hold duration. Future shoulder look-behind or menu changes must
exercise repeated opens, early selection, cancellation, remapped keys, shared
edits, other rings and native UV handling through the existing T65 gate.

### 7.2 Main menu coverage

| ID | Native feature | Current coverage | Gap / decision |
| --- | --- | --- | --- |
| M01 | Options opens three-section native radial, right-stick choice. | ConsolePort menu trigger declaration and native/manual Game Menu routes. | **Related delegated capability**; no dedicated stock three-section Forever menu in loaded product. Audit actual ConsolePort menu before replacement. |
| M02 | Main: Character, Talents, Professions, Bags, Spellbook, Game Menu, Chat, Quests/Map. | Several direct preset/native routes; no source-defined matching section membership. | **Missing exact organization**, not proof these destinations are inaccessible. |
| M03 | Left: Shop, Legacy, Group Finder, Collections, Minimap settings, Buffs, Social, Communities. | Native/manual Retail panels; exact ConsolePort coverage unverified. | **Missing exact section; destination compatibility varies.** Native Forever “Legacy” need not be a Retail-equivalent panel. |
| M04 | Right: PvP, Calendar, Clock. | Native/manual access unverified as gamepad flow. | **Missing exact section**, requires actual Retail menu destination audit. |
| M05 | L1/R1 section switching. | No dedicated Forever three-section state machine. | **Missing**; competes with targeting/class shoulders only while this radial owns input. |
| M06 | D-pad Up emote wheel; Down sit/stand while radial focused. | No matching active custom routes found. | **Missing/delegated unverified**; stock complete emote list/order unknown. |
| M07 | Wheel angles, glow, deadzone, animation, opener close/confirm. | ConsolePort native renderer may provide related behavior. | **Native unknown/delegated**, not exact geometry to copy from early screenshots. |
| M08 | Buff viewer and cancellable buff selection. | No dedicated Forever viewer/shoulder route; native/manual routes remain. | **Missing/delegated**; secure cancellation needs action-specific qualification. |

A menu project can be relatively self-contained visually, but only after actual
destination support and native input leases are understood. Avoid duplicating
ConsolePort's wheel and calling it stock because both are circular. The existing
utility and mount rings are useful addon features; stock reference does not
establish them as native Forever wheels.

## 8. Focus, contextual legend, windows and dialogs

Source anchors: [C03], [C08], [C09], [C17], [C18], [C19], [C20]. Native comparison:
N §§9.1, 9.5, 9.7, 10.7–10.8, 11.

### 8.1 Active versus dormant ownership

`NATIVE_INPUT_RECOVERY=true` is a source-level parent gate. `RefreshUI` passes
false for custom context acquisition even if stored `uiContextsEnabled`,
`windowsEnabled`, `bagsEnabled` or `mapEnabled` flags are true. Popup/window/map
methods being loaded or passing tests does not enable them.

Active independent paths include native cursor combat-claim relinquishment,
reviewed focus-effect cosmetics, Targeting preferences and reviewed visibility.
`InputBridge` can release the named native widget's own claims during combat
handoff, including late widgets, while preserving foreign claims. That safety
bridge is not a new popup/window owner.

| ID | Native feature | Actual addon source | Classification and needed work |
| --- | --- | --- | --- |
| U01 | Context legend upper-left with current action glyphs. | Device glyph helpers, bank/class prompts and native ConsolePort UI; no complete custom upper-left stock legend controller found. | **Missing dedicated stock legend / delegated unverified.** Audit existing prompts first; avoid duplicate instructions. |
| U02 | Legend changes for gameplay, targeting, bags, map, binding, menus. | No unified enabled Forever context-to-legend model. | **Missing.** Requires trustworthy effective owner/action state; observation alone cannot claim an input lease. |
| U03 | Gold/Blue/Black focus border and opacity. | Native cursor presentation retained; FocusVisuals suppresses seven transient gameplay feedback regions. | **Different purpose/delegated.** Our focus cosmetics are not stock focus-style selection. |
| U04 | D-pad focused navigation and context-sensitive faces. | Native ConsolePort cursor owns normal navigation. | **Delegated**, not every Retail panel audited for stock sequence. |
| U05 | L2/R2 focused-window switching. | `UI/Windows.lua` has descendant-aware native window ordering and trigger routes. | **Dormant**; native/foreign keyboard/menu/popup priority must be qualified before activation. |
| U06 | L1/R1 section/tab navigation. | Audited native-tab routes in Windows. | **Dormant/partial**; only supported native tabs, not every possible addon window. |
| U07 | Tooltip/context inspection. | Window R3 focused tooltip route. | **Dormant**; R3 differs from stock panel-specific hints and competes with gameplay ping. |
| U08 | Popup accept/cancel/context by displayed hints. | Focused popup buttons 1–4 map PAD1–PAD4; R3 extra. Missing button routes do not consume input. | **Dormant/partial**; numeric popup order is not a universal stock face semantic. |
| U09 | Quantity/split stack adjustment. | PAD1 accept/PAD2 cancel; left/right native adjustment. | **Dormant**, foundation exists; validate bounds, owner replacement and held repeat. |
| U10 | Scroll focused list. | Audited unprotected native scroll-controller callbacks, right-stick dispatcher, 0.2 deadzone, neutral acquisition/native repeats. | **Dormant/partial**; unknown widgets retain native behavior. No universal stock axis contract established. |
| U11 | Hold versus press visual indicators, updated Oct 8. | Several custom prompts, no unified stock updated hold-prompt art/controller. | **Missing exact update / native constants unknown.** Do not apply 0.5s to every action. |
| U12 | Character movement while UI open when focus permits. | Native input retained; no active custom stock movement/focus replication. | **Delegated/unverified**; especially map opening needs focused-state observation. |
| U13 | Raid manager, role poll, loot roll dialogs. | Native Retail/ConsolePort retained; generic dormant popup routes cover only qualified cases. | **Delegated/partial**, not direct proof of all official stock improvements. |
| U14 | Character-select navigation. | Ordinary addon loading does not supply login-screen UI replacement. | **Outside addon scope**; track client/controller capability separately. |

### 8.2 Genuine source wording discrepancy

The setup review label says **“Suppress gameplay icons and highlights while the
interface cursor owns input”**. Actual FocusVisuals preserves icons/cooldowns
and suppresses HighlightTexture, CheckedTexture, PushedTexture, Flash, Border,
SpellHighlightTexture and NewActionTexture, restoring the latest requested
alpha when focus releases. This is an established implementation/label mismatch
already documented in Known Issues. It is a sensible small future source fix,
but this analysis does not change the label or feature.

### 8.3 Recommended activation strategy

Do not lift the recovery gate globally to obtain U05–U10. Select one narrow
native context, prove effective Manager/Layers dispatch and held release,
exercise late/replaced widgets and foreign modals, and preserve all ordinary
32-chord combat routes. Missing-contract paths must yield rather than swallowing
input. Keep keyboard/text owners, menus, radials and protected routes distinct.

A contextual legend can be developed alongside a qualified context, but it
should describe the actual route now available. Displaying a “More” or “Bind”
glyph without a working hardware-authorized operation repeats the Base Circle
problem in a different panel.

## 9. Bags, spellbook, NPCs, crafting and other panel workflows

Source anchors: [C02], [C03], [C19], [C20], [C21], [C22], [C23]. Native comparison:
N §§2.4, 9.2–9.7, 12.

| ID | Workflow | Current coverage | What is missing / incomplete |
| --- | --- | --- | --- |
| W01 | Bag grid navigation. | Native BetterBags/ConsolePort interface retained. | Exact stock grid focus and hints **delegated/unverified**; not a stock all-item radial. |
| W02 | Equip/select/move item, More menu. | BetterBags adapter implements exact qualified physical pool and native left/right click/ItemMenu using distinct configured face keys. | **Dormant**, not delivered custom mapping. Do not equate physical Square with native left-click without current key configuration. |
| W03 | Bind usable item from More to chosen action chord. | Native item/action editing retained. | No dedicated active stock-style Bind transition/controller destination capture. **Missing/delegated**. |
| W04 | Bind learned spell from Spellbook with Square. | Native spellbook/action editing preserved. | No dedicated active matching flow. **Missing/delegated**; audit upstream before building duplicate bind mode. |
| W05 | Macro movement. | Native drag/remove preserved; ActionRecovery no longer writes slots. | Preservation **implemented**; exhaustive controller macro-flow acceptance not asserted. Stock Oct 1 fix is not a guarantee about Retail addon input. |
| W06 | Split/destroy/share item contextual choices. | Native ItemMenu retained; dormant quantity and bag routes. | **Partial/dormant/delegated**; exact operations depend on focused item eligibility. |
| W07 | Item comparison via bag management. | Native tooltip/item interfaces preserved; custom item hints avoid disturbing comparison. | Exact controller route/toggle **unverified**, not proof stats are unavailable. |
| W08 | Cancel carried item before bag close. | Dormant BetterBags path explicitly clears carried item before closing. | **Implemented but dormant**, useful foundation. Validate stale item/owner rejection. |
| W09 | Contextual merchant hints. | ItemHints supports native Select/Buy/Buy Back and eligible container Open glyphs; preserves names/foreign instructions. | **Dormant**; not complete vendor/trade/AH accessibility. |
| W10 | 0.5-second transient loot hold. | Native modified click retained; no exact temporary override. | **Missing/gated**; must not toggle persistent auto-loot or use timer as protected-action authority. |
| W11 | Interact NPC/object/corpse. | Native `INTERACTTARGET`; Immersion dialog integration. | **Partial** stock tap/hold behavior; K01 concrete quest-object report needs diagnosis. |
| W12 | Quest accept/complete/choice focus. | Native Immersion/ConsolePort interfaces retained. | Exact gamepad-only sequence for every dialog **delegated/unverified**. Required Items position repair does not supply navigation. |
| W13 | Required Items presentation. | Deferred native Immersion measurement correction; exact integration guards; reported defect accepted. | **Implemented addon improvement**. Not evidence stock Forever uses the Immersion frame/offset. Preserve disable/manual settings. |
| W14 | Quest-starting inventory item. | Native item access retained; potential dormant container hint. | **Unverified end-to-end workflow**, not automatically fixed by stock Sep 22 notes. |
| W15 | Professions/crafting navigation and held confirmation. | Native Retail panels retained; generic dormant windows routes. | No dedicated complete recipe/craft/hold implementation. **Missing/delegated**, stock universal hold duration unknown. |
| W16 | Pet stable navigation. | Native Retail/ConsolePort retained. | No dedicated verified stock-like stable route. **Delegated/unverified**. |
| W17 | Auction House, trade, vendor quantities, recipe search/text. | Native/manual interfaces; custom typing deferred. | **Unverified accessibility**, not established one universal failure. Requires panel-specific walkthrough and text-owner behavior. |
| W18 | Chat text input. | Native/manual chat; existing ConsolePort keyboard, if available, retains its ownership. | Custom changes deferred; no proof stock built-in keyboard after later beta changes. **Do not invent missing native feature.** |

The BetterBags adapter is version-qualified to v0.5.14. It checks bag/slot/item
GUID/stack/lock and context generation at dispatch; virtual items and stale
themes yield. This makes it a meaningful implementation foundation, but also
means “support all bags” is not a small activation task. Its safe refusal cases
are part of the contract, not incomplete polish to remove.

For choosing the next panel project, use a concrete walkthrough: open panel,
acquire focus, navigate, inspect, invoke the relevant action, handle confirmation,
cancel/back, return to gameplay, then repeat across combat/owner changes. A
screen with correct art but a required mouse operation is only partial
controller coverage.

## 10. World map and quest log: an existing implementation that would change

Source anchors: [C02], [C03], [C19], [C24]. Native comparison: N §§9.4, 11, 14.

This is the clearest **dormant implementation conflict**, rather than a blank
feature area. Our adapter's documented controls differ from the captured native
Forever map. Neither should be silently enabled as the other's equivalent.

| ID | Aspect | Native reference | Our adapter / current active state | Consequence |
| --- | --- | --- | --- | --- |
| Q01 | Opening focus. | Oct 8 focuses Quest Log first, allows movement until map cursor engaged. B-04. | Native Retail/ConsolePort opening remains active; custom adapter recognizes existing map/detail focus, does not implement that stock initial-focus transition. | **Missing/delegated unverified.** Must observe actual startup focus and movement/camera before changing it. |
| Q02 | Map pan. | Right stick in captured walkthrough. G/V. | Dormant adapter uses **left stick** pan. | **Conflict**; adopting stock mapping changes implemented axis contract and movement arbitration. |
| Q03 | Map zoom. | L1/R1 in captured walkthrough. | Dormant adapter uses **right stick vertical** zoom. | **Conflict**, affects existing generic window shoulder tabs and camera restoration. |
| Q04 | Map marker. | Square in walkthrough. | Dormant hardware **L3** waypoint/remove/supertrack route. | **Conflict**, not only a glyph update. Native waypoint action revalidates map/coordinates/owner. |
| Q05 | Fullscreen toggle. | D-pad Down toggles both directions. | Adapter Back minimizes expanded map; no matching stock D-pad toggle established. | **Partial/missing** exact control. |
| Q06 | Upper controls/filters. | D-pad Up changes focus. | Native cursor remains; no dedicated stock Up route. | **Delegated/unverified**. |
| Q07 | Broader map level. | Triangle in walkthrough. | No matching custom stock Triangle route. | **Missing/delegated**. |
| Q08 | Quest list/details. | D-pad list; Square details; Triangle Share/Abandon. | Native list ownership; dormant detail-aware Back returns from detail or minimizes. | **Partial/dormant**, not matching complete stock faces. |
| Q09 | Back. | Context-dependent return/close. | Dormant native minimize/detail-return logic; focused owner validation. | Existing useful behavior, but no universal Back priority to copy from one capture. |
| Q10 | POI pin hover. | Sep 24 gamepad improvement. | Native map/provider behavior retained; no dedicated verified stock hover implementation. | **Delegated/unverified**, requires actual provider focus test. |
| Q11 | Search/keyboard/foreign owner. | Context ownership matters. | Adapter yields for text/keyboard/menu/foreign overlay, validates map IDs/art/coordinates and public values. | **Implemented dormant safety foundation** to preserve in redesign. |

**Decision needed if selected:** keep our existing dormant controller design,
adopt the documented stock pan/zoom/marker controls, or expose a narrowly defined
choice. Recommendation for a Forever-parity goal: investigate stock control
mapping and Quest Log-first focus together, then choose one default. A
configurable two-scheme solution adds settings, gesture coverage and maintenance;
it should not be assumed desirable without the user's preference.

Whichever scheme is chosen, demonstrate that opening map while running leaves
movement available until focus intentionally transfers, that held sticks acquire
neutrally, and that closing/text/modal/combat transitions restore gameplay
without duplicate pings, waypoints or camera movement. Offline callback tests
alone do not establish this user experience.

## 11. Artwork, geometry, composition and visual states

Source anchors: [C06], [C07], [C08], [C25], [C26]. Native comparison:
N §10, §§4.5, 6.1, 6.4, 8.1, 9.1.

### 11.1 What the current visual system does well

We already ship `ForeverInGame.blp` and `ForeverTargeting.blp`, with original
sprite coordinates, available atlas fallback and device-resolved input glyphs.
Face icon/state treatment is scoped to 16 face surfaces rather than disabling
Masque globally. Occupied face icons sit above empty-only mattes; obsolete
square Masque overlays are retired; native atlas UVs and secret-value sinks are
preserved. Empty D-pad cells receive directional art without making filled
D-pad cells round.

Native usability, range/resource restrictions, charge/GCD/loss-of-control
cooldowns and power information remain. Late native art/Masque recreation,
combat cosmetic refresh, bank opacity mirroring and bounded collision fitting
have meaningful existing regression coverage. Candidate.17 acceptance covers
reported composition/HUD defects. None of that establishes every stock texture
or source-default coordinate is reproduced.

### 11.2 Geometry comparison

| Native pinned reference | Current addon source | Classification / choice |
| --- | --- | --- |
| Whole HUD 656×202 at UIParent BOTTOM +110. | Separate native ConsolePort groups using captured/user geometry; runtime guard can lift qualified older Base layout; current 160/5 bank geometry retained. | **Different accepted geometry.** No single equivalent whole-HUD frame. Do not overwrite saved layouts to force pinned defaults. |
| Square cells 32 collapsed / 40 expanded; circles 30 / 38. | Current ConsolePort group/button sizing and native scale policies retained; face masks/art fit live button width. | **Partial visual parity**, not identical fixed size contract. Need scale-aware capture before deciding. |
| Eight-cell frame 208×68 / 266×86. | Captured reference groups 277.5×140 before native scaling; live current geometry may differ. | **Different source model**; direct unscaled numbers cannot be compared as screen pixels. |
| Press shrinks cell by 4 and moves anchor about -2. | Native button press visibility and round gold pushed overlay; no dedicated stock -4/-2 geometry animation found. | **Partial** physical feedback; exact stock pressed motion missing/unverified. |
| Class opener 38×38; paired prompt 72×24 at pinned ±138/-50/-80 anchors. | Cosmetic badge 26×26 below side D-pad Down; paired glyphs 18 with 10 spacing. | **Demonstrated design difference**; change only if approved visual target warrants it. |
| Trigger prompts near clusters, device-aware. | 22px stationary trigger prompts mirror visibility/opacity and avoid active-scale drift. | **Implemented family**, with deliberately stabilized placement. |
| Page tracker 1/2/3/S. | No dedicated tracker. | **Missing**; depends on actual page semantics. |

Native September captures are useful composition references, but 1920×1080
image dimensions do not convert source UI units into live pixel coordinates.
A visual comparison needs matching viewport, UI scale, device glyph family,
action fill state and active layer. Fixed personal layout improvements are
within a potential request; general adaptive resolution/controller work is still
outside current scope.

### 11.3 Art and feedback completeness

| ID | State / component | What is implemented | Gap / qualification |
| --- | --- | --- | --- |
| V01 | Empty faces and D-pad. | Original circle glyph/directional-square empty art; SHP/LTR/REV mappings and atlas fallback. | **Implemented major parity.** Native Generic mode's exact empty-face artwork not separately mapped in `FACE_NAMES`; unknown labels fall back to letters. Glyph helper can use device-native art. |
| V02 | Normal/hover/checked/pressed face borders. | Round atlas/fallback surfaces; native visibility retained. | **Implemented family**, not every stock effect sequence. |
| V03 | Pushed feedback. | Native pushed region uses ConsolePort round highlight tinted gold and drawn above icon; failed casts still press. | **Different effect source**, not necessarily incorrect accepted design. Exact stock border/size motion would require visual choice. |
| V04 | Filled D-pad square state family. | Native square buttons retained; Forever empty art only. | **Partial.** Full stock square normal/pressed/hover/checked/cast/channel/AoE/interrupt family is not comprehensively replaced by face skinning. |
| V05 | Cooldown/GCD/charges/LoC. | Round faces preserve separate native pathways; nonzero overlay alpha capped at 0.65, native zero retained. | **Implemented feedback protection**, custom alpha policy. Native reference does not provide a universal exact swipe formula to clone. |
| V06 | Range/resource/disabled/party-sync. | Native real and secret/opaque state pathways retained. | **Implemented** important semantics; never whiten icons to match a screenshot at the cost of usability feedback. |
| V07 | Cast and interrupt. | Face native nested effect masks, cast/interrupt atlas/fallback and parent-local masks. | **Partial original-art integration**, not all square/circle timing/complete-glow parity. |
| V08 | Channel fill/complete glow. | Native feedback retained; sprite coordinate exists; no dedicated comprehensive channel rebuild found in `RoundEffects`. | **Partial/delegated visual state**; presence of a channel sprite is not proof it is used everywhere. |
| V09 | AoE reticle. | Round face target-reticle mask/atlas integration; qualified ground adapter. | **Implemented family**, distinct from shoulder target-aim circle. |
| V10 | Pet autocast corners/ants. | Native pet/manual controls retained; no dedicated complete stock square/circle pet-autocast skin path found. | **Missing/unverified visual parity**, tied to future pet access. |
| V11 | Shoulder backgrounds and glyphs. | Original targeting sheet and fixed Friendly/Hostile prompt decorations. | **Partial**: no binding-role swap reflection or stock pressed/hold overlay system. |
| V12 | Target-mode action art. | No active friendly/hostile action overlay renderer. | **Missing**, requires valid action/owner semantics first. |
| V13 | Both-shoulder shortcut art. | No active stock shortcuts overlay. | **Missing**; depends on shortcut project. |
| V14 | Class badge. | Learned/native icon, active public form preference, matching chord glyphs, continuous bank-opacity mirror. | **Implemented presentation family**; no badge click/stock popup or native 38px geometry. |
| V15 | Main radial/emote/focus art. | ConsolePort/base-game rendering retained. | **Delegated/different**, not a stock menu/Gold-Blue-Black art pack. |
| V16 | Contextual press/hold prompts. | Existing device glyphs/bank/class/hint machinery. | Updated Oct 8 stock indicator **missing/native dimensions unknown**. |
| V17 | Hidden native side/bag/micro bars. | Reviewed owned-parent suppression; Edit Mode/disable/foreign drift restoration. | **Active adjunct policy**, not full native HUD takeover. |
| V18 | Native class row suppression. | Independent accepted complete three-class ring guard; restore on Edit Mode/lost eligibility. | **Implemented**; other class rows/power must not be hidden by analogy. |
| V19 | Native resource/power/player/target/cast UI. | Preserved, including previous player-strip feedback work. | **Preservation**, not a complete stock whole-screen re-layout. |
| V20 | Full boss-HUD composition. | Saved manual layout authority and existing personal HUD. | **Partial/incomparable without matched capture**; screenshot is a composition guide, not an instruction to move every system. |

### 11.4 A useful visual work package

If artwork is selected next, define a finite state contact sheet instead of
“make it identical”: each face/D-pad filled and empty; inactive/active bank;
pressed cast success/failure; range/resource/disabled; GCD/charge/LoC; cast/channel
completion; AoE; class badge; targeting shoulder; device glyph variant; and
Edit Mode/focus transitions. Compare composed pixels and silhouette, not only
tint/alpha getters. Preserve T24/T49/T53, geometry T45/T50/T51 and feedback
T54–T57 gates. A narrow art project can improve V04/V08/V10 without requiring a
new paging or targeting policy, provided it does not imply inactive controls.

## 12. Settings, persistence and Edit Mode

Source anchors: [C03], [C08], [C12], [C15], [C23], [C27], [C28], [C29]. Native
comparison: N §11 and §4.4. The table covers every individual native setting
listed in N §11.2; an upstream option with similar intent is **not** claimed as
an exact Forever label, default or saved-data contract.

| Native setting / control | Current addon counterpart | Assessment and future choice |
| --- | --- | --- |
| Enable Gamepad UI (Alpha). | Installed/accepted character and reviewed feature policies; native ConsolePort presentation. | **Different architecture**, no stock UI-type switch supplied. Login/client control is outside normal addon scope. |
| Show Input Legend. | Native ConsolePort prompts plus local bank/class glyphs. | Complete dedicated stock legend/toggle **missing/delegated**. |
| Horizontal Camera Speed. | Native Retail/ConsolePort settings retained; no matching Forever proposal. | **Delegated/unverified**; preserve current value, stock numeric default unknown. |
| Vertical Camera Speed. | Same. | Same; do not manufacture a couch-camera preset. |
| Horizontal Invert. | Native settings retained. | **Delegated**, exact stock default/persistence unknown. |
| Vertical Invert. | Native settings retained. | Same; historical beta save bug is not a current addon defect. |
| Follow Camera. | Native camera and copied current DynamicCam profile/situations. | **Related capability**, no proven one-to-one mapping. |
| Follow Camera Pitch Offset. | Native/current DynamicCam state preserved. | Exact stock field/default **unverified**. |
| Turn Player With Camera. | Native input/CVars retained; not among bulk setup writes. | **Delegated**, do not override from guide assumptions. |
| Face Movement While Mounted. | Native/LiteMount/DynamicCam behavior retained. | **Delegated**, not mount rule rewrite. |
| Face Movement While Swimming. | Native movement. | **Delegated**, no matching addon setting. |
| Face Movement While Gliding. | Native movement/temporary family qualification. | **Delegated**, flight appearance does not authorize bank takeover. |
| HUD Modifier: Press to Toggle. | No active shoulder/HUD toggle preference. | **Missing/conflict**, requires state arbitration; does not imply trigger latch. |
| Frame Focus Style. | Native cursor visuals; local focus-effect suppression is different. | Dedicated Gold/Blue/Black choice **missing/delegated**. |
| Frame Focus Opacity. | Native cursor settings; local restoration of external feedback alpha. | No matching stock focus-opacity surface. **Different concept**. |
| Show Input Prompts. | Local device glyphs and stationary bank prompts under source eligibility. | **Partial**, no single delivered stock prompt toggle covering all controls. Post-Oct 8 location uncertain. |
| Show Action Bar Highlight. | Native scale/opacity and face feedback, no matching dedicated stock-shadow setting. | **Partial/delegated**; active group shadow differs from spell pressed glow. |
| Enable Action Bar Scaling. | Native group rescale from current/captured layout; decoration fixes accommodate scale. | **Implemented capability**, no matching stock Edit Mode control proved. |
| Show Empty Action Bars. | Per-cell empty art and native group visibility retained. | Dedicated whole-empty-cluster option **missing**. |
| Use Compact Action Bar. | Expanded personal layout; no dedicated compatible stock Compact feature. | **Missing/conflict** with R01/current layout. Add only after clear user choice; not ordinary cell hiding. |
| Stance Bar Override. | Native ordinary class pages and guarded class row suppression. | **Different policy**; exact stock setting truth table unknown. |
| Possess Bar Override. | Qualified possess routing on L2R2. | **Approved difference**; native configurable truth table unknown. |
| Fixed Party Targeting. | Native Party layout preservation, not a target-direction router. | **Missing**, exact stock member direction unknown. |
| Swap Target Modifier Sides. | Editable shoulder binds; prompts fixed. | Matching coordinated preference **missing**; potential prompt inconsistency. |
| Swap Friendly Target Action Sides. | No active friendly overlay model. | **Missing**, depends on targeting. |
| Swap Hostile Target Action Sides. | No active hostile overlay model. | **Missing**, depends on targeting. |
| Raid Targeting Hover Mode. | Native target ownership/ground preferences. | Matching shoulder/cast-target preference **missing/unverified**. |
| Gamepad Action Bar Edit Mode. | ConsolePort group geometry plus native Retail layout adapter/tracker. | **Partial/different owner**; not stock Blizzard GamepadActionBar handles/options. |
| Gamepad UI layout type. | Managed native Retail saved layout and per-GUID capture. | Automatic separate gamepad versus keyboard UI-type layouts **missing**; per-GUID capture is not per-input-type switching. |

### 12.1 Existing settings that are useful additions

Our reviewed configuration, conflict choices, before-state journals, owned
readback, recovery and GUID archives are deliberate addon mechanisms, not stock
Forever UI settings. Setup proposes only registered trigger emulation CVars,
not all saved native camera/controller values. The active ground panel supports
`default`, `cursor`, `player`, `manual` per spell/context/context-spell with
qualification; it has no equivalent fully defined in the supplied stock list.

Our ground history records prior whole tables but has no retention cap or
history-restore command; Revert discards draft edits, not prior applied history.
This is a settings usability/maintenance opportunity, not native parity.
Similarly `/cpf update` opens configuration review, not a code updater; runtime
readiness strings can remain “pending” after later scoped user acceptance.

### 12.2 Layout authority must survive future parity work

Latest native saved layouts are authoritative. Tracking captures active
saved/export/index per GUID and the uniquely owned account default separately,
including an inactive default. It never saves/selects/imports while tracking.
Initial reviewed managed-copy setup is separate; Party defaults apply only to
new copies, preserving existing Party/manual edits. Packaged 52-system data can
seed a missing stored reference but is not automatically applied.

Stock October 8 added per-UI-type layout separation and moved **action-bar**
settings into Edit Mode without migrating prior values. That is neither a reason
to clear our settings nor proof all stock gamepad options moved. If Compact or
input-type switching is chosen, first specify whose layout is saved, when a
selection is allowed, how manual changes survive, and how previous ownership
is restored. R09 and T67 must remain explicit.

## 13. Conflict and decision register

These are the choices that would change current behavior or ownership. They are
not all defects, and no decision is recorded as made by this analysis.

| ID | Choice | Current contract affected | Recommendation / alternative |
| --- | --- | --- | --- |
| D01 | Editable ConsolePort/native bindings versus stock static physical controls. | R02/R04; shared base faces, GUID personal bindings, native edit capture. | **Preserve editable ownership.** Reproduce stock defaults where useful without locking user edits. Exact lock would require explicit decision. |
| D02 | Base Triangle target menu versus `TURNORACTION`. | Current preset/native camera/action route. | Investigate current actual use and stock callback; choose context-scoped target menu only with preserved camera access. Alternative: keep current Triangle and add separate inspect access. |
| D03 | Exact one-success Base Circle versus current empty/native binding. | Native recovery and protected dispatch; current cosmetic exit art. | Prioritize secure feasibility and explicit world/focused-UI contract. If not provable, keep native route and make presentation honest; do not substitute combined cancellation silently. |
| D04 | Three coordinated numbered arrangements versus current bank/storage model. | R02/R03/R04; Retail native paging, actions, GUID persistence. | Treat as a major separate feature. Alternative: retain one arrangement and add clear temporary-state feedback. |
| D05 | Stock special-page bank routing versus L2R2-only temporary policy. | R03; accepted ordinary bank access. | **Preserve L2R2 policy** absent demonstrated user need and authoritative native truth table. |
| D06 | Expanded accepted layout versus Compact/stock source dimensions. | R01/R09; accepted geometry and manual saved layouts. | Preserve expanded default; add optional Compact only if selected. Exact dimension clone is a separate visual choice. |
| D07 | Shoulder targeting/shortcuts over existing native commands. | R02/R07/R11; class ring, ping, camera, ordinary and UI ownership. | Design one qualified arbitration system, stage narrow active routes. Alternative: improve existing direct commands/prompts without a new full mode. |
| D08 | Stock class lists/order versus editable native rings and augmentation. | R04/R07; GUID ownership/manual order and learned entries. | Preserve native manual rings; qualify stock-like generated subset only if chosen. Document whether generated-entry deletion is persistent. |
| D09 | Two pet categories versus current single inactive CPFPet preview. | Class/pet discovery, inactive preview keys and current native pet access. | Research source-defined category split; do not promote preview as production. Alternative: a separately specified Retail pet utility ring. |
| D10 | Stock map right-pan/shoulder-zoom/Square-marker versus current left-pan/right-zoom/L3. | Dormant Map adapter, native movement and window shoulders. | Choose one scheme after observation. For strict parity prefer referenced scheme when evidence is sufficient; dual scheme adds maintenance. |
| D11 | Quest Log-first map opening versus existing native focus. | Cursor/window acquisition and character movement/camera. | Treat focus transition as part of map project, not unrelated polish. Yield to keyboard/foreign owners. |
| D12 | Dedicated Forever main menu versus native ConsolePort menu. | Native menu lease, current utility ring/menu binds, Retail destination availability. | Audit native menu and add missing organization conservatively. Full replacement only if chosen and qualified. |
| D13 | Re-enable all custom UI versus native recovery. | R11; combat handoff, accepted native dispatch/ground/ping. | **Do not lift gate wholesale.** Qualify one contextual route at a time through real native ownership. |
| D14 | Exact stock press/channel/autocast art versus accepted native feedback treatment. | R01; Masque, native usability and feedback. | Narrow visual changes with composed-state evidence; preserve semantics. |
| D15 | Input-type layout switching versus native saved-layout authority. | R09 and manual layout/Party preservation. | No automatic switching until a specific ownership/selection design is approved. |
| D16 | New stock-like settings page versus existing native/reviewed configuration. | Review/planner/source gates and native configuration ownership. | Expose only actual enabled options, with correct labels and values. A setting must not promise dormant behavior. |

## 14. Native unknowns and research still needed

The following maps **all twenty unresolved items in native N §14** to a planning
effect. Missing addon behavior does not resolve missing native evidence.

| Native unknown # | Unresolved evidence | Why it matters here / next evidence |
| --- | --- | --- |
| 1 | Hunter/Warlock contents, order, autocast, no-pet fallback. | Needed for CL03/CL10 and D09. Obtain dated native source or captures for both pet categories and pet states. |
| 2 | Druid form order across learned/race combinations. | Our form discovery/manual ring order is not stock order. Capture low/full learned lists before claiming exact content. |
| 3 | Warrior stance order/unknown/blocked presentation. | Test inactive/blocked stances separately; do not equate ring availability with stock grey/hide rules. |
| 4 | Complete class selection/release/neutral/cancel gestures. | Our gated stick-return and active-entry behavior cannot be asserted stock from opener code alone. Need complete input/cast timeline. |
| 5 | Form/stance/stealth bank changes across settings/builds. | Needed before changing native ordinary pages or D04/D05; preserve current policy meanwhile. |
| 6 | Full possess/charm/vehicle/extra/pet/override/S priority. | Required for exact special-page parity. Our L2R2-only policy is a chosen solution, not native evidence. |
| 7 | Numeric hold thresholds beyond pinned Interact 0.5s. | Our ping 0.15s is not stock; crafting/cinematic/class timers need separate evidence. |
| 8 | Hostile targeting D-pad. | Keep TG07 unknown; do not allocate arbitrary hostile actions. |
| 9 | Fixed Party D-pad-to-member mapping and self/order handling. | Needed for TG05 and settings; party/raid layout snapshot alone does not prove mapping. |
| 10 | Toggle-HUD modifier arbitration. | Needed before optional latch mode and shoulder simultaneous-release behavior. |
| 11 | Special page count/meaning across gameplay contexts. | Prevent `S` from being implemented as fourth ordinary arrangement. |
| 12 | Main radial angles/radius/glow/timing/confirm. | September visuals guide style, not exact October constants; source or matched footage needed for D12. |
| 13 | Emote/ping stock contents/order/editability. | Do not substitute our editable six-entry account ring as native proof. |
| 14 | Current stock integrated keyboard. | Text-entry work remains separately deferred; no false claim of native keyboard absence after unverified updates. |
| 15 | Share/touchpad/Home translation across Windows input modes. | Record actual physical-to-logical device map before changing Menu/Map access. |
| 16 | Which bar options moved to Edit Mode and exact controls/ranges. | Section 12 names provenance; do not present historical guide menu location as current verified UI. |
| 17 | Persistence of old Edit Mode/form bugs after Oct 8. | Do not open local defects or imitate old bugs from stale reports. |
| 18 | Actual October geometry after scale/viewport/Edit Mode. | Needed for visual parity contact sheet; retain accepted geometry until chosen. |
| 19 | Invalid target/pet/item/range/unusable and same-input fallbacks. | Completion cases for target, pet and item projects; exact defaults cannot be inferred. |
| 20 | Complete controller-only accessibility of every panel. | Use panel walkthroughs; official support for one manager does not certify AH/professions/vendor coverage. |

### 14.1 Limits and useful improvements to the supplied reference

The original reference is strong as a descriptive catalog: it separates
official updates, pinned source, visuals, guide claims and player reports;
distinguishes four modifier systems; records October 8 setting migration; and
keeps unknowns explicit. It should remain separate from this addon comparison.

For future research, enrich it with build/controller/input-mode provenance per
capture, exact path/line anchors per source claim, and complete gesture timelines.
For each mode capture down, hold, selection, release, neutral return, cancel and
re-entry, not only an open popup screenshot. Capture supported/unsupported
target/action cases and actual resulting target/cast/UI state. Record UI scale,
viewport and saved layout when measuring art.

The title's “complete observed” scope does not mean every operational contract
is complete. Its redundant quick matrix is an index; the detailed qualifications
prevail. Held cinematic skip and exact stick-return/close-and-continue are approved
addon directions recorded elsewhere, but the supplied native reference does not
fully establish them as stock gestures. They remain separate research/secure
proof tasks rather than automatic parity requirements.

## 15. Choosing the next implementation work

### 15.1 Recommended ordering

| Priority | Work package | User value | Difficulty / dependency | Concrete outcome to review |
| --- | --- | --- | --- | --- |
| 1 | Base Circle semantics and truthful face prompts. | Closes a visible/action mismatch during normal gameplay; improves cancellation consistency. | Medium-to-high secure feasibility; current one-success gate is material. | Proven context-scoped action/owner sequence, or honest native/cosmetic fallback with explicit unresolved limit. |
| 1 when reproducible | Quest-object interaction diagnosis. | Addresses a reported real failure rather than inferred parity. | Requires recurrence/effective native target and input evidence. | Demonstrated cause and regression that rejects the old failure; no guessed pointer-click workaround. |
| 2 | Focused artwork/feedback contact sheet and narrow gaps. | Visible improvement with limited policy change; square/channel/pet art can be assessed separately. | Medium; matched source/art states and existing composition gates. | Named states with verified composition, preserving feedback and manual geometry. |
| 3 | Friendly/hostile shoulder system with class/ping arbitration. | Largest gain toward the native controller experience. | High; protected/native input ownership, right-stick transfer, target semantics and native unknowns. | A bounded first mode with release/cancel/foreign/combat behavior, then the second mode/settings. |
| 4 | One native window/dialog context. | Improves actual gamepad navigation, uses existing code. | Medium-to-high; recovery remains until qualified. | End-to-end panel workflow with real dispatch, no swallowed/misdirected inputs. |
| 5 | Map controls plus Quest Log-first focus. | Strong everyday navigation improvement. | High; explicit D10/D11 decision and movement/camera ownership. | Chosen control scheme, working focus transfer and repeatable return to gameplay. |
| 6 | Hunter/Warlock pet access. | High for those characters, limited benefit otherwise. | Research first; category split, pet identity/autocast secure paths. | Two justified categories or clearly labeled Retail-specific alternative, with pet swap/no-pet behavior. |
| 7 | Three-section main menu / contextual legend. | Discoverability and visual identity. | Medium-to-high native menu/destination audit; exact stock art constants unknown. | Working destinations and honest current input hints; no duplicate wheel ownership. |
| 8 | Numbered arrangements / Compact / stock settings surface. | Broader customization/parity. | High policy/storage/layout choice; not needed for existing four-bank correctness. | Explicitly approved capacity/layout model preserving manual actions, bindings and saved layouts. |

Priorities are conditional recommendations, not a compulsory roadmap. If the
user wants the closest interaction resemblance first, shoulder targeting is the
largest project. If they want visible progress with less ownership risk, choose
a finite art package. If they mainly play pet classes, pet research/access can
move earlier. A reported reproducible failure should take precedence over
cosmetic parity.

### 15.2 Smaller cleanup opportunities kept separate from parity

- Correct the existing focus review label to match preservation of icons and
  suppression of transient feedback.
- Make runtime proof/readiness wording distinguish source readiness from retained
  user acceptance, without claiming untouched cases passed.
- Review whether fixed shoulder role art should follow effective bindings or
  disappear when roles cannot be qualified.
- Decide whether ground-preference history needs bounded retention or an explicit
  restore-history operation; this is addon usability, not stock imitation.

These are potential future source changes. None is applied by this document.

### 15.3 Validation needed for selected work

Existing [testing requirements](../../TESTING.md) determine exact gates. Runtime
work needs fresh official stable Retail dependency inspection before edits and
the complete Test-All entry point. This documentation pass uses the approved
docs-only exemption; it does not declare cached dependencies current.

| Work | Existing gates to preserve | Additional meaningful cases |
| --- | --- | --- |
| Base faces / shoulders / menus | T41 native Layers/Input ownership; T42 ground dispatch; T61/T62 ordinary/temporary integration. | Effective Jump/Interact/Cancel/context commands, release order, failed/ineligible actions, late owner, foreign modal, all ordinary chords, combat handoff. Action-slot-only main-face fixtures are insufficient. |
| Art / glyph / geometry | T24/T49/T53 composition; T45/T50/T51 geometry; T54–T57 native feedback. | Square and circle state contact sheet; Generic/Shapes/Letters/Reverse where available; empty/refill, Masque late recreation, channel/autocast, device changes and matched captures. |
| Class/pet | T43/T47/T58/T59/T63 binding/ring/GUID ownership. | Learned/no-learned, pet change/no-pet, blocked action, manual order/duplicates/deletion, action-specific cancellation, selector activation distinct from preview. |
| Map/window/bags | T41 actual native ownership, existing qualified context/adapter tests. | Panel walkthrough, search/text ownership, neutral acquisition, carried/stale item, lost frame, close/minimize, running/camera restoration, repeated combat and foreign-owner transitions. |
| Pages/temporary/overflow | T61/T62/T64 routing/editing/no-restoration. | User edits/removals before/after page switch; old held action release; exact capacity; vehicle exit/overflow gamepad access; no permanent-slot spill. |
| Ping impacted by another mode | T65 actual native wrappers/backend/frontend/compiler/macro dispatch. | Early selected tap, empty fallback, repeated open, alternate keys, shared edits, other-ring reuse, modifier/combat/owner cancellation and UV preservation. |
| Settings/layout | T67 saved capture and independent installer/configuration ownership checks. | Existing manual Party/layout preserved, no tracking save/select, stale review conflicts, reload/GUID/account behavior and honest dormant setting labels. |
| Immersion impacted | T66 native measurement reproduction and negative control. | Required Items native preference/disable/close guards; no upstream bytes/settings rewrite. |

Offline results cannot certify Retail authority, taint, physical timing, composed
pixels or persistence. New live acceptance must name the selected behavior,
candidate, controller/class/context and observed outcome. Existing accepted
candidate.17/candidate.30 cases remain valuable preservation targets, not blanket
proof for a new subsystem.

## 16. Source and authority index

The C identifiers used above link to inspected local production source or its
current contract. Their purpose is traceability; definitions and guards in those
files take precedence over a table shorthand.

| ID | Source / authority | Relevant evidence |
| --- | --- | --- |
| C01 | [TOC](../../../addon/ConsolePort_Forever/ConsolePort_Forever.toc) | Loaded modules, optional dependencies, candidate.30; no XML entry point. |
| C02 | [Reference.lua](../../../addon/ConsolePort_Forever/Reference.lua) | Captured layout, physical/logical binding declarations; preset rather than live engine state. |
| C03 | [Bootstrap](../../../addon/ConsolePort_Forever/ConsolePort_Forever.lua) | `NATIVE_INPUT_RECOVERY`, `RefreshModes`, `RefreshUI`, selector preparation and actual parent gates. |
| C04 | [BindingPolicy](../../../addon/ConsolePort_Forever/BindingPolicy.lua) | Shared unmodified faces versus personal modified/D-pad binding ownership. |
| C05 | [ModePolicy](../../../addon/ConsolePort_Forever/ModePolicy.lua) | Pure L2R2 temporary semantic model; production callers must be traced separately. |
| C06 | [Skin](../../../addon/ConsolePort_Forever/Skin.lua) | 16 face skin install, D-pad empty-only hooks, fixed shoulder `Prompts`. |
| C07 | [HUDPresentation](../../../addon/ConsolePort_Forever/HUDPresentation.lua) | Art families, face layers, pushed effect, round masks, glyph fallback, bank/class prompts and geometry. |
| C08 | [FocusVisuals](../../../addon/ConsolePort_Forever/UI/FocusVisuals.lua) | Active transient-region suppression preserving icons/cooldowns and later alpha writes. |
| C09 | [RuntimeSetup](../../../addon/ConsolePort_Forever/RuntimeSetup.lua) | Actual review fields, CVars, labels, proposals and preserved current native settings. |
| C10 | [ClassActions](../../../addon/ConsolePort_Forever/ClassActions.lua) | Class chord, resolved ring, learned augmentation, revision repair and guarded StanceBar suppression. |
| C11 | [Discovery](../../../addon/ConsolePort_Forever/Rings/Discovery.lua) and [Selectors](../../../addon/ConsolePort_Forever/Rings/Selectors.lua) | Read-only GUID/pet evidence and inactive `active=false` preparation/gesture gate. |
| C12 | [Rings adapter](../../../addon/ConsolePort_Forever/Adapters/Rings.lua) | Personal/native Shared distinction, manual order/duplicates/metadata and projection guards. |
| C13 | [TemporaryRouting](../../../addon/ConsolePort_Forever/TemporaryRouting.lua) | Actual native family/page qualification, combined-bank dispatch/editing. |
| C14 | [TemporaryAccess](../../../addon/ConsolePort_Forever/TemporaryAccess.lua) | Native mouse-accessible overflow/exit; no extra controller claim. |
| C15 | [Controller spec](../../CONTROLLER_SPEC.md) and [state matrix](../../STATE_MATRIX.md) | Current intended commands, independent active paths and per-state limits. |
| C16 | [Ping](../../../addon/ConsolePort_Forever/Targeting/Ping.lua) | Native account ring, release dispatch, cosmetic timing, key/owner/collision guards. |
| C17 | [InputBridge](../../../addon/ConsolePort_Forever/UI/InputBridge.lua) | Native claims, generation/lease validation and independent combat relinquishment. |
| C18 | [Contexts](../../../addon/ConsolePort_Forever/UI/Contexts.lua) | Popup/quantity route model and disabled-context bridge behavior. |
| C19 | [Windows](../../../addon/ConsolePort_Forever/UI/Windows.lua) and [Scroll](../../../addon/ConsolePort_Forever/UI/Scroll.lua) | Qualified dormant focus/tab/tooltip and unprotected scroll contracts. |
| C20 | [BetterBags adapter](../../../addon/ConsolePort_Forever/Adapters/BetterBags.lua) and [ItemHints](../../../addon/ConsolePort_Forever/UI/ItemHints.lua) | Version/item/owner validation; dormant native item actions/prompts. |
| C21 | [ActionRecovery](../../../addon/ConsolePort_Forever/ActionRecovery.lua) | Passive diagnostic observation; removed action-slot writer. |
| C22 | [Known issues](../../KNOWN_ISSUES.md) | Quest interaction and original Paladin writer unknown; exact gesture gates and established label discrepancy. |
| C23 | [ImmersionProgress](../../../addon/ConsolePort_Forever/UI/ImmersionProgress.lua) | Additive deferred native Required Items correction, settings/eligibility preservation. |
| C24 | [Map](../../../addon/ConsolePort_Forever/UI/Map.lua) | Dormant left-stick pan/right-stick zoom/L3 waypoint, detail/minimize Back and owner/public-value checks. |
| C25 | [Presentation/UI contract](../../reference/PRESENTATION-AND-UI.md) | Active art/visibility versus dormant route distinctions and feedback scope. |
| C26 | [Runtime](../../../addon/ConsolePort_Forever/Runtime.lua) and [HiddenAccess](../../../addon/ConsolePort_Forever/UI/HiddenAccess.lua) | Independent sidebar visibility and suspended full replacement/seat controls. |
| C27 | [Runtime configuration](../../reference/RUNTIME-CONFIGURATION.md) | Setup/ownership/migration, ground history, integration and saved-layout details. |
| C28 | [EditModeReference](../../../addon/ConsolePort_Forever/UI/EditModeReference.lua) and [Edit Mode adapter](../../../addon/ConsolePort_Forever/Adapters/EditMode.lua) | Read-only saved capture versus separately reviewed copy/save/select. |
| C29 | [Ground preferences](../../../addon/ConsolePort_Forever/Targeting/Preferences.lua), [Ground](../../../addon/ConsolePort_Forever/Targeting/Ground.lua), [Targeting panel](../../../addon/ConsolePort_Forever/UI/Targeting.lua) | Account spell/context policy, qualification and independent native secure placement. |
| C30 | [Cinematic](../../../addon/ConsolePort_Forever/Cinematic.lua) | Read-only eligibility; held skip, exact Circle and selector gestures explicitly unproved. |

Additional authority: [requirements](../../REQUIREMENTS.md),
[native execution decision](../../decisions/0002-native-execution-and-proof.md),
[manual/GUID ownership](../../decisions/0003-character-state-and-manual-edits.md),
[saved-layout authority](../../decisions/0006-native-saved-layout-authority.md),
[current status](../../IMPLEMENTATION-STATUS.md),
[candidate.17 acceptance](../../../evidence/forever-ui/candidate17-live-acceptance.json),
[candidate.30 acceptance](../../../evidence/forever-ui/candidate30-live-acceptance.json),
[next live cases](../../NEXT-DEPLOYMENT-CHECKLIST.md).

## 17. Maintenance and scope of this analysis

This analysis adds comparison/recommendations beside the original reference and
updates navigation. It changes no approved requirement, runtime gate, binding,
dependency, tool, test, package or installed state. Requirements/controller/states
remain accurate because no feature selection or implementation decision has yet
been made; they should change only when a specific direction is approved.

When a work package is selected, retain the row IDs, record the actual decision
in requirements/decisions as appropriate, and update implementation/activation
and acceptance separately. Re-review native evidence for exact claimed parity.
Do not turn recommendation, dormant code, historical beta report or unknown
native cell into a delivered feature by changing a status word.

[C01]: ../../../addon/ConsolePort_Forever/ConsolePort_Forever.toc
[C02]: ../../../addon/ConsolePort_Forever/Reference.lua
[C03]: ../../../addon/ConsolePort_Forever/ConsolePort_Forever.lua
[C04]: ../../../addon/ConsolePort_Forever/BindingPolicy.lua
[C05]: ../../../addon/ConsolePort_Forever/ModePolicy.lua
[C06]: ../../../addon/ConsolePort_Forever/Skin.lua
[C07]: ../../../addon/ConsolePort_Forever/HUDPresentation.lua
[C08]: ../../../addon/ConsolePort_Forever/UI/FocusVisuals.lua
[C09]: ../../../addon/ConsolePort_Forever/RuntimeSetup.lua
[C10]: ../../../addon/ConsolePort_Forever/ClassActions.lua
[C11]: ../../../addon/ConsolePort_Forever/Rings/Selectors.lua
[C12]: ../../../addon/ConsolePort_Forever/Adapters/Rings.lua
[C13]: ../../../addon/ConsolePort_Forever/TemporaryRouting.lua
[C14]: ../../../addon/ConsolePort_Forever/TemporaryAccess.lua
[C15]: ../../CONTROLLER_SPEC.md
[C16]: ../../../addon/ConsolePort_Forever/Targeting/Ping.lua
[C17]: ../../../addon/ConsolePort_Forever/UI/InputBridge.lua
[C18]: ../../../addon/ConsolePort_Forever/UI/Contexts.lua
[C19]: ../../../addon/ConsolePort_Forever/UI/Windows.lua
[C20]: ../../../addon/ConsolePort_Forever/Adapters/BetterBags.lua
[C21]: ../../../addon/ConsolePort_Forever/ActionRecovery.lua
[C22]: ../../KNOWN_ISSUES.md
[C23]: ../../../addon/ConsolePort_Forever/UI/ImmersionProgress.lua
[C24]: ../../../addon/ConsolePort_Forever/UI/Map.lua
[C25]: ../../reference/PRESENTATION-AND-UI.md
[C26]: ../../../addon/ConsolePort_Forever/Runtime.lua
[C27]: ../../reference/RUNTIME-CONFIGURATION.md
[C28]: ../../../addon/ConsolePort_Forever/UI/EditModeReference.lua
[C29]: ../../../addon/ConsolePort_Forever/Targeting/Preferences.lua
[C30]: ../../../addon/ConsolePort_Forever/Cinematic.lua
