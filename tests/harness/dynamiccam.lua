-- Real pinned AceDB, LibStub and CallbackHandler lifecycle, with game API mocks.
function UnitFactionGroup() return 'Alliance' end
function GetLocale() return 'enUS' end
function UnitClass() return 'Mage','MAGE' end
function UnitRace() return 'Human','HUMAN' end
function UnitNameUnmodified() return 'ProfileTester' end
function GetRealmName() return 'Offline' end
function GetCurrentRegionName() return 'US' end
function GetCurrentRegion() return 1 end
strlenutf8=string.len
strmatch=string.match
function securecallfunction(fn,...) return fn(...) end
function CreateFrame()
    return {RegisterEvent=function() end,SetScript=function() end}
end
--@CURRENT_ACEDB
local Core=Addon.Core
local db=LibStub('AceDB-3.0'):New(PERSISTED_STATE and PERSISTED_STATE.sv or {}, {profile={enabled=true,nested={default=9}}},'Original')
if not PERSISTED_STATE then
    db.profile.nested.manual=7
    db.profile.situations={one={enabled=true,executeOnInit='preserved script'}}
end
local originalEffective=Core.Copy(db.profile)
local refreshes=0
local addon={db=db}
function addon:RefreshConfig() refreshes=refreshes+1 end
db.RegisterCallback(addon,'OnProfileChanged','RefreshConfig')
db.RegisterCallback(addon,'OnProfileCopied','RefreshConfig')
local account=PERSISTED_STATE and PERSISTED_STATE.account or {}
assert(Addon.Store.EnsureSchema(account,'A'))
local owned,combat=account.shared.managedDynamicCamProfiles,false
local adapter=Addon.DynamicCamAdapter.New({version='2.21.1',addon=function() return addon end,inCombat=function() return combat end},owned)
--@LIFECYCLE
local name,data=adapter:Proposal('CPF managed')
assert(name=='CPF managed' and Core.Equal(data,originalEffective))
assert(not owned[name] and not db.profiles[name] and refreshes==0,'proposal mutated the native database')
local coordinator=Addon.Coordinator.New(account,'A',{dynamiccam=adapter},function() return not combat end)
-- Mix an existing selection default with new profile ownership; operation vs
-- conflict grouping must not select a profile before its clone is prepared.
account.managedFields.select={value='Original',revision=3}
local fields={{id='copy',scope='dynamiccam',path={'profile',name},value=Core.Encode(data),revision=4},
    {id='select',scope='dynamiccam',path={'selected'},value=name,revision=4}}
coordinator:Build(fields,4)
combat=true assert(not coordinator:Accept({copy='accept',select='accept'})) assert(not owned[name]) combat=false
assert(coordinator:Resume())
local first=coordinator.lastJournal
assert(db:GetCurrentProfile()==name and refreshes==1 and owned[name].created)
assert(Core.Equal(db.profile,originalEffective),'native defaults or situations changed in clone')
SERIALIZED_STATE=serialized({sv=db.sv,account=account})
assert(db.profiles.Original and db.profiles.Original.nested.manual==7,'original profile removed or edited')
local repeatedName,repeatedData=adapter:Proposal('CPF managed')
assert(repeatedName==name and Core.Equal(repeatedData,db.profile))
coordinator:Build(fields,4) assert(coordinator:Accept()) assert(refreshes==1)
-- Manual active edits are retained by proposal, while backup restore reviews them.
db.profile.nested.manual=99
db.profiles.Original.nested.manual=21
local restore=assert(coordinator:BuildRestore(first.id))
local decisions={}
for _,conflict in ipairs(restore.conflicts) do decisions[conflict.id]='accept' end
assert(coordinator:Accept(decisions))
assert(db:GetCurrentProfile()=='Original' and db.profile.nested.manual==21 and refreshes==2)
assert(not db.profiles[name] and first.steps[1].value.situations.one.executeOnInit=='preserved script')
-- Names alone do not confer ownership; versions and namespaces fail locally.
db.profiles[name]={manual=true}
assert(not adapter:Proposal(name))
assert(not adapter:write({'profile',name},{manual=false}))
-- Inject an exception after native selection has already taken effect.
db.profiles[name]=nil
local nextName,nextData=adapter:Proposal('Second managed')
local realSetProfile=db.SetProfile
local reject=true
db.SetProfile=function(self,value)
    realSetProfile(self,value)
    if reject then reject=false error('injected after selection') end
end
local failure=Addon.Coordinator.New(account,'A',{dynamiccam=adapter},function() return true end)
failure:Build({{id='new-copy',scope='dynamiccam',path={'profile',nextName},value=Core.Encode(nextData),revision=4},
    {id='new-select',scope='dynamiccam',path={'selected'},value=nextName,revision=4}},4)
assert(not failure:Accept({['new-copy']='accept',['new-select']='accept'}))
assert(db:GetCurrentProfile()=='Original' and not db.profiles[nextName],'failed selection did not compensate')
assert(failure.lastJournal.status=='rolled-back' and owned[nextName].removed)
db.SetProfile=realSetProfile
adapter.api.version='new unqualified' assert(not adapter:Probe()) adapter.api.version='2.21.1'
db:RegisterNamespace('Other',{profile={a=1}}) assert(not adapter:Probe())
-- Qualify explicit-default expansion against the actual Retail profile template.
local defaultsAddon={projectId=1,WOW_PROJECT_FOREVER='forever'}
WOW_PROJECT_MAINLINE=1
LibStub:NewLibrary('AceAddon-3.0',999).GetAddon=function() return defaultsAddon end
LibStub:NewLibrary('AceLocale-3.0',999).GetLocale=function() return setmetatable({},{__index=function(_,key) return key end}) end
function GetCVarDefault() return '1' end
--@CURRENT_DYNAMIC_DEFAULTS
local realisticDB=LibStub('AceDB-3.0'):New({},defaultsAddon.defaults,'Current')
realisticDB.profile.standardSettings.cvars.cameraZoomSpeed=42
realisticDB.profile.situations['100'].executeOnInit='my custom script'
local realisticAddon={db=realisticDB,RefreshConfig=function() end}
local realisticOwned={}
local realisticAdapter=Addon.DynamicCamAdapter.New({version='2.21.1',addon=function() return realisticAddon end,inCombat=function() return false end},realisticOwned)
local realisticName,realisticData=realisticAdapter:Proposal('Realistic managed')
assert(realisticName and realisticData.standardSettings.cvars.cameraZoomSpeed==42)
assert(realisticAdapter:write({'profile',realisticName},realisticData))
assert(realisticAdapter:write({'selected'},realisticName))
assert(Core.Equal(realisticAdapter:read({'profile',realisticName}),realisticData))
assert(realisticAdapter:write({'selected'},'Current'))
assert(Core.Equal(realisticAdapter:read({'profile',realisticName}),realisticData),'native default removal broke detached profile readback')
assert(realisticDB.profile.situations['100'].executeOnInit=='my custom script')
-- Unsupported future wildcard schemas must preserve the current integration.
realisticDB.defaults.profile.future={['*']=true}
assert(not realisticAdapter:Probe())
TEST_SUCCESS=true
