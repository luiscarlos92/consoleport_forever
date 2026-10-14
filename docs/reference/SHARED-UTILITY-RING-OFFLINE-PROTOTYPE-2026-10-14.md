# Shared utility ring offline prototype

Status: maintained
Reviewed: 2026-10-14
Evidence: [prototype](../../tests/prototypes/shared_utility.lua),
[native-source harness](../../tests/harness/shared_utility.lua),
[runner](../../tools/test-all.cjs),
[design](../plans/SHARED-UTILITY-RING-2026-10-13.md).

## Authority and scope

This record describes the earlier offline-only phase. The later user instruction
authorizes implementation/deployment when sufficient qualification exists. The
[admission continuation](SHARED-UTILITY-RING-ADMISSION-2026-10-14.md) records that
authority, the new counterexamples and the independent feature-flag contract.
The retained reports here belong to this earlier exact source, not the later
expanded test inventory.

Following the source-only investigation, the user authorizes writing code and
tests without launching WoW or deploying anything. This implementation remains
under tests/prototypes; it is not in the addon TOC or any installed code. The
runtime addon, native vendors, immutable evidence/reference/fixtures, live game
configuration and game input remain untouched. No package, install, commit/push
or game operation belongs to this proof phase.

Fresh official stable discovery checks all nine dependency identities before
coding; all match the current lock. Only the two freshly browsed CurseForge
timestamps and the stable recheck receipt are refreshed. No dependency bytes or
lock identity change. This is source freshness, not engine qualification.

## What was implemented

The prototype has a shared ordered archive with stable IDs and explicit edit
revision, a current-context availability cache, targeted dependency notifications,
one queued worker per burst, and native-view comparison before writing. It
classifies player spells by modeled learned/override/metadata contracts, ordinary
items by carried count/readiness, and character-scoped saved macros by exact
identity/body. Other kinds stay pending; toys, mounts, equipment sets and pet
commands have not been implemented/qualified by this experiment.

User deletion/clear removes canonical choices; temporary unavailability does not.
Reorder permutes visible stable IDs in their existing canonical positions,
retaining hidden positions. Native autoassigned extras and other rings remain
separate. Sticky selection remaps through the last stable-ID view. This is a
prototype edit API, not completed runtime UI/hook integration.

Metadata requests are deduplicated. A resolved override's ID is indexed back to
its selected base entry, so its data-arrival notification can resume the entry.
Opaque/failing reads remain pending. Identity is rechecked after classification
and before commit. Combat, open wheel, Edit Mode and busy states defer with no
automatic worker loop. Two retained receipts provide failed-write/readback and
drift-aware recovery across prototype reloads; they do not prune existing product
journals or historical backups.
Recovery recognizes an already-completed owned desired view by readback; it
does not reinstall the previous spec's before-view to undo a successful write
followed by an exception. Newer foreign edits remain untouched.

## Native source versus modeled engine

The harness loads exact package-locked ConsolePort 3.3.10 bodies for ActionMap,
Database access/validation, Map, Container, RunSafe/combat queue, RefreshAll,
Events, Auto, Observer, configuration Ring/Loadout and the confirmed-clear method.
Each native file is verified against the lock when read. Pinned source bytes are
not edited. The current Forever RingsAdapter executes the baseline dormant-log
reproduction unchanged.

Modeled boundaries include player/spec/inventory/catalog/learned APIs, macro
enumeration, database-backed symbol lookup, callbacks, scheduling, frames and
button compilation/record setters. The test counts output and work; it neither
executes Retail C APIs nor proves protected action authority or rendered pixels.
Native edit operations execute first, then the fixture explicitly submits their
completed operation to the prototype edit API. This does not prove a real addon
can capture every operation's provenance with safe hooks.

The harness intentionally models catalogue metadata as available independently
of learned status. Named lookup can fail when a spell leaves the active book.
This explores source-consistent C API outcomes rather than asserting all Retail
builds have those exact return values. It uses synthetic spell IDs/classes, not
a claimed Retail Rite spell-ID lookup.

## Findings that change the plan

1. The native baseline emits one name-based rejection and three further archive
   validation messages in the controlled sequence. Repeated detached validation
   is a demonstrated mechanism; the exact screenshot call sequence remains unknown.
2. Loaded numeric identities plus pure archive classification pass the modeled
   spec/character transition cases in either refresh order without expected
   rejection output. Canonical choices return, while explicit deletion persists.
3. Missing numeric spell metadata before a native-first immediate refresh still
   produces a removal message. Deferred-only integration therefore remains
   insufficient for the universal no-message requirement. This counterexample
   is retained as an expected limitation, not concealed by a passing test.
4. Native macro validation adds macrotext=false. The candidate payload must
   include that native normalized field for readback equality. Native similarity
   matching can retarget a stale macro to another macro; the prototype instead
   leaves changed/deleted identities pending.
5. Mouse drag and gameplay removal bypass OnSetChanged. Native replacement
   performs two native rebuilds; completed-edit capture can coalesce the prototype
   update without pretending those original native calls have disappeared.
6. An item burst of 100 notifications coalesces. Positive stack changes add no
   prototype rebuild and perform no player-spell classification. Untracked item
   IDs and idle resume add no utility work. These are operation assertions, not
   milliseconds or real-client profiling results.

## Regression controls and completion evidence

T80 covers transitions, pending metadata, learned/catalog separation, overrides,
public-value failures, explicit deletion, duplicates, native extras, hidden order,
sticky mapping, native editing, macro drift, deferral, identity races, bounded
receipts and guarded recovery. T81 reloads a serialized archive in a fresh Lua VM.
T82 rejects eight variants: catalogue-as-learned, rebuild on unchanged contents,
missing item absence, ignored deletion, item notifications rescanning spells,
unbounded receipts, missing identity checks, and ignored macro drift.

Full current-source verification and its exact report inventories are recorded
in the [qualification receipt](../../evidence/utility-ring/offline-prototype-2026-10-14.json).
The standard runner includes the new checks without excluding existing suites.
Source syntax is checked as Lua 5.1; Fengari execution uses Lua 5.3 compatibility.
All receipt claims must reflect the completed final run, not an earlier targeted
development pass.

Completed verification: all 82 runtime/source suites and 66 tooling tests pass.
T80 performs 258 fixture checks; T81 verifies a fresh-VM archive and T82 rejects
all eight faulty variants. Exact inventories match 58 product files and 139
tool/test files; the product tree, immutable reference/fixtures and lock remain
unchanged. The retained reports and their checksums are linked in the receipt.
The 100-notification item case records one worker, one item query, zero spell
classifications and zero prototype rebuilds. The uncached native-first case
records one expected removal message, retaining the integration gap.

## Remaining implementation boundary

Do not activate this code as a runtime addon module. The next qualified step is
safe admission/prevalidation and explicit native-edit capture, preserving taint
ownership, startup/late loading, unknown contracts and native secure dispatch.
Universal expected-transition silence remains unproved because of the retained
uncached native-first case. Runtime binding migration, collection/pet/equipment
types and real management UI remain outside this prototype.

Subsequent controlled Retail observations are still required for engine readiness,
taint, persistence, gesture timing and comparable CPU average/peak/spike behavior.
The prior K04/K05 reports are not resolved by these offline checks.
