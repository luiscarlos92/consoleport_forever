# Pawn and Immersion: source investigation and staged plan

Status: maintained
Reviewed: 2026-10-16
Evidence: [source identities and limited saved observation](../../evidence/pawn-immersion/2026-10-16/source-research.json),
[requirements](../REQUIREMENTS.md),
[previous staged workflow](SHARED-UTILITY-RING-2026-10-13.md).

## Request and stopping boundary

The user subsequently approved the isolated experiment. Both BetterBags source
variants pass actual Pawn/Immersion tests with ten rejected defect controls.
[Results and limits](../reference/PAWN-IMMERSION-ISOLATED-EXPERIMENT-2026-10-16.md).
The user then replied “Proceed”, approving candidate.42 Forever integration.
[Runtime ownership and limits](../reference/PAWN-IMMERSION-RUNTIME-2026-10-16.md)
record that stage. Current status owns exact qualification/delivery and Retail
acceptance. The text below retains the initial plan and stage separation.

The October 16 request adds Pawn's bag-style upgrade feedback to three Immersion
reward views. Pawn remains the authority for upgrade decisions, enabled scales,
comparison baseline, percentages, localization and formatting. The screenshots
illustrate the requested surfaces; their item names, Protection scale and 28%
example are not constants or general acceptance criteria.

The initial stage authorized source research and a text plan only. No Lua execution,
prototype, runtime/test/tool edits, dependency refresh, packaging, installation
or game input had occurred then. Plan approval authorized the isolated dry-run stage
below. Present its results and obtain further approval before addon integration.
This explicit staged request overrides standing delivery permission for this
feature. Approval of the plan does not authorize installing an experiment.

| User screenshot / surface | Requested result |
| --- | --- |
| 1: summarized quest rewards | The same green upgrade arrow used on bag item icons, only on rewards Pawn judges upgrades under the relevant bag configuration. No new explanatory text in the summary. |
| 2: Choose your reward detail popup | Pawn's own generated tooltip note on each eligible reward tooltip, including the configured scale/spec and upgrade amount when Pawn would show them in bags. |
| 3: L2 Currently Equipped comparison | Keep that same note on the selected reward tooltip while native equipped-item comparison is open, and after L2 release. Existing equipped-item information remains native. |
| 4 and 5: BetterBags reference | Arrow appearance and Pawn-generated annotation are the reference. Item level, vendor/auction text, appearance collection and native stat-difference text are separate features. |

Do not add reward auto-selection, a best-reward algorithm, custom stat weights,
independent percentage math or new controller mappings. Retain the existing
Required Items correction and reward-context/vendor markers. No new settings UI
or persistence model is justified at this research stage.

## What the sources establish

Installed source was inspected read-only: Pawn **2.13.17**, BetterBags
**v0.5.14**, Immersion **1.4.61**. Official GitHub latest stable metadata
observed Pawn 2.13.17, BetterBags v0.5.16 and Immersion 1.4.61. Selected installed
Pawn files match the official release exactly; selected BetterBags/Immersion
files match their installed release tags after line-ending normalization.
This establishes selected-file provenance, not complete package qualification.
BetterBags v0.5.16 is already prepared separately; this plan neither installs it
nor treats its bytes as the running bag implementation.

### Bag arrow and tooltip have different owners

BetterBags `integrations/pawn.lua:Register` registers an upgrade provider that
passes the full item link to
`PawnShouldItemLinkHaveUpgradeArrowUnbudgeted(link, true)`. The second argument
checks player level. `data/items.lua:GetActiveUpgradeProvider` respects an explicit
provider choice and otherwise prefers Pawn when registered. `ResolveUpgrade`
delegates to that provider; `frames/item.lua:UpdateUpgrade` toggles the themed
button's `UpgradeIcon`. The normal themed button inherits
`ContainerFrameItemButtonTemplate`. Pawn determines the boolean; BetterBags/native
item-button artwork supplies the bag overlay. Do not assume Pawn's inline tooltip
arrow texture is the same artwork as the bag overlay.

Pawn's author recommends the public budgeted
`PawnShouldItemLinkHaveUpgradeArrow(link, true)` API. It wraps the same evaluator
and returns true, false or nil; nil includes unavailable data or an exhausted
time budget. The unbudgeted entry point is explicitly marked internal. Compare
the public result with the installed BetterBags provider in the dry run before
selecting it. Pending must not become a cached non-upgrade. See
[Pawn bag integration guidance](https://github.com/VgerMods/Pawn/blob/Pawn-2.13.17/PawnBags.lua)
and [BetterBags' installed-version integration](https://github.com/Cidan/BetterBags/blob/v0.5.14/integrations/pawn.lua).

The bag tooltip annotation comes from Pawn itself. `PawnUpdateTooltip` obtains
item data, invokes Pawn's upgrade calculation and formatting, and honors its
display options. Its configured scale/spec labels, colors, icons and rounding
must be reused rather than reconstructed from `PawnIsItemAnUpgrade` results.
Pawn's own equipment/history and scale rules decide the comparison baseline;
do not substitute a calculation against only the item currently equipped.
[Pawn implementation](https://github.com/VgerMods/Pawn/blob/Pawn-2.13.17/Pawn.lua).

The limited disk observation shows upgrade tooltips, upgrade-only values, spec
icons and colored borders enabled; item-level upgrades and Pawn tooltip-button
icons disabled; one decimal digit. BetterBags' saved file has neither an explicit
upgrade-provider field nor its user-set marker. Its source therefore predicts
Pawn precedence when available. These are persisted observations, not proof of
the live profile/spec or screenshot-time state. Runtime must read the actual
owners, never bake these observed settings into Forever. In particular,
BetterBags' Pawn provider does not itself test Pawn's bag/quest-advisor toggles;
do not silently replace bag parity with different quest-advisor policy.

### Immersion's inspector uses separate pooled tooltips

Immersion `Components/Elements.lua:ShowRewards` fills reusable summary buttons
using quest item type/index and `GetQuestItemLink`. `Logic/Frame.lua:UpdateItems`
collects both reward and Required Items buttons, so it is not by itself a
sufficient scope filter. Only the requested reward area is eligible here.

`Logic/Inspector.lua` acquires named tooltips from a pool. `Utils.lua:Create`
names them `ImmersionGameTooltip1`, `ImmersionGameTooltip2`, etc.
`Logic/Frame.lua:SetItemTooltip` fills each with `SetQuestItem`, adds any native
reward-context line, sets its icon and shows it. Pawn hooks the ordinary
`GameTooltip:SetQuestItem`; that does not automatically hook these other
instances. This is a concrete source explanation for the missing annotation,
not a live engine diagnosis.

`Logic/Controller.lua:ShowFocusedTooltip` delegates to
`Components/Tooltip.lua:SetFocus`, which calls native
`GameTooltip_ShowCompareItem` on the selected reward tooltip. The selected reward
stays present and other choices fade; `ClearFocus` hides shopping tooltips and
restores the choices. No new L2 handling should be needed. See
[Immersion reward population](https://github.com/seblindfors/Immersion/blob/1.4.61/Logic/Frame.lua)
and [comparison lifecycle](https://github.com/seblindfors/Immersion/blob/1.4.61/Components/Tooltip.lua).

The tooltip template already schedules a deferred size adjustment on show, and
the inspector measures its children. Annotation timing must therefore be tested
with those actual functions, including longer Pawn text and repeated refreshes.
Adding lines after layout without remeasurement can overlap columns; repeated
Show-driven adjustments can also create growth. Neither is proved safe yet.

### Registration helpers are not automatic solutions

`PawnRegisterThirdPartyTooltip` registers border-color overrides; it does not
discover and annotate arbitrary tooltip frames. Its callback handling is global
enough that careless registration could affect unrelated tooltips.
`PawnRegisterThirdPartyBag` enables refresh callbacks but also disables Pawn's
default-bag integration. An Immersion-only bridge must not register as a bag.
Investigate narrow additive observation of Pawn's existing invalidation functions
(`PawnResetTooltips` / `PawnResetBags`) instead, with no replacement of their
bodies. Exact coverage and duplicate callbacks remain dry-run questions.

## Recommended design to qualify

Keep the bridge in Forever with optional, identity-checked Pawn/Immersion
readiness. Keep the existing Required Items policy independent. First qualify
two small presentation paths:

1. After native summary population, resolve each eligible reward's complete
   quest link, ask Pawn for its bag-equivalent verdict and show an owned overlay
   using the verified bag icon artwork. Preserve existing reward markers and
   clear owned artwork on hide, item/type/quest change and button reuse. Reflect
   relevant explicit BetterBags provider settings; do not fall back to an item
   level heuristic if Pawn is unavailable or another provider is selected.
2. At the native reward-tooltip population boundary, invoke Pawn's existing
   updater on that named tooltip and its current full item link. Prefer the
   existing `ImmersionFrame:SetItemTooltip` boundary if experiments establish
   correct ordering. Do not change the tooltip's item setter to a hyperlink
   setter just because Pawn accepts a `SetHyperlink` method argument: Pawn uses
   that argument to resolve the supplied link. Preserve quest context and native
   comparisons. Ensure exactly one Pawn annotation per native population.

Use full links, not bare item IDs, so bonus/scaling variants stay distinct.
Install hooks once per qualified owner. Scope callbacks to current reward frames
and visible inspector entries. Unknown/secret/unready data produce no invented
verdict or explanatory text. Late load and data completion may retry only while
the same reward generation is still eligible.

Reuse Pawn's caches and invalidate Forever's presentation on actual Pawn reset,
equipment/spec/scale changes and reward/data changes. Coalesce equivalent work,
bound pending retries and cancel them on close/reuse; no idle polling or work
over every bag item. On a settings refresh, rebuild an affected tooltip through
its native reward setter before re-annotation if necessary; do not remove old
Pawn lines by parsing their text. Exact callbacks, retry bounds and refresh
ordering are to be chosen from the dry-run evidence.

Pawn is installed but outside the managed dependency lock. Qualify it as an
optional external integration before runtime work; this request does not
authorize packaging or modifying Pawn. Resolve actual load order and bootstrap
eligibility before choosing any necessary TOC OptionalDeps change. Do not attach
this display feature to the suspended custom UI context path. No protected input
or secure dispatch changes are proposed.

## Ordered stages and approval gates

1. **Text review: completed.** Review the three surfaces, source
   findings, design candidates and dry-run cases. No implementation is claimed.
2. **Isolated dry run: subsequently approved and completed.** Read tooling/test
   instructions and freshly inspect all official stable Retail dependencies
   before executable work. Capture exact source/provenance for Pawn, installed
   and prepared BetterBags, Immersion and relevant native item/tooltip contracts
   outside immutable reference/fixtures. Execute actual selected Pawn and
   Immersion functions in an isolated harness, with explicit C/UI substitutes.
   Build only the smallest standalone candidate bridge; do not add it to addon
   source, TOC, shipping bootstrap or package payload. No game/WTF writes/input.
3. **Review dry-run results: completed; further approval received.** Present passed cases, failed
   negative controls, proposed hook order/artwork and unresolved engine limits.
   If the source experiment cannot establish a route, refine it or explain the
   needed user-owned observation. A mock that simply asserts the desired Pawn
   answer or assumes correct tooltip layout is insufficient. The user reviewed the results and replied “Proceed”, authorizing addon
   integration.
4. **Forever integration and qualification: approved, candidate.42.**
   Recheck freshness, qualify affected contracts and implement only the proven
   paths. Preserve addon locations/loading contracts, Required Items, native
   controller ownership and manual settings. Run relevant native/visual/input/
   performance regressions, `./tools/Test-All.ps1` and documentation validation
   with complete current inventories. Reassess compatibility, architecture,
   testing and release documentation against the actual change.
5. **Later scoped delivery and user-owned Retail acceptance.** Establish the
   permitted delivery scope in that later stage, then follow tested-source
   commit/push, scoped build/preview/install and independent readback. Compare
   the same item and Pawn configuration in bags and all three Immersion views;
   check L2 press/hold/release, selecting the other choice, close/reopen and a
   second quest. Include a non-upgrade and no-stat/currency reward. User testing
   establishes rendered appearance and controller behavior; offline results do
   not certify Retail taint, timing, persistence, layout or CPU.

## Dry-run acceptance and negative controls

| Case | Required proof |
| --- | --- |
| Verdict parity | Compare actual Pawn public API and the installed BetterBags provider on the same full links/settings: upgrade, non-upgrade, equal/best item, too-high level, unsuitable armor/weapon, rings/trinkets, multiple/custom scales and item-level option changes. Model unavailable C data explicitly. |
| Exact tooltip text | Compare Pawn-added lines, colors, icons, percentages/rounding and option-dependent suppression against the same item passed through the bag-tooltip Pawn route. Test localized/custom names and right-aligned values. No frozen Protection/28% expected string. |
| Three views | Summary contains only the arrow addition; detail tooltips obtain Pawn output; selected reward retains it across native comparison focus/unfocus without duplication. Equipped shopping tooltips keep their existing Pawn/native behavior. |
| Pending data | Nil from the public budget or missing item info remains pending. Same-generation resolution updates once; failed requests, close, new quest/item and pool reuse cannot publish stale results. Settled/closed UI has zero bridge retry work. |
| Lifecycle and options | Both addon load orders, initialized/uninitialized Pawn, reopen, reused tooltip/button, changed spec/equipment/scale/options, explicit provider None/other provider and unsupported/missing addon contract. No default-bag registration side effect. |
| Composition and preservation | Actual reward setter, pool, context lines, inspector sizing and compare lifecycle execute. Verify structural sizing/work bounds offline; reserve pixels for Retail. Required Items, currencies, money/vendor marker, other tooltips, controls and settings retain their owners. |
| Negative controls | Reject hardcoded scale/percentage, item-level-only verdict, nil cached as false, annotation on currency/Required Items, stale reused widget, duplicate lines/size growth on re-show, refresh storms and loss of selected reward text on L2. |

Work-count receipts must distinguish native work from added bridge work and
compare equivalent sequences before/after. Harness timing is not Retail profiling.

## Documentation impact and stage result

The initial text-only pass recorded R16, navigation and controller/state/gated
intent, using the documentation-only freshness exemption. The approved experiment
then freshly checked all managed stable dependencies and added isolated sources,
prototype/harness, T103/T104, capture guards, CI reconstruction and result docs.
Installed status, current runtime architecture, dependency lock, compatibility
claims and release receipts remain unchanged because no addon or package changed.

The initial stage produced a researched plan. The subsequently approved isolated
experiment establishes the source behavior described in its results; it does
not mean the bridge is integrated, installed or accepted in Retail.


## Subsequent integration approval

The user’s “Proceed” advances the work to candidate.42 Forever integration.
[Runtime ownership and validation](../reference/PAWN-IMMERSION-RUNTIME-2026-10-16.md)
record actual startup, frame and asynchronous composition contracts. The isolated
stage receipts above remain historical evidence. Current status owns exact
qualification, preparation/installation and acceptance; offline source execution
never substitutes for user-owned Retail observations.
