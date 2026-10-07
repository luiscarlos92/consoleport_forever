local _, Addon = ...
-- Retail ground-placement cast IDs, not AoE damage/buff IDs. Qualifications and
-- exclusions are recorded in evidence/targeting/ground-spells.json. Unknown
-- IDs (including replacements) deliberately retain native targeting.
Addon.GroundSpells = {
    [43265]='Death and Decay', [152280]='Defile', [51052]='Anti-Magic Zone',
    [189110]='Infernal Strike', [191427]='Metamorphosis',
    [202137]='Sigil of Silence', [202138]='Sigil of Chains',
    [204596]='Sigil of Flame', [207684]='Sigil of Misery',
    [390163]='Sigil of Spite', [452490]='Sigil of Doom', [1234796]='Shift',
    [102793]="Ursol's Vortex", [145205]='Efflorescence', [205636]='Force of Nature',
    [1543]='Flare', [162488]='Steel Trap',
    [187650]='Freezing Trap', [187698]='Tar Trap', [191433]='Explosive Trap',
    [260243]='Volley',
    [2120]='Flamestrike', [113724]='Ring of Frost', [153561]='Meteor', [190356]='Blizzard',
    [115313]='Summon Jade Serpent Statue', [115315]='Summon Black Ox Statue',
    [116844]='Ring of Peace',
    [32375]='Mass Dispel', [62618]='Power Word: Barrier',
    [34861]='Holy Word: Sanctify', [121536]='Angelic Feather',
    [1725]='Distract', [195457]='Grappling Hook',
    [2484]='Earthbind Totem', [61882]='Earthquake', [73920]='Healing Rain',
    [98008]='Spirit Link Totem', [51485]='Earthgrab Totem', [192058]='Capacitor Totem',
    [192222]='Liquid Magma Totem', [192077]='Wind Rush Totem',
    [207399]='Ancestral Protection Totem',
    [444995]='Surging Totem', [108287]='Totemic Projection', [198838]='Earthen Wall Totem',
    [1122]='Summon Infernal', [5740]='Rain of Fire', [30283]='Shadowfury',
    [152108]='Cataclysm', [111771]='Demonic Gateway', [6544]='Heroic Leap', [376079]="Champion's Spear",
}
