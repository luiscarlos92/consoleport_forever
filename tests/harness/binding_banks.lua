local C,T=Addon.Core,Addon.Transactions
local function fixture(unsaved,initialFailure)
    local db={} assert(Addon.Store.EnsureSchema(db,"A"))
    local record=Addon.Store.GetCharacter(db,"A")
    local stored={[1]={SPACE="JUMP",PAD1="JUMP",PAD2="OLD",PADOUT="UNOWNED"},[2]={K="OTHER",PAD1="TARGET",PAD2="TARGET2"}}
    local set,persisted,view=1,1,C.Copy(stored[1])
    if unsaved then view.UNSAVED="ORIGINAL-TRANSIENT" end
    local stats={loads=0,saves=0,sets=0}
    local api={AccountSet=1,CharacterSet=2,GetCurrentBindingSet=function() return set end,
        InCombatLockdown=function() return stats.combat or false end,
        LoadBindings=function(v) stats.loads=stats.loads+1 if stats.failLoad==v then return end set=v view=C.Copy(stored[v]) end,
        GetNumBindings=function() local n=0 for _ in pairs(view) do n=n+1 end return n end,
        GetBinding=function(i) local n=0 for key,value in pairs(view) do n=n+1 if n==i then return value,"category",key end end end,
        GetBindingAction=function(key) return view[key] or "" end,
        SetBinding=function(key,value)
            stats.sets=stats.sets+1
            if stats.sets==stats.failSet then return false end
            view[key]=value return true
        end,
        SaveBindings=function(v)
            assert(v==set) stats.saves=stats.saves+1
            -- Model a native save that takes effect even if its return is false.
            stored[v]=C.Copy(view) persisted=v
            return stats.saves~=stats.failSave
        end}
    local native=Addon.NativeBindings.New(api)
    local state=Addon.BindingStateAdapter.New(native,{PAD1=true,PAD2=true},record)
    local banks=Addon.BindingBanksAdapter.New(native,record,function() return not stats.combat end)
    state.bankInspector=banks
    local adapters={bindings=state,bindingBanks=banks}
    local before=state:read({"state"})
    local desired=C.Copy(before) desired.set=2 desired.keys.PAD2="NEW"
    local journal=T.Prepare(db,"A",{{id="A/controller",scope="bindings",path={"state"},before=before,value=desired,revision=1}})
    if initialFailure then stats[initialFailure.kind]=initialFailure.index end
    local installed=T.Apply(journal,adapters,function() return not stats.combat end)
    if not initialFailure then assert(installed) assert(T.Commit(db,journal,1)) else assert(not installed) end
    local co=Addon.Coordinator.New(db,"A",adapters,function() return not stats.combat end)
    return {db=db,record=record,stored=stored,stats=stats,native=native,banks=banks,state=state,adapters=adapters,journal=journal,co=co,
        persisted=function() return persisted end,view=function() return view end,set=function() return set end,
        select=function(v) api.LoadBindings(v) end}
end

-- Initial projection rollback restores persisted selection, not just the
-- current API view. Discarded source transient keys require conflict review.
for _,kind in ipairs({"failSet","failSave"}) do
    local initial=fixture(false,{kind=kind,index=1})
    assert(initial.journal.status=="rolled-back" and initial.set()==1 and initial.persisted()==1)
    assert(initial.stored[1].SPACE=="JUMP" and initial.stored[2].K=="OTHER" and initial.stored[2].PAD1=="TARGET")
end
local transient=fixture(true,{kind="failSave",index=1})
assert(transient.journal.status=="recovery-required" and transient.record.bindingViewRecovery and transient.set()==1 and transient.persisted()==1)
local viewPlan=assert(transient.co:BuildBindingViewRecovery())
local viewDecisions={}
for _,entry in ipairs(viewPlan.conflicts) do viewDecisions[entry.id]="accept" end
assert(transient.co:Accept(viewDecisions) and transient.journal.bindingOriginalViewReviewed.UNSAVED=="ORIGINAL-TRANSIENT")
assert(T.Recover(transient.journal,transient.adapters,function() return true end))
assert(transient.journal.status=="rolled-back" and transient.view().UNSAVED=="ORIGINAL-TRANSIENT" and transient.persisted()==1)

local f=fixture(true)
f.stored[1].SPACE="NEWER-ACCOUNT-KEY"
f.stored[1].Z="NEW-ACCOUNT-KEY"
assert(f.native:write({"PAD2"},"MANUAL"))
assert(f.native:write({"NEWPAD"},"UNSAVED-NEWER-KEY"))
local priorView=C.Copy(f.view()) local priorStored=C.Copy(f.stored)
local loads,saves=f.stats.loads,f.stats.saves
local plan,reason=f.co:BuildRestore(f.journal.id)
assert(not plan and reason:match("consent") and f.stats.loads==loads and f.stats.saves==saves)
assert(not pcall(f.banks.read,f.banks,{"key",1,"SPACE"}))
assert(C.Equal(f.stored,priorStored) and C.Equal(f.view(),priorView))
f.banks:Permit(1,f.journal.id) f.banks:Permit(2,f.journal.id)
plan=assert(f.co:BuildRestore(f.journal.id))
assert(f.stats.saves==saves and f.set()==2 and C.Equal(f.view(),priorView) and C.Equal(f.stored,priorStored),"inspection saved or discarded a native bank/view")
local decisions={}
for _,entry in ipairs(plan.conflicts) do
    decisions[entry.id]=entry.path[3]=="UNSAVED" and "accept" or "keep"
end
assert(#plan.conflicts==3,"target edit, original edit and discarded original transient key must be separately reviewed")
assert(f.co:Accept(decisions))
local restored=f.co.lastJournal
assert(restored.status=="restored" and f.set()==1 and f.persisted()==1)
assert(f.stored[1].SPACE=="NEWER-ACCOUNT-KEY" and f.stored[1].UNSAVED=="ORIGINAL-TRANSIENT" and f.stored[1].Z=="NEW-ACCOUNT-KEY")
assert(f.stored[2].K=="OTHER" and f.stored[2].PAD1=="TARGET" and f.stored[2].PAD2=="MANUAL" and f.stored[2].NEWPAD=="UNSAVED-NEWER-KEY")
assert(not f.db.managedFields["A/controller"] and not f.record.pendingBindingSelection)
-- A new-session verifier has no inherited permit; only the accepted retained
-- journal may authorize scoped temporary selection for reload readback.
local fresh=Addon.BindingBanksAdapter.New(f.native,f.record,function() return true end)
assert(not pcall(fresh.read,fresh,{"key",2,"PAD1"}))
fresh:Attach(restored)
saves=f.stats.saves
for _,step in ipairs(restored.steps) do assert(C.Equal(C.Encode(fresh:read(step.path)),step.value)) end
assert(f.set()==1 and f.persisted()==1 and f.stats.saves==saves)

-- Inactive-bank review entered while combat starts must stay deferred.
f=fixture(false) f.banks:Permit(1,f.journal.id) f.stats.combat=true
loads=f.stats.loads
assert(not pcall(f.banks.read,f.banks,{"key",1,"SPACE"}) and f.stats.loads==loads)
f.stats.combat=false f.stats.failLoad=1
assert(not pcall(f.banks.read,f.banks,{"key",1,"SPACE"}))
assert(f.set()==2 and not f.record.pendingBindingSelection)

-- Interrupt returning to the outgoing bank: preserve the full view durably.
f=fixture(false) assert(f.native:write({"UNSAVED"},"TEMP"))
f.banks:Permit(1,f.journal.id) f.stats.failLoad=2
assert(not pcall(f.banks.read,f.banks,{"key",1,"SPACE"}))
assert(f.record.pendingBindingSelection and f.record.pendingBindingSelection.beforeView.UNSAVED=="TEMP")
f.stats.failLoad=nil
assert(f.banks:RecoverSelection())
assert(f.set()==2 and f.record.bindingViewRecovery and not f.record.pendingBindingSelection,"unknown post-interruption view must stay available for a later review")
assert(f.native:write({"NEWER"},"POST-INTERRUPTION"))
plan=assert(f.co:BuildBindingViewRecovery())
decisions={}
for _,entry in ipairs(plan.conflicts) do decisions[entry.id]=entry.path[3]=="UNSAVED" and "accept" or "keep" end
assert(f.co:Accept(decisions))
assert(not f.record.bindingViewRecovery and f.view().UNSAVED=="TEMP" and f.view().NEWER=="POST-INTERRUPTION" and f.record.appliedRevision==1)

-- A newer effective edit during partial return recovery is not reloaded away.
f=fixture(false)
f.record.pendingBindingSelection={beforeSet=2,targetSet=1,beforeView={PAD1="OLD-VIEW"},returnedView=C.Copy(f.view()),phase="returning"}
assert(f.native:write({"PAD1"},"NEWER-EFFECTIVE"))
loads=f.stats.loads
assert(not f.banks:RecoverSelection() and f.stats.loads==loads and f.view().PAD1=="NEWER-EFFECTIVE")

-- Every key writer and native saver fails once, including false-after-save.
local successful=fixture(false)
successful.banks:Permit(1,successful.journal.id) successful.banks:Permit(2,successful.journal.id)
assert(successful.co:BuildRestore(successful.journal.id))
local initialSets,initialSaves=successful.stats.sets,successful.stats.saves
assert(successful.co:Accept({}))
local countSets,countSaves=successful.stats.sets-initialSets,successful.stats.saves-initialSaves
for _,kind in ipairs({"Set","Save"}) do
    for index=1,(kind=="Set" and countSets or countSaves) do
        f=fixture(false) f.banks:Permit(1,f.journal.id) f.banks:Permit(2,f.journal.id)
        assert(f.co:BuildRestore(f.journal.id))
        local initial=C.Copy(f.stored) local selected=f.set()
        f.stats["fail"..kind]=(kind=="Set" and f.stats.sets or f.stats.saves)+index
        local ok=f.co:Accept({})
        assert(not ok,"injected native failure was falsely committed")
        if f.record.pendingBindingSelection then assert(f.banks:RecoverSelection()) end
        local journal=f.co.lastJournal
        if journal.status=="recovery-required" then assert(T.Recover(journal,f.adapters,function() return true end)) end
        assert(journal.status=="rolled-back" and C.Equal(f.stored,initial) and f.set()==selected and f.persisted()==selected,"both banks/selection must recover after a rejected restore")
    end
end
TEST_SUCCESS=true
