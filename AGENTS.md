# ConsolePort Forever working rules

Read `docs/MASTER-PLAN.md` and the current implementation checkpoint. User
instructions supersede older historical deployment/packaging rules.

## Before making changes in each work session

1. Check **every** dependency for a new official stable **Retail** release.
   Read `dependencies/sources.json` and `dependencies/lock.json`.
2. Freshly inspect each CurseForge source's official latest Retail file listing
   and file page using browsing. Confirm release type, Retail support, version,
   file ID and filename. Update only those observed fields and
   `metadataVerifiedAt` in `sources.json`. Direct HTTP may return 403; use the
   official pages through available browsing, not third-party mirrors or old
   timestamps. A previous session's cached check is not a new check.
3. Run `python tools/check_stable_sources.py --discover`. It queries all GitHub
   stable release identities and reports changed repositories alongside the
   freshly reviewed CurseForge sources. Failed/unavailable metadata is not
   evidence that an addon is current.
4. Download/qualify only changed repositories with
   `python tools/resolve_dependencies.py --refresh --only OWNER/REPO` (repeat
   `--only` as needed). Do not refresh/re-extract every unchanged package.
   Commit the updated lock, source identities and evidence in Git. Immutable
   cached official files remain unmodified; custom fixes belong in Forever.
5. Review the updated official source contracts, compatibility guards and
   runtime closure. Refresh the affected pinned contracts/audit evidence;
   test compatibility and fix failures before continuing product changes.
   Include all changed packages in the later scoped deployment, including
   updates prepared earlier but not yet installed. Do not silently certify a
   new version by merely changing a version guard. Then run the ordinary
   work/tests required by the requested change.

The first implementation of this rule checked all 18 packages on October 6:
no newer releases were found. Better Wardrobe and Transmog plus its SourceData
helper were subsequently adopted as dependency 19. Explicit added coverage lives
in `dependencies/sources.json` (`additionalAddonFolders`); do not edit the
immutable original reference to add later dependencies. See
`docs/DEPENDENCY-WORKFLOW.md`.

## Deployments

- Deploy only with explicit user authorization and WoW closed. Current installed
  checkpoint is candidate.8/revision 14 with unchanged ConsolePort 3.3.10
  (October 7, 17:43:12 Toronto). HideClassBars was backed up/parked by the scoped
  installer. All 2,165 remaining vendor files, 298 WTF files and 42 links are
  unchanged. This authorization is complete; future deployments need new
  authorization. Retain all earlier artifacts/receipts/backups. See
  `evidence/delivery/live-install-candidate8.json`.
- DBM was uninstalled by the user on October 7 and retired from the active lock.
  Do not restore it. Preserve historical references, archives and receipts.
  HideClassBars is replaced by reviewed Forever controller access and explicitly
  retired with the scoped installer; no broad addon pruning. SharedMedia_Causese
  stays for the saved Quazii Plater profile (164 direct sound references).
- Never write live WTF. In-game reviewed configuration remains game-owned.
- Default to a scoped update built by `tools/build_update.py`: Forever plus only
  explicitly updated dependency packages, with all their selected official
  folders/helpers intact. Do not use full-pack install/assembly for routine fixes.
- Run `tools/deploy_update.py` in preview mode, then execute the exact verified
  update. It backs up/replaces only included folders and backs up canonical WTF;
  unrelated/unchanged dependencies stay byte-for-byte intact. Retain backups.
- Preserve CurseForge-owned inactive DBM companions and bundled helpers. No
  broad pruning or repeated copying of unchanged addons.
- Commit and push tested source before building/deploying; retain exact receipts
  and document the installed version and dependency changes afterward.
