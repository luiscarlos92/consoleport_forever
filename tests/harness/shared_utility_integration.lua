local messages={}
DEFAULT_CHAT_FRAME={AddMessage=function(_,text) messages[#messages+1]=text end}
SlashCmdList={}
--@UTILITY_FLAG
--@UTILITY_INTEGRATION
local Integration=Addon.UtilityIntegration
local frames=container
function container:HookScript(event,callback) self.hooks=self.hooks or {} self.hooks[event]=callback end
function container:EnumerateActive() return function() end end
local cp={GetData=function() return db end}
local lib={ConsolePort_Rings=env}
local itemCalls=0
local gapi={LibStub=function() return lib end,ConsolePort=cp,CPAPI=CPAPI,issecretvalue=api.issecretvalue,
    C_AddOns={GetAddOnMetadata=function() return '3.3.10' end},
    GetSpecialization=function() return ctx.spec==65 and 2 or 1 end,GetSpecializationInfo=function() return ctx.spec end,
    UnitGUID=function() return ctx.guid end,UnitFactionGroup=function() return 'Alliance' end,
    C_ClassTalents={GetActiveConfigID=function() return ctx.config end},
    InCombatLockdown=function() return combat end,C_Timer={After=function(_,callback) queue[#queue+1]=callback end},
    Enum={SpellBookSpellBank={Player=0,Pet=1}},
    C_SpellBook={IsSpellKnown=function(id,bank) return bank==0 and known(id) or false end},
    C_Spell={GetOverrideSpell=function(id) return overrides[id] or id end,RequestLoadSpellData=function() end},
    C_Item={IsItemDataCachedByID=function(id) return not not itemLoaded[id] end,RequestLoadItemDataByID=function() end,
        GetItemCount=function(value,bank,uses,reagent,account)
            itemCalls=itemCalls+1 check(bank==false and uses==false and reagent==false and account==false,'integration included bank items')
            local id=tonumber(value) or (type(value)=='string' and tonumber(value:match('item:(%d+)'))) return inventory[id] or 0
        end},
    C_MountJournal={GetMountFromSpell=function() end,GetMountInfoByID=function() end},PlayerHasToy=function() return false end,
    C_EquipmentSet={GetEquipmentSetID=function(name) if name=='Set' then return 4 end end},
    GetActionInfo=function() return 'spell',101 end,GetPetActionInfo=function() return 'Attack',nil,true,false,false,false,1 end}
CPAPI.MAX_ACCOUNT_MACROS=120
local account={} assert(Addon.Store.EnsureSchema(account,'A'))
local record=Addon.Store.GetCharacter(account,'A') record.ringAccepted=true
local itemLink='|cffffffff|Hitem:12345:0:0:0:0:0:0:0:0:0:0:0|h[Item]|h|r'
local native={[0]={name='Utility'},env:GetStarterSet()[1],{type='spell',spell='Rite',link='spell:101'},
    {type='item',item=itemLink},{type='macro',macro=1,name='Personal',body='/cast Rite',icon=1},
    {type='custom',ring='Class',link='native:Class'},{type='equipmentset',equipmentset='Set'}}
-- Model the native link description for the nested-ring action.
function env:GetDescriptionFromRingLink(link) return link,nil,'Class','texture' end
macros[121]={name='Character',body='/cast Rite',icon=1}
native[#native+1]={type='macro',macro=121,name='Character',body='/cast Rite',icon=1}
container.Data[1]=Core.Copy(native)
record.rings.sets={[1]=Core.Copy(native),Class=Core.Copy(container.Data.Class)}
record.rings.sets[1][#record.rings.sets[1]+1]={type='spell',spell=102}
account.shared.ringProjectionGUID='A'
local app={db=account,record=record,guid='A',Prompt={active=false}}
ConsolePortForeverDB=account
local runtime,reason=Addon.UtilityIntegration:Refresh(app,gapi)
check(runtime~=nil,'qualified runtime integration did not initialize: '..tostring(reason))
Addon.utilityRuntime=runtime
pump()
check(account.sharedUtilityEnabled==true and #account.sharedUtilityArchive.entries==8,'first-use migration lost current/dormant choices')
check(activeSpell(101) and not activeSpell(102),'first-use migration ignored current availability')
local linkPreserved=false for _,action in ipairs(container.Data[1]) do if action.item==itemLink then linkPreserved=true end end
check(linkPreserved,'item-only hyperlink lost variant/execution identity')
local initial=model
local queries=itemCalls local spellQueries=runtime.model.counts.spell local rebuilds=refreshes
for i=1,100 do Addon.UtilityIntegration:Event(app,gapi,'ITEM_COUNT_CHANGED',12345) end pump()
check(itemCalls==queries+1 and runtime.model.counts.spell==spellQueries and refreshes==rebuilds,'integration item event burst did not stay incremental')

-- Macro edit cannot fall through native fuzzy matching into another index.
macros[2]={name='Personal',body='/cast Rite',icon=1}
macros[1]={name='Personal',body='/cast Other',icon=1}
container:UPDATE_MACROS() Addon.UtilityIntegration:Event(app,gapi,'UPDATE_MACROS') pump()
local accountMacro=false local wrongMacro=false
for _,action in ipairs(container.Data[1]) do if action.macro==1 then accountMacro=true elseif action.macro==2 then wrongMacro=true end end
check(not accountMacro and not wrongMacro,'edited macro was retargeted by native fuzzy matching')
macros[1]={name='Personal',body='/cast Rite',icon=1}
container:UPDATE_MACROS() Addon.UtilityIntegration:Event(app,gapi,'UPDATE_MACROS') pump()
local saved=Core.Copy(account.sharedUtilityArchive)
ctx={guid='B',spec=577,config=2} app.guid='B' app.record=Addon.Store.GetCharacter(account,'B')
container:SPELLS_CHANGED() Addon.UtilityIntegration:Event(app,gapi,'PLAYER_SPECIALIZATION_CHANGED','player') pump()
local characterMacro=false local characterRing=false local equipment=false
for _,action in ipairs(container.Data[1]) do
    if action.macro==121 then characterMacro=true elseif action.ring=='Class' then characterRing=true elseif action.equipmentset then equipment=true end
end
check(not characterMacro and not characterRing and not equipment,'character-owned native entry leaked to another GUID')
check(activeSpell(102) and not activeSpell(101),'integration character switch lost shared availability')
ctx={guid='A',spec=66,config=1} app.guid='A' app.record=record
container:SPELLS_CHANGED() Addon.UtilityIntegration:Event(app,gapi,'PLAYER_SPECIALIZATION_CHANGED','player') pump()
check(activeSpell(101) and #logs==0,'integration return produced errors/lost spell')

-- Native removal is an intentional edit while its wheel remains open. It must
-- rebuild immediately so the native restricted remove hook redraws current DATA.
open=true
local removeIndex for index,action in ipairs(container.Data[1]) do if action.spell==101 then removeIndex=index end end
local beforeRemoval=refreshes
container:SafeRemoveAction(1,removeIndex)
check(not activeSpell(101) and refreshes==beforeRemoval+1,'native open-wheel removal did not rebuild current selection')
open=false container.hooks.OnHide(container) pump()
ctx.spec=65 container:SPELLS_CHANGED() ctx.spec=66 container:SPELLS_CHANGED()
check(not activeSpell(101),'explicit open-wheel removal was resurrected')
cursor={'spell',1,'player',101} container:CheckCursorInfo(1,true) pump()
check(activeSpell(101),'native cursor re-add failed after open-wheel removal')

-- Actual independent slash handler can disable this running object. Reload has
-- no constructor, hook, worker or projection when the stored flag is false.
SlashCmdList.CPFUTILITY('off')
check(account.sharedUtilityEnabled==false and runtime.stopped,'actual off command did not persist/stop feature')
local master=Core.Copy(account.sharedUtilityArchive)
local fallback=Core.Copy(record.rings.sets[1])
check(#fallback>0 and fallback[0].name=='Utility','disable did not retain native fallback view')
local disabledApp={db=account,record=record,guid='A',Prompt={active=false}}
local hooked=env.ValidateSet
Addon.utilityRuntime=nil
check(Addon.UtilityIntegration:Refresh(disabledApp,gapi)==nil and env.ValidateSet==hooked,'disabled reload initialized feature hooks')
check(Core.Equal(account.sharedUtilityArchive,master),'disable changed shared archive')
-- The command remains usable without any feature object/module construction.
Addon.UtilityIntegration=nil
SlashCmdList.CPFUTILITY('status') SlashCmdList.CPFUTILITY('on') SlashCmdList.CPFUTILITY('off')
check(account.sharedUtilityEnabled==false and #messages>=4,'independent command bootstrap failed')
local before=Core.Copy(account)
SlashCmdList.CPFUTILITY('unexpected')
check(Core.Equal(account,before),'invalid slash command changed storage')
local broken={} assert(Addon.Store.EnsureSchema(broken,'A'))
local brokenRecord=Addon.Store.GetCharacter(broken,'A')
broken.sharedUtilityArchive={version=999,entries='corrupt'}
local brokenApp={db=broken,record=brokenRecord,guid='A',Prompt={active=false}}
local constructor=Addon.SharedUtility.New local attempts=0
Addon.SharedUtility.New=function(...) attempts=attempts+1 return constructor(...) end
for i=1,100 do check(Integration:Refresh(brokenApp,gapi)==nil,'corrupt archive unexpectedly initialized') end
Addon.SharedUtility.New=constructor
check(attempts==1,'actual feature initialization error retried on every event')
ConsolePortForeverDB=broken
SlashCmdList.CPFUTILITY('off')
check(broken.sharedUtilityEnabled==false and broken.sharedUtilityArchive.version==999,'corrupt archive blocked independent disable')
local empty={} assert(Addon.Store.EnsureSchema(empty,'A'))
local emptyRecord=Addon.Store.GetCharacter(empty,'A')
empty.sharedUtilityArchive={version=1,revision=0,nextID=1,entries={},receipts={}}
container.Data[1]={[0]={name='Empty'}}
local emptyApp={db=empty,record=emptyRecord,guid='A',Prompt={active=false}}
local emptyRuntime=Integration:Refresh(emptyApp,gapi) pump()
check(emptyRuntime and emptyRuntime.primed,'empty saved master did not establish edit ownership')
open=true cursor={'spell',1,'player',101} container:CheckCursorInfo(1,true)
check(activeSpell(101) and #empty.sharedUtilityArchive.entries==1,'first cursor add to open empty ring was dropped/deferred')
open=false container.hooks.OnHide(container) pump()
INTEGRATION_UTILITY_RESULTS={checks=checks,initialChoices=8,slashMessages=#messages,bankQueriesExcluded=true}
TEST_SUCCESS=true
