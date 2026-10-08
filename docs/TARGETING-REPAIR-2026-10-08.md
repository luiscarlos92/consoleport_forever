# Prepared targeting repair — October 8, 2026

Candidate.11 is checkout-only. The user is playing and has explicitly prohibited
deployment. Candidate.10 remains installed; a read-only comparison found all 50
installed Forever files still match its retained recovery ZIP. No installer was
invoked and live WTF was neither edited nor included in the prepared payload.

## Diagnosis

ConsolePort 3.3.10's Variables.lua provides center/free-cursor reticle settings and
recommends an @cursor macro for single-click placement. Those settings choose the
pointer/reticle behavior; they do not supply per-ability placement choices.
Forever already had such choices, but candidate.10 suspended the runtime casting
wrapper along with custom mode/UI interception.

The old test runner gave every restricted snippet an invented owner argument.
Blizzard SecureHandlers invokes the actual signature self,button,down and its
RestrictedExecution environment supplies the header as control. The unchanged
Forever wrapper fails under that corrected contract before native dispatch:
`attempt to index a nil value (global 'owner')`. The exact failing reproduction is
retained in evidence/targeting/native-control-before.txt. The previous test was
insufficient and should not have been treated as evidence of secure compatibility.

Forever now uses control. The pinned LAB OnClick also reads owner for flyouts, while
the pinned native CP group initialization does not define that upvalue. Preparation
initializes it only if absent, in that group's managed environment. Existing owners
are preserved. No upstream file is modified. The newly pinned RestrictedExecution
contract and T12 environment manager expose missing globals instead of inventing
runtime arguments. This is a demonstrated source defect consistent with the user's
combat report; exact live-client taint and any additional causes remain unverified.

## Resulting behavior

Known ground-target spells default to cursor placement; the retained Death and
Decay/Defile/Angelic Feather recommendations default to player placement. Both modes
use a secure /cast [@cursor] or /cast [@player] command, bypassing the second placement
click. Manual uses native targeting. Terrain/range and cast success remain game-owned.

Open ConsolePort settings > Targeting, choose Ordinary abilities / Vehicle UI /
Override bar / Temporary bar / Extra action, cycle each spell's placement and Apply
outside combat. A context-specific spell choice wins over the ordinary spell choice,
then context defaults, then the curated default. Settings are account-wide and shared
across specializations; existing saved preferences remain compatible. Encountered
abilities and Add spell ID support temporary/unknown reticles. Unknown abilities
retain native dispatch until an explicit cursor/player choice qualifies them.

Casting reads the current native resolved slot and actual temporary page. It no
longer requires Forever SecureModes or hardcoded L2R2 mode paging. Native Blizzard
vehicle/override overflow and extra-action buttons receive the same transient
placement adapter. Native button storage, display, bindings, page updates, normal
abilities, macros/items/flyouts, empowered actions, alternate clicks and UI ownership
remain in their original handlers. Only a qualifying hardware click temporarily
changes its dispatch attributes, restores them afterward, and latches the chosen
command/edge through release or cancels if ownership is lost.

Native recovery stays active for custom gameplay modes, UI takeovers and hidden
controls. No live configuration migration/rewrite or saved ability macros are needed.
The existing reviewed ground-placement enable policy remains respected.

## Validation and limits

T12 exercises the actual CP/LAB/Manager and Blizzard click/action handlers with the
native restricted environment manager. T42 joins actual Layers/Input engine routes
with that same click pipeline, covering all 32 controller chords, cursor casts and
ordinary UseAction, both cast edges, three UI/combat cycles, foreign modal ownership,
vehicle context in an ordinary bank, contextual unknown qualification, native overflow
and extra buttons, attribute restoration and full native dispatch after disabling.
T38 covers contextual account preferences and custom IDs. Product bootstrap rejects
custom SecureModes/UI acquisition while reaching placement preparation. The build
gate now rejects omitted, duplicate or failed runtime suites, with three new tool tests.

All 42 runtime/source suites and 39 tooling tests pass. Exact reports are retained in
evidence/test-results/candidate11-runtime.json and candidate11-tooling.json;
evidence/targeting/candidate11-preparation.json records the preparation boundary.
The installed executable reports 12.1.0.69933 through read-only file metadata.
All nine official stable Retail dependency releases were freshly checked and remain
current; no vendor package was downloaded, changed or copied. Actual Retail hardware,
secure/taint behavior, rendered terrain placement and persistence remain pending manual
case 44 after a separately authorized closed-WoW deployment. Offline checks are not
live acceptance, and the earlier candidate.9 result remains a failed user test.
