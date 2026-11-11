# WoW Forever installed addon audit

Status: maintained
Reviewed: 2026-11-11
Evidence: [previous selection readback](../../evidence/forever-config/2026-11-05/selection-readback.json),
[Immersion source parity](../../evidence/immersion-extended/2026-11-05/native-source-parity.json),
[Forever compatibility](../COMPATIBILITY.md).

The later [revised plan](FOREVER-IMMERSION-REPAIR-PLAN-2026-11-11.md)
supersedes the upstream-update suggestion and the planned BetterBags
requalification. This audit retains the observed inventory and error evidence.

## Installed inventory

Read on November 11 from `_forever_/Interface/AddOns`. The installed Forever
build is 1.60.1.70888. The 35 folders below include bundled modules. Versions
come from the installed TOCs, using Plater's Camelot TOC for this client.

| Installed folders | Version |
| --- | --- |
| Auctionator | 341 |
| BagPad | 1.4.0 |
| BtWQuests | v2.67.0-forever |
| BtWQuestsClassic | v19.0 |
| DynamicCam | 2.21.6 |
| ForeverConfig_Extended | 0.1.3 |
| ForeverDungeonJournal | 2.0.2 |
| GearQuestForever, GearQuestForever_Languages and the nine GearQuestForever class modules (DRUID, HUNTER, MAGE, PALADIN, PRIEST, ROGUE, SHAMAN, WARLOCK, WARRIOR) | 1.1.3 |
| GlowingBars | 3.0.1 |
| Immersion | 1.4.61 |
| Immersion_ExtraFade | 1.18.2 |
| ImmersionExtended_Forever | 0.1.1 |
| Leatrix_Maps, Leatrix_Plus, Leatrix_Sounds | 1.60.25 |
| LiteMount | 12.1.5-2 |
| Masque | 12.1.8 |
| Pawn | 2.14.1 |
| Plater | Plater-v663-Forever |
| SilverDragon, SilverDragon_History, SilverDragon_Overlay, SilverDragon_RangeExtender | v2026.41 |
| Sparkles_Forever | 0.4.0-beta |
| WhatsTraining | 11.4.3 |

Compared with the November 5 selection-install snapshot, 18 folders were added
and 30 were removed. The additions are BagPad, GearQuestForever and its ten
modules, GlowingBars, SilverDragon and its three modules, and WhatsTraining.
BetterBags, BetterBags_Forever and the 28 Polestar folders are absent. Among
retained third-party folders, the file hashes changed in DynamicCam,
ForeverDungeonJournal and Sparkles_Forever. Both local extensions have six
installed files each, byte-identical to their checkout copies. Neither ConsolePort
nor ConsolePort_Forever is present in this client's AddOns.

The newest saved addon list enables both local extensions and BagPad. It also
retains Spoken entries for folders absent from the current AddOns directory.
SilverDragon_RangeExtender is on disk with a game-type restriction of
`standard, mists`. BtWQuestsClassic and GearQuestForever's modules declare
load-on-demand. Current in-game load state is unverified.

## Immersion Extended

The installed TOC requires Immersion and optionally orders Pawn ahead of the
extension. Reward refresh follows Immersion's `UpdateItems` and native
`QUEST_ITEM_UPDATE` path, the client's item-data/equipment/spec events, and
Pawn invalidation. Pawn supplies the scoring and preference. The extension has
no BetterBags or BagPad code, registration or lookup. Its `PawnResetBags`
post-hook observes a Pawn-owned function that can also invoke registered bag
providers. If a provider aborts that function, the post-hook cannot be relied on
as the sole refresh path. Preserve independent quest/item-data refreshes and
use Pawn's own option callbacks for option changes.

**Reproduced offline.** Pawn's native Quest Upgrade Advisor checkbox updates
`PawnCommon.ShowQuestUpgradeAdvisor` without calling either reset hook.
Executing that exact installed handler in the Immersion harness left an arrow
visible on an already-open quest after the setting was turned off. A simple
callback routed through the existing open-only invalidation hid the arrow but
could not restore it on re-enable. An in-memory probe post-hooked the checkbox's
actual frame-script slot and deferred a generation-checked refresh. Turning
off and on worked in both directions, and closing the dialog cancelled the
refresh. A code change should keep that refresh coalesced and preserve the
native checkbox, Pawn verdict and quest ownership. This is a candidate repair
for a specific transition. The reported Immersion symptom has no matching
runtime stack or exact quest context yet.

## Forever Config Extended

BetterBags-specific code lives here. Both the bag bridge and native navigation
require a ready BetterBags owner and stay dormant with the current folder set.
The last saved extension snapshot agrees. BagPad
extends the native gamepad bags and owns its own input behavior. Requalify the
existing BetterBags bridge against the version actually installed if it returns,
including item navigation, Circle and native action blocking.
[BagPad 1.4.0](https://www.curseforge.com/wow/addons/bagpad-forever/files/9522659).

The diagnostic list in `Core.lua` is a fixed name list. It still queries
Polestar and the absent BetterBags modules, while missing BagPad and several
current addons. Replace that list in a future revision with enumeration of the
client's addon registry and a load-state read per registered addon. Keep
provider-specific diagnostics tied to the provider. A registry row can report
client discovery and load state, while a folder inventory can include
ineligible modules and pending discoveries.

The last saved snapshot records Plater on Default with the intended
`1.428571452899855` multiplier, and DynamicCam 2.21.6 enabled and evaluated
with zero recorded situation errors. Running the existing DynamicCam model
with the installed 2.21.6 startup, evaluator, defaults and AceDB sources passed
20 supported contexts and seven modeled transitions. There is no demonstrated
Plater migration or DynamicCam integration change to make.

## Disable-addons warning

The retained Forever `Logs/General.log` through November 9 contains 62 Lua
error records. Of these, 60 report `Blizzard_MapCanvas.lua:414` rejecting the
table given to `tDeleteItem`. Twenty of the map stacks include BtWQuests
`LibMapPinHandler.lua:63`; 40 contain only native frames. Two further errors
are BtWQuests quest-link tooltips calling a nil quest-log lookup in
`BtWQuestsTemplates.lua:1788`. The retained stacks name BtWQuests and the
native UI. The exact warning text, triggering action and any
blocked-action attribution from the reported warning are unavailable.

The published Forever BtWQuests v2.70.0 archive passes ZIP integrity and
contains BtWQuestsClassic v19.2. Its tooltip source selects the quest-log
function by API availability. Its
`LibMapPinHandler.lua` is byte-identical to the installed copy, although
other map code has changed. The updated pair is the first targeted test for
the two logged paths. Open the world map via the gamepad, change zones or zoom
levels on the map, and reopen an active-quest link. Check for fresh error
stacks before attributing or closing the warning.
[Official Forever release](https://www.curseforge.com/wow/addons/btw-quests/files/9547866).

GearQuestForever 1.1.3 also attempts to unregister Blizzard's blocked and
forbidden action listeners in gamepad mode at login. This affects visibility of
protected-action warnings if the calls succeed. Its presence does not identify
the source of the reported popup. A recurrence should be tied to the exact
message, time and action, with the matching log stack if available.

## Verification

T109–T112 passed with the retained fixtures. All seven installed Immersion/Pawn
contract inputs in the source-parity receipt still match the prior installed
hashes. The checkbox probe and the installed DynamicCam substitution were
executed in memory. Frame scripts, game API behavior, rendering and secure
execution remain modeled. This audit changed documentation only.
