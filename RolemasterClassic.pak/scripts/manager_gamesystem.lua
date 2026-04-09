-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Ruleset action types
actions = {
	["dice"] = { bUseModStack = "true" },
	["table"] = { },
	["rmdice"] = { bUseModStack = "true" },
	["stat"] = { bUseModStack = "true" },
	["statgen"] = { },
	["statgain"] = { },
	["resistance"] = { bUseModStack = "true" },
	["skill"] = { bUseModStack = "true" },
	["attack"] = { sIcon = "action_attack", sTargeting = "each", bUseModStack = "true" },
	["damage"] = { sIcon = "action_damage", sTargeting = "each", bUseModStack = "true" },
	["heal"] = { sIcon = "action_heal", sTargeting = "each", bUseModStack = "true" },
	["effect"] = { sIcon = "action_effect", sTargeting = "all" },
	["initiative"] = { bUseModStack = "true" }
};

targetactions = {
	"attack",
	"damage",
	"heal",
	"effect"
};

currencies = { 
	{ name = "MP", weight = 0.01, value = 1000 },
	{ name = "PP", weight = 0.01, value = 100 },
	{ name = "GP", weight = 0.01, value = 10 },
	{ name = "SP", weight = 0.01, value = 1 },
	{ name = "BP", weight = 0.01, value = 0.1 },
	{ name = "CP", weight = 0.01, value = 0.01 },
	{ name = "TP", weight = 0.01, value = 0.001 },
	{ name = "IP", weight = 0.01, value = 0.0001 },
};
currencyDefault = "SP";

function onInit()	
	CombatListManager.registerStandardInitSupport();

	VisionManager.removeVisionType(Interface.getString("vision_darkvision"));
	VisionManager.removeVisionType(Interface.getString("vision_blindsight"));
	VisionManager.removeVisionType(Interface.getString("vision_truesight"));
	
	VisionManager.addVisionType(Interface.getString("vision_darkvision"), "truesight", true);
	VisionManager.addVisionType(Interface.getString("vision_nightvision"), "darkvision");
	VisionManager.addVisionType(Interface.getString("vision_sonar"), "blindsight", true);

	ImageDeathMarkerManagerRMC.registerStandardDeathMarkersRMC();
end

function getCharSelectDetailHost(nodeChar)
	return GameSystem.getCharSelectDetails(nodeChar);
end

function requestCharSelectDetailClient()
	return "name,#level,race,profession";
end

function receiveCharSelectDetailClient(vDetails)
	return vDetails[1], "Level " .. math.floor(vDetails[2]*100)*0.01 .. " " .. vDetails[3] .. " " .. vDetails[4];
end

function getPregenCharSelectDetail(nodePregenChar)
	return GameSystem.getCharSelectDetails(nodePregenChar);
end

function getCharSelectDetails(nodeChar)
	local sValue = "";
	local nLevel = DB.getValue(nodeChar, "level", 0);
	local sRace = DB.getValue(nodeChar, "race", "");
	local sProfession = DB.getValue(nodeChar, "profession", "");
	sValue = "Level " .. math.floor(nLevel*100)*0.01 .. " " .. sRace .. " " .. sProfession;
	return sValue;
end

function getDistanceUnitsPerGrid()
	return 5;
end

function getDistanceSuffix()
	return "'";
end
