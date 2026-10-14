# Shared utility admission and disable-control investigation

Status: maintained
Reviewed: 2026-10-14
Evidence: [admission prototype](../../tests/prototypes/shared_utility_admission.lua),
[native-source harness](../../tests/harness/shared_utility_admission.lua),
[independent flag prototype](../../tests/prototypes/shared_utility_flag.lua),
[flag harness](../../tests/harness/shared_utility_flag.lua),
[runner](../../tools/test-all.cjs).

## Authority and outcome

This retained phase describes the rejected experimental adapter. The later
instruction requires continued fixes until manual testing is needed; candidate.39
implements and tests a replacement in the
[runtime continuation](SHARED-UTILITY-RING-RUNTIME-2026-10-14.md). Passing this
phase's defect-reproduction assertions does not describe the new runtime behavior.

The latest October 14 user instruction authorizes more useful tests when proof
is inconclusive, and implementation/deployment when sufficient qualification
exists. It requires a new feature to activate on first use and provide a
persistent slash-command disable followed by reload. No additional permission
is needed for that authorized implementation or qualified delivery. The earlier
offline-only restriction does not override this later instruction.

This continuation takes the additional-tests branch. Actual native-source
experiments reproduce four failures in the proposed admission adapter, so it
does not qualify for runtime activation or deployment. Changes stay under
tests/prototypes and tests/harness, the existing runner and maintained evidence/
documentation. Addon runtime, native addons, live configuration and installed
candidate.38 remain unchanged. No game launch, input, packaging or deployment
occurs. The independent flag is a tested contract, not an installed command.

All nine official stable Retail identities were freshly checked before changes;
they match the existing lock. No dependency package or lock change was needed.
The prior [archive proof](SHARED-UTILITY-RING-OFFLINE-PROTOTYPE-2026-10-14.md)
remains a separate retained result. Passing a counterexample test below means
the defect was reproduced; it does not mean the adapter is safe to deploy.

## Additional native-source experiments

T83 executes the same hash-verified ConsolePort 3.3.10 native source as T80,
including Container.OnDataLoaded, validation, RunSafe/RefreshAll, SPELLS_CHANGED,
cursor insertion, removal, configuration drag and confirmed Clear. C APIs,
event delivery, frames and protected action storage remain modeled. No native
function is replaced in the installed addon or immutable source. The isolated
Lua admission experiment temporarily decorates the fixture's ordinary validator
and spell event method, then restores them.

| Experiment | Observed result | Implementation consequence |
| --- | --- | --- |
| Post-refresh reconciliation with missing spell metadata | Native prints one removal message before the callback. | A posthook cannot establish silent prevalidation. |
| Earlier validation adapter with a stale availability cache | One removal message still appears. | Invalidation must precede the native event's immediate refresh. |
| Synchronous SPELLS_CHANGED invalidation in the admission experiment | Tested uncached/spec/class transitions produce zero messages; saved choices return. | This particular ordering is demonstrated offline, not a qualified runtime hook. |
| Native RemoveAction and cursor insertion | Deletion survives spec returns; insertion is captured before validation. | Stable active-entry IDs can reconcile these paths. |
| Actual native SetDragEntry completion | Direct reorder is captured without relying on OnSetChanged. | Completed direct edits require their own observed boundary. |
| Confirmed native Clear, with dormant choices | Recognizing the native wipe removes visible and hidden choices; cancel/opening the prompt changes nothing. | An ordinary visible-entry diff cannot implement global Clear. |
| Other personal/shared sets | Class and account Ping content remain equal. | Admission must remain restricted to the managed default utility set. |

The qualified subsection performs 15 admissions and recognizes three completed
edits. These are counts across deliberate operations, not idle work, mock timing
or a CPU-performance estimate. T84 removes the synchronous invalidation and
explicit-clear handling separately; both mutants fail their intended assertions.

## Reproduced integration blockers

1. **Open wheel:** the synchronous validator bypasses the model worker's
   blocked/open-wheel guard. An actual native SPELLS_CHANGED/RefreshAll call
   changes the utility projection while the fixture wheel is open. Waiting in
   a deferred Forever worker alone cannot prevent that synchronous path. The
   next adapter must qualify the native setup/rebuild boundary and preserve
   held selection/release, immediate native feedback, combat queues and edits;
   adding a timer or another posthook is not sufficient.
2. **Late startup:** native Container.OnDataLoaded sets validation readiness and
   immediately queues/runs refresh when IsLoggedIn is true. Attaching admission
   afterward cannot undo the one already-emitted message. Establish an early
   supported readiness/loading seam, including saved-variable loading and
   native loader consumption; do not infer its order from a successful late
   full Forever refresh.
3. **Existing native choices:** the limited spell/item import drops a real
   GetStarterSet custom UNITMENU binding. The migration must preserve native
   menu/ring commands and qualify each collection, pet, equipment and macro
   identity or retain it explicitly as unresolved. It cannot silently apply
   the limited prototype to a complete existing ring.
4. **Unknown context:** the admission experiment calls its raw context getter
   rather than the model's guarded context path; a modeled opaque GUID is
   accepted as projection owner. Every synchronous entry point needs public
   value/readiness/context/revision checks before comparisons or classification.
   Pending identity must preserve saved choices and prevent stale dispatch.

These are demonstrated defects of the experimental admission adapter, not new
claims about live engine state or the root cause of existing K04/K05 reports.
Their assertions deliberately retain the failing behavior as counterexamples
until a replacement admission design supplies meaningful defect rejection.
Retail taint, hardware timing, rendering and actual CPU attribution remain
unproved by this ordinary Lua model. The restricted native compiler must qualify
any future changed secure bodies; none are changed in this phase.

## Feature flag contract and remaining wiring

T85 tests an account-level sharedUtilityEnabled boolean separately from feature
construction and archive state. First eligible use initializes an absent value
to true. An explicit false is preserved. Ineligible startup creates no flag and
calls no constructor. A constructor exception and malformed feature archive do
not prevent the independent off operation. GUID archives and shared choices are
unchanged. One hundred eligible retries invoke a rejected constructor only once
in the session, containing initialization error/CPU loops. A deliberate
unconditional first-use re-enable mutant is rejected.
T86 serializes the disabled account and loads a fresh Lua VM with the flag module
alone: startup calls no feature constructor, and explicit on/off remain usable.

The planned runtime interface is `/cpfutility off`, then `/reload`, with
`/cpfutility on` plus reload and `/cpfutility status` for recovery/inspection.
These commands **are not installed yet**. The standalone command bootstrap
should load before optional feature initialization and register independently of
the normal refresh/setup path. A failing feature constructor must not remove the
escape hatch. Persist false through the ordinary in-game SavedVariables lifecycle;
never edit live WTF on disk. On the disabled reload install no feature hooks,
workers, classifier or projection adapter, preserve the shared archive and use
the qualified prior character/native utility view. Re-enabling must not import
that fallback as deletions of dormant shared choices.

The flag tests do not yet exercise a production slash handler, hook installation,
queued-worker shutdown, a native fallback projection or foreign-edit rollback.
Those are runtime integration gates, not conclusions manufactured from a boolean
test. The archive proof's bounded workers/receipts and item-domain operation
limits remain required alongside these new admission gates.

## Validation record

The complete Test-All and documentation checks qualify this test/evidence change,
not the experimental feature. Exact final reports and current inventory/hash
checks are recorded in the [admission receipt](../../evidence/utility-ring/admission-2026-10-14.json).
No runtime release identity, installed slash command or Retail acceptance is
claimed. Continue implementation only after these reproduced boundary failures
are rejected by the replacement adapter and the flag's actual native lifecycle
is qualified; user authorization for that work is already present.
