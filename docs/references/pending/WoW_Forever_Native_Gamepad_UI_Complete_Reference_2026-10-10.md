# World of Warcraft: Forever — Native Gamepad UI: Complete Observed Reference

**Reference cutoff:** October 10, 2026 (Toronto)  
**Product:** World of Warcraft: Forever beta, native **Gamepad UI (Alpha)**, not a third-party controller addon  
**Scope:** What the native Forever client **is documented or observed to display and do**: controls, button combinations, on-screen artwork, placements, menu structures, settings, page/form/pet/override states, interactions, and limitations.  
**Audience:** Anyone investigating or reproducing the native Forever controller experience.  
**Deliberately excluded:** Any description of a separate implementation, existing repository, preferred customization, implementation architecture, migrations, tests of a separate product, or choices about which Forever behaviors to adopt.

> **Accuracy rule:** This is a **descriptive reference, not a proposed design**. If a fact is unknown, disputed, version-dependent, or only player-reported, it is labeled. No unspecified keybind, flyout entry, position, gesture, timeout, or ability-page behavior should be inferred from the layout. Screenshots, source snapshots, and notes have different dates. **Never promote a September screenshot or pinned beta source snapshot to an unverified October 10 default.**

---

## 0. Evidence legend and version map

| Label | Meaning | How it is used |
|---|---|---|
| **B** | Blizzard's official dated change log / announcement | Definitive statement for the dated beta build, unless subsequently changed. |
| **S** | Blizzard-authored **Forever** UI Lua/XML from a pinned public source snapshot | Strong evidence of implementation in that **snapshot**; not automatically proof of a later beta build. Exact constants/geometry carry this label. |
| **V** | Screenshot or identified footage of **native Forever Gamepad UI** | Direct evidence of depicted appearance and on-screen labels, but build/date/crop matter. |
| **G** | Independent gamepad controls guide | Useful documented user-facing behavior; less definitive than first-party source. |
| **P** | Named player firsthand observation or forum feedback | Describes that player's observed beta build, controller, settings and possible bugs; not automatically universal. |
| **U** | Not established by the available sources; conflict unresolved | **Unknown is not “unused”, “disabled”, “bindable”, or “missing.”** |

### Dated official changes

| Date | Native Gamepad UI changes substantiated by Blizzard |
|---|---|
| **Sep 22–23** | Controller character-selection navigation improved when started in gamepad mode; quest-starting items became interactable. [B-01] |
| **Sep 24** | Added Druid shapeshift, Paladin aura, Warrior stance, and Hunter/Warlock pet-control and pet-spell flyouts; Hunter/Warlock pet bar no longer replaces bottom gamepad bar; Compact mode, Fixed Party Targeting, targeting-side swaps; Edit Mode layouts became applicable with gamepad UI; updated map/quest bindings and compact raid manager/role poll handling. [B-02] |
| **Oct 1** | Pet stable UI updated; gamepad UI bindings made static and ordinary gamepad rebinding affects keyboard/mouse interface; compact raid/party manager updated; fixed moving macros already placed on a gamepad bar. [B-03] |
| **Oct 8** | Hold-versus-press input indicators revised; post-loot input problem fixed; map now opens with Quest Log focused to allow continued movement until map cursor engaged; raid-frame traversal updated; Gamepad Action Bar gained Edit Mode support; Edit Mode layouts saved/loaded per UI type; Gamepad Action Bar settings, **including Compact**, moved from general Options into Edit Mode and earlier values are **not migrated**. [B-04] |

**Version warning:** Pre-October 8 screenshots of `Options → Gamepad (Alpha) → Use Compact Action Bar` show a historical menu position. October 8's action-bar panel in **Edit Mode** supersedes that specific location. An October 1 known issue about Edit Mode reset is not proof that the exact same issue persists following October 8's layout separation. The Oct 8 update does not mean all settings moved: Blizzard specifically says **Gamepad Action Bar settings**, not every gamepad option. [B-03][B-04]

## 1. Physical controls, nomenclature and layout

All tables use physical **PlayStation** labels (DualSense/DualShock) and Xbox equivalents. Physical glyphs can vary if the game detects a virtual Xbox controller. The native **Shapes** art set shows PlayStation Square/Triangle/Circle/Cross; **Letters** is the Xbox-style A/B/X/Y set; **Reverse** swaps letter mappings; **Generic** is also present in pinned client button-art source. [S-06]

| PlayStation | Xbox | Normal native meaning or ownership |
|---|---|---|
| Left stick directional | Left stick | Walk/run character. |
| Right stick directional | Right stick | Camera in gameplay; aim during L1/R1 targeting; directional selection in radial menus; map pan when map owns focus. |
| L3 / left-stick click | LS | Autorun toggle in normal world control. |
| R3 / right-stick click | RS | Ping tap / hold-to-open ping selection menu, reported in native UI guides. |
| L1 | LB | Friendly targeting modifier **by default**; also menu-section navigation and two-shoulder shortcuts. |
| R1 | RB | Hostile targeting modifier **by default**; also menu-section navigation and two-shoulder shortcuts. |
| L2 | LT | First action-bar modifier; may be repurposed by focused windows. |
| R2 | RT | Second action-bar modifier; may be repurposed by focused windows. |
| D-pad Up/Down/Left/Right | D-pad | Four assignable square action positions in gameplay, contextual navigation in UI. |
| Square (left face) | X | Reserved **Interact** without triggers; assignable in trigger banks; menus context dependent. |
| Triangle (top face) | Y | Reserved context/inspect without triggers; assignable in trigger banks; menus context dependent. |
| Circle (right face) | B | Reserved Back/Cancel gameplay without triggers; assignable in trigger banks; UI context Back. |
| Cross (bottom face) | A | Reserved Jump without triggers; assignable in trigger banks; UI context accept/select. |
| Options / Menu (☰) | Menu / Start | Opens native radial main menu. |
| Create / Share | View / Select | Interface-focus/select-related function reported on some configurations; **exact physical mapping is not universal**. |
| DualSense touchpad click / swipe | No universal Xbox equivalent | PS5 walkthrough reports focus switch on click and mouse-like cursor on swipe; mapping can depend on driver/input emulation. |
| PS / Home | Guide / Xbox button | **No proven universally assigned native Forever UI action**; generally intercepted or mapped by platform. |
| Optional back paddles / extra inputs | Device-specific | **No Blizzard-stock fixed binding or native glyph contract established.** Do not confuse add-on features with stock Forever. |

### Four distinct modifier systems — not the same thing

1. **L2 / R2:** select spell/item action layers; hold both for combined action layer.
2. **L1 / R1:** target friendly or hostile and reveal targeting overlay while held.
3. **L1 + R1:** an additional **HUD shortcuts** mode, separate from L2+R2.
4. **L1 + L2 / R1 + R2:** potential **class-action flyout** openers on left/right, with class-specific existence and contents; they are not two buttons for the same flyout. [S-02][S-03][G-01]

A physical input can mean different things depending on *which UI has focus*: D-pad Up is an ability slot in unmodified gameplay, a group-frame navigation direction in friendly targeting, Quest shortcut with both shoulders, an emote-wheel entrance while the main radial owns focus, and a map-controls navigation key with the map focused. It is not a global one-action-per-key system.

---

## 2. Native action-bar architecture and exact slot numbering

### 2.1. Four sets of eight: 32 visible positions, 28 ordinary customizable

Forever's basic combat composition uses **four eight-position clusters**, each made of **four square D-pad cells on the left** and **four circular face-button cells on the right**. The bars are spatially arranged as controller-shaped diamonds, not a row of rectangular keyboard hotkeys. [G-01][V-01][S-04]

| Action layer | Activation | 4 D-pad cells | 4 face cells | Ordinary assignable cells |
|---|---|---|---|---:|
| **Base (no trigger)** | Neither L2 nor R2 | Assignable | Four **reserved** built-in actions | **4** |
| **L2** | Hold L2 | Assignable | Assignable | **8** |
| **R2** | Hold R2 | Assignable | Assignable | **8** |
| **L2+R2** | Hold both | Assignable | Assignable | **8** |
| **Total** | One ordinary manual action-bar page | **16** | **12 assignable + 4 reserved** | **28** |

#### Per-cluster directional index used by Blizzard's native binding source

```text
        D-pad Up (2)                 Triangle / Y (6)
D-pad Left (1)  D-pad Right (3)  Square / X (5)  Circle / B (7)
        D-pad Down (4)               Cross / A (8)
```

These are **relative eight-button indices**, not keys `1..8` on the keyboard. `Blizzard_GamepadActionBars/Bindings.xml` registers `GAMEPADACTIONBUTTON1` through `GAMEPADACTIONBUTTON8`, each invoking the corresponding action index on the current active bar with down/up state. The pinned binding utility **reserves native base face slots** instead of allocating them as ordinary spell storage. [S-04][S-07]

### 2.2. Three standard arrangements plus special page

Guides describe **three standard selectable page arrangements** (`1`, `2`, `3`), each containing the four action layers. The native Page Tracker also has an **`S` special page marker**. The `S` marker does **not** establish a fourth freely assignable normal arrangement. [G-02][S-05]

- Manual arrangement cycling is performed through **L1+R1+D-pad Left/Right** in the documented controller shortcuts.
- Pinned source starts on page **1**, wraps when moving beyond last/first page, represents normal page statuses with **active, populated-but-inactive, and empty/disabled** states, and has a special-page slot distinct from ordinary numbered pages.
- Native source distinguishes **pageable** top/left/right/bottom bars from **nonpageable** special overrides, including stance, possession and targeting/shortcut overlays. An action's display page, storage slot, and action's physical controller combination are separate concepts.
- Exact behavior when the special page `S` becomes active depends on what context triggered it; it must not be treated as a user-selected normal page without additional evidence.

**Count interpretation:** The phrase **28 customizable per arrangement** is correct; it does not imply 32 freely assignable on the base cluster or a fourth normal arrangement. The documented three standard arrangements imply up to 84 customizable positions in principle, subject to native storage and actual page availability. [G-01][G-02][S-07]

### 2.3. Layout states

- **Expanded/default layout:** the four action clusters can remain displayed together. The active cluster is identified by larger dimensions/selection emphasis, and inactive clusters appear reduced or dimmed. This gives at-a-glance visibility into abilities outside the current trigger layer. [G-01][V-02][S-05]
- **Compact Action Bar:** displays **only the currently active action cluster**. Introduced Sep 24; as of Oct 8 it is selected by focusing the gamepad bar within **Edit Mode**, not at its older Options entry. [B-02][B-04]
- **Show Empty Action Bars:** in the historical setting, hides/shows **whole empty clusters**, *not individual empty cells*. [G-01]
- **Input prompts:** button symbols on active hotbar, historically **off by default** per guide; physical glyph set follows recognized controller type. [G-01][S-06]
- **Active-bar highlighting:** shadow behind active action group, historically on by default. **Active-bar scaling:** active group expands, historically on by default. [G-01]
- Native input-mode changes may temporarily de-emphasize/hide action icons while targeting overlays own the center display; this is not the same as replacing a spell assignment. [S-04][S-05]

### 2.4. Binding an ability or usable item (visible native workflow)

- Open main radial with **Options**, choose **Spellbook**, use D-pad to focus a spell; L1/R1 move between spellbook sections/pages in the September walkthrough.
- With a spell selected, **Square/X** activates the displayed **Bind to Action Bar** operation; press the desired gameplay combination to choose its target cell.
- For a potion/usable item: open Bags, select item, use **Triangle/Y → More → Bind**, then enter the destination chord.
- Macros can occupy normal gamepad action cells; the **Oct 1** patch explicitly fixed an issue preventing an already placed macro from being moved.
- These are **action contents**, not global physical gamepad-input reassignment. Blizzard explicitly changed the **native Gamepad UI bindings to static** on Oct 1. [B-03][V-03][G-02]

---

## 3. The four reserved base face buttons — context and exact source behavior

| Face | Xbox | Native gameplay purpose | What is specifically supported by evidence |
|---|---|---|---|
| **Cross (✕)** | A | Jump | Source sends jump **down/up**. When HUD shortcut modifier is active, uses **Sit/Stand/Descend Start** on down; calls DescendStop and Jump up on release. [S-04] |
| **Circle (○)** | B | Stop/cancel | Pinned source's gameplay priority: try **stop casting**; else **stop targeting ground spell**; else **clear hard target**. This particular gameplay callback is not a generic unconditional `Escape` or blanket close-all-windows call. Separate contextual focused UI handling can close panels. [S-04][G-01] |
| **Square (□)** | X | Interact | Context resolves player-facing interact/attack/loot according to situation; a source-level **0.5-second hold** distinguishes tap from an alternate hold interaction/auto-loot path. It updates button pressed styling across down/hold/release. [S-04] |
| **Triangle (△)** | Y | Inspect/context | On normal gameplay **release**, opens target-frame context menu if `target` exists; image switches based on target and targeting-modifier state. While a targeting modifier is active its icon/behavior can become raid-target marking instead. [S-04] |

**Important distinctions:**

- The guide describes Circle as *Back/Cancel/Close* in UI contexts. The **world gameplay** implementation is narrower; these are not contradictory when focus changes who owns the button.
- Square is sometimes described as *attack*, sometimes *interact*. Its native role is a **contextual resolver**, not a universal bound auto-shot spell or an always-attacking melee macro. Players report that tapping repeatedly can toggle an active auto attack off; that is a **player-observed limitation**, not a deliberately verified requested toggle mode. [P-03]
- The source's `0.5` figure is for the native interact hold handler **in its pinned snapshot**. It is not proof that crafting holds, loot confirmations, emotes, and cinematic skipping share the same threshold.
- Face buttons become **normal assignable ability slots when L2/R2 modifiers select a spell layer**. Their base reservation does not imply they stay context-only inside those layers.
- **L1+R1+Cross** is **Sit/Stand/Descend**, not blank. The native jump callback explicitly handles the HUD shortcut flag. [S-04]

---

## 4. L1/R1 targeting controls and on-screen targeting presentation

### 4.1. Default roles and tap/hold distinction

- **L1 / LB**: friendly targeting, by default. Tap attempts to target a suitable friendly ahead; hold presents friendly targeting-mode controls.
- **R1 / RB**: hostile targeting, by default. Tap selects a suitable hostile ahead; hold presents hostile targeting-mode controls.
- With either hold mode, the **right stick becomes a target-aim control**, not ordinary camera rotation, and a visible small targeting circle may appear beneath the character's feet. [G-01][G-02][V-04]
- **Soft/action targeting:** merely facing a nearby enemy may display a soft indicator/health bar before hard targeting. An attack may act on that unit without a prior R1 press, while an existing hard target can remain different. Target-mode displays and hard-target state therefore cannot be inferred solely from the spell recipient. [G-01][G-02]

### 4.2. Friendly targeting (hold L1 by default)

| Input while held | Documented action | Evidence |
|---|---|---|
| **Cross / A** | Target **self** | G-01/G-02 |
| **Square / X** | Target **pet** | G-01/G-02 |
| **Circle / B** | **Assist** target (target that unit's target) | G-01/G-02 |
| **Triangle / Y** | Cycle/place **friendly raid target marker** | G-01/G-02 |
| **D-pad Up** | Move focus **up** through party/raid display | G-01/G-02 |
| **D-pad Down** | Move focus **down** | G-01/G-02 |
| **D-pad Left** | Move focus **left** through raid grid | G-01/G-02 |
| **D-pad Right** | Move focus **right** through raid grid | G-01/G-02 |
| **Right stick** | Aim at available friendly selection | G-01 |

- In a party, actual targets depend on the party-frame arrangement and any fixed-party option. In raids, grid navigation remains spatial/directional rather than four fixed party-member slots.
- The guide reports friendly marker cycling **opposite in direction/order** to hostile cycling; there is **not** sufficient first-party data here to assert a particular internal marker-ID loop.
- For no pet/dead or out-of-range group members, the missing-target indicator, fallback target, and error message are **not exhaustively documented**.

### 4.3. Hostile targeting (hold R1 by default)

| Input while held | Documented action | Evidence |
|---|---|---|
| **Cross / A** | Target **last hostile** | G-01 |
| **Square / X** | **Ranged Attack** displayed action | G-01; whether available on every class/weapon is not established |
| **Circle / B** | **Assist Target** | G-01 |
| **Triangle / Y** | Cycle hostile **raid target markers** | G-01 |
| **Right stick** | Aim toward specific hostile selection | G-01/G-02 |
| **D-pad Up/Down/Left/Right** | **Not established as a universal default** | U: contradictory field descriptions; do not label as unbound or automatic cycle |

### 4.4. Targeting configuration confirmed in Sep 24 notes

| Setting | Confirmed function | Scope |
|---|---|---|
| **Fixed Party Targeting** | In **non-raid parties**, assigns each D-pad button to a particular group member instead of relative grid traversal | Only normal party, not raid; exact physical direction → member index **not verified**. [B-02] |
| **Swap Target Modifier Sides** | Friendly and hostile targeting swap L1/R1 sides | Changes target-role meaning of left/right shoulders, not L2/R2 spell slots. [B-02] |
| **Swap Friendly Target Action Sides** | Swap D-pad and face-button action groups while friendly modifier is active | Group exchange, **not** arbitrary binding of every target action. [B-02] |
| **Swap Hostile Target Action Sides** | The analogous group exchange in hostile targeting mode | Scope limited to hostile targeting actions. [B-02] |
| **Raid Targeting Hover Mode** | Changes how group-directed spells apply versus hard-target selection | Guide says **off by default**, and describes **on** as switching selection to friendly unit when casting. Name is counterintuitive: flag behavior must be interpreted from dated client/source, not English word “hover”. [G-01] |
| **HUD Modifier — Press to Toggle** | Toggles targeting/HUD modifier mode rather than continuous bumper hold | Does **not** make L2 or R2 action layers latched. Historical player reports mention a sticky shortcut mode. [G-01/P] |

### 4.5. Native targeting artwork

In pinned native XML, left/right shoulder-backplate art uses:

```text
gamepad-targeting-left-shoulder-bg
gamepad-targeting-right-shoulder-bg
gamepad-targeting-left-shoulder-pressed
gamepad-targeting-right-shoulder-pressed
```

The friendly/hostile icon atlases (`gamepad-targeting-friendly`, `gamepad-targeting-hostile`) are swapped to the appropriate shoulder based on the *Swap Target Modifier Sides* setting. Separate **FriendlyTargetingActionBar** and **HostileTargetingActionBar** overlays are anchored to the top-centered page unit; they are **visual/action context layers**, not ordinary stored spell pages. The per-shoulder pressed highlight is a distinct overlay. [S-03][S-04]

---

## 5. L1+R1 HUD shortcuts — separate from spell layers and class flyouts

**Hold L1 and R1 together** for shortcuts. The lower action display can switch to a shortcuts overlay; the upper-left input legend provides current hints. These functions are documented across gamepad guides and September controller videos unless marked source-confirmed. [G-02][V-03]

| PlayStation chord | Native action | Evidence and qualification |
|---|---|---|
| L1+R1 + **D-pad Up** | Open **Quest Log/quest panel** | G-02/V-03. Oct 8 changes focus when **map** opens, not necessarily how the shortcut first opens. |
| L1+R1 + **D-pad Down** | Open **Chat** | G-02/V-03; does **not** imply a built-in text keyboard. |
| L1+R1 + **D-pad Left** | Previous numbered action-bar arrangement | G-02/V-03; wrapped page tracking in S-05. |
| L1+R1 + **D-pad Right** | Next numbered arrangement | G-02/V-03. |
| L1+R1 + **Square** | **Sheathe/unsheathe weapons** | G-02/V-03. |
| L1+R1 + **Triangle** | Open **buff viewer** | G-02/V-03. |
| L1+R1 + **Circle** | Open **Combined Backpack/bags** | G-02/V-03. |
| L1+R1 + **Cross** | **Sit/Stand/Descend** | **S-04** for source-level HUD-modifier branch; guides also show menu-context Sit/Stand. |
| L1+R1 + **right stick Up** | Zoom **world camera in** | G-02/V-03. |
| L1+R1 + **right stick Down** | Zoom **world camera out** | G-02/V-03. |
| L1+R1 + **L3** | **Recenter camera** | G-02/V-03. |
| L1+R1 + **hold R3** | **Look behind** character | G-02/V-03; distinct from ordinary R3 ping. |
| L1+R1 + **right stick Left/Right** | **No universal shortcut established** | U; do not derive from Up/Down zoom. |
| L1+R1 + **Create/Share / touchpad / PS** | **No universal shortcut established** | U; hardware and driver mappings vary. |

Some older walkthroughs access Sit/Stand via **Options → D-pad Down** while in the main radial; that is an **additional UI-context route**, not proof that the L1+R1+Cross shortcut is absent. [V-03][S-04]

---
## 6. Class-specific flyouts, physical sides, visibility and contents

### 6.1. Two independent class-action locations

The native gamepad page-unit XML contains two **physically distinct class-action buttons**:

- **LeftClassAction**: **L1 + L2** (LB+LT), located left of center at `(x=-138, y=-50)` relative to the **bottom-centered anchor** of the native gamepad page unit.
- **RightClassAction**: **R1 + R2** (RB+RT), right of center at `(x=+138, y=-50)` relative to the same anchor.
- Their separate two-glyph prompts measure **72 × 24 UI units** and anchor at `(x=-138, y=-80)` and `(x=+138, y=-80)` in that pinned XML.
- Each class button uses the **expanded circular** visual style, a spell-like icon, a checked/pressed layer and an anchored flyout popup. The two sides do **not** automatically duplicate content.
- In pinned `ClassActionFlyout.lua`, the opener polls for **both same-side shoulder and trigger held**, sends a secure press when both are down in core gamepad gameplay input context, and sends release when either becomes up. It consumes the targeting modifier when activated. This is a source-level description of the **class button opener**, not proof of the full stick-selection/activation/close behavior for every flyout item. [S-02][S-03]

### 6.2. Exact source-backed class mapping versus documented categories

| Class | L1 + L2 / Left | R1 + R2 / Right | Evidence and important boundary |
|---|---|---|---|
| **Druid** | **Shapeshift** flyout, source flyout ID **262** | No separate right native flyout identified by the **three-class source snapshot** | **B-02** confirms category; **S-02** confirms left side and ID in pinned source. Not a guarantee that later code never adds a second button. |
| **Paladin** | **Aura** flyout, source ID **270** | No right native flyout identified by that snapshot | B-02/S-02. |
| **Warrior** | No left native flyout identified by that snapshot | **Stance** flyout, source ID **269** | B-02/S-02; **important correction:** Warrior's documented stance selector is **R1+R2**, not L1+L2. |
| **Hunter** | **Pet-related flyout(s)** | **Pet-related flyout(s)** | B-02 confirms **pet control and pet spell** flyout categories; field descriptions associate different categories with left/right, but no checked first-party source here proves a complete exact split or individual slots. **Left = pet utility / Right = pet spells remains P, not B/S.** |
| **Warlock** | **Pet-related flyout(s)** | **Pet-related flyout(s)** | Same B-02 categories and same unresolved exact left/right contents. |
| **Mage** | No dedicated class flyout documented | No dedicated class flyout documented | **Not documented ≠ physically blocked or guaranteed empty**; baseline uses normal action groups. |
| **Priest** | No dedicated class flyout documented | No dedicated class flyout documented | Same bound. |
| **Shaman** | No dedicated dedicated totem flyout documented | No dedicated dedicated totem flyout documented | No stock totem-wheel artwork/assignment proven. |
| **Rogue** | No dedicated poison/stealth flyout documented | No dedicated poison/stealth flyout documented | Rogue **stealth paging** is a separate mechanism, not a class-action flyout. |

**Why Hunter/Warlock are marked separately:** A September 29 forum player reports that L2+R2 pet-class behavior was updated; this is a **pet-related report about the combined normal action layer**, not definitive proof of all class-button item arrangements. Blizzard's September notes definitively add pet control and pet spell flyouts, but the archived `Camelot/ClassSpellFlyout.lua` maps only Druid/Paladin/Warrior. No exact IDs/icon order for Hunter/Warlock were recovered from that file. [B-02][P-04]

### 6.3. Visibility and population conditions

The pinned `ClassSpellFlyout.lua` uses a **known-spells-only** enumeration to determine whether its class-action button should appear. It updates visibility on **learned spell** and **flyout update** events. It updates the flyout icon and cooldown in normal button refresh paths. Thus, in the dated source snapshot, the button's visibility is **derived from known flyout entries**, not simply shown for every member of a class from level 1. [S-02]

Examples of what is **conceptually** present, without inventing exact flyout ordering:

- **Druid:** class shapeshift forms actually learned at that character's level (e.g. Bear, Cat and other applicable forms); **not** an automatic promise that all form icons appear on a low-level character.
- **Warrior:** stances actually learned and included in its stance flyout.
- **Paladin:** auras actually learned and included in its aura flyout.
- **Hunter/Warlock:** pet-control and pet-spell categories; visibility and number of entries may vary with active pet, known training, pet spell ranks and current client. Exact ordering/count is **U**.

### 6.4. Flyout visual behavior, as distinct from action-bar paging

A **class flyout** is an additional circular opener and nearby expanding selection of class abilities. A **stance/form action-bar change** is the replacement/paging of combat actions after a form or stance state changes. A **pet/possess bar** is a distinct set of controlled-unit actions. They are related in gameplay but **not the same frame or input concept**. [S-02][S-03][S-05]

Visual evidence includes an actual Warrior screenshot showing a **shield/fist icon flyout directly beside controller-button artwork**, and the pinned class button style is a **38 × 38 expanded circle**. The available evidence does **not** give a stable, numeric, first-party contract for flyout item radial angle, radius, number of wedges, delay, gamepad stick-selection threshold, release-to-cast gesture, cancel-to-keep-open sequence or item spacing. [V-05][S-02]

### 6.5. Class abilities and gameplay pages vary without a class flyout

- Druid forms and Warrior stances can alter which ordinary abilities are usable and which action bar should be shown; flyout existence does **not** prove every one of the four action layers gets its own fully independent form bar.
- A beta Druid tester described a **Bear Form flyout / caster-bar mismatch**, suggesting incomplete synchronization in that build. Another tester reported form paging unavailable; neither observation is a universal contract for the October 8 build. [P-01][P-02]
- A Rogue tester (Oct 5) observed that entering Stealth can replace **one selected trigger bank** (L2, R2 or combined), not automatically all four banks. The exact UI setting, persistence and behavior for every Rogue build were not established. [P-02]
- A class can have **changed spell availability, range, resources or spell iconography** in form/stance/pet mode without receiving a unique special flyout graphic.
- Hunter and Warlock **pet bar no longer takes the bottom gamepad action bar's place** after Sep 24, specifically called out by Blizzard. The old replacement behavior belongs to an earlier beta build. [B-02]

---

## 7. Special action bars, stance overrides, possession, pets and interface state

### 7.1. Native architectural distinctions (pinned source)

`PageUnit.lua` defines four pageable normal bars and multiple nonpageable/override bars. Named action-bar instances include:

```text
topBar                 base eight-button action set
leftBar                left-trigger layer
rightBar               right-trigger layer
bottomBar              combined-trigger layer
stanceBar              special non-pageable stance/context override
possessBar             special non-pageable possess/context override
friendlyTargetingBar   temporary friendly targeting actions
hostileTargetingBar    temporary hostile targeting actions
shortcutsBar           temporary both-shoulders HUD shortcuts
```

The page unit keeps an **override collection** distinct from the regular page-controlled four. It evaluates modifier presses to decide which ordinary bar should be active, then can substitute a matching special/context bar when that override is active. The existence of this code is not enough to state a universal routing rule such as “all vehicles always overwrite L2” or “all temporary actions only use L2+R2.” [S-05]

### 7.2. Context matrix — what is definitively known

| State/context | Documented display or input change | Confidence | What's **not** established universally |
|---|---|---|---|
| **Normal world gameplay** | Four banks, base four reserved faces, normal camera/movement | S/G | Exact screen positions after Edit Mode user customizations |
| **Hold L2** | Active set changes to left-trigger spell layer | S/G | Whether any accessibility feature can latch that layer in latest build |
| **Hold R2** | Right-trigger spell layer | S/G | Same |
| **Hold L2+R2** | Combined spell layer | S/G | Whether a particular temporary context also substitutes this layer |
| **L1 targeting** | Friendly targeting overlay and right-stick aiming | S/G | Exact temporary icon animation timing |
| **R1 targeting** | Hostile targeting overlay and right-stick aiming | S/G | Hostile D-pad universal defaults |
| **L1+R1** | Shortcut overlay and shortcut mapping | G/V | Every fallback when other modal input owns same hardware |
| **Class flyout open** | Side class-action button pressed; class ability flyout opens | S/B | All flyout selection/cancel gesture details |
| **Druid shape changed** | Action availability and potentially stance/form bar display change | S/P | Guaranteed independent 28-slot layout per form |
| **Warrior stance changed** | Stance/active abilities and possible stance bar context | S/P | Exact number of simultaneous bank overrides |
| **Rogue Stealth** | Player reports one configured modifier bank may page | P | Universal code behavior after Oct 8 |
| **Hunter/Warlock pet active** | Pet controls/spells available; bottom normal bar no longer fully replaced | B | Exact class side + icon arrangement and pet autocast visuals in every pet state |
| **Pet dismissed/no pet** | Pet context changes available buttons | S/B by architecture | Whether particular flyout visually disappears versus greys out |
| **Possess/Charm/Mind Control** | Dedicated nonpageable `possessBar` exists in pinned UI | S | Which ordinary banks the current build substitutes and which override is highest priority |
| **Vehicle/transport with native override** | A special gameplay context can replace regular actions | S general/P | Exact replacement layer, number of slots, and icon arrangement per vehicle |
| **Quest action / extra-action scenario** | Contextual action may appear through special action controls | G/P | A single universal bank for all quests or all instances |
| **Swimming** | Jump/descend and facing changes may apply | S/G | How every flying/swim exception affects all inputs |
| **Mounted / gliding** | Movement/camera facing settings influence behavior | G | Identical handling for every mount, flight and special transport |
| **In-combat** | Ability state/cooldown/range/target changes; certain interactions restricted | S/G | Blanket combat exceptions for all contextual menus |
| **Inventory/map/menu/chat open** | Frame-focused input takes over some game buttons | G/V | One global key priority independent of actual focused panel |
| **Controller mode → keyboard UI** | Separate UI mode/layout behavior; October 8 per-UI-type layouts | B | All action contents, per-character data and external input mappings |

### 7.3. Stance Bar Override and Possess Bar Override settings

The pre-October-8 gamepad guide lists **Stance Bar Override** and **Possess Bar Override** settings. Its author explicitly said they could **not personally test** the associated class/possession scenarios, so their existence is documented [G], but the precise default, full truth table and exact presentation are **U**. Do not state “Stance Bar Override always pages all four banks,” “possess always owns combined,” or an action-slot mapping not shown in source/testing. [G-01]

### 7.4. Priority and interaction ownership

On a held key combination, the visible state depends on the currently active **gamepad input binding context** and on the active special bar, not solely which physical keys are down. The pinned class flyout only opens when the core binding context is active. Similarly, the normal Circle gameplay callback is different from Circle on a focused dialog. The correct way to describe stock behavior is a **state-dependent transition**, not a globally invariant “Circle = Escape everywhere.” [S-02][S-04][G-02]

---

## 8. Main radial menu: native appearance, sections and shortcuts

### 8.1. Visual and spatial model

Pressing **Options/Menu** brings up a **temporary multi-section radial main-menu overlay**, shown in original September 13 screenshots. It contains icons with category captions arranged around a circular choice area, with the right stick choosing a destination. **L1/R1 change which menu section/page is displayed.** The gameplay bar remains its own HUD system, rather than every ordinary spell button turning into a menu wedge. [V-01][G-02]

The three original menu-section screenshots are [IMG-01], [IMG-02], and [IMG-03] in the source appendix. Their exact image dimensions and wheel radius are **not a reliable October 8 coordinate specification**, because they are early demo footage.

### 8.2. Entry groups shown in footage/guides

| Menu section | Entries reported as visible in native beta |
|---|---|
| **Central/main** | **Character, Talents, Professions, Bags, Spellbook, Game Menu, Chat, Quests/Map** |
| **L1 / left section** | **Shop, Legacy, Group Finder, Collections, Minimap settings, Buffs, Social, Communities** |
| **R1 / right section** | **PvP, Calendar, Clock** |

These entries reflect September menu footage. It is not established that later changes never introduced, removed or rearranged wedges. The exact **wheel ordering/angle per entry, selected-item zoom, animation duration, dead zone and release-to-select logic** remain unknown from the screenshots and summaries alone. [V-01][G-02]

### 8.3. Menu-context controls

| Context | Input | Observed action |
|---|---|---|
| Main radial open | Right stick | Select/highlight an entry. |
| Main radial open | L1 / R1 | Move between radial menu sections. |
| Main radial open | D-pad **Up** | Open an **emote wheel**. |
| Main radial open | D-pad **Down** | **Sit / Stand**. |
| Menus and submenus | Circle / contextual Back | Return/close as permitted by focused UI. |
| Main radial open | Direction for a specific menu entry | Actual activation gesture (release/confirm/hold) is **not exhaustively source-confirmed** across every submenu. |

### 8.4. What is **not** automatically a native radial wheel

- **Triangle** on an item/player opens an **item or unit context menu**, often a list of actions (inspect/invite, bind, share, split, destroy), **not necessarily a circular wheel**.
- **Class form/stance/aura/pet flyout** is a side-attached class action popup near the action-bar system, distinct from the main Options wheel.
- **R3 hold Ping Menu** and **D-pad Up Emote Wheel** are contextual radial/picker UI separate from the main radial menu's top-level entries.
- **D-pad and face-button diamonds** in the persistent lower HUD are ordinary action clusters, not selectable radial menus.
- No official **freeform custom spell wheel**, **custom consumable wheel**, **totem wheel**, or **mount wheel** is substantiated for stock Forever by the official class-flyout list. Screenshots of such features can belong to unrelated addons. [B-02][V-01]

---

## 9. Detailed native window and panel interactions

### 9.1. Input legend, focus system, cursor handoff

The **upper-left input legend** lists available control glyphs/actions for the current input context: gameplay, targeting, menus, inventory, map, spell/item bind mode, or other focused panels. It is a **contextually updated UI component**, not a fixed printed controller cheat sheet. Its visibility can be toggled through **Show Input Legend** in Gamepad settings in pre-Oct 8 guides. [G-01][V-06]

- Selected interactive UI frames/items have a visible **focus outline** and focused control hints.
- Native guides describe **Gold, Blue and Black** selectable focus-border styles plus opacity control. Gold was described as the historical default and easiest to see; the beta client may expose other final styling choices. [G-01][V-07]
- D-pad navigates focused lists/grids; Square/Cross/Triangle/Circle can be **Select, Equip, More, Back, Cancel, Context**, etc., as the **on-screen input legend** indicates.
- A PS5 walkthrough reports **touchpad swipe mouse-like cursor** and **touchpad click focus switch**; with two panels open, L2/R2 can change selected frame. This input routing can depend on recognized controller and active UI owner; not a universal Xbox/PlayStation physical map. [G-02/V-03]
- Opening a UI panel does **not necessarily immobilize the character**. The Oct 8 map update deliberately focuses Quest Log first so movement can continue until map cursor takes focus. [B-04]

### 9.2. Bags, equipment and item context

| Visible context | Documented interface / action |
|---|---|
| **Bags** open | Traditional grid/combined backpack with focused selected slot; not an all-item radial wheel. |
| L1+R1+Circle | Opens combined backpack. |
| D-pad inside bags | Moves focus between visible item locations. |
| Square on equippable item | Equipment/equip action in demonstrated context. |
| Triangle on selected item | **More** contextual choices, such as Bind, Split Stack, Destroy and sometimes Share. |
| Select/move item | Uses displayed select/move hint, not a universal gameplay cast binding. |
| Circle in focused bag context | Back/close the UI. |
| Focus bag header/manage bag | A Sep 18 forum report describes an **item comparison** toggle within bag management; not a universal always-visible compare state. [P-05] |

### 9.3. Spellbook and ability binding

- Normal **Spellbook** panel and icon/page layout remain recognizably WoW.
- D-pad navigates learned spells and focuses a specific spell icon; **L1/R1** can switch spellbook pages/tabs in the captured walkthrough.
- Square selects **Bind** for a focused spell, taking the UI into **Bind to Action Bar** mode.
- Pressing an allowed ability-layer chord places the selected spell into the corresponding destination action slot.
- **Base four reserved face slots are not normal bind destinations.** Rebinding a gamepad key through the general binding UI is **not equivalent** to replacing these native reserved base actions after Oct 1. [B-03][G-02][S-07]

### 9.4. Quest log and world map

| UI focus / action | Observed controller action |
|---|---|
| L1+R1+D-pad Up | Opens Quest panel/log. |
| Quest list focused, D-pad | Move through quest list. |
| Quest selected, Square | Open quest details and related map location. |
| Quest selected, Triangle | Quest **Share** / **Abandon** context options. |
| World map focused, right stick | Pan map view. |
| World map focused, L1/R1 | Zoom **map**, distinct from L1+R1+right-stick camera zoom. |
| Map focused, D-pad Down | Toggle expanded/full-screen map view; same command returns to smaller view in captured walkthrough. |
| Map focused, D-pad Up | Move focus to upper map controls/filters. |
| Map focused, Square | Place map/location marker in walkthrough. |
| Map focused, Triangle | Broader/higher-level map view. |
| **October 8, on opening map UI** | **Quest Log is focused first**, so character can keep running until actual map cursor engages. [B-04] |

Sep 24 additionally introduced **POI-pin hover** support and updated Map/Quest Log bindings; exact icon focus glow and modal priority on all map variants should be understood as client-version dependent, not deduced from one screenshot. [B-02]

### 9.5. NPC interaction, dialog, quest items, vendors, profession and crafting

- Near an interactable NPC, object, or corpse, a **Square/X interaction prompt** appears; the user can trigger contextual interaction without first hard-targeting that NPC in the walkthrough. [G-02]
- D-pad moves through available quest/dialog choices; accept/complete actions use displayed context hints rather than a globally fixed spell action.
- Quest-starting inventory items became controller-interactable by Sep 22–23. [B-01]
- Profession windows retain conventional recipe/list and craft controls; September walkthrough shows a crafting and subsequent item-equipping flow. Some crafting tasks display **hold** rather than tap to confirm. Oct 8 explicitly updated the visual indicator of **hold-required** actions; it did **not** document one universal hold duration. [B-04][G-02]
- Pet stable UI gained explicit gamepad support on Oct 1. [B-03]
- Reports describe partial difficulty with specific vendor/trade/Auction House/crafting focus or keyboard-entry situations. Their existence does not establish a single universal missing input for every panel. [P-03]

### 9.6. Buff viewer, emotes, ping and chat

- **L1+R1+Triangle:** opens buff viewer. D-pad navigates available buff displays; **Square** can cancel a selected cancellable buff in the video walkthrough. [G-02]
- **L1+R1+Square:** sheathe/unsheathe equipped weapon. [G-02]
- **Options → D-pad Up:** opens native emote wheel; one demonstration selects **Wave**. No verified universal complete emote wedge order or customizable emote-ring settings. [G-02]
- **R3 tap:** issue a native ping to a valid world/unit location. **R3 hold:** open ping selection menu. Validity/errors depend on target, pointer and world/UI interaction context. Full ping-wheel contents and geometry not captured as stable constants in sources here. [G-02]
- **L1+R1+D-pad Down:** opens chat; native beta reports say controller navigation doesn't automatically provide an integrated onscreen text keyboard. Some setups can use a separate keyboard, OS typing overlay or Steam Input, which are *not stock Forever UI features*. [G-02][P-03]

### 9.7. Character selection, party/raid frames and battle dialogs

- Sep 22 fixed **character-select navigation** when starting gamepad-enabled. [B-01]
- Sep 24 improved **Compact Raid Frame Manager** and **Role Poll Frames**; Oct 1 improved compact Raid/Party manager frames; Oct 8 refined **raid traversal** again. The latest behavior should be distinguished from older “D-pad sometimes loses focus” forum reports. [B-02][B-03][B-04]
- Holding L1 in raid targeting can move focus across a grid of party-member panels. **Fixed Party Targeting** only applies in non-raid parties.
- Loot roll and focus problems were reported in September; Oct 8 claims a fix for **inputs failing after looting**, not a guarantee that every older loot-roll focus complaint has been resolved. [P-03][B-04]

---
## 10. Exact visual reference: HUD composition, dimensions, button artwork and layer states

### 10.1. Where the gamepad HUD sits in the viewport

In the pinned Blizzard XML, `GamepadMainActionBarFrame` is a **656 × 202 UI-unit** frame anchored to `UIParent`'s **BOTTOM** at an upward offset of **110**, horizontally centered. These are the **source defaults before user repositioning or scale changes**, not screenshot pixel coordinates or guaranteed values after the October 8 Edit Mode update. [S-03]

The overall composition contains:

- **Four ordinary eight-button action bars** arranged around a centrally managed gamepad page unit. Each bar has **left D-pad diamond** and **right face-button diamond**.
- **Top/base set**; other sets identified by L2, R2 and L2+R2 graphical prompts. The prompt art is physically gamepad glyphs, not ordinary keyboard labels.
- **Side shoulder indicators:** a friendly/hostile symbol and background/pressed artwork above the action region. These change according to targeting modifier swap state.
- **Page tracker** near the bar composition, with `1`, `2`, `3` standard states and `S` special marker in pinned source.
- **Extra class buttons** left and right of lower center **when applicable**; circular class icon plus corresponding two-icon shoulder+trigger prompt beneath.
- Separate top-centered **targeting/shortcuts temporary overlays** when those modes activate.
- **Upper-left contextual input legend**, while the conventional UI still supplies player/target frames, cast and resource information, chat, objectives and minimap. The gamepad system does **not** turn the whole game screen into a radial menu. [S-03][S-05][V-01][V-08]

**Screenshot interpretation:** A 1920 × 1080 capture cannot be used to infer native XML dimensions unless UI scale, screen scale, viewport crop, camera and Edit Mode offsets are known. The figures below are **source UI units** from the pinned Blizzard snapshot.

### 10.2. Action-cell sizes and expanded/collapsed geometry (pinned source)

| Visual object | Collapsed | Expanded | Pinned implementation source |
|---|---:|---:|---|
| **Square D-pad action cell** | **32 × 32** | **40 × 40** | `ActionBarStyles.lua` |
| **Circular face-button cell** | **30 × 30** | **38 × 38** | `ActionBarStyles.lua` |
| **One eight-cell action-bar frame** | **208 × 68** | **266 × 86** | `ActionBarStyles.lua` |
| **Pressed-button size adjustment** | **−4 UI units** | **−4 UI units** | `ActionBarStyles.lua` |
| **Pressed-button vertical anchor adjustment** | Approximately **−2 UI units** | Approximately **−2 UI units** | `ActionBarStyles.lua` |
| **Class-action opener button** | — | **38 × 38** circle | `ClassActionFlyout.lua` |
| **Class two-glyph prompt** | — | **72 × 24** | `MainActionBarFrame.xml` |
| **Whole native HUD action-bar frame** | — | **656 × 202** | `MainActionBarFrame.xml` |

### 10.3. Relative center coordinates for each eight-cell diamond (pinned source)

Coordinates use **the center of each bar** as `(0,0)`; values are not global screen pixels. Ordering below is **Left / Top / Right / Bottom** within each four-input diamond.

| Group and size state | Left | Top | Right | Bottom |
|---|---|---|---|---|
| **Square D-pad collapsed** | `(-92,0)` | `(-58,17)` | `(-24,0)` | `(-58,-17)` |
| **Square D-pad expanded** | `(-119,0)` | `(-75,23)` | `(-31,0)` | `(-75,-23)` |
| **Circle faces collapsed** | `(25,0)` | `(55,18)` | `(85,0)` | `(55,-18)` |
| **Circle faces expanded** | `(32,0)` | `(70,23)` | `(108,0)` | `(70,-23)` |

The **visual** center of the D-pad diamond is offset left; the face-button diamond offset right. The left group uses square artwork while the right group uses circular borders/icons. The paired patterns are deliberate and asymmetric in icon shape, though broadly balanced around the action-bar center. [S-08]

### 10.4. Distinct original art states: square vs circle

The pinned `ActionBarButton.lua` does not merely clip every button to a circle. It defines **two independent families of textures and masks** with state-specific artwork:

| State | Circle atlas naming | Square atlas naming | Meaning |
|---|---|---|---|
| Normal border | `gamepad-actionbar-circleslot-border-normal` | `gamepad-actionbar-squareslot-border-normal` | Resting edge/frame |
| Pressed border | `gamepad-actionbar-circleslot-border-pressed` | `gamepad-actionbar-squareslot-border-pressed` | Key-down physical feedback |
| Hover highlight | `gamepad-actionbar-circleslot-border-hover` | `gamepad-actionbar-squareslot-border-hover` | Selection/hover feedback |
| Selected/checked | `gamepad-actionbar-circleslot-border-selected` | `gamepad-actionbar-squareslot-border-selected` | Selected/toggled state |
| AoE targeting | `gamepad-actionbar-circleslot-aoetarget` | `gamepad-actionbar-squareslot-aoetarget` | Area spell aiming overlay |
| AoE mask | `gamepad-actionbar-circleslot-aoetarget-mask` | `gamepad-actionbar-squareslot-aoetarget-mask` | Correct geometry for targeting overlay |
| Casting | `gamepad-actionbar-circleslot-casting` | `gamepad-actionbar-squareslot-casting` | Casting glow/inner cue |
| Channeling | `gamepad-actionbar-circleslot-channel` | `gamepad-actionbar-squareslot-channel` | Channel inner cue |
| Interrupt | `gamepad-actionbar-circleslot-interrupt` | `gamepad-actionbar-squareslot-interrupt` | Interrupt feedback |
| Pet autocast | `gamepad-actionbar-circleslot-petautocastcorners` | `gamepad-actionbar-squareslot-petautocastcorners` | Autocast-capable pet action indicator |

Additional shared FX at the pinned source include:

```text
gamepad-actionbar-targeting-overlayglow
gamepad-hud-actionbar-channel-fill
gamepad-hud-actionbar-channel-complete-glow
gamepad-hud-actionbar-cast-fill
gamepad-hud-actionbar-casting-complete-glow
gamepad-actionbar-interrupt-overlayglow
gamepad-actionbar-petautocast-ants
```

**Art-state independence:** an action can have overlapping states (e.g. spell cooldown while button held; pressed border while cast/channel glow occurs; disabled range coloration while circular border remains round). The source has **distinct layers** for button frame, icon, mask, pressed/hover/checked, cooldown, channel, casting, AoE, interrupt and autocast. This is more specific than saying “action icon glows”. [S-06]

### 10.5. Empty slots and controller-specific glyph sets

The native source supplies **empty-slot art separate from learned spell icon art**. On an unassigned D-pad cell, a directional arrow appears in square art. On an unassigned face cell, the controller button letter/shape appears within circular art. Once a slot holds an action, its icon is displayed with the correct shape/edge and appropriate special state effects. [S-06]

**Native texture families:**

```text
D-pad, four directions:
  gamepad-actionbar-squareslot-generic-dpadleft-normal
  gamepad-actionbar-squareslot-generic-dpadup-normal
  gamepad-actionbar-squareslot-generic-dpadright-normal
  gamepad-actionbar-squareslot-generic-dpaddown-normal

PlayStation / Shapes:
  gamepad-actionbar-circleslot-ps-square-normal
  gamepad-actionbar-circleslot-ps-triangle-normal
  gamepad-actionbar-circleslot-ps-circle-normal
  gamepad-actionbar-circleslot-ps-cross-normal

Xbox-style / Letters:
  gamepad-actionbar-circleslot-xbox-x-normal
  gamepad-actionbar-circleslot-xbox-y-normal
  gamepad-actionbar-circleslot-xbox-b-normal
  gamepad-actionbar-circleslot-xbox-a-normal
```

There are native **Generic / Letters / Reverse / Shapes** texture-set modes. Their existence establishes that Forever's art is input-device-aware; a screenshot showing Xbox button letters does **not** prove that PlayStation icons are absent from the UI.

### 10.6. Four highlighted graphical states worth distinguishing

| Visible situation | Native expected look | Evidence |
|---|---|---|
| Normal resting ability | Square or circle frame around action icon, size according to active/inactive bank | S-06/S-08 |
| Holding L2 or R2 | Corresponding eight-button bank expands/highlights; other groups collapse/de-emphasize or hide under Compact | S-05/G-01 |
| Holding L1/R1 | Shoulder pressed art activates; targeting overlay supplies its own action/aim iconography | S-03/S-04 |
| Pressing an action face button | Distinct **round** pushed frame, with animation/state independently from the bound spell icon | S-06/S-08 |
| Unassigned face button | Grey PlayStation shape or Xbox letter in circle | S-06 |
| Unassigned D-pad button | Grey directional arrow in square | S-06 |
| Targeting an AoE | Dedicated aiming overlay/glow/mask by square/circle shape | S-06 |
| Channel/cast ability | Cast or channel fill/glow and completion glow; separate from cooldown/pressed | S-06 |
| Pet autocast toggled | Corners/ants/special pet indicator layered over pet action | S-06 |
| Class-action opener displayed | Standalone small **circle** with learned-class icon and paired bumper+trigger glyph beneath | S-02/S-03 |
| Page number active | Distinct selected page-tracker art, compared with inactive populated/disabled page styles | S-05 |
| UI item/frame focused | Configurable Gold/Blue/Black focus outline, independent from spell button press | G-01/V-07 |

**Cooldown presentation caveat:** Pinned action-button source establishes native action button state and art/mask pathways. It does **not** by itself establish the global cooldown time formula for every spell or whether all charge mechanics visually draw the same radial swipe. Any claim such as “all cooldowns always use one sweep” is stronger than the evidence.

### 10.7. Input prompts and their location

- Ability action glyphs are small device-specific prompts near/on active controls when enabled.
- Two-icon class prompts are separate source `InputPromptTwoIconTemplate` frames with the matching same-side bumper and trigger. Their anchors are **below** their respective class action buttons in pinned XML; they are intentionally not children of the flyout popup so opening the popup does not displace them. [S-03]
- October 8 changed the **tap vs hold** prompt glyph/indicator to make hold-required actions identifiable. Exact replacement texture and numeric frame dimensions for this new Oct 8 indicator have not been extracted. [B-04]
- Targeting shoulder icons/pressed backgrounds are separate from trigger bank glyphs; the two different types of overlay should not be conflated.

### 10.8. Other non-combat HUD art and “rings”

| On-screen feature | What is confirmed visually | What is **not** proven |
|---|---|---|
| Main radial | Multiple sections with icon wedges and menu labels; transient overlay | Stable Oct 8 radius, precise angle and animation timing |
| Class flyout | Small attached circular class opener and extension of ability icons | Full wedge count, ordering for every class, gesture thresholds |
| Emote wheel | Separate contextual emote selection popup | Full fixed emote list or ability to customize entries |
| Ping menu | Hold-R3 contextual ping choice display | Full type order, icon sizes, radius, timing |
| Target aiming circle | Small world-space circle near character feet while shoulder target selection | One invariant color/size under every creature/terrain |
| Face-button diamond | Four persistent circular combat buttons on right of D-pad diamond | It is **not** itself a popup radial wheel |
| Focus glow | Gold/Blue/Black border around selected UI object | A spell-selected circle or an ability cooldown display |
| Page tracker | Numbered and special selected/disabled state art | A fourth normal full page tied to the `S` symbol |

---

## 11. Settings, defaults, what can be adjusted, and what is locked

### 11.1. Exact historical and current menu locations

- **Gamepad UI switch:** Available at login/character selection and through in-game Options → Gameplay → **Gamepad (Alpha)**. Set **Enable Gamepad UI (Alpha)** to switch presentation. [G-01]
- **September 24–October 1:** General gamepad Options contained the newly added **Use Compact Action Bar** switch and other action-bar settings. [B-02]
- **October 8 onward:** **Gamepad Action Bar Edit Mode support**; open **Edit Mode**, select/click the **Gamepad Action Bar** itself, and set its options there. **Existing action-bar option values are not carried across** into this new location. UI layouts load/save **per UI type** (gamepad versus keyboard/mouse). [B-04]
- **Unknown within Oct 8 menu migration:** Blizzard's note says **“such as compact action bar”**. It does not individually enumerate which of Show Input Prompts, Scaling, Highlight, Show Empty etc. moved. Earlier guide locations for those settings are historical, not unconditionally still current.

### 11.2. Individual setting reference

| Native setting / control | What it controls | Historical default if supported | Version/availability provenance |
|---|---|---|---|
| `Enable Gamepad UI (Alpha)` | Choose native gamepad interface | Off unless enabled by user | G-01; exact account/character persistence **U** |
| `Show Input Legend` | Contextual instruction list top-left | Not confidently established here | G-01 |
| Horizontal Camera Speed | Camera speed from right stick | Exact numeric default **U** | G-01 |
| Vertical Camera Speed | Camera vertical speed | Exact numeric default **U** | G-01 |
| Horizontal/Vertical Invert | Reverse relevant camera axis | Exact initial values **U** | G-01/P reports invert value not saving in Sep |
| Follow Camera | Camera follows user movement | Exact starting state **U** | G-01 |
| Follow Camera Pitch Offset | Camera vertical follow pitch | Exact starting value **U** | G-01 |
| Turn Player With Camera | When camera rotation turns player too | Exact starting state **U** | G-01 |
| Face Movement While Mounted | Face the character's movement direction while mounted | Guide mentions option; exact initial **U** | G-01 |
| Face Movement While Swimming | Corresponding swim facing | Exact initial **U** | G-01 |
| Face Movement While Gliding | Corresponding glide facing | Exact initial **U** | G-01 |
| `HUD Modifier: Press to Toggle` | Target/HUD shoulder modes toggle rather than hold | **Off reported** | G-01; not a trigger-bank latch |
| `Frame Focus Style` | UI selection decoration | **Gold** reported | G-01/V-07; Gold/Blue/Black documented |
| `Frame Focus Opacity` | Focus border strength | Exact numeric default **U** | G-01 |
| `Show Input Prompts` | Display action button glyphs on action bar | **Off reported** | G-01; post-Oct 8 exact location **U** |
| `Show Action Bar Highlight` | Shadow emphasis of active bar | **On reported** | G-01; post-Oct 8 exact location **U** |
| `Enable Action Bar Scaling` | Increase active bar size | **On reported** | G-01; post-Oct 8 exact location **U** |
| `Show Empty Action Bars` | Show completely empty **sets**, not only filled sets | **On reported** | G-01; post-Oct 8 exact location **U** |
| `Use Compact Action Bar` | Show only selected action group | Not presumed default | **B-02** added; **B-04** moved into Edit Mode |
| `Stance Bar Override` | Stance bar substitution preference | **U** | G-01 lists but author could not test |
| `Possess Bar Override` | Possess-controlled bar preference | **U** | G-01 lists but author could not test |
| `Fixed Party Targeting` | One D-pad direction per party member outside raid | **U** | **B-02** confirms feature; exact mapping **U** |
| `Swap Target Modifier Sides` | Swap L1/R1 friend and foe | Default **off** implied by documented L1 friend/R1 foe | **B-02** |
| `Swap Friendly Target Action Sides` | Swap face/D-pad groups in friendly targeting | Exact stored default **U** | **B-02** |
| `Swap Hostile Target Action Sides` | Swap face/D-pad groups in hostile targeting | Exact stored default **U** | **B-02** |
| `Raid Targeting Hover Mode` | Whether group-directed spell changes hard selected target | **Off reported** | G-01; semantics explained in §4 |
| Gamepad Action Bar Edit Mode | Position/layout settings for native action-bar UI | UI-type saved layouts | **B-04**; exact handles/limits **U** |
| Gamepad UI layout type | Separate gamepad and keyboard UI layouts | UI-type dependent | **B-04** |

### 11.3. Locked versus configurable concepts

| Thing someone might want to change | Stock Forever status as supported here |
|---|---|
| **Which learned spell, usable item or macro goes into an assignable gamepad slot** | **Configurable** by native Bind to Action Bar process; macro movement fixed Oct 1. |
| **Which action-bar arrangement 1/2/3 is active** | **User changeable** via page shortcuts. |
| **L1/R1 friendly/hostile target side** | **Configurable** by side-swap option. |
| **D-pad vs face target-action sides** | **Configurable** per friendly/hostile target mode as whole groups. |
| **Fixed party target behavior** | **Configurable**; applies only to non-raid parties. |
| **Compact vs multi-cluster layout** | **Configurable**; moved to Edit Mode Oct 8. |
| **UI focus style/opacity, camera behavior, various HUD presentation settings** | **Configurable** as listed; the exact current menu location varies by setting. |
| **Physical base Cross jump / Circle cancel / Square interact / Triangle context** | **Locked in native default Gamepad UI** according to pinned source and Oct 1 static-binding update; cannot be replaced by ordinary binding of another spell into those base slots. |
| **Individual physical gamepad UI command rebinding** | **Static** as of Oct 1; Blizzard says input rebinding affects keyboard/mouse interface, not the stock gamepad UI controls. |
| **Completely custom native flyout contents** | **Not substantiated** as available in the native UI; stock ability lists are sourced from learned class/pet data. |
| **Native arbitrary custom spell/utility/emote radial wheels** | **Not established** as a stock feature. Screenshots of addon-created rings are not evidence. |
| **Native assignable extra paddles, PS button, DualSense touchpad buttons** | **Not established** as a universal default. Input hardware translation can introduce mappings not provided by Forever. |
| **Double-tap triggers for a second modifier bank** | **Not established** as stock; sometimes requested by players. |
| **Independent form-specific customization of all 28 assigned cells** | **Not established**; player feedback reports partial/buggy stance paging. |

---

## 12. Current-beta observed limitations and reports — not stock feature definitions

The following are useful to understand the **observed** beta but must not be misrepresented as stable design specs. Dates and source type matter.

| Topic | Field observation / official change | Source and interpretation |
|---|---|---|
| Base face buttons not freely bindable | Multiple players requested making base Square/X and other faces replaceable with spells or a single persistent basic attack | P-03/P-04; supports locked design complaint, not a new feature |
| Repeated base attack/interact can toggle attacks off | Reported in combat when rapidly switching triggers | P-03; interaction-specific observation |
| Action-bar editing formerly restricted | Earlier testers described layouts greyed out/repositioning limited | P-02; **Oct 8 introduced native bar Edit Mode**, so old claims are not automatically current |
| Chat lacks fully integrated typing | Reports of needing physical or OS keyboard | P-03/G-02; opening chat shortcut itself works |
| UI tooltip comparison missing until managed | Item stats/compare toggle accessed via Manage Bag according to Sept report | P-05; contextual hidden option, not evidence that item stats can never show |
| Druid form paging inconsistent | Bear Form icon/bar desync and page change limitations reported | P-01/P-02; no definitive post-Oct 8 status established |
| Rogue Stealth only one layer overridden | Oct 5 firsthand user observation | P-02; cannot infer every class's form behavior |
| Ground AoE precision | Users reported some ground-spell casts biased to target location and wanting cursor placement | Player reports; spell targeting behavior varies, not a single universal “all AoEs auto target” law |
| Mini-map focus / pings | Players requested focusable minimap, zoom and ping | P-03; request implies capability was not visible to that user, but is not an official “unsupported forever” contract |
| UI focus can be lost after level up | Player said they needed to reopen menu to recover selection | P-06; dated bug report |
| Loot input sticking | Official Oct 8 explicitly fixed an issue after looting | **B-04**; later build should not be assumed to share earlier defect |
| Input prompts failed to distinguish hold | Oct 8 improved hold-required indicator | **B-04**; updated behavior takes precedence over old visual guide |
| Legacy Edit Mode preset reset | Oct 1 known issue when switching UI types | **B-03**, followed by **B-04** per-type layout saving, so continuing status **U** |
| Pet action-bar replacement | Officially changed Sep 24 to **not replace** bottom normal bar | **B-02**; earlier footage can be outdated |

---

## 13. One-look state-specific controller reference (complete compact matrix)

The detailed sections above carry the qualifications. This matrix is intentionally redundant as a *quick retrieval index*, not a replacement for confidence labels.

| Physical control | Base gameplay | L2 / R2 / both spell layer | L1 friend target | R1 hostile target | L1+R1 HUD shortcuts | Main radial focused | Item/quest/map focused |
|---|---|---|---|---|---|---|---|
| **D-pad Up** | Assignable ability | Assignable ability | Party/raid up or fixed party member | **U** | Quest Log | Emote wheel | Up navigation / map filters |
| **D-pad Down** | Assignable ability | Assignable ability | Party/raid down or fixed party member | **U** | Chat | Sit/Stand | Down navigation / map fullscreen toggle |
| **D-pad Left** | Assignable ability | Assignable ability | Raid focus left or fixed party member | **U** | Previous page | Context navigation | Left navigation |
| **D-pad Right** | Assignable ability | Assignable ability | Raid focus right or fixed party member | **U** | Next page | Context navigation | Right navigation |
| **Square / X** | Interact / context attack / loot; optional hold action | Assignable ability | Target pet | Ranged attack displayed | Sheathe/unsheathe | Menu-specific action | Equip/Bind, quest details, map marker; context dependent |
| **Triangle / Y** | Inspect / unit context | Assignable ability | Friendly marker | Hostile marker | Buff viewer | Menu-specific action | Item More, quest options, map broader view |
| **Circle / B** | Stop cast → stop targeting → clear target in pinned world code | Assignable ability | Assist | Assist | Bags | Close/back, depending on focus | Back/close |
| **Cross / A** | Jump (down/up) | Assignable ability | Self | Last hostile | Sit/Stand/Descend | Select/confirm according to prompts | Select/confirm according to prompts |
| **Left stick move** | Move character | Move character | Movement behavior depends on targeting/modal | Same | Movement as permitted | Modal ownership **U** | Can still move under Oct 8 map-Quest-log-first focus |
| **Right stick move** | Camera | Camera | Aim friendly | Aim hostile | Up/down camera zoom | Select menu wedge | Pan map when cursor focused / focus-specific role |
| **L3** | Autorun | Autorun unless context captures it | Context-specific **U** | Context-specific **U** | Camera recenter | **U** | **U** |
| **R3 tap** | Ping | Ping unless context captures it | **U** | **U** | Held R3 look-behind; tap semantics **U** | **U** | **U** |
| **R3 hold** | Ping selector | Ping selector unless context captures it | **U** | **U** | Look behind | **U** | **U** |
| **L1** | Friend tap/hold | Class flyout when paired with L2 on appropriate class | Modifier itself | Possible collision resolved by mode | Both shoulders shortcut | Change menu section | Spellbook/page navigation depending on focus |
| **R1** | Foe tap/hold | Class flyout when paired with R2 on appropriate class | Possible collision resolved by mode | Modifier itself | Both shoulders shortcut | Change menu section | Map zoom/spellbook pages depending on focus |
| **L2** | Hold selects first spell layer | Layer owner | **U** for combined targeting chord beyond class | **U** | **U** | **U** | Can change focused frame in multi-window walkthrough |
| **R2** | Hold selects second spell layer | Layer owner | **U** | **U** beyond class | **U** | **U** | Can change focused frame in multi-window walkthrough |
| **Options** | Open radial | Open radial if no modal interferes | **U** | **U** | **U** | Dismiss/context actions | UI focus dependent |
| **Share/touchpad** | Focus / cursor for some PS setups | Driver dependent | **U** | **U** | **U** | Focus-switch in PS walkthrough | Mouse-like cursor or focus switch in PS walkthrough |
| **PS/Home** | No documented native binding | Same | Same | Same | Same | Same | Host OS/driver dependent |

**The `U` cells are intentional.** They prohibit making up an action for combinations that are not demonstrated or supported by native source. “U” also does not say the control is guaranteed to have no function in a newer build.

---

## 14. Genuinely unresolved native-UI details (research boundary)

These gaps are not accidental omissions of instructions; the public evidence checked here **does not support a definitive answer**. A later client capture or more recent Blizzard-authored source is necessary to settle each:

1. **Hunter/Warlock** left/right class-flyout exact contents, spell/item IDs, order, pet autocast control icons, and no-pet fallback; a source snapshot of Druid/Paladin/Warrior alone does not settle pet flyouts.
2. Exact **Druid form** flyout icon order for every learned-form combination, including whether additional race variants affect icon list beyond the learned spells.
3. **Warrior stance** flyout popup icon order and whether current beta hides unknown/blocked stances versus greying them.
4. **Class flyout selection gesture** in full (right stick angle/neutral return, button release, hold duration, cancellation/close without casting) and whether all flyouts use exactly the same gesture.
5. Whether **Rogue Stealth, Druid forms, Warrior stances** page one or several banks in the Oct 8 build under every supported setting; individual dated reports conflict.
6. Full priority and bank assignment for **possess, charm, vehicles, quest temporary actions, extra action, pet, override, and special `S` page** in every context.
7. Exact numeric **hold-vs-tap thresholds** except the pinned **0.5s Interact hold**. Oct 8 changed visual indicators but does not publish the new atlas constants in the checked sources.
8. Exact **hostile targeting D-pad functions** while holding R1: some early descriptions and player reports disagree.
9. Exact D-pad **Fixed Party Targeting** physical direction → `party1..party4` mapping and what happens to self selection with party member ordering changes.
10. Exact **toggle-HUD-modifier** transition priorities across simultaneous L1/R1 and return-to-normal states.
11. Exact **native page count under all special modes**: three standard arrangements and `S` are confirmed in the pinned source, but what `S` does in all gameplay contexts remains conditional.
12. Full **radial main-menu wedge angular positions**, selected/glow frame names, radius, snap, animation length, opener toggle behavior and release-to-select mechanism in Oct 8 build.
13. Complete **emote and ping wheel** icon lists/order, selection-confirm mechanics and whether players can edit them in stock UI.
14. Whether **Chat** now has an integrated keyboard after late-beta updates (no first-party confirmation checked here), versus host OS onscreen keyboard.
15. Exact **Create/Share, touchpad-click and PS/Home** mappings on DualSense under all Windows input modes; physical button to game input translation is device/driver-dependent.
16. Which **bar visual options besides Compact** were moved to Edit Mode on Oct 8, their controls and numeric ranges; Blizzard only describes the family and Compact explicitly.
17. Post-Oct 8 status of the **old Edit Mode reset bug** and older stance-form UI bugs; a historical report does not prove continued reproduction.
18. The October 8 build's definitive **pixel placement** after UI scale, Edit Mode position and viewport changes; pinned 656×202 and 110 anchor are older source constants.
19. Exact fallback behavior for **invalid target, no pet, blocked spell, missing item, unusable cast, out of range, same-input arbitration** under all contexts.
20. Whether every keyboard/mouse **spellbook, profession, item comparison, raid marker, minimap, vendor/AH** operation is accessible with gamepad alone in Oct 8 client; several player reports describe exceptions.

A future answer to any of these must contain a **specific build/source path and line or a dated native capture**. Absence of evidence cannot legitimately be changed into a locked-default claim or filled by analogy with a different WoW edition.

---

## 15. Source index — official updates, actual native source and visual evidence

### Official Blizzard dated changes

- **[B-01]** Blizzard / Kaivax, Sep 22–23: [Beta Client Update – September 22](https://us.forums.blizzard.com/en/wow/t/beta-client-update-september-22/2358655). Controller character select and quest item interaction.
- **[B-02]** Blizzard / Kaivax, Sep 24: [WoW Forever Beta Development Notes, first entry](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-8/2360696/1). All five class-flyout categories; pet bar change; targeting swaps, compact mode; map/Quest Log, Edit Mode, raid UI.
- **[B-03]** Blizzard / Kaivax, Oct 1: [Beta Development Notes, October 1 entry](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-8/2360696/4). Static Gamepad UI bindings, pet stable, compact raid frames and macro movement; older known Edit Mode reset issue.
- **[B-04]** Blizzard / Kaivax, Oct 8: [Beta Development Notes, October 8 entry](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-development-notes-%E2%80%93-updated-october-8/2360696/5). Hold prompts, loot fix, Quest Log map focus, raid traversal, bar Edit Mode, per-UI-type layouts, moved settings.

### Blizzard-authored **Forever** UI source (version-qualified snapshot)

The following paths are Blizzard-authored UI code preserved in a **pinned public Gethe/wow-ui-source snapshot**. This source is an **implementation artifact**, not an official promise that later beta builds cannot change. Commit reference **`15666a6e67938a1ab5caf041406464251db111ca`** is used consistently throughout to keep the documented geometry/code internally coherent. This is **not** the latest beta build hash.

- **[S-01]** [Blizzard_GamepadActionBars directory](https://github.com/Gethe/wow-ui-source/tree/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars): native action-bar components and mode-specific files.
- **[S-02]** [Camelot/ClassSpellFlyout.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/Camelot/ClassSpellFlyout.lua) and [ClassActionFlyout.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ClassActionFlyout.lua): Druid=262 Left, Paladin=270 Left, Warrior=269 Right, learned-only visibility, same-side button chord detection and extra circular button styling.
- **[S-03]** [MainActionBarFrame.xml](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.xml): overall frame size/anchor, targeting shoulders, class-action positions, paired glyph prompts.
- **[S-04]** [MainActionBarFrame.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua): four reserved faces, cast/target cancel priority, contextual interact and 0.5-second hold, HUD-modifier Jump branch, shoulder icon swapping and press routing.
- **[S-05]** [PageUnit.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/PageUnit.lua): four normal bars, targeting/shortcuts special bars, page tracker, active bar/context override and compact layout.
- **[S-06]** [ActionBarButton.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.lua): original circle/square atlas names, PS/Xbox/Reverse/Generic glyphs, cast/channel/AoE/autocast/highlight states.
- **[S-07]** [Bindings.xml](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/Bindings.xml) and [ActionBindingUtil.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBindingUtil.lua): eight directional indices; reserved base face slots; standard/special slot translation.
- **[S-08]** [ActionBarStyles.lua](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarStyles.lua): square/circle button sizes, 208×68 / 266×86 group bounds, pressed offset and exact left/right diamond coordinates.

### Guides and player reports

- **[G-01]** [Warcraft Tavern — Forever controller guide](https://www.warcrafttavern.com/forever/guides/controller): targeting map, stock settings/defaults, input legend and original image examples. It reflects largely **pre-Oct 8** locations.
- **[G-02]** [NerdsChalk / ConCon video walkthrough](https://nerdschalk.com/world-of-warcraft-forever-beta-controller-setup-bindings-and-controls/): 35-step in-game guide to bindings, menus, inventory, map, quest log, stick shortcuts, PS touchpad and professions. Originally published **Sep 23**.
- **[V-01]** [Warcraft Tavern — built-in controller and three radial screenshots](https://www.warcrafttavern.com/forever/news/world-of-warcraft-forever-has-built-in-controller-support/): **Sep 13** early native beta/BlizzCon visual capture.
- **[V-02]** [Warcraft Tavern hotbar images](https://www.warcrafttavern.com/forever/guides/controller) and [original top/base group](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-hotbars-1.png).
- **[V-03]** [NerdsChalk / ConCon step-by-step screenshots](https://nerdschalk.com/world-of-warcraft-forever-beta-controller-setup-bindings-and-controls/): key/button prompts, radial navigation, quests, map, focus and bind mode.
- **[V-04]** [Warcraft Tavern targeting screenshots and explanations](https://www.warcrafttavern.com/forever/guides/controller).
- **[V-05]** [Native Warrior stance flyout screenshot from beta footage](https://wowforeverguides.com/assets/systems/gamepad/wow-forever-gamepad-stance-flyout.webp) and [support documentation](https://wowforeverguides.com/systems/gamepad-support).
- **[V-06]** [Native input legend image](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-input-legend.png).
- **[V-07]** [Gold focus](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-gold-glow.png), [Blue focus](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-blue-glow.png), [Black focus](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-black-glow.png).
- **[V-08]** [Warcraft Tavern actual BlizzCon boss fight HUD](https://www.warcrafttavern.com/wp-content/uploads/2026/09/world-of-warcraft-forever-gamepad-boss-fight.png).
- **[P-01]** [Druid/Hunter firsthand controller feedback](https://us.forums.blizzard.com/en/wow/t/controller-feedback-rdruidhunter/2362556): levelled Restoration Druid/Hunter, flyout convenience and form UI issues.
- **[P-02]** [Controller feedback & bug tracking](https://us.forums.blizzard.com/en/wow/t/wow-forever-controller-feedback-bug-tracking/2358921): historical stance paging and Oct 5 Rogue Stealth observation.
- **[P-03]** [Forty-hour controller feedback & suggestions](https://us.forums.blizzard.com/en/wow/t/wow-forever-beta-controller-suggestions/2360604): attack/interact behavior, chat, minimap requests.
- **[P-04]** [Forum controller feedback](https://us.forums.blizzard.com/en/wow/t/feedback-controller-support/2355361): base face rebinding constraints and pet changes reported Sep 29.
- **[P-05]** [Gamepad item comparison via bag management](https://us.forums.blizzard.com/en/wow/t/gamepad-mode/2353538): Sep 18 player report.
- **[P-06]** [Controller issues and annoyances](https://us.forums.blizzard.com/en/wow/t/controller-issues-and-annoyances/2362371): Sep 25 focus/default controller complaints.

### Full-size screenshot URLs (native UI only; dates mostly September)

| Image | Direct file | Evidentiary purpose |
|---|---|---|
| **IMG-01** | [Main radial — section 1](https://www.warcrafttavern.com/wp-content/uploads/2026/09/wow-forever-gamepad-main-menu-1.jpg) | Menu geometry and icons in initial screenshot |
| **IMG-02** | [Main radial — section 2](https://www.warcrafttavern.com/wp-content/uploads/2026/09/wow-forever-gamepad-main-menu-2.jpg) | Alternate page/section |
| **IMG-03** | [Main radial — section 3](https://www.warcrafttavern.com/wp-content/uploads/2026/09/wow-forever-gamepad-main-menu-3.jpg) | Another page/section |
| **IMG-04** | [Four-set hotbar illustration](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-hotbars-1.png) | Pair of D-pad and face-button diamonds |
| **IMG-05** | [Warrior class flyout](https://wowforeverguides.com/assets/systems/gamepad/wow-forever-gamepad-stance-flyout.webp) | Flyout/icon presence, not later numeric position |
| **IMG-06** | [Friendly targeting overlay](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-friendly-targeting-actions.png) | Friendly mode visible action prompts |
| **IMG-07** | [Hostile targeting overlay](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-enemy-targeting-actions.png) | Enemy mode visible action prompts |
| **IMG-08** | [Input legend](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-input-legend.png) | Upper-left contextual controls |
| **IMG-09** | [Gold focus example](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-gold-glow.png) | Selected UI frame art |
| **IMG-10** | [Blue focus example](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-blue-glow.png) | Alternative focus art |
| **IMG-11** | [Black focus example](https://www.warcrafttavern.com/wp-content/uploads/2026/09/forever-controller-black-glow.png) | Alternative focus art |
| **IMG-12** | [Full boss HUD](https://www.warcrafttavern.com/wp-content/uploads/2026/09/world-of-warcraft-forever-gamepad-boss-fight.png) | Uncropped-style native world UI composition |
| **IMG-13** | [Historical Gamepad options](https://wowforeverguides.com/assets/systems/gamepad/wow-forever-gamepad-options-targeting.webp) | Older controls list; **not current action-bar setting location** |

---

## 16. Interpretation contract / final scope declaration

This document describes **Forever's native Gamepad UI** and nothing else. An exact source-derived number is tagged **S**, an official later change is **B**, a screenshot observation **V**, a guide-derived mapping **G**, a dated beta-player account **P**, and unresolved details **U**. It does not prescribe a different product's behavior and does not choose which features should be retained, removed, or implemented elsewhere.

**In particular:** do not silently turn **U** into a default, call a requested addon feature native, use screenshots from a different WoW client as original art, assume L1+L2 and R1+R2 are identical, assume Warrior's stance flyout is on the left, assume that Oct 8 action-bar options remain under the pre-Oct 8 Gamepad settings list, or treat early beta bugs as confirmed current behavior.
