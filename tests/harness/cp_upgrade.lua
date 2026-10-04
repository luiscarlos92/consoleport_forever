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
    assert(ConsolePortSettings.keyboardEraseButton=='old escape' and ConsolePortSettings.keyboardEscapeButton=='old enter' and ConsolePortSettings.keyboardEnterButton=='old erase')
    assert(ConsolePortCharacterSettings.keyboardEscapeButton=='character enter' and ConsolePortCharacterSettings.keyboardEnterButton==nil)
    Keyboard:MigrateButtonConvention() assert(ConsolePortSettings.keyboardEraseButton=='old escape')
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
    setID=2 GamepadAPI:ClearBlockedBindings() assert(writes==1 and saves[1]==2)
    GamepadAPI:ClearBlockedBindings() assert(writes==1 and #saves==1)
end
TEST_SUCCESS=true
