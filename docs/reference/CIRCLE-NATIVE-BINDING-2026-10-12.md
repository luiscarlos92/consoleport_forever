# Circle silent failure, native binding and automatic evidence

Status: maintained
Reviewed: 2026-10-12
Evidence: [user report and sanitized saved evidence](../../evidence/circle/candidate32-silent-failure-2026-10-12.json),
[Circle source](../../addon/ConsolePort_Forever/Circle.lua),
[native row/log tests](../../tests/harness/circle_native_binding.lua),
[automatic event tests](../../tests/harness/circle_logging_bootstrap.lua).

## Established observation

The user accepted Use proposed and Apply in candidate.32. Menus close and the
protected popup is absent, but Circle does not interrupt casting. Read-only saved
data confirms revision 18, a committed macro resource, the expected native cached
body, the reviewed legacy CLICK binding and an offline-verified feature claim.
These are persisted observations, not live effective-binding or engine snapshots.
The supplied image shows old rolled-back journal IDs, not the current Circle
state. A later resource journal is committed; the install was not declined.

The precise live owner, key edge, modifier state and whether the intermediate
button/RunMacro ran remain unknown. Candidate.32's passing test directly claimed
the CPF button in native Layers. It covered that claim and native click functions,
but did not exercise how the actual saved command is mirrored into the native row.
Readiness and absence of a protected warning do not demonstrate cancellation.

## Candidate.33 source repair

Revision 19 offers `MACRO CPF Circle` directly through the existing native binding
adapter and ConsolePort saved row. This removes the intermediate addon button from
the new gameplay route. No new input layer, override claim, protected public callback,
Escape command or CVar change is introduced. The saved cancel-all macro body is
unchanged; its exact existing account resource is reused without editing or taking
another slot. Cast, ground placement and hard target cancellation remain combined;
exact Forever first-success ordering remains gated.

Blizzard's pinned
[restricted frame macro binding](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua)
delegates string/number macro arguments to native SetOverrideBindingMacro.
The [BindPad author's API examples](https://github.com/Stanzilla/BindPad)
also use native SetBindingMacro and saved bindings. Native ConsolePort
OnNewBindings stores the command as a binding, ApplyRow claims the current row,
and Resolve uses the existing native binding writer. These establish the supported
route and inspected source behavior, not Retail cancellation acceptance.

Automatic review changes only an empty Circle or an exact legacy CLICK command
matching the character's managed controller baseline. A non-owned/manual command
is preserved. The migration requires Use proposed and Apply; startup/hydration
does not silently convert the old binding. Keep retains the legacy helper and
its historical coverage. Native UI/ring priorities and modified actions remain.
The native engine owns macro execution and its key timing. T71 models a single
press edge; it does not certify real engine timing from a Lua host.

Resource checks govern proposals and report missing/edited/duplicate macros.
Once a native MACRO binding is accepted, native macro edits/deletion retain their
ordinary engine semantics. Forever does not rebind, reconstruct, edit or delete
user changes to prevent them. This differs from disabling the old helper's type
attribute after a resource edit. Both legacy and direct bindings retain the exit
artwork; round composition and native feedback remain independently tested.

## Automatic logs

The user requests logs instead of another diagnose command. Login refresh installs
secure post-hooks for native RunMacro/SpellStopCasting/SpellStopTargeting/ClearTarget.
They observe completed calls and never invoke protected actions. Player cast/channel
events, modifier events, binding snapshots and logout are recorded automatically.
Spell IDs, cast GUIDs, names, destinations and targets are not logged. Secret or
unavailable getter values remain unknown; false modifier states remain false.
Hooks are optional: a failed observer installation cannot stop normal refresh.

Each GUID retains at most four sessions, with at most 80 rows per session and
aggregate native call counts. Previous-session evidence survives a new UI session.
The current log is also in lastRuntimeDiagnostics.circle. WoW writes SavedVariables
on reload/logout; addons cannot write an arbitrary external logfile or force an
immediate disk flush. The agent reads those files without requesting /cpf diagnose.
Calls may originate from other native controls; they are correlated observations,
not proof that Circle was the caller or that a cast actually stopped.

T71 runs actual native OnNewBindings/ApplyRow/Resolve and modeled C macro dispatch,
plus owner/modifier, manual binding, secret/false logging, repeated hooks, bounded
session retention and GUID separation. Negative controls reintroduce the legacy
route, remove migration, erase false states, remove persistence or bounds.
T72 runs real bootstrap/event/Persist calls without the slash command. T70 covers
the exact accepted revision-18 legacy record and macro-preserving binding Apply.
T68 retains the old helper/provenance/macrotext defect coverage rather than deleting
it. Full existing regression gates and Retail limitations still apply.

The full gate passed 72 runtime checks and 66 tooling tests, with exact inventories
of 62 product and 130 tooling/test files. The 328 legacy Circle assertions remain;
T71 adds 60 native binding/log assertions and T72 checks bootstrap persistence.
[Runtime](../../evidence/test-results/candidate33-native-circle-runtime.json),
[tooling](../../evidence/test-results/candidate33-native-circle-tooling.json) and
[qualification](../../evidence/test-results/candidate33-native-circle-qualification.json)
retain proof and limits. These results do not establish the live failure's cause.

## Deployment authority

The later user instruction grants standing qualified companion deployment while
playing unless explicitly prohibited. It supersedes one-off permission expiry for
these updates and remains active until revoked. Existing exact-source, schema,
payload, backup and readback guards remain. No game input, direct WTF writes,
dependency replacement or restore is covered by the running-companion mechanism.
See [decision 0004](../decisions/0004-scoped-delivery.md).
