# Focused reward Pawn annotation repair

Status: maintained
Reviewed: 2026-10-17
Evidence: [user observation](../../evidence/pawn-immersion/2026-10-17/user-observation.json),
[old-defect reproduction](../../evidence/pawn-immersion/2026-10-17/old-defect.json),
[native input pins](../../evidence/pawn-immersion/2026-10-17/tooltip-repair-inputs.json).

The user confirms candidate.42's summary arrows on Consequences of Our Duty.
Ordinary hover shows Pawn Protection upgrade notes of +10% and +17%, while the
focused inspector lacks both notes. Holding L2 displays Pawn's equipped-item
notes but still omits the selected reward note. These are separate observations;
the initial offline results did not establish the missing focused Retail case.

## Demonstrated source defect and proof limit

The bridge required `tooltip:GetItem()` to echo the exact `GetQuestItemLink`
string. A different non-nil string aborted annotation without scheduling work;
a nil string postponed annotation even when Pawn already had the full item data.
The previous model simply returned the same stored link for both APIs.

Native `GameTooltipDataMixin:GetItem` delegates to `TooltipUtil.GetDisplayedItem`.
That function reads primary tooltip data and returns its GUID-derived link or
`hyperlink`; it does not promise a decorated quest-link round trip. Pawn's
`PawnGetItemLinkFromTooltip` explicitly accepts a supplied full link for its
SetHyperlink compatibility entry point. Immersion's real ShowItems sets the
tooltip Button's item/inspector/pool references before SetItemTooltip populates
the selected quest reward.

The new regression executes those native getter Lua bodies with modeled C
primary-data inputs. With a decorated quest link and bare primary hyperlink,
candidate.42 fails `decorated quest link suppressed focused Pawn note`. A second
case supplies no getter hyperlink despite cached Pawn data. This proves the
unsupported dependency and its failure paths; the exact getter values and
engine timing in the user's screenshots remain unobserved. Layout inspection
did not establish a separate visibility-timing defect.

## Candidate.43 repair and scope

The existing native SetItemTooltip posthook supplies the current full quest link
to Pawn. Active named pool membership, current quest/generation, accepted state
and Immersion's own Button item/inspector/pool references authorize annotation.
The bridge no longer asks the getter to authorize that already identified
population. A real Pawn-data miss still uses the existing bounded retry.
Retained-inspector ownership uses those same native references. Full bonus links
remain the identity for scoring and stale asynchronous work; no item-ID shortcut,
percentage, scale, localized text or scoring rule is introduced.

New controls restore each getter dependency or remove the native reference guard.
Both link representations retain notes across L2 press/release; pooled reuse,
secret quest links, two-choice refresh, padding and previous controls remain.
Summary arrow logic, native population, reward selection, comparison and input
are retained. Schema3/revision20 remain; there is no new preference or migration.

The session's required freshness check discovered BetterBags v0.5.17. It is
retrieved separately with full closure/notices and new versioned contracts; the
old captures remain immutable. Native physical item construction/input is
tested for .14, .16 and .17. Its new cached Sonata decoration and post-draw
visibility are explicit UI model boundaries, not theme-rendering proof. Pawn
provider resolution is exercised against installed .14 and prepared .17; the
original isolated .16 experiment remains. Dependencies are excluded from this
Forever-only repair delivery.

## Retail boundary

After the user reloads, reopen the same focused reward inspector, inspect both
choices, and hold/release L2. Match the exact Pawn note against ordinary hover.
Only the user can confirm that this repair resolves the reported game case.
Offline results do not certify native rendering, hardware timing, taint,
persistence or measured CPU. Broader arrow cases also remain unaccepted.
