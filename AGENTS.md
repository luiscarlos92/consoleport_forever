## Authorized candidate.11 deployment — October 8, 2026

The user explicitly requests "deploy now, I'll test tomorrow", superseding the
checkout-only restriction below. Deploy the already-tested candidate.11 scoped
Forever-only artifact with WoW closed, retaining backups and all junctions/WTF.
Freshly recheck all nine stable Retail dependencies; do not copy unchanged packages.
Native gameplay modes/UI/hidden-control recovery remains active; only the repaired
placement adapter is restored. Actual Retail testing is deferred to the user.

## Current checkout-only targeting authority

October 8: the user is playing. Diagnose and prepare candidate.11 only; DO NOT
DEPLOY or write live WTF/AddOns. Candidate.10 remains installed. Targeting may be
restored independently of native recovery, but keep SecureModes, UI takeover and
hidden controls suspended. Run T12 with actual Blizzard restricted environment and
T42 full native bindings-to-action dispatch, as well as T41 and the full suite.
See docs/TARGETING-REPAIR-2026-10-08.md. Older installed checkpoints below are history.

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

## Current recovery boundary

Candidate.10/native input recovery is installed (October 8, 00:11:20 Toronto).
Candidate.9 failed the user's live test. Do not claim that T41 fixed the complete
live cause. Keep native recovery active until live diagnosis/acceptance supports
restoring custom secure modes, ground casting, UI takeover and hidden controls.
Preserve saved policies/WTF. Receipt: evidence/delivery/live-install-candidate10.json.
All earlier installed checkpoints below are historical. New deployment needs authorization.

## Deployments

- Deploy only with explicit user authorization and WoW closed. Current installed
  checkpoint is candidate.9/revision 14 with unchanged ConsolePort 3.3.10
  (October 7, 23:58:54 Toronto). Combat handoff regresses the old hidden UI claim
  failure and restores native gameplay dispatch; 41 runtime/source and 36 tooling
  checks pass. All 1,949 vendor files, 298 WTF files and 42 links are unchanged.
  DBM, HideClassBars and SharedMedia_Causese remain retired. This authorization is
  complete; future deployments require new authorization. Retain every prior
  artifact/receipt/backup. See `evidence/delivery/live-install-candidate9.json`.
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
