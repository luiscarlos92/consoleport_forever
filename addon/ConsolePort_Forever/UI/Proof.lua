local _, Addon = ...
local Proof={}
Addon.Proof=Proof
local buttons={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}
local function shown(frame) return frame and frame.IsShown and tostring(frame:IsShown()) or 'unavailable' end
function Proof:Text(api)
    local lines={'ConsolePort Forever '..tostring(Addon.VERSION),'Offline verification is not Retail secure, controller or visual acceptance.',
        'GUID: '..tostring(Addon.guid or 'pending'),'Config: '..tostring(Addon.record and Addon.record.appliedRevision or 0)..' / '..tostring(Addon.CONFIG_REVISION),
        'Saved binding set: '..tostring(api.GetCurrentBindingSet()),'Last projected GUID: '..tostring(Addon.db and Addon.db.lastProjectedGUID or 'none'),
        'Reload pending: '..tostring(Addon.record and Addon.record.pendingReload or 'none'),'',Addon.Diagnostics:Summary()}
    local db=Addon.adapters and Addon.adapters.consoleport.db
    if db and db.Layers then
        local layer=db.Layers
        if layer.GetActiveLayer then lines[#lines+1]='Layers prefix: '..layer:GetActiveLayer() end
        if layer.GetActiveChord then lines[#lines+1]='Engine chord: '..layer:GetActiveChord() end
    end
    lines[#lines+1]='Interface cursor shown: '..shown(db and db.Cursor)
    local discovered,discoveryReason=Addon.RingDiscovery.Capture(api,Addon.guid)
    lines[#lines+1]='Ring discovery is read-only; ring projection and exact gesture remain pending.'
    if discovered then
        for _,form in ipairs(discovered.forms) do lines[#lines+1]='Native stance '..form.nativeStanceSlot..': spell '..form.spell..' active='..tostring(form.active)..' castable='..tostring(form.castable) end
        lines[#lines+1]='Current pet: '..tostring(discovered.pet.guid or 'none')
        for _,pet in ipairs(discovered.pet.actions) do lines[#lines+1]='Native pet slot '..pet.action..': '..pet.name..' autocast allowed='..tostring(pet.autoCastAllowed)..' enabled='..tostring(pet.autoCastEnabled) end
        for _,reason in ipairs(discovered.pending) do lines[#lines+1]='Discovery pending: '..reason end
    else lines[#lines+1]='Discovery pending: '..tostring(discoveryReason) end
    local context=Addon.UIContexts
    local input=context and context.input
    if input then
        lines[#lines+1]='Native UI context: '..tostring(context.context and context.context.kind or 'none')
        local keys={}
        for key,state in pairs(input.states) do if state.active or state.front then keys[#keys+1]=key end end
        table.sort(keys)
        for _,key in ipairs(keys) do
            local state=input.states[key]
            local row=state.widget:GetOverride(true)
            lines[#lines+1]=key..' UI generation='..state.generation..' active='..tostring(state.active)
                ..' allowed='..tostring(state.allowed)..' held='..tostring(state.widget:GetAttribute('cpf-ui-held'))
                ..' native owner='..tostring(row and row.owner and row.owner.GetName and row.owner:GetName() or 'unnamed')
                ..' target='..tostring(state.target and state.target.GetName and state.target:GetName() or 'none')
        end
    end
    lines[#lines+1]=''
    lines[#lines+1]='Saved -> effective bindings (engine overrides may change ownership):'
    for _,modifier in ipairs(modifiers) do
        for _,button in ipairs(buttons) do
            local key=modifier..button
            local saved,effective=api.GetBindingAction(key),api.GetBindingAction(key,true)
            local claim=db and db.Layers.GetChordClaim and db.Layers:GetChordClaim(key)
            lines[#lines+1]=key..': '..tostring(saved or '')..' -> '..tostring(effective or '')..(claim and ' [claim: '..claim..']' or '')
        end
    end
    lines[#lines+1]=''
    lines[#lines+1]='Resolved native button display/click state:'
    for _,bankID in ipairs({'Base','L2','R2','L2R2'}) do
        local bank=api['ConsolePortGroup'..bankID]
        if bank and bank.buttons then
            for _,key in ipairs(buttons) do
                local button=bank.buttons[key]
                if button then
                    local kind=button:GetAttribute('type')
                    local field=button:GetAttribute('action_field')
                    local action=field and button:GetAttribute(field)
                    lines[#lines+1]=bankID..' '..key..': '..tostring(kind)..' '..tostring(action or '')..' / displayed '..tostring(button._state_type)..' '..tostring(button._state_action)..' / held '..tostring(button:GetAttribute('cpf-held') or false)
                end
            end
        end
    end
    if Addon.capabilities then
        lines[#lines+1]=''
        lines[#lines+1]='Dependency readiness:'
        local names={}
        for name in pairs(Addon.capabilities.modules) do names[#names+1]=name end
        table.sort(names)
        for _,name in ipairs(names) do
            local module=Addon.capabilities.modules[name]
            lines[#lines+1]=name..' '..tostring(module.version)..' installed='..tostring(module.installed)..' enabled='..tostring(module.enabled)..' loaded='..tostring(module.loaded)
        end
    end
    if Addon.db then
        lines[#lines+1]=''
        lines[#lines+1]='Retained transactions (backups are not deleted):'
        local ids={}
        for id in pairs(Addon.db.transactions) do ids[#ids+1]=id end
        table.sort(ids,function(a,b) return tonumber(a)<tonumber(b) end)
        for _,id in ipairs(ids) do
            local journal=Addon.db.transactions[id]
            lines[#lines+1]=id..' '..journal.guid..' '..journal.status..' steps='..#journal.steps..' recovery='..#journal.recovery
        end
    end
    lines[#lines+1]=''
    for _,entry in ipairs(Addon.Diagnostics.entries) do lines[#lines+1]=entry.kind..': '..entry.message end
    return table.concat(lines,'\n')
end
function Proof:Show(api,details)
    if api.InCombatLockdown() then return false,'proof panel opens out of combat; /cpf status remains available' end
    if not self.frame then
        local frame=api.CreateFrame('Frame','ConsolePortForeverProof',api.UIParent,'BackdropTemplate')
        self.frame=frame
        frame:SetSize(760,560) frame:SetPoint('CENTER') frame:SetFrameStrata('DIALOG') frame:EnableMouse(true)
        frame:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
        frame:SetBackdropColor(0.04,0.05,0.07,1)
        local close=api.CreateFrame('Button',nil,frame,'UIPanelCloseButton') close:SetPoint('TOPRIGHT',-3,-3)
        local scroll=api.CreateFrame('ScrollFrame',nil,frame,'UIPanelScrollFrameTemplate')
        scroll:SetPoint('TOPLEFT',22,-36) scroll:SetPoint('BOTTOMRIGHT',-36,18)
        local content=api.CreateFrame('Frame',nil,scroll) content:SetSize(694,1)
        self.text=content:CreateFontString(nil,'ARTWORK','GameFontHighlightSmall')
        self.text:SetPoint('TOPLEFT') self.text:SetWidth(690) self.text:SetJustifyH('LEFT') self.text:SetJustifyV('TOP')
        self.content=content scroll:SetScrollChild(content)
        api.UISpecialFrames[#api.UISpecialFrames+1]='ConsolePortForeverProof'
        if api.ConsolePort and api.ConsolePort.AddInterfaceCursorFrame then api.ConsolePort:AddInterfaceCursorFrame(frame) end
    end
    self.text:SetText(details or self:Text(api)) self.content:SetHeight(math.max(500,self.text:GetStringHeight()+20))
    self.frame:Show()
    return true
end
