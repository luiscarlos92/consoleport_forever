local _,Addon=...
local Discovery={}
Addon.RingDiscovery=Discovery
local function opaque(api,...)
    if not api.issecretvalue then return false end
    for i=1,select('#',...) do
        local value=select(i,...)
        if api.issecretvalue(value) then return true end
    end
    return false
end
local function capture(api,expectedGUID)
    if type(api.UnitGUID)~='function' then return nil,'current player identity unavailable' end
    local guid=api.UnitGUID('player')
    if opaque(api,guid) or type(guid)~='string' or guid=='' or guid~=expectedGUID then return nil,'discovery belongs to another or unavailable GUID' end
    local result={guid=guid,forms={},pet={actions={}},pending={}}
    if type(api.GetNumShapeshiftForms)~='function' or type(api.GetShapeshiftFormInfo)~='function' then
        result.pending[#result.pending+1]='native stance discovery unavailable'
    else
        local count=api.GetNumShapeshiftForms()
        if opaque(api,count) or type(count)~='number' or count<0 or count>64 or count%1~=0 then
            result.pending[#result.pending+1]='native stance count opaque or invalid'
        else
            for slot=1,count do
                local texture,active,castable,spellID=api.GetShapeshiftFormInfo(slot)
                if opaque(api,texture,active,castable,spellID) then
                    result.pending[#result.pending+1]='native stance '..slot..' opaque'
                elseif type(spellID)=='number' and spellID>0 and spellID%1==0 then
                    result.forms[#result.forms+1]={type='spell',spell=spellID,nativeStanceSlot=slot,
                        active=not not active,castable=not not castable}
                else result.pending[#result.pending+1]='native stance '..slot..' has no qualified spell ID' end
            end
        end
    end
    if type(api.PetHasActionBar)~='function' or type(api.GetPetActionInfo)~='function' then
        result.pending[#result.pending+1]='native pet action discovery unavailable'
    else
        local hasBar=api.PetHasActionBar()
        local petGUID=api.UnitGUID('pet')
        if opaque(api,hasBar,petGUID) then result.pending[#result.pending+1]='native pet identity/action bar opaque'
        elseif hasBar then
            if type(petGUID)~='string' or petGUID=='' then
                result.pending[#result.pending+1]='pet commands lack a qualified current pet identity'
            else
                result.pet.guid=petGUID
                -- Blizzard's current PetActionBar declares ten native slots.
                for slot=1,10 do
                    local name,texture,token,active,autoAllowed,autoEnabled,spellID=api.GetPetActionInfo(slot)
                    if opaque(api,name,texture,token,active,autoAllowed,autoEnabled,spellID) then
                        result.pending[#result.pending+1]='native pet slot '..slot..' opaque'
                    elseif type(name)=='string' and name~='' then
                        result.pet.actions[#result.pet.actions+1]={type='pet',action=slot,name=name,
                            isToken=not not token,active=not not active,autoCastAllowed=not not autoAllowed,
                            autoCastEnabled=not not autoEnabled,spell=(type(spellID)=='number' and spellID>0) and spellID or nil}
                    end
                end
            end
        end
    end
    local endGUID,endPetGUID=api.UnitGUID('player'),result.pet.guid and api.UnitGUID('pet')
    if opaque(api,endGUID,endPetGUID) or endGUID~=guid or (result.pet.guid and endPetGUID~=result.pet.guid) then
        return nil,'identity changed during discovery'
    end
    return result
end
function Discovery.Capture(api,expectedGUID)
    local ok,result,reason=pcall(capture,api,expectedGUID)
    if not ok then return nil,'native discovery read rejected' end
    return result,reason
end
function Discovery.BindingForSet(rings,setID)
    if not rings or type(rings.GetBindingForSet)~='function' or type(rings.GetBindingSuffixForSet)~='function'
        or type(rings.GetName)~='function' then return nil,'audited native ring container unavailable' end
    if (type(setID)~='number' and type(setID)~='string') or not ((type(rings.Data)=='table' and rings.Data[setID]) or (type(rings.Shared)=='table' and rings.Shared[setID])) then return nil,'native ring set does not exist' end
    local suffix=rings:GetBindingSuffixForSet(setID)
    local binding=rings:GetBindingForSet(setID)
    if type(binding)~='string' or binding~='CLICK '..rings:GetName()..':'..tostring(suffix) then return nil,'native ring binding readback rejected' end
    return binding
end
