# 0005: Actual native account ring with release-only ping dispatch

Status: maintained
Reviewed: 2026-10-11
Evidence: [account-ring choice](../CANDIDATE28-NATIVE-ACCOUNT-PING-RING-2026-10-10.md),
[release repair](../CANDIDATE30-PING-RELEASE-LIFECYCLE-2026-10-10.md),
[user acceptance](../../evidence/forever-ui/candidate30-live-acceptance.json).

Decision: use the actual ConsolePort Shared account ring/backend/frontend/skins,
not a separately reconstructed renderer. Preserve account edits and unrelated
native rings; retain candidate.27 functional code inactive outside runtime.

Context: the prior functional renderer looked broken. Candidate.29 artwork then
opened only once, and the user rejected the initial ping during a hold.

Current requirement: no dispatch on R3 down; selected release sends once and
empty release sends one aimed fallback. Cosmetic hold visibility has an
independent monitor; public clocks/alpha do not authorize protected actions.
Unchanged refreshes preserve active gestures; native ownership/collision/taint
guards remain.

Supersedes: candidate.28's immediate-down ping instruction and independent
renderer approaches. The user accepted the reported ring defect after candidate.30;
this does not individually accept all broader account/combat/edit cases.
See [gesture contract](../CONTROLLER_SPEC.md#ping-gesture).
