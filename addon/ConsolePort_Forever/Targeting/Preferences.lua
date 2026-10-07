local _,Addon=...
local Prefs={}
Addon.TargetingPreferences=Prefs
Prefs.Modes={default=true,cursor=true,player=true,manual=true}
Prefs.Contexts={vehicle=true,override=true,temporary=true,extra=true}
Prefs.Classes={
    DEATHKNIGHT={43265,152280,51052},
    DEMONHUNTER={189110,191427,202137,202138,204596,207684,390163,452490,1234796},
    DRUID={102793,145205,205636}, HUNTER={1543,162488,187650,187698,191433,260243},
    MAGE={2120,113724,153561,190356}, MONK={115313,115315,116844},
    PRIEST={32375,62618,34861,121536}, ROGUE={1725,195457},
    SHAMAN={2484,61882,73920,98008,51485,192058,192222,192077,207399,444995,108287,198838},
    WARLOCK={1122,5740,30283,152108,111771}, WARRIOR={6544,376079}, PALADIN={},EVOKER={},
}
-- PvE placement recommendations and their rationale are retained in
-- evidence/targeting/pve-defaults.json. Defaults never depend on spec/GUID.
Prefs.PlayerDefaults={[43265]=true,[152280]=true,[121536]=true}
function Prefs.Default(id,context)
    if context then return 'cursor' end
    return Prefs.PlayerDefaults[id] and 'player' or 'cursor'
end
function Prefs.Validate(value)
    if type(value)~='table' then return false end
    if (value.spells~=nil and type(value.spells)~='table') or (value.contexts~=nil and type(value.contexts)~='table') then return false end
    for key,mode in pairs(value.spells or {}) do
        if type(key)~='number' or key<=0 or key%1~=0 or not Prefs.Modes[mode] then return false end
    end
    for key,mode in pairs(value.contexts or {}) do
        if not Prefs.Contexts[key] or not Prefs.Modes[mode] then return false end
    end
    return true
end
function Prefs.Read(db)
    local value=db and db.shared and db.shared.groundTargeting
    return value==nil and {spells={},contexts={}} or value
end
function Prefs.Resolve(value,id,context)
    if not Prefs.Validate(value) then return 'manual' end
    local chosen=(value.spells or {})[id]
    if chosen and chosen~='default' then return chosen end
    if context then
        local mode=(value.contexts or {})[context]
        if mode and mode~='default' then return mode end
    end
    return Prefs.Default(id,context)
end
function Prefs.Qualified(value,id)
    -- An explicit player choice can qualify an encountered temporary reticle.
    -- Neither an unknown action nor a context default is evidence of a reticle.
    local chosen=Prefs.Validate(value) and (value.spells or {})[id]
    return Addon.GroundSpells[id]~=nil or chosen=='cursor' or chosen=='player'
end
function Prefs.Apply(db,draft,api)
    if api.InCombatLockdown() then return false,'Finish combat before applying targeting preferences.' end
    if not db or not db.shared or not Prefs.Validate(draft) then return false,'Targeting preferences are unavailable.' end
    local previous=Addon.Core.Copy(db.shared.groundTargeting or {})
    db.shared.groundTargetingHistory=db.shared.groundTargetingHistory or {}
    db.shared.groundTargetingHistory[#db.shared.groundTargetingHistory+1]=previous
    db.shared.groundTargeting=Addon.Core.Copy(draft)
    return true
end
function Prefs.Rows(class,api,observed)
    local rows,seen={},{}
    for _,id in ipairs(Prefs.Classes[class] or {}) do
        local info=api.C_Spell and api.C_Spell.GetSpellInfo(id)
        rows[#rows+1]={id=id,name=info and info.name or Addon.GroundSpells[id],known=true}
        seen[id]=true
    end
    for id in pairs(observed or {}) do
        if not seen[id] then
            local info=api.C_Spell.GetSpellInfo(id)
            if info and type(info.name)=='string' then rows[#rows+1]={id=id,name=info.name,known=Addon.GroundSpells[id]~=nil,temporary=true} end
        end
    end
    table.sort(rows,function(a,b) if a.temporary~=b.temporary then return not a.temporary end return a.name<b.name end)
    return rows
end
