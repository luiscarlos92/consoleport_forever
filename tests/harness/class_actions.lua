local Class=Addon.ClassActions
for _,class in ipairs({'WARRIOR','DRUID','PALADIN'}) do
    local chord=Class.Chord({UnitClass=function() return class,class end})
    assert(chord==(class=='WARRIOR' and Class.CHORD or Class.LEFT_CHORD),'class side differs from native Forever flyouts')
end
Addon.guid='A'
local binding=container:GetBindingForSet('Auras')
local keys={['CTRL-PADFORWARD']=binding,['CTRL-PADRSHOULDER']='TARGETSCANENEMY',PADRSHOULDER='TARGETSCANENEMY',
    ['SHIFT-PAD1']='ACTIONBUTTON1',SPACE='JUMP'}
local api={GetBindingAction=function(key) return keys[key] or '' end,
    UnitGUID=function() return 'A' end,GetNumShapeshiftForms=function() return 2 end,
    GetShapeshiftFormInfo=function(slot) return 1,slot==1,true,slot==1 and 101 or 102 end,
    PetHasActionBar=function() return false end,GetPetActionInfo=function() end}
assert(Class.ResolveSet(container,api)=='Auras','migration lost native suffix')
local state={set=2,keys=Core.Copy(keys),keyboard={SPACE='JUMP'}}
local before=Core.Copy(state)
Class.Bindings(state,a)
assert(state.keys[Class.CHORD]==binding and state.keys[Class.LEGACY]=='')
assert(state.keys.PADRSHOULDER=='TARGETSCANENEMY' and state.keys['SHIFT-PAD1']=='ACTIONBUTTON1' and state.keyboard.SPACE=='JUMP')
keys=Core.Copy(state.keys)
assert(Class.ResolveSet(container,api)=='Auras','reload lost migrated class ring address')
keys[Class.LEGACY]='TOGGLECHARACTER0'
local custom=Class.Bindings({keys=Core.Copy(keys)},a)
assert(custom.keys[Class.LEGACY]=='TOGGLECHARACTER0','unrelated menu shortcut was removed')
local both={keys={[Class.CHORD]=binding,[Class.LEFT_CHORD]=binding}}
Class.Bindings(both,a)
assert(both.keys[Class.LEFT_CHORD]=='','opposite-side legacy class opener survived')
local unrelated={keys={[Class.LEFT_CHORD]='TOGGLECHARACTER0'}}
Class.Bindings(unrelated,a)
assert(unrelated.keys[Class.LEFT_CHORD]=='TOGGLECHARACTER0','unrelated opposite-side chord was cleared')
local scopes=Addon.BindingPolicy.Split(state.keys)
assert(scopes.character[Class.CHORD]==binding)
assert(Addon.BindingPolicy.Compose(scopes.shared,scopes.character,scopes.retained)[Class.CHORD]==binding,'GUID projection dropped class chord')
keys={} assert(Class.ResolveSet(container,api)=='Auras','existing unbound class ring was ignored')
local classSet=container.Data.Auras container.Data.Auras=nil
assert(Class.ResolveSet(container,api)=='CPFClass','clean account has no class ring address')
container.Data.Auras=classSet
local baseline=Core.Copy(container.Data)
local proposed=Class.RingProposal(assert(a:Proposal()),a,api)
assert(Core.Equal(container.Data,baseline),'class preparation mutated native data')
assert(#proposed.sets.Auras==2 and proposed.sets.Auras[1].spell==102 and proposed.sets.Auras[2].spell==101)
assert(proposed.sets.Auras[0].name=='Manual class','class migration overwrote manual metadata')
assert(a:write({'state'},proposed))
assert(container.compiled.Auras.actions[2].kind=='spell' and container.compiled.Auras.actions[2].action==101,'native secure compiler did not receive learned class spell')
local again=Class.RingProposal({sets=Core.Copy(proposed.sets)},a,api)
assert(Core.Equal(again.sets,proposed.sets),'repeat class discovery duplicated abilities')
-- Ordinary managed transaction backs up both class binding and native ring state.
container.Data=Core.Copy(baseline)
local live=Core.Copy(before)
local adapter={read=function() return Core.Copy(live) end,write=function(_,_,value) if combat then return false end live=Core.Copy(value) return true end}
local coordinator=assert(Addon.Coordinator.New(account,'A',{bindings=adapter,rings=a},function() return not combat end))
local fields={{id='A/controller',scope='bindings',path={'state'},value=state,revision=15},
    {id='A/rings',scope='rings',path={'state'},value=proposed,revision=15}}
local installPlan=coordinator:Build(fields,15)
local decisions={} for _,field in ipairs(installPlan.conflicts) do decisions[field.id]='accept' end
combat=true assert(not coordinator:Accept()) combat=false
local ok,journal=coordinator:Accept(decisions) assert(ok,tostring(journal))
assert(live.keys[Class.CHORD]==binding and container.compiled.Auras.actions[2].action==101)
local restore,conflicts=Addon.Transactions.RestorePlan(journal,{bindings=adapter,rings=a})
assert(#conflicts==0)
local recovery=Addon.Transactions.Prepare(account,'A',restore,{restores=journal.id})
assert(Addon.Transactions.Apply(recovery,{bindings=adapter,rings=a},function() return not combat end))
assert(Core.Equal(live,before) and Core.Equal(container.Data,baseline),'class update rollback failed')
TEST_SUCCESS=true
