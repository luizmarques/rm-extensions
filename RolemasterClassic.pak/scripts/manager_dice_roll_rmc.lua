-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--
--	ATTACK TABLE DICE TABLE ADDITIONS 
--
local _tAttackTableCodes = {
	["ALT"] = "armslaw",
	["CLT"] = "clawlaw",
	["ARM"] = "armoury",
	["RFW"] = "fantasyweapons",
	["SLT"] = "spelllaw"
}

local _tAttackTableIDs = {
	["SLT-01"] = "shockbolt",
	["SLT-02"] = "waterbolt",
	["SLT-03"] = "icebolt",
	["SLT-04"] = "firebolt",
	["SLT-05"] = "lightningbolt",
	["SLT-06"] = "coldball",
	["SLT-07"] = "fireball"
}

function registerAttackKey(sDefaultKey)
	DiceRollManager.setAction("attack", { sDefaultKey = sDefaultKey });
end
function registerAttackTypeKey(sAttackType, sDefaultKey)
	if (sAttackType or "") == "" then
		return;
	end
	DiceRollManager.setAction("attack-type-" .. sAttackType:gsub("%s", "-"), { sDefaultKey = sDefaultKey });
end

function addAttackDice(tTargetDice, tSourceDice, tData)
	local tDiceSkin;
	if tData.attacktype then
		tDiceSkin = DiceRollManagerRMC.getAttackDiceSkin(tData.attacktype);
	end
	DiceRollManager.helperAddDice(tTargetDice, tSourceDice, tData, tDiceSkin);
end
function getAttackDiceSkin(sAttackTypes)
	local tAttackTypes = StringManager.split(sAttackTypes, ",", true);
	local tDiceSkin;
	for _,sAttackType in ipairs(tAttackTypes) do
		tDiceSkin = DiceRollManager.resolveAction("attack-type-" .. sAttackType:gsub("%s", "-"));
		if tDiceSkin then
			break;
		end
	end
	if not tDiceSkin then
		tDiceSkin = DiceRollManager.resolveAction("attack");
	end
	return tDiceSkin;
end
function getAttackTData(sTableID)
	local sTableCode = string.sub(sTableID, 1, 3);
	local tData = {};
	tData.attacktype = "";

	local sType = _tAttackTableIDs[sTableID];
	if sType then
		tData.attacktype = sType;
	else
		sType = _tAttackTableCodes[sTableCode];
		if sType then
			tData.attacktype = sType;
		end	
	end

	return tData;
end
function isAttackTable(sTableID)
	local sTableCode = string.sub(sTableID, 1, 3);
	return _tAttackTableCodes[sTableCode];
end


--
--	RESULT TABLE DICE TABLE ADDITIONS 
--
local _tResultTableCodes = {
	["CT-"] = "armslaw",
	["SCT"] = "spelllaw",
	["SF-"] = "spelllaw"
}

local _tResultTableIDs = {
	["CT-01"] = "grapple",
	["CT-02"] = "krush",
	["CT-03"] = "mathrows",
	["CT-04"] = "mastrikes",
	["CT-05"] = "puncture",
	["CT-06"] = "slash",
	["CT-07"] = "tiny",
	["CT-08"] = "unbalancing",
	["CT-09"] = "largearms",
	["CT-10"] = "superlargearms",
	["CT-11"] = "weaponfumble",
	["CT-12"] = "nonweaponfumble",
	["SCT-01"] = "cold",
	["SCT-02"] = "electricity",
	["SCT-03"] = "heat",
	["SCT-04"] = "impact",
	["SCT-05"] = "largespells",
	["SCT-06"] = "superlargespells",
	["SF-01"] = "nonattackspellfailure",
	["SF-02"] = "attackspellfailure",
	["ARMC-01"] = "subdual",
}

function registerResultTableKey(sDefaultKey)
	DiceRollManager.setAction("resulttable", { sDefaultKey = sDefaultKey });
end
function registerResultTableTypeKey(sResultTableType, sDefaultKey)
	if (sResultTableType or "") == "" then
		return;
	end
	DiceRollManager.setAction("resulttable-type-" .. sResultTableType:gsub("%s", "-"), { sDefaultKey = sDefaultKey });
end

function addResultTableDice(tTargetDice, tSourceDice, tData)
	local tDiceSkin;
	if tData.resulttabletype then
		tDiceSkin = DiceRollManagerRMC.getResultTableDiceSkin(tData.resulttabletype);
	end
	DiceRollManager.helperAddDice(tTargetDice, tSourceDice, tData, tDiceSkin);
end
function getResultTableDiceSkin(sResultTableTypes)
	local tResultTableTypes = StringManager.split(sResultTableTypes, ",", true);
	local tDiceSkin;
	for _,sResultTableType in ipairs(tResultTableTypes) do
		tDiceSkin = DiceRollManager.resolveAction("resulttable-type-" .. sResultTableType:gsub("%s", "-"));
		if tDiceSkin then
			break;
		end
	end
	if not tDiceSkin then
		tDiceSkin = DiceRollManager.resolveAction("resulttable");
	end
	return tDiceSkin;
end
function getResultTableTData(sTableID)
	local tData = {};
	tData.resulttabletype = "";

	local sType = _tResultTableIDs[sTableID];
	if sType then
		tData.resulttabletype = sType;
	end

	return tData;
end
function isResultTable(sTableID)
	local sTableCode = string.sub(sTableID, 1, 3);
	return _tResultTableCodes[sTableCode];
end


--
--	REALM/RR DICE TABLE ADDITIONS 
--
local _tRealmRRCodes = {
	["Channeling"] = "channeling",
	["Essence"] = "essence",
	["Mentalism"] = "mentalism",
	["Channeling/Essence"] = "channelingessence",
	["Ess/Chan"] = "channelingessence",
	["Channeling/Mentalism"] = "channelingmentalism",
	["Chan/Ment"] = "channelingmentalism",
	["Essence/Mentalism"] = "essencementalism",
	["Ment/Ess"] = "essencementalism",
	["Arcane"] = "arcane",
	["Disease"] = "disease",
	["Poison"] = "poison",
	["Terror"] = "terror"
}

function registerRealmRRKey(sDefaultKey)
	DiceRollManager.setAction("realmrr", { sDefaultKey = sDefaultKey });
end
function registerRealmRRTypeKey(sRealmRRType, sDefaultKey)
	if (sRealmRRType or "") == "" then
		return;
	end
	DiceRollManager.setAction("realmrr-type-" .. sRealmRRType:gsub("%s", "-"), { sDefaultKey = sDefaultKey });
end

function addRealmRRDice(tTargetDice, tSourceDice, tData)
	local tDiceSkin;
	if tData.realmrrtype then
		tDiceSkin = DiceRollManagerRMC.getRealmRRDiceSkin(tData.realmrrtype);
	end
	DiceRollManager.helperAddDice(tTargetDice, tSourceDice, tData, tDiceSkin);
end
function getRealmRRDiceSkin(sRealmRRTypes)
	local tRealmRRTypes = StringManager.split(sRealmRRTypes, ",", true);
	local tDiceSkin;
	for _,sRealmRRType in ipairs(tRealmRRTypes) do
		tDiceSkin = DiceRollManager.resolveAction("realmrr-type-" .. sRealmRRType:gsub("%s", "-"));
		if tDiceSkin then
			break;
		end
	end
	if not tDiceSkin then
		tDiceSkin = DiceRollManager.resolveAction("realmrr");
	end
	return tDiceSkin;
end
function getRealmRRTData(sRealmRR)
	local tData = {};
	tData.realmrrtype = "";

	local sType = _tRealmRRCodes[sRealmRR];
	if sType then
		tData.realmrrtype = sType;
	end

	return tData;
end
