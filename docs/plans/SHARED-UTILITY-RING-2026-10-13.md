# Shared utility ring design proposal

Status: maintained
Reviewed: 2026-10-14
Evidence: [current ring adapter](../../addon/ConsolePort_Forever/Adapters/Rings.lua),
[native refresh contract](../../evidence/consoleport-contracts/ConsolePort_Rings/Controller/Secure.lua),
[performance requirements](../DEVELOPMENT.md#addon-performance).

The [October 14 technical investigation](../reference/SHARED-UTILITY-RING-TECHNICAL-RESEARCH-2026-10-14.md)
adds verified refresh/edit traces, API choices, precise dirty events, persistence
bounds and unproved integration gates. It supersedes broad assumptions below:
native refresh can be immediate, spellbook presence alone is insufficient,
one edit callback does not cover reorder/clear, and native rebuilds affect all rings.

## Request and authority

The latest October 14 instruction requires continued fixes and qualified delivery
until manual testing is needed. Candidate.39's
[runtime continuation](../reference/SHARED-UTILITY-RING-RUNTIME-2026-10-14.md)
supersedes the earlier activation gates once its replacement defects are rejected.
The default-on independent `/cpfutility off` plus reload is implemented in source;
current status distinguishes installed and accepted stages.

The October 13 user requests a plan for one shared utility ring across characters
and specs, supporting items, abilities and other native entry types. Unavailable
entries should produce no expected-transition error, remain saved, and return
when their character/spec/availability returns. CPU cost is a first-class concern.
This document began as a proposal. The later October 14 instruction authorizes
implementation and deployment when sufficient qualification exists, and more
useful tests while it does not. No runtime change occurred in those earlier proof
phases. Candidate.39 now contains the qualified replacement described above;
the original failures remain negative controls rather than current blockers.

The later October 14 instruction authorizes the isolated
[offline prototype and tests](../reference/SHARED-UTILITY-RING-OFFLINE-PROTOTYPE-2026-10-14.md)
without launching WoW or deploying. That phase executes native source with modeled
engine APIs; it does not activate this feature in the runtime addon. Its retained
uncached native-first counterexample keeps universal no-message integration gated.
The isolated phase passes all 82 runtime/source and 66 tooling suites with exact
current inventories. It supports the shared archive/work-bound design; it does
not establish runtime readiness. The
[admission continuation](../reference/SHARED-UTILITY-RING-ADMISSION-2026-10-14.md)
demonstrates event invalidation and edit/Clear handling, but reproduces open-wheel,
late-startup, unsupported native-choice and opaque-context failures. It separately
tests a persistent first-use flag and independent disable contract. The planned
runtime escape hatch is `/cpfutility off` followed by `/reload`; an explicit false
survives startup, shared choices are retained and disabled reload installs no
feature work. This command is not installed yet. Runtime admission/fallback and
collection/pet/equipment qualification remain required before delivery.

This proposed exception covers utility-ring choices only. Existing class rings,
ordinary action slots and personal action bindings retain their ownership.
Ground-placement retirement, native protected dispatch and manual editing remain
unchanged. Future implementation must update affected requirements/decisions to
describe the approved utility exception to current GUID-owned personal rings.

## Proposed experience

Use L2 + PlayStation Menu/Options as the common default opener, resolved through
the actual device's logical SHIFT-PADFORWARD route. Existing deliberate conflicting
bindings are reviewed rather than overwritten; no entire binding-bank copy is
needed to establish a common default.

Maintain one account-owned ordered list of deliberately added utility entries.
Every character sees the available subset. Additions, removals and reordering are
shared edits. Merely switching spec, changing character, consuming an item or
losing access to an ability does not edit that list.

| Situation | Proposed result |
| --- | --- |
| Paladin spec has learned Rite of Sanctification | Show the selected spell through native ring execution. |
| Another spec cannot access Rite | Retain the choice; omit it from that spec's active ring without removal messages. |
| Return to a spec with Rite | Restore the saved choice in its original relative order. |
| Different class | Show its available spells plus shared available items/other actions; retain other classes' choices. |
| Same-class alt knows the same selected spell | Show it without requiring another addition. |
| Consumable count becomes zero, then is replenished | Hide, then return the saved item entry. |
| Cooldown, insufficient resources, range, movement or death restriction | Keep the entry; native feedback and casting rules apply. |
| User deliberately removes an entry | Remove it globally; availability changes must not resurrect it. |
| Item/spell data or identity is not ready | Mark pending; do not delete saved choices or infer availability. |

Recommendation: hide unavailable entries in the playing ring and show them,
with an explanation, in a compact management view. This retains native ring
geometry; visible entries keep relative order, but their angular positions can
change as the count changes. Fixed angular positions/placeholders would require
separate native-layout qualification and are not included in this proposal.

## Saved choices and native projection

Store the full list in Forever's shared account store, outside ConsolePort's
validated live ring tables. Do not put a union of every class's spells directly
into native Shared: native enumeration validates both personal and Shared sets.

Each entry needs a stable entry ID, action kind, qualified identity, ordering and
any required ownership scope. Keep intentional duplicates as distinct entries.
Use numeric spell/item identities where qualified, while retaining the native
execution representation: native mount casting may require a name. Never invent
spell IDs from icons or infer equivalence from identical display names.

Build a detached active projection for the current GUID, spec, talents and
inventory. Map projected positions back to stable entry IDs. Native ConsolePort
continues to own buttons, selection, release dispatch, cooldowns and restrictions.
Only the utility set is projected; preserve other personal rings, the account
ping ring, manual metadata and native autoassigned quest/zone/extra actions.
Autoassigned actions remain transient and never enter the shared manual archive.

Availability has three states: available, unavailable, pending. Unavailable is
not an error or deletion. Pending is not evidence of absence. Runtime projection
identity must include GUID/context and shared-list revision; reject results from
a previous owner or obsolete worker before committing.

## Entry-type rules

| Kind | Availability and identity rule |
| --- | --- |
| Player ability | Qualified current learned status and native override/talent identity. Catalog existence or spellbook presence alone is insufficient; exclude future/offspec slots and qualify temporary grants. Do not gate on cooldown/resource/range usability. |
| Ordinary item | Qualified item ID and carried/equipped possession; bank-only possession does not imply usable access. Treat zero count as dormant, not deletion. |
| Toy or mount | Collection/unlock rules appropriate to that kind, preserving native execution representation. A toy is not an ordinary bag-count item. |
| Saved macro | Preserve native user-authored semantics. Account macros need unambiguous identity/readback; character macros retain GUID scope. Never share a numeric macro index or guess a replacement by similar name/body. |
| Equipment set | Retain GUID scope and exact native identity; another character's same name does not establish ownership. |
| Pet command | Resolve a qualified current pet action; a stored slot number alone cannot identify the same command on another pet. |
| Binding or nested ring | Validate the native route and target ownership; character-only targets remain dormant elsewhere. Reject cycles/missing targets without deleting the saved entry. |
| Unknown/custom payload | Preserve original data for review; do not automatically project an unqualified cross-character action. |

A shared ring does not mean every payload is transferable. Character-scoped
actions can live in the same shared list and appear only for their owner. Ship
only kinds whose active/pending/dormant and native execution contracts have been
qualified; do not silently discard remaining saved kinds. Automatic macro
creation, action-slot replacement or broad automatic ability discovery are not
required to implement the requested behavior.

## Native validation and manual editing

The first implementation gate is a native lifecycle reproduction. Demonstrate
silent filtering before native validation on login, spec changes, item-data
arrival and combat-delayed refresh. An after-refresh hook alone is too late to
prevent a message already printed. Qualify a narrow Forever-owned integration
point using actual pinned native source; do not assume event registration order
or a zero-delay timer wins. Do not modify upstream files, globally suppress
chat/errors, replace native dispatch or send invalid entries repeatedly until
the validator removes them. If a safe integration point cannot be qualified,
revisit the design before claiming the no-message requirement is solved.

Capture explicit native editing operations using the projected-ID map. Native
validation removal and transient autoassigned removal are not user deletion.
Reconcile add/remove/reorder as small changes to the shared list; never replace
it with a compact visible-only snapshot. Preserve hidden entries' relative order
when visible entries move. Provide explicit access to dormant choices for global
removal. Preserve/remap sticky selection by entry identity rather than carrying
a numeric slice index into a different projection.

Guard reentrancy: the projection's native RefreshAll must not be captured as a
new manual edit that queues another projection. Install owner-scoped hooks once,
handle late replacement/missing addons, and release only owned integration.
Defer protected projection changes during combat, Edit Mode, open-ring gestures,
configuration review or recovery. Resume once eligible using current identity.
Native immediate input/feedback continues throughout; public eligibility caches
never authorize protected dispatch. Save through in-game storage only.

## Performance design and acceptance targets

Use change-driven reconciliation, not polling. Keep one current-character runtime
cache; do not rebuild every character/spec profile or retain an unbounded history.
Keep saved metadata separate from dynamic native feedback and secret values.

| Trigger | Scoped work |
| --- | --- |
| Login/character readiness | One initial relevant-entry classification after readiness; bounded retry only for unresolved dependencies. |
| Player spec/talent/spellbook change | Invalidate relevant spell entries and any dependent pet/native routes; merge equivalent requests. |
| Item count/bag/equipment change | Prefer ITEM_COUNT_CHANGED's item ID and indexed item queries. Positive quantity changes do not rebuild. Bag fallback checks only tracked items when affected IDs are unknown. |
| Item-data/collection/macro/pet update | Recheck the corresponding entry kind/dependency; qualify the exact official events/APIs before coding. |
| Manual ring edit | Update affected stable entry IDs and shared revision. |
| Cooldown, target, resource, cursor movement, repeated casts | No new shared-ring classification or rebuild; keep native feedback immediate. |
| Combat/Edit Mode/ring close | Resume a single pending reconciliation when writable; do nothing if no work is pending. |

One coalesced worker handles each dirty batch; public queries are cached per
relevant generation. Multi-frame bursts may require further classification as
the engine settles, but unchanged projected output must cause zero additional
Forever-requested native rebuilds. No permanent OnUpdate/ticker, no unlimited
readiness retries, no full addon setup/skin/layout for ordinary ring updates.

Use linear indexed reconciliation for saved/projected entries instead of the
current nested previous-entry/current-entry matching. Query each affected
identity once per dirty generation. Compare ordered identities and qualified
payload/metadata before writing. Duplicate no-op notifications should produce
no additional table replacement, saved-history copy or native rebuild.

Current CaptureEdits can run twice before a refresh comparison; the shared utility
path should instead capture completed explicit edits once. Native edit routes
include direct drag/swap/clear writes, not only OnSetChanged. Preserve ordinary
full refresh responsibilities for class/binding/readiness transitions while
making shared-utility reconciliation incremental within them.

Keep reviewed migration/configuration journals. Routine utility projections need
a separately qualified bounded before/desired/owner/readback receipt instead of
creating unlimited full-ring transaction backups on item availability changes.
Do not prune historical evidence or weaken newer-edit recovery to obtain this bound.

Proposed measurable gates:

- Idle adds zero recurring Forever ring workers and zero polling queries.
- A same-frame burst queues at most one reconciliation worker.
- An unchanged active projection causes zero Forever-requested native rebuilds.
- One completed material projection change requests at most one native rebuild,
  with no reentrant self-triggered rebuild loop. Independent native automatic
  refreshes are measured separately, not falsely claimed eliminated.
- A bag-only batch performs no spell classification/full setup/skin/layout.
- Expected unavailable entries produce zero invalid-removal chat messages.
- Diagnostics are disabled by default, fixed-size aggregates when enabled;
  record classifications, rebuilds, no-op skips and bounded timing without
  copying the master list/history on each event.

These are operation-count targets, not promised Retail millisecond savings.
Compare baseline and candidate with the same client/addons/character/profiler
mode/FPS and scenario lengths. Include average, peak, total and spike counts for
idle, repeated spec switches, ring opens, combat casts, looting/bag bursts and
quest extras. Measure Forever and native ConsolePort_Rings together because work
can be attributed across callbacks. Retain the earlier performance reproduction
and do not declare existing K04 CPU or K05 taint reports resolved by this feature.

## Migration, validation and implementation sequence

1. Reproduce the reported name-based spell rejection and repeated dormant
   validation logs with pinned native code. Establish current refresh/edit costs
   and qualify prevalidation ordering/taint boundaries before designing hooks.
2. Implement the shared-choice model, availability classifier, context guards
   and active projection separately from native dispatch. Add meaningful tests
   that fail when unavailable data is deleted or sent to noisy validation.
3. Qualify native editing/projection integration and each supported entry kind.
   Add dirty-domain caching and operation gates before broad activation.
4. Present one migration preview: selected current utility order as the base,
   reviewed additions from other GUID archives, duplicates and metadata conflicts
   retained for decision. Preserve all previous GUID archives and native snapshots
   for guarded rollback. Never silently overwrite with the last logged-in ring.
   Schema/revision changes depend on the final persistent contract; do not assume
   this is a running-game update eligible under the current delivery exception.
5. Validate explicit deletion, hidden-entry reorder, shared edits across logins,
   same-class alts, other classes, all-spec/talent returns, consumed/replenished
   items, collection actions, macro deletion/edit/index drift, missing data,
   interrupted migration, foreign owners, native extras, sticky selection and
   open-wheel/combat/Edit Mode transitions. Run actual native input/compiler gates
   where restricted execution is affected; mocks do not certify taint.
6. Preserve T43/T47/T58/T59/T63 persistence, T65 ping/other-ring isolation,
   T73-T76 performance and applicable native dispatch/feedback/retirement gates.
   Run the full Test-All and maintained documentation checks for implementation,
   with complete exact-source inventories and fresh dependency qualification.
7. Separately qualify Retail no-message, persistence, gesture and profiling
   acceptance. Package/deliver only after implementation scope is authorized and
   applicable source/receipt/backup/readback gates pass.

Likely affected runtime responsibilities: Store, Adapters/Rings, RuntimeSetup,
RefreshRings/event reconciliation and reviewed migration. Keep existing runtime
locations/loading unless a functional need is established. Documentation impact:
requirements/ownership decision, architecture, controller/state/configuration,
testing/performance, known issues and delivery state only when each changes.

Completion requires persisted shared choices, silent expected transitions,
reappearance without deleted-entry resurrection, preserved native/other-ring
behavior, green operation gates and comparable Retail performance evidence.
This planning artifact does not claim any of those implementation results.
