-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function UpdateToCoreRPG(nodeRecord) 
	-- Migrate old power point fields to CoreRPG pp table
	if DB.getChild(nodeRecord, "ppmax") then
		DB.setValue(nodeRecord, "pp.max", "number", DB.getValue(nodeRecord, "ppmax", 0));
	end
	if DB.getChild(nodeRecord, "ppused") then
		DB.setValue(nodeRecord, "pp.used", "number", DB.getValue(nodeRecord, "ppused", 0));
	end
	if DB.getChild(nodeRecord, "spelladdermax") then
		DB.setValue(nodeRecord, "pp.spelladdermax", "number", DB.getValue(nodeRecord, "spelladdermax", 0));
	end
	if DB.getChild(nodeRecord, "spelladderused") then
		DB.setValue(nodeRecord, "pp.spelladderused", "number", DB.getValue(nodeRecord, "spelladderused", 0));
	end

	-- Change glance to nonid_name field to match CoreRPG
	if DB.getChild(nodeRecord, "glance") then
		DB.setValue(nodeRecord, "nonid_name", "string", DB.getValue(nodeRecord, "glance", ""));
		DB.deleteChild(nodeRecord, "glance");
	end

	-- Update size field to a string field for use with a drop down list
	if DB.getChild(nodeRecord, "size") and DB.getChild(nodeRecord, "size").getType() == "number" then
		nSize = DB.getValue(nodeRecord, "size", 0);
		DB.deleteChild(nodeRecord, "size");
		DB.setValue(nodeRecord, "size", "string", Rules_NPC.GetSizeString(nSize));
	end
	
	-- Update maxpace field to a string field for use with a drop down list
	if DB.getChild(nodeRecord, "maxpace") and DB.getChild(nodeRecord, "maxpace").getType() == "number" then
		nMaxPace = DB.getValue(nodeRecord, "maxpace", 0);
		DB.deleteChild(nodeRecord, "maxpace");
		DB.setValue(nodeRecord, "maxpace", "string", Rules_NPC.GetMaxPaceString(nMaxPace));
	end

	-- Update ms field to a string field for use with a drop down list
	if DB.getChild(nodeRecord, "ms") and DB.getChild(nodeRecord, "ms").getType() == "number" then
		nMovementSpeed = DB.getValue(nodeRecord, "ms", 0);
		DB.deleteChild(nodeRecord, "ms");
		DB.setValue(nodeRecord, "ms", "string", Rules_NPC.GetMSAQString(nMovementSpeed));
	end

	-- Update aq field to a string field for use with a drop down list
	if DB.getChild(nodeRecord, "aq") and DB.getChild(nodeRecord, "aq").getType() == "number" then
		nAttackQuickness = DB.getValue(nodeRecord, "aq", 0);
		DB.deleteChild(nodeRecord, "aq");
		DB.setValue(nodeRecord, "aq", "string", Rules_NPC.GetMSAQString(nAttackQuickness));
	end

	-- Update critmod field to a string field for use with a drop down list
	if DB.getChild(nodeRecord, "critmod") and DB.getChild(nodeRecord, "critmod").getType() == "number" then
		nCritMod = DB.getValue(nodeRecord, "critmod", 0);
		DB.deleteChild(nodeRecord, "critmod");
		DB.setValue(nodeRecord, "critmod", "string", Rules_NPC.GetCritModString(nCritMod));
	end

	-- Update immunity field to a string field for use with a drop down list
	if DB.getChild(nodeRecord, "immunity") and DB.getChild(nodeRecord, "immunity").getType() == "number" then
		nImmunity = DB.getValue(nodeRecord, "immunity", 0);
		DB.deleteChild(nodeRecord, "immunity");
		DB.setValue(nodeRecord, "immunity", "string", Rules_NPC.GetImmunityString(nImmunity));
	end

end

-- Group/Subgroup Functions
function GroupList()
	return { "", "Animals", "Monsters", "NPCs", "Races" };
end

function SubgroupList()
	return { 	
				"", 
				"Birds and Other Flying/Gliding Animals",
				"Carnivorous Mammals",
				"Composite Monsters",
				"Dangerous Plants",
				"Dragons and Other Fell Creatures",
				"Elementals and Artificial Beings",
				"Entities from Other Planes",
				"Fairy Races",
				"Fish and Other Water Creatures",
				"Flying Monsters",
				"Giant Arthropods, Great Serpents, and Water Beasts",
				"Giant Races",
				"Herbivores and Other Normally Unaggressive Animals",
				"Insects, Arachnids, and Crustaceans",
				"Other Potentially Dangerous Animals",
				"Prehistoric Animals",
				"Reptiles and Amphibians",
				"Riding and Draft Animals",
				"Shapechangers",
				"The Undead",
				"Underground Races",
				"Unusual Races",
			};
end

function SubgroupDeathMarkerList()
	local aSubgroupList = SubgroupList();
	local aSubgroupDeathMarkerList = {};

	for k, v in pairs(aSubgroupList) do
		if v ~= "" then
			table.insert(aSubgroupDeathMarkerList, v:lower());
		end
	end

	return aSubgroupDeathMarkerList;
end

-- Races
function SetRace(nodeNPC, nodeRace)
	--[[ Stat modifiers ]]
	if nodeRace then
		for sNodeName, vStatBonus in pairs(DB.getChildren(nodeRace, "statbonuses")) do
			DB.setValue(nodeNPC, "stats." .. sNodeName .. ".race", "number", vStatBonus.getValue());
		end
	end
	
	--[[ RR modifiers ]]
	if nodeRace then
		for sNodeName, vRRBonus in pairs(DB.getChildren(nodeRace, "resistances")) do
			DB.setValue(nodeNPC, "rr.base." .. sNodeName .. ".race", "number", vRRBonus.getValue());
		end
	end
	
	DB.setValue(nodeNPC, "senses", "string", DB.getValue(nodeRace, "senses", ""));
end

function ClearRace(nodeNPC)
	--[[ Stat modifiers ]]
	if nodeNPC then
		for k, vStat in pairs(DB.getChildren(nodeNPC, "stats")) do
			DB.setValue(vStat, "race", "number", 0);
		end
	end
	
	--[[ RR modifiers ]]
	if nodeNPC then
		for k, vRR in pairs(DB.getChildren(nodeNPC, "rr.base")) do
			DB.setValue(vRR, "race", "number", 0);
		end
	end

	DB.setValue(nodeNPC, "senses", "string", "");
end

-- Size Functions
function SizeList()
	return { "", "Tiny", "Small", "Medium", "Large", "Huge" };
end

function GetSizeString(nSize)
	local sSize = "Medium";
	
	if nSize == 1 then
		sSize = "Tiny";
	elseif nSize == 2 then
		sSize = "Small";
	elseif nSize == 3 then
		sSize = "Medium";
	elseif nSize == 4 then
		sSize = "Large";
	elseif nSize == 5 then
		sSize = "Huge";
	end
	
	return sSize;
end

function GetSizeAbbr(sSize)
	local sSizeAbbr = "M";
	
	if sSize == "Tiny" then
		sSizeAbbr = "T";
	elseif sSize == "Small" then
		sSizeAbbr = "S";
	elseif sSize == "Medium" then
		sSizeAbbr = "M";
	elseif sSize == "Large" then
		sSizeAbbr = "L";
	elseif sSize == "Huge" then
		sSizeAbbr = "H";
	end
	
	return sSizeAbbr;
end

function GetSpaceAndReach(sSize)
	local nSpace = 0;
	local nReach = 0;

	if sSize == "Huge" then
		nSpace = 4 * GameSystem.getDistanceUnitsPerGrid();
		nReach = 2 * GameSystem.getDistanceUnitsPerGrid();
	elseif sSize == "Large" then
		nSpace = 2 * GameSystem.getDistanceUnitsPerGrid();
		nReach = 1 * GameSystem.getDistanceUnitsPerGrid();
	elseif sSize ~= "" then
		nSpace = 1 * GameSystem.getDistanceUnitsPerGrid();
		nReach = 1 * GameSystem.getDistanceUnitsPerGrid();
	end

	return nSpace, nReach;
end

-- MaxPace Functions
function MaxPaceList()
	return { "", "Walk", "Jog", "Run", "Sprint", "Fast Sprint", "Dash" };
end

function GetMaxPaceString(nMaxPace)
	local sMaxPace = "";
	
	if nMaxPace == 2 then
		sMaxPace = "Walk";
	elseif nMaxPace == 3 then
		sMaxPace = "Jog";
	elseif nMaxPace == 4 then
		sMaxPace = "Run";
	elseif nMaxPace == 5 then
		sMaxPace = "Sprint";
	elseif nMaxPace == 6 then
		sMaxPace = "Fast Sprint";
	elseif nMaxPace == 7 then
		sMaxPace = "Dash";
	end
	
	return sMaxPace;
end

function GetMaxPaceAbbr(sMaxPace)
	local sMaxPaceAbbr = "-";
	
	if sMaxPace == "Walk" then
		sMaxPaceAbbr = "Walk";
	elseif sMaxPace == "Jog" then
		sMaxPaceAbbr = "Jog";
	elseif sMaxPace == "Run" then
		sMaxPaceAbbr = "Run";
	elseif sMaxPace == "Sprint" then
		sMaxPaceAbbr = "Spr";
	elseif sMaxPace == "Fast Sprint" then
		sMaxPaceAbbr = "FSpr";
	elseif sMaxPace == "Dash" then
		sMaxPaceAbbr = "Dash";
	end
	
	return sMaxPaceAbbr;
end

-- MS/AQ Functions
function MSAQList()
	return { "", "Inching (IN)", "Creeping (CR)", "Very Slow (VS)", "Slow (SL)", "Medium (MD)", "Moderately Fast (MF)", "Fast (FA)", "Very Fast (VF)", "Blindingly Fast (BF)" };
end

function GetMSAQString(nMSAQ)
	local sMSAQ = "";
	
	if nMSAQ == 2 then
		sMSAQ = "Inching (IN)";
	elseif nMSAQ == 3 then
		sMSAQ = "Creeping (CR)";
	elseif nMSAQ == 4 then
		sMSAQ = "Very Slow (VS)";
	elseif nMSAQ == 5 then
		sMSAQ = "Slow (SL)";
	elseif nMSAQ == 6 then
		sMSAQ = "Medium (MD)";
	elseif nMSAQ == 7 then
		sMSAQ = "Moderately Fast (MF)";
	elseif nMSAQ == 8 then
		sMSAQ = "Fast (FA)";
	elseif nMSAQ == 9 then
		sMSAQ = "Very Fast (VF)";
	elseif nMSAQ == 10 then
		sMSAQ = "Blindingly Fast (BF)";
	end
	
	return sMSAQ;
end

function GetInitMod(sAttackQuickness)
	local nAttackQuickness = 0;
	
	if sAttackQuickness == "Inching (IN)" then
		nAttackQuickness = -25;
	elseif sAttackQuickness == "Creeping (CR)" then
		nAttackQuickness = -20;
	elseif sAttackQuickness == "Very Slow (VS)" then
		nAttackQuickness = -10;
	elseif sAttackQuickness == "Slow (SL)" then
		nAttackQuickness = 0;
	elseif sAttackQuickness == "Medium (MD)" then
		nAttackQuickness = 10;
	elseif sAttackQuickness == "Moderately Fast (MF)" then
		nAttackQuickness = 20;
	elseif sAttackQuickness == "Fast (FA)" then
		nAttackQuickness = 30;
	elseif sAttackQuickness == "Very Fast (VF)" then
		nAttackQuickness = 40;
	elseif sAttackQuickness == "Blindingly Fast (BF)" then
		nAttackQuickness = 50;
	end
	
	return nAttackQuickness;
end

function GetMSAQAbbr(sMSAQ)
	local sMSAQAbbr = "-";
	
	if sMSAQ == "Inching (IN)" then
		sMSAQAbbr = "IN";
	elseif sMSAQ == "Creeping (CR)" then
		sMSAQAbbr = "CR";
	elseif sMSAQ == "Very Slow (VS)" then
		sMSAQAbbr = "VS";
	elseif sMSAQ == "Slow (SL)" then
		sMSAQAbbr = "SL";
	elseif sMSAQ == "Medium (MD)" then
		sMSAQAbbr = "MD";
	elseif sMSAQ == "Moderately Fast (MF)" then
		sMSAQAbbr = "MF";
	elseif sMSAQ == "Fast (FA)" then
		sMSAQAbbr = "FA";
	elseif sMSAQ == "Very Fast (VF)" then
		sMSAQAbbr = "VF";
	elseif sMSAQ == "Blindingly Fast (BF)" then
		sMSAQAbbr = "BF";
	end
	
	return sMSAQAbbr;
end

-- CritMod Functions
function CritModList()
	return { "", "-1 severity (I)", "-2 severities (II)", "Large (L)", "Super-Large (SL)" };
end

function GetCritModString(nCritMod)
	local sCritMod = "";
	
	if nCritMod == 2 then
		sCritMod = "-1 severity (I)";
	elseif nCritMod == 3 then
		sCritMod = "-2 severities (II)";
	elseif nCritMod == 4 then
		sCritMod = "Large (L)";
	elseif nCritMod == 5 then
		sCritMod = "Super-Large (SL)";
	end
	
	return sCritMod;
end

function GetCritModAbbr(sCritMod)
	local sCritModAbbr = "-";
	
	if sCritMod == "-1 severity (I)" then
		sCritModAbbr = "I";
	elseif sCritMod == "-2 severities (II)" then
		sCritModAbbr = "II";
	elseif sCritMod == "Large (L)" then
		sCritModAbbr = "L";
	elseif sCritMod == "Super-Large (SL)" then
		sCritModAbbr = "SL";
	end
	
	return sCritModAbbr;
end

function AdjustCritical(nodeNPC, aCritical, sAttackType, sLargeColumnName, aCritTableList, sOriginalSeverity)
	if not nodeNPC then
		return aCritical, aCritTableList;
	end

	local sCritMod = DB.getValue(nodeNPC, "critmod", "");
	local sCritSeverity = aCritical.Severity;

	if sCritMod == "Super-Large (SL)" then
		if sCritSeverity >= "D" then
			aCritical.Code = "SL";
			aCritical.Name = "Super-Large";
			aCritical.Severity = sLargeColumnName;
			if sAttackType == "Spell" then
				-- Spells
				aCritical.ResultTable = "SCT-06";
				if sLargeColumnName ~= "Slaying" then
					aCritical.Severity = "Normal";
				end
			else
				-- Arms
				aCritical.ResultTable = "CT-10";
			end
			aCritTableList = {};
			table.insert(aCritTableList, aCritical);
		else
			Comm.deliverChatMessage({icon="icon_info", font="systemfont", text="NOTE: There is no critical because Super-Large criticals require a minimum severity of 'D'.", secret=true});
			aCritical = nil;
		end
	elseif sCritMod == "Large (L)" then
		if sCritSeverity >= "B" then
			aCritical.Code = "L";
			aCritical.Name = "Large";
			aCritical.Severity = sLargeColumnName;
			if sAttackType == "Spell" then
				-- Spells
				aCritical.ResultTable = "SCT-05";
				if sLargeColumnName ~= "Slaying" then
					aCritical.Severity = "Normal";
				end
			else
				-- Arms
				aCritical.ResultTable = "CT-09";
			end
			aCritTableList = {};
			table.insert(aCritTableList, aCritical);
		else
			Comm.deliverChatMessage({icon="icon_info", font="systemfont", text="NOTE: There is no critical because Large criticals require a minimum severity of 'B'.", secret=true});
			aCritical = nil;
		end
	elseif sCritMod == "-2 severities (II)" then
		aCritical, aCritTableList = ReduceCritical(aCritical, -2, aCritTableList, sOriginalSeverity);
	elseif sCritMod == "-1 severity (I)" then
		aCritical, aCritTableList = ReduceCritical(aCritical, -1, aCritTableList, sOriginalSeverity);
	end
	
	return aCritical, aCritTableList;
end

function ReduceCritical(aCritical, nReduction, aCritTableList, sOriginalSeverity)
	local nCritSeverity = string.byte(aCritical.Severity);
	
	if nCritSeverity then
		nCritSeverity = nCritSeverity + nReduction;
		if nCritSeverity < 65 then
			aCritical.Severity = "A";
			if nCritSeverity == 64 then
				aCritical.Modifier = -20;
			else
				aCritical.Modifier = -50;
			end
		elseif sOriginalSeverity and sOriginalSeverity > "E" then 
			nCritSeverity = string.byte(sOriginalSeverity) + nReduction;
			local sNewSeverity = string.char(nCritSeverity);
			if sNewSeverity <= "E" then
				aCritTableList[2] = nil;
				aCritTableList[3] = nil;
			else
				if sNewSeverity == "F" then
					aCritTableList[2].Severity = "A";
					aCritTableList[3] = nil;
				elseif sNewSeverity == "G" then
					aCritTableList[2].Severity = "B";
					aCritTableList[3] = nil;
				elseif sNewSeverity == "H" then
					aCritTableList[2].Severity = "C";
					aCritTableList[3].Severity = "A";
				elseif sNewSeverity == "I" then
					aCritTableList[2].Severity = "D";
					aCritTableList[3].Severity = "B";
				elseif sNewSeverity == "J" then
					aCritTableList[2].Severity = "D";
					aCritTableList[3].Severity = "C";
				end
				sNewSeverity = "E";
			end
			aCritical.Severity = sNewSeverity;
		else
			aCritical.Severity = string.char(nCritSeverity);
		end
	end

	return aCritical, aCritTableList;
end

-- Immunity Functions
function ImmunityList()
	return { "", "Stun (@)", "Stun and Hits/rd (#)" };
end

function GetImmunityString(nImmunity)
	local sImmunity = "";
	
	if nImmunity == 2 then
		sImmunity = "Stun (@)";
	elseif nImmunity == 3 then
		sImmunity = "Stun and Hits/rd (#)";
	end
	
	return sImmunity;
end

-- IQ Functions
function IQList()
	return { "", "None (animal instincts)", "Very Low (1-5)", "Low (3-12)", "Little (7-25)", "Inferior (13-40)", "Mediocre (23-50)", "Average (36-65)", "Above Average (50-77)", "Superior (60-86)", "High (80-98)", "Very High (94-99)", "Exceptional (100-102)" };
end

function GetIQString(nIQ)
	local sIQ = "";
	
	if nIQ == 2 then
		sIQ = "None (animal instincts)";
	elseif nIQ == 3 then
		sIQ = "Very Low (1-5)";
	elseif nIQ == 4 then
		sIQ = "Low (3-12)";
	elseif nIQ == 5 then
		sIQ = "Little (7-25)";
	elseif nIQ == 6 then
		sIQ = "Inferior (13-40)";
	elseif nIQ == 7 then
		sIQ = "Mediocre (23-50)";
	elseif nIQ == 8 then
		sIQ = "Average (36-65)";
	elseif nIQ == 9 then
		sIQ = "Above Average (50-77)";
	elseif nIQ == 10 then
		sIQ = "Superior (60-86)";
	elseif nIQ == 11 then
		sIQ = "High (80-98)";
	elseif nIQ == 12 then
		sIQ = "Very High (94-99)";
	elseif nIQ == 13 then
		sIQ = "Exceptional (100-102)";
	end
	
	return sIQ;
end

-- Outlook Functions
function OutlookList()
	return { "", "Aggressive", "Aloof", "Altruistic", "Belligerent", "Berserk", "Carefree", "Cruel", "Dominate", "Good", "Greedy", "Hostile", "Hungry", "Inquisitive", "Jumpy", "Normal", "Passive", "Playful", "Protect", "Timid", "Varies" };
end

function GetOutlookString(nOutlook)
	local sOutlook = "";
	
	if nOutlook == 2 then
		sOutlook = "Aggressive";
	elseif nOutlook == 3 then
		sOutlook = "Aloof";
	elseif nOutlook == 4 then
		sOutlook = "Altruistic";
	elseif nOutlook == 5 then
		sOutlook = "Belligerent";
	elseif nOutlook == 6 then
		sOutlook = "Berserk";
	elseif nOutlook == 7 then
		sOutlook = "Carefree";
	elseif nOutlook == 8 then
		sOutlook = "Cruel";
	elseif nOutlook == 9 then
		sOutlook = "Dominate";
	elseif nOutlook == 10 then
		sOutlook = "Good";
	elseif nOutlook == 11 then
		sOutlook = "Greedy";
	elseif nOutlook == 12 then
		sOutlook = "Hostile";
	elseif nOutlook == 13 then
		sOutlook = "Hungry";
	elseif nOutlook == 14 then
		sOutlook = "Inquisitive";
	elseif nOutlook == 15 then
		sOutlook = "Jumpy";
	elseif nOutlook == 16 then
		sOutlook = "Normal";
	elseif nOutlook == 17 then
		sOutlook = "Passive";
	elseif nOutlook == 18 then
		sOutlook = "Playful";
	elseif nOutlook == 19 then
		sOutlook = "Protect";
	elseif nOutlook == 20 then
		sOutlook = "Timid";
	elseif nOutlook == 21 then
		sOutlook = "Varies";
	end
	
	return sOutlook;
end

function GetOutlookDescription(sOutlook)
	local sDescription = "";
	
	if sOutlook == "Aggressive"then
		sDescription = "Aggressive and will attack if provoked or hungry.";
	elseif sOutlook == "Aloof" then
		sDescription = "Ignores other creatures unless interfered with or attack.";
	elseif sOutlook == "Altruistic" then
		sDescription = "Altruistic, has an unselfish regard for the interests of others, often to the extent of risking his own safety.";
	elseif sOutlook == "Belligerent" then
		sDescription = "Belligerent, often attacks without provocation.";
	elseif sOutlook == "Berserk" then
		sDescription = "Attacks cloest living creature until it is destroyed.";
	elseif sOutlook == "Carefree" then
		sDescription = "Does not believe that danger or misfortune exists for it.";
	elseif sOutlook == "Cruel" then
		sDescription = "Not only hostile, but delights in death, pain, and suffering.";
	elseif sOutlook == "Dominate" then
		sDescription = "Desires power, attempts to control or dominate other creatures.";
	elseif sOutlook == "Good" then
		sDescription = "Opposed to 'evil' (e.g., those who are cruel, hostile, belligerent, etc.); supportive of those who are 'good'.";
	elseif sOutlook == "Greedy" then
		sDescription = "Will attack or attempt to steal from other creatures if the risk does not seem too high.";
	elseif sOutlook == "Hostile" then
		sDescription = "Normally attacks other creatures on sight.";
	elseif sOutlook == "Hungry" then
		sDescription = "If hungry, will attack anything edible; otherwise Normal.";
	elseif sOutlook == "Inquisitive" then
		sDescription = "Inquisitive/Curious will approach and examine unusual situations.";
	elseif sOutlook == "Jumpy" then
		sDescription = "Normally bolts at any sign of other creatures.";
	elseif sOutlook == "Normal" then
		sDescription = "Watches and is wary of other creatures, will sometimes attack if hungry.";
	elseif sOutlook == "Passive" then
		sDescription = "Ignores the presence of other creatures unless threatened.";
	elseif sOutlook == "Playful" then
		sDescription = "Mischievous/Playful, will attempt to play with or play pranks on other creatures.";
	elseif sOutlook == "Protect" then
		sDescription = "Protective of a thing, place, other creature, etc.";
	elseif sOutlook == "Timid" then
		sDescription = "Skittish around other creatures, runs at the slightest hint of danger.";
	elseif sOutlook == "Varies" then
		sDescription = "Varies";
	end

	return sDescription;
end

-- Level/Constitution Functions
function UpdateRandomHitsAndLevel(nodeNPC)
	local nLevel = DB.getValue(nodeNPC, "level", 0);
	local sLevelCode = DB.getValue(nodeNPC, "levelcode", "");
	local nHits = DB.getValue(nodeNPC, "hits", 0);
	local sHitsCode = DB.getValue(nodeNPC, "hitscode", "");
	local nHitsRoll = math.random(100);
	local nLevelRoll = math.random(100);
	if nLevelRoll >= 96 then
		local nNextRoll = math.random(100);
		while nNextRoll >= 96 do
			nLevelRoll = nLevelRoll + nNextRoll;
			nNextRoll = math.random(100);
		end
		nLevelRoll = nLevelRoll + nNextRoll;
	elseif nLevelRoll <= 5 then
		local nNextRoll = math.random(100);
		while nNextRoll >= 96 do
			nLevelRoll = nLevelRoll - nNextRoll;
			nNextRoll = math.random(100);
		end
		nLevelRoll = nLevelRoll - nNextRoll;
	end
	
	-- Level
	local nLevelDiff = Rules_NPC.GetLevelDiff(nLevelRoll, sLevelCode);
	-- Change the nLevelDiff so it will reduce the level only to zero and not below it
	if nLevel + nLevelDiff < 0 then
		nLevelDiff = -1 * nLevel;
	end
	DB.setValue(nodeNPC, "level", "number", nLevel + nLevelDiff);

	-- Exhaustion
	local nConstitutionBonus = GetConstitutionBonus(nHitsRoll, sHitsCode);
	local nExhaustionMisc = nConstitutionBonus + Rules_NPC.BonusExhaustion(sHitsCode);
	DB.setValue(nodeNPC, "exhaustionmisc", "number", nExhaustionMisc);
	DB.setValue(nodeNPC, "exhaustionmax", "number", nHitsRoll + nExhaustionMisc);
	
	-- Hits
	local nNewHits = nHits + ((nConstitutionBonus / 100) * nHits) + (nLevelDiff * HitsPerLevelDiff(sHitsCode));
	nNewHits =  math.floor(nNewHits + 0.5);
	if nNewHits < 0 then
		nNewHits = 1;
	end
	if nNewHits ~= nHits then
		DB.setValue(nodeNPC, "hits", "number", nNewHits);
	end
	
	-- Constitution
	if DB.getValue(nodeNPC, "stats.constitution.temp", 0) == 0 then
		DB.setValue(nodeNPC, "stats.constitution.temp", "number", nHitsRoll);
	end
	
	-- Offensive Bonus
	if nodeNPC then
		local nOBChange = nLevelDiff * 3;
		for _, vAttack in pairs(DB.getChildren(nodeNPC, "weapons")) do
			local nOB = DB.getValue(vAttack, "ob", 0) + nOBChange;
			if nOB < 0 then
				nOB = 0;
			end
			DB.setValue(vAttack, "ob", "number", nOB);
		end
	end
end

function GetConstitutionBonus(nHitsRoll, sHitsCode)
	local nConstitutionBonus = 0;
	
	if sHitsCode == "A" then
		if nHitsRoll == 1 then nConstitutionBonus = -15; 
		elseif nHitsRoll <= 9 then nConstitutionBonus = -10; 
		elseif nHitsRoll <= 25 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 74 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 91 then nConstitutionBonus = 5; 
		elseif nHitsRoll <= 99 then nConstitutionBonus = 10; 
		else nConstitutionBonus = 15;
		end
	elseif sHitsCode == "B" then
		if nHitsRoll == 1 then nConstitutionBonus = -20; 
		elseif nHitsRoll <= 4 then nConstitutionBonus = -15; 
		elseif nHitsRoll <= 11 then nConstitutionBonus = -10; 
		elseif nHitsRoll <= 31 then nConstitutionBonus = -5;
		elseif nHitsRoll <= 69 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 89 then nConstitutionBonus = 5; 
		elseif nHitsRoll <= 96 then nConstitutionBonus = 10; 
		elseif nHitsRoll <= 99 then nConstitutionBonus = 15; 
		else nConstitutionBonus = 20; 
		end
	elseif sHitsCode == "C" then
		if nHitsRoll == 1 then nConstitutionBonus = -25; 
		elseif nHitsRoll <= 3 then nConstitutionBonus = -20; 
		elseif nHitsRoll <= 8 then nConstitutionBonus = -15; 
		elseif nHitsRoll <= 23 then nConstitutionBonus = -10;
		elseif nHitsRoll <= 74 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 89 then nConstitutionBonus = 0;
		elseif nHitsRoll <= 94 then nConstitutionBonus = 5;
		elseif nHitsRoll <= 97 then nConstitutionBonus = 10; 
		elseif nHitsRoll <= 99 then nConstitutionBonus = 15; 
		else nConstitutionBonus = 20; 
		end
	elseif sHitsCode == "D" then
		if nHitsRoll == 1 then nConstitutionBonus = -25; 
		elseif nHitsRoll == 2 then nConstitutionBonus = -20; 
		elseif nHitsRoll <= 4 then nConstitutionBonus = -15; 
		elseif nHitsRoll <= 9 then nConstitutionBonus = -10;
		elseif nHitsRoll <= 24 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 74 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 89 then nConstitutionBonus = 5;
		elseif nHitsRoll <= 94 then nConstitutionBonus = 10; 
		elseif nHitsRoll <= 97 then nConstitutionBonus = 15; 
		elseif nHitsRoll <= 99 then nConstitutionBonus = 20; 
		else nConstitutionBonus = 25; 
		end
	elseif sHitsCode == "E" then
		if nHitsRoll == 1 then nConstitutionBonus = -25; 
		elseif nHitsRoll == 2 then nConstitutionBonus = -20; 
		elseif nHitsRoll <= 4 then nConstitutionBonus = -15; 
		elseif nHitsRoll <= 9 then nConstitutionBonus = -10;
		elseif nHitsRoll <= 24 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 72 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 87 then nConstitutionBonus = 5; 
		elseif nHitsRoll <= 92 then nConstitutionBonus = 10;
		elseif nHitsRoll <= 95 then nConstitutionBonus = 15; 
		elseif nHitsRoll <= 97 then nConstitutionBonus = 20; 
		elseif nHitsRoll == 98 then nConstitutionBonus = 25; 
		elseif nHitsRoll == 99 then nConstitutionBonus = 30; 
		else nConstitutionBonus = 35; 
		end
	elseif sHitsCode == "F" then
		if nHitsRoll == 1 then nConstitutionBonus = -25; 
		elseif nHitsRoll == 2 then nConstitutionBonus = -20; 
		elseif nHitsRoll == 3 then nConstitutionBonus = -15; 
		elseif nHitsRoll <= 5 then nConstitutionBonus = -10;
		elseif nHitsRoll <= 10 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 25 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 72 then nConstitutionBonus = 5; 
		elseif nHitsRoll <= 87 then nConstitutionBonus = 10;
		elseif nHitsRoll <= 92 then nConstitutionBonus = 10; 
		elseif nHitsRoll <= 95 then nConstitutionBonus = 20; 
		elseif nHitsRoll <= 97 then nConstitutionBonus = 25;
		elseif nHitsRoll == 98 then nConstitutionBonus = 30; 
		elseif nHitsRoll == 99 then nConstitutionBonus = 35; 
		else nConstitutionBonus = 45; 
		end
	elseif sHitsCode == "G" then
		if nHitsRoll == 1 then nConstitutionBonus = -25; 
		elseif nHitsRoll == 2 then nConstitutionBonus = -20; 
		elseif nHitsRoll == 3 then nConstitutionBonus = -15; 
		elseif nHitsRoll == 4 then nConstitutionBonus = -10;
		elseif nHitsRoll <= 6 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 11 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 26 then nConstitutionBonus = 5; 
		elseif nHitsRoll <= 71 then nConstitutionBonus = 10;
		elseif nHitsRoll <= 86 then nConstitutionBonus = 15; 
		elseif nHitsRoll <= 91 then nConstitutionBonus = 20; 
		elseif nHitsRoll <= 94 then nConstitutionBonus = 25; 
		elseif nHitsRoll <= 96 then nConstitutionBonus = 30;
		elseif nHitsRoll <= 98 then nConstitutionBonus = 35; 
		elseif nHitsRoll == 99 then nConstitutionBonus = 45; 
		else nConstitutionBonus = 60; 
		end
	elseif sHitsCode == "H" then
		if nHitsRoll == 1 then nConstitutionBonus = -25; 
		elseif nHitsRoll == 2 then nConstitutionBonus = -20;
		elseif nHitsRoll == 3 then nConstitutionBonus = -15; 
		elseif nHitsRoll == 4 then nConstitutionBonus = -10;
		elseif nHitsRoll == 5 then nConstitutionBonus = -5; 
		elseif nHitsRoll <= 7 then nConstitutionBonus = 0; 
		elseif nHitsRoll <= 12 then nConstitutionBonus = 5; 
		elseif nHitsRoll <= 27 then nConstitutionBonus = 10;
		elseif nHitsRoll <= 72 then nConstitutionBonus = 15; 
		elseif nHitsRoll <= 88 then nConstitutionBonus = 20; 
		elseif nHitsRoll <= 93 then nConstitutionBonus = 25; 
		elseif nHitsRoll <= 96 then nConstitutionBonus = 30;
		elseif nHitsRoll <= 98 then nConstitutionBonus = 35; 
		elseif nHitsRoll == 99 then nConstitutionBonus = 45; 
		else nConstitutionBonus = 60; 
		end
	end
	
	return nConstitutionBonus;
end

function GetLevelDiff(nLevelRoll, sLevelCode)
	local nRow = 21;
	if nLevelRoll <= 1 then nRow = 1;
	elseif nLevelRoll<=10 then nRow = 2; 
	elseif nLevelRoll<=15 then nRow = 3; 
	elseif nLevelRoll<=20 then nRow = 4;
	elseif nLevelRoll<=25 then nRow = 5;
	elseif nLevelRoll<=35 then nRow = 6;
	elseif nLevelRoll<=45 then nRow = 7;
	elseif nLevelRoll<=55 then nRow = 8;
	elseif nLevelRoll<=65 then nRow = 9;
	elseif nLevelRoll<=75 then nRow = 10;
	elseif nLevelRoll<=80 then nRow = 11;
	elseif nLevelRoll<=85 then nRow = 12;
	elseif nLevelRoll<=90 then nRow = 13;
	elseif nLevelRoll<=100 then nRow = 14;
	elseif nLevelRoll<=140 then nRow = 15;
	elseif nLevelRoll<=170 then nRow = 16;
	elseif nLevelRoll<=190 then nRow = 17;
	elseif nLevelRoll<=200 then nRow = 18;
	elseif nLevelRoll<=250 then nRow = 19;
	elseif nLevelRoll<=300 then nRow = 20;
	end
	
	local A = {-99,-1,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,2,3,4};
	local B = {-99,-2,-1,0,0,0,0,0,0,0,0,0,1,1,1,2,2,3,4,5,6};
	local C = {-99,-3,-2,-1,0,0,0,0,0,0,0,1,1,2,2,3,4,5,6,7,8};
	local D = {-99,-4,-3,-2,-1,0,0,0,0,0,1,2,3,4,5,6,7,8,9,10,11};
	local E = {-99,-5,-4,-3,-2,-1,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12};
	local F = {-99,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13};
	local G = {-99,-10,-8,-6,-4,-2,-1,0,1,2,4,6,8,10,11,12,13,14,15,16,17};
	local H = {-3,-2,-2,-1,-1,-1,0,0,0,1,1,1,2,2,3,3,3,3,3,4,4};
	
	local nLevelDiff = 0;
	if sLevelCode == "A" then nLevelDiff = A[nRow]; 
	elseif sLevelCode == "B" then nLevelDiff = B[nRow];
	elseif sLevelCode == "C" then nLevelDiff = C[nRow];
	elseif sLevelCode == "D" then nLevelDiff = D[nRow];
	elseif sLevelCode == "E" then nLevelDiff = E[nRow];
	elseif sLevelCode == "F" then nLevelDiff = F[nRow];
	elseif sLevelCode == "G" then nLevelDiff = G[nRow];
	elseif sLevelCode == "H" then nLevelDiff = H[nRow];
	end

	return nLevelDiff;
end

function HitsPerLevelDiff(sHitsCode)
	if sHitsCode == "A" then
		return 1;
	elseif sHitsCode == "B" then
		return 2;
	elseif sHitsCode == "C" then
		return 3;
	elseif sHitsCode == "D" then
		return 5;
	elseif sHitsCode == "E" then
		return 8;
	elseif sHitsCode == "F" then
		return 10;
	elseif sHitsCode == "G" then
		return 12;
	elseif sHitsCode == "H" then
		return 15;
	else 
		return 0;
	end
end

function BonusExhaustion(sHitsCode)
	if sHitsCode == "E" then
		return 50;
	elseif sHitsCode == "F" then
		return 100;
	elseif sHitsCode == "G" then
		return 150;
	elseif sHitsCode == "H" then
		return 200;
	else 
		return 0;
	end
end

