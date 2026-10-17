# Follower dungeon candidate.40

Status: maintained
Reviewed: 2026-10-16
Evidence: [implementation](../../addon/ConsolePort_Forever/Rings/FollowerDungeon.lua),
[native execution](FOLLOWER-DUNGEON-EXECUTION-PROBE-2026-10-16.md),
[rejected proxy and boundary experiments](FOLLOWER-DUNGEON-ADMISSION-BOUNDARIES-2026-10-16.md),
[tests](../../tests/harness/follower_runtime.lua).

## Subsequent Retail report and correction

The user reports unchanged behavior after delivery. Candidate.40 requires an
unsupported PartyInfo method, while its test fixture fabricated it. Therefore
its green proof did not establish startup against the documented Retail API.
Candidate.41 repairs activation by exact active ability identity and adds native
API-surface regression/status coverage. See the [activation diagnosis](FOLLOWER-DUNGEON-ACTIVATION-2026-10-16.md).
The user's subsequent "done, fixed" confirms the candidate.41 repair for the
reported problem and resolves K06. [Acceptance](../../evidence/follower-dungeons/2026-10-16/candidate41-user-acceptance.json).
The following sections retain candidate.40's implementation and qualification
checkpoint; they do not establish that its named cast route ran in Retail.

## Observation and selected repair

The user confirms that Blizzard's original control consistently alternates the
follower command. The ring retains the blue icon, changes the original control
once, then generally repeats lead; rapid selections occasionally produce the
opposite command. This is direct user evidence, not an instrumented event trace.
The latest instruction authorizes proceeding with the best supported candidate.
The [direct observation](../../evidence/follower-dungeons/2026-10-16/native-button-comparison.json)
retains that scoped comparison.

The earlier numeric spell route and native zone handler have different toggle
arguments. Ordinary paired native gestures do not reproduce duplicate dispatch.
A pooled-button proxy introduces a demonstrated wrong-spell risk; it is rejected.
The selected candidate uses the native secure spell-name branch for this one
default-ring entry. Blizzard's captured `/cast` handler also uses
`CastSpellByName`; the [Blizzard forum report](https://us.forums.blizzard.com/en/wow/t/dungeon-assitance-button-missing/1770209)
describes `/cast Dungeon Assistance` as a working alternate control. That supports
trying the name route, but does not prove current C/server toggle semantics.

Only compiled secure metadata changes to the localized spell name from
`C_Spell.GetSpellName(426756)`. The saved numeric spell row, autoassignment,
LAB spell identity, cooldown/usability/tooltip routes and native release handler
remain owned by ConsolePort. No macro is created, no pooled button is borrowed,
and no public callback casts. Native secure spell dispatch remains usable in
combat after eligible configuration outside combat/held wheel/editor/review.

## Presentation and selective suppression

Matching default-ring widgets use `C_ZoneAbility.GetZoneAbilityIcon` after native
override resolution. Their narrowly owned texture setter preserves later LAB
writes and foreign ownership. Player aura/cooldown/usability notifications
coalesce into one cosmetic worker; they do not rebuild rings. Context/name
changes request guarded recompilation. No polling or per-frame worker is added.

Only an identified, unprotected, active zone child for 426756 is hidden, and only
after a compiled owned replacement and public icon are ready. Its shared style
is suppressed only when it is the sole active zone child. Other zone abilities,
ExtraActionBarFrame and ExtraAbilityContainer retain native visibility/layout.
Pool reuse, unknown context, Edit Mode, disable or owner loss restore owned
suppression; protected restoration defers through combat. No protected hide is
authorized by public observations. The utility feature's existing disable plus
reload restores native handling without deleting choices.

## Delivery

The qualified Forever-only update is installed; the user owns reload. The
[artifact audit](../../evidence/delivery/candidate40-artifact-audit.json),
[installation](../../evidence/delivery/live-install-candidate40.json) and
[independent readback](../../evidence/delivery/candidate40-independent-readback.json)
identify exact tested/pushed source and verify all 60 payload files plus preservation.
Dependencies and WTF were untouched; no game input occurred. This is installation,
not Retail lead/stop acceptance.

## Validation and remaining boundary

The [full qualification](../../evidence/test-results/candidate40-follower-qualification.json)
passes 102 runtime/source checks and 70 tooling tests against complete matching
63-product and 155-tool/test inventories. The actual runtime records 341 assertions
and 128 paired gestures. Exact reports and hashes are retained with that receipt.
[Fresh Windows CI](../../evidence/test-results/candidate40-fresh-ci.json) passes the
same suites from a clean checkout with matching complete inventories and lock.

T101 runs the actual runtime and initialization caller with captured native ring,
restricted compiler/dispatch, LAB state/getters, zone refresh and extra-container
ordering. It checks 128 paired selections across adapter presence, hold/toggle,
keydown settings, modifiers and modeled combat. It asserts one name request per
selection, retained source/LAB identity, override artwork, sibling preservation,
pool reuse, Edit Mode, unknown context, localized-name refresh, disabled startup,
owner loss, late zone updates, held-close recompilation and protected deferred
restoration. A burst of 120 cooldown events
requires one worker and zero full ring refreshes. T102 must reject numeric-route,
stale-icon, blanket-hide, lost-LAB-state and routine-rebuild fault variants.
T88 also loads the new module with unavailable follower APIs to preserve startup
and the independent kill switch. Earlier experiments remain historical evidence.

Frames, C spell APIs, protection flags, event delivery and rendering are modeled.
The cast spy records requests; it deliberately does not invent lead/stop behavior.
Passing tests establishes the selected route and preservation, not Retail toggle,
taint, hardware timing, pixels, persistence or CPU acceptance. K06 remains open.

After deployment and the user's reload, select lead, wait for native cooldown,
select stop, and repeat. Verify artwork and one matching follower response each
time. Then check exit/re-entry, combat, Edit Mode and a coexisting actual extra
ability. If name dispatch still repeats lead, further offline runs cannot settle
the C semantics: the next useful evidence is a scoped live comparison of the
native button and a user-created `/cast Dungeon Assistance` macro, followed by
native event/cast tracing only if needed. No game input has been performed.

## Dependency and documentation scope

Fresh official discovery found BetterBags v0.5.16, Plater-v661 and DynamicCam
2.21.2. Their archives, complete folder closure and notices are retained under
the refreshed lock; new versioned integration captures leave old evidence intact.
The BetterBags item input paths execute against the new capture; its optional
Perf registration is modeled. DynamicCam Core/default/AceDB contracts are
unchanged. Forever retains exact guards for both currently installed and newly
qualified BetterBags/DynamicCam versions. Plater has no Forever profile adapter.
The [dependency qualification](../../evidence/dependencies/follower-candidate40-qualification.json)
records exact package changes and source identities. These dependencies are
prepared, not selected for the running-game delivery;
only Forever may be installed while WoW remains open.

Requirements, controller/states, K06, architecture, compatibility, testing, plan,
navigation, current status, changelog and checklist are affected. No setting,
schema/revision, binding policy, game-input authority or recurring workflow changes.

The repository is public. New third-party captures and personal screenshots stay
local and ignored. Tracked manifests plus the existing capture tool's reconstruction
option recover exact test inputs; the CI network stage runs before checks.
This extends source preparation without publishing new vendor source/assets.
