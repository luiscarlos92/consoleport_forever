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

## Combat input regression gate

Changes involving UI ownership or controller routing must run T41's actual native
Layers/Input combat transition and engine dispatch through the native UseAction
handler for all 32 gameplay chords. Shown buttons/action attributes alone are not
proof of input dispatch. Check held UI release, native/late-created widgets,
foreign modal preservation and repeated UI/combat cycles. Do not modify upstream
ConsolePort files to fix the companion's handoff.

## Deployments

- Deploy only with explicit user authorization and WoW closed. Current installed
  checkpoint is candidate.8/revision 14 with unchanged ConsolePort 3.3.10
  (October 7, 22:42:24 Toronto). HideClassBars and SharedMedia_Causese were backed
  up/parked by scoped installers. All 1,949 remaining vendor files, 298 WTF files
  and 42 links are unchanged. Plater profileKeys still select Default for all
  four recorded characters; deployment does not install/select a Plater profile.
  This authorization is complete; future deployments need new authorization.
  Retain all earlier artifacts/receipts/backups. See
  `evidence/delivery/live-install-candidate8-sharedmedia-retirement.json`.
- DBM was uninstalled by the user on October 7 and retired from the active lock.
  Do not restore it. Preserve historical references, archives and receipts.
  HideClassBars is replaced by reviewed Forever controller access and explicitly
  retired with the scoped installer; no broad addon pruning. SharedMedia_Causese
  is also retired under user authorization: all current Plater profileKeys select
  Default; the unused Quazii profile is retained as game-owned saved data.
- Never write live WTF. In-game reviewed configuration remains game-owned.
- Default to a scoped update built by `tools/build_update.py`: Forever plus only
  explicitly updated dependency packages, with all their selected official
  folders/helpers intact. Do not use full-pack install/assembly for routine fixes.
- Run `tools/deploy_update.py` in preview mode, then execute the exact verified
  update. It backs up/replaces only included folders and backs up canonical WTF;
  unrelated/unchanged dependencies stay byte-for-byte intact. Retain backups.
- Preserve unselected CurseForge-owned helpers and inactive addon folders.
  Retirement requires explicit named authorization; no broad pruning or repeated
  copying of unchanged addons. DBM, HideClassBars and SharedMedia_Causese are retired.
- Commit and push tested source before building/deploying; retain exact receipts
  and document the installed version and dependency changes afterward.
