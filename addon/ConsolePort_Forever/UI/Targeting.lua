local _,Addon=...
local UI={}
Addon.TargetingUI=UI
local order={'default','cursor','player','manual'}
local contexts={'general','vehicle','override','temporary','extra'}
local contextLabels={general='Ordinary abilities',vehicle='Vehicle UI',override='Override bar',temporary='Temporary bar',extra='Extra action'}
local labels={cursor='At cursor',player='At player',manual='Manual placement'}
local function Label(mode,id,context,qualified)
    if mode=='default' then
        if not qualified and id then return 'Default: native targeting' end
        return 'Default: '..labels[Addon.TargetingPreferences.Default(id,context)]
    end
    return labels[mode]
end
local function Font(parent,text,x,y)
    local font=parent:CreateFontString(nil,'OVERLAY','GameFontNormal')
    font:SetPoint('TOPLEFT',x,y) font:SetText(text)
    return font
end
function UI:Initialize(api)
    if api.InCombatLockdown() then return end
    if self.panel or not api.ConsolePortConfig or type(api.ConsolePortConfig.CreatePanel)~='function' then return end
    local bridge=Addon.adapters and Addon.adapters.consoleport
    if not bridge or bridge.api.version~='3.3.10' then return end
    local panel=api.ConsolePortConfig:CreatePanel({name='Targeting',description='Account-wide ground placement preferences'})
    self.panel=panel
    function panel:OnLoad() self:SetScript('OnShow',function() UI:Render(api) end) end
    function panel:OnDefaults()
        if not UI.draft then return end
        local _,class=api.UnitClass('player')
        for _,id in ipairs(Addon.TargetingPreferences.Classes[class] or {}) do UI.draft.spells[id]=nil end
        for key in pairs(Addon.TargetingPreferences.Contexts) do UI.draft.contexts[key]=nil end
        UI.draft.contextSpells={}
        UI:Render(api,true)
    end
end
function UI:Render(api,retainDraft)
    if not Addon.db or api.InCombatLockdown() then return end
    local canvas,new=self.panel:GetCanvas()
    canvas:Show()
    if new or not canvas.__cpfTargeting then
        canvas.__cpfTargeting=true
        Font(canvas,'Ground placement',20,-14)
        Font(canvas,'Shared across this account and every specialization.',20,-38)
        Font(canvas,'Cursor/player skip the ground selector; Manual keeps native placement.',20,-62)
        local context=api.CreateFrame('Button',nil,canvas,'UIPanelButtonTemplate')
        context:SetSize(250,28) context:SetPoint('TOPLEFT',20,-92)
        context:SetScript('OnClick',function()
            for i,key in ipairs(contexts) do if key==(UI.context or 'general') then UI.context=contexts[i%#contexts+1] break end end
            UI:Render(api,true)
        end)
        canvas.context=context
        local id=api.CreateFrame('EditBox',nil,canvas,'InputBoxTemplate')
        id:SetSize(100,28) id:SetPoint('TOPLEFT',320,-92)
        id:SetAutoFocus(false) id:SetNumeric(true)
        canvas.spellID=id
        local add=api.CreateFrame('Button',nil,canvas,'UIPanelButtonTemplate')
        add:SetSize(220,28) add:SetPoint('LEFT',id,'RIGHT',12,0) add:SetText('Add spell ID')
        add:SetScript('OnClick',function()
            local spellID=tonumber(id:GetText())
            local info=spellID and spellID>0 and spellID%1==0 and api.C_Spell.GetSpellInfo(spellID)
            if not info or type(info.name)~='string' then canvas.status:SetText('Enter a valid spell ID.') return end
            UI.added=UI.added or {} UI.added[spellID]=true
            local bucket=UI.context=='general' and UI.draft.spells or UI.draft.contextSpells[UI.context]
            if bucket[spellID]==nil then bucket[spellID]='default' end
            UI:Render(api,true) canvas.status:SetText('Choose placement, then Apply.')
        end)
        canvas.add=add
        local scroll=api.CreateFrame('ScrollFrame',nil,canvas,'UIPanelScrollFrameTemplate')
        scroll:SetPoint('TOPLEFT',20,-132) scroll:SetPoint('BOTTOMRIGHT',-40,64)
        local child=api.CreateFrame('Frame',nil,scroll) child:SetSize(680,1) scroll:SetScrollChild(child)
        canvas.scroll,canvas.child,canvas.rows=scroll,child,{}
        local apply=api.CreateFrame('Button',nil,canvas,'UIPanelButtonTemplate')
        apply:SetSize(150,28) apply:SetPoint('BOTTOMLEFT',20,24) apply:SetText('Apply')
        apply:SetScript('OnClick',function()
            local ok,reason=Addon.TargetingPreferences.Apply(Addon.db,UI.draft,api)
            if ok then
                local refreshed,ready,detail=pcall(Addon.RefreshModes,Addon)
                if not refreshed or ready==false then reason='Saved; '..(detail or 'targeting setup is pending.') end
            end
            canvas.status:SetText(reason or 'Saved for this account.')
        end)
        canvas.apply=apply
        local revert=api.CreateFrame('Button',nil,canvas,'UIPanelButtonTemplate')
        revert:SetSize(150,28) revert:SetPoint('LEFT',apply,'RIGHT',12,0) revert:SetText('Revert changes')
        revert:SetScript('OnClick',function() UI:Render(api) end)
        canvas.revert=revert
        canvas.status=Font(canvas,'',20,-82)
        canvas.status:ClearAllPoints() canvas.status:SetPoint('BOTTOMLEFT',340,30)
    end
    if not retainDraft then
        local saved=Addon.TargetingPreferences.Read(Addon.db)
        self.draft=Addon.TargetingPreferences.Validate(saved) and Addon.Core.Copy(saved) or {spells={},contexts={}}
        self.draft.spells=self.draft.spells or {} self.draft.contexts=self.draft.contexts or {}
        self.draft.contextSpells=self.draft.contextSpells or {}
        canvas.status:SetText(Addon.db.shared.runtimePolicy.groundTargetingEnabled and '' or 'Enable ground placement in Forever setup.')
    end
    for _,row in ipairs(canvas.rows) do row:Hide() end
    local _,class=api.UnitClass('player')
    self.context=self.context or 'general'
    self.draft.contextSpells=self.draft.contextSpells or {}
    if self.context~='general' then self.draft.contextSpells[self.context]=self.draft.contextSpells[self.context] or {} end
    canvas.context:SetText(contextLabels[self.context])
    local observed=Addon.Core.Copy(Addon.GroundTargeting.observed or {})
    for id in pairs(self.added or {}) do observed[id]=true end
    local rows=Addon.TargetingPreferences.Rows(class,api,observed,self.draft)
    for _,context in ipairs({'vehicle','override','temporary','extra'}) do
        rows[#rows+1]={context=context,name=({vehicle='Vehicle ground spells',override='Override ground spells',temporary='Temporary ground spells',extra='Extra-action ground spells'})[context],known=true}
    end
    for index,entry in ipairs(rows) do
        local row=canvas.rows[index]
        if not row then
            row=api.CreateFrame('Frame',nil,canvas.child) row:SetSize(680,44)
            row.title=Font(row,'',0,-8)
            row.choice=api.CreateFrame('Button',nil,row,'UIPanelButtonTemplate')
            row.choice:SetSize(240,30) row.choice:SetPoint('TOPLEFT',340,0)
            canvas.rows[index]=row
        end
        row:ClearAllPoints() row:SetPoint('TOPLEFT',0,-(index-1)*44) row:Show()
        row.title:SetText(entry.name..(entry.id and (' ('..entry.id..')') or ''))
        local bucket=entry.context and self.draft.contexts or (self.context=='general' and self.draft.spells or self.draft.contextSpells[self.context])
        local key=entry.context or entry.id
        local function update()
            if not entry.context and self.context~='general' and (not bucket[key] or bucket[key]=='default') then
                local inherited=Addon.TargetingPreferences.Resolve(self.draft,entry.id,self.context)
                local qualified=Addon.TargetingPreferences.Qualified(self.draft,entry.id,self.context)
                row.choice:SetText('Inherited: '..(qualified and labels[inherited] or 'native targeting'))
            else row.choice:SetText(Label(bucket[key] or 'default',entry.id,entry.context,entry.known)) end
        end
        row.choice:SetScript('OnClick',function()
            local selected=bucket[key] or 'default'
            for i,mode in ipairs(order) do if mode==selected then bucket[key]=order[i%#order+1] break end end
            update() canvas.status:SetText('Unsaved changes')
        end)
        update()
    end
    canvas.child:SetHeight(math.max(1,#rows*44))
    canvas.scroll:SetVerticalScroll(0)
end
local events=CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED') events:RegisterEvent('PLAYER_LOGIN')
events:SetScript('OnEvent',function() UI:Initialize(_G) end)
