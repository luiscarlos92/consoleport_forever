# Shared utility runtime implementation and qualification

Status: maintained
Reviewed: 2026-10-14
Evidence: [archive](../../addon/ConsolePort_Forever/Rings/Utility.lua),
[native adapter](../../addon/ConsolePort_Forever/Adapters/SharedUtility.lua),
[integration](../../addon/ConsolePort_Forever/Rings/UtilityRuntime.lua),
[independent flag](../../addon/ConsolePort_Forever/Rings/UtilityFlag.lua),
[native harness](../../tests/harness/shared_utility_runtime.lua),
[integration harness](../../tests/harness/shared_utility_integration.lua),
[runner](../../tools/test-all.cjs).

## Authority and stage

The user explicitly requests continued fixes until manual testing is required,
and authorizes qualified deployment with first-use activation and a persistent
slash disable plus reload. The earlier
[admission report](SHARED-UTILITY-RING-ADMISSION-2026-10-14.md) records the failing
experimental adapter, not this runtime replacement. Candidate.39 fixes those
boundaries inside Forever. Dependencies, immutable inputs, action-slot storage,
retired ground placement and native input/dispatch remain unchanged. Installation
state is separate in [current status](../IMPLEMENTATION-STATUS.md).

## Model, ownership and migration

UtilityFlag loads after Core and registers `/cpfutility` independently of feature
initialization. Utility, SharedUtility and UtilityRuntime load after the existing
Rings adapter. Existing relative loading/module locations remain. InitializeStore
attempts public/native qualification; disabled/unavailable startup retains normal
setup. The additive account fields sharedUtilityEnabled and sharedUtilityArchive
leave schema3/revision20 intact. The master has version1, stable IDs/revision and
at most two before/desired/owner/readback receipts. False survives startup; rejected
construction is latched once per session and cannot remove the command.

First migration uses current native manual order, including native menus and
duplicates, and supplements missing spell/item identities from the known current
GUID's retained default archive. It never sweeps other GUID archives or collapses
duplicates. Native automatic extras remain transient. Prior GUID views are
retained. The GUID adapter excludes the managed default from capture/archived
validation while preserving personal/class rings and account Ping. The known
Forever posthook trampoline is adopted; foreign owner replacement cannot write.

Spell selection stays distinct from resolved override execution. Learned player/
pet status, public metadata and context determine availability. Items exclude bank,
reagent and account-bank possession; explicit hyperlinks retain variant execution.
Toys use collection ownership. Mounts retain mountID/name execution, collection/
character/faction checks and metadata readiness; temporary zone usability does not
change membership. Account macros require exact index/name/body; character macros,
personal nested rings, equipment and native positional references are GUID scoped.
Drift remains unavailable. Unresolved choices remain saved, and name-only spell
metadata can resolve later without guessing/replacing the saved selection.

The [pinned MountJournal API](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua)
qualifies mount fields. Existing spellbook/spell/item/toy source declarations are
routed by the [technical research](SHARED-UTILITY-RING-TECHNICAL-RESEARCH-2026-10-14.md).

## Admission, editing and performance

ValidateSet admission applies only to the live native default set. Other sets and
detached legacy views retain their validation. SPELLS_CHANGED/UPDATE_MACROS dirty
their domain before native immediate refresh. RefreshAll is guarded before
ClearAllActions touches compiled DATA/META. Automatic work defers while open,
combat/editor/review/setup is active, or context/owner is unknown. Native explicit
add/remove and completed direct edits retain same-context immediate rebuild outside
hard blockers so the unchanged restricted remove hook redraws current selection.
Automatic extras do not count as manual edits.

Completed drag/swap/removal use stable visible IDs; missing dormant entries are
not deleted. Confirmed native Clear removes the whole master; canceled prompts do
nothing. Sticky selection remaps by ID or transient native identity. Recovery
recognizes an owned already-applied view without reinstalling an old spec; foreign
edits are retained. No new protected snippet, macro creation or slot restoration
is introduced.

OnHide, regen, setup completion and the owned Prompt.Cancel posthook resume pending
work. No recurring timer/frame polling exists. Item-ID notifications dirty tracked
dependencies; unchanged quantities skip rebuilding and bag work avoids spell/full
GUID setup. Native slot invalidation targets native references. Subscriptions
register once and disappear on disable. Core/ordinary native projections retain
bounded receipts; failed construction runs once for 100 repeated eligible retries.

## Startup and disable

Native OnDataLoaded can refresh before late attachment. At PLAYER_LOGOUT, retain
the account master but replace only the public native default saved table with
timeless menu commands/metadata. No native refresh/protected operation/disk write
occurs; workers become inert until shutdown. Engine serialization persists the
master and safe seed. Next qualified startup restores available choices. Initial
adoption cannot undo prior legacy chat; crashes before persistence have ordinary
SavedVariables limitations.

`/cpfutility off` persists false and stops queued work. A verified owned current
view becomes the character/native fallback; full master and prior GUID data remain.
After `/reload`, normal native/GUID handling installs no feature hooks, worker,
classifier or utility-only events. `/cpfutility on` plus reload resumes the master.
Edits while disabled belong to the retained native fallback; re-enable resumes
the shared master. `/cpfutility status` reports requested/effective readiness.
The independent command survives corrupt archives and constructor failure.

## Qualification and manual boundary

T87 executes locked native validation/events/RunSafe/refresh/cursor/remove/drag/
Clear against the runtime modules. It verifies cache-before-validation, native/
collection preservation, held/combat/editor/busy deferral and resumption, opaque
context rejection, deletion/Clear, seed startup without removal chat, GUID/other-
ring isolation, disabled queued work, foreign-owner refusal and bounded receipts.
T88 executes actual initialization/slash handling, hyperlink migration, incremental
bank-excluded items, exact macro drift, GUID-owned types, immediate open-wheel
native removal, first addition to an empty master while open and constructor
failure containment. T89 reintroduces all four
admission defects and the legacy ownership conflict; each must fail its intended
assertion. T90 executes actual TOC/bootstrap, known posthook coexistence, one-time
registration and off subscription removal. Earlier reproductions remain evidence.

C APIs, frames, event delivery and compiled action storage are modeled in these
fixtures. Existing relevant restricted-compiler/native input/visual/performance
gates remain required in the complete Test-All run. Reports identify exact full
source inventories. The complete qualification passes all 90 runtime/source
checks and 66 tooling tests with 62 product and 145 tool/test files.
[Exact-source receipt](../../evidence/test-results/candidate39-shared-utility-qualification.json).
Fresh clean [Windows CI](../../evidence/test-results/candidate39-fresh-ci.json)
passes the same checks with matching complete source inventories.
Offline counts do not prove Retail taint, hardware timing,
pixels, engine persistence or CPU milliseconds; K04/K05 remain open.

After qualified delivery, manual acceptance covers reload/opener/native menus,
Rite add/spec/class switch and return, item depletion/replenishment, deletion/Clear,
native remove while open, reload/character persistence and off/reload/on/reload.
Observe native feedback, unexpected chat/blocked-action errors and comparable CPU.
The agent does not launch/operate WoW or write live WTF.
