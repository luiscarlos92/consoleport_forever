# ConsolePort Forever change history

Status: maintained
Reviewed: 2026-10-14
Evidence: [current status](docs/IMPLEMENTATION-STATUS.md),
[historical chronology](docs/archive/ai-native-2026-10-11/IMPLEMENTATION-STATUS.pre-restructure.md).

Dates below use America/Toronto. This is a curated change index, not invented
release tags or blanket gameplay certification. Detailed receipts own exact
source/artifact/file identities. Prepared, installed and accepted are separate.

## Automatic native-action trace — October 13–14, 2026

Candidate.38 records bounded initial
security labels and later observed stock action-field transitions with caller
stacks, plus first blocked-event stacks. It leaves native handlers, input,
cooldowns and action values unchanged; this is diagnostic instrumentation, not
a claimed combat-error fix. Fresh discovery also qualifies official LiteMount
12.1.5-1 while retaining old adapter identities. All 115 files already match that
release on disk before this deployment; no LiteMount replacement is needed.
[Investigation](docs/reference/COMBAT-ERROR-AUDIT-2026-10-13.md).
All 79 runtime/source checks and 66 tooling tests pass with exact current
inventories. [Qualification](evidence/test-results/candidate38-trace-qualification.json).
The final bounded build was installed October 14 at 00:02:27 Toronto from pushed
source `b89fa7dfa2d5837235a97e6ef411783f6ea7b9b8`, with only Forever selected while
WoW was open. A concurrent WTF save caused one safe refusal; its 53 newer files
were retained before a fresh retry. No vendor/WTF writes or game input.
[Readback](evidence/delivery/candidate38-independent-readback.json).

## Combat-error audit and observer repair — October 13, 2026

Candidate.37 guards passive action observations against opaque/unavailable reads
and fixes the blocked-action logger's Forever-only attribution filter. Automatic
evidence now aggregates all blamed addons with bounded public security labels;
native bars, cooldowns, input, retained data and retired targeting remain unchanged.
The captured 1,020 native cooldown errors have an unconfirmed original taint writer;
these source repairs do not claim that gameplay warning is resolved.
[Audit](docs/reference/COMBAT-ERROR-AUDIT-2026-10-13.md).
Installed at 00:58:18 Toronto from tested/pushed source
`4146195e5b126c6e4e1a606d21512e1e7ee8b26f`. Local qualification passed 78 runtime/source
checks and 66 tooling tests. Independent readback verified 55 installed files,
four product changes, 2,252 other addon files, 310 WTF files, 42 links/root anchors
and all 24,353 prior backup files preserved. WoW was closed; no game input or
dependency/WTF writes. [Receipt](evidence/delivery/candidate37-independent-readback.json).

## Ground targeting retired — October 12, 2026

Candidate.36 removes the Targeting tab, ground-placement interceptor, preference
model/registry, setup policy, scans and diagnostics under explicit user instruction.
Native action/macro slots, temporary routing, R3 ping, Circle and HUD remain.
Old saved data stay inert; schema/revision are unchanged. Retail performance and
input acceptance require user validation. [Report](docs/reference/TARGETING-RETIREMENT-2026-10-12.md).
Installed at 21:50:35 Toronto from tested/pushed source
`61a50ccb9a63e3275f1f708657de681bcae8292c`. Local and fresh Windows CI passed
76 runtime/source checks and 66 tooling tests with complete inventories matching.
Independent readback verified all 55 installed files, four module removals,
2,252 other addon files, 310 WTF files, 42 links/root anchors and all 23,982 prior
backup files preserved. [Receipt](evidence/delivery/candidate36-independent-readback.json).

## HUD performance update installed — October 12, 2026

Candidate.35 removes demonstrated redundant diagnostic
history copies, routine full skin/layout refreshes and unrelated routine event
initialization. Visual updates remain immediate; native secure/pressed/cooldown/
power ownership and configuration revision20 remain. Bounded optional callback
timing is disabled by default. New work-count/native lifecycle regression gates
retain old-defect negative controls. Retail CPU improvement and K04 acceptance
remain unverified. [Report](docs/reference/HUD-PERFORMANCE-2026-10-12.md).
Full qualification passed 76 runtime/source checks and 66 tooling tests.
[Receipt](evidence/test-results/candidate35-hud-qualification.json).
Installed at 19:52:51 Toronto from tested/pushed
`5359b52b92b5f4fb97178327f902f1203e31e9eb`. Independent readback verified 59 payload
files, eight runtime changes, 2,252 other addon files, 310 WTF files, 42 links and
23,611 prior backup files preserved. No dependency/WTF writes or game input.
User-owned reload activates the code; revision20 is retained.
[Installation](evidence/delivery/live-install-candidate35.json),
[readback](evidence/delivery/candidate35-independent-readback.json).
Fresh Windows CI passed the same 76/66 gates with complete inventories matching
local qualification. [CI receipt](evidence/test-results/candidate35-fresh-ci.json).

## Circle cast interruption accepted — October 12, 2026

The user confirms candidate.34 successfully interrupts casting. K03's reported
cast failure is resolved; earlier menu closure remains confirmed. Ground-placement
cancellation was not tested because the user reports targeting interception and
accepts that limitation. This does not assert channel/independent target or
exhaustive transition coverage, or exact Forever first-success behavior.
[Acceptance](evidence/circle/candidate34-live-acceptance-2026-10-12.json).
Fresh Windows CI also passed 72 runtime checks and 66 tooling tests, matching
the retained exact-source inventories. [CI receipt](evidence/test-results/candidate34-fresh-ci.json).

## Circle resource comparison repair deployed — October 12, 2026

Candidate.33 installed successfully, but saved revision19 retains the old CLICK
binding with a macro-edited deferral. The direct native route was not active in
that session. Candidate.34/revision20 reuses identical commands across CRLF/final
LF formatting without editing native macro bytes and adds automatic body-format
evidence. Genuine edits remain preserved; automatic review returns. Retail cast
interruption was unconfirmed at deployment; the later scoped acceptance above
resolves the reported cast failure.
[Investigation](docs/reference/CIRCLE-MACRO-FORMAT-2026-10-12.md).
Full qualification passed 72 runtime checks and 66 tooling tests, with 94 native
binding/log assertions and 328 retained legacy assertions.
Candidate.34 installed at 17:08:57 Toronto from tested/pushed source
`36466db91a88a97c4627cdf5863d8dbdd23de6ab`. Independent readback verified 59
payload files, three runtime changes, 2,617 other addon files, 308 WTF files,
42 links and all 23,242 prior backup files. No dependency/WTF writes or game input.
[Installation](evidence/delivery/live-install-candidate34.json),
[readback](evidence/delivery/candidate34-independent-readback.json).

## Native Circle binding and automatic evidence deployed — October 12, 2026

Candidate.32 installed/applied without errors but did not stop casting. Candidate.33
/revision19 proposes direct native MACRO binding for an owned legacy Circle,
reuses the saved resource and adds automatic bounded logs across four sessions per
GUID. Native input/UI/ring ownership and artwork remain. No live repair claim.
Standing permission now authorizes qualified updates while playing unless explicitly
prohibited. [Investigation](docs/reference/CIRCLE-NATIVE-BINDING-2026-10-12.md).
Candidate.33 installed at 16:33:01 Toronto from source `6797d0edbec48d8bc8247d37ddbbf3c73415b9f6`.
Independent readback preserved 2,617 other addon files, 308 installer-start WTF
files, 42 links and 22,873 prior backup files. Game writes between preflight and
installer start were captured and preserved. [Receipt](evidence/delivery/live-install-candidate33.json),
[readback](evidence/delivery/candidate33-independent-readback.json).

## Circle regression repair deployed — October 12, 2026

Candidate.32/revision 18 was installed at 15:08:29 Toronto while WoW ran, under
explicit current user authorization. It replaces forbidden RunMacroText with
reviewed native saved-macro RunMacro, retains inherited OnClick and restores
automatic login update review. Only four Forever files changed; 59 payload files,
2,617 unselected addon files, 308 WTF files, 42 links/root anchors and 22,504 prior
backup files were independently verified. No dependency/WTF writes or game input.
Local and fresh Windows CI passed 70 runtime checks/66 tooling tests, with 328
Circle assertions. User reload, macro review and Retail cast acceptance remain.
[Install](evidence/delivery/live-install-candidate32.json),
[readback](evidence/delivery/candidate32-independent-readback.json),
[investigation](docs/reference/CIRCLE-BLOCKED-ACTION-2026-10-12.md).

## Circle deployment â€” October 12, 2026

Candidate.31 was installed from tested/pushed source `a74aa8fd27ebb4e24b99ef580daeedab503235e9`.
Only Forever changed; 59 installed files matched the verified artifact.
Other addons, WTF, junctions/root anchors and retained backups passed independent
preservation readback. Circle activation still requires explicit `/cpf update`
review; actual Retail acceptance is pending. The installed source passed 69
runtime/source checks and 50 tooling tests.
[Readback](evidence/delivery/candidate31-independent-readback.json).

Fixed the pre-existing fresh-CI setup failure by retaining fully verified pinned
dependency archives/files in ignored test-input caches. Drift/foreign files are
rejected rather than repaired. Added seven regression tests; the complete local
entry point and fresh Windows CI pass 69 runtime/source suites and 57 tooling
tests, with matching exact inventories. No installed
addon or dependency-lock change.
[Qualification](evidence/test-results/candidate31-ci-inputs-qualification.json).

## Repository system â€” October 11, 2026

Candidate.31 source adds Circle-only reviewed secure cancel-all access for
an explicitly empty Base binding. It uses no Escape/menu or custom UI takeover,
preserves manual commands/removals and native Layers ownership, and makes the
first-success parity limit explicit. Configuration revision remains 17; schema 3.
Added native dispatch/review and original Forever callback oracle regressions.
[Research and implementation](docs/reference/CIRCLE-CANCEL-RESEARCH-2026-10-11.md).

Follow-up code/document reconciliation clarifies actual feature activation,
reviewed setup, binding-bank recovery, class-ring augmentation, early native ping
selection, visual composition and dormant UI routes. Added detailed configuration
and presentation references; retained stale source labels and historical designs
as explicit differences. No runtime change. See the
[source-linked findings](docs/reference/CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md).

Approved documentation/agent workflow restructure: concise current guidance,
requirements/architecture/controller/state/compatibility/development/testing/
issues pages, retained historical snapshots, sourced decisions and three
repository-local skills. Added read-only documentation validation to existing
checks/CI and the approved narrow docs-only dependency-check exception.
No runtime version, TOC, product files, live state or deployment changes.
See [decision](docs/decisions/0001-repository-development-system.md) and
[verification receipt](evidence/organization/2026-10-11/ai-native-restructure.json).

Earlier October 11 workspace organization imported OneDrive working material,
relocated user provisioning scripts and retained the native UI reference for a
later request. [Organization record](docs/WORKSPACE-ORGANIZATION-2026-10-11.md).

## Candidate.30 â€” October 10, 2026

Installed: release-only R3 dispatch, repeated native account-ring artwork lifecycle
and stable active gestures across unchanged refreshes. No down ping; cosmetic
timer does not gate protected dispatch. [Implementation](docs/CANDIDATE30-PING-RELEASE-LIFECYCLE-2026-10-10.md).
The user accepted reported ring and Required Items defects; broader cases remain
unclaimed. [Acceptance](evidence/forever-ui/candidate30-live-acceptance.json).

## Candidate.29 â€” October 10, 2026

Installed: Forever-owned deferred Immersion Required Items offset correction and
native saved Edit Mode reference tracking. Preserve Immersion bytes/settings and
manual/Party edits. Options-list request withdrawn.
[Implementation](docs/CANDIDATE29-IMMERSION-EDITMODE-2026-10-10.md).

## Candidates.28 and .27 â€” October 10, 2026

Candidate.28 was prepared but not installed: genuine Shared account ping ring;
its immediate-down behavior was later superseded by candidate.30.
[Native ring work](docs/CANDIDATE28-NATIVE-ACCOUNT-PING-RING-2026-10-10.md).

Candidate.27 installed: removed automatic action restoration; preserved native
editing/cache/held-action transitions and provided the then-functional hold-ring
path, now retained inactive outside runtime.
[Editing repair](docs/CANDIDATE27-HOLD-RING-AND-ACTION-GUARD-2026-10-10.md).

## Candidates.26 through .21 â€” October 9â€“10, 2026

Candidate.26 installed emergency Paladin recovery plus incomplete archive/stale
header repair and changed LiteMount/Plater packages. Its automatic writer was
subsequently removed; original quest-loss writer remains unconfirmed.
[Diagnosis](evidence/action-recovery/candidate26-diagnosis.json).

Candidate.25's restricted compiler repair was prepared, then included in .26.
Candidate.24/23/21 ping readiness claims did not establish successful Retail
behavior. Preserve their rejected/source evidence and compiler lessons.
[Compiler diagnosis](docs/CANDIDATE25-SILENT-PING-2026-10-10.md).
Candidate.22 restored all-class temporary native families to L2R2.
[Routing](docs/CANDIDATE22-TEMPORARY-ROUTING-2026-10-09.md).

## Candidates.20 through .10 â€” October 7â€“8, 2026

Native input recovery, independent repaired ground placement, actual round
surfaces/composition, class access, stationary trigger hints and native feedback
were iterated across these installations. Candidate.19 suppressed the wrong power
UI; .20 restored native power and character-owned class access.
[Power/class repair](docs/CANDIDATE20-AURA-RECOVERY-2026-10-08.md).
Candidate.17 has scoped visual acceptance.
[Composition](docs/CANDIDATE17-COMPOSITION-2026-10-08.md).

Earlier baseline/configuration/integration/dependency/delivery work remains in
the [history index](docs/reference/README.md). Add future entries for meaningful
behavior or compatibility changes; keep exact receipts out of operating rules.
