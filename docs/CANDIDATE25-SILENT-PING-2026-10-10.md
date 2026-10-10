# Candidate.25: silent ping diagnosis, checkout only

The user is playing and explicitly forbids deployment. Candidate.24 remains
installed. This repair and the two dependency updates are prepared only in the
product checkout. No installer, reload, game input or live WTF write is performed.

The user's useful observation is that holding ping shows **nothing**. That puts
the failure before the selector opens, rather than merely at the point where
Blizzard sends a ping.

The pair review found a deterministic error in the deployed press snippet:

```lua
for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
```

That is valid ordinary Lua, but it is invalid inside Blizzard's restricted
handler. `BuildRestrictedClosure` rejects any body containing `{` or `}` before
executing it, with `Direct table creation is not permitted`. Consequently the
handler cannot reach its Show, targeting or macro dispatch. This accounts for
the missing selector and ping. It is a Lua compilation error, distinct from an
addon protected-action popup; a user's absence of a visible Lua error panel
does not establish that the handler compiled.

We reproduced the rejection using the unchanged Blizzard-authored compiler and
the exact deployed source from commit
`28429e5db4cf7fe66d83aa485fa1d3d5c7cd1058`. We did not infer it from a hypothetical
mouse position or declare another ordinary-Lua test pass to be engine proof.

The runtime ping fix is one line:

```lua
for _,name in ipairs(newtable('Cursor','Raid','TargetRing')) do
```

`newtable` is the restricted environment's supported table constructor. The
three owners and their order are unchanged. Native secure macro execution,
soft-unit `exists` checks, ground `@cursor` UI bypass, selection, cancellation,
native Layers priority and competing radial ownership remain as in candidate.24.
There is no return to an insecure addon ping call or plain ground `/ping`.

The earlier test host compiled restricted bodies with ordinary Lua `load`. It
therefore accepted the table literal that Retail rejects. Both agents reject
their earlier candidate.24 readiness conclusion in light of this omitted
boundary. Its retained reports describe historical passes, not live acceptance.

T60 now compiles **every** restricted execution in this fixture through the
unchanged pinned `SelfScrub` and `BuildRestrictedClosure` implementation. A narrow
private host adapter supplies Lua 5.1 `setfenv` behavior to Fengari's Lua 5.3 VM.
It is outside the restricted snippet environment. Tests check independent
environment isolation, correct handle scrubbing, unavailable host/debug/load
helpers, invalid signatures and forbidden function declarations. The old table
literal is a mandatory regression which must fail with the native error.

The test still models C APIs, full secret-value/taint tagging, controller sampling,
macro option parsing and actual cursor timing. Those remain Retail acceptance
limits. In particular, we do not label artificial delayed button-state examples
as evidence of the user's live input order. The source compiler failure is
independently established regardless of those unknowns.

The mandatory fresh dependency check found LiteMount `12.1.0-2` and Plater `v658`.
Only those official packages were downloaded into the checkout. All nine sources
now match the new lock. Review found unchanged native mount button/action and
ConsolePort icon contracts; the adapter accepts both audited LiteMount versions.
The two-version icon tests pass. New Lua files parse under Lua 5.1; Retail closure,
coverage and original notices are qualified. AceDB now uses unmodified player
names and has an additional non-Retail naming branch; LibSharedMedia now errors
on missing media registrations. The changed upstream sources remain unmodified.
Any future authorized scoped update must include both changed packages; none is
copied into the running installation in this task.

TemporaryRouting.lua and Ground.lua remain byte-identical to installed
candidate.24. Revision 17, saved settings/bindings, class rings and accepted bar
rendering remain. The full runtime/source and tooling suites remain the final
qualification gate, including all 4,160 class/temporary-state/chord cases.

The source evidence is Blizzard's [restricted compiler](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedExecution.lua)
and ConsolePort's unmodified secure conversion/contracts in
`evidence/consoleport-contracts`. The same compiler rejection was also verified
against the freshly inspected live source on October 10.

Actual candidate.25 gameplay remains NOT RUN and it is NOT DEPLOYED.

Final local qualification: all 62 runtime/source suites and 39 tooling tests pass
for the frozen product/tooling hashes. T60 includes 15 mandatory defect mutations
and runs the actual restricted compiler for each secure body execution. T61/T62
retain all-character temporary-bank and startup coverage. Exact reports are
evidence/test-results/candidate25-runtime.json and candidate25-tooling.json.

Both the implementing agent and the root reviewing agent independently ACCEPT
the compiler repair and preparation readiness after checking the frozen sources
against these complete reports. The verdict qualifies this concrete source
repair for a future user test; it does not claim observed Retail success.
