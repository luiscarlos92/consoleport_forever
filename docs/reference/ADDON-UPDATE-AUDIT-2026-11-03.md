# Addon update compatibility audit

Status: maintained
Reviewed: 2026-11-03
Evidence: [official-file readback](../../evidence/dependencies/candidate44-installed-audit.json),
[current ConsolePort contracts](../../evidence/consoleport-contracts-candidate44/manifest.json),
[current integrations](../../evidence/integration-contracts-candidate44/manifest.json),
[decision 0009](../decisions/0009-capability-based-integrations.md).

## Established defect and repair

The pre-update Forever candidate.43 rejects ConsolePort 3.3.13 through 3.3.10-only
guards in configuration, rings, HUD, temporary routing, ping and contexts. Its
BetterBags, DynamicCam, ExtraFade, LiteMount and Pawn version guards also reject
the installed updates. This is a source-proven admission defect; which modules
were loaded in the user's current game session was not observed.

Candidate.44 removes every third-party version admission gate and retains
capability, ownership, readiness, value-shape and secure-body checks. ConsolePort
configuration additionally requires its native getter, and DynamicCam requires
the actual AceDB saved-variable structure. Version metadata remains diagnostic.
No runtime file moves, TOC order, schema/revision, protected dispatch, manual
configuration or retired feature changes are involved.

## Source and package review

The nine managed official packages and external Pawn match their complete
installed file inventories, with no missing, extra or differing files. Fresh
stable identities were checked through GitHub releases and the official
[DynamicCam file](https://www.curseforge.com/wow/addons/dynamiccam/files/9272555)
and [ExtraFade file](https://www.curseforge.com/wow/addons/immersion-extrafade/files/9272158).
Only Forever needs delivery; already installed dependencies must not be recopied.

Evaluated sources: ConsolePort 3.3.13, BetterBags v0.8.12, Immersion 1.4.61,
ExtraFade 1.18.2, DynamicCam 2.21.5, LiteMount 12.1.5-2, Masque 12.1.8,
Plater-v662, BetterWardrobe 6.12.5 and Pawn 2.14.1. These identify evidence,
not a runtime support allowlist.

ConsolePort's newer actionbar mapping adds Camelot-specific eight-slot bars;
Retail retains ordinary twelve-slot mapping. Native input/layers, modified bank
routing, ring entry mapping/automatic entries, editing, ping and follower paths
are exercised against the new capture. Masque composition uses current native
Group/Normal/Icon/Button/Texture sources. BetterBags retains the physical item
pool and upgrade-provider API; its new cache invalidation participates in the
Pawn source test. Full custom bag/UI takeover remains suspended. DynamicCam
adds a Ghost Wolf situation and retains AceDB profile ownership/RefreshConfig;
ExtraFade adds frame-level subtree restoration and retains its flat settings.
LiteMount's two named buttons/rules remain native. Plater and BetterWardrobe
have no dedicated Forever settings adapters; their official closure/notices
were reviewed without inventing one.

Auctionator, BtWQuests/Midnight, Leatrix Maps/Plus/Sounds and SimpleWaypoints
were scanned for direct integration and shared gamepad/input/tooltip hooks.
No source evidence selected a further Forever repair. Leatrix Plus can set the
maximum camera zoom at startup, overlapping DynamicCam's camera ownership.
Its disk options show MaxCameraZoom On, tooltip enhancement Off and quest
automation Off. This is a settings interaction to observe, not proof of an
engine fault or permission to change the user's settings.

## Validation and proof boundary

The full regression runner uses a separate current ConsolePort capture and new
integration capture, preserving old pinned evidence. It retains native restricted
compilation, input/visual/transition negative controls and historical bag variants.
T107 rejects the old version-gate defect; compatible future/missing metadata and
missing required API cases are covered. T108 runs actual Pawn 2.14.1 and
BetterBags v0.8.12 source with arbitrary future metadata, both provider load
orders, the assertions and 19 defect controls recorded in its exact-source receipt.
All 108 runtime/source checks and 76 tooling tests pass with matching complete
source inventories. [Qualification](../../evidence/test-results/candidate44-addon-compatibility-qualification.json).

Candidate.44 was installed November 3 at 19:21:17 Toronto from pushed source
`ec1f348ceab2dc267de09b822ac4270865394adc`, selecting Forever alone. All 61
files match the artifact independently; other addons, WTF, links/root anchors
and prior backups are preserved. Fresh Windows CI matches complete local
inventories; its follow-up changes only historical archive selection after an
unused old Masque asset returned 404. No additional runtime or dependency payload.
[Readback](../../evidence/delivery/candidate44-independent-readback.json),
[CI](../../evidence/test-results/candidate44-fresh-ci.json).

A tooling closure defect discovered with Masque's AllowLoadTextLocale TOC
annotations is repaired without changing upstream bytes. All declared locale
files remain mandatory; missing and escaping include negative controls remain.
Historical reconstruction explicitly selects the preserved old lock; current
captures must still match the current lock and all source hashes.

Offline C/UI models do not certify Retail engine authority, taint, timing,
rendering, persistence or CPU. K04/K05/K07 retain their existing acceptance
boundaries. After delivery, the user owns reload and checks of the ordinary HUD,
Base/L2/R2/L2+R2, temporary actions, ping/shared/follower rings and focused
Immersion rewards with and without L2.
