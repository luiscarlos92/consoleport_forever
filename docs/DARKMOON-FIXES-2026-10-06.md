# Darkmoon feedback and development fixes — October 6, 2026

**Candidate.5 is now installed.** Initial work remained development-only while
the user tested candidate.4 with ConsolePort 3.3.9. The user then closed WoW and
authorized deployment. The scoped installation completed October 6 at 19:34:44
Toronto, replacing only Forever; dependency files and WTF remained unchanged.
StoreSchema 3 and configuration revision 12 are retained.

## Reported problems and fixes

- **Opening Backpack empties the HUD.** Forever's cursor-focus policy explicitly set every main-bank icon's alpha to zero. Remove icons from that suppression; preserve their current texture/alpha while continuing to suppress transient gameplay highlights. This overrides the earlier approved icon-suppression requirement based on the user's actual rendered feedback.
- **Merchant tooltip lacks controller Select/Buy hints.** Audited ConsolePort 3.3.9 Hooks provide bag use/equip/sell/options prompts but no merchant Select/Buy branch. A companion tooltip bridge identifies Blizzard's real MerchantItemTemplate ItemButton, formats prompts with the active device and configured native left/right cursor controls, and adds Select/Buy (Buy Back on the buyback tab). It calls no purchase API. Native extended-cost/high-price confirmation remains authoritative.
- **Ticket-book tooltip still says Right Click to Open.** Native ConsolePort's bag-use branch tests IsUsableItem/IsEquippableItem, missing some loot containers; its instruction-rewrite branch identifies the bag portrait instead of a container item. For a focused, unlocked native container item with hasLoot, replace only Blizzard's container-open instruction with the configured right-click/Open glyph. Add it if absent, preserve native Options and deduplicate rendered prompts. Leave background/comparison/mouse-only/combat-paused/locked/carried-item tooltips alone. Merchant, bank, mail, trade and auction contexts retain their own semantics.
- **Second Circle can leave BetterBags open.** The current Default/ElvUI themes store CloseButton on a decoration child, not the bag root. Resolve the visible native close target afresh; first Circle still cancels a carried item, subsequent Circle delegates to the real close callback. Hidden old theme decorations are excluded.
- **Rinling shows a 9/10 artifact and all icons are empty; Finlay shows Exit and the same empty HUD.** Supplemental controls were registered with ConsolePort's normal interface-window stack. That stack automatically enables its cursor when a registered frame appears, redirecting face/modifier input from gameplay. The screenshots show that cursor on the supplemental control. Keep the native secure exit/overflow surface outside the automatic window stack; explicit mouse access remains, with no new key assignments. Qualify later actions by native override capacity and actual exposed action identity rather than HasAction alone, which can include backing storage outside the override's supported slots. Preserve held owners until release and hide empty parents.

## Extra-action audit

The retained shortcut is SHIFT-PADRSTICK / L2+R3 -> EXTRAACTIONBUTTON1. It is separate from the four-bank temporary-page replacement. Current native ExtraActionBar_Update controls the ExtraAbilityContainer; Forever's side-bar visibility policy does not hide either frame, and the focus-visual module only touches ConsolePort main-bank feedback. Regression checks execute the pinned Blizzard extra-button availability/key lifecycle and the current ConsolePort Layers resolver to verify the chord restores after UI ownership ends. This is offline evidence; real Brewery hammer rendering and controller execution remain untested.

The supplemental surface no longer supports automatic interface-cursor navigation. Native Exit and genuine overflow remain explicitly mouse-accessible. This prevents automatic cursor capture from blocking the approved L2R2 gameplay abilities. No new controller shortcut or global cursor preference is introduced.

A read-only inspection confirmed `ConsolePortForeverTemporaryAccess = true` in the existing saved cursor registry. The new runtime calls native `RemoveInterfaceCursorFrame` for its own frame and updates the cursor stack, so the old registration is cleared when the fix is eventually loaded in-game. No saved file is edited directly.

## User observations on installed candidate.4

The user reports dragonriding, general mounts, world-map zoom, normal combat and NPC dialogue looking okay. Square successfully bought the vendor item and opened the ticket book. Record these as broad successful observations, not complete acceptance of every step in the older 35-card suite. Rinling/Finlay temporary-mode tests failed because buttons disappeared and supplemental controls captured focus.

## Verification and handoff

All **35 runtime/source suites** and **24 tooling tests** passed. The tests cover icon visibility through cursor focus/rebuilds; decorated BetterBags close routing; native merchant Select/Buy/currency-confirmation behavior; container hint deduplication, remapping and context guards; native persisted cursor-registration cleanup; ghost overflow bounds and held releases; native extra-action visibility/availability in combat; and restoration of L2+R3 through the actual ConsolePort Layers resolver after UI closes. Lua 5.1 syntax is checked separately from Fengari's Lua 5.3 semantics.

Exact receipts: `evidence/test-results/darkmoon-candidate5-runtime.json` and `evidence/test-results/darkmoon-candidate5-tooling.json`. Every tested product/tooling hash was compared to the final working source before retaining these receipts. Their commit field identifies the pre-change base; the product hashes identify the tested candidate.5. The repository retains 34 exact ConsolePort contract files, pinned native merchant/extra-action sources, and current BetterBags theme sources.

Candidate.5 was deployed after explicit authorization. All 44 installed Forever
files match the verified payload, and an independent readback confirms all
3,693 vendor files, 296 WTF files and 42 links unchanged. Exact deployment
evidence is `evidence/delivery/live-install-candidate5.json`. Focused Retail
retesting remains pending; the user can reopen WoW to load the corrections.

Retest now: open Bags and inspect HUD; vendor Select/Buy hints; ticket-book Square/Open hint; carried-item Circle then close; Rinling shooting; Finlay actions and Exit; Brewery hammer L2+R3. Keep existing successful broad scenarios as a baseline.
