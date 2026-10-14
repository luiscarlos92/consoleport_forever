# Shared utility ring technical investigation

Status: maintained
Reviewed: 2026-10-14
Evidence: [design proposal](../plans/SHARED-UTILITY-RING-2026-10-13.md),
[qualified package lock](../../dependencies/lock.json),
[native API provenance](../../evidence/native/manifest.json).

## Scope and strength of evidence

The user authorizes further investigation and plan adaptation only, without
coding or deployment. This session reads source, verifies selected hashes and
updates documentation. It writes no runtime, test, executable-tooling, dependency,
production or game-configuration file and operates no game input. No new native
harness, prototype, simulated execution, Retail test or profiling capture was run.

This paragraph describes the source-only phase. The subsequent user-authorized
[offline code/test phase](SHARED-UTILITY-RING-OFFLINE-PROTOTYPE-2026-10-14.md)
adds a prototype and native-source execution with modeled APIs, while retaining
the no-game/no-deployment boundary and the unqualified engine limits.

The 15 selected inspected ConsolePort package files match the 3.3.10 lock: Rings Database,
Map, Container, Secure, Events, Observer, Auto, config Display/Ring, Loadout,
Config, main ActionMap, RelaTable, Utils, Wrapper and Rings TOC. Three local
Blizzard API sources (SpellBook, Spell, PetInfo) match their existing manifest.
The Blizzard source reference is commit
`09b9db7948abc9b9648dedaab51eb0cf3ee67b31`; additional generated APIs/UI sources
were read at that same commit. Package-cache inspection is not fresh stable
discovery and API documentation is not a snapshot of the user's engine.

Source inspection establishes control flow and documented contracts. Proposed
integration behavior, security/taint, C API readiness and CPU milliseconds remain
unproved. The image establishes repeated rejection messages with a name-based
Rite payload; it does not establish all stored bytes, the exact message count's
callers, or whether Rite was learned at every point in the transition.

## Native refresh order: the asynchronous-only assumption fails

The inspected native path is:

1. `Events:SPELLS_CHANGED` marks spell validation ready, schedules zone-ability
   work through CPAPI.Next, then calls QueueRefresh directly.
2. QueueRefresh calls `db:RunSafe(self.RefreshAll, self)`.
3. RelaTable's safe callback invokes the function immediately outside combat.
   During combat it retains the last arguments under the function key and drains
   that map on PLAYER_REGEN_ENABLED. The source does not establish ordering
   between different queued functions or other addons' event handlers.
4. RefreshAll clears compiled actions and pools, enumerates available sets, and
   rebuilds their metadata/buttons/restricted action records.
5. Enumeration calls GetData and GetShared without skipValidation, so both live
   stores undergo ValidateData/ValidateSet. The validator compacts the supplied
   table in place, including when called on a detached copy.

Therefore a next-frame Forever worker cannot guarantee preprocessing before the
immediate native refresh. GUI reads can validate too; fixing QueueRefresh alone
would not cover GetSet/GetData access. No prevalidation callback was found in
the inspected Database/Map/Secure paths. Existing posthooks can observe a result
but cannot stop a message already printed. CPAPI.Next uses RunNextFrame, not an
ordering barrier. RelaTable's combat queuing already coalesces a given function;
outside-combat QueueRefresh does not provide that deduplication.

Source: [native Events](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort_Rings/Controller/Events.lua),
[Database](../../evidence/consoleport-contracts/ConsolePort_Rings/Database.lua),
[Secure](../../evidence/consoleport-contracts/ConsolePort_Rings/Controller/Secure.lua).
RelaTable/Utils are verified files in the local 3.3.10 package cache, not additions
to the pinned evidence manifest.

### Candidate integration choices, not proven repairs

| Choice | Finding / implementation consequence |
| --- | --- |
| Deferred projection only | Insufficient as a universal no-message solution; native validation can precede it. |
| Numeric player-spell normalization plus pure archive classification | First candidate to qualify: native cursor spells already retain IDs. Stop validating dormant archives through the noisy native validator. This may remove the demonstrated name-resolution/repeated-archive causes without replacing any native function, but does not prove silence for every stale/pending live payload. |
| Narrow managed-utility preprocessing at env.ValidateSet | Candidate if the first option cannot satisfy ordering. This is a common boundary for both refresh and GUI validation. Replacing/decorating an ordinary Lua method still changes native ownership/taint provenance; it is not an approved safe hook or a proven secure route. Must defer to original behavior for foreign sets/owners and qualify actual native/engine boundaries before selecting it. |
| Decorating only ActionValidationMap.spell | Narrower, but incomplete for items, macros, metadata and other kinds. Catalog validation alone still does not establish learned availability. |
| Overriding global logging or replacing protected refresh/input | Rejected: hides unrelated evidence or changes native authority. |

Do not implement a validator decoration merely because this table identifies a
possible seam. The next coding-authorized phase must establish startup, late
loading, combat/GUI validation, method collisions and secure provenance first.
Fail pending for an unknown contract; never silently install a global wrapper.

## Identity and availability API refinements

### Player spells

Use a qualified selected spell ID, and retain its selected/base/override identity
separately from the native cast payload. A string with a qualified spell hyperlink
can be resolved from that link for migration; a name without an unambiguous link
must remain pending rather than acquire a guessed ID. Native ActionMap.spell uses
the cursor spell ID. Mount mapping deliberately uses a name; it must not undergo
blanket numeric conversion.

The [Blizzard SpellBook source](../../evidence/native/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua)
distinguishes learned spells from spellbook presence, including talent overrides
and temporary grants. A book-presence OR is not a strict learned predicate.
Candidate classification uses `C_SpellBook.IsSpellKnown(id, Enum.SpellBookSpellBank.Player)`
with current override resolution, not usability/cooldown reads. Active slot lookup
can exclude future/offspec entries and expose actionID versus overriding spellID.
Do not use the pet bank for player spells. Exact identity/override execution still
needs the native-class/talent fixtures; source signatures cannot choose policy
for every temporary aura override.

The [Spell source](../../evidence/native/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua)
provides `C_Spell.GetOverrideSpell(id, 0, true, 0)`, GetBaseSpell, IsSpellDataCached
and RequestLoadSpellData. The spec argument defaults to the current spec and
onlyKnown defaults true. Use bounded outstanding requests and SPELL_DATA_LOAD_RESULT
for missing metadata; a failed response is not deletion. Public numeric input,
return and identity checks are required before comparisons/storage. Keep saved
selection distinct from resolved execution; following an override never edits
the user's canonical choice.

Source: [native ActionMap](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort/Model/Game/ActionMap.lua).

### Items and collections

The [Blizzard Item API](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua)
documents C_Item.GetItemCount with independent bank, uses, reagent-bank and
account-bank flags. Candidate ordinary-item queries explicitly exclude all
banks; equipped possession can be checked through IsEquippedItem. Recheck exact
equipped/use-count semantics in engine fixtures. ITEM_COUNT_CHANGED supplies an
itemID, and ITEM_DATA_LOAD_RESULT supplies itemID/success. Index tracked entries
by that ID; changed positive stack quantity alone must not rebuild the ring.

Native numeric item validation converts through item information to a hyperlink;
uncached information can fail its accepted-format check. A decimal-string item
ID is accepted by the inspected validator without that numeric conversion.
Treat decimal-string execution as a candidate LAB payload to qualify, not a
promise about uncached items. Async RequestLoadItemDataByID can instead keep
such entries pending. Preserving a full hyperlink may be necessary for an
explicit item variant; do not merge distinct variants without review.

Source: [native Map](../../evidence/consoleport-contracts/ConsolePort_Rings/Model/Map.lua).

For mounts, [GetMountInfoByID](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/MountJournalDocumentation.lua)
provides collection, faction and shouldHideOnChar fields. Retain mountID and
spellID for identity, and the qualified native name for execution. Do not let
temporary zone/movement usability cause constant removal/reappearance. NEW_MOUNT_ADDED
supplies a specific ID; no full collection enumeration is necessary for a saved
mount choice.

For toys, [Blizzard's ToyBox UI](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_Collections/Mainline/Blizzard_ToyBox.lua)
uses PlayerHasToy and C_ToyBox.GetToyInfo rather than inventory ownership.
[TOYS_UPDATED/NEW_TOY_ADDED](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/ToyBoxInfoDocumentation.lua)
provide targeted notification, with TOYS_UPDATED allowing an absent item ID.
Collection ownership is source-supported; character restrictions and native ring
toy dispatch still require qualification. Avoid using a broad dynamic
IsToyUsable result as a permanent-membership predicate without proving what it
includes. Other kinds remain typed and scoped as described in the design.

### Context and cache invalidation

Use GUID, qualified spec ID, active talent config ID and separate dirty
generations. An index such as specialization 1 does not identify the same spec
across classes. A talent config ID can remain constant while its nodes change,
so context-ID equality cannot suppress spell invalidation.

The [ClassTalents API](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClassTalentsDocumentation.lua)
provides GetActiveConfigID and ACTIVE_COMBAT_CONFIG_CHANGED(configID).
[TRAIT_CONFIG_UPDATED](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/SharedTraitsDocumentation.lua)
also includes configID; invalidate the active/unknown context rather than treating
every update to another saved loadout as a ring change. The current Forever
player-spec filter remains necessary. SPELLS_CHANGED remains an independent
spell generation even if config/spec IDs are unchanged.

Keep future/item-data/spell-data outstanding sets deduplicated per ID/context.
Responses mark only their indexed dependencies dirty; an obsolete callback may
complete metadata loading but must not commit an old character's projection.
Never register UNIT_AURA broadly just to scan every saved spell on each aura.
Aura-only overrides need a qualified targeted invalidation/native-payload rule
or must remain an explicit coverage gap. Do not claim spec/talent events cover
every temporarily granted ability.

## Native editing requires several routes

Generic post-refresh differences cannot distinguish deliberate deletion from
validation. The following paths are demonstrated in the locked package:

| User/native path | Source behavior | Candidate capture rule |
| --- | --- | --- |
| Cursor added by opening a ring | CheckCursorInfo -> AddFromCursorInfo -> AddUniqueAction -> AddSavedVar -> RefreshAll; OnRingContentChanged fires afterward. | Observe low-level addition before validation can remove it, map its identity and exclude autoassigned additions. |
| Native configuration add/delete | Loadout OnSelected calls native add/remove, then emits OnSetChanged. | Capture one completed edit, not every internal mutation. |
| Replace an entry | Loadout replacement removes then adds; cursor replacement adds then removes an adjacent entry. | Group the operation and preserve the replaced stable entry's place; do not queue two projections or commit an intermediate empty state. |
| Gameplay ring remove button | Restricted snippet calls SafeRemoveAction -> RemoveAction -> RemoveSavedVar. | Observe only a successful writable removal; map its old index through the last qualified projection. No OnSetChanged is emitted here. |
| Mouse drag reorder | SetDragEntry copies data on drag start, writes its reordered entries directly at drag end, then RefreshAll. | Capture once at completed drag; no per-frame capture, and do not rely on OnSetChanged, which this path does not emit. |
| Gamepad swap | OnReplace swaps live entries directly, RefreshAll, then OnSetChanged. | Capture one order operation by stable IDs. |
| Clear ring | Confirmed popup closure directly wipes the set and refreshes. | Qualify confirmed clear capture separately; OnRequestWipe can also be canceled, and is not proof the clear happened. |
| Native auto/validation changes | Auto uses some of the same mutators; validation directly compacts tables. | autoassigned entries remain native/transient; validation never deletes canonical shared choices. |

Sources: [Observer](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort_Rings/Controller/Observer.lua),
[Container](../../evidence/consoleport-contracts/ConsolePort_Rings/Model/Container.lua),
[config Ring](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort_Rings/View/Config/Display/Ring.lua),
[Loadout](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort_Rings/View/Config/Loadout/Loadout.lua),
[Config](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort_Rings/View/Config/Config.lua).
Registrations for OnRingCleared/OnRingRemoved exist, but no emitters were found
in the searched locked suite Lua files; do not assume they provide clear capture.

Candidate posthooks on AddSavedVar/RemoveSavedVar can observe mutations before
the subsequent native refresh. Stable projection mapping and autoassigned
classification are still required, especially for removed values that posthooks
do not receive as return values. No single hook above completes edit handling.
Late native config creation must be covered without forcing its creation/login
UI. Do not place foreign metadata onto entries merely to make matching convenient
until native comparison/duplicate/edit behavior is qualified.

For reorder, a concrete proposed rule is to permute visible manual IDs within
their current canonical positions while leaving hidden IDs in their positions.
Example: canonical A, hidden H, B becomes B, H, A after swapping visible A/B.
This is a proposal to make hidden-order behavior deterministic, not an existing
user-approved UI rule. Clear All should explicitly identify its global effect,
including dormant choices, before the user confirms it. Native transient extras
must never enter the canonical sequence.

## Actual avoidable work and persistence risks

The accepted same-GUID RefreshRings path calls CaptureEdits, then Proposal calls
CaptureEdits again before comparison. Each capture copies manual data across
personal sets, compares prior/current entries in nested loops, and copies the
updated archive. Missing entries are passed to native ValidateSet even if already
recorded dormant. Proposal copies/validates the archived sets again. This explains
how detached validation can print repeatedly; it does not identify the exact
live callers of each screenshot line or quantify their CPU milliseconds.

[RefreshRings](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua) additionally
calls PrepareSelectors on same-GUID refreshes, captures after native RefreshAll
through a posthook, and requests ring reconciliation on every ring close.
BAG_UPDATE_DELAYED routes to that whole rings path. SPELLS_CHANGED/spec/talent
notifications retain full runtime refresh for other existing responsibilities.
The shared utility feature must avoid its own unchanged work without arbitrarily
disabling those necessary existing refresh domains.

When projections differ, the current path prepares a full transaction.
[Transactions.Prepare](../../addon/ConsolePort_Forever/Transactions.lua) stores a
copied journal, another backup and the character transaction ID; Commit retains
the managed value. Applying this wholesale to frequent item visibility changes
would accumulate large persistent histories. No live file-size/CPU consequence
is asserted from this static finding.

Adaptation: reviewed migration/configuration retains the existing durable
journals/backups. Design a separately bounded utility-projection receipt with
before/desired values, owner/revision, attempting/verified state, drift-aware
readback/recovery and a fixed retained count. Ordinary availability projection
must not manufacture an unlimited history or overwrite newer manual/foreign
edits. This new lifecycle needs validation and documentation; it is not permission
to prune historical journals/backups or weaken Transactions.

### More precise performance targets

- Shared utility capture is edit-triggered, not performed twice per refresh.
  Retain separate existing class/personal capture until its own contract changes.
- Spell dirty work is bounded by unique selected spell dependencies, not every
  known spell or all character records. Explicit book scans, if necessary for
  qualification, occur once per spell generation and are measured separately.
- Item-ID notifications check only indexed IDs. A positive count changing from
  20 to 19 changes native count feedback but adds zero projection rebuilds.
- Duplicate same-frame requests produce at most one worker; ring close without
  pending work adds zero new shared-utility queries/rebuilds.
- One completed active-view change adds at most one Forever-requested RefreshAll.
  Native replacement can already invoke it twice; that native baseline is counted
  separately. Do not wrap/debounce all native refreshes to force a lower number.
- Use exact indexed identities/qualified payload comparisons, not arbitrary
  table serialization or secret-value hashing. Stable-ID matching is linear;
  insertion/reorder of a Lua array can still cost linear work and must be counted.
- Prevalidation guards have a distinct low-cost contract: no archive copying,
  all-ring traversal, full API scan or worker recursion on every GUI lookup.
- Save edit changes incrementally; outstanding metadata requests, receipts and
  counters are bounded. No elapsed-time claim is inferred from source complexity.

## Proposed implementation contracts and next proof gates

The following is a data/API design specification, not executable code:

| Responsibility | Proposed contract |
| --- | --- |
| Shared archive | schema marker, monotonic edit revision, next stable entry ID, ordered entry records; each includes kind, selected identity, optional GUID scope and preserved native payload. |
| Current context | GUID, class token, spec ID, active config ID, spell/item/collection/pet dirty generations; never a persistent matrix of every spec's live state. |
| Classifier | Input: one qualified entry/current public context. Output: available/unavailable/pending, resolved native payload, reason and dependencies. No native table write or chat output. |
| Projection builder | Produce ordered qualified manual entries, mapping and remapped sticky metadata. Preserve native autoassigned extras and other sets; distinguish native-only view changes from canonical edits. |
| Edit reconciler | Input: completed explicit edit with old mapping and revision. Apply exact shared deltas; reject stale context/mapping. No visible-only replacement of the whole archive. |
| Commit coordinator | Guard identity, ownership, combat/Edit Mode/review/recovery and open-wheel/drag state; compare before/desired, commit once, read back, and record a bounded receipt. |

Pending classification omits an unqualified new payload, retains its canonical
choice, and waits for a targeted readiness event. Keep an existing entry only if
its current-context/native validity remains qualified; never reuse a foreign
character's last good view. Do not rebuild under a held selector or editor drag
and remap indices while that gesture is in progress.

Next proof gates when coding is authorized:

1. Execute locked native validation/refresh/edit paths in a narrowly modeled
   fixture to reject deferred-only ordering, invalid archive checks, and missing
   drag/clear capture. Retain the original rejection and meaningful negative
   controls. No such fixture was written or executed in this investigation.
2. Qualify selected numeric Rite identity, override execution, future/offspec
   exclusion, decimal-string/uncached items, toys/mounts and scoped macro drift
   against actual native handlers; no fuzzy macro retargeting. The native macro
   validator's similarity search makes stale shared macro indices particularly
   unsuitable for direct projection.
3. Test compiled ring action count, sticky mapping, manual duplicates, extras,
   clear/replace semantics, metadata, late owners, save/reload and bounded receipt
   recovery. Enforce exact work counts rather than mock timing thresholds.
4. Preserve actual native Layers/secure compiler and existing regression gates.
   Only subsequent Retail observations can establish taint, API event readiness,
   immediate gesture behavior, persistence and comparable CPU performance.

The architecture is more concrete, but zero-message secure integration remains
the highest-risk unqualified boundary. This investigation does not declare that
the feature is implemented, live-safe, or that prior CPU/taint reports are fixed.
