-- Engine/widget host boundary. Full native Database/Map/Container/Secure and
-- ring/button frontend run below; no copied native selection or custom renderer.
restricted.cos=cos restricted.sin=sin
db.Radial.secureEnv.cos=cos db.Radial.secureEnv.sin=sin
function Region:SetTexCoord(...) self.uv={...} end
local nativeAtlasSetter=Region.SetAtlas
function Region:SetAtlas(atlas,...) nativeAtlasSetter(self,atlas,...) self:SetTexCoord(.11,.21,.31,.41) end
CPAPI.DefaultRingSetID=1 CPAPI.ActionTypeRelease='typerelease'
CPAPI.Static=function(value) return function() return value end end
CPAPI.Index=function(value) return getmetatable(value).__index end
db.ActionMap={}
db.table.spairs=pairs
db.Bindings={Custom={UnitMenu='UnitMenu',MenuRing='MenuRing'},GetDescriptionForBinding=function(_,binding) return nil,nil,binding,134400 end}
function db:Save() end
local ring=CreateFrame('PieMenu','ConsolePortUtilityToggle',UIParent,'ConsolePortUtilityRingTemplate,ConsolePortSecurePie,ConsolePortSlicedPie')
ring:Hide() ring:SetAlpha(1)
ring:RegisterForClicks('AnyDown','AnyUp')
ring:SetScript('OnClick',SecureActionButton_OnClick)
local env={Frame=ring,DisplayButton={},IsDataReady=true,IsSpellValidationReady=true}
function CPAPI.GetEnv() return env,db end
strmatch=string.match
--@NATIVE_LIBSTUB
local nativeLibraries=LibStub:NewLibrary('RelaTable',10)
nativeLibraries.ConsolePort_Rings=env
assert(type(LibStub)=='table' and getmetatable(LibStub).__call,'native callable LibStub not modeled')
DEFAULT='Default' BLUE_FONT_COLOR={GenerateHexColor=function() return '0000ff' end}
tinsert=table.insert tAppendAll=function(dest,src) for _,item in ipairs(src) do dest[#dest+1]=item end end
Clamp=function(n,min,max) return math.min(math.max(n,min),max) end max=math.max
env.callbacks={}
function env:RegisterCallback(name,fn,owner) self.callbacks[name]={fn,owner} end
function env:TriggerEvent(name,...) local row=self.callbacks[name] if row then row[1](row[2],...) end end
--@NATIVE_RING_DATABASE
--@NATIVE_RING_MAP
--@NATIVE_RING_CONTAINER
env.IsDataReady,env.IsSpellValidationReady=true,true
ring.Data={[1]={[0]={}},PaladinAuras={[0]={}, {type='custom',binding='unchanged-aura'}}}
ring.Shared={UserShared={[0]={}}}
ConsolePortRingsShared=ring.Shared
local personalBefore=ring.Data local auraBefore=ring.Data.PaladinAuras local sharedBefore=ring.Shared.UserShared
env.ActionButton={SkinUtility={},Skin={UtilityRingButton=function(button) button.nativeSkinCalls=(button.nativeSkinCalls or 0)+1 end}}
local Lib=env.ActionButton
--@NATIVE_TEXTURE_ADAPTER
--@NATIVE_RING_BUTTON
ring.widgets={}
function Frame:SetID(id) self.id=id end function Frame:GetID() return self.id end
function Frame:GetParent() return self.parent end function Region:GetParent() return self.parent end
function Frame:SetFrameLevel(n) self.level=n end
function Frame:SetPreventSkinning(value) self.preventSkinning=value end
function Frame:Initialize() self.initialized=true end
function Frame:SetRotation(value) self.rotation=value end
function Frame:DisableDragNDrop(value) self.dragDisabled=value end
function Frame:LockHighlight() self.highlighted=true end function Frame:UnlockHighlight() self.highlighted=false end
function Frame:GetSpellId() return nil end function Frame:HideOverlayGlow() end
function Frame:ClearStates() self.states={} end
function Frame:SetState(state,kind,action) self.states=self.states or {} self.states[state]={kind,action} end
GameTooltip={IsOwned=function() return false end}
RunNextFrame=function(fn) fn() end
function ring:TryAcquireRegistered(index)
    if self.widgets[index] then return self.widgets[index],false end
    local button=CreateFrame('Button',nil,self,'SecureActionButtonTemplate')
    Mixin(button,env.DisplayButton) button.icon=button:CreateTexture() button.icon.parent=button
    self.widgets[index]=button return button,true
end
function ring:EnumerateActive() local i=0 return function() i=i+1 return self.widgets[i] end end
function ring:ReleaseAll() end
function ring:ChildUpdate(kind,state)
    assert(kind=='state')
    for _,button in ipairs(self.widgets) do
        local row=button.states[state]
        if row then
            button._state_type,button._state_action=row[1],row[2]
            button.RunCustom=row[1]=='custom' and function() end or nil
            if row[2].texture then button.icon:SetTexture(row[2].texture) end
        end
    end
end
function ring:GetObjectByIndex(index) return self.widgets[index] end
function ring:GetCurrentMetadataValue(key) return (self.Shared[self:GetAttribute('state')] or {[0]={}})[0][key] end
function ring:SetFocusByIndex(index)
    for _,button in ipairs(self.widgets) do if button.id==index then button:OnFocus() else button:OnClear() end end
    return self.widgets[index]
end
function ring:CheckCursorInfo() end -- no held cursor in these hardware fixtures
function ring:OnSelection(running) self.report=running and {} or nil end
function ring:OnSelectionAttributeAdded(key,value) self.report[key]=value end
function ring:SafeSetMetadata(set,key,value) self.Shared[set][0][key]=value end
function ring:SafeRemoveAction(set,index) table.remove(self.Shared[set],index) end
function ring:OnPostShow() end
ring.Remove=CreateFrame('Button','ConsolePortUtilityToggleRemove',ring,'SecureActionButtonTemplate')
--@NATIVE_RING_SECURE
db.Radial:Register(ring,'UtilityRing',{sticks={'Camera'},sizer=[[local size=self:GetAttribute('size');]]})
ring:SetScript('OnShow',ring.OnShow) ring:SetScript('OnHide',ring.OnHide)
ring.secureEnv.control=proxy(ring)
ring:OnAxisInversionChanged()
nativeSettings.ringPressAndHold=true nativeSettings.ringStickySelect=false
ring:OnPressAndHoldChanged() ring:OnStickySelectChanged()
ring:SetAttribute('removeButton','PADRSHOULDER') ring:SetAttribute('acceptButton','PAD1')
local anim={SetFromAlpha=function() end,SetToAlpha=function() end}
ring.PulseAnim={PulseIn=anim,PulseOut=anim}
ring.StickySlice={SetShown=function() end,SetAlpha=function() end,SetIndex=function(self,index,size) self.index=index end}
function ring:SetSliceTextAlpha(value) self.sliceTextAlpha=value end
function ring:SetSliceText(index,text) self.sliceText=self.sliceText or {} self.sliceText[index]=text end
--@NATIVE_RING_FRONTEND
-- Native OnSelection builds ReportData; retained script references use it.
function ring:GetNumVisible() return self:GetAttribute('size') or 0 end
function ring:RegisterColorCallbacks() end
ring:UpdateColorSettings()
