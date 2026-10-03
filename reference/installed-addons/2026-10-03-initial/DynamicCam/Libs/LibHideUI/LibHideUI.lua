
local MAJOR, MINOR = "LibHideUI-1.0", 0;
local LibHideUI = LibStub:NewLibrary(MAJOR, MINOR);

if not LibHideUI then
  return
end














-- config.uiParentTargetAlpha     (default is 0, otherwise set UIFrame alpha to uiParentTargetAlphaw while hidden)
-- config.uiParentFadeTime        (default is 0, otherwise assume uiParentTargetAlpha with a fade effect of uiParentFadeTime seconds.
-- config.hideFrameRate           (As frame rate label is not a child of UIParent, hiding it requires extra steps.)
-- config.customFramesToKeep      (a list of lits, with one list per frame to keep)
--    {
--      frameName                 (mandatory: frame name)
--      frameTargetAlpha          (optional: default is 1, otherwise set frame alpha to frameTargetAlpha)
--      frameFadeTime             (optional: default is the same as uiParentFadeTime, otherwise assume frameTargetAlpha with a fade effect of frameFadeTime seconds)
--      frameMouseOverAlpha       (optional: default nil -> mousover has no effect, otherwise frame will assume alpha frameMouseOverAlpha while mouse is hovering)
--      frameMouseOverEnterTime   (optional: default 0, otherwise assume frameMouseOverAlpha with a fade effect of frameMouseOverEnterTime seconds after the beginning of hovering)
--      frameMouseOverLeaveTime   (optional: default 0, otherwise go back to frameTargetAlpha with a fade effect of frameMouseOverLeaveTime seconds after the end of hovering)
--    }
-- config.keepAlertFrames         (more complicated than just providing frame names)
-- config.keepTooltip             (more complicated than just providing frame names)

-- config.keepTrackingBar         (Has a lot of different frames. Also depending on retail/classic.)
-- config.keepChatFrame           (Has to iterate over several frames.)
-- config.keepPartyRaidFrame      (Has to iterate over several frames.)

-- config.addonPriority           (if several addons want to explicitly give priority to one another, higher number = higher priority)



-- config.keepMinimap (TODO: Not sure if I need this because of other addons (Immersion) setting IgnoreParentAlpha...)








-- If we are keeping at least some frames, we cannot hide UIFrame after fade out. This means that hidden frames are still clickable and (if config.keepTooltip) still show their tooltips upon mouseover. Hence, we have this list of frames to hide when their (or their parent's) alpha is 0 (but their parent is not hidden).
-- We set the value to true if we want to always hide it (unless frame is included customFramesToKeep), or to the key in config which can be used to not hide it. 
LibHideUI.framesToHide = {
  ["PlayerFrame"] = true,
  ["PetFrame"] = true,
  ["TargetFrame"] = true,
  ["BuffFrame"] = true,
  ["DebuffFrame"] = true,
  ["ObjectiveTrackerFrame"] = true,
  ["CollectionsJournal"] = true,
  ["QuickJoinToastButton"] = true,
  -- TODO: Would have to fade every single 3D model separately.
  ["WardrobeFrame"] = true,
  
  ["StatusTrackingBarManager"] = "keepTrackingBar",
  ["BT4BarStatus"] = "keepTrackingBar",
  ["MainMenuExpBar"] = "keepTrackingBar",
  ["ReputationWatchBar"] = "keepTrackingBar",
  ["GwExperienceFrame"] = "keepTrackingBar",
  ["EncounterBar"] = "keepTrackingBar",
  ["CompactRaidFrameContainer"] = "keepTrackingBar",
  
}


for i = 1, 12, 1 do
  LibHideUI.framesToHide["ChatFrame" .. i] = "keepChatFrame"
  LibHideUI.framesToHide["ChatFrame" .. i .. "Tab"] = "keepChatFrame"
  LibHideUI.framesToHide["ChatFrame" .. i .. "EditBox"] = "keepChatFrame"
  LibHideUI.framesToHide["GwChatContainer" .. i] = "keepChatFrame"
end


LibHideUI.framesToHide["CompactRaidFrameContainer"] = "keepPartyRaidFrame"

for i = 1, 4, 1 do
  LibHideUI.framesToHide["PartyMemberFrame" .. i] = "keepPartyRaidFrame"
  LibHideUI.framesToHide["PartyMemberFrame" .. i .. "NotPresentIcon"] = "keepPartyRaidFrame"
end



-- The CompactRaidFrameContainer frame gets shown every time the raid roster changes.
-- While the UI is hidden, we have to hide it again.
CompactRaidFrameContainer:HookScript("OnShow", function()
  if not currentConfig or ludius_UiHideModule.uiHiddenTime == 0 then return end
  if currentConfig.keepPartyRaidFrame == false then
    FadeOutFrame(CompactRaidFrameContainer, 0, false, currentConfig.UIParentAlpha)
  end
end)




if Bartender4 then
  LibHideUI.framesToHide["BT4Bar1"] = true
  LibHideUI.framesToHide["BT4Bar2"] = true
  LibHideUI.framesToHide["BT4Bar3"] = true
  LibHideUI.framesToHide["BT4Bar4"] = true
  LibHideUI.framesToHide["BT4Bar5"] = true
  LibHideUI.framesToHide["BT4Bar6"] = true
  LibHideUI.framesToHide["BT4Bar7"] = true
  LibHideUI.framesToHide["BT4Bar8"] = true
  LibHideUI.framesToHide["BT4Bar9"] = true
  LibHideUI.framesToHide["BT4Bar10"] = true
  LibHideUI.framesToHide["BT4Bar11"] = true
  LibHideUI.framesToHide["BT4Bar12"] = true
  LibHideUI.framesToHide["BT4Bar13"] = true
  LibHideUI.framesToHide["BT4Bar14"] = true
  LibHideUI.framesToHide["BT4Bar15"] = true
  LibHideUI.framesToHide["BT4BarBagBar"] = true
  LibHideUI.framesToHide["BT4BarMicroMenu"] = true
  LibHideUI.framesToHide["BT4BarStanceBar"] = true
  LibHideUI.framesToHide["BT4BarPetBar"] = true
else
  LibHideUI.framesToHide["MainMenuBar"] = true
  LibHideUI.framesToHide["MultiBarLeft"] = true
  LibHideUI.framesToHide["MultiBarRight"] = true
  LibHideUI.framesToHide["MultiBarBottomLeft"] = true
  LibHideUI.framesToHide["MultiBarBottomRight"] = true
  LibHideUI.framesToHide["MultiBar5"] = true
  LibHideUI.framesToHide["MultiBar6"] = true
  LibHideUI.framesToHide["MultiBar7"] = true
  LibHideUI.framesToHide["MultiBar8"] = true
  LibHideUI.framesToHide["ExtraAbilityContainer"] = true
  LibHideUI.framesToHide["MainMenuBarVehicleLeaveButton"] = true
  LibHideUI.framesToHide["MicroButtonAndBagsBar"] = true
  LibHideUI.framesToHide["MultiCastActionBarFrame"] = true
  LibHideUI.framesToHide["StanceBar"] = true
  LibHideUI.framesToHide["PetActionBar"] = true
  LibHideUI.framesToHide["PossessBar"] = true
end



















-- When keeping a frame, we have to make sure that none of their parent frames are hidden because of being in framesToHide.
LibHideUI.framesToHideSuspended = {}







function LibHideUI:HideUI(addonName, config)



end
















-- local enterCombatFrame = CreateFrame("Frame")
-- enterCombatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
-- enterCombatFrame:SetScript("OnEvent", function()
  -- -- print("enterCombatFrame")

  -- -- If entering combat while UIParent is hidden,
  -- -- we have to show it here again, because it is not allowed during combat.
  -- -- To avoid that the UI is also faded in again, we have to
  -- -- temporarily disable our UIEscapeHandler while showing UIParent.
  -- if not UIParent:IsShown() then
    -- local fadeUIEscapeHandlerShown = fadeUIEscapeHandlerFrame:IsShown()
    -- if fadeUIEscapeHandlerShown then UIEscapeHandlerDisable() end
    -- uiParentHidden = false
    -- UIParent:Show()
    -- if fadeUIEscapeHandlerShown then fadeUIEscapeHandlerFrame:Show() end
  -- end

  -- -- If entering combat while frames are faded to 0 *and hidden*,
  -- -- we have to show the hidden frames again, because Show() is
  -- -- not allowed for protected frames during combat.
  -- if ludius_UiHideModule.uiHiddenTime ~= 0 then
    -- Addon.ShowUI(0, true)
  -- end
-- end)


