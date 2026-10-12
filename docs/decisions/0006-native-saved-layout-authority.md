# 0006: Saved native layouts remain authoritative

Status: maintained
Reviewed: 2026-10-11
Evidence: [candidate.29 design](../CANDIDATE29-IMMERSION-EDITMODE-2026-10-10.md),
[saved reference](../../evidence/editmode/saved-reference-2026-10-10.json),
[tracker](../../addon/ConsolePort_Forever/UI/EditModeReference.lua),
[initial adapter](../../addon/ConsolePort_Forever/Adapters/EditMode.lua).

Decision: established user request to track their latest saved Edit Mode changes,
including newly positioned systems. Preserve the 52-system captured reference;
native subsequent saves and selections remain authoritative.

Chosen behavior: tracker captures active layout per GUID and owned managed
account layout as known default without native save/import/select calls. Initial
reviewed managed-copy creation may use native save/select; it is a separate
transaction, not ongoing tracking. Reuse owned copies without resetting Party or
manual geometry; Party defaults apply only to new managed copies.

Source detail clarified October 11: the uniquely named owned account copy is
captured as the known default even when another layout is active. Ambiguous
matches reject default capture; missing matches retain the earlier reference.
When none exists, the packaged 52-system data may initialize the stored reference
without applying it. Per-GUID active capture and shared default capture remain
distinct. See [configuration](../reference/RUNTIME-CONFIGURATION.md#integration-and-saved-layout-details).

Consequences: the packaged reference is read-only data, not a command to overwrite
current layouts or filesystem WTF. A display-name collision is not ownership.
Alternatives rejected: replaying the complete installer for each saved change or
forcing a chosen default back onto the user's later native selection.
T67 proves source/host capture limits; broader live Edit Mode regression cases
remain separate from ring/Required Items acceptance.
