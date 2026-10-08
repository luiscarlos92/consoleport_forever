-- Actual native Layers/Input owns the engine chord destinations. The ground
-- fixture below owns the actual CP/LAB/Manager/Blizzard action-handler stack.
-- Join them at hardware dispatch, without replacing either native pipeline.
local destinations={}
local targetingEngine={}
local env={GetSignature=function(_,owner) return owner:GetName() end}
local Manager={}
--@NATIVE_MANAGER_ENV
--@NATIVE_MANAGER_REGISTER
--@NATIVE_MANAGER_PARSE
local registration=CreateFrame('Frame','CPRegressionManager',UIParent,'SecureHandlerBaseTemplate')
local owner=CreateFrame('Frame','CPRegressionGroup',UIParent,'SecureHandlerBaseTemplate')
registration.layerEnv=setmetatable({bindings={},layers=db.Layers},{__index=_G})
registration.Execute=CPAPI.SecureEnvironmentMixin.Execute
registration.Parse=nativeParse registration.RegisterOverride=Manager.RegisterOverride
registration:SetAttribute(owner:GetName(),true)
for key,body in pairs(Manager.Env) do registration:SetAttribute(key,CPAPI.ConvertSecureBody(body)) end
db.Layers.layerEnv.ENABLED=true
db.Layers.layerEnv.MODS={'CTRL-','SHIFT-'}
function db.Layers:ChildUpdate() end
function db:TriggerEvent() end
function targetingEngine:Register(key,name,callback)
    destinations[name]=callback
    registration:RegisterOverride(owner,name,key)
    local before=trusted trusted=true
    registration:RunAttribute('ApplyBindings')
    trusted=before
end
function targetingEngine:Dispatch(key,down)
    local prefix=key:match('^(.*%-)') or ''
    local before=trusted trusted=true
    -- Actual native modifier resolution -> one live row -> engine override.
    db.Layers:RunAttribute('OnModifier','CTRL-',prefix:find('CTRL-',1,true) and true or false)
    db.Layers:RunAttribute('OnModifier','SHIFT-',prefix:find('SHIFT-',1,true) and true or false)
    trusted=before
    local route=GetBindingAction(key,true)
    local name,button=route:match('^CLICK ([^:]+):(.+)$')
    assert(destinations[name],'gameplay chord intercepted: '..key..' -> '..tostring(route))
    destinations[name](down,button)
end
function targetingEngine:Focus()
    local routes={}
    for _,key in ipairs({'PAD1','PAD2','PAD3','PAD4','PADDLEFT','PADDUP','PADDRIGHT','PADDDOWN'}) do routes[key]=target end
    assert(bridge:Apply({frame=popup,token='targeting-regression',routes=routes},true))
    assert(GetBindingAction('PAD1',true):find('CP%-Input%-'))
end
function targetingEngine:Combat(value)
    combat=value trusted=true
    input:SetAttribute('state-combat',value or nil)
    SecureHandler_Other_Execute(input,input,'self,newstate',input:GetAttribute('_onstate-combat'),value or nil)
    trusted=false
    if not value then bridge:Release() end
end
function targetingEngine:ForeignClaim(value)
    if value then db.Layers:Claim('foreign-modal','MODAL','PAD1','command','FOREIGN_MODAL')
    else db.Layers:ReleaseAll('foreign-modal') end
end
