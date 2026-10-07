# Candidate.6 deployment with ConsolePort 3.3.10

The user explicitly authorized deployment on October 7, 2026 and will manually
test afterward. Fresh checks of all 19 official stable Retail dependencies found
only ConsolePort changed, from 3.3.9 to 3.3.10. Its official package SHA-256 is
`6175a327b3b7505b6f1d79ef0adc96c7a65db3cc8220dd59e34de6658dbb4f49`.
The other 18 versions, archive hashes and file bytes remain unchanged. Earlier
same-version candidate.6 artifacts/receipts remain retained and superseded.

The package comparison in `evidence/dependencies/consoleport-upgrade-3.3.10.json`
records ten changed official files and no additions/removals. All custom changes
remain in Forever. Current 42 exact native contracts are captured from the new
locked official package. Ground secure dispatch, LAB usability/cooldown, Group,
Manager, Input, config panel API and native Retail menu routes remain compatible.

Relevant changed behavior is explicitly tested:

- Native Layers maps blocked self-modifier claims/releases to the tap key emitted
  by WoW; tests execute actual SetModifiers, Claim, Release and cleanup.
- The new native unbound texture provider desaturates and dims a glyph to 0.5,
  returning a reset callback. Forever retains that unavailable appearance for
  genuinely unbound slots and restores color/opacity for its meaningful Jump,
  Interact, look and decorated Exit artwork. Normal spell lock/tint/swipe fixes
  remain scoped and covered with native bodies.
- Native nested Table.Set propagates silent validation. BuildLayout preserves
  supported elements while logging/removing unknown or broken ones. Native rename
  copies the element instead of moving a subscribed table. Pet-ring factories
  preserve the first canonical name and create a distinct subsequent frame.
- Artwork now supports complex position/strata/level with native level 1. Current
  layout read/proposal keeps native fields; no saved layout or binding is edited
  through filesystem tools. Forever's audited four-bank requirement still defers
  if a user renames a required bank, preserving that deliberate layout.

`T24` and `T32` extend the native glyph/layer checks; `T39` exercises the changed
native layout/rename/pet paths. The full required suite must pass and exact reports
are retained as `candidate6-cp-3.3.10-runtime.json` and
`candidate6-cp-3.3.10-tooling.json` before building/deploying.

Candidate version 2.0.0-candidate.6, StoreSchema 3 and reviewed revision 13 remain
unchanged for this first deployment. The scoped update contains Forever and the
nine complete selected official ConsolePort folders only. DBM remains disabled
and excluded. Better Wardrobe remains adopted and unchanged. Preserve all other
addons/helpers, canonical WTF, junctions and backups. Preview and execute through
`tools/deploy_update.py` with WoW closed, then independently verify installed bytes
and unchanged unselected vendors/WTF/links. The user owns actual Retail testing.

All **39 runtime/source suites and 33 tooling tests passed**, with no failed
or skipped checks, against the exact current source and dependency lock.
