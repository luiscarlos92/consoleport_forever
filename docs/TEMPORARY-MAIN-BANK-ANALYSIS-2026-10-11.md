# Main face buttons during temporary bars â€” October 11, 2026

User report: an override quest bar occupied L2+R2; main Square did not
interact with an item on the floor. Request is analysis and confirmation.
Follow-up: quest name is unknown, both triggers were released, the user pointed
at the item with a floating hand visible, controller Square did nothing, and
the physical mouse could interact successfully. This supports a real reported
controller interaction failure but does not reveal the effective engine binding
or establish that the native soft-interact target matched the hovered object.
No runtime patch, package, deployment, game input or live WTF write is authorized
or performed by this investigation.

## Source findings

Installed candidate.30 TemporaryRouting.lua and Reference.lua match checkout
SHA256. The current temporary routing assigns `cpf-temp-special-cell` only to
L2R2. Base, L2 and R2 retain their ordinary binding model and action page.
Runtime visibility/opacity drivers remove the old vehicle/override hide clause;
the native standalone override Page is hidden and its binding claim disabled.
Saved layout geometry and ordinary action storage are not rewritten.

The shipped main face mapping in Reference.lua is:

| Face | Physical key | Ordinary command |
| --- | --- | --- |
| Cross / X | PAD1 | JUMP |
| Circle | PAD2 | Empty; user edits may differ |
| Square | PAD3 | INTERACTTARGET |
| Triangle | PAD4 | TURNORACTION |

Native ConsolePort ProxyButton:RefreshBinding represents non-action commands as
custom cosmetic buttons, without registering an action-button override for them.
Layers mirrors the saved command in STORED and resolves it as a binding command.
Those commands do not become vehicle action slots just because the button is
visible. Native UI/modal claims can temporarily supersede them independently of
the temporary action page.

ConsolePort also has an optional conditional click override. Its default
interactButton is `none`; its default interactCondition begins `[vehicleui] nil`
and otherwise can substitute TURNORACTION depending on target state. Read-only
search of current persisted ConsolePort settings found no explicit override of
those two settings. This is a source-audited alternative path, not proof it was
enabled during the quest. Persisted data is not a live engine snapshot.

## Verification and limits

All nine official stable Retail dependency identities were freshly checked this
session, including official CurseForge latest listings and file pages. All match
the lock; no dependency updates/downloads are required. See
evidence/dependencies/stable-recheck.json and dependencies/sources.json.

The existing T61 action dispatch harness gives every main face an action-slot
binding, so its all-class coverage alone cannot prove Jump/Interact/right-click
resolution. A scratch-only diagnostic runner extends the native Layers/Manager
fixture with the shipped main commands and removes the synthetic main face
action registrations. It checks effective Jump/Interact/right-click commands
before/during/after UI/combat transitions, across normal, skyriding, vehicle,
possess, override, quest, temporary and unflagged high-page contexts, and after
L2R2 Square press/release. Circle is unbound in the shipped preset.

Runner: scratch/temporary-command-analysis.cjs.
Result: PASSED T41 and T61, including the added main-command probe.
Full result: scratch/test-results/temporary-command-analysis.json.
Retained summary: evidence/test-results/temporary-main-bank-analysis-2026-10-11.json.
This is offline engine binding resolution; it does not simulate Blizzard's
actual interact-target selection, quest object eligibility, hardware, terrain,
or a real quest's third-party/native claims.

## Conclusion

Source does not support a blanket disabling of Base/L2/R2 when L2R2 owns a
temporary bar. A binding-interception defect causing the reported quest failure
is not yet confirmed. Square sends INTERACTTARGET rather than an unconditional
cursor click; a ground object not selected by native interaction can therefore
fail to respond while a mouse click works. That is a possible explanation,
not an established cause for the unnamed quest.

During the affected quest with both triggers released, the user can read:

`/dump GetBindingAction("PAD3"), GetBindingAction("PAD3", true)`

The first value is the saved command, the second its effective engine binding.
INTERACTTARGET in both supports investigating target/object interaction rather
than the bank pager; a different effective value supports investigating the
claim owner. Modifier state is confirmed unmodified; quest identity is unavailable.
A live effective-binding observation during recurrence remains needed to choose
between a claim/routing repair and an interaction/cursor behavior change.
