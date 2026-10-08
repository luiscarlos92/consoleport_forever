-- Actual native Layers/Input owns the engine chord destinations. The ground
-- fixture below owns the actual CP/LAB/Manager/Blizzard action-handler stack.
-- Join them at hardware dispatch, without replacing either native pipeline.
local destinations={}
local targetingEngine={}
function targetingEngine:Register(key,name,callback)
    destinations[name]=callback
    db.Layers:Claim('targeting-native-bars','BASE',key,'click',name,'ControllerInput')
end
function targetingEngine:Dispatch(key,down)
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
