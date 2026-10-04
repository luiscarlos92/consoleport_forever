local C,P=Addon.Core,Addon.Prompt
local shown,details,queue=nil,nil,{}
local applied,declined
local dialogs={}
P:Initialize({dialogs=dialogs,show=function(name,text,_,data) shown={name=name,text=text,data=data} return shown end,
    defer=function(fn) queue[#queue+1]=fn end,details=function(text) details=text end,reload=function() error("not requested") end})
local function flush() while #queue>0 do table.remove(queue,1)() end end
local function click(index)
    local row=shown local info=dialogs[row.name]
    local callback=info["OnButton"..index] or (index==1 and info.OnAccept or info.OnCancel)
    callback(nil,row.data)
    if info.OnHide then info.OnHide(nil,row.data) end
    flush()
end
local long=string.rep("full-value-",100)
local changes=P.Differences(C.Encode(nil),{a=false,nested={value=long}})
assert(#changes==2 and changes[1]=="a: Unset -> false" and changes[2]:find(long,1,true),"full table details were hidden/truncated")
local plan={operations={{id="routine",before=1,value=2,label="Routine update"}},conflicts={{id="manual",before={x=false},value={x=true}}},deferred={}}
assert(P:Show(plan,function(resolutions) applied=resolutions end,function() declined=true end))
click(1)
assert(shown.name=="CPF_FIELD_REVIEW" and shown.text:find("x: false -> true",1,true))
click(4)
assert(details:find("x: false -> true",1,true) and P.active and shown.name=="CPF_FIELD_REVIEW" and not applied and not declined)
click(2)
assert(shown.name=="CPF_FIELD_REVIEW" and shown.text:find("Routine update",1,true))
click(2)
assert(shown.name=="CPF_PLAN_APPLY" and shown.text:find("Apply 0",1,true))
click(1)
assert(applied.manual=="keep" and applied.routine=="keep" and not P.active)
assert(#Addon.Plan.Accept(plan,applied)==0)
local fields={{id="routine",scope="flat",path={"x"},value=2,revision=3}}
local repeated=Addon.Plan.Build({flat={x=1}},{routine={value=1}},fields,{routine={decision="keep",revision=3,current=1,proposed=2}})
assert(#repeated.operations==0 and repeated.noops[1].reason=="reviewed keep")
local loads=0
assert(P:InspectBindings(function() loads=loads+1 end,function() declined=true end))
click(2) assert(loads==0 and not P.active)
assert(P:InspectBindings(function() loads=loads+1 end,function() declined=true end))
click(1) assert(loads==1 and not P.active)
TEST_SUCCESS=true
