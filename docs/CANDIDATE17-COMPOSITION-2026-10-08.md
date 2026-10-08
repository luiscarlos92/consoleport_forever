# Candidate.17 — filled round backdrop occlusion

Live acceptance: on October 8, 2026, after the installed repair, the user
reported "it works" and requested documentation/regression protection. The
combat-grey symptom is accepted as fixed. This supersedes this document's
pending-at-deployment notes; installer receipts retain their historical state.
No runtime change, version bump, migration or deployment accompanies acceptance.
Evidence: evidence/forever-ui/candidate17-live-acceptance.json.

Before candidate.17, the user confirmed candidate.16 labels and stance placement
worked. Only combat grey remained; no layout, class binding, bank opacity or casting changes belong
in this fix. The saved /cpf diagnose data is actual candidate.16 client evidence:
ready action/spell queries true, icon tint (1,1,1,1), alpha 1 and desaturation 0
on the affected round faces. Sanitized ready-face observations are retained in
evidence/forever-ui/candidate16-ready-face-observations.json. Previous colour
repair tests were insufficient: icon getter values do not prove final rendered
brightness. Neither RGBA correction nor desaturation explains these observations.

The pinned Blizzard ActionButtonTemplate creates icon and SlotBackground on
BACKGROUND sublevel 0, with SlotBackground declared later. Actual current Masque
Core.Skin_Icon restores Icon to BACKGROUND/0 during RemoveButton's default skin.
Our round skin made SlotBackground a 65% dark fill and always showed it, without
restoring a distinct draw order or suppressing it for assigned spells. It can
therefore darken a white, usable image while all observed icon values stay correct.
Masque UpdateButtonArt can also restore the native placeholder atlas in combat.
That layer is not one of the round border regions our combat repair previously
handled. D-pad faces do not receive our dark-filled round background.

Repair: assigned face icons draw on ARTWORK/0, slot background on BACKGROUND/-1.
Filled faces hide both SlotBackground and SlotArt. Hooks on native Show prevent
later combat updates from exposing them again. Empty cells retain the exact
original grey device artwork. Draw-layer/visibility updates alter no protected
attributes, geometry, actions, saved binds or pages. Existing circle masks,
round Normal_Custom retirement, native spell effects and genuine resource/range
colouring remain. Diagnostics now observe icon/background draw layers and native
slot background/art visibility in addition to the existing colour/alpha data.

T53 extends the host beyond icon fields: actual current Masque Core.Skin_Icon
and UpdateButtonArt, native XML declaration ordering, alpha composition at the
centre of a filled icon, repeated combat background reactivation, empty glyph
retention and existing round-mask identity. Candidate.16 reproduces the dark
result while icon tint is white. Reverting the layer/filled-background repairs
must fail. T24/T49 and full T41/T42 remain required. This is an offline composition
model/native-source reproduction; the reported symptom now also has the
user's live confirmation. No false claim of client rendering certification from pass counts.

All nine official stable Retail packages were freshly checked; none changed.
Keep scoped Forever-only deployment with WoW closed, verified backups/readback,
unchanged unselected addons, WTF and junctions. No filesystem live WTF writes.
The running in-game visual initialization applies these changes; config revision
17 and existing bindings remain unchanged. Ground.lua stays byte-identical to the
user-tested candidate.13 interceptor. The candidate.16 layout/class functions
remain byte-identical.

Validation: 53 runtime/source suites and 39 tooling checks pass. T53 includes
a mandatory old-backdrop negative control. Reports retained in
evidence/forever-ui/candidate17-runtime-tests.json and candidate17-tooling-tests.json.

Scoped deployment completed October 8, 2026 at 17:48:19 Toronto from source
4cbf2ebb094a7dddcd2c60e26de597b0439ab773. ZIP SHA256:
261a198ed6208250b5cadc673bc465e8dcc0ab7da85f37f70f8bce8b9a740ce6.
Preview and exact execution copied Forever only. Independent readback verifies
52 installed files, 1,949 unselected addon files, 298 WTF files, 42 junctions,
root anchors and previous companion/canonical WTF backups. Backup retained at
C:/Users/luisr/WoW-Backups/ConsolePort-Forever/20261008T214746Z-009b1434dce3.
Receipts: evidence/delivery/prepared-candidate17.json, live-install-candidate17.json
and candidate17-independent-readback.json. The subsequent user confirmation
is retained separately in candidate17-live-acceptance.json.

Acceptance regression expansion covers every PAD1–PAD4 in Base/L2/R2/L2R2,
six occupied types (action/spell/item/macro/flyout/held custom), six cycles each,
and both combat/peace native art resets: 1,152 redraws. It verifies all RGB
components of composed pixels, not only icon getters; clear/refill and empty
HasAction slots preserve original glyphs. Each late SlotBackground/SlotArt Show
must be retired immediately, before a later refresh can hide a defect. The same
mask object survives. Genuine unavailable/resource/range colours remain visible.
Three mandatory negative controls independently reproduce old matte occlusion,
a missing immediate Show hook and native same-layer reset. Original deployment
reports stay immutable; new maintenance reports use candidate17-acceptance-*.
