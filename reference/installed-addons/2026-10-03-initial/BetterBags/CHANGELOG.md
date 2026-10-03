# BetterBags

## [v0.5.11](https://github.com/Cidan/BetterBags/tree/v0.5.11) (2026-09-20)
[Full Changelog](https://github.com/Cidan/BetterBags/compare/v0.5.10...v0.5.11) [Previous Releases](https://github.com/Cidan/BetterBags/releases)

- Fix PLAYER\_MONEY crash on WoW: Forever (directly UnregisterEvent BankPanel.MoneyDisplay) (#1106)  
    On Camelot, looting coin away from the bank (after a bank visit) crashed in  
    Blizzard's code:  
    Blizzard\_UIPanels\_Game/Camelot/BankFrame.lua:43: bad argument #1 to  
    'FetchNumPurchasedBankTabs' (bankType nil). Does not happen with the addon  
    disabled.  
    Trigger (verified from the forever source line-by-line):  
    BankPanel.MoneyDisplay:OnEvent(PLAYER\_MONEY) [425/427] -> :Refresh() [405,  
    TriggerEvent "BankPanelMixin.ShowOrHideBagCost"] -> BankFrameMixin:OnShowOrHideBagCost  
    [41/43] -> C\_Bank.FetchNumPurchasedBankTabs(nil). Refresh's guard reads  
    BankPanel:GetActiveBankType() (raw bankType, non-nil after a bank visit, so it  
    passes), but the handler reads BankFrame:GetActiveBankType() =  
    BankPanel:IsShown() and ... or nil = nil (CloseBank left BankPanel hidden).  
    Why BetterBags triggers it, and why Hide() can't fix it: MoneyDisplay registers  
    PLAYER\_MONEY at login (XML OnShow) and, because BetterBags reparents BankFrame  
    under a permanently-hidden sneakyFrame, it is never IsVisible, so its OnHide  
    never fires. Event registration is independent of shown state -- verified live  
    in the broken state: IsEventRegistered("PLAYER\_MONEY")==true while  
    IsShown()==false. So hiding it (my two earlier attempts) does nothing; it must be  
    UnregisterEvent'd directly (confirmed live to stop the crash).  
    Fix: UnregisterEvent("PLAYER\_MONEY") on MoneyDisplay in two taint-safe places --  
    bags/bank.lua bank:SuppressBlizzardBankPanel() (the consolidated bank-open  
    suppression helper, replacing the duplicated inline BankPanel blocks) so it is  
    killed when BetterBags takes over the bank, and core/hooks.lua addon.CloseBank  
    (the BANKFRAME\_CLOSED handler). Nothing re-registers it (its OnShow can't fire  
    while not IsVisible). Not done at init -- touching BankPanel/children during  
    HideBlizzardBags taints BankPanel and breaks UseContainerItem for all containers.  
    Nil-guarded, so live retail (no MoneyDisplay) is unaffected.  
    Tests: spec/bags/bank\_panel\_suppress\_spec.lua and spec/core/close\_bank\_spec.lua  
    assert the direct UnregisterEvent (plus the chrome hides / no-op on live retail).  
    Full suite 1060 passing, luacheck clean. Documented in camelot-forever.md  
    section 8.  
- Fix equipment-set crash on WoW: Forever + document Camelot bank model (#1104)  
    * Fix equipment-set crash on WoW: Forever (feature-detect EquipmentManager API)  
    On WoW: Forever (codename Camelot), creating a gear set crashed with  
    "data/equipmentsets.lua:39: attempt to call a nil value" via  
    CreateEquipmentSet -> EQUIPMENT\_SETS\_CHANGED -> refresh:RequestUpdate ->  
    equipmentSets:Update.  
    Root cause: equipmentSets:Update() chose between UpdatePreMidnight  
    (EquipmentManager\_UnpackLocation) and UpdateMidnight  
    (EquipmentManager\_GetLocationData) using the version gate addon.isMidnight  
    (addon.isRetail and tocVersion >= 120000). Forever is a mainline retail fork  
    that already ships the Midnight EquipmentManager (only GetLocationData; no  
    UnpackLocation) but reports a sub-12.0 TOC (Interface 16001), so isMidnight is  
    false. Update() therefore routed to UpdatePreMidnight and called the  
    non-existent EquipmentManager\_UnpackLocation.  
    Fix: route by which EquipmentManager API the client actually provides rather  
    than by TOC version. Prefer the old API where present so live retail (War  
    Within) and the classic-retail variants (BCC/Cata/Mists) keep their exact  
    current path, including the non-retail void-bank slot shift; both Midnight and  
    Forever fall to the GetLocationData path. This mirrors the "detect features,  
    not versions" rule already established for Camelot.  
    Tests: reworked the equipmentsets Update describe block to assert API  
    feature-detection (UnpackLocation-present path, UnpackLocation-absent Midnight  
    path) and added a Forever regression case (retail, non-midnight, no  
    UnpackLocation) that reproduced the crash before the fix. Documented in  
    .claude/rules/camelot-forever.md section 6.  
    * Fix empty bank showing no free-slot markers on WoW: Forever (Camelot)  
    On Camelot, opening an empty bank showed no free-slot markers because the base  
    character bank was never re-indexed after its container slots materialized.  
    Camelot is a retail fork (addon.isRetail == true) whose bank is a classic-style  
    numbered bank behind the retail tab UI. Its base/general character bank is  
    CharacterBankTab\_1 = bag id 6 (verified from origin/forever  
    Blizzard\_UIPanels\_Game/Camelot/BankFrame.lua: GetBagIDFromBankTypeAndSlot maps  
    Character base slot 1 -> bagSlot + ITEM\_INVENTORY\_BANK\_BAG\_OFFSET(5) = 6), which  
    is already in const.BANK\_BAGS, so the container list was correct.  
    The problem: unlike live retail's virtual bank tabs (refreshed via BAG\_UPDATE),  
    Camelot signals bank slot changes with the classic PLAYERBANKSLOTS\_CHANGED event  
    (its bank item-bag mixin registers PLAYERBANKSLOTS\_CHANGED,  
    PLAYER\_ACCOUNT\_BANK\_TAB\_SLOTS\_CHANGED, BAG\_CONTAINER\_UPDATE). But  
    data/refresh.lua gated its PLAYERBANKSLOTS\_CHANGED handler behind  
    `if not addon.isRetail`, so on Camelot it was never registered. The  
    BANKFRAME\_OPENED sweep runs before the paged bank's slots exist  
    (GetContainerNumSlots(6) reads 0), the base bank harvests empty, and with no  
    re-scan trigger it stays empty -> no free-slot markers. The free-space pipeline  
    itself is correct given consistent inputs; this was purely a missing re-scan  
    trigger.  
    Fix: add an `elseif addon.isForever` branch in refresh:OnEnable that registers  
    PLAYERBANKSLOTS\_CHANGED and requests a full bank re-scan ({ bank = true }, no  
    targeted bags), re-indexing every tab once its slots materialize. It does not  
    reuse the non-retail handler's bags = { [-1] = true } targeting because  
    Camelot's base bank is bag 6, not the classic -1. Live retail (isForever false)  
    stays unregistered and untouched; the stateless clean-sweep pipeline makes a  
    redundant bank refresh a no-op redraw.  
    Tests: added Forever registration/targeting test and a live-retail  
    non-registration test to spec/refresh\_spec.lua (the Forever case reproduced the  
    missing-marker root cause before the fix). Documented in  
    .claude/rules/camelot-forever.md section 7.  
    * Revert "Fix empty bank showing no free-slot markers on WoW: Forever (Camelot)"  
    * Fix blank/unindexed bank on WoW: Forever (base bank lives in container -1)  
    On Camelot an (empty) bank rendered completely blank -- no items, no free-slot  
    markers, no tab slots -- because BetterBags never scanned the container that  
    actually holds the base bank.  
    Verified live on a 1.60.1 client (empty bank, 0 purchased tabs): the only  
    bank-range container reporting slots was -1 (slots=32, free=32).  
    Characterbanktab (-2) reported nothing (it only holds bank-bag objects), and  
    every CharacterBankTab\_N (6..14) was empty because  
    C\_Bank.FetchNumPurchasedBankTabs(Character) == 0. So Camelot's always-present  
    base/general character bank is stored in container -1. The mainline enum  
    Camelot inherits labels -1 as "Keyring", but Camelot has no keyring.  
    const.BANK\_BAGS (retail build) was { [-2]=-2, 6..14 } and never included -1, so  
    Harvest / Phase5\_UpdateFreeSlots / Phase6\_EnrichData never touched the base  
    bank; with no purchased tabs, nothing bank-side was scanned at all.  
    Fix (inline addon.isForever, no split file, no new constant):  
    - core/constants.lua: after the retail CharacterBankTab\_ loop, add  
      const.BANK\_BAGS[-1] = -1 on Forever (BANK\_BAGS only, not BANK\_ONLY\_BAGS which  
      is the purchasable tabs alone). BANK\_BAGS drives the whole scan/partition/  
      free-count pipeline, the loader's managed-bag set, and the BAG\_UPDATE->bank  
      refresh fan-out, so this single addition indexes the base bank end to end and  
      routes it to the character bank tab (ACCOUNT\_BANK\_BAGS[-1] is nil).  
    - data/items.lua: the keyring special-casing keys off Enum.BagIndex.Keyring,  
      which is -1 on Camelot (the base bank). Gate both sites with  
      `not addon.isForever` so -1 is never excluded/mislabeled as the keyring:  
      Phase5\_UpdateFreeSlots (isKeyring guard) and Phase6\_EnrichData (name="Keyring"  
      branch). GetBagName needs no change (-1 isn't in BACKPACK\_BAGS, so it already  
      returns "#1: Bank").  
    This supersedes the reverted PLAYERBANKSLOTS\_CHANGED attempt, which could not  
    work because the base bank container was never in the scan list.  
    Tests (written first, observed failing): spec/core/constants\_spec.lua  
    ("Forever base bank container (-1)") and spec/items\_spec.lua ("Forever base  
    bank at -1 (keyring guard)"). Full suite 1058 passing, luacheck clean.  
    Documented in .claude/rules/camelot-forever.md section 7.  
    * Revert wrong Camelot base-bank fix (-1 is the keyring, not the bank)  
    The previous commit (77c36d3) added bag id -1 to const.BANK\_BAGS on Forever,  
    believing it was Camelot's base/general character bank. That was wrong and  
    caused the bank's aggregate free-slot counter to over-count by 32 (showed 80  
    free when the real bank had 48).  
    A per-container /run dump on a live 1.60.1 client resolved it: the real  
    character bank is the purchased tab CharacterBankTab\_1 = bag id 6  
    (slots=48, free=48, matching the player's hand count of 48). Bag id -1 is a  
    separate 32-slot container. The origin/forever source confirms -1 is the  
    KEYRING, not the bank: Blizzard\_FrameXMLBase/Constants.lua sets  
    KEYRING\_CONTAINER = Enum.BagIndex.Keyring (= -1), and Camelot (Wrath-era) has a  
    working keyring (Blizzard\_MainMenuBarBagButtons/Camelot GetKeyRingSize uses  
    GetContainerNumSlots(-1)). Adding -1 to BANK\_BAGS therefore counted 32 keyring  
    slots as bank free space.  
    This restores core/constants.lua and data/items.lua to their pre-77c36d3 state  
    (BANK\_BAGS = {-2, 6..14}, original keyring guards), which correctly scans the  
    purchased character bank tabs (6..14) and never touches the keyring (-1 is in  
    neither BACKPACK\_BAGS nor BANK\_BAGS). Removes the now-wrong constants/items  
    specs that asserted -1 belonged in BANK\_BAGS.  
    Documents the definitive Camelot bank container model in  
    .claude/rules/camelot-forever.md section 7 (bank = purchased CharacterBankTab\_N  
    6..14; -2/-3 hold bank-bag objects; -1 is the keyring; do NOT add -1), including  
    the note that a blank bank with slotted tabs is an async first-tab-load timing  
    issue, not a missing base-bank container.  
    Full suite 1054 passing, luacheck clean.  
- fix(search): in-bag search filter persistence + retail sparse-tooltip re-scan (#1103)  
    * fix(search): keep the in-bag search filter after a redraw (send-to-bank clears search)  
    Typing a query into the per-bag in-bag search box, then right-clicking an  
    item to send it to the bank, cleared the visible search filter. The redraw  
    triggered by the resulting BAG\_UPDATE recomputed each item's search state in  
    the data phase, but from the wrong source.  
    Root cause: there are two search inputs. The overlay box (searchBox:Create,  
    kind == nil, toggled by the search keybind, stored as searchBox.searchFrame)  
    and the per-kind in-bag boxes (searchBox:CreateBox, one per bag, stored on the  
    themed decoration as decoration.search). In-bag search is the default, and its  
    live filter is applied imperatively by bagProto:Search from the in-bag box's  
    OnTextChanged. Phase8\_EnrichCategories, which recomputes item.isSearchResult on  
    every sweep, read searchBox:GetText() -- which only ever sees the overlay box.  
    With in-bag search active the overlay box is empty, so Phase8 computed no  
    results and set isSearchResult = nil on every item; on redraw SetItemFromData  
    then took the SetMatchesSearch(not isFiltered) branch and un-dimmed everything.  
    Fix: add searchBox:GetSearchText(kind), which resolves the active query for a  
    bag kind -- the per-kind in-bag box when in-bag search is on and it holds text,  
    otherwise the overlay box (which searches both bags). Phase8\_EnrichCategories  
    now consults GetSearchText(kind) instead of GetText(), so a redraw faithfully  
    re-applies whatever filter the user typed.  
    Tests: new spec/frames/search\_spec.lua covers GetSearchText resolution  
    (in-bag vs overlay, per-kind, empty-fallback, in-bag-disabled); spec/items\_spec  
    adds a Phase8 repro (overlay empty, in-bag box holds the query) and the  
    existing Phase8/Phase6 search stubs plus refresh\_pipeline/persistent\_tabs stubs  
    are updated to the kind-aware getter. Documented in item-drawing.md #9.  
    * fix(tooltip): re-scan sparse retail tooltips on TOOLTIP\_DATA\_UPDATE  
    Searching a word that only appears in an item's tooltip body (e.g. "health"  
    from "Use: Restores 70 to 90 health.") intermittently failed to match, same  
    code, different sessions -- a race, not a logic bug.  
    Root cause: the TooltipScanner caches scanned text per item GUID and short-  
    circuits on a cache hit, but the retail scan (C\_TooltipInfo.GetBagItem) can  
    return a SPARSE tooltip. An item's "Use:" spell line loads on a separate async  
    channel (C\_Spell.RequestLoadSpellData -> SPELL\_DATA\_LOAD\_RESULT) from its base  
    data (ITEM\_DATA\_LOAD\_RESULT), and the ItemLoader ContinuableContainer barrier  
    waits only on the item channel. So the harvest can scan a tooltip whose name  
    line is present but whose "Use:" line is still cold, cache that non-empty-but-  
    partial text, and -- because nothing invalidated the cache (ClearCache/  
    RemoveFromCache had zero callers, no TOOLTIP\_DATA\_UPDATE listener) -- keep it  
    until /reload. Whether it was warm at scan time is the race.  
    Fix (retail only; Classic's GameTooltip FontString scan is untouched -- it has  
    no C\_TooltipInfo/dataInstanceID):  
    - Record each scanned tooltip's dataInstanceID against the cached GUID  
      (instanceToGUID/guidToInstance, kept strictly 1:1 with the cache so they can  
      never leak).  
    - Register TOOLTIP\_DATA\_UPDATE exactly once (guarded against duplicate handlers)  
      when addon.isRetail. On the debounced batch, drop the stale cache entry for  
      each resolved instance and re-harvest (bags/RefreshBackpack always;  
      bags/RefreshBank only when addon.atBank, so the bank is never clobbered while  
      away). Unknown/nil instance ids are ignored -- no spurious refresh.  
    The debounce + per-fire arg collection lives in the Events module, not a hand-  
    rolled timer: events:BucketEvent now coalesces every fire's payload in the 0.2s  
    window and passes the callback an EventArg[] (dataInstanceIDs), while keeping  
    its prior ctx-first contract for existing callers.  
    Tests: events\_spec (BucketEvent arg collection), tooltip\_spec (instance map,  
    invalidate+re-harvest, warm re-scan, unknown/nil ignored, atBank routing, map  
    1:1 with cache, once-only registration). Documented in tooltip-scanning.md.  