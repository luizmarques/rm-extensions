-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Creatures and Treasures
	LibraryData.setCustomColumnHandler("npc_view_levelwithcode", ReferenceManagerRMC.getNPCViewLevelWithCode);
	LibraryData.setCustomColumnHandler("npc_view_sizecrit", ReferenceManagerRMC.getNPCViewSizeCrit);
	LibraryData.setCustomColumnHandler("npc_view_atdb", ReferenceManagerRMC.getNPCViewATDB);
	LibraryData.setCustomColumnHandler("npc_view_pacewithbonus", ReferenceManagerRMC.getNPCViewPaceWithBonus);
	LibraryData.setCustomColumnHandler("npc_view_msaq", ReferenceManagerRMC.getNPCViewMSAQ);
	LibraryData.setCustomColumnHandler("npc_view_hitswithcode", ReferenceManagerRMC.getNPCViewHitsWithCode);
	LibraryData.setCustomColumnHandler("npc_view_outlookiq", ReferenceManagerRMC.getNPCViewOutlookIQ);
	LibraryData.setCustomColumnHandler("npc_view_attacks", ReferenceManagerRMC.getNPCViewAttacks);
	-- Character Law
	LibraryData.setCustomGroupOutputHandler("skill_type", ReferenceManagerRMC.getSkillType);
	LibraryData.setCustomColumnHandler("skill_view_typelabel", ReferenceManagerRMC.getSkillViewTypeLabel);
	LibraryData.setCustomColumnHandler("npc_view_armorlabel", ReferenceManagerRMC.getNPCViewArmorLabel);
	LibraryData.setCustomColumnHandler("npc_view_oblabel", ReferenceManagerRMC.getNPCOBLabel);
	LibraryData.setCustomColumnHandler("npc_view_malabel", ReferenceManagerRMC.getNPCMALabel);
	LibraryData.setCustomColumnHandler("npc_view_ambush", ReferenceManagerRMC.getNPCAmbush);
	LibraryData.setCustomColumnHandler("npc_view_hitslabel", ReferenceManagerRMC.getNPCHitsLabel);
	LibraryData.setCustomColumnHandler("npc_view_directspelllabel", ReferenceManagerRMC.getNPCDirectSpellLabel);
	LibraryData.setCustomColumnHandler("npc_view_manueverlabel", ReferenceManagerRMC.getNPCManeuverLabel);
	LibraryData.setCustomColumnHandler("npc_view_perception", ReferenceManagerRMC.getNPCPerception);
	LibraryData.setCustomColumnHandler("npc_view_amlabel", ReferenceManagerRMC.getNPCAdrenalMoveLabel);
	LibraryData.setCustomColumnHandler("npc_view_languages", ReferenceManagerRMC.getNPCLanguages);
	LibraryData.setCustomColumnHandler("npc_view_spellslabel", ReferenceManagerRMC.getNPCSpellsLabel);
	LibraryData.setCustomColumnHandler("race_view_stat_1", ReferenceManagerRMC.getRaceStats1Label);
	LibraryData.setCustomColumnHandler("race_view_stat_2", ReferenceManagerRMC.getRaceStats2Label);
	LibraryData.setCustomColumnHandler("race_view_rr", ReferenceManagerRMC.getRaceRRLabel);
end

function populateReferenceTableList(w)
	local tTables = {};

	for _,v in pairs(DB.getChildrenGlobal("Sublists")) do
		local sKey = DB.getValue(v, "TableType", "") .. ":" .. DB.getValue(v, "TableClass", "");
		if tTables[sKey] then
			tTables[sKey].sTitle = DB.getValue(v, "ListTitle", "");
		else
			tTables[sKey] = { sTitle = DB.getValue(v, "ListTitle", ""), tData = {} };
		end
	end
	for _,v in pairs(DB.getChildrenGlobal("RMTables")) do
		local sKey = DB.getValue(v, "TableType", "") .. ":" .. DB.getValue(v, "Class", "");
		if tTables[sKey] then
			table.insert(tTables[sKey].tData, v);
		else
			tTables[sKey] = { sTitle = "Misc", tData = { v } };
		end
	end
	for _,v in pairs(tTables) do
		local wChild = w.list.createWindow();
		wChild.name.setValue(v.sTitle);
		for _,v2 in ipairs(v.tData) do
			wChild.list.createWindow(v2);
		end
		wChild.refresh();
	end
	-- for _,sModule in pairs(Module.getModules()) do
	-- 	for _,v in pairs(DB.getChildren("Sublists@" .. sModule)) do
	-- 		tTables[DB.getValue(v, "ListTitle", "")] = { sType = DB.getValue(v, "TableType", ""), sClass = DB.getValue(v, "Class", "") };
	-- 	end
	-- end
	-- for k,v in pairs(tTables) do
	-- 	wChild = w.list.createWindow();
	-- 	wChild.name.setValue(k);
	-- 	wChild.setFilter(v.sType, v.sClass);
	-- end
end

-- Creatures and Treasures
function getNPCViewLevelWithCode(node)
	if not node then
		return "";
	end
	return string.format("%d%s", DB.getValue(node, "level", ""), DB.getValue(node, "levelcode", ""));
end
function getNPCViewSizeCrit(node)
	if not node then
		return "";
	end
	return string.format("%s/%s", Rules_NPC.GetSizeAbbr(DB.getValue(node, "size", "-")), Rules_NPC.GetCritModAbbr(DB.getValue(node, "critmod", "-")));
end
function getNPCViewATDB(node)
	if not node then
		return "";
	end
	return string.format("%d(%d)", DB.getValue(node, "at", 0), DB.getValue(node, "db", 0));
end
function getNPCViewPaceWithBonus(node)
	if not node then
		return "";
	end
	return string.format("%s/%d", Rules_NPC.GetMaxPaceAbbr(DB.getValue(node, "maxpace", "-")), DB.getValue(node, "mnbonus", ""));
end
function getNPCViewMSAQ(node)
	if not node then
		return "";
	end
	return string.format("%s/%s", Rules_NPC.GetMSAQAbbr(DB.getValue(node, "ms", "-")), Rules_NPC.GetMSAQAbbr(DB.getValue(node, "aq", "-")));
end
function getNPCViewHitsWithCode(node)
	if not node then
		return "";
	end
	return string.format("%d%s", DB.getValue(node, "hits", ""), DB.getValue(node, "hitscode", ""));
end
function getNPCViewOutlookIQ(node)
	if not node then
		return "";
	end
	local _,sOutlook = OptionManager.invoke("outlooklabel", DB.getValue(node, "outlook", 0));
	local _,sIQ = OptionManager.invoke("iqlabel", DB.getValue(node, "iq", 0));
	if sIQ ~= "-" then
		sOutlook = string.format("%s (%s)", sOutlook, sIQ);
	end
	return sOutlook;
end
function getNPCViewAttacks(node)
	if not node then
		return "";
	end

	local tWeapons = {};
	for _,v in pairs(DB.getChildren(node, "weapons")) do
		table.insert(tWeapons, OptionManager.invoke("weaponlabel", v));
	end
	return table.concat(tWeapons, "/");
end

-- Character Law
function getSkillType(nType)
	local sResult = "";
	if nType == 1 then
		sResult = "MM";
	elseif nType == 2 then
		sResult = "SM";
	elseif nType == 3 then
		sResult = "OB";
	elseif nType == 4 then
		sResult = "SP";
	end
	return sResult;
end
function getSkillViewTypeLabel(node)
	if not node then
		return "";
	end
	return ReferenceManagerRMC.getSkillType(DB.getValue(node, "type", 0));
end
function getNPCViewArmorLabel(node)
	if not node then
		return "";
	end

	local sProfession = DB.getValue(node, "profession", "");
	local nLevel = DB.getValue(node, "level", 0);
	local sArmorType = "NONE";
	if sProfession == "Ranger" 
			or (sProfession == "Bard" and nLevel >= 5 and nLevel <= 7) 
			or (sProfession == "Thief"  and nLevel <= 3)
			or (sProfession == "Pure Channeling Spell User" and nLevel >= 3) then			
		sArmorType = "RL";
	elseif (sProfession == "Bard" and nLevel >= 10) 
			or (sProfession == "Thief" and nLevel >= 5 and nLevel <= 7)
			or (sProfession == "Rogue" and nLevel == 1)
			or (sProfession == "Pure Mentalism Spell User" and nLevel >= 5) then
		sArmorType = "CH";
	elseif sProfession == "Fighter"
			or (sProfession == "Thief" and nLevel >= 10)
			or (sProfession == "Rogue" and nLevel >= 3) then
		sArmorType = "ANY";
	end

	local nAT = DB.getValue(node, "at", 0);

	local nDB = DB.getValue(node, "db", 0);
	for _,v in pairs(DB.getChildren(node, "defences")) do
		nDB = nDB + DB.getValue(v, "meleebonus", 0);
	end

	local sUseShield = "N";
	for _,v in pairs(DB.getChildren(node, "defences")) do
		sUseShield = "Y";
	end

	local sResult = string.format("%s - %d/%d/%s", sArmorType, nAT, nDB, sUseShield);
	if sProfession:find("Spell User") then
		sResult = sResult .. "**";
	end
	return sResult;
end
function getNPCOBLabel(node)
	if not node then
		return "";
	end
	local nMeleeResult = -25;
	for _,v in pairs(DB.getChildren(node, "weapons")) do
		local sName = DB.getValue(v, "name", "");
		if sName == "Melee" then
			nMeleeResult = DB.getValue(v, "ob", -25);
		elseif sName == "Missile" then
			nMissileResult = DB.getValue(v, "ob", -25);
		end
	end

	local sResult = string.format("%d/%d", nMeleeResult, nMissileResult);
	local sProfession = DB.getValue(node, "profession", "");
	if sProfession:find("Pure Mentalism Spell User") then
		sResult = sResult .. "*";
	end
	return sResult;
end
function getNPCMALabel(node)
	if not node then
		return "";
	end
	local sRank = "1";
	local nMAResult = -25;
	for _,v in pairs(DB.getChildren(node, "weapons")) do
		local sName = DB.getValue(v, "name", "");
		if sName:find("MA") then
			local nLoc = sName:find("Rank");
			if nLoc then
				sRank = sName:sub(nLoc + 5, nLoc + 5);
			end
		end
		if sName:find("MA ") then
			nMAResult = DB.getValue(v, "ob", -25);
		end
	end

	local sProfession = DB.getValue(node, "profession", "");
	local sMAType = "STK";
	if sProfession == "Monk" then
		sMAType = "ONE";
	elseif sProfession == "Warrior Monk" then
		sMAType = "ANY";
	end

	return string.format("%s/%s/%d", sRank, sMAType, nMAResult);
end
function getNPCAmbush(node)
	if not node then
		return "";
	end
	local nValue = 0;
	for _,v in pairs(DB.getChildren(node, "skills")) do
		if DB.getValue(v, "name", "") == "Ambush" then
			nValue = DB.getValue(v, "bonus", 0);
		end
	end
	local sProfession = DB.getValue(node, "profession", "");
	if StringManager.contains({ "Hybrid Spell User", "Pure Essence Spell User", "Pure Channeling Spell User" } , sProfession) then
		return tostring(nValue) .. "*";
	end
	return tostring(nValue);
end
function getNPCHitsLabel(node)
	if not node then
		return "";
	end
	local nValue = DB.getValue(node, "hits", 0);
	local sProfession = DB.getValue(node, "profession", "");
	if StringManager.contains({ "Pure Essence Spell User", "Pure Channeling Spell User" } , sProfession) then
		return tostring(nValue) .. "*";
	end
	return tostring(nValue);
end
function getNPCDirectSpellLabel(node)
	if not node then
		return "";
	end
	local nDSResult = -25;
	for _,v in pairs(DB.getChildren(node, "weapons")) do
		if DB.getValue(v, "name", "") == "Directed Spell" then
			nDSResult = DB.getValue(v, "ob", -25);
		end
	end
	local sProfession = DB.getValue(node, "profession", "");
	if StringManager.contains({ "Pure Essence Spell User", "Hybrid Spell User" } , sProfession) then
		return tostring(nDSResult) .. "*";
	end
	return tostring(nDSResult);
end
function getNPCManeuverLabel(node)
	if not node then
		return "";
	end

	local sProfession = DB.getValue(node, "profession", "");

	local nClimb = -25;
	local nRide = -25;
	local nStalk = -25;
	for _,v in pairs(DB.getChildren(node, "skills")) do
		local sName = DB.getValue(v, "name", "");
		if sName == "Climb" then
			nClimb = DB.getValue(v, "bonus", -25);
		elseif sName == "Ride" then
			nRide = DB.getValue(v, "bonus", -25);
		elseif sName == "Disarm Trap" then
			nDisarmTrap = DB.getValue(v, "bonus", -25);
		elseif sName == "Stalk" then
			nStalk = DB.getValue(v, "bonus", -25);
		end
	end

	local sClimb = tostring(nClimb);
	local sRide = tostring(nRide);
	local sDisarmTrap = tostring(nDisarmTrap);
	local sStalk = tostring(nStalk);
	if StringManager.contains({ "Pure Mentalism Spell User", "Pure Channeling Spell User" } , sProfession) then
		sRide = sRide .. "*";
	end
	if sProfession == "Pure Essence Spell User" then
		sDisarmTrap = sDisarmTrap .. "*";
	end
	if sProfession:find("Spell User") then
		sStalk = sStalk .. "*";
	end

	return string.format("%s/%s/%s/%s", sClimb, sRide, sDisarmTrap, sStalk);
end
function getNPCPerception(node)
	if not node then
		return "";
	end
	local nValue = -25;
	for _,v in pairs(DB.getChildren(node, "skills")) do
		if DB.getValue(v, "name", "") == "Perception" then
			nValue = DB.getValue(v, "bonus", -25);
		end
	end
	local sProfession = DB.getValue(node, "profession", "");
	if sProfession == "Pure Mentalism Spell User" then
		return tostring(nValue) .. "*";
	end
	return tostring(nValue);
end
function getNPCAdrenalMoveLabel(node)
	if not node then
		return "";
	end

	local nCount = 0;
	local nBonus = 0;
	for _,v in pairs(DB.getChildren(node, "skills")) do
		local sName = DB.getValue(v, "name", "");
		if sName:find("Adrenal Move") then
			nCount = nCount + 1;
			if sName == "Adrenal Move 1" then
				nBonus = DB.getValue(v, "bonus", 0);
			end
		end
	end

	if nCount == 0 then
		return "0/-";
	end
	return string.format("%d/%d", nCount, nBonus);
end
function getNPCLanguages(node)
	return DB.getText(node, "abilities", ""):match("(%d+) Languages to Level 5") or "0";
end
function getNPCSpellsLabel(node)
	if not node then
		return "";
	end

	local sProfession = DB.getValue(node, "profession", "");

	local nRunes = -25;
	local nChanneling = -25;
	for _,v in pairs(DB.getChildren(node, "skills")) do
		local sName = DB.getValue(v, "name", "");
		if sName == "Runes" then
			nRunes = DB.getValue(v, "bonus", -25);
		elseif sName == "Channeling" then
			nChanneling = DB.getValue(v, "bonus", -25);
		end
	end

	local sRunes = tostring(nRunes);
	local sChanneling = tostring(nChanneling);
	if sProfession == "Hybrid Spell User" then
		sRunes = sRunes .. "*";
		sChanneling = sChanneling .. "*";
	end

	local sAbilities = DB.getText(node, "abilities", "");
	local sListsTo5 = sAbilities:match("(%d+) Spell Lists to Level 5") or "0";
	local sListsTo10 = sAbilities:match("(%d+) Spell Lists to Level 10") or "0";
	local sListsTo20 = sAbilities:match("(%d+) Spell Lists to Level 20") or "0";

	return string.format("%s/%s (%s/%s/%s)", sRunes, sChanneling, sListsTo5, sListsTo10, sListsTo20);
end
function getRaceStats1Label(node)
	if not node then
		return "";
	end

	local nST = DB.getValue(node, "statbonuses.strength", 0);
	local nQU = DB.getValue(node, "statbonuses.quickness", 0);
	local nPR = DB.getValue(node, "statbonuses.presence", 0);
	local nIN = DB.getValue(node, "statbonuses.intuition", 0);
	local nEM = DB.getValue(node, "statbonuses.empathy", 0);

	return string.format("%d/%d/%d/%d/%d", nST, nQU, nPR, nIN, nEM);
end
function getRaceStats2Label(node)
	if not node then
		return "";
	end

	local nCO = DB.getValue(node, "statbonuses.constitution", 0);
	local nAG = DB.getValue(node, "statbonuses.agility", 0);
	local nSD = DB.getValue(node, "statbonuses.selfdiscipline", 0);
	local nME = DB.getValue(node, "statbonuses.memory", 0);
	local nRE = DB.getValue(node, "statbonuses.reasoning", 0);

	return string.format("%d/%d/%d/%d/%d", nCO, nAG, nSD, nME, nRE);
end
function getRaceRRLabel(node)
	if not node then
		return "";
	end

	local nEss = DB.getValue(node, "resistances.essence", 0);
	local nChan = DB.getValue(node, "resistances.channeling", 0);
	local nMent = DB.getValue(node, "resistances.mentalism", 0);
	local nPoi = DB.getValue(node, "resistances.poison", 0);
	local nDis = DB.getValue(node, "resistances.disease", 0);

	return string.format("%d/%d/%d/%d/%d", nEss, nChan, nMent, nPoi, nDis);
end
