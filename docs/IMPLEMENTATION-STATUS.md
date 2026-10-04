# Implementation checkpoint — October 3, 2026

Implementation is underway and remains incomplete. Work is confined to `C:\Users\luisr\Dev\consoleport_forever`. Neither live WoW tree has been edited, installed into or launched. The user will request installation later. H0–H8 of MASTER-PLAN.md remain the authority.

## Retained baseline and repository

- Public remote: https://github.com/luiscarlos92/consoleport_forever.git, branch main. Untouched baseline `15a191ab06b6d4562d63761116ca2c248150c3cc` was pushed before implementation. Do not reset or overwrite it.
- Initial capture manifest: `reference/manifests/2026-10-03-initial.json`: 3,984 files, 186,510,461 bytes, 44 aliases recorded (42 character template links, two live executable-tree junctions). Copies are ordinary files. Source-before/source-after/destination hashes matched. References and historical harnesses remain immutable.
- No AGENTS.md applied to the inspected workspace or checkout. No subagents were used.
- Product source and all custom behavior belong to addon/ConsolePort_Forever. Third-party packages remain unmodified.

## Runtime foundation milestone

The TOC now loads the replacement modules, with the new bootstrap last. Old Layout/Bindings/Profile source files remain as migration evidence but are no longer loaded. Product version is explicitly `2.0.0-dev`; it is not an installable release claim.

- Core, Store schema 3, field Plan, durable Transactions, BindingPolicy, ModePolicy, scoped UI Ownership, Diagnostics, Capability and runtime Baseline are implemented. Unknown schemas/anonymous GUIDs/malformed store fields defer safely. Legacy backups are retained; shared flat character data does not confer acceptance on a new GUID.
- A readiness-driven coordinator and native StaticPopup review replace the legacy eager preset installer. Loading the addon does not change settings or bindings. Review captures current runtime layout, native keyboard/controller bindings, active Edit Mode and selected flat settings. Decline writes no configuration. Combat/Edit Mode postpone protected writes, and all reviewed fields are rechecked before an accepted queued plan can apply.
- BindingState journals character-set selection, target-bank snapshot, per-key intents and save side effects. It preserves keyboard keys and controller keys outside its explicit mask. Native SetBinding plus action context/readback is used; CPAPI.SetBinding is deliberately avoided because its success result/clearing behavior cannot provide these semantics.
- Four unmodified faces are shared; the other 28 main cells are GUID-owned. Existing retained routes survive. Previously accepted characters hydrate their own arrangement after identity changes; outgoing keyboard view is preserved. No native spell slots/spec/loadouts are rewritten.
- ConsolePort bridge is gated to audited 3.3.3 and actual RelaTable bar environment. Current geometry is adopted, not replayed from Reference.lua. Old automatic binding preset condition is proposed for explicit review. Supported Retail trigger CVars are proposed only when registered.
- Edit Mode clones the active runtime profile to an account managed copy, retains original profiles, checks capacity/name ownership and verifies combined preset/saved indices. Flat adapters retain table identity and unrelated fields. Immersion/ExtraFade currently adopt selected current values; full desired integration settings and DynamicCam managed-copy work remain.
- Backup restore now opens a review, including newer-edit conflicts with accept/keep decisions; it uses another independently retained transaction. Rollback rejects newer values and exposes recovery-required journals. `/cpf recover <id>` retries guarded compensation.
- Reload now/later is implemented. Same-session world entry cannot certify persistence; a fresh-session readback can. A failed/changed reload scope is diagnosed without automatic reset. Current bootstrap tests serialize saved state, parse it as data and reload the full actual TOC in a separate restricted VM.
- Skin/runtime retain original appearance/hidden menu behavior behind GUID acceptance. No new mode/action/UI protected integration is active yet.

## SecureModes and UI visual milestone

SecureModes now extends the actual current ConsolePort Group/LAB buttons and leaves Manager/Layers binding registration intact. It precompiles secure ordinary slot data independent of LAB's cosmetic maps, selects native vehicle/override/temporary pages only for the eight L2R2 cells, ignores form/stealth bonus paging for ordinary main-relative slots, retains native empowered attributes, and latches a held button through mode changes. Native header APIs execute/wrap the snippets. Rebinding, repeated setup, restoring native environments and deactivation have current-source contract coverage. Possession without one of those native action families remains pending; do not invent pet paging.

Activation is reviewed and gated by the current four native groups, audited helpers, and actual retained keyboard routes for VEHICLEEXIT and native actions 9–12. Missing routes leave the previous geometry/access surface intact and expose the reason. Layout proposal retains runtime positions/scale/editor data, removes only the known legacy vehicle/override hide clauses and the misspelled old Page after readiness. No constant global Pager and no ninth cell is introduced. CONFIG_REVISION is now 2. Combat/input/visual acceptance remains pending.

D29 FocusVisuals listens to native ordinary interface-cursor ownership, suppresses only gameplay icon/highlight regions, preserves geometry/art/radial feedback, and restores the latest native alpha after UI focus. Rebuilt regions and native cursor reacquisition are handled. This behavior requires accepted policy. `/cpf proof` opens an on-demand scrollable native panel with saved/effective bindings, Layers prefix/chord/claims, native resolved/displayed cells, held state, dependency readiness, journals and diagnostic pending reasons. No proof panel is created until requested. Offline checks do not certify rendered Retail results.

Fifteen Node/Lua suites now pass, in addition to three Python suites. Exact unmodified ConsolePort 3.3.3 contract files are committed in evidence/consoleport-contracts with its license, package/file hashes and capture tool. This keeps ordinary tests and CI independent of ignored download caches. Additional native restricted-frame, stack split, cinematic/movie and spellbook/pet/spell contracts are pinned under evidence/native. Latest tested hashes/results: evidence/test-results/secure-modes-and-focus.json.

## Validation and source contracts

`tools/Test-All.ps1` currently passes three Python tooling suites and thirteen Node/Lua suites: immutable capture, Lua 5.1 syntax, foundation/failure matrix, separate-VM ownership persistence, policy/owner sequences, binding readiness, actual coordinator/adapters, full TOC/bootstrap/new-session persistence, malicious data rejection and three historical baseline regressions. Historical regressions test copied old source separately, not the new product. Fengari has Lua 5.3 execution semantics, with independent Lua 5.1 syntax validation. No offline test proves Retail taint/combat input or appearance.

The last exact tested source hashes/results are committed in `evidence/test-results/runtime-foundations.json`. Native UI source is pinned to Gethe/wow-ui-source commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`, build 12.1.0 (69933), with provenance and SHA/blob verification in evidence/native. API signatures, secure handler whitelist, restricted exports, secure action dispatch, Edit Mode and StaticPopup behavior are checked against these sources. `tools/fetch_native_sources.py` fetches only declared pinned sources into the checkout.

Native secure handlers do not permit wrapping OnGamePadStick or OnKeyDown. Exact right-stick-return protected commit and one-success Circle are still technical gates. No combined cancellation macro or hold/release wheel substitute is authorized. Do not infer secure capability from unprotected callbacks.

## Dependencies and pack

Lock verification succeeds for 14 official stable GitHub packages: ConsolePort 3.3.3, BetterBags 0.5.14, Immersion 1.4.61, LiteMount 12.1.0-1, Masque 12.1.0, Plater-v656, DBM core 12.1.12 and seven installed historical content families. Exact identities/digests/TOCs/folder coverage live in dependencies/lock.json. Cache/unpacked/scratch/dist are ignored. `tools/Resolve-Dependencies.ps1` verifies pinned local bytes; `-Refresh` explicitly queries current official releases. Cache reuse requires independently retrieved upstream digest qualification.

Pack remains incomplete: DynamicCam, Immersion_ExtraFade, SharedMedia_Causese packaged distribution and HideClassBars source/package qualification remain unresolved. DBM core contains DBM-VPVEM 99e0c33 including sound media: verify/close its provenance ticket from this official package, without adding a duplicate folder owner. DBM families contain extra folders (including Party-Forever); retain installed native content coverage and justified closure only. Audit actual expected folders and exclusions before assembling.

Matching-old-package migration audit, license/notices, Build-Pack, guarded Install-Pack/Restore-Pack and fake-root/junction/failure simulations remain. No candidate ZIP exists.

## Continue next

1. Check account five-hour usage and Git status. Continue only in the isolated repo, without deployment or launching WoW. Commit/push coherent tested milestones on main.
2. SecureModes now has the native extension above. Continue integration/edge-case coverage, especially missing exit/overflow route handling, family transitions, held owner changes/disconnects and real-game taint/empowered proofs. These remain pending acceptance. Do not replace the global Pager with a constant page or infer possessed-pet paging.
3. Runtime reference contains an invalid temporary Page `overiidebar` and hides ordinary groups in special modes. Replace these only after the new extension is ready and review accepts its geometry proposal. It is not valid replacement data. L2R2 alone receives eight special cells; preserve overflow/native exit access and do not invent possessed-pet paging from ordinary bonuses.
4. Complete class/form/aura and pet learned discovery, actual ring suffix, optional profile/settings ownership and D22–D31 contextual UI adapters using supported native CP mechanisms. Exact unsupported gestures stay individually pending with baseline preserved. Add source contract/offline coverage for actual snippets and lifecycle, not only pure policy models. Native Input supports only two override tiers and its conflict hook reinstates existing owners: do not blindly install an independent competing high-priority UI owner. Held frontend mouse-up must not trigger a newly attached UI control.
5. Audit granular binding review and complete backup restore of both banks: rollback restores the target bank through its subjournal, but ordinary accepted backup restore currently only reconstructs the originally selected effective binding view. Preserve newer edits and expose a review for target-bank changes too; never read another bank by changing selection before user acceptance.
6. Resolve dependency/package coverage, audit old patches, build reproducible local candidate pack plus guarded fake-root-tested scripts, receipt/hash and consolidated user acceptance checklist. Keep genuine game/secure/controller/visual tests pending.
7. Pause this same heartbeat when all authorized build-only implementation and candidate delivery are complete. Do not call the candidate complete or installable prematurely.

## Usage and continuation

This is the second run, awakened by same-chat heartbeat `continue-consoleport-forever-implementation` (thread `01a103b2-8a16-7931-9f91-938f0f07569b`). Most recent five-hour usage: 15% used / 85% remaining; reset Unix 1791086666. Continue monitoring frequently.

When approaching 10% remaining, the last substantive action must update this same heartbeat for five minutes after the next reported five-hour reset. Then save a complete graceful handoff, commit/push it and end cleanly. Preserve all instructions across runs, do not create duplicate automation, and do not consume the available reset credit. The old one-shot wakeup has fired; do not rely on it to repeat without explicitly updating it at the next cutoff.
