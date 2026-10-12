# Controller behavior specification

Status: maintained
Reviewed: 2026-10-12
Evidence: [binding policy](../addon/ConsolePort_Forever/BindingPolicy.lua),
[shipped reference](../addon/ConsolePort_Forever/Reference.lua),
[temporary routing](../addon/ConsolePort_Forever/TemporaryRouting.lua),
[ping](../addon/ConsolePort_Forever/Targeting/Ping.lua).

## Ordinary banks and saved commands

The expanded HUD has Base/L2/R2/L2R2 banks with eight cells each: four D-pad and
four face cells. The unmodified faces are reserved/shared commands, leaving 28
ordinary character-owned action positions in this model. L2 maps to SHIFT, R2
to CTRL and L2+R2 to CTRL-SHIFT in the shipped reference. Native/user binding
edits remain authoritative; the reference is a preset, not a live engine dump.

| Face | Key | Shipped Base command |
| --- | --- | --- |
| Cross/X | PAD1 | JUMP |
| Circle/B | PAD2 | Captured preset remains empty; candidate.34 review offers MACRO CPF Circle for empty or owned legacy Base binding. Cast interruption is user-confirmed; manual commands/Keep/removal retained. |
| Square | PAD3 | INTERACTTARGET |
| Triangle | PAD4 | TURNORACTION |

Candidate.34 review offers native MACRO binding for an empty or owned legacy Circle.
Resource identity tolerates CRLF and final LF blank lines only when the exact
owned commands match. Native macro bytes are never rewritten for normalization.
The engine owns its key edge. Candidate.34 cast interruption is user-confirmed;
ground-placement cancellation is untested because the user reports interception
by the existing targeting adapter. Detailed timing and other contexts remain
individually unasserted. [Acceptance](../evidence/circle/candidate34-live-acceptance-2026-10-12.json).
The unchanged body will stop casting/channeling,
cancel ground placement and clear the hard target together. It never invokes
Escape/Options or closes native windows itself. This is an explicit Retail
approximation, not Forever's first-success chain; cancellation also clears a
coexisting hard target. Native Layers retains UI/ring priority. Modified clicks
are blocked by the fixed macro guard; ordinary modified actions stay native.
The direct MACRO binding uses no addon button callback or macrotext/RunMacroText.
The inherited helper remains solely for retained legacy click bindings. One account macro CPF Circle needs explicit review;
full storage, name collisions and edited macros remain untouched. Missing/edited
resources defer proposals; native accepted MACRO edits keep engine semantics. Refresh never recreates them. Macro creation and
attribute writes wait outside combat/Edit Mode. Hydration never installs the
binding proposal, preserving later manual removals. See the
[research/proof record](reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md) and
[blocked-action investigation](reference/CIRCLE-BLOCKED-ACTION-2026-10-12.md).

Square is native interaction, not an unconditional mouse click at the pointer.
A floating hand and successful mouse click do not prove that the native soft
interaction target or effective controller binding was the same. See
[open interaction report](KNOWN_ISSUES.md#open-reports).

The preset maps base D-pad to action buttons 9–12; L2 to ordinary action buttons
1–8; R2 to MultiActionBar1 buttons 1–8; L2R2 to MultiActionBar2 buttons 1–8.
These are binding declarations, distinct from the spells currently occupying
slots and from temporary secure page resolution.

## Priority and state

Native ConsolePort Manager/Layers/Input resolve saved commands and temporary
claims. Focused UI, modals and other native owners may supersede a visible bank.
Visibility or `GetBindingAction(key)` alone does not prove effective dispatch;
the effective engine lookup and native handler matter. Preserve foreign claims,
release held UI actions on combat handoff and restore native gameplay priority.
See [state matrix](STATE_MATRIX.md) and T41/T61 in [testing](TESTING.md).

Native temporary family/page evidence replaces only L2R2. Base/L2/R2 keep their
ordinary models. Ordinary forms/stances/stealth use native class pages; being
mounted/in flight/in a form is not sufficient evidence for a temporary takeover.
The native declared capacity limits those eight cells. Vehicle/override defaults
are six where no different audited count is declared, leaving L2R2 cells 7–8
empty rather than guessing slots. Temporary shapeshift can declare twelve.
[TemporaryAccess](../addon/ConsolePort_Forever/TemporaryAccess.lua) exposes eligible
slots 9–12 and exit through native mouse-accessible buttons; it installs no new
controller key or interface-cursor acquisition. Ordinary class/skyriding bonus
state alone is not an overflow signal. This is not a claim of full controller
access to every native action. Unavailable temporary drops fail without changing
ordinary bindings; removal clears cached direct actions, and held release retains
the pressed action before resolving the current native page.

## Ping gesture

| Event | Candidate.30 contract |
| --- | --- |
| Bound gamepad ping key down (preset R3) | No ping dispatch. Arm the native ring/selection immediately with artwork initially hidden. |
| Neutral/empty tap release | One contextual aimed unit/world fallback, without tap artwork. A deflected/sticky native selection can instead select a ping before the artwork threshold. |
| Hold | Cosmetic reveal after the configured 0.15-second threshold; actual ConsolePort account ring. |
| Right stick / native sticky selection | Native selection handling; no replica renderer. |
| Selected release | Send the selected native ping once. |
| Empty release | One aimed fallback. |
| Cancel / competing owner / ineligible state | Retain native cancellation and guarded owner handoff; no independent public ping call. |

The ring is seeded once in native Shared account data and preserves later edits,
order and removals; collisions fail closed. A timer/alpha controls presentation
only, never privileged permission. Repeated ordinary refreshes preserve the
gesture. The candidate.27 fallback is retained inactive outside addon/TOC.
[Acceptance](../evidence/forever-ui/candidate30-live-acceptance.json) covers the
reported defects, not every account/combat/selection case.

Ping follows qualified gamepad keys actually bound to native
`TOGGLEPINGLISTENER`, including remapped/multiple keys; R3 is the preset, not a
hardcoded exclusive route. Keyboard bindings remain native. Standard audited
modifier layers are required; alternate tap-latch/double-bar/ordered policies
are rejected. A modifier change, combat transition or competing native
cursor/radial owner cancels the active gesture. The artwork monitor tolerates a
brief missing controller sample (0.25 seconds), then unwinds/cancels where public
state permits; device changes also unwind. These timers do not gate dispatch.

Default ring entries are Attack, Warning, On My Way, Assist, Non-threat and Threat.
Selected dispatch delegates native release/sticky handling. An empty fallback
checks soft enemy, then soft friend, then centered world cursor. Native secure
macro machinery temporarily centers the gamepad cursor; the prior CVar restores
only while the value is still owned. No public `C_Ping` dispatch is used.

## Class and utility access

ClassActions determines qualified class content/chord. Paladin/Druid use the
left L1+L2 route; Warrior uses the right R1+R2 route. The resolver's fallback for
other classes is also right R1+R2. The explicit three-class supported set gates
revision-17 repair and native class-row suppression; generic binding/ring proposal
helpers still require actual native learned data and are not universally disabled
for other classes. This does not establish an all-class aura wheel or activate
the later class/pet selector preview. Personal rings must not leak across GUIDs.
Existing native hold/release selection remains; exact additional Forever
stick-return/active-entry/close-and-continue gestures remain separate gates.

Manual ring order/duplicates/metadata are preserved by generic capture, with
unavailable actions retained dormant. Class augmentation separately appends
missing learned forms and the scoped migration can repair access. Consequently
class-entry deletion differs from action-slot removal; automatic action-slot
restoration remains removed. See [configuration](reference/RUNTIME-CONFIGURATION.md).

The shipped utility preset includes L3 autorun; L2+L3/R2+L3 invoke native
LiteMount buttons LM_B1/LM_B2; L2+R3 invokes the native extra action command.
Preserve native mount rules and explicit icons; LM_B2's default icon remains
unproved. Controller glyphs are device-resolved; DualSense L2/R2 and Xbox LT/RT
are labels for the same logical banks, not universal literal artwork.

## Ground placement and UI controls

Ground placement is a reviewed native secure click adapter with account
preferences and per-spell/context overrides. Qualify a spell/context before
using it; retain native behavior for unknowns. Do not disable the accepted
adapter as an incidental workaround for another defect.

The current [preference model](../addon/ConsolePort_Forever/Targeting/Preferences.lua)
stores shared `groundTargeting` maps for spells, contexts and context-specific
spells. Modes are `default`, `cursor`, `player` and `manual`; contexts are vehicle,
override, temporary and extra. Resolution prefers a context-specific spell,
then general spell, then context, then the registered default. Player defaults
are explicitly limited to Death and Decay, Defile and Angelic Feather; other
qualified defaults use cursor placement. Defaults do not qualify unknown reticles:
the registry or an explicit per-spell cursor/player choice is required. Reviewed
preferences retain history and native fallback; this describes current source,
not a claim that every spell has been tested in Retail.

The Targeting configuration panel stays available under recovery. Draft Revert,
Defaults and Apply have different meanings; Apply stores account preferences
and whole prior-table history, without itself enabling the adapter. It rejects
combat but can save during Edit Mode while protected refresh defers. The
[configuration contract](reference/RUNTIME-CONFIGURATION.md#ground-preferences)
describes qualification, reset scope and history limitations.

Full custom UI context acquisition is suspended under native input recovery.
The following directions have tests/design but are not current enabled parity:
popup face-to-button mapping, quantity D-pad/confirm/cancel, window L2/R2 focus,
L1/R1 tabs, audited right-stick scrolling, custom map pan/zoom/waypoint and bag
prompt/loot-hold behavior. Native UI controls remain available. Text entry,
exact one-success gameplay Circle, active-entry cancellation and held cinematic
skip remain deferred/gated. [Requirements](REQUIREMENTS.md) owns their intent.
The [presentation/UI reference](reference/PRESENTATION-AND-UI.md) describes
actual guarded dormant routes and the active visual/visibility behavior.

## Maintenance

For changed bindings/gestures, record physical keys, native command, context,
priority, down/hold/release/cancel behavior and persistence owner. Update states
and applicable regression/acceptance cases; keep Forever evidence separate.
