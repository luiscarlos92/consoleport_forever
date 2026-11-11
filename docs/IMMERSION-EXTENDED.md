# Immersion Extended (Forever)

Status: maintained
Reviewed: 2026-11-11
Evidence: [plan](reference/IMMERSION-EXTENDED-FOREVER-PLAN-2026-11-05.md),
[source parity](../evidence/immersion-extended/2026-11-05/native-source-parity.json),
[runtime](../addon/ImmersionExtended_Forever/ImmersionExtended_Forever.toc),
[safety tests](../tests/test_standalone_forever.py).

This standalone addon provides Pawn summary reward arrows, Pawn annotations in
the native reward inspector and the Required Items layout correction for WoW
Forever. Immersion owns native input and layout. Pawn owns scoring, options and
formatting. The extension is independent of bag addons and ConsolePort and
has no configuration, bindings or SavedVariables of its own.

Local qualification: 110 runtime/source checks and 86 tooling tests passed against complete 70 product / 167 tool-test inventories. [Receipt](../evidence/immersion-extended/2026-11-05/local-qualification.json). Installed November 5 at 02:39:37 Toronto; engine acceptance remains pending. [Fresh CI](../evidence/immersion-extended/2026-11-05/ci-verification.json), [artifact rehearsal](../evidence/immersion-extended/2026-11-05/artifact-dry-run.json), [delivery/readback](../evidence/immersion-extended/2026-11-05/delivery.json).

## Required Items event repair

Version 0.1.1 is installed while playing for the November 5 clipped progress panel.
[Delivery](../evidence/immersion-extended/2026-11-05/progress-event-script-delivery.json),
[readback](../evidence/immersion-extended/2026-11-05/progress-event-script-readback.json). Immersion
registers its event method in a separate script slot; the extension now uses
HookScript on that slot after native processing, preserving native ownership.
The regression fixture dispatches the captured script, and rejects the old hook.
[Qualification](../evidence/immersion-extended/2026-11-05/progress-event-script-qualification.json).

The user explicitly limits this repair to Forever Immersion tests. The existing
builder supports `--targeted-immersion-report scratch/test-results/diagnostic.json`
with `--standalone-forever`: both T109/T110 must pass against exact current
inventories; all changes outside this addon and its named qualification files
are rejected against the retained full baseline. This is scoped qualification,
not a fresh full-suite claim. Use `--allow-running-forever` for the authorized
code-only update while playing; no WTF or dependency writes.

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
Relevant item/equipment/spec/Pawn-reset events coalesce. Version 0.1.2
preserves a confirmed arrow while the same reward and comparison context await
a fresh Pawn result. The native Pawn advisor checkbox refreshes arrows while
the quest is open. A negative verdict, changed comparison context, hidden or
reused button, quest change, or close clears the owned arrow.

For native inspector item cards, the extension checks the active pool,
the current reward and the native item's references after Immersion populates
the tooltip. Pawn receives the full reward link and appends its own lines.
Delayed data gets bounded retries tied to the current card. Native padding and
comparison continue through Immersion. The read-only command
/immersionextended reports readiness and work counters.
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

T109 executes the addon with actual Immersion event, layout, inspector
population and comparison methods, plus Pawn's budget, verdict, checkbox and
tooltip formatting code. Geometry, C APIs, item statistics and Pawn startup
are modeled. Existing R16 suites retain actual Pawn arithmetic coverage.
T110 rejects faults including arrow flicker, stale comparison context, missed
checkbox changes, duplicate and stale tooltip annotations, bag coupling,
unbounded work, and wrong or early layout. Ten tooling tests cover client/scope
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
