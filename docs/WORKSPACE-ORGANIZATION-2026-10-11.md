# Workspace organization — October 11, 2026

The user designated `C:/Users/luisr/Dev/consoleport_forever` as the only working
source of truth. Development scripts, plans, Markdown, research and evidence
belong in this checkout. The OneDrive World of Warcraft root is reserved for
production/deployment data under `_retail_` and the user's `Documents` folder.
`Documents` was not traversed, read or modified; its directory identity was
checked only. The game was running, and no deployment or provisioning script
was executed.

## Imported material

6,843 files, totaling 464,301,197 bytes, were moved into the checkout. The
[historical archive](../archive/onedrive-legacy/README.md) preserves working
folders, scripts, plans, research, prototype outputs and conversation image
attachments. The original root `AGENTS.md` is preserved in
[the documentation archive](archive/onedrive-root-working-rules.md); the repo's
active instructions now define the new workspace boundary.

The user's two PowerShell scripts are in [tools/local](../tools/local/README.md).
The OneDrive setup script's destination path was adjusted after verification
because its former `$PSScriptRoot` default would point into the repo after moving.
The scripts were syntax checked without executing their provisioning operations.

The [native gamepad UI reference](references/pending/WoW_Forever_Native_Gamepad_UI_Complete_Reference_2026-10-10.md)
was preserved without content changes. It awaits processing on a later feature
request; no native UI feature was implemented during this run.

Development scripts, documents and evidence are retained in Git. Old upstream
checkouts and reproducible package/reference caches remain locally inside the
repo and are ignored by Git. Nested upstream `.git` metadata is preserved under
`scratch/onedrive-import-git-metadata`. The large community listfile is preserved
under `scratch/onedrive-import-bulk-resources`. The exact destinations and SHA-256
hashes of all imported files are in the migration manifest.

## Authorized backup cleanup

7,515 backup files, totaling 2,147,218,198 bytes, were deleted, including all seven
root RAR archives, `Removed AddOns 2026-09-26`, `Former Character AddOns 2026-09-26`,
legacy `before`/`before-docs` copies, failed-install configuration copies,
historical configuration snapshots and `master-before-*` copies. Working
scripts, Markdown and evidence in mixed folders were preserved. The concrete
paths and reasons are recorded in the manifest. External deployment backups,
immutable repo references and production data remain preserved.

## Verification and future work

The final OneDrive root contains only `_retail_` and `Documents`. Every imported
file was verified against its original SHA-256 before the setup script's path
correction. Root identities and junction targets were compared with the
pre-migration inventory; all 16,674 production files remain byte-identical and
all 42 junctions retain their targets. No production file contents were written.
The [verification receipt](../evidence/organization/2026-10-11/verification.json)
records exact counts and results. The [migration manifest](../evidence/organization/2026-10-11/migration-plan.json)
records every retained file and authorized deletion.

All nine dependencies were freshly checked against their official stable Retail
sources. DynamicCam 2.21.1/file 8995535 and Immersion ExtraFade 1.18.0/file 8995675
were verified on their official listings and file pages; all seven GitHub stable
identities were checked by `tools/check_stable_sources.py --discover`. No package
changed or required downloading, compatibility repair or deployment. The
[session dependency receipt](../evidence/organization/2026-10-11/stable-recheck.json)
preserves this check.

For new work, use the repo's current instructions, master plan and implementation
status. Historical absolute paths and rollback/deployment scripts in the archive
remain documentary evidence. Deploy finished, tested updates only after explicit
authorization with WoW closed, using the scoped builder/installer. Never edit
live WTF through filesystem tools or place working material back into OneDrive.
