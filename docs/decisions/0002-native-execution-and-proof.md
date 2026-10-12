# 0002: Retain native execution ownership and realistic proof

Status: maintained
Reviewed: 2026-10-11
Evidence: [native recovery](../NATIVE-RECOVERY-2026-10-08.md),
[compiler correction](../CANDIDATE25-SILENT-PING-2026-10-10.md),
[runtime branch](../../addon/ConsolePort_Forever/ConsolePort_Forever.lua).

Decision: established current boundary, recorded here without a runtime change.
Native ConsolePort bindings/pages/UI ownership remain authoritative. Full custom
modes/UI takeover/hidden replacement stay suspended; qualified temporary routing
and accepted ground placement operate independently.

Context: live combat controller failures persisted despite visible buttons and
offline passes. Ping later crossed protected authority, then ordinary Lua
compilation missed a forbidden restricted table literal. Visual tests also missed
native hierarchy and final composition.

Consequences: use actual relevant native dispatch/functions and restricted
compiler, reproduce old defects and retain negative controls. Public timers/alpha
cannot authorize protected work. Offline engine/taint/hardware/rendering limits
remain explicit even when tests execute native Lua functions.

Alternatives rejected by the established boundary: modifying upstream ConsolePort,
restoring full custom takeover incidentally, or equating shown attributes/simple
mocks with successful engine dispatch. See [testing](../TESTING.md) for mandatory
gates; changing activation needs a separately scoped requirement/decision.
