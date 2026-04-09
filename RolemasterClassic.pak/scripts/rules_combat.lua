-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

aAddCrit1 = {Code=nil, Name=nil, ResultTable=nil, Severity=nil};
aAddCrit2 = {Code=nil, Name=nil, ResultTable=nil, Severity=nil};
nAddCrit1LevelDiff = 0;
nAddCrit2LevelDiff = 0;

sAltCritTableID = nil;
sAltCritTableName = nil;

nLevelAttacker = -1;
nLevelDefender = -1;
nLevelActor = -1;

nUnmodifiedRoll = -1;
nFumbleValue = -1;
sFumbleTableID = nil;
sFumbleTableColumn = nil;

-- Levels
function SetLevels(aCustomData)
	nLevelAttacker = -1;
	nLevelDefender = -1;
	nLevelActor = -1;

	-- get Attacker Level
	if aCustomData.attackerNodeName then
		nLevelAttacker = Rules_Combat.GetLevel(aCustomData.attackerNodeName);
	end
	
	-- get Defender Level
	if aCustomData.defenderNodeName then
		nLevelDefender = Rules_Combat.GetLevel(aCustomData.defenderNodeName);
	end
	
	-- get Actor Level
	if aCustomData.actorNodeName then
		nLevelActor = Rules_Combat.GetLevel(aCustomData.actorNodeName);
	end
end

function GetLevel(sNodeName)
	local nLevel = -1;
	local nodeMain = DB.findNode(sNodeName);

	if nodeMain then
		nLevel = DB.getValue(nodeMain, "level", -1);
		local sClass, sRecordName = DB.getValue(nodeMain, "link", nil);
		local nodeSource = nodeMain;
		if sClass == "charsheet" then
			nodeSource = DB.findNode(sRecordName);
		end
		if nodeSource and DB.getChild(nodeSource, "level") then
			nLevel = DB.getValue(nodeSource, "level", -1);
		end
	end

	return nLevel;
end

-- Weapon Additional Criticals
function SetAddCrits(aCustomData)
	if aCustomData.attackDBNodeName then
		local nodeAttack = DB.findNode(aCustomData.attackDBNodeName);

		if nodeAttack then
			local sClass, sRecordName = DB.getValue(nodeAttack, "open", nil);
			
			if sRecordName and sRecordName ~= 0 and sRecordName ~= "" then
				nodeAttack = DB.findNode(sRecordName);
			end
		
			-- Add Crit 1 Info
			aAddCrit1 = Rules_Combat.GetAddCrit(DB.getChild(nodeAttack, "addcrit1"));
			nAddCrit1LevelDiff = DB.getValue(nodeAttack, "addcrit1leveldiff", 0);
			
			-- Add Crit 2 Info
			aAddCrit2 = Rules_Combat.GetAddCrit(DB.getChild(nodeAttack, "addcrit2"));
			nAddCrit2LevelDiff = DB.getValue(nodeAttack, "addcrit2leveldiff", 0);
		end
	end
end

function GetAddCrit(nodeAddCrit)
	local aAddCrit = {Code=nil, Name=nil, ResultTable=nil, Severity=nil}; 

	if nodeAddCrit then
		local sTableID = DB.getValue(nodeAddCrit, "tableid", "");
		local sName = DB.getValue(nodeAddCrit, "name", ""); 
		aAddCrit.Name = sName;
		aAddCrit.Code = string.sub(sName, 1, 1);
		aAddCrit.ResultTable = sTableID;
		aAddCrit.Severity = nil;
	end
	
	return aAddCrit;
end

-- Weapon Alternate Criticals
function SetAltCrit(aCustomData)
	if aCustomData.critTableID then
		sAltCritTableID = aCustomData.critTableID;
	else
		sAltCritTableID = nil;
	end
	if aCustomData.critTableName then
		sAltCritTableName = aCustomData.critTableName;
	else
		sAltCritTableName = nil;
	end
end

function GetAltCrit(aAltcrit)
	if sAltCritTableID and sAltCritTableName then
		aAltcrit.ResultTable = sAltCritTableID;
		aAltcrit.Name = sAltCritTableName;
		aAltcrit.Code = string.sub(sAltCritTableName, 1, 1);
	else
		aAltcrit.Name = ""
	end
	return aAltcrit;
end

-- Critical Severities
function GetNewCrit1SevNumber(nOldSevNumber)
	local nSevNumber = nOldSevNumber + nAddCrit1LevelDiff;
	
	if nSevNumber > 5 then
		nSevNumber = 5;
	end

	return nSevNumber;
end

function GetNewCrit2SevNumber(nOldSevNumber)
	local nSevNumber = nOldSevNumber + nAddCrit2LevelDiff;
	
	if nSevNumber > 5 then
		nSevNumber = 5;
	end

	return nSevNumber;
end

function GetNewCrit1Sev(nOldSevNumber)
	return Rules_Combat.GetSev(Rules_Combat.GetNewCrit1SevNumber(nOldSevNumber));
end

function GetNewCrit2Sev(nOldSevNumber)
	return Rules_Combat.GetSev(Rules_Combat.GetNewCrit2SevNumber(nOldSevNumber));
end

function GetSevNumber(sSeverity)
	local nSevNumber = 0;

	if sSeverity then
		if sSeverity == "A" then
			nSevNumber = 1;
		end
		if sSeverity == "B" then
			nSevNumber = 2;
		end
		if sSeverity == "C" then
			nSevNumber = 3;
		end
		if sSeverity == "D" then
			nSevNumber = 4;
		end
		if sSeverity == "E" then
			nSevNumber = 5;
		end
	end

	return nSevNumber;
end

function GetSev(nSevNumber)
	local sSeverity = "";

	if nSevNumber then
		if nSevNumber == 1 then
			sSeverity = "A";
		end
		if nSevNumber == 2 then
			sSeverity = "B";
		end
		if nSevNumber == 3 then
			sSeverity = "C";
		end
		if nSevNumber == 4 then
			sSeverity = "D";
		end
		if nSevNumber >= 5 then
			sSeverity = "E";
		end
	end

	return sSeverity;
end

-- Unmodified Rolls
function SetUnmodifiedRoll(aCustomData)
	-- get Attacker Level
	if aCustomData.unmodifiedRoll then
		nUnmodifiedRoll = aCustomData.unmodifiedRoll
	end
end

-- Fumble
function SetFumble(nNewFumbleValue)
	nFumbleValue = nNewFumbleValue;
end

function GetFumble()
	if nFumbleValue and nFumbleValue > 0 then
		return nFumbleValue;
	else
		nFumbleValue = -1;
		return -1;
	end
end

function SetFumbleTableInfo(aCustomData)
	if aCustomData.attackDBNodeName then
		local nodeAttack = DB.findNode(aCustomData.attackDBNodeName);

		if nodeAttack then
			local sClass, sRecordName = DB.getValue(nodeAttack, "open", nil);
			
			if sRecordName and sRecordName ~= 0 then
				nodeAttack = DB.findNode(sRecordName);
			end
		
			sFumbleTableID = DB.getValue(nodeAttack, "fumbletable.tableid", nil);
			sFumbleTableColumn = DB.getValue(nodeAttack, "fumbletable.column", nil);
		end
	end
end

function GetFumbleTableInfo()
	return sFumbleTableID, sFumbleTableColumn;
end

-- Maximum Level/Size/Rank/Result
function MaxRankSizeList()
	return {"", "Rank 1/Small", "Rank 2/Medium", "Rank 3/Large", "Rank 4/Huge" };
end

function GetMaxResultTotal(nMaxResultLevel)
	if nMaxResultLevel == 1 then
		return 105;
	elseif nMaxResultLevel == 2 then
		return 120;
	elseif nMaxResultLevel == 3 then
		return 135;
	elseif nMaxResultLevel == 4 then
		return 150;
	else
		return 999;
	end
end

function GetMaxRankSize(nMaxLevel)
	if nMaxLevel == 1 then
		return "Rank 1/Small";
	elseif nMaxLevel == 2 then
		return "Rank 2/Medium";
	elseif nMaxLevel == 3 then
		return "Rank 3/Large";
	elseif nMaxLevel == 4 then
		return "Rank 4/Huge";
	else
		return "";
	end
end

function GetMaxLevel(sMaxRankSize)
	if sMaxRankSize == "Rank 1/Small" then
		return 1;
	elseif sMaxRankSize == "Rank 2/Medium" then
		return 2;
	elseif sMaxRankSize == "Rank 3/Large" then
		return 3;
	elseif sMaxRankSize == "Rank 4/Huge" then
		return 4;
	else
		return 0;
	end
end

-- Equipped Information
function HasEquippedShield(nodeCTEntry)
	local bEquippedShield = false;
	local sClass, sNodeName = DB.getValue(nodeCTEntry, "link", "", "");
	
	if sClass == "charsheet" then
		local nodeChar = DB.findNode(sNodeName);
		local sPrimaryHand = DB.getValue(nodeChar, "equipped_primary_hand", ""):lower();
		local sSecondaryHand = DB.getValue(nodeChar, "equipped_secondary_hand", ""):lower();
		-- Check for Shield in Primary or Secondary Hand
		if sPrimaryHand:find("shield") or sSecondaryHand:find("shield") then
			bEquippedShield = true;
		end
	else
		-- Check for Shield in Defences
		for _,nodeDefence in pairs(DB.getChildren(nodeCTEntry, "defences")) do
			if DB.getValue(nodeDefence, "name", ""):lower():find("shield") then
				bEquippedShield = true;
				break;
			end
		end
	end
	
	return bEquippedShield;
end

function HasEquippedMetalShield(nodeCTEntry)
	local bEquippedMetalShield = false;
	local sClass, sNodeName = DB.getValue(nodeCTEntry, "link", "", "");
	
	if sClass == "charsheet" then
		local nodeChar = DB.findNode(sNodeName);
		local sPrimaryHand = DB.getValue(nodeChar, "equipped_primary_hand", ""):lower();
		local sSecondaryHand = DB.getValue(nodeChar, "equipped_secondary_hand", ""):lower();
		-- Check for Metal Shield in Primary or Secondary Hand
		if (Rules_Combat.HasMetalName(sPrimaryHand) and sPrimaryHand:find("shield")) 
				or (Rules_Combat.HasMetalName(sSecondaryHand) and sSecondaryHand:find("shield")) then
			bEquippedMetalShield = true;
		end
	else
		-- Check for Metal Shield in Defences
		for _,nodeDefence in pairs(DB.getChildren(nodeCTEntry, "defences")) do
			local sDefenceName = DB.getValue(nodeDefence, "name", ""):lower();
			if Rules_Combat.HasMetalName(sDefenceName) and sDefenceName:find("shield") then
				bEquippedMetalShield = true;
				break;
			end
		end
	end
	
	return bEquippedMetalShield;
end

function HasMetalName(sName)
	local sNameLower = sName:lower();
	if sNameLower:find("metal") then
		return true;
	elseif sNameLower:find("iron") then
		return true;
	elseif sNameLower:find("steel") then
		return true;
	elseif sNameLower:find("alloy") then
		return true;
	elseif sNameLower:find("adamantine") then
		return true;
	elseif sNameLower:find("eog") then
		return true;
	elseif sNameLower:find("ithloss") then
		return true;
	elseif sNameLower:find("keron") then
		return true;
	elseif sNameLower:find("mithril") then
		return true;
	elseif sNameLower:find("titusinium") then
		return true;
	end
	
	return false; 
end

function HasEquippedCloak(nodeCTEntry)
	local bEquippedCloak = false;
	local sClass, sNodeName = DB.getValue(nodeCTEntry, "link", "", "");
	
	if sClass == "charsheet" then
		local nodeChar = DB.findNode(sNodeName);
		for _,v in pairs(DB.getChildren(nodeChar, "inventorylist")) do
			if DB.getValue(v, "name", ""):find("Cloak") and (DB.getValue(v, "carried", 0) == 2) then  -- 2 = Equipped, 1 = Carried
				bEquippedCloak = true;
				break;
			end			
		end
	end
	
	return bEquippedCloak;
end

function HasProtection(nodeCTEntry, sProtectionLocation, sProtectionType)
	local bProtection = false;
	local sProtectionResult = Rules_ArmorTypes.ProtectionNone;
	local sProtectionNodeName = "";
	local sClass, sNodeName = DB.getValue(nodeCTEntry, "link", "", "");
	
	if sClass == "charsheet" then
		local nodeChar = DB.findNode(sNodeName);
		sProtectionNodeName = "protection." .. string.lower(sProtectionLocation);
		sProtectionResult = DB.getValue(nodeChar, sProtectionNodeName, Rules_ArmorTypes.ProtectionNone);
	elseif DB.getChild(nodeCTEntry, "at") then
		if DB.getValue(nodeCTEntry, "protection.head", "") == "" and 
							DB.getValue(nodeCTEntry, "protection.face", "") == "" and 
							DB.getValue(nodeCTEntry, "protection.neck", "") == "" and 
							DB.getValue(nodeCTEntry, "protection.torso", "") == "" and 
							DB.getValue(nodeCTEntry, "protection.arms", "") == "" and 
							DB.getValue(nodeCTEntry, "protection.legs", "") == "" then 
			local nAT = DB.getValue(nodeCTEntry, "at", 1);
			local aArmor = Rules_ArmorTypes.GetATDetails(nAT);
			if sProtectionLocation == Rules_ArmorTypes.ProtectionHead and aArmor.protectionHead then
				sProtectionResult = aArmor.protectionHead;
			elseif sProtectionLocation == Rules_ArmorTypes.ProtectionFace and aArmor.protectionFace then
				sProtectionResult = aArmor.protectionFace;
			elseif sProtectionLocation == Rules_ArmorTypes.ProtectionNeck and aArmor.protectionNeck then
				sProtectionResult = aArmor.protectionNeck;
			elseif sProtectionLocation == Rules_ArmorTypes.ProtectionTorso and aArmor.protectionTorso then
				sProtectionResult = aArmor.protectionTorso;
			elseif sProtectionLocation == Rules_ArmorTypes.ProtectionArms and aArmor.protectionArms then
				sProtectionResult = aArmor.protectionArms;
			elseif sProtectionLocation == Rules_ArmorTypes.ProtectionLegs and aArmor.protectionLegs then
				sProtectionResult = aArmor.protectionLegs;
			end
		else
			sProtectionNodeName = "protection." .. string.lower(sProtectionLocation);
			sProtectionResult = DB.getValue(nodeCTEntry, sProtectionNodeName, Rules_ArmorTypes.ProtectionNone);
		end
	end

	if sProtectionType and sProtectionType == sProtectionResult then
		bProtection = true;
	elseif not sProtectionType and sProtectionResult ~= Rules_ArmorTypes.ProtectionNone then
		bProtection = true;
	end

	return bProtection;
end

function UseConditionalEffects(woundEffects, nodeTarget)
	local bUseConditionalEffects = false;
	local sTrueCondition = "";
	local sMsgIcon = "roll_effect";

	if woundEffects.TrueCondition then
		sTrueCondition = woundEffects.TrueCondition;
		if sTrueCondition == "Shield" then
			if Rules_Combat.HasEquippedShield(nodeTarget) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_shield_true";
			else
				sMsgIcon = "roll_crit_shield_false";
			end
		elseif sTrueCondition == "Metal Shield" then
			if Rules_Combat.HasEquippedMetalShield(nodeTarget) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_shield_true";
			else
				sMsgIcon = "roll_crit_shield_false";
			end
		elseif sTrueCondition == "Helm" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionHead) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_head_true";
			else
				sMsgIcon = "roll_crit_head_false";
			end
		elseif sTrueCondition == "Leather Helm" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionHead, "Leather") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_head_true";
			else
				sMsgIcon = "roll_crit_head_false";
			end
		elseif sTrueCondition == "Facial Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionFace) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_face_true";
			else
				sMsgIcon = "roll_crit_face_false";
			end
		elseif sTrueCondition == "Neck Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionNeck) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_neck_true";
			else
				sMsgIcon = "roll_crit_neck_false";
			end
		elseif sTrueCondition == "Chest Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Metal Chest Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso, "Metal") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Leather Chest Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso, "Leather") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Abdominal Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Arm Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionArms) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_arms_true";
			else
				sMsgIcon = "roll_crit_arms_false";
			end
		elseif sTrueCondition == "Wrist Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionArms) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_arms_true";
			else
				sMsgIcon = "roll_crit_arms_false";
			end
		elseif sTrueCondition == "Leg Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionLegs) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_legs_true";
			else
				sMsgIcon = "roll_crit_legs_false";
			end
		elseif sTrueCondition == "Hip Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionLegs) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_legs_true";
			else
				sMsgIcon = "roll_crit_legs_false";
			end
		elseif sTrueCondition == "Metal Leg Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionLegs, "Metal") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_legs_true";
			else
				sMsgIcon = "roll_crit_legs_false";
			end
		elseif sTrueCondition == "Leather Leg Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionLegs, "Leather") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_legs_true";
			else
				sMsgIcon = "roll_crit_legs_false";
			end
		elseif sTrueCondition == "Metal Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionHead, "Metal") 
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionFace, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionNeck, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionArms, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionLegs, "Metal") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Metal Armor No Shield" then
			if not Rules_Combat.HasEquippedShield(nodeTarget) and (Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionHead, "Metal") 
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionFace, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionNeck, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionArms, "Metal")
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionLegs, "Metal")) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Metal Arm and Chest Armor" then
			if Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso, "Metal")
						and Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionArms, "Metal") then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		elseif sTrueCondition == "Cloak" then
			if Rules_Combat.HasEquippedCloak(nodeTarget)
						or Rules_Combat.HasProtection(nodeTarget, Rules_ArmorTypes.ProtectionTorso) then
				bUseConditionalEffects = true;
				sMsgIcon = "roll_crit_torso_true";
			else
				sMsgIcon = "roll_crit_torso_false";
			end
		else
			if sTrueCondition ~= "" then
				Debug.console("Warning: Rules_Combat.UseConditionalEffects doesn't handle - " .. sTrueCondition);
			end
		end
	end

	return bUseConditionalEffects, sTrueCondition, sMsgIcon;
end

-- XP
function GetBonusXP(sBonusXPCode, nAttackerLevel)
	local nBonuxXP = 0;
	if sBonusXPCode == "A" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 50;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 40;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 30;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 20;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 10;
		end
	elseif sBonusXPCode == "B" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 75;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 60;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 50;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 40;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 30;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 20;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 10;
		end
	elseif sBonusXPCode == "C" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 100;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 95;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 90;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 85;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 80;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 75;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 70;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 65;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 60;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 55;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 50;
		end
	elseif sBonusXPCode == "D" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 200;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 190;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 180;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 170;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 160;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 150;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 140;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 130;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 120;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 110;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 100;
		end
	elseif sBonusXPCode == "E" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 400;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 380;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 360;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 340;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 320;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 300;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 280;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 260;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 240;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 220;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 210;
		end
	elseif sBonusXPCode == "F" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 800;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 760;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 720;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 680;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 640;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 600;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 560;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 520;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 480;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 440;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 420;
		end
	elseif sBonusXPCode == "G" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 1200;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 1140;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 1080;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 1020;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 960;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 900;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 840;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 780;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 720;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 660;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 600;
		end
	elseif sBonusXPCode == "H" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 1600;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 1520;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 1440;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 1360;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 1280;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 1200;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 1120;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 1040;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 960;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 880;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 800;
		end
	elseif sBonusXPCode == "I" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 2000;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 1900;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 1800;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 1700;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 1600;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 1500;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 1400;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 1300;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 1200;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 1100;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 1000;
		end
	elseif sBonusXPCode == "J" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 3000;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 2850;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 2700;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 2550;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 2400;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 2250;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 2100;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 1950;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 1800;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 1650;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 1500;
		end
	elseif sBonusXPCode == "K" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 4000;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 3800;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 3600;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 3400;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 3200;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 3000;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 2800;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 2600;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 2400;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 2200;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 2000;
		end
	elseif sBonusXPCode == "L" then
		if nAttackerLevel == 1 or nAttackerLevel == 2 then
			nBonuxXP = 5000;
		elseif nAttackerLevel == 3 or nAttackerLevel == 4 then 
			nBonuxXP = 4750;
		elseif nAttackerLevel == 5 or nAttackerLevel == 6 then 
			nBonuxXP = 4500;
		elseif nAttackerLevel == 7 or nAttackerLevel == 8 then 
			nBonuxXP = 4250;
		elseif nAttackerLevel == 9 or nAttackerLevel == 10 then 
			nBonuxXP = 4000;
		elseif nAttackerLevel == 11 or nAttackerLevel == 12 then 
			nBonuxXP = 3750;
		elseif nAttackerLevel == 13 or nAttackerLevel == 14 then 
			nBonuxXP = 3500;
		elseif nAttackerLevel == 15 or nAttackerLevel == 16 then 
			nBonuxXP = 3250;
		elseif nAttackerLevel == 17 or nAttackerLevel == 18 then 
			nBonuxXP = 3000;
		elseif nAttackerLevel == 19 or nAttackerLevel == 20 then 
			nBonuxXP = 2750;
		elseif nAttackerLevel > 20 then 
			nBonuxXP = 2500;
		end
	end
	
	return nBonuxXP;
end

