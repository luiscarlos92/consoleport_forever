local _, Addon = ...
local Core, Setup = Addon.Core, {}
Addon.RuntimeSetup = Setup
function Setup.Adapters(api,account)
    local native=Addon.NativeBindings.New({GetCurrentBindingSet=api.GetCurrentBindingSet,
        GetNumBindings=api.GetNumBindings,GetBinding=api.GetBinding,GetBindingAction=api.GetBindingAction,
        SetBinding=api.SetBinding,LoadBindings=api.LoadBindings,InCombatLockdown=api.InCombatLockdown,
        SaveBindings=api.CPAPI.SaveBindings,GetBindingContextForAction=api.CPAPI.GetBindingContextForAction,
        AccountSet=api.Enum.BindingSet.Account,CharacterSet=api.Enum.BindingSet.Character})
    local current=native:Capture()
    if not current then return nil,"bindings not initialized" end
    local mask={}
    for key,command in pairs(Addon.ReferenceBindings) do
        if Addon.BindingPolicy.Scope(key)~="retained" or command~="" then mask[key]=true end
    end
    local cp=Addon.ConsolePortAdapter.New({version=api.C_AddOns.GetAddOnMetadata("ConsolePort","Version"),
        inCombat=api.InCombatLockdown,getDB=function() return api.ConsolePort:GetData() end,
        getBar=function()
            local lib=api.LibStub("RelaTable",true)
            return lib and rawget(lib,"ConsolePort_Bar")
        end})
    if not cp:Probe() then return nil,"ConsolePort settings/bar data not initialized" end
    local adapters={bindings=Addon.BindingStateAdapter.New(native,mask),consoleport=cp}
    if account and Addon.guid then
        local record=assert(Addon.Store.GetCharacter(account,Addon.guid))
        local previousBusy
        adapters.bindingBanks=Addon.BindingBanksAdapter.New(native,record,function() return not api.InCombatLockdown() and not (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown()) end,function(active)
            if active then previousBusy=Addon.busy Addon.busy=true else Addon.busy=previousBusy end
        end)
        adapters.bindings.record=record
        adapters.bindings.bankInspector=adapters.bindingBanks
        adapters.bindings.canWrite=adapters.bindingBanks.canWrite
    end
    if account then adapters.policy=Addon.FlatConfigAdapter.New(function() return account.shared.runtimePolicy end,{modesEnabled=true,focusVisuals=true,uiContextsEnabled=true},api.InCombatLockdown) end
    if api.C_EditMode and api.EditModePresetLayoutManager then
        adapters.editmode=Addon.EditModeAdapter.New({GetLayouts=api.C_EditMode.GetLayouts,
            SaveLayouts=api.C_EditMode.SaveLayouts,SetActiveLayout=api.C_EditMode.SetActiveLayout,
            ConvertLayoutInfoToString=api.C_EditMode.ConvertLayoutInfoToString,
            presets=function() return api.EditModePresetLayoutManager:GetCopyOfPresetLayouts() end,
            AccountType=api.Enum.EditModeLayoutType.Account,CharacterType=api.Enum.EditModeLayoutType.Character,
            limit=api.Constants and api.Constants.EditModeConsts and api.Constants.EditModeConsts.EditModeMaxLayoutsPerType,
            inCombat=api.InCombatLockdown,isEditing=function() return api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown() end})
    end
    adapters.cvars={read=function(_,p) return api.GetCVar(p[1]) end,
        write=function(_,p,value)
            if api.InCombatLockdown() or api.GetCVarDefault(p[1])==nil then return false end
            api.SetCVar(p[1],value)
            return api.GetCVar(p[1])==tostring(value)
        end}
    local immersionFields={scale=true,boxoffsetX=true,boxoffsetY=true,boxpoint=true,boxscale=true,
        titleoffset=true,titleoffsetY=true,titlescale=true,elementscale=true,immersivemode=true}
    if type(api.ImmersionSetup)=="table" then adapters.immersion=Addon.FlatConfigAdapter.New(function() return api.ImmersionSetup end,immersionFields,api.InCombatLockdown) end
    if type(api.IEF_Config)=="table" then
        local allowed={}
        for key in pairs(api.IEF_Config) do allowed[key]=true end
        adapters.extrafade=Addon.FlatConfigAdapter.New(function() return api.IEF_Config end,allowed,api.InCombatLockdown)
    end
    return adapters
end
function Setup.BindingProposal(db,guid,adapter,reference)
    local state=adapter:read({"state"})
    local split=Addon.BindingPolicy.Split(state.keys)
    local record=assert(Addon.Store.GetCharacter(db,guid))
    local shared=next(db.shared.faceBindings) and db.shared.faceBindings or split.shared
    local personal=next(record.controllerBindings) and record.controllerBindings or split.character
    if not next(record.controllerBindings) and db.lastProjectedGUID and db.lastProjectedGUID~=guid then
        personal=Addon.BindingPolicy.Split(reference).character
    end
    state.keys=Addon.BindingPolicy.Compose(shared,personal,split.retained)
    state.set=adapter.native.api.CharacterSet
    return state
end
function Setup.Fields(db,guid,adapters,api,revision)
    local fields,deferred={},{}
    local function add(id,scope,path,value,label)
        fields[#fields+1]={id=id,scope=scope,path=path,value=Core.Encode(value),revision=revision,label=label}
    end
    add(guid.."/controller","bindings",{"state"},Setup.BindingProposal(db,guid,adapters.bindings,Addon.ReferenceBindings),"Character controller arrangement and preserved keyboard bindings")
    add("shared/consoleport/condition","consoleport",{"settings","bindingPresetCondition"},"","Disable the old automatic preset loader")
    local layout=adapters.consoleport:read({"layout"})
    local modeReady,modeReason=Addon.SecureModes.Probe(adapters.consoleport,api)
    if modeReady and adapters.policy then
        add("shared/consoleport/layout","consoleport",{"layout"},Addon.SecureModes.LayoutProposal(layout),"Keep current geometry; route temporary actions through L2R2")
        add("shared/policy/modesEnabled","policy",{"modesEnabled"},true,"Enable eight temporary L2R2 cells with retained native exit and overflow routes")
    else
        add("shared/consoleport/layout","consoleport",{"layout"},layout,"Current ConsolePort geometry")
        deferred[#deferred+1]={id="secureModes",reason=modeReason or "mode policy unavailable"}
    end
    if Addon.FocusVisuals:Probe(adapters.consoleport,api) and adapters.policy then
        add("shared/policy/focusVisuals","policy",{"focusVisuals"},true,"Suppress gameplay icons and highlights while the interface cursor owns input")
    else deferred[#deferred+1]={id="focusVisuals",reason="native interface cursor not initialized"} end
    local contextReady,contextReason=Addon.UIContexts:Probe(adapters.consoleport,api)
    if contextReady and adapters.policy then
        add("shared/policy/uiContextsEnabled","policy",{"uiContextsEnabled"},true,"Use native semantic popup/quantity controls; retain parent and keyboard owners")
    else deferred[#deferred+1]={id="uiContexts",reason=contextReason} end
    for cvar,value in pairs({GamePadEmulateShift="PADLTRIGGER",GamePadEmulateCtrl="PADRTRIGGER"}) do
        if api.GetCVarDefault(cvar)~=nil then add("shared/cvar/"..cvar,"cvars",{cvar},value,"Controller trigger modifier: "..cvar)
        else deferred[#deferred+1]={id=cvar,reason="registered Retail CVar unavailable"} end
    end
    if adapters.editmode then
        local snapshot,reason=adapters.editmode:Capture()
        if snapshot then
            local proposal,error=adapters.editmode:Proposal(snapshot,Addon.PROFILE_NAME,db.shared.managedEditModeName)
            if proposal then add("shared/editmode","editmode",{"state"},proposal,"Managed copy of your active Edit Mode layout")
            else deferred[#deferred+1]={id="editmode",reason=error} end
        else deferred[#deferred+1]={id="editmode",reason=reason} end
    else deferred[#deferred+1]={id="editmode",reason="Blizzard Edit Mode is not initialized"} end
    for scope,tableValue in pairs({immersion=api.ImmersionSetup,extrafade=api.IEF_Config}) do
        if adapters[scope] then
            for key in pairs(adapters[scope].allowed) do
                add("shared/"..scope.."/"..key,scope,{key},tableValue[key],"Preserve "..scope.." "..key)
            end
        else deferred[#deferred+1]={id=scope,reason="optional integration not initialized"} end
    end
    table.sort(fields,function(a,b) return a.id<b.id end)
    return fields,deferred
end
