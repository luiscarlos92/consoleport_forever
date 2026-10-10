# Candidate.23 native secure ping repair — October 10, 2026

The user reports candidate.22 still blocks R3 ping. The attached screenshot shows
ConsolePort_Forever blocked from an action available only to Blizzard UI. The
user confirms dragonriding is fixed and authorizes patch/deployment with WoW closed.
Candidate.21/22 ping acceptance is rejected; their offline results missed the API
security boundary. The confirmed dragonriding/temporary routing remains unchanged.

## Diagnosis and primary-source research

[Blizzard's generated ping API](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/PingManagerDocumentation.lua)
marks TogglePingListener and SendMacroPing restricted.
[Blizzard's binding](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_PingUI/Bindings.xml)
executes TOGGLEPINGLISTENER with runOnUp=true in the native dispatcher.
Candidate.22 instead claims R3 as CPF_GAMEPAD_PING and calls TogglePingListener
from addon Lua. A hardware press alone does not remove addon taint; pcall only
catches errors. This concrete source defect matches the new protected-action
popup; the screenshot alone does not expose the engine's exact stack/function.

[ConsolePort's native mouse handler](https://raw.githubusercontent.com/seblindfors/ConsolePort/3.3.10/ConsolePort/Controller/Mouse.lua)
changes cursor mode in OnGamePadButtonDown and propagates input. Its
[QMenu ping implementation](https://raw.githubusercontent.com/seblindfors/ConsolePort/master/ConsolePort_World/Controller/Ping.lua)
uses secure macro buttons for /ping. Those explicit macro pings are valid for
QMenu but do not reproduce native listener hold/radial behavior. The restricted
secure-handler function scope does not expose RunBinding, and insecure forwarding
cannot elevate the caller. No privileged API/callback is replaced or wrapped.

## Repair

Remove Forever Bindings.xml and its TOC entry and CPF_GAMEPAD_PING entry point.
Keep all saved native bindings, native Layers arbitration and Blizzard's secure
TOGGLEPINGLISTENER dispatcher. Attach passive down/up hooks to the current native
Mouse frame. Match the effective native chord through CPAPI's current key/binding
helpers; higher priority modal claims and rebound non-ping keys stay untouched.
In camera freelook only, with no free cursor/raid/target-ring/UI owner, prepare
GamePadCursorCentering before the native binding samples the pointer. Up schedules
restoration on the next frame, after native dispatch. Keep tap, hold, cooldown,
radial, eligibility and error ownership in Blizzard. Preserve prior centering and
newer external changes. Repeated down, changed modifiers, rapid repress, disable
and stale queued restore are guarded. No persistent binding/configuration migration;
revision 17 stays. Native Mouse input must be enabled to receive pointer callbacks;
if disabled, native ping bindings remain available without this pointer preparation.

## Validation and limits

T60 uses exact hash-qualified Blizzard binding/listener/manager/API declarations,
ConsolePort Mouse input and native Layers source. Hardware and trusted native
binding authority are separate. The old direct call now produces
ADDON_ACTION_FORBIDDEN even with hardware=true. Mandatory injected insecure call,
missing centering, early restore and missing restore mutations must fail.
Tap/hold, combat, foreign modal, mouse/free/UI/raid/ring modes, keyboard F2,
modifier changes, rebinding, repeated press, rapid repress and disable are covered.
Input script ordering, actual cursor timing and engine restrictions are modeled;
offline tests cannot certify real Retail controller or taint acceptance.

Run the full 62 runtime/source suites and 39 tooling checks before scoped build.
T61's 4,160 temporary routing cases and T62 actual recovery startup stay required.
TemporaryRouting.lua and Ground.lua must remain byte-identical to candidate.22.
All nine stable official Retail dependencies were freshly checked on October 10;
none changed/downloaded/reshipped. Deploy Forever only with closed-WoW guards,
retain backups and independently compare installed files, unselected addons,
WTF and junctions. Do not launch WoW or run controller automation.

Manual case 50 remains pending user input. Case 49 dragonriding has user acceptance;
other temporary families retain the existing automated coverage/pending live checks.

All 62 runtime/source suites and 39 tooling checks now pass for the exact current
product/tooling hashes. Reports: evidence/test-results/candidate23-runtime.json
and candidate23-tooling.json. The final nine-source official recheck remains current.
