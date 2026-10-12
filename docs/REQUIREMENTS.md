# Approved requirements and scope

Status: maintained
Reviewed: 2026-10-11
Evidence: [confirmed historical decisions](archive/ai-native-2026-10-11/MASTER-PLAN.pre-restructure.md),
[current status](IMPLEMENTATION-STATUS.md), [candidate.30 requirement](CANDIDATE30-PING-RELEASE-LIFECYCLE-2026-10-10.md).

This document owns intended behavior. Source activation is documented in
[architecture](ARCHITECTURE.md); [reference evidence](reference/EVIDENCE.md)
distinguishes Forever source, project decisions and runtime proof. A requested
feature may be approved in direction yet still deferred or gated.

## Current contracts

| ID | Approved requirement | Current implementation/evidence |
| --- | --- | --- |
| R01 | Personal Retail companion with Forever-inspired expanded controller HUD; preserve approved size/art/layout and native feedback. | HUDPresentation/Skin; retained candidate.17 acceptance and later feedback gates. |
| R02 | Four ordinary banks: Base, L2, R2, L2+R2. Only unmodified four face bindings shared; ordinary D-pad/modified actions character owned. | BindingPolicy, native binding adapters; [ownership decision](decisions/0003-character-state-and-manual-edits.md). |
| R03 | Vehicle, possession, quest override, skyriding and native temporary action families replace L2+R2 only; ordinary side/base banks remain. Ordinary class form/stealth changes do not introduce blanket custom replacement. | TemporaryRouting; [state matrix](STATE_MATRIX.md). |
| R04 | Preserve manual action edits/removals, native drag/drop, binding/ring ownership and native saved layouts. No automatic spell pickup/place/restoration. | Candidate.27 editing repair; passive ActionRecovery. |
| R05 | Ground placement remains enabled under accepted policy through the repaired independent native adapter; preserve manual/native fallback and context preferences. | Ground/Preferences; scoped Paladin/DH acceptance, T12/T42. |
| R06 | R3 sends nothing on down. Tap/empty release sends one contextual aimed ping; selected release sends one selected ping. Hold reveals a real native account ring; keep native selection/cancel/edit behavior. | Candidate.30 supersedes candidate.28 immediate-down requirement; T65 and user acceptance. |
| R07 | Class-appropriate access and ring content are character owned; preserve learned/manual entries and native routes. | ClassActions and ring projection; exact additional selector gestures remain gated. |
| R08 | Required Items correction belongs in Forever; preserve Immersion bytes/settings and native preferences. | Deferred native offset post-hooks; T66 and user acceptance. |
| R09 | Latest native saved Edit Mode layouts are authoritative. Capture active layout per GUID and owned managed account default without save/import/select during tracking; preserve existing Party/manual edits. | T67; broader live layout regression acceptance remains unclaimed. |
| R10 | Reviewed configuration runs in game with conflict review, before-state journals, guarded readback and recovery; disk installers do not edit live WTF. | Store/Plan/Transactions/Coordinator. |
| R11 | Native execution owns protected dispatch. Preserve recovery boundary and accepted working features when repairing another subsystem. | [native execution decision](decisions/0002-native-execution-and-proof.md). |
| R12 | Check official stable Retail dependencies for product/tooling sessions, qualify changed contracts and deliver only actual changed packages. Preparation is distinct from installation. | [delivery decision](decisions/0004-scoped-delivery.md); docs-only exemption in decision 0001. |
| R13 | October 11 Circle-only work: best qualified Retail cancellation without native Escape/Options; preserve native UI/ring and manual binding ownership. Scoped deployment later authorized with WoW closed. | Candidate.31 offers an explicitly reviewed empty Base PAD2 secure cancel-all command. Cast/ground/hard target cancel together; exact first-success parity remains gated. [Research and implementation](reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md). |

R04's action-slot preservation does not imply an unconditional no-add rule for
learned class rings: current class augmentation appends missing learned forms
and scoped migrations repair access. Generic ring capture preserves manual
entries/deletion, while augmentation is separate. R06's empty/neutral tap uses
the fallback; native selection is armed on down and can select on a deflected or
sticky early release before artwork appears. These source details are recorded
in [controller behavior](CONTROLLER_SPEC.md) and
[configuration](reference/RUNTIME-CONFIGURATION.md); no additional feature
authorization or widened Retail acceptance is inferred.

These are requirements, not a claim that every state, character or engine case
has been exercised. [Known issues](KNOWN_ISSUES.md) owns limitations and open reports.

## Approved directions with incomplete proof

Exact Forever stick-return activation/close-and-continue, one-success gameplay
Circle cancellation, active-entry cancellation, additional learned class/pet
selector activation, transient loot hold and held cinematic skip remain gated.
Custom popup/quantity/window/map controls have offline source coverage but are
suspended under native recovery. Text-entry changes remain deferred. Do not
replace an exact requested gesture with a superficially similar shortcut and
call it parity. See [controller specification](CONTROLLER_SPEC.md).

## Exclusions and supersession

- Public distribution, adaptive layouts/controllers/resolutions and a general
  product installer remain future evolution, not the current personal scope.
- The parked native UI reference is not an instruction to implement a feature.
- The candidate.29 Immersion options-list request was withdrawn; scrolling
  remains the user's accepted answer for that request.
- DBM, HideClassBars and SharedMedia_Causese are retired from the active lock.
  Preserved old keep rules do not authorize restoring them.
- The candidate.26 automatic restoration design and candidate.28 initial ping
  on down are superseded, even though their evidence is retained.
- Historical copy/cleanup/installation permissions are not ongoing permission.

## Maintenance

Update a requirement when the user approves, withdraws or supersedes behavior.
Keep stable IDs, link the decision/evidence and describe implications. Never
promote a hypothesis, test stub or research observation into approved intent.
