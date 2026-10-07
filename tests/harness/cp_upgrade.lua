-- Actual current native upgrade paths; engine methods are host substitutes.
local combat,trusted=false,false
function InCombatLockdown() return combat end
function Mixin(base,other) for k,v in pairs(other) do base[k]=v end return base end
function newtable(...) return {...} end
function wipe(t) for k in pairs(t) do t[k]=nil end end
string.trim=function(s) return s:match('^%s*(.-)%s*$') end
CPAPI={SecureEnvironmentMixin={}}
--@NATIVE_CONVERSION
--@NATIVE_MACRO
local function run(self,body,...)
    local fn=assert(load('return function(self,...) '..body..' end','native-layer','t',_G))()
    local prior=trusted trusted=true
    local ok,value=pcall(fn,self,...)
    trusted=prior assert(ok,value) return value
end
local layers={attributes={},refs={}}
function layers:Execute(body) return run(self,body) end
function layers:CreateEnvironment() for name,body in pairs(self.Env) do self.attributes[name]=CPAPI.ConvertSecureBody(body) end end
function layers:RunAttribute(name,...) return run(self,self.attributes[name],...) end
function layers:GetAttribute(name) return self.attributes[name] end
function layers:SetAttribute(name,value) self.attributes[name]=value end
function layers:SetFrameRef(name,frame) assert(frame:IsProtected()) self.refs[name]=frame end
function layers:GetFrameRef(name) return self.refs[name] end
function layers:CallMethod(name,...) return self[name](self,...) end
function layers:ChildUpdate(name,value) self.childNotifications=self.childNotifications or {} self.childNotifications[#self.childNotifications+1]={name,value} end
local engineBindings={}
function layers:GetName() return 'ConsolePortLayers' end
function layers:SetBindingClick(priority,key,name,button) engineBindings[key]={priority=priority,action='CLICK '..name..':'..button} end
function layers:SetBinding(priority,key,action) engineBindings[key]={priority=priority,action=action} end
function layers:ClearBinding(key) engineBindings[key]=nil end
function ClearOverrideBindings(owner) assert(owner==layers and not combat) for key in pairs(engineBindings) do engineBindings[key]=nil end end
tremove=table.remove
CPAPI.DataHandler=function() return layers end
function RegisterStateDriver() end
function UnregisterStateDriver() end
function RegisterAttributeDriver() end
function UnregisterAttributeDriver() end
local db={Locale={},Gamepad={Index={Modifier={Active={['']=true,['SHIFT-']=true,['CTRL-']=true,['CTRL-SHIFT-']=true}}}}}
function db:Register() end
function db:RegisterSafeCallback() end
function db:RegisterSafeCallbacks() end
--@NATIVE_LAYERS
local function target(protected)
    local frame={attributes={},shown=true,writes=0}
    function frame:IsProtected() return protected end
    function frame:SetAttribute(k,v) assert(not protected or not combat or trusted) self.attributes[k]=v self.writes=self.writes+1 end
    function frame:GetAttribute(k) return self.attributes[k] end
    function frame:Show() assert(not protected or not combat or trusted) self.shown=true end
    function frame:Hide() assert(not protected or not combat or trusted) self.shown=false end
    function frame:RunAttribute(k,...) return run(self,self.attributes[k],...) end
    return frame
end
PREFIX=''
local secure,insecure=target(true),target(false)
layers:RegisterState(secure,'mode','[mod:SHIFT-] 7; 2',"self:SetAttribute('body-result',newstate)")
layers:RegisterState(insecure,'value','[mod:SHIFT-] 8; 3')
local secureIndex=layers.States[tostring(secure)..'mode']
local insecureIndex=layers.States[tostring(insecure)..'value']
assert(STATES[secureIndex][1]==secure and not STATES[secureIndex][7])
assert(STATES[insecureIndex][1]==false and STATES[insecureIndex][7])
assert(secure:GetAttribute('mode')==2 and secure:GetAttribute('body-result')==2 and insecure:GetAttribute('value')==3)
assert(not pcall(layers.RegisterState,layers,insecure,'body','1','return'))
combat=true PREFIX='SHIFT-'
layers:RunAttribute('EvaluateState',secureIndex) layers:RunAttribute('EvaluateState',insecureIndex)
assert(secure:GetAttribute('mode')==7 and insecure:GetAttribute('value')==8)
local writes=insecure.writes
layers:RunAttribute('EvaluateState',insecureIndex)
assert(insecure.writes==writes,'unchanged insecure state reapplied')
combat=false
layers:UnregisterState(insecure,'value')
assert(not STATES[insecureIndex] and not layers.StateFrames[insecureIndex])
layers:RegisterState(insecure,'state-visibility','[mod:SHIFT-] hide; show',nil,true)
assert(not insecure.shown and insecure:GetAttribute('statehidden'))
PREFIX='' local index=layers.States[tostring(insecure)..'state-visibility'] layers:RunAttribute('EvaluateState',index)
assert(insecure.shown and insecure:GetAttribute('statehidden')==nil)
-- An unmatched driver preserves the last state in protected and ordinary frames.
layers:RegisterState(secure,'partial','[mod:SHIFT-] 7')
local partialIndex=layers.States[tostring(secure)..'partial']
PREFIX='SHIFT-' layers:RunAttribute('EvaluateState',partialIndex)
assert(secure:GetAttribute('partial')==7)
PREFIX='' layers:RunAttribute('EvaluateState',partialIndex)
assert(secure:GetAttribute('partial')==7,'unmatched modifier driver cleared the native state')
layers:RegisterState(insecure,'partial','[mod:SHIFT-] 8')
local ordinaryIndex=layers.States[tostring(insecure)..'partial']
PREFIX='SHIFT-' layers:RunAttribute('EvaluateState',ordinaryIndex)
PREFIX='' local priorWrites=insecure.writes layers:RunAttribute('EvaluateState',ordinaryIndex)
assert(insecure:GetAttribute('partial')==8 and insecure.writes==priorWrites)

-- Native binding claims restore the underlying owner after modal/UI closure.
assert(layers:Claim('bar','BASE','PAD1','binding','GAMEPLAY'))
assert(layers:Claim('interact','OVERRIDE','PAD1','binding','INTERACTTARGET'))
assert(layers:Claim('cursor','NAV','PAD1','click','CursorButton','LeftButton'))
assert(layers:Claim('wheel','MODAL','PAD1','click','WheelButton','PAD1'))
assert(engineBindings.PAD1.action=='CLICK WheelButton:PAD1' and engineBindings.PAD1.priority)
layers:ReleaseAll('wheel') assert(engineBindings.PAD1.action=='CLICK CursorButton:LeftButton')
layers:Claim('dialogue','NAV','PAD1','click','DialogueButton','LeftButton')
assert(engineBindings.PAD1.action=='CLICK DialogueButton:LeftButton','equal-priority newer claim lost')
layers:ReleaseAll('dialogue') layers:ReleaseAll('cursor')
assert(engineBindings.PAD1.action=='INTERACTTARGET' and not engineBindings.PAD1.priority)
combat=true assert(not layers:Claim('cursor','NAV','PAD1','binding','BAD'))
assert(not layers:ReleaseAll('interact') and engineBindings.PAD1.action=='INTERACTTARGET') combat=false
layers:ReleaseAll('interact') assert(engineBindings.PAD1.action=='GAMEPLAY')
layers:ReleaseAll('bar') assert(engineBindings.PAD1==nil,'released claim left an engine binding')
-- 3.3.10 maps blocked self-modifier chords to the tap actually emitted by WoW.
db.table={spairs=function(t)
    local keys={} for k in pairs(t) do keys[#keys+1]=k end table.sort(keys)
    local i=0 return function() i=i+1 if keys[i] then return keys[i],t[keys[i]] end end
end}
setmetatable(db,{__call=function() return false end})
function db:TriggerEvent() end
db.Gamepad.Index.Modifier.Prefix={['SHIFT-']='PADLTRIGGER',['CTRL-']='PADRTRIGGER'}
db.Gamepad.Index.Modifier.Layered={}
db.Gamepad.Index.Modifier.Blocked={['SHIFT-PADLTRIGGER']='SHIFT',['CTRL-PADRTRIGGER']='CTRL'}
layers:SetModifiers()
assert(ALIAS['SHIFT-PADLTRIGGER']=='PADLTRIGGER' and ALIAS['CTRL-PADRTRIGGER']=='PADRTRIGGER')
assert(layers:Claim('tap','BASE','PADLTRIGGER','binding','GAMEPLAY'))
assert(layers:Claim('blocked','NAV','SHIFT-PADLTRIGGER','click','Modal','LeftButton'))
assert(engineBindings.PADLTRIGGER.action=='CLICK Modal:LeftButton' and not engineBindings['SHIFT-PADLTRIGGER'])
layers:Release('blocked','SHIFT-PADLTRIGGER') assert(engineBindings.PADLTRIGGER.action=='GAMEPLAY')
layers:ReleaseAll('tap') layers:ReleaseModifiers()
assert(not ALIAS['SHIFT-PADLTRIGGER'] and not engineBindings.PADLTRIGGER)

-- Native first-login module and keyboard migrations remain upstream-owned.
do
    local Modules,Keyboard={},{}
    local log,selected={},{}
    CPAPI.Log=function(text) log[#log+1]=text end
    CPAPI.EnableAddOn=function(name) selected[name]=true end
    CPAPI.DisableAddOn=function(name) selected[name]=false end
    function Modules:GetEntry(id) return {addon=id} end
    --@NATIVE_MODULE_MIGRATION
    --@NATIVE_KEYBOARD_MIGRATION
    ConsolePortSettings={moduleRings=true,moduleMenus=false,keyboardEraseButton='old erase',keyboardEscapeButton='old escape',keyboardEnterButton='old enter'}
    ConsolePortCharacterSettings={moduleWorld=false,keyboardEnterButton='character enter'}
    Modules:MigrateFromSettings()
    assert(selected.Rings==true and selected.Menu==false and selected.World==false and selected.Bar==true)
    assert(selected.Keyboard==nil and ConsolePortSettings.moduleStateVersion==1)
    assert(ConsolePortSettings.moduleMenus==nil and ConsolePortCharacterSettings.moduleWorld==nil)
    selected.Bar=false Modules:MigrateFromSettings() assert(selected.Bar==false,'native once-only migration repeated')
    Keyboard:MigrateButtonConvention()
    assert(ConsolePortSettings.keyboardButtonVersion==2)
    assert(ConsolePortSettings.keyboardEraseButton=='old erase' and ConsolePortSettings.keyboardEscapeButton=='old escape' and ConsolePortSettings.keyboardEnterButton=='old enter')
    assert(ConsolePortCharacterSettings.keyboardEnterButton=='character enter')
    ConsolePortSettings.keyboardButtonVersion=1
    ConsolePortSettings.keyboardEraseButton='old escape' ConsolePortSettings.keyboardEscapeButton='old enter' ConsolePortSettings.keyboardEnterButton='old erase'
    ConsolePortCharacterSettings={keyboardEscapeButton='character enter'}
    Keyboard:MigrateButtonConvention()
    assert(ConsolePortSettings.keyboardEraseButton=='old erase' and ConsolePortSettings.keyboardEscapeButton=='old escape' and ConsolePortSettings.keyboardEnterButton=='old enter')
    assert(ConsolePortCharacterSettings.keyboardEnterButton=='character enter' and ConsolePortCharacterSettings.keyboardEscapeButton==nil)
    Keyboard:MigrateButtonConvention() assert(ConsolePortSettings.keyboardEraseButton=='old erase','native restoration repeated')
end
do
    local NM,GamepadAPI='',{Index={Modifier={Blocked={['SHIFT-PAD1']=true}},Button={Binding={PAD1=true}},}}
    local setID,writes,saves=0,0,{}
    Enum={BindingSet={Account=1,Character=2}}
    function GetCurrentBindingSet() return setID end
    local binding='BLOCKED'
    CPAPI.GetBindingAction=function() return binding end
    CPAPI.SetBinding=function() writes=writes+1 binding='' end
    CPAPI.SaveBindings=function(id) saves[#saves+1]=id or setID end
    CPAPI.IsButtonValidForBinding=function() return false end
    --@NATIVE_CLEAR_BLOCKED
    GamepadAPI:ClearBlockedBindings() assert(writes==0 and #saves==0)
    setID=2 GamepadAPI:ClearBlockedBindings() assert(writes==0 and #saves==0,'binding cleanup ran before dispatch readiness')
    GamepadAPI.IsDispatchReady=true
    GamepadAPI:ClearBlockedBindings() assert(writes==1 and saves[1]==2)
    GamepadAPI:ClearBlockedBindings() assert(writes==1 and #saves==1)
end
TEST_SUCCESS=true
