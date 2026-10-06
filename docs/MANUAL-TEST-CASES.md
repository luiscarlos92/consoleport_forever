# Retail tests and results — installed candidate.4, revision 12

October 6 live feedback: mounts/skyriding, normal combat, map zoom and NPC dialogue look okay; Square buys vendor items and opens containers. Backpack hides all action icons; merchant/controller Open hints need improvement; Rinling and Finlay show supplemental artifacts and empty banks. Candidate.5 fixes are being prepared **without deployment** while the user keeps WoW open. See [current feedback/fixes](DARKMOON-FIXES-2026-10-06.md). These broad observations do not certify every old test-card step.

Latest read-only audit: [third WTF report](WTF-AUDIT-2026-10-04-THIRD.md). All 296 files/42 links are intact, 257 Lua/fallback files parse, 52 owned-field checks match and the new runtime log has no entries. Your basic skyriding retest is recorded as successful; the full action/held/combat test is still separate. Test 35 addresses the remaining BagsBar parent/visibility question.

Start out of combat on the current Paladin, with unchanged addon versions and your usual controller. Use a training dummy for damaging actions. Before tests that deliberately alter a binding, ring, frame or setting, note its original value and restore it afterward. Do not reload halfway through a held-input test; normal logout at the end of each batch gives the next read-only audit a complete save.

Use **PASS** only after every applicable step and expected result agrees. Use **PARTIAL** for only some completed steps, **FAIL** for an observed mismatch, and **UNAVAILABLE** when a required quest/vehicle/class/widget does not exist. An offline-verified diagnostic means setup/source checks, not a hardware pass. If a test fails, record its ID, exact step, expected versus actual behavior, class/spec and `/cpf diagnose`; stop that case and continue independent cases. Record the result and notes directly beneath each case in this document. For a failure, include the step letter and expected versus actual behavior.

Installed code source: `c004591fb1372322f33f9bf603a8546e1d039c8e`. Each case below includes its steps, expected result and current recorded outcome.

## Agent execution with an emulated controller

**Controller requirement: PS5 / DualSense, matching the user's controller.** Earlier Xbox OS qualification and preliminary PS4 observations are excluded from PS5 acceptance. The PS4 device was removed when the user corrected the controller requirement. No PS5 case has passed yet.

Preliminary PS4 observations on 2026-10-04: R2+Create opened Character, Circle closed it and restored gameplay icons; L2+Create opened BetterBags; D-pad Down moved its focus. These establish that actual emulated HID reports can reach Retail, but do not certify DualSense behavior or any complete test card. Bags contained a Hearthstone and no observed stack suitable for case 22. The native bag/micro strip appeared hidden in the observed ordinary-play screenshots; Edit Mode/reload restoration remains untested.

For genuine PS5 USB emulation, the user approved the signed USB/IP 0.9.7.7 driver and VIIPER v0.1.9-rc4.6.6 backend. Official release hashes and the driver installer's Authenticode signature were checked. The user completed the administrator setup wizard; its completion screen requires a Windows restart. `C:/Program Files/USBip/usbip.exe` reports version 0.9.7.7. An earlier backend start correctly refused the absent prerequisite. No PS5 device was created; resume after restart. Packet contract checks for `tools/dualsense_live_client.py` passed offline, including trigger chords, axes, inactive touches and an independently calculated CRC. Preparation evidence is `evidence/test-results/dualsense-preparation.json`.

After driver installation, confirm that Retail recognizes **DualSense/PS5**, check the actual PAD controls and leave the saved profile intact. Use actual virtual-controller reports for chords, axes, holds and release transitions; screenshots and `/cpf proof`/`/cpf diagnose` provide observations. Mouse clicks or direct Lua callback execution do not count as controller-input passes. Attempt every applicable case and record observations directly below. USB emulation tests game input/profile behavior; the physical controller's Bluetooth transport, factory sensors and physical feedback remain hardware-specific checks.

The isolated test server must bind USB/IP and its management API to loopback only, use the repository scratch config/key paths and register no startup service. The live client requires observed WoW foreground, sends bounded holds, releases on focus loss or a 10-second watchdog, and removes only its newly created bus. It edits no live WTF. Disconnect and stop the client/server when the batch ends.

## Current controls, from the saved bindings

Cross = PAD1; Circle = PAD2; Square = PAD3; Triangle = PAD4. L2 supplies Shift; R2 supplies Ctrl. L3/R3 are stick clicks. The hardware control named `PADSYSTEM` opens map, with L2+PADSYSTEM zoom in and R2+PADSYSTEM zoom out. `PADFORWARD` opens the ConsolePort menu; L2+PADFORWARD opens utility, R2+PADFORWARD opens your existing Auras/manual class ring. Both-trigger PADFORWARD remains unbound while the new pet gesture is gated.

L2+Back (`SHIFT-PADBACK`) opens Bags; R2+Back opens Character; both triggers+Back opens the spellbook. Your saved Social-button combinations provide the same three window shortcuts if that is the physical control exposed by your pad. Identify these named controls once in ConsolePort Bindings if the controller's printed labels differ. **Circle as contextual Back is distinct from the hardware PADBACK button.** Follow native item prompts if the configured face controls differ.

## Run order

1. Everyday UI: **01 → 35 → 34 → 18 → 19 → 20 → 21 → 22 → 23 → 25 → 26 → 27 → 16 → 28 → 02**. This is the first batch to report.
2. Actions and transitions: **03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 24 → 33**. Mark unavailable vehicle/quest/overflow cases honestly.
3. Persistence and integrations: **12 → 14 → 15 → 17 → 29 → 30**. Other classes/characters require their own normal login/review.
4. Deliberate edits/recovery, last: **13 → 31 → 32**. Runtime restore is optional and can undo the new mode settings if applied.

## Harmless popup used by case 21

Paste this outside combat. It has no gameplay or saved-setting action. Circle should dismiss it and print `CPF Cancel`. The definition is transient and disappears on reload. Do not use `/logout` to obtain a popup; logout can be immediate in a rested area.

```lua
/run StaticPopupDialogs.CPF_TEST={text="CPF popup test",button1="OK",button2="Cancel",OnCancel=function() print("CPF Cancel") end,timeout=0,whileDead=true,hideOnEscape=true};StaticPopup_Show("CPF_TEST")
```

## Test cards

### 01 — installed version/review

- **A.** Log in after deployment.
- **B.** Run `/cpf status` and verify candidate.3.
- **C.** If mode/ring revision 12 was already accepted, continue without forcing a new review; otherwise review the genuinely pending mode/layout and GUID personal-ring fields, Apply and Reload.

**Verify:** Configuration revision remains 12. Code-only fixes do not repeat accepted reviews. Existing anchors, sizes and actions remain; no old automatic preset replaces your layout. Any genuinely applied review retains its journal.

**Result:** NOT RUN

**Notes / failing step:** —

### 02 — persisted review

- **A.** Run `/cpf status` and `/cpf diagnose` after reload.
- **B.** Reload once more.
- **C.** Log out normally and return to the same character.

**Verify:** No repeated review of the same accepted fields. The old missing keyboard exit route and ring-version errors are absent. The old Edit Mode reload-verification failure clears if you kept the same managed layout. Exact gesture/icon gates may remain pending.

**Result:** NOT RUN

**Notes / failing step:** —

### 03 — ordinary banks

- **A.** Note one assigned action in Base D-pad, L2, R2 and L2R2.
- **B.** Press each corresponding control on an appropriate target.
- **C.** Release both triggers.

**Verify:** Every action matches its displayed icon and your original slot; no new spell is inserted. Base returns to its original controls. Empty buttons stay inert.

**Result:** NOT RUN

**Notes / failing step:** —

### 04 — both mounts

- **A.** Press L2+L3 and note the mount chosen by LM_B1.
- **B.** Dismount.
- **C.** Press R2+L3 and note LM_B2's behavior.
- **D.** Repeat in a place where their existing rules differ, if available.

**Verify:** The two original LiteMount actions/rules remain distinct and usable. Chords are intentionally unchanged. LM_B1 retains its approved icon; an unspecified LM_B2 icon does not make its action fail.

**Result:** NOT RUN

**Notes / failing step:** —

### 05 — skyriding

- **A.** Mount using your normal chord with skyriding selected.
- **B.** Compare Base/L2/R2 against test 03 while grounded, then take off.
- **C.** Hold both triggers and use available flight abilities.
- **D.** Land and dismount.

**Verify:** Only L2R2 receives actual flight-page actions. Base D-pad/L2/R2 retain ordinary actions and remain visible. No separate full replacement bank appears. Flight actions restore to your ordinary bottom actions after the temporary page ends; landing alone need not end an engine page.

**Result:** PARTIAL

**Notes / failing step:** User: skyriding seems okay after candidate.3; full case not yet recorded.

### 06 — steady flight

- **A.** Switch to steady flight through the native game control.
- **B.** Mount and fly.
- **C.** Land, dismount and switch back.

**Verify:** No special-bank takeover merely because you are mounted/flying; replacement occurs only if the engine actually supplies a special action page. Mount rule selection remains LiteMount-owned.

**Result:** NOT RUN

**Notes / failing step:** —

### 07 — visual/skin regression

- **A.** Inspect all banks with triggers released, L2, R2 and both.
- **B.** Use an action with cooldown, then target something out of range.
- **C.** Reload and inspect again.

**Verify:** Exactly the face-button art/masks retain the intended circular appearance; D-pad remains as before. Icons, cooldowns, empty cells, ranges/usability and active/inactive scaling remain coherent. No doubled prompts/masks or reset to square face art. For the Paladin grey-icon symptom record the spell, resources, target, range, spec and displayed/resolved action.

**Result:** NOT RUN

**Notes / failing step:** —

### 08 — quest override

- **A.** Start a quest granting temporary action buttons.
- **B.** Check all four banks; use temporary ability 1 and a later available slot through L2R2.
- **C.** End/cancel that quest state using its native route.

**Verify:** Temporary actions replace only L2R2. Base/L2/R2 remain ordinary and visible. Exit restores bottom-bank contents; no quest ability is copied permanently into a spell slot.

**Result:** NOT RUN

**Notes / failing step:** —

### 09 — vehicle and exit

- **A.** Enter a vehicle with an exit route.
- **B.** Use its L2R2 actions.
- **C.** Use the supplemental Exit control with mouse or interface cursor if you have no keyboard exit binding.

**Verify:** Exit remains reachable even with no VEHICLEEXIT keyboard key. It leaves the vehicle once and restores ordinary routing. Exit is absent when the engine says you cannot exit.

**Result:** NOT RUN

**Notes / failing step:** —

### 10 — overflow

- **A.** Find a genuine vehicle/override/temporary page containing action 9–12, if one is available.
- **B.** Check retained supplemental access at the former extra-page area.
- **C.** Activate an available later action and leave the mode.
- **D.** Mount with only a skyriding bonus page.

**Verify:** Only real temporary overflow is shown; bonus-only skyriding produces no numbered side bar. No new paging/ring/keyboard shortcuts. Controls and their cursor parent disappear outside eligible modes after a held press releases. A real >8 case still needs separate acceptance; if none is available, leave that portion UNAVAILABLE.

**Result:** NOT RUN

**Notes / failing step:** —

### 11 — held transition

- **A.** Hold a primary action/empowered input.
- **B.** During that hold, trigger a feasible temporary-page entry/exit or release/change triggers.
- **C.** Release the original input. Repeat with a supplemental overflow control if available.

**Verify:** The release belongs to the original press. It does not execute a new slot selected by the intervening mode/modifier change, cast twice or leave an action held.

**Result:** NOT RUN

**Notes / failing step:** —

### 12 — forms/stealth

- **A.** On a Druid/Rogue, note the ordinary four-bank actions.
- **B.** Change normal form/stealth.
- **C.** Leave that state; if possible do form → vehicle → form.

**Verify:** Ordinary class bonus states do not replace whole banks. A real vehicle/skyriding page still replaces L2R2 and later restores ordinary mapping. Engine spell overrides/usability and intentionally conditional macros may still change their own icons/effects.

**Result:** NOT RUN

**Notes / failing step:** —

### 13 — Edit Mode

- **A.** Open Blizzard Edit Mode and check the managed layout is selected.
- **B.** Move a harmless frame a small distance and use native Revert.
- **C.** Repeat with Save; close and reload.

**Verify:** Native editor handles work; hidden native strips/side bars give way during editing and return to intended visibility on exit. Revert restores the old position; Save retains your deliberate edit. No taint/block/error or silent switch to another profile. A genuine saved manual change can require later conflict review.

**Result:** NOT RUN

**Notes / failing step:** —

### 14 — shared/personal persistence

- **A.** On character A, change one personal L2/D-pad binding and one manual ring entry through the normal editor.
- **B.** Log out normally; enter B and complete its review.
- **C.** Give B a different personal action and return A → B → A.

**Verify:** A/B retain their own personal cells and manual rings, including migration/review state. The unmodified four face controls remain shared. Neither character receives the other's spell/ring contents just because their disk folders share a template.

**Result:** NOT RUN

**Notes / failing step:** —

### 15 — native spec bars

- **A.** On one character, note its controller arrangement and native action slots.
- **B.** Switch specialization/loadout.
- **C.** Switch back.

**Verify:** Controller commands/manual-ring arrangement remain character-owned. Native spell/action slot contents follow the game's existing spec/loadout behavior. No per-spec companion profile is invented or another character's contents appear.

**Result:** NOT RUN

**Notes / failing step:** —

### 16 — keyboard preservation

- **A.** With UI closed, try your normal jump, movement and a known keyboard action.
- **B.** Open chat and type; close chat.
- **C.** Repeat after reload.

**Verify:** Keyboard mappings/text entry remain usable; controller context keys do not cause hidden gameplay actions while typing. No global mount/vehicle keyboard shortcut was assigned by the hotfix.

**Result:** NOT RUN

**Notes / failing step:** —

### 17 — manual rings

- **A.** Open the utility ring with L2+forward-menu and your existing class ring with R2+forward-menu.
- **B.** Add/reorder one harmless manual entry in the native ring editor.
- **C.** Reload, reopen and then repeat test 14.

**Verify:** Existing native opener/gesture works, entries/order remain, and available native quest/zone entries remain automatic. No surprise activation of the new learned-selector/pet gesture.

**Result:** NOT RUN

**Notes / failing step:** —

### 18 — windows/tabs

- **A.** Use the keyboard or native menu buttons to open Character and Bags together, then acquire interface-cursor focus inside one window. This sets up window cycling without depending on a gameplay opener while another window owns input.
- **B.** Press L2 and R2 separately to cycle between these two windows.
- **C.** Close both windows first. Open the spellbook using L2+R2+Back, focus a native tab, then press L1 and R1 to visit its available tabs.
- **D.** Close all windows and try the same controls in ordinary play.

**Verify:** Window-focus triggers select a real visible window. Shoulders change supported native tabs; absent/disabled tabs stay inert. No gameplay spell fires underneath a focused window. Ordinary controls return after close.

**Result:** NOT RUN

**Notes / failing step:** —

### 19 — scroll/tooltips

- **A.** Open Achievements with keyboard Y and choose a category with enough entries to show a vertical scrollbar. Put interface-cursor focus on its scrollbar thumb or arrow, rather than a list entry. If that widget is not supported, mark this scroll portion UNAVAILABLE and record the window/widget; do not assume every list is supported.
- **B.** Return the right stick to neutral, scroll down/up and release.
- **C.** Close Achievements, open Bags, focus an item with a tooltip and press R3.
- **D.** Close the window and move/look normally.

**Verify:** Scroll starts only after neutral qualification, stays within bounds and stops on release/focus loss. R3 refreshes/shows the focused tooltip when supported. Ordinary camera/movement returns. Unsupported widgets retain native behavior rather than being falsely marked supported.

**Result:** NOT RUN

**Notes / failing step:** —

### 20 — focus visuals

- **A.** Note gameplay icons/highlights with UI closed.
- **B.** Focus Character/Bags using the interface cursor.
- **C.** Open a nested popup and close it; finally close UI.

**Verify:** Action icons remain visible while the approved UI owner holds focus. Transient gameplay highlights are suppressed, then restored. Ring feedback and item/window controls remain visible. No blank HUD or hidden gameplay cast through a focused window. This follows the October 6 correction to the earlier icon-suppression requirement.

**Result:** NOT RUN

**Notes / failing step:** —

### 21 — popups

- **A.** Outside combat, paste the harmless two-button popup command at the top of this suite.
- **B.** Close chat and move the interface cursor onto the popup; press Circle once.
- **C.** Show it again and press Cross once.
- **D.** If a real four-button review appears naturally, check its displayed Cross/Circle/Square/Triangle prompts separately; otherwise mark that portion UNAVAILABLE.

**Verify:** Circle cancels once and prints CPF Cancel. Cross dismisses OK without printing CPF Cancel. Neither press activates gameplay underneath the popup. Native button 1/2/3/4 and extra-button routes are tested only where those controls actually exist.

**Result:** NOT RUN

**Notes / failing step:** —

### 22 — quantity

- **A.** Open Bags with L2+Back.
- **B.** Select a harmless stack containing at least five items and leave one bag slot free; open its native Split Stack command through the item menu or keyboard Shift-left-click.
- **C.** Use D-pad left to reach 1 and keep pressing; then right to reach the stack maximum and keep pressing.
- **D.** Return to 2, confirm with Cross and check the new stack; recombine it.
- **E.** Open Split Stack again and cancel with Circle; try the parent-window trigger controls while the quantity dialog is open.

**Verify:** Quantity never goes below 1 or above the native maximum. Cross splits exactly the selected quantity once. Circle leaves the stack unchanged. The modal retains priority over parent focus/tab controls; ordinary bag input returns on close.

**Result:** NOT RUN

**Notes / failing step:** —

### 23 — bag item actions

- **A.** Open Bags with L2+Back and focus a harmless, unlocked item.
- **B.** Press Triangle to open its native item menu; inspect its choices and cancel.
- **C.** On a non-usable harmless item, press Cross to pick it up.
- **D.** Press Circle once, then a second time.
- **E.** Reopen Bags and, with no merchant/trade/mail open, focus an expendable consumable and press Square once; check its stack count.

**Verify:** Triangle opens the eligible native item menu. Cross acts on the focused item. First Circle clears the carried item while keeping Bags open; second Circle closes Bags. Square performs the native right-click/use once on that item; its stack changes once if consumed. Unsupported, empty or locked nodes stay inert.

**Result:** NOT RUN

**Notes / failing step:** —

### 24 — bags with merchant/bank

- **A.** Visit a vendor or bank and focus a harmless item.
- **B.** Try its native eligible item action; cancel a quantity/context popup rather than buying/selling something valuable.
- **C.** Close/reopen the bag or change focus while a button is held.

**Verify:** Native merchant/bank priority remains. The prior item is not sold/used after its slot/identity changes, and an obsolete release does not activate a new item. Protected repair/equip/sell semantics remain the game's native operations.

**Result:** NOT RUN

**Notes / failing step:** —

### 25 — map pan/zoom

- **A.** Open the map with the Map control (`PADSYSTEM`), or use its normal keyboard opener only to set up the canvas test.
- **B.** Acquire interface-cursor focus on the canvas and release both sticks to neutral.
- **C.** Pan with left stick, release, then zoom in/out with right stick and release.
- **D.** Focus a search/list field; move the sticks, return to the canvas and neutralize again.
- **E.** Close the map and move/look normally.

**Verify:** Pan/zoom obey native map bounds and stop after release. Search/list focus suspends canvas input. Zoom respects the native smooth/full preference. Movement, camera and autorun return with no stuck vector. A keyboard setup does not count as a controller-opener pass.

**Result:** NOT RUN

**Notes / failing step:** —

### 26 — map waypoint/Back

- **A.** On an eligible map, place the controller cursor at a known location and press L3.
- **B.** Focus that actual waypoint pin and press L3 again.
- **C.** Use Circle/Back with the canvas open or maximized, then press again if it minimized first.

**Verify:** Waypoint appears at the cursor's map location and can be removed through the current pin. Native prohibited maps remain prohibited. Back follows native minimize-before-close where applicable; it does not clear a gameplay target underneath the map.

**Result:** NOT RUN

**Notes / failing step:** —

### 27 — quest details

- **A.** Open an eligible quest detail on the map.
- **B.** Use its shown controls and minimize as appropriate.
- **C.** Use Back to leave details, then close map.

**Verify:** Native reward/face routes remain; Back returns through native quest detail/list/map behavior. No accidental waypoint or gameplay action while quest details own input.

**Result:** NOT RUN

**Notes / failing step:** —

### 28 — preserved commands

- **A.** With UI closed, press the Map control (`PADSYSTEM`) to open/close map; test L2+Map for zoom in and R2+Map for zoom out.
- **B.** Press the forward-menu control (`PADFORWARD`) and close its menu.
- **C.** On clear ground press L3 to start autorun and L3 again to stop; press R3 to open/use the native ping route.
- **D.** Use L1 for nearest-friendly and R1 for enemy scan on suitable targets.
- **E.** When an extra-action button is available, press L2+R3 once; reopen/close a normal UI window and repeat the ordinary shortcuts.

**Verify:** Each existing shortcut invokes its saved native command and returns after contextual UI ownership ends. No new command is assigned to an unbound chord. Extra-action access remains separate from whole-bank replacement. Missing extra-action opportunity is UNAVAILABLE, not PASS.

**Result:** NOT RUN

**Notes / failing step:** —

### 29 — DynamicCam

- **A.** Open its native options and note the managed profile selected for this character.
- **B.** Travel between city/interior/open-world and test your existing camera zoom/situations.
- **C.** Reload and revisit.

**Verify:** Original profile still exists; the managed copy retains your previous situations/scripts and camera preferences. No second independent camera/fade controller or surprise default reset. Manual managed edits remain after reload.

**Result:** NOT RUN

**Notes / failing step:** —

### 30 — Immersion/ExtraFade

- **A.** Speak to a quest NPC.
- **B.** Check dialogue positions/scales and fade behavior against your previous setup; finish/cancel dialogue.
- **C.** If appropriate enter/leave combat and view an allowed native cinematic.

**Verify:** Dialogue controls and all retained offsets/settings remain. Fade restoration follows native Immersion/ExtraFade coordination; chat/tracker visibility follows your approved existing settings. No UI remains stuck faded after closing.

**Result:** NOT RUN

**Notes / failing step:** —

### 31 — update/conflicts

- **A.** After the installation is stable, deliberately change one supported managed setting through its normal addon editor.
- **B.** Run `/cpf update`.
- **C.** If a conflict is offered, choose Keep mine and reload.

**Verify:** A newer owned edit is retained/reviewed rather than silently overwritten. Unchanged/default fields are no-ops. Do not force a conflict to appear if there is no newly proposed default; that part remains UNAVAILABLE.

**Result:** NOT RUN

**Notes / failing step:** —

### 32 — runtime restore (last)

- **A.** Finish and record the earlier tests.
- **B.** Run `/cpf status` to identify a chosen runtime journal, then `/cpf restore <id>` and inspect the preview.
- **C.** Cancel first; only Apply if you deliberately intend to undo that reviewed change.

**Verify:** Cancel changes nothing. An applied restore preserves newer conflicting edits, restores only reviewed fields and retains its own journal. Restoring the mode-install journal can disable the new behavior, so run this last and reapply only through a later review. Disk disaster restore is a separate operation and is not part of this controller test.

**Result:** NOT RUN

**Notes / failing step:** —

### 33 — reconnect/focus/combat

- **A.** Open a context, hold a control and disconnect/reconnect the controller or change focus.
- **B.** Neutralize sticks/release buttons and return to ordinary play.
- **C.** Repeat a low-risk temporary-page transition in combat.

**Verify:** No stuck modifiers/actions/vectors, no delayed release cast and no blocked protected mutation/taint. Configuration application waits until out of combat/Edit Mode.

**Result:** NOT RUN

**Notes / failing step:** —

### 34 — empty supplemental owner

- **A.** Mount/dismount with skyriding, then open Character as the only eligible window.
- **B.** Use window-focus triggers and the interface cursor.
- **C.** Close Character and return to ordinary play; log out normally afterward.

**Verify:** No invisible empty supplemental bar becomes a focus destination or leaves gameplay feedback suppressed. The next read-only WTF audit should contain bounded candidate.3 runtime diagnostics; those recorded statuses remain evidence, not a hardware pass certificate.

**Result:** NOT RUN

**Notes / failing step:** —

### 35 — native bag/micro strip ownership

- **A.** Out of combat, close all ordinary windows and inspect the native bag/micro-menu strip and five native side bars; distinguish these from the four ConsolePort banks and BetterBags window.
- **B.** Enter Blizzard Edit Mode through the game menu; check any offered native editing handles, then use Revert/exit without saving a position change.
- **C.** Reinspect ordinary play, reload once and inspect again; run /cpf diagnose.

**Verify:** The approved native strips/side bars stay hidden in ordinary play and return to the intended state after Edit Mode/reload. Any editing handle actually offered by the game remains usable. If no bag-strip handle is offered, mark that edit-access portion UNAVAILABLE. Record whether BagsBar ownership still reports pending. An unwanted visible strip, unusable offered handle or failed restoration is FAIL; the conservative parent warning alone is not proof of a visual failure.

**Result:** NOT RUN

**Notes / failing step:** —

## Known gates — observe baseline only

The following are not implemented pass criteria in this candidate: exact one-success gameplay Circle; right-stick-return ring commit/close-and-continue; active ring-entry cancellation; automatic learned class/aura/new pet selector activation; exact transient 0.5-second loot hold; exact held cinematic skip; missing LM_B2 default icon; unaudited scroll widgets. Preserve and observe existing native controls. Their absence does not become a new regression merely because other tests pass. Do not spend the first batch trying to prove an intentionally inactive feature. Real >8 temporary cases require separate review; retained emergency access is not acceptance of new paging/rings.
