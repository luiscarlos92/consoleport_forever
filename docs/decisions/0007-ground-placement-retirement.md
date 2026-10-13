# 0007: Retire Forever ground placement until explicitly requested again

Status: maintained
Reviewed: 2026-10-12
Evidence: [confirmed requirement R05](../REQUIREMENTS.md),
[retirement and delivery](../reference/TARGETING-RETIREMENT-2026-10-12.md),
[user observation](../../evidence/targeting/retirement-user-observation-2026-10-12.json).

## Authority and decision

On October 12 the user requested a complete purge of Forever's Targeting tab and
its ground-placement behavior, then confirmed the enumerated removal scope.
After delivery the user reports "generally seems to be working" and explicitly
asks that documentation prevent an accidental comeback, with commit and push.

This is a standing exclusion, not a temporarily disabled feature or an unfinished
parity goal. Do not restore the tab, interceptor, preference model, spell registry,
setup policy, observation scans, command preparation, secure wrappers or diagnostic
hooks. An equivalent Forever implementation using automatic macro creation or
spell replacement is also outside scope. Reinstatement requires a new explicit
user request authorizing that feature and an updated requirement/decision.

## Context and scope

The user prefers other addons for this purpose. Earlier callback evidence located
100 ms-class stalls inside mode refresh, which included both temporary routing and
ground preparation. It did not isolate the ground adapter's contribution. Removal
is an explicit product decision; it does not prove every performance spike resolved.

Preserve native ConsolePort input, native ground reticles and user/external-addon-
owned macro slots. R3 ping, Circle cancellation, temporary vehicle/skyriding/
override routing, HUD artwork and feedback remain separate supported features.
Shared targeting-named artwork and the existing Ping module path are not permission
to restore placement. Old saved preferences, observations, policy values, managed
fields and journals remain inert; neither their existence nor a true flag enables
or authorizes this feature. Do not edit live WTF to erase historical data.

## Supersession and future work

This supersedes the ground-placement clause of [decision 0002](0002-native-execution-and-proof.md),
the former R05 preservation requirement and older placement acceptance/designs.
Other native ownership, secure execution, preservation and delivery rules remain.
Historical reports, immutable references, old fixtures and backups are evidence,
not an implementation backlog. General bug repair, optimization, dependency work,
parity completion or rollback instructions do not authorize reviving placement.

Keep T12 retirement/data preservation, T38 product absence and T42 native dispatch
as mandatory gates. Do not remove or repurpose them merely to make a restoration
pass. Temporary routing, ping, Circle and HUD regression coverage remain required
for affected changes. [Testing](../TESTING.md) owns their actual proof boundaries.

The general working report is scoped user feedback after candidate.36 delivery.
It is not measured CPU improvement or exhaustive input/visual/taint acceptance.
No runtime change, package rebuild or installation accompanies this documentation
decision.

## Alternatives

A saved off toggle, dormant placement code, or a cheaper replacement inside
Forever would retain a route for accidental activation and would not satisfy the
confirmed purge. Keeping historical evidence and inert saved data preserves
recovery information without making the feature active or planned again.
