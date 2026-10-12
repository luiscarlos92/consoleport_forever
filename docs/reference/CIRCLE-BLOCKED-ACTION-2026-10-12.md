# Circle protected-action repair and automatic update review

Status: maintained
Reviewed: 2026-10-12
Evidence: [implementation](../../addon/ConsolePort_Forever/Circle.lua),
[dispatch regression](../../tests/harness/circle.lua),
[startup regression](../../tests/harness/startup_circle_review.lua),
[research manifest](../../evidence/circle/research/sources.json),
[running-game delivery tests](../../tests/test_running_companion.py).

## Report and authority

Menu closure works, but pressing Circle while casting with no menu open produces
a protected-action warning. The user's later live diagnose image identifies
`ADDON_ACTION_FORBIDDEN: RunMacroText()` twice. This establishes the rejected
function; the complete Retail taint stack remains unavailable. Earlier saved
diagnostics were not live snapshots and contained no persisted entry.

The user requests automatic login update review, preserving accepted features,
and retains the decision to avoid native Escape because it opens Options.
The initial no-deployment instruction was superseded by explicit October 12
authorization to install this update while WoW runs, leaving reload to the user.
This grants no game input or direct live WTF writes. Historical deployment
permissions remain non-reusable.

## Native evidence and repair

Candidate.31 used `macrotext`. The pinned native action invokes the reported
`C_Macro.RunMacroText` for that branch. Its separate `macro` branch invokes
native `RunMacro` on a saved macro:
[Blizzard SecureTemplates](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
Generated [macro documentation](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/UIMacrosDocumentation.lua)
marks RunMacroText restricted and UPDATE_MACROS synchronous. Native
[constants](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_APIDocumentationGenerated/MacroConstantsDocumentation.lua)
and [macro UI](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.lua)
qualify 120 account slots, 30 character slots, the offset, reads/deletion and
editor-save lifecycle. Raw snapshots remain ignored; URL/hash/size metadata
reconstructs the research cache for CI.

Native STOPCASTING only stops casts; it cannot preserve ground/target cancellation.
The [authored macrotext issue](https://github.com/Stanzilla/WoWUIBugs/issues/552)
records real-slot workarounds and later restoration with length/chaining restrictions.
That history does not certify current engine permissions. The user's live rejected
function supplies the direct evidence for changing our dispatch.

Candidate.32 uses one account macro `CPF Circle` and the native button's `macro`
attribute, with no macrotext/RunMacroText fallback. It preserves the template's
inherited OnClick rather than assigning it through addon SetScript. Pointer
equality alone did not establish secure provenance; retaining the inherited slot
is necessary hygiene, but alone did not address the reported macrotext restriction.

The static reviewed cancel-all body is:

```text
/stopmacro [mod]
/stopcasting
/stopspelltarget
/cleartarget
```

It runs once on down, stopping all three states together, including a coexisting
hard target. Exact Forever first-success ordering remains gated. ConsolePort
menu/ring/foreign ownership and modified actions remain native. No custom input
layer, Escape/Game Menu fallback or public cast-state dispatch is introduced.

## Review and ownership

Revision 18 automatically offers the existing login review to accepted revision-17
characters; StoreSchema stays 3. Accepted features remain active while pending or
declined. Combat/Edit Mode defers review; current acceptance/decline suppresses
repeats; an older decline does not suppress a new update. Historical class repairs
still commit 17 only.

The saved macro is a separate explicit Use Proposed/Keep decision in the normal
coordinator. Startup/preparation/refresh never create or repair macros. Reviewed
CreateMacro runs outside combat/Edit Mode with native readback and the ordinary
retained before-state/compensating journal. An exact account macro is reused
without a write. Restore deletes only an exact reviewed resource; newer body/name
edits remain. There is no EditMacro writer or automatic reconstruction.

Both banks are scanned. Duplicate/character-only names, manual body edits, full
or unreadable account capacity, secret data, unknown limits and missing APIs fail
closed. Name dispatch survives index changes. UPDATE_MACROS synchronously
revalidates/disables the route on edits/deletion, before deferred refresh.
Blizzard's pending editor save before native dispatch remains an engine timing
acceptance limit. Public observations do not select protected actions.

An empty Base PAD2 may receive the reviewed click command. An existing Forever
Circle click may receive only the resource repair. Other nonempty/missing bindings
receive no replacement or unnecessary macro offer. Keep/manual removal remains
authoritative. A kept/deferred resource leaves Circle inactive and diagnosed as
pending rather than invoking the rejected route.

## Qualification and delivery

T68 executes pinned attributes, template contract, secure click, saved-macro/editor
helper, slash registrations and native ConsolePort Layers/Input. The host always
forbids RunMacroText, independently of hardware or modeled script provenance.
The exact candidate.31 route reproduces the reported function rejection with
protected state intact. Negative controls restore macrotext/script replacement
and fail. Lifecycle cases cover review/Keep/drift, capacity/duplicate/secret
failures, index changes, manual edits, restore and compensation while preserving
unrelated macros/bindings.

T70 runs actual loading/events/setup/planner/prompt/transaction paths: automatic
review without startup writes, prior acceptance/manual data, current/old declines,
combat/Edit Mode deferral, macro-only Apply and synchronous invalidation.
T62 retains all-class routing during pending revision-18 review. Its single-VM
GUID transition ends the previous character review, as real UI login would.
T69 independently retains Forever's first-success oracle. All existing input,
ground, ping, class, visual, GUID, action-editing and delivery gates remain required.

The full gate passed 70 runtime checks and 66 tooling tests, with 328 Circle
assertions. Exact inventories match 62 product and 128 tooling/test files.
[Runtime report](../../evidence/test-results/candidate32-circle-runtime.json),
[tooling report](../../evidence/test-results/candidate32-circle-tooling.json) and
[qualification receipt](../../evidence/test-results/candidate32-circle-qualification.json)
retain the source hashes and limits. The original native UI reference is unchanged.

The explicitly requested running-game installer option requires an existing
Forever-only payload, exact prior receipt and unchanged StoreSchema. Closed WoW
remains default for full install, restore and dependencies. Code/WTF backups,
junction checks, untouched-file readback, drift refusal and code-only rollback
remain required; no live WTF writes or game input occur. See
[delivery decision](../decisions/0004-scoped-delivery.md).

Candidate.32 was installed at 15:08:29 Toronto with WoW open, from tested/pushed
source dce5c5016344fbc8df1e72d98063f898cae294a3. Independent readback verifies the
59-file payload, all unselected addons/WTF/topology and 22,504 prior backup files.
No dependencies, live WTF or game input were changed. The deployment permission
is fulfilled. [Installation](../../evidence/delivery/live-install-candidate32.json),
[readback](../../evidence/delivery/candidate32-independent-readback.json) and
[fresh Windows CI](../../evidence/test-results/candidate32-fresh-ci.json) retain proof.

Offline results reject modeled defects, but do not certify Retail C API permission,
provenance, taint, hardware timing, rendering or immediate disk persistence.
Installation readback is separate from user-owned cast/channel/reticle/target,
native menu/ring and automatic-review acceptance.
