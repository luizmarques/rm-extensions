-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOriginalAddWoundEffects;
local fOriginalApplyDamage;
local OOB_MSGTYPE_XPAUTO_SKILL_POSTROLL = "xpautoskpostroll";
local OOB_MSGTYPE_XPAUTO_BASECAST_POSTROLL = "xpautobcpostroll";
local OOB_MSGTYPE_XPAUTO_WOUNDEFFECTS = "xpautowoundeffects";
local OOB_MSGTYPE_XPAUTO_APPLYDAMAGE = "xpautoapplydamage";
local aPendingAttackerPCByTarget = {};
local aPendingAttackerNameByTarget = {};
local aProcessedCombatEPKeys = {};
local aProcessedCombatEventKeys = {};
local aProcessedSeverityKeys = {};
local aProcessedCriticalMatrixKeys = {};
local aProcessedCriticalSelfKeys = {};
local aProcessedStatusKillKeys = {};
local aProcessedSkillEPKeys = {};
local aProcessedSpellEPKeys = {};
local aPendingSkillRollByActor = {};
local aLoggedFoeKillNotesKeys = {};

function onInit()
	ActionsManager.registerPostRollHandler("skill", onSkillPostRoll);
	ActionsManager.registerPostRollHandler("basecasting", onBaseCastingPostRoll);

	if Session.IsHost then
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_XPAUTO_SKILL_POSTROLL, handleSkillPostRollOOB);
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_XPAUTO_BASECAST_POSTROLL, handleBaseCastingPostRollOOB);
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_XPAUTO_WOUNDEFFECTS, handleWoundEffectsOOB);
		OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_XPAUTO_APPLYDAMAGE, handleApplyDamageOOB);
	end

	if CombatManager2 and CombatManager2.addWoundEffects then
		fOriginalAddWoundEffects = CombatManager2.addWoundEffects;
		CombatManager2.addWoundEffects = onAddWoundEffectsWithXP;
	end

	if ActionDamage and ActionDamage.applyDamage then
		fOriginalApplyDamage = ActionDamage.applyDamage;
		ActionDamage.applyDamage = onApplyDamageWithXP;
	end

	if Session.IsHost then
		initializeFoeKillCounters();
	end
end

function onSkillPostRoll(rSource, a2, a3)
	local rRoll = a3 or a2;
	if not rRoll then
		return;
	end

	if not Session.IsHost then
		notifySkillPostRollOOB(rSource, rRoll);
		return;
	end

	processSkillPostRollHost(rSource, rRoll);
end

function processSkillPostRollHost(rSource, rRoll)
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

	if not Session.IsHost then
		notifyBaseCastingPostRollOOB(rSource, rRoll);
		return;
	end

	processBaseCastingPostRollHost(rSource, rRoll);
end

function processBaseCastingPostRollHost(rSource, rRoll)
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
	appendSpellXPLog(nodeSourcePC, rRoll, nSpellLevel);
end

function notifySkillPostRollOOB(rSource, rRoll)
	if not rRoll then
		return;
	end

	local msgOOB = buildPostRollOOBMessage(rSource, rRoll);
	msgOOB.type = OOB_MSGTYPE_XPAUTO_SKILL_POSTROLL;
	Comm.deliverOOBMessage(msgOOB, "");
end

function notifyBaseCastingPostRollOOB(rSource, rRoll)
	if not rRoll then
		return;
	end

	local msgOOB = buildPostRollOOBMessage(rSource, rRoll);
	msgOOB.type = OOB_MSGTYPE_XPAUTO_BASECAST_POSTROLL;
	Comm.deliverOOBMessage(msgOOB, "");
end

function handleSkillPostRollOOB(msgOOB)
	if not Session.IsHost or type(msgOOB) ~= "table" then
		return;
	end

	local rSource = decodeSourceFromOOB(msgOOB);
	local rRoll = decodeRollFromOOB(msgOOB);
	processSkillPostRollHost(rSource, rRoll);
end

function handleBaseCastingPostRollOOB(msgOOB)
	if not Session.IsHost or type(msgOOB) ~= "table" then
		return;
	end

	local rSource = decodeSourceFromOOB(msgOOB);
	local rRoll = decodeRollFromOOB(msgOOB);
	processBaseCastingPostRollHost(rSource, rRoll);
end

function notifyWoundEffectsOOB(nodeAttackerCT, nodeAttackerPC, nodeTarget, nodeTargetPC, sDescription, bWasAlive, sSeverity, sOutcome, woundEffects)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_XPAUTO_WOUNDEFFECTS;
	msgOOB.nodeAttackerCTPath = nodeAttackerCT and (DB.getPath(nodeAttackerCT) or "") or "";
	msgOOB.nodeAttackerPCPath = nodeAttackerPC and (DB.getPath(nodeAttackerPC) or "") or "";
	msgOOB.nodeTargetPath = nodeTarget and (DB.getPath(nodeTarget) or "") or "";
	msgOOB.nodeTargetPCPath = nodeTargetPC and (DB.getPath(nodeTargetPC) or "") or "";
	msgOOB.sDescription = tostring(sDescription or "");
	msgOOB.bWasAlive = bWasAlive and 1 or 0;
	msgOOB.sSeverity = tostring(sSeverity or "");
	msgOOB.sOutcome = tostring(sOutcome or "");
	if type(woundEffects) == "table" then
		msgOOB.sCriticalCode = tostring(woundEffects.CriticalCode or "");
		msgOOB.sCriticalName = tostring(woundEffects.CriticalName or "");
	end

	Comm.deliverOOBMessage(msgOOB, "");
end

function notifyApplyDamageOOB(nodeSourcePC, nodeTargetPC, nodeTarget, sTargetType, nAppliedDamage, bKill, sEventKey, sSourceName)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_XPAUTO_APPLYDAMAGE;
	msgOOB.nodeSourcePCPath = nodeSourcePC and (DB.getPath(nodeSourcePC) or "") or "";
	msgOOB.nodeTargetPCPath = nodeTargetPC and (DB.getPath(nodeTargetPC) or "") or "";
	msgOOB.nodeTargetPath = nodeTarget and (DB.getPath(nodeTarget) or "") or "";
	msgOOB.sTargetType = tostring(sTargetType or "");
	msgOOB.nAppliedDamage = tonumber(nAppliedDamage or 0) or 0;
	msgOOB.bKill = bKill and 1 or 0;
	msgOOB.sEventKey = tostring(sEventKey or "");
	msgOOB.sSourceName = tostring(sSourceName or "");

	Comm.deliverOOBMessage(msgOOB, "");
end

function handleWoundEffectsOOB(msgOOB)
	if not Session.IsHost or type(msgOOB) ~= "table" then
		return;
	end

	local nodeAttackerCT = DB.findNode(tostring(msgOOB.nodeAttackerCTPath or ""));
	local nodeAttackerPC = DB.findNode(tostring(msgOOB.nodeAttackerPCPath or ""));
	local nodeTarget = DB.findNode(tostring(msgOOB.nodeTargetPath or ""));
	local nodeTargetPC = DB.findNode(tostring(msgOOB.nodeTargetPCPath or ""));
	local sDescription = tostring(msgOOB.sDescription or "");
	local sSeverity = normalizeText(tostring(msgOOB.sSeverity or ""));
	local sOutcome = normalizeText(tostring(msgOOB.sOutcome or ""));
	local bWasAlive = tonumber(msgOOB.bWasAlive or 0) == 1;
	local sCriticalCode = tostring(msgOOB.sCriticalCode or "");
	local sCriticalName = tostring(msgOOB.sCriticalName or "");

	if nodeAttackerPC and nodeTarget then
		updateCombatXPDescByOpponent(nodeAttackerPC, nodeTarget);
	end
	if nodeTargetPC and nodeAttackerCT then
		updateCombatXPDescByOpponent(nodeTargetPC, nodeAttackerCT);
	end

	if nodeAttackerPC then
		local tWoundSummary = {
			CriticalCode = sCriticalCode,
			CriticalName = sCriticalName,
		};
		tryGrantStatusFoeKill(nodeAttackerPC, nodeTarget, tWoundSummary, sDescription, sOutcome);
	end

	if sSeverity:match("^[abcde]$") then
		if sOutcome == "" then
			sOutcome = "norm";
		end

		if nodeAttackerPC then
			local sField = getCriticalFieldName(sSeverity, sOutcome);
			if sField ~= "" then
				local sEventKey = table.concat({
					DB.getPath(nodeAttackerPC) or "",
					nodeTarget and (DB.getPath(nodeTarget) or "") or "",
					sSeverity,
					normalizeText(sCriticalCode),
					normalizeText(sCriticalName),
					sOutcome,
					normalizeText(sDescription)
				}, "|");
				if not isCriticalMatrixProcessedRecently(sEventKey) then
					addXPValue(nodeAttackerPC, sField, 1);
					local nCriticalAfter = getCombatCriticalEquationXP(nodeAttackerPC);
					appendXPLogCombat(nodeAttackerPC, sField, nCriticalAfter, "Critical Matrix " .. sSeverity .. "/" .. sOutcome, nodeTarget);
				end
			end
		end

		if nodeTargetPC then
			local sSelfField = getCriticalFieldName(sSeverity, "self");
			if sSelfField ~= "" then
				local sSelfEventKey = table.concat({
					DB.getPath(nodeTargetPC) or "",
					nodeTarget and (DB.getPath(nodeTarget) or "") or "",
					sSeverity,
					normalizeText(sCriticalCode),
					normalizeText(sCriticalName),
					normalizeText(sDescription)
				}, "|");
				if not isCriticalSelfProcessedRecently(sSelfEventKey) then
					addXPValue(nodeTargetPC, sSelfField, 1);
					local nCriticalAfter = getCombatCriticalEquationXP(nodeTargetPC);
					appendXPLogCombat(nodeTargetPC, sSelfField, nCriticalAfter, "Critical Self " .. sSeverity, nodeTarget);
				end
			end
		end
	end

	tryProcessPendingSkillEP(nodeAttackerCT, nodeTarget, sDescription);
end

function handleApplyDamageOOB(msgOOB)
	if not Session.IsHost or type(msgOOB) ~= "table" then
		return;
	end

	local nodeSourcePC = DB.findNode(tostring(msgOOB.nodeSourcePCPath or ""));
	local nodeTargetPC = DB.findNode(tostring(msgOOB.nodeTargetPCPath or ""));
	local nodeTarget = DB.findNode(tostring(msgOOB.nodeTargetPath or ""));
	local sTargetType = tostring(msgOOB.sTargetType or "");
	local nAppliedDamage = tonumber(msgOOB.nAppliedDamage or 0) or 0;
	local bKill = tonumber(msgOOB.bKill or 0) == 1;
	local sEventKey = tostring(msgOOB.sEventKey or "");
	local sSourceName = tostring(msgOOB.sSourceName or "");
	if sEventKey == "" then
		sEventKey = buildCombatApplyEventKey(nodeSourcePC, nodeTargetPC, nodeTarget, nAppliedDamage, bKill);
	end

	if nAppliedDamage <= 0 then
		return;
	end

	if isCombatEventProcessedRecently(sEventKey) then
		return;
	end

	if nodeTargetPC and not isCombatEPProcessedRecently(nodeTargetPC, "hitstaken", nAppliedDamage, bKill) then
		addXPValue(nodeTargetPC, "hitstaken", nAppliedDamage);
		appendXPLogCombat(nodeTargetPC, "hitstaken", nAppliedDamage, "Apply Damage", nodeTarget, sSourceName);
	end

	if nodeSourcePC and not isCombatEPProcessedRecently(nodeSourcePC, "hitsgiven", nAppliedDamage, bKill) then
		addXPValue(nodeSourcePC, "hitsgiven", nAppliedDamage);
		appendXPLogCombat(nodeSourcePC, "hitsgiven", nAppliedDamage, "Apply Damage", nodeTarget, sSourceName);
	end

	if nodeSourcePC and bKill and not isCombatEPProcessedRecently(nodeSourcePC, "foekill", 1, bKill) then
		local nFoeKillBonusBase, sFoeKillBonusCategory, nKillBasePoints, nKillCategoryBonus = getFoeKillBonusFromTarget(nodeSourcePC, nodeTarget, sTargetType);
		if sFoeKillBonusCategory == "" then
			sFoeKillBonusCategory = "Unrecognized";
		end
		if nFoeKillBonusBase > 0 then
			addXPValue(nodeSourcePC, "foekill", 1);
			addXPValue(nodeSourcePC, "foekillbase", nFoeKillBonusBase);
		end

		addFoeKillBonusEntry(nodeSourcePC, nodeTarget, sFoeKillBonusCategory, nFoeKillBonusBase, sEventKey, nKillBasePoints, nKillCategoryBonus);
	end
end

function buildPostRollOOBMessage(rSource, rRoll)
	local msgOOB = {};
	msgOOB.nodeSourcePath = getSourcePathFromActor(rSource);
	msgOOB.nodeActorName = tostring(rRoll.nodeActorName or "");
	msgOOB.nodeAttackerName = tostring(rRoll.nodeAttackerName or "");
	msgOOB.targetNodeName = tostring(rRoll.targetNodeName or "");
	msgOOB.skillName = tostring(rRoll.skillName or "");
	msgOOB.sDesc = tostring(rRoll.sDesc or "");
	msgOOB.difficultyName = tostring(rRoll.difficultyName or "");
	msgOOB.columnTitle = tostring(rRoll.columnTitle or "");
	msgOOB.modifiers = tostring(rRoll.modifiers or "");
	msgOOB.nSpellLevel = tonumber(rRoll.nSpellLevel or 0) or 0;
	msgOOB.sSpellNodeName = tostring(rRoll.sSpellNodeName or "");
	msgOOB.sSpellListNodeName = tostring(rRoll.sSpellListNodeName or "");
	msgOOB.nFailure = tonumber(rRoll.nFailure or 0) or 0;
	msgOOB.unmodified = tonumber(rRoll.unmodified or 0) or 0;
	msgOOB.dieResult = tonumber(rRoll.dieResult or 0) or 0;
	msgOOB.primaryDieResult = tonumber(getRollPrimaryDieResult(rRoll) or 0) or 0;
	return msgOOB;
end

function decodeRollFromOOB(msgOOB)
	local rRoll = {};
	rRoll.nodeActorName = msgOOB.nodeActorName;
	rRoll.nodeAttackerName = msgOOB.nodeAttackerName;
	rRoll.targetNodeName = msgOOB.targetNodeName;
	rRoll.skillName = msgOOB.skillName;
	rRoll.sDesc = msgOOB.sDesc;
	rRoll.difficultyName = msgOOB.difficultyName;
	rRoll.columnTitle = msgOOB.columnTitle;
	rRoll.modifiers = msgOOB.modifiers;
	rRoll.nSpellLevel = tonumber(msgOOB.nSpellLevel or 0) or 0;
	rRoll.sSpellNodeName = msgOOB.sSpellNodeName;
	rRoll.sSpellListNodeName = msgOOB.sSpellListNodeName;
	rRoll.nFailure = tonumber(msgOOB.nFailure or 0) or 0;
	rRoll.unmodified = tonumber(msgOOB.unmodified or 0) or 0;
	rRoll.dieResult = tonumber(msgOOB.dieResult or 0) or 0;
	rRoll.aDice = {
		{ result = tonumber(msgOOB.primaryDieResult or 0) or 0 }
	};
	return rRoll;
end

function decodeSourceFromOOB(msgOOB)
	local sPath = tostring(msgOOB.nodeSourcePath or "");
	if sPath == "" then
		return nil;
	end

	local nodeSource = DB.findNode(sPath);
	if not nodeSource then
		return nil;
	end

	local sClass, sRecord = DB.getValue(nodeSource, "link", "", "");
	if sClass == "charsheet" and sRecord ~= "" then
		return ActorManager.resolveActor(sClass, sRecord);
	end

	local sNodePath = DB.getPath(nodeSource) or "";
	if sNodePath:match("^charsheet%.") then
		return ActorManager.resolveActor("charsheet", sNodePath);
	end

	if sNodePath:match("^combattracker%.list%.") then
		return ActorManager.resolveActor("ct", sNodePath);
	end

	return nil;
end

function getSourcePathFromActor(rSource)
	if not rSource then
		return "";
	end

	local nodeCT = ActorManager.getCTNode(rSource);
	if nodeCT then
		return DB.getPath(nodeCT) or "";
	end

	local nodeActor = ActorManager.getCreatureNode(rSource);
	if nodeActor then
		return DB.getPath(nodeActor) or "";
	end

	return "";
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
	if not nodeTargetPC then
		nodeTargetPC = getPCNodeFromNode(nodeTarget);
	end

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

		local sAttackerName = "";
		if nodeAttackerPC then
			sAttackerName = getCombatActorName(nodeAttackerPC);
		end
		if normalizeText(sAttackerName) == "" or normalizeText(sAttackerName) == "unknown" then
			sAttackerName = getActorNameFromCTNode(nodeAttackerCT);
		end

		if nodeAttackerPC then
			aPendingAttackerPCByTarget[sTargetPath] = DB.getPath(nodeAttackerPC) or "";
		else
			aPendingAttackerPCByTarget[sTargetPath] = "";
		end

		if normalizeText(sAttackerName) ~= "" then
			aPendingAttackerNameByTarget[sTargetPath] = sAttackerName;
		else
			aPendingAttackerNameByTarget[sTargetPath] = "";
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

	if not Session.IsHost then
		local sSeverity = "";
		local sOutcome = "";
		if bIsApplyTrigger then
			sSeverity = getCriticalSeverityFromEvent(woundEffects, description);
			if sSeverity ~= "" then
				sOutcome = getCriticalMatrixOutcome(nodeAttackerCT, nodeTarget, woundEffects, description, bWasAlive);
			end
		end
		notifyWoundEffectsOOB(nodeAttackerCT, nodeAttackerPC, nodeTarget, nodeTargetPC, description, bWasAlive, sSeverity, sOutcome, woundEffects);
		tryProcessPendingSkillEP(nodeAttackerCT, nodeTarget, description);
		return;
	end

	if bIsApplyTrigger then
		processCombatCriticalMatrix(nodeAttackerCT, nodeAttackerPC, nodeTargetPC, nodeTarget, woundEffects, description, bWasAlive);
	end

	tryProcessPendingSkillEP(nodeAttackerCT, nodeTarget, description);
end

function processCombatCriticalMatrix(nodeAttackerCT, nodeAttackerPC, nodeTargetPC, nodeTarget, woundEffects, sDescription, bWasAlive)
	if type(woundEffects) ~= "table" then
		return;
	end

	local sSeverity = getCriticalSeverityFromEvent(woundEffects, sDescription);
	local sOutcome = "";

	if nodeAttackerPC then
		sOutcome = getCriticalMatrixOutcome(nodeAttackerCT, nodeTarget, woundEffects, sDescription, bWasAlive);
		tryGrantStatusFoeKill(nodeAttackerPC, nodeTarget, woundEffects, sDescription, sOutcome);
	end

	if sSeverity == "" then
		return;
	end

	if nodeAttackerPC then
		if sOutcome ~= "" then
			local sEventKey = getCriticalMatrixEventKey(nodeAttackerPC, nodeTarget, woundEffects, sDescription, sSeverity, sOutcome);
			if not isCriticalMatrixProcessedRecently(sEventKey) then
				local sField = getCriticalFieldName(sSeverity, sOutcome);
				if sField ~= "" then
					addXPValue(nodeAttackerPC, sField, 1);
					local nCriticalAfter = getCombatCriticalEquationXP(nodeAttackerPC);
					appendXPLogCombat(nodeAttackerPC, sField, nCriticalAfter, "Critical Matrix " .. sSeverity .. "/" .. sOutcome, nodeTarget);
				end
			end
		end
	end

	if nodeTargetPC then
		local sSelfField = getCriticalFieldName(sSeverity, "self");
		if sSelfField ~= "" then
			local sSelfEventKey = getCriticalSelfEventKey(nodeTargetPC, nodeTarget, woundEffects, sDescription, sSeverity);
			if not isCriticalSelfProcessedRecently(sSelfEventKey) then
				addXPValue(nodeTargetPC, sSelfField, 1);
				local nCriticalAfter = getCombatCriticalEquationXP(nodeTargetPC);
				appendXPLogCombat(nodeTargetPC, sSelfField, nCriticalAfter, "Critical Self " .. sSeverity, nodeTarget);
			end
		end
	end
end

function tryGrantStatusFoeKill(nodeAttackerPC, nodeTarget, woundEffects, sDescription, sOutcome)
	if not nodeAttackerPC then
		return;
	end

	if not isStatusKillByEffect(nodeTarget, woundEffects, sDescription, sOutcome) then
		return;
	end

	if isCombatEPProcessedRecently(nodeAttackerPC, "foekill", 1, true) then
		return;
	end

	local sStatusEventKey = buildStatusKillEventKey(nodeAttackerPC, nodeTarget, sOutcome, sDescription);
	if isStatusKillProcessedRecently(sStatusEventKey) then
		return;
	end

	local nFoeKillBonusBase, sFoeKillBonusCategory, nKillBasePoints, nKillCategoryBonus = getFoeKillBonusFromTarget(nodeAttackerPC, nodeTarget, "");
	if sFoeKillBonusCategory == "" then
		sFoeKillBonusCategory = "Unrecognized";
	end

	local sStatusKillLabel = getStatusKillLabel(nodeTarget, woundEffects, sDescription, sOutcome);
	if nFoeKillBonusBase > 0 then
		addXPValue(nodeAttackerPC, "foekill", 1);
		addXPValue(nodeAttackerPC, "foekillbase", nFoeKillBonusBase);
	end

	addFoeKillBonusEntry(nodeAttackerPC, nodeTarget, sFoeKillBonusCategory, nFoeKillBonusBase, sStatusEventKey, nKillBasePoints, nKillCategoryBonus, sStatusKillLabel);
end

function getStatusKillLabel(nodeTarget, woundEffects, sDescription, sOutcome)
	local sDesc = normalizeText(sDescription or "");
	local sOutcomeNorm = normalizeText(sOutcome or "");

	local function hasStatus(sLabelUpper, sLabelLower)
		if hasTargetEffectOrCondition(nodeTarget, { sLabelUpper })
			or isTargetInEffectState(nodeTarget, { sLabelLower })
			or hasWoundFlag(woundEffects, sLabelUpper)
			or hasAnyWoundText(woundEffects, { sLabelLower })
			or sDesc:find(sLabelLower, 1, true) then
			return true;
		end

		return false;
	end

	if hasStatus("Dead", "dead") then
		return "Dead";
	end

	if hasStatus("Dying", "dying") then
		return "Dying";
	end

	if hasStatus("Unconscious", "unconscious") or sOutcomeNorm == "unc" then
		return "Unconscious";
	end

	return "Status";
end

function isStatusKillByEffect(nodeTarget, woundEffects, sDescription, sOutcome)
	local sOutcomeNorm = normalizeText(sOutcome or "");
	if sOutcomeNorm == "unc" then
		return true;
	end

	if hasTargetEffectOrCondition(nodeTarget, { "Unconscious", "Dying", "Dead" })
		or isTargetInEffectState(nodeTarget, { "unconscious", "dying", "dead" }) then
		return true;
	end

	if hasWoundFlag(woundEffects, "Unconscious") or hasWoundFlag(woundEffects, "Dying") or hasWoundFlag(woundEffects, "Dead") then
		return true;
	end

	if hasAnyWoundText(woundEffects, { "unconscious", "dying", "dead" }) then
		return true;
	end

	local sDesc = normalizeText(sDescription or "");
	if sDesc:find("unconscious", 1, true) or sDesc:find("dying", 1, true) or sDesc:find("dead", 1, true) then
		return true;
	end

	return false;
end

function buildStatusKillEventKey(nodeAttackerPC, nodeTarget, sOutcome, sDescription)
	local sAttackerPath = nodeAttackerPC and (DB.getPath(nodeAttackerPC) or "") or "";
	local sTargetPath = nodeTarget and (DB.getPath(nodeTarget) or "") or "";
	local sOutcomeNorm = normalizeText(sOutcome or "");
	local sDescNorm = normalizeText(sDescription or "");
	return table.concat({ sAttackerPath, sTargetPath, "statuskill", sOutcomeNorm, sDescNorm }, "|");
end

function isStatusKillProcessedRecently(sEventKey)
	sEventKey = tostring(sEventKey or "");
	if sEventKey == "" then
		return false;
	end

	local nNow = os.time() or 0;
	for sKey, nTimestamp in pairs(aProcessedStatusKillKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedStatusKillKeys[sKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedStatusKillKeys[sEventKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedStatusKillKeys[sEventKey] = nNow;
	return false;
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

	if nodeAttackerCT and nodeTarget and DB.getPath(nodeAttackerCT) == DB.getPath(nodeTarget) then
		return "self";
	end

	if bWasAlive and isTargetNowDead(nodeTarget) then
		return "solo";
	end

	if hasTargetEffectOrCondition(nodeTarget, { "Unconscious", "Dying", "Dead" })
		or isTargetInEffectState(nodeTarget, { "unconscious", "dying", "dead" })
		or isTargetUnconsciousByHealth(nodeTarget)
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

	local sSizeOutcome = getTargetSizeOutcome(nodeTarget);
	if sSizeOutcome ~= "" then
		return sSizeOutcome;
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

function isTargetUnconsciousByHealth(nodeTarget)
	if not nodeTarget then
		return false;
	end

	local nHits = tonumber(DB.getValue(nodeTarget, "hits", 0)) or 0;
	local nDamage = tonumber(DB.getValue(nodeTarget, "damage", 0)) or 0;

	if nHits <= 0 then
		local sClass, sRecord = DB.getValue(nodeTarget, "link", "", "");
		if sClass == "charsheet" and sRecord ~= "" then
			local nodeChar = DB.findNode(sRecord);
			if nodeChar then
				nHits = tonumber(DB.getValue(nodeChar, "hits.max", 0)) or 0;
				nDamage = tonumber(DB.getValue(nodeChar, "hits.damage", 0)) or 0;
			end
		end
	end

	if nHits <= 0 then
		return false;
	end

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

function getCriticalSelfEventKey(nodeTargetPC, nodeTarget, woundEffects, sDescription, sSeverity)
	local sTargetPCPath = DB.getPath(nodeTargetPC) or "";
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
	return table.concat({ sTargetPCPath, sTargetPath, sSeverity or "", sCode, sName, sDesc }, "|");
end

function isCriticalSelfProcessedRecently(sEventKey)
	if sEventKey == "" then
		return false;
	end

	local nNow = os.time() or 0;
	for sKey, nTimestamp in pairs(aProcessedCriticalSelfKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedCriticalSelfKeys[sKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedCriticalSelfKeys[sEventKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedCriticalSelfKeys[sEventKey] = nNow;
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

	local sEventKey = buildCombatApplyEventKey(nodeSourcePC, nodeTargetPC, nodeTarget, nAppliedDamage, bKill);
	local sTargetPathForPending = nodeTarget and (DB.getPath(nodeTarget) or "") or "";

	local nHitsTakenXP = nAppliedDamage;
	local nHitsGivenXP = nAppliedDamage;

	if not Session.IsHost then
		local sSourceName = getCombatSourceNameForDamage(rSource, nodeSourcePC, nodeTarget);
		if sTargetPathForPending ~= "" then
			aPendingAttackerNameByTarget[sTargetPathForPending] = nil;
		end
		notifyApplyDamageOOB(nodeSourcePC, nodeTargetPC, nodeTarget, sTargetType, nAppliedDamage, bKill, sEventKey, sSourceName);
		return;
	end

	local sSourceName = getCombatSourceNameForDamage(rSource, nodeSourcePC, nodeTarget);
	if sTargetPathForPending ~= "" then
		aPendingAttackerNameByTarget[sTargetPathForPending] = nil;
	end

	if isCombatEventProcessedRecently(sEventKey) then
		return;
	end

	if nodeTargetPC and nHitsTakenXP > 0 and not isCombatEPProcessedRecently(nodeTargetPC, "hitstaken", nHitsTakenXP, bKill) then
		addXPValue(nodeTargetPC, "hitstaken", nHitsTakenXP);
		appendXPLogCombat(nodeTargetPC, "hitstaken", nHitsTakenXP, "Apply Damage", nodeTarget, sSourceName);
	end

	if nodeSourcePC and nHitsGivenXP > 0 and not isCombatEPProcessedRecently(nodeSourcePC, "hitsgiven", nHitsGivenXP, bKill) then
		addXPValue(nodeSourcePC, "hitsgiven", nHitsGivenXP);
		appendXPLogCombat(nodeSourcePC, "hitsgiven", nHitsGivenXP, "Apply Damage", nodeTarget, sSourceName);
	end

	if nodeSourcePC and bKill and not isCombatEPProcessedRecently(nodeSourcePC, "foekill", 1, bKill) then
		local nFoeKillBonusBase, sFoeKillBonusCategory, nKillBasePoints, nKillCategoryBonus = getFoeKillBonusFromTarget(nodeSourcePC, nodeTarget, sTargetType);
		if sFoeKillBonusCategory == "" then
			sFoeKillBonusCategory = "Unrecognized";
		end
		if nFoeKillBonusBase > 0 then
			addXPValue(nodeSourcePC, "foekill", 1);
			addXPValue(nodeSourcePC, "foekillbase", nFoeKillBonusBase);
		end

		addFoeKillBonusEntry(nodeSourcePC, nodeTarget, sFoeKillBonusCategory, nFoeKillBonusBase, sEventKey, nKillBasePoints, nKillCategoryBonus);
	end
end

function getFoeKillBonusFromTarget(nodeSourcePC, nodeTarget, sTargetType)
	local aCandidates = getTargetTypeCandidates(nodeTarget, sTargetType);
	local sTargetText = normalizeText(table.concat(aCandidates, " "));

	local nAttackerLevel = 1;
	if nodeSourcePC then
		nAttackerLevel = tonumber(DB.getValue(nodeSourcePC, "level", 1)) or 1;
	end
	if nAttackerLevel < 1 then
		nAttackerLevel = 1;
	end

	local nOpponentLevel = getTargetLevelForKillPoints(nodeTarget, sTargetType);
	if nOpponentLevel < 0 then
		nOpponentLevel = 0;
	end

	local nKillBasePoints = 0;
	local sBaseLabel = "";

	local nKillPointsTable = getKillPointsFromTable0904(nOpponentLevel, nAttackerLevel);
	if nKillPointsTable > 0 then
		nKillBasePoints = nKillPointsTable;
		sBaseLabel = "Table 09-04";
	else
		local nFallbackKillPoints = getFallbackKillPointsFromTarget(nodeTarget, sTargetType);
		if nFallbackKillPoints > 0 then
			nKillBasePoints = nFallbackKillPoints;
			sBaseLabel = "Fallback (Hits + 20xLevel)";
		end
	end

	local nKillCategoryBonus, sKillCategoryLabel = getFoeKillCategoryBonus(nodeSourcePC, aCandidates, sTargetText);
	local nKillTotal = nKillBasePoints + nKillCategoryBonus;

	if nKillTotal <= 0 then
		return 0, "Unrecognized", nKillBasePoints, nKillCategoryBonus;
	end

	local sCombinedLabel = sBaseLabel;
	if sCombinedLabel == "" then
		sCombinedLabel = "Kill Points";
	end
	if sKillCategoryLabel ~= "" then
		sCombinedLabel = sCombinedLabel .. " + " .. sKillCategoryLabel;
	end

	return nKillTotal, sCombinedLabel, nKillBasePoints, nKillCategoryBonus;
end

function getFoeKillCategoryBonus(nodeSourcePC, aCandidates, sTargetText)
	if isFoeOwnRace(nodeSourcePC, aCandidates) then
		return 150, "Own Race";
	end

	if isAnyFoeCategory(aCandidates, { "human", "high man", "common man", "dunedain" }) then
		return 100, "Human";
	end

	if isAnyFoeCategory(aCandidates, { "dwarf" }) then
		return 100, "Dwarf";
	end

	if isAnyFoeCategory(aCandidates, { "elf", "silvan elf", "sindar elf", "noldo elf", "half-elf" }) then
		return 100, "Elf";
	end

	if isAnyFoeCategory(aCandidates, { "hobbit", "halfling" }) then
		return 100, "Hobbits";
	end

	if sTargetText:find("demon", 1, true) then
		local nTypeOrPale = extractDemonTypeOrPale(sTargetText);
		if nTypeOrPale < 1 then
			nTypeOrPale = 1;
		end

		local nBonus = (nTypeOrPale * nTypeOrPale) * 50;
		local sLabel = "Demons";
		if sTargetText:find("demon of might", 1, true) or sTargetText:find("beyond pale", 1, true) then
			nBonus = nBonus + 5000;
			sLabel = "Demons + Beyond Pale";
		end

		return nBonus, sLabel;
	end

	if isAnyFoeCategory(aCandidates, { "dragon" }) then
		return 2000, "Dragons";
	end

	if isAnyFoeCategory(aCandidates, { "eagle" }) then
		return 200, "Eagle";
	end

	if isAnyFoeCategory(aCandidates, { "orc", "uruk", "uruk-hai" }) then
		return 75, "Orc";
	end

	if isAnyFoeCategory(aCandidates, { "troll" }) then
		return 200, "Troll";
	end

	return 0, "";
end

function getKillPointsFromTable0904(nOpponentLevel, nAttackerLevel)
	nOpponentLevel = tonumber(nOpponentLevel or 0) or 0;
	nAttackerLevel = tonumber(nAttackerLevel or 1) or 1;

	if nAttackerLevel < 1 then
		nAttackerLevel = 1;
	elseif nAttackerLevel > 10 then
		nAttackerLevel = 10;

	end

	local aTable = {
		[0] =  { 50, 45, 40, 35, 30, 25, 20, 15, 10, 5 },
		[1] =  { 200, 150, 130, 110, 100, 90, 80, 70, 60, 50 },
		[2] =  { 250, 200, 150, 130, 110, 100, 90, 80, 70, 60 },
		[3] =  { 300, 250, 200, 150, 130, 110, 100, 90, 80, 70 },
		[4] =  { 350, 300, 250, 200, 150, 130, 110, 100, 90, 80 },
		[5] =  { 400, 350, 300, 250, 200, 150, 130, 110, 100, 90 },
		[6] =  { 450, 400, 350, 300, 250, 200, 150, 130, 110, 100 },
		[7] =  { 500, 450, 400, 350, 300, 250, 200, 150, 130, 110 },
		[8] =  { 550, 500, 450, 400, 350, 300, 250, 200, 150, 130 },
		[9] =  { 600, 550, 500, 450, 400, 350, 300, 250, 200, 150 },
		[10] = { 650, 600, 550, 500, 450, 400, 350, 300, 250, 200 },
	};

	local nColumn = nAttackerLevel;
	local nOpponentClamped = nOpponentLevel;
	if nOpponentClamped < 0 then
		nOpponentClamped = 0;
	elseif nOpponentClamped > 10 then
		nOpponentClamped = 10;
	end

	local aRow = aTable[nOpponentClamped];
	if not aRow then
		return 0;
	end


	local nBase = tonumber(aRow[nColumn] or 0) or 0;
	if nOpponentLevel > 10 then
		nBase = nBase + ((nOpponentLevel - 10) * 50);
	end

	return nBase;
end

function getTargetLevelForKillPoints(nodeTarget, sTargetType)
	if not nodeTarget then
		return 0;
	end

	local nLevel = tonumber(DB.getValue(nodeTarget, "level", 0)) or 0;
	if nLevel > 0 then
		return nLevel;
	end

	if sTargetType == "charsheet" then
		return nLevel;
	end

	local _, sRecord = DB.getValue(nodeTarget, "link", "", "");
	if sRecord ~= "" then
		local nodeLinked = DB.findNode(sRecord);
		if nodeLinked then
			nLevel = tonumber(DB.getValue(nodeLinked, "level", 0)) or 0;
			if nLevel > 0 then
				return nLevel;
			end
		end
	end

	return nLevel;
end

function getFallbackKillPointsFromTarget(nodeTarget, sTargetType)
	if not nodeTarget then
		return 0;
	end

	local nHits = 0;
	if sTargetType == "charsheet" then
		nHits = tonumber(DB.getValue(nodeTarget, "hits.max", 0)) or 0;
	else
		nHits = tonumber(DB.getValue(nodeTarget, "hits", 0)) or 0;
		if nHits <= 0 then
			nHits = tonumber(DB.getValue(nodeTarget, "hits.max", 0)) or 0;
		end
	end

	local nLevel = tonumber(DB.getValue(nodeTarget, "level", 0)) or 0;

	if nHits <= 0 or nLevel <= 0 then
		local _, sRecord = DB.getValue(nodeTarget, "link", "", "");
		if sRecord ~= "" then
			local nodeLinked = DB.findNode(sRecord);
			if nodeLinked then
				if nHits <= 0 then
					nHits = tonumber(DB.getValue(nodeLinked, "hits.max", 0)) or 0;
					if nHits <= 0 then
						nHits = tonumber(DB.getValue(nodeLinked, "hits", 0)) or 0;
					end
				end
				if nLevel <= 0 then
					nLevel = tonumber(DB.getValue(nodeLinked, "level", 0)) or 0;
				end
			end
		end
	end

	if nHits <= 0 and nodeTarget then
		nHits = tonumber(DB.getValue(nodeTarget, "hp.total", 0)) or 0;
	end

	if nHits <= 0 and nLevel <= 0 then
		return 0;
	end

	return nHits + (20 * nLevel);
end

function addFoeKillBonusEntry(nodePC, nodeTarget, sCategory, nBonus, sEventKey, nBasePoints, nCategoryBonus, vStatusKill)
	if not nodePC then
		return;
	end

	nBonus = tonumber(nBonus or 0) or 0;
	nBasePoints = tonumber(nBasePoints or 0) or 0;
	nCategoryBonus = tonumber(nCategoryBonus or 0) or 0;
	local sStatusKillLabel = "";
	if type(vStatusKill) == "string" then
		sStatusKillLabel = tostring(vStatusKill or "");
	elseif vStatusKill then
		sStatusKillLabel = "Status";
	end

	local nodeList = DB.createChild(nodePC, "foekillbonuslist");
	if not nodeList then
		return;
	end

	local nOrder = 1;
	for _, _ in pairs(DB.getChildren(nodeList)) do
		nOrder = nOrder + 1;
	end

	local nodeEntry = DB.createChild(nodeList);
	if not nodeEntry then
		return;
	end

	local sFoeName = "Unknown";
	if nodeTarget then
		sFoeName = DB.getValue(nodeTarget, "name", "");
	end
	if normalizeText(sFoeName) == "" then
		sFoeName = "Unknown";
	end

	local sEntryCategory = sCategory or "Bonus";
	local nFoeLevel = getTargetLevelForKillPoints(nodeTarget, "");
	local sLevelText = "Level ?";
	if nFoeLevel > 0 then
		sLevelText = string.format("Level %d", nFoeLevel);
	end
	local sEntryText = "";
	sEntryText = string.format("%s | %s | %+d XP", sFoeName, sLevelText, nBonus);
	if normalizeText(sStatusKillLabel) ~= "" then
		sEntryText = sEntryText .. string.format(" | %s Kill", sStatusKillLabel);
	end

	DB.setValue(nodeEntry, "order", "number", nOrder);
	DB.setValue(nodeEntry, "category", "string", sEntryCategory);
	DB.setValue(nodeEntry, "bonus", "number", nBonus);
	DB.setValue(nodeEntry, "foe", "string", sFoeName);
	DB.setValue(nodeEntry, "text", "string", sEntryText);

	appendFoeKillBonusToNotes(nodePC, sEntryText, sEventKey);
end

function appendFoeKillBonusToNotes(nodePC, sEntryText, sEventKey)
	if not Session.IsHost or not nodePC then
		return;
	end

	sEntryText = tostring(sEntryText or "");
	if sEntryText == "" then
		return;
	end

	sEventKey = tostring(sEventKey or "");
	if sEventKey ~= "" and aLoggedFoeKillNotesKeys[sEventKey] then
		return;
	end

	local sPCPath = DB.getPath(nodePC) or "";
	if sPCPath == "" then
		return;
	end

	local sXPLogsPath = sPCPath .. ".xplogs";
	local sCurrentXPLogs = DB.getValue(nodePC, "xplogs", "") or "";
	local sNewXPLogs = buildFoeKillXPLogText(nodePC, sCurrentXPLogs, sEntryText);

	local sXPLogsType = DB.getType(sXPLogsPath) or "";
	if sXPLogsType ~= "string" and sXPLogsType ~= "formattedtext" then
		sXPLogsType = "string";
	end

	DB.setValue(nodePC, "xplogs", sXPLogsType, sNewXPLogs);

	if sEventKey ~= "" then
		aLoggedFoeKillNotesKeys[sEventKey] = os.time() or 0;
	end
end

function initializeFoeKillCounters()
	for _, nodePC in pairs(DB.getChildren("charsheet")) do
		ensureFoeKillCounterInXPLog(nodePC);
	end
end

function ensureFoeKillCounterInXPLog(nodePC)
	if not Session.IsHost or not nodePC then
		return;
	end

	local sPCPath = DB.getPath(nodePC) or "";
	if sPCPath == "" then
		return;
	end

	local sXPLogsPath = sPCPath .. ".xplogs";
	local sCurrentXPLogs = DB.getValue(nodePC, "xplogs", "") or "";
	local sNewXPLogs = buildFoeKillXPLogText(nodePC, sCurrentXPLogs, "");
	if sNewXPLogs == sCurrentXPLogs then
		return;
	end

	local sXPLogsType = DB.getType(sXPLogsPath) or "";
	if sXPLogsType ~= "string" and sXPLogsType ~= "formattedtext" then
		sXPLogsType = "string";
	end

	DB.setValue(nodePC, "xplogs", sXPLogsType, sNewXPLogs);
end

function buildFoeKillXPLogText(nodePC, sCurrentXPLogs, sEntryText)
	local aLogLines = {};
	for sLine in tostring(sCurrentXPLogs or ""):gmatch("[^\r\n]+") do
		if not isFoeKillCounterLine(sLine) then
			table.insert(aLogLines, sLine);
		end
	end

	sEntryText = tostring(sEntryText or "");
	if sEntryText ~= "" then
		table.insert(aLogLines, sEntryText);
	end

	table.insert(aLogLines, 1, getFoeKillCounterLine(nodePC));
	return table.concat(aLogLines, "\n");
end

function getFoeKillCounterLine(nodePC)
	local nFoesKilled = 0;
	if nodePC then
		nFoesKilled = tonumber(DB.getValue(nodePC, "foekill", 0)) or 0;
	end

	if nFoesKilled < 0 then
		nFoesKilled = 0;
	end

	return string.format("Foes Killed = %d", nFoesKilled);
end

function isFoeKillCounterLine(sLine)
	local sNormalized = normalizeText(sLine or "");
	if sNormalized:find("foes killed =", 1, true) == 1 then
		return true;
	end

	if sNormalized:find("foes killed total =", 1, true) == 1 then
		return true;
	end

	return false;
end

function buildCombatApplyEventKey(nodeSourcePC, nodeTargetPC, nodeTarget, nAppliedDamage, bKill)
	local sSource = nodeSourcePC and (DB.getPath(nodeSourcePC) or "") or "";
	local sTargetPC = nodeTargetPC and (DB.getPath(nodeTargetPC) or "") or "";
	local sTarget = nodeTarget and (DB.getPath(nodeTarget) or "") or "";
	local nTargetDamage = 0;
	if nodeTarget then
		nTargetDamage = tonumber(DB.getValue(nodeTarget, "damage", 0)) or 0;
		if nTargetDamage <= 0 then
			nTargetDamage = tonumber(DB.getValue(nodeTarget, "hits.damage", 0)) or 0;
		end
	end

	return table.concat({
		sSource,
		sTargetPC,
		sTarget,
		tostring(tonumber(nAppliedDamage or 0) or 0),
		tostring(nTargetDamage),
		bKill and "1" or "0",
	}, "|");
end

function isCombatEventProcessedRecently(sEventKey)
	sEventKey = tostring(sEventKey or "");
	if sEventKey == "" then
		return false;
	end

	local nNow = os.time() or 0;
	for sKey, nTimestamp in pairs(aProcessedCombatEventKeys) do
		if (nNow - (tonumber(nTimestamp) or 0)) > 5 then
			aProcessedCombatEventKeys[sKey] = nil;
		end
	end

	local nLast = tonumber(aProcessedCombatEventKeys[sEventKey]) or 0;
	if nLast > 0 and (nNow - nLast) <= 5 then
		return true;
	end

	aProcessedCombatEventKeys[sEventKey] = nNow;
	return false;
end

function isAnyFoeCategory(aCandidates, aNeedles)
	if type(aCandidates) ~= "table" or type(aNeedles) ~= "table" then
		return false;
	end

	for _, sCandidateRaw in ipairs(aCandidates) do
		local sCandidate = normalizeText(sCandidateRaw);
		if sCandidate ~= "" then
			for _, sNeedleRaw in ipairs(aNeedles) do
				local sNeedle = normalizeText(sNeedleRaw);
				if sNeedle ~= "" and sCandidate:find(sNeedle, 1, true) then
					return true;
				end
			end
		end
	end

	return false;
end

function isFoeOwnRace(nodeSourcePC, aTargetCandidates)
	if not nodeSourcePC or type(aTargetCandidates) ~= "table" then
		return false;
	end

	local sSourceRace = normalizeText(DB.getValue(nodeSourcePC, "race", ""));
	if sSourceRace == "" then
		return false;
	end

	local sSourceGroup = getRaceGroupName(sSourceRace);
	if sSourceGroup == "" then
		return false;
	end

	for _, sCandidateRaw in ipairs(aTargetCandidates) do
		local sTargetGroup = getRaceGroupName(sCandidateRaw);
		if sTargetGroup ~= "" and sTargetGroup == sSourceGroup then
			return true;
		end
	end

	return false;
end

function getRaceGroupName(sRace)
	local sValue = normalizeText(sRace);
	if sValue == "" then
		return "";
	end

	if sValue:find("human", 1, true) or sValue:find("high man", 1, true) or sValue:find("common man", 1, true)
		or sValue:find("dunedain", 1, true) then
		return "human";
	end

	if sValue:find("dwarf", 1, true) then
		return "dwarf";
	end

	if sValue:find("hobbit", 1, true) or sValue:find("halfling", 1, true) then
		return "hobbit";
	end

	if sValue:find("elf", 1, true) then
		return "elf";
	end

	if sValue:find("orc", 1, true) or sValue:find("uruk", 1, true) then
		return "orc";
	end

	if sValue:find("troll", 1, true) then
		return "troll";
	end

	return "";
end

function extractDemonTypeOrPale(sText)
	local nValue = extractNumericOrRoman(sText:match("type%s*[:%-]?%s*([%dIVXLCM]+)"));
	if nValue > 0 then
		return nValue;
	end

	nValue = extractNumericOrRoman(sText:match("pale%s*[:%-]?%s*([%dIVXLCM]+)"));
	if nValue > 0 then
		return nValue;
	end

	return 1;
end

function extractNumericOrRoman(sValue)
	if type(sValue) ~= "string" or sValue == "" then
		return 0;
	end

	local nNumeric = tonumber(sValue);
	if nNumeric and nNumeric > 0 then
		return nNumeric;
	end

	return romanToNumber(sValue);
end

function romanToNumber(sRoman)
	if type(sRoman) ~= "string" then
		return 0;
	end

	sRoman = sRoman:upper();
	if sRoman == "" then
		return 0;
	end

	local aValues = {
		I = 1,
		V = 5,
		X = 10,
		L = 50,
		C = 100,
		D = 500,
		M = 1000,
	};

	local nTotal = 0;
	local nPrev = 0;
	for i = #sRoman, 1, -1 do
		local sChar = sRoman:sub(i, i);
		local nCurrent = aValues[sChar];
		if not nCurrent then
			return 0;
		end

		if nCurrent < nPrev then
			nTotal = nTotal - nCurrent;
		else
			nTotal = nTotal + nCurrent;
			nPrev = nCurrent;
		end
	end

	return nTotal;
end

function getTargetTypeCandidates(nodeTarget, sTargetType)
	local aCandidates = {};

	if nodeTarget then
		table.insert(aCandidates, DB.getValue(nodeTarget, "race", ""));
		table.insert(aCandidates, DB.getValue(nodeTarget, "type", ""));
		table.insert(aCandidates, DB.getValue(nodeTarget, "name", ""));

		local sClass, sRecord = DB.getValue(nodeTarget, "link", "", "");
		if sRecord ~= "" then
			local nodeLinked = DB.findNode(sRecord);
			if nodeLinked then
				table.insert(aCandidates, DB.getValue(nodeLinked, "race", ""));
				table.insert(aCandidates, DB.getValue(nodeLinked, "type", ""));
				table.insert(aCandidates, DB.getValue(nodeLinked, "name", ""));
			end
		end
	end

	if sTargetType == "charsheet" and nodeTarget then
		table.insert(aCandidates, DB.getValue(nodeTarget, "race", ""));
	end

	return aCandidates;
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

	local nDiff = nOpponentLevel - nPCLevel;
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
		skillraw = tostring(sSkillName or ""),
		desc = normalizeText(sDescription or ""),
		descraw = tostring(sDescription or ""),
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
	appendManeuverXPLog(nodeAttackerPC, tPending.field, tPending.skillraw, tPending.descraw, sDescription);
	aPendingSkillRollByActor[sActorPath] = nil;
end

function appendXPLogLine(nodePC, sLogField, sEntryText)
	if not Session.IsHost or not nodePC then
		return;
	end

	sLogField = tostring(sLogField or "");
	sEntryText = tostring(sEntryText or "");
	if sLogField == "" or sEntryText == "" then
		return;
	end

	local sPCPath = DB.getPath(nodePC) or "";
	if sPCPath == "" then
		return;
	end

	local sPath = sPCPath .. "." .. sLogField;
	local sCurrent = DB.getValue(nodePC, sLogField, "") or "";
	local sNew = "";
	if sCurrent == "" then
		sNew = sEntryText;
	else
		sNew = sCurrent .. "\n" .. sEntryText;
	end

	local sType = DB.getType(sPath) or "";
	if sType ~= "string" and sType ~= "formattedtext" then
		sType = "string";
	end

	DB.setValue(nodePC, sLogField, sType, sNew);
end

function getSpellXPValue(nodePC, nSpellLevel)
	nSpellLevel = tonumber(nSpellLevel or 0) or 0;
	local nPCLevel = tonumber(DB.getValue(nodePC, "level", 0)) or 0;
	local nSpellXP = math.floor(100 - ((nPCLevel - nSpellLevel) * 10));
	if nSpellXP > 200 then
		nSpellXP = 200;
	end
	return nSpellXP;
end

function getSpellDisplayName(rRoll)
	if type(rRoll) ~= "table" then
		return "Unknown Spell";
	end

	local sSpellName = tostring(rRoll.sSpellName or "");
	if normalizeText(sSpellName) ~= "" then
		return sSpellName;
	end

	local sSpellNodeName = tostring(rRoll.sSpellNodeName or "");
	if sSpellNodeName ~= "" then
		local nodeSpell = DB.findNode(sSpellNodeName);
		if nodeSpell then
			sSpellName = DB.getValue(nodeSpell, "name", "");
			if normalizeText(sSpellName) ~= "" then
				return sSpellName;
			end
		end
	end

	sSpellName = tostring(rRoll.skillName or "");
	if normalizeText(sSpellName) ~= "" then
		return sSpellName;
	end

	return "Unknown Spell";
end

function appendSpellXPLog(nodePC, rRoll, nSpellLevel)
	if not nodePC then
		return;
	end

	nSpellLevel = tonumber(nSpellLevel or 0) or 0;
	local sSpellName = getSpellDisplayName(rRoll);
	local nSpellXP = getSpellXPValue(nodePC, nSpellLevel);
	local sEntryText = string.format("Cast Level %d Spell | %s | XP: %+d", nSpellLevel, sSpellName, nSpellXP);
	appendXPLogLine(nodePC, "spelllvleps", sEntryText);
end

function getManeuverDifficultyXPValue(sField)
	local aXPByField = {
		routine = 0,
		easy = 5,
		light = 10,
		medium = 50,
		hard = 100,
		veryhard = 150,
		extremelyhard = 200,
		sheerfolly = 300,
		absurd = 500,
	};

	return tonumber(aXPByField[tostring(sField or "")] or 0) or 0;
end

function getManeuverDifficultyLabel(sField)
	local aLabelByField = {
		routine = "Routine",
		easy = "Easy",
		light = "Light",
		medium = "Medium",
		hard = "Hard",
		veryhard = "Very Hard",
		extremelyhard = "Extremely Hard",
		sheerfolly = "Sheer Folly",
		absurd = "Absurd",
	};

	return aLabelByField[tostring(sField or "")] or "Unknown";
end

function getManeuverDetailText(sPendingDesc, sResolutionDesc)
	local sDetail = tostring(sResolutionDesc or "");
	if normalizeText(sDetail) == "" then
		sDetail = tostring(sPendingDesc or "");
	end

	sDetail = sDetail:gsub("SUCCESS:%s*Your static action is successful%.?%s*", "");
	sDetail = sDetail:gsub("[\r\n]+", " ");
	sDetail = sDetail:gsub("%s+", " ");
	sDetail = sDetail:gsub("^%s+", "");
	sDetail = sDetail:gsub("%s+$", "");

	if normalizeText(sDetail) == "" then
		sDetail = "Resolution";
	end

	return sDetail;
end

function appendManeuverXPLog(nodePC, sField, sSkillName, sPendingDesc, sResolutionDesc)
	if not nodePC then
		return;
	end

	local sSkill = tostring(sSkillName or "");
	if normalizeText(sSkill) == "" then
		sSkill = "Unknown Skill";
	end

	local sDifficulty = getManeuverDifficultyLabel(sField);
	local nXP = getManeuverDifficultyXPValue(sField);
	local sEntryText = string.format("%s | %s | XP: %+d", sSkill, sDifficulty, nXP);
	appendXPLogLine(nodePC, "successfulmaneuverseps", sEntryText);
end

function appendXPLogDetailed(nodePC, sLogField, sCategory, sField, nDelta, sOrigin)
	if not Session.IsHost or not nodePC then
		return;
	end

	local sPCPath = DB.getPath(nodePC) or "";
	if sPCPath == "" then
		return;
	end

	sLogField = tostring(sLogField or "combateps");
	sCategory = tostring(sCategory or "General");
	sField = tostring(sField or "unknown");
	nDelta = tonumber(nDelta or 0) or 0;
	sOrigin = tostring(sOrigin or "Auto");
	local nTotal = tonumber(DB.getValue(nodePC, sField, 0)) or 0;
	local sTime = getLogTimestamp();

	local sEntryText = string.format("[%s] [%s] %s | %s %+d => %d", sTime, sCategory, sOrigin, sField, nDelta, nTotal);
	appendXPLogLine(nodePC, sLogField, sEntryText);
end

function appendXPLogCombat(nodePC, sField, nDelta, sOrigin, nodeTarget, sSourceName)
	if not Session.IsHost or not nodePC then
		return;
	end

	if not shouldAppendCombatLogEntry(sField, sOrigin) then
		return;
	end

	local sEntryText = buildCombatXPLogEntry(nodePC, sField, nDelta, sOrigin, nodeTarget, sSourceName);
	appendXPLogLine(nodePC, "combateps", sEntryText);
end

function shouldAppendCombatLogEntry(sField, sOrigin)
	sField = tostring(sField or "");
	local sOriginNorm = normalizeText(sOrigin or "");

	if sField == "hitsgiven" or sField == "hitstaken" then
		return true;
	end

	if sOriginNorm:find("critical matrix ", 1, true) == 1 or sOriginNorm:find("critical self ", 1, true) == 1 then
		return true;
	end

	return false;
end

function buildCombatXPLogEntry(nodePC, sField, nDelta, sOrigin, nodeTarget, sSourceName)
	sField = tostring(sField or "");
	nDelta = tonumber(nDelta or 0) or 0;
	sOrigin = tostring(sOrigin or "");
	sSourceName = tostring(sSourceName or "");

	local sOriginNorm = normalizeText(sOrigin);
	local sXPText = string.format("%+d", nDelta);
	local sActorName = getCombatActorName(nodePC);
	local sTargetName = getCombatTargetName(nodeTarget);

	if sOriginNorm:find("critical matrix ", 1, true) == 1 then
		local sSeverity, sOutcome = sOriginNorm:match("critical matrix ([abcde])/([%a]+)");
		local sSeverityLabel = string.upper(tostring(sSeverity or "?"));
		local sOutcomeLabel = getCriticalOutcomeLabel(sOutcome);
		return string.format("%s %s | %s XP | %s", sOutcomeLabel, sSeverityLabel, sXPText, sActorName);
	end

	if sOriginNorm:find("critical self ", 1, true) == 1 then
		local sSeverity = sOriginNorm:match("critical self ([abcde])");
		local sSeverityLabel = string.upper(tostring(sSeverity or "?"));
		return string.format("Self %s | %s XP | %s", sSeverityLabel, sXPText, sActorName);
	end

	if sField == "hitsgiven" then
		return string.format("Hits Given: %s XP | %s -> %s", sXPText, sActorName, sTargetName);
	end

	if sField == "hitstaken" then
		local sSource = sSourceName;
		if normalizeText(sSource) == "" or normalizeText(sSource) == "unknown" then
			sSource = sTargetName;
		end
		if normalizeText(sSource) == "" then
			sSource = "Unknown";
		end
		return string.format("Hits Taken: %s XP | %s -> %s", sXPText, sSource, sActorName);
	end

	if sField == "foekill" then
		return string.format("%s | Foes Killed: XP: %s", sTargetName, sXPText);
	end

	if sField == "foekillbase" then
		return string.format("%s | Foe Kill Bonus: XP: %s", sTargetName, sXPText);
	end

	local sFieldLabel = getCombatFieldLabel(sField);
	return string.format("%s | %s: XP: %s", sTargetName, sFieldLabel, sXPText);
end

function getCombatCriticalEquationXP(nodePC)
	if not nodePC then
		return 0;
	end

	local nMultiplier = tonumber(DB.getValue(nodePC, "combatxpdesc", 1)) or 1;
	if nMultiplier == 0 then
		nMultiplier = 1;
	end

	local function getFieldValue(sName)
		return tonumber(DB.getValue(nodePC, sName, 0)) or 0;
	end

	local nCritBase = 0;
	nCritBase = nCritBase + (getFieldValue("norma") + (getFieldValue("unca") * 0.1) + (getFieldValue("downa") * 0.2) + (getFieldValue("stuna") * 0.5) + (getFieldValue("soloa") * 2) + (getFieldValue("largea") * 1.5) + (getFieldValue("vlargea") * 2)) * 5;
	nCritBase = nCritBase + (getFieldValue("normb") + (getFieldValue("uncb") * 0.1) + (getFieldValue("downb") * 0.2) + (getFieldValue("stunb") * 0.5) + (getFieldValue("solob") * 2) + (getFieldValue("largeb") * 1.5) + (getFieldValue("vlargeb") * 2)) * 10;
	nCritBase = nCritBase + (getFieldValue("normc") + (getFieldValue("uncc") * 0.1) + (getFieldValue("downc") * 0.2) + (getFieldValue("stunc") * 0.5) + (getFieldValue("soloc") * 2) + (getFieldValue("largec") * 1.5) + (getFieldValue("vlargec") * 2)) * 15;
	nCritBase = nCritBase + (getFieldValue("normd") + (getFieldValue("uncd") * 0.1) + (getFieldValue("downd") * 0.2) + (getFieldValue("stund") * 0.5) + (getFieldValue("solod") * 2) + (getFieldValue("larged") * 1.5) + (getFieldValue("vlarged") * 2)) * 20;
	nCritBase = nCritBase + (getFieldValue("norme") + (getFieldValue("unce") * 0.1) + (getFieldValue("downe") * 0.2) + (getFieldValue("stune") * 0.5) + (getFieldValue("soloe") * 2) + (getFieldValue("largee") * 1.5) + (getFieldValue("vlargee") * 2)) * 25;
	nCritBase = nCritBase + ((getFieldValue("selfa") * 100) / nMultiplier) + ((getFieldValue("selfb") * 200) / nMultiplier) + ((getFieldValue("selfc") * 300) / nMultiplier) + ((getFieldValue("selfd") * 400) / nMultiplier) + ((getFieldValue("selfe") * 500) / nMultiplier);

	nCritBase = math.floor(nCritBase);
	return math.floor(nCritBase * nMultiplier);
end

function getCriticalOutcomeLabel(sOutcome)
	sOutcome = normalizeText(tostring(sOutcome or ""));
	local aOutcomeLabel = {
		norm = "Norm",
		unc = "Unc",
		down = "Down",
		stun = "Stun",
		solo = "Solo",
		large = "Large",
		vlarge = "VLarge",
	};

	return aOutcomeLabel[sOutcome] or "Critical";
end

function getCombatActorName(nodePC)
	if not nodePC then
		return "Unknown";
	end

	local sActorName = DB.getValue(nodePC, "name", "Unknown");
	if normalizeText(sActorName) == "" then
		sActorName = "Unknown";
	end

	return sActorName;
end

function getCombatSourceNameFromActor(rSource, nodeSourcePC)
	if nodeSourcePC then
		local sPCName = getCombatActorName(nodeSourcePC);
		if normalizeText(sPCName) ~= "" and normalizeText(sPCName) ~= "unknown" then
			return sPCName;
		end
	end

	if rSource then
		local sActorDisplayName = tostring(rSource.sName or "");
		if normalizeText(sActorDisplayName) ~= "" and normalizeText(sActorDisplayName) ~= "unknown" then
			return sActorDisplayName;
		end

		local nodeSource = ActorManager.getCreatureNode(rSource);
		if nodeSource then
			local sSourceName = DB.getValue(nodeSource, "name", "");
			if normalizeText(sSourceName) ~= "" then
				return sSourceName;
			end

			local _, sRecord = DB.getValue(nodeSource, "link", "", "");
			if sRecord ~= "" then
				local nodeLinked = DB.findNode(sRecord);
				if nodeLinked then
					sSourceName = DB.getValue(nodeLinked, "name", "");
					if normalizeText(sSourceName) ~= "" then
						return sSourceName;
					end
				end
			end
		end
	end

	return "Unknown";
end

function getActorNameFromCTNode(nodeCT)
	if not nodeCT then
		return "";
	end

	local sName = DB.getValue(nodeCT, "name", "");
	if normalizeText(sName) ~= "" then
		return sName;
	end

	local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
	if sRecord ~= "" then
		local nodeLinked = DB.findNode(sRecord);
		if nodeLinked then
			sName = DB.getValue(nodeLinked, "name", "");
			if normalizeText(sName) ~= "" then
				return sName;
			end
		end
	end

	return "";
end

function getCombatSourceNameForDamage(rSource, nodeSourcePC, nodeTarget)
	local sSourceName = getCombatSourceNameFromActor(rSource, nodeSourcePC);
	if normalizeText(sSourceName) ~= "" and normalizeText(sSourceName) ~= "unknown" then
		return sSourceName;
	end

	if nodeTarget then
		local sTargetPath = DB.getPath(nodeTarget) or "";
		if sTargetPath ~= "" then
			local sPendingSourceName = aPendingAttackerNameByTarget[sTargetPath] or "";
			if normalizeText(sPendingSourceName) ~= "" then
				return sPendingSourceName;
			end
		end
	end

	return sSourceName;
end

function getCombatFieldLabel(sField)
	local aFieldLabel = {
		hitsgiven = "Hits Given",
		hitstaken = "Hits Taken",
		foekill = "Foes Killed",
		foekillbase = "Foe Kill Bonus",
	};

	return aFieldLabel[tostring(sField or "")] or tostring(sField or "XP");
end

function getCombatTargetName(nodeTarget)
	if not nodeTarget then
		return "Unknown";
	end

	local sTargetName = DB.getValue(nodeTarget, "name", "Unknown");
	if normalizeText(sTargetName) == "" then
		sTargetName = "Unknown";
	end

	return sTargetName;
end

function getLogTimestamp()
	return os.date("%H:%M") or "00:00";
end

function buildSpellLogOrigin(rRoll, nSpellLevel)
	local sSpellName = "Unknown Spell";
	if type(rRoll) == "table" then
		sSpellName = tostring(rRoll.sSpellName or rRoll.skillName or "Unknown Spell");
		if normalizeText(sSpellName) == "" then
			sSpellName = "Unknown Spell";
		end
	end

	return string.format("Cast L%d %s", tonumber(nSpellLevel or 0) or 0, sSpellName);
end

function buildManeuverLogOrigin(sSkillName, sPendingDesc, sResolutionDesc)
	local sSkill = tostring(sSkillName or "");
	if normalizeText(sSkill) == "" then
		sSkill = "Unknown Skill";
	end

	local sPending = normalizeText(sPendingDesc or "");
	local sResolution = normalizeText(sResolutionDesc or "");
	local sDetail = "resolution";
	if sPending ~= "" then
		sDetail = sPending;
	elseif sResolution ~= "" then
		sDetail = sResolution;
	end

	return string.format("%s (%s)", sSkill, sDetail);
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

