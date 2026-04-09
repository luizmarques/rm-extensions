-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local fOriginalAddWoundEffects;
local fOriginalApplyDamage;
local aPendingAttackerPCByTarget = {};
local aProcessedCombatEPKeys = {};
local aProcessedSeverityKeys = {};

function onInit()
	if not Session.IsHost then
		return;
	end

	ActionsManager.registerPostRollHandler("attack", onAttackPostRoll);

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

	if not bIsApplyTrigger then
		return;
	end

	local nDamageAfter = DB.getValue(nodeTarget, "damage", 0);
	local bNowDead = false;
	if nTargetHits > 0 then
		bNowDead = (nDamageAfter >= nTargetHits);
	end

	local sCritSeverity = getCriticalSeverity(woundEffects, description);
	if sCritSeverity == "" then
		return;
	end

	local sCritOutcome = getCriticalOutcome(nodeAttackerCT, nodeTarget, woundEffects, description, bWasAlive, bNowDead);
	local sCritField = getCriticalFieldName(sCritSeverity, sCritOutcome);
	if not nodeAttackerPC or sCritField == "" then
		return;
	end

	if isSeverityProcessedRecently(nodeAttackerPC, sCritField, description) then
		return;
	end

	addXPValue(nodeAttackerPC, sCritField, 1);
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
	if hasWoundKey(woundEffects, "Unconscious") or hasWoundKey(woundEffects, "Dying") or hasAnyWoundText(woundEffects, { "unconscious", "dying" }) or sDesc:find("unconscious", 1, true) then
		return "unc";
	end
	if sDesc:find("down", 1, true) or sDesc:find("prone", 1, true) or sDesc:find("kneeling", 1, true) or hasAnyWoundText(woundEffects, { "down", "prone", "kneeling" }) then
		return "down";
	end
	if hasWoundKey(woundEffects, "Stun") or hasWoundKey(woundEffects, "NoParry") or hasWoundKey(woundEffects, "MustParry") or hasAnyWoundText(woundEffects, { "stun", "no parry", "mustparry", "must parry" }) or sDesc:find("stun", 1, true) then
		return "stun";
	end

	return "norm";
end

function hasAnyWoundText(woundEffects, aNeedles)
	if type(woundEffects) ~= "table" then
		return false;
	end

	for sKey, vValue in pairs(woundEffects) do
		if type(vValue) == "string" then
			local sKeyNormalized = normalizeText(tostring(sKey or ""));
			if sKeyNormalized:find("effect", 1, true) or sKeyNormalized:find("wound", 1, true) then
				local sText = normalizeText(vValue);
				for _, sNeedle in ipairs(aNeedles) do
					if sText:find(sNeedle, 1, true) then
						return true;
					end
				end
			end
		end
	end

	return false;
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
