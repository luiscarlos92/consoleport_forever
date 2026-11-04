# Capability-based addon integration

Status: maintained
Reviewed: 2026-11-03
Evidence: [user requirement](../REQUIREMENTS.md), [compatibility audit](../reference/ADDON-UPDATE-AUDIT-2026-11-03.md).

## Authority and decision

On November 3 the user requests checking recently updated addons, patching only
where needed and deploying nothing if no patch is needed. The follow-up says:
"patch it so it's NEVER locked to any version".

Forever must never admit or reject a third-party addon by its version label,
range or allowlist. Probe the loaded APIs, data shapes, native ownership and
required secure snippet semantics instead. Missing required contracts leave the
affected integration unavailable, retaining the native fallback. Version labels
may be reported as diagnostics. This supersedes older exact-version admission
instructions in compatibility documents and prior candidate descriptions.

## Qualification and limits

Official release identities, archive/file hashes and pinned native sources
remain reproducible build/test evidence. These pins do not authorize a runtime
version gate. Qualification covers the actual evaluated sources; capability
checks cannot guarantee the semantics of every possible future implementation.
When an upstream API changes incompatibly, investigate its actual contract and
repair Forever without introducing a new version restriction.

Keep protected/native input ownership, manual data, feature exclusions and
StoreSchema/configuration migration guards. Those are independent contracts.
The user owns Retail reload/input/rendering/taint acceptance. No dependency,
WTF, game-input or unrelated settings writes are authorized by this decision.
