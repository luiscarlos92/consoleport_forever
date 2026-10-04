local C=Addon.Core
local presets={{layoutName="Modern",layoutType=0,systems={{x=1}}},{layoutName="Classic",layoutType=0,systems={{x=2}}}}
local state={activeLayout=3,layouts={{layoutName="User active",layoutType=1,systems={{x=99,custom=true}}},
    {layoutName="Character extra",layoutType=2,systems={{x=44}}}}}
local combat,editing=false,false
local rejected=false
local api={AccountType=1,CharacterType=2,limit=5,presets=function() return C.Copy(presets) end,
    GetLayouts=function() return C.Copy(state) end,inCombat=function() return combat end,isEditing=function() return editing end,
    ConvertLayoutInfoToString=function(p) return p.layoutName..":"..tostring(p.systems[1].x) end,
    SaveLayouts=function(info)
        assert(not combat and not editing)
        if rejected then return false end
        state.layouts={}
        for i=3,#info.layouts do state.layouts[#state.layouts+1]=C.Copy(info.layouts[i]) end
        state.activeLayout=info.activeLayout
    end,
    SetActiveLayout=function(v) state.activeLayout=v end}
local edit=Addon.EditModeAdapter.New(api)
local before=assert(edit:Capture())
local proposed=assert(edit:Proposal(before,"CPF managed"))
assert(proposed.activeLayout==4 and proposed.layouts[2].layoutName=="CPF managed")
assert(proposed.layouts[2].systems[1].x==99 and proposed.layouts[1].layoutName=="User active")
assert(state.activeLayout==3 and #state.layouts==2)
combat=true assert(not edit:write({"state"},proposed)) combat=false
editing=true assert(not edit:write({"state"},proposed)) editing=false
rejected=true assert(not edit:write({"state"},proposed)) rejected=false
assert(edit:write({"state"},proposed) and C.Equal(edit:read({"state"}),proposed))
assert(edit:write({"state"},before) and state.activeLayout==3 and #state.layouts==2)
api.limit=1 assert(not edit:Proposal(before,"CPF new")) api.limit=5
assert(not edit:Proposal(before,"User active"))

local flat={owned={a=1,b=2},manual=88}
local ref=flat.owned
local adapter=Addon.FlatConfigAdapter.New(function() return flat end,{owned=true},function() return combat end)
assert(adapter:write({"owned"},{a=9}) and flat.owned==ref and ref.b==nil and flat.manual==88)
assert(not pcall(adapter.write,adapter,{"manual"},0))
combat=true assert(not adapter:write({"owned"},{})) combat=false

local db={Settings={bindingPresetCondition="keep"},Layers={}}
function db:Get(p) return self.Settings[p:match("Settings/(.+)")] end
function db:Set(p,v) self.Settings[p:match("Settings/(.+)")]=v return true end
local bar={Layout={name="current",children={}},Manager={hasEnvironment=true}}
function bar:ApplyPreset(v) self.Layout=v end
local bridge=Addon.ConsolePortAdapter.New({version="3.3.5",getDB=function() return db end,getBar=function() return bar end,inCombat=function() return combat end})
assert(bridge:Probe() and bridge:Capture().settings.bindingPresetCondition=="keep")
assert(bridge:write({"settings","bindingPresetCondition"},""))
assert(bridge:read({"settings","bindingPresetCondition"})=="")
bridge.api.version="3.2.6" assert(not bridge:Probe())
TEST_SUCCESS=true
