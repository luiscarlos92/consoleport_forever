local Core,S=Addon.Core,Addon.RingSelectors
local manual={[0]={name='Manual class',custom='keep'},
    {type='item',item='6948'}, {type='spell',spell=101,link='manual'},
    {type='custom',binding='CUSTOM'}}
local wanted={{type='spell',spell=101,cpfSelector='CPFForm101'},
    {type='spell',spell=102,cpfSelector='CPFForm102'}}
local set,ledger,pending=S.Reconcile(manual,wanted,{})
assert(#set==4 and set[1].item=='6948' and set[2].link=='manual' and set[3].binding=='CUSTOM')
assert(not ledger.CPFForm101 and ledger.CPFForm102 and #pending==0)
-- Reorder generated entries without losing manual entries; remove only an
-- unchanged entry actually owned by the previous proposal.
set={set[4],set[3],set[1],set[2],[0]=set[0]}
local nextSet,nextLedger=S.Reconcile(set,{},ledger)
assert(#nextSet==3 and nextSet[1].binding=='CUSTOM' and nextSet[2].item=='6948' and nextSet[3].link=='manual')
assert(next(nextLedger)==nil and nextSet[0].custom=='keep')
set[1].manualNote='edited'
local changed,changedLedger,changedPending=S.Reconcile(set,wanted,ledger)
assert(#changed==4 and changed[1].manualNote=='edited' and not changedLedger.CPFForm102 and #changedPending==1)
local duplicate=Core.Copy(ledger.CPFForm102)
set[1]=Core.Copy(duplicate) set[#set+1]=Core.Copy(duplicate)
local kept,keptLedger,keptPending=S.Reconcile(set,wanted,ledger)
assert(#kept==5 and keptLedger.CPFForm102 and #keptPending==1,'duplicate tag was silently removed/claimed')
-- Current native generated suffixes are the only opener preview source. No
-- sets, bindings, protected actions or runtime globals are mutated.
local native={Data={Auras=Core.Copy(manual)},Shared={},GetName=function() return 'ActualRingFrame' end,
    GetBindingSuffixForSet=function(_,id) return 'suffix-'..id end}
function native:GetBindingForSet(id) return 'CLICK '..self:GetName()..':'..self:GetBindingSuffixForSet(id) end
local before=Core.Copy(native.Data)
local snapshot={guid='A',formsReady=true,forms={{spell=101,active=false},{spell=102,active=true},{spell=102}},
    pet={ready=true,guid='Pet-A',actions={{action=1,autoCastAllowed=false},{action=4,autoCastAllowed=true}}}}
local preview=assert(S.Build(snapshot,'A',native,'Auras',native.Data))
assert(not preview.active and #preview.class.set==4 and #preview.pet.set==2)
assert(preview.class.key=='CTRL-PADFORWARD' and preview.pet.key=='CTRL-SHIFT-PADFORWARD')
assert(preview.pet.bindingPreview=='CLICK ActualRingFrame:suffix-CPFPet')
assert(Core.Equal(native.Data,before) and not native.Data.CPFPet)
assert(preview.pet.set[1].type=='pet' and preview.pet.set[1].action==1)
assert(not preview.pet.set[2].autoCastAllowed,'discovery status was misused as a secure action attribute')
-- No pet/sacrificed pet offers no stale commands. A different pet has new
-- selector identities even if its native command slot stays the same.
local oldID=preview.pet.set[1].cpfSelector
snapshot.pet.guid='Pet-B'
local changedPet=assert(S.Build(snapshot,'A',native,'Auras',native.Data,preview))
assert(changedPet.pet.petGUID=='Pet-B' and changedPet.pet.set[1].cpfSelector~=oldID)
snapshot.pet={ready=true,actions={}}
assert(#assert(S.Build(snapshot,'A',native,'Auras',native.Data,changedPet)).pet.set==0)
snapshot.pet.ready=false
assert(not assert(S.Build(snapshot,'A',native,'Auras',native.Data,changedPet)).pet,'unqualified pet reused old commands')
snapshot.formsReady=false
assert(not assert(S.Build(snapshot,'A',native,'Auras',native.Data)).class)
snapshot.formsReady=true snapshot.pet.ready=true
native.Data.CPFPet={[0]={name='User pet set'}}
assert(not assert(S.Build(snapshot,'A',native,'Auras',native.Data)).pet,'same display name conferred set ownership')
native.Data.CPFPet=nil native.Shared.CPFPet={}
assert(not assert(S.Build(snapshot,'A',native,'Auras',native.Data)).pet)
native.Shared.CPFPet=nil
assert(not S.Build(snapshot,'B',native,'Auras',native.Data))
assert(not S.Build(snapshot,'A',native,'Auras',native.Data,{guid='B'}))
assert(not S.Build(snapshot,'A',native,'Auras',native.Data,true))
assert(not S.Build(snapshot,'A',native,'Auras',native.Data,{guid='A',class={managed=false}}))
native.GetBindingForSet=function() return 'CLICK wrong:wrong' end
local invalid=assert(S.Build(snapshot,'A',native,'Auras',native.Data))
assert(not invalid.class and not invalid.pet and #invalid.pending==2)
TEST_SUCCESS=true
