# Candidate.20: restore power and character-owned aura access

Candidate.19 hid PaladinPowerBarFrame instead of the reported native aura row.
The user explicitly reports the lost power bar and rejects that behavior.
Runtime.lua is restored byte-for-byte to candidate.18, removing all power-opacity
ownership. The actual three native aura buttons are StanceBar. Its conservative
visibility policy correctly retained access because no complete bound ring existed.
Read-only saved diagnostics confirm accepted revision 17, missing class opener,
utility-only current ring and an empty Demon Hunter Auras placeholder. The user
explains intentionally deleting the obsolete ring after its wrong chord and
cross-character appearance; no accidental deletion cause is inferred.

The old migration gate only considered revisions 14–16, so accepted revision 17
never repaired deleted class access. A one-time per-character classAccessRepair=1
marker now allows supported classes to recover learned forms and the native ring
opener through existing backup/rollback transactions and native SaveBindings.
Repair waits for complete form discovery, correct character binding bank, closed
native ring, current GUID projection and an out-of-combat writable state. Paladin
uses SHIFT-PADLSHOULDER (L1+L2). The obsolete R2+R1 opener is cleared only when it
targets the restored ring or obsolete Auras; unrelated commands remain intact.
No configuration revision bump or full installer prompt is introduced. Subsequent
player edits are respected after this one-time repair.

The obsolete-opener test also caught ResolveSet receiving native.api, a binding
wrapper with no UnitClass. It therefore inferred the default right-side chord.
RuntimeSetup now passes the full qualified game API so Paladin discovery uses
the correct left-side chord, instead of following a deleted right-side Auras.

Recovered CPFClass carries GUID/class ownership and stays in the character
archive, never native Shared. Projection and capture reject another character's
owned ring. The old synthetic empty Auras placeholder is no longer created;
unsupported classes drop an existing anonymous empty relic while retaining
populated/named manual rings. Demon Hunter receives neither Paladin ring nor
class chord; switching back restores Paladin's own archive and opener.

Investigation also reproduces an independent account-view capture bug:
CaptureControllerEdits previously copied account bindings into the GUID record.
It now requires native CharacterSet before capturing, preserving archives when
the account bank is selected. This is independently tested, not asserted as the
cause of the user's intentional ring deletion.

T57 executes actual native ClassPowerBar/ClassResourceBar/Paladin methods and
requires visible power through redraw/combat/editor/disable/replacement cycles.
An injected wrong power suppression must fail. T58 replays the missing-ring
accepted-17 condition through real bootstrap/native validation/compiler and
transaction machinery for Paladin/Druid/Warrior, verifies native aura refreshes
remain hidden only after complete access, old chord removal, utility preservation,
idempotence and Paladin→Demon Hunter→Paladin projection/binding ownership.
Missing revision-17 repair and missing owner filtering mutations must fail.
T59 reproduces account-bank archive loss; removing the new guard must fail.
The pre-fix T58/T59 failures are retained in candidate20-before.log. Existing
full rendering, geometry, combat dispatch, casting and installer gates also pass.

All 59 runtime/source suites and 39 tooling checks pass for retained report
hashes. Runtime/HUDPresentation/Skin/Ground preservation is independently checked
against accepted candidate.18. All nine official stable Retail releases freshly
checked in this session; none changed. Deploy Forever only with WoW closed,
preserving live WTF, unchanged addons, anchors, junctions and verified backups.
In-game repair uses normal game-owned saved transactions on next login. No game
launch, actual hardware/pixels/secure-engine/taint acceptance is claimed. Case 47
remains pending user verification.
