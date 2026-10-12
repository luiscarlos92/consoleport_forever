# Reference and history navigation

Status: maintained
Reviewed: 2026-10-11
Evidence: [migration record](../WORKSPACE-ORGANIZATION-2026-10-11.md),
[original reference manifest](../../reference/manifests/2026-10-03-initial.json),
[preserved master plan](../archive/ai-native-2026-10-11/MASTER-PLAN.pre-restructure.md).

## Source categories

| Location | Meaning |
| --- | --- |
| [Original reference](../../reference) | Immutable captured installed addon/configuration/assets. Historical baseline, not package payload. |
| [Pinned native source](../../evidence/native/manifest.json) | Blizzard-authored Retail UI source mirror provenance and hashes. |
| [ConsolePort contracts](../../evidence/consoleport-contracts/manifest.json) | Exact native methods/backend/frontend used by tests and integrations. |
| [Dependency lock](../../dependencies/lock.json) | Qualified official package identities/files; source freshness is separate. |
| [Forever investigation](../../archive/onedrive-legacy/Forever-Investigation-2026-10-03/evidence-manifest.json) | Pinned Forever source/settings discovery and saved-baseline observations; no client runtime test. |
| [Test results](../../evidence/test-results) | Exact-source offline receipts and stated limitations. |
| [Delivery](../../evidence/delivery) | Prepared/installed/readback receipts; no implicit hardware acceptance. |
| [Retail acceptance](../../evidence/forever-ui) | Scoped user observations alongside visual source/test evidence. |
| [Pre-restructure snapshots](../archive/ai-native-2026-10-11/README.md) | Original combined guidance preserved exactly. |
| [Imported work](../../archive/onedrive-legacy/README.md) | Historical scripts/plans/research; never executable deployment authority. |
| [Native UI reference and gap analysis](../references/pending/README.md) | Original native reference plus user-requested current implementation comparison; proposed features still await selection. |

Read [evidence conventions](EVIDENCE.md) before comparing behavior. The
[development history analysis](DEVELOPMENT-HISTORY.md) records sources, patterns
and access limits. The singular `docs/reference` is the new index; the existing
plural pending-reference directory is intentionally retained without moving it.

## Current code contracts

- [Runtime configuration](RUNTIME-CONFIGURATION.md): actual setup proposals,
  binding-bank consent, GUID rings/class augmentation, preferences, integration
  lifecycle, saved layouts, commands and diagnostic retention.
- [Circle cancellation research](CIRCLE-CANCEL-RESEARCH-2026-10-11.md): Circle-only
  native-source/addon/forum investigation, rejected Escape route, reviewed
  cancel-all approximation and original first-success oracle.
- [Presentation and UI](PRESENTATION-AND-UI.md): composed face/HUD feedback,
  visibility ownership and guarded dormant UI routes.
- [October 11 code/document reconciliation](CODE-DOCUMENTATION-RECONCILIATION-2026-10-11.md):
  specific stale/overbroad claims, source anchors and current corrections.

## Historical paths

Historical documents retain their original absolute OneDrive paths and links.
They were not rewritten because their exact bytes are evidence. For imported
working files, map the former WoW-root-relative path to the same relative path
under `archive/onedrive-legacy`, then confirm it exists and check the
[migration manifest](../../evidence/organization/2026-10-11/migration-plan.json).
For example, former `Forever-Investigation-2026-10-03/evidence-manifest.json`
is now linked in the source table above.

Exceptions: original root instructions live in `docs/archive`; user provisioning
scripts live in [tools/local](../../tools/local/README.md); the pending native UI
reference lives in `docs/references/pending`. Authorized deleted RARs/assistant
backups have no live replacement; do not invent rollback paths. Upstream checkouts,
large caches and imported Git metadata can be ignored local resources rather
than clone-available files. The migration inventory distinguishes them.

New maintained docs use repository-relative links. Do not repair historical
links by recreating production folders or changing immutable files. Use current
verified deployment backups/receipts for separately authorized restore work.

Installation/dependency/delivery/acceptance/manual-test pages also contain retained
historical checkpoints. Their new reading notices route to current specifications;
the [snapshot index](../archive/ai-native-2026-10-11/README.md) preserves original
bytes before those notices. Current routine release commands are documented in
[development](../DEVELOPMENT.md), with the source freshness procedure retained
as evidence. Historical “current” headings and NOT RUN cases do not override
later scoped acceptance.

[Circle silent failure, native binding and automatic logs](CIRCLE-NATIVE-BINDING-2026-10-12.md) — candidate.33 installed; direct binding migration was deferred.

[Circle macro format comparison](CIRCLE-MACRO-FORMAT-2026-10-12.md) — candidate.34 repair of formatting-only resource mismatches; no Retail acceptance claim.

[Circle protected-action report and automatic review](CIRCLE-BLOCKED-ACTION-2026-10-12.md) — candidate.32 installed; source/delivery proof is separate from pending Retail acceptance.
