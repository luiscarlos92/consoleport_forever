# 0004: Qualify official changes and deploy scoped updates

Status: maintained
Reviewed: 2026-10-12
Evidence: [dependency workflow](../DEPENDENCY-WORKFLOW.md),
[builder](../../tools/build_update.py), [installer](../../tools/deploy_update.py),
[workspace authority](../WORKSPACE-ORGANIZATION-2026-10-11.md).

Decision: established October 6 selective dependency workflow and October 11
workspace authority. Freshly check every official stable Retail source for
applicable sessions, download/qualify only changed packages, and deliver only
Forever plus those complete selected packages. The narrow docs-only exemption
is now in [decision 0001](0001-repository-development-system.md).

Context: repeatedly copying unchanged dependencies caused delays; broad pack
operations risk unrelated addons/configuration and helper coverage. Historical
permissions and imported scripts accumulated in old working directories.

Consequences: clean tested/pushed source, exact inventories, fresh source evidence,
scoped preview, explicit current installation authority, WoW closed by default, verified
backups and independent preservation readback. Preparation and installation are
separate outcomes. Never write live WTF or prune unrelated/inactive helpers.
User-owned provisioning scripts are not routine installer entry points.

October 12 amendment: the user explicitly authorizes the Circle repair while WoW
runs and owns reload. Qualify `--allow-running-companion` in the existing scoped
installer for an existing Forever-only payload, exact installed receipt/file
inventory and identical StoreSchema. Full install, dependencies, retirement,
restore and WTF writes cannot use this exception. Verified code/WTF backups,
topology and untouched-file checks, concurrent-drift refusal and code-only rollback
remain required. Process checks still record whether WoW runs. This permits a
mechanism, not standing deployment permission: every use needs explicit current
authorization. User reload timing and engine acceptance are separate proof.
[Regressions](../../tests/test_running_companion.py) reject scope expansion,
unknown prior code/schema, default running-game use, drift and interrupted promotion.

Later October 12 user instruction: "you can now always deploy while I'm playing
unless I specifically said the contrary". This establishes standing authority
for qualified companion updates until revoked or contradicted for a task. It
supersedes the amendment's requirement to obtain another one-off permission for
each such update. Payload/schema/receipt/backup/readback guards remain; no game
input or direct WTF writing is authorized. Full installs, dependency replacement
and restore still cannot use the companion-only running-game mechanism.

Alternatives: full-pack build/install remains for deliberate full installation or
recovery, not routine fixes. Public redistribution remains unapproved despite
local notice/assembly review. Retired DBM/HideClassBars/SharedMedia packages are
not restored because older references included them.
