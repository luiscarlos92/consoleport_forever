# Native input recovery after unsuccessful candidate.9

The user reports candidate.9 still has no combat ability dispatch. The previous
fix addressed a reproducible native UI claim-retention defect, but did not identify
and fix the user's full live failure. Saved candidate.9 diagnostics have no blocked
entries and still lack a secure engine snapshot at the failed combat press. The
remaining live root cause is therefore unresolved; claiming it fixed is premature.

Within the renewed ten-minute deadline, candidate.10 takes all Forever gameplay
interceptors off the live path. No SecureModes.Install or GroundTargeting.Enable
runs, even though their reviewed policies remain saved. No CPF UI-context binding
claim is enabled. HiddenAccess returns before reading/mutating rings or creating
cursor panels, so native stance and vehicle frames remain visible. The native UI
claim cleanup from candidate.9 is retained without enabling CPF context routes.
The four-bank HUD and accepted binding storage stay; native ConsolePort owns
ability dispatch and ground spells use normal manual targeting. This temporarily
suspends custom cursor/player casts, special mode routing, semantic UI takeover
and the hidden-class/vehicle replacement. It does not erase those settings.

The bootstrap test loads the actual TOC and fails if the recovery flag is absent,
if custom secure-mode/casting installation is called, if UI takeover is enabled,
or if hidden controls access any API. Current native-action/combat tests remain.
All nine dependencies are current; no vendor update or reshipping is selected.
No live WTF write or game launch occurs. Exact source/testing/deployment receipts
will be retained. Actual combat must be confirmed by the user before a dungeon.
