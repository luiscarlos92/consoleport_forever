# Retail acceptance: pending

This candidate is for the approved personal setup. All actual hardware input, secure combat, taint, appearance, native logout persistence and rollback acceptance remain pending. No WoW process was launched and no actual installation was performed during implementation. Offline Lua hosts execute Lua 5.3 semantics with independent Lua 5.1 parsing; source-contract tests are not Blizzard's secure engine.

The single acceptance checklist is H8 in `docs/MASTER-PLAN.md`. The identical checklist is reproduced below for the pack. On failure, capture its item number, `/cpf diagnose` output and precise class/spec/action/context for the later test session. `/cpf status` gives version, runtime readiness and pending reasons; `/cpf proof` displays the proof panel.

1. First login: install/update prompt once, current layout/profile/keyboard captured, decline leaves UI unchanged; accept applies only the reviewed plan; Reload now/later works. `/cpf status` names ready/pending features and exact dependency versions.
2. Four banks: current sizes/anchors/art/scales preserved, faces circular/D-pad unchanged; one ordinary arrangement; native spell slots/spec loadouts and keyboard bindings retained. Edit Mode open/move/save/revert/close works without taint and restores hidden strips correctly.
3. A→B→A with normal logout/reload: personal 28 cells/rings/migration status stay with each character; shared four faces remain shared; no previous character's abilities/config leak. Change spec and confirm native spell bars follow the existing native policy.
4. Skyriding ground/takeoff/landing/dismount, quest override, vehicle and possession: only L2R2 replaces/restores temporary actions; every other bank stays ordinary; exit and overflow access remain reachable. Test form→vehicle→form and Rogue stealth without bank takeover.
5. Circle: focused window/popup actions first, then cast/channel/reticle/target one success per press, idle no Game Menu. Record any pending exact mechanism honestly; combined cancellation is not an approved substitute.
6. Rings: existing utility/class opener behavior preserved, learned selectors and both-trigger pet opener correct; empty/invalid entry inert; current pet refresh; stick-return/close-and-continue/active-entry cancel only when capability is proved. A delayed opener release must never cast twice.
7. UI: windows/tabs/scroll/tooltips, nested popup buttons, quantity bounds, BetterBags pickup/use/equip/sell/context/cancel and eligible item tap/hold; disabled actions do nothing. UI focus hides/restores gameplay feedback and never leaks gameplay actions.
8. Map: pan/zoom/waypoint/Back and return to normal movement/camera; cinematic held skip only when allowed; reconnect/focus loss/mouse handoff do not leave held actions/modifiers stuck. Keyboard and ground aiming behavior remain unchanged.
9. Both mounts, extra action, quest/zone access, menu/zoom/autorun/ping remain usable. Check the reported Paladin grey-icon case against actual spell usability; capture spell/spec/target/resources and resolved action identity if it fails.
10. DynamicCam, Immersion/ExtraFade and other managed configurations persist; manual edits survive a later update with conflict review where needed. Test `/cpf restore` on the chosen backup and confirm code/config compatibility before treating rollback as accepted.

## Precise gates in this candidate

The following remain independent feature-local proof gates. Native working controls remain available. These pending behaviors must not be marked passed simply because the pack assembles or the other checklist behaviors work.

| Gate | Candidate behavior / required proof |
| --- | --- |
| Exact right-stick return and close-and-continue | Protected activation route unproved; retain native wheel gesture. No opener hold/release substitute. |
| One-success gameplay Circle | Exact cast/channel/reticle/target priority unproved; no combined cancellation macro. Focused UI/popup controls are separately implemented. |
| Active ring-entry cancellation | Separate protected proof; no combined cancellation fallback. |
| Learned class/aura selectors and new pet opener | Private reconciliation is prepared but inactive until exact ring execution is proved. Existing manual GUID ring entries/order and native extras are preserved. |
| Exact transient 0.5-second loot hold | Protected transient preference route unproved; native modified-click access retained. |
| Exact held cinematic skip | Eligibility is source-tested; protected held skip is unproved. Native confirmation/menu controls retained. |
| LiteMount second icon | No qualified current LM_B2 default. Existing explicit icon and both native actions/rules are preserved; LM_B1's guarded native icon field is reviewable. |
| Other scroll widgets | Only audited ScrollController/map callbacks extended; other native widget input is retained. |
| Rendering/native engine | All in-game secure/held/empowered input, combat/taint, Paladin color symptoms, bank geometry/masks/visibility and persistence remain actual Retail tests. |

Source-tested substitutes for the four historical ConsolePort patches live in the companion. BetterBags' formerly suppressed native integration notice is restored by clean upstream and disclosed. All historical Immersion files matched their packaged source. Current dependencies are unpatched; public redistribution permission is not implied by personal assembly.
