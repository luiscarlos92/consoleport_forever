local _,Addon=...
local Core,Selectors=Addon.Core,{}
Addon.RingSelectors=Selectors
Selectors.PET_SET='CPFPet'
Selectors.GATE='Exact stick-return and close-and-continue have no audited Retail protected route; existing controls retained. Active-entry cancellation has a separate unresolved action-type gate.'
local function semantic(action,resolver)
    if action.type~='spell' and action.type~='pet' then return end
    local kind,value=action.type,action.type=='spell' and action.spell or action.action
    if resolver then kind,value=resolver(action) end
    if kind and value then return kind..':'..tostring(value) end
end
-- The ledger claims only unchanged tagged entries from our previous proposal.
-- Untracked tags or manually edited generated entries retain their position.
function Selectors.Reconcile(current,wanted,ledger,resolver)
    local set,managed,pending={},{},{}
    for key,value in pairs(current) do if type(key)~='number' or key<1 then set[key]=Core.Copy(value) end end
    local desired,seen,semantics={},{},{}
    for _,entry in ipairs(wanted) do
        assert(type(entry.cpfSelector)=='string','selector identity required')
        assert(not desired[entry.cpfSelector],'duplicate selector identity')
        desired[entry.cpfSelector]=entry
    end
    for _,entry in ipairs(current) do
        local id=entry.cpfSelector
        local previous=id and ledger and ledger[id]
        if previous and Core.Equal(previous,entry) and not seen[id] then
            local nextEntry=desired[id]
            if nextEntry then
                set[#set+1]=Core.Copy(nextEntry)
                managed[id]=Core.Copy(nextEntry)
                semantics[assert(semantic(nextEntry,resolver),'qualified selector action required')]=true
            end
            seen[id]=true
        else
            set[#set+1]=Core.Copy(entry)
            local kind=semantic(entry,resolver)
            if kind then semantics[kind]=true end
            if id and desired[id] then
                seen[id]=true
                pending[#pending+1]='selector '..id..' is manual or has an unowned duplicate tag'
            end
        end
    end
    for _,entry in ipairs(wanted) do
        local id,kind=entry.cpfSelector,assert(semantic(entry,resolver),'qualified selector action required')
        if not seen[id] and not semantics[kind] then
            set[#set+1]=Core.Copy(entry)
            managed[id]=Core.Copy(entry)
            seen[id],semantics[kind]=true,true
        end
    end
    return set,managed,pending
end
local function address(rings,id)
    if not rings or type(rings.GetName)~='function' or type(rings.GetBindingForSet)~='function'
        or type(rings.GetBindingSuffixForSet)~='function' then return nil,'native ring suffix methods unavailable' end
    local suffix=rings:GetBindingSuffixForSet(id)
    local binding=rings:GetBindingForSet(id)
    local name=rings:GetName()
    if type(name)~='string' or name=='' or type(suffix)~='string' or suffix=='' or type(binding)~='string'
        or binding~='CLICK '..name..':'..suffix then return nil,'native selector suffix readback rejected' end
    return binding
end
function Selectors.Build(discovery,guid,rings,classSet,manualSets,previous)
    if not discovery or discovery.guid~=guid then return nil,'selector discovery belongs to another or unavailable GUID' end
    if type(manualSets)~='table' or (previous~=nil and type(previous)~='table') then return nil,'selector preparation storage is malformed' end
    if previous and previous.guid~=guid then return nil,'retained selector ledger belongs to another GUID' end
    for _,kind in ipairs({'class','pet'}) do
        local part=previous and previous[kind]
        if part~=nil and (type(part)~='table' or (part.managed~=nil and type(part.managed)~='table')) then return nil,'retained selector ledger is malformed' end
    end
    local result={guid=guid,active=false,gate=Selectors.GATE,pending={}}
    previous=previous or {}
    local resolver=rings.GetKindAndAction and function(entry) return rings:GetKindAndAction(Core.Copy(entry)) end
    if discovery.formsReady and classSet and manualSets[classSet] then
        local actions={}
        local seen={}
        for _,form in ipairs(discovery.forms) do
            if not seen[form.spell] then actions[#actions+1]={type='spell',spell=form.spell,cpfSelector='CPFForm'..form.spell} seen[form.spell]=true end
        end
        local set,managed,pending=Selectors.Reconcile(manualSets[classSet],actions,previous.class and previous.class.managed,resolver)
        local binding,reason=address(rings,classSet)
        if binding then result.class={id=classSet,set=set,managed=managed,bindingPreview=binding,key='CTRL-PADFORWARD',pending=pending}
        else result.pending[#result.pending+1]=reason end
    else result.pending[#result.pending+1]='qualified stance snapshot or current personal class set unavailable; baseline retained' end
    if discovery.pet.ready then
        if rings.Data[Selectors.PET_SET] or rings.Shared[Selectors.PET_SET] then
            result.pending[#result.pending+1]='new pet set name is already owned by native/manual data; no claim inferred'
        else
            local actions={}
            for _,pet in ipairs(discovery.pet.actions) do
                actions[#actions+1]={type='pet',action=pet.action,cpfSelector='CPFPet'..tostring(discovery.pet.guid)..'Slot'..pet.action}
            end
            local set,managed,pending=Selectors.Reconcile({[0]={name='Pet'}},actions,previous.pet and previous.pet.managed,resolver)
            local binding,reason=address(rings,Selectors.PET_SET)
            if binding then result.pet={id=Selectors.PET_SET,petGUID=discovery.pet.guid,set=set,managed=managed,
                bindingPreview=binding,key='CTRL-SHIFT-PADFORWARD',pending=pending}
            else result.pending[#result.pending+1]=reason end
        end
    else result.pending[#result.pending+1]='qualified current pet snapshot unavailable; no old pet commands offered' end
    return result
end
