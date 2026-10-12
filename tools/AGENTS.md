# Tool work in ConsolePort Forever

Status: maintained
Reviewed: 2026-10-11
Evidence: [path guards](repository_paths.py), [build gates](build_pack.py),
[delivery decision](../docs/decisions/0004-scoped-delivery.md).

Read root instructions and the applicable development/dependency/delivery
procedure. New tooling outputs belong strictly inside the checkout, with existing
path guards rejecting aliases, live trees and immutable references/fixtures.
Prefer read-only defaults. A metadata check is distinct from downloading,
qualifying, packaging or installing. Preserve archive/file hashes and complete
official folders; do not silently widen version guards or retire helpers.

Routine delivery uses build_update.py/deploy_update.py. Existing clean pushed
source, full exact-current inventories, lock/source/notices and preview/readback
gates remain binding. Do not bypass them for documentation or create another
installer. Explicit current installation authorization and closed WoW are required
by default; the qualified existing-companion-only running-game exception needs
explicit current user instruction (see [decision 0004](../docs/decisions/0004-scoped-delivery.md)). It excludes full install, restore, dependencies and WTF writes.
before mutation. Preserve unselected addons, WTF, root anchors, junctions and
verified backups; recovery must reject newer drift rather than erase later play.

`tools/local` contains user provisioning scripts with destructive operations.
Hashing/parsing/importing them grants no execution permission. Archived scripts
are not executable deployment instructions. Tests use guarded scratch copies.

Run complete Test-All.ps1 after executable tooling changes. The documentation
checker is read-only, standard-library-only and scoped to maintained pages/skills;
historical link text is intentionally not rewritten. Keep new checks in existing
CI/test entry points and document their actual limits.
