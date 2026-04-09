-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

sDBStatNodeName = "abilities.quickness.total";
sBMRStatNodeName = "abilities.quickness.total";
sEncumbranceStatNodeName = "abilities.strength.total";


-- Get Stat List
function List()
	local aStatList = {};
	
	--[[ Development Stats ]]
	table.insert(aStatList, {name = "constitution", 	label = "Co", displayname = "Constitution", 	devStat = true, order = 1});
	table.insert(aStatList, {name = "agility", 			label = "Ag", displayname = "Agility", 			devStat = true, order = 2});
	table.insert(aStatList, {name = "selfdiscipline", 	label = "SD", displayname = "Self Discipline", 	devStat = true, order = 3});
	table.insert(aStatList, {name = "reasoning", 		label = "Re", displayname = "Reasoning", 		devStat = true, order = 4});
	table.insert(aStatList, {name = "memory", 			label = "Me", displayname = "Memory", 			devStat = true, order = 5});
	--[[ Other Stats ]]
	table.insert(aStatList, {name = "strength", 		label = "St", displayname = "Strength", 		devStat = false, order = 6});
	table.insert(aStatList, {name = "quickness", 		label = "Qu", displayname = "Quickness", 		devStat = false, order = 7});
	table.insert(aStatList, {name = "presence", 		label = "Pr", displayname = "Presence", 		devStat = false, order = 8});
	table.insert(aStatList, {name = "intuition", 		label = "In", displayname = "Intuition", 		devStat = false, order = 9});
	table.insert(aStatList, {name = "empathy", 			label = "Em", displayname = "Empathy", 			devStat = false, order = 10});

	return aStatList;
end

function DisplayNameList()
	local aFullStatList = Rules_Stats.List();
	local aDisplayNameList = {};
	
	for _, vStat in pairs(aFullStatList) do
		table.insert(aDisplayNameList, vStat.displayname);
	end
	
	return aDisplayNameList;
end

function AbbreviationList()
	local aFullStatList = Rules_Stats.List();
	local aAbbreviationList = {};
	
	table.insert(aAbbreviationList, "");
	for _, vStat in pairs(aFullStatList) do
		table.insert(aAbbreviationList, vStat.label);
	end
	
	return aAbbreviationList;
end


function GetAbbrFromName(sName)
	local statList = Rules_Stats.List();
	local sAbbr = "";
	sName = string.gsub(sName, "%s+", "")
	
	for _, vStat in pairs(statList) do
		if string.lower(vStat.name) == string.lower(sName) then
			sAbbr = vStat.label;
		end
	end
	
	return sAbbr;
end

function GetDisplayNameFromAbbr(sAbbr)
	local aStatList = Rules_Stats.List();
	local sName = nil;
	
	for _, vStat in pairs(aStatList) do
		if vStat.label == sAbbr then
			sName = vStat.displayname;
		end
	end
	
	return sName;
end


-- Stat Generation
StatGenType = {};
StatGenType.Random = "Random";
StatGenType.RandomFixed = "Random Fixed";
StatGenType.ThreeColumn = "Three Column";

function StatGenMinRollValue()
	return tonumber(OptionsManager.getOption("CMSG"));
end

-- Potentials and Stat Gain
function StatPotential(nTemp, nPotRoll)
	local nLocStart = 0;
	local nLocEnd = 0;
	local nPotential;
	local nColumn = 1;
	local aPotentialTable = {};
	table.insert(aPotentialTable, { min = 01, max = 10, results = "25 - - - - - - - - -" });
	table.insert(aPotentialTable, { min = 11, max = 20, results = "30 - - - - - - - - -" });
	table.insert(aPotentialTable, { min = 21, max = 30, results = "35 39 - - - - - - - -" });
	table.insert(aPotentialTable, { min = 31, max = 35, results = "38 42 59 - - - - - - -" });
	table.insert(aPotentialTable, { min = 36, max = 40, results = "40 45 62 - - - - - - -" });
	table.insert(aPotentialTable, { min = 41, max = 45, results = "42 47 64 - - - - - - -" });
	table.insert(aPotentialTable, { min = 46, max = 49, results = "44 49 66 - - - - - - -" });
	table.insert(aPotentialTable, { min = 50, max = 51, results = "46 51 68 - - - - - - -" });
	table.insert(aPotentialTable, { min = 52, max = 53, results = "48 53 70 - - - - - - -" });
	table.insert(aPotentialTable, { min = 54, max = 55, results = "50 55 71 - - - - - - -" });
	table.insert(aPotentialTable, { min = 56, max = 57, results = "52 57 72 74 84 - - - - -" });
	table.insert(aPotentialTable, { min = 58, max = 59, results = "54 59 73 75 85 - - - - -" });
	table.insert(aPotentialTable, { min = 60, max = 61, results = "56 61 74 76 86 - - - - -" });
	table.insert(aPotentialTable, { min = 62, max = 63, results = "58 63 75 77 87 - - - - -" });
	table.insert(aPotentialTable, { min = 64, max = 65, results = "60 65 76 78 88 - - - - -" });
	table.insert(aPotentialTable, { min = 66, max = 67, results = "62 67 77 79 88 89 - - - -" });
	table.insert(aPotentialTable, { min = 68, max = 69, results = "64 69 78 80 89 89 - - - -" });
	table.insert(aPotentialTable, { min = 70, max = 71, results = "66 71 79 81 89 90 - - - -" });
	table.insert(aPotentialTable, { min = 72, max = 73, results = "68 73 80 82 90 90 - - - -" });
	table.insert(aPotentialTable, { min = 74, max = 75, results = "70 75 81 83 90 91 - - - -" });
	table.insert(aPotentialTable, { min = 76, max = 77, results = "72 77 82 84 91 91 - - - -" });
	table.insert(aPotentialTable, { min = 78, max = 79, results = "74 79 83 85 91 92 - - - -" });
	table.insert(aPotentialTable, { min = 80, max = 81, results = "76 81 84 86 92 92 - - - -" });
	table.insert(aPotentialTable, { min = 82, max = 83, results = "78 83 85 87 92 93 - - - -" });
	table.insert(aPotentialTable, { min = 84, max = 85, results = "80 85 86 88 93 93 94 - - -" });
	table.insert(aPotentialTable, { min = 86, max = 87, results = "82 86 87 89 93 94 94 - - -" });
	table.insert(aPotentialTable, { min = 88, max = 89, results = "84 87 88 90 94 94 95 - - -" });
	table.insert(aPotentialTable, { min = 90, max = 90, results = "86 88 89 91 94 95 95 97 - -" });
	table.insert(aPotentialTable, { min = 91, max = 91, results = "88 89 90 92 95 95 96 97 - -" });
	table.insert(aPotentialTable, { min = 92, max = 92, results = "90 90 91 93 95 96 96 97 - -" });
	table.insert(aPotentialTable, { min = 93, max = 93, results = "91 91 92 94 96 96 97 98 - -" });
	table.insert(aPotentialTable, { min = 94, max = 94, results = "92 92 93 95 96 97 97 98 99 -" });
	table.insert(aPotentialTable, { min = 95, max = 95, results = "93 93 94 96 97 97 98 98 99 -" });
	table.insert(aPotentialTable, { min = 96, max = 96, results = "94 94 95 97 97 98 98 99 99 -" });
	table.insert(aPotentialTable, { min = 97, max = 97, results = "95 95 96 97 98 98 99 99 99 -" });
	table.insert(aPotentialTable, { min = 98, max = 98, results = "96 96 97 98 98 99 99 99 100 -" });
	table.insert(aPotentialTable, { min = 99, max = 99, results = "97 97 98 98 99 99 100 100 100 -" });
	table.insert(aPotentialTable, { min = 100, max = 100, results = "98 98 99 99 99 100 100 100 100 101" });
	
	for _, nRow in pairs(aPotentialTable) do
		if nPotRoll >= nRow.min and nPotRoll <= nRow.max then
			if nTemp < 25 then
				nColumn = 1;
			elseif nTemp <= 39 then
				nColumn = 2;
			elseif nTemp <= 59 then
				nColumn = 3;
			elseif nTemp <= 74 then
				nColumn = 4;
			elseif nTemp <= 84 then
				nColumn = 5;
			elseif nTemp <= 89 then
				nColumn = 6;
			elseif nTemp <= 94 then
				nColumn = 7;
			elseif nTemp <= 97 then
				nColumn = 8;
			elseif nTemp <= 99 then
				nColumn = 9;
			elseif nTemp == 100 then
				nColumn = 10;
			end
			
			nLocStart = 0;
			nLocEnd = 0;
			for i = 1, nColumn do
				nLocStart = nLocEnd;
				nLocEnd = string.find(nRow.results, " ", nLocStart + 1);
			end
			if nColumn == 10 then
				nPotential = string.sub(nRow.results, nLocStart + 1);
			else
				nPotential = string.sub(nRow.results, nLocStart + 1, nLocEnd - 1);
			end
		end
	end
	if nPotential == "-" then
		nPotential = nTemp;
	end
	if nPotential then
		nPotential = tonumber(nPotential);
	else
		nPotential = nTemp;
	end
	return nPotential;
end

function StatGain(nDiff, nRoll)
	if nRoll >= 1 and nRoll <= 4 then
		return nRoll * -2;
	elseif nDiff == 1 then
		if nRoll >= 51 then
			return 1;
		end
	elseif nDiff == 2 then
		if nRoll >= 31 and nRoll <= 65 then
			return 1;
		elseif nRoll >= 66 then
			return 2;
		end
	elseif nDiff == 3 then
		if nRoll >= 26 and nRoll <= 50 then
			return 1;
		elseif nRoll >= 51 and nRoll <= 75 then
			return 2;
		elseif nRoll >= 76 then
			return 3;
		end
	elseif nDiff == 4 or nDiff == 5 then
		if nRoll >= 21 and nRoll <= 40 then
			return 1;
		elseif nRoll >= 41 and nRoll <= 60 then
			return 2;
		elseif nRoll >= 61 and nRoll <= 80 then
			return 3;
		elseif nRoll >= 81 then
			return 4;
		end
	elseif nDiff == 6 or nDiff == 7 then
		if nRoll >= 16 and nRoll <= 25 then
			return 1;
		elseif nRoll >= 26 and nRoll <= 40 then
			return 2;
		elseif nRoll >= 41 and nRoll <= 55 then
			return 3;
		elseif nRoll >= 56 and nRoll <= 70 then
			return 4;
		elseif nRoll >= 71 and nRoll <= 85 then
			return 5;
		elseif nRoll >= 86 then
			return 6;
		end
	elseif nDiff == 8 or nDiff == 9 then
		if nRoll >= 11 and nRoll <= 20 then
			return 1;
		elseif nRoll >= 21 and nRoll <= 35 then
			return 2;
		elseif nRoll >= 36 and nRoll <= 50 then
			return 3;
		elseif nRoll >= 51 and nRoll <= 65 then
			return 4;
		elseif nRoll >= 66 and nRoll <= 75 then
			return 5;
		elseif nRoll >= 76 and nRoll <= 85 then
			return 6;
		elseif nRoll >= 86 and nRoll <= 95 then
			return 7;
		elseif nRoll >= 96 then
			return 8;
		end
	elseif nDiff == 10 or nDiff == 11 then
		if nRoll >= 5 and nRoll <= 15 then
			return 1;
		elseif nRoll >= 16 and nRoll <= 25 then
			return 2;
		elseif nRoll >= 26 and nRoll <= 35 then
			return 3;
		elseif nRoll >= 36 and nRoll <= 45 then
			return 4;
		elseif nRoll >= 46 and nRoll <= 55 then
			return 5;
		elseif nRoll >= 56 and nRoll <= 65 then
			return 6;
		elseif nRoll >= 66 and nRoll <= 75 then
			return 7;
		elseif nRoll >= 76 and nRoll <= 85 then
			return 8;
		elseif nRoll >= 86 and nRoll <= 95 then
			return 9;
		elseif nRoll >= 96 then
			return 10;
		end
	elseif nDiff >= 12 and nDiff <= 14 then
		if nRoll >= 5 and nRoll <= 10 then
			return 1;
		elseif nRoll >= 11 and nRoll <= 15 then
			return 2;
		elseif nRoll >= 16 and nRoll <= 20 then
			return 3;
		elseif nRoll >= 21 and nRoll <= 25 then
			return 4;
		elseif nRoll >= 26 and nRoll <= 35 then
			return 5;
		elseif nRoll >= 36 and nRoll <= 45 then
			return 6;
		elseif nRoll >= 46 and nRoll <= 55 then
			return 7;
		elseif nRoll >= 56 and nRoll <= 65 then
			return 8;
		elseif nRoll >= 66 and nRoll <= 75 then
			return 9;
		elseif nRoll >= 76 and nRoll <= 85 then
			return 10;
		elseif nRoll >= 86 and nRoll <= 95 then
			return 11;
		elseif nRoll >= 96 then
			return 12;
		end
	elseif nDiff >= 15 then
		if nRoll >= 5 and nRoll <= 10 then
			return 1;
		elseif nRoll >= 11 and nRoll <= 15 then
			return 2;
		elseif nRoll >= 16 and nRoll <= 20 then
			return 3;
		elseif nRoll >= 21 and nRoll <= 25 then
			return 4;
		elseif nRoll >= 26 and nRoll <= 30 then
			return 5;
		elseif nRoll >= 31 and nRoll <= 35 then
			return 6;
		elseif nRoll >= 36 and nRoll <= 40 then
			return 7;
		elseif nRoll >= 41 and nRoll <= 45 then
			return 8;
		elseif nRoll >= 46 and nRoll <= 50 then
			return 9;
		elseif nRoll >= 51 and nRoll <= 55 then
			return 10;
		elseif nRoll >= 56 and nRoll <= 65 then
			return 11;
		elseif nRoll >= 66 and nRoll <= 75 then
			return 12;
		elseif nRoll >= 76 and nRoll <= 85 then
			return 13;
		elseif nRoll >= 86 and nRoll <= 95 then
			return 14;
		elseif nRoll >= 96 then
			return 15;
		end
	end
	
	return 0;
end


function StatList(sStats)
	local aNewStatList = {};
	local aStatList = StringManager.split(sStats, "/");
	for _, vStat in ipairs(aStatList) do
		sStatEntry = Rules_Stats.StatEntryFromAbbr(vStat);
		if sStatEntry then
			table.insert(aNewStatList, sStatEntry);
		end  
	end
	return aNewStatList;
end

function StatEntryFromAbbr(sStat)
	local aStatEntry = {};
	sStat = string.lower(sStat);
	
	if sStat == "ag" then
		aStatEntry = {name = "Agility", nodename = "agility", abbr = "Ag" };
	elseif sStat == "co" then
		aStatEntry = {name = "Constitution", nodename = "constitution", abbr = "Co" };
	elseif sStat == "em" then
		aStatEntry = {name = "Empathy", nodename = "empathy", abbr = "Em" };
	elseif sStat == "in" then
		aStatEntry = {name = "Intuition", nodename = "intuition", abbr = "In" };
	elseif sStat == "me" then
		aStatEntry = {name = "Memory", nodename = "memory", abbr = "Me" };
	elseif sStat == "pr" then
		aStatEntry = {name = "Presence", nodename = "presence", abbr = "Pr" };
	elseif sStat == "qu" then
		aStatEntry = {name = "Quickness", nodename = "quickness", abbr = "Qu" };
	elseif sStat == "re" then
		aStatEntry = {name = "Reasoning", nodename = "reasoning", abbr = "Re" };
	elseif sStat == "sd" then
		aStatEntry = {name = "Self Discipline", nodename = "selfdiscipline", abbr = "Sd" };
	elseif sStat == "st" then
		aStatEntry = {name = "Strength", nodename = "strength", abbr = "St" };
	else
		aStatEntry = nil;
	end

	return aStatEntry;
end

-- Stat Bonuses
function Bonus(nStat)
	local sOptRC48B = string.lower(OptionsManager.getOption("RC48B"));
	if sOptRC48B and nStat > 100 then
		return Rules_Stats.VeryHighStatBonus(nStat, sOptRC48B);
	end
	
	local sOptRC44B = string.lower(OptionsManager.getOption("RC44B"));
	if sOptRC44B then
		if sOptRC44B ==  string.lower(Interface.getString("option_val_core")) then
			return Rules_Stats.StandardStatBonus(nStat);
		elseif sOptRC44B ==  string.lower(Interface.getString("option_val_linear")) then
			return Rules_Stats.LinearStatBonus(nStat);
		elseif sOptRC44B ==  string.lower(Interface.getString("option_val_smooth")) then
			return Rules_Stats.SmoothedStatBonus(nStat);
		else 
			return Rules_Stats.StandardStatBonus(nStat);
		end
	else 
		return Rules_Stats.StandardStatBonus(nStat);
	end
end

function StandardStatBonus(nStat)
	if nStat >= 102 then
		return 35;
	elseif nStat >= 101 then
		return 30;
	elseif nStat >= 100 then
		return 25;
	elseif nStat >= 98 then
		return 20;
	elseif nStat >= 95 then
		return 15;
	elseif nStat >= 90 then
		return 10;
	elseif nStat >= 75 then
		return 5;
	elseif nStat >= 25 then
		return 0;
	elseif nStat >= 10 then
		return -5;
	elseif nStat >= 5 then
		return -10;
	elseif nStat >= 3 then
		return -15;
	elseif nStat >= 2 then
		return -20;
	else
		return -25;
	end
end

function LinearStatBonus(nStat)
	return math.floor((nStat - 50) / 2);
end

function SmoothedStatBonus(nStat)
	if nStat >= 102 then
		return 35;
	elseif nStat >= 101 then
		return 30;
	elseif nStat >= 100 then
		return 25;
	elseif nStat >= 99 then
		return 23;
	elseif nStat >= 98 then
		return 21;
	elseif nStat >= 97 then
		return 19;
	elseif nStat >= 96 then
		return 17;
	elseif nStat >= 95 then
		return 15;
	elseif nStat >= 94 then
		return 14;
	elseif nStat >= 93 then
		return 13;
	elseif nStat >= 92 then
		return 12;
	elseif nStat >= 91 then
		return 11;
	elseif nStat >= 90 then
		return 10;
	elseif nStat >= 87 then
		return 9;
	elseif nStat >= 84 then
		return 8;
	elseif nStat >= 81 then
		return 7;
	elseif nStat >= 78 then
		return 6;
	elseif nStat >= 75 then
		return 5;
	elseif nStat >= 72 then
		return 4;
	elseif nStat >= 68 then
		return 3;
	elseif nStat >= 64 then
		return 2;
	elseif nStat >= 60 then
		return 1;
	elseif nStat >= 41 then
		return 0;
	elseif nStat >= 37 then
		return -1;
	elseif nStat >= 33 then
		return -2;
	elseif nStat >= 30 then
		return -3;
	elseif nStat >= 28 then
		return -4;
	elseif nStat >= 25 then
		return -5;
	elseif nStat >= 22 then
		return -6;
	elseif nStat >= 19 then
		return -7;
	elseif nStat >= 16 then
		return -8;
	elseif nStat >= 13 then
		return -9;
	elseif nStat >= 11 then
		return -10;
	elseif nStat >= 10 then
		return -11;
	elseif nStat >= 9 then
		return -12;
	elseif nStat >= 8 then
		return -13;
	elseif nStat >= 7 then
		return -14;
	elseif nStat >= 6 then
		return -15;
	elseif nStat >= 5 then
		return -17;
	elseif nStat >= 4 then
		return -19;
	elseif nStat >= 3 then
		return -21;
	elseif nStat >= 2 then
		return -23;
	else
		return -25;
	end
end

function VeryHighStatBonus(nStat, sOptRC48B)
	if sOptRC48B then
		if sOptRC48B ==  string.lower(Interface.getString("option_val_option1")) then
			if nStat >= 120 then
				return 90 + nStat - 119;
			elseif nStat >= 114 then
				return 80 + ((nStat - 114) * 2);
			elseif nStat >= 109 then
				return 65 + ((nStat - 109) * 3);
			elseif nStat >= 104 then
				return 45 + ((nStat - 104) * 4);
			elseif nStat >= 100 then
				return 25 + ((nStat - 100) * 5);
			end
		elseif sOptRC48B ==  string.lower(Interface.getString("option_val_option2")) then
			return  25 + ((nStat - 100) * 5); 
		end
	end
	
	if nStat >= 102 then
		return 35;
	elseif nStat >= 101 then
		return 30;
	else
		return 25;
	end
end

-- Development Points
function DPs(nStat, nBonus)
	if nBonus and string.lower(OptionsManager.getOption("CL111")) == string.lower(Interface.getString("option_val_on")) then  -- Bonus based DPs Option is On
		local sOptRC48D = string.lower(OptionsManager.getOption("RC48D"));
		if sOptRC48D and nBonus and nBonus > 25 then
			return Rules_Stats.VeryHighStatDPsByBonus(nBonus, sOptRC48D);
		end
		
		local sOptRC44D = string.lower(OptionsManager.getOption("RC44D"));
		if sOptRC44D then
			if sOptRC44D ==  string.lower(Interface.getString("option_val_core"))  then
				return Rules_Stats.StandardDPsByBonus(nBonus, nStat);
			elseif sOptRC44D ==  string.lower(Interface.getString("option_val_linear")) then
				return Rules_Stats.LinearDPsByBonus(nBonus, nStat);
			elseif sOptRC44D ==  string.lower(Interface.getString("option_val_smooth")) then
				return Rules_Stats.SmoothedDPsByBonus(nBonus, nStat);
			else 
				return Rules_Stats.StandardDPsByBonus(nBonus, nStat);
			end
		else 
			return Rules_Stats.StandardDPsByBonus(nBonus, nStat);
		end
	else -- Bonus based DPs Option is Off
		local sOptRC48D = string.lower(OptionsManager.getOption("RC48D"));
		if sOptRC48D and nStat > 100 then
			return Rules_Stats.VeryHighStatDPs(nStat, sOptRC48D);
		end
		
		local sOptRC44D = string.lower(OptionsManager.getOption("RC44D"));
		if sOptRC44D then
			if sOptRC44D ==  string.lower(Interface.getString("option_val_core"))  then
				return Rules_Stats.StandardDPs(nStat);
			elseif sOptRC44D ==  string.lower(Interface.getString("option_val_linear")) then
				return Rules_Stats.LinearDPs(nStat);
			elseif sOptRC44D ==  string.lower(Interface.getString("option_val_smooth")) then
				return Rules_Stats.SmoothedDPs(nStat);
			else 
				return Rules_Stats.StandardDPs(nStat);
			end
		else 
			return Rules_Stats.StandardDPs(nStat);
		end
	end
end

function StandardDPs(nStat)
	if nStat >= 102 then
		return 11;
	elseif nStat >= 100 then
		return 10;
	elseif nStat >= 95 then
		return 9;
	elseif nStat >= 85 then
		return 8;
	elseif nStat >= 75 then
		return 7;
	elseif nStat >= 60 then
		return 6;
	elseif nStat >= 40 then
		return 5;
	elseif nStat >= 25 then
		return 4;
	elseif nStat >= 15 then
		return 3;
	elseif nStat >= 5 then
		return 2;
	else
		return 1;
	end
end

function LinearDPs(nStat)
	return nStat / 10;
end

function SmoothedDPs(nStat)
	if nStat >= 102 then
		return 11.0;
	elseif nStat >= 100 then
		return 10.0;
	elseif nStat >= 99 then
		return 9.8;
	elseif nStat >= 98 then
		return 9.6;
	elseif nStat >= 97 then
		return 9.4;
	elseif nStat >= 96 then
		return 9.2;
	elseif nStat >= 95 then
		return 9.0;
	elseif nStat >= 94 then
		return 8.9;
	elseif nStat >= 93 then
		return 8.8;
	elseif nStat >= 92 then
		return 8.7;
	elseif nStat >= 91 then
		return 8.6;
	elseif nStat >= 90 then
		return 8.4;
	elseif nStat >= 87 then
		return 8.2;
	elseif nStat >= 84 then
		return 8.0;
	elseif nStat >= 81 then
		return 7.7;
	elseif nStat >= 78 then
		return 7.4;
	elseif nStat >= 75 then
		return 7.0;
	elseif nStat >= 72 then
		return 6.8;
	elseif nStat >= 68 then
		return 6.6;
	elseif nStat >= 64 then
		return 6.3;
	elseif nStat >= 60 then
		return 6.0;
	elseif nStat >= 41 then
		return 5.5;
	elseif nStat >= 37 then
		return 5.0;
	elseif nStat >= 33 then
		return 4.8;
	elseif nStat >= 30 then
		return 4.6;
	elseif nStat >= 28 then
		return 4.3;
	elseif nStat >= 25 then
		return 4.0;
	elseif nStat >= 22 then
		return 3.8;
	elseif nStat >= 19 then
		return 3.6;
	elseif nStat >= 16 then
		return 3.3;
	elseif nStat >= 13 then
		return 3.0;
	elseif nStat >= 11 then
		return 2.9;
	elseif nStat >= 10 then
		return 2.8;
	elseif nStat >= 9 then
		return 2.7;
	elseif nStat >= 8 then
		return 2.6;
	elseif nStat >= 7 then
		return 2.4;
	elseif nStat >= 6 then
		return 2.2;
	elseif nStat >= 5 then
		return 2.0;
	elseif nStat >= 4 then
		return 1.8;
	elseif nStat >= 3 then
		return 1.6;
	elseif nStat >= 2 then
		return 1.3;
	else
		return 1.0;
	end
end

function VeryHighStatDPs(nStat, sOptRC48D)
	if sOptRC48D then
		if sOptRC48D ==  string.lower(Interface.getString("option_val_option1")) then
			if nStat >= 115 then
				return 15.0 + ((nStat - 115) * 0.2);
			elseif nStat >= 107 then
				return 13.0 + ((nStat - 107) * 0.25);
			elseif nStat >= 104 then
				return 12.0 + ((nStat - 104) * 0.33);
			elseif nStat >= 100 then
				return 10.0 + ((nStat - 100) * 0.5);
			end
		elseif sOptRC48D ==  string.lower(Interface.getString("option_val_option2")) then
			return  math.floor(10.0 + ((nStat - 100) * 0.5)); 
		end
	end
	
	if nStat >= 102 then
		return 11;
	else
		return 10;
	end
	
end

function StandardDPsByBonus(nBonus, nStat)
	if nBonus >= 35 then
		return 11;
	elseif nBonus >= 25 then
		return 10;
	elseif nBonus >= 15 then
		return 9;
	elseif nBonus >= 5 then
		if nStat >= 85 then
			return 8;
		else
			return 7;
		end
	elseif nBonus >= 0 then
		if nStat >= 60 then
			return 6;
		elseif nStat >= 40 then
			return 5;
		else 
			return 4;
		end
	elseif nBonus >= -5 then
		if nStat >= 15 then
			return 3;
		else
			return 2;
		end
	else
		return 1;
	end
end

function LinearDPsByBonus(nBonus)
	return ((nBonus * 2) + 50) / 10;
end

function SmoothedDPsByBonus(nBonus)
	if nBonus >= 35 then
		return 11.0;
	elseif nBonus >= 25 then
		return 10.0;
	elseif nBonus >= 23 then
		return 9.8;
	elseif nBonus >= 21 then
		return 9.6;
	elseif nBonus >= 19 then
		return 9.4;
	elseif nBonus >= 17 then
		return 9.2;
	elseif nBonus >= 15 then
		return 9.0;
	elseif nBonus >= 14 then
		return 8.9;
	elseif nBonus >= 13 then
		return 8.8;
	elseif nBonus >= 12 then
		return 8.7;
	elseif nBonus >= 11 then
		return 8.6;
	elseif nBonus >= 10 then
		return 8.4;
	elseif nBonus >= 9 then
		return 8.2;
	elseif nBonus >= 8 then
		return 8.0;
	elseif nBonus >= 7 then
		return 7.7;
	elseif nBonus >= 6 then
		return 7.4;
	elseif nBonus >= 5 then
		return 7.0;
	elseif nBonus >= 4 then
		return 6.8;
	elseif nBonus >= 3 then
		return 6.6;
	elseif nBonus >= 2 then
		return 6.3;
	elseif nBonus >= 1 then
		return 6.0;
	elseif nBonus >= 0 then
		return 5.5;
	elseif nBonus >= -1 then
		return 5.0;
	elseif nBonus >= -2 then
		return 4.8;
	elseif nBonus >= -3 then
		return 4.6;
	elseif nBonus >= -4 then
		return 4.3;
	elseif nBonus >= -5 then
		return 4.0;
	elseif nBonus >= -6 then
		return 3.8;
	elseif nBonus >= -7 then
		return 3.6;
	elseif nBonus >= -8 then
		return 3.3;
	elseif nBonus >= -9 then
		return 3.0;
	elseif nBonus >= -10 then
		return 2.9;
	elseif nBonus >= -11 then
		return 2.8;
	elseif nBonus >= -12 then
		return 2.7;
	elseif nBonus >= -13 then
		return 2.6;
	elseif nBonus >= -14 then
		return 2.4;
	elseif nBonus >= -15 then
		return 2.2;
	elseif nBonus >= -17 then
		return 2.0;
	elseif nBonus >= -19 then
		return 1.8;
	elseif nBonus >= -21 then
		return 1.6;
	elseif nBonus >= -23 then
		return 1.3;
	else
		return 1.0;
	end
end

function VeryHighStatDPsByBonus(nBonus, sOptRC48D)
	if sOptRC48D then
		if sOptRC48D ==  string.lower(Interface.getString("option_val_option1")) then
			if nBonus >= 90 then
				return 15.8 + ((nBonus - 90) * 0.2);
			elseif nBonus >= 82 then
				return 15.0 + (math.floor((nBonus - 82) * 0.5) * 0.2);
			elseif nBonus >= 65 then
				return 13.5 + (math.floor((nBonus - 65) / 3) * 0.25);
			elseif nBonus >= 57 then
				return 13.0 + (math.floor((nBonus - 57) / 4) * 0.25);
			elseif nBonus >= 45 then
				return 12.0 + (math.floor((nBonus - 45) / 4) * 0.33);
			elseif nBonus >= 25 then
				return 10.0 + (math.floor((nBonus - 25) / 5) * 0.5);
			end
		elseif sOptRC48D ==  string.lower(Interface.getString("option_val_option2")) then
			return  math.floor(10.0 + (math.floor((nBonus - 25) / 5) * 0.5)); 
		end
	end
	
	if nBonus >= 35 then
		return 11;
	else
		return 10;
	end
	
end


-- Power Points 
function PPMultiplier(nStat)
	local sOptRC48P = string.lower(OptionsManager.getOption("RC48P"));
	if sOptRC48P and nStat > 100 then
		return Rules_Stats.VeryHighStatPPs(nStat, sOptRC48P);
	end
	
	local sOptRC44P = string.lower(OptionsManager.getOption("RC44P"));
	if sOptRC44P then
		if sOptRC44P ==  string.lower(Interface.getString("option_val_core"))  then
			return Rules_Stats.StandardPPMultiplier(nStat);
		elseif sOptRC44P ==  string.lower(Interface.getString("option_val_linear")) then
			return Rules_Stats.LinearPPMultiplier(nStat);
		elseif sOptRC44P ==  string.lower(Interface.getString("option_val_smooth")) then
			return Rules_Stats.SmoothedPPMultiplier(nStat);
		else 
			return Rules_Stats.StandardPPMultiplier(nStat);
		end
	else 
		return Rules_Stats.StandardPPMultiplier(nStat);
	end
end

function StandardPPMultiplier(nStat)
	if nStat >= 102 then
		return 4;
	elseif nStat >= 100 then
		return 3;
	elseif nStat >= 95 then
		return 2;
	elseif nStat >= 75 then
		return 1;
	else
		return 0;
	end
end

function LinearPPMultiplier(nStat)
	local nPP = 0;
	if nStat > 70 then
		nPP = (nStat - 70) / 10;
	end
	return nPP;
end

function SmoothedPPMultiplier(nStat)
	if nStat >= 102 then
		return 4.0;
	elseif nStat >= 100 then
		return 3.0;
	elseif nStat >= 99 then
		return 2.8;
	elseif nStat >= 98 then
		return 2.6;
	elseif nStat >= 97 then
		return 2.4;
	elseif nStat >= 96 then
		return 2.2;
	elseif nStat >= 95 then
		return 2.0;
	elseif nStat >= 94 then
		return 1.9;
	elseif nStat >= 93 then
		return 1.8;
	elseif nStat >= 92 then
		return 1.7;
	elseif nStat >= 91 then
		return 1.6;
	elseif nStat >= 90 then
		return 1.5;
	elseif nStat >= 87 then
		return 1.4;
	elseif nStat >= 84 then
		return 1.3;
	elseif nStat >= 81 then
		return 1.2;
	elseif nStat >= 78 then
		return 1.1;
	elseif nStat >= 75 then
		return 1.0;
	elseif nStat >= 72 then
		return 0.8;
	elseif nStat >= 68 then
		return 0.6;
	elseif nStat >= 64 then
		return 0.4;
	elseif nStat >= 60 then
		return 0.2;
	else
		return 0.0;
	end
end

function StatBonusPPMultiplier(nStatBonus)
	if nStatBonus >= 35 then
		return 4;
	elseif nStatBonus >= 25 then
		return 3;
	elseif nStatBonus >= 15 then
		return 2;
	elseif nStatBonus >= 5 then
		return 1;
	else
		return 0;
	end
end

function VeryHighStatPPs(nStat, sOptRC48P)
	if sOptRC48P then
		if sOptRC48P ==  string.lower(Interface.getString("option_val_option1")) then
			if nStat >= 115 then
				return 8.0 + ((nStat - 115) * 0.2);
			elseif nStat >= 107 then
				return 6.0 + ((nStat - 107) * 0.25);
			elseif nStat >= 104 then
				return 5.0 + ((nStat - 104) * 0.33);
			elseif nStat >= 100 then
				return 3.0 + ((nStat - 100) * 0.5);
			end
		elseif sOptRC48P ==  string.lower(Interface.getString("option_val_option2")) then
			return  math.floor(3.0 + ((nStat - 100) * 0.5)); 
		end
	end

	if nStat >= 102 then
		return 4;
	else
		return 3;
	end
	
end
