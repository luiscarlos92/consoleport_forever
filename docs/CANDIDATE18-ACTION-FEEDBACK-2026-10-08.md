## Installed candidate.18 — October 8, 2026, 19:04:57 Toronto

Authorized closed-WoW scoped deployment is complete from tested/pushed source
985d257d72d83184e92dcdf4a628e8dde3a00a43. Only ConsolePort_Forever was
copied; all nine official stable Retail releases were freshly checked again and
none changed/downloaded/reshipped. Independent readback verifies 52 installed
files, 1,949 unselected addon files unchanged, 298 WTF files unchanged, 42 junctions
and root anchors preserved. Previous companion/configuration backups are verified
and retained at C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261008T230430Z-f6b2d442f0d0.
All 56 runtime/source suites and 39 tooling checks pass; revision 17 remains,
with no binding/configuration migration or filesystem live WTF writes. Golden
native pushed feedback, round cooldown frame layering and mirrored R2 are
installed; accepted brightness/roundness, L2/other HUD geometry and Ground.lua
remain. Actual Retail animation/hardware/combat acceptance remains pending the
user's manual case 45. No game launched, reload or live test performed.
Receipts: evidence/delivery/prepared-candidate18.json, live-install-candidate18.json
and candidate18-independent-readback.json. SHA256: bc6e23005185aeae357cb08eb8fe50a7b353f7a57d2d071ff56c61bdc1210c88.
This deployment authority is complete; future deployments require new user
authorization with WoW closed. Older preparation restrictions below are history.

## Authorized candidate.18 deployment — October 8, 2026

The user explicitly requests "deploy", superseding the earlier checkout-only
restriction below. WoW is closed. Deploy the tested candidate.18 through the
scoped builder/installer, Forever only: all nine official stable Retail releases
were freshly checked again and none changed. Preserve all unselected addons,
WTF, junctions and backups. Configuration revision 17 remains; no binding/data
migration. All 56 runtime/source suites and 39 tooling checks pass for these
exact bytes. Actual Retail rendering/hardware/taint acceptance remains pending
the user's manual case 45. Do not launch WoW or claim a live test.

# Candidate.18: action feedback and mirrored R2 indicator

Status: checkout preparation only. **DO NOT DEPLOY.** The user is playing.
Candidate.17 remains the accepted installed baseline. No live AddOns/WTF access,
installer invocation, UI reload, game restart, or live test accompanies this work.
Candidate.18 changes presentation only; configuration revision 17 and the
user-accepted casting interceptor, bindings, bank geometry and class access stay.

## Findings and changes

**Pressed feedback.** Native pushed regions and input handling remain. History
shows the original skin used ConsolePort's RoundBorderHighlight image; the later
RoundRegion conversion uses a neutral pressed border, with a .6 grey fallback.
It also retains Masque's ARTWORK/0 state layer, shared by the icon after the
candidate.17 repair. HUDPresentation now puts the original transparent round
highlight on the native pushed region, tints it golden and sets OVERLAY/1 with
additive blending. Native press/release owns visibility. No new cast-success
listener, click interceptor, secure attribute, cooldown trigger or timer exists.
Native getter and field paths are repaired, including combat art refreshes.
Same-layer drawing depends on creation order; late icon replacement can occlude
the old state layer. Tests model both orders rather than assuming equal layers
always hide the pressed texture.

**Cooldown swipe.** Locked Retail LAB still queries game cooldown/charge/LoC
metadata and forwards native duration objects to SetCooldownFromDurationObject.
The retained Blizzard template sets useParentLevel=true for its cooldown frames;
the circular skin never separated them from the new ARTWORK icon. Skin.lua now
turns off parent-level sharing and places those existing frames one level above
the button outside combat. Round swipe texture, mask-sized bounds, translucency
and circular edge stay. Normal/LoC swipes are enabled; native charge drawSwipe=false
stays. Native casting alpha zero, LoC colour, countdown numbers, duration changes,
clearing, action pages and other VFX remain native. This is a source-level
rendering repair; prior engine pixel composition and the reported client symptom
cannot be certified by an offline frame model.

**R2 alignment.** BankPrompt uses the same right-D-pad-relative offset on both
sides, then LayoutGuard independently searches for clear space. Identical offsets
do not reflect labels across the screen origin; independent collision fitting
can give them different heights. LayoutGuard now reflects the final fitted L2
rectangle to place R2. It checks screen bounds and both native scale extremes.
R2 is not independently displaced away from that mirror if space is unavailable;
such a case reports pending geometry. The current matrix has no unresolved
collision. L2's algorithm and all bank positions remain. R2 retains its inactive
scale decorative parent and native visibility/opacity following.

## Regression evidence

- T54 executes actual current Masque Core.Skin_Texture and Blizzard down/up
  functions for 16 faces, two atlas modes and six states (192 cases). It checks
  state visibility, actual region order, golden round art, failed-use independence,
  release, resting masks/art, empty slots and resource/range colours. Layer and
  grey-tint mutations must fail. Engine state setters and TryUseActionButton
  remain doubles; ConsolePort secure dispatch is covered separately by T41/T42.
- T55 executes the SHA-qualified Retail LAB duration-object branch and Retail
  action getters for 16 faces and ten transitions (160 cases): GCD, ability
  cooldown, changed duration, off-GCD without cooldown, failure, completion,
  charges, LoC, replacement LoC, and missing duration. It checks opaque duration
  identity, native clear/show decisions, circular bounds, frame separation and
  charge/cast policy. Same-level and invented-cooldown mutations must fail.
  The host does not animate actual engine pixels or advance duration objects.
- T56 checks mirrored physical rectangles over five resolutions, three scales,
  two layouts and four selections. Old independent positioning must fail.
  Original and fixed algorithms produce identical rectangles for L2, every
  gameplay cell, combined trigger prompt and class shortcut/chord prompt in all
  120 cases. T50 retains the same frames through combat selection and refresh.
- T24/T49/T53 retain circular masks, actual Masque/native art redraws, immediate
  filled-background suppression and grey-regression negative controls. Full
  T41/T42 dispatch/casting and T45/T50/T51 geometry/opacity checks remain.
- The build gate rejects reports missing T54/T55/T56. Native function extraction
  accepts the whitespace in Blizzard's down/up declarations.

The six relevant existing visual suites passed before changes. Final exact-source
reports are evidence/forever-ui/candidate18-runtime-tests.json and
candidate18-tooling-tests.json: 56 runtime/source suites and 39 tooling checks
pass, with no unresolved failure. All nine dependency releases were freshly
checked using official GitHub identities and CurseForge listings/file pages.
All match the lock; none was downloaded or updated. See stable-recheck.json;
sources.json records fresh CurseForge inspection timestamps only.

## Live acceptance boundary

All three fixes are ready for separately authorized deployment and in-game
acceptance, with no pending product decision. No deployment or installer runs in
this task. Manual case 45 covers every bank, press/release, failed casts, actual
GCD/ability/charge/LoC sweeps and completion, combat/modifier transitions, scaling,
empty slots, existing overlays and accepted circles/class access/ground casting.
Retail pixels, hardware edges, protected-frame/taint behavior and animation timing
remain unverified; offline pass counts cannot replace the user's live test.
