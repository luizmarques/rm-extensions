-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

MovingManeuver_ID = 1;
StaticManeuver_ID = 2;

Primary_ID = 1;
Secondary_ID = 2;

BodyDevelopment = "Body Development";

SkillClasses = { 	[1] = "Primary", 
					[2] = "Secondary", 
}
function ClassList()
	local aClassList = {};
	for nID, sClass in pairs(SkillClasses) do
		table.insert(aClassList, sClass);
	end
	return aClassList;
end
function GetClassName(sSkillName)
	local nClassID = SkillClass(sSkillName);
	for nID, sClass in pairs(SkillClasses) do
		if nID == nClassID then
			return sClass;
		end
	end
	return "";
end
function GetClassID(sSkillClass)
	for nID, sClass in pairs(SkillClasses) do
		if sClass == sSkillClass then
			return nID;
		end
	end

	return Rules_Skills.Secondary_ID;
end
function SkillClass(sSkillName, nodeSkill)
	if nodeSkill then
		local sClass = string.lower(DB.getValue(nodeSkill, "class", ""));
		if sClass == "primary" then
			return Rules_Skills.Primary_ID;
		elseif sClass == "secondary" then
			return Rules_Skills.Secondary_ID;
		end
	end	
	
	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(vSkill, "fullname", "") == sSkillName or DB.getValue(vSkill, "name", "") == sSkillName then
				local sClass = string.lower(DB.getValue(vSkill, "class", ""));
				if sClass == "primary" then
					return Rules_Skills.Primary_ID;
				elseif sClass == "secondary" then
					return Rules_Skills.Secondary_ID;
				elseif string.find(vMapping, "primary") then
					return Rules_Skills.Primary_ID;
				else
					return Rules_Skills.Secondary_ID;
				end
			end
		end
	end
	-- not found
	return Rules_Skills.Secondary_ID;
end

SkillTypes = { 	[1] = "Moving Maneuver", 
				[2] = "Static Maneuver", 
				[3] = "Offensive Bonus", 
				[4] = "Special", 
}
function TypeList()
	local aTypeList = {};
	for nID, sType in pairs(SkillTypes) do
		table.insert(aTypeList, sType);
	end
	return aTypeList;
end
function GetTypeName(nTypeID)
	for nID, sType in pairs(SkillTypes) do
		if nID == nTypeID then
			return sType;
		end
	end
	return "";
end
function GetTypeID(sTypeName)
	for nID, sType in pairs(SkillTypes) do
		if sType == sTypeName then
			return nID;
		end
	end
	return 1;
end

SkillProgressions = { 	[1] = "Standard", 
						[2] = "Base (rank x 5)", 
						[3] = "Hits", 
						[4] = "Manual", 
						[5] = "Power Point"
}
function ProgressionList()
	local aProgressionList = {};
	for nID, sProgression in pairs(SkillProgressions) do
		table.insert(aProgressionList, sProgression);
	end
	return aProgressionList;
end
function GetProgressionName(nProgressionID)
	for nID, sProgression in pairs(SkillProgressions) do
		if nID == nProgressionID then
			return sProgression;
		end
	end
	return "";
end
function GetProgressionID(sProgressionName)
	for nID, sProgression in pairs(SkillProgressions) do
		if sProgression == sProgressionName then
			return nID;
		end
	end
	return 1;
end

function SkillCost(sSkillName, sProfession)
	-- Check Professions for Skill Costs
	local aMappings = LibraryData.getMappings("profession");
	for _, vMapping in ipairs(aMappings) do
		for _, vProfession in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(vProfession, "name", "") == sProfession then
				-- Check Primary Skill Costs for the profession
				for l, vSkillCost in pairs(DB.getChildren(vProfession, "skillcosts.primary")) do
					if DB.getValue(vSkillCost, "name", "") == sSkillName then
						return DB.getValue(vSkillCost, "cost", "");
					end
				end
				-- Check Secondary Skill Costs for the profession
				for l, vSkillCost in pairs(DB.getChildren(vProfession, "skillcosts.secondary")) do
					if DB.getValue(vSkillCost, "name", "") == sSkillName then
						return DB.getValue(vSkillCost, "cost", "");
					end
				end
			end
		end
	end
	
	-- Check Skill Costs for Skill Costs to handle the legacy way of storing skill costs
	local sLowerProfession = string.lower(string.gsub(sProfession,"%s+",""));
	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(vSkill, "name", "") == sSkillName then
				return DB.getValue(vSkill, "costs." .. sLowerProfession, "");
			end
		end
	end
	
	-- not found
	return "";
end

function RankBonus(nRank, nCalc)
	if nCalc==1 then
		-- This is a skill with standard progression
		if nRank < 1 then
			return -25;
		elseif nRank < 11 then
			return 5 * nRank;
		elseif nRank < 21 then
			return 2 * nRank + 30;
		elseif nRank < 31 then
			return nRank + 50;
		else
			return math.floor(nRank / 2) + 65;
		end
	elseif nCalc==2 then
		-- This is a skill with basic progression
		return 5 * nRank;
	else
		-- This is a skill with manual progression
		return 0;
	end
end

function SkillType(sSkillName)
	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(vSkill, "fullname", "") == sSkillName then
				return DB.getValue(vSkill, "type", Rules_Skills.StaticManeuver_ID);
			end
		end
	end

	-- not found
	return Rules_Skills.StaticManeuver_ID;
end

function ValidNewRanks(sCost, nNewRanks)
	if nNewRanks == 0 then
		return true;
	elseif string.len(sCost) > 0 and nNewRanks > 0 then
		if string.find(sCost, "/") then
			local loc = string.find(sCost, "/");
			local sFirstCost = string.sub(sCost, 1, loc - 1);
			local sSecondCost = string.sub(sCost, loc + 1);
			if sSecondCost == "*" then
				return true;
			else
				if nNewRanks <= 2 then
					return true;
				else
					return false;
				end
			end		
		else
			if nNewRanks == 1 then
				return true;
			else
				return false;
			end
		end
	end
	return false;
end

function DPCost(sCost, nNewRanks)
	if string.len(sCost) > 0 and nNewRanks > 0 then
		if string.find(sCost, "/") then
			local loc = string.find(sCost, "/");
			local sFirstCost = string.sub(sCost, 1, loc - 1);
			local sSecondCost = string.sub(sCost, loc + 1);
			if sSecondCost == "*" then
				return tonumber(sFirstCost) * nNewRanks;
			else
				return tonumber(sFirstCost) + (tonumber(sSecondCost) * (nNewRanks - 1));
			end		
		else
			if tonumber(sCost) ~= nil then
				return sCost * nNewRanks;
			else
				return 0;
			end
		end
	end
	return 0;
end

function Stats(sSkillName)
	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(vSkill, "fullname", "") == sSkillName then
				return DB.getValue(vSkill, "stats", "");
			end
		end
	end

	-- not found
	return ""

end

function PrimarySkillList()
	local aSkillList = {};
	
	aSkillList = SkillListByClass("Primary");
	
	return aSkillList;
end
function SecondarySkillList()
	local aSkillList = {};
	
	aSkillList = SkillListByClass("Secondary");
	
	return aSkillList;
end
function SkillListByClass(sSkillClass)
	local aSkillList = {};

	sSkillClass = string.lower(sSkillClass);

	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			local sClass = string.lower(DB.getValue(vSkill, "class", ""));
			if sClass == sSkillClass then
				local nSkillType = DB.getValue(vSkill, "type", 0);
				if nSkillType == 1 or nSkillType == 2 or sSkillType == "Moving Maneuver" or sSkillType == "Static Maneuver" then
					if DB.getChild(vSkill, "fullname") then
						table.insert(aSkillList, DB.getValue(vSkill, "fullname", ""));
					elseif DB.getChild(vSkill, "name") then
						table.insert(aSkillList, DB.getValue(vSkill, "name", ""));
					end
				end
			end
		end
	end
	
	return aSkillList;
end

function ManeuveringInArmorSkillList()
	local aSkillList = {};

	table.insert(aSkillList, "");

	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			if string.find(DB.getValue(vSkill, "fullname", ""), "Maneuvering in") then
				table.insert(aSkillList, DB.getValue(vSkill, "fullname", ""));
			end
		end
	end
	
	return aSkillList;
end

function GetStaticActionColumn(sSkillName)
	local sColumn = "General";
	local aColumnSkills = 	{ 
								["Influence and Interaction"] = { "Acting", "Diplomacy", "Interrogation", "Music", "Public-speaking", "Seduction", "Singing", "Streetwise", "Trading" }, 
								["Picking Locks and Disarming Traps"] = { "Pick Locks", "Disarm Traps" }, 
								["Reading Runes and Using Items"] = { "Runes", "Staves & Wands" }, 
								["Perception and Tracking"] = { "Perception", "Tracking" }
							};		
							
	for sColumnName, aSkills in pairs(aColumnSkills) do
		for _, sSkill in pairs(aSkills) do
			if sSkill == sSkillName then
				sColumn = sColumnName;
			end
		end
	end
	
	return sColumn;
end

-- LEVEL BONUSES
function CoreLevelBonusGroupList()
	return { 
				"Combat", 
				"Spell" 
			};
end

function RM2LevelBonusGroupList()
	return { 
				"Combat", 
				"Base Spells", 
				"Directed Spells", 
				"Outdoor Skills", 
				"Subterfuge Skills", 
				"Item Skills", 
				"Perception", 
				"Body Development" 
			};
end

function RMFRPLevelBonusGroupList()
	return { 
				"Armor", 
				"Artistic", 
				"Athletic", 
				"Awareness", 
				"Body Development", 
				"Combat Manuevers", 
				"Communications", 
				"Crafts", 
				"Directed Spells", 
				"Influence", 
				"Lore", 
				"Martial Arts", 
				"Outdoor", 
				"Power Awareness/Manipulation", 
				"Power Point Development", 
				"Science/Analytic", 
				"Self Control", 
				"Special Attacks", 
				"Special Defenses", 
				"Spells", 
				"Subterfuge", 
				"Technical/Trade", 
				"Urban", 
				"Weapon" 
			};
end

function RMCompanion2LevelBonusGroupList()
	return { 
				"Academic Skills", 
				"Arms Law Combat", 
				"Athletic Skills", 
				"Base Spell Casting", 
				"Body Development", 
				"Concentration Skills", 
				"Deadly Skills", 
				"Directed Spells Skills", 
				"General Skills", 
				"Linguistic Skills", 
				"Magical Skills", 
				"Medical Skills", 
				"Outdoor Skills", 
				"Perception Skills", 
				"Social Skills", 
				"Subterfuge Skills" 
			};
end

function GetLevelBonusNodeName(sOpt23G)
	local sLevelBonusNodeName = nil;

	if sOpt23G == string.lower(Interface.getString("option_val_core")) then
		sLevelBonusNodeName = "levelbonus.core";
	elseif sOpt23G == string.lower(Interface.getString("option_val_opt23_1")) then
		sLevelBonusNodeName = "levelbonus.rm2";
	elseif sOpt23G == string.lower(Interface.getString("option_val_opt23_2")) then
		sLevelBonusNodeName = "levelbonus.rmfrp";
	elseif sOpt23G == string.lower(Interface.getString("option_val_rmc2")) then
		sLevelBonusNodeName = "levelbonus.rmcompanion2";
	end
	
	return sLevelBonusNodeName;
end

function CoreLevelBonus(nLevelBonus, nLevel, bIsCombatSkill)
	local nBonus = 0;
	
	if nLevel > 20 then
		nBonus = 20 * nLevelBonus;
		if bIsCombatSkill and nBonus > 0 then
			nBonus = nBonus + (nLevel - 20);
		end
	else
		nBonus = nLevel * nLevelBonus;
	end

	return nBonus;
end

function SteppedLevelBonus(nLevelBonus, nLevel, bIsCombatSkill)
	if nLevelBonus >= 3 then
		if bIsCombatSkill then
			if nLevel >= 20 then
				return 75;
			elseif nLevel >= 10 then
				return 50;
			else
				return 25;
			end
		else
			if nLevel >= 20 then
				return 60;
			elseif nLevel >= 10 then
				return 40;
			else
				return 20;
			end
		end
	elseif nLevelBonus == 2 then
		if nLevel >= 20 then
			return 40;
		elseif nLevel >= 10 then
			return 25;
		else
			return 10;
		end
	elseif nLevelBonus == 1 then
		if nLevel >= 20 then
			return 20;
		elseif nLevel >= 10 then
			return 10;
		else
			return 5;
		end
	end
	
	return 0;
end

function StaticLevelBonus(nLevelBonus, bIsCombatSkill)
	if nLevelBonus >= 3 then
		if bIsCombatSkill then
			return 40;
		else
			return 30;
		end
	elseif nLevelBonus == 2 then
		return 20;
	elseif nLevelBonus == 1 then
		return 10;
	end
	
	return 0;
end

function GetSkillLevelBonus(nodeSkill, sLevelBonusNodeName, nodeProfession, nLevel)
	local nTotal = 0;
	if nodeSkill and sLevelBonusNodeName and nodeProfession and nLevel then
		local bIsCombatSkill = false;
		local nLevelBonus = 0;
		local sLevelBonusGroup = DB.getValue(nodeSkill, sLevelBonusNodeName, "");
		if sLevelBonusGroup ~= "" then
			if sLevelBonusGroup == "Combat" or sLevelBonusGroup == "Arms Law Combat" or sLevelBonusGroup == "Weapon" then
				bIsCombatSkill = true;
			end
			
			for _, vLevelBonus in pairs(DB.getChildren(nodeProfession, sLevelBonusNodeName)) do
				if sLevelBonusGroup == DB.getValue(vLevelBonus, "name", "") then
					nLevelBonus = DB.getValue(vLevelBonus, "bonus", 0);
				end
			end
		end
		
		local sOpt23T = string.lower(OptionsManager.getOption("CL23T"));
		if sOpt23T == string.lower(Interface.getString("option_val_core")) then
			nTotal = Rules_Skills.CoreLevelBonus(nLevelBonus, nLevel, bIsCombatSkill);
		elseif sOpt23T == string.lower(Interface.getString("option_val_opt23_3")) then
			nTotal = Rules_Skills.SteppedLevelBonus(nLevelBonus, nLevel, bIsCombatSkill);
		elseif sOpt23T == string.lower(Interface.getString("option_val_opt23_4")) then
			nTotal = Rules_Skills.StaticLevelBonus(nLevelBonus, bIsCombatSkill);
		end
	end
	
	return nTotal;
end
