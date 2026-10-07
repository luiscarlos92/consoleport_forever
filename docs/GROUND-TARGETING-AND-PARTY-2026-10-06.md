# Candidate.6: cursor casting and Party defaults

The user authorized implementation and package preparation, and prohibited
deployment with WoW open. DBM is intentionally disabled for now. This update
ships only Forever; no dependency/DBM bytes, addon-enable state or live WTF is
changed. Installed candidate.5/revision 12 remains the live version.

## Ground spells

Revision 13 offers `groundTargetingEnabled` through the existing reviewed runtime
policy, with Accept/Keep mine, combat/Edit Mode deferral and retained restore
journals. It depends on the accepted native four-group mode layout. There is no
saved macro per ability: normal native spell slots remain on the bars.

`Targeting/Ground.lua` prepares localized `/cast [@cursor]` commands outside
combat on the existing native headers. A restricted OnClick wrapper reads the
actual resolved action/ID at the controller press. Only registry-qualified spell
actions use the transient native macro dispatch. Explicit unqualified overrides,
missing data, alternate click attributes, items, saved macros, flyouts, assisted
combat and empowered actions remain native. No insecure callback casts, places
a reticle, creates a saved macro or owns a new controller binding.

The wrapper keeps native slots, spec/loadout storage, icons, tooltips, cooldowns,
modifier banks and temporary pages. It avoids the native helpful-spell assist
selector only for a qualifying cursor cast, while preserving UI/raid/target-ring
owners. The command and click edge are latched on press. A changed input owner,
hide or disable cancels an outstanding cursor release. Attributes are restored
by the native wrapper's post body; repeated initialization installs no duplicate
wrappers. Native key-down/key-up preference and fallback hold/release behavior
are retained. `/cpf proof` includes ground-policy/prepared/pressed status.

The initial registry has 47 IDs, including Sigil of Misery, Flame, Doom, Silence,
Chains and Spite, Infernal Strike, Metamorphosis and Shift. Evidence and exclusions
are in `evidence/targeting/ground-spells.json`. Some legacy reticles are supported
by the original ConsolePort author's empirical classification plus current
tooltip consistency; they still need live Retail revalidation. This is not a
universal AoE predicate. In particular Ravager/Binding Shot's changed targeting,
unqualified IDs, pets and multi-stage Demonic Gateway remain native; Anti-Magic
Zone/Volley await stronger current classification. Registry updates require
source evidence, not merely an AoE description.

ConsolePort's gamepad camera mode uses a hidden cursor at its configured centered
screen position; unlocked cursor mode uses the actual pointer. `[@cursor]`
follows that position, not the selected enemy or an exact camera ray in every
mode. No camera/cursor CVar or crosshair setting changes. Terrain/range failures
remain ordinary game failures.

## Party Frames

`UI/PartyLayout.lua` proposes the native compact Party Frames below the current
Raid frame, left aligned: Party TOPLEFT to Raid BOTTOMLEFT, with an 8-unit gap.
Native `UseHorizontalGroups=0` makes one vertical column;
`UseRaidStylePartyFrames=1` selects the compact style shown in the reference.
Other Party dimensions/settings, Raid and all other screenshot experiments
are retained. It uses native frame identity/enums rather than hardcoded enum
numbers or screenshot coordinates.

The proposal is part of the existing Edit Mode managed-copy review. First setup
still copies the actual active layout. A known managed copy is reused even if
inactive, and updating it preserves the user's current experimental selection.
Unowned matching names cannot be claimed. Missing/duplicate records, unavailable
contracts and a direct Raid-to-Party anchor cycle defer this default locally.
Native SaveLayouts/select/export/readback and existing retained journals apply
and restore it; no live frame UpdateSystem/systemInfo write or filesystem edit
to WTF occurs.

## Better Wardrobe and Transmog

The user installed and adopted Better Wardrobe and Transmog as a pack dependency.
The current official stable Retail release is [6.12.3](https://github.com/SLOKnightfall/BetterWardrobe/releases/tag/6.12.3),
also confirmed by the [official Retail file](https://www.curseforge.com/wow/addons/better-wardrobe-and-transmog/files/8809353).
The exact GitHub archive has independently advertised SHA-256
`abcba6be5535c15a581721192a5c4865e05b568dbac52d79c108c89e6c763d8c`.
Only this newly adopted package was downloaded into the checkout. All 18 existing
versions, archives and files remain unchanged; derived TOC metadata is normalized
by the corrected parser. The fresh stable check now covers 19.

Both `BetterWardrobe` and its load-on-demand `BetterWardrobe_SourceData` helper
are included in explicit added coverage, preserving the immutable October 3
reference. All 149 official files already match the installed files with no
extras. This scoped update records the dependency identity and leaves the
matching live folders in place. Full official package/library bytes are retained
in the qualified source cache, with original notices and terms inventoried.

The runtime include closure is complete. Required `Blizzard_Collections` and
`Blizzard_Transmog` are qualified with hashed native Retail TOCs, rather than
classified as missing external addons or shipped with the pack. Unknown native
addon names receive no exemption. All 108 Lua files parse under Lua 5.1 grammar;
the parser's rejection of legal `break;` syntax is independently reproduced and
resolved only in token-selected in-memory parsing buffers, preserving every
upstream byte. Evidence is in
`evidence/dependencies/betterwardrobe-2026-10-06.json`.

Better Wardrobe owns its options, native tabs and recolor-helper loader. Forever
does not enable it, write its configuration or add custom addon-specific routes.
Existing guarded native window/cursor behavior remains. Actual rendered/controller
navigation, filters, transmogrification and recolors need live acceptance.

## Verification and delivery

New suites execute the pinned ConsolePort state/Manager/LAB click bodies and
Blizzard Wrapped_Click/secure macro/action dispatch, plus native Party anchor,
orientation and compact-frame generation methods. Coverage includes combat
guards, mouse/native fallback, supported replacements, alternate attributes,
modifier/slot/temporary changes, click edges, localization/data failures,
owner/hide/disable cancellation, proposal-only behavior, Keep mine, queued
acceptance, restore, active/inactive owned layouts, scale and unrelated fields.
The full-TOC lifecycle also models DBM installed but disabled and rejects an
attempt to enable it or load any optional addon through that route.

All 37 runtime/source suites and all 32 guarded tooling tests passed. Exact product,
tooling inventories and dependency-lock hashes were independently read back.
Run `tools/Test-All.ps1` to repeat the checks.
Reports are retained as `evidence/test-results/candidate6-runtime.json` and
`candidate6-tooling.json`. Source hashes, package and delivery receipt are checked
before handoff. Hardware/taint/rendered placement, actual cursor intersection,
native saved-layout persistence and all class reticles remain live acceptance.

The small update is built with `python tools/build_update.py` after tested source
is committed and pushed. The package contains only `ConsolePort_Forever` and no
dependency updates, including no DBM. Its receipt is retained under
`evidence/delivery/prepared-candidate6.json`. No installer is run. After a later
authorized deployment, normal in-game revision 13 review enables the policy and
applies the Party default; Apply/Reload retains its backup.

Prepared artifact: `dist/2.0.0-candidate.6/ConsolePort-Forever-Update-companion-only.zip`.
It contains 47 exact Forever files, is 474,986 bytes, and has SHA-256
`92ae073ddac4acaebe0d683c11cdadcb8e90e511dac4e038ad831b50656d001c`.
Tested source commit: `cfab284241348ce95d1757157e2c0f92a683046e`.
Independent archive readback confirms revision 13, all product bytes, both test
report hashes, the current dependency lock, Better Wardrobe in all 19 tested
identities, and no dependency/DBM/WTF payload. WoW was still running at verification.
No installation/preview command against the live game was run. The receipt is
committed separately after building and does not alter the tested source bytes.
