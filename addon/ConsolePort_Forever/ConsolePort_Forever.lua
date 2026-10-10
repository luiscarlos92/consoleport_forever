local ADDON_NAME, Addon = ...
Addon.VERSION=C_AddOns.GetAddOnMetadata(ADDON_NAME,"Version") or "0.0.0"
Addon.SCHEMA=Addon.Store.VERSION
Addon.CONFIG_REVISION=17
-- Native recovery retains ConsolePort bindings, modes and UI ownership.
-- Ground placement is a separate secure click adapter; it does not page actions.
Addon.NATIVE_INPUT_RECOVERY=true
Addon.PROFILE_NAME="Console Port - Forever (Managed)"
local function Print(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0ConsolePort Forever:|r "..tostring(message)) end
end
local function CanWrite()
    return not InCombatLockdown() and not (EditModeManagerFrame and EditModeManagerFrame:IsShown())
end
function Addon:IsCharacterInstalled()
    return self.record and self.record.appliedRevision>0 or false
end
function Addon:InitializeStore()
    local guid=UnitGUID("player")
    if not guid then return false,"player GUID unavailable" end
    ConsolePortForeverDB=ConsolePortForeverDB or {}
    local db,reason=self.Store.EnsureSchema(ConsolePortForeverDB,guid,ConsolePortForeverCharacterDB)
    if not db then return false,reason end
    local record,error=self.Store.GetCharacter(db,guid,{name=UnitName("player"),realm=GetRealmName()})
    if not record then return false,error end
    self.db,self.guid,self.record=db,guid,record
    record.requiredRevision=self.CONFIG_REVISION
    return true
end
function Addon:CaptureControllerEdits()
    if self.busy or not self.adapters or not self.record or not self.record.bindingAccepted or self.db.lastProjectedGUID~=self.guid then return end
    local ok,state=pcall(self.adapters.bindings.read,self.adapters.bindings,{"state"})
    if not ok then return end
    local native=self.adapters.bindings.native
    if not native or state.set~=native.api.CharacterSet then
        self.Diagnostics:SetFeature('controllerCapture','pending','account binding view retained; GUID character archive not overwritten')
        return
    end
    local scopes=self.BindingPolicy.Split(state.keys)
    self.record.controllerBindings=self.Core.Copy(scopes.character)
    self.db.shared.faceBindings=self.Core.Copy(scopes.shared)
end
function Addon:FinishAccepted(journal)
    local state=self.adapters.bindings:read({"state"})
    local scopes=self.BindingPolicy.Split(state.keys)
    self.record.bindingAccepted=state.set==Enum.BindingSet.Character
    if self.record.bindingAccepted then
        self.record.controllerBindings=self.Core.Copy(scopes.character)
        self.db.shared.faceBindings=self.Core.Copy(scopes.shared)
        self.db.lastProjectedGUID=self.guid
    end
    self.db.shared.geometry=self.adapters.consoleport:read({"layout"})
    local rings=self.adapters.rings
    local keptRings=journal.context.resolutions and journal.context.resolutions[self.guid..'/rings']=='keep'
    if keptRings and self.db.shared.ringProjectionGUID~=self.guid then self.record.ringAccepted=false end
    if rings and rings:Probe() and self.db.shared.ringProjectionGUID==self.guid then
        if not self.record.ringAccepted then self.record.rings.sets=self.Core.Copy(rings:read({'state'}).sets) end
        self.record.ringAccepted=true
        rings:CaptureEdits()
    end
    if self.adapters.editmode then
        local snapshot=self.adapters.editmode:Capture()
        if snapshot and snapshot.active.layoutName==self.PROFILE_NAME then self.db.shared.managedEditModeName=self.PROFILE_NAME end
    end
    self.record.lastInstallTransaction=journal.id
    self.record.pendingReload=journal.id
    self.reloadAppliedInSession=journal.id
    self:RefreshModes()
    self:RefreshUI()
    self:RefreshRings()
    self.Diagnostics:SetFeature("configuration","applied","runtime baseline retained; reload verification pending")
    Print("Reviewed configuration applied. Backup "..journal.id.." is retained.")
    self.Prompt:Reload()
end
function Addon:ApplyReviewed(resolutions)
    self.busy=true
    local ok,result,detail=pcall(self.coordinator.Accept,self.coordinator,resolutions)
    self.busy=false
    if not ok then self.Diagnostics:Log("error",result) Print("Configuration failed; use /cpf diagnose.") return end
    if not result then self.Diagnostics:Log("pending",detail) Print(detail) return end
    if detail.context.restores then self:FinishRestored(detail)
    elseif detail.context.viewRecovery then self:FinishBindingView(detail)
    else self:FinishAccepted(detail) end
end
function Addon:ShowPrompt(force)
    if self.Prompt.active then return end
    if not self.coordinator then self.forcePrompt=force self:Refresh() return end
    if not force and (self.record.appliedRevision>=self.CONFIG_REVISION or self.record.declinedRevision==self.CONFIG_REVISION) then return end
    if not CanWrite() then self.forcePrompt=true return end
    local fields,deferred=self.RuntimeSetup.Fields(self.db,self.guid,self.adapters,_G,self.CONFIG_REVISION)
    if self.adapters.rings and self.adapters.rings:Probe() then self.record.ringOfferedRevision=self.CONFIG_REVISION end
    local plan=self.coordinator:Build(fields,self.CONFIG_REVISION)
    for _,entry in ipairs(deferred) do plan.deferred[#plan.deferred+1]=entry end
    self.record.runtimeBaseline=self.Core.Copy(plan.current)
    self.record.baselineProvenance={guid=self.guid,previousProjectedGUID=self.db.lastProjectedGUID,bindingSet=GetCurrentBindingSet(),codeVersion=self.VERSION}
    self.Prompt:Show(plan,function(resolutions) self:ApplyReviewed(resolutions) end,function()
        self.record.declinedRevision=self.CONFIG_REVISION
        Print("Review cancelled. Configuration retained; /cpf install opens it again.")
    end)
end
function Addon:HydrateController()
    if not self.record.bindingAccepted or not CanWrite() then return end
    if self.db.lastProjectedGUID==self.guid then self:CaptureControllerEdits() end
    local adapter=self.adapters.bindings
    local current=adapter:read({"state"})
    local desired=self.RuntimeSetup.BindingProposal(self.db,self.guid,adapter,self.ReferenceBindings)
    if self.Core.Equal(current,desired) then self.db.lastProjectedGUID=self.guid return end
    local step={id=self.guid.."/controller",scope="bindings",path={"state"},before=current,value=desired,revision=self.CONFIG_REVISION}
    local journal=self.Transactions.Prepare(self.db,self.guid,{step},{projection=true})
    self.busy=true
    local ok,result=pcall(self.Transactions.Apply,journal,self.adapters,CanWrite)
    self.busy=false
    if ok and result then
        self.Transactions.Commit(self.db,journal,self.record.appliedRevision)
        self.db.lastProjectedGUID=self.guid
    else self.Diagnostics:Log("recovery","character projection requires review") end
end
function Addon:RefreshRings()
    local adapter=self.adapters and self.adapters.rings
    if not adapter then self.Diagnostics:SetFeature('rings','pending','native ring adapter not initialized') return end
    local ready,probeReason=adapter:Probe()
    if not ready then self.Diagnostics:SetFeature('rings','pending',probeReason) return end
    if not self.record.ringAccepted then self.Diagnostics:SetFeature('rings','review-required','GUID ring projection has not been accepted; baseline retained') return end
    local preparedBefore=self.db.shared.ringProjectionGUID==self.guid
    if preparedBefore then self:PrepareSelectors(adapter) end
    if not CanWrite() then return end
    if adapter.rings:IsShown() then self.Diagnostics:SetFeature('rings','pending','ring projection waits for the current native wheel to close') return end
    adapter:CaptureEdits()
    local desired,reason=adapter:Proposal()
    if not desired then self.Diagnostics:SetFeature('rings','pending',reason) return end
    if self.record.appliedRevision>=15 and GetBindingAction(adapter.api.classChord or self.ClassActions.CHORD)==adapter.rings:GetBindingForSet(adapter.api.classSet) then
        desired=self.ClassActions.RingProposal(desired,adapter,_G)
    end
    local current=adapter:read({'state'})
    if not self.Core.Equal(current,desired) then
        local step={id=self.guid..'/rings',scope='rings',path={'state'},before=current,value=desired,revision=self.CONFIG_REVISION}
        local journal=self.Transactions.Prepare(self.db,self.guid,{step},{ringProjection=true})
        self.busy=true
        local ok,result=pcall(self.Transactions.Apply,journal,self.adapters,CanWrite)
        self.busy=false
        if not ok or not result then self.Diagnostics:SetFeature('rings','recovery-required','personal ring projection requires guarded recovery; /cpf diagnose') return end
        self.Transactions.Commit(self.db,journal,self.record.appliedRevision)
    end
    self.ringHookTargets=self.ringHookTargets or setmetatable({},{__mode='k'})
    if not self.ringHookTargets[adapter.rings] then
        self.ringHookTargets[adapter.rings]=true
        local target=adapter.rings
        hooksecurefunc(target,'RefreshAll',function()
            local current=self.adapters and self.adapters.rings
            if not self.busy and current and current.rings==target then current:CaptureEdits() end
        end)
        target:HookScript('OnHide',function()
            C_Timer.After(0,function() if CanWrite() and not self.busy then self:RefreshRings() end end)
        end)
    end
    self.Diagnostics:SetFeature('rings','offline-verified','GUID personal rings; native utility extras preserved; new selector gesture remains pending')
    if not preparedBefore then self:PrepareSelectors(adapter) end
end
function Addon:PrepareSelectors(adapter)
    local snapshot,reason=self.RingDiscovery.Capture(_G,self.guid)
    if not snapshot then self.selectorPreview=nil self.Diagnostics:SetFeature('learnedSelectors','pending',reason) return end
    local preview,error=self.RingSelectors.Build(snapshot,self.guid,adapter.rings,adapter.api.classSet,
        self.record.rings.sets or {},self.record.rings.preparedSelectors)
    self.selectorPreview=preview
    if preview then
        self.record.rings.preparedSelectors=self.Core.Copy(preview)
        self.Diagnostics:SetFeature('learnedSelectors','pending',preview.gate..' '..table.concat(preview.pending,'; '))
    else self.Diagnostics:SetFeature('learnedSelectors','pending',error) end
end
function Addon:VerifyReload()
    local id=self.record.pendingReload
    if not id or id==self.reloadAppliedInSession then return end
    local journal=self.db.transactions[id]
    if not journal or (journal.status~="committed" and journal.status~="restored") then return end
    if journal.context.bindingInspection then
        if not CanWrite() then return end
        self.adapters.bindingBanks:Attach(journal)
    end
    local failures={}
    for _,step in ipairs(journal.steps) do
        local adapter=self.adapters[step.scope]
        local ok,value=false,nil
        if adapter then ok,value=pcall(adapter.read,adapter,step.path) end
        local same=ok and self.Core.Equal(self.Core.Encode(value),step.value)
        if ok and adapter and type(adapter.equal)=='function' then
            local compared,result=pcall(adapter.equal,adapter,value,self.Core.Decode(step.value))
            same=compared and result==true
        end
        if not same then failures[#failures+1]=step.id end
    end
    journal.reloadVerification={failures=failures}
    if #failures==0 then
        self.record.pendingReload=nil
        self.Diagnostics:SetFeature("configuration","verified","accepted fields survived reload")
    else self.Diagnostics:SetFeature("configuration","review-required","reload fields changed; /cpf diagnose") end
end
function Addon:Refresh()
    local ok,reason=self:InitializeStore()
    if not ok then self.Diagnostics:SetFeature("configuration","pending",reason) return end
    local probe=self.Capability.Probe({C_AddOns=C_AddOns,UnitGUID=UnitGUID,UnitName=UnitName,GetBuildInfo=GetBuildInfo,
        GetCurrentBindingSet=GetCurrentBindingSet,AccountSet=Enum.BindingSet.Account,CharacterSet=Enum.BindingSet.Character})
    self.capabilities=probe
    if not probe.ready then self.Diagnostics:SetFeature("configuration","pending",table.concat(probe.pending,", ")) return end
    local adapters,error=self.RuntimeSetup.Adapters(_G,self.db)
    if not adapters then self.Diagnostics:SetFeature("configuration","pending",error) return end
    self.adapters=adapters
    if self.PingTargeting then
        local ready,reason=self.PingTargeting:Refresh(_G,self:IsCharacterInstalled(),adapters.consoleport)
        self.Diagnostics:SetFeature('pingTargeting',ready and 'offline-verified' or 'pending',reason)
    end
    self.TargetingUI:Initialize(_G)
    self.coordinator=self.Coordinator.New(self.db,self.guid,adapters,CanWrite)
    if self.record.pendingBindingSelection then
        self.Diagnostics:SetFeature("bindingSelection","recovery-required","temporary bank inspection interrupted; /cpf recover-selection")
        return
    end
    if self.record.bindingViewRecovery then self.Diagnostics:SetFeature("bindingView","review-required","pre-interruption native view retained; /cpf recover-view opens its conflict review") end
    for _,journal in pairs(self.db.transactions) do
        if journal.guid==self.guid and (journal.status=="applying" or journal.status=="recovery-required") then
            self.Diagnostics:SetFeature("configuration","recovery-required","transaction "..journal.id.."; /cpf recover "..journal.id)
            return
        end
    end
    self:VerifyReload()
    if self:IsCharacterInstalled() then self:HydrateController() end
    self:RefreshRings()
    self.ClassActions.Migrate(self,_G,CanWrite)
    self:RefreshModes()
    self:RefreshUI()
    if self:IsCharacterInstalled() and not self.record.ringAccepted and self.record.ringOfferedRevision~=self.CONFIG_REVISION
        and adapters.rings and adapters.rings:Probe() then self.forcePrompt=true end
    if self.forcePrompt then self.forcePrompt=nil self:ShowPrompt(true) else self:ShowPrompt(false) end
end
function Addon:Restore(id)
    if not self.coordinator then Print("Configuration is not initialized.") return end
    id=id~="" and id or self.record.lastInstallTransaction
    if not id then Print("No installed backup for this character.") return end
    if self.Prompt.active then Print("Finish or cancel the current review first.") return end
    if not CanWrite() then self.restoreRequested=id Print("Backup review is deferred until combat and Edit Mode end.") return end
    if self.record.pendingBindingSelection then Print("Complete /cpf recover-selection before opening another restore review.") return end
    local original=self.db.transactions[id]
    if not original or original.guid~=self.guid or original.status~="committed" then Print("Backup does not belong to this installed character.") return end
    local banks,detail=self.adapters.bindingBanks,original.bindingDetails
    if banks and detail and (banks:NeedsInspection(detail.targetSet) or banks:NeedsInspection(detail.originalSet)) then
        self.Prompt:InspectBindings(function()
            banks:Permit(detail.targetSet,id) banks:Permit(detail.originalSet,id)
            self:Restore(id)
        end,function() banks.permits={} Print("Bank inspection cancelled; current bindings retained.") end)
        return
    end
    local plan,reason=self.coordinator:BuildRestore(id)
    if not plan then Print(reason) return end
    self.Prompt:Show(plan,function(resolutions) self:ApplyReviewed(resolutions) end,function()
        if banks then banks.permits={} end
        Print("Restore cancelled; configuration retained.")
    end)
end
function Addon:RecoverBindingSelection()
    local banks=self.adapters and self.adapters.bindingBanks
    if not banks then Print("Native binding banks are not initialized.") return end
    self.busy=true
    local ok,result,reason=pcall(banks.RecoverSelection,banks)
    self.busy=false
    if not ok or not result then Print(reason or result) return end
    Print("Previous binding bank selected; retained transient-view snapshots remain available for review.")
    self:Refresh()
    if self.record.bindingViewRecovery then self:ReviewBindingView() end
end
function Addon:ReviewBindingView()
    if not self.coordinator or self.Prompt.active then return end
    if not CanWrite() then Print("Transient binding view review is available outside combat and Edit Mode.") return end
    local plan,reason=self.coordinator:BuildBindingViewRecovery()
    if not plan then Print(reason) return end
    self.Prompt:Show(plan,function(resolutions) self:ApplyReviewed(resolutions) end,function() Print("Transient view retained for a later review; current bindings kept.") end)
end
function Addon:FinishBindingView(journal)
    self.record.pendingReload=journal.id
    self.reloadAppliedInSession=journal.id
    self:CaptureControllerEdits()
    local original=self.db.transactions[journal.context.viewRecoveryBackup]
    if original and original.status=="recovery-required" then self:Recover(original.id) end
    Print("Reviewed transient binding view saved. Recovery backup "..journal.id.." retained.")
    self.Prompt:Reload()
end
function Addon:FinishRestored(journal)
    self.record.bindingAccepted=false
    self.record.ringAccepted=false
    self.record.declinedRevision=self.CONFIG_REVISION
    self.record.pendingReload=journal.id
    self.reloadAppliedInSession=journal.id
    self:RefreshModes()
    self:RefreshUI()
    Print("Reviewed backup fields restored; retained edits and unavailable fields are preserved. Backup "..journal.id.." retained.")
    self.Prompt:Reload()
end
function Addon:RefreshModes()
    if self.NATIVE_INPUT_RECOVERY then
        -- Placement is independent of the suspended mode/UI interceptors.
        -- Native ConsolePort still owns bindings, action pages and UpdateState.
        if self.record then
            self.record.targetingObserved=self.record.targetingObserved or {}
            self.GroundTargeting.observed=self.record.targetingObserved
            self.GroundTargeting.Observe(_G)
        end
        if not CanWrite() or not self.adapters then return end
        self.SecureModes.Disable(_G,self.adapters.consoleport)
        local enabled=self:IsCharacterInstalled() and self.db.shared.runtimePolicy.groundTargetingEnabled
        local ready,reason=self.GroundTargeting.Enable(self.adapters.consoleport,_G,enabled,self.TargetingPreferences.Read(self.db))
        self.Diagnostics:SetFeature('secureModes','native-recovery','Forever secure mode interception suspended; native ConsolePort dispatch retained')
        self.Diagnostics:SetFeature('groundTargeting',ready and 'offline-verified' or 'pending',reason)
        return ready,reason
    end
    if self.record then
        self.record.targetingObserved=self.record.targetingObserved or {}
        self.GroundTargeting.observed=self.record.targetingObserved
        self.GroundTargeting.Observe(_G)
    end
    if not CanWrite() or not self.adapters then return end
    local bridge=self.adapters.consoleport
    if not self:IsCharacterInstalled() or not self.db.shared.runtimePolicy.modesEnabled then
        self.GroundTargeting.Disable(_G)
        self.Diagnostics:SetFeature('groundTargeting','pending','reviewed mode policy not enabled')
        self.SecureModes.Disable(_G,bridge)
        self.Diagnostics:SetFeature("secureModes","pending","reviewed mode policy not enabled; baseline retained")
        return
    end
    local current=bridge:read({"layout"})
    if not self.Core.Equal(current,self.SecureModes.LayoutProposal(current)) then
        self.GroundTargeting.Disable(_G)
        self.Diagnostics:SetFeature('groundTargeting','pending','native mode layout requires review')
        self.SecureModes.Disable(_G,bridge)
        self.Diagnostics:SetFeature("secureModes","review-required","legacy special visibility/access remains; review the layout proposal")
        return
    end
    local ok,reason=self.SecureModes.Install(bridge,_G)
    self.Diagnostics:SetFeature("secureModes",ok and "offline-verified" or "pending",reason or "native CP buttons/Layers retained; in-game secure input proof pending")
    local groundEnabled=ok and self.db.shared.runtimePolicy.groundTargetingEnabled
    local groundReady,groundReason=self.GroundTargeting.Enable(bridge,_G,groundEnabled,self.TargetingPreferences.Read(self.db))
    self.Diagnostics:SetFeature('groundTargeting',groundEnabled and groundReady and 'offline-verified' or 'pending',groundReason)
    if ok and not self.modeCallbacks then
        self.modeCallbacks=true
        local function changed() C_Timer.After(0,function() local called,error=pcall(self.RefreshModes,self) if not called then self.Diagnostics:Log("mode-error",error) end end) end
        bridge.bar:RegisterSafeCallback('OnLayoutChanged',changed)
        bridge.bar:RegisterSafeCallback('OnNewBindings',changed)
    end
end
function Addon:Recover(id)
    if self.record and self.record.pendingBindingSelection then Print("Complete /cpf recover-selection before recovering a configuration transaction.") return end
    local journal=self.db and self.db.transactions[id]
    if not journal or journal.guid~=self.guid then Print("Recovery journal unavailable for this character.") return end
    if not CanWrite() then Print("Recovery is unavailable during combat or Edit Mode.") return end
    if journal.status~="applying" and journal.status~="recovery-required" then Print("This journal does not require recovery.") return end
    self.busy=true
    local ok,result=pcall(self.Transactions.Recover,journal,self.adapters,CanWrite)
    self.busy=false
    Print(ok and result and "Interrupted transaction rolled back." or "Recovery remains pending; newer edits are preserved. /cpf diagnose")
end
function Addon:Status()
    Print(("Version %s; character %s; configuration %s/%s; binding set %s"):format(self.VERSION,tostring(self.guid or "pending"),
        tostring(self.record and self.record.appliedRevision or 0),self.CONFIG_REVISION,tostring(GetCurrentBindingSet())))
    Print(self.Diagnostics:Summary())
    local names={}
    for name in pairs(self.capabilities and self.capabilities.modules or {}) do names[#names+1]=name end
    table.sort(names)
    for _,name in ipairs(names) do
        local module=self.capabilities.modules[name]
        Print(name..": "..tostring(module.version or "version metadata unavailable").."; installed="..tostring(module.installed)
            .." enabled="..tostring(module.enabled).." loaded="..tostring(module.loaded))
    end
    local journals={}
    for id,journal in pairs(self.db and self.db.transactions or {}) do
        if journal.guid==self.guid then journals[#journals+1]=tostring(id).." ("..tostring(journal.status)..")" end
    end
    table.sort(journals)
    if #journals>0 then
        Print("Runtime journals retained: "..#journals.."; IDs (use /cpf restore <id> or /cpf recover <id>):")
        for index=math.max(1,#journals-9),#journals do Print(journals[index]) end
    end
end
function Addon:RefreshUI()
    self.BlizzardVisibility:Update()
    self.Cinematic:Refresh(_G)
    if not self.adapters then return end
    self:RequestSkinRefresh()
    local enabled=self:IsCharacterInstalled() and self.db.shared.runtimePolicy.focusVisuals
    local ok,reason=self.FocusVisuals:Enable(self.adapters.consoleport,_G,enabled)
    self.Diagnostics:SetFeature("focusVisuals",enabled and ok and "offline-verified" or "pending",reason or (enabled and "ordinary cursor ownership only; rendered acceptance pending" or "reviewed visual policy not enabled"))
    local contexts=not self.NATIVE_INPUT_RECOVERY and self:IsCharacterInstalled() and self.db.shared.runtimePolicy.uiContextsEnabled
    local active,error=self.UIContexts:Enable(self.adapters.consoleport,_G,contexts,self:IsCharacterInstalled() and self.db.shared.runtimePolicy.windowsEnabled,self:IsCharacterInstalled() and self.db.shared.runtimePolicy.bagsEnabled,self:IsCharacterInstalled() and self.db.shared.runtimePolicy.mapEnabled)
    self.Diagnostics:SetFeature("uiContexts",contexts and active and "offline-verified" or "pending",error or (contexts and "native popup/quantity ownership; Retail input/taint acceptance pending" or "reviewed UI context policy not enabled"))
end
Addon.Prompt:Initialize({dialogs=StaticPopupDialogs,show=StaticPopup_Show,reload=ReloadUI,defer=function(callback) C_Timer.After(0,callback) end,
    details=function(text) local ok,reason=Addon.Proof:Show(_G,text) if not ok then Print(reason) end end})
SLASH_CONSOLEPORTFOREVER1="/cpf"
SlashCmdList.CONSOLEPORTFOREVER=function(input)
    local command,arg=(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command=command:lower()
    if command=="install" or command=="update" then Addon:ShowPrompt(true)
    elseif command=="restore" then Addon:Restore(arg)
    elseif command=="recover" then Addon:Recover(arg)
    elseif command=="recover-selection" then Addon:RecoverBindingSelection()
    elseif command=="recover-view" then Addon:ReviewBindingView()
    elseif command=="proof" then
        local ok,reason=Addon.Proof:Show(_G)
        if not ok then Print(reason) end
    elseif command=="diagnose" then
        if Addon.PingTargeting then Addon.PingTargeting:Observe(_G) end
        if Addon.SnapshotFaceVisuals then Addon:SnapshotFaceVisuals(true) end
        Addon:Status()
        for _,entry in ipairs(Addon.Diagnostics.entries) do Print(entry.kind..": "..entry.message) end
    else Addon:Status() end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_LOGOUT","PLAYER_ENTERING_WORLD","PLAYER_REGEN_ENABLED","PLAYER_REGEN_DISABLED","ADDON_LOADED","UPDATE_BINDINGS","EDIT_MODE_LAYOUTS_UPDATED","SPELLS_CHANGED","ACTIONBAR_SLOT_CHANGED","PLAYER_SPECIALIZATION_CHANGED","TRAIT_CONFIG_UPDATED","SPELL_DATA_LOAD_RESULT","CVAR_UPDATE","UPDATE_SHAPESHIFT_FORMS","PET_BAR_UPDATE","UNIT_PET","BAG_UPDATE_DELAYED","ITEM_LOCK_CHANGED","CURSOR_CHANGED","MERCHANT_SHOW","MERCHANT_CLOSED","CINEMATIC_START","CINEMATIC_STOP","PLAY_MOVIE","STOP_MOVIE","ADDON_ACTION_BLOCKED","ADDON_ACTION_FORBIDDEN"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event,...)
    if event=='PING_SYSTEM_ERROR' then
        if Addon.PingTargeting then Addon.PingTargeting:Observe(_G,...) end
        return
    end
    if event=='CVAR_UPDATE' and tostring((...)):lower()~='actionbuttonusekeydown' then return end
    if event=='SPELL_DATA_LOAD_RESULT' and not (Addon.GroundTargeting.requested and Addon.GroundTargeting.requested[(...)]) then return end
    if event=='PLAYER_SPECIALIZATION_CHANGED' and (...)~='player' then return end
    if event=="PLAYER_LOGOUT" then
        Addon:CaptureControllerEdits()
        if Addon.adapters and Addon.adapters.rings then Addon.adapters.rings:CaptureEdits() end
        return
    end
    if event=="PLAYER_REGEN_DISABLED" then Addon.FocusVisuals:SetFocus(false,_G) Addon.UIContexts:Refresh() return end
    if event=="UPDATE_BINDINGS" then Addon:CaptureControllerEdits() end
    if event=="ADDON_ACTION_BLOCKED" or event=="ADDON_ACTION_FORBIDDEN" then
        local blamed,func=...
        if blamed==ADDON_NAME then Addon.Diagnostics:Log("blocked",event..": "..tostring(func)) end
        return
    end
    if event=="PLAYER_LOGIN" and not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") and CanWrite() then C_AddOns.LoadAddOn("Blizzard_EditMode") end
    if Addon.busy then return end
    if not Addon.refreshQueued then
        Addon.refreshQueued=true
        C_Timer.After(0,function()
            Addon.refreshQueued=false
            if Addon.Prompt.active then return end
            if Addon.restoreRequested and CanWrite() then
                local id=Addon.restoreRequested Addon.restoreRequested=nil Addon:Restore(id) return
            end
            if Addon.coordinator and Addon.coordinator.queued and CanWrite() then
                Addon.busy=true
                local ok,result,journal=pcall(Addon.coordinator.Resume,Addon.coordinator)
                Addon.busy=false
                if ok and result then
                    if journal.context.restores then Addon:FinishRestored(journal)
                    elseif journal.context.viewRecovery then Addon:FinishBindingView(journal)
                    else Addon:FinishAccepted(journal) end
                else Print("Queued review changed; reopen its review.") end
            else
                local ok,error=pcall(Addon.Refresh,Addon)
                if not ok then Addon.Diagnostics:Log("error",error) end
            end
        end)
    end
end)
events:RegisterEvent('PING_SYSTEM_ERROR')
