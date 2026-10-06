local combat=false
local db={}
local events={}
function db:TriggerEvent(name,id,value) events[#events+1]={name,id,value} end
local Bindings={Icons=setmetatable({['CLICK LM_B2:LeftButton']='manual-second-icon',OTHER=777},{__index={JUMP=10}})}
--@NATIVE_BINDING_ICON_METHODS
db.Bindings=Bindings
local version='12.1.0-1'
local api={InCombatLockdown=function() return combat end,
    C_AddOns={IsAddOnLoaded=function() return true end,GetAddOnMetadata=function(name,key)
        if name=='ConsolePort' then return '3.3.9' end
        if key=='Version' then return version elseif key=='IconTexture' then return '132247' end
    end},LM_B1={GetName=function() return 'LM_B1' end},LM_B2={GetName=function() return 'LM_B2' end}}
local adapter=assert(Addon.LiteMountAdapter.New(db,api))
local before=Addon.Core.Copy(Bindings.Icons)
local icons,pending=adapter:Proposal()
assert(icons['CLICK LM_B1:LeftButton']==132247 and icons['CLICK LM_B2:LeftButton']=='manual-second-icon' and #pending==0)
assert(Addon.Core.Equal(before,Bindings.Icons) and #events==0,'icon proposal changed settings or rules')
assert(adapter:write({'CLICK LM_B1:LeftButton'},132247))
assert(#events==1 and events[1][1]=='OnBindingIconChanged' and Bindings.Icons.OTHER==777)
Bindings.Icons['CLICK LM_B1:LeftButton']=999
local plan=Addon.Plan.Build({mount=Bindings.Icons},{icon={value=132247}},
    {{id='icon',scope='mount',path={'CLICK LM_B1:LeftButton'},value=123}})
assert(#plan.conflicts==1 and plan.conflicts[1].before==999)
assert(adapter:write({'CLICK LM_B1:LeftButton'},nil) and rawget(Bindings.Icons,'CLICK LM_B1:LeftButton')==nil)
combat=true assert(not adapter:write({'CLICK LM_B1:LeftButton'},132247)) combat=false
Bindings.Icons['CLICK LM_B2:LeftButton']=nil
icons,pending=adapter:Proposal() assert(icons['CLICK LM_B2:LeftButton']==nil and #pending==1,'second native action got a guessed mount icon')
Bindings.Icons['CLICK LM_B1:LeftButton']={}
icons,pending=adapter:Proposal() assert(icons['CLICK LM_B1:LeftButton']==nil and #pending==2)
assert(not pcall(adapter.write,adapter,{'CLICK LM_B1:LeftButton'},{}))
assert(not pcall(adapter.write,adapter,{'OTHER'},1))
Bindings.Icons=Addon.Core.Copy(before) assert(not pcall(adapter.read,adapter,{'CLICK LM_B1:LeftButton'}))
adapter=assert(Addon.LiteMountAdapter.New(db,api))
version='newer' assert(not pcall(adapter.read,adapter,{'CLICK LM_B1:LeftButton'}))
api.LM_B2=nil assert(Addon.LiteMountAdapter.New(db,api)==nil)
TEST_SUCCESS=true
