local _, Addon = ...
local Ground={}
Addon.GroundTargeting=Ground
local banks={'Base','L2','R2','L2R2'}
local cells={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}
-- Transient changes exist only inside the native secure OnClick wrapper. LAB
-- keeps its action storage, display, cooldown, tooltip and drag ownership.
local attributes={'type','*type-ControllerInput','*macro-ControllerInput',
    '*macrotext-ControllerInput','*unit-ControllerInput','*typerelease-ControllerInput',
    'pressAndHoldAction','useOnKeyDown'}
local backup,restore,alternate={},{},{}
for _,name in ipairs(attributes) do
    backup[#backup+1]=("self:SetAttribute(%q,self:GetAttribute(%q))"):format('cpf-ground-backup-'..name,name)
    restore[#restore+1]=("self:SetAttribute(%q,self:GetAttribute(%q)); self:SetAttribute(%q,nil)")
        :format(name,'cpf-ground-backup-'..name,'cpf-ground-backup-'..name)
end
for _,name in ipairs({'type','macro','macrotext','unit','typerelease','downbutton','unitsuffix'}) do
    alternate[#alternate+1]=("blocked = blocked or self:GetAttribute(prefix..%q) or self:GetAttribute(prefix..%q) or self:GetAttribute(%q) or self:GetAttribute(%q);")
        :format(name..'-ControllerInput',name..'*','*'..name..'-ControllerInput','*'..name..'*')
end
Ground.Restore=table.concat(restore,'\n').."\nself:SetAttribute('cpf-ground-active',nil)"
Ground.Pre=[[
    if button ~= 'ControllerInput' then return end;
    if down then
        self:SetAttribute('cpf-ground-pressed',nil)
        self:SetAttribute('cpf-ground-text',nil)
        self:SetAttribute('cpf-ground-cancelled',nil)
    end;
    local previous = self:GetAttribute('cpf-ground-pressed') or self:GetAttribute('cpf-ground-cancelled');
    if not previous and not self:GetAttribute('cpf-ground-enabled') then return end;
    local blocked = not self:GetAttribute('cpf-ground-enabled') or not self:GetAttribute('cpf-enabled');
    local cursor = owner:GetFrameRef('cpfGroundCursor');
    local raid = owner:GetFrameRef('cpfGroundRaid');
    local ring = owner:GetFrameRef('cpfGroundRing');
    blocked = blocked or (cursor and cursor:IsShown()) or (raid and raid:IsShown()) or (ring and ring:IsShown());
    -- Do not override native dragging, alternate click actions or empowered spells.
    blocked = blocked or (((self:GetAttribute('unlockedpreventdrag') and not self:GetAttribute('buttonlock'))
        or IsModifiedClick('PICKUPACTION')) and not self:GetAttribute('LABdisableDragNDrop'));
    local prefix = '';
    if IsShiftKeyDown() then prefix='shift-'..prefix end;
    if IsControlKeyDown() then prefix='ctrl-'..prefix end;
    if IsAltKeyDown() then prefix='alt-'..prefix end;
    blocked = blocked or self:GetAttribute('downbutton') or self:GetAttribute('unitsuffix');
]]..table.concat(alternate,'\n')..[[
    local text;
    if down and not blocked and self:GetAttribute('type') == 'action' then
        local slot=self:GetAttribute('action');
        local kind,id,subType=GetActionInfo(slot);
        if kind == 'spell' and subType ~= 'assistedcombat' and not IsPressHoldReleaseSpell(id) then
            local context='';
            if self:GetAttribute('cpf-ground-extra') then context='extra-'
            elseif HasVehicleActionBar() then context='vehicle-'
            elseif HasOverrideActionBar() then context='override-'
            elseif HasTempShapeshiftActionBar() then context='temporary-' end;
            -- Only L2R2's resolved temporary page inherits context defaults.
            -- Ordinary cells keep the same account-wide ability preference.
            if not self:GetAttribute('cpf-ground-temporary-bank') then context='' end;
            text=owner:GetAttribute('cpf-ground-'..context..'spell-'..tostring(id));
        end;
        if text then
            self:SetAttribute('cpf-ground-pressed',true)
            self:SetAttribute('cpf-ground-text',text)
            local keydown=self:GetAttribute('useOnKeyDown');
            if keydown == nil then keydown=self:GetAttribute('cpf-ground-default-keydown') end;
            self:SetAttribute('cpf-ground-keydown',keydown)
        end;
    elseif previous then
        -- A release uses the command selected on press, even after a modifier,
        -- page or action-slot change. Losing an input owner cancels that release.
        if not blocked and not self:GetAttribute('cpf-ground-cancelled') then
            text=self:GetAttribute('cpf-ground-text');
        end;
    end;
    if not text and not previous then return end;
]]..table.concat(backup,'\n')..[[
    self:SetAttribute('cpf-ground-active',true)
    self:SetAttribute('type',text and 'macro' or 'empty')
    self:SetAttribute('*type-ControllerInput',text and 'macro' or '')
    -- ATTRIBUTE_NOOP prevents an old saved-macro attribute from winning.
    self:SetAttribute('*macro-ControllerInput','')
    self:SetAttribute('*macrotext-ControllerInput',text or '')
    self:SetAttribute('*unit-ControllerInput','none')
    self:SetAttribute('*typerelease-ControllerInput','')
    self:SetAttribute('pressAndHoldAction',false)
    self:SetAttribute('useOnKeyDown',self:GetAttribute('cpf-ground-keydown'))
    return nil,'cpf-ground';
]]
-- Wrapped_Click runs its post body only when the pre body returned a message.
Ground.Post=Ground.Restore..[[
    if not down then
        self:SetAttribute('cpf-ground-pressed',nil)
        self:SetAttribute('cpf-ground-text',nil)
        self:SetAttribute('cpf-ground-keydown',nil)
        self:SetAttribute('cpf-ground-cancelled',nil)
    end;
]]
Ground.OnHide=[[
    if self:GetAttribute('cpf-ground-pressed') then
        self:SetAttribute('cpf-ground-cancelled',true)
        self:SetAttribute('cpf-ground-text',nil)
    end;
]]
-- Supplemental/extra buttons use native LeftButton hardware clicks. The same
-- backup/restore and latch apply; no saved bindings or native action slots change.
-- Blizzard's modified-attribute suffix for LeftButton is numeric 1.
Ground.SupplementalPre=Ground.Pre:gsub('ControllerInput','LeftButton'):gsub('%-LeftButton','1')
Ground.SupplementalPost=Ground.Post:gsub('ControllerInput','LeftButton'):gsub('%-LeftButton','1')

function Ground.Probe(bridge,api)
    local ok,reason=Addon.SecureModes.Probe(bridge,api)
    if not ok then return false,reason end
    if not api.C_Macro or type(api.C_Macro.RunMacroText)~='function'
        or not api.C_Spell or type(api.C_Spell.GetSpellInfo)~='function'
        or type(api.GetActionInfo)~='function' or type(api.GetCVarBool)~='function' then return false,'Retail secure macro/spell APIs unavailable' end
    -- These owners are required, not guessed from unrelated visible UI frames.
    local db=bridge.db
    for _,name in ipairs({'Cursor','Raid','TargetRing'}) do
        if not db or not db[name] or type(db[name].IsShown)~='function' then
            return false,'native '..name..' input owner unavailable'
        end
    end
    for _,bank in ipairs(banks) do
        local group=api['ConsolePortGroup'..bank]
        if type(group.SetAttribute)~='function' or type(group.SetFrameRef)~='function' then
            return false,'native group secure attributes unavailable'
        end
        for _,key in ipairs(cells) do
            if group.buttons[key].header~=group then return false,'native ground button/header owner changed' end
        end
    end
    return true
end
function Ground.Commands(api,preferences,context)
    local commands,pending={},{}
    preferences=preferences or {spells={},contexts={}}
    local ids={}
    for id in pairs(Addon.GroundSpells) do ids[id]=true end
    for id in pairs(preferences.spells or {}) do if Addon.TargetingPreferences.Qualified(preferences,id) then ids[id]=true end end
    for id in pairs(ids) do
        local mode=Addon.TargetingPreferences.Resolve(preferences,id,context)
        local ok,info=pcall(api.C_Spell.GetSpellInfo,id)
        local overrideOK,override=true,nil
        if api.C_Spell.GetOverrideSpell then overrideOK,override=pcall(api.C_Spell.GetOverrideSpell,id) end
        if not overrideOK or (override and override~=0 and not ids[override])
            or (ok and info and info.spellID and not ids[info.spellID]) then
            pending[#pending+1]=id
        elseif ok and type(info)=='table' and type(info.name)=='string' and info.name~=''
            and not info.name:find('[\r\n%[%];|]') then
            -- Localized names are provided by the client. Reject command syntax.
            if mode~='manual' then commands[id]='/cast [@'..mode..'] '..info.name end
        else
            pending[#pending+1]=id
            if api.C_Spell.RequestLoadSpellData and not info then
                Ground.requested=Ground.requested or {}
                if not Ground.requested[id] then
                    Ground.requested[id]=true
                    api.C_Spell.RequestLoadSpellData(id)
                end
            end
        end
    end
    table.sort(pending)
    return commands,pending
end
function Ground.Observe(api)
    Ground.observed=Ground.observed or {}
    for _,family in ipairs({'Vehicle','Override','TempShapeshift'}) do
        local has,index=api['Has'..family..'ActionBar'],api['Get'..family..'BarIndex']
        if has and index and has() then
            local page=index()
            if type(page)=='number' and page>0 then
                local limit=family=='TempShapeshift' and 12 or (api.NUM_OVERRIDE_BUTTONS or 6)
                for slot=(page-1)*12+1,(page-1)*12+limit do
                    local kind,id=api.GetActionInfo(slot)
                    if not (api.issecretvalue and api.issecretvalue(kind)) and kind=='spell' and not (api.issecretvalue and api.issecretvalue(id)) and type(id)=='number' and id>0 then Ground.observed[id]=true end
                end
            end
        end
    end
    local extra=api.ExtraActionButton1
    if extra and extra.GetAttribute and extra:IsShown() then
        local slot=extra:GetAttribute('action')
        if not (api.issecretvalue and api.issecretvalue(slot)) and type(slot)=='number' then
            local kind,id=api.GetActionInfo(slot)
            if kind=='spell' and not (api.issecretvalue and api.issecretvalue(id)) and type(id)=='number' and id>0 then Ground.observed[id]=true end
        end
    end
end
function Ground.Enable(bridge,api,enabled,preferences)
    if api.InCombatLockdown() then return false,'ground setup deferred during combat' end
    if not enabled then return Ground.Disable(api),'reviewed ground-target policy not enabled' end
    local ok,reason=Ground.Probe(bridge,api)
    if not ok then Ground.Disable(api) return false,reason end
    preferences=preferences or {spells={},contexts={}}
    if not Addon.TargetingPreferences.Validate(preferences) then Ground.Disable(api) return false,'invalid targeting preferences; native targeting retained' end
    Ground.Observe(api)
    local commands,pending=Ground.Commands(api,preferences)
    local contextCommands={}
    for context in pairs(Addon.TargetingPreferences.Contexts) do contextCommands[context]=Ground.Commands(api,preferences,context) end
    if not next(commands) then Ground.Disable(api) return false,'ground spell metadata unavailable; native targeting retained' end
    Ground.prepared,Ground.pending=commands,pending
    local groups={}
    for _,bank in ipairs(banks) do
        local group=api['ConsolePortGroup'..bank]
        local buttons={} for _,key in ipairs(cells) do buttons[#buttons+1]=group.buttons[key] end
        groups[#groups+1]={group=group,buttons=buttons,temporary=bank=='L2R2'}
    end
    local access=Addon.TemporaryAccess
    if access and access.frame and access.buttons then
        local buttons={} for i=1,4 do if access.buttons[i] then buttons[#buttons+1]=access.buttons[i] end end
        groups[#groups+1]={group=access.frame,buttons=buttons,temporary=true,supplemental=true}
    end
    local extra=api.ExtraActionButton1
    if extra and extra.GetAttribute and extra:GetAttribute('type')=='action' and type(extra:GetAttribute('action'))=='number' then
        groups[#groups+1]={group=api.ConsolePortGroupBase,buttons={extra},temporary=true,supplemental=true,extra=true}
    end
    for _,definition in ipairs(groups) do
        local group=definition.group
        group:SetFrameRef('cpfGroundCursor',bridge.db.Cursor)
        group:SetFrameRef('cpfGroundRaid',bridge.db.Raid)
        group:SetFrameRef('cpfGroundRing',bridge.db.TargetRing)
        local ids=Addon.Core.Copy(Ground.ids or {})
        for id in pairs(Addon.GroundSpells) do ids[id]=true end
        for id in pairs(preferences.spells or {}) do ids[id]=true end
        for id in pairs(ids) do
            group:SetAttribute('cpf-ground-spell-'..id,commands[id])
            for context,prepared in pairs(contextCommands) do group:SetAttribute('cpf-ground-'..context..'-spell-'..id,prepared[id]) end
        end
        Ground.ids=ids
        for _,button in ipairs(definition.buttons) do
            button:SetAttribute('cpf-ground-temporary-bank',definition.temporary)
            button:SetAttribute('cpf-ground-extra',definition.extra)
            if definition.supplemental then button:SetAttribute('cpf-enabled',true) end
            if not button.__cpfGround then
                group:WrapScript(button,'OnClick',definition.supplemental and Ground.SupplementalPre or Ground.Pre,definition.supplemental and Ground.SupplementalPost or Ground.Post)
                group:WrapScript(button,'OnHide',Ground.OnHide)
                button.__cpfGround=true
            end
            button:SetAttribute('cpf-ground-default-keydown',api.GetCVarBool('ActionButtonUseKeyDown'))
            if button:GetAttribute('cpf-ground-pressed') then
                local text=button:GetAttribute('cpf-ground-text')
                local valid=false
                for _,command in pairs(commands) do if text==command then valid=true break end end
                for _,prepared in pairs(contextCommands) do for _,command in pairs(prepared) do if text==command then valid=true break end end end
                if not valid then button:SetAttribute('cpf-ground-cancelled',true) end
            end
            button:SetAttribute('cpf-ground-enabled',true)
        end
    end
    local retained={}
    for _,definition in ipairs(groups) do for _,button in ipairs(definition.buttons) do retained[button]=true end end
    for _,button in ipairs(Ground.buttons or {}) do
        if not retained[button] then
            button:SetAttribute('cpf-ground-enabled',false)
            button:SetAttribute('cpf-ground-cancelled',true)
            button:SetAttribute('cpf-ground-text',nil)
        end
    end
    Ground.buttons={}
    for _,definition in ipairs(groups) do for _,button in ipairs(definition.buttons) do Ground.buttons[#Ground.buttons+1]=button end end
    return true,'account-wide ground placement prepared; '..#pending..' unavailable IDs retain native targeting; Retail acceptance pending'
end
function Ground.Disable(api)
    if api.InCombatLockdown() then return false end
    for _,bank in ipairs(banks) do
        local group=api['ConsolePortGroup'..bank]
        if group and group.buttons then
            for _,key in ipairs(cells) do
                local button=group.buttons[key]
                if button and button.__cpfGround then
                    button:SetAttribute('cpf-ground-enabled',false)
                    if button:GetAttribute('cpf-ground-pressed') then button:SetAttribute('cpf-ground-cancelled',true) end
                    button:SetAttribute('cpf-ground-text',nil)
                end
            end
        end
    end
    for _,button in ipairs(Ground.buttons or {}) do
        button:SetAttribute('cpf-ground-enabled',false)
        if button:GetAttribute('cpf-ground-pressed') then button:SetAttribute('cpf-ground-cancelled',true) end
        button:SetAttribute('cpf-ground-text',nil)
    end
    Ground.prepared=nil
    return true
end
