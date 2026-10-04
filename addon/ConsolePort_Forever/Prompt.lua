local _, Addon = ...
local Prompt = {generation=0}
Addon.Prompt = Prompt
local function Display(value,full)
    if Addon.Core.IsNil(value) then return "Unset" end
    if type(value)=="table" then
        local n=0 for _ in pairs(value) do n=n+1 end
        return "Table ("..n.." fields)"
    end
    if value=="" then return "Unbound / disabled" end
    local text=tostring(value)
    return not full and #text>120 and text:sub(1,117).."..." or text
end
function Prompt.Differences(before,value)
    local lines={}
    local function visit(old,new,prefix,depth)
        if Addon.Core.Equal(old,new) then return end
        local oldTable=type(old)=="table" and not Addon.Core.IsNil(old)
        local newTable=type(new)=="table" and not Addon.Core.IsNil(new)
        if depth<20 and (oldTable or newTable) then
            if (not oldTable and not Addon.Core.IsNil(old)) or (not newTable and not Addon.Core.IsNil(new)) then
                lines[#lines+1]=((prefix~="" and prefix..": " or "")..Display(old,true).." -> "..Display(new,true)):gsub("|","||")
            end
            local keys,ordered={},{}
            local a,b=oldTable and old or {},newTable and new or {}
            for key in pairs(a) do keys[key]=true end for key in pairs(b) do keys[key]=true end
            for key in pairs(keys) do ordered[#ordered+1]=key end
            table.sort(ordered,function(a,b) return tostring(a)<tostring(b) end)
            if #ordered==0 then lines[#lines+1]=(prefix..": "..Display(old,true).." -> "..Display(new,true)):gsub("|","||") end
            for _,key in ipairs(ordered) do visit(Addon.Core.Encode(a[key]),Addon.Core.Encode(b[key]),prefix=="" and tostring(key) or prefix.."."..tostring(key),depth+1) end
        else
            local text=(prefix~="" and prefix..": " or "")..Display(old,true).." -> "..Display(new,true)
            lines[#lines+1]=text:gsub("|","||")
        end
    end
    visit(before,value,"",0)
    return lines
end
function Prompt:Initialize(api)
    self.api=api
    api.dialogs.CPF_BINDING_INSPECT={text="To review this backup, temporarily inspect the native account and character binding banks? Your current view, including unsaved keys, will be returned after inspection. No binding bank is saved until you apply the separate restore review.",button1="Inspect banks",button2="Cancel",
        OnAccept=function(_,data) data.accept() end,OnCancel=function(_,data) data.cancel() end,
        OnHide=function(_,data) if data then data.cancel() end end,
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    api.dialogs.CPF_PLAN_REVIEW={text="%s",button1="Review",button2="Cancel",
        OnAccept=function(_,data) data.next() end,OnCancel=function(_,data) data.cancel() end,
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    api.dialogs.CPF_FIELD_REVIEW={text="%s",button1="Use proposed",button2="Keep mine",button3="Cancel all",button4="Details",selectCallbackByIndex=true,
        OnButton1=function(_,data) data.decided=true data.choose("accept") end,
        OnButton2=function(_,data) data.decided=true data.choose("keep") end,
        OnButton3=function(_,data) data.decided=true data.cancel() end,
        OnButton4=function(_,data) data.decided=true data.details() end,
        OnHide=function(_,data) if data and not data.decided then data.cancel() end end,
        timeout=0,whileDead=true,hideOnEscape=true,noCancelOnEscape=true,preferredIndex=3}
    api.dialogs.CPF_PLAN_APPLY={text="%s",button1="Apply",button2="Cancel",
        OnAccept=function(_,data) data.apply() end,OnCancel=function(_,data) data.cancel() end,
        timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
    api.dialogs.CPF_RELOAD={text="Configuration saved. Reload to finish applying the selected changes?",button1="Reload now",button2="Later",
        OnAccept=function() api.reload() end,timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
end
function Prompt:InspectBindings(onAccept,onCancel)
    if self.active then return false end
    local active={} self.active=active
    local function finish(callback)
        if self.active~=active then return end
        self:Cancel()
        self.api.defer(callback)
    end
    if not self.api.show("CPF_BINDING_INSPECT",nil,nil,{accept=function() finish(onAccept) end,cancel=function() finish(onCancel) end}) then self:Cancel() return false end
    return true
end
function Prompt:Cancel()
    self.generation=self.generation+1
    self.active=nil
end
function Prompt:Show(plan,onApply,onDecline)
    if self.active then return false,"review already open" end
    self.generation=self.generation+1
    local generation=self.generation
    local active={plan=plan,resolutions={},index=1,generation=generation,fields={}}
    for _,field in ipairs(plan.conflicts) do active.fields[#active.fields+1]=field end
    for _,field in ipairs(plan.operations) do active.fields[#active.fields+1]=field end
    self.active=active
    local function valid() return self.active==active and self.generation==generation end
    local function cancel()
        if not valid() then return end
        self:Cancel()
        if onDecline then onDecline() end
    end
    local function defer(callback)
        self.api.defer(function() if valid() then callback() end end)
    end
    local function show(name,message,data)
        if not self.api.show(name,message,nil,data) then cancel() return false end
        return true
    end
    local function final()
        local accepted=#plan.operations
        for _,field in ipairs(plan.operations) do if active.resolutions[field.id]=="keep" then accepted=accepted-1 end end
        for _,decision in pairs(active.resolutions) do if decision=="accept" then accepted=accepted+1 end end
        local message=("Apply %d reviewed changes? Your current configuration will be backed up.\n\n%d features remain pending; existing access is retained."):format(accepted,#plan.deferred)
        if plan.bindingInspection then message=message.."\n\nNative banks may be temporarily selected for verification, including after reload. Accepted key changes and the selected bank are saved; newer keys you kept remain." end
        show("CPF_PLAN_APPLY",message,{cancel=cancel,apply=function()
            if not valid() then return end
            self:Cancel()
            onApply(active.resolutions)
        end})
    end
    local nextField
    nextField=function()
        local field=active.fields[active.index]
        if not field then final() return end
        local label=field.label or field.id
        local differences=Prompt.Differences(field.before,field.value)
        local preview={}
        for index=1,math.min(8,#differences) do
            local line=differences[index]
            preview[#preview+1]=#line>200 and line:sub(1,197).."... (Details)" or line
        end
        if #differences>8 then preview[#preview+1]=(#differences-8).." more differences; select Details to read all." end
        local message=label.."\n\n"..table.concat(preview,"\n").."\n\nChoose which value to keep."
        show("CPF_FIELD_REVIEW",message,{cancel=cancel,details=function()
            defer(function()
                if self.api.details then self.api.details(label.."\n\n"..table.concat(differences,"\n")) end
                nextField()
            end)
        end,choose=function(decision)
            if not valid() then return end
            active.resolutions[field.id]=decision
            active.index=active.index+1
            defer(nextField)
        end})
    end
    local message=("ConsolePort Forever has %d %s to review.\n\nYour active layout, keyboard bindings and integration settings are captured. No configuration changes occur until you apply the reviewed plan."):format(#plan.operations+#plan.conflicts,plan.restores and "backup fields" or "changes")
    return show("CPF_PLAN_REVIEW",message,{cancel=cancel,next=function() defer(nextField) end})
end
function Prompt:Reload() self.api.show("CPF_RELOAD") end
