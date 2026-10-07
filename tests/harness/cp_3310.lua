-- Exact changed native layout, rename and pet-ring functions; engine frames
-- and data-field values are substitutes. No live saved configuration is used.
do
    local DATA,INIT,CALL={},{},{}
    local Table,Field={},{}
    function Field.Set() error('unexpected uninitialized data field') end
    --@NATIVE_DATA_TABLE
    local leaf={value=1,IsType=function() return false end,Get=function(self) return self.value end,Set=function(self,v) self.value=v end}
    local function node(children)
        local self=setmetatable({[INIT]=true,[DATA]={}},{__index=Table})
        function self:IsType(kind) return kind=='Table' end
        for name,child in pairs(children) do self[DATA][name]={[DATA]=child} end
        return self
    end
    local root=node({nested=node({value=leaf})})
    root:Set({nested={value=2,newerField=9},newerRoot=8},true)
    assert(leaf.value==2 and root:Get().nested.value==2,'nested silent flag was not propagated')
    assert(not pcall(root.Set,root,{nested={unknown=1}},false),'strict field validation was lost')
end
do
    local env={Interface={}}
    local logs={}
    CPAPI={Log=function(...) logs[#logs+1]={...} end}
    function env.IsV1Layout() return false end
    env.Interface.Group=function() return {Warp=function(_,data) data.upgraded=true return data end} end
    env.Interface.Broken=function() return {Warp=function() error('bad saved element') end} end
    --@NATIVE_BUILD_LAYOUT
    local result=env.BuildLayout({children={Base={type='Group',children={Nested={type='Group'},Future={type='Unsupported'}}},
        L2={type='Group'},Broken={type='Broken'},Future={type='FutureWidget'}}})
    assert(result.children.Base.upgraded and result.children.L2.upgraded and result.children.Base.children.Nested.upgraded)
    assert(not result.children.Future and not result.children.Broken and not result.children.Base.children.Future and #logs==3)
end
do
    local BASE='Layout/children'
    local function PATH(a,b) return a..'/'..b end
    local Loadout={}
    local original={type='Group',pos={x=5}}
    local values={[PATH(BASE,'Old')]=original}
    local env=setmetatable({},{__call=function(_,name,...)
        if select('#',...)>0 then values[name]=(...) else return values[name] end
    end})
    local released,triggered=false,false
    function env:Release(owner) released=owner end
    function env:TriggerEvent(event,value) assert(event=='OnLayoutChanged' and value) triggered=true end
    local CopyTable=Addon.Core.Copy
    --@NATIVE_RENAME
    local loadout=setmetatable({ReleaseAll=function(self) self.released=true end,Update=function(self) self.updated=true end},{__index=Loadout})
    local widget={owner={}}
    loadout:OnRename(PATH(BASE,'Old'),'New',widget)
    assert(values[PATH(BASE,'Old')]==nil and values[PATH(BASE,'New')]~=original)
    assert(Addon.Core.Equal(values[PATH(BASE,'New')],original) and released==widget.owner and loadout.released and loadout.updated and triggered)
    values[PATH(BASE,'New')].pos.x=9 assert(original.pos.x==5,'rename moved a subscribed source table')
end
do
    local env={Manager={},Interface={Petring={}}}
    local factory
    function env:AddFactory(kind,fn) assert(kind=='Petring') factory=fn end
    function env.MakeID(pattern,id) return pattern:format(id) end
    local names={}
    local function CreateFrame(kind,name,parent,template)
        assert(kind=='Button' and parent==env.Manager and template=='CPPetRing' and not names[name])
        local f={name=name} names[name]=f _G[name]=f return f
    end
    ConsolePortBarPetRing=nil
    --@NATIVE_PET_FACTORY
    local first,second=factory('First'),factory('Second')
    assert(first~=second and first.name=='ConsolePortBarPetRing' and second.name=='ConsolePortBarPetRingSecond')
end
TEST_SUCCESS=true
