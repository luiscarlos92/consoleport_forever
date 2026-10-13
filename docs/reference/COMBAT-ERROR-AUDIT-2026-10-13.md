# Combat error audit and passive-observer repair

Status: maintained
Reviewed: 2026-10-13
Evidence: [captured diagnosis](../../evidence/runtime-errors/diagnosis-2026-10-13.json),
[old observer](../../evidence/runtime-errors/ActionRecovery-candidate36.lua),
[regression runner](../../tools/test-all.cjs).

## Established failure and limits

The user reported the large-number-of-errors popup in ordinary combat and the
login chat warning “Interface action failed because of an AddOn.” They requested
log analysis, broad impact review, repair and deployment, then explicitly declined
a reproduction procedure. No game input or live WTF modification is authorized.

The captured General.log contains **1,020 instances of one Lua error** between
raw log times October 12 23:42:34.795 and 23:59:41.929. These clock values are not
converted to host/server time. The error is Blizzard ActionButton.lua:847 rejecting
secret arguments to `SetCooldown` during tainted execution. Line866 is the charge
cooldown branch. Stacks include the native controller's world-entry reset and
action-button event dispatch during gameplay. This establishes the failing sink,
not the original taint writer or the affected button identity. No taint.log or
saved BugGrabber/BugSack error store was found. The last saved Forever diagnostic
record identifies candidate.36 but contains no blocked entries; saved files are
not a live engine snapshot.

The reviewed [native ActionButton source](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua)
matches the logged line numbers. The
[template](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml)
shows ConsolePort LAB uses BaseActionButtonMixin rather than the stock
ActionBarActionButtonMixin registration. Forever's face skin changes composition;
it does not invoke the failing numeric cooldown setter. Native LAB's qualified
Retail cooldown pipeline uses duration objects. T55 continues covering that path.

An [upstream ConsolePort report](https://github.com/seblindfors/ConsolePort/issues/182)
contains the same error family. The maintainer rejected a proposed lifecycle rewrite
in [PR217](https://github.com/seblindfors/ConsolePort/pull/217): native C hide/parent
cascades preserve handler security, and neither those calls nor attribute writes
establish the proposed taint chain. That discussion concerns other versions and
does not diagnose this session. We therefore retain accepted visibility/parent
behavior, native events and cooldown ownership. No dispatcher purge, alpha-only
bar rewrite, global cooldown replacement or error suppression is introduced.

## Impact review

Starting source is d99c942, whose product bytes match the installed candidate.36
qualification. Candidate.35 introduced incremental diagnostic copies, immediate
per-slot visuals, coalesced skin/visibility workers, scoped bootstrap event domains
and optional timing. Candidate.36 removed four placement modules and their callers;
temporary routing's native LAB header owner remains independently initialized.

| Area reviewed | Source finding / consequence |
| --- | --- |
| TOC, retirement, setup/store/journals | Retired placement modules/tab/registry/setup field are absent. Legacy data remain inert; no deleted-module call was found. T12/T38/T42 retain negative controls. |
| Event domains and combat transitions | Full readiness/spec/binding/layout/recovery fallback remains. Ordinary visual feedback stays immediate; protected setup defers. T74/T75 and native dispatch gates remain required. |
| Native bars/class row | Parent ownership/foreign-frame/Edit Mode guards retained. C parent changes alone are not a demonstrated taint write; no speculative rewrite. |
| Skin/HUD/focus | Scoped CP cosmetic regions, native duration cooldowns and resource UI retained. No stock numeric cooldown setter replacement or direct stock `.action` field write found. |
| Temporary routes/overflow/editing | Qualified native compiler, header/pager, held-release and ordinary-edit restoration remain. No new routing repair is selected without an identified failed contract. T61 retains 4,160 scenarios. |
| Circle/ping | Native MACRO/secure ring ownership retained. Existing bounded public logging and inactive fallback remain; no protected action is authorized by a public timer. |
| Dormant UI/context replacement | Native recovery still suppresses full takeover; native combat handoff coverage retained. Disabled helper tests are not evidence of active product behavior. |
| Optional integrations/persistence | Existing native profiles/layouts/bindings/manual edits remain owned and unchanged. Fresh official stable inspection found no changed package among all nine sources. |
| Passive action observer | Demonstrated unsafe read forwarding/persistence and uncaught unavailable reads; repaired below. No action-slot writer is restored. |
| Blocked-action diagnostics | Demonstrated attribution filter discarded events unless blamed addon was Forever; repaired below. Empty old logs cannot exonerate other integration paths. |

## Demonstrated repairs

The passive ActionRecovery observer previously forwarded an opaque specialization
index into another API, performed arithmetic/formatting using unchecked reads,
and could retain an opaque temporary-state value. Its unprotected API queries could
also throw out of an observation callback. Candidate.37 checks query success and
secrecy before forwarding, comparison or storage, rejects invalid numeric slot
identities, and leaves unknown facts absent. It preserves known `false` flags,
working/saved loadout separation, explicit manual edits and the 40-row bound.
The compatibility refresh remains read-only toward action slots.

The bootstrap already registered blocked/forbidden events, but logged only
`ConsolePort_Forever` attribution. Candidate.37 records all attributions in
`lastRuntimeDiagnostics.blocked`, with a total counter and at most 16 distinct
event/addon/function aggregates. Repeats increment counts rather than append
identical chat/history rows. When an event identifies a frame, the observer queries
`issecurevariable` for six relevant field labels without reading their values.
The reported addon remains attribution, not a claim of original responsibility.
Data are detached and scoped to the current record; opaque payloads become unknown.
No error-handler replacement, logging CVar change, automatic chat spam, protected
dispatch or game action occurs. Ordinary Lua errors do not necessarily emit these
events, so this is additional evidence rather than a full error collector.

Neither repaired observer defect is established as the cause of the 1,020 native
cooldown failures. K05 stays open after code delivery until normal gameplay
provides evidence. The user need not reproduce a prescribed sequence or run a
diagnose command for the new blocked-event evidence to persist through normal
game saving. Disappearance of a rare error alone is not a causal proof.

## Verification and delivery boundary

T77 executes the actual observer against opaque and failing reads; the retained
candidate.36 observer fails by forwarding an opaque specialization. A separate
negative control leaks an opaque temporary flag and is rejected. T64 continues
checking manual/loadout evidence and the permanent absence of slot restoration.
T78 executes real bootstrap/event/persistence, aggregates 1,000 foreign-attributed
blocked events, checks read-only security-label inspection, bounds, detached
snapshots, opaque payloads and GUID-owner changes. Reinstating the old attribution
filter fails. A separate full-snapshot owner-isolation negative control rejects
copying the prior character's rows before any new blocked event. These modeled
APIs do not establish Retail engine taint behavior.

Final local qualification passes all 78 runtime/source checks and 66 tooling
tests with complete current product/tool/test inventories. The retained candidate.36
baseline has 76/66 passing checks for its source; T77/T78 add defect controls.
[Exact receipts](../../evidence/test-results/candidate37-errors-qualification.json).

Only four product files change: ActionRecovery.lua, Diagnostics.lua, the bootstrap
blocked-event call and TOC version. Source placement, load order, schema3 and
configuration revision20 remain unchanged. Full source/tool/fixture inventories,
required gates, pushed source, scoped packaging and independent preservation
readback are required before installation. Current installed status and exact
receipts belong in [implementation status](../IMPLEMENTATION-STATUS.md).

The qualified Forever-only package was installed October 13 at 00:58:18 Toronto
from pushed source `4146195e5b126c6e4e1a606d21512e1e7ee8b26f`. Its SHA256 is
`7d0b14c80ce7884240248cba29cedbc76f7765c6d535561b235cb67f6ba30aae`.
Independent readback verifies 55 installed files/four changed product files,
2,252 unselected addon files, 310 WTF files, 42 links/root anchors and all 24,353
prior backup files. The game's 67 intervening WTF changes were preserved; no
direct WTF/dependency writes or game input occurred. WoW was closed. The user
loads the update by next login or reload; no revision20 setup review is required.
[Install](../../evidence/delivery/live-install-candidate37.json),
[readback](../../evidence/delivery/candidate37-independent-readback.json).
K05 remains unresolved at delivery: these are tested observer repairs and
installed-code proof, not Retail cooldown/taint acceptance.
