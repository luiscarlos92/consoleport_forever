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
        local rings=cp.db.Rings
        local classSet
        if rings and rings.GetSetForBindingSuffix and rings.GetName then
            local currentClass=native.api.GetBindingAction('CTRL-PADFORWARD')
            local name,suffix=currentClass:match('^CLICK ([^:]+):(.+)$')
            if name==rings:GetName() then classSet=rings:GetSetForBindingSuffix(suffix) end
        end
        adapters.rings=Addon.RingsAdapter.New({version=api.C_AddOns.GetAddOnMetadata('ConsolePort_Rings','Version'),
            getDB=function() return cp.db end,getEnv=function()
                local lib=api.LibStub('RelaTable',true)
                return lib and rawget(lib,'ConsolePort_Rings')
            end,inCombat=api.InCombatLockdown,currentGUID=function() return api.UnitGUID('player') end,
            defaultSet=api.CPAPI.DefaultRingSetID,classSet=classSet},account,Addon.guid)
    end
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
    if account then adapters.policy=Addon.FlatConfigAdapter.New(function() return account.shared.runtimePolicy end,{modesEnabled=true,focusVisuals=true,uiContextsEnabled=true,windowsEnabled=true,bagsEnabled=true},api.InCombatLockdown) end
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
    adapters.integrationReasons={}
    for _,kind in ipairs({'immersion','extrafade'}) do
        adapters[kind],adapters.integrationReasons[kind]=Addon.FlatIntegrations.New(kind,api)
    end
    if account and api.DynamicCam then
        adapters.dynamiccam=Addon.DynamicCamAdapter.New({addon=function() return api.DynamicCam end,
            version=api.C_AddOns.GetAddOnMetadata('DynamicCam','Version'),inCombat=api.InCombatLockdown},account.shared.managedDynamicCamProfiles)
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
    if adapters.rings then
        local state,reason=adapters.rings:Proposal()
        if state then
            add(guid..'/rings','rings',{'state'},state,'Keep personal ring contents and manual order in this character GUID; native utility extras remain automatic')
            fields[#fields].requireReview=db.shared.ringProjectionGUID~=guid
        else deferred[#deferred+1]={id='rings',reason=reason} end
    end
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
    if contextReady and Addon.UIWindows.CanUse(adapters.consoleport.db) and adapters.policy then
        add('shared/policy/windowsEnabled','policy',{'windowsEnabled'},true,'Use registered-window triggers, native tabs, audited right-stick scrolling and focused tooltips; popup and quantity keep priority')
    else deferred[#deferred+1]={id='windows',reason='audited native cursor/stack/input window bridge unavailable'} end
    local bagReady,bagReason=Addon.BetterBagsAdapter.New(adapters.consoleport.db,api):Probe()
    if contextReady and Addon.UIWindows.CanUse(adapters.consoleport.db) and bagReady and adapters.policy then
        add('shared/policy/bagsEnabled','policy',{'bagsEnabled'},true,'Guard native BetterBags item clicks by current item identity; clear a carried item before Back closes the bag')
    else deferred[#deferred+1]={id='bags',reason=bagReason or 'native window context unavailable'} end
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
    for _,scope in ipairs({'immersion','extrafade'}) do
        if adapters[scope] then
            for key in pairs(adapters[scope].allowed) do
                local readable,value=pcall(adapters[scope].read,adapters[scope],{key})
                if readable then add("shared/"..scope.."/"..key,scope,{key},value,"Preserve "..scope.." "..key)
                else deferred[#deferred+1]={id=scope..'/'..key,reason=tostring(value)} end
            end
            for _,reason in ipairs(adapters[scope].pending or {}) do deferred[#deferred+1]={id=scope,reason=reason} end
        else deferred[#deferred+1]={id=scope,reason=adapters.integrationReasons and adapters.integrationReasons[scope] or "optional integration not initialized"} end
    end
    if adapters.dynamiccam then
        local name,profile=adapters.dynamiccam:Proposal(Addon.PROFILE_NAME)
        if name then
            add('shared/dynamiccam/1-profile','dynamiccam',{'profile',name},profile,'Managed copy of your current DynamicCam settings and situations')
            add('shared/dynamiccam/2-selected','dynamiccam',{'selected'},name,'Select the managed DynamicCam copy through its native profile lifecycle')
        else deferred[#deferred+1]={id='dynamiccam',reason=profile} end
    else deferred[#deferred+1]={id='dynamiccam',reason='optional DynamicCam not initialized'} end
    table.sort(fields,function(a,b) return a.id<b.id end)
    return fields,deferred
end
