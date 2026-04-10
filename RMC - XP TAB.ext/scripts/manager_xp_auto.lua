-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOriginalAddWoundEffects;
local fOriginalApplyDamage;
local aPendingAttackerPCByTarget = {};
local aProcessedCombatEPKeys = {};
local aProcessedSeverityKeys = {};
local aProcessedCriticalMatrixKeys = {};
local aProcessedSkillEPKeys = {};
local aProcessedSpellEPKeys = {};
local aPendingSkillRollByActor = {};

function onInit()
	if not Session.IsHost then
		return;
	end

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

function onSkillPostRoll(rSource, a2, a3)
	local rRoll = a3 or a2;
	if not rRoll then
		return;
	end

	local nodeSourcePC = getPCNodeFromRoll(rSource, rRoll);
	if not nodeSourcePC then
		return;
	end

	local sSkillField = getSkillDifficultyField(rRoll);
	if sSkillField == "" then
		return;
	end

	setPendingSkillRoll(nodeSourcePC, sSkillField, rRoll.skillName, rRoll.sDesc);
end

function onBaseCastingPostRoll(rSource, a2, a3)
	local rRoll = a3 or a2;
	if not rRoll then
		return;
	end

	if not isBaseCastingSuccess(rRoll) then
		return;
	end

	local nodeSourcePC = getPCNodeFromRoll(rSource, rRoll);
	if not nodeSourcePC then
		return;
	end

	local nSpellLevel = tonumber(rRoll.nSpellLevel or 0) or 0;
	if nSpellLevel <= 0 then
		return;
	end

	local sSpellField = getSpellLevelFieldName(nSpellLevel);
	if sSpellField == "" then
		return;
	end

	local nDieResult = getRollPrimaryDieResult(rRoll);
	if isSpellEPProcessedRecently(nodeSourcePC, sSpellField, nSpellLevel, rRoll.sSpellNodeName, rRoll.sSpellListNodeName, nDieResult, rRoll.sDesc) then
		return;
	end

	addXPValue(nodeSourcePC, sSpellField, 1);
end

function onAddWoundEffectsWithXP(nodeTarget, woundEffects, description, ...)
	if not fOriginalAddWoundEffects then
		return;
	end

	local bIsApplyTrigger = (type(woundEffects) == "table") and (next(woundEffects) ~= nil);

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

	if bIsApplyTrigger then
		processCombatCriticalMatrix(nodeAttackerCT, nodeAttackerPC, nodeTarget, woundEffects, description, bWasAlive);
	end

	tryProcessPendingSkillEP(nodeAttackerCT, nodeTarget, description);
end

function processCombatCriticalMatrix(nodeAttackerCT, nodeAttackerPC, nodeTarget, woundEffects, sDescription, bWasAlive)
	if not nodeAttackerPC or type(woundEffects) ~= "table" then
		return;
	end

	local sSeverity = getCriticalSeverityFromEvent(woundEffects, sDescription);
	if sSeverity == "" then
		return;
	end

	local sOutcome = getCriticalMatrixOutcome(nodeAttackerCT, nodeTarget, woundEffects, sDescription, bWasAlive);
	if sOutcome == "" then
		return;
	end

	local sEventKey = getCriticalMatrixEventKey(nodeAttackerPC, nodeTarget, woundEffects, sDescription, sSeverity, sOutcome);
	if isCriticalMatrixProcessedRecently(sEventKey) then
		return;
	end

	local sField = getCriticalFieldName(sSeverity, sOutcome);
	if sField ~= "" then
		addXPValue(nodeAttackerPC, sField, 1);
	end
end

function getCriticalSeverityFromEvent(woundEffects, sDescription)
	if type(woundEffects) == "table" then
		local sSeverity = normalizeText(tostring(woundEffects.CriticalSeverity or ""));
		if sSeverity:match("^[abcde]$") then
			return sSeverity;
		end

		local sCode = tostring(woundEffects.CriticalCode or ""):upper();
		local sCodeSev = sCode:match("%d+([ABCDE])[A-Z]");
		if sCodeSev then
			return sCodeSev:lower();
		end
	end

	local sDesc = tostring(sDescription or ""):upper();
	local sDescSev = sDesc:match("%d+([ABCDE])[A-Z]");
	if not sDescSev then
		sDescSev = sDesc:match("([ABCDE])%s+CRITICAL");
	end
	if sDescSev then
		return sDescSev:lower();
	end

	return "";
end

function getCriticalMatrixOutcome(nodeAttackerCT, nodeTarget, woundEffects, sDescription, bWasAlive)
	local sDesc = normalizeText(sDescription or "");
	local sSizeOutcome = getTargetSizeOutcome(nodeTarget);
	if sSizeOutcome ~= "" then
		return sSizeOutcome;
	end

	if nodeAttackerCT and nodeTarget and DB.getPath(nodeAttackerCT) == DB.getPath(nodeTarget) then
		return "self";
	end

	if bWasAlive and isTargetNowDead(nodeTarget) then
		return "solo";
	end

	if hasTargetEffectOrCondition(nodeTarget, { "Unconscious", "Dying", "Dead" })
		or isTargetInEffectState(nodeTarget, { "unconscious", "dying", "dead" })
		or hasWoundFlag(woundEffects, "Unconscious") or hasWoundFlag(woundEffects, "Dying")
		or hasAnyWoundText(woundEffects, { "unconscious", "dying" })
		or sDesc:find("unconscious", 1, true) or sDesc:find("dying", 1, true) then
		return "unc";
	end

	if hasTargetEffectOrCondition(nodeTarget, { "Prone", "Kneeling" })
		or isTargetInEffectState(nodeTarget, { "prone", "kneeling", "down" })
		or hasAnyWoundText(woundEffects, { "down", "prone", "kneeling" })
		or sDesc:find("down", 1, true) or sDesc:find("prone", 1, true) or sDesc:find("kneeling", 1, true) then
		return "down";
	end

	if hasTargetEffectOrCondition(nodeTarget, { "Stun", "Stunned", "NoParry", "MustParry" })
		or isTargetInEffectState(nodeTarget, { "stun", "no parry", "must parry", "mustparry" })
		or hasWoundFlag(woundEffects, "Stun") or hasWoundFlag(woundEffects, "NoParry") or hasWoundFlag(woundEffects, "MustParry")
		or hasAnyWoundText(woundEffects, { "stun", "no parry", "must parry", "mustparry" })
		or sDesc:find("stun", 1, true) or sDesc:find("no parry", 1, true) or sDesc:find("must parry", 1, true) then
		return "stun";
	end

	return "norm";
end

function getTargetSizeOutcome(nodeTarget)
	if not nodeTarget then
		return "";
	end

	local sSize = normalizeText(DB.getValue(nodeTarget, "size", ""));
	if sSize == "" then
		return "";
	end

	if sSize == "5" or sSize == "huge" or sSize == "super large" or sSize == "super-large" or sSize == "superlarge" then
		return "vlarge";
	end

	if sSize == "4" or sSize == "large" then
		return "large";
	end

	return "";
end

function isTargetInEffectState(nodeTarget, aNeedles)
	if not nodeTarget or type(aNeedles) ~= "table" then
		return false;
	end

	for _, nodeEffect in pairs(DB.getChildren(nodeTarget, "effects")) do
		local sLabel = normalizeText(DB.getValue(nodeEffect, "label", ""));
		if sLabel ~= "" then
			for _, sNeedle in ipairs(aNeedles) do
				if sLabel:find(sNeedle, 1, true) then
					return true;
				end
			end
		end
	end

	return false;
end

function hasTargetEffectOrCondition(nodeTarget, aNames)
	if not nodeTarget or type(aNames) ~= "table" then
		return false;
	end

	local rTarget = ActorManager.resolveActor(nodeTarget);
	if not rTarget then
		return false;
	end

	for _, sName in ipairs(aNames) do
		if type(sName) == "string" and sName ~= "" then
			if EffectManagerRMC and EffectManagerRMC.hasEffect and EffectManagerRMC.hasEffect(rTarget, sName) then
				return true;
			end
			if EffectManager and EffectManager.hasCondition and EffectManager.hasCondition(rTarget, sName) then
				return true;
			end
		end
	end

	return false;
end

function hasWoundFlag(woundEffects, sFlag)
	if type(woundEffects) ~= "table" or sFlag == "" then
		return false;
	end
	return woundEffects[sFlag] ~= nil or woundEffects["Conditional" .. sFlag] ~= nil;
end

function hasAnyWoundText(woundEffects, aNeedles)
	if type(woundEffects) ~= "table" or type(aNeedles) ~= "table" then
		return false;
	end

	for _, v in pairs(woundEffects) do
		if type(v) == "string" then
			local sText = normalizeText(v);
			for _, sNeedle in ipairs(aNeedles) do
				if sText:find(sNeedle, 1, true) then
					return true;
				end
			end
		end
	end

	return false;
end

function isTargetNowDead(nodeTarget)
	if not nodeTarget then
		return false;
	end

	local nHits = tonumber(DB.getValue(nodeTarget, "hits", 0)) or 0;
	if nHits <= 0 then
		return false;
	end

	local nDamage = tonumber(DB.getValue(nodeTarget, "damage", 0)) or 0;
	return nDamage >= nHits;
end

function getCriticalMatrixEventKey(nodeAttackerPC, nodeTarget, woundEffects, sDescription, sSeverity, sOutcome)
	local sAttackerPath = DB.getPath(nodeAttackerPC) or "";
	local sTargetPath = "";
	if nodeTarget then
		sTargetPath = DB.getPath(nodeTarget) or "";
	end

	local sCode = "";
	local sName = "";
	if type(woundEffects) == "table" then
		sCode = tostring(woundEffects.CriticalCode or ""):upper();
		sName = normalizeText(tostring(woundEffects.CriticalName or ""));
	end

	local sDesc = normalizeText(sDescription or "");
	return table.concat({ sAttackerPath, sTargetPath, sSeverity or "", sCode, sName, sOutcome or "", sDesc }, "|");
end

function isCriticalMatrixProcessedRecently(sEventKey)
	if sEventKey == "" then
		return false;
	end

	local nNow = os.time() or 0;
	for sKey, nTimestamp in pairs(aProcessedCriticalMatrixKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedCriticalMatrixKeys[sKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedCriticalMatrixKeys[sEventKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedCriticalMatrixKeys[sEventKey] = nNow;
	return false;
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

	local bNowDead = false;
	if nHitsAfter > 0 then
		bNowDead = (nWoundsAfter >= nHitsAfter);
	end
	local bKill = bWasAlive and bNowDead;

	local nodeTargetPC = getPCNodeFromTarget(rTarget, nodeTarget, sTargetType);

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

	if nodeTargetPC and not isCombatEPProcessedRecently(nodeTargetPC, "hitstaken", nAppliedDamage, bKill) then
		addXPValue(nodeTargetPC, "hitstaken", nAppliedDamage);
	end

	if nodeSourcePC and not isCombatEPProcessedRecently(nodeSourcePC, "hitsgiven", nAppliedDamage, bKill) then
		addXPValue(nodeSourcePC, "hitsgiven", nAppliedDamage);
	end

	if nodeSourcePC and bKill and not isCombatEPProcessedRecently(nodeSourcePC, "foekill", 1, bKill) then
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

	local sActorRecordType = ActorManager.getRecordType(rActor) or "";
	if sActorRecordType == "charsheet" then
		return nodeActor;
	end

	local sActorPath = DB.getPath(nodeActor) or "";
	if sActorPath:match("^charsheet%.") then
		return nodeActor;
	end

	local sClass, sRecord = DB.getValue(nodeActor, "link", "", "");
	if sClass == "charsheet" and sRecord ~= "" then
		return DB.findNode(sRecord);
	end

	return nil;
end

function getPCNodeFromRoll(rSource, rRoll)
	local nodePC = getPCNodeFromActor(rSource);
	if nodePC then
		return nodePC;
	end

	if type(rRoll) ~= "table" then
		return nil;
	end

	local aCandidatePaths = {
		rRoll.nodeActorName,
		rRoll.nodeAttackerName,
		rRoll.targetNodeName,
	};

	for _, sPath in ipairs(aCandidatePaths) do
		if type(sPath) == "string" and sPath ~= "" then
			local nodeCandidate = DB.findNode(sPath);
			nodePC = getPCNodeFromNode(nodeCandidate);
			if nodePC then
				return nodePC;
			end
		end
	end

	return nil;
end

function getPCNodeFromNode(nodeValue)
	if not nodeValue then
		return nil;
	end

	local sPath = DB.getPath(nodeValue) or "";
	if sPath:match("^charsheet%.") then
		return nodeValue;
	end

	local nodePC = getPCNodeFromCT(nodeValue);
	if nodePC then
		return nodePC;
	end

	local sClass, sRecord = DB.getValue(nodeValue, "link", "", "");
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

function getRollPrimaryDieResult(rRoll)
	if not rRoll then
		return 0;
	end

	if rRoll.aDice and rRoll.aDice[1] and rRoll.aDice[1].result then
		return tonumber(rRoll.aDice[1].result) or 0;
	end

	if rRoll.unmodified then
		return tonumber(rRoll.unmodified) or 0;
	end

	if rRoll.dieResult then
		return tonumber(rRoll.dieResult) or 0;
	end

	return 0;
end

function isBaseCastingSuccess(rRoll)
	if type(rRoll) ~= "table" then
		return false;
	end

	local nFailure = tonumber(rRoll.nFailure);
	if not nFailure then
		return false;
	end

	if not (rRoll.aDice and rRoll.aDice[1] and rRoll.aDice[1].result) then
		return false;
	end

	local nFirstDie = tonumber(rRoll.aDice[1].result) or 0;
	return nFirstDie > nFailure;
end

function getSkillDifficultyField(rRoll)
	if type(rRoll) ~= "table" then
		return "";
	end

	-- Priority: explicit difficulty modifier chosen by actor, then roll fields, then text fallback.
	local sDifficulty = extractDifficultyFromModifierTable(rRoll.modifiers);
	if sDifficulty == "" then
		sDifficulty = normalizeText(rRoll.difficultyName or rRoll.columnTitle or "");
	end
	if sDifficulty == "" then
		sDifficulty = extractDifficultyFromText(rRoll.sDesc or "");
	end
	if sDifficulty == "" and type(rRoll.modifiers) == "string" then
		sDifficulty = extractDifficultyFromText(rRoll.modifiers);
	end
	if sDifficulty == "" then
		return "medium";
	end

	if sDifficulty:find("sheer folly", 1, true) or sDifficulty:find("sheerfolly", 1, true) then
		return "sheerfolly";
	end
	if sDifficulty:find("extremely hard", 1, true) or sDifficulty:find("extremelyhard", 1, true) then
		return "extremelyhard";
	end
	if sDifficulty:find("very hard", 1, true) or sDifficulty:find("veryhard", 1, true) then
		return "veryhard";
	end
	if sDifficulty:find("routine", 1, true) then
		return "routine";
	end
	if sDifficulty:find("easy", 1, true) then
		return "easy";
	end
	if sDifficulty:find("light", 1, true) then
		return "light";
	end
	if sDifficulty:find("hard", 1, true) then
		return "hard";
	end
	if sDifficulty:find("absurd", 1, true) then
		return "absurd";
	end
	if sDifficulty:find("medium", 1, true) then
		return "medium";
	end

	return "";
end

function extractDifficultyFromText(sText)
	local sNormalized = normalizeText(sText or "");
	if sNormalized == "" then
		return "";
	end

	if sNormalized:find("sheer folly", 1, true) or sNormalized:find("sheerfolly", 1, true) then
		return "sheerfolly";
	end
	if sNormalized:find("extremely hard", 1, true) or sNormalized:find("extremelyhard", 1, true) then
		return "extremelyhard";
	end
	if sNormalized:find("very hard", 1, true) or sNormalized:find("veryhard", 1, true) then
		return "veryhard";
	end
	if sNormalized:find("routine", 1, true) then
		return "routine";
	end
	if sNormalized:find("easy", 1, true) then
		return "easy";
	end
	if sNormalized:find("light", 1, true) then
		return "light";
	end
	if sNormalized:find("absurd", 1, true) then
		return "absurd";
	end
	if sNormalized:find("hard", 1, true) then
		return "hard";
	end
	if sNormalized:find("medium", 1, true) then
		return "medium";
	end

	return "";
end

function extractDifficultyFromModifierTable(vModifiers)
	if not Utilities or not Utilities.modifiersStringToTable or type(vModifiers) ~= "string" or vModifiers == "" then
		return "";
	end

	local aModifiers = Utilities.modifiersStringToTable(vModifiers);
	if type(aModifiers) ~= "table" then
		return "";
	end

	for _, rMod in ipairs(aModifiers) do
		local sDesc = "";
		if type(rMod) == "table" then
			sDesc = normalizeText(rMod.description or "");
		end
		local sFound = extractDifficultyFromText(sDesc);
		if sFound ~= "" then
			return sFound;
		end
	end

	return "";
end

function setPendingSkillRoll(nodePC, sSkillField, sSkillName, sDescription)
	if not nodePC or sSkillField == "" then
		return;
	end

	local sActorPath = DB.getPath(nodePC) or "";
	if sActorPath == "" then
		return;
	end

	aPendingSkillRollByActor[sActorPath] = {
		field = sSkillField,
		skill = normalizeText(sSkillName or ""),
		desc = normalizeText(sDescription or ""),
		time = os.time() or 0,
	};
end

function tryProcessPendingSkillEP(nodeAttackerCT, nodeTarget, sDescription)
	if not nodeAttackerCT or not nodeTarget then
		return;
	end

	local sAttackerPath = DB.getPath(nodeAttackerCT) or "";
	local sTargetPath = DB.getPath(nodeTarget) or "";
	if sAttackerPath == "" or sTargetPath == "" or sAttackerPath ~= sTargetPath then
		return;
	end

	local nodeAttackerPC = getPCNodeFromCT(nodeAttackerCT);
	if not nodeAttackerPC then
		return;
	end

	local sActorPath = DB.getPath(nodeAttackerPC) or "";
	local tPending = aPendingSkillRollByActor[sActorPath];
	if not tPending then
		return;
	end

	local nNow = os.time() or 0;
	if (nNow - (tonumber(tPending.time) or 0)) > 30 then
		aPendingSkillRollByActor[sActorPath] = nil;
		return;
	end

	if not isSkillResolutionSuccessful(sDescription) then
		aPendingSkillRollByActor[sActorPath] = nil;
		return;
	end

	if isSkillEPProcessedRecently(nodeAttackerPC, tPending.field, tPending.skill, 0, sDescription or "") then
		aPendingSkillRollByActor[sActorPath] = nil;
		return;
	end

	addXPValue(nodeAttackerPC, tPending.field, 1);
	aPendingSkillRollByActor[sActorPath] = nil;
end

function isSkillResolutionSuccessful(sDescription)
	local sText = normalizeText(sDescription or "");
	if sText == "" then
		return false;
	end

	if sText:find("failure", 1, true) or sText:find("fail", 1, true) or sText:find("fumble", 1, true) then
		return false;
	end

	if sText:find("partial success", 1, true) then
		return false;
	end

	if sText:find("total success", 1, true) or sText:find("absolute success", 1, true) then
		return true;
	end

	if sText:find("success", 1, true) then
		return true;
	end

	return false;
end

function getSpellLevelFieldName(nSpellLevel)
	nSpellLevel = tonumber(nSpellLevel or 0) or 0;
	if nSpellLevel <= 0 then
		return "";
	end

	local aSpellFieldByLevel = {
		"spellone",
		"spelltwo",
		"spellthree",
		"spellfour",
		"spellfive",
		"spellsix",
		"spellseven",
		"spelleight",
		"spellnine",
		"spellten",
	};

	if nSpellLevel <= #aSpellFieldByLevel then
		return aSpellFieldByLevel[nSpellLevel];
	end

	return "spelleleven";
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

function isCombatEPProcessedRecently(nodePC, sField, nValue, bKill)
	if not nodePC or sField == "" then
		return false;
	end

	local sPath = DB.getPath(nodePC) or "";
	local sKey = table.concat({ sPath, sField, tostring(nValue or 0), bKill and "1" or "0" }, "|");

	local nNow = os.time() or 0;
	for sExistingKey, nTimestamp in pairs(aProcessedCombatEPKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedCombatEPKeys[sExistingKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedCombatEPKeys[sKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedCombatEPKeys[sKey] = nNow;
	return false;
end

function isSeverityProcessedRecently(nodePC, sField, sDescription)
	if not nodePC or sField == "" then
		return false;
	end

	local sPath = DB.getPath(nodePC) or "";
	local sDesc = normalizeText(sDescription or "");
	local sKey = table.concat({ sPath, sField, sDesc }, "|");

	local nNow = os.time() or 0;
	for sExistingKey, nTimestamp in pairs(aProcessedSeverityKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedSeverityKeys[sExistingKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedSeverityKeys[sKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedSeverityKeys[sKey] = nNow;
	return false;
end

function isSkillEPProcessedRecently(nodePC, sField, sSkillName, nDieResult, sDescription)
	if not nodePC or sField == "" then
		return false;
	end

	local sPath = DB.getPath(nodePC) or "";
	local sName = normalizeText(sSkillName or "");
	local sDesc = normalizeText(sDescription or "");
	local sKey = table.concat({ sPath, sField, sName, tostring(nDieResult or 0), sDesc }, "|");

	local nNow = os.time() or 0;
	for sExistingKey, nTimestamp in pairs(aProcessedSkillEPKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedSkillEPKeys[sExistingKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedSkillEPKeys[sKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedSkillEPKeys[sKey] = nNow;
	return false;
end

function isSpellEPProcessedRecently(nodePC, sField, nSpellLevel, sSpellNodeName, sSpellListNodeName, nDieResult, sDescription)
	if not nodePC or sField == "" then
		return false;
	end

	local sPath = DB.getPath(nodePC) or "";
	local sSpellPath = tostring(sSpellNodeName or "");
	local sListPath = tostring(sSpellListNodeName or "");
	local sDesc = normalizeText(sDescription or "");
	local sKey = table.concat({ sPath, sField, tostring(nSpellLevel or 0), sSpellPath, sListPath, tostring(nDieResult or 0), sDesc }, "|");

	local nNow = os.time() or 0;
	for sExistingKey, nTimestamp in pairs(aProcessedSpellEPKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedSpellEPKeys[sExistingKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedSpellEPKeys[sKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedSpellEPKeys[sKey] = nNow;
	return false;
end

