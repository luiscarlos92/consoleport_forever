local queue,frames,messages={}, {}, {}
local fire
local guid,combat,editing,bindingSet="A",false,false,0
local writes,reloads=0,0
local banks={[1]={SPACE="JUMP",PAD1="JUMP",PAD2="",PAD3="INTERACTTARGET",PAD4="TURNORACTION"},[2]={K="OTHER",PAD1="OLD"}}
local cv={GamePadEmulateShift="PADLTRIGGER",GamePadEmulateCtrl="PADRTRIGGER"}
local db={Settings={bindingPresetCondition="[] old"},Layers={}}
function db:Get(p) return self.Settings[p:match("Settings/(.+)")] end
function db:Set(p,v) assert(not combat) writes=writes+1 self.Settings[p:match("Settings/(.+)")]=v return true end
local bar={Layout={name="actual runtime layout",children={}},Manager={hasEnvironment=true}}
function bar:ApplyPreset(v) assert(not combat) writes=writes+1 self.Layout=v end
local presets={{layoutName="Modern",layoutType=0,systems={{x=1}}}}
local editInfo={activeLayout=2,layouts={{layoutName="Actual runtime profile",layoutType=1,systems={{x=999}}}}}
if SESSION_STATE then
    ConsolePortForeverDB=SESSION_STATE.account
    banks,bindingSet,cv,editInfo=SESSION_STATE.banks,SESSION_STATE.bindingSet,SESSION_STATE.cvars,SESSION_STATE.editInfo
    db.Settings=SESSION_STATE.settings
end
local shown
local modules={ConsolePort=true,ConsolePort_Bar=true,ConsolePort_Menu=true,ConsolePort_Config=true,ConsolePort_Cursor=true,ConsolePort_Rings=true,Immersion=true,Immersion_ExtraFade=true,Blizzard_EditMode=true,ConsolePort_Forever=true}
Enum={BindingSet={Account=1,Character=2},EditModeLayoutType={Account=1,Character=2}}
C_AddOns={GetAddOnMetadata=function(name,key) if name=="ConsolePort_Rings" then return nil elseif name=="ConsolePort" then return "3.3.9" elseif name=='Immersion' then return '1.4.61' elseif name=='Immersion_ExtraFade' then return '1.18.0' end return "2.0.0-dev" end,
    GetAddOnInfo=function(name) return (name=='DBM-Core' or modules[name]) and name or nil end,
    IsAddOnLoaded=function(name) return modules[name] or false end,
    GetAddOnEnableState=function(name,character) assert(character=="Player") return modules[name] and 2 or 0 end,
    EnableAddOn=function() error('disabled addon must remain game/user owned') end,
    LoadAddOn=function(name) assert(name=="Blizzard_EditMode" and not combat) modules[name]=true return true end}
function GetBuildInfo() return "12.1.0","69933","date",120100 end
function UnitGUID() return guid end
function UnitName() return "Player" end
function GetRealmName() return "Realm" end
function InCombatLockdown() return combat end
function GetCurrentBindingSet() return bindingSet end
function LoadBindings(v) assert(not combat) writes=writes+1 bindingSet=v if fire then fire("UPDATE_BINDINGS") end end
function GetNumBindings() local n=0 for _,v in pairs(banks[bindingSet] or {}) do if v~="" then n=n+1 end end return n end
function GetBinding(i) local n=0 for k,v in pairs(banks[bindingSet] or {}) do if v~="" then n=n+1 if n==i then return v,"category",k end end end end
function GetBindingAction(k,effective) return (banks[bindingSet] or {})[k] or "" end
function SetBinding(k,v) assert(not combat) writes=writes+1 banks[bindingSet][k]=v if fire then fire("UPDATE_BINDINGS") end return true end
function GetCVar(k) return cv[k] end
function GetCVarDefault(k) return cv[k] end
function SetCVar(k,v) assert(not combat) writes=writes+1 cv[k]=v end
CPAPI={SaveBindings=function(v) assert(not combat and v==bindingSet and (v==1 or v==2)) writes=writes+1 return true end}
ConsolePort={GetData=function() return db end}
function LibStub(name,silent) assert(name=="RelaTable") return {ConsolePort_Bar=bar} end
EditModePresetLayoutManager={GetCopyOfPresetLayouts=function() return presets end}
EditModeManagerFrame={IsShown=function() return editing end}
Constants={EditModeConsts={EditModeMaxLayoutsPerType=5}}
C_EditMode={GetLayouts=function() return editInfo end,
    ConvertLayoutInfoToString=function(p) return p.layoutName..":"..p.systems[1].x end,
    SaveLayouts=function(info)
        assert(not combat and not editing) writes=writes+1
        editInfo={activeLayout=info.activeLayout,layouts={}}
        for i=2,#info.layouts do editInfo.layouts[#editInfo.layouts+1]=info.layouts[i] end
    end,
    SetActiveLayout=function(v) assert(not combat) writes=writes+1 editInfo.activeLayout=v end}
ImmersionSetup={scale=1.2,boxoffsetX=0,boxoffsetY=150,boxpoint="Bottom",manual="preserve"}
IEF_Config={hideFrameRateCinematic=true,UIParentAlpha=0}
if SESSION_STATE then ImmersionSetup,IEF_Config=SESSION_STATE.immersion,SESSION_STATE.extrafade end
C_Timer={After=function(delay,callback) assert(delay==0 or delay==1) queue[#queue+1]=callback end}
DEFAULT_CHAT_FRAME={AddMessage=function(_,msg) messages[#messages+1]=msg end}
StaticPopupDialogs,SlashCmdList={},{}
function StaticPopup_Show(name,text,arg,data) assert(StaticPopupDialogs[name]) shown={name=name,text=text,data=data} return shown end
function ReloadUI() reloads=reloads+1 end
function CreateFrame(kind,name,parent,template)
    assert(kind=="Frame" and name==nil and parent==nil and template==nil)
    local frame={events={}}
    function frame:RegisterEvent(event) self.events[event]=true end
    function frame:SetScript(script,fn) assert(script=="OnEvent") self.event=fn end
    frames[#frames+1]=frame
    return frame
end
fire=function(event)
    for _,frame in ipairs(frames) do if frame.events[event] then frame.event(frame,event) end end
end
local function flush()
    local iterations=0
    while #queue>0 do
        iterations=iterations+1 assert(iterations<100,"timer loop")
        table.remove(queue,1)()
    end
end
local function choose(button)
    local dialog=shown
    local info=StaticPopupDialogs[dialog.name]
    local fn=info["OnButton"..button] or (button==1 and info.OnAccept or button==2 and info.OnCancel or info.OnAlt)
    if fn then fn(nil,dialog.data,"clicked") else assert(button==2 and dialog.name=="CPF_RELOAD","unknown popup callback: "..dialog.name) end
    if info.OnHide then info.OnHide(nil,dialog.data) end
end
--@LOAD_PRODUCT
--@NATIVE_RING_BOOTSTRAP
--@LIFECYCLE
assert(writes==0 and ConsolePortForeverDB==nil and db.Settings.bindingPresetCondition=="[] old")
fire("PLAYER_LOGIN") flush()
assert(writes==0 and shown==nil and Addon.Diagnostics.features.configuration.status=="pending")
bindingSet=1
fire("UPDATE_BINDINGS") flush()
assert(writes==0 and shown.name=="CPF_PLAN_REVIEW" and db.Settings.bindingPresetCondition=="[] old")
choose(2)
assert(writes==0 and not Addon.Prompt.active)
SlashCmdList.CONSOLEPORTFOREVER("install")
choose(1) flush()
while shown.name=="CPF_FIELD_REVIEW" do choose(1) flush() end
assert(shown.name=="CPF_PLAN_APPLY" and writes==0)
combat=true
choose(1)
assert(writes==0 and Addon.coordinator.queued)
combat=false
fire("PLAYER_REGEN_ENABLED") flush()
assert(Addon:IsCharacterInstalled(),Addon.Diagnostics:Summary())
assert(Addon.record.ringAccepted and Addon.db.shared.ringProjectionGUID=='A')
assert(bootstrapRings.Data.Auras[1].spell==101 and Addon.record.rings.sets.Auras[1].spell==101)
assert(bindingSet==2 and banks[2].SPACE=="JUMP" and banks[2].K==nil and banks[2].PAD1=="JUMP")
assert(db.Settings.bindingPresetCondition=="" and bar.Layout.name=="actual runtime layout")
assert(ImmersionSetup.scale==1.2 and ImmersionSetup.manual=="preserve")
assert(#editInfo.layouts==2 and editInfo.layouts[1].layoutName=="Actual runtime profile")
assert(editInfo.layouts[2].systems[1].x==999 and shown.name=="CPF_RELOAD")
assert(reloads==0)
choose(2) -- later must not call ReloadUI
assert(reloads==0)
-- A new revision offers review while the previously accepted feature scope
-- remains active. Declining the update must not disable that older scope.
local currentRevision=Addon.CONFIG_REVISION
Addon.record.appliedRevision=currentRevision-1
Addon.record.declinedRevision=nil
Addon:ShowPrompt(false)
assert(shown.name=='CPF_PLAN_REVIEW' and Addon:IsCharacterInstalled())
choose(2) assert(Addon:IsCharacterInstalled())
Addon.record.appliedRevision=currentRevision
local beforeRepeated=writes
fire("PLAYER_ENTERING_WORLD") flush()
assert(writes==beforeRepeated,"repeated login reapplied preset")
assert(Addon.record.pendingReload~=nil,"world-entry incorrectly certified a reload")
SESSION_STATE=Addon.Core.Copy({account=ConsolePortForeverDB,banks=banks,bindingSet=bindingSet,cvars=cv,settings=db.Settings,editInfo=editInfo,immersion=ImmersionSetup,extrafade=IEF_Config,rings=bootstrapRings.Data,sharedRings=bootstrapRings.Shared})
bootstrapRings.Data.Auras[0].name='A manual after acceptance'
bootstrapRings:RefreshAll()
assert(Addon.record.rings.sets.Auras[0].name=='A manual after acceptance','native hook failed to capture outgoing ring edit')
banks[2]["SHIFT-PAD1"]="ACTIONBUTTON7"
fire("UPDATE_BINDINGS") flush()
assert(Addon.record.controllerBindings["SHIFT-PAD1"]=="ACTIONBUTTON7")
fire("PLAYER_LOGOUT")
guid="B"
fire("PLAYER_LOGIN") flush()
assert(Addon.record.appliedRevision==0 and shown.name=="CPF_PLAN_REVIEW")
assert(Addon.record.controllerBindings["SHIFT-PAD1"]==nil,"B inherited A's personal arrangement")
assert(not Addon.record.ringAccepted and Addon.record.rings.sets==nil,'B inherited A ring acceptance/archive')
choose(2)
guid="A"
fire("PLAYER_LOGIN") flush()
assert(Addon.record.controllerBindings["SHIFT-PAD1"]=="ACTIONBUTTON7")
assert(Addon.record.rings.sets.Auras[0].name=='A manual after acceptance')
local beforeRestore=writes
SlashCmdList.CONSOLEPORTFOREVER("restore")
assert(shown.name=="CPF_BINDING_INSPECT" and writes==beforeRestore)
choose(2) flush()
assert(writes==beforeRestore and not Addon.Prompt.active and bindingSet==2)
local priorBanks=Addon.Core.Copy(banks)
local owned=Addon.Core.Copy(Addon.record.controllerBindings)
SlashCmdList.CONSOLEPORTFOREVER("restore") choose(1) flush()
assert(shown.name=="CPF_PLAN_REVIEW" and bindingSet==2 and Addon.Core.Equal(banks,priorBanks))
assert(Addon.Core.Equal(Addon.record.controllerBindings,owned),"temporary bank inspection captured the other bank as this character's edits")
choose(1) flush()
while shown.name=="CPF_FIELD_REVIEW" do choose(1) flush() end
local beforeApply=writes
combat=true choose(1)
assert(writes==beforeApply and Addon.coordinator.queued and bindingSet==2)
combat=false fire("PLAYER_REGEN_ENABLED") flush()
assert(bindingSet==1 and Addon.record.appliedRevision==0 and not Addon.record.bindingAccepted and shown.name=="CPF_RELOAD")
assert(not Addon.record.ringAccepted and Addon.db.shared.ringProjectionGUID==nil)
assert(banks[2].K=="OTHER" and banks[2].PAD1=="OLD" and banks[1].SPACE=="JUMP")
RESTORED_SESSION_STATE=Addon.Core.Copy({account=ConsolePortForeverDB,banks=banks,bindingSet=bindingSet,cvars=cv,settings=db.Settings,editInfo=editInfo,immersion=ImmersionSetup,extrafade=IEF_Config,rings=bootstrapRings.Data,sharedRings=bootstrapRings.Shared})
local statusWrites=writes
local statusMessages=#messages
SlashCmdList.CONSOLEPORTFOREVER('status')
local statusText=table.concat(messages,'\n',statusMessages+1)
assert(statusText:find('ConsolePort: 3.3.9',1,true),'status omits exact native dependency version')
assert(statusText:find('Runtime journals retained:',1,true),'status omits retained restore identities')
assert(writes==statusWrites,'status changed runtime configuration')
TEST_SUCCESS=true
