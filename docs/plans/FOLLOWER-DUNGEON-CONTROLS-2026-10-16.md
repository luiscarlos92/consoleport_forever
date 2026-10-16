# Follower dungeon controls: investigation and staged plan

Status: maintained
Reviewed: 2026-10-16
Evidence: [source dry runs](../../evidence/follower-dungeons/2026-10-16/source-dry-runs.json),
[source provenance](../../evidence/follower-dungeons/2026-10-16/source-manifest.json),
[saved-data observation](../../evidence/follower-dungeons/2026-10-16/saved-data-observation.json).

## Current candidate continuation

The later user comparison confirms Blizzard's button works while the numeric
ring route usually repeats lead and retains blue artwork. The user authorizes
proceeding with the best supported repair. Candidate.40 now implements the
[native name route and selective presentation](../reference/FOLLOWER-DUNGEON-RUNTIME-2026-10-16.md).
The sections below retain the ordered investigation and earlier stopping
boundaries; their no-code/pending-dependency statements describe those stages.
The current lock qualifies the three discovered updates, while the running-game
delivery selects Forever only. Retail lead/stop acceptance remains pending.

## Request and current boundary

The October 16 user requests investigation and an ordered plan before changing
the addon: remove the duplicate standalone follower-control button inside
follower dungeons, preserve actual extra dungeon abilities, and repair the
Utility Ring's stale icon and reported inconsistent/repeated lead/stop action.
That initial instruction authorized research, documentation and isolated source
dry runs before runtime implementation. The later queued October 16 instruction
authorizes further valuable experiments and qualified implementation/deployment,
or stopping where Retail testing is the best next step. Permission is no longer
the open boundary; a supported complete execution repair remains necessary.

The subsequent October 16 instruction authorizes hypothesis validation and a
persistent isolated execution reproducer, with online implementation research.
That continuation is complete in the [native execution experiment](../reference/FOLLOWER-DUNGEON-EXECUTION-PROBE-2026-10-16.md):
normal paired gestures did not double-dispatch; an explicitly replayed release
with a deflected stick can issue another command. Native toggle arguments still
differ, but engine causation remains unproved. Direct click delegation preserves
the argument under modeled access, while native ring data has no direct click
kind. No addon implementation or deployment followed from these experiments.

The next user continuation authorizes the [custom-binding/proxy experiment](../reference/FOLLOWER-DUNGEON-PROXY-PROBE-2026-10-16.md).
Its chain works under modeled permissions, but native pooled-frame reuse can
cast a different spell and native auto-assignment can append the original spell
beside a replacement custom entry. The conservative prototype avoids combat
reuse by disabling then; that is not adopted product behavior. Keep the native
fallback and do not integrate this partial candidate as a complete repair.

The user then clarified that the affected selection uses release: open the ring,
move to the follower entry and let go. The resulting lead/follow command feels
unpredictable. Focus the remaining execution diagnosis on this route; ordinary
paired release did not reproduce it offline. This clarification does not prove
an extra engine event or a two-call sequence. [User observation](../../evidence/follower-dungeons/2026-10-16/user-gesture-observation.json).

The preceding chat, **Plan Utility Bar Ability Support**, was inspected. Its
useful workflow is source investigation, explicit uncertainty, isolated native
experiments, then runtime integration and separate Retail acceptance. Existing
shared-ring authority and positive feedback do not establish acceptance here.

The user's three screenshots are retained locally as ordinary view (`user-1.png`),
open ring (`user-2.png`), and selected follower entry (`user-3.png`) in the dated
evidence directory. These personal images are excluded from the public repository.
The third shows a blue ring icon while the standalone icon is orange. Chat
includes a follower agreeing to lead and then saying it is ready. Still images
cannot establish which gesture caused each line, elapsed cooldowns, or cast count.
Loaded candidate and exact screenshot spec are not independently established.

## What the source establishes

### Separate siblings share the extra-ability area

Blizzard's `ExtraAbilityContainer` holds `ExtraActionBarFrame` at priority 100
and `ZoneAbilityFrame` at priority 200. Its sorting explains the separate extra
action appearing to the left of the zone ability. The follower-style control is
consistent with the zone-ability child, rather than the extra-action slot.

`ZoneAbilityFrame` also supports multiple unrelated zone abilities in its pooled
`SpellButtonContainer`. Therefore hiding the shared container, the extra-action
bar, or every zone ability would exceed the request. Do not assume a fixed
child index: content and pooled frame identity can change. Preserve native
style/layout, sibling abilities, tooltips and Edit Mode behavior.

ConsolePort's `ConsolePortTempAbilityFrame` is a separate short-lived ability
briefing. Its source does not match the persistent square button in the images.
Disabling all ability briefings is not this requested fix.

### Ring presentation loses zone-specific state

ConsolePort 3.3.10 `Controller/Auto.lua:ToggleZoneAbilities` adds each eligible
active zone ability as an `autoassigned=true`, `type='spell'` entry. Its regular
extra-action entry instead uses the extra action slot (`action=169`). These
mechanisms must remain distinct.

The locked LibActionButton spell `GetTexture` calls ordinary `GetSpellTexture`.
Blizzard's zone button `Refresh` instead calls
`C_ZoneAbility.GetZoneAbilityIcon` after resolving its current override. A valid
generic spell icon therefore does not establish correct follower-state artwork.
Repeatedly rebuilding the same spell entry is not an adequate icon repair.

Forever's actual `Rings/Utility.lua:Build` preserves native autoassigned entries
outside the shared manual archive, with temporary entries mapped to zero. The
dry run confirms the plain spell payload survives this path unchanged. That
does not prove the integration cannot contribute another live failure.

Read-only saved Forever archive receipts contain Dungeon Assistance, spell
426756, as an autoassigned spell in both before/desired views. Saved ConsolePort
settings contain `ringPressAndHold=true`. These are persisted observations, not
the current engine or the screenshots' effective input state. The native default
ring's logout seed is deliberately sparse; its absence there is not loss proof.
No saved data was written or copied wholesale into research evidence.

Blizzard's [follower-dungeon description](https://news.blizzard.com/en-gb/article/24054790/take-the-lead-in-follower-dungeons)
labels blue as allowing a follower to lead and orange as stopping that leading.
The implementation should follow native semantics and tooltip, not an inferred
meaning from colour alone.

### Execution differs; the double-toggle cause remains open

The native zone button calls `CastSpellByID(baseSpellID, nil, true)`; the third
argument explicitly requests toggle handling. The pinned generic secure spell
handler calls `CastSpellByID(spellID, unit)` without that argument, or casts by
name for a string payload. This is a concrete contract difference to investigate.
It is not proof of what the Retail C implementation does with this spell.

ConsolePort's restricted `Main` clears its release action type before routing
the gesture. Hold mode opens on down and commits on release; toggle mode ignores
down and opens/commits on successive releases. `CommitAction` copies a selected
slot to the secure release attributes. The inspected flow does not itself prove
two casts from one gesture. Do not replace all ring input, add a timer debounce,
or attribute the symptom to duplicate down/up dispatch without reproducing it.

Possibilities still to distinguish include native toggle semantics, a stale
selected/override payload, repeat/sticky/accept-button interaction, and another
binding or macro path. A saved spell entry alone does not identify the effective
hardware path at the moment of failure.

## Source identity and dry runs completed

Checkout baseline: `594ebaeba621f19075e9a9e83926c8b5c74bc2f9`, initially clean.
The official latest stable ConsolePort release checked October 16 is 3.3.10,
matching the lock. Selected files were hash-verified before execution. Limited
issue searches found no matching lead/stop/icon report; this is not an exhaustive
absence claim. [Discovery receipt](../../evidence/follower-dungeons/2026-10-16/upstream-discovery.json).

Blizzard-authored mirrored source was inspected at the repository's existing
Retail pin `09b9db7948abc9b9648dedaab51eb0cf3ee67b31` and the discovered live head
`18c6d677b605b312f3d813d498404631fb941977`. ZoneAbility Lua/XML and the extra-ability
container Lua/XML are identical across those two observations. New research
copies have their own manifest; existing pinned evidence is unchanged.
The pinned LFG API exposes `C_LFGInfo.IsInLFGFollowerDungeon()`; prefer that
native context predicate to dungeon-name or difficulty-number guesses.

Five bounded experiments executed actual selected Lua bodies in Fengari:

| Experiment | Observed result | Limit |
| --- | --- | --- |
| Blizzard `Refresh` versus locked LAB spell texture getter | With modeled state change, zone icon changes and generic icon stays fixed. | C icon results modeled; no rendered-pixel proof. |
| Blizzard `OnClick` versus pinned `SECURE_ACTIONS.spell` | Each calls once; native zone call has the third toggle argument, generic call does not. | Cast API is a recording spy; no toggle/server/taint semantics. |
| Native ConsolePort zone auto-assignment | Produces a temporary generic spell. | Synthetic active ability and action-bar lookup. |
| Actual Forever utility projection | Preserves that temporary spell unchanged. | Not the whole loaded client/handler sequence. |
| Blizzard extra-ability container | Extra-action precedes zone frame; removing the zone sibling leaves extra-action visible. | Does not qualify removing all zone abilities or pooled child suppression. |

These are research dry runs, not production regression qualification. They do
not execute a new restricted snippet, simulate the complete hardware route, or
certify Retail taint, timing, combat permissions, persistence or visuals. No
full release suite was needed for unchanged runtime/tooling. All official stable
dependencies must be freshly checked before later development changes under the
normal dependency workflow; this pass checked only relevant ConsolePort freshness.

## Ordered next steps and gates

1. **Lock the narrow behavior contract.** Follower entry appears only in the
   appropriate native context, shows native current artwork/tooltip, and one
   selection produces at most one command with native lead/stop behavior.
   Preserve real extra actions and other zone abilities. Record the requested
   UI change as intended, not already implemented or accepted.

2. **Reproduce execution before selecting a repair.** In an isolated test
   harness, execute the actual ConsolePort ring controller and pinned restricted
   compiler, generic secure dispatch and relevant Forever admission path.
   Exercise hold/release, toggle mode, second selection, sticky/neutral selection,
   separate accept button, cancel, modifiers and reopened wheels. Count commands
   and record selected payload/attributes. Run the same cases with Forever's
   shared adapter absent and present. Distinguish two commands from one command
   with different native toggle semantics. If the reported sequence cannot be
   reproduced offline, retain that limit and define the smallest user-owned
   Retail observation before claiming a fix; do not manufacture an engine model
   that merely assumes the suspected result.

3. **Qualify one execution route outside the addon.** First investigate secure
   delegation to Blizzard's real follower zone button, since that preserves the
   native toggle handler. It is a candidate, not a selected safe solution:
   `SECURE_ACTIONS.click` checks access/forbidden scripted-input aspects, pooled
   buttons may be anonymous/reused, and a public callback cannot grant casting
   authority. Prove frame-reference lifetime, combat legality, click semantics
   and ConsolePort's data/secure representation before using it. If that route
   cannot be qualified, compare an existing supported native secure spell/macro
   route that supplies equivalent toggle behavior. Never call the native OnClick
   from a public event/timer, replace Blizzard's mixin globally, or dispatch both
   a spell and a click as fallbacks in one selection. An engine-only uncertainty
   may require a small reviewed Retail experiment before choosing the route.

4. **Prove presentation and selective hiding separately.** Use the qualified
   zone icon API and native override/tooltip behavior for matching ring widgets.
   Test later LAB updates, widget reuse and ring reopening so a later write
   cannot restore the generic icon. Prototype hiding only the identified
   follower button and its associated decoration/hit area; preserve other
   pooled zone buttons and ExtraActionBarFrame. Test actual native layout with
   follower alone, follower plus extra action, follower plus another zone ability,
   and unrelated abilities alone. Native frame ownership and protection decide
   the exact suppression mechanism. Do not hide a working fallback before the
   replacement route is ready; unknown identity/contract leaves it available.

5. **Reject old defects and check transitions before integration.** Negative
   controls must fail for the ordinary fixed spell icon, an execution route
   that reverses/duplicates a command, blanket shared-container hiding, stale
   pooled references, and temporary entries leaking into the manual archive.
   Cover entry/exit/re-entry, reload, native state changes, combat, held-wheel
   transitions, Edit Mode, late load, disabled/unready integration, manual edits,
   shared utility disable, other rings and GUID/spec changes. No player-bar slot
   writes, automatic spell placement, unrelated removal or retired ground logic.
   If a bad cast route is only distinguishable in Retail, label its offline
   negative-control limitation explicitly.

6. **Integrate the smallest qualified Forever change after plan review.**
   Candidate files are `Adapters/SharedUtility.lua` for admission coordination,
   `Rings/UtilityRuntime.lua` for guarded initialization/events, and a narrowly
   owned presentation/dispatch integration if needed. Actual prototype findings
   determine the final files. Keep native protected ownership; do not alter
   upstream addons, TOC order or module locations for cleanup. Preserve schema3,
   revision20 and shared archive semantics unless a demonstrated need changes
   the design. Register once, filter to public follower identity, coalesce public
   reconciliation, add no polling worker, avoid rebuilding every ring for icon
   changes, and retain immediate native cooldown/usability feedback. Defer
   protected reconfiguration while combat/held-wheel/editor guards require it.

7. **Run qualification, then perform scoped Retail acceptance.** After runtime
   implementation, run the meaningful new native regressions, existing utility,
   secure input, composed visual and performance gates, `./tools/Test-All.ps1`
   and documentation validation with complete exact-source inventories. Follow
   the normal tested-source commit/push, scoped packaging/preview/delivery and
   independent preservation readback only in the subsequent authorized stage.
   The first user-owned Retail test should start with the native fallback still
   available: select lead, wait beyond the native cooldown, select stop, repeat,
   compare artwork/tooltip and count follower responses. Then validate selective
   hiding with coexisting extra ability, exit/re-entry, reload and combat. Report
   only tested cases. Do not claim that offline green checks certify this bug.

The execution reproduction is retained as T91/T92 and the proxy-chain experiment
as T93/T94. Representation works, but borrowed-frame lifetime and entry
replacement remain unqualified. Preserve native authoritative entry identity in
any later admission experiment and resolve the remaining Retail command/event
observation before selecting the execution repair or changing addon code.
No additional preference or global ring rewrite is justified by this evidence.
The [extended admission/presentation/boundary experiments](../reference/FOLLOWER-DUNGEON-ADMISSION-BOUNDARIES-2026-10-16.md)
resolve saved identity and native LAB feedback separation and reject public
identity/cast authority shortcuts. They reach the Retail observation boundary
for actual release/command behavior. The original standalone control remains
available; no partial combat-disable route or speculative repair was deployed.
Fresh discovery found three unrelated dependency updates; these are recorded as
pending qualification, not folded into the experiment or installed.

## Documentation impact and completion criteria

The initial planning pass updates requirements, intended controller behavior,
state notes, known issues and navigation. The execution continuation adds the
testing map and a compatibility note for freshly discovered pending updates.
Installed status, runtime architecture, supported identities and release history
remain unchanged because no runtime contract or installed payload changed.
Implementation will reassess those pages against its actual scope, rather than
copying this plan's proposed architecture into current-runtime claims.

Completion requires the standalone follower control to be absent under the
qualified working ring route; sibling extra/zone abilities to remain usable;
native follower-state presentation to agree; repeated deliberate selections to
perform exactly the requested single toggle; and scoped source plus Retail
evidence. The implemented candidate is recorded separately above; this plan alone is not Retail acceptance.
