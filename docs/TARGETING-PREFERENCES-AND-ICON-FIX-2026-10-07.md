# Candidate.6 refinement: targeting choices and face-button availability

The user authorized these changes in the same unshipped candidate.6. Deployment
is prohibited until explicitly authorized, even if WoW closes. Installed
candidate.5/revision 12, live AddOns, live WTF and disabled DBM remain untouched.
Party's reviewed vertical default beneath Raid and Better Wardrobe dependency
coverage remain part of the candidate. No vendor code is patched or reshipped.

## Account targeting preferences

ConsolePort's native configuration gains a **Targeting** tab, through its audited
`CreatePanel` API. It shows the current class's qualified ground-placement spells
across all specs, including unlearned/talent options, plus encountered temporary
abilities and vehicle/override/temporary/extra-action defaults. It excludes the
other classes' catalog. Select a placement button to cycle **Default**, **At
cursor**, **At player**, **Manual placement**. Apply saves the account-wide draft;
Revert discards it. Native Defaults resets this class and the context defaults in
the draft, preserving other classes and explicit encountered-ability choices.

One numeric spell ID is saved in `shared.groundTargeting.spells`, never by GUID or
spec. Context fallbacks live in `shared.groundTargeting.contexts`; an explicit
ability choice wins in every context. Prior preferences are retained in
`shared.groundTargetingHistory` on Apply. StoreSchema 3, revision 13 and version
candidate.6 remain unchanged because this candidate was never deployed. Apply
during combat refuses without saving; secure preparation waits for normal
out-of-combat refresh. The existing ground policy still requires reviewed setup.
No saved macros, native spell slots, bindings, loadouts or cursor CVars change.

PvE defaults use `@player` for Death and Decay, Defile and Angelic Feather;
other qualified reticles use `@cursor`. Method documents self placement alongside
cursor placement for [Death and Decay](https://www.method.gg/guides/blood-death-knight/interface-and-macros)
and self placement for [Angelic Feather](https://www.method.gg/guides/holy-priest/interface-and-macros).
Defile's self-placement default is our melee-PvE recommendation. Cursor examples
for sigils/movement, healing areas, damage areas and utility are retained from
original player/guide/addon authors in `evidence/targeting/pve-defaults.json`.
Extending cursor placement to other qualified reticles is a recommendation,
not a claim of unanimous player preference or a universal best option.

The source-qualified catalog now contains **53 IDs**. New qualification covers
Anti-Magic Zone, Volley, Demonic Gateway, Surging Totem, Totemic Projection and
Earthen Wall Totem. Demonic Gateway's former conservative exclusion is superseded
by an original addon author's explicit cursor macro. Ground eligibility evidence
is retained in `evidence/targeting/ground-spells.json`. Class lists and source
default records are checked against the runtime catalog. Generic `@target`,
`@focus` and `@mouseover` do not supply unit-position destinations for reticles
and are not offered as ground-placement modes.

The secure click reads the actual resolved spell, and latches its command/edge
until release. Main cells use their normal ability policy; L2R2's temporary page
inherits context fallbacks. Existing overflow 9–12 and qualified native extra
actions use LeftButton's native numeric attribute suffix, with full temporary
attribute restoration. Exit is not intercepted. Native owners, pickup/alternate
clicks, empowered/assisted actions, macros and items keep their existing routes.
Disable/hide/owner loss cancels an outstanding release.

WoW exposes no reliable universal pre-cast reticle predicate. Context defaults
apply to qualified ground spells only. Unknown temporary abilities appear when
encountered and remain native until the user explicitly selects cursor/player
for that ability. Their choices persist account-wide; encountered rows are
retained per character for relevance. Manual/default removes that explicit
qualification. Unqualified replacements and unavailable data remain native.
This protects ordinary unit/self-targeted vehicle attacks. Future class/quest
IDs still require qualification; the catalog is not an exhaustive future API.

## Face-button diagnosis and fix

Current ConsolePort 3.3.9 LAB `UpdateUsable` sets icon desaturation for a party-sync
lock, but never clears it when the lock disappears. Its full Update clears it;
quick usability/transition updates can leave grey artwork. The companion now
refreshes only PAD1–PAD4 in the four banks, including during combat, using the
current level-link lock and zone-disabled state. It retains LAB's actual range,
mana and unusable vertex colors, and preserves unknown/secret lock states.

LAB's native cast-finish callback also restores cooldown swipe alpha to **1**.
Forever's existing circular face skin detaches those faces from the native
Masque group for scoped geometry; it previously restored no translucent swipe
color. Repeated GCDs can therefore cover their artwork almost continuously.
The scoped hook caps the face cooldown swipe at **0.65**, preserving alpha zero
during casting, loss-of-control color, progress and charge counters. D-pad
membership and cooldown appearance remain native Masque-owned. The circular
masks/borders and installed Masque dependency remain in place. This diagnoses
two source-confirmed causes; rendered Retail confirmation remains pending.

## Verification and retained delivery

`T24` executes current native usability and cast-finish bodies and proves lock
unlock, resource/range/unusable tint, zone-disabled feedback, transparent casting,
translucent finish, D-pad isolation and inactive-hook behavior. Ground tests use
native CP/LAB/Manager state/click wrappers, Blizzard Wrapped_Click and secure
dispatch for account choices, manual fallback, temporary context overrides,
explicit unknown qualification/removal, supplemental/extra restoration and the
existing held/input-owner cases. `T38` executes actual native panel registration,
deferred loading/nav lifecycle and draft Apply/Revert/default behavior, class
filtering, account/spec independence and combat refusal. Full-TOC regression
checks continue to include Party defaults and disabled DBM.

The full required runtime/source and tooling reports must pass before source is
committed/pushed and the scoped builder runs with `--label targeting-options`.
The earlier immutable ZIP and `prepared-candidate6.json` remain historical,
superseded evidence. The new receipt is
`evidence/delivery/prepared-candidate6-targeting-options.json`. No installer runs.
Hardware, taint, actual ground intersections, rendered tab/controller scrolling,
face colors and logout/reload persistence remain Retail acceptance, not offline
test claims. See cases 39–40 in `MANUAL-TEST-CASES.md` after future authorization.

Full verification passed: **38 runtime/source suites and 33 tooling tests**,
with no failed or skipped checks. Exact result inventories are retained in
`evidence/test-results/candidate6-targeting-options-runtime.json` and
`candidate6-targeting-options-tooling-final.json`.

The earlier targeting-options tooling receipt is retained as superseded evidence:
the final UI combat-test addition changed its harness inventory. The final
33-test rerun above matches the exact current tooling and runtime inventories.

Prepared and independently read back: **49 exact Forever files**, 481,013 bytes,
all 19 tested dependency identities and zero dependency/DBM/WTF payload. Artifact:
`dist/2.0.0-candidate.6/ConsolePort-Forever-Update-companion-only-targeting-options.zip`.
SHA-256: `20f5c234aac506555cb01bdc612453f0d62fcfbb73930fabc0609eb4b94f8c10`.
Source: `2075892c76f05ecdac15398a9a5c5d24a95a0756`.
The verified receipt above is retained; the earlier ZIP checksum is unchanged.
Nothing was deployed.
