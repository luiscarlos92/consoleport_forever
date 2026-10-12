---
name: forever-scoped-release
description: Prepare, verify or separately deploy ConsolePort Forever scoped updates using existing exact-source gates, artifact receipts and preservation readback. Use for package, install or restore requests; invoking the skill does not authorize production writes or game input.
---

# Scoped preparation and delivery

Read [current status](../../../docs/IMPLEMENTATION-STATUS.md),
[installation](../../../docs/INSTALLATION.md) and the
[cumulative checklist](../../../docs/NEXT-DEPLOYMENT-CHECKLIST.md). Root instructions
own authorization/preservation rules. Do not replay permissions embedded in
historical receipts or execute old scratch/archive deploy scripts.

## Establish the requested stage

Identify preparation versus installation/restore, exact candidate/source,
qualified changed dependency set and artifact identity. Preparation may proceed
within its authorization; actual production installation needs current explicit
user authority. The October 12 standing instruction permits qualified Forever
updates while playing unless explicitly prohibited; it persists until revoked.
Use the qualified existing-Forever-only running-game option described in
[decision 0004](../../../docs/decisions/0004-scoped-delivery.md). It does not apply
to full installs, dependencies, restore or configuration replacement.
Scope cannot expand to game launch/input,
filesystem WTF editing, broad pruning or unrelated package updates.

## Prepare with existing gates

Check current official stable identities and qualified prepared-but-not-installed
changes through the dependency workflow. Require complete current product/tool/
test inventories and passing exact-source reports, qualified lock/closure/notices,
clean committed source pushed on main as the existing builder requires.
Use `tools/build_update.py`; include Forever and only actual qualified changed
packages, with all selected official folders/helpers. Preserve prior same-version
artifacts using the existing label mechanism where needed. Record manifest,
source/lock/report identities and independently verified checksum/file scope.
Do not weaken a gate because only documentation changed.

## Install or restore only when authorized

Use current scoped tools with explicit verified executable root, backup directory,
artifact and checksum. Confirm current game process/topology, run preview, inspect
the selected scope, then execute the authorized operation. Retain verified prior
code/configuration backups; read back installed selected files independently and
verify unselected addons, canonical WTF inventory, junctions and root anchors.
Restore/recovery must preserve newer edits and follow the existing guarded mode;
unknown compatibility is not permission to replace saved configuration.

## Output and completion

Record prepared or installed status accurately, changed packages, source/artifact
hashes, backup/readback evidence and remaining Retail cases. Update current status,
changelog and checklist as applicable; historical acceptance covers only reported
cases. Completion is exact scoped evidence, not a game test or permission for
an unrelated operation. Standing deployment permission remains subject to explicit
contrary instructions and all guards. On drift/failure, use supported recovery and report the stage;
do not bypass protection or delete retained backups to finish.
