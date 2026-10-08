-- Exact CP button state, LAB/Manager OnClick wrappers, Blizzard Wrapped_Click
-- and secure macro/action dispatch. The hardware/terrain engine is a double;
-- this does not certify Retail combat, taint or rendered cursor placement.
local combat,trusted,hardware=false,false,false
local state={page=1,bonus=0,keydown=true,keyheld=true,pickup=false}
local slots={[1]={'spell',207684},[2]={'spell',116844},[3]={'spell',999},
    [4]={'macro',207684,'spell'},[5]={'item',207684},[6]={'flyout',207684},
    [7]={'spell',888},[8]={'spell',207684,'assistedcombat'},[61]={'spell',207684},[73]={'spell',190356},[137]={'spell',777}}
local casts,uses,releases,assistOpens,flyoutHides={},{},{},0,0
local names,overrides,loadRequests={},{},{}
for id,name in pairs(Addon.GroundSpells) do names[id]=name end
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
            IsShown=function() return raw:IsShown() end,IsVisible=function() return raw:IsVisible() end,
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
    button.scripts[event]=function(self,key,down)
        if event=='OnClick' then return Wrapped_Click(self,owner,pre,post,previous,key,down,true,true) end
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
    local function wrapped(self,key,down)
        local globals=setmetatable(managerEnvironment,{__index=_G})
        local before=assert(load(source,'native-manager','t',globals))()
        local after=assert(load('return function(self,message,button,down) '..CPAPI.ConvertSecureBody(post)..' end','native-manager-post','t',globals))()
        local changed,message=before(self,key,down)
        if changed==false then return end
        if changed then key=tostring(changed) end
        if native then native(self,key,down,true,true) end
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
assert(Addon.SecureModes.Install(bridge,api))
assert(Addon.GroundTargeting.Enable(bridge,api,true))
local installedWraps=wrapCount
assert(Addon.GroundTargeting.Enable(bridge,api,true) and wrapCount==installedWraps,'duplicated secure wrappers')
local button=api.ConsolePortGroupBase.buttons.PAD1
local function click(target,down,key)
    local prior=trusted trusted,hardware=true,true
    if target.scripts.PreClick then target.scripts.PreClick(target,key or 'ControllerInput',down) end
    target.scripts.OnClick(target,key or 'ControllerInput',down,true,true)
    if target.scripts.PostClick then target.scripts.PostClick(target,key or 'ControllerInput',down) end
    trusted,hardware=prior,false
end
local function pair(target,key) click(target,true,key) click(target,false,key) end
local function selectSlot(slot)
    state.shift,state.ctrl,state.alt=false,false,false
    local prior,priorCombat=trusted,combat trusted=true combat=false
    button:SetAttribute('state','') button:SetState('', 'action',slot)
    trusted,combat=prior,priorCombat
end
local function configure(target,key,value)
    local prior=combat combat=false target:SetAttribute(key,value) combat=prior
end
local function clear() casts,uses,releases={},{},{} end
combat=true
assert(not pcall(button.SetAttribute,button,'type','macro'),'insecure combat mutation succeeded')
pair(button)
assert(#casts==1 and #uses==0 and #releases==0)
assert(casts[1].text=='/cast [@cursor] Sigil of Misery' and casts[1].cursor=='camera')
assert(button:GetAttribute('type')=='action' and button:GetAttribute('action')==1 and button._state_action==1)
assert(not button:GetAttribute('*type-ControllerInput') and not button:GetAttribute('cpf-ground-pressed'))
assert(not Addon.GroundTargeting.Enable(bridge,api,true) and not Addon.GroundTargeting.Disable(api))
-- Native mouse input, macros/items/flyouts, unknown spells and empowered spells.
for _,slot in ipairs({3,4,5,6,7,8}) do
    selectSlot(slot) clear() db.TargetRing.shown=false
    pair(button)
    assert(#casts==0,'unsupported action was converted '..slot)
end
selectSlot(1) clear() pair(button,'LeftButton') assert(#casts==0 and #uses==1)
state.empowered=207684 clear() pair(button)
assert(#casts==0 and #uses==1 and #releases==1,'recognized ID lost native empower/hold handling')
state.empowered=nil
-- Modified banks and fixed native slots, including the temporary L2R2 family.
clear() state.shift=true button:RunAttribute('UpdateState','SHIFT-') pair(button)
assert(#casts==1 and casts[1].text=='/cast [@cursor] Ring of Peace' and assistOpens==1,'ground help spell opened native assist ring')
clear() state.ctrl=true button:RunAttribute('UpdateState','CTRL-SHIFT-') pair(button)
assert(#casts==1 and button._state_action==61)
local special=api.ConsolePortGroupL2R2.buttons.PADDLEFT
state.family='vehicle' special:RunAttribute('UpdateState','CTRL-SHIFT-') clear() pair(special)
assert(#casts==0 and #uses==1 and uses[1].slot==137)
state.family=nil
-- Default and per-button key-up casting both fire exactly once on release.
combat=false state.keydown=false assert(Addon.GroundTargeting.Enable(bridge,api,true)) combat=true
selectSlot(1) clear() click(button,true) assert(#casts==0)
-- Modifier and slot changes during a hold retain the ground command from press.
slots[1]={'spell',999} state.shift=true button:RunAttribute('UpdateState','SHIFT-')
click(button,false) assert(#casts==1 and casts[1].text=='/cast [@cursor] Sigil of Misery')
slots[1]={'spell',207684} selectSlot(1)
configure(button,'useOnKeyDown',true) clear() pair(button) assert(#casts==1)
configure(button,'useOnKeyDown',false) clear() click(button,true) assert(#casts==0)
click(button,false) assert(#casts==1)
-- The edge is latched even if the CVar changes between press and release.
configure(button,'useOnKeyDown',nil) clear() click(button,true) state.keydown=true
click(button,false) assert(#casts==1,'changed click edge lost or duplicated the cast')
state.keydown=false
-- Existing stale saved macro/unit attributes cannot steal the cursor cast.
configure(button,'macro',17) configure(button,'unit','missing') configure(button,'checkmouseovercast',true)
clear() pair(button) assert(#casts==1 and button:GetAttribute('macro')==17 and button:GetAttribute('unit')=='missing')
configure(button,'macro',nil) configure(button,'unit',nil)
-- Native owner entry while held cancels the cast; no release uses the new slot.
for _,owner in pairs(db) do
    clear() click(button,true) owner.shown=true click(button,false)
    assert(#casts==0 and #uses==0,'owner change released another action') owner.shown=false
end
-- A fresh native assist action still gets the original native selector.
selectSlot(3) clear() local opens=assistOpens pair(button)
assert(#casts==0 and assistOpens==opens+1 and #uses==1 and uses[1].unit=='party1')
selectSlot(1)
-- Hide/disconnect and disable invalidate an outstanding ground release.
clear() click(button,true) button.scripts.OnHide(button) click(button,false) assert(#casts==0 and #uses==0)
clear() click(button,true) combat=false assert(Addon.GroundTargeting.Disable(api)) combat=true
click(button,false) assert(#casts==0 and #uses==0)
combat=false assert(Addon.GroundTargeting.Enable(bridge,api,true)) combat=true
-- Pickup and alternate modified click semantics retain native ownership.
configure(button,'LABdisableDragNDrop',nil) state.pickup=true clear() pair(button) assert(#casts==0)
state.pickup=false configure(button,'LABdisableDragNDrop',true)
configure(button,'shift-type-ControllerInput','action') state.shift=true clear() pair(button) assert(#casts==0)
configure(button,'shift-type-ControllerInput',nil)
configure(button,'shift-macro*',17) clear() pair(button) assert(#casts==0,'alternate saved macro field was overwritten')
configure(button,'shift-macro*',nil) state.shift=false
-- Free cursor is intentionally usable; terrain/range failures stay game-owned.
state.freeCursor=true state.terrainFailure=true clear() pair(button)
assert(#casts==1 and casts[1].cursor=='free' and not casts[1].success and not button:GetAttribute('cpf-ground-active'))
state.freeCursor=false state.terrainFailure=false
-- Unrecognized press never becomes a cursor cast merely because the slot changed.
selectSlot(5) clear() click(button,true) slots[5]={'spell',207684} click(button,false) assert(#casts==0)
slots[5]={'item',207684}
-- Missing metadata, localized names, injection rejection, and overrides fail locally.
combat=false db.TargetRing.shown=false
names[207684]='Symbole de misère'
names[190356]=nil names[5740]='/bad\n/cast anything' overrides[43265]=999999
assert(Addon.GroundTargeting.Enable(bridge,api,true))
assert(Addon.GroundTargeting.Enable(bridge,api,true))
assert(loadRequests[190356]==1 and not Addon.GroundTargeting.prepared[190356]
    and not Addon.GroundTargeting.prepared[5740] and not Addon.GroundTargeting.prepared[43265])
selectSlot(1) clear() combat=true pair(button)
assert(#casts==1 and casts[1].text=='/cast [@cursor] Symbole de misère')
-- Resolved action info is checked at click time even when combat prevents setup.
slots[1]={'spell',452490} clear() pair(button) assert(#casts==1 and casts[1].text=='/cast [@cursor] Sigil of Doom')
slots[1]={'spell',999999} clear() pair(button) assert(#casts==0)
slots[1]={'spell',207684}
combat=false local originalMacro=api.C_Macro api.C_Macro=nil
assert(not Addon.GroundTargeting.Enable(bridge,api,true) and not button:GetAttribute('cpf-ground-enabled'))
api.C_Macro=originalMacro
assert(Addon.GroundTargeting.Enable(bridge,api,true) and wrapCount==installedWraps)
assert(Addon.GroundTargeting.Disable(api)) clear() pair(button) assert(#casts==0 and #uses==1)
assert(Addon.GroundSpells[207684] and not Addon.GroundSpells[228920] and not Addon.GroundSpells[191034])
-- The actual proposal stays inert until reviewed, permits Keep mine, queues
-- during combat and restores the previous flag through the existing journal.
local account={}
assert(Addon.Store.EnsureSchema(account,'G'))
function bridge:read(path) assert(path[1]=='layout') return Addon.Core.Copy(self.bar.Layout) end
api.GetCVarDefault=function() return nil end
local policy=Addon.FlatConfigAdapter.New(function() return account.shared.runtimePolicy end,
    {groundTargetingEnabled=true},InCombatLockdown)
local adapters={integrationReasons={},consoleport=bridge,policy=policy,bindings={read=function() return {keys={},set=2} end,
    native={api={CharacterSet=2}}}}
local fields=Addon.RuntimeSetup.Fields(account,'G',adapters,api,13)
local groundField
for _,field in ipairs(fields) do if field.id=='shared/policy/groundTargetingEnabled' then groundField=field end end
assert(groundField and groundField.value==true and groundField.revision==13)
assert(account.shared.runtimePolicy.groundTargetingEnabled==nil,'proposal wrote the policy')
local coordinator=Addon.Coordinator.New(account,'G',{policy=policy},function() return not combat end)
local plan=coordinator:Build({groundField},13)
assert(#plan.conflicts==1 and coordinator:Accept({[groundField.id]='keep'}))
assert(account.shared.runtimePolicy.groundTargetingEnabled==nil)
account.reviews={}
coordinator:Build({groundField},13) combat=true
assert(not coordinator:Accept({[groundField.id]='accept'}) and coordinator.queued)
assert(account.shared.runtimePolicy.groundTargetingEnabled==nil)
combat=false assert(coordinator:Resume())
assert(account.shared.runtimePolicy.groundTargetingEnabled==true)
local journal=coordinator.lastJournal
assert(Addon.GroundTargeting.Enable(bridge,api,true))
assert(coordinator:Restore(journal.id) and account.shared.runtimePolicy.groundTargetingEnabled==nil)
assert(Addon.GroundTargeting.Enable(bridge,api,account.shared.runtimePolicy.groundTargetingEnabled))
assert(not button:GetAttribute('cpf-ground-enabled') and account.backups[journal.id])
local macroAPI=api.C_Macro api.C_Macro=nil
local deferredFields,deferred=Addon.RuntimeSetup.Fields(account,'G',adapters,api,13)
for _,field in ipairs(deferredFields) do assert(field.id~=groundField.id,'unsupported runtime offered ground conversion') end
local found=false for _,entry in ipairs(deferred) do if entry.id=='groundTargeting' then found=true end end
assert(found) api.C_Macro=macroAPI
-- Account preference changes are prepared OOC, preserve a held command, and
-- manual placement restores the native action. Explicit temporary choices
-- qualify only that ability; context defaults never qualify unknown IDs.
names[207684]='Sigil of Misery'
local prefs={spells={[207684]='player'},contexts={vehicle='manual',override='player'}}
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
selectSlot(1) clear() combat=true pair(button)
assert(#casts==1 and casts[1].text=='/cast [@player] Sigil of Misery')
combat=false prefs.spells[207684]='manual' assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
clear() combat=true pair(button) assert(#casts==0 and #uses==1)
combat=false prefs.spells[207684]=nil state.family='override' slots[133]={'spell',207684}
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
local temp=api.ConsolePortGroupL2R2.buttons.PAD1
temp:SetAttribute('state','') temp:SetState('','action',133)
clear() combat=true pair(temp) assert(#casts==1 and casts[1].text=='/cast [@player] Sigil of Misery')
combat=false state.family='vehicle' assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
clear() combat=true pair(temp) assert(#casts==0 and #uses==1)
combat=false state.family='override' names[999999]='Quest reticle' slots[133]={'spell',999999}
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs)) clear() combat=true pair(temp) assert(#casts==0)
combat=false prefs.spells[999999]='cursor' assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
assert(Addon.GroundTargeting.observed[999999]) clear() combat=true pair(temp) assert(#casts==1)
combat=false prefs.spells[999999]=nil assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
clear() combat=true pair(temp) assert(#casts==0,'removed explicit qualification left a stale command')
combat=false state.family=nil
-- The existing supplemental 9-12 surface and native extra-action click use
-- their own LeftButton macro attributes and retain ordinary native dispatch.
local supplemental=frame() local extra=frame()
supplemental.scripts.OnClick=SecureActionButton_OnClick extra.scripts.OnClick=SecureActionButton_OnClick
for _,target in ipairs({supplemental,extra}) do
    target:SetAttribute('type','action') target:SetAttribute('action',133) target:SetAttribute('useOnKeyDown',false)
end
local savedAccess=Addon.TemporaryAccess
Addon.TemporaryAccess={frame=frame(),buttons={supplemental}}
api.ExtraActionButton1=extra extra.shown=true
slots[133]={'spell',207684} prefs={spells={},contexts={extra='player'}}
assert(Addon.GroundTargeting.Enable(bridge,api,true,prefs))
state.family='override' clear() combat=true pair(supplemental,'LeftButton')
assert(#casts==1 and casts[1].text=='/cast [@cursor] Sigil of Misery')
assert(supplemental:GetAttribute('type')=='action' and not supplemental:GetAttribute('*macrotext1'))
state.family=nil clear() pair(extra,'LeftButton')
assert(#casts==1 and casts[1].text=='/cast [@player] Sigil of Misery')
combat=false assert(Addon.GroundTargeting.Disable(api)) clear() combat=true pair(extra,'LeftButton')
assert(#casts==0 and #uses==1)
combat=false Addon.TemporaryAccess=savedAccess api.ExtraActionButton1=nil
TEST_SUCCESS=true
