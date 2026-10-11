# Pending deployment and cumulative acceptance

Status: candidate.29 installed on October 10, 2026 at 20:15:55 Toronto.
The user's deployment authorization is fulfilled. Only Forever was updated;
verified backups and independent readback retain prior candidate.27/settings.
The tests below remain pending in Retail. Another deployment requires new user
authorization with WoW closed.

## Changes awaiting Retail acceptance

- Native ConsolePort account ring ForeverPings: immediate aimed R3 press ping;
  no tap artwork; hold reveals the real native ring. Native release, stick,
  sticky, cancel and editor behavior. Six ping types; account data seeded once
  without overwriting later edits. Candidate.27 functional code retained as
  disabled backup outside the addon/TOC. See candidate.28 implementation notes.
- Immersion Required Items: deferred native offset recalculation owned by
  Forever, qualified for Immersion 1.4.61. One Forever policy field enabled on
  login for an accepted installation; no configuration revision bump/reinstall,
  Immersion update, ImmersionSetup change or filesystem WTF editing.
- Edit Mode: exact saved managed layout reference (52 systems), active saved
  layout captured per character and owned account layout captured as default.
  Future in-game saves remain authoritative. Existing Party/manual geometry
  retained by installer review; new-copy Party defaults remain available.

## Preserve installed, accepted repairs

- Candidate.27 action recovery stays passive; automatic action-slot restoration
  remains removed and cannot be re-enabled by the old toggle.
- Temporary action pages retain native drag/drop, clear stale direct-action
  caches/latches and avoid needless binding reapplication. Accepted L2+R2 ground
  placement, class actions/rings and HUD stay intact.
- The original quest wipe's exact writer remains unconfirmed. Old Copybara
  backups are stale, and that addon is uninstalled; do not use them for recovery.

## Deployment procedure after authorization

1. Recheck every dependency's official stable Retail release for that session.
   Respect the user's prohibition on updating Immersion. Include only actual
   changed packages, otherwise copy only Forever through the tested scoped
   update builder/installer. Requalify source if dependencies change.
2. Confirm WoW closed, exact tested/pushed source and matching artifact hashes.
   Run the scoped preview/installer, verify backups and installed readback.
3. Verify unselected addons, WTF inventories and junctions unchanged. Never
   directly edit live WTF, prune CurseForge helpers or reship unchanged addons.
4. Record installed version/hash and retain previous package/code/config backups.

## In-game tests after deployment

1. R3 neutral tap and aimed unit/world press: immediate correct ping with no menu.
   Hold: native ring artwork, readable icons and native selection/release/cancel
   behavior. Test all six types, combat/noncombat and account availability on DH.
   Edit/reorder/remove a ping entry and reload: edits persist without reseeding.
2. Open Paladin aura and ordinary utility rings after the ping ring. Confirm
   their context, artwork, bindings and pooled icon texture coordinates remain
   intact. Compare the ping ring appearance against these native rings.
3. Reopen a Required Items turn-in like The Dark Part of the Woods, including
   incomplete/complete progress, multiple items, money/currencies and item updates.
   The text moves up and the full item panel remains above the controller footer.
   Close/switch quests before the correction; no stale dialog movement.
4. Rewards, quest offers and gossip retain their existing position/animation.
   Test scale/base-offset edits, dynamic offset Off, top and nameplate anchors;
   those native preferences remain respected. Check combat/Edit Mode deferral
   and /cpf diagnose's immersionProgress status without a full install prompt.
5. Verify the currently chosen Edit Mode layout and breath/timer bar. Compare
   other newly positioned systems and Party frames. Save another small Edit Mode
   change, close, reload/login: Forever's known default tracks it, without moving
   anything back. Another character's different selection remains different.
6. Smoke-test ordinary bars, dragonriding/skyriding and quest/vehicle/possession
   overrides: rearrange/remove/add actions, transition in/out and reload/login.
   Edits persist and no removed action returns. Confirm L2+R2 temporary access,
   native exit controls, accepted ground placement and personal class rings.

Automated offline passes do not substitute for these hardware/rendering tests.
