## Installed candidate.19 — October 8, 2026, 19:46:29 Toronto

Authorized closed-WoW scoped deployment completed from tested/pushed source
61bd8c5f95568440b0f6e5edd08d6804e70c7feb. Only ConsolePort_Forever was
replaced; nine official stable Retail dependencies were freshly checked again,
none changed/downloaded/reshipped. Independent readback verifies all 52 installed
files, 1,949 unselected addon files unchanged, 298 WTF files unchanged, 42 junctions
and root anchors preserved. Previous candidate.18 and configuration backups are
verified and retained at C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261008T234604Z-02718cc24421.
All 57 runtime/source suites and 39 tooling checks pass. Revision 17 remains;
no binding/config migration or filesystem live WTF writes. Native five-rune
player-strip suppression is installed; accepted candidate.18 feedback/cooldown,
R2/other HUD geometry and Ground.lua remain. Actual client visibility/combat/taint
acceptance remains pending user manual case 46; no WoW launch or live test.
Receipts: evidence/delivery/prepared-candidate19.json, live-install-candidate19.json
and candidate19-independent-readback.json. Pack SHA256: 0b4ba84ad32e1fb832000f8a01c689063626ff0957389df423929e3d997d59cb.
This deployment authorization is complete. Future deployments need new user
authorization with WoW closed. Earlier preparation-only restrictions below are
historical records, not current deployment instructions.

## Authorized candidate.19 deployment — October 8, 2026

The user states "wow closed deploy", superseding the preparation-only restriction
below. Process verification confirms WoW closed. Deploy the exact tested
candidate.19 with the scoped builder/installer, Forever only. All nine official
stable Retail releases were freshly checked again; none changed/downloaded.
All 57 runtime/source suites and 39 tooling checks pass for these bytes.
Preserve WTF, unselected addons, anchors, junctions and verified backups.
Revision 17 and accepted candidate.18 feedback/cooldown/geometry/casting remain;
only the native five-rune player-strip presentation changes. Do not launch WoW
or claim live rendering/taint verification; manual case 46 remains user-owned.

# Candidate.19: hide the native five-rune player strip

**Prepared only. DO NOT DEPLOY.** The user is playing. Candidate.18 remains
installed; the user confirms its action feedback, cooldowns and R2 alignment:
"all working". This confirmation excludes the reported player-strip regression.
No installation, reload, game interaction or live WTF access occurs in this task.

The screenshot's five black symbols in a gold holder below player health/mana
match PaladinPowerBarFrame, the native Holy Power resource strip. The retained
Blizzard PaladinPowerBar XML declares uf-holypower-runeholder and five rune
children. It inherits ClassResourceBarSelfManagedPointsTemplate, independently
of StanceBar. Existing T46/T48 only tested StanceBar and therefore could pass while
this separate strip rendered. Candidate.18 did not modify those aura/stance
functions. The exact live event that exposed this previously unmanaged resource
strip was not queried while the user plays.

Runtime.lua adds a narrowly scoped player-resource presentation policy for the
native PaladinPowerBarFrame instance and its verified PaladinPowerBar.UpdatePower
method. While the character is installed and Blizzard visibility policy enabled,
its opacity is zero during normal play. Secure post-hooks reconcile later native
opacity writes and OnShow refreshes; no protected reparent or hide occurs in
combat. The hook guard prevents recursion and captures the latest native opacity
for restoration. New hook acquisition waits until out of combat. Edit Mode,
disable, frame replacement, other classes and changed native method identity
release the override. Native shown state, event registration, power values,
updates, parent and anchors remain. The player health/mana, class-ring access,
nameplate and personal-resource clones are untouched; no CVar is rewritten.

T57 loads the actual native ClassPowerBar/ClassResourceBar/PaladinPowerBar
Setup, OnEvent, UpdateMaxPower and UpdatePower methods. It first reproduces the
visible five-rune strip, then checks effective painted visibility through six
combat/peace cycles and power values 0–5, native Show/Hide, resource/power/spec
events, PRD visibility toggles and late alpha writes. It asserts native resource
updates/events continue, only the exact instance is suppressed, parent/geometry
stay, latest opacity restores in Edit Mode/disable, replacement releases old
ownership and unsupported/foreign identities are retained. Engine setters and
animation/pixel rendering remain doubles; no actual Retail test is claimed.

The pre-fix T57 fails with "native five-rune strip still rendered under player
frame"; see evidence/aura-regression/candidate19-before.log. Mandatory mutations
removing the policy or late-writer reconciliation reproduce the visible strip.
The build gate requires T57. T31/T46/T48 still pass; the full suite retains
T24/T49/T53 brightness/roundness, T54/T55/T56 accepted action feedback/geometry,
and T41/T42 native dispatch/casting coverage. Exact native sources and hashes are
in evidence/aura-regression/native-manifest.json.

Candidate.19 changes Runtime.lua and the TOC version only. HUDPresentation.lua,
Skin.lua, ClassActions.lua and the user-accepted Ground.lua remain byte-identical
to candidate.18. Configuration revision 17 and saved bindings remain.
All nine official stable Retail dependencies were freshly checked again;
none changed or was downloaded. The source metadata records this session's
official CurseForge inspections and GitHub release check.

Full validation: 57 runtime/source suites and 39 tooling checks pass, with exact
reports retained under evidence/aura-regression/candidate19-*.json. Actual client
visibility and combat/taint acceptance await separately authorized deployment
and manual case 46. There is no pending design choice or deployment authority.
