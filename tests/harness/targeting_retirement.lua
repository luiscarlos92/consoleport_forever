local C,S=Addon.Core,Addon.Store
local fresh={}
assert(S.EnsureSchema(fresh,'A'))
assert(fresh.shared.groundTargeting==nil and fresh.shared.groundTargetingHistory==nil,'retired preference tables recreated')
assert(Addon.GroundTargeting==nil and Addon.TargetingPreferences==nil and Addon.GroundSpells==nil and Addon.TargetingUI==nil,'placement module still loaded')
local old={databaseVersion=3,shared={groundTargeting={spells={[207684]='player'}},groundTargetingHistory={{manual='keep'}},runtimePolicy={groundTargetingEnabled=true,modesEnabled=true}},characters={A={targetingObserved={[207684]=true},identity={},appliedRevision=20}},transactions={}}
local legacy=C.Copy(old)
assert(S.EnsureSchema(old,'A'))
assert(S.GetCharacter(old,'A'))
assert(C.Equal(old.shared.groundTargeting,legacy.shared.groundTargeting) and C.Equal(old.shared.groundTargetingHistory,legacy.shared.groundTargetingHistory))
assert(C.Equal(old.characters.A.targetingObserved,legacy.characters.A.targetingObserved),'retirement erased historical observations')
-- Retired values, even malformed ones, must not gate unrelated character setup.
old.shared.groundTargeting='opaque legacy value'
old.characters.A.targetingObserved=false
assert(S.EnsureSchema(old,'A') and S.GetCharacter(old,'A'))
local policy=Addon.FlatConfigAdapter.New(function() return old.shared.runtimePolicy end,{modesEnabled=true},function() return false end)
local co=Addon.Coordinator.New(old,'A',{policy=policy},function() return true end)
old.transactions.old={guid='A',status='committed',steps={
    {id='retired-placement',scope='policy',path={'groundTargetingEnabled'},before=C.Encode(nil),value=C.Encode(true),revision=20},
    {id='retained-routing',scope='policy',path={'modesEnabled'},before=C.Encode(false),value=C.Encode(true),revision=20}}}
local journal=C.Copy(old.transactions.old)
local plan=assert(co:BuildRestore('old'))
assert(#plan.operations==1 and plan.operations[1].id=='retained-routing' and #plan.deferred==1,'retired policy blocked unrelated restore')
assert(co:Accept({}))
assert(old.shared.runtimePolicy.modesEnabled==false and old.shared.runtimePolicy.groundTargetingEnabled==true,'restore wrote retired policy')
assert(C.Equal(old.transactions.old.steps,journal.steps),'restore edited old journal')
TEST_SUCCESS=true
