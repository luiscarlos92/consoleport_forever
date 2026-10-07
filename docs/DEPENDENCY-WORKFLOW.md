# Check before development; deploy only changed packages

## Candidate.6 added dependency — Better Wardrobe and Transmog

After the existing 18 packages were checked, the user installed and adopted
Better Wardrobe and Transmog. Official stable Retail 6.12.3 is now dependency 19,
with both BetterWardrobe and BetterWardrobe_SourceData selected through explicit
added coverage in sources.json. The official archive was downloaded only into
this checkout. All 149 installed files already match it, with no extras; both
live folders remain untouched and are not recopied in the scoped update.
The latest stable recheck covers all 19 and reports no updates. Native Retail
TOCs qualify its two client-owned Blizzard dependencies. Closure, syntax,
original notices and compatibility readback are recorded in
`evidence/dependencies/betterwardrobe-2026-10-06.json`.
No DBM bytes are shipped and no deployment is authorized.

The October 6 user instruction supersedes the previous companion-only rule:
check every dependency before starting a work session, update the Git dependency
lock/cache for new official stable Retail releases, test compatibility and repair
the companion where necessary, then deploy Forever plus only updated packages.
Unchanged dependencies are never copied just to redeploy Forever. Live WTF is
never edited by the disk installer.

`AGENTS.md` makes this the starting rule for later chats in this checkout. A check
is fresh for the current work session; a prior session's cached successful
report is not a substitute. Source discovery is distinct from downloading.

## Start of work

1. Freshly inspect the official CurseForge listings/file pages from
   `dependencies/sources.json`, including stable release type and Retail support.
   Record the observed version, file ID, filename and verification time. GitHub
   checks are automated; CurseForge browsing is necessary when direct HTTP is
   blocked. Do not invent fresh timestamps without inspecting the pages.
2. Run `python tools/check_stable_sources.py --discover`. It checks all official
   GitHub latest stable releases and source/asset identities, compares the fresh
   CurseForge identities with the lock (including file ID, not version alone),
   and records the update list. A missing independent GitHub asset digest still
   requires independent bytes qualification; unavailable sources are not current.
3. For each actual update run
   `python tools/resolve_dependencies.py --refresh --only OWNER/REPO`, repeating
   `--only` for multiple packages. The existing resolver merges only these
   repositories into the lock; it does not download/extract unchanged packages.
4. Review new upstream code, refresh affected pinned source contracts and
   compatibility/runtime-closure evidence, and fix/test compatibility before
   continuing the requested feature work. Keep all upstream bytes unmodified.
   New versions can add/change/remove official folders; review that scope, retain
   native inactive companions/helpers, and handle any genuine removed-folder
   migration explicitly rather than silently pruning other addons.
5. Run required final runtime/tooling checks, commit and push. Check again before
   delivery if the work spans a long period or upstream sources changed.

## Scoped delivery

Build a small update rather than a full UI pack:

```powershell
python tools/build_update.py
# If a dependency actually changed, include its complete qualified package:
python tools/build_update.py --dependency seblindfors/ConsolePort
```

Repeat `--dependency` as needed, including updates prepared earlier but not yet
installed. The default update builder does not read any unchanged vendor cache or
unpacked vendor file. It includes only Forever, the selected packages' complete
qualified folders, tested dependency identities and exact source/test hashes.
Its artifact is locally verified and retained; it is not a full-install package.

Preview `tools/deploy_update.py` with the artifact, checksum, explicit Retail
executable root and backup directory; execute only under user authorization with
WoW closed. It routes an empty dependency-update set through the existing tested
companion-only installer. For actual updates it backs up/stages/swaps only the
included folders, preserves unselected addons and WTF, verifies readback, and
rolls back all promoted folders when an error or handled interruption occurs.
New package folders are removed from the live tree again during rollback by
parking them inside the verified stage. Nothing is recursively deleted. Power
loss/process termination during a swap can still require recovery from the
retained backups/stage; do not treat offline interruption tests as proof of
power-loss recovery.

The original full-pack builder/installer remains for deliberate full-install or
recovery work. It is not the normal update path.

## Candidate.6 preparation check (later October 6)

A fresh session check again found all 18 official stable Retail identities current;
no package was downloaded or updated. Source verification timestamps and
`evidence/dependencies/stable-recheck.json` record this check. Candidate.6 adds
ground cursor casting and the native vertical Party default. The user requests
package preparation only, with WoW open. DBM is intentionally disabled: preserve
its enable state/files and omit it from this delivery. The scoped update has an
empty dependency update set and contains only Forever. Earlier deployment
receipts below are historical and do not authorize a candidate.6 installation.

## October 6 candidate.5 deployment check

All 18 official stable package identities still match the tested lock; no new
dependency download is needed. Fresh official CurseForge inspection confirms
[DynamicCam 2.21.1](https://www.curseforge.com/wow/addons/dynamiccam/files/8995535),
[Immersion ExtraFade 1.18.0](https://www.curseforge.com/wow/addons/immersion-extrafade/files/8995675),
and [SharedMedia_Causese 7.6](https://www.curseforge.com/wow/addons/sharedmedia_causese/files/7242737).
GitHub release/asset identities and bundled voice provenance match as well.
The candidate.5 deployment therefore includes only ConsolePort_Forever.

All 35 runtime/source suites and 29 tooling tests passed. The five additional
checks exercise update discovery, no reads of unchanged vendor sources, complete
selected-package delivery, refusal of inconsistent scopes, preservation of
unselected addons/WTF and rollback after interruptions at each promotion step.
Exact final product/tooling hashes match the retained receipts:
`evidence/test-results/scoped-update-runtime.json` and
`evidence/test-results/scoped-update-tooling.json`.

The WoW workspace root also has an `AGENTS.md` pointing to the Git workflow, so
later chats starting in the gaming folder encounter the same standing rule.
## Verified candidate.5 deployment

Completed **October 6, 2026, 19:34:44 America/Toronto**, from pushed/tested
source `eba070c92b1a75f6a24da1a8a1e56a6be2fcc107`. The scoped payload is
468,619 bytes and contains only ConsolePort_Forever. No dependency package was
downloaded or copied. Installer execution took approximately 41 seconds,
including backup, staging and verification.

- Artifact: `dist/2.0.0-candidate.5/ConsolePort-Forever-Update-companion-only.zip`.
- SHA-256: `a8717515da5752b4a57dbc6f4d26750ab6d45e2f3ef9a8b347f43d18bd80a462`.
- Backup: `C:\Users\luisr\WoW-Backups\ConsolePort-Forever\20261006T233402Z-755ac9a981fa`.
- Parked previous Forever: `C:\Users\luisr\OneDrive\Documents\03 Gaming\World of Warcraft\_retail_\Interface\.cpf-companion-stage-20261006T233402Z-755ac9a981fa\previous`.
- Receipt: `evidence/delivery/live-install-candidate5.json`.

Preview, backup verification, staging and installation readback passed. A
separate readback compared all 44 installed Forever files to the verified ZIP;
all 3,693 vendor files and all 296 WTF files/42 links match the pre-deployment
snapshot. No game was launched. Actual Darkmoon and Brewery controller testing
remains the user's next step.
