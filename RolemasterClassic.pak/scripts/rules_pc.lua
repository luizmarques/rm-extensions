-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Race
function SetRace(nodeChar, nodeRace)
	--[[ Stat modifiers ]]
	if nodeRace then
		for sNodeName, vStatBonus in pairs(DB.getChildren(nodeRace, "statbonuses")) do
			DB.setValue(nodeChar, "abilities." .. sNodeName .. ".race", "number", vStatBonus.getValue());
		end
	end
	
	--[[ RR modifiers ]]
	if nodeRace then
		for sNodeName, vRRBonus in pairs(DB.getChildren(nodeRace, "resistances")) do
			DB.setValue(nodeChar, "rr.base." .. sNodeName .. ".race", "number", vRRBonus.getValue());
		end
	end
	
	DB.setValue(nodeChar, "senses", "string", DB.getValue(nodeRace, "senses", ""));
	
	Rules_PC.SetBaseMoveRate(nodeChar);
end

function ClearRace(nodeChar)
	--[[ Stat modifiers ]]
	if nodeChar then
		for k, vStat in pairs(DB.getChildren(nodeChar, "abilities")) do
			DB.setValue(vStat, "race", "number", 0);
		end
	end
	
	--[[ RR modifiers ]]
	if nodeChar then
		for k, vRR in pairs(DB.getChildren(nodeChar, "rr.base")) do
			DB.setValue(vRR, "race", "number", 0);
		end
	end

	DB.setValue(nodeChar, "senses", "string", "");
	
	Rules_PC.SetBaseMoveRate(nodeChar);
end

function IsElf(nodeChar)
	local sRaceName = DB.getValue(nodeChar, "race", "");
	local bIsElf = false;
	
	if string.find(string.lower(sRaceName), "elf") or string.find(string.lower(sRaceName), "elves") 
				or string.find(string.lower(sRaceName), "dyari") or string.find(string.lower(sRaceName), "erlini") 
				or string.find(string.lower(sRaceName), "linaeri") or string.find(string.lower(sRaceName), "loari") 
				or string.find(string.lower(sRaceName), "shuluri") or string.find(string.lower(sRaceName), "eritari") 
				or string.find(string.lower(sRaceName), "ky'taari") or string.find(string.lower(sRaceName), "punkari") 
				or string.find(string.lower(sRaceName), "sulini") or string.find(string.lower(sRaceName), "vorloi") 
				or string.find(string.lower(sRaceName), "sindar") or string.find(string.lower(sRaceName), "vanyar") 
				or string.find(string.lower(sRaceName), "noldor") or string.find(string.lower(sRaceName), "silvan") then
		bIsElf = true;
	end

	return bIsElf;
end

function IsHalfling(nodeChar)
	local sRaceName = DB.getValue(nodeChar, "race", "");
	local bIsHalfling = false;

	if string.find(string.lower(sRaceName), "halfling") or string.find(string.lower(sRaceName), "hobbit") then
		bIsHalfling = true;
	end

	return bIsHalfling;
end


-- Stats
function CombinedStatBonus(nodeChar, sStats, sSkillName)  -- Change for different rules
	local nBonus = 0;
	local aStatList = Rules_Stats.StatList(sStats);

	if nodeChar and #aStatList > 0 then
		for _, vStat in pairs(aStatList) do
			local nStatBonus = Rules_PC.StatBonus(nodeChar, vStat.nodename, sSkillName);
			nBonus = nBonus + nStatBonus;
		end
	
		nBonus = math.floor((nBonus / #aStatList) + 0.5); -- Needed for RMC. Not needed for RMFRP and RMU
	end	

	return nBonus;
end

function StatBonus(nodeChar, sStatNodeName, sSkillName)
	local nodeStat = DB.getChild(nodeChar, "abilities." .. sStatNodeName .. ".total");

	if nodeStat then
		local nStatBonus = nodeStat.getValue();

		if sSkillName then
			local sOptRC422 = string.lower(OptionsManager.getOption("RC422"));
		
			-- Check Rolemaster Companion 1 option 4.22  
			if sOptRC422 and sOptRC422 ~= string.lower(Interface.getString("option_val_none")) and sStatNodeName == "selfdiscipline" then
				local sRace = DB.getValue(nodeChar, "race", "");
				local bIsRace = false;
				if (sOptRC422 == string.lower(Interface.getString("option_val_elves")) 
								or sOptRC422 == string.lower(Interface.getString("option_val_elves_halflings")))
								and Rules_PC.IsElf(nodeChar) then
					bIsRace = true;
				end
				if (sOptRC422 == string.lower(Interface.getString("option_val_halflings")) 
								or sOptRC422 == string.lower(Interface.getString("option_val_elves_halflings")))
								and Rules_PC.IsHalfling(nodeChar) then
					bIsRace = true;
				end

				if bIsRace then
					-- PC is an appropriate race.  Is it the right skill for the options?
					local bIsSkill = false;
					if (string.lower(sSkillName) == "hide" or string.lower(sSkillName) == "stalk") 
								and string.lower(OptionsManager.getOption("RC422A")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "adrenal moves**" 
								and string.lower(OptionsManager.getOption("RC422B")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "diving" 
								and string.lower(OptionsManager.getOption("RC422C")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "fletching" 
								and string.lower(OptionsManager.getOption("RC422D")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "meditation" 
								and string.lower(OptionsManager.getOption("RC422E")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "signaling"
								and string.lower(OptionsManager.getOption("RC422F")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "skiing" 
								and string.lower(OptionsManager.getOption("RC422G")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					elseif string.lower(sSkillName) == "tumbling"  
								and string.lower(OptionsManager.getOption("RC422H")) == string.lower(Interface.getString("option_val_on")) then
						bIsSkill = true;
					end

					if bIsSkill then		
						-- PC is an appropriate race and the skill matches one of the turned on options
						local nRaceBonus = DB.getValue(nodeChar, "abilities.selfdiscipline.race", 0);
						if nRaceBonus < 0 then
							-- Change the Stat Bonus so that the Racial Bonus is now positive instead of negative
							nStatBonus = nStatBonus + (-2 * nRaceBonus);
						end
					end
				end
			end
		end
		
		return nStatBonus;
	else
		return 0;
	end
end

-- Realm
function Realm(nodeChar)
	return DB.getValue(nodeChar, "realm", "");
end

function RealmPPMultiplier(nodeChar)
	local nMultiplier = 0;

	if string.lower(OptionsManager.getOption("CL01")) == string.lower(Interface.getString("option_val_on")) then
		nMultiplier = Rules_Stats.StatBonusPPMultiplier(Rules_PC.RealmStatBonus(nodeChar));
	else
		nMultiplier = Rules_Stats.PPMultiplier(Rules_PC.RealmStatAverage(nodeChar));
	end

	return nMultiplier;	
end

function RealmStatBonus(nodeChar)
	local sRealm = Rules_PC.Realm(nodeChar);
	local nTotalBonus = 0;
	local nStatCount = 0;

	if string.find(sRealm, "Ess") or string.find(sRealm, "Arc") then
		nTotalBonus = nTotalBonus + DB.getValue(nodeChar, "abilities.empathy.total", 0);
		nStatCount = nStatCount + 1;
	end
	if string.find(sRealm, "Chan") or string.find(sRealm, "Arc") then
		nTotalBonus = nTotalBonus + DB.getValue(nodeChar, "abilities.intuition.total", 0);
		nStatCount = nStatCount + 1;
	end
	if string.find(sRealm, "Ment") or string.find(sRealm, "Arc") then
		nTotalBonus = nTotalBonus + DB.getValue(nodeChar, "abilities.presence.total", 0);
		nStatCount = nStatCount + 1;
	end
	
	if nStatCount > 0 then
		nTotalBonus = nTotalBonus / nStatCount;
	end
	
	return nTotalBonus;	
end

function RealmStatAverage(nodeChar)
	local sRealm = Rules_PC.Realm(nodeChar);
	local sStatTotal = 0;
	local nStatCount = 0;
	
	if string.find(sRealm, "Ess") or string.find(sRealm, "Arc") then
		sStatTotal = sStatTotal + DB.getValue(nodeChar, "abilities.empathy.temp_current", 0);
		nStatCount = nStatCount + 1;
	end
	if string.find(sRealm, "Chan") or string.find(sRealm, "Arc") then
		sStatTotal = sStatTotal + DB.getValue(nodeChar, "abilities.intuition.temp_current", 0);
		nStatCount = nStatCount + 1;
	end
	if string.find(sRealm, "Ment") or string.find(sRealm, "Arc") then
		sStatTotal = sStatTotal + DB.getValue(nodeChar, "abilities.presence.temp_current", 0);
		nStatCount = nStatCount + 1;
	end

	if nStatCount > 0 then
		sStatTotal = sStatTotal / nStatCount;
	end
	
	return sStatTotal;	
end

-- Miscellaneous Characteristics
function Hits(nodeChar)
	return Rules_PC.BodyDevelopment(nodeChar);
end

function BodyDevelopment(nodeChar)
	local nTotal = 0;

	local nodeSkill = nil;
	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		local sFullname = DB.getValue(vSkill, "fullname", "string", "");
		if sFullname == "Body Development" then
			nodeSkill = vSkill;
		end
	end
	if nodeSkill then
		nTotal = DB.getValue(nodeSkill, "total", "number", 0);
	end

	return nTotal;
end

function PowerPoints(nodeChar)
	local nLevel = DB.getValue(nodeChar, "level", 0);
	local nPPMult = DB.getValue(nodeChar, "pp.mult", 1);
	local nRealmPPMult = Rules_PC.RealmPPMultiplier(nodeChar);
	local nBonus = nLevel * nRealmPPMult;

	if string.lower(OptionsManager.getOption("CL16")) == string.lower(Interface.getString("option_val_on")) then
		nBonus = Rules_PC.PowerPointDevTotal(nodeChar);
	end
	
	if string.lower(OptionsManager.getOption("SL04")) == string.lower(Interface.getString("option_val_on")) then
		nBonus = nBonus + 10 + math.ceil(Rules_PC.RealmStatBonus(nodeChar) / 10);
	end
	
	nBonus = nBonus * nPPMult;
	
	return math.floor(nBonus);
end

function PowerPointDevTotal(nodeChar)
	local nTotal = 0;

	local nodeSkill = nil;
	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		local sFullname = DB.getValue(vSkill, "fullname", "string", "");
		if sFullname == "Power Point Development***" then
			nodeSkill = vSkill;
		end
	end
	if nodeSkill then
		local nRankBonus = DB.getValue(nodeSkill, "rankbonus", 0);
		local nStat = Rules_PC.RealmPPMultiplier(nodeChar);
		local nLevel = DB.getValue(nodeSkill, "level", 0);
		local nItem = DB.getValue(nodeSkill, "item", 0);
		local nSpecial = DB.getValue(nodeSkill, "special", 0);
		local nMisc = DB.getValue(nodeSkill, "misc", 0);
		nTotal = (nRankBonus * nStat) + nLevel + nItem + nSpecial + nMisc;

		-- Update the Stat Bonus if it has changed
		if nStat ~= DB.getValue(nodeSkill, "statbonus", 0) then
			DB.setValue(nodeSkill, "statbonus", "number", nStat);
		end
	end
	
	return nTotal;
end

function PPMult(nodeChar, sAdderMultName)
	local nodeInventoryList = DB.createChild(nodeChar, "inventorylist");
	local nPPMult = 1;
	if nodeInventoryList then
		for _, vItem in pairs(DB.getChildren(nodeInventoryList)) do
			if sAdderMultName == DB.getValue(vItem, "name", "") then
				nPPMult = DB.getValue(vItem, "multiplierbonus", 1);
			end
		end
	end
	if nPPMult < 1 then
		nPPMult = 1;
	end
	DB.setValue(nodeChar, "pp.mult", "number", nPPMult);
end

function SpellAdder(nodeChar, sAdderMultName)
	local nodeInventoryList = DB.createChild(nodeChar, "inventorylist");
	local nSpellAdder = 0;
	if nodeInventoryList then
		for _, vItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
			if sAdderMultName == DB.getValue(vItem, "name", "") then
				nSpellAdder = DB.getValue(vItem, "adderbonus", 0);
			end
		end
	end
	DB.setValue(nodeChar, "pp.spelladdermax", "number", nSpellAdder);
end

function TotalDP(nodeChar)
	local nTotalDP = 0;

	if string.lower(OptionsManager.getOption("CL112")) == string.lower(Interface.getString("option_val_off")) then  -- Check if Flat DP Option is Off
		for _, vStat in pairs(DB.getChildren(nodeChar, "abilities")) do
			nDev = DB.getValue(vStat, "dev", 0);
			nTemp = DB.getValue(vStat, "temp", 0);
			nTotalBonus = DB.getValue(vStat, "total", 0);
			if nDev == 1 or string.lower(OptionsManager.getOption("RC552")) == string.lower(Interface.getString("option_val_on")) then 
					nTotalDP = nTotalDP + Rules_Stats.DPs(nTemp, nTotalBonus);
			end
		end
	else -- Flat DP Option is On
		nTotalDP = tonumber(OptionsManager.getOption("CL112"));
	end
	
	return nTotalDP;
end

function SetBaseMoveRate(nodeChar)
	if nodeChar then
		local sHeight = DB.getValue(nodeChar, "height", "");
		local nBMR = Rules_Move.BaseMovementRate(sHeight);
		DB.setValue(nodeChar, "bmr.race", "number", nBMR);
	end	
end

function GetTotalBMR(nodeChar)
	local bShowBMRStatInfo = false;
	local bShowBMREncumbranceInfo = false;
	local nBMRRace = DB.getValue(nodeChar, "bmr.race", 0);
	local nBMRMisc = DB.getValue(nodeChar, "bmr.misc", 0);
	local nBMRStat = DB.getValue(Rules_PC.BMRStatNode(nodeChar), "", 0);
	local nArmorQUPenalty = DB.getValue(nodeChar, "dbpen", 0);

	if nBMRStat > 0 and nArmorQUPenalty < 0 then
		nBMRStat = nBMRStat + nArmorQUPenalty;
		if nBMRStat < 0 then
			nBMRStat = 0;
		end
		bShowBMRStatInfo = true;
	end

	local nBMRTotal = nBMRRace + nBMRStat + nBMRMisc;
	local nBMREncumbrance = DB.getValue(nodeChar, "encumbrance.total", 0);
	if string.lower(OptionsManager.getOption("CEMV")) == string.lower(Interface.getString("option_val_on")) then 
		nBMRTotal = nBMRTotal + nBMREncumbrance;
	else
		if nBMREncumbrance < 0 then
			bShowBMREncumbranceInfo = true;
		end
	end

	return nBMRTotal, nBMRStat, bShowBMRStatInfo, bShowBMREncumbranceInfo;
end

function MMPenalty(nodeChar)
	local nMMMax = DB.getValue(nodeChar, "mmmax", 0);
	local nodeMMSkill = nil;
	local sMMSkillName = OptionManager.invoke("mmskillname", DB.getValue(nodeChar, "at", 1));
	local sEquippedArmor = DB.getValue(nodeChar, "equipped_armor", "");
	local nMMPenalty = nMMMax;
	
	-- Check the EquippedArmor item for the Armor MM Skill
	if sEquippedArmor and sEquippedArmor ~= "" then
		local nodeInventoryList = DB.createChild(nodeChar, "inventorylist");

		if nodeInventoryList then
			for _, vItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
				if sEquippedArmor == DB.getValue(vItem, "name", "") then
					local sArmorMMSkill = DB.getValue(vItem, "armor_mm_skill", "");
					if sArmorMMSkill ~= "" then
						sMMSkillName = sArmorMMSkill;
					end
				end
			end
		end
	end

	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		local sFullname = DB.getValue(vSkill, "fullname", "zzzzzzzzzzz");
		if sFullname == sMMSkillName then
			nodeMMSkill = vSkill;
		end
	end
	if nodeMMSkill then
		nMMPenalty = nMMPenalty + DB.getValue(nodeMMSkill, "total", 0);
		if nMMPenalty > DB.getValue(nodeChar, "mmmin", nMMPenalty) then
			nMMPenalty = DB.getValue(nodeChar, "mmmin", nMMPenalty);
		end
	end

	if nMMPenalty < nMMMax then
		nMMPenalty = nMMMax;
	end
	DB.setValue(nodeChar, "mmpenalty", "number", nMMPenalty);
	
	return nMMPenalty;
end

function AdrenalDefence(nodeChar)
	local nBonus = 0;

	local nodeADSkill = nil;
	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		local sFullname = DB.getValue(vSkill, "fullname", "");
		if sFullname == "Adrenal Defence" or sFullname == "Adrenal Defense" then
			nodeADSkill = vSkill;
		end
	end
	if nodeADSkill then
		nBonus = DB.getValue(nodeADSkill, "total", 0);
	end
	
	if nBonus < 0 then
		nBonus = 0;
	end

	return nBonus;
end

function DBStatNode(nodeChar)
	return DB.getChild(nodeChar, Rules_Stats.sDBStatNodeName);
end
function DBStatBonus(nodeChar)
	return DB.getValue(nodeChar, Rules_Stats.sDBStatNodeName, 0);
end

function BMRStatNode(nodeChar)
	return DB.getChild(nodeChar, Rules_Stats.sBMRStatNodeName);
end
function BMRStatBonus(nodeChar)
	return DB.getValue(nodeChar, Rules_Stats.sBMRStatNodeName, 0);
end

function EncumbranceStatNode(nodeChar)
	return DB.getChild(nodeChar, Rules_Stats.sEncumbranceStatNodeName);
end
function EncumbranceStatBonus(nodeChar)
	local nBonus = DB.getValue(nodeChar, Rules_Stats.sEncumbranceStatNodeName, 0);
	if nBonus > 0 then
		return nBonus;
	else
		return 0;
	end
end

function ArmorQuicknessPenalty(node)
	local nStBonus = Rules_PC.EncumbranceStatBonus(node);
	local nEncBase = DB.getValue(node, "encumbrance.base", 0);
	local nEncMisc = DB.getValue(node, "encumbrance.misc", 0);
	local nPenalty = DB.getValue(node, "qupen", 0);

	-- Reduce Strength Bonus by amount used to reduce Encumbrance but not below zero
	nStBonus = nStBonus + nEncBase + nEncMisc;
	if nStBonus < 0 then
		nStBonus = 0;
	end
	
	-- Reduce Penalty by remain Strength bonus
	nPenalty = nPenalty + nStBonus;
	if nPenalty > 0 then
		nPenalty = 0;
	end
	
	return nPenalty;
end

function MagicDB(nodeChar)
	local nMagicDB = 0;
	local sEquippedArmor = DB.getValue(nodeChar, "equipped_armor", "");
	local sEquippedHelmet = DB.getValue(nodeChar, "equipped_helmet", "");
	local sEquippedPrimaryHand = DB.getValue(nodeChar, "equipped_primary_hand", "");
	local sEquippedSecondaryHand = DB.getValue(nodeChar, "equipped_secondary_hand", "");
	local sEquippedAdderMultiplier = DB.getValue(nodeChar, "equipped_adder_multiplier", "");

	-- Check Equipped Items in Inventory
	for _, nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		local bID = (DB.getValue(nodeItem, "isidentified", 1) == 1);
		if bID then
			local sItemName = DB.getValue(nodeItem, "name", "");
			local nCarried = DB.getValue(nodeItem, "carried", 0);
			
			-- Get Defense Bonus for Equipped Items
			if nCarried == 2  -- 2 = Equipped, 1 = Carried
						or sEquippedArmor == sItemName
						or sEquippedHelmet == sItemName
						or sEquippedPrimaryHand == sItemName
						or sEquippedSecondaryHand == sItemName
						or sEquippedAdderMultiplier == sItemName then
				local nItemMagicDB = DB.getValue(nodeItem, "defensebonus", 0);
				nMagicDB = nMagicDB + nItemMagicDB;
			end		
		end
	end
	
	return nMagicDB;
end

function MagicDBNoID(nodeChar)
	local nMagicDB = 0;

	local nodeEquippedArmor = ItemManager2.GetEquippedItemNode(DB.getValue(nodeChar, "equipped_armor_link", nil))
	local nodeEquippedHelmet = ItemManager2.GetEquippedItemNode(DB.getValue(nodeChar, "equipped_helmet_link", nil))
	local nodeEquippedPrimaryHand = ItemManager2.GetEquippedItemNode(DB.getValue(nodeChar, "equipped_primary_hand_link", nil))
	local nodeEquippedSecondaryHand = ItemManager2.GetEquippedItemNode(DB.getValue(nodeChar, "equipped_secondary_hand_link", nil))
	local nodeEquippedAdderMultiplier = ItemManager2.GetEquippedItemNode(DB.getValue(nodeChar, "equipped_adder_multiplier_link", nil))

	-- Check Equipped Items in Inventory
	for _, nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		local bID = (DB.getValue(nodeItem, "isidentified", 1) == 1);
		if not bID then
			local sItemName = DB.getValue(nodeItem, "name", "");
			local nCarried = DB.getValue(nodeItem, "carried", 0);
			
			-- Get Defense Bonus for Equipped Items
			if nCarried == 2  -- 2 = Equipped, 1 = Carried
						or nodeEquippedArmor == nodeItem
						or nodeEquippedHelmet == nodeItem
						or nodeEquippedPrimaryHand == nodeItem
						or nodeEquippedSecondaryHand == nodeItem
						or nodeEquippedAdderMultiplier == nodeItem then
				local nItemMagicDB = DB.getValue(nodeItem, "defensebonus", 0);
				nMagicDB = nMagicDB + nItemMagicDB;
			end		
		end
	end

	return nMagicDB;
end

function ShieldDB(nodeChar)
	local nShieldDB = 0;

	-- Check Equipped Items in Inventory
	local sEquippedSecondaryHand = DB.getValue(nodeChar, "equipped_secondary_hand", "");
	for _, nodeItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		local sItemName = DB.getValue(nodeItem, "name", "");
		local nCarried = DB.getValue(nodeItem, "carried", 0);
		
		-- Get Defense Bonus for Equipped Items
		if nCarried == 2  -- 2 = Equipped, 1 = Carried
					or sEquippedSecondaryHand == sItemName then
			local nItemShieldDB = DB.getValue(nodeItem, "meleebonus", 0);
			nShieldDB = nShieldDB + nItemShieldDB;
		end			
	end
	
	return nShieldDB;
end

function GetInitMod(nodeChar)
	return DB.getValue(nodeChar, "initiative.total", 0);
end

-- Skills
function SkillList(nodeChar)
	if not nodeChar then
		return { "" };
	end

	local aSkillList = {};
	table.insert(aSkillList, "");	
	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		if DB.getChild(vSkill, "name") then
			table.insert(aSkillList, DB.getValue(vSkill, "name", ""));	
		end
	end
	return aSkillList;
end

function SkillNode(nodeChar, sSkillName)
	if not nodeChar then
		return nil;
	end

	local nodeSkill = nil;
	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		if DB.getValue(vSkill, "name", "") == sSkillName then
			nodeSkill = vSkill;
		end				
	end
	return nodeSkill;
end

function SkillTotal(nodeChar, sSkillName)
	if sSkillName == "" then
		return 0;
	end

	local nTotal = nil;
	
	if nodeChar then
		for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
			if DB.getValue(vSkill, "name", "") == sSkillName then
				nTotal = DB.getValue(vSkill, "total", 0);
			end				
		end
	end
	
	if nTotal then
		return nTotal;
	else
		return Rules_PC.SkillUntrainedTotal(nodeChar, sSkillName);
	end
end

function SkillTotalChanged(nodeChar, sSkillName, sSkillFullName, nSkillTotal)
	-- Update Hits and Max PP
	if sSkillFullName == "Body Development" then
		if string.lower(OptionsManager.getOption("CCHP")) == string.lower(Interface.getString("option_val_on")) then
			DB.setValue(nodeChar, "hits.max", "number", Rules_PC.Hits(nodeChar));
		end
	elseif sSkillFullName == "Power Point Development***" then
		if string.lower(OptionsManager.getOption("CCPP")) == string.lower(Interface.getString("option_val_on")) then
			DB.setValue(nodeChar, "pp.max", "number", Rules_PC.PowerPoints(nodeChar));
		end
	elseif sSkillFullName == "Adrenal Defense" then
		if DB.getValue(nodeChar, "at", 1) == 1 and nSkillTotal > 0 and string.lower(OptionsManager.getOption("CCAD")) == string.lower(Interface.getString("option_val_on")) then
			DB.setValue(nodeChar, "dbad", "number", nSkillTotal);
		end
	elseif sSkillFullName == "Perception" then
		DB.setValue(nodeChar, "links.skill_perception_total", "number", nSkillTotal);
	end

	-- Update Weapon OB
	for _, vWeapon in pairs(DB.getChildren(nodeChar, "weapons")) do
		if DB.getValue(vWeapon, "associatedskill", "") == sSkillName then
			local _, sRecordName = DB.getValue(vWeapon, "open", nil);
			if sRecordName and sRecordName ~= "" then
				nodeItem = DB.findNode(sRecordName);
			else
				nodeItem = vWeapon;
			end
			DB.setValue(nodeItem, "skillbonus", "number", nSkillTotal);
			local iWeaponBonus = DB.getValue(nodeItem, "weaponbonus", 0);
			DB.setValue(nodeItem, "ob", "number", nSkillTotal + iWeaponBonus);
		end
	end
end

function SkillUntrainedTotal(nodeChar, sSkillName)
	local sStats = Rules_Skills.Stats(sSkillName);
	return Rules_PC.CombinedStatBonus(nodeChar, sStats) - 25;
end

function UpdateLevelBonuses(nodeChar)
	if not nodeChar then
		return;
	end

	for _, vCharSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		if DB.getValue(vCharSkill, "levelbonus.core", "") == "" and DB.getValue(vCharSkill, "levelbonus.rm2", "") == "" and 
						DB.getValue(vCharSkill, "levelbonus.rmfrp", "") == "" and DB.getValue(vCharSkill, "levelbonus.rmcompanion2", "") == "" then
			local aMappings = LibraryData.getMappings("skill");
			for _, vMapping in ipairs(aMappings) do
				for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
					if DB.getValue(vSkill, "fullname", "") == DB.getValue(vCharSkill, "fullname", "") then
						DB.setValue(vCharSkill, "levelbonus.core", "string", DB.getValue(vSkill, "levelbonus.core", ""));
						DB.setValue(vCharSkill, "levelbonus.rm2", "string", DB.getValue(vSkill, "levelbonus.rm2", ""));
						DB.setValue(vCharSkill, "levelbonus.rmfrp", "string", DB.getValue(vSkill, "levelbonus.rmfrp", ""));
						DB.setValue(vCharSkill, "levelbonus.rmcompanion2", "string", DB.getValue(vSkill, "levelbonus.rmcompanion2", ""));
					end
				end
			end
		end
	end
end

function SkillArmorFactor(nodeChar, sSkillName)
	if (sSkillName or "") == "" then
		return 0;
	end
	if not nodeChar then
		return 1;
	end

	local nArmorFactor = 1;
	for _, vSkill in pairs(DB.getChildren(nodeChar, "skills")) do
		if DB.getValue(vSkill, "name", "") == sSkillName then
			nArmorFactor = DB.getValue(vSkill, "armorfactor", 1);
		end				
	end
	return nArmorFactor;
end

-- Spells
function SpellList(nodeChar)
	if not nodeChar then
		return {};
	end

	local aSpellList = {};
	for _, vSpellList in pairs(DB.getChildren(nodeChar, "spells")) do
		if DB.getChild(vSpellList, "name") then
			table.insert(aSpellList, DB.getValue(vSpellList, "name", ""));	
		end
	end
	return aSpellList;
end

function SpellsFromSpellListName(nodeChar, sSpellList)
	if not nodeChar or ((sSpellList or "") == "") then
		return {};
	end

	local aSpells = {};
	for _, vSpellList in pairs(DB.getChildren(nodeChar, "spells")) do
		if DB.getValue(vSpellList, "name", "") == sSpellList then
			local sClass, sRecordName = DB.getValue(vSpellList, "open", nil);
			if sRecordName and sRecordName ~= "" then
				local nodeSpellList = DB.findNode(sRecordName);
				if nodeSpellList and DB.getChild(nodeSpellList, "spells") then
					for _, vSpell in pairs(DB.getChildren(nodeSpellList, "spells")) do
						local nLevel = DB.getValue(vSpell, "level", 0);
						if nLevel < 10 then
							nLevel = "0" .. nLevel;
						end
						table.insert(aSpells, nLevel .. ". " .. DB.getValue(vSpell, "name", ""));
					end
					return aSpells;
				end
			end
		end
	end
	return aSpells;
end

function LevelKnownFromSpellListName(nodeChar, sSpellList)
	if not nodeChar or ((sSpellList or "") == "") then
		return 0;
	end

	local nKnown = 0;
	for _, vSpellList in pairs(DB.getChildren(nodeChar, "spells")) do
		if DB.getValue(vSpellList, "name", "") == sSpellList then
			nKnown = DB.getValue(vSpellList, "maxlevel", 0);
		end
	end
	return nKnown;
end

function RealmFromSpellListName(nodeChar, sSpellList)
	if not nodeChar or ((sSpellList or "") == "") then
		return "";
	end

	local sRealm = "";
	for _, vSpellList in pairs(DB.getChildren(nodeChar, "spells")) do
		if DB.getValue(vSpellList, "name", "") == sSpellList then
			local sClass, sRecordName = DB.getValue(vSpellList, "open", nil);
			if sRecordName and sRecordName ~= "" then
				local nodeSpellList = DB.findNode(sRecordName);
				if nodeSpellList and DB.getChild(nodeSpellList, "spells") then
					sRealm = DB.getValue(nodeSpellList, "realm", "");
				end
			end
		end
	end
	return sRealm;
end


-- Next Level
function NextLevelXP(nCurrentLevel)
	local nNextLevel = nCurrentLevel + 1;
	
	if nNextLevel == 1 then
		return 10000;
	elseif nNextLevel == 2 then
		return 20000;
	elseif nNextLevel == 3 then
		return 30000;
	elseif nNextLevel == 4 then
		return 40000;
	elseif nNextLevel == 5 then
		return 50000;
	elseif nNextLevel == 6 then
		return 70000;
	elseif nNextLevel == 7 then
		return 90000;
	elseif nNextLevel == 8 then
		return 110000;
	elseif nNextLevel == 9 then
		return 130000;
	elseif nNextLevel == 10 then
		return 150000;
	elseif nNextLevel == 11 then
		return 180000;
	elseif nNextLevel == 12 then
		return 210000;
	elseif nNextLevel == 13 then
		return 240000;
	elseif nNextLevel == 14 then
		return 270000;
	elseif nNextLevel == 15 then
		return 300000;
	elseif nNextLevel == 16 then
		return 340000;
	elseif nNextLevel == 17 then
		return 380000;
	elseif nNextLevel == 18 then
		return 420000;
	elseif nNextLevel == 19 then
		return 460000;
	elseif nNextLevel == 20 then
		return 500000;
	elseif nNextLevel > 20 then
		return (nNextLevel - 20) * 50000 + 500000;
	else
		return 0;
	end
end

-- Get Inventory Item Links
function GetInventoryItemLink(nodeChar, sItemName, sItemCategory)
	local sNodeName = "";

	for _, vItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if sItemName == ItemManager2.getDisplayName(vItem) then
			if sItemCategory then
				local sItemType = DB.getValue(vItem, "type", "");
				if sItemCategory == ItemManager2.CategoryHelmet and ItemManager2.IsHelmet(sItemType, sItemName) then
					sNodeName = DB.getPath(vItem);
				elseif sItemCategory == ItemManager2.CategoryPrimaryHand and ItemManager2.IsPrimaryHandType(sItemType) then
					sNodeName = DB.getPath(vItem);
				elseif sItemCategory == ItemManager2.CategorySecondaryHand and ItemManager2.IsSecondaryHandType(sItemType) then
					sNodeName = DB.getPath(vItem);
				elseif sItemCategory == ItemManager2.CategoryAdderMultipler then
					local nAdder = DB.getValue(vItem, "adderbonus", 0);
					local nMultiplier = DB.getValue(vItem, "multiplierbonus", 0);
					if nAdder + nMultiplier > 0 then
						sNodeName = DB.getPath(vItem);
					end
				end
			else
				sNodeName = DB.getPath(vItem);
			end
		end
	end
	
	if sNodeName ~= "" then
		return "item", sNodeName;
	else
		return nil;
	end
end
