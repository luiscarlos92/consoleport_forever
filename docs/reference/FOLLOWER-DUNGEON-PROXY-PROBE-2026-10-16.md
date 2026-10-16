# Follower control: custom binding and native proxy experiment

Status: maintained
Reviewed: 2026-10-16
Evidence: [prototype](../../tests/prototypes/follower_proxy.lua),
[native-chain harness](../../tests/harness/follower_proxy.lua),
[source captures](../../evidence/follower-dungeons/2026-10-16/proxy-source-manifest.json),
[qualification receipt](../../evidence/follower-dungeons/2026-10-16/proxy-qualification.json).

## Scope and result

The user's October 16 continuation authorizes the next proposed isolated
experiment: existing custom binding, named secure proxy, native follower button,
with missing/changed delegates and permission failures. It does not skip the
original investigation-before-addon-implementation boundary. The new prototype
is outside the addon TOC; installed files, addon Lua, native sources, live WTF
and game input remain unchanged.

The represented command chain works under the permitted C-API model. It is
**not qualified for runtime integration**: native pooled-button reuse can change
the ability it casts; replacing the native saved entry allows automatic
re-addition of the plain spell; and disabling the proxy in combat avoids the
stale reference only by removing combat access. Retail macro restrictions,
taint, native pool event ordering and actual follower command behavior remain
unproved. No new combat limitation is adopted as product behavior.

During this experiment the user clarified the affected gesture: open the ring,
move selection to Dungeon Assistance, then release to activate. The resulting
lead/follow choice feels unpredictable. This is a direct user report about the
release-selection path, not a separate confirm-button report. It does not
establish whether Retail delivers an extra release or how many spell calls occur.
The ordinary paired-release cases already exercised offline did not reproduce
the reported unpredictability. See the [gesture observation](../../evidence/follower-dungeons/2026-10-16/user-gesture-observation.json).

## Executed source and modeled boundary

T93/T94 reuse the previous actual native restricted ring fixture. They add the
pinned Blizzard `/click` slash handler, actual ConsolePort action-map spell
factory, RelaTable deep comparison and zone auto-assignment. New snapshots are
separate from the original immutable native manifest. Selected official package
inputs are verified against ConsolePort 3.3.10's lock before execution.

The command path is:

1. A serializable temporary ring entry contains a custom `CLICK name:LeftButton`
   binding, with no frame object in saved ring data.
2. Actual native `Model/Map.lua` constructs the LAB description and secure
   `/click name LeftButton` macro payload.
3. Actual restricted ring selection/commit and Blizzard macro dispatch reach
   `C_Macro.RunMacroText`.
4. A deliberately narrow C macro tokenizer model forwards that single command
   to Blizzard's actual `/click` handler.
5. That handler resolves/checks the named proxy and requests a release click.
   The proxy's native secure click action checks and invokes the native zone
   button, preserving its explicit toggle argument.

Frame creation, Button:Click/GetClickFrame, macro authorization/tokenization,
option parsing, StringToBoolean, spell metadata, state-driver notification and
input sampling remain host models. The fixed macro has no conditions or extra
lines. The permitted macro model is a hypothesis input, not proof of Retail
permission. A second model rejects macrotext and must produce zero spell casts,
with no generic cast fallback or bypass. Native announcement visuals/sound are
excluded from the auto-assignment counterexample.

The pinned [slash handler](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ChatFrameBase/Shared/SlashCommands.lua)
uses explicit boolean parsing and checks access constraints plus forbidden
scripted-input aspects. Older online examples about `/click` edge parsing do
not replace this source contract. The captured UIMacros API documentation marks
`C_Macro.RunMacroText` as restricted; offline success cannot waive that boundary.

## Results and counterexamples

| Case | Observed offline result | Meaning |
| --- | --- | --- |
| 96 selected gestures: adapter absent/present, hold/toggle, both key-down settings and four modifier states | One macro invocation and one native toggle call per selected gesture. | The existing representation can carry the chain under modeled permissions. |
| Neutral nonsticky gesture | No command. | No unconditional activation was added. |
| Proxy or delegate access/forbidden predicate | No cast. | Both native source guards are exercised; neither is bypassed. |
| Missing, outside-follower, ambiguous, opaque-context or foreign-handler delegate | Public reconciliation clears the proxy outside combat; subsequent selection does not cast. | Failure cases do not silently keep an old delegate. |
| Native `SetContent` reuses the borrowed frame for another spell, before reconciliation | One cast of the other spell. | A frame pointer alone is not follower identity. This is a genuine source-level counterexample, not an NPC-AI model. |
| Out-of-combat reconciliation, then a different native follower frame appears | Stale delegate is removed and the new matching frame can be bound. | Controlled replacement works at the tested setup boundary; automatic hooks/event order remain unqualified. |
| Predeclared secure clear on combat entry and again on return | Pool reuse does not cast; peace does not re-enable an old pointer before reconciliation. | The conservative experiment is safe for this case by disabling combat access. It does not satisfy the full product requirement. |
| Macro engine rejects the command | Error is retained; zero casts and no secondary fallback. | Engine permission is a real remaining boundary. |
| Actual native zone auto-assignment runs after its saved spell row was replaced by a custom row | The original plain spell is appended alongside the custom entry. | Replacing the authoritative entry is not a stable integration. |

Four fault controls must be rejected: wrong `/click` edge, missing secure
transition clearing, stale public reference retention and disabling the native
auto-add in the counterexample. The last control verifies that the observed
duplicate row depends on executing real native auto-assignment.

## Why combat pool reuse remains unresolved

Blizzard's zone button is pooled and its native `SetContent` changes the spell
used by its native OnClick. A public reconciliation callback cannot update a
protected proxy's click target during combat. Nor can a restricted snippet
simply inspect arbitrary native Lua fields or call GetSpellID and receive a
public method's result as secure authorization. Pinned RestrictedFrames access
rules also restrict methods on unprotected handles during combat.

The prototype therefore predeclares a secure state driver that clears both
`typerelease` and `clickbutton` on combat transitions. It does not auto-enable
on peace: a fresh public identity check is required. This exposes a tradeoff;
it does not settle it. Do not integrate the prototype and silently describe
disabled combat control as a completed fix.

This counterexample does not prove that the reported dungeon actually reused
the follower frame during combat. It shows that the native source contract does
not give the lifetime guarantee required by the proposed borrowed-frame design.

## Revised implementation direction

Keep the standalone follower control available while these boundaries remain.
Do not install a global ring debounce, copy protected casting into public
callbacks, change upstream code, or invent a new player action slot.

The duplicate-row problem has a more appropriate source-level direction:
preserve native authoritative entry identity and investigate adapting only its
compiled/presentation result. Native `AddSecureAction` already distinguishes
source info from mapped secure extra info. That is a design candidate for a
later isolated admission experiment, not a qualified adapter in this prototype.
It would still need matching removal/re-entry, ownership and manual-edit tests.

The borrowed pooled delegate remains the harder issue. Before choosing it over
the existing direct spell route, obtain the smallest discriminating Retail
observation from the preceding execution report: a second deliberate selection
after cooldown, its delivered press/release/command count, and comparison with
the native button's toggle result. The missing toggle argument is still not
proved to cause the user's reversal. If extra input is demonstrated, investigate
a narrow secure gesture guard on the existing route; do not assume delegation
is necessary merely because its handler has a different argument list.

No game input or new live instrumentation was performed. Any later observation
must preserve secure ownership and avoid wrapping protected cast functions or
tainting native callbacks. Existing K05 taint evidence is not permission to add
another speculative observer.

## Verification and stopping boundary

The receipt distinguishes local tests, complete input inventories and C/engine
limits. The earlier [execution probe](FOLLOWER-DUNGEON-EXECUTION-PROBE-2026-10-16.md)
remains an exact historical checkpoint; its 92/66 reports are not current-source
receipts after adding this prototype. T93/T94 do not ship runtime functionality.
The experiment's outcome is a supported serialized command chain plus two
reproduced integration counterexamples, not a follower-control repair.

At this checkpoint `./tools/Test-All.ps1` passed all 94 runtime/source checks
and 66 tooling tests, including all four proxy fault controls. Independent
readback verified every current hash and complete inventory: 62 addon files
and 148 tool/test files, plus all 18 research source captures. Maintained
documentation validation passed for 50 pages/skill files. These counts describe
this source checkpoint, not fixed requirements for future runs.

The retained [runtime/source report](../../evidence/follower-dungeons/2026-10-16/proxy-runtime-results.json)
and [tooling report](../../evidence/follower-dungeons/2026-10-16/proxy-tooling-results.json)
have checksums in the qualification receipt. No addon, locked dependency,
upstream, installed file or live WTF change, game input, packaging or delivery
was performed. Retail engine permission, rendering, taint, hardware timing and
the user's actual reversal remain outside these offline results.

The [subsequent admission/presentation/boundary experiments](FOLLOWER-DUNGEON-ADMISSION-BOUNDARIES-2026-10-16.md)
preserve native saved identity and LAB spell feedback while separating compiled
metadata, and exercise the actual restricted authority limits. The pooled
delegate and live release/toggle cause remain unresolved; this proxy checkpoint
does not become a runtime repair through those later results.
