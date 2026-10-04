local _,Addon=...
local Access={}
Addon.TemporaryAccess=Access

-- Retain exit and actions 9-12 at the former extra-page anchor. These are
-- supplemental native actions, not another bank or a new key assignment.
Access.Response=[[
    local page;
    if self:GetAttribute('cpf-enabled') then
        if HasVehicleActionBar() then page=GetVehicleBarIndex()
        elseif HasOverrideActionBar() then page=GetOverrideBarIndex()
        elseif HasTempShapeshiftActionBar() then page=GetTempShapeshiftBarIndex() end;
    end;
    -- The editable skyriding bonus page is not evidence of temporary
    -- vehicle/quest overflow. Keep its approved eight cells on L2R2 only.
    local visible=false;
    for index=9,12 do
        local button=self:GetFrameRef('action'..index);
        local action=page and ((page-1)*12+index);
        if button:GetAttribute('cpf-held') then
            -- Retain the original press owner until its release.
            visible=true;
        elseif action and HasAction(action) then
            button:SetAttribute('action',action); button:Show(); visible=true;
        else button:Hide() end;
    end;
    local exit=self:GetFrameRef('exit');
    if exit:GetAttribute('cpf-held') then visible=true;
    else
        if page and CanExitVehicle() then exit:Show(); visible=true; else exit:Hide() end;
    end;
    -- A shown empty parent is still a native cursor/window owner.
    if visible then self:Show() else self:Hide() end;
]]
function Access:Probe(bridge,api)
    return bridge.db and bridge.db.Pager and type(bridge.db.Pager.RegisterHeader)=='function'
        and type(api.CreateFrame)=='function' and api.UIParent~=nil
end
function Access:Enable(bridge,api)
    if not self.frame then
        local frame=api.CreateFrame('Frame','ConsolePortForeverTemporaryAccess',api.UIParent,'SecureHandlerBaseTemplate')
        frame:SetSize(200,36)
        frame:SetPoint('BOTTOM',api.UIParent,'BOTTOM',458,20)
        frame:SetAttribute('ActionPageChanged',self.Response)
        frame:Hide()
        self.frame,self.api=frame,api
        self.buttons={}
        for index=9,13 do
            local exit=index==13
            local button=api.CreateFrame('Button',nil,frame,'SecureActionButtonTemplate')
            button:SetSize(36,36)
            button:SetPoint('LEFT',frame,'LEFT',(index-9)*40,0)
            button:RegisterForClicks('AnyDown','AnyUp')
            button:SetAttribute('useOnKeyDown',false)
            button:SetAttribute('type',exit and 'leavevehicle' or 'action')
            local icon=button:CreateTexture(nil,'BACKGROUND') icon:SetAllPoints()
            button.icon=icon
            local label=button:CreateFontString(nil,'OVERLAY','GameFontNormalSmall')
            label:SetPoint('BOTTOM',button,'BOTTOM',0,1)
            label:SetText(exit and 'Exit' or tostring(index))
            function button:RefreshIcon()
                local texture=api.C_ActionBar and api.C_ActionBar.GetActionTexture or api.GetActionTexture
                self.icon:SetTexture(exit and 132331 or (texture and texture(self:GetAttribute('action') or 0)))
            end
            button:SetScript('OnShow',button.RefreshIcon)
            if not exit then
                button:SetScript('OnAttributeChanged',function(self,name) if name=='action' then self:RefreshIcon() end end)
            end
            frame:SetFrameRef(exit and 'exit' or 'action'..index,button)
            frame:WrapScript(button,'PreClick',[[if down then self:SetAttribute('cpf-held',true) end]])
            frame:WrapScript(button,'PostClick',[[if not down then
                self:SetAttribute('cpf-held',nil)
                control:RunFor(control,control:GetAttribute('ActionPageChanged'))
            end]])
            frame:WrapScript(button,'OnHide',[[self:SetAttribute('cpf-held',nil)]])
            button:Hide()
            self.buttons[#self.buttons+1]=button
        end
        -- Register once with the same native protected pager as all four banks.
        bridge.db.Pager:RegisterHeader(frame)
        if api.ConsolePort and type(api.ConsolePort.AddInterfaceCursorFrame)=='function' then
            api.ConsolePort:AddInterfaceCursorFrame(frame)
        end
    end
    self.frame:SetAttribute('cpf-enabled',true)
    self.frame:Execute(self.Response)
end
function Access:Disable()
    if self.frame then self.frame:SetAttribute('cpf-enabled',nil) self.frame:Execute(self.Response) end
end
