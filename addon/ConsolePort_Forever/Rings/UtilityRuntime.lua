local ADDON_NAME,Addon=...
local Core,Integration=Addon.Core,{}
Addon.UtilityIntegration=Integration
local function public(api,value) return not (api.issecretvalue and api.issecretvalue(value)) end
local function positive(api,value) return public(api,value) and type(value)=='number' and value>0 and value%1==0 end
local function manual(set)
    local result={[0]=Core.Copy(set[0] or {})}
    for _,action in ipairs(set) do if not action.autoassigned then result[#result+1]=Core.Copy(action) end end
    return result
end
local function key(action)
    if action.type=='spell' then
        local id=type(action.spell)=='number' and action.spell or (type(action.link)=='string' and action.link:match('spell:(%d+)'))
        return 'spell:'..tostring(id or action.spell)
    elseif action.type=='item' then
        local id=tonumber(action.item) or (type(action.item)=='string' and action.item:match('item:(%d+)'))
            or (type(action.link)=='string' and action.link:match('item:(%d+)'))
        return 'item:'..tostring(id or action.item)
    end
end
function Integration:Refresh(addon,api)
    if not addon.db or not Addon.UtilityFlag.Enabled(addon.db) then return nil,'disabled' end
    if addon.utilityRuntime then
        addon.utilityRuntime:Resume()
        self:StartFollower(addon,api,addon.utilityRuntime)
        return addon.utilityRuntime
    end
    local session=Addon.UtilityFlag.sessions[addon.db]
    if session then return session.feature,session.reason end
    local lib=api.LibStub('RelaTable',true)
    local env=lib and rawget(lib,'ConsolePort_Rings')
    local db=api.ConsolePort and api.ConsolePort:GetData()
    local frame=db and db.Rings
    if api.C_AddOns.GetAddOnMetadata('ConsolePort','Version')~='3.3.10' then return nil,'native ring version unqualified' end
    if type(env)~='table' or not frame or env.Frame~=frame or not env.IsDataReady or not env.IsSpellValidationReady
        or type(frame.Data)~='table' or type(frame.Shared)~='table' or type(frame.Data[api.CPAPI.DefaultRingSetID])~='table'
        or type(frame.RefreshAll)~='function' or type(env.ValidateSet)~='function' or not env.Attributes
        or env.Attributes.MetadataIndex~=0 or not api.C_SpellBook or type(api.C_SpellBook.IsSpellKnown)~='function'
        or not api.C_Spell or type(api.C_Spell.GetOverrideSpell)~='function' or not api.C_Item
        or type(api.C_Item.GetItemCount)~='function' or type(api.C_Item.IsItemDataCachedByID)~='function'
        or not api.Enum or not api.Enum.SpellBookSpellBank then return nil,'native ring readiness pending' end
    local setID=api.CPAPI.DefaultRingSetID
    local featureAPI={issecretvalue=api.issecretvalue}
    local publicReader={api=featureAPI}
    featureAPI.enabled=function() return Addon.UtilityFlag.Enabled(addon.db) and not (addon.utilityRuntime and addon.utilityRuntime.stopped) end
    featureAPI.context=function()
        local spec=api.GetSpecialization()
        if not positive(api,spec) then return end
        return {guid=api.UnitGUID('player'),spec=api.GetSpecializationInfo(spec),
            config=api.C_ClassTalents and api.C_ClassTalents.GetActiveConfigID and api.C_ClassTalents.GetActiveConfigID()}
    end
    featureAPI.blocked=function()
        return api.InCombatLockdown() or frame:IsShown() or addon.busy or (addon.Prompt and addon.Prompt.active)
            or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown())
    end
    featureAPI.defer=function(callback) api.C_Timer.After(0,callback) end
    featureAPI.spellKnown=function(id)
        local known=api.C_SpellBook.IsSpellKnown(id,api.Enum.SpellBookSpellBank.Player)
        if not public(api,known) or type(known)~='boolean' then return known end
        if known then return true end
        return api.C_SpellBook.IsSpellKnown(id,api.Enum.SpellBookSpellBank.Pet)
    end
    featureAPI.overrideSpell=function(id) return api.C_Spell.GetOverrideSpell(id) end
    featureAPI.spellInfo=api.CPAPI.GetSpellInfo
    featureAPI.itemCount=api.C_Item.GetItemCount
    featureAPI.itemReady=api.C_Item.IsItemDataCachedByID
    featureAPI.toyOwned=function(id) return api.PlayerHasToy and api.PlayerHasToy(id) end
    featureAPI.macroInfo=api.CPAPI.GetMacroInfo
    featureAPI.macroScope=function(id)
        local limit=api.CPAPI.MAX_ACCOUNT_MACROS
        if not positive(api,limit) then return addon.guid end
        if id>limit then return addon.guid end
    end
    featureAPI.mountForSpell=function(id) return api.C_MountJournal and api.C_MountJournal.GetMountFromSpell(id) end
    featureAPI.mountInfo=function(id)
        local name,spellID,_,_,_,_,_,factionSpecific,faction,hidden,collected=api.C_MountJournal.GetMountInfoByID(id)
        local playerFaction=api.UnitFactionGroup('player')
        return {name=name,spellID=spellID,collected=collected,hidden=hidden,
            factionSpecific=factionSpecific,faction=faction,playerFaction=playerFaction}
    end
    featureAPI.ringScope=function(id) if not env:IsSharedSet(id) then return addon.guid end end
    featureAPI.nativeIdentity=function(action)
        if action.type=='action' then
            local kind,id,subtype=api.GetActionInfo(action.action) return {kind=kind,id=id,subtype=subtype}
        elseif action.type=='pet' then
            local name,_,_,_,_,_,id=api.GetPetActionInfo(action.action) return {name=name,id=id}
        elseif action.type=='equipmentset' then return {id=api.C_EquipmentSet.GetEquipmentSetID(action.equipmentset)} end
    end
    featureAPI.nativeAvailable=function(entry)
        local action=entry.native
        if type(action)~='table' then return false end
        if action.type=='custom' then
            if action.ring then return type(env:GetSet(action.ring,true))=='table' end
            return (type(action.binding)=='string' and action.binding~='') or type(action.house)=='string'
        end
        local current=featureAPI.nativeIdentity(action)
        if not Addon.SharedUtility.Safe(publicReader,current) then return nil end
        if type(current)~='table' or not Core.Equal(current,entry.identity) then return false end
        if action.type=='equipmentset' then return current.id~=nil end
        return current.id~=nil or current.name~=nil
    end
    featureAPI.requestData=function(kind,id)
        if kind=='spell' then api.C_Spell.RequestLoadSpellData(id)
        elseif kind=='item' then api.C_Item.RequestLoadItemDataByID(id) end
    end
    featureAPI.readView=function() return frame.Data[setID] end
    local runtime
    featureAPI.writeView=function(value) return runtime and runtime:Write(value) or false end
    local now=featureAPI.context()
    if not Addon.SharedUtility.Safe(publicReader,now) or type(now)~='table' or type(now.guid)~='string' or now.guid==''
        or not positive(api,now.spec) or not Addon.SharedUtility.Safe(publicReader,frame.Data[setID]) or featureAPI.blocked() then
        return nil,'public context/write readiness pending'
    end
    return Addon.UtilityFlag.Start(addon.db,true,function()
        local candidate=Addon.SharedUtility.New(featureAPI,addon.db.sharedUtilityArchive)
        local fresh=addon.db.sharedUtilityArchive==nil
        addon.db.sharedUtilityArchive=candidate.archive
        if fresh then
            local initial=manual(frame.Data[setID])
            local archive=addon.record and addon.record.rings.sets and addon.record.rings.sets[setID]
            local sourceGUID=addon.db.shared.ringProjectionGUID
            local seen={}
            for _,action in ipairs(initial) do
                candidate:AddNative(action)
                local identity=key(action) if identity then seen[identity]=(seen[identity] or 0)+1 end
            end
            -- Restore retained unavailable choices only from the known current
            -- GUID. Never sweep/merge other GUIDs or collapse deliberate duplicates.
            if sourceGUID==addon.guid and type(archive)=='table' and candidate:Safe(archive) then
                for _,action in ipairs(archive) do
                    if not action.autoassigned then
                        local identity=key(action)
                        if identity and (seen[identity] or 0)>0 then seen[identity]=seen[identity]-1
                        elseif identity then candidate:AddNative(action) end
                    end
                end
            end
        end
        addon.record.rings.sharedUtilityBefore=addon.record.rings.sharedUtilityBefore or manual(frame.Data[setID])
        local runtimeAPI={enabled=featureAPI.enabled,blocked=featureAPI.blocked,defer=featureAPI.defer,
            hardBlocked=function()
                return api.InCombatLockdown() or addon.busy or (addon.Prompt and addon.Prompt.active)
                    or (api.EditModeManagerFrame and api.EditModeManagerFrame:IsShown())
            end,
            owner=function() return api.ConsolePort:GetData().Rings end,
            saveFallback=function(actions,meta)
                local record=addon.record
                if record and api.UnitGUID('player')==addon.guid and candidate:Safe(actions) and candidate:Safe(meta) then
                    local fallback={[0]=Core.Copy(meta or {})}
                    for _,action in ipairs(actions) do fallback[#fallback+1]=Core.Copy(action) end
                    record.rings.sets=record.rings.sets or {} record.rings.sets[setID]=fallback
                end
            end}
        runtime=Addon.SharedUtilityRuntime.New(candidate,env,setID,runtimeAPI)
        addon.utilityRuntime=runtime
        local installed=pcall(runtime.Install,runtime)
        if not installed then runtime:Abort('hook initialization rejected; /cpfutility off then /reload') return runtime end
        if api.hooksecurefunc and addon.Prompt and type(addon.Prompt.Cancel)=='function' then
            api.hooksecurefunc(addon.Prompt,'Cancel',function() featureAPI.defer(function() runtime:Resume() end) end)
        end
        candidate:Mark() candidate.viewDirty=true
        local applied=candidate:Flush()
        if applied and not runtime.primed then runtime:Remember(frame.Data[setID],candidate.mapping,candidate.owner) end
        self:StartFollower(addon,api,runtime)
        return runtime
    end)
end
function Integration:StartFollower(addon,api,runtime)
    if addon.followerDungeon or not Addon.FollowerDungeon or runtime.stopped then return end
    addon.followerDungeon,addon.followerDungeonReason=Addon.FollowerDungeon.New(runtime.env,api,
        function() return runtime:Enabled() and runtime:Owns() end,runtime.api.blocked)
    if addon.followerDungeon then runtime.frame:QueueRefresh() end
end
function Integration:Event(addon,api,event,id)
    local runtime=addon.utilityRuntime
    if not runtime then return end
    if event=='PLAYER_LOGOUT' then runtime:SaveNativeSeed() return end
    if event=='ITEM_COUNT_CHANGED' or event=='ITEM_DATA_LOAD_RESULT' then runtime:Notify('item',id)
    elseif event=='SPELL_DATA_LOAD_RESULT' then runtime:Notify('spell',id)
    elseif event=='UPDATE_MACROS' then runtime:Notify('macro')
    elseif event=='NEW_MOUNT_ADDED' then runtime.model:Mark('mount') runtime.model:Queue()
    elseif event=='TOYS_UPDATED' or event=='NEW_TOY_ADDED' then runtime:Notify('item',id)
    elseif event=='BAG_UPDATE_DELAYED' then runtime:Notify('item')
    elseif event=='PLAYER_EQUIPMENT_CHANGED' or event=='PET_BAR_UPDATE' or event=='ACTIONBAR_SLOT_CHANGED' then
        local kind=event=='PLAYER_EQUIPMENT_CHANGED' and 'equipmentset' or event=='PET_BAR_UPDATE' and 'pet' or 'action'
        runtime.model:MarkNative(kind,event=='ACTIONBAR_SLOT_CHANGED' and id or nil) runtime.model:Queue()
    elseif event=='PLAYER_REGEN_ENABLED' then runtime:Resume()
    elseif event=='SPELLS_CHANGED' or event=='PLAYER_SPECIALIZATION_CHANGED' or event=='TRAIT_CONFIG_UPDATED'
        or event=='ACTIVE_COMBAT_CONFIG_CHANGED' or event=='UPDATE_SHAPESHIFT_FORMS' or event=='UNIT_PET' then runtime:Notify('context') end
end
