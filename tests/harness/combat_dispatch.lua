-- Executes after the full current Input/Layers/UI fixture. Tests the engine
-- binding destination and the native UseAction handler, not visual attributes.
TEST_SUCCESS=nil
--@NATIVE_ACTION_DISPATCH
function securecallfunction(fn,...) return fn(...) end
function SaveMacro() end
function GetActionInfo() return 'spell',123 end
function GetCursorInfo() return nil end
SpellFlyout={Hide=function() end}
local used={}
function UseAction(action)
    assert(hardware,'action did not originate at a hardware press')
    used[action]=(used[action] or 0)+1
end
local gameplay={}
local controls={'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}
local modifiers={'','SHIFT-','CTRL-','CTRL-SHIFT-'}
local slots={}
for _,modifier in ipairs(modifiers) do
    for _,button in ipairs(controls) do
        local key=modifier..button
        local id=#slots+1
        local action=CreateFrame('Button','CPFRegressionAction'..id,UIParent,'SecureActionButtonTemplate')
        action:SetAttribute('action',id)
        function action:CalculateAction() return self:GetAttribute('action') end
        action:SetScript('OnClick',function(self,click,down)
            if not down then SECURE_ACTIONS.action(self,nil,click,true) end
        end)
        gameplay[key]=action slots[#slots+1]=key
        db.Layers:Claim('regression-gameplay','BASE',key,'click',action:GetName(),'ControllerInput')
    end
end
local function dispatch(key,down)
    local route=GetBindingAction(key,true)
    local name,click=route:match('^CLICK ([^:]+):(.+)$')
    assert(named[name],'engine route has no actual frame: '..tostring(route))
    press(named[name],down,click)
end
local function enterCombat()
    combat=true trusted=true
    input:SetAttribute('state-combat',true)
    SecureHandler_Other_Execute(input,input,'self,newstate',input:GetAttribute('_onstate-combat'),true)
    trusted=false
end
local function leaveCombat()
    combat=false trusted=true
    input:SetAttribute('state-combat',nil)
    SecureHandler_Other_Execute(input,input,'self,newstate',input:GetAttribute('_onstate-combat'),nil)
    trusted=false
    bridge:Release()
end
-- A ready-check, bag, or other focused window can claim every gameplay chord.
local uiRoutes={}
for _,key in ipairs(controls) do uiRoutes[key]=target end
assert(bridge:Apply({frame=popup,token='combat-entry',routes=uiRoutes},true))
for _,key in ipairs(slots) do assert(GetBindingAction(key,true):find('CP%-Input%-'),'UI setup did not acquire the chord') end
-- Combat state drivers run before/independently of insecure event callbacks.
-- The first new hardware press must already resolve to gameplay.
enterCombat()
for index,key in ipairs(slots) do
    assert(GetBindingAction(key,true)=='CLICK '..gameplay[key]:GetName()..':ControllerInput',
        'combat retained a hidden UI claim instead of gameplay: '..key)
    dispatch(key,true) dispatch(key,false)
    assert(used[index]==1,'combat input did not call native UseAction exactly once: '..key)
end
assert(bridge:Release())
for _,key in ipairs(slots) do assert(GetBindingAction(key,true)=='CLICK '..gameplay[key]:GetName()..':ControllerInput') end
leaveCombat()
-- Native cursor controls created after Forever's bridge must hand back too,
-- even when no CPF popup/window owns the widget and insecure release is refused.
local nativeOwner=CreateFrame('Frame','CPFRegressionNativeCursor',UIParent)
local ordinary=gameplay.PAD1
input:SetCommand('PAD1',nativeOwner,true,'LeftButton','NativeCursorControl',function() end)
enterCombat()
assert(GetBindingAction('PAD1',true)=='CLICK '..ordinary:GetName()..':ControllerInput',
    'native cursor UI claim survived combat without CPF context ownership')
leaveCombat() input:Release(nativeOwner)
local later=CreateFrame('Button','CPFRegressionLateAction',UIParent,'SecureActionButtonTemplate')
later:SetScript('OnClick',function() end)
db.Layers:Claim('regression-gameplay','BASE','PADLSHOULDER','click',later:GetName(),'ControllerInput')
input:SetCommand('PADLSHOULDER',nativeOwner,true,'LeftButton','NativeLateControl',function() end)
local late=input.Widgets.PADLSHOULDER:GetAttribute('_childupdate-combat')
input:GetWidget('PADLSHOULDER',nativeOwner)
assert(late==input.Widgets.PADLSHOULDER:GetAttribute('_childupdate-combat'),'repeat widget setup duplicated secure handoff')
enterCombat()
assert(GetBindingAction('PADLSHOULDER',true)=='CLICK '..later:GetName()..':ControllerInput',
    'late-created native cursor widget retained combat ownership')
leaveCombat() input:Release(nativeOwner)
-- Combat entry while an old UI press is held never invokes its stale target.
assert(bridge:Apply({frame=popup,token='held-ui',routes=uiRoutes},true))
local oldClicks=clicked
local held=input.Widgets.PAD1
press(held,true) enterCombat() press(held,false)
assert(clicked==oldClicks,'combat leaked the held UI release')
dispatch('PAD1',true) dispatch('PAD1',false)
assert(used[1]==2,'first gameplay action after the cancelled UI press was lost')
leaveCombat()
-- Foreground modal ownership belongs to another addon: do not release it.
local foreign=CreateFrame('Button','CPFRegressionForeign',UIParent,'SecureActionButtonTemplate')
foreign:SetScript('OnClick',function() end)
assert(bridge:Apply({frame=popup,token='foreign-test',routes=uiRoutes},true))
db.Layers:Claim('foreign-modal','MODAL','PAD1','click',foreign:GetName(),'LeftButton')
enterCombat()
assert(GetBindingAction('PAD1',true)=='CLICK '..foreign:GetName()..':LeftButton','combat erased another owner claim')
leaveCombat() db.Layers:ReleaseAll('foreign-modal')
-- Repeated UI acquisition/combat transitions leave no stale NAV claims.
for cycle=1,3 do
    assert(bridge:Apply({frame=popup,token='repeat'..cycle,routes=uiRoutes},true))
    enterCombat()
    for _,key in ipairs(slots) do assert(GetBindingAction(key,true)=='CLICK '..gameplay[key]:GetName()..':ControllerInput') end
    leaveCombat()
end
-- The new class chord uses the same native engine/layer resolver and native
-- ring Hold body. It stays distinct from every face/D-pad gameplay cell.
local classHold
--@NATIVE_CLASS_HOLD
local classRing=CreateFrame('Button','CPFRegressionClassRing',UIParent,'SecureActionButtonTemplate')
classRing.layerEnv=setmetatable({},{__index=_G})
local classOpens,classCommits=0,0
function classRing:Opened() classOpens=classOpens+1 end
function classRing:Committed() classCommits=classCommits+1 end
classRing:SetAttribute('Hold',CPAPI.ConvertSecureBody(classHold))
classRing:SetAttribute('Enable',[[local button=...; self:SetAttribute('selected-set',button); self:CallMethod('Opened')]])
classRing:SetAttribute('Commit',[[local button=...; assert(self:GetAttribute('selected-set')==button); self:SetAttribute('selected-set',nil); self:CallMethod('Committed')]])
classRing:SetScript('OnClick',function(self,click,down)
    assert(hardware)
    local prior=trusted trusted=true
    self:RunAttribute('Hold',click,down,false,true)
    trusted=prior
end)
db.Layers:Claim('regression-class','BASE',Addon.ClassActions.CHORD,'click',classRing:GetName(),'Auras')
for cycle=1,3 do
    assert(bridge:Apply({frame=popup,token='class-cycle'..cycle,routes=uiRoutes},true))
    enterCombat()
    assert(GetBindingAction(Addon.ClassActions.CHORD,true)=='CLICK '..classRing:GetName()..':Auras')
    dispatch(Addon.ClassActions.CHORD,true)
    assert(classOpens==cycle and classCommits==cycle-1,'native class ring did not open on chord down')
    dispatch(Addon.ClassActions.CHORD,false)
    assert(classCommits==cycle,'native class ring lost chord release')
    for _,key in ipairs(slots) do assert(GetBindingAction(key,true)=='CLICK '..gameplay[key]:GetName()..':ControllerInput') end
    leaveCombat()
end
TEST_SUCCESS=true
