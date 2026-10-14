# Combat error audit and passive-observer repair

Status: maintained
Reviewed: 2026-10-14
Evidence: [captured diagnosis](../../evidence/runtime-errors/diagnosis-2026-10-13.json),
[candidate.37 recurrence](../../evidence/runtime-errors/recurrence-2026-10-13.json),
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
secret arguments to `SetCooldown` during tainted execution. Line866 is the normal
cooldown branch. The initial diagnosis incorrectly called it the charge branch;
this maintained report corrects that label without rewriting the old evidence.
Stacks include the native controller's world-entry reset and
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

## Candidate.37 combat recurrence

The user reports the warning recurring during ordinary combat on October 13.
The [new read-only capture](../../evidence/runtime-errors/recurrence-2026-10-13.json)
identifies candidate.37 and another 1,020 native `SetCooldown` failures between
raw log times 21:42:40.569 and 22:17:39.309. These are captured occurrences;
the snapshot is not asserted to be the complete number of engine failures. A
later flushed log contains 1,050 cooldown failures, so no fixed 1,020 reporting
cap is inferred. Both the ordinary
cooldown and charge branches occur in this capture.

| Native stack route | Captured occurrences |
| --- | --- |
| Shared button dispatcher -> cooldown event -> normal setter | 869 |
| Keyed action dispatcher -> `SPELL_UPDATE_ICON` -> full update -> normal setter | 85 |
| Shared button dispatcher -> slot change -> `UpdateAction(true)` -> charge setter | 33 |
| Shared button dispatcher -> cooldown event -> charge setter | 29 |
| Native action-bar controller reset -> `UpdateAction` -> normal setter | 2 |
| Shared button dispatcher -> slot change -> `UpdateAction(true)` -> normal setter | 2 |

The saved blocked-event observer counted **926 events**, retaining at most 16
distinct aggregates. Retained observations mark stock `ActionButton6` through
`ActionButton12` and `OverrideActionBarButton4` Lua `action` fields insecure,
with writer attribution **ConsolePort_Bar**. Their inspected `OnEvent`,
`UpdateAction`, `eventsRegistered`, `needsUpdate` and `popupDirection` fields
remain secure. The container rows are distinct objects; a secure absent `action`
field on a container does not exonerate its button. A blocked
`MultiBarBottomRightButton7:SetAttribute` observation has `action` marked secure,
so this one tainted field does not explain every blocked event.

These are materially stronger observations than the initial capture. Stock
`UpdateAction` assigns `self.action`; native update/cooldown and press-and-hold
paths subsequently read it. Reading an already tainted field provides a source-
supported route into the failing secret cooldown setter and blocked attribute
updates. Combat makes the secret-value failure observable; it need not be where
the initial contamination occurred. This is a consistent propagation mechanism,
not a captured first-write chain or a one-to-one correlation between the two logs.
The rows are saved observations, not the live engine state, and evicted aggregates
cannot reconstruct the full 926-event sequence.

The deeper source review checked these specific alternatives:

- All **303 installed ConsolePort Lua/XML/TOC files** match the qualified 3.3.10
  unpacked source byte-for-byte; no mixed/modified installation was found.
- CP_Bar's assisted-combat manager clones functions into a new table, supplies
  private candidate tables and an addon-local action-change callback registry.
  Its explicit public `UpdateAction(true)` ticker is a candidate only if a stock
  button can enter it. The reviewed callers enumerate CP LAB buttons or emit
  their own button as the callback argument; no such stock-button ingress was
  established. Cloning is not evidence of mutating the global native manager.
- Native CallbackRegistry uses `secureexecuterange` and `securecallfunction` for
  callbacks. A plain mock callback loop would misrepresent that boundary.
- CP_Bar hides native bars/buttons and removes keyed dispatcher entries, while
  Blizzard's separate array dispatcher remains active. This explains why a
  hidden stock button can still receive cooldown events; it does not establish
  how its Lua field became tainted. Native C hide/parent/attribute calls and nil
  dispatcher removal remain rejected as standalone causal explanations.
- The native interface cursor has script substitution for action-button hover,
  avoiding the native hover method's forced `UpdateAction`. This is a plausible
  area for a first-write trace, not proof of a failure in that substitution.
- No source path was found that makes the retired ground-placement adapter,
  Forever face skin, or temporary-route wrappers the original stock `.action`
  writer. Permanent retirement stays intact.

Two other General.log errors are separate: BetterBagsItemButton62 reaches native
tooltip anchoring with `GetRight()` returning nil, then native ContainerFrame
compares it with half the screen width. These two occurrences do not explain the
1,020 cooldown failures. The capture supplies no Forever caller for this tooltip
failure; no upstream tooltip patch is selected.

No taint.log was present. The missing evidence is the engine stack for the first
ConsolePort_Bar-attributed stock action-field contamination, before its later
native reads spread it. If the user elects to capture this, enabling
`/console taintLog 2` followed by a user-owned reload before ordinary play is
sufficient preparation; no special combat reproduction is prescribed. After the
next warning, `/console taintLog 0` stops capture. Direct live WTF edits and game
input by the agent remain prohibited. Repeating field snapshots alone will not
identify the first write.

That first recurrence review changed evidence/guidance only and selected no
runtime repair. The following later user instruction expands the investigation.

## Silent taint capture and automatic trace

The user enabled logging but saw no response and requested another investigation
method. Logging had silently produced a 62,801,321-byte file spanning raw times
22:48:00.708 through 23:06:56.251. The
[limited captured evidence](../../evidence/runtime-errors/taint-capture-2026-10-13.json)
retains the exact hash and first relevant stack, not the full private log.
At 23:02:07.862, ConsolePort cursor `ExecuteScript`/`OnEnterNode` calls native
ProfessionsBook.lua:158, whose `ClearOnBarHighlightMarks` replaces the global
`ON_BAR_HIGHLIGHT_MARKS` under ConsolePort taint. The capture includes 62,713 later
reads of that global through native `GetOnBarHighlightMark`.

This is a demonstrated contamination path, but native reads use
`securecallfunction`; the trace does not establish escape from that boundary.
It contains no ConsolePort_Bar attribution, stock `action`-field write or protected
block. It therefore does not identify the earlier combat error's first writer.
No professions hover, tooltip or native highlight behavior is removed on that
assumption. Enabling logging is not expected to print an activation message.

Candidate.38 adds an alternative collection path: automatic posthooks on matching
native `UpdateAction` methods for at most 102 existing stock buttons after store
initialization outside combat. They query `issecurevariable` labels, never action
values, and record initial contamination separately from later observed
clean-to-tainted changes. At most 16 observations/four initial snapshots retain
public writer labels and stacks of at most 3072 characters. Clean/repeated tainted
observations collect no stack; saturation stops inspections. First blocked-event
aggregates also retain bounded stacks. An independent `blocked.firstStacks`
list keeps the first 16 attempts even after rolling rows are evicted, without
recapturing stacks indefinitely during an error flood. Missing stack reads also
consume their attempt. No error handler, CVar, native script,
action value, cooldown setter or input route is replaced or invoked.

Posthooks run after completed calls and cannot recover a prior write, a failing
call's unfinished stack, or an intermediate contamination that is cleared before
return. Their caller is an observation point rather than certified original
responsibility. T79 tests actual bootstrap/persistence with explicit C security/
posthook/stack doubles; missing registration and cross-GUID leakage must fail.
T78 additionally verifies a first blocked stack is captured once for 1,000 repeated
events, then more distinct functions than the aggregate capacity: first callers
remain and total stack attempts stay bounded. Removing the work bound fails.
These are collection-mechanics tests, not reproduced Retail taint.

Fresh dependency discovery found official LiteMount 12.1.5-1. The
[selective qualification](../../evidence/dependencies/litemount-12.1.5-1-qualification.json)
compares all 115 files: no additions/removals and only TOC/version, changelog and
bundled numeric rarity data/timestamps change. Native integration and notices
remain identical; T13 retains old versions and covers the new adapter identity.
This update is unrelated to the combat diagnosis. All nine official stable
identities are freshly checked. A later independent disk comparison verifies all
115 new LiteMount files were already present in the pre-deployment snapshot.
This investigation therefore replaces no LiteMount files; disk state does not
certify currently loaded engine metadata. Old/new adapter identities are both
covered, and only Forever is selected through the qualified running-game route.
There is no Retail combat-error resolution claim at this preparation stage.

The [later logging-window capture](../../evidence/runtime-errors/logging-window-2026-10-13.json)
also contains 226 nil-call errors beginning in the 22:48 reload window, including
native nameplate/class bar, casting alpha and tooltip methods. Many faulting
methods have existing addon posthooks. A
[first-person Blizzard forum report](https://us.forums.blizzard.com/en/wow/t/wow-forever-gamepad-ui-bugs-build-160170170/2370253)
describes engine taint logging breaking C posthooks with this error on a different
Forever client build. This is a Retail hypothesis supported by timing/pattern,
not confirmed causality and not the earlier cooldown cause. The user reports
logging off and WoW open. No further engine logging is requested. Candidate.38
installs its optional diagnostic hooks only when `taintLog` is known zero and
never changes that CVar. Existing installed hooks require a user-owned reload
to reset; the diagnostic cannot repair a broken engine posthook mechanism.

Candidate.38 local qualification passes all 79 runtime/source checks and 66
tooling tests with complete matching current inventories. Four product files
change and 54 remain unchanged; schema3/configuration revision20 remain intact.
[Exact reports](../../evidence/test-results/candidate38-trace-qualification.json).
This qualifies diagnostic collection and old/new LiteMount adapter identities,
not a Retail taint repair. Only Forever is selected for the urgent update.
The initial candidate.38 source `c820f0b` was installed during this investigation
before the final stack-work bound was added. Its artifact, tested-source reports,
install and independent readback are retained under the `candidate38-initial`
evidence names. The final qualification includes eviction pressure and independent
retention of the first stacks; it supersedes that initial source. No activation
or gameplay acceptance is inferred from either file installation.

The final bounded build was installed October 14 at 00:02:27 Toronto from pushed
source `b89fa7dfa2d5837235a97e6ef411783f6ea7b9b8`, with artifact SHA256
`01ef27c914f2fbcdd1b66354b2a14449f30501db8a2b382aae3f288a58f915ca`.
Independent readback verifies all 55 selected files (one final promotion change
relative to the initial candidate.38), 2,252 other addon files, 311 WTF files,
42 links/root anchors and all 25,456 prior backup files/2,342 directories.
The installer refused one attempt after 53 game-owned WTF files changed during
staging, before code promotion. Those newer files and the refused-attempt backup
were preserved in the fresh successful retry. No vendor/direct WTF writes or
game input occurred. The user explicitly confirmed logging off and WoW open,
and authorized addon updates while open. Only Forever needed replacement.
[Install](../../evidence/delivery/live-install-candidate38.json),
[refusal](../../evidence/delivery/candidate38-staging-refusal.json),
[readback](../../evidence/delivery/candidate38-independent-readback.json).
The user owns reload and ordinary play. K05 remains open pending live caller
evidence; no additional engine taint logging or prescribed reproduction is needed.

## Candidate.37 impact review

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
| Optional integrations/persistence | Existing native profiles/layouts/bindings/manual edits remain owned and unchanged. The initial candidate.37 stable inspection found no changed package among all nine sources; the later candidate.38 inspection separately qualifies LiteMount 12.1.5-1 above. |
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
