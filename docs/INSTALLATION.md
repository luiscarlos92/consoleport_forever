# ConsolePort Forever personal candidate

## Current authority - SharedMedia retirement, October 7, 2026

A fresh read-only Plater WTF parse confirms all four profileKeys select Default.
Default has no Causese references anywhere in its saved profile. The 164 direct
cast-sound paths belong only to the inactive Quazii Plater Season 4 profile.
Forever has no Plater profile adapter and the disk deployment contains addon code,
not WTF or a Plater profile; it cannot install/select Quazii. The user explicitly
authorized removing SharedMedia_Causese under this confirmed Default selection.
Retire it from sources/lock/coverage/notices/capability diagnostics and park the
live addon with verified backup through the scoped installer. Preserve Plater,
both profiles and all live WTF. Candidate.8/revision 14 remains; this is a labeled
same-version retirement update. All 10 pre-retirement official stable Retail
sources were freshly checked/current, then the nine remaining sources rechecked;
no downloads or dependency reshipping. Earlier SharedMedia keep rules are superseded.


## Current authorized work - October 7, 2026

Candidate.8 replaces HideClassBars with reviewed native class-ring access and a
utility-ring vehicle-seat panel, plus fallback native visibility and Edit Mode
restoration. StoreSchema 3/configuration revision 14. HideClassBars and all eight
DBM packages are retired from active dependencies; original reference/cache/history
remain preserved. DBM is already absent live. SharedMedia_Causese is retained for
164 direct sound references in the saved Quazii Plater profile; current Default
has none. All 19 initial releases and 10 remaining releases were freshly checked;
no updates/downloads. User explicitly authorizes scoped deployment with WoW closed.
See `HIDDEN-CONTROLS-AND-RETIREMENT-2026-10-07.md`. Earlier authority below is history.


This is the personal delivery for the approved Retail setup. Run the guarded installer only when the user requests installation. No script runs the game. The dependency/package assembly can be complete while precise parity features and all actual Retail acceptance remain pending; see `Delivery/ACCEPTANCE.md` and `pack-manifest.json`.

Full UI packaging preserves 42 addon folders: ConsolePort Forever and 41 folders from 18 pinned official packages. Two DBM companions are inactive on Retail according to their original TOCs; retain them so CurseForge sees a complete package. No official package files are deliberately pruned. The pack contains no WTF, binding cache, reference snapshots or test harnesses. Keep the complete personal ZIP local; publishing third-party code/media has not been approved.

Current clean upstream dependency behavior includes ConsolePort 3.3.9's own keyboard migration, binding claims, account-wide bar choice and BetterBags' native ConsolePort integration notice. Those upstream behaviors are not disabled by declining Forever's configuration review. Forever adopts whichever native bar data source is active and does not select shared layouts automatically. Existing manual layout, actions, keyboard mappings, mount rules and profiles are captured at runtime; the pack contains no replay of the old preset. Unloaded historical companion modules are omitted from its own payload; dependency package files remain unchanged.

## Preferred update when CurseForge manages dependencies

With WoW closed, `tools/deploy_companion.py --retail-root '<executable-_retail_>' --pack '<verified-pack>' --sha256 '<receipt-sha256>' --backup-root '<separate-backup-root>' --user-install` previews a companion-only update. Add `--execute` only for a user-requested deployment. The tool validates the installed ConsolePort version, backs up the current companion and canonical WTF, stages and replaces only `ConsolePort_Forever`, and verifies every other addon file and all WTF bytes/links unchanged. Failed promotion restores the previous companion. No dependency files, native addon enable state or live WTF are written. WoW and the in-game reviewed installer own settings persistence.

## Verify and assemble outside the game tree

Use Windows PowerShell and Python 3.11 or newer, available as `python` (or supply `-Python` with its executable path). Extract the delivery tools/instructions to a separate ordinary directory, outside WoW, AddOns and WTF. Keep the pack ZIP outside the selected game root. Compare its SHA-256 against the separately delivered receipt before using it. Hashes prove agreement with that receipt; they are not a publisher signature.

Examples below are templates for the later installation session. Replace every placeholder with the reviewed absolute path and the separately supplied hash. PowerShell's `-ExecutionPolicy Bypass` applies only to this invocation; it does not change the machine policy.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Delivery\Verify-Pack.ps1 -Pack '<full-pack.zip>' -ExpectedSHA256 '<receipt-sha256>' -RequireComplete
```

To reproduce a full personal ZIP from the official-source recipe, use a fresh output filename outside every game directory. The assembler fetches each pinned official archive, verifies its exact size/SHA-256 and selected-file hashes, retains its runtime closure, and writes a new full manifest/receipt. A failed or unavailable download stops assembly; it does not silently substitute an installed or newer package.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Delivery\Assemble-Pack.ps1 -Recipe '<recipe.zip>' -ExpectedSHA256 '<recipe-receipt-sha256>' -Output '<fresh-full-pack.zip>'
```

The recipe itself is incomplete and cannot be installed. The delivered full ZIP was assembled locally using those same pinned official archives and assembler. Assembly output is never written into a game tree.

## Later installation session

First close WoW normally. Select the explicit executable `_retail_` directory containing `WoW.exe`, and review its canonical Interface/AddOns/WTF paths. Inventory any existing Interface/WTF anchor junctions and the 42 character links. The installer permits those inventoried anchor links, refuses AddOns/code links, and refuses changed identities or configuration links that escape canonical WTF. It never traverses character links during copying; the canonical shared data is backed up once and exact link topology is recorded.

Start with the read-only preview; absence of `-Execute` means no backups, staging or game writes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Delivery\Install-Pack.ps1 -RetailRoot '<chosen-_retail_>' -Pack '<full-pack.zip>' -ExpectedSHA256 '<receipt-sha256>' -UserInstall
```

Only after we inspect the preview together, adding `-Execute` authorizes execution. Before promotion it creates and verifies a fresh full AddOns + canonical WTF backup, including fallback `.lua.bak`, binding/Edit Mode caches, prior TOC versions and hashes. Default location is `<chosen-_retail_>\CPFBackups\<unique-id>`; a reviewed non-overlapping `-BackupRoot` can be chosen instead. All backups are retained. Allow enough free space for the entire backup plus staged old/new addon folders; copy/storage failures stop promotion.

The full-pack installer stages verified files on the AddOns volume, parks whole previous pack-owned folders, and renames whole new folders into place. Obsolete files disappear only in those owned folders. It preserves DBM-Azeroth and DBM-Test-Vanilla as shipped; their native TOCs own load eligibility. Unrelated addons and current WTF files/links remain intact. A durable operation receipt records backup/stage identities, source commit, ZIP hash, compatibility and recovery state. Interrupted/failed operations retain old code, new code and backups. Ordinary installation never writes saved configuration.

Open Retail manually afterwards. `/cpf status` and `/cpf diagnose` report readiness and pending reasons; `/cpf proof` shows the proof panel. Accept only reviewed configuration fields outside combat/Edit Mode, then choose Reload now or later. Declining leaves companion-managed fields unchanged. Execute the single H8 checklist in `Delivery/ACCEPTANCE.md`; passing offline tests does not certify secure combat behavior or appearance.

## Runtime restore, code rollback and interrupted recovery

Prefer `/cpf restore <journal-id>` for reviewed runtime fields. `/cpf status` reports retained journal identities. It preserves newer conflicting edits and operates outside combat/Edit Mode; `/cpf recover <journal-id>` handles a pending runtime transaction. Disk receipts and runtime journals are separate backups.

With WoW closed, `Restore-Pack.ps1 -RetailRoot '<chosen-_retail_>' -Backup '<operation-backup>' -UserInstall` previews disk rollback. It refuses newer edits to pack-owned code. Code-only rollback requires a known prior installed receipt with the same StoreSchema and dependency versions; it preserves all later saved configuration, even when configuration revisions differ. Adding `-Execute` is the separate later execution choice. Current code/configuration is fully backed up again before every restore.

For an interrupted folder promotion use the same preview with `-RecoverInterrupted`. After review, `-Execute` compensates only matching parked/new code from the durable receipt. Newer edits, changed links, missing/drifted backups or running WoW stop recovery and retain the evidence. Do not delete the parked `.cpf-stage-*` directories or prune backups before the chosen recovery is verified.

Unknown baseline/schema/dependency compatibility prevents automatic code-only rollback. If the game cannot load enough for runtime restoration, the separate disaster option is `-RestoreConfiguration -AcceptCurrentConfigurationLoss`, initially without `-Execute`. It explicitly replaces the current canonical WTF ordinary files with the chosen pre-install backup together with old code, after making another verified backup of all later play. It keeps junctions intact and requires unchanged topology. This deliberately loses later configuration in the active tree; the fresh current backup retains it. Use this only after inspecting the exact selected backup and accepting that loss together.

Repository developers run `tools/Test-All.ps1`, locked dependency verification and `tools/Build-Pack.ps1` from clean pushed tested source. Repository-only `-Simulation` is for guarded fresh scratch roots and requires repository guard tooling; it is not a delivered real-install option. Full pack receipts identify exact source/test hashes independently from subsequent documentation commits.
