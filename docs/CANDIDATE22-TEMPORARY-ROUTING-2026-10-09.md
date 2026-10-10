# Candidate.22: all-character temporary routing

The user reports dragonriding taking over L2 on Demon Hunter and requires L2+R2
for every character. They subsequently authorize deployment after completion and
explicitly include possession, quest override bars, vehicle UI and other native
replacement bars. Deployment remains gated on full tests and WoW being closed.

## Cause

Native input recovery deliberately disabled the old SecureModes installer. That
also disabled the temporary-page adapter. ConsolePort's native Pager broadcasts
the current page to all groups, and its native main-bar buttons (slots 1-12)
follow that page. Here those slots occupy L2. Dragonriding's native bonus offset 5
becomes page 11, so L2 followed it while L2+R2's fixed ordinary slots stayed put.
The prior targeting-only/native recovery dispatch tests did not assert the
combined bank for temporary actions; testing the disabled old adapter in
isolation did not cover the installed recovery startup.

T61 now reproduces the L2 takeover through the actual pinned native Pager header
response and native button page handler before installing the repair. T62 checks
the actual recovery bootstrap calls the separate adapter for all 13 installed
class records even with the old full modes policy disabled.

## Repair and scope

TemporaryRouting is separate from the suspended full SecureModes/UI takeover.
It adapts native button state/page responses through ConsolePort's qualified
secure extension APIs; native Manager/Layers retain all input binding ownership.
Only L2+R2 maps to temporary cells. Ordinary banks retain their native bindings,
class bonus forms/stealth and manual main pages. Slots past native vehicle/override
capacity are empty rather than showing unrelated occupied storage.

The adapter uses native vehicle, override and temporary-shapeshift API/index
evidence, dragonriding's bonus page, and a high native-page fallback for possession
or quest variants without the usual family flags. Ordinary pages 1-6 and class
bonus offsets 1-4 are never classified as temporary takeover. Native high pages
preserve the last ordinary main page. No mounted/flying/class-name heuristic
triggers replacement, and no spell/action slot or saved binding is rewritten.

Native group visibility and modifier-opacity drivers shed only the old temporary
hide/zero prefix at runtime. The saved geometry/layout remains unchanged. Native
standalone override-page runtime claims are disabled to prevent a competing bar
from winning the same input; their saved definitions survive disable/restore.
The existing mouse-accessible native exit/qualified overflow surface remains
outside automatic interface cursor/window ownership. Native possession dismissal
and extra-action controls are retained; this repair concerns replacement pages,
not hiding or rebinding unrelated pet, extra-action, class or keyboard controls.

A hidden read-only resolved-action helper supplies the native Manager assist
wrapper with the button's actual resolved spell. The native global pager would
otherwise add page 11 again to ordinary low slots while the combination bank
owns riding. Original ring/click wrappers remain. Held button actions latch until
release; newer page/state requests apply afterward. Rebinding, native layout
rebuild and late environment callbacks reapply the adapter, with protected setup
deferred in combat. The entire class-neutral repair applies on login to installed
characters without changing configuration revision 17 or their GUID-owned data.

Candidate.21's prepared ping fix is included. Ground.lua, rendering, class rings,
accepted masks/feedback/cooldowns and normal UI recovery remain unchanged.

## Dependencies and delivery scope

All nine official stable Retail sources were freshly checked this session;
none changed or were downloaded. Candidate.21 previously prepared Plater v657,
but the current live Plater now already matches every one of its 524 official
files, with no missing/different/extra file. Its receipt is retained. Therefore
the authorized scoped update includes Forever only. Do not reship Plater or the
other eight current dependencies. This supersedes candidate.21's earlier pending
Plater deployment scope based on its then-current installed state.

Use the scoped tested builder/installer; preserve backup folders, root anchors,
all unselected addons/helpers, WTF content and junction topology. No filesystem
live WTF edits or automatic game launch/reload are authorized.

## Validation and client limits

T61 covers all 13 classes and all 32 chords across ten states: normal,
dragonriding, vehicle, possession, override, quest override, temporary shapeshift,
unflagged native possession page, class form and stealth. It checks 4,160
display/engine-dispatch cases, six-button capacity, manual page retention, repeated
configuration, native rebuild, held transition, custom restoration, modal priority,
disable/re-enable, resolved assist and the accepted ground-casting interceptor.
Mandatory mutations reproduce skipping the adapter and assigning temporary cells
to L2. T62 rejects omitting it from actual recovery startup. T41/T42 and all prior
rendering/casting/character gates remain required alongside full tooling checks.

Restricted APIs, native source bodies and input arbitration are exercised offline;
the client engine, real class/spec/control states, renderer, controller hardware
and taint are not certified by these tests. User-owned manual case 49 remains
required after installation. Confirm takeoff/landing/dismount, ground spells,
quest possession/override/vehicle enter/exit, class form transitions, ordinary
page return, held release, UI/combat handoff and character A-B-A behavior.

Final verification: all 62 runtime/source suites and all 39 tooling checks pass
for unchanged source hashes. Reports: evidence/test-results/candidate22-runtime.json,
candidate22-tooling.json and candidate22-plater-live-readback.json.

Installed October 9, 2026, 22:59:10 Toronto from source 9c3556fd440bb5729f7673dbbe70b754271df1b2.
Independent readback verifies all 55 installed files, 2,498 unselected files,
304 WTF files and 42 junctions unchanged/preserved as scoped. Previous code and
configuration backups are verified and retained at C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261010T025816Z-894f53729e4d.
Only Forever was copied; Plater and other addons remain byte-for-byte unchanged.
Receipts: evidence/delivery/prepared-candidate22.json, live-install-candidate22.json
and candidate22-independent-readback.json. The authorization is fulfilled.
Manual cases 48/49 remain pending; no game launch or client test was performed.
