# Circle migration blocked by macro resource comparison

Status: maintained
Reviewed: 2026-10-12
Evidence: [saved observations](../../evidence/circle/candidate33-resource-pending-2026-10-12.json),
[adapter and observer](../../addon/ConsolePort_Forever/Circle.lua),
[regressions](../../tests/harness/circle_native_binding.lua).

## Established state and remaining uncertainty

The user reports candidate.33 still closes menus without interrupting casts or
showing an error. Read-only saved evidence records accepted revision19, but the
Base binding remains `CLICK ConsolePortForeverCircleCancel:LeftButton`. Both the
pending change and feature diagnosis report a changed Circle macro. The legacy
helper therefore has its macro action disabled. The proposed direct native MACRO
route was not active in this saved session; this report cannot reject that route.

The account macro cache contains exactly the four intended commands, with CRLF
file records and a final line delimiter. The managed resource records the same
commands with LF and no final newline. The API-returned body was not logged in
candidate.33, so the specific in-memory difference is unknown. Native cache
formatting is a concrete candidate, not an established engine diagnosis. Logs
cover a seven-second session before the later casting test; saved files are not
a live engine snapshot.

The [MySlot author's macro comparison](https://github.com/tg123/myslot/blob/42b9e4de0a95e471c5b7b6fab8a6b59af58f0e07/Myslot.lua#L1168)
normalizes carriage returns and outer whitespace before matching GetMacroInfo
bodies. This provides primary-source precedent for formatting-aware comparisons,
not proof of this client's exact API bytes. Forever applies a narrower rule.

## Candidate.34/revision20

Normalize CRLF into LF and remove terminal LF blank lines only for the exact
four-command Circle body. Return the canonical owned value to the transaction
adapter so a native round trip compares equal. Do not edit the stored macro,
change commands, trim spaces or accept additions/reordering. Actual edits,
duplicates, character-bank collisions and unreadable values still block reuse.

Revision20 restores automatic review for the accepted revision19 record. Owned
legacy binding migration still requires Use proposed and Apply. No automatic
binding rewrite, macro restoration, native Escape, UI takeover or CVar change
is introduced. Macro bytes and other configuration remain native/user-owned.

The automatic log now records body length, CRLF pair count, terminal newline
count and whether the commands match; it does not copy arbitrary macro text.
These values describe the most recent resource refresh. Secret/unavailable
resources produce an unreadable flag. Existing cast/native call observations
and four-session/80-row bounds remain, with normal reload/logout persistence.

T71 adds equivalent-body reuse/readback cases, byte-preservation checks, real
edit rejection, secret resource logging and automatic format persistence. Its
negative control restores strict byte comparison and must reject the formatting
cases. T70 reproduces an accepted revision19 legacy binding with a final LF,
then exercises actual startup review and native binding Apply without a macro
write. Native C API formatting, dispatch, taint and hardware remain modeled;
offline success does not certify interruption in Retail.

The complete frozen-source gate passed 72 runtime checks and 66 tooling tests,
with current inventories of 62 product and 130 tooling/test files. T68 retains
328 assertions; T71 passes 94, including the format-only log refresh case.
[Runtime report](../../evidence/test-results/candidate34-circle-format-runtime.json),
[tooling report](../../evidence/test-results/candidate34-circle-format-tooling.json)
and [qualification](../../evidence/test-results/candidate34-circle-format-qualification.json)
retain exact source hashes and proof limits.

## Documentation impact

Current status, known issues, checklist and changelog distinguish installed
candidate.33 from this repair and retain the reported lack of interruption.
Controller/architecture/testing contracts explain formatting-aware resource
identity and review. Original Forever behavior and its detailed UI reference are
unchanged: combined cancellation remains an approximation of first-success
behavior, and broader implementation priorities are outside this repair.
