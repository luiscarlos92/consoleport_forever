-- Runs through the actual event/bootstrap/planner/prompt/transaction entrypoints.
-- Native frame creation here models template inheritance, not Retail authority.
TEST_SUCCESS=nil
local C=Addon.Core
assert(Addon.CONFIG_REVISION==19,'new Circle update does not have a new review revision')
local originalCreate=CreateFrame
UIParent={}
function SecureActionButton_OnClick() error('startup dispatched protected Circle action') end
C_Macro={RunMacroText=function() error('startup dispatched Circle macro') end}
local macros={}
Constants.MacroConsts={MAX_ACCOUNT_MACROS=120,MAX_CHARACTER_MACROS=30}
function GetMacroInfo(index) local row=macros[index] if row then return row.name,134400,row.body end end
function GetNumMacros() local n=0 for _ in pairs(macros) do n=n+1 end return n,0 end
function CreateMacro(name,icon,body,character)
    assert(not combat and not editing and not character) writes=writes+1
    local index=GetNumMacros()+1 macros[index]={name=name,body=body} fire('UPDATE_MACROS') return index
end
function DeleteMacro(index) assert(not combat and not editing) writes=writes+1 macros[index]=nil fire('UPDATE_MACROS') end
function RunMacro() error('startup dispatched saved macro') end
function SetBindingMacro() error('startup changed native macro binding') end
CreateFrame=function(kind,name,parent,template)
    if name~=Addon.CircleCancel.NAME then return originalCreate(kind,name,parent,template) end
    assert(kind=='Button' and template=='SecureActionButtonTemplate')
    local f={attributes={},scripts={OnClick=SecureActionButton_OnClick}}
    function f:GetScript(key) return self.scripts[key] end
    function f:SetScript() error('startup replaced template-native Circle script') end
    function f:GetAttribute(key) return self.attributes[key] end
    function f:SetAttribute(key,value) assert(not combat and not editing) self.attributes[key]=value end
    function f:SetSize() end
    function f:SetPoint() end
    function f:EnableMouse() end
    function f:RegisterForClicks() end
    _G[name]=f
    return f
end
local function snapshot()
    return C.Copy({banks=banks,set=bindingSet,cvars=cv,settings=db.Settings,layout=bar.Layout,
        edit=editInfo,immersion=ImmersionSetup,fade=IEF_Config,rings=bootstrapRings.Data,sharedRings=bootstrapRings.Shared,macros=macros})
end
local record=ConsolePortForeverDB.characters.A
record.appliedRevision=18 record.declinedRevision=nil record.pendingReload=nil
record.classAccessRepair=1
local before=snapshot() local initialWrites=writes
fire('PLAYER_LOGIN') flush()
assert(shown and shown.name=='CPF_PLAN_REVIEW','revision17 login omitted automatic Circle update review')
assert(Addon:IsCharacterInstalled() and record.appliedRevision==18,'prompt disabled or silently upgraded prior acceptance')
assert(C.Equal(before,snapshot()) and writes==initialWrites,'automatic review replayed accepted bindings/layout/settings/rings')
local active=Addon.Prompt.active
fire('PLAYER_ENTERING_WORLD') flush()
assert(Addon.Prompt.active==active,'duplicate world event replaced active update review')
choose(2) -- Decline: existing configuration remains installed and unchanged.
assert(record.declinedRevision==19 and record.appliedRevision==18 and Addon:IsCharacterInstalled())
fire('PLAYER_ENTERING_WORLD') flush()
assert(not Addon.Prompt.active and C.Equal(before,snapshot()),'declined update repeatedly prompted or mutated old state')
record.declinedRevision=nil
combat=true shown=nil fire('PLAYER_LOGIN') flush()
assert(not Addon.Prompt.active and shown==nil,'automatic update opened in combat')
combat=false fire('PLAYER_REGEN_ENABLED') flush()
assert(shown and shown.name=='CPF_PLAN_REVIEW','deferred combat update review did not resume')
choose(2)
record.declinedRevision=nil editing=true shown=nil fire('PLAYER_LOGIN') flush()
assert(not Addon.Prompt.active and shown==nil,'automatic update opened in Edit Mode')
editing=false fire('EDIT_MODE_LAYOUTS_UPDATED') flush()
assert(shown and shown.name=='CPF_PLAN_REVIEW','deferred Edit Mode review did not resume')
choose(2)
-- Current-revision acceptance suppresses prompts; old cancellation/Keep decisions
-- do not silently accept a new revision. Manual Circle remains authoritative.
record.appliedRevision=19 record.declinedRevision=nil shown=nil
fire('PLAYER_LOGIN') flush()
assert(not Addon.Prompt.active and shown==nil,'accepted revision18 repeated its update prompt')
record.appliedRevision=18 record.declinedRevision=18 shown=nil
banks[2].PAD2='CLICK ManualCircle:LeftButton'
record.controllerBindings.PAD2=nil
ConsolePortForeverDB.shared.faceBindings.PAD2='CLICK ManualCircle:LeftButton'
before=snapshot()
fire('PLAYER_LOGIN') flush()
assert(shown and shown.name=='CPF_PLAN_REVIEW','old decline suppressed newer automatic update')
assert(C.Equal(before,snapshot()),'startup update replaced manual Circle or unrelated configuration')
local field
for _,row in ipairs(Addon.Prompt.active.plan.fields or {}) do if row.id=='A/controller' then field=row end end
-- Validate the actual setup proposal independently of UI rendering.
local fields=Addon.RuntimeSetup.Fields(Addon.db,'A',Addon.adapters,_G,18)
for _,row in ipairs(fields) do if row.id=='A/controller' then field=row end end
assert(field and C.Decode(field.value).keys.PAD2=='CLICK ManualCircle:LeftButton','new revision proposed over manual Circle')
choose(2)
-- Existing candidate31 Circle binding receives the resource repair on the
-- automatic login review, without another binding command or Escape route.
record.appliedRevision=18 record.declinedRevision=nil
banks[2].PAD2=Addon.CircleCancel.BINDING
ConsolePortForeverDB.shared.faceBindings.PAD2=Addon.CircleCancel.BINDING
before=snapshot() initialWrites=writes
fire('PLAYER_LOGIN') flush()
assert(shown and shown.name=='CPF_PLAN_REVIEW','existing Circle route omitted automatic macro repair')
assert(GetNumMacros()==0,'unreviewed macro repair activated')
local offered=false
for _,row in ipairs(Addon.Prompt.active.plan.fields) do if row.id=='shared/circleMacro' then offered=row.requireReview==true end end
assert(offered,'automatic review omitted explicit saved-macro resource decision')
choose(1) flush()
while shown.name=='CPF_FIELD_REVIEW' do choose(1) flush() end
assert(shown.name=='CPF_PLAN_APPLY') choose(1) flush()
assert(record.appliedRevision==19 and GetNumMacros()==1,'accepted automatic repair did not create macro/commit revision19')
assert(GetBindingAction('PAD2')==Addon.CircleCancel.BINDING,'accepted repair did not retain native MACRO binding')
local repaired=snapshot() repaired.macros=before.macros
assert(C.Equal(repaired,before) and writes==initialWrites+1,'macro-only repair replayed bindings/settings/layouts/rings')
-- Synchronous native edit invalidates before the queued review refresh. No
-- auto overwrite/recreation follows deletion or edits.
macros[1].body='/say user edit' fire('UPDATE_MACROS')
assert(Addon.Diagnostics.features.circleCancel.status=='pending','native macro edit failed synchronous resource diagnosis')
flush() assert(macros[1].body=='/say user edit' and GetBindingAction('PAD2')==Addon.CircleCancel.BINDING,'macro refresh overwrote manual edit/binding')
macros[1]=nil fire('UPDATE_MACROS') flush()
assert(GetNumMacros()==0 and Addon.Diagnostics.features.circleCancel.status=='pending','native deletion auto-restored macro')
-- Reproduce the user's accepted revision18 record: valid saved resource and
-- reviewed legacy click binding. Revision19 reviews only native binding change.
record.appliedRevision=18 record.declinedRevision=nil record.pendingReload=nil
macros[1]={name=Addon.CircleCancel.MACRO_NAME,body=Addon.CircleCancel.MACRO}
banks[2].PAD2=Addon.CircleCancel.LEGACY_BINDING
ConsolePortForeverDB.shared.faceBindings.PAD2=Addon.CircleCancel.LEGACY_BINDING
ConsolePortForeverDB.managedFields['A/controller'].value.keys.PAD2=Addon.CircleCancel.LEGACY_BINDING
before=snapshot() initialWrites=writes
fire('PLAYER_LOGIN') flush()
assert(shown and shown.name=='CPF_PLAN_REVIEW','accepted legacy record did not automatically review migration')
local migration
for _,row in ipairs(Addon.Prompt.active.plan.fields) do if row.id=='A/controller' then migration=row end end
assert(migration and migration.requireReview and C.Decode(migration.value).keys.PAD2==Addon.CircleCancel.BINDING,'actual setup omitted reviewed legacy-to-native macro migration')
assert(C.Equal(before,snapshot()) and writes==initialWrites,'migration review changed old accepted state')
choose(1) flush()
while shown.name=='CPF_FIELD_REVIEW' do choose(1) flush() end
assert(shown.name=='CPF_PLAN_APPLY') choose(1) flush()
assert(record.appliedRevision==19 and banks[2].PAD2==Addon.CircleCancel.BINDING,'native binding migration did not commit')
before.banks[2].PAD2=Addon.CircleCancel.BINDING
assert(C.Equal(before,snapshot()) and GetNumMacros()==1 and writes==initialWrites+2,'native binding migration changed macros/other configuration or unsafely saved bindings')
TEST_SUCCESS=true
