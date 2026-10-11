# Imported historical OneDrive work

These folders retain the original scripts, Markdown, research, evidence,
attachments and prototype outputs from the former OneDrive working directory.
They are historical inputs. Their embedded production paths, rollback scripts
and deployment instructions are not the current workflow. Do all new work in
the product checkout and use its scoped builder/installer for authorized
production updates. Do not execute archived scripts against live WoW data.

The original directory structure is retained to keep historical relative
references readable. References to removed backup copies are intentionally
historical and cannot be used for rollback. Before-change copies, configuration
backup snapshots, inactive addon/configuration backup folders and RAR archives
were deleted under the user's explicit cleanup instruction. Current deployment
backups outside OneDrive remain preserved.

The user's two provisioning scripts are in `../../tools/local`. The native UI
reference is in `../../docs/references/pending`, reserved for a later request.
The former root `AGENTS.md` is preserved as
`../../docs/archive/onedrive-root-working-rules.md`; the active repo `AGENTS.md`
contains the current working rules.

Upstream source checkouts, extracted packages and installed-source references
remain local inside this archive and are ignored by Git as reproducible caches.
Nested upstream Git metadata is preserved separately under
`../../scratch/onedrive-import-git-metadata`, avoiding embedded repositories.
The 145 MB community listfile is preserved under
`../../scratch/onedrive-import-bulk-resources` because it exceeds GitHub's normal
file size limit. These local resources are inventoried with hashes in
`../../evidence/organization/2026-10-11/migration-plan.json`.

See `../../docs/WORKSPACE-ORGANIZATION-2026-10-11.md` for the outcome and
verification receipt. Original files are preserved byte-for-byte except the
documented production-path correction in the relocated OneDrive setup script.
