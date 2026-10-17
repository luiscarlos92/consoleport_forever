# Follower controls: candidate.40 startup defect

Status: maintained
Reviewed: 2026-10-16
Evidence: [native API identities](../../evidence/follower-dungeons/2026-10-16/candidate41-api-source-manifest.json),
[implementation](../../addon/ConsolePort_Forever/Rings/FollowerDungeon.lua),
[actual runtime test](../../tests/harness/follower_runtime.lua).

## Report and demonstrated cause

After candidate.40 delivery the user reports unchanged behavior and asks whether
Forever can take over the follower entry, prevent native addition and govern its
flow. The existing instruction authorizes qualified repair/deployment; this new
request additionally authorizes investigating ownership of this specific ability.
It does not authorize unrelated input takeover or game input.

Candidate.40's constructor requires `C_PartyInfo.IsPartyInFollowerDungeon`.
The captured Retail PartyInfo contract does not declare that function. The
captured LFGInfo contract instead declares `C_LFGInfo.IsInLFGFollowerDungeon`.
With the documented API surface, the constructor returns before installing any
mapping, icon or suppression hooks. The old fixture manufactured the unsupported
PartyInfo method, so its green tests missed this startup failure. Installed file
verification established delivery, not activation. The user's report is
consistent with this demonstrated defect; no live engine object was inspected.

This means candidate.40 did not establish that name dispatch failed while active.
Changing the entry representation or replacing the whole flow before fixing
activation would not test that hypothesis. The earlier pooled-button proxy still
has its demonstrated wrong-ability reuse/combat boundary; it is not adopted.

## Candidate.41 repair and ownership boundary

Forever activates this scoped adapter from the public active zone-ability list
when it contains Dungeon Assistance, spell 426756. It requires neither the
invented PartyInfo method nor a matchmade-LFG flag; quest/story follower contexts
can expose the same control. Opaque/unavailable lists do not establish availability.
Native ring readiness, ownership, disable, combat/held/editor guards remain.

Once active, Forever owns this entry's compiled name route, state artwork and
selective stock-control suppression. ConsolePort retains automatic source-row
addition/removal and native ring input; Blizzard retains protected execution and
actual follower state. This candidate does not suppress native autoassignment or
introduce a private lead/stop state machine. The smallest demonstrated repair is
activation of the already implemented route. A larger replacement remains a
separate implementation choice if an active route still fails in Retail.

`/cpf status` now reports follower controls as active, outside/unavailable,
awaiting spell/entry readiness, disabled/owner-lost, or blocked at initialization.
It reads cached public status on demand, adds no polling/event worker and does
not persist a new diagnostic stream. Initialization refusal supplies a reason.

## Regression evidence and limits

T101 builds its supplied Spell, SpellBook and ZoneAbility methods only from
names declared by captured Blizzard API documentation. It starts without either
PartyInfo or LFGInfo runtime tables, proving that active ability identity is
sufficient. Its existing 128-selection matrix, source/LAB preservation, icon,
suppression, pool/editor/opaque/disable and work-count checks remain. It also
asserts truthful active/disabled status and explicit missing-API refusal.

T102 reinstates candidate.40's unsupported PartyInfo startup guard. Initialization
must then fail at the expected boundary, rather than reaching the cast spy.
Five earlier route/presentation/work controls remain. This distinguishes an
adapter never starting from an active cast behaving incorrectly. New API captures
stay local/ignored; CI reconstructs them from the tracked hash manifest.

Cast spies still do not model C/server toggle semantics. After installation and
the user's reload, verify `/cpf status` reports follower controls active while
Dungeon Assistance is present. Then check the stock follower control disappears,
the ring icon agrees with state and repeated cooldown-separated selections
alternate lead/stop. Other extra/zone abilities must remain usable. K06 remains
open until that scoped Retail result; no game input has been performed.

## Dependency qualification scope

The fresh check found DynamicCam 2.21.4 and ExtraFade 1.18.1 after the previous
checkpoint. Only those archives were refreshed. New versioned contract metadata
leaves old captures intact. DynamicCam's real RefreshConfig executes for old/current
captures with recorded UI/camera/script boundaries; native AceDB/default expansion
tests cover retained/current version guards. ExtraFade's native settings initialization
and typed restoration run for 1.18.0/1.18.1. Its UI-hide changes are upstream code;
they are not a demonstrated explanation of K05 or a Forever UI takeover.

Folder closure, syntax and exact notices are qualified by the required full gates.
These packages remain prepared. This authorized running-game delivery selects
Forever alone and retains support for currently installed versions. Offline
dependency qualification does not establish new UI-hide, camera, taint or CPU
acceptance in Retail.

## Qualified delivery

[Full source qualification](../../evidence/test-results/candidate41-follower-qualification.json)
and [fresh Windows CI](../../evidence/test-results/candidate41-fresh-ci.json) pass
with matching complete inventories. [Artifact audit](../../evidence/delivery/candidate41-artifact-audit.json),
[installation](../../evidence/delivery/live-install-candidate41.json) and
[independent readback](../../evidence/delivery/candidate41-independent-readback.json)
identify the exact installed Forever-only bytes and preservation results. This
establishes offline qualification and delivery; the user owns reload and Retail
active-route acceptance. No private follower state machine or native autoassignment
replacement is installed.
