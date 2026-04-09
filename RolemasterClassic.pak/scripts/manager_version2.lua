-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local rsname = "RolemasterClassic";

function onInit()
	if Session.IsHost then
		updateCampaign();
	end

	DB.onAuxCharLoad = onCharImport;
	DB.onImport = onImport;
end

function onCharImport(nodePC)
	local _, _, aMajor, aMinor = DB.getImportRulesetVersion();
	updateChar(nodePC, aMajor[rsname], aMinor[rsname]);
end

function onImport(node)
	local aPath = StringManager.split(DB.getPath(node), ".");
	if #aPath == 2 and aPath[1] == "charsheet" then
		local _, _, aMajor, aMinor = DB.getImportRulesetVersion();
		updateChar(node, aMajor[rsname], aMinor[rsname]);
	end
end

function updateChar(nodePC, nMajor, nMinor)
	local nVersion = getVersionNumber(nMajor, nMinor);
	
	if nVersion < 2 then
		migrateChar1(nodePC);
	end
	if nVersion < 2.01 then
		migrateChar2_0(nodePC);
	end
end

function getVersionNumber(nMajor, nMinor)
	if not nMajor then
		nMajor = 0;
	end
	if not nMinor then
		nMinor = 0;
	end
	
	return nMajor + (nMinor/100);
end

function updateCampaign()
	local _a, _b, aMajor, aMinor, aExtra = DB.getRulesetVersion();
	local major = aMajor[rsname];
	local minor = aMinor[rsname];
	local nVersion = getVersionNumber(major, minor);

	if nVersion < 2.03 then
		ChatManager.SystemMessage("Migrating campaign database to latest data version. (" .. rsname ..")");
		DB.backup();
		
		if nVersion < 2 then
			convertChars1();
			convertCTEntries1();
			convertPreferences1();
			convertEncounters1();
			convertNotes1();
		end
		if nVersion < 2.01 then
			convertChars2_0();
			convertCTEntries2_0();
		end
		if nVersion < 2.02 then
			convertChars2_1();
			convertCTEntries2_1();
		end
		if nVersion < 2.03 then
			convertCTEntries2_2();
		end
	end
end

function convertChars1()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar1(nodeChar);
	end
end

function convertChars2_0()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar2_0(nodeChar);
	end
end

function convertChars2_1()
	for _,nodeChar in pairs(DB.getChildren("charsheet")) do
		migrateChar2_1(nodeChar);
	end
end

function migrateChar1(nodeChar)
	-- Migrate Combat Weapons Tab
	if DB.getChildCount(nodeChar, "weapons") > 0 then
		for _,vWeapon in pairs(DB.getChildren(nodeChar, "weapons")) do
			local nodeType = DB.getChild(vWeapon, "type");
			if DB.getType(nodeType) == "number" then
				iType = DB.getValue(vWeapon, "type", 0);
				DB.deleteChild(vWeapon, "type");
				DB.setValue(vWeapon, "type", "string", ItemManager2.getItemTypeString(iType));
			end
		end
	end
	
	-- Remove old InitBonus
	if DB.getChild(nodeChar, "initbonus") then
		DB.deleteChild(nodeChar, "initbonus");
	end
	
	-- Migrate Inventory Items
	updateInventoryList(nodeChar, "weapon");
	updateInventoryList(nodeChar, "herb");
	updateInventoryList(nodeChar, "transport");
	
	-- Update Inventory Items 
	local nodeInventoryList = DB.createChild(nodeChar, "inventorylist");
	if nodeInventoryList then
		for _, vItem in pairs(DB.getChildren(nodeChar, "inventorylist")) do
			local msgItem = {};
			msgItem.nodeName = DB.getPath(vItem);
			ItemManager2.notifyUpdateToCoreRPG(msgItem);
		end
	end

	-- Update Combat Tab Weapon Items 
	local nodeWeaponList = DB.createChild(nodeChar, "weapons");
	if nodeInventoryList then
		for _, vItem in pairs(DB.getChildren(nodeChar, "weapons")) do
			local msgItem = {};
			msgItem.nodeName = DB.getPath(vItem);
			ItemManager2.notifyUpdateToCoreRPG(msgItem);
		end
	end
	
	-- Migrate Coins
	if DB.getChildCount(nodeChar, "treasure.coins") > 0 then
		local nodeOldCoinList = DB.getChild(nodeChar, "treasure.coins");
		local nodeNewCoinList = DB.createChild(nodeChar, "coins");
		if nodeOldCoinList and nodeNewCoinList then
			local nodeOldCoin = nil;
			local nodeNewCoin = nil;
			for i = 1, 7 do
				nodeOldCoin = DB.getChild(nodeOldCoinList, "id-0000" .. i);
				nodeNewCoin = DB.createChild(nodeNewCoinList, "slot" .. i);
				if nodeOldCoin and nodeNewCoin then
					DB.setValue(nodeNewCoin, "name", "string", DB.getValue(nodeOldCoin, "name", ""));
					DB.setValue(nodeNewCoin, "amount", "number", DB.getValue(nodeOldCoin, "value", 0));
				end
			end
		end
	end

	-- Migrate Languages
	if DB.getChildCount(nodeChar, "languages") > 0 then
		local nodeLanguageList = DB.createChild(nodeChar, "languagelist");
		if nodeLanguageList then
			for _,vLanguage in pairs(DB.getChildren(nodeChar, "languages")) do
				local vLanguageItem = DB.createChild(nodeLanguageList);
				if vLanguageItem then
					DB.copyNode(vLanguage, vLanguageItem);
					DB.deleteNode(vLanguage);
				end
			end
		end
	end
	if DB.getChildCount(nodeChar, "languages") == 0 then
		DB.deleteChild(nodeChar, "languages");
	end	
	
	-- Migrate Remarks to Notes
	if DB.getChild(nodeChar,"remarks") then
		local sNotes = DB.getValue(nodeChar, "notes", "");
		sNotes = DB.getValue(nodeChar, "remarks", "") .. "\n" .. sNotes;
		DB.setValue(nodeChar, "notes", "string", sNotes);
		DB.deleteChild(nodeChar, "remarks");
	end

	-- Migrate Hits
	if DB.getChild(nodeChar,"hits") and not (DB.getChild(nodeChar, "hits.max") or DB.getChild(nodeChar, "hits.damage")) then
		local nHits = DB.getValue(nodeChar, "hits", 0)
		DB.deleteChild(nodeChar, "hits");
		DB.createChild(nodeChar, "hits");
		DB.setValue(nodeChar, "hits.max", "number", nHits);
	end
	if DB.getChild(nodeChar,"damage") then
		DB.setValue(nodeChar, "hits.damage", "number", DB.getValue(nodeChar, "damage", 0));
		DB.deleteChild(nodeChar, "damage");
	end
	
	-- Migrate Power Points
	if DB.getChild(nodeChar,"maxpower") then
		DB.createChild(nodeChar, "pp");
		DB.setValue(nodeChar, "pp.max", "number", DB.getValue(nodeChar, "maxpower", 0));
		DB.deleteChild(nodeChar, "maxpower");
	end
	if DB.getChild(nodeChar,"power") then
		DB.setValue(nodeChar, "pp.used", "number", DB.getValue(nodeChar, "power", 0));
		DB.deleteChild(nodeChar, "power");
	end
	
end

function migrateChar2_0(nodeChar)
	-- Check Combat Tab weapons and shields for links to Inventory items
	for _, nodeWeapon in pairs(DB.getChildren(nodeChar, "weapons")) do
		local sClass, sPath = DB.getValue(nodeWeapon, "open", nil); 
		if not sPath or sPath == "" or (sPath and string.find(sPath, ".weapons.")) then
			local sItemType = DB.getValue(nodeWeapon, "type", "");
			if ItemManager2.IsInventoryAttack(sItemType) then
				local sWeaponName = DB.getValue(nodeWeapon, "name", "");
				local bFound = false;
				for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
					local sItemName = DB.getValue(nodeItem, "name", "");
					if sWeaponName == sItemName then
						DB.setValue(nodeItem, "associatedskill", "string", DB.getValue(nodeWeapon, "associatedskill", ""));
						DB.setValue(nodeWeapon, "open", "windowreference", "item", DB.getPath(nodeItem));
						bFound = true;
					end
				end
				if not bFound then
					local nodeNewItem = DB.createChild(DB.createChild(nodeChar, "inventorylist"));
					DB.copyNode(nodeWeapon, nodeNewItem);
					DB.setValue(nodeWeapon, "open", "windowreference", "item", DB.getPath(nodeNewItem));
				end
			end
		end
	end

	-- Check Inventory Items for weapons or shields to add to the Combat Tab weapons
	if DB.getChild(nodeChar, "inventorylist") then
		for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
			local sItemType = DB.getValue(nodeItem, "type", "");
			if ItemManager2.IsInventoryAttack(sItemType) then
				local sItemNodeName = DB.getPath(nodeItem);
				local bFound = false;
				for _, nodeWeapon in ipairs(DB.getChildList(nodeChar, "weapons")) do
					local sClass, sPath = DB.getValue(nodeWeapon, "open", nil); 
					if sItemNodeName == sPath then
						bFound = true;
					end
				end
				if not bFound then
					local nodeNewWeapon = DB.createChild(DB.createChild(nodeChar, "weapons"));
					DB.setValue(nodeNewWeapon, "open", "windowreference", "item", sItemNodeName);
					DB.setValue(nodeNewWeapon, "type", "string", DB.getValue(nodeItem, "type", ""));
					DB.setValue(nodeNewWeapon, "name", "string", DB.getValue(nodeItem, "name", ""));
					DB.setValue(nodeNewWeapon, "ob", "number", DB.getValue(nodeItem, "ob", 0));
					DB.setValue(nodeNewWeapon, "fumble", "number", DB.getValue(nodeItem, "fumble", 0));
					DB.setValue(nodeNewWeapon, "meleebonus", "number", DB.getValue(nodeItem, "meleebonus", 0));
					DB.setValue(nodeNewWeapon, "missilebonus", "number", DB.getValue(nodeItem, "missilebonus", 0));
				end
			end
		end
	end
	
	-- Convert Martial Arts to attacks like other weapons and spells
	if DB.getChild(nodeChar, "martialarts") then
		for _, nodeMartialArt in ipairs(DB.getChildList(nodeChar, "martialarts")) do
			local iType = DB.getValue(nodeMartialArt, "type", 0);
			if iType > 0 then
				if iType == 1 then
					sTableID = "CLT-09";
					sTableName = "MA Sweeps and Throws";
				else
					sTableID = "CLT-08";
					sTableName = "MA Striking";
				end

				local sName = DB.getValue(nodeMartialArt, "name", "");
				if sName == "" then
					sName = sTableName;
				end
				
				local nStatBonus = DB.getValue(nodeMartialArt, "bonus", 0);
				for nRank = 1, 4 do
					local nRankBonus = DB.getValue(nodeMartialArt, "rank"..nRank, 0);
					if nRankBonus ~= 0 then
						local nRankTotal = DB.getValue(nodeMartialArt, "rank"..nRank.."total", 0);
						if nRankTotal == 0 then
							nRankTotal = nRankBonus + nStatBonus;
						end
						local nHitsMultiplier = DB.getValue(nodeMartialArt, "hitsmultiplier", 1);
						local nodeAttack = DB.createChild(DB.getChild(nodeChar, "weapons"));
						DB.setValue(nodeAttack, "name", "string", sName .. " (Rank " .. nRank .. ")");
						DB.setValue(nodeAttack, "ob", "number", nRankTotal);
						DB.setValue(nodeAttack, "max_level", "number", nRank);
						DB.setValue(nodeAttack, "fumble", "number", 2);
						DB.setValue(nodeAttack, "hitsmultiplier", "number", nHitsMultiplier);
						DB.setValue(nodeAttack, "type", "string", "Natural Weapon");
						DB.setValue(nodeAttack, "attacktable.name", "string", sTableName);
						DB.setValue(nodeAttack, "attacktable.tableid", "string", sTableID);
						DB.setValue(nodeAttack, "criticaltable", "string", "Attack Default");
					end
				end
			end
		end
		DB.deleteChild(nodeChar, "martialarts");
	end
end

function migrateChar2_1(nodeChar)
	-- Convert Rolemaster Companion 1 Spell List Links
	for _, nodeSpell in pairs(DB.getChildren(nodeChar, "spells")) do
		local sClass, sRecordName = DB.getValue(nodeSpell, "open", nil);
		local _, nLast = string.find(sRecordName, "Rolemaster Companion 1");
		if nLast and nLast == string.len(sRecordName) then
			local sNewRecordName = string.gsub(sRecordName, "Rolemaster Companion 1", "Rolemaster Companion 1 - Players");
			DB.setValue(nodeSpell, "open", "windowreference", sClass, sNewRecordName);
		end
	end
end

function migrateCTEntry1(nodeCTEntry)
	-- Change Attacks and Defenses class when clicking the link to Item from Weapon
	if DB.getChildCount(nodeCTEntry, "attacks") > 0 then
		for _, vAttack in pairs(DB.getChildren(nodeCTEntry, "attacks")) do
			local sClass, sNodeName = DB.getValue(vAttack, "open", nil);
			local nodeOpen = DB.getChild(vAttack, "open");
			if nodeOpen and sClass == "weapon" then
				nodeOpen.setValue("item", sNodeName);
			end
		end
	end
	if DB.getChildCount(nodeCTEntry, "defences") > 0 then
		for _, vDefense in pairs(DB.getChildren(nodeCTEntry, "defences")) do
			local sClass, sNodeName = DB.getValue(vDefense, "open", nil);
			local nodeOpen = DB.getChild(vDefense, "open");
			if nodeOpen and sClass == "weapon" then
				nodeOpen.setValue("item", sNodeName);
			end
		end
	end

	-- Migrate Hits and PowerPoints
	if DB.getChild(nodeCTEntry, "hits.max") then
		local hits = DB.getValue(nodeCTEntry, "hits.max", 0);
		local damage = DB.getValue(nodeCTEntry, "hits.damage", 0);
		local ppmax = DB.getValue(nodeCTEntry, "pp.max", 0);
		local ppcurrent = DB. getValue(nodeCTEntry, "pp.used", 0);

		DB.deleteChild(nodeCTEntry, "hits");
		DB.deleteChild(nodeCTEntry, "pp");
		
		DB.setValue(nodeCTEntry, "hits", "number", hits);
		DB.setValue(nodeCTEntry, "damage", "number", damage);
		DB.setValue(nodeCTEntry, "ppmax", "number", ppmax);
		DB.setValue(nodeCTEntry, "ppcurrent", "number", ppcurrent);
	end

	-- Change TokenRefID Fields to match CoreRPG Field
	if DB.getChild(nodeCTEntry, "tokenrefid") and DB.getChild(nodeCTEntry, "tokenrefid").getType() == "number" then
		nTokenRefID = DB.getValue(nodeCTEntry, "tokenrefid", "");
		DB.deleteChild(nodeCTEntry, "tokenrefid");
		DB.setValue(nodeCTEntry, "tokenrefid", "string", nTokenRefID);
	end
	
	-- Change Friend or Foe fields to match CoreRPG
	if DB.getChild(nodeCTEntry, "fof") then
		DB.setValue(nodeCTEntry, "friendfoe", "string", DB.getValue(nodeCTEntry, "fof", ""));
		DB.deleteChild(nodeCTEntry, "fof");
	end

	-- Change glance to nonid_name field to match CoreRPG
	if DB.getChild(nodeCTEntry, "glance") then
		DB.setValue(nodeCTEntry, "nonid_name", "string", DB.getValue(nodeCTEntry, "glance", ""));
		DB.deleteChild(nodeCTEntry, "glance");
	end
	
	-- Need to move entry to the combattracker.list node
	local nodeNewCTEntry = DB.createChild("combattracker.list");
	if nodeNewCTEntry then
		DB.copyNode(nodeCTEntry, nodeNewCTEntry);

		-- Change initiative to initresult field to match CoreRPG
		if DB.getChild(nodeNewCTEntry, "initiative") then
			local sClass, sNodeName = DB.getValue(nodeNewCTEntry, "link", nil);
			local nInitiative = DB.getValue(nodeNewCTEntry, "initiative", 0);
			if sClass == "charsheet" then
				local nodePC = DB.findNode(sNodeName);
				if nodePC then
					DB.setValue(nodePC, "initiative.initresult", "number", nInitiative);
				end
			else
				DB.setValue(nodeNewCTEntry, "initresult", "number", nInitiative);
			end
			DB.deleteChild(nodeNewCTEntry, "initiative");
		end

		-- Change move to baserate field to match CoreRPG
		if DB.getChild(nodeNewCTEntry, "move") then
			local sClass, sNodeName = DB.getValue(nodeNewCTEntry, "link", nil);
			local nMove = DB.getValue(nodeNewCTEntry, "move", 0);
			if sClass ~= "charsheet" then
				DB.setValue(nodeNewCTEntry, "baserate", "number", nMove);
			end
		end

		-- Migrate Effects to New Effects
		DB.deleteChild(nodeNewCTEntry, "effects");
		DB.deleteChild(nodeNewCTEntry, "effectssummary");
		if DB.getChildCount(nodeCTEntry, "effects") > 0 then
			for _, vEffect in pairs(DB.getChildren(nodeCTEntry, "effects")) do
				local nBleeding = DB.getValue(vEffect, "bleeding", 0);
				local nCantParry = DB.getValue(vEffect, "cantParry", 0);
				local nDuration = DB.getValue(vEffect, "duration", 0);
				local nMustParry = DB.getValue(vEffect, "mustParry", 0);
				local nParryAt = DB.getValue(vEffect, "parryAt", 0);
				local nPenalty = DB.getValue(vEffect, "penalty", 0);
				local nStunned = DB.getValue(vEffect, "stunned", 0);
				local sDescription = DB.getValue(vEffect, "description", "");
				
				if nPenalty ~= 0 then
					local nPenaltyDuration = nDuration;
					addEffect(nodeNewCTEntry, sDescription .. "; Penalty: " .. nPenalty, nPenaltyDuration);
				end
				if nBleeding ~= 0 then
					addEffect(nodeNewCTEntry, "Bleeding: " .. nBleeding, 0);
				end
				if nMustParry ~= 0 then
					summarizeEffect(nodeNewCTEntry, "MustParry", nMustParry);
				end
				if nStunned ~= 0 then
					summarizeEffect(nodeNewCTEntry, "Stun", nStunned);
				end
				if nCantParry ~= 0 then
					summarizeEffect(nodeNewCTEntry, "NoParry", nCantParry);
				end
				if nParryAt ~= 0 then
					local nParryPenaltyDuration = 0;
					if nMustParry ~= 0 then
						nParryPenaltyDuration = nMustParry;
					end
					addEffect(nodeNewCTEntry, "ParryPenalty: " .. nParryAt, 0);
				end
				
				
			end
		end

		DB.deleteNode(nodeCTEntry);
	end
end

function migrateCTEntry2_0(nodeCTEntry)
	local sClass, sRecordName = DB.getValue(nodeCTEntry, "link", nil);
	if sClass == "charsheet" then
		local nodeChar = DB.findNode(sRecordName);

		-- Update Attacks and Defenses to match PC Combat tab
		for _, nodeWeapon in pairs(DB.getChildren(nodeChar, "weapons")) do
			local bFound = false;
			local nodeMatch = nil;
			local sWeaponName = DB.getValue(nodeWeapon, "name", "");
			local sWeaponType = DB.getValue(nodeWeapon, "type", "");
			local sWeaponClass, sWeaponRecord = DB.getValue(nodeWeapon, "open", nil);
			if not sWeaponRecord or sWeaponRecord == "" then
				sWeaponRecord = DB.getPath(nodeWeapon);
			end

			if sWeaponType == "Shield" then
				local bFound = false;
				for _, nodeDefense in pairs(DB.getChildren(nodeCTEntry, "defences")) do
					local sDefenseName = DB.getValue(nodeDefense, "name", "");
					if sWeaponName ~= "" and sWeaponName == sDefenseName then
						DB.setValue(nodeDefense, "open", "windowreference", "item", sWeaponRecord);
						bFound = true;
					end
				end
				if not bFound then
					local nodeDefense = DB.createChild(DB.getChild(nodeCTEntry, "defences"));
					DB.setValue(nodeDefense, "open", "windowreference", "item", sWeaponRecord);
					DB.setValue(nodeDefense, "name", "string", DB.getValue(nodeWeapon, "name", ""));
					DB.setValue(nodeDefense, "meleebonus", "number", DB.getValue(nodeWeapon, "meleebonus", 0));
					DB.setValue(nodeDefense, "missilebonus", "number", DB.getValue(nodeWeapon, "missilebonus", 0));
				end
			else
				local bFound = false;
				for _, nodeAttack in pairs(DB.getChildren(nodeCTEntry, "attacks")) do
					local sAttackName = DB.getValue(nodeAttack, "name", "");
					if sWeaponName ~= "" and sWeaponName == sAttackName then
						DB.setValue(nodeAttack, "open", "windowreference", "item", sWeaponRecord);
						bFound = true;
					end
				end
				if not bFound then
					local nodeAttack = DB.createChild(DB.getChild(nodeCTEntry, "attacks"));
					DB.setValue(nodeAttack, "open", "windowreference", "item", sWeaponRecord);
					DB.setValue(nodeAttack, "name", "string", DB.getValue(nodeWeapon, "name", ""));
					DB.setValue(nodeAttack, "hitsmultiplier", "number", DB.getValue(nodeWeapon, "hitsmultiplier", 0));
					DB.setValue(nodeAttack, "ob", "number", DB.getValue(nodeWeapon, "ob", 0));
					DB.setValue(nodeAttack, "attack", "number", DB.getValue(nodeWeapon, "ob", 0));
					DB.setValue(nodeAttack, "attacktable.tableid", "string", DB.getValue(nodeWeapon, "attacktable.tableid", ""));
					DB.setValue(nodeAttack, "attacktable.name", "string", DB.getValue(nodeWeapon, "attacktable.name", ""));
				end
			end
		end
	end
end

function migrateCTEntry2_1(nodeCTEntry)
	local sClassCTEntry, sRecordNameCTEntry = DB.getValue(nodeCTEntry, "link", nil);
	local nodeWeaponList = DB.createChild(nodeCTEntry, "weapons");
	DB.deleteChildren(nodeWeaponList);
	for _, nodeAttack in pairs(DB.getChildren(nodeCTEntry, "attacks")) do
		local nodeNew = DB.createChild(nodeWeaponList);
		if nodeNew then
			local sClassAttack, sRecordNameAttack = DB.getValue(nodeAttack, "open", nil);
			Utilities.copyWeapon(nodeAttack, nodeNew);
			ItemManager2.UpdateToCoreRPG(nodeNew);
			if sClassCTEntry == "charsheet" then
				DB.setValue(nodeNew, "open", "windowreference", "item", sRecordNameAttack);
			else
				DB.setValue(nodeNew, "open", "windowreference", "item", DB.getPath(nodeNew));
				DB.setValue(nodeNew, "locked", "number", 1);
			end
		end
	end
	DB.deleteChild(nodeCTEntry, "attacks");
end

function migrateCTEntry2_2(nodeCTEntry)
	local tNodesToDelete = {};
	local sCTPath = DB.getPath(nodeCTEntry);
	for _, nodeAttack in pairs(DB.getChildren(nodeCTEntry, "weapons")) do
		local _,sRecord = DB.getValue(nodeAttack, "open", "", "");
		if sRecord ~= "" and (sRecord:find(sCTPath, 1, true) ~= 1) then
			table.insert(tNodesToDelete, nodeAttack);
		else
			DB.deleteChild(nodeAttack, "attack");
		end
	end
	for _, nodeDefense in pairs(DB.getChildren(nodeCTEntry, "defences")) do
		local _,sRecord = DB.getValue(nodeDefense, "open", "", "");
		if sRecord ~= "" and (sRecord:find(sCTPath, 1, true) ~= 1) then
			table.insert(tNodesToDelete, nodeDefense);
		end
	end
	for _,v in ipairs(tNodesToDelete) do
		DB.deleteNode(v);
	end
end

function addEffect(nodeNewCTEntry, sLabel, nDuration)
	local nodeEffect = DB.createChild(DB.createChild(nodeNewCTEntry, "effects"));
	DB.setValue(nodeEffect, "label", "string", sLabel);
	DB.setValue(nodeEffect, "duration", "number", nDuration);
	DB.setValue(nodeEffect, "init", "number", 0);
	DB.setValue(nodeEffect, "isactive", "number", 1);
	DB.setValue(nodeEffect, "isgmonly", "number", 0);
	nodeEffect.setPublic(true);
end

function summarizeEffect(nodeNewCTEntry, sLabel, nDuration)
	local bFound = false;
	
	for _,vEffect in pairs(DB.getChildren(nodeNewCTEntry, "effects")) do
		local sEffectLabel = DB.getValue(vEffect, "label", "");
		local nEffectDuration = DB.getValue(vEffect, "duration", 0);
		if string.find(sLabel, sEffectLabel) and not string.find(sLabel, "Penalty:") then
			-- Update the duration
			local nNewDuration = nDuration + nEffectDuration;
			DB.setValue(vEffect, "duration", "number", nNewDuration);
			bFound = true;
		end
	end  -- END EFFECT LOOP
	
	if not bFound then
		addEffect(nodeNewCTEntry, sLabel, nDuration);
	end
end

function convertCTEntries1()
	for _, nodeCTEntry in pairs(DB.getChildren("combattracker.entries")) do
		migrateCTEntry1(nodeCTEntry);
	end
	DB.deleteNode("combattracker.entries");
end

function convertCTEntries2_0()
	for _, nodeCTEntry in pairs(DB.getChildren("combattracker.list")) do
		migrateCTEntry2_0(nodeCTEntry);
	end
end

function convertCTEntries2_1()
	for _, nodeCTEntry in pairs(DB.getChildren("combattracker.list")) do
		migrateCTEntry2_1(nodeCTEntry);
	end
end

function convertCTEntries2_2()
	for _, nodeCTEntry in pairs(DB.getChildren("combattracker.list")) do
		migrateCTEntry2_2(nodeCTEntry);
	end
end

function updateInventoryList(nodeChar, itemType)
	if DB.getChildCount(nodeChar, itemType) > 0 then
		local nodeInventoryList = DB.createChild(nodeChar, "inventorylist");
		if nodeInventoryList then
			for _,vItem in pairs(DB.getChildren(nodeChar, itemType)) do
				local vInventoryItem = DB.createChild(nodeInventoryList);
				if vInventoryItem then
					if itemType == "transport" then
						DB.setValue(vItem, "transport_ob", "string", DB.getValue(vItem, "ob", "0"));
						DB.deleteChild(vItem, "ob");
					end
					DB.copyNode(vItem, vInventoryItem);
					DB.setValue(vInventoryItem, "isidentified", "number", 1);
					DB.setValue(vInventoryItem, "locked", "number", 1);
					DB.deleteNode(vItem);
				end
			end
		end
	end
	if DB.getChildCount(nodeChar, itemType) == 0 then
		DB.deleteChild(nodeChar, itemType);
	end	
end

function convertPreferences1()
	local nodeOptions = DB.createNode("options");

	for _, nodePref in pairs(DB.getChildren("preferences")) do
		local sPrefName = DB.getName(nodePref);
		local sPrefType = DB.getType(nodePref);
		local vPrefValue; 

		if sPrefType == "string" then
			vPrefValue = DB.getValue(nodePref, "", "");
			if string.lower(vPrefValue) == "yes" then
				vPrefValue = "on";
			elseif string.lower(vPrefValue) == "no" then
				vPrefValue = "off";
			elseif string.lower(vPrefValue) == "ag" then
				vPrefValue = "AG";
			elseif string.lower(vPrefValue) == "qu" then
				vPrefValue = "QU";
			elseif string.lower(vPrefValue) == "ag/qu" then
				vPrefValue = "AG/QU";
			end
		elseif sPrefType == "number" then
			sPrefType = "string";
			vPrefValue = DB.getValue(nodePref, "", 0);
		end

		if sPrefName == "ChLOpt16PPDev" then
			DB.setValue(nodeOptions, "CL16", sPrefType, vPrefValue);
		elseif sPrefName == "ChLOpt1PPStatBonus" then
			DB.setValue(nodeOptions, "CL01", sPrefType, vPrefValue);
		elseif sPrefName == "CharAssistMinStatGenRoll" then
			if vPrefValue <= 15 then
				vPrefValue = "10";
			elseif vPrefValue <= 25 then
				vPrefValue = "20";
			elseif vPrefValue <= 35 then
				vPrefValue = "30";
			elseif vPrefValue <= 45 then
				vPrefValue = "40";
			elseif vPrefValue <= 55 then
				vPrefValue = "50";
			elseif vPrefValue <= 65 then
				vPrefValue = "60";
			elseif vPrefValue <= 75 then
				vPrefValue = "70";
			elseif vPrefValue <= 85 then
				vPrefValue = "80";
			elseif vPrefValue > 85 then
				vPrefValue = "90";
			else
				vPrefValue = "20";
			end
			DB.setValue(nodeOptions, "CMSG", sPrefType, vPrefValue);
		elseif sPrefName == "CharAssistSecSkillPercent" then
			if vPrefValue <= 5 then
				vPrefValue = "0";
			elseif vPrefValue <= 15 then
				vPrefValue = "10";
			elseif vPrefValue <= 22 then
				vPrefValue = "20";
			elseif vPrefValue <= 27 then
				vPrefValue = "25";
			elseif vPrefValue <= 35 then
				vPrefValue = "30";
			elseif vPrefValue <= 45 then
				vPrefValue = "40";
			elseif vPrefValue <= 55 then
				vPrefValue = "50";
			elseif vPrefValue <= 65 then
				vPrefValue = "60";
			elseif vPrefValue <= 72 then
				vPrefValue = "70";
			elseif vPrefValue <= 77 then
				vPrefValue = "75";
			elseif vPrefValue <= 85 then
				vPrefValue = "80";
			elseif vPrefValue <= 95 then
				vPrefValue = "90";
			elseif vPrefValue <= 125 then
				vPrefValue = "100";
			elseif vPrefValue <= 175 then
				vPrefValue = "150";
			elseif vPrefValue > 175 then
				vPrefValue = "200";
			else
				vPrefValue = "0";
			end
			DB.setValue(nodeOptions, "CL113", sPrefType, vPrefValue);
		elseif sPrefName == "CharAssistStatGenTypePref" then
			if vPrefValue == "Random" then
				DB.setValue(nodeOptions, "CL07", sPrefType, "Core: Random");
			elseif vPrefValue == "Random Fixed" then
				DB.setValue(nodeOptions, "CL07", sPrefType, "7.1: Random Fixed");
			elseif vPrefValue == "Three Column" then
				DB.setValue(nodeOptions, "CL07", sPrefType, "7.2: Three Column");
			end
		elseif sPrefName == "ExhaustionAutoTrackPref" then
			DB.setValue(nodeOptions, "CEAT", sPrefType, vPrefValue);
		elseif sPrefName == "ExhaustionHitsMultiplierPref" then
			DB.setValue(nodeOptions, "CEMD", sPrefType, vPrefValue);
		elseif sPrefName == "ExhaustionPenaltyPref" then
			DB.setValue(nodeOptions, "CEEP", sPrefType, vPrefValue);
		elseif sPrefName == "MMRollStatPref" then
			DB.setValue(nodeOptions, "OOMM", sPrefType, vPrefValue);
		elseif sPrefName == "MoveRollStatPref" then
			DB.setValue(nodeOptions, "OOMV", sPrefType, vPrefValue);
		elseif sPrefName == "RMCAutoNumberNPCs" then
			vPrefValue = string.lower(vPrefValue);
			DB.setValue(nodeOptions, "NNPC", sPrefType, vPrefValue);
		elseif sPrefName == "RMCCharCalcAD" then
			DB.setValue(nodeOptions, "CCAD", sPrefType, vPrefValue);
		elseif sPrefName == "RMCCharCalcHits" then
			DB.setValue(nodeOptions, "CCHP", sPrefType, vPrefValue);
		elseif sPrefName == "RMCCharCalcPP" then
			DB.setValue(nodeOptions, "CCPP", sPrefType, vPrefValue);
		elseif sPrefName == "RMCRingBell" then
			DB.setValue(nodeOptions, "RING", sPrefType, vPrefValue);
		elseif sPrefName == "RMCRollNPCInit" then
			DB.setValue(nodeOptions, "INIT", sPrefType, vPrefValue);
		elseif sPrefName == "RMCSkipBelowZeroHits" then
			DB.setValue(nodeOptions, "TSDU", sPrefType, vPrefValue);
		elseif sPrefName == "RMCSortOrder" then
			DB.setValue(nodeOptions, "TRSO", sPrefType, vPrefValue);
		elseif sPrefName == "RevealDice" then
			DB.setValue(nodeOptions, "REVL", sPrefType, vPrefValue);
		elseif sPrefName == "SendEffectsToChat" then
			DB.setValue(nodeOptions, "SETC", sPrefType, vPrefValue);
		elseif sPrefName == "SpLOpt4BasePP" then
			DB.setValue(nodeOptions, "SL04", sPrefType, vPrefValue);
		elseif sPrefName == "harAssistAlwaysUseMinStatGenRoll" then
			DB.setValue(nodeOptions, "CGEN", sPrefType, vPrefValue);
		end
		
		DB.deleteNode(nodePref);
	end
	DB.deleteNode("preferences");
end

function convertEncounters1()
	for _Encounter, vEncounter in pairs(DB.getChildren("battle")) do
		for _NPC, vNPC in pairs(DB.getChildren(vEncounter, "npclist")) do
			for _Map, vMap in pairs(DB.getChildren(vNPC, "maplink")) do
				local nodeImageLink = DB.getChild(vMap, "imagelink");
				if nodeImageLink then
					local nodeImageRef = DB.createChild(vMap, "imageref", "windowreference");
					DB.copyNode(nodeImageLink, nodeImageRef);
					DB.deleteNode(nodeImageLink);
				end
			end
		end
	end
end

function convertNotes1()
	VersionManager.convertNotes2();
end
