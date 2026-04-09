-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_CTUPDATEOWNERS = "ctupdateowners";

function onInit()
	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_CTUPDATEOWNERS, handleCTUpdateOwners);
	end

	CombatManager.setCustomSort(onSort);
	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomTurnEnd(onTurnEnd);

	ActorCommonManager.setRecordTypeSpaceReachCallback("npc", getSpaceReachRMC);
	if Session.IsHost then
		CombatRecordManager.setRecordTypePostAddCallback("charsheet", onPCPostAdd);
		CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
	end
end

--
-- SORT FUNCTIONS
--

function onSort(node1, node2)
	local bHost = Session.IsHost;
	local sOptCTSI = OptionsManager.getOption("CTSI");
	
	local sFaction1 = DB.getValue(node1, "friendfoe", "");
	local sFaction2 = DB.getValue(node2, "friendfoe", "");
	
	local bShowInit1 = bHost or ((sOptCTSI == "friend") and (sFaction1 == "friend")) or (sOptCTSI == "on");
	local bShowInit2 = bHost or ((sOptCTSI == "friend") and (sFaction2 == "friend")) or (sOptCTSI == "on");
	
	if bShowInit1 ~= bShowInit2 then
		if bShowInit1 then
			return true;
		elseif bShowInit2 then
			return false;
		end
	else
		if bShowInit1 then
			local initResult1 = DB.getValue(node1, "initresult", 0);
			local initResult2 = DB.getValue(node2, "initresult", 0);
			if initResult1 ~= initResult2 then
				return initResult1 > initResult2;
			end

			local quicknessBonus1 = DB.getValue(node1, "quicknessBonus", 0);
			local quicknessBonus2 = DB.getValue(node2, "quicknessBonus", 0);
			if quicknessBonus1 ~= quicknessBonus2 then
				return quicknessBonus1 > quicknessBonus2;
			end

			local quicknessStat1 = DB.getValue(node1, "quicknessStat", 0);
			local quicknessStat2 = DB.getValue(node2, "quicknessStat", 0);
			if quicknessStat1 ~= quicknessStat2 then
				return quicknessStat1 > quicknessStat2;
			end
		else
			if sFaction1 ~= sFaction2 then
				if sFaction1 == "friend" then
					return true;
				elseif sFaction2 == "friend" then
					return false;
				end
			end
		end
	end
	
	local sValue1 = DB.getValue(node1, "name", "");
	local sValue2 = DB.getValue(node2, "name", "");
	if sValue1 ~= sValue2 then
		return sValue1 < sValue2;
	end

	return DB.getPath(node1) < DB.getPath(node2);
end

-- NOTE: This sort function does not match same ordering behavior as previous one, since it's called directly
function onSortCompareAttackDefense(bPC, w1, w2)
	local node1 = w1.getDatabaseNode();
	local sName1;
	if node1 then
		if not PC or (DB.getValue(node1, "isidentified", 1) == 1) then
			sName1 = DB.getValue(node1, "name", "");
		else
			sName1 = DB.getValue(node1, "nonid_name", "");
		end
	end
	local node2 = w2.getDatabaseNode();
	local sName2;
	if node2 then
		if not PC or (DB.getValue(node2, "isidentified", 1) == 1) then
			sName2 = DB.getValue(node2, "name", "");
		else
			sName2 = DB.getValue(node2, "nonid_name", "");
		end
	end

	return (sName1 or "") > (sName2 or "");
end

--
-- TURN FUNCTIONS
--

function onRoundStart(nCurrent)
	CombatManager2.resetTurnComplete();

	if OptionsManager.isOption("INTC", "on") then
		CombatManager2.clearAllInit();
	end

	local sOptionINTA = OptionsManager.getOption("INTA");
	if sOptionINTA == "NPCs Only" then
		CombatManager2.rollAllInit("npc");
	elseif sOptionINTA == "PCs Only" then
		CombatManager2.rollAllInit("charsheet");
	elseif sOptionINTA == "PCs and NPCs" then
		CombatManager2.rollAllInit();
	end
end
function onTurnStart(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	if OptionsManager.isOption("TSDU", "on") then
		local bSkip = false;
		local rActor = ActorManager.resolveActor(nodeEntry);
		if EffectManager.hasCondition(rActor, "Unconscious") or EffectManager.hasCondition(rActor, "Dead") then
			bSkip = true;
		else
			local iHits = DB.getValue(nodeEntry, "hits", 0);
			local iDamage = DB.getValue(nodeEntry, "damage", 0);
			if iHits ~= 0 and iDamage ~= 0 then
				if (iHits - iDamage) <= 0 then
					bSkip = true;
				end
			end
		end
		if bSkip then
			CombatManager.nextActor();	
		end
	end
end
function onTurnEnd(nodeEntry)
	if not nodeEntry then
		return;
	end

	-- See if the TurnComplete box has not been checked
	if DB.getValue(nodeEntry, "turncomplete", 0) == 0 then
		-- Update Exhaustion
		local rActor = ActorManager.resolveActor(nodeEntry);
		if not EffectManager.hasCondition(rActor, "Unconscious") and not EffectManager.hasCondition(rActor, "Dead") then
			local bOptionCEAT = OptionsManager.isOption("CEAT", "on");

			-- Exhaustion Multiplier
			local nExhaustionMultiplier = 1;
			if OptionsManager.isOption("CEMD", "on") then
				local nDamage = DB.getValue(nodeEntry, "damage", 0);
				local nHits = math.max(DB.getValue(nodeEntry, "hits", 1), 1);
				local nPercentDamaged = nDamage / nHits; 
				if nPercentDamaged > 0.5 then 
					nExhaustionMultiplier = 4;
				elseif nPercentDamaged > 0.25 then
					nExhaustionMultiplier = 2;
				end
			end
			
			-- Exhaustion for Melee Activity
			if DB.getValue(nodeEntry, "activitymelee", 0) > 0 then
				if bOptionCEAT then
					DB.setValue(nodeEntry, "exhaustioncurrent", "number", DB.getValue(nodeEntry, "exhaustioncurrent", 0) + (0.5 * nExhaustionMultiplier));
				end
				DB.setValue(nodeEntry, "activitymelee", "number", 0);
			end
			
			-- Exhaustion for Missile Activity
			if DB.getValue(nodeEntry, "activitymissile", 0) > 0 then
				if bOptionCEAT then
					DB.setValue(nodeEntry, "exhaustioncurrent", "number", DB.getValue(nodeEntry, "exhaustioncurrent", 0) + (0.16 * nExhaustionMultiplier));
				end
				DB.setValue(nodeEntry, "activitymissile", "number", 0);
			end
			
			-- Exhaustion for Spell/Concentration Activity
			if DB.getValue(nodeEntry, "activityconcentration", 0) > 0 then
				if bOptionCEAT then
					DB.setValue(nodeEntry, "exhaustioncurrent", "number", DB.getValue(nodeEntry, "exhaustioncurrent", 0) + (0.16 * nExhaustionMultiplier));
				end
				DB.setValue(nodeEntry, "activityconcentration", "number", 0);
			end
			
			-- Exhaustion for Movement Activity
			if bOptionCEAT then
				local sPace = DB.getValue(nodeEntry, "pace", "");
				local nNewExhaustion = DB.getValue(nodeEntry, "exhaustioncurrent", 0) + (Rules_Move.PaceExhaustion(sPace) * nExhaustionMultiplier)
				DB.setValue(nodeEntry, "exhaustioncurrent", "number", nNewExhaustion);
			end
		end

		-- Set Pace to None and MM% to 100
		DB.setValue(nodeEntry, "pace", "string", "x1 Walk");
		DB.setValue(nodeEntry, "manueverresult", "number", 100);
		
		-- Reduce the Activity Percent by 100 down to a minimum of 0
		DB.setValue(nodeEntry, "activitypercent", "number", math.max(0, DB.getValue(nodeEntry, "activitypercent", 0) - 100));

		DB.setValue(nodeEntry, "turncomplete", "number", 1);
	end
end

--
-- ADD FUNCTIONS
--

function getSpaceReachRMC(rActor)
	local nDU = GameSystem.getDistanceUnitsPerGrid();
	local nSpace = nDU;
	local nReach = nDU;

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		local nNPCSpace = DB.getValue(nodeActor, "space", 0);
		local nNPCReach = DB.getValue(nodeActor, "reach", 0);
		
		if nNPCSpace > 0 and nNPCReach > 0 then
			nSpace = nNPCSpace;
			nReach = nNPCReach;
		else
			if vSize == 5 or vSize == "Huge" then
				nSpace = 4 * nDU;
				nReach = 2 * nDU;
			elseif vSize == 4 or vSize == "Large" then
				nSpace = 2 * nDU;
				nReach = 1 * nDU;
			end
		end
	end

	return nSpace, nReach;
end

function onNPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	DB.setValue(tCustom.nodeCT, "manueverresult", "number", 100);
	
	-- Update for CoreRPG Version
	Rules_NPC.UpdateToCoreRPG(tCustom.nodeCT);

	-- Handle optional rule
	if OptionsManager.isOption("NRLH", "on") then
		Rules_NPC.UpdateRandomHitsAndLevel(tCustom.nodeCT);
	end
	
	-- Handle quickness
	local nQuickness = DB.getValue(tCustom.nodeCT, "initmod", 0);
	if nQuickness == 0 then
		local sAQ = DB.getValue(tCustom.nodeCT, "aq");
		if sAQ then
			nQuickness = Rules_NPC.GetInitMod(sAQ);
		end
	end
	DB.setValue(tCustom.nodeCT, "quicknessBonus", "number", nQuickness);

	-- Setup Attacks
	for _, nodeWeapon in pairs(DB.getChildren(tCustom.nodeCT, "weapons")) do
		if DB.getValue(nodeWeapon, "name", "") == "" and DB.getValue(nodeWeapon, "type", "") == "" then
			DB.deleteNode(nodeWeapon);
		else
			ItemManager2.UpdateToCoreRPG(nodeWeapon);
			DB.setValue(nodeWeapon, "open", "windowreference", "item", "");
			DB.setValue(nodeWeapon, "locked", "number", 1);
			DB.setValue(nodeWeapon, "isidentified", "number", 1); 
		end
	end
	
	-- Add Parry
	local bOptionDDTA = OptionsManager.isOption("DDTA", "on");
	local nodeParry = nil;
	for _, nodeDefence in pairs(DB.getChildren(tCustom.nodeCT, "defences")) do
		if bOptionDDTA then
			DB.setValue(nodeDefence, "targetall", "number", 1);
		end
		if DB.getValue(nodeDefence, "name", "") == "Parry" then
			nodeParry = nodeDefence;
		end
	end
	if not nodeParry then
		local nodeDefences = DB.createChild(tCustom.nodeCT, "defences");
		local nodeNewDefence = DB.createChild(nodeDefences);
		DB.setValue(nodeNewDefence, "name", "string", "Parry");
		if bOptionDDTA then
			DB.setValue(nodeNewDefence, "targetall", "number", 1);
		end
	end

	-- Roll initiative and sort
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT == "group" then
		if tCustom.nodeCTLastMatch then
			nInit = DB.getValue(tCustom.nodeCTLastMatch, "initresult", 0);
			DB.setValue(tCustom.nodeCT, "initresult", "number", nInit);
		else
			rollEntryInit(tCustom.nodeCT);
		end
	elseif sOptINIT == "on" then
		rollEntryInit(tCustom.nodeCT);
	else
		DB.setValue(tCustom.nodeCT, "initresult", "number", 0);
	end
end
function onPCPostAdd(tCustom)
	-- Parameter validation
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	DB.setValue(tCustom.nodeCT, "manueverresult", "number", 100);
	
	for _, nodeDefence in pairs(DB.getChildren(tCustom.nodeCT, "defences")) do
		if DB.getValue(nodeDefence, "name", "") == "Parry" then
			nodeParry = nodeDefence;
		end
	end
	if not nodeParry then
		local nodeDefences = DB.createChild(tCustom.nodeCT, "defences");
		local nodeNewDefence = DB.createChild(nodeDefences);
		DB.setValue(nodeNewDefence, "name", "string", "Parry");
		DB.setValue(nodeNewDefence, "isidentified", "number", 1);
	end
	
	CombatManager2.notifyCTUpdateOwners();
end

function addEntryWeaponItem(nodeEntry, sList, nodeSource)
	if not nodeEntry or not nodeSource or ((sList or "") == "") then
		return;
	end

	local nodeList = DB.createChild(nodeEntry, sList);
	local nodeNew = DB.createChild(nodeList);
	if not nodeNew then
		return;
	end

	CombatManager2.copyCTAttack(nodeSource, nodeNew);
	DB.setValue(nodeNew, "open", "windowreference", "item", "");
	if DB.getValue(nodeNew, "hitsmultiplier", 0) == 0 then
		DB.setValue(nodeNew, "hitsmultiplier", "number", 1);
	end
	return nodeNew;
end
function addEntrySpellItem(nodeEntry, sList, nodeSource)
	if not nodeEntry or not nodeSource or ((sList or "") == "") then
		return;
	end

	local nodeList = DB.createChild(nodeEntry, sList);
	local nodeNew = DB.createChild(nodeList);
	if not nodeNew then
		return;
	end

	DB.setValue(nodeNew, "name", "string", DB.getValue(nodeSource, "name", ""));
	DB.setValue(nodeNew, "open", "windowreference", "spell", DB.getPath(nodeSource));
	return nodeNew;
end
function copyCTAttack(src, dst)
	DB.setValue(dst, "isidentified", "number", DB.getValue(src, "isidentified", 1));

	-- Descriptive fields
	DB.setValue(dst, "name", "string", DB.getValue(src, "name", ""));
	DB.setValue(dst, "nonid_name", "string", DB.getValue(src, "nonid_name", ""));
	if DB.getType(DB.getPath(src, "type")) == "number" then
		DB.setValue(dst, "type", "string", ItemManager2.getItemTypeString(DB.getValue(src, "type", 0)));
	else
		DB.setValue(dst, "type", "string", DB.getValue(src, "type", ""));
	end

	-- Attack stats
	DB.setValue(dst, "ob", "number", tonumber(DB.getValue(src, "ob", 0)) or 0);
	DB.setValue(dst, "hitsmultiplier", "number", DB.getValue(src, "hitsmultiplier", ""));
	DB.setValue(dst, "attacktable.name", "string", DB.getValue(src, "attacktable.name", ""))
	DB.setValue(dst, "attacktable.tableid", "string", DB.getValue(src, "attacktable.tableid", ""))

	-- Defence stats
	DB.setValue(dst, "meleebonus", "number", DB.getValue(src, "meleebonus", ""));
	DB.setValue(dst, "missilebonus", "number", DB.getValue(src, "missilebonus", ""));

	return dst;
end

function isCTEntryOwner(nodeCT)
	if not nodeCT then
		return false;
	end
	if Session.IsHost then
		return true;
	end
	return (DB.getValue(nodeCT, "owner", "") == User.getUsername());
end

--
-- RESET FUNCTIONS
--

function resetTurnComplete()
	function resetCombatantTurnComplete(nodeCT)
		DB.setValue(nodeCT, "turncomplete", "number", 0);
	end
	CombatManager.callForEachCombatant(resetCombatantTurnComplete);
end
function resetInit()
	function resetCombatantInit(nodeCT)
		DB.setValue(nodeCT, "initresult", "number", 0);
		DB.setValue(nodeCT, "reaction", "number", 0);
	end
	CombatManager.callForEachCombatant(resetCombatantInit);
end
function resetHealth(nodeCT, bLong)
	if bLong then
		DB.setValue(nodeCT, "wounds", "number", 0);
		DB.setValue(nodeCT, "hptemp", "number", 0);
		DB.setValue(nodeCT, "deathsavesuccess", "number", 0);
		DB.setValue(nodeCT, "deathsavefail", "number", 0);
		
		local rActor = ActorManager.resolveActor(nodeCT);
		EffectManager.removeCondition(rActor, "Stable");
		
		local nExhaustMod = EffectManagerRMC.getEffectsBonus(rActor, {"EXHAUSTION"}, true);
		if nExhaustMod > 0 then
			nExhaustMod = nExhaustMod - 1;
			EffectManagerRMC.removeEffectByType(nodeCT, "EXHAUSTION");
			if nExhaustMod > 0 then
				local nEffectInit = DB.getValue(nodeCT, "initresult", 1) - 1;
				EffectManager.addEffect("", "", nodeCT, { sName = "EXHAUSTION: " .. nExhaustMod, nDuration = 0, nInit = nEffectInit }, false);
			end
		end
	end
end
function clearExpiringEffects()
	function checkEffectExpire(nodeEffect)
		local sLabel = DB.getValue(nodeEffect, "label", "");
		local nDuration = DB.getValue(nodeEffect, "duration", 0);
		local sApply = DB.getValue(nodeEffect, "apply", "");
		
		if nDuration ~= 0 or sApply ~= "" or sLabel == "" then
			DB.deleteNode(nodeEffect);
		end
	end
	CombatManager.callForEachCombatantEffect(checkEffectExpire);
end
function rest(bLong)
	CombatManager.resetInit();
	clearExpiringEffects();

	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if not EffectManager.hasCondition(v, "Dead") then
			local bHandled = false;
			local nodePC = CombatManager2.getPCLinkNode(v);
			if nodePC then
				CharManager.rest(nodePC, bLong);
				bHandled = true;
			end
			
			if not bHandled then
				resetHealth(v, bLong);
			end
		end
	end
end

function restHours(nHours)
	local sDescription = "Resting for " .. nHours .. " hour";
	if nHours ~= 1 then
		sDescription = sDescription .. "s";
	end
	
	local rMessage = {};
	rMessage.text = sDescription;
	rMessage.icon = "resting";
	Comm.deliverChatMessage(rMessage);

	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		if not EffectManager.hasCondition(nodeCT, "Dead") then
			CombatManager2.restHoursEntry(nodeCT, nHours);
			
			if nHours >= 8 then
				CombatManager2.restRemovePPEntry(nodeCT);
			end
		end
	end
end
function restRemoveHitsPP()
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		if not EffectManager.hasCondition(nodeCT, "Dead") then
			CombatManager2.restRemoveHitsEntry(nodeCT);
			CombatManager2.restRemovePPEntry(nodeCT);
		end
	end
end
function restRemoveHits()
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		if not EffectManager.hasCondition(nodeCT, "Dead") then
			CombatManager2.restRemoveHitsEntry(nodeCT);
		end
	end
end
function restRemovePP()
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		if not EffectManager.hasCondition(nodeCT, "Dead") then
			CombatManager2.restRemovePPEntry(nodeCT);
		end
	end
end

function restHoursEntry(nodeCT, nHours)
	if nodeCT then
		local nCurrentDamage = DB.getValue(nodeCT, "damage", 0);
		local nRecoveryMultiplier = 1;

		if string.lower(OptionsManager.getOption("RRRM")) == string.lower(Interface.getString("option_val_on")) then 
			local sCharClass, sCharRecordName = DB.getValue(nodeCT, "link", nil);
			if sCharClass == "charsheet" then
				local nodeChar = DB.findNode(sCharRecordName);
				if nodeChar then
					local _, sRaceRecordName = DB.getValue(nodeChar, "racelink", nil);
					if sRaceRecordName then
						local nodeRace = DB.findNode(sRaceRecordName);
						if nodeRace then
							nRecoveryMultiplier = Rules_Races.GetRecoverMultiplier(nodeRace);
						end
					end
				end
			end
		end

		if nCurrentDamage ~= 0 then
			local nHealAmount = math.floor(((-1 * nHours) / nRecoveryMultiplier) + 0.5);
			if nCurrentDamage < nHours then
				nHealAmount = -1 * nCurrentDamage;
			end
			local rActor = ActorManager.resolveActor(nodeCT);
			ActionDamage.applyDamage(nil, rActor, false, "Resting", nHealAmount);
		end

		DB.setValue(nodeCT, "exhaustioncurrent", "number", 0);
	end
end
function restRemoveHitsEntry(nodeCT)
	if nodeCT then
		DB.setValue(nodeCT, "damage", "number", 0);
	end
end
function restRemovePPEntry(nodeCT)
	if nodeCT then
		DB.setValue(nodeCT, "ppcurrent", "number", 0);
		DB.setValue(nodeCT, "spelladderused", "number", 0);

		local rActor = ActorManager.resolveActor(nodeCT);
		if ActorManager.isPC(rActor) then
			local nodeChar = ActorManager.getCreatureNode(rActor);
			if nodeChar then
				DB.setValue(nodeChar, "pp.spelladderused", "number", 0);
			end
		end
	end
end

--
-- INITIATIVE FUNCTIONS
--

function rollRandomInit(nMod)
	local nInitResult = 0;
	
	local sOptionINTD = OptionsManager.getOption("INTD");
	if sOptionINTD == "Core: 2d10" then
		nInitResult = math.random(10) + math.random(10);
	elseif sOptionINTD == "d100" then
		nInitResult = math.random(100);
	elseif sOptionINTD == "Open-Ended" then
		nInitResult = math.random(100);
		if nInitResult >= 96 then
			local nNextRoll = math.random(100);
			while nNextRoll >= 96 do
				nInitResult = nInitResult + nNextRoll;
				nNextRoll = math.random(100);
			end
			nInitResult = nInitResult + nNextRoll;
		elseif nInitResult <= 5 then
			local nNextRoll = math.random(100);
			while nNextRoll >= 96 do
				nInitResult = nInitResult - nNextRoll;
				nNextRoll = math.random(100);
			end
			nInitResult = nInitResult - nNextRoll;
		end
	elseif sOptionINTD == "High Open-Ended" then
		nInitResult = math.random(100);
		if nInitResult >= 96 then
			local nNextRoll = math.random(100);
			while nNextRoll >= 96 do
				nInitResult = nInitResult + nNextRoll;
				nNextRoll = math.random(100);
			end
			nInitResult = nInitResult + nNextRoll;
		end
	elseif sOptionINTD == "Low Open-Ended" then
		nInitResult = math.random(100);
		if nInitResult <= 5 then
			local nNextRoll = math.random(100);
			while nNextRoll >= 96 do
				nInitResult = nInitResult - nNextRoll;
				nNextRoll = math.random(100);
			end
			nInitResult = nInitResult - nNextRoll;
		end
	end
	
	nInitResult = nInitResult + nMod;
	return nInitResult;
end
function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end
	
	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	
	-- Get any effect modifiers
	local rActor = ActorManager.resolveActor(nodeEntry);
	local aEffectDice, nEffectBonus = EffectManagerRMC.getEffectsBonus(rActor, "INIT");
	nInit = nInit + StringManager.evalDice(aEffectDice, nEffectBonus);

	-- For PCs, we always roll unique initiative
	local nodeChar = CombatManager2.getPCLinkNode(nodeEntry);
	if nodeChar then
		local nInitResult = rollRandomInit(nInit);
		nInitResult = nInitResult + Rules_PC.GetInitMod(nodeChar);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end

	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then
		local sAttackQuickness = DB.getValue(nodeEntry,"aq","");
		if string.len(sAttackQuickness) > 1 then
			nInit = nInit + Rules_NPC.GetInitMod(sAttackQuickness);
		else
			local nInitMod = DB.getValue(nodeEntry, "initmod", 0);
			nInit = nInit + nInitMod;
		end
		local nInitResult = rollRandomInit(nInit);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end

	-- For NPCs with group option enabled
	
	-- Get the entry's database node name and creature name
	local sStripName = CombatManager.stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then
		local sAttackQuickness = DB.getValue(nodeEntry,"aq","");
		nInit = nInit + Rules_NPC.GetInitMod(sAttackQuickness);
		local nInitResult = rollRandomInit(nInit);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		return;
	end
		
	-- Iterate through list looking for other creature's with same name and faction
	local nLastInit = nil;
	local sEntryFaction = DB.getValue(nodeEntry, "friendfoe", "");
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if DB.getName(v) ~= DB.getName(nodeEntry) then
			if DB.getValue(v, "friendfoe", "") == sEntryFaction then
				local sTemp = CombatManager.stripCreatureNumber(DB.getValue(v, "name", ""));
				if sTemp == sStripName then
					local nChildInit = DB.getValue(v, "initresult", 0);
					if nChildInit ~= -10000 then
						nLastInit = nChildInit;
					end
				end
			end
		end
	end
	
	-- If we found similar creatures, then match the initiative of the last one found
	if nLastInit and nLastInit ~= 0 then
		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
	else
		local sAttackQuickness = DB.getValue(nodeEntry,"aq","");
		nInit = nInit + Rules_NPC.GetInitMod(sAttackQuickness);
		local nInitResult = rollRandomInit(nInit);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
	end
end
function rollAllInit(sType)
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		local sClass,_ = DB.getValue(nodeCT, "link", "", "");
		if not sType or sClass == sType then
			rollEntryInit(nodeCT);
		end
	end
end
function clearAllInit()
	for _,nodeCT in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(nodeCT, "initresult", "number", 0);
	end
end

function UpdateEffectInit(nodeCT, nInit)
	if not nodeCT then
		return;
	end
	for _,nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
		DB.setValue(nodeEffect, "init", "number", nInit - 1);
	end
end

--
--	XP FUNCTIONS
--

function calcBattleXP(nodeBattle)
	local sTargetNPCList = LibraryData.getCustomData("battle", "npclist") or "npclist";
	local nPartyAvgLevel = DB.getValue(nodeBattle, "party_avg_level", 1);

	local nXP = 0;
	for _, vNPCItem in pairs(DB.getChildren(nodeBattle, sTargetNPCList)) do
		local sClass, sRecord = DB.getValue(vNPCItem, "link", "", "");
		if sRecord ~= "" then
			local nodeNPC = DB.findNode(sRecord);
			if nodeNPC then
				local nLevel = DB.getValue(nodeNPC, "level", 0);
				local nHits = DB.getValue(nodeNPC, "hits", 0);
				local sBonusXPCode = DB.getValue(nodeNPC, "bonusep", "")
				local nBaseXP = nHits + (20 * nLevel);
				local nBonusXP = 0;
				if sBonusXPCode ~= "" then
					nBonusXP = Rules_Combat.GetBonusXP(sBonusXPCode, nPartyAvgLevel);
				end
				local nTotalXP = nBaseXP + nBonusXP;
				
				nXP = nXP + (DB.getValue(vNPCItem, "count", 0) * nTotalXP);
			else
				local sMsg = string.format(Interface.getString("enc_message_refreshxp_missingnpclink"), DB.getValue(vNPCItem, "name", ""));
				ChatManager.SystemMessage(sMsg);
			end
		end
	end
	
	DB.setValue(nodeBattle, "exp", "number", nXP);
end
function calcBattlePartyAvgLevel(nodeBattle)
	local nPartyTotalLevels = 0;
	local nPCCount = 0;
	local nAvgLevel = 0;

	for _,v in pairs(PartyManager.getPartyNodes()) do
		local sClass, sRecord = DB.getValue(v, "link", "", "");
		if (sClass == "charsheet") and (sRecord ~= "") then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				nPCCount = nPCCount + 1;
				nPartyTotalLevels = nPartyTotalLevels + DB.getValue(nodePC, "level", 0);
			end
		end
	end

	if nPCCount > 0 then
		nAvgLevel = math.floor(nPartyTotalLevels/nPCCount);
	end
	DB.setValue(nodeBattle, "party_avg_level", "number", nAvgLevel);
end

--
--	COMBAT ACTION FUNCTIONS
--

function addRightClickDiceToClauses(rRoll)
	if #rRoll.clauses > 0 then
		local nOrigDamageDice = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nOrigDamageDice = nOrigDamageDice + #vClause.dice;
		end
		if #rRoll.aDice > nOrigDamageDice then
			local v = rRoll.clauses[#rRoll.clauses].dice;
			for i = nOrigDamageDice + 1,#rRoll.aDice do
				table.insert(rRoll.clauses[1].dice, rRoll.aDice[i]);
			end
		end
	end
end

function addWoundEffects(nodeTarget, woundEffects, description)
	local nEffectInit = DB.getValue(nodeTarget, "initresult", 1) - 1;
	local bUseConditionalEffects, sCondition, sMsgIcon = Rules_Combat.UseConditionalEffects(woundEffects, nodeTarget);
	local sFriendFoe = DB.getValue(nodeTarget, "friendfoe", "");
	local sImmunity = DB.getValue(nodeTarget, "immunity", "");
	local bShowEffect = true;
	local nEffectGMOnly = 1;

	if sFriendFoe == "friend" then -- Ally
		if OptionsManager.isOption("SEPC", "all") then
			bShowEffect = true;
			nEffectGMOnly = 0;
		end	
	else -- Non-ally
		if OptionsManager.isOption("SENPC", "all") and not CombatManager.isCTHidden(nodeTarget) then
			bShowEffect = true;
			nEffectGMOnly = 0;
		end	
	end

	-- Attacker Effects
	if woundEffects.AttackerNodeName then
		nodeAttacker = DB.findNode(woundEffects.AttackerNodeName);
	end
	if woundEffects.AttackerNextAttack and nodeAttacker then
		EffectManager.addEffect("", "", nodeAttacker, { sName = description .. "; OB: " .. woundEffects.AttackerNextAttack, sApply = "action", nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
	end
	if woundEffects.AttackerNextRoll and nodeAttacker then
		EffectManager.addEffect("", "", nodeAttacker, { sName = description .. "; OB: " .. woundEffects.AttackerNextRoll, sApply = "roll", nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
	end

	if bUseConditionalEffects then  -- Use conditional effects
		-- hits
		if woundEffects.ConditionalHits then
			ActionDamage.applyDamage(nil, nodeTarget, CombatManager.isCTHidden(node), description, woundEffects.ConditionalHits);
		end
		
		-- effects
		if woundEffects.ConditionalPenalty then
			local nPenaltyDuration = 0;
			if woundEffects.ConditionalPenaltyRounds then
				nPenaltyDuration = woundEffects.ConditionalPenaltyRounds;
			end
			EffectManager.addEffect("", "", nodeTarget, { sName = description .. "; Penalty: " .. woundEffects.ConditionalPenalty, nDuration = nPenaltyDuration, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		if woundEffects.ConditionalBleeding then
			if sImmunity:lower():find("hits/rd") then
				EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "Bleeding: " .. woundEffects.ConditionalBleeding, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			else
				EffectManager.addEffect("", "", nodeTarget, { sName = "Bleeding: " .. woundEffects.ConditionalBleeding, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.ConditionalMustParry then
			if sImmunity:lower():find("stun") and OptionsManager.isOption("AL14", "on") then
				EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "MustParry", nDuration = woundEffects.ConditionalMustParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", nodeTarget, { sName = "MustParry", nDuration = woundEffects.ConditionalMustParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			end
		end
		if woundEffects.ConditionalStun then
			local stun = woundEffects.ConditionalStun;
			if stun > 0 then
				if sImmunity:lower():find("stun") then
					EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "Stun", nDuration = stun, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
				else
					EffectManagerRMC.summarizeEffect("", "", nodeTarget, { sName = "Stun", nDuration = stun, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
				end
			end
		end
		if woundEffects.ConditionalNoParry then
			if sImmunity:lower():find("stun") then
				EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "NoParry", nDuration = woundEffects.ConditionalNoParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", nodeTarget, { sName = "NoParry", nDuration = woundEffects.ConditionalNoParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			end
		end
		if woundEffects.ConditionalParryPenalty then
			local nParryPenaltyDuration = 0;
			if woundEffects.ConditionalMustParry then
				nParryPenaltyDuration = woundEffects.ConditionalMustParry;
			end
			EffectManager.addEffect("", "", nodeTarget, { sName = "ParryPenalty: " .. woundEffects.ConditionalParryPenalty, nDuration =  nParryPenaltyDuration, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		if woundEffects.ConditionalWound then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.ConditionalWound) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.ConditionalWound, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.ConditionalEffect then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.ConditionalEffect) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.ConditionalEffect, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.ConditionalEffect2 then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.ConditionalEffect2) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.ConditionalEffect2, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.ConditionalEffect3 then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.ConditionalEffect3) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.ConditionalEffect3, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.ConditionalDying then
			EffectManager.addEffect("", "", nodeTarget, { sName = "Dying", nDuration = woundEffects.ConditionalDying, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		
	else -- Use Default Effects
		-- hits
		if woundEffects.Hits then
			ActionDamage.applyDamage(nil, nodeTarget, CombatManager.isCTHidden(node), description, woundEffects.Hits);
		end
		
		if woundEffects.RR then
			EffectManager.addEffect("", "", nodeTarget, { sName = "RR: " .. woundEffects.RR, sApply = "action", nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		if woundEffects.RRTarget then
			EffectManager.removeEffect(nodeTarget, "RRTarget");
			EffectManager.addEffect("", "", nodeTarget, { sName = "RRTarget: " .. woundEffects.RRTarget, sApply = "action", nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		
		-- effects
		if woundEffects.Penalty then
			local nPenaltyDuration = 0;
			if woundEffects.PenaltyRounds then
				nPenaltyDuration = woundEffects.PenaltyRounds;
			end
			EffectManager.addEffect("", "", nodeTarget, { sName = description .. "; Penalty: " .. woundEffects.Penalty, nDuration = nPenaltyDuration, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		if woundEffects.Bleeding then
			if sImmunity:lower():find("hits/rd") then
				EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "Bleeding: " .. woundEffects.Bleeding, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			else
				EffectManager.addEffect("", "", nodeTarget, { sName = "Bleeding: " .. woundEffects.Bleeding, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.MustParry then
			if sImmunity:lower():find("stun") and OptionsManager.isOption("AL14", "on") then
				EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "MustParry", nDuration = woundEffects.MustParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", nodeTarget, { sName = "MustParry", nDuration = woundEffects.MustParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			end
		end
		if woundEffects.Stun then
			local stun = woundEffects.Stun;
			if stun > 0 then
				if sImmunity:lower():find("stun") then
					EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "Stun", nDuration = stun, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly)
				else
					EffectManagerRMC.summarizeEffect("", "", nodeTarget, { sName = "Stun", nDuration = stun, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
				end
			end
		end
		if woundEffects.NoParry then
			if sImmunity:lower():find("stun") then
				EffectManagerRMC.notifyImmunity("", "", nodeTarget, { sName = "NoParry", nDuration = woundEffects.NoParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", nodeTarget, { sName = "NoParry", nDuration = woundEffects.NoParry, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect, nEffectGMOnly);
			end
		end
		if woundEffects.ParryPenalty then
			local nParryPenaltyDuration = 0;
			if woundEffects.MustParry then
				nParryPenaltyDuration = woundEffects.MustParry;
			end
			EffectManager.addEffect("", "", nodeTarget, { sName = "ParryPenalty: " .. woundEffects.ParryPenalty, nDuration =  nParryPenaltyDuration, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
		if woundEffects.Wound then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.Wound) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.Wound, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.Effect then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.Effect) then
				local nEffectDuration = 0;
				if woundEffects.EffectDuration then
					nEffectDuration = woundEffects.EffectDuration;
				end
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.Effect, nDuration = nEffectDuration, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.Effect2 then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.Effect2) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.Effect2, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.Effect3 then
			if not EffectManagerRMC.hasEffect(nodeTarget, woundEffects.Effect3) then
				EffectManager.addEffect("", "", nodeTarget, { sName = woundEffects.Effect3, nDuration = 0, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
			end
		end
		if woundEffects.Dying then
			EffectManager.addEffect("", "", nodeTarget, { sName = "Dying", nDuration = woundEffects.Dying, nInit = nEffectInit, nGMOnly = nEffectGMOnly }, bShowEffect);
		end
	end

	-- Check if Description should be sent to the Chat Window
	local sOptionSETC = OptionsManager.getOption("SETC");
	if ((description or "") ~= "") and (sOptionSETC ~= "off") then
		local msg = {font = "msgfont", icon = sMsgIcon, mode = "system"};
		local sClass,_ = DB.getValue(nodeTarget, "link", "", "");
		local sMessageText = "";
		
		if sClass == "npc" then
			local bID = LibraryData.getIDState("npc", nodeTarget, true);
			if bID then
				sMessageText = "[" .. DB.getValue(nodeTarget, "name", "") .. "] ";
			else
				sMessageText = "[" .. DB.getValue(nodeTarget, "nonid_name", "") .. "] ";
			end
		else
			sMessageText = "[" .. DB.getValue(nodeTarget, "name", "") .. "] ";
		end
		if sCondition and string.len(sCondition) > 1 then
			if bUseConditionalEffects then
				sMessageText = sMessageText .. "* [" .. sCondition .. "] * ";
			else
				sMessageText = sMessageText .. "* [No " .. sCondition .. "] * ";
			end
			sCondition = "";
		end
		sMessageText = sMessageText .. " -  " .. description;
		msg.text = sMessageText;

		if (sOptionSETC == "gm only") or CombatManager.isCTHidden(nodeTarget) then
			msg.secret = true;
		end
		Comm.deliverChatMessage(msg);	
	end
 end
 
function getRange(nodeAttacker, nodeDefender)
	local bSameImage = false;
	if nodeAttacker and nodeDefender then
		local tokenAttacker = CombatManager.getTokenFromCT(nodeAttacker);
		local tokenDefender = CombatManager.getTokenFromCT(nodeDefender);
		if tokenAttacker and tokenDefender and tokenAttacker.getContainerNode() == tokenDefender.getContainerNode() then
			local ctrlImage = ImageManager.getImageControl(tokenAttacker, true);
			nDistance = ctrlImage.getDistanceBetween(tokenAttacker, tokenDefender);
			nDistance = (math.floor((nDistance + 0.05) * 10) / 10);
			return nDistance;
		end	
	end

	return -1;
end

function isPC(nodeCT)
	return CombatManager2.isRecordType(nodeCT, "charsheet");
end
function isRecordType(nodeCT, sRecordTypeParam)
	if not nodeCT then
		return false;
	end

	local sClass,_ = DB.getValue(nodeCT, "link", "", "");
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);
	return (sRecordType == sRecordTypeParam);
end

function getPCLinkNode(nodeCT)
	return CombatManager2.getRecordTypeLinkNode(nodeCT, "charsheet");
end
function getRecordTypeLinkNode(nodeCT, sRecordTypeParam)
	if not nodeCT then
		return nil;
	end

	local sClass,sRecord = DB.getValue(nodeCT, "link", "", "");
	local sRecordType = LibraryData.getRecordTypeFromDisplayClass(sClass);
	if (sRecordType ~= sRecordTypeParam) then
		return nil;
	end

	if sRecord ~= "" then
		return DB.findNode(sRecord);
	end
	return nodeCT;
end

--
-- CT NODE FUNCTIONS
--

function CTNodeOnDrop(nodeCT, draginfo)
	if not Session.IsHost then
		return;
	end

	local customData = draginfo.getCustomData();

	-- only recognise dropped strings, numbers or Attack Effects
	if draginfo and (draginfo.isType("number") or draginfo.isType("rmdice"))then
		if not customData then
			local iHits = draginfo.getNumberData();
			if iHits then
				customData = {Hits=iHits};
				draginfo.setDescription(tostring(iHits));
			end
		end
	elseif draginfo and draginfo.isType("effect") then
		local rEffect = EffectManager.decodeEffectFromDrag(draginfo);
		local sFriendFoe = DB.getValue(nodeCT, "friendfoe", "");
		local sImmunity = DB.getValue(nodeCT,"immunity", "");
		local bShowEffect = true;
		local nEffectGMOnly = 1;
		if sFriendFoe == "friend" then -- Ally
			if OptionsManager.isOption("SEPC", "all") then
				bShowEffect = true;
				nEffectGMOnly = 0;
			end	
		else -- Non-ally
			if OptionsManager.isOption("SENPC", "all") and not CombatManager.isCTHidden(nodeCT) then
				bShowEffect = true;
				nEffectGMOnly = 0;
			end	
		end

		rEffect.nGMOnly = nEffectGMOnly;
		rEffect.nInit = DB.getValue(nodeCT,"initresult", 1) - 1;
		if rEffect.sName == "Stun" or rEffect.sName == "NoParry" then	
			if sImmunity:lower():find("stun") then
				EffectManagerRMC.notifyImmunity("", "", nodeCT, rEffect, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", nodeCT, rEffect, bShowEffect, nEffectGMOnly);
			end
		elseif rEffect.sName == "MustParry" then
			if sImmunity:lower():find("stun") and OptionsManager.isOption("AL14", "on") then
				EffectManagerRMC.notifyImmunity("", "", nodeCT, rEffect, bShowEffect, nEffectGMOnly);
			else
				EffectManagerRMC.summarizeEffect("", "", nodeCT, rEffect, bShowEffect, nEffectGMOnly);
			end
		else
			if rEffect.sName:lower():find("bleeding") and sImmunity:lower():find("hits/rd") then
				EffectManagerRMC.notifyImmunity("", "", nodeCT, rEffect, bShowEffect, nEffectGMOnly);
			else
				EffectManager.addEffect("", "", nodeCT, rEffect, bShowEffect, nEffectGMOnly);
			end
		end
		return true;
	elseif (not draginfo) or (not draginfo.isType(Rules_Constants.DataType.AttackEffects)) then
		return;
	end

	if customData then
		if draginfo.getDescription() and draginfo.getDescription()~="" then
			addWoundEffects(nodeCT, customData, draginfo.getDescription());
		end
		-- indicate that we have processed this event
		return true;
	end
end

--
-- CT OWNER FUNCTIONS
--

function notifyCTUpdateOwners()
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_CTUPDATEOWNERS;

	Comm.deliverOOBMessage(msgOOB, "");
end
function handleCTUpdateOwners()
    if not Session.IsHost then
    	return;
    end

	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local nodePC = CombatManager2.getPCLinkNode(v);
		if nodePC then
			CombatManager2.updateOwner(v, DB.getOwner(nodePC));
		end
	end
end
function updateOwner(nodeCT, sOwner)
	if (sOwner or "") ~= "" then
		DB.setOwner(nodeCT, sOwner);
		DB.setValue(nodeCT, "owner", "string", sOwner);
	else
		DB.setOwner(nodeCT, nil);
		DB.setValue(nodeCT, "owner", "string", "");
	end
end
