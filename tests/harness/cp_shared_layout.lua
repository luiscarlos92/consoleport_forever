-- Native 3.3.10 data-source selection plus the actual companion adapter.
local C=Addon.Core
local callbacks={}
local db={Settings={},Layers={}}
function db:Register(key,value) self[key]=value end
function db:Get(key) return self.Settings[key:match('Settings/(.+)')] end
function db:Set(key,value) self.Settings[key:match('Settings/(.+)')]=value return true end
local env={db=db,Defaults={},Presets={},Manager={hasEnvironment=true},BuildLayout=C.Copy}
function env:Register(key,value) self[key]=value end
function env:Default() end
function env:Save(key,variable) _G[variable]=self[key] end
function env:RegisterCallback(key,fn,owner,...)
    callbacks[key]={fn=fn,owner=owner,args={...}}
end
function env:GetDefaultLayout() return {name='default',children={}} end
function env:ReleaseAll() end
function env:TriggerEvent() end
setmetatable(env,{__call=function(self,key,value)
    if value~=nil then
        self[key]=value
        local cb=callbacks[key]
        if cb then cb.fn(cb.owner,table.unpack(cb.args)) end
    end
    return self[key]
end})
CopyTable=C.Copy
CPAPI={Proxy=function(value) return value end}
--@NATIVE_BAR_DATA
--@NATIVE_APPLY_PRESET
local function adapter()
    return Addon.ConsolePortAdapter.New({version='3.3.10',getDB=function() return db end,
        getBar=function() return env end,inCombat=function() return false end})
end
ConsolePort_BarDB={custom='personal'}
ConsolePort_BarLayout={name='personal',children={base={x=10}}}
ConsolePort_BarSharedDB=nil ConsolePort_BarSharedLayout=nil ConsolePort_BarShareAll=nil ConsolePort_BarScope=nil
env:UpdateDataSource()
assert(db.BarLayoutKey=='ConsolePort_BarLayout' and not env:UsesSharedLayout())
assert(adapter():Capture().layout.name=='personal')
assert(adapter():write({'layout'},{name='personal edited',children={base={x=20}}}))
assert(ConsolePort_BarLayout.name=='personal edited' and ConsolePort_BarSharedLayout==nil)
local personal=C.Copy(ConsolePort_BarLayout)
env:SetSharedLayout(true,false)
assert(C.Equal(ConsolePort_BarSharedLayout,personal) and ConsolePort_BarSharedLayout~=ConsolePort_BarLayout)
env:UpdateDataSource()
assert(db.BarLayoutKey=='ConsolePort_BarSharedLayout' and env:UsesSharedLayout())
assert(adapter():write({'layout'},{name='shared edited',children={base={x=30}}}))
assert(ConsolePort_BarSharedLayout.name=='shared edited' and C.Equal(ConsolePort_BarLayout,personal),'shared update overwrote the inactive character layout')
assert(ConsolePort_BarDB.custom=='personal' and ConsolePort_BarSharedDB.custom=='personal')
local shared=C.Copy(ConsolePort_BarSharedLayout)
env:SetSharedLayout(false,false) env:UpdateDataSource()
assert(adapter():Capture().layout.name=='personal edited' and C.Equal(ConsolePort_BarSharedLayout,shared))
-- Account defaults cannot overrule an explicit character opt-out.
ConsolePort_BarShareAll=true env:UpdateDataSource()
assert(not env:UsesSharedLayout() and db.BarLayoutKey=='ConsolePort_BarLayout')
ConsolePort_BarScope=nil env:UpdateDataSource()
assert(env:UsesSharedLayout() and adapter():Capture().layout.name=='shared edited')
-- A new character inherits the existing native shared copy without deleting it.
ConsolePort_BarShareAll=nil ConsolePort_BarLayout=nil ConsolePort_BarDB=nil
env:UpdateDataSource()
assert(env:UsesSharedLayout() and C.Equal(ConsolePort_BarSharedLayout,shared))
env:SetSharedLayout(false,false) env:UpdateDataSource()
assert(not env:UsesSharedLayout() and C.Equal(ConsolePort_BarLayout,shared))
assert(ConsolePort_BarLayout~=ConsolePort_BarSharedLayout)
TEST_SUCCESS=true
