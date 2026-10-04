local Core,Discovery=Addon.Core,Addon.RingDiscovery
local playerGUID,petGUID='Player-A','Pet-A'
local forms,petSlots={},{}
local hasPet=false
local secret={}
local api={UnitGUID=function(unit) return unit=='player' and playerGUID or petGUID end,
    GetNumShapeshiftForms=function() return #forms end,
    GetShapeshiftFormInfo=function(slot) return table.unpack(forms[slot]) end,
    PetHasActionBar=function() return hasPet end,
    GetPetActionInfo=function(slot) if petSlots[slot] then return table.unpack(petSlots[slot]) end end,
    issecretvalue=function(value) return value==secret end}
GetNumShapeshiftForms=api.GetNumShapeshiftForms
GetShapeshiftFormInfo=api.GetShapeshiftFormInfo
GetPetActionInfo=api.GetPetActionInfo
-- These operations must never be invoked by discovery.
function CastShapeshiftForm() error('discovery cast a form') end
function CastPetAction() error('discovery cast a pet action') end
function SetBinding() error('discovery changed a binding') end
function GetShapeshiftFormCooldown() return 0,0,0 end
function CooldownFrame_Set() end
--@NATIVE_ACTION_BARS
local noOp=function() end
local nativeButtons={}
for slot=1,3 do
    nativeButtons[slot]={icon={SetTexture=noOp,SetVertexColor=noOp},cooldown={Show=noOp,Hide=noOp},
        SetChecked=noOp,GetID=function() return slot end}
end
local nativeStance={actionButtons=nativeButtons,UpdateShownButtons=noOp,UpdateGridLayout=noOp}
-- Parameterize all Retail classes without product-side spell or flyout presets.
for classID=1,13 do
    playerGUID='Class-'..classID
    forms={{classID*10,true,false,classID*100},{classID*10+1,false,true,classID*100+1}}
    hasPet=classID%2==0
    petSlots={[1]={'PET_ATTACK',11,true,false,false,false},[4]={'TestPetSpell',12,false,true,true,true,400+classID}}
    local snapshot=assert(Discovery.Capture(api,playerGUID))
    StanceBarMixin.UpdateState(nativeStance)
    assert(#snapshot.forms==2 and snapshot.forms[1].spell==nativeButtons[1].spellID)
    assert(snapshot.forms[1].active and not snapshot.forms[1].castable,'learned form was filtered by current usability')
    if hasPet then
        local native=PetActionButtonMixin.GetActionButtonInfo({index=4})
        assert(#snapshot.pet.actions==2 and snapshot.pet.guid==petGUID)
        assert(snapshot.pet.actions[2].spell==native.id and snapshot.pet.actions[2].autoCastAllowed==native.autoCastAllowed)
        assert(snapshot.pet.actions[1].isToken and snapshot.pet.actions[1].action==1)
    else assert(#snapshot.pet.actions==0 and not snapshot.pet.guid) end
end
forms={} hasPet=false
assert(#assert(Discovery.Capture(api,playerGUID)).forms==0)
assert(not Discovery.Capture(api,'Different-GUID'))
hasPet=true petGUID=nil
assert(#assert(Discovery.Capture(api,playerGUID)).pet.actions==0)
petGUID='Pet-B' petSlots={[1]={'NewPetAction',13,false,false,false,false,500}}
local changedPet=assert(Discovery.Capture(api,playerGUID))
assert(changedPet.pet.guid=='Pet-B' and #changedPet.pet.actions==1)
petSlots[1][1]=secret
assert(#assert(Discovery.Capture(api,playerGUID)).pet.actions==0,'secret pet data was retained')
forms={{10,true,true,secret}}
assert(#assert(Discovery.Capture(api,playerGUID)).forms==0,'secret form was retained')
api.GetNumShapeshiftForms=function() return -1 end
assert(#assert(Discovery.Capture(api,playerGUID)).pending>0)
api.GetNumShapeshiftForms=function() error('getter unavailable during load') end
assert(not Discovery.Capture(api,playerGUID))
api.GetNumShapeshiftForms=GetNumShapeshiftForms
api.UnitGUID=function(unit)
    if unit=='pet' then petGUID=petGUID=='Pet-B' and 'Pet-C' or 'Pet-B' return petGUID end
    return playerGUID
end
assert(not Discovery.Capture(api,playerGUID),'mixed pet identities were retained')
api.UnitGUID=function() return secret end assert(not Discovery.Capture(api,playerGUID))

-- Actual current container suffix generation, not a hardcoded LeftButton.
local container={GetName=function() return 'CurrentNativeRing' end}
local env={Frame=container,Attributes={DefaultSetBtn='LeftButton'},GetStarterSet=function() return {} end}
local db={Register=function() end,Save=function() end}
CPAPI={DefaultRingSetID=1,GetEnv=function() return env,db end}
--@CURRENT_RING_CONTAINER
container.Data.Auras={} container.Data.CPFPetA={} container.Shared.SharedManual={}
assert(Discovery.BindingForSet(container,1)=='CLICK CurrentNativeRing:LeftButton')
assert(Discovery.BindingForSet(container,'Auras')=='CLICK CurrentNativeRing:Auras')
assert(Discovery.BindingForSet(container,'CPFPetA')=='CLICK CurrentNativeRing:CPFPetA')
assert(Discovery.BindingForSet(container,'SharedManual')=='CLICK CurrentNativeRing:SharedManual')
assert(not Discovery.BindingForSet(container,'Missing'))
container.GetBindingForSet=function() return 'CLICK CurrentNativeRing:wrong' end
assert(not Discovery.BindingForSet(container,'Auras'))
TEST_SUCCESS=true
