# HideClassBars replacement and dependency retirement - October 7, 2026

The user authorized implementing missing HideClassBars behavior, preserving
controller access to hidden controls, retiring HideClassBars, and deploying with
WoW closed. They subsequently uninstalled DBM and authorized its removal from
active repository dependencies. SharedMedia_Causese removal was conditional on
being unused.

## Findings and replacement

The exact official HideClassBars v1.1.0 source controls StanceBar for Warrior,
Priest, Rogue, Druid and Paladin, plus VehicleSeatIndicator. Read-only live
settings show all six options enabled. ConsolePort 3.3.10 explicitly leaves
StanceBar hiding commented out and does not hide the vehicle seat indicator.
Forever's old parent-based policy handled only side bars and the bags/micro strip.
The class form discovery/selector preparation existed but was inactive; that
preparation's independent exact stick-return/cancellation gates remain pending.

Candidate.8 uses StoreSchema 3 and configuration revision 14. A separately
reviewed hiddenAccessEnabled policy adds current native discovered stance/form
spell IDs to the already bound class ring (CTRL-PADFORWARD, R2 + menu with the
current reviewed mapping). Native ConsolePort press-point-release/confirmation,
spell execution, icons and usability remain authoritative. Manual class entries
and metadata survive; duplicate numeric spell IDs are avoided. Generated entries
are marked autoassigned and excluded from the GUID manual archive. Spell, form,
specialization and binding changes refresh outside combat after an open ring
closes. No new controller binding or user macro is installed.

The existing utility ring (SHIFT-PADFORWARD, L2 + menu) gains Vehicle seats.
Native custom-binding compilation produces an internal /click to a Forever-owned
secure click handler. A hardware release toggles a separate secure parent for the
unchanged Blizzard VehicleSeatIndicator; native seat buttons and their actions
remain intact. The explicit opened panel enters ConsolePort's normal interface
cursor stack; select seats with its usual controls and use Close or select the
utility entry again. Native seat hiding on vehicle exit closes the panel. Opening
outside a vehicle is a noop. No automatic interface-cursor activation happens
when entering a vehicle with the panel closed. This panel does not replace the
existing secure vehicle actions/exit routes.

Only a proved available current ring opener permits suppressing the corresponding
native frame. Missing rings, unaccepted ring projection, changed opener, unavailable
form discovery, an unsupported class or a native-frame identity change retain
Blizzard access. Edit Mode and disabling the policy restore captured parents.
No native shown-state, events, action storage, visibility method or dependency
source is replaced. Protected configuration changes defer in combat.

## Dependencies and SharedMedia audit

All 19 then-active official stable Retail identities were freshly checked before
product edits and current; no package was downloaded/re-extracted. After removing
HideClassBars and eight DBM repositories, the 10 remaining packages were freshly
rechecked and current. Official CurseForge file/listing browsing verifies DynamicCam
2.21.1 (8995535), ExtraFade 1.18.0 (8995675), SharedMedia_Causese 7.6 (7242737).
Sources, lock, coverage, notice review, optional capability probes and future
resolver coverage now exclude the retired dependencies. Official archives,
notices, original references, prior receipts and explicit retired package identities
remain retained for history/recovery. DBM is absent from the live addon directory.
Voice-source checks are inapplicable without DBM in the active lock.

SharedMedia_Causese remains. A read-only literal parse confirms all four current
Plater profile keys select Default, which has no direct cast-sound assignments.
The saved Quazii Plater Season 4 profile has 164 assignments directly pointing to
Causese files (Front, CC, Jump, etc.). Plater_Audio.lua calls PlaySoundFile on the
selected profile's cast_audiocues paths. Deleting the sound package would break
that retained profile. This is a saved-profile dependency, not evidence that the
current Default profile is playing those cues. Exact evidence is
`evidence/dependencies/sharedmedia-usage-2026-10-07.json`.

## Verification and delivery

Native Blizzard vehicle visibility Lua/XML and ConsolePort's current Mainline
hide policy are pinned unchanged with hashes. The new runtime suite covers all
five classes, changing learned forms, retained manual entries, repeat refresh,
native ring action compilation, secure press/release reveal and close, combat
write deferral, vehicle exit/empty-panel cleanup, missing openers, Edit Mode and
disabling. Existing source/runtime suites still apply. Tooling covers explicit
retirement coverage, exact scoped backup/parking, unselected addon/WTF preservation
and interruption rollback restoring both Forever and HideClassBars.

The scoped builder requires an explicitly declared --retire-addon HideClassBars;
the installer preview includes only Forever replacement and that retirement.
HideClassBars is backed up and parked outside AddOns; no recursive deletion or
broad prune occurs. DBM bytes are neither shipped nor copied. Normal revision-14
accept/keep review remains in-game; the disk installer never edits WTF.

Actual Retail ring input, stance toggling, vehicle seat navigation, taint and
rendering remain manual acceptance checks. Offline tests do not certify them.

All 40 runtime/source suites and 36 tooling tests passed on the final source.
Exact reports: evidence/test-results/candidate8-runtime.json and candidate8-tooling.json.

Deployment completed at 17:43:12 Toronto with exact source above. The verified ZIP
SHA-256 is `72c945b43fa9966df0187e3fb637c1874c843c9d1ac6cd370b99ec3743217aa7` (483,855 bytes). Backup:
`C:\Users\luisr\WoW-Backups\ConsolePort-Forever\20261007T214245Z-0232c10f0b58`. Scoped readback verifies 50 Forever files, removal/retained
backup of HideClassBars, 2,165 untouched other addon files, 298 untouched WTF files
and 42 untouched junctions. Exact receipt and independent readback are retained.
