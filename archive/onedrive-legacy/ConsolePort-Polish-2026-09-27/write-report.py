from pathlib import Path
from datetime import datetime, timezone
import shutil, json, difflib

work=Path(__file__).resolve().parent
project=work.parent
stamp=datetime.now(timezone.utc).isoformat(timespec='seconds')
docs=['ConsolePort-Forever-Implementation-Report.md','ConsolePort-Forever-Configuration-Plan.md','ConsolePort-Circular-Buttons-Handoff.md']
(work/'before-docs').mkdir(exist_ok=True)
for name in docs:
    dest=work/'before-docs'/name
    assert not dest.exists(),'Documentation snapshot already exists'
    shutil.copy2(project/name,dest)

report=project/docs[0]
s=report.read_text(encoding='utf8')
s=s.replace('State: **second offline pass complete; ready for login and runtime verification**','State: **final polish installed and offline validation passed; one consolidated in-game check remains. Automation is PAUSED. See the final section below.**',1)
s=s.replace('| Create/Share | World map |\n| Touchpad/Social | Bags |\n| Options | Game/ConsolePort menu path |','| Left trackpad-side / `PADBACK` | ConsolePort main radial menu in all four modifier states |\n| Right trackpad-side / `PADSYSTEM` | World map in all four modifier states |\n| L2+R2+D-pad Up | LiteMount (`CLICK LM_B1:LeftButton`), static icon 132247 |',1)
s+='''

## Final polish installed — 2026-09-26 evening / 2026-09-27 UTC

All five scoped changes are installed. **This is an offline-validated implementation, not a claimed in-game visual sign-off.** WoW was closed at the initial process check, the backup, and deployment; the deployment script refuses to write while any `Wow*` process exists. No game session was launched, no character was selected, and no gameplay state was changed. Native game UI inspection is unavailable in this session. The single consolidated login check at the end is the remaining acceptance step.

The automation `fix-consoleport-circular-buttons` was changed through the app to **PAUSED**, and its saved configuration confirms that state. Its existing one-occurrence schedule, project, model, and prompt were retained. It will not run again automatically.

### Why the previous circle changes missed the visible slots

The saved approved layout declares four **Group** banks (`Base`, `L2`, `R2`, `L2R2`) containing **32 GroupButton** children. It does not instantiate the Cluster/ClusterButton factory for these slots. The earlier `isForeverFaceButton` tag was set only inside the ClusterButton factory, and `Cluster/Skins.lua` was only installed by that factory's `Button:UpdateSkin`. Consequently neither function could change these visible GroupButtons. Parsing those files proved syntax, not reachability. The currently installed Forever helper also had no face-slot skin code; its remaining functions positioned unit frames and hid the menu bars.

The actual construction path is `CPGroupBar:UpdateButtons` → `GroupButton` factory → `LAB:CreateButton` → `ActionButtonTemplate, SecureActionButtonTemplate` → `Group Button:OnLoad` → `ProxyButton:OnLoad` → `SlotButton:OnLoad` → the ordinary Retail slot skin. That slot skin only installs a name-width update on Retail. The inherited Retail art stays square. LibActionButton's `Update` then restores the AddRow normal atlas for both populated and empty buttons, while Masque's two group enrollment paths can subsequently skin the same buttons.

Source cross-check: the downloaded Blizzard UI source is commit `09b9db7948abc9b9648dedaab51eb0cf3ee67b31`, labeled **12.1.0 (69933)**, matching the local installation's `.build.info`. See the [Retail action-button template](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml). A copy and reference metadata are saved with the validation evidence.

### The new face-slot path and final writers

[Group.lua](<C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/ConsolePort_Bar/Widget/Group/Group.lua:5>) now tags PAD1–PAD4 only when their parent ID is one of the four approved banks. This reaches all **16 face slots**, independently of each bank's fixed modifier. D-pad slots and unrelated groups retain their original code path.

The tag is established before `OnLoad`. `PreventSkinning` sets `MasqueSkinned` to suppress LAB's native square reset; this flag alone is insufficient to stop Masque. Both `UpdateButtons` and `OnMasqueLoaded` now exclude tagged faces from Masque enrollment. After the ordinary ProxyButton initialization installs its default updater, the face skin installs the final `UpdateLocal` function, plus an art-refresh post-hook and size-change hook. The existing circular `RoundBorderHighlight` texture supplies the silver ring. Button dimensions, anchors, secure actions, hotkey glyphs, alpha and scale drivers are unchanged.

| Visible layer | Original writer | Final face-slot writer / behavior |
|---|---|---|
| Populated icon | LAB `Update` and ProxyButton texture provider | LAB still chooses and shows the icon; the face updater changes only its UVs and circular `IconMask`. |
| Empty fill | Template `SlotBackground`, then LAB/Masque visibility/art | A dark masked circular background remains available behind icons and in empty slots. |
| Empty slot rim/art | Template `SlotArt`, native art refresh, Masque | Face updater clears and hides `SlotArt`, removing the second square layer. |
| Normal border | Template atlas, LAB `SetNormalAtlas`, Masque normal skin | Face updater assigns the circular ring after initialization and art refresh. |
| Pushed, hover, checked, attack flash | Template textures; state visibility from LAB/native button | Circular ring textures replace these shapes; their state machinery remains intact. |
| Equipped, new-action and spell highlights | Native template textures, LAB visibility updates | `Border`, `NewActionTexture` and `SpellHighlightTexture` use circular art; obsolete `BorderShadow` texture is cleared. |
| Normal, charge and loss-of-control cooldowns | Retail template plus LAB timing updates | Circular swipe texture and edge, bounded by the circular fill; timing, colors, text and charge swipe settings remain native. |
| Proc overlay | ConsolePort's LibButtonGlow wrapper | Tagged slots dispatch to existing `RoundGlow.ShowOverlayGlow`/`HideOverlayGlow`; the group's alpha callback is retained. |
| Small controller glyph | `ProxyHotkey:OnIconsChanged` | Unchanged. A Square-button glyph may still be square inside/above a circular action slot. |

The obsolete Cluster-only tag and face-style override were removed from `Cluster.lua` and `Cluster/Skins.lua`; their ordinary Cluster skin remains. This eliminates the misleading dead trial rather than treating it as a second active solution. Masque remains installed and continues to own the same D-pad and other eligible buttons.

### Cast/progress frame

Retail's ConsolePort toolbar explicitly skips casting-bar ownership (`not CPAPI.IsRetailVersion`), so its saved `castbar.enabled` setting could not place this bar. The actual Retail global is **PlayerCastingBarFrame**. Blizzard's attachment and Edit Mode functions can restore its parent/anchor and change its look; see the matching-build [player-frame attachment code](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_UnitFrame/Shared/PlayerFrame.lua) and [Edit Mode cast-bar code](https://github.com/Gethe/wow-ui-source/blob/09b9db7948abc9b9648dedaab51eb0cf3ee67b31/Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua).

[ConsolePort_Forever.lua](<C:/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/ConsolePort_Forever/ConsolePort_Forever.lua:30>) now captures the bar's loaded width, height, effective scale, look and strata. It reparents the bar to UIParent and anchors its **BOTTOM to ConsolePortGroupBase TOP, x=0, gap=12**. The top row's slot bounds sit just below the group's top, leaving a small gap. The bar remains independently scaled while its anchor follows the bank's native 94%/106% rescaling.

Login/reload use the existing entering-world refresh. Native attachment, look/parent/scale changes, art positioning, OnShow and Edit Mode restoration schedule a guarded reanchor. Combat defers writes until `PLAYER_REGEN_ENABLED`. The helper uses Edit Mode's base point/scale methods for its own positioning, avoiding writes to saved `systemInfo` and snapped-frame bookkeeping. It preserves the loaded skin rather than calling the native detach operation, which also changes appearance. Existing player/target placement and menu-hiding functions are unchanged. No Edit Mode cache was edited.

### Binding and icon persistence

| Combination | Durable action |
|---|---|
| `PADBACK`, `SHIFT-PADBACK`, `CTRL-PADBACK`, `CTRL-SHIFT-PADBACK` | `CLICK ConsolePortMenuTrigger:LeftButton` |
| `PADSYSTEM`, `SHIFT-PADSYSTEM`, `CTRL-PADSYSTEM`, `CTRL-SHIFT-PADSYSTEM` | `TOGGLEWORLDMAP` |
| `CTRL-SHIFT-PADDUP` | `CLICK LM_B1:LeftButton` |

These are the four configured modifier states; the Alt emulator remains disabled. The mappings are now consistent in the stable **Forever Controller** preset, all **four current character snapshots**, the active saved PS5 generator, the PS5 source generator, the account binding cache, and the shared template's formerly empty character binding cache. Every other binding remains unchanged, including the other central buttons. Historical `.bak`/`.old` files are rollback history and were not rewritten.

The existing account setting `bindingPresetCondition = "[] Forever Controller"`, `useCharacterSettings = false`, and overlap-enabled binding loader remain intact. They apply the stable preset on login, including when the active binding set is character-scoped. All **42 character junctions** still resolve to the shared template. The mount icon is saved as `ConsolePortBindingIcons["CLICK LM_B1:LeftButton"] = 132247`, and the same ID is a default-icon fallback in the core binding source. ID 132247 was verified in the installed LiteMount TOC. No mount rules, dynamic-icon heuristics, or other gameplay actions were changed.

### Immersion

Only `ImmersionSetup.boxoffsetX` and `boxoffsetY` changed: **12.36656450478768 → 0**, **204.111328125 → 150**. Bottom anchoring, scale **1.2**, box/element/title scaling, animation divisor **5**, all ExtraFade choices, and title offsets **446.7689819335938 / -117.6884460449219** remain unchanged.

The native `TalkBox:SetExtraOffset` adds temporary height to the stored base Y only for Bottom anchoring. Reward/objective content supplies `(height + 32) * elementscale`; required-item progress supplies `(height + 48) * elementscale`. Native reset paths restore zero extra offset. No permanent reserved space was added. `Titles:OnUpdateOffset` and the initial title anchor operate separately relative to UIParent CENTER, so their offsets were deliberately retained. No Immersion addon source was edited.

### Validation and limits

- **All eight edited Lua files parse with luaparse 0.3.1 in Lua 5.1 mode.**
- A focused Fengari Lua harness executes the installed ConsolePort local action-button library and ProxyButton code, the actual patched Group factories, the extracted actual LAB `Update` body, the patched helper, and unchanged Immersion movement code. Frame/API mocks replace the game engine; this is not a WoW client simulation.
- Both early and late Masque loading, plus group rebuilds: exactly 16 face slots reach the round path; 16 D-pad slots remain square. Other groups are excluded. All state textures, masks and three cooldown shapes are asserted; proc dispatch points to the existing round-glow functions.
- **48 LAB update cases** cover action/custom/empty content across all 16 face slots, including a later native square-art refresh. The final updater retains the ring and circular empty fill.
- Cast harnesses cover fresh login and reload, native reattachment, Edit Mode look/scale/anchor resets, combat deferral and recovery, and unchanged unit positions. Captured effective size/skin are retained, with no additional Edit Mode bookkeeping writes.
- Native Immersion animation settles at **(0,150)**, rises to **282** for a representative 100-unit reward panel and **298** for required-item progress, then returns to **150**. The base Y stays 150 throughout.
- AST comparisons allow only requested binding/icon edits and exactly two Immersion setting edits. Both caches retain every unrelated line. Deployment hashes match the tested files.
- Preservation audit: **3,784 unchanged paths** (including aliases), **41 unchanged addon folders**, and **42 valid shared character junctions**. Bar geometry/scale/visibility, UI scale, chat, DynamicCam, ExtraFade, Masque settings, addon enablement and Edit Mode caches are unchanged.

**Unverified:** final pixels and ring weight on the television; actual GPU masking/animation; hardware button delivery; Blizzard secure/taint behavior and absence of in-game Lua errors; runtime conflicts; cast-bar gap during real spells/progress; real NPC panel overlap. No offline test can establish those visual/client results. There was one evidence-backed implementation and no sequence of in-game speculative trials.

Validation output: [installed-file tests](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/evidence/validation-live.txt>) and [preservation audit](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/evidence/preservation.json>). The readable [patch](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/changes.patch>) and [test harness](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/harness.lua>) are retained.

### Changed files, rollback, and updates

Ten game files changed: Group.lua; the two obsolete Cluster trial files; ConsolePort_Forever.lua; the PS5 source generator; the core binding-icon source; account ConsolePort and Immersion SavedVariables; and the account/template binding caches. Exact relative paths and original hashes are in the [backup manifest](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Polish-2026-09-27/manifest.json>). Originals are under the sibling `before` directory; documentation originals are under `before-docs`.

To undo this run while WoW is closed:

```powershell
python "C:\\Users\\luisr\\OneDrive\\Documents\\03 Gaming\\World of Warcraft\\ConsolePort-Polish-2026-09-27\\deploy.py" --rollback
```

The rollback script refuses to overwrite files that changed after deployment (including normal post-login SavedVariables rewrites or addon updates). If it refuses, compare the relevant original in `before` and restore only the intended settings/source portions. There is no need to restore the entire WTF directory. The unchanged approved bar-layout file is not part of rollback.

**Addon-update overwrite risk:** updates to ConsolePort/ConsolePort_Bar can replace the Group skin, PS5 generator, icon fallback, and retired Cluster trial files. The separate Forever helper and SavedVariables normally survive an upstream update; a device-version migration can replace a saved generator, while the separate Forever Controller preset should remain. Preserve this patch/evidence and recheck the new factory/template path after an update. Do not blindly copy an old full addon file over a newer version. A changed Retail frame name or anchor API can also require revisiting the helper.

### One consolidated login check

In one session, compare with screenshots 1000102993 and 1000102996:

1. Check all four banks: 16 circular face slots, 16 square D-pad slots; populated and empty appearances; hover/pressed/checked/cooldown/proc states when available. The bank geometry, scaling, unit frames and hidden toolbar should match the approved baseline.
2. Cast or use an ordinary progress action, then `/reload` and open/close Edit Mode: the same-sized bar should remain centered immediately above the base bank. Check for any Lua/blocked-action errors during this session.
3. Test left `PADBACK` for the radial menu and right `PADSYSTEM` for the world map with neither trigger, L2, R2, and both held. Confirm L2+R2+D-pad Up has the LiteMount icon and invokes LiteMount; confirm the same preset on another existing character when convenient.
4. Open simple NPC dialogue and dialogue with rewards/requirements: the talk box should rest centered at the lower position, move upward only as needed, then return. Scale, ExtraFade and the separate title/choice panel should retain the user's choices.

This is the sole remaining consolidated visual/runtime check; the automation is disabled and will not keep retrying.
'''
report.write_text(s,encoding='utf8')

plan=project/docs[1];s=plan.read_text(encoding='utf8')
replacements={
    "| Options/Menu | Large radial menu | Put ConsolePort's menu trigger on this button and curate its rings/quick menu. |":"| Left trackpad-side / PADBACK | Large radial menu | Keep ConsolePort's main menu trigger in all four modifier states. Right trackpad-side / PADSYSTEM opens the world map. |",
    'Keep the Game Menu on Options/Menu instead.':'Keep the main radial menu on PADBACK instead.',
    '| Options/Menu | ConsolePort Menu trigger | Opens the curated radial/menu UI. |':'| Left trackpad-side / PADBACK | ConsolePort Menu trigger | All four configured modifier states. |',
    '| Create/Share/View | Utility ring or map | Controller model and personal preference determine this. |':'| Right trackpad-side / PADSYSTEM | World map | All four configured modifier states. |\n| L2+R2+D-pad Up | LiteMount | CTRL-SHIFT-PADDUP = CLICK LM_B1:LeftButton; static icon 132247. |',
    '- Put the ConsolePort Menu trigger on Options/Menu.':'- Keep the ConsolePort Menu trigger on PADBACK and TOGGLEWORLDMAP on PADSYSTEM in all four configured modifier states.',
    '- configure Options/Menu as the ConsolePort menu trigger;':'- configure PADBACK as the ConsolePort menu trigger and PADSYSTEM as the world map;',
    '- [ ] Options/Menu opens the intended ConsolePort menu rather than only Blizzard\'s Escape menu.':'- [ ] PADBACK opens the ConsolePort main radial menu; PADSYSTEM opens the world map across all four configured modifier states.',
    'Database is preserved and no stick-click is newly assigned to LiteMount. Use its existing action-slot/ring placement.':'Database is preserved. CTRL-SHIFT-PADDUP invokes CLICK LM_B1:LeftButton through the stable Forever Controller preset, with static icon 132247.',
}
for old,new in replacements.items():
    assert old in s,old
    s=s.replace(old,new)
s+='\n\nFinal polish implementation and the single remaining login check are recorded in [the implementation report](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Implementation-Report.md>). Automation `fix-consoleport-circular-buttons` is PAUSED after offline validation.\n'
plan.write_text(s,encoding='utf8')
handoff=project/docs[2]
s=handoff.read_text(encoding='utf8')
s+='\n\n## Disposition — final polish run\n\nImplemented and offline-validated at '+stamp+'. The active slots were GroupButtons; the obsolete Cluster-only trial was removed. All five scoped changes are installed. Automation `fix-consoleport-circular-buttons` is PAUSED. See [the final implementation report](<C:/Users/luisr/OneDrive/Documents/03 Gaming/World of Warcraft/ConsolePort-Forever-Implementation-Report.md>) for the proven results, rollback, update risk, and the one consolidated visual/runtime check. The historical failed-approach list above describes the pre-run state.\n'
handoff.write_text(s,encoding='utf8')

manifest=json.loads((work/'manifest.json').read_text(encoding='utf8'))
patch=[]
for rel in manifest['originals']:
    old=(work/'before'/rel).read_text(encoding='utf8').splitlines(keepends=True)
    new=(work/'staged'/rel).read_text(encoding='utf8').splitlines(keepends=True)
    patch.extend(difflib.unified_diff(old,new,fromfile='before/'+rel,tofile='after/'+rel))
(work/'changes.patch').write_text(''.join(patch),encoding='utf8')
print('Updated implementation report, durable configuration plan and handoff disposition; wrote reviewable patch. UTC '+stamp)
