-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Abilities (database names)
abilities = {
	"strength",
	"dexterity",
	"constitution",
	"intelligence",
	"wisdom",
	"charisma"
};

ability_stol = {
	["STR"] = "strength",
	["DEX"] = "dexterity",
	["CON"] = "constitution",
	["INT"] = "intelligence",
	["WIS"] = "wisdom",
	["CHA"] = "charisma"
};


-- Values for wound comparison
healthstatusfull = "healthy";
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- Values for creature type comparison
creaturedefaulttype = "humanoid";
creaturehalftype = "half-";
creaturehalftypesubrace = "human";
creaturesubtype = {
	"aarakocra",
	"bullywug",
	"demon",
	"devil",
	"dragonborn",
	"dwarf",
	"elf", 
	"gith",
	"gnoll",
	"gnome", 
	"goblinoid",
	"grimlock",
	"halfling",
	"human",
	"kenku",
	"kuo-toa",
	"kobold",
	"lizardfolk",
	"living construct",
	"merfolk",
	"orc",
	"quaggoth",
	"sahuagin",
	"shapechanger",
	"thri-kreen",
	"titan",
	"troglodyte",
	"yuan-ti",
	"yugoloth",
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
conditions = {
	"blinded", 
	"charmed",
	"CoverSoftHalf",
	"CoverSoftFull",
	"CoverHardHalf",
	"CoverHardFull",
	"deafened",
	"encumbered",
	"frightened", 
	"grappled", 
	"incapacitated",
	"incorporeal",
	"intoxicated",
	"invisible", 
	"kneeling", 
	"paralyzed",
	"petrified",
	"poisoned",
	"prone", 
	"restrained",
	"Sleeping",
	"turned",
	"unconscious",
	"dead"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"CHECK",
	"DB",
	"OB",
	"DMG",
	"HEAL",
	"RR",
	"STR",
	"CON",
	"DEX",
	"INT",
	"WIS",
	"CHA",
};

-- Condition effect types for token widgets
condcomps = {
	["blinded"] = "cond_blinded",
	["charmed"] = "cond_charmed",
	["deafened"] = "cond_deafened",
	["encumbered"] = "cond_encumbered",
	["frightened"] = "cond_frightened",
	["grappled"] = "cond_grappled",
	["incapacitated"] = "cond_paralyzed",
	["incorporeal"] = "cond_incorporeal",
	["invisible"] = "cond_invisible",
	["kneeling"] = "cond_prone",
	["paralyzed"] = "cond_paralyzed",
	["petrified"] = "cond_paralyzed",
	["poisoned"] = "cond_sickened",
	["prone"] = "cond_prone",
	["restrained"] = "cond_restrained",
	["Sleeping"] = "cond_unconscious",
	["unconscious"] = "cond_unconscious",
	["dead"] = "cond_dead",
	-- Similar to conditions
	["CoverSoftHalf"] = "cond_conceal",
	["CoverSoftFull"] = "cond_conceal",
	["CoverHardHalf"] = "cond_cover",
	["CoverHardFull"] = "cond_cover",

	["Bleeding"] = "cond_bleed",
	["Stun"] = "cond_stunned",
	["NoParry"] = "cond_helpless",
	["MustParry"] = "cond_mustparry",
	["Penalty"] = "cond_penalty",
	["ParryPenalty"] = "cond_penalty",
	["Dying"] = "cond_dying",
};

-- Other visible effect types for token widgets
othercomps = {
	["CoverSoftHalf"] = "cond_conceal",
	["CoverSoftFull"] = "cond_conceal",
	["CoverHardHalf"] = "cond_cover",
	["CoverHardFull"] = "cond_cover",
	["IMMUNE"] = "cond_immune",
	["RESIST"] = "cond_resistance",
	["VULN"] = "cond_vulnerable",
	["REGEN"] = "cond_regeneration",
	["DMGO"] = "cond_bleed",

	["Bleeding"] = "cond_bleed",
	["Stun"] = "cond_stunned",
	["NoParry"] = "cond_helpless",
	["MustParry"] = "cond_mustparry",
	["Penalty"] = "cond_penalty",
	["ParryPenalty"] = "cond_penalty",
	["Dying"] = "cond_dying",
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"COVER",
	"SCOVER",
	"DB",
	"RR",
	"OB",
	"DMG",
	"IMMUNE",
	"VULN",
	"RESIST"
};

connectors = {
	"and",
	"or"
};

-- Range types supported
rangetypes = {
	"melee",
	"ranged"
};

-- Damage types supported
dmgtypes = {
	"acid",		-- ENERGY TYPES
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"poison",
	"psychic",
	"radiant",
	"thunder",
	"adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	"cold-forged iron",
	"magic",
	"piercing",
	"silver",
	"slashing",
	"critical", -- SPECIAL DAMAGE TYPES
	"Bleeding",
	"Stun",
};

specialdmgtypes = {
	"critical",
	"Bleeding",
	"Stun",
};

-- Bonus types supported in power descriptions
bonustypes = {
};
stackablebonustypes = {
};

function onInit()
	-- Skills
	skilldata = {
		[Interface.getString("skill_value_acrobatics")] = { lookup = "acrobatics", stat = 'dexterity' },
		[Interface.getString("skill_value_animalhandling")] = { lookup = "animalhandling", stat = 'wisdom' },
		[Interface.getString("skill_value_arcana")] = { lookup = "arcana", stat = 'intelligence' },
		[Interface.getString("skill_value_athletics")] = { lookup = "athletics", stat = 'strength' },
		[Interface.getString("skill_value_deception")] = { lookup = "deception", stat = 'charisma' },
		[Interface.getString("skill_value_history")] = { lookup = "history", stat = 'intelligence' },
		[Interface.getString("skill_value_insight")] = { lookup = "insight", stat = 'wisdom' },
		[Interface.getString("skill_value_intimidation")] = { lookup = "intimidation", stat = 'charisma' },
		[Interface.getString("skill_value_investigation")] = { lookup = "investigation", stat = 'intelligence' },
		[Interface.getString("skill_value_medicine")] = { lookup = "medicine", stat = 'wisdom' },
		[Interface.getString("skill_value_nature")] = { lookup = "nature", stat = 'intelligence' },
		[Interface.getString("skill_value_perception")] = { lookup = "perception", stat = 'wisdom' },
		[Interface.getString("skill_value_performance")] = { lookup = "performance", stat = 'charisma' },
		[Interface.getString("skill_value_persuasion")] = { lookup = "persuasion", stat = 'charisma' },
		[Interface.getString("skill_value_religion")] = { lookup = "religion", stat = 'intelligence' },
		[Interface.getString("skill_value_sleightofhand")] = { lookup = "sleightofhand", stat = 'dexterity' },
		[Interface.getString("skill_value_stealth")] = { lookup = "stealth", stat = 'dexterity', disarmorstealth = 1 },
		[Interface.getString("skill_value_survival")] = { lookup = "survival", stat = 'wisdom' },
	};

end
