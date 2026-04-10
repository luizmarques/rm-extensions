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
local aProcessedCombatEPKeys = {};
local aProcessedSeverityKeys = {};
local aProcessedCriticalMatrixKeys = {};
local aProcessedCriticalSelfKeys = {};
local aProcessedSkillEPKeys = {};
local aProcessedSpellEPKeys = {};
local aPendingSkillRollByActor = {};

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

function notifyApplyDamageOOB(nodeSourcePC, nodeTargetPC, nodeTarget, sTargetType, nAppliedDamage, bKill)
	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_XPAUTO_APPLYDAMAGE;
	msgOOB.nodeSourcePCPath = nodeSourcePC and (DB.getPath(nodeSourcePC) or "") or "";
	msgOOB.nodeTargetPCPath = nodeTargetPC and (DB.getPath(nodeTargetPC) or "") or "";
	msgOOB.nodeTargetPath = nodeTarget and (DB.getPath(nodeTarget) or "") or "";
	msgOOB.sTargetType = tostring(sTargetType or "");
	msgOOB.nAppliedDamage = tonumber(nAppliedDamage or 0) or 0;
	msgOOB.bKill = bKill and 1 or 0;

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

	if nAppliedDamage <= 0 then
		return;
	end

	if nodeTargetPC and not isCombatEPProcessedRecently(nodeTargetPC, "hitstaken", nAppliedDamage, bKill) then
		addXPValue(nodeTargetPC, "hitstaken", nAppliedDamage);
	end

	if nodeSourcePC and not isCombatEPProcessedRecently(nodeSourcePC, "hitsgiven", nAppliedDamage, bKill) then
		addXPValue(nodeSourcePC, "hitsgiven", nAppliedDamage);
	end

	if nodeSourcePC and bKill and not isCombatEPProcessedRecently(nodeSourcePC, "foekill", 1, bKill) then
		local nFoeKillBonusBase, sFoeKillBonusCategory = getFoeKillBonusFromTarget(nodeSourcePC, nodeTarget, sTargetType);
		if sFoeKillBonusCategory == "" then
			sFoeKillBonusCategory = "Unrecognized";
		end
		addFoeKillBonusEntry(nodeSourcePC, nodeTarget, sFoeKillBonusCategory, nFoeKillBonusBase);

		if nFoeKillBonusBase > 0 then
			addXPValue(nodeSourcePC, "foekill", 1);
			addXPValue(nodeSourcePC, "foekillbase", nFoeKillBonusBase);
		end
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
	if sSeverity == "" then
		return;
	end

	if nodeAttackerPC then
		local sOutcome = getCriticalMatrixOutcome(nodeAttackerCT, nodeTarget, woundEffects, sDescription, bWasAlive);
		if sOutcome ~= "" then
			local sEventKey = getCriticalMatrixEventKey(nodeAttackerPC, nodeTarget, woundEffects, sDescription, sSeverity, sOutcome);
			if not isCriticalMatrixProcessedRecently(sEventKey) then
				local sField = getCriticalFieldName(sSeverity, sOutcome);
				if sField ~= "" then
					addXPValue(nodeAttackerPC, sField, 1);
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
			end
		end
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

	local nHitsTakenXP = nAppliedDamage;
	local nHitsGivenXP = nAppliedDamage;

	if not Session.IsHost then
		notifyApplyDamageOOB(nodeSourcePC, nodeTargetPC, nodeTarget, sTargetType, nAppliedDamage, bKill);
		return;
	end

	if nodeTargetPC and nHitsTakenXP > 0 and not isCombatEPProcessedRecently(nodeTargetPC, "hitstaken", nHitsTakenXP, bKill) then
		addXPValue(nodeTargetPC, "hitstaken", nHitsTakenXP);
	end

	if nodeSourcePC and nHitsGivenXP > 0 and not isCombatEPProcessedRecently(nodeSourcePC, "hitsgiven", nHitsGivenXP, bKill) then
		addXPValue(nodeSourcePC, "hitsgiven", nHitsGivenXP);
	end

	if nodeSourcePC and bKill and not isCombatEPProcessedRecently(nodeSourcePC, "foekill", 1, bKill) then
		local nFoeKillBonusBase, sFoeKillBonusCategory = getFoeKillBonusFromTarget(nodeSourcePC, nodeTarget, sTargetType);
		if sFoeKillBonusCategory == "" then
			sFoeKillBonusCategory = "Unrecognized";
		end
		addFoeKillBonusEntry(nodeSourcePC, nodeTarget, sFoeKillBonusCategory, nFoeKillBonusBase);

		if nFoeKillBonusBase > 0 then
			addXPValue(nodeSourcePC, "foekill", 1);
			addXPValue(nodeSourcePC, "foekillbase", nFoeKillBonusBase);
		end
	end
end

function getFoeKillBonusFromTarget(nodeSourcePC, nodeTarget, sTargetType)
	local aCandidates = getTargetTypeCandidates(nodeTarget, sTargetType);
	local sTargetText = normalizeText(table.concat(aCandidates, " "));

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
		local sLabel = "Demons (Type " .. tostring(nTypeOrPale) .. ")";
		if sTargetText:find("demon of might", 1, true) or sTargetText:find("beyond pale", 1, true) then
			nBonus = nBonus + 5000;
			sLabel = sLabel .. " + Beyond Pale";
		end

		return nBonus, sLabel;
	end

	if isAnyFoeCategory(aCandidates, { "dragon" }) then
		return 2000, "Dragons";
	end

	if isAnyFoeCategory(aCandidates, { "eagle" }) then
		return 2000, "Eagle";
	end

	if isAnyFoeCategory(aCandidates, { "orc", "uruk", "uruk-hai" }) then
		return 75, "Orc";
	end

	if isAnyFoeCategory(aCandidates, { "troll" }) then
		return 200, "Troll";
	end

	local nFallbackKillPoints = getFallbackKillPointsFromTarget(nodeTarget, sTargetType);
	if nFallbackKillPoints > 0 then
		return nFallbackKillPoints, "Base Formula (Hits + 20xLevel)";
	end

	return 0, "";
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

function addFoeKillBonusEntry(nodePC, nodeTarget, sCategory, nBonus)
	if not nodePC then
		return;
	end

	nBonus = tonumber(nBonus or 0) or 0;

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
	local sEntryText = "";
	if nBonus > 0 then
		sEntryText = string.format("%03d - %s: +%d (%s)", nOrder, sEntryCategory, nBonus, sFoeName);
	else
		sEntryText = string.format("%03d - %s: +0 (%s)", nOrder, sEntryCategory, sFoeName);
	end

	DB.setValue(nodeEntry, "order", "number", nOrder);
	DB.setValue(nodeEntry, "category", "string", sEntryCategory);
	DB.setValue(nodeEntry, "bonus", "number", nBonus);
	DB.setValue(nodeEntry, "foe", "string", sFoeName);
	DB.setValue(nodeEntry, "text", "string", sEntryText);
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

