local C,S=Addon.Core,Addon.Store
local db={}
assert(S.EnsureSchema(db,"A"))
assert(not S.EnsureSchema({characters=false},"A"))
assert(not S.EnsureSchema({databaseVersion=-1},"A"))
local values={x=1,y=false}
local writable=true
local adapter={read=function(_,p) return values[p[1]] end,
    write=function(_,p,v) assert(writable) values[p[1]]=v return true end}
local co=Addon.Coordinator.New(db,"A",{flat=adapter},function() return writable end)
local fields={{id="A:x",scope="flat",path={"x"},value=2,revision=1},
              {id="A:y",scope="flat",path={"y"},value=true,revision=1}}
local plan=co:Build(fields,1)
assert(#plan.conflicts==2 and values.x==1 and values.y==false)
assert(not co:Accept({}) and values.x==1)
writable=false
assert(not co:Accept({["A:x"]="accept",["A:y"]="keep"}))
assert(co.queued and values.x==1)
writable=true
values.x=3
assert(not co:Resume() and values.x==3) -- entire accepted review invalidated
plan=co:Build(fields,1)
assert(co:Accept({["A:x"]="accept",["A:y"]="keep"}))
local id=co.lastJournal.id
assert(values.x==2 and values.y==false and db.reviews["A:y"].decision=="keep")
assert(#co:Build(fields,1).conflicts==0)
assert(co:Restore(id) and values.x==3)
co:Build(fields,1)
assert(co:Accept({["A:x"]="accept"}))
id=co.lastJournal.id
values.x=77
assert(not co:Restore(id) and values.x==77)
local restorePlan=co:BuildRestore(id)
assert(#restorePlan.conflicts==1 and restorePlan.conflicts[1].before==77)
assert(co:Accept({["A:x"]="keep"}) and values.x==77)
restorePlan=co:BuildRestore(id)
assert(co:Accept({["A:x"]="accept"}) and values.x==3)
assert(co.lastJournal.status=="restored")
for i=1,100 do Addon.Diagnostics:Log("test",i) end
assert(#Addon.Diagnostics.entries==80)
Addon.record={} Addon.VERSION='test-candidate' Addon.CONFIG_REVISION=12
Addon.Diagnostics:SetFeature('temporaryAccess','pending','real overflow requires native acceptance')
local saved=Addon.record.lastRuntimeDiagnostics
assert(saved.codeVersion=='test-candidate' and saved.configRevision==12)
assert(#saved.entries==80 and saved.features.temporaryAccess.status=='pending')
Addon.Diagnostics.features.temporaryAccess.reason='changed'
assert(saved.features.temporaryAccess.reason=='real overflow requires native acceptance','diagnostics aliased live tables')
Addon.record={}
Addon.Diagnostics:Log('test','new GUID session')
assert(Addon.record.lastRuntimeDiagnostics~=saved and #Addon.record.lastRuntimeDiagnostics.entries==80)
assert(saved.entries[80].message~='new GUID session','diagnostics rewrote previous saved snapshot')
Addon.record=nil

-- Binding selection and key changes carry their own compensating subjournal.
for failAt=1,5 do
    local set=1
    local banks={[1]={SPACE="JUMP",PAD1="JUMP",PAD2="OLD"},[2]={K="OTHER",PAD1="TARGET",PAD2="TARGET2"}}
    local originals=C.Copy(banks)
    local calls=0
    local api={AccountSet=1,CharacterSet=2,GetCurrentBindingSet=function() return set end,
        InCombatLockdown=function() return false end,LoadBindings=function(v) set=v end,
        GetNumBindings=function() local n=0 for _ in pairs(banks[set]) do n=n+1 end return n end,
        GetBinding=function(i) local n=0 for k,v in pairs(banks[set]) do n=n+1 if n==i then return v,"category",k end end end,
        GetBindingAction=function(k) return banks[set][k] or "" end,
        SetBinding=function(k,v) calls=calls+1 if calls==failAt then return false end banks[set][k]=v return true end,
        SaveBindings=function(v) assert(v==set) return true end}
    local native=Addon.NativeBindings.New(api)
    local batch=Addon.BindingStateAdapter.New(native,{PAD1=true,PAD2=true})
    local before=batch:read({"state"})
    local desired=C.Copy(before)
    desired.set,desired.keys.PAD2=2,"NEW"
    local step={id="binding",scope="bindings",path={"state"},before=before,value=desired,revision=1}
    local record=S.GetCharacter(db,"B")
    local journal=Addon.Transactions.Prepare(db,"B",{step})
    local applied=Addon.Transactions.Apply(journal,{bindings=batch},function() return true end)
    if failAt<=4 then
        assert(not applied and journal.status=="rolled-back")
        assert(set==1 and C.Equal(banks,originals))
    else
        assert(applied and set==2 and banks[2].SPACE=="JUMP" and banks[2].PAD1=="JUMP" and banks[2].PAD2=="NEW")
        assert(not Addon.Transactions.Recover(journal,{bindings=batch},function() return true end))
        assert(journal.status=="recovery-required" and #journal.recovery==1)
        assert(Addon.Transactions.Recover(journal,{bindings=batch},function() return true end))
        assert(set==1 and C.Equal(banks,originals))
    end
end
TEST_SUCCESS=true
