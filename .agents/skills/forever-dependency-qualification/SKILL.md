---
name: forever-dependency-qualification
description: Check official stable Retail dependency identities and qualify selective updates for ConsolePort Forever, including native contracts, complete folders and notices. Use for dependency or compatibility work and applicable development-session freshness checks; pure documentation sessions have the approved narrow exemption.
---

# Dependency qualification

Use [COMPATIBILITY.md](../../../docs/COMPATIBILITY.md) and the existing
[dependency procedure](../../../docs/DEPENDENCY-WORKFLOW.md). They own contracts;
this skill supplies review routing, not a second resolver or permission to deploy.

## Discover before refreshing

Read sources.json and lock.json, current task restrictions and prepared-but-not-
installed changes. Freshly inspect each official CurseForge latest stable Retail
listing and matching file page for release type, support, ID/version/filename.
Only then update observed fields/timestamps. Run
`python -B tools/check_stable_sources.py --discover` for official GitHub identities
and the freshly reviewed CurseForge records. Failed/unavailable metadata is an
explicit blocker, never evidence of currency. Cached checks are not fresh.

For a discovered actual update, refresh only that repository using the existing
resolver's `--refresh --only OWNER/REPO`. Preserve immutable old references and
all current official bytes. A documentation-focused task can record a discovered
update for separately scoped qualification instead of silently expanding into
product changes; disclose the pending compatibility/delivery consequence.

## Qualify the changed contract

Inspect affected native source, TOC/load closure, new/removed official folders and
helpers, method/data ownership, syntax and notices. Refresh only affected pinned
contracts with their capture tools. A guard-string edit or unchanged filename
alone is not version support. Run affected compatibility regressions and complete
applicable gates. Keep integration fixes in Forever, not upstream files; respect
task-specific prohibitions on updating an integration.

## Outputs and validation

Retain exact observed identities, lock hashes, changed-package set, qualified
source/closure/notices and unresolved blockers inside the repo. Update compatibility
when audited assumptions change. The output distinguishes current identities,
retrieved archives, qualified bytes and installation state. Include qualified
prepared changes in a later authorized scoped release; never reship unchanged
packages or silently prune old helpers. Success means evidence supports the
claimed stage; offline compatibility is not Retail hardware/taint acceptance.
