# Candidate.15 — four visual regressions

Candidate.14 round buttons are confirmed by the user. Preserve the actual Masque
Normal_Custom retirement, original sprites and same-parent circle masks. Keep
Ground.lua byte-identical to working candidate.13 and native input recovery.

Read-only saved-data inspection found the paladin's accepted revision-16 record
with all three Auras entries but neither class opener in its controller bindings.
This fails the badge and duplicate-row hiding gates. Revision 17 extends the
existing authorized in-game class migration to revision-16 records: real class
chord and learned forms, native binding save, transaction backup/rollback,
idempotent next login, no filesystem WTF edits. Paladin/druid use L1+L2;
warrior R1+R2. The smaller badge stays below R2 and now reports readiness failure.
Native aura access stays until complete installed ring access exists; Edit Mode
restores it. No controller UI layer takeover.

Ready round icons reconcile the native LAB IsUsable result after local/event
redraws, reset stale tint and placeholder opacity, and retain genuine range,
resource and unusable colours. Opaque combat availability/range values use
Blizzard C_CurveUtil.EvaluateColorValueFromBoolean without Lua branching. Opaque
lock booleans pass directly to the permitted
texture sink. This repairs reproduced stale presentation paths; exact origin of
the user's live combat grey rendering still needs client confirmation.
Sources: current official ConsolePort 3.3.10 LAB Action.IsUsable/UpdateUsable,
[Blizzard texture API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua),
[CurveUtil API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurveUtilDocumentation.lua),
[LevelLink API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/LevelLinkDocumentation.lua).

L2/R2 hints have independent unprotected anchors at inactive bank scale.
Collision fitting checks both native scale extremes, so selection cannot choose
a different gap. Native bank geometry and overall HUD size remain.

- T47 replays real first-login bootstrap with accepted-16 missing paladin chord,
  native save, backup, unrelated-key preservation, no new review and idempotence.
- T48 executes actual Blizzard StanceBar.Update across combat cycles. Native Show
  cannot leak the duplicate row; Edit Mode restores it, combat never reparents it.
- T49 covers all 16 round faces across six combat cycles using actual native
  Action.IsUsable: ready tint/opacity/desaturation, actual range/resource/unusable
  colours, roundness and opaque lock values. A negative control must reproduce
  stale grey tint when reconciliation is disabled.
- T50 preserves the same frames through 32 combat modifier/scale transitions and
  compares exact hint positions, including post-combat refresh.

T45 adds fixed-position comparisons to 120 physical geometry cases across five
resolutions, three UI scales, two saved layouts and four selected banks. Screen
bounds, spell/hint collisions and native bank collisions remain checked. T24
keeps actual native Masque lifecycle and the private square negative control.
Full T41/T42 native controller combat dispatch and all other suites are required.
Offline model/source execution is not live renderer acceptance.

Fresh checks of all nine official stable Retail packages found no updates.
Deploy tested/pushed code through scoped builder and installer with WoW closed;
copy Forever only, retain backups and verify other addons, WTF and junctions
unchanged. No game launch or gameplay automation.

Validation: all 50 runtime/source suites and 39 tooling tests pass. Exact reports
are retained in evidence/forever-ui/candidate15-runtime-tests.json and
candidate15-tooling-tests.json.
