# 0003: GUID-owned state and native manual editing

Status: maintained
Reviewed: 2026-10-11
Evidence: [binding policy](../../addon/ConsolePort_Forever/BindingPolicy.lua),
[store](../../addon/ConsolePort_Forever/Store.lua),
[editing repair](../CANDIDATE27-HOLD-RING-AND-ACTION-GUARD-2026-10-10.md),
[passive observer](../../addon/ConsolePort_Forever/ActionRecovery.lua).

Decision: established user choices. Only unmodified four face bindings are shared;
D-pad/modified bank actions and class ring contents are character-owned. Physical
shared files do not prove identity. Preserve explicit empty edits, manual entries
and native action storage.

Context: incomplete Paladin archives caused projection rejection and class data
could leak across views. Candidate.26 emergency spell restoration was followed
by removed/rearranged actions returning; the user requested undoing automatic
restoration entirely.

Chosen behavior: GUID projection/capture guards, account-view rejection, reviewed
conflicts/journals and native editing cache/latch repair. ActionRecovery is passive;
the old toggle cannot enable pickup/place/clear-cursor/timed repair. Historical
snapshots remain diagnostic, not executable spell seeds.

Source scope clarified October 11: generic ring capture preserves manual
order/duplicates/metadata and deletion, while separate ClassActions augmentation
appends missing learned forms. The authorized scoped class migration/one-time
repair can recreate access through journaled binding/ring writes. These paths
remain active and differ from removed action-slot restoration. Explicit empty
binding values also differ from absent mask entries recovered from the same
GUID's committed transaction. [Configuration](../reference/RUNTIME-CONFIGURATION.md)
records the gates; this clarification does not approve additional runtime work.

Consequences: diagnose the original writer separately; it remains unconfirmed.
Manual edit preservation takes precedence over speculative automatic repair.
Alternatives superseded: inferring ownership from per-character filenames and
replaying historical slots when an anomaly appears. See [requirements](../REQUIREMENTS.md).
