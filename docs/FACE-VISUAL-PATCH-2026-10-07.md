# Candidate.7 face-button visual patch

The user authorized fixing the visual regression observed after candidate.6
with ConsolePort 3.3.10 was deployed. Circle and Triangle behavior still works;
cursor/player targeting was confirmed working. This patch is prepared only.
Candidate.6 remains installed until a new authorized closed-game deployment.

## Diagnosis and implementation

The old skin relied exclusively on its own event frame for startup. Event
registration preceded handler installation and included legacy PARTY_SYNC
names. An unavailable registration could abort initialization; normal runtime
readiness never explicitly refreshed the skin. This is a source-confirmed
failure path, not a claim that those events were rejected in the user's live
session. No live error capture was supplied.

Candidate.7 installs the handler first, validates supported events using pinned
C_EventUtils.IsEventValid, protects each registration, and explicitly requests
a refresh from normal accepted runtime readiness. World, binding, group and
addon changes refresh presentation. Requests coalesce; native bank rebuilds
and Masque load callbacks retain their scoped refresh hooks.

A private circular mask is retained per face button. A native replacement of
the IconMask field cannot discard that ownership. Removing the attached mask
invalidates the connection cache and schedules restoration. Icon-region
replacement reconnects the same mask and releases the old attachment. Optional
border/highlight texture holes no longer stop later textures from being rounded.
The native cooldown circular-edge setter is optional for compatibility.

Frame/mask geometry and Masque group membership repairs defer during combat;
custom artwork and native availability feedback still refresh on native icon
updates. Combat-end refresh restores deferred masks. One face's refresh failure
is recorded as pending without aborting all the other faces; a later refresh
can recover it. The new faceSkin diagnostic reports prepared faces and explicitly
leaves rendered Retail acceptance pending.

Only Forever source changes. Its existing circular face geometry and custom
Exit/look/Jump/Interact art remain. The installed Masque dependency and settings,
D-pad Masque ownership, native unavailable/range/resource/zone colors and the
candidate.6 translucent cooldown fix remain. All targeting modules, bindings,
preferences, Party placement, StoreSchema 3 and configuration revision 13 are
unchanged. No extra @unit targeting modes are part of this patch.

## Verification and delivery

The expanded T24 executes pinned native CP 3.3.10 and Masque lifecycle bodies.
It now starts through actual event/readiness requests rather than directly
applying the skin. Cases cover invalid/unavailable registration, delayed
character acceptance, coalescing, native artwork replacement, mask removal,
region replacement, sparse borders, failure isolation/recovery, late Masque
loads, bank rebuilds, combat deferral and world-entry restoration. Existing
availability, legitimate unbound glyphs, cooldown and D-pad tests remain.
Full-TOC bootstrap separately asserts normal runtime readiness requests skin
initialization. Native EventUtils API evidence is pinned to Blizzard source
revision 09b9db7948abc9b9648dedaab51eb0cf3ee67b31.

All 39 runtime/source suites and 33 tooling tests pass. The scoped ZIP has
been independently read back and matches all 49 Forever source files. Offline Lua simulation does not prove Retail geometry, controller
input or combat taint acceptance. Manual case 41 is the later in-game check.

All 19 dependencies were freshly checked this session: no changed packages.
The verified scoped update contains only ConsolePort_Forever, retaining tested
identities for all 19 dependencies including Better Wardrobe. It includes no
vendor, DBM or WTF bytes. No installer is run for this patch. Prior artifacts,
receipts and backups are retained; DBM remains disabled/user owned.

Prepared artifact: `dist/2.0.0-candidate.7/ConsolePort-Forever-Update-companion-only-visual-fix.zip`.
Size: **481,795 bytes**, 49 Forever files. Source commit: `a15232604b5757a2254d295e7b5ecd8fda3d5046`.
SHA-256: `59726ecde789ecd2c75bffe5e612d288aa4e84f145a09e4801a7eb09cf9d3b4e`.
Independent receipt: `evidence/delivery/prepared-candidate7-visual.json`.
Exact retained reports: `evidence/test-results/candidate7-visual-runtime.json`
and `evidence/test-results/candidate7-visual-tooling.json`.
Against deployed source 580f1e3, only Skin.lua, the readiness call in the main
module, and the TOC version differ; the other 46 payload files are unchanged.
All previous candidate.6 artifact checksums are unchanged. Candidate.6 remains
installed; no live addon/WTF files were written and no installer was invoked.

## Authorized deployment - October 7, 2026, 15:10:51 Toronto

The user then said "WoW is closed, you can deploy", superseding the preparation
boundary above. WoW closure and anchors were verified, all 19 official stable
Retail releases freshly checked (unchanged), and the exact tested artifact
was previewed then installed through tools/deploy_update.py. No rebuild,
product change, dependency update or reshipping was needed.

Independent readback confirms all 49 Forever files match the ZIP, all 3,842
vendor files and directories remain unchanged, all 298 WTF files and 42 links
match the before snapshot, and root anchors are unchanged. Both old Forever
and canonical WTF backup bytes are verified. DBM stays disabled/user owned;
no live WTF files were written. Backups/staging snapshots remain preserved.

Installed source: `a15232604b5757a2254d295e7b5ecd8fda3d5046`.
Receipt: `evidence/delivery/live-install-candidate7.json`.
Backup: `C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261007T191022Z-cb816cd1554e`.
No configuration revision or targeting changes. The user can launch WoW and
perform manual case 41. Actual rendering, availability transitions and combat
taint acceptance remain pending their in-game result.
