local C=Addon.Core
local combat,editing,saves,selections=false,false,0,0
local name='Console Port - Forever (Managed)'
local managed={layoutName=name,layoutType=0,systems={{system=17,systemIndex=-1,anchorInfo={offsetX=12,offsetY=-43},
    settings={{setting=1,value=75}}},{system=3,systemIndex=3,anchorInfo={offsetY=-25},settings={{setting=1,value=1}}},
    {system=999,systemIndex=9,newNativeField='preserved',anchorInfo={offsetY=91}}}}
local alternative={layoutName='User experiment',layoutType=0,systems={{system=17,systemIndex=-1,anchorInfo={offsetY=-123}}}}
local info={activeLayout=3,layouts={managed,alternative}}
local presets={{layoutName='Modern',systems={}},{layoutName='Classic',systems={}}}
local queue,hide={},nil
local api={InCombatLockdown=function() return combat end,C_Timer={After=function(_,callback) queue[#queue+1]=callback end},
    EditModeManagerFrame={IsShown=function() return editing end,HookScript=function(_,key,callback) assert(key=='OnHide') hide=callback end}}
local native={presets=function() return C.Copy(presets) end,GetLayouts=function() return C.Copy(info) end,
    ConvertLayoutInfoToString=function(layout) return serialized(layout) end,AccountType=0,CharacterType=1,
    inCombat=api.InCombatLockdown,isEditing=function() return editing end,
    SaveLayouts=function() saves=saves+1 error('reference tracking saved native layout') end,
    SetActiveLayout=function() selections=selections+1 error('reference tracking changed selection') end}
local adapter=Addon.EditModeAdapter.New(native)
local db=assert(Addon.Store.EnsureSchema({},'A'))
local record=assert(Addon.Store.GetCharacter(db,'A')); record.appliedRevision=17
db.shared.managedEditModeName=name
db.managedFields['shared/editmode']={value='old accepted transaction; do not rewrite',revision=17}
local owner={db=db,record=record,adapters={editmode=adapter}}
function owner:IsCharacterInstalled() return self.record.appliedRevision>0 end
local tracker=Addon.EditModeReference
assert(tracker:Refresh(owner,api))
assert(C.Equal(db.shared.knownEditModeDefault.layout,managed) and C.Equal(record.knownEditModeActive.layout,managed))
assert(db.shared.knownEditModeDefault.source=='native-saved-layout')
assert(db.managedFields['shared/editmode'].value=='old accepted transaction; do not rewrite')
local reference=db.shared.knownEditModeDefault
assert(tracker:Refresh(owner,api) and reference==db.shared.knownEditModeDefault,'unchanged layout recaptured on every refresh')
local before=C.Copy(info)
editing=true managed.systems[1].anchorInfo.offsetY=-202
assert(not tracker:Refresh(owner,api) and reference==db.shared.knownEditModeDefault,'unsaved Edit Mode view captured')
editing=false hide() assert(#queue==1) table.remove(queue,1)()
assert(db.shared.knownEditModeDefault.layout.systems[1].anchorInfo.offsetY==-202)
assert(C.Equal(info.layouts[1].systems[3],before.layouts[1].systems[3]),'new native system dropped')
combat=true managed.systems[1].anchorInfo.offsetY=-250
assert(not tracker:Refresh(owner,api)) combat=false assert(tracker:Refresh(owner,api))
assert(db.shared.knownEditModeDefault.layout.systems[1].anchorInfo.offsetY==-250)
-- Another active layout/character remains active without replacing the owned
-- account reference or inheriting the previous character's selection.
local b=assert(Addon.Store.GetCharacter(db,'B')); b.appliedRevision=17 owner.record=b
info.activeLayout=4 assert(tracker:Refresh(owner,api))
assert(b.knownEditModeActive.layout.layoutName=='User experiment')
assert(record.knownEditModeActive.layout.layoutName==name and db.shared.knownEditModeDefault.layout.layoutName==name)
assert(info.activeLayout==4 and saves==0 and selections==0)
local missing=owner.adapters.editmode owner.adapters.editmode=nil
assert(not tracker:Refresh(owner,api)) owner.adapters.editmode=missing
-- Existing owned copies preserve all saved manual edits in a normal installer
-- review, including Party configuration. Only creating a new copy offers defaults.
local originalProbe,originalParty=Addon.SecureModes.Probe,Addon.PartyLayout.Proposal
Addon.SecureModes.Probe=function() return false,'not needed' end
Addon.PartyLayout.Proposal=function() error('manual Party edit reset') end
Addon.PROFILE_NAME=name Addon.guid='B'
local bridge={api={version='3.3.10'},db={},read=function() return {children={}} end}
local fields=Addon.RuntimeSetup.Fields(db,'B',{consoleport=bridge,editmode=adapter,integrationReasons={},
    bindings={read=function() return {keys={},set=2} end,native={api={CharacterSet=2}}}},
    {GetCVarDefault=function() return nil end},17)
local field
for _,candidate in ipairs(fields) do if candidate.id=='shared/editmode' then field=candidate end end
assert(field and adapter:equal(adapter:Capture(),C.Decode(field.value)),'known default proposal overwrote saved player geometry')
assert(saves==0 and selections==0 and info.activeLayout==4)
Addon.SecureModes.Probe,Addon.PartyLayout.Proposal=originalProbe,originalParty
-- Packaged reference is an inert fallback: never an import or saved layout.
db.shared.knownEditModeDefault=nil db.shared.managedEditModeName=nil owner.adapters.editmode=nil
assert(not tracker:Refresh(owner,api))
assert(C.Equal(db.shared.knownEditModeDefault,Addon.SavedEditModeReference))
assert(db.shared.knownEditModeDefault.layoutName==name and db.shared.knownEditModeDefault.export:find(' 52 ',1,true))
assert(saves==0 and selections==0)
TEST_SUCCESS=true
