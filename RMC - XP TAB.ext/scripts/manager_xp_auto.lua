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

local aMMDifficultyParseOrder = {
	"extremely hard",
	"extremelyhard",
	"sheer folly",
	"sheerfolly",
	"very hard",
	"veryhard",
	"routine",
	"medium",
	"absurd",
	"light",
	"easy",
	"hard",
};

local aSpellLevelToField = {
	"spellone", "spelltwo", "spellthree", "spellfour", "spellfive", "spellsix", "spellseven", "spelleight", "spellnine", "spellten", "spelleleven"
};

local fOriginalAddWoundEffects;
local fOriginalApplyDamage;
local fOriginalNotifyResolveSkill;
local aPendingAttackerPCByTarget = {};
local aProcessedSkillRollKeys = {};
local aSkillStateByKey = {};
local aProcessedBaseCastingRollKeys = {};
local aBaseCastingStateByKey = {};
local aProcessedCombatEPKeys = {};
local aCombatEPStateByKey = {};
local aProcessedSeverityKeys = {};
local aSeverityStateByKey = {};

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

	if ActionSkill and ActionSkill.notifyResolveSkill then
		fOriginalNotifyResolveSkill = ActionSkill.notifyResolveSkill;
		ActionSkill.notifyResolveSkill = onNotifyResolveSkillWithXP;
	end
end

function onNotifyResolveSkillWithXP(msgRoll)
	if fOriginalNotifyResolveSkill then
		fOriginalNotifyResolveSkill(msgRoll);
	end

	processSkillRollXP(nil, nil, msgRoll);
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
	processSkillRollXP(rSource, rTarget, rRoll);
end

function processSkillRollXP(rSource, rTarget, rRoll)
	if not rRoll then
		return;
	end

	local sStateKey = buildSkillStateKey(rSource, rRoll);

	if not isSkillSuccess(rRoll) then
		return;
	end

	local nodePC = getPCNodeFromActor(rSource);
	if not nodePC then
		nodePC = getPCNodeFromRoll(rRoll);
	end

	local sDifficulty = getSkillDifficulty(rRoll);
	local sField = getMMDifficultyField(sDifficulty);

	updateSkillState(sStateKey, nodePC, sDifficulty, sField);

	if not nodePC then
		nodePC = getPCNodeFromSkillState(sStateKey);
	end
	if sField == "" then
		sField = getSkillFieldFromState(sStateKey);
	end

	if not nodePC or sField == "" then
		return;
	end

	if isSkillRollProcessedRecently(rRoll, nodePC, sField) then
		return;
	end

	addXPValue(nodePC, sField, 1);
end

function buildSkillStateKey(rSource, rRoll)
	local sActorPath = "";
	if rSource then
		local nodeActor = ActorManager.getCreatureNode(rSource);
		if nodeActor then
			sActorPath = DB.getPath(nodeActor) or "";
		end
	end
	if sActorPath == "" then
		sActorPath = tostring(rRoll.nodeActorName or rRoll.nodeAttackerName or rRoll.nodeActor or "");
	end

	local sSkill = normalizeText(tostring(rRoll.skillName or ""));
	local sResults = tostring(rRoll.sResults or "");
	local sRollTotal = tostring(ActionsManager.total(rRoll) or "");

	if sActorPath == "" and sSkill == "" and sResults == "" and sRollTotal == "" then
		return "";
	end

	return table.concat({ sActorPath, sSkill, sResults, sRollTotal }, "|");
end

function purgeSkillState()
	local nNow = os.time() or 0;
	for sKey, tState in pairs(aSkillStateByKey) do
		local nLast = tonumber(tState.nTimestamp) or 0;
		if nLast <= 0 or (nNow - nLast) > 30 then
			aSkillStateByKey[sKey] = nil;
		end
	end
end

function updateSkillState(sStateKey, nodePC, sDifficulty, sField)
	if sStateKey == "" then
		return;
	end

	purgeSkillState();

	local tState = aSkillStateByKey[sStateKey] or {};
	if nodePC then
		tState.sPCPath = DB.getPath(nodePC) or "";
	end
	if sDifficulty and sDifficulty ~= "" then
		tState.sDifficulty = sDifficulty;
	end
	if sField and sField ~= "" then
		tState.sField = sField;
	end
	tState.nTimestamp = os.time() or 0;

	aSkillStateByKey[sStateKey] = tState;
end

function getPCNodeFromSkillState(sStateKey)
	if sStateKey == "" then
		return nil;
	end

	local tState = aSkillStateByKey[sStateKey];
	if not tState then
		return nil;
	end

	local sPCPath = tState.sPCPath or "";
	if sPCPath == "" then
		return nil;
	end

	return DB.findNode(sPCPath);
end

function getSkillFieldFromState(sStateKey)
	if sStateKey == "" then
		return "";
	end

	local tState = aSkillStateByKey[sStateKey];
	if not tState then
		return "";
	end

	return tState.sField or "";
end

function buildBaseCastingStateKey(rSource, rRoll)
	local sActorPath = "";
	if rSource then
		local nodeActor = ActorManager.getCreatureNode(rSource);
		if nodeActor then
			sActorPath = DB.getPath(nodeActor) or "";
		end
	end
	if sActorPath == "" then
		sActorPath = tostring(rRoll.nodeActorName or rRoll.nodeAttackerName or rRoll.nodeActor or "");
	end

	local sSpellList = normalizeText(tostring(rRoll.sSpellList or ""));
	local sSpellName = normalizeText(tostring(rRoll.sSpellName or ""));
	local sResults = tostring(rRoll.sResults or "");
	local sRollTotal = tostring(ActionsManager.total(rRoll) or "");

	if sActorPath == "" and sSpellList == "" and sSpellName == "" and sResults == "" and sRollTotal == "" then
		return "";
	end

	return table.concat({ sActorPath, sSpellList, sSpellName, sResults, sRollTotal }, "|");
end

function purgeBaseCastingState()
	local nNow = os.time() or 0;
	for sKey, tState in pairs(aBaseCastingStateByKey) do
		local nLast = tonumber(tState.nTimestamp) or 0;
		if nLast <= 0 or (nNow - nLast) > 30 then
			aBaseCastingStateByKey[sKey] = nil;
		end
	end
end

function updateBaseCastingState(sStateKey, nodePC, nSpellLevel, sField)
	if sStateKey == "" then
		return;
	end

	purgeBaseCastingState();

	local tState = aBaseCastingStateByKey[sStateKey] or {};
	if nodePC then
		tState.sPCPath = DB.getPath(nodePC) or "";
	end
	if nSpellLevel and nSpellLevel > 0 then
		tState.nSpellLevel = nSpellLevel;
	end
	if sField and sField ~= "" then
		tState.sField = sField;
	end
	tState.nTimestamp = os.time() or 0;

	aBaseCastingStateByKey[sStateKey] = tState;
end

function getPCNodeFromBaseCastingState(sStateKey)
	if sStateKey == "" then
		return nil;
	end

	local tState = aBaseCastingStateByKey[sStateKey];
	if not tState then
		return nil;
	end

	local sPCPath = tState.sPCPath or "";
	if sPCPath == "" then
		return nil;
	end

	return DB.findNode(sPCPath);
end

function getBaseCastingFieldFromState(sStateKey)
	if sStateKey == "" then
		return "";
	end

	local tState = aBaseCastingStateByKey[sStateKey];
	if not tState then
		return "";
	end

	return tState.sField or "";
end

function buildBaseCastingRollKey(rRoll, nodePC, sField)
	if not rRoll then
		return "";
	end

	local sActorPath = tostring(rRoll.nodeActorName or rRoll.nodeAttackerName or rRoll.nodeActor or "");
	if sActorPath == "" and nodePC then
		sActorPath = DB.getPath(nodePC) or "";
	end
	local sSpellList = normalizeText(tostring(rRoll.sSpellList or ""));
	local sSpellName = normalizeText(tostring(rRoll.sSpellName or ""));
	local sFieldKey = normalizeText(tostring(sField or ""));
	local sResults = tostring(rRoll.sResults or "");
	local sRollTotal = tostring(ActionsManager.total(rRoll) or "");

	if sActorPath == "" and sSpellList == "" and sSpellName == "" and sFieldKey == "" and sResults == "" and sRollTotal == "" then
		return "";
	end

	return table.concat({ sActorPath, sSpellList, sSpellName, sFieldKey, sResults, sRollTotal }, "|");
end

function isBaseCastingRollProcessedRecently(rRoll, nodePC, sField)
	local sKey = buildBaseCastingRollKey(rRoll, nodePC, sField);
	if sKey == "" then
		return false;
	end

	local nNow = os.time() or 0;
	for sExistingKey, nTimestamp in pairs(aProcessedBaseCastingRollKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedBaseCastingRollKeys[sExistingKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedBaseCastingRollKeys[sKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedBaseCastingRollKeys[sKey] = nNow;
	return false;
end

function buildCombatEPStateKey(rSource, rTarget, nodeTarget, nAppliedDamage, bKill)
	local sSourcePath = "";
	if rSource then
		sSourcePath = ActorManager.getCreatureNodeName(rSource) or "";
	end

	local sTargetPath = "";
	if rTarget then
		sTargetPath = ActorManager.getCreatureNodeName(rTarget) or "";
	end
	if sTargetPath == "" and nodeTarget then
		sTargetPath = DB.getPath(nodeTarget) or "";
	end

	local sDamage = tostring(nAppliedDamage or 0);
	local sKill = "0";
	if bKill then
		sKill = "1";
	end

	if sSourcePath == "" and sTargetPath == "" and sDamage == "0" and sKill == "0" then
		return "";
	end

	return table.concat({ sSourcePath, sTargetPath, sDamage, sKill }, "|");
end

function purgeCombatEPState()
	local nNow = os.time() or 0;
	for sKey, tState in pairs(aCombatEPStateByKey) do
		local nLast = tonumber(tState.nTimestamp) or 0;
		if nLast <= 0 or (nNow - nLast) > 30 then
			aCombatEPStateByKey[sKey] = nil;
		end
	end
end

function updateCombatEPState(sStateKey, nodeSourcePC, nodeTargetPC, nAppliedDamage, bKill)
	if sStateKey == "" then
		return;
	end

	purgeCombatEPState();

	local tState = aCombatEPStateByKey[sStateKey] or {};
	if nodeSourcePC then
		tState.sSourcePCPath = DB.getPath(nodeSourcePC) or "";
	end
	if nodeTargetPC then
		tState.sTargetPCPath = DB.getPath(nodeTargetPC) or "";
	end
	tState.nAppliedDamage = tonumber(nAppliedDamage) or 0;
	tState.bKill = bKill and true or false;
	tState.nTimestamp = os.time() or 0;

	aCombatEPStateByKey[sStateKey] = tState;
end

function getCombatEPStateNodePC(sStateKey, bSource)
	if sStateKey == "" then
		return nil;
	end

	local tState = aCombatEPStateByKey[sStateKey];
	if not tState then
		return nil;
	end

	local sPath = "";
	if bSource then
		sPath = tState.sSourcePCPath or "";
	else
		sPath = tState.sTargetPCPath or "";
	end

	if sPath == "" then
		return nil;
	end

	return DB.findNode(sPath);
end

function isCombatEPProcessedRecently(sStateKey, sField, nodePC)
	if sStateKey == "" or sField == "" then
		return false;
	end

	local sPath = "";
	if nodePC then
		sPath = DB.getPath(nodePC) or "";
	end
	local sKey = table.concat({ sStateKey, sField, sPath }, "|");

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

function buildSeverityStateKey(nodeAttackerCT, nodeTarget, sDescription)
	local sAttackerPath = "";
	if nodeAttackerCT then
		sAttackerPath = DB.getPath(nodeAttackerCT) or "";
	end

	local sTargetPath = "";
	if nodeTarget then
		sTargetPath = DB.getPath(nodeTarget) or "";
	end

	local sDesc = normalizeText(sDescription or "");
	if sAttackerPath == "" and sTargetPath == "" and sDesc == "" then
		return "";
	end

	return table.concat({ sAttackerPath, sTargetPath, sDesc }, "|");
end

function purgeSeverityState()
	local nNow = os.time() or 0;
	for sKey, tState in pairs(aSeverityStateByKey) do
		local nLast = tonumber(tState.nTimestamp) or 0;
		if nLast <= 0 or (nNow - nLast) > 30 then
			aSeverityStateByKey[sKey] = nil;
		end
	end
end

function updateSeverityState(sStateKey, nodeAttackerPC, sCritField)
	if sStateKey == "" then
		return;
	end

	purgeSeverityState();

	local tState = aSeverityStateByKey[sStateKey] or {};
	if nodeAttackerPC then
		tState.sAttackerPCPath = DB.getPath(nodeAttackerPC) or "";
	end
	if sCritField and sCritField ~= "" then
		tState.sCritField = sCritField;
	end
	tState.nTimestamp = os.time() or 0;

	aSeverityStateByKey[sStateKey] = tState;
end

function getSeverityStateNodePC(sStateKey)
	if sStateKey == "" then
		return nil;
	end

	local tState = aSeverityStateByKey[sStateKey];
	if not tState then
		return nil;
	end

	local sPath = tState.sAttackerPCPath or "";
	if sPath == "" then
		return nil;
	end

	return DB.findNode(sPath);
end

function getSeverityFieldFromState(sStateKey)
	if sStateKey == "" then
		return "";
	end

	local tState = aSeverityStateByKey[sStateKey];
	if not tState then
		return "";
	end

	return tState.sCritField or "";
end

function isSeverityProcessedRecently(sStateKey, nodePC, sField)
	if sStateKey == "" or sField == "" then
		return false;
	end

	local sPath = "";
	if nodePC then
		sPath = DB.getPath(nodePC) or "";
	end
	local sKey = table.concat({ sStateKey, sPath, sField }, "|");

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

function onBaseCastingPostRoll(rSource, rTarget, rRoll)
	if not rRoll then
		return;
	end

	local sStateKey = buildBaseCastingStateKey(rSource, rRoll);

	if not isBaseCastingSuccess(rRoll) then
		return;
	end

	local nodePC = getPCNodeFromActor(rSource);
	if not nodePC then
		nodePC = getPCNodeFromRoll(rRoll);
	end

	local nSpellLevel = tonumber(rRoll.nSpellLevel) or 0;
	if nSpellLevel <= 0 then
		nSpellLevel = 1;
	end

	local sField = getSpellLevelField(nSpellLevel);

	updateBaseCastingState(sStateKey, nodePC, nSpellLevel, sField);

	if not nodePC then
		nodePC = getPCNodeFromBaseCastingState(sStateKey);
	end
	if sField == "" then
		sField = getBaseCastingFieldFromState(sStateKey);
	end

	if not nodePC or sField == "" then
		return;
	end

	if isBaseCastingRollProcessedRecently(rRoll, nodePC, sField) then
		return;
	end

	addXPValue(nodePC, sField, 1);
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
	local sSeverityStateKey = buildSeverityStateKey(nodeAttackerCT, nodeTarget, description);

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

	local sCritSeverity = getCriticalSeverity(woundEffects, description);
	local sCritField = "";
	if sCritSeverity ~= "" then
		local sCritOutcome = getCriticalOutcome(nodeAttackerCT, nodeTarget, woundEffects, description, bWasAlive, bNowDead);
		sCritField = getCriticalFieldName(sCritSeverity, sCritOutcome);
	end

	updateSeverityState(sSeverityStateKey, nodeAttackerPC, sCritField);

	if not nodeAttackerPC then
		nodeAttackerPC = getSeverityStateNodePC(sSeverityStateKey);
	end
	if sCritField == "" then
		sCritField = getSeverityFieldFromState(sSeverityStateKey);
	end

	if nodeAttackerPC and sCritField ~= "" and not isSeverityProcessedRecently(sSeverityStateKey, nodeAttackerPC, sCritField) then
		addXPValue(nodeAttackerPC, sCritField, 1);
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

	local bNowDead = false;
	if nHitsAfter > 0 then
		bNowDead = (nWoundsAfter >= nHitsAfter);
	end
	local bKill = bWasAlive and bNowDead;

	local sCombatStateKey = buildCombatEPStateKey(rSource, rTarget, nodeTarget, nAppliedDamage, bKill);

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

	updateCombatEPState(sCombatStateKey, nodeSourcePC, nodeTargetPC, nAppliedDamage, bKill);

	if not nodeTargetPC then
		nodeTargetPC = getCombatEPStateNodePC(sCombatStateKey, false);
	end
	if not nodeSourcePC then
		nodeSourcePC = getCombatEPStateNodePC(sCombatStateKey, true);
	end

	if nodeTargetPC and not isCombatEPProcessedRecently(sCombatStateKey, "hitstaken", nodeTargetPC) then
		addXPValue(nodeTargetPC, "hitstaken", nAppliedDamage);
	end

	if nodeSourcePC and not isCombatEPProcessedRecently(sCombatStateKey, "hitsgiven", nodeSourcePC) then
		addXPValue(nodeSourcePC, "hitsgiven", nAppliedDamage);
	end

	if nodeSourcePC and bKill and not isCombatEPProcessedRecently(sCombatStateKey, "foekill", nodeSourcePC) then
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

function getPCNodeFromRoll(rRoll)
	if not rRoll then
		return nil;
	end

	local aNodeFields = {
		rRoll.nodeActorName,
		rRoll.nodeAttackerName,
		rRoll.nodeActor,
	};

	for _, sPath in ipairs(aNodeFields) do
		if sPath and sPath ~= "" then
			local node = DB.findNode(sPath);
			if node then
				local sNodePath = DB.getPath(node) or "";
				if sNodePath:match("^charsheet%.") then
					return node;
				end

				local sClass, sRecord = DB.getValue(node, "link", "", "");
				if sClass == "charsheet" and sRecord ~= "" then
					return DB.findNode(sRecord);
				end
			end
		end
	end

	return nil;
end

function buildSkillRollKey(rRoll, nodePC, sField)
	if not rRoll then
		return "";
	end

	local sActorPath = tostring(rRoll.nodeActorName or rRoll.nodeAttackerName or rRoll.nodeActor or "");
	if sActorPath == "" and nodePC then
		sActorPath = DB.getPath(nodePC) or "";
	end
	local sSkill = normalizeText(tostring(rRoll.skillName or ""));
	local sDifficulty = normalizeText(getSkillDifficulty(rRoll));
	local sFieldKey = normalizeText(tostring(sField or ""));
	local sResults = tostring(rRoll.sResults or "");
	local sRollTotal = tostring(ActionsManager.total(rRoll) or "");

	if sActorPath == "" and sSkill == "" and sDifficulty == "" and sFieldKey == "" and sResults == "" and sRollTotal == "" then
		return "";
	end

	return table.concat({ sActorPath, sSkill, sDifficulty, sFieldKey, sResults, sRollTotal }, "|");
end

function isSkillRollProcessedRecently(rRoll, nodePC, sField)
	local sKey = buildSkillRollKey(rRoll, nodePC, sField);
	if sKey == "" then
		return false;
	end

	local nNow = os.time() or 0;
	for sExistingKey, nTimestamp in pairs(aProcessedSkillRollKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedSkillRollKeys[sExistingKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedSkillRollKeys[sKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedSkillRollKeys[sKey] = nNow;
	return false;
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

	-- Rolls coming directly from a PC sheet may not have a CT node/link.
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

	local sNormalized = normalizeText(sDesc);
	for _, sToken in ipairs(aMMDifficultyParseOrder) do
		if sNormalized:find(sToken, 1, true) then
			return sToken;
		end
	end

	return "";
end

function getMMDifficultyField(sDifficulty)
	local sKey = normalizeText(sDifficulty);
	return aMMDifficultyToField[sKey] or "";
end

function isSkillSuccess(rRoll)
	if not rRoll then
		return false;
	end

	local sCombined = normalizeText(
		(rRoll.sDesc or "") .. " " ..
		(rRoll.name or "") .. " " ..
		(rRoll.sResult or "") .. " " ..
		(rRoll.result or "")
	);

	if sCombined:find("partial success", 1, true) or sCombined:find("failure", 1, true) then
		return false;
	end

	if sCombined:find("absolute success", 1, true) or sCombined:find("[success]", 1, true) then
		return true;
	end

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
	if not sDescSeverity then
		sDescSeverity = sDesc:match("([abcde])%s+critical");
	end
	if not sDescSeverity then
		local sDescUpper = (sDescription or ""):upper();
		local sMatch = sDescUpper:match("([ABCDE])%s+CRITICAL");
		if sMatch then
			sDescSeverity = sMatch:lower();
		end
	end
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
