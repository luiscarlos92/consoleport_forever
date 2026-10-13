-- Exact CP button state, LAB/Manager OnClick wrappers, Blizzard Wrapped_Click
-- and secure macro/action dispatch. The hardware/terrain engine is a double;
-- this does not certify Retail combat, taint or rendering.
local combat,trusted,hardware=false,false,false
local state={page=1,bonus=0,keydown=true,keyheld=true,pickup=false}
local slots={[1]={'spell',207684},[2]={'spell',116844},[3]={'spell',999},
    [4]={'macro',207684,'spell'},[5]={'item',207684},[6]={'flyout',207684},
    [7]={'spell',888},[8]={'spell',207684,'assistedcombat'},[9]={'spell',1000},[61]={'spell',207684},[73]={'spell',190356},[137]={'spell',777}}
local casts,uses,releases,assistOpens,flyoutHides={},{},{},0,0
local names,overrides,loadRequests={},{},{}
names[207684],names[116844]="Sigil of Misery","Ring of Peace"
function InCombatLockdown() return combat end
function GetActionBarPage() return state.page end
function GetBonusBarOffset() return state.bonus end
function HasVehicleActionBar() return state.family=='vehicle' end
function HasOverrideActionBar() return state.family=='override' end
function HasTempShapeshiftActionBar() return state.family=='temporary' end
function GetVehicleBarIndex() return 12 end
function GetOverrideBarIndex() return 12 end
function GetTempShapeshiftBarIndex() return 12 end
function GetActionInfo(slot) if slots[slot] then return table.unpack(slots[slot]) end end
function IsPressHoldReleaseSpell(id) return id==888 or state.empowered==id end
function IsModifiedClick(name) return name=='PICKUPACTION' and state.pickup end
function IsShiftKeyDown() return state.shift end
function IsControlKeyDown() return state.ctrl end
function IsAltKeyDown() return state.alt end
function GetCVarBool(name)
    if name=='ActionButtonUseKeyDown' then return state.keydown end
    if name=='ActionButtonUseKeyHeldSpell' then return state.keyheld end
    return false
end
function UnitExists(unit) return unit~='none' and unit~='missing' end
function UnitHasVehicleUI() return false end
function UnitCanAttack() return false end
function UnitCanAssist() return false end
function PlayerCanAssist() return false end
function SpellCanTargetItem() return false end
function SpellCanTargetItemID() return false end
function GetCursorInfo() return nil end
function forceinsecure() error('insecure dispatch') end
function securecallfunction(fn,...) return fn(...) end
function RunMacro() error('saved macro route must remain native only') end
C_Macro={RunMacroText=function(text,button)
    assert(hardware and trusted,'macro lacks secure hardware authority')
    assert(button=='ControllerInput' or button=='LeftButton')
    assert(text:match('^/cast %[@cursor%] [^\n]+$') or text:match('^/cast %[@player%] [^\n]+$'),'unexpected macro text')
    casts[#casts+1]={text=text,success=not state.terrainFailure,cursor=state.freeCursor and 'free' or 'camera'}
end}
C_Spell={GetSpellInfo=function(id) if names[id] then return {name=names[id],spellID=id} end end,
    GetOverrideSpell=function(id) return overrides[id] end,
    RequestLoadSpellData=function(id) loadRequests[id]=(loadRequests[id] or 0)+1 end}
function UseAction(slot,unit,button,isKeyPress)
    assert(hardware and trusted) uses[#uses+1]={slot=slot,unit=unit,button=button,key=isKeyPress}
end
function ReleaseAction(slot,unit,button)
    assert(hardware and trusted) releases[#releases+1]={slot=slot,unit=unit,button=button}
end
SpellFlyout={Hide=function() flyoutHides=flyoutHides+1 end,Toggle=function() end}
CPAPI={SecureEnvironmentMixin={}}
local env={Attributes={Update=function(name) return '_childupdate-'..name end},RegisterCallback=function() end}
function CPAPI.GetEnv() return env,{SetCVar=function() end} end
function Mixin(object,...)
    for i=1,select('#',...) do for key,value in pairs(select(i,...)) do object[key]=value end end
    return object
end
function CreateFromMixins(...) return Mixin({},...) end
string.trim=function(value) return value:match('^%s*(.-)%s*$') end
format,tostring,gsub=string.format,tostring,string.gsub
NUM_ACTIONBAR_BUTTONS=12
--@CURRENT_CP
local Frame={}
function Frame:IsProtected() return self.protected~=false end
function Frame:GetAttribute(prefix,name,suffix)
    if not name then return self.attributes[prefix] end
    return self.attributes[prefix..name..suffix] or self.attributes['*'..name..suffix]
        or self.attributes[prefix..name..'*'] or self.attributes['*'..name..'*'] or self.attributes[name]
end
function Frame:SetAttribute(key,value)
    assert(not combat or trusted,'untrusted protected mutation') self.attributes[key]=value
end
function Frame:SetFrameRef(key,value) assert(not combat) self.refs[key]=value end
function Frame:GetFrameRef(key) return self.refs[key] end
function Frame:GetParent() return self.parent end
function Frame:IsShown() return self.shown end
function Frame:IsVisible() return self.shown end
function Frame:GetID() return self.id end
function Frame:SetID(id) self.id=id end
function Frame:CallMethod(method,...) return self[method](self,...) end
function Frame:ButtonContentsChanged(s,kind,value) self._state_type,self._state_action=kind,value end
function Frame:OnTypeChanged() end
function Frame:CalculateAction(button) return SecureButton_GetModifiedAttribute(self,'action',button) end
function Frame:CreateEnvironment(newEnv)
    assert(not combat)
    self.Env=CreateFromMixins(self.Env,newEnv)
    for key,body in pairs(self.Env) do self:SetAttribute(key,CPAPI.ConvertSecureBody(body)) end
end
function Frame:SetState(s,kind,value)
    self:SetAttribute('labtype-'..s,kind) self:SetAttribute('labaction-'..s,value)
    if s==self:GetAttribute('state') then self:RunAttribute('UpdateState',s) end
end
function Frame:RefreshBinding(s,value) self:SetState(s,'action',value) end
function Frame:SetBindings(bindings) for s,value in pairs(bindings) do self:RefreshBinding(s,value) end end
local function frame(parent)
    return setmetatable({parent=parent,attributes={},refs={},scripts={},shown=true}, {__index=Frame})
end
function GetFrameMetatable() return {__index=Frame} end
function CopyTable(value) return Addon.Core.Copy(value) end
--@NATIVE_MODIFIED_ATTRIBUTES
SECURE_ACTIONS={}
--@NATIVE_SECURE_ACTIONS
--@NATIVE_SECURE_DISPATCH
--@NATIVE_RESTRICTED_ENV
-- Exact Blizzard handle validation: an unprotected cursor is legal outside
-- lockdown and illegal inside it, even when hidden. Earlier doubles missed it.
local LOCAL_CHECK_Frame=Frame
local function GetFrameHandleFrame(handle) return handle,handle:IsProtected() end
local function AddReferencedFrame() end
local function CheckForbidden() return false end
local function PropagateForbiddenToReferencedFrames() end
local function scrub(...) return ... end
local HANDLE={}
--@NATIVE_HANDLE_ACCESS
local function run(header,self,signature,body,...)
    -- Use Blizzard's actual environment manager. Only control is supplied;
    -- inventing an owner parameter previously masked a fatal Retail error.
    local restricted,manage=CreateRestrictedEnvironment(_G)
    local fn=assert(load('return function('..signature..') '..CPAPI.ConvertSecureBody(body)..' end','restricted','t',restricted))()
    -- Restricted snippets receive handles, not mutable raw-frame fields.
    local function handle(raw)
        if not raw then return nil end
        return {GetAttribute=function(_,key) return raw:GetAttribute(key) end,
            SetAttribute=function(_,key,value) raw:SetAttribute(key,value) end,
            GetFrameRef=function(_,key) return handle(raw:GetFrameRef(key)) end,
            IsShown=function() return HANDLE.IsShown(raw) end,IsVisible=function() return raw:IsVisible() end,
            GetParent=function() return handle(raw:GetParent()) end,
            SetID=function(_,id) raw:SetID(id) end,GetID=function() return raw:GetID() end,
            CallMethod=function(_,method,...) return raw:CallMethod(method,...) end,
            RunAttribute=function(_,key,...) return raw:RunAttribute(key,...) end,
            Hide=function() raw.shown=false end}
    end
    local before=trusted trusted=true
    header.working=header.working or {}
    local working,control=header.working,handle(header)
    manage(true,working,control)
    local results=table.pack(pcall(fn,handle(self),...))
    manage(false,working,control)
    trusted=before assert(results[1],results[2])
    return table.unpack(results,2,results.n)
end
function Frame:RunAttribute(key,...)
    return run(self.header or self,self,'self,...',assert(self:GetAttribute(key),'missing snippet '..key),...)
end
function Frame:Execute(body)
    assert(not combat)
    if body=='owner = owner or self' then return run(self,self,'self',body) end
    local button=self:GetFrameRef('cpfUpdateButton')
    assert(body:find('cpfUpdateButton',1,true))
    button:RunAttribute('UpdateState',button:GetAttribute('state'))
end
function Frame:RegisterPageResponse(body) self:SetAttribute('ActionPageChanged',body) end
local function SecureHandler_Other_Execute(header,self,signature,body,...)
    return run(header,self,signature,body,...)
end
local function IsWrapEligible() return true end
local function SafeCallWrappedHandler(self,fn,...) if fn then return fn(self,...) end end
local function securecall(fn,...) return fn(...) end
--@NATIVE_WRAPPED_CLICK
local wrapCount=0
function Frame:WrapScript(button,event,pre,post)
    assert(not combat) wrapCount=wrapCount+1
    local owner=self
    local previous=button.scripts[event]
    button.scripts[event]=function(self,key,down,...)
        if event=='OnClick' then return Wrapped_Click(self,owner,pre,post,previous,key,down,...) end
        run(owner,self,'self,button,down',pre,key,down)
        if previous then previous(self,key,down) end
    end
end
local api={CPAPI=CPAPI,InCombatLockdown=InCombatLockdown,GetBindingKey=function() return 'K' end,
    C_Spell=C_Spell,C_Macro=C_Macro,GetActionInfo=GetActionInfo,GetCVarBool=GetCVarBool}
for _,family in ipairs({'Vehicle','Override','TempShapeshift'}) do
    api['Has'..family..'ActionBar']=_G['Has'..family..'ActionBar']
    api['Get'..family..'BarIndex']=_G['Get'..family..'BarIndex']
end
function api.hooksecurefunc(object,method,callback)
    local previous=object[method]
    object[method]=function(...) local value=previous(...) callback(...) return value end
end
local db={Cursor=frame(),Raid=frame(),TargetRing=frame()}
db.Cursor.protected=false -- Official Cursor.xml has no secure inheritance.
for _,owner in pairs(db) do owner.shown=false end
function db.TargetRing:OpenAssist(id)
    if id==116844 or id==999 then self.shown=true assistOpens=assistOpens+1 return true end
end
function db.TargetRing:GetHoveredUnit() return 'party1' end
function db.TargetRing:CloseAssist() self.shown=false end
local manager=frame()
local bridge={db=db,api={version='3.3.10'},bar={Layout={children={}},Manager=manager},Probe=function() return true end}
function manager:GetBindings(key) return {['']=1,['SHIFT-']=2,['CTRL-']=3,['CTRL-SHIFT-']=61} end
-- Manager owns a distinct managed environment, as it does in Retail.
local managerEnvironment={ring=db.TargetRing,cursor=db.Raid,pager={GetSpellID=function(_,slot) return select(2,GetActionInfo(slot)) end}}
function manager:Hook(button,event,pre,post)
    local native=button.scripts[event]
    function managerEnvironment.ring:RunAttribute(key,...) return self[key](self,...) end
    function managerEnvironment.pager:RunAttribute(key,...) return self[key](self,...) end
    -- Preserve snippet globals such as assist in a per-manager closure.
    local source='return function(self,button,down) '..CPAPI.ConvertSecureBody(pre)..' end'
    local function wrapped(self,key,down,...)
        local globals=setmetatable(managerEnvironment,{__index=_G})
        local before=assert(load(source,'native-manager','t',globals))()
        local after=assert(load('return function(self,message,button,down) '..CPAPI.ConvertSecureBody(post)..' end','native-manager-post','t',globals))()
        local changed,message=before(self,key,down)
        if changed==false then return end
        if changed then key=tostring(changed) end
        if native then native(self,key,down,...) end
        if message~=nil then after(self,message,key,down) end
    end
    button.scripts[event]=wrapped
end
local Manager=manager
--@NATIVE_MANAGER_REROUTE
--@NATIVE_LAB_CLICK_FACTORY
for _,bank in ipairs({'Base','L2','R2','L2R2'}) do
    local group=frame()
    group.buttons={}
    bridge.bar.Layout.children[bank]={type='Group'} api['ConsolePortGroup'..bank]=group
    for _,key in ipairs({'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}) do
        local button=frame(group) button.id=key button.header=group button.Env=Addon.Core.Copy(env.SlotButton.Env)
        button.scripts.OnClick=SecureActionButton_OnClick
        button:CreateEnvironment({IsFlyoutActive='return false'})
        button:SetAttribute('state','') button:SetAttribute('LABdisableDragNDrop',true)
        installLABClick(button)
        manager:RegisterReroute(button)
        group.buttons[key]=button
    end
end
