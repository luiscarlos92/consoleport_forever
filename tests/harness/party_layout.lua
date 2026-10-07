-- Native anchor and orientation methods with saved-layout API doubles. No
-- live frames, rendering, combat taint or disk/WTF writes are certified here.
local C=Addon.Core
Enum={EditModeSystem={UnitFrame=20},EditModeUnitFrameSystemIndices={Party=44,Raid=45},
    EditModeUnitFrameSetting={UseHorizontalGroups=87,UseRaidStylePartyFrames=88,RaidGroupDisplayType=89},
    RaidGroupDisplayType={SeparateGroupsHorizontal=2}}
PartyFrame={system=20,systemIndex=44,GetName=function() return 'PartyFrame' end}
CompactRaidFrameContainer={system=20,systemIndex=45,GetName=function() return 'CompactRaidFrameContainer' end}
local contract=assert(Addon.PartyLayout.Contract(_G))
local original={layoutName='User experiments',layoutType=1,systems={
    {system=20,systemIndex=44,isInDefaultPosition=true,
        anchorInfo={point='TOPLEFT',relativeTo='UIParent',relativePoint='TOPLEFT',offsetX=600,offsetY=-150},
        settings={{setting=87,value=1},{setting=88,value=0},{setting=100,value=99}}},
    {system=20,systemIndex=45,isInDefaultPosition=false,
        anchorInfo={point='TOPLEFT',relativeTo='UIParent',relativePoint='TOPLEFT',offsetX=17,offsetY=-72},
        settings={{setting=89,value=2},{setting=101,value=24}}},
    {system=90,systemIndex=1,anchorInfo={point='CENTER',relativeTo='UIParent',relativePoint='CENTER',offsetX=99,offsetY=300},settings={{setting=1,value=73}}},
}}
local state={activeLayout=2,layouts={C.Copy(original),{layoutName='Character extra',layoutType=2,systems={{custom=444}}}}}
local presets={{layoutName='Modern',layoutType=0,systems=C.Copy(original.systems)}}
local combat,editing,rejected=false,false,false
local saves,selections=0,0
local api={AccountType=1,CharacterType=2,partyContract=contract,limit=5,
    presets=function() return C.Copy(presets) end,GetLayouts=function() return C.Copy(state) end,
    inCombat=function() return combat end,isEditing=function() return editing end,
    ConvertLayoutInfoToString=function(layout) return serialized(layout) end,
    SaveLayouts=function(value)
        assert(not combat and not editing) saves=saves+1
        if rejected then return false end
        state={activeLayout=value.activeLayout,layouts={}}
        for i=#presets+1,#value.layouts do state.layouts[#state.layouts+1]=C.Copy(value.layouts[i]) end
    end,SetActiveLayout=function(index) selections=selections+1 state.activeLayout=index end}
local adapter=Addon.EditModeAdapter.New(api)
local before=assert(adapter:Capture())
local managed=assert(adapter:Proposal(before,'CPF managed'))
local proposed=assert(Addon.PartyLayout.Proposal(managed,api))
assert(saves==0 and selections==0 and C.Equal(state.layouts[1],original),'proposal changed active state')
assert(C.Equal(proposed.layouts[1],original) and C.Equal(proposed.layouts[3],state.layouts[2]),'source/character layout changed')
local party,raid=proposed.active.systems[1],proposed.active.systems[2]
assert(party.settings[1].value==0 and party.settings[2].value==1 and party.settings[3].value==99)
assert(party.anchorInfo.point=='TOPLEFT' and party.anchorInfo.relativePoint=='BOTTOMLEFT'
    and party.anchorInfo.relativeTo=='CompactRaidFrameContainer' and party.anchorInfo.offsetX==0 and party.anchorInfo.offsetY==-8)
assert(not party.isInDefaultPosition and not party.anchorInfo2)
assert(C.Equal(raid,original.systems[2]) and C.Equal(proposed.active.systems[3],original.systems[3]),'unrelated screenshot experiments changed')
assert(C.Equal(managed.active.systems[1],original.systems[1]),'managed proposal mutated in place')
-- The existing native managed copy is updated, rather than cloning it again.
assert(adapter:write({'state'},proposed) and saves==1 and selections==1)
local current=adapter:Capture()
assert(adapter:equal(current,proposed))
local reused=assert(adapter:Proposal(current,'CPF managed','CPF managed'))
assert(#reused.layouts==#proposed.layouts)
assert(C.Equal(Addon.PartyLayout.Proposal(reused,api),reused),'party default is not idempotent')
-- Keep the user's active experimental layout when updating an inactive owned
-- copy. A matching unowned display name still cannot be claimed on first install.
state.activeLayout=2
local experimental=adapter:Capture()
local inactive=assert(adapter:Proposal(experimental,'CPF managed','CPF managed'))
local inactiveParty=assert(Addon.PartyLayout.Proposal(inactive,api,'CPF managed'))
assert(inactiveParty.activeLayout==2 and C.Equal(inactiveParty.active,experimental.active)
    and C.Equal(inactiveParty.layouts[1],experimental.layouts[1]) and #inactiveParty.layouts==#experimental.layouts)
assert(not adapter:Proposal(experimental,'CPF managed'),'unowned matching name was claimed')
state.activeLayout=current.activeLayout
-- Execute Blizzard's real anchor application and checkbox interpretation.
EditModeSystemMixin={}
EditModeManagerFrameMixin={}
--@NATIVE_ANCHOR
--@NATIVE_PARTY_ORIENTATION
local anchorCalls={}
EditModeUtil={IsRightAnchoredActionBar=function() return false end,IsBottomAnchoredActionBar=function() return false end}
EditModeManagerFrame={UpdateActionBarLayout=function() end}
local native={systemInfo=party,GetManagedFrameContainer=function() return nil end,
    IsInDefaultPosition=function(self) return self.systemInfo.isInDefaultPosition end,
    ClearAllPoints=function() end,GetScale=function() return 2 end,
    SetPoint=function(_,...) anchorCalls[#anchorCalls+1]={...} end}
EditModeSystemMixin.ApplySystemAnchor(native)
assert(#anchorCalls==1 and anchorCalls[1][1]=='TOPLEFT' and anchorCalls[1][2]=='CompactRaidFrameContainer'
    and anchorCalls[1][3]=='BOTTOMLEFT' and anchorCalls[1][4]==0 and anchorCalls[1][5]==-4,'native scaled anchor disagreed')
local manager={GetSettingValueBool=function(_,system,index,setting)
    assert(system==20 and index==44)
    for _,entry in ipairs(party.settings) do if entry.setting==setting then return entry.value==1 end end
end}
assert(EditModeManagerFrameMixin.ShouldRaidFrameUseHorizontalRaidGroups(manager,44)==false,'native party flow is not vertical')
-- Native compact party remains parented to PartyFrame and keeps game visibility.
local created
local nativeCompact=CompactRaidFrameContainer
CompactPartyFrame=nil
function CreateFrame(kind,name,parent,template)
    created={kind=kind,name=name,parent=parent,template=template,
        RegisterEvent=function(_,event) assert(event=='GROUP_ROSTER_UPDATE') end}
    return created
end
function CompactRaidGroup_UpdateBorder() end
function PartyFrame:UpdatePaddingAndLayout() end
--@NATIVE_COMPACT_GENERATE
assert(CompactPartyFrame_Generate()==created)
assert(created.name=='CompactPartyFrame' and created.parent==PartyFrame and created.template=='CompactPartyFrameTemplate')
CompactRaidFrameContainer=nativeCompact
-- Existing transaction review protects manual edits, defers protected writes,
-- and retains the original managed copy/source layout for restoration.
local account={}
assert(Addon.Store.EnsureSchema(account,'G'))
local coordinator=Addon.Coordinator.New(account,'G',{editmode=adapter},function() return not combat and not editing end)
local old=adapter:Capture()
local changed=C.Copy(proposed)
changed.active.systems[1].anchorInfo.offsetY=-12
changed.export=api.ConvertLayoutInfoToString(changed.active)
local field={id='shared/editmode',scope='editmode',path={'state'},value=C.Encode(changed),revision=13}
coordinator:Build({field},13)
assert(coordinator:Accept({[field.id]='keep'}) and adapter:equal(adapter:Capture(),old))
account.reviews={}
coordinator:Build({field},13) combat=true
assert(not coordinator:Accept({[field.id]='accept'}) and coordinator.queued and adapter:equal(adapter:Capture(),old))
combat=false editing=true assert(not coordinator:Resume()) editing=false
assert(coordinator:Resume())
local journal=coordinator.lastJournal
assert(coordinator:Restore(journal.id) and adapter:equal(adapter:Capture(),old) and account.backups[journal.id])
combat=true assert(not adapter:write({'state'},before)) combat=false
editing=true assert(not adapter:write({'state'},before)) editing=false
rejected=true assert(not adapter:write({'state'},before)) rejected=false
assert(adapter:write({'state'},before) and adapter:equal(adapter:Capture(),before))
-- Missing/ambiguous contracts defer this default, preserving all current data.
local incompatible=C.Copy(managed)
table.remove(incompatible.active.systems,2) table.remove(incompatible.layouts[2].systems,2)
assert(not Addon.PartyLayout.Proposal(incompatible,api))
incompatible=C.Copy(managed)
incompatible.layouts[2].systems[2].anchorInfo.relativeTo='PartyFrame'
assert(not Addon.PartyLayout.Proposal(incompatible,api),'cyclic anchor proposal accepted')
incompatible=C.Copy(managed)
incompatible.layouts[2].systems[#incompatible.layouts[2].systems+1]=C.Copy(incompatible.layouts[2].systems[1])
assert(not Addon.PartyLayout.Proposal(incompatible,api),'duplicate Party record accepted')
api.partyContract=nil assert(not Addon.PartyLayout.Proposal(managed,api)) api.partyContract=contract
PartyFrame.systemIndex=999 assert(not Addon.PartyLayout.Contract(_G)) PartyFrame.systemIndex=44
assert(C.Equal(original,before.layouts[1]) and C.Equal(presets[1].systems,original.systems))
-- Actual runtime field construction offers only the Party-related differences
-- inside the normal managed-copy review, even when controller modes are absent.
local originalProbe=Addon.SecureModes.Probe
Addon.SecureModes.Probe=function() return false,'test main banks unavailable' end
Addon.PROFILE_NAME='CPF managed'
local runtimeAPI={InCombatLockdown=function() return false end,GetCVarDefault=function() return nil end}
local bridge={api={version='3.3.9'},db={},read=function() return {children={}} end}
local fields=Addon.RuntimeSetup.Fields(account,'G',{consoleport=bridge,editmode=adapter,integrationReasons={},
    bindings={read=function() return {keys={},set=2} end,native={api={CharacterSet=2}}}},runtimeAPI,13)
local field
for _,entry in ipairs(fields) do if entry.id=='shared/editmode' then field=entry end end
assert(field and field.label:find('vertical Party Frames',1,true))
local result=C.Decode(field.value)
assert(result.active.systems[1].settings[1].value==0 and result.active.systems[1].settings[2].value==1)
assert(result.active.systems[1].anchorInfo.relativeTo=='CompactRaidFrameContainer')
assert(C.Equal(result.active.systems[2],original.systems[2]) and C.Equal(result.active.systems[3],original.systems[3]))
assert(adapter:equal(adapter:Capture(),before),'runtime proposal performed an unreviewed save')
Addon.SecureModes.Probe=originalProbe
TEST_SUCCESS=true
