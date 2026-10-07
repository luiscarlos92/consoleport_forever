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
            text=owner:GetAttribute('cpf-ground-spell-'..tostring(id));
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
function Ground.Commands(api)
    local commands,pending={},{}
    for id in pairs(Addon.GroundSpells) do
        local ok,info=pcall(api.C_Spell.GetSpellInfo,id)
        local overrideOK,override=true,nil
        if api.C_Spell.GetOverrideSpell then overrideOK,override=pcall(api.C_Spell.GetOverrideSpell,id) end
        if not overrideOK or (override and override~=0 and not Addon.GroundSpells[override])
            or (ok and info and info.spellID and not Addon.GroundSpells[info.spellID]) then
            pending[#pending+1]=id
        elseif ok and type(info)=='table' and type(info.name)=='string' and info.name~=''
            and not info.name:find('[\r\n%[%];|]') then
            -- Localized names are provided by the client. Reject command syntax.
            commands[id]='/cast [@cursor] '..info.name
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
function Ground.Enable(bridge,api,enabled)
    if api.InCombatLockdown() then return false,'ground setup deferred during combat' end
    if not enabled then return Ground.Disable(api),'reviewed ground-target policy not enabled' end
    local ok,reason=Ground.Probe(bridge,api)
    if not ok then Ground.Disable(api) return false,reason end
    local commands,pending=Ground.Commands(api)
    if not next(commands) then Ground.Disable(api) return false,'ground spell metadata unavailable; native targeting retained' end
    Ground.prepared,Ground.pending=commands,pending
    for _,bank in ipairs(banks) do
        local group=api['ConsolePortGroup'..bank]
        group:SetFrameRef('cpfGroundCursor',bridge.db.Cursor)
        group:SetFrameRef('cpfGroundRaid',bridge.db.Raid)
        group:SetFrameRef('cpfGroundRing',bridge.db.TargetRing)
        for id in pairs(Addon.GroundSpells) do group:SetAttribute('cpf-ground-spell-'..id,commands[id]) end
        for _,key in ipairs(cells) do
            local button=group.buttons[key]
            if not button.__cpfGround then
                button.header:WrapScript(button,'OnClick',Ground.Pre,Ground.Post)
                button.header:WrapScript(button,'OnHide',Ground.OnHide)
                button.__cpfGround=true
            end
            button:SetAttribute('cpf-ground-default-keydown',api.GetCVarBool('ActionButtonUseKeyDown'))
            if button:GetAttribute('cpf-ground-pressed') then
                local text=button:GetAttribute('cpf-ground-text')
                local valid=false
                for _,command in pairs(commands) do if text==command then valid=true break end end
                if not valid then button:SetAttribute('cpf-ground-cancelled',true) end
            end
            button:SetAttribute('cpf-ground-enabled',true)
        end
    end
    return true,'secure cursor casts prepared; '..#pending..' unavailable IDs retain native targeting; Retail acceptance pending'
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
    Ground.prepared=nil
    return true
end
