# Immersion Extended (Forever)

Status: maintained
Reviewed: 2026-11-05
Evidence: [plan](reference/IMMERSION-EXTENDED-FOREVER-PLAN-2026-11-05.md),
[source parity](../evidence/immersion-extended/2026-11-05/native-source-parity.json),
[runtime](../addon/ImmersionExtended_Forever/ImmersionExtended_Forever.toc),
[safety tests](../tests/test_standalone_forever.py).

This separate personal addon implements Pawn summary reward arrows and the
Required Items layout correction for WoW Forever. Qualification and installation
are recorded separately; implementation alone is not game acceptance. It has no
ConsolePort dependency, configuration, bindings or SavedVariables. Retail remains
separate and unchanged.

Local qualification: 110 runtime/source checks and 86 tooling tests passed against complete 70 product / 167 tool-test inventories. [Receipt](../evidence/immersion-extended/2026-11-05/local-qualification.json). Installation and engine acceptance remain pending.

## Behavior

After native measurement, a valid visible Required Items panel's height plus 48,
multiplied by native element scale, is passed to TalkBox:SetExtraOffset. Resting
positions/scales and saved preferences remain untouched. Top anchors, nameplate
mode, disabled offsets, unsupported contracts, combat and Edit Mode retain native
behavior. Queued work coalesces and cancels on quest/owner/dialog change.
Re-evaluation occurs after combat/Edit Mode ends.

Once Pawn's real initialization completion is observed, current visible quest
item rewards/choices receive the native green arrow when Pawn's public budgeted
verdict is true. Pawn's quest-advisor preference, scales, level checks and scoring
remain authoritative. Nil results retry at most eight times per population.
Relevant item/equipment/spec/Pawn-reset events coalesce. Foreign/reused/hidden
buttons, stale quests and unknown/secret identities cannot receive arrows.
Close cancels pending work. BetterBags is independent of this feature.

The first scope is summary arrows and Required Items layout. Clicks, native focus,
controller navigation, ordinary positioning and focused tooltip notes stay native.
The read-only command /immersionextended reports readiness and work counters.
If loaded after Pawn initialization was missed, reload to observe startup.

## Client and delivery

The TOC declares interface 16001, game type camelot, required Immersion and optional
Pawn. A runtime gate prevents initialization on other clients. Version/hash pins
identify tested sources, never runtime admission. Matching Forever native UI uses
the same camelot declaration. Installed input parity required only BOM/newline
normalization.

Existing entry points provide an explicit separate route:

    python -B tools/build_update.py --standalone-forever
    python -B tools/deploy_update.py --forever-root '<verified _forever_ root>' --pack '<artifact>' --sha256 '<checksum>' --backup-root '<retained backup root>' --user-install

The second command previews; --execute applies the user-authorized installation.
Only ImmersionExtended_Forever may be included. Retail, dependency replacements,
retirements, aliases, unsafe paths, wrong checksums and running WoW are refused.
Default Retail companion build/deploy selection and guards remain. New-addon
discovery/default enablement is declarative: no AddOns.txt/WTF write is performed.
Confirm actual discovery/enablement at the next user-owned launch.

Full exact-current source/tooling reports and clean tested source pushed on main
remain required. The standalone manifest carries its client contract instead of
claiming the companion store schema. Verify prior addons, WTF, links and backups
before/after installation.

## Tests and proof limits

T109 executes the addon with actual Immersion event/layout/button methods and
Pawn's public budget wrapper/verdict function. Geometry, C APIs, item statistics
and Pawn's completion boundary are modeled; existing R16 suites retain actual
Pawn arithmetic coverage. Cases cover optional-addon absence, preferences,
readiness, delayed items, reuse/close, secrecy, compatible unknown versions,
layout timing/scale/anchor guards, combat/Edit Mode and bounded event work.
T110 rejects ten faults targeting readiness, BetterBags coupling, stale arrows,
unbounded work and wrong/early layout. Ten tooling tests cover client/scope
admission, preview, checksums, aliases, install/update interruption/rollback and
newer WTF preservation.

Run ./tools/Test-All.ps1 before packaging. Offline Lua 5.3 execution and separate
Lua 5.1 syntax checks do not prove engine taint, pixels, protected authority,
controller timing or actual gameplay persistence.

After launch, check upgraded/non-upgraded rewards, choices, delayed item data and
close/reopen; Required Items across quests; ordinary gossip/reward layout; anchor
preferences; combat/Edit Mode; native controller focus and a cold restart.
Rollback parks only this addon or restores its previous code. No saved-setting
or progress restore is needed because the addon writes no SavedVariables.
