# Combat dispatch regression and candidate.9 hotfix

The user reports visible abilities working out of combat but never activating in
combat, followed by a dungeon deserter penalty. Deployment was explicitly
authorized with WoW closed, within 30 minutes. No live WTF editing is authorized.

## Diagnosis and reproduced failure

Read-only saved diagnostics from candidate.8 report a UIContexts effective-route
readback failure on the affected character. Native ConsolePort Input's protected
_childupdate-combat clears clickbutton, hides the input widget and calls Clear.
It does not relinquish the native Layers NAV claim. The subsequent insecure
Input:Release/ClearOverride asks Layers:ReleaseAll to release that claim, but the
public Layers method returns false during combat lockdown. The claim continues
to outrank gameplay's BASE claim while its target is hidden. This reproduces the
reported visual-buttons-but-no-combat-action symptom. No taint event was captured
in the saved diagnostic entries; source/mock reproduction identifies the claim
failure without asserting that every possible live cause was observed.

The old UI tests checked suppression of stale UI clicks in combat; they did not
follow the engine's effective binding back to gameplay or call native UseAction.
The new T41 case demonstrably fails against the prior implementation on PAD1:
combat retained a hidden UI claim instead of gameplay. Its host uses the exact
pinned native Input, Layers claim resolver, protected combat driver, wrapped click
and native action handler. Gameplay calls are counted only on hardware dispatch.

## Patch and stronger gate

InputBridge qualifies native Layers' restricted ReleaseAll attribute and preserves
the original native combat child snippet. It appends a secure handoff that invokes
Layers:RunAttribute('ReleaseAll', nativeWidgetName) and cancels stale CPF click
markers. Only that Input widget's claims are relinquished; Layers itself resolves
the remaining BASE/MODAL owners. All existing Input widgets are prepared, including
native cursor rows with no CPF context. GetWidget post-hooks prepare future
widgets once, outside combat. The original native hide/clear behavior remains.
Native secure script APIs GetFrameRef/GetName/RunAttribute are pinned and audited.
No addon-created insecure callback attempts protected binding writes in combat.

The regression asserts effective engine targets and actual UseAction calls for
all eight gameplay buttons in all four modifier banks. It also checks a held UI
press across combat, first subsequent gameplay action, native-only UI ownership,
widgets created after setup, idempotence, other owners' MODAL claims and repeated
UI acquisition/combat cycles. The fixture fails before the patch and passes after.
AGENTS.md now requires this dispatch gate for input/ownership changes. Existing
current-source tests continue to cover secure modes, ground targeting, vehicles,
UI/window close, native popup/quantity controls and setup rejection recovery.

Candidate.9 retains StoreSchema 3/configuration revision 14 and all user settings.
DBM, HideClassBars and SharedMedia_Causese remain retired. All nine releases were
freshly checked through official sources and current, so delivery is Forever only.
Offline checks do not substitute for actual Retail hardware acceptance; the user
should verify combat input on a training dummy before entering another dungeon.

All 41 runtime/source suites and 36 tooling tests pass on the final patch.
Exact source reports and the failing-before/passing-after reproducer are retained
in evidence/test-results/candidate9-*.

Installed at 23:58:54 Toronto, about 14 minutes after the first diagnostic read.
Source: `096a24953d7c8ec72fb0d65768ef89af0706d125`. ZIP SHA-256: `a7d5840b95b315e56e5f8298f3b5c19882ccc2821a69813958b30c38377f5e6a`.
Backup: `C:\Users\luisr\WoW-Backups\ConsolePort-Forever\20261008T035825Z-8e82353124f0`. Independent readback proves 50 exact Forever
files, 1,949 unchanged vendor files, 298 unchanged WTF files and 42 unchanged links.
Exact receipt/readback retained under evidence/delivery/candidate9*.
