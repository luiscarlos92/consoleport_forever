# Runtime state and coverage matrix

Status: maintained
Reviewed: 2026-10-16
Evidence: [routing](../addon/ConsolePort_Forever/TemporaryRouting.lua),
[mode policy](../addon/ConsolePort_Forever/ModePolicy.lua),
[bootstrap](../addon/ConsolePort_Forever/ConsolePort_Forever.lua),
[test runner](../tools/test-all.cjs).

Candidate.39 is installed with shared default utility choice projection and an
independent persistent disable. Candidate.38's bounded automatic native-action
transition/first blocked-call stacks and candidate.37's observer hardening remain.
Candidate.36's ground-placement and Targeting-panel
retirement remain. Native controller/routing contracts remain; old targeting preferences
are inert. Circle cast interruption was user-confirmed on candidate.34. Performance
and broader Retail acceptance remain open, including the K05 cooldown taint origin.
Ground-reticle cancellation
was previously untested because targeting interception prevented that case.
Activation requires explicit review; other states are not individually asserted.
[Acceptance](../evidence/circle/candidate34-live-acceptance-2026-10-12.json).
It does not claim blanket Retail acceptance. [Requirements](REQUIREMENTS.md) owns intended behavior;
[testing](TESTING.md) explains what offline coverage can establish.

## Context transitions

Follower-dungeon entry/exit, native follower-state changes, coexistence with extra
and other zone abilities, held-ring transitions, combat and pooled-button reuse
are candidate.40 cases under R15/K06. Native name dispatch is precompiled outside
protected-write guards; public icon events never cast or rebuild rings. Only
the identified unprotected follower child is suppressed. Unknown state, disable,
editor, owner loss and pool reuse restore owned visibility, deferring protected
restoration until combat ends. Actual Retail toggle/rendering acceptance remains
pending; see the [candidate.40 runtime](reference/FOLLOWER-DUNGEON-RUNTIME-2026-10-16.md).

Candidate.39 adds shared default utility choice projection after public/native
readiness, with first eligible activation and persistent independent disable.
Automatic changes defer across held wheels/combat/editor/review/setup; qualified
native explicit editing stays immediate. Unknown context/foreign owners cannot
publish. Logout retains the account master and saves a harmless native seed;
disabled reload installs no utility work. Other rings/input retain their existing
scope. [Cases and limits](reference/SHARED-UTILITY-RING-RUNTIME-2026-10-14.md).

| Context | Base/L2/R2 | L2R2 / action owner | Other constraints | Evidence |
| --- | --- | --- | --- | --- |
| Ordinary gameplay | Native saved commands/actions. | Ordinary model. | Accepted character configuration and native readiness required. | T41/T42/T61/T62. |
| Ordinary class forms/stances/stealth | Native ordinary/bonus pages; no blanket custom bank replacement. | Ordinary class model unless native temporary evidence independently qualifies. | Appearance/form name alone is not takeover evidence. | T61; ModePolicy/TemporaryRouting. |
| Skyriding/dragonriding | Ordinary models retained. | Native temporary page on L2R2 when family/page evidence qualifies. | Mounted/flying/ordinary bonus appearance alone does not qualify takeover or overflow. Held release resolves current page; no spell-slot restoration. | T61/T62/T64. |
| Vehicle UI | Ordinary models retained. | Qualified native temporary contents on L2R2. | Native seat/exit/overflow routes retained; unavailable drops rejected. | T61; temporary native drag tests. |
| Possession | Ordinary models retained. | Native family/page evidence on L2R2. | Restore ordinary dispatch after release/transition. | T61/T62. |
| Quest override | Ordinary models retained. | Native override/high-page evidence on L2R2. | Stale headers cannot persist after authoritative normal return. | T61; candidate.26/27 source regressions. |
| Temporary shapeshift/unflagged high page | Ordinary models retained. | Native temporary/high-page evidence where qualified. | Distinguish from ordinary class bonus pages 1–4. | T61. |
| Native UI/modal focus | Native priority can supersede visible controls. | Full custom UI acquisition suspended. | Native claim relinquishment bridge retained; foreign claims preserved. | T41. |
| UI to combat | Native gameplay dispatch restored. | Native action handler, all 32 chords. | Release held UI ownership; defer ordinary configuration writes. | T41/T42. |
| Edit Mode | Native editor owns layout. | Main reviewed/protected setup and saved-layout tracking defer. | Release owned visibility/class presentation. Ground preferences are retired; ping refresh has a combat guard rather than the shared Edit Mode guard. | T31/T34/T46/T67; source-specific guards. |
| Drag/remove/rebind | Native editing owns action slots and commands. | Temporary cache/latch cleared as needed; unchanged declarations not replayed. | Unavailable temporary cells do not consume drops into permanent bindings. | T61/T64. |
| Reload/login/character switch | GUID archive projected only after readiness/acceptance. | Account base faces and personal modified/D-pad models separated. | Interrupted journal recovery and manual-edit conflicts retained. | T05/T59/T63; coordinator/binding tests. |
| Pet battle/foreign owner/unknown contract | Native conditions and safe fallback. | Do not force custom claims over another owner. | Do not infer all behavior from a single visible frame. | Applicable native ownership guards; broader Retail cases pending. |

## Class scope

| Scope | Current behavior | Coverage / limit |
| --- | --- | --- |
| All 13 Retail class tokens modeled by T61 | Temporary native-family routing and four-bank dispatch share the same policy. | 4,160 offline cases; not 13-class live acceptance. |
| Paladin | Qualified learned aura access, L1+L2, personal class ring. | T43/T47/T58; no cross-GUID aura leakage. |
| Druid | Qualified forms/class access, L1+L2. Ordinary class pages remain native. | Discovery/class tests and T61; additional exact selector gestures gated. |
| Warrior | Qualified class access, R1+R2. | Class chord/badge tests; live exhaustive stance coverage unclaimed. |
| Other classes/pets | Retain native/manual routes; generic class proposal uses qualified learned data and right-side chord fallback. Later selector preview stays inactive. | ClassActions.Supported gates revision-17 repair/native row suppression for three classes, not every generic proposal; no universal aura claim. |

## Configuration versus runtime state

| Stored/observed state | Actual consequence |
| --- | --- |
| `appliedRevision > 0` | Installed-character predicate; still requires feature-specific acceptance, policy and probes. |
| `modesEnabled=true` under native recovery | Full installer remains disabled. TemporaryRouting uses installed-character readiness independently. |
| Legacy ground-placement preferences/policy/history | Inert; no Targeting tab, placement interception or recreation of preference tables. Historical saved data remain. |
| UI/window/bag/map/hidden flags true under recovery | Custom acquisition/full hidden replacement remain disabled; focus cosmetics retain a separate path; ground-placement preferences are retired. |
| `ringAccepted` plus complete qualified class ring/opener | Independent native StanceBar suppression possible; not native power suppression. |
| Missing/unowned Immersion repair field, eligible installed character | One journaled policy initialization; existing owned disable/restore is preserved. |
| Legacy class revision or unmarked supported revision-17 repair | Narrow accepted binding/ring migration with journal and reload verification, not full setup replay. |
| Interrupted bank selection or applying journal | Main refresh pauses normal hydration; explicit guarded recovery is required. |
| Native saved layout changed | Read-only capture after eligible refresh/Edit Mode close; no tracking selection/save. |
| Passive action/visual/ping event | Saved diagnostic evidence may change; no spell pickup/place restoration. |
| Retained legacy Circle frame prepared | Inert until the reviewed unique account CPF Circle macro exists and legacy native click command is bound. Current native MACRO binding bypasses this helper. No RunMacroText fallback; readiness is not live proof. |
| Reviewed Circle command on Base PAD2 | Native MACRO cancel-all with engine-owned timing; no Escape/menu. Native UI/ring claims supersede Base; modified action routes stay ordinary. Candidate.34 cast interruption is accepted for the reported case; ground cancellation untested. |
| Older accepted character under revision20 source | Automatic login update review, deferred in combat/Edit Mode; accepted features remain active and review does not write settings. |
| Manual Circle command / later empty | Preserve command/removal. Circle proposal is only in explicit review, never ordinary hydration. |
| Saved Circle macro edited/deleted/duplicated | Synchronous revalidation reports pending. Native MACRO edits retain engine semantics; legacy helper can disable its type. No automatic recreation, rebinding or overwrite. |

Native readiness, saved state, effective engine ownership and Retail acceptance
are independent axes. [Architecture](ARCHITECTURE.md#native-execution-and-refresh)
lists actual activation gates; [configuration](reference/RUNTIME-CONFIGURATION.md)
documents persistent fields and recovery commands.

## Acceptance and observations still needed

The [cumulative checklist](NEXT-DEPLOYMENT-CHECKLIST.md) covers ring repetition,
account edits, other-ring reuse, Required Items preferences, saved-layout changes
and ordinary/temporary editing smoke tests. The reported ring/Required Items
defects are accepted; individual broader cases remain unclaimed.

The [quest interaction report](TEMPORARY-MAIN-BANK-ANALYSIS-2026-10-11.md)
needs effective native binding/target observation on recurrence. Its added
offline main-command probe is retained separately from T61's action-slot model.

Update rows when a transition, class rule or activation gate changes. Link both
the regression and any scoped live result; preserve unknowns explicitly.
