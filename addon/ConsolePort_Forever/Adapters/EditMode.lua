local _, Addon = ...
local Core, Edit = Addon.Core, {}
Addon.EditModeAdapter = Edit
function Edit.New(api) return setmetatable({api=api},{__index=Edit}) end
function Edit:Capture()
    local presets=self.api.presets()
    local info=self.api.GetLayouts()
    if type(presets)~="table" or #presets==0 or type(info)~="table" or type(info.layouts)~="table" then return nil,"Edit Mode data unavailable" end
    local index=info.activeLayout
    if type(index)~="number" then return nil,"active layout unknown" end
    local active=index<=#presets and presets[index] or info.layouts[index-#presets]
    if type(active)~="table" or type(active.systems)~="table" then return nil,"active layout missing" end
    local export=self.api.ConvertLayoutInfoToString(active)
    if type(export)~="string" or export=="" then return nil,"active layout export rejected" end
    return {layouts=Core.Copy(info.layouts),activeLayout=index,export=export,active=Core.Copy(active),presetCount=#presets}
end
function Edit:Proposal(snapshot,name,managedName)
    local proposed=Core.Copy(snapshot)
    local existingIndex
    if managedName then
        for index,layout in ipairs(proposed.layouts) do if layout.layoutName==managedName then existingIndex=index end end
    end
    -- First install always clones the actually active layout. A matching display
    -- name alone is not proof of companion ownership.
    if existingIndex and snapshot.active.layoutName==managedName then return proposed end
    local count=0
    for _,layout in ipairs(proposed.layouts) do if layout.layoutType==self.api.AccountType then count=count+1 end end
    if self.api.limit and count>=self.api.limit then return nil,"account layout capacity reached" end
    for _,layout in ipairs(proposed.layouts) do
        if layout.layoutName==name then return nil,"managed profile name already belongs to another layout" end
    end
    local clone=Core.Copy(snapshot.active)
    clone.layoutName,clone.layoutType=name,self.api.AccountType
    clone.layoutIndex=nil
    local insertAt=#proposed.layouts+1
    for index,layout in ipairs(proposed.layouts) do if layout.layoutType==self.api.CharacterType then insertAt=index break end end
    table.insert(proposed.layouts,insertAt,clone)
    proposed.activeLayout=proposed.presetCount+insertAt
    proposed.active=clone
    proposed.export=self.api.ConvertLayoutInfoToString(clone)
    return proposed
end
function Edit:read(path)
    assert(path[1]=="state")
    local state,reason=self:Capture()
    if not state then error(reason) end
    return state
end
function Edit:equal(a,b)
    if type(a)~='table' or type(b)~='table' or a.activeLayout~=b.activeLayout
        or a.presetCount~=b.presetCount or a.export~=b.export or #a.layouts~=#b.layouts then return false end
    -- The native cache serializes coordinates at its export precision and
    -- reconstructs incidental fields on reload. Compare the native persisted
    -- representation plus selection/name/type, rather than Lua float bits.
    for index,layout in ipairs(a.layouts) do
        local expected=b.layouts[index]
        if layout.layoutName~=expected.layoutName or layout.layoutType~=expected.layoutType
            or self.api.ConvertLayoutInfoToString(layout)~=self.api.ConvertLayoutInfoToString(expected) then return false end
    end
    return a.active.layoutName==b.active.layoutName and a.active.layoutType==b.active.layoutType
end
function Edit:write(path,value)
    if self.api.inCombat() or self.api.isEditing() or type(value)~="table" then return false end
    local presets=self.api.presets()
    if #presets~=value.presetCount then return false end
    local combined={}
    for _,p in ipairs(presets) do combined[#combined+1]=Core.Copy(p) end
    for _,p in ipairs(value.layouts) do combined[#combined+1]=Core.Copy(p) end
    local result=self.api.SaveLayouts({layouts=combined,activeLayout=value.activeLayout})
    if result==false then return false end
    if self.api.SetActiveLayout(value.activeLayout)==false then return false end
    local current=self:Capture()
    -- Index and serialized export verify selection; layouts preserve unrelated
    -- saved records. Never call live frame UpdateSystem or import systemInfo.
    return current and self:equal(current,value) or false
end
