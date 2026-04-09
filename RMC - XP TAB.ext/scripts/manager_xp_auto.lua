-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local aMMDifficultyToField = {
	["routine"] = "routine",
	["easy"] = "easy",
	["light"] = "light",
	["medium"] = "medium",
	["hard"] = "hard",
	["very hard"] = "veryhard",
	["veryhard"] = "veryhard",
	["extremely hard"] = "extremelyhard",
	["extremelyhard"] = "extremelyhard",
	["sheer folly"] = "sheerfolly",
	["sheerfolly"] = "sheerfolly",
	["absurd"] = "absurd",
};

local aSpellLevelToField = {
	"spellone", "spelltwo", "spellthree", "spellfour", "spellfive", "spellsix", "spellseven", "spelleight", "spellnine", "spellten", "spelleleven"
};

local fOriginalAddWoundEffects;
local fOriginalApplyDamage;
local aPendingAttackerPCByTarget = {};

function onInit()
	if not Session.IsHost then
		return;
	end

	ActionsManager.registerPostRollHandler("attack", onAttackPostRoll);
	ActionsManager.registerPostRollHandler("skill", onSkillPostRoll);
	ActionsManager.registerPostRollHandler("basecasting", onBaseCastingPostRoll);

	if CombatManager2 and CombatManager2.addWoundEffects then
		fOriginalAddWoundEffects = CombatManager2.addWoundEffects;
		CombatManager2.addWoundEffects = onAddWoundEffectsWithXP;
	end

	if ActionDamage and ActionDamage.applyDamage then
		fOriginalApplyDamage = ActionDamage.applyDamage;
		ActionDamage.applyDamage = onApplyDamageWithXP;
	end
end

function onAttackPostRoll(rSource, rTarget, rRoll)
	if not rRoll then
		return;
	end

	local nodeAttackerPC = getPCNodeFromActor(rSource);
	if nodeAttackerPC and rTarget then
		local nodeTargetCT = ActorManager.getCTNode(rTarget);
		updateCombatXPDescByOpponent(nodeAttackerPC, nodeTargetCT);
	end

	local nodeTargetPC = getPCNodeFromActor(rTarget);
	if nodeTargetPC and rSource then
		local nodeSourceCT = ActorManager.getCTNode(rSource);
		updateCombatXPDescByOpponent(nodeTargetPC, nodeSourceCT);
	end
end

function onSkillPostRoll(rSource, rTarget, rRoll)
	local nodePC = getPCNodeFromActor(rSource);
	if not nodePC or not rRoll then
		return;
	end

	if not isSkillSuccess(rRoll) then
		return;
	end

	local sDifficulty = getSkillDifficulty(rRoll);
	local sField = getMMDifficultyField(sDifficulty);
	if sField ~= "" then
		addXPValue(nodePC, sField, 1);
	end
end

function onBaseCastingPostRoll(rSource, rTarget, rRoll)
	local nodePC = getPCNodeFromActor(rSource);
	if not nodePC or not rRoll then
		return;
	end

	if not isBaseCastingSuccess(rRoll) then
		return;
	end

	local nSpellLevel = tonumber(rRoll.nSpellLevel) or 0;
	if nSpellLevel <= 0 then
		nSpellLevel = 1;
	end

	local sField = getSpellLevelField(nSpellLevel);
	if sField ~= "" then
		addXPValue(nodePC, sField, 1);
	end
end

function onAddWoundEffectsWithXP(nodeTarget, woundEffects, description, ...)
	if not fOriginalAddWoundEffects then
		return;
	end

	local nodeAttackerCT = nil;
	if type(woundEffects) == "table" and woundEffects.AttackerNodeName then
		nodeAttackerCT = DB.findNode(woundEffects.AttackerNodeName);
	end

	local nodeAttackerPC = getPCNodeFromCT(nodeAttackerCT);
	local nodeTargetPC = getPCNodeFromCT(nodeTarget);

	if nodeAttackerPC then
		updateCombatXPDescByOpponent(nodeAttackerPC, nodeTarget);
	end
	if nodeTargetPC then
		updateCombatXPDescByOpponent(nodeTargetPC, nodeAttackerCT);
	end

	local sTargetPath = "";
	if nodeTarget then
		sTargetPath = DB.getPath(nodeTarget) or "";
	end
	local sPrevPendingAttacker = "";
	if sTargetPath ~= "" then
		sPrevPendingAttacker = aPendingAttackerPCByTarget[sTargetPath] or "";
		if nodeAttackerPC then
			aPendingAttackerPCByTarget[sTargetPath] = DB.getPath(nodeAttackerPC) or "";
		else
			aPendingAttackerPCByTarget[sTargetPath] = "";
		end
	end

	local nTargetHits = DB.getValue(nodeTarget, "hits", 0);
	local nDamageBefore = DB.getValue(nodeTarget, "damage", 0);
	local bWasAlive = true;
	if nTargetHits > 0 then
		bWasAlive = (nDamageBefore < nTargetHits);
	end

	fOriginalAddWoundEffects(nodeTarget, woundEffects, description, ...);

	if sTargetPath ~= "" then
		aPendingAttackerPCByTarget[sTargetPath] = sPrevPendingAttacker;
	end

	local nDamageAfter = DB.getValue(nodeTarget, "damage", 0);

	local bNowDead = false;
	if nTargetHits > 0 then
		bNowDead = (nDamageAfter >= nTargetHits);
	end

	if nodeAttackerPC then
		local sCritSeverity = getCriticalSeverity(woundEffects, description);
		if sCritSeverity ~= "" then
			local sCritOutcome = getCriticalOutcome(nodeAttackerCT, nodeTarget, woundEffects, description, bWasAlive, bNowDead);
			local sCritField = getCriticalFieldName(sCritSeverity, sCritOutcome);
			if sCritField ~= "" then
				addXPValue(nodeAttackerPC, sCritField, 1);
			end
		end
	end
end

function onApplyDamageWithXP(rSource, rTarget, bSecret, sDamage, nTotal)
	if not fOriginalApplyDamage then
		return;
	end

	local nHitsBefore, nWoundsBefore, nodeTarget, sTargetType = getTargetHealthState(rTarget);
	local bWasAlive = false;
	if nHitsBefore > 0 then
		bWasAlive = (nWoundsBefore < nHitsBefore);
	end

	fOriginalApplyDamage(rSource, rTarget, bSecret, sDamage, nTotal);

	local nHitsAfter, nWoundsAfter = getTargetHealthState(rTarget);
	local nAppliedDamage = math.max(0, nWoundsAfter - nWoundsBefore);
	if nAppliedDamage <= 0 then
		return;
	end

	local nodeTargetPC = getPCNodeFromTarget(rTarget, nodeTarget, sTargetType);
	if nodeTargetPC then
		addXPValue(nodeTargetPC, "hitstaken", nAppliedDamage);
	end

	local nodeSourcePC = getPCNodeFromActor(rSource);
	if not nodeSourcePC then
		local sTargetPath = "";
		if nodeTarget then
			sTargetPath = DB.getPath(nodeTarget) or "";
		end
		if sTargetPath ~= "" then
			local sSourcePCPath = aPendingAttackerPCByTarget[sTargetPath] or "";
			if sSourcePCPath ~= "" then
				nodeSourcePC = DB.findNode(sSourcePCPath);
			end
		end
	end

	if nodeSourcePC then
		addXPValue(nodeSourcePC, "hitsgiven", nAppliedDamage);
	end

	local bNowDead = false;
	if nHitsAfter > 0 then
		bNowDead = (nWoundsAfter >= nHitsAfter);
	end
	if nodeSourcePC and bWasAlive and bNowDead then
		addXPValue(nodeSourcePC, "foekill", 1);
	end
end

function getTargetHealthState(rTarget)
	local nHits = 0;
	local nWounds = 0;
	local nodeTarget = ActorManager.getCreatureNode(rTarget);
	local sTargetType = ActorManager.getRecordType(rTarget);

	if not nodeTarget then
		return nHits, nWounds, nodeTarget, sTargetType;
	end

	if sTargetType == "charsheet" then
		nHits = tonumber(DB.getValue(nodeTarget, "hits.max", 0)) or 0;
		nWounds = tonumber(DB.getValue(nodeTarget, "hits.damage", 0)) or 0;
	else
		nHits = tonumber(DB.getValue(nodeTarget, "hits", 0)) or 0;
		nWounds = tonumber(DB.getValue(nodeTarget, "damage", 0)) or 0;
	end

	return nHits, nWounds, nodeTarget, sTargetType;
end

function getPCNodeFromTarget(rTarget, nodeTarget, sTargetType)
	local nodePC = getPCNodeFromActor(rTarget);
	if nodePC then
		return nodePC;
	end

	if nodeTarget then
		nodePC = getPCNodeFromCT(nodeTarget);
		if nodePC then
			return nodePC;
		end
	end

	if sTargetType == "charsheet" and nodeTarget then
		return nodeTarget;
	end

	return nil;
end

function getPCNodeFromActor(rActor)
	if not rActor then
		return nil;
	end

	local nodeCT = ActorManager.getCTNode(rActor);
	if nodeCT then
		local nodePC = getPCNodeFromCT(nodeCT);
		if nodePC then
			return nodePC;
		end
	end

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end

	local sClass, sRecord = DB.getValue(nodeActor, "link", "", "");
	if sClass == "charsheet" and sRecord ~= "" then
		return DB.findNode(sRecord);
	end

	return nil;
end

function getPCNodeFromCT(nodeCT)
	if not nodeCT then
		return nil;
	end

	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if sClass == "charsheet" and sRecord ~= "" then
		return DB.findNode(sRecord);
	end

	return nil;
end

function getActorLevelFromCT(nodeCT)
	if not nodeCT then
		return 0;
	end

	local nLevel = tonumber(DB.getValue(nodeCT, "level", 0)) or 0;
	if nLevel > 0 then
		return nLevel;
	end

	local nodePC = getPCNodeFromCT(nodeCT);
	if nodePC then
		nLevel = tonumber(DB.getValue(nodePC, "level", 0)) or 0;
		if nLevel > 0 then
			return nLevel;
		end
	end

	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if sRecord ~= "" then
		local nodeLinked = DB.findNode(sRecord);
		if nodeLinked then
			nLevel = tonumber(DB.getValue(nodeLinked, "level", 0)) or 0;
			if nLevel > 0 then
				return nLevel;
			end
		end
	end

	return 0;
end

function updateCombatXPDescByOpponent(nodePC, nodeOpponentCT)
	if not nodePC or not nodeOpponentCT then
		return;
	end

	local nPCLevel = tonumber(DB.getValue(nodePC, "level", 0)) or 0;
	local nOpponentLevel = getActorLevelFromCT(nodeOpponentCT);
	if nPCLevel <= 0 or nOpponentLevel <= 0 then
		return;
	end

	local nDiff = math.abs(nOpponentLevel - nPCLevel);
	if nDiff < 1 then
		nDiff = 1;
	end

	local nCurrent = tonumber(DB.getValue(nodePC, "combatxpdesc", 1)) or 1;
	if nCurrent < 1 then
		nCurrent = 1;
	end

	if nDiff > nCurrent then
		DB.setValue(nodePC, "combatxpdesc", "number", nDiff);
	end
end

function addXPValue(nodePC, sField, nDelta)
	if not nodePC or sField == "" or nDelta == 0 then
		return;
	end

	local nCurrent = DB.getValue(nodePC, sField, 0);
	DB.setValue(nodePC, sField, "number", nCurrent + nDelta);
end

function normalizeText(sValue)
	sValue = (sValue or ""):lower();
	sValue = sValue:gsub("%s+", " ");
	sValue = sValue:gsub("^%s+", "");
	sValue = sValue:gsub("%s+$", "");
	return sValue;
end

function getSkillDifficulty(rRoll)
	if rRoll.columnTitle and rRoll.columnTitle ~= "" then
		return rRoll.columnTitle;
	end
	if rRoll.difficultyName and rRoll.difficultyName ~= "" then
		return rRoll.difficultyName;
	end

	local sDesc = rRoll.sDesc or "";
	local sFound = sDesc:match("%- ([^%[]+) Difficulty");
	if sFound then
		return sFound;
	end

	return "";
end

function getMMDifficultyField(sDifficulty)
	local sKey = normalizeText(sDifficulty);
	return aMMDifficultyToField[sKey] or "";
end

function isSkillSuccess(rRoll)
	local nTotal = ActionsManager.total(rRoll) or 0;
	return nTotal > 0;
end

function isBaseCastingSuccess(rRoll)
	if not rRoll or not rRoll.aDice or not rRoll.aDice[1] then
		return false;
	end

	local nFirstDie = tonumber(rRoll.aDice[1].result) or 0;
	local nFailure = tonumber(rRoll.nFailure) or 0;
	return nFirstDie > nFailure;
end

function getSpellLevelField(nSpellLevel)
	if nSpellLevel < 1 then
		nSpellLevel = 1;
	elseif nSpellLevel > 11 then
		nSpellLevel = 11;
	end
	return aSpellLevelToField[nSpellLevel] or "";
end

function getCriticalSeverity(woundEffects, sDescription)
	local sSeverity = "";
	if type(woundEffects) == "table" then
		sSeverity = tostring(woundEffects.CriticalSeverity or "");
	end

	sSeverity = normalizeText(sSeverity);
	if sSeverity == "a" or sSeverity == "b" or sSeverity == "c" or sSeverity == "d" or sSeverity == "e" then
		return sSeverity;
	end

	local sDesc = normalizeText(sDescription);
	local sDescSeverity = sDesc:match("^([abcde])%s");
	if sDescSeverity then
		return sDescSeverity;
	end

	return "";
end

function getCriticalOutcome(nodeAttackerCT, nodeTarget, woundEffects, sDescription, bWasAlive, bNowDead)
	if nodeAttackerCT and nodeTarget and (DB.getPath(nodeAttackerCT) == DB.getPath(nodeTarget)) then
		return "self";
	end

	local sCritName = "";
	if type(woundEffects) == "table" then
		sCritName = normalizeText(woundEffects.CriticalName or "");
	end

	if sCritName == "super-large" or sCritName == "super large" then
		return "vlarge";
	end
	if sCritName == "large" then
		return "large";
	end

	if bWasAlive and bNowDead then
		return "solo";
	end

	local sDesc = normalizeText(sDescription);
	if hasWoundKey(woundEffects, "Unconscious") or sDesc:find("unconscious", 1, true) then
		return "unc";
	end
	if sDesc:find("down", 1, true) then
		return "down";
	end
	if hasWoundKey(woundEffects, "Stun") or sDesc:find("stun", 1, true) then
		return "stun";
	end

	return "norm";
end

function hasWoundKey(woundEffects, sBaseKey)
	if type(woundEffects) ~= "table" then
		return false;
	end
	if woundEffects[sBaseKey] then
		return true;
	end
	if woundEffects["Conditional" .. sBaseKey] then
		return true;
	end
	return false;
end

function getCriticalFieldName(sSeverity, sOutcome)
	if sSeverity == "" or sOutcome == "" then
		return "";
	end

	local aSuffix = {
		norm = "norm",
		unc = "unc",
		down = "down",
		stun = "stun",
		solo = "solo",
		large = "large",
		vlarge = "vlarge",
		self = "self",
	};

	local sPrefix = aSuffix[sOutcome];
	if not sPrefix then
		return "";
	end

	return sPrefix .. sSeverity;
end
