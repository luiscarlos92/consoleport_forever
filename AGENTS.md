## Current authority — candidate.13 repair, October 8, 2026

The user reports candidate.11/12 combat controller casting is broken and rejects
candidate.12 artwork/placement. Keep automatic ground placement enabled and fix
its interceptor; do not repeat native-only isolation. Read earlier chat history.
Deployment is authorized once WoW is closed. Preserve HUD size. Original Forever
art/source takes precedence; ask about material uncertainty. Candidate.13 adds
secure combat guarding of the unprotected UI cursor, exact original sprite UV,
empty-only glyphs, raised banks/prompts and a separate class badge. Revision-14/15
characters migrate the correct class side to revision 16 with in-game backups.
See docs/CANDIDATE13-REPAIR-2026-10-08.md. The old preparation/installed claims below
are historical; live hardware and final visual acceptance remain unverified.

## Installed candidate.12 — October 8, 2026, 06:16:20 UTC

Authorized closed-WoW deployment is complete. Candidate.12 is installed from
pushed/tested source e0dfd82439cf85c22443bd7c1e6b59d5597096dd; independent
readback verifies all 52 Forever files against the exact scoped ZIP. All 1,949
vendor files, 298 WTF files, 42 junctions and root anchors are unchanged. Backups
of the previous companion and canonical configuration are verified and retained:
C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261008T061555Z-0d0169ce11b0.
Receipt: evidence/delivery/live-install-candidate12.json; independent readback:
evidence/delivery/candidate12-independent-readback.json. All 43 runtime/source
suites and 39 tooling tests passed. Nine stable Retail releases were freshly
checked again before packaging; no dependency was downloaded or copied.

The UI now has circular face-button state/effect surfaces, grey glyph backgrounds
on all 32 cells, three device-specific modifier-bank prompts and native class-side
shoulder+trigger badges. Both current saved character records are accepted revision
14 with accepted rings, verified by fresh read-only parsing. On their first eligible
login the addon migrates the matching bindings and learned class entries together
with an in-game transaction backup, reaching revision 15. Warrior uses R1+R2/RB+RT;
druid/paladin use L1+L2/LB+LT. The replaced R2+menu class binding is removed.
Native gameplay/UI recovery and candidate.11 ground placement remain active.
Actual Retail visual/hardware/combat acceptance is pending; no game was launched.
This deployment authorization is complete; future deployments need fresh user
authorization with WoW closed. Never edit live WTF or prune unrelated addons.
See docs/FOREVER-UI-2026-10-08.md for source research and remaining client checks.

## Candidate.12 Forever UI work — October 8, 2026

User authorizes matching the attached native Forever controller interface and
closed-WoW deployment, including first-login application of necessary bindings.
Forever appearance/behavior is the reference; investigate material uncertainty
or use its verified behavior, rather than retaining an incompatible old mapping.
Candidate.12/revision 15 adds true round button-state surfaces, all 32 grey glyph
backdrops, three device-specific trigger-bank prompts and class-specific native
shoulder+trigger openers (warrior R1+R2/RB+RT; druid/paladin L1+L2/LB+LT).
Accepted revision-14 characters migrate the class chord/ring together on first
eligible login with an in-game transaction backup. No file edits to live WTF.
Keep native input recovery and candidate.11 ground placement; do not re-enable
custom SecureModes, UI takeover or hidden-control replacement. Nine current
stable releases freshly checked; no dependency updates. Full tests and scoped
build/preview/install/readback required. See docs/FOREVER-UI-2026-10-08.md.

## Installed candidate.11 — October 8, 2026, 00:59:13 Toronto

The user's "deploy now, I'll test tomorrow" authorization is complete. Candidate.11
is installed from tested/pushed source 66e15995aa1d608335169b1b112b997d0852c473.
Scoped preview/installation and independent readback verify 50 Forever files against
the exact prepared ZIP. All 1,949 vendor files, 298 WTF files, 42 character junctions
and anchors are unchanged; original code/configuration backups are verified and
retained. No dependency was copied or downloaded: all nine official stable Retail
releases were freshly checked/current. Forty-two runtime/source suites and 39 tooling
tests qualify the unchanged installed bytes. StoreSchema 3/revision 14 remain.

Ground placement is restored independently of native recovery. Custom SecureModes,
UI takeover and hidden-control replacement remain suspended; native ConsolePort owns
bindings/pages/UI. Configure per-spell/context placement in ConsolePort > Targeting.
Actual Retail combat/terrain/taint acceptance is pending the user's test tomorrow,
starting with ordinary combat abilities on a dummy and then placement/manual case 44.
No game was launched by the agent. Keep the demonstrated source defect distinct from
unconfirmed exact live-client root cause. Receipt: evidence/delivery/live-install-candidate11.json;
readback: evidence/delivery/candidate11-independent-readback.json. Backup:
C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261008T045847Z-fede3bd40bf1.
Earlier preparation/install rules below are historical. Any future deployment needs
new user authorization with WoW closed; never write live WTF or prune other addons.

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
