-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ColorManager.setWindowMenuIconColor("400020");
	DecalManager.setDefault("images/decals/RM_bloody_decal.png@RolemasterClassic Assets");

	ModifierManager.addModWindowPresets(_tModifierWindowPresets);
	ModifierManager.addKeyExclusionSets(_tModifierExclusionSets);
	
	for k,v in pairs(aDataModuleSet) do
		for _,v2 in ipairs(v) do
			Desktop.addDataModuleSet(k, v2);
		end
	end

	if Session.IsHost then
		local tRMT = {
				sIcon = "sidebar_icon_link_rolemaster_tables",
				tooltipres="sidebar_tooltip_rolemaster_tables",
				class="referencetablelist",
			};
	    DesktopManager.registerSidebarToolButton(tRMT);
		local tRMR = {
				sIcon = "sidebar_icon_link_tableresolver",
				tooltipres="sidebar_tooltip_tableresolver",
				class="tableresolver",
			};
	    DesktopManager.registerSidebarToolButton(tRMR);
	end
end

aDataModuleSet = 
{
	["client"] =
	{
		{
			name = "RMC - Core Rules",
			modules =
			{
				{ name = "Arms Law", storeid = "DGA080" },
				{ name = "Character Law", storeid = "DGA080" },
				{ name = "Spell Law", storeid = "DGA080" },
			},
		},
		{
			name = "RMC - All Rules",
			modules =
			{
				{ name = "Arms Law", storeid = "DGA080" },
				{ name = "Character Law", storeid = "DGA080" },
				{ name = "Spell Law", storeid = "DGA080" },
				{ name = "Fantasy Weapons", storeid = "ICERMCFantasyWeapons" },
				{ name = "The Armoury", storeid = "ICERMC1016FG2" },
				{ name = "Rolemaster Companion 1 - Players", storeid = "ICEFGRMCGCP009" },
			},
		},
	},
	["host"] =
	{
		{
			name = "RMC - Core Rules",
			modules =
			{
				{ name = "Arms Law", storeid = "DGA080" },
				{ name = "Character Law", storeid = "DGA080" },
				{ name = "Spell Law", storeid = "DGA080" },
				{ name = "Creatures and Treasures", storeid = "DGA080" },
				{ name = "Creatures and Treasures - Players", storeid = "DGA080" },
			},
		},
		{
			name = "RMC - All Rules",
			modules =
			{
				{ name = "Arms Law", storeid = "DGA080" },
				{ name = "Character Law", storeid = "DGA080" },
				{ name = "Spell Law", storeid = "DGA080" },
				{ name = "Creatures and Treasures", storeid = "DGA080" },
				{ name = "Creatures and Treasures - Players", storeid = "DGA080" },
				{ name = "Fantasy Weapons", storeid = "ICERMCFantasyWeapons" },
				{ name = "The Armoury", storeid = "ICERMC1016FG2" },
				{ name = "Rolemaster Companion 1", storeid = "ICEFGRMCGCP009" },
				{ name = "Rolemaster Companion 1 - Players", storeid = "ICEFGRMCGCP009" },
			},
		},
	},
};

-- Shown in Modifiers window
-- NOTE: Set strings for "modifier_category_*" and "modifier_label_*"
_tModifierWindowPresets =
{
	{ 
		sCategory = "position",
		tPresets = { 
			"flank",
			"rearflank",
			"rear",
		}
	},
	{ 
		sCategory = "cover",
		tPresets = { 
			"halfsoft",
			"fullsoft",
			"halfhard",
			"fullhard",
		}
	},
};
_tModifierExclusionSets =
{
	{ "routine", "easy", "light", "medium", "hard", "veryhard", "extremelyhard", "sheerfolly", "absurd" },
	{ "flank", "rearflank", "rear" },
	{ "halfsoft", "fullsoft", "halfhard", "fullhard" },
};

_tTokenLight = {
	["candle"] = {
		sColor = "FFFFFCC3",
		nBright = 1,
		nDim = 2,
		sAnimType = "flicker",
		nAnimSpeed = 100,
		nDuration = 720,
	},
	["torch"] = {
		sColor = "FFFFF3E1",
		nBright = 2,
		nDim = 4,
		sAnimType = "flicker",
		nAnimSpeed = 25,
		nDuration = 2160,
	},
	["lantern"] = {
		sColor = "FFF9FEFF",
		nBright = 5,
		nDim = 10,
		nDuration = 2160,
	},
	["spell_light_1"] = {
		sColor = "FFFFF3E1",
		nBright = 1,
		nDim = 2,
		nDuration = 120,
	},
	["spell_light_2"] = {
		sColor = "FFFFF3E1",
		nBright = 2,
		nDim = 4,
		nDuration = 240,
	},
	["spell_light_3"] = {
		sColor = "FFFFF3E1",
		nBright = 3,
		nDim = 6,
		nDuration = 480,
	},
	["spell_light_5"] = {
		sColor = "FFFFF3E1",
		nBright = 5,
		nDim = 10,
		nDuration = 780,
	},
	["spell_light_10"] = {
		sColor = "FFFFF3E1",
		nBright = 10,
		nDim = 20,
		nDuration = 900,
	},
	["spell_darkness_1"] = {
		sColor = "FF000000",
		nBright = 2,
		nDim = 2,
		nDuration = 360,
	},
	["spell_darkness_2"] = {
		sColor = "FF000000",
		nBright = 4,
		nDim = 4,
		nDuration = 60,
	},
	["spell_darkness_5"] = {
		sColor = "FF000000",
		nBright = 10,
		nDim = 10,
		nDuration = 540,
	},
	["spell_darkness_10"] = {
		sColor = "FF000000",
		nBright = 20,
		nDim = 20,
		nDuration = 180,
	},
};