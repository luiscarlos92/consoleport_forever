local Core,Bridge=Addon.Core,Addon.RingsAdapter
local combat,open,currentGUID=false,false,'A'
local known={[101]=true,[102]=true}
local refreshes=0
local container={GetName=function() return 'NativeUtility' end}
function container:IsShown() return open end
local env={Frame=container,Attributes={MetadataIndex=0,DefaultSetBtn='LeftButton'},IsDataReady=true,IsSpellValidationReady=true}
local db=setmetatable({table={compare=Core.Equal},ActionMap={binding=function(id) return {type='custom',binding=id} end,
    spellID=function(id) return {type='spell',spell=id} end,item=function(id) return {type='item',item=id} end},
    Bindings={Custom={UnitMenu='UNITMENU',MenuRing='MENURING'},ConvertRingSetIDToDisplayName=function(_,id) return tostring(id) end,
        GetDescriptionForBinding=function(_,id) return id,nil,id,'texture' end}},
    {__call=function() return true end})
function db:Register() end
function db:Save() end
function db:RegisterCallback() end
function db:RegisterSafeCallback() end
function env:AddLoader() end
CPAPI={DefaultRingSetID=1,ExtraActionButtonID=169,IsModernVersion=true,GetEnv=function() return env,db end,
    GetSpellInfo=function(spell) return known[spell] and {spellID=spell} or {} end,
    GetSpellLink=function(spell) return known[spell] and 'spell:'..spell end,
    GetItemInfo=function(item) return {itemLink=tostring(item)} end,Log=function() end,
    Static=function(value) return function() return value end end}
function CreateFromMixins(...)
    local value={} for i=1,select('#',...) do for k,v in pairs(select(i,...)) do value[k]=v end end return value
end
function Clamp(value,min,max) return math.max(min,math.min(max,value)) end
function wipe(t) for key in pairs(t) do t[key]=nil end return t end
function tAppendAll(dest,source) for _,v in ipairs(source) do table.insert(dest,v) end end
tinsert,tremove=table.insert,table.remove
function InCombatLockdown() return combat end
--@NATIVE_DATABASE
--@NATIVE_MAP
--@NATIVE_CONTAINER
local Secure=container
--@NATIVE_REFRESH
--@NATIVE_AUTO
function container:ClearAllActions() assert(not combat) refreshes=refreshes+1 self.compiled={} end
function container:AddSecureMetadata(id,data) self.compiled[id]={meta=Core.Copy(data),actions={}} end
function container:AddSecureAction(id,index,info)
    local kind,action=env:GetKindAndAction(info)
    self.compiled[id].actions[index]={kind=kind,action=action}
end
function container:SetAttribute() end
function env:EnumerateAvailableSets()
    local sets=self:GetAvailableSets()
    return next,sets,nil
end
local account=SESSION_STATE and SESSION_STATE.account or {}
assert(Addon.Store.EnsureSchema(account,'A'))
Addon.Store.GetCharacter(account,'A') Addon.Store.GetCharacter(account,'B')
if SESSION_STATE then
    container.Data=Core.Copy(SESSION_STATE.live)
    container.Shared=Core.Copy(SESSION_STATE.shared)
else
    container.Data={[1]={{type='item',item='6948'}, {type='spell',spell=101},[0]={name='Utility',customMeta='keep'}},
        Auras={{type='spell',spell=102},[0]={name='Manual class'}},Manual={{type='custom',binding='CUSTOM'},[0]={name='Custom'}}}
    container.Shared={SharedManual={{type='item',item='12345'},[0]={name='Account ring'}}}
end
local sharedBefore=Core.Copy(container.Shared)
local function adapter(guid)
    return Bridge.New({version='3.3.5',getEnv=function() return env end,getDB=function() return db end,
        inCombat=function() return combat end,currentGUID=function() return currentGUID end,defaultSet=1,classSet='Auras'},account,guid)
end
db.Rings=container
local a,b=adapter('A'),adapter('B')
local function install(r,guid)
    currentGUID=guid
    local writeError
    r.write=function(self,...)
        local ok,result=pcall(Bridge.write,self,...)
        if not ok then writeError=tostring(result) error(result) end
        return result
    end
    local desired=assert(r:Proposal())
    local fields={{id=guid..'/rings',scope='rings',path={'state'},value=desired,revision=5}}
    local c=assert(Addon.Coordinator.New(account,guid,{rings=r},function() return not combat end))
    local plan=c:Build(fields,5)
    local decisions={}
    for _,field in ipairs(plan.conflicts) do decisions[field.id]='accept' end
    local ok,journal=c:Accept(decisions) assert(ok,guid..': '..tostring(journal)..' '..tostring(writeError))
    if not account.characters[guid].ringAccepted then account.characters[guid].rings.sets=Core.Copy(r:read({'state'}).sets) end
    account.characters[guid].ringAccepted=true
    assert(r:CaptureEdits())
    return journal
end
--@LIFECYCLE
local baseline=Core.Copy(container.Data)
local dataIdentity,utilityIdentity,metadataIdentity=container.Data,container.Data[1],container.Data[1][0]
local proposed=assert(a:Proposal())
assert(refreshes==0 and Core.Equal(container.Data,baseline),'proposal changed native ring data')
local first=install(a,'A')
assert(container.Data==dataIdentity and container.Data[1]==utilityIdentity)
assert(Core.Equal(container.Data[1][0],metadataIdentity),'native metadata rebuild lost manual values')
assert(account.shared.ringProjectionGUID=='A' and account.characters.A.ringAccepted)
local ringData=container.Data
local archiveBefore=Core.Copy(account.characters.A.rings)
local prepared=assert(Addon.RingSelectors.Build({guid='A',formsReady=true,forms={{spell=101},{spell=102}},
    pet={ready=true,guid='Pet-A',actions={{action=1},{action=4}}}},'A',container,'Auras',a:read({'state'}).sets))
assert(not prepared.active and prepared.pet.bindingPreview=='CLICK NativeUtility:CPFPet')
-- Only this isolated native-source simulation installs the inactive draft in
-- its disposable frame data to check current native kind/action compilation.
container.Data=Core.Copy(ringData)
container.Data.Auras=prepared.class.set container.Data.CPFPet=prepared.pet.set
container:RefreshAll()
assert(container.compiled.CPFPet.actions[1].kind=='pet' and container.compiled.CPFPet.actions[2].action==4)
assert(Core.Equal(account.characters.A.rings,archiveBefore),'selector preparation changed the GUID archive')
container.Data=ringData container:RefreshAll()
-- Native automatic quest/zone behavior stays on the real Container methods.
assert(container:AssignAction({type='spell',spell=101,questID=900}))
assert(#container.Data[1]==3 and container.Data[1][3].autoassigned)
assert(a:CaptureEdits() and #account.characters.A.rings.sets[1]==2)
assert(not b:CaptureEdits(),'B captured A projection')
-- Native duplicate/manual ordering is preserved, while current utility extras
-- remain native-owned across the accepted GUID replacement.
container.Data.Auras[2]={type='spell',spell=101}
container.Data.Auras[3]={type='spell',spell=102}
container:RefreshAll() assert(a:CaptureEdits())
local aArchive=Core.Copy(account.characters.A.rings.sets)
currentGUID='B'
local bProposal=assert(b:Proposal())
assert(#bProposal.sets.Auras==0 and bProposal.sets.Manual==nil and #bProposal.sets[1]==2)
assert(bProposal.sets[1][1].type=='custom','new GUID inherited prior personal spells')
local second=install(b,'B')
assert(account.shared.ringProjectionGUID=='B' and #container.Data.Auras==0 and container.Data.Manual==nil)
assert(container.Data[1][3].autoassigned and container.Data[1][3].questID==900)
assert(Core.Equal(container.Shared,sharedBefore))
container.Data.Auras[1]={type='spell',spell=101}
container.Data.Auras[0].name='B own order'
container:RefreshAll() assert(b:CaptureEdits())
assert(Core.Equal(account.characters.A.rings.sets,aArchive),'B overwrote A archive')
-- Return projection through an independently retained transaction.
currentGUID='A'
local desired=assert(a:Proposal())
local step={id='A/rings',scope='rings',path={'state'},before=a:read({'state'}),value=desired,revision=5}
local projection=Addon.Transactions.Prepare(account,'A',{step},{ringProjection=true})
assert(Addon.Transactions.Apply(projection,{rings=a},function() return not combat end))
assert(Addon.Transactions.Commit(account,projection,5))
assert(#container.Data.Auras==3 and container.Data.Auras[1].spell==102 and container.Data.Auras[2].spell==101)
assert(container.Data.Auras[3].spell==102 and Core.Equal(container.Shared,sharedBefore))
-- Native validation hides unavailable entries; GUID archive keeps them and
-- restores their original position after availability returns.
known[102]=nil
container:RefreshAll() assert(#container.Data.Auras==1)
assert(a:CaptureEdits())
assert(#account.characters.A.rings.sets.Auras==3 and #account.characters.A.rings.dormant.Auras==2)
assert(#assert(a:Proposal()).sets.Auras==1)
known[102]=true
assert(#assert(a:Proposal()).sets.Auras==3)
assert(a:write({'state'},assert(a:Proposal())))
assert(a:CaptureEdits() and not account.characters.A.rings.dormant.Auras)
-- Manual removal of an available entry and an entire custom set survives.
table.remove(container.Data.Auras,2) container.Data.Manual=nil
container:RefreshAll() assert(a:CaptureEdits())
assert(#account.characters.A.rings.sets.Auras==2 and account.characters.A.rings.sets.Manual==nil)
-- Combat, unknown versions, missing readiness and mismatched environment defer.
local snapshot=a:read({'state'})
combat=true assert(not a:write({'state'},snapshot)) combat=false
open=true assert(not a:write({'state'},snapshot)) open=false
local version=a.api.version a.api.version='future' assert(not a:Probe()) a.api.version=version
env.IsSpellValidationReady=false assert(not a:Proposal()) env.IsSpellValidationReady=true
a.api.getEnv=function() return {Frame={}} end assert(not a:Probe()) a.api.getEnv=function() return env end
local retained=account.characters.A.rings.sets
account.characters.A.rings.sets=false assert(not a:Proposal()) account.characters.A.rings.sets=retained
-- Failure after the native refresh takes effect compensates and retains both
-- original/personal snapshots. A newer edit refuses automatic compensation.
local refresh=container.RefreshAll
local failures=0
container.RefreshAll=function(self) refresh(self) failures=failures+1 if failures==1 then error('native refresh rejected after mutation') end end
local before=a:read({'state'}) local failureDesired=Core.Copy(before) failureDesired.sets.Auras[0].name='Failure target'
local failed=Addon.Transactions.Prepare(account,'A',{{id='A/rings',scope='rings',path={'state'},before=before,value=failureDesired,revision=5}})
assert(not Addon.Transactions.Apply(failed,{rings=a},function() return true end))
assert(failed.status=='rolled-back' and Core.Equal(a:read({'state'}),before))
container.RefreshAll=refresh
local changed=Core.Copy(before) changed.sets.Auras[0].name='Newer edit'
assert(a:write({'state'},changed))
failed.status='applying' failed.attempted=1
assert(not Addon.Transactions.Recover(failed,{rings=a},function() return true end) and failed.status=='recovery-required')
assert(container.Data.Auras[0].name=='Newer edit')
-- Restore exposes per-field newer edits rather than silently replacing them.
local c=Addon.Coordinator.New(account,'B',{rings=b},function() return true end)
currentGUID='B'
local restore=assert(c:BuildRestore(second.id))
assert(#restore.conflicts==1 and restore.conflicts[1].reason=='newer edit')
assert(c:Accept({['B/rings']='keep'}))
assert(container.Data.Auras[0].name=='Newer edit')
local removed=Core.Copy(sharedBefore) assert(Core.Equal(container.Shared,removed))
SESSION_STATE={account=account,live=container.Data,shared=container.Shared}
TEST_SUCCESS=true
