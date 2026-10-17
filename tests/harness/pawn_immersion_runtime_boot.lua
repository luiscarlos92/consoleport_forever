-- Execute the real PawnInitialize/PawnOnEvent/PawnInitializePlugins bodies.
-- Saved-option migration, game keybindings/UI and scale parsing are explicit
-- subsystem models here; scoring/formatting are exercised by the shared suite.
RUNTIME_ASSERTIONS=0
local nativeAssert=assert
local function assert(value,message)RUNTIME_ASSERTIONS=RUNTIME_ASSERTIONS+1;return nativeAssert(value,message)end
TEST_OWNER={guid='test-guid',record={appliedRevision=20},db={transactions={}}}
function TEST_OWNER:IsCharacterInstalled()return self.record.appliedRevision>0 end
local metadata=C_AddOns.GetAddOnMetadata
C_AddOns.GetAddOnMetadata=function(name,...)
 if name=='BetterBags' then return PREPARED and 'v0.5.16' or 'v0.5.14' end
 return metadata(name,...)
end
local loaded=C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded=function(name)
 if name:match('^Blizzard_') then return false end
 return loaded(name)
end
function SetBasicMessageDialogText()MODEL.startupWarning=true end
function GetLocale()return 'enUS'end
SlashCmdList={};PawnLocalizedLanguages={'enUS'}
local originalOptions,originalSpec=PawnInitializeOptions,PawnOnSpecChanged
local originalBindings,originalUI=PawnSetDefaultKeybindings,PawnUI_InventoryPawnButton_Move
function PawnInitializeOptions()PawnCommon={Scales={}};PawnOptions={}end
function PawnSetDefaultKeybindings()end
function PawnUI_InventoryPawnButton_Move()end
function PawnOnSpecChanged()MODEL.specInitialized=true end
VgerCore.IsBattleOrLater=true
local function nothing()end
for _,name in ipairs({'DeleteCursorItem','PickupMerchantItem','EmbeddedItemTooltip_SetItemByQuestReward',
 'LootWonAlertFrame_SetUp','PawnUI_GroupLootFrame_OnShow','PawnUI_LootWonAlertFrame_SetUp'})do _G[name]=nothing end
local setters={'SetBagItem','SetBuybackItem','SetHyperlink','SetInboxItem','SetInventoryItem','SetItemByID',
 'SetQuestLogItem','SetLootItem','SetLootRollItem','SetMerchantItem','SetSendMailItem','SetTradePlayerItem','SetTradeTargetItem','SetTrainerService'}
for _,name in ipairs(setters)do if not GameTooltip[name]then GameTooltip[name]=nothing end end
ItemRefTooltip=CreateFrame('GameTooltip','ItemRefTooltip',UIParent);ItemRefTooltip.SetHyperlink=nothing
for i=1,4 do local f=CreateFrame('Frame','GroupLootFrame'..i);f.IconFrame=CreateFrame('Frame')end
ShoppingTooltip1=GameTooltip.shoppingTooltips[1];ShoppingTooltip2=GameTooltip.shoppingTooltips[2]
local probe
if not WORKLOAD_ONLY then
 probe=Addon.PawnImmersion.New(TEST_OWNER,_G);Addon.PawnImmersion.instance=probe
 assert(probe:Install(),'runtime hook installation unavailable')
 assert(not probe:Available(),'runtime queried before actual Pawn initialization')
end
-- A real early return (old/missing VgerCore) must not manufacture readiness.
PawnOnEvent('PLAYER_LOGIN');RunTimers()
assert(MODEL.startupWarning,'real Pawn early-return branch not reached')
if probe then assert(not probe:Available(),'failed Pawn initialization accepted')end
VgerCore.Version=1.23
PawnOnEvent('PLAYER_LOGIN')
assert(MODEL.specInitialized,'real Pawn initialization did not finish scale phase')
if probe then assert(not probe:Available(),'Pawn readiness published inside initialization')end
RunTimers()
if probe then assert(probe:Available(),'observed actual Pawn initialization did not activate bridge')end
PawnInitializeOptions,PawnOnSpecChanged=originalOptions,originalSpec
PawnSetDefaultKeybindings,PawnUI_InventoryPawnButton_Move=originalBindings,originalUI
TEST_BOOT_BRIDGE=probe
