# Follower control: isolated native execution experiment

Status: maintained
Reviewed: 2026-10-16
Evidence: [experiment harness](../../tests/harness/follower_execution.lua),
[runner](../../tools/test-all.cjs),
[execution receipt](../../evidence/follower-dungeons/2026-10-16/isolated-execution.json),
[initial investigation](../plans/FOLLOWER-DUNGEON-CONTROLS-2026-10-16.md).

## Authority and question

The October 16 follow-up authorizes validating the hypotheses, building the
isolated execution reproducer and checking online implementation guidance.
This experiment adds test tooling and documentation; it changes no addon Lua,
TOC, protected runtime handler, installed addon, dependency lock or live WTF.
No game input occurred. No repair is installed or Retail accepted.

The hypotheses are separate: generic spell presentation can miss the native
zone icon; missing toggle handling may affect the follower command; or repeated
input dispatch may issue more than one command. The experiment must not implement
an assumed follower state machine and then present that assumption as a discovery.

## Actual source versus modeled boundary

The existing native account-ring fixture now has a reusable builder. Its original
T65 checks remain intact. The follower variant executes ConsolePort 3.3.10's
Database, Map, Container, restricted ring controller, Layers/Radial selection and
frontend; Blizzard's pinned restricted compiler, Wrapped_Click and secure spell/
click dispatch; and the actual Forever shared utility model/admission adapter.
The new zone-button source is verified against its research capture manifest.

Blizzard's full modified-attribute lookup replaces the earlier fixture's simple
lookup in this variant, allowing modifier/button suffix tests. Native GetIndex
and radial deadzone/angle calculations run against modeled stick samples.
The native modal accept binding supplies the accepted click slug.

Frame creation/C methods, physical events, stick samples, spell metadata, combat
flags, access/forbidden predicates, and CastSpellByID are explicit doubles.
CastSpellByID only records arguments and checks modeled authority. It does not
pretend to implement the spell, aura/server toggle, native cooldown or NPC AI.
The direct native zone handler is treated as Blizzard-trusted source by the host;
that models provenance, not a Retail taint qualification for an addon bridge.

The pinned compiler rejects a deliberately illegal direct-table snippet. Fault
variants additionally duplicate generic dispatch, retain stale release type,
remove the native toggle request or bypass a native click access predicate.
Each must fail its intended behavioral assertion; green baseline alone is not
sufficient evidence that the observer can detect a fault.

## Findings

### Ordinary paired selection did not double-dispatch

The 320-case matrix covers adapter absent/present, modeled combat/peace,
hold/toggle opening, sticky on/off, no/Shift/Ctrl/Alt/Ctrl+Shift modifiers, three
successive selected gestures and a neutral gesture per combination. Each adapter
phase records 140 casts, including the expected sticky-neutral repeats. Every
deliberate selected gesture reaches the generic secure cast path once.

Additional cases cover held-wheel context reconciliation, repeated reopening,
the native separate accept key, neutral cancellation and a further ordinary
selected gesture. The adapter preserves the transient spell outside its manual
archive and does not introduce a cast during held reconciliation.

This rejects a simple claim that the inspected normal hold/release path always
casts twice, or that the shared adapter necessarily introduces the double call.
It does not establish the user's live effective input/event stream.

### An injected extra release can commit again

After a completed hold-mode selection, the test deliberately replays another
release while the modeled stick remains deflected. The actual native Commit
path selects again and issues one additional cast. Its source checks LAST versus
the incoming button, but has no shown/armed prerequisite at this point; the
radial getter can still resolve the deflected stick while the ring is closed.

This is a conditional counterexample, not a reproduction from one normal paired
physical gesture. It does not prove that controller hardware, native bindings,
modal handoff or another addon supplies that extra release in Retail. Do not
translate it into a blanket timer debounce or a global ConsolePort modification.
The retained duplicate-dispatch and stale-release fault controls show that the
fixture detects more than one command under a normal gesture when introduced.

### The toggle-argument difference survives complete dispatch

Every generic numeric spell command in this experiment reaches
`CastSpellByID(spellID, unit)` with two arguments. The actual native zone handler
reaches `CastSpellByID(baseSpellID, nil, true)` with three. Both call once.
There is still no source-only proof that omitting the third argument explains
the user's opposite/immediate-stop outcome. Its behavior is inside the Retail
C/server boundary, which this experiment intentionally does not invent.

The initial generic-versus-zone icon dry run remains valid and independent of
that unresolved execution diagnosis.

### Native click delegation is only a partial candidate

A test-only preconfigured secure proxy uses Blizzard's actual secure click
handler to invoke the native zone handler. With modeled access permitted, one
release invokes it once and preserves `tryToggleSpell=true`, in modeled peace
and combat. When access constraints or forbidden scripted-input aspects are
modeled present, it dispatches zero times. No generic cast fallback is added.

However, `env:GetKindAndAction({type='click', ...})` is unsupported by the native
ring map. A proxy passing this direct dispatch experiment does not provide a
qualified ring data format, pooled-button reference lifecycle, secret-safe
identity guard or actual Retail combat authority. Do not put live frame objects
into the serializable shared archive. Integration must solve those boundaries
before this candidate can replace the existing ring route.

The existing native custom-binding path is a concrete representation candidate:
`Model/Map.lua:GetCustomAction` converts `CLICK name:button` to a native `/click`
payload. A named, predeclared proxy could therefore be investigated through that
existing map rather than introducing an unsupported direct click kind. This
experiment has not qualified the macro-to-proxy chain, dynamic pooled delegate
references, later metadata/icon writes or engine permission/taint behavior.

## Online guidance and source conclusions

No matching upstream fix was located in the selected issue searches. The useful
primary guidance is the code itself:

- [Blizzard zone button](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ZoneAbility/ZoneAbility.lua)
  defines the zone-specific icon and explicit toggle request.
- [Blizzard secure action templates](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)
  define release dispatch and access-checked click delegation.
- [ConsolePort ring controller](https://github.com/seblindfors/ConsolePort/blob/3.3.10/ConsolePort_Rings/Controller/Secure.lua)
  defines Main/Hold/Toggle/Commit and the clear-before-routing behavior.

General macro recipes do not qualify pooled anonymous zone-button references,
Retail scripted-input constraints or this project's native ownership boundary.
No internet recipe was copied into the addon.

Fresh discovery inspected all nine official stable sources. ConsolePort remains
3.3.10; BetterBags v0.5.16, Plater-v661 and DynamicCam 2.21.2 differ from the lock.
[Discovery receipt](../../evidence/dependencies/stable-recheck.json).
The isolated experiment uses the pinned source identities, without downloading,
qualifying or installing those unrelated updates. `allCurrent=false` remains
explicit: this experiment is not release/dependency qualification. Resolve and
qualify the actual updates in the appropriate subsequent development/delivery
stage; do not package a claim that all dependencies are current.

## Next discriminating work

At this first execution checkpoint, the local `./tools/Test-All.ps1` run passed 92 runtime/source checks
and 66 tooling tests, including T91/T92's four deliberate fault controls. The
retained reports matched every then-current file in the complete 62-product-file and
146-tool/test-file inventories. Documentation validation passes for 49 maintained
files. These counts describe this exact experiment, not a future fixed gate.
The probe records 321 gesture-helper runs plus separate held/accept/replay cases,
971 modeled input edges and 1,551 assertions. None are Retail acceptance.

Before addon integration, test the existing custom-binding-to-named-proxy path
and a guarded native delegate lifecycle, including pool reuse and disabled/
unavailable fallback. Preserve ordinary secure input and avoid global handler replacement.
Retain the stock follower button until the replacement is usable. Selective
hiding and composed visuals remain later independent gates.

The smallest Retail observation needed to establish execution causation is a
single second selection after the native cooldown: did one or two commands
reach the cast route, and was a second release delivered without a matching new
press? Compare with the native zone button's own toggle outcome. Any future
observation must be narrowly bounded, avoid wrapping/replacing native secure
functions or protected-action calls in public callbacks, and stay within current
user authorization. The user has not requested game input or a new live test in
this experiment; none was performed.

The [subsequent proxy-chain experiment](FOLLOWER-DUNGEON-PROXY-PROBE-2026-10-16.md)
executes the proposed representation and reproduces pooled-target reuse plus
native automatic re-addition. Its conservative combat disable is not adopted
as product behavior. This first checkpoint's receipts remain historical.

The result is a repeatable source experiment with a conditional replay case
and a narrower diagnosis. It is not a completed or accepted follower-control fix.
