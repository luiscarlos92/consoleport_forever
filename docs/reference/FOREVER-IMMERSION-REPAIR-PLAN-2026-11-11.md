# Forever Immersion repair and config retirement plan

Status: maintained
Reviewed: 2026-11-11
Evidence: [installed addon audit](FOREVER-ADDON-AUDIT-2026-11-11.md),
[Immersion extension](../IMMERSION-EXTENDED.md),
[previous tooltip repair](PAWN-IMMERSION-TOOLTIP-REPAIR-2026-10-17.md),
[config extension](../FOREVER-CONFIG-EXTENDED.md).

## Scope

Work in the Forever client and deliver changes through our own extensions.
Keep the current addon set enabled. Keep third-party addon files, releases
and settings under their existing ownership. BagPad owns the current bags.
Any future BetterBags integration requires a new design. Any demonstrated
BtWQuests repair belongs in a separate dedicated extension.

## Immersion Extended

1. Preserve the current Required Items positioning repair and its native
   measurement, anchor, scale, combat and Edit Mode guards. Verify the
   Required Items and Choose Your Reward screens independently. Extend the
   positioning code to the reward screen only after reproducing bad geometry
   there. Use the final native measurements and the user's existing anchor.
2. Stabilize the summary arrows. Keep a confirmed arrow during a bounded Pawn
   retry for the same visible quest, reward button and full item link. Clear it
   on an authoritative negative verdict, preference disable, ownership loss,
   close or reuse. Invalidate on equipment/spec or Pawn scale changes so a
   stale positive verdict cannot outlive its comparison context. Coalesce
   item-data events and keep the bounded work and generation checks. Observe
   the native Pawn checkbox script so off/on works with the quest already open.
3. Add Pawn's percentage to Immersion's native inspector item tooltips on
   Forever. Use Immersion's current tooltip, item, inspector and active-pool
   references and pass the full native quest reward link to Pawn's existing
   tooltip formatter. Preserve Pawn's preferences, scales, comparison and
   localization. Reuse the ownership approach from the Retail repair with
   Forever's installed Immersion/Pawn contracts. Annotate once per tooltip
   population and retry unresolved data only while that population is current.
   Keep the integration independent of bag addons and ConsolePort.
4. Reproduce the reported controller tooltip failure at the inspector entry
   point. Verify that the card opens, the selected reward shows the same Pawn
   line as hover, comparison still works, and rapid selection/close/reopen
   cannot leave duplicate or stale notes. If the card itself fails to open,
   trace Immersion's existing input, focus and pool lifecycle before changing
   the open path. Preserve reward selection and existing bindings.

## Forever Config Extended

1. Retire the one-time Plater profile write. Keep the applied scale, later
   manual edits and existing migration receipt. DynamicCam already owns its
   own profile and camera behavior. Keep the existing diagnostic readouts.
2. Permanently remove the active BetterBags bridge from the addon load path.
   Remove its open/close, Circle, navigation, focus registration and pending
   work, along with its load-order dependency and bridge-only status output.
   The current addon remains available for `/foreverconfig` diagnostics.
   A later BetterBags installation, older saved data or a reload must be unable
   to reactivate the retired bridge.

## BtWQuests follow-up

Keep the installed BtWQuests and BtWQuestsClassic pair in place. The earlier
upstream-update suggestion is superseded. Use the exact popup, timestamp and
action and a matching stack to distinguish the map failure, quest-link failure
and protected-action warnings. If the fault can be reproduced and safely
addressed through an owned, capability-checked extension point, plan a
dedicated Forever addon around that point. Avoid global MapCanvas or protected
action overrides and retain the warning for diagnosis. Track the unresolved
warning separately from Immersion acceptance.

## Qualification and delivery

- Reproduce the arrow disappearance using Pawn's actual budget wrapper and
  exercise the actual checkbox script. Keep negative controls for a stale
  positive verdict, tooltip pool reuse, duplicate Pawn lines, delayed item
  data, hidden or replaced dialogs and bad layout timing. Use the installed
  Immersion/Pawn source for the relevant behavior.
- Exercise Forever Config Extended with BetterBags available at startup and
  loaded later. Require zero bridge hooks, focus registrations and bag
  requests. Require zero Plater profile or DynamicCam changes and preserve the
  diagnostic command and saved migration history.
- Run the full current source and tooling checks for the two-addon change.
  Use the existing source freshness and standalone packaging gates. Any
  third-party discovery is evidence for compatibility, with both payloads
  limited to our addon code. Use one package per extension and preview each
  against the explicit Forever root. Keep verified backups and independently
  read back the installed code and preservation of the other addons, WTF and
  links. The user owns reload and controller/rendering acceptance.

Immersion Extended 0.1.2 and Forever Config Extended 0.1.4 implement the source
changes in this plan. No separate reward layout defect has been reproduced.
See the [current status](../IMPLEMENTATION-STATUS.md) for delivery and game
acceptance.
