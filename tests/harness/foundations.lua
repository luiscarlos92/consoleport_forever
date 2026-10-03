local C, S, P, T = Addon.Core, Addon.Store, Addon.Plan, Addon.Transactions
assert(io == nil and os == nil and loadfile == nil and dofile == nil)
assert(not C.Equal(false,C.NIL) and C.Decode(C.NIL)==nil)
assert(not C.IsNil({__cpfNil=true, other=true}))
local db = {installedSchema=2, backup={untouched=true}}
assert(S.EnsureSchema(db, "A", {installedSchema=2}))
assert(db.databaseVersion==3 and db.backup.untouched)
assert(db.legacy.ambiguousCharacter.installedSchema==2)
local migration = db.legacy.schemaMigration
S.EnsureSchema(db,"A")
assert(db.legacy.schemaMigration==migration)
assert(not S.EnsureSchema({databaseVersion=999},"A"))
assert(not S.GetCharacter(db,nil))
assert(S.GetCharacter(db,"A").appliedRevision==0)
assert(S.GetCharacter(db,"B").appliedRevision==0)

local live = {personal="old-view"}
local adapter = {capture=function() return live end,
    project=function(_, view) for k in pairs(live) do live[k]=nil end
        for k,v in pairs(view) do live[k]=v end return true end}
assert(S.Hydrate(db,"A",adapter,{personal="A-default"}))
live.personal="A-edit"
assert(S.CaptureOwnedEdits(db,"A",adapter))
assert(not S.CaptureOwnedEdits(db,"B",adapter))
assert(S.Hydrate(db,"B",adapter,{personal="B-default"}))
assert(live.personal=="B-default")
live.personal="B-edit"
assert(S.CaptureOwnedEdits(db,"B",adapter))
assert(S.Hydrate(db,"A",adapter,{}))
assert(live.personal=="A-edit" and db.characters.B.projectedView.personal=="B-edit")

local function plan(now,old,new,hasOld)
    return P.Build({shared={value=now}},hasOld and {x={value=C.Encode(old)}} or {},
        {{id="x",scope="shared",path={"value"},value=C.Encode(new),revision=1}})
end
assert(#plan(1,1,2,true).operations==1)
assert(#plan(2,1,2,true).noops==1)
assert(#plan(3,1,1,true).noops==1)
assert(#plan(3,1,2,true).conflicts==1)
assert(#plan(1,nil,2,false).conflicts==1)
assert(#plan(false,false,nil,true).operations==1)
assert(#plan(nil,nil,false,true).operations==1)
local conflict=plan(3,1,2,true)
assert(not P.Accept(conflict,{}))
assert(#P.Accept(conflict,{x="keep"})==0 and #P.Accept(conflict,{x="accept"})==1)

-- Inject false, throw-after-mutation and readback mismatch at every step.
for failAt=1,3 do
    for _,kind in ipairs({"false","throw","mismatch"}) do
        local values={a=1,b=2,c=3}
        local writes=0
        local access={read=function(_,path) return values[path[1]] end,
            write=function(_,path,value)
                writes=writes+1
                if writes==failAt then
                    if kind=="false" then return false end
                    if kind=="throw" then values[path[1]]=value error("injected") end
                    values[path[1]]=99 return true
                end
                values[path[1]]=value return true
            end}
        local steps={}
        for i,k in ipairs({"a","b","c"}) do
            steps[i]={id=k,scope="shared",path={k},before=i,value=i+10,revision=1}
        end
        local j=T.Prepare(db,"A",steps,{bindingSet=2})
        assert(not T.Apply(j,{shared=access},function() return true end))
        assert(db.characters.A.appliedRevision==0 and not T.Commit(db,j,1))
        if kind=="mismatch" then
            assert(j.status=="recovery-required" and values[steps[failAt].path[1]]==99)
        else
            assert(j.status=="rolled-back" and values.a==1 and values.b==2 and values.c==3)
        end
    end
end
local values={a=1}
local access={read=function(_,p) return values[p[1]] end,
    write=function(_,p,v) values[p[1]]=v return true end}
local step={{id="a",scope="shared",path={"a"},before=1,value=2,revision=2}}
local j=T.Prepare(db,"A",step)
assert(not T.Apply(j,{shared=access},function() return false end) and values.a==1)
values.a=3
assert(not T.Apply(j,{shared=access},function() return true end) and j.status=="stale")
values.a=1
j=T.Prepare(db,"A",step)
assert(T.Apply(j,{shared=access},function() return true end))
assert(T.Commit(db,j,2) and values.a==2 and db.characters.A.appliedRevision==2)
assert(not T.Apply(j,{shared=access},function() return true end))
assert(db.backups[j.id].steps[1].before==1)
assert(not T.Recover(j,{shared=access},function() return false end))
TEST_SUCCESS=true
