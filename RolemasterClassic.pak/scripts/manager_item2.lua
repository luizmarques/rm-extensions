-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_ITEMUPDATETOCORERPG = "itemupdatetocorerpg";

CategoryHelmet = "Helmet";
CategoryPrimaryHand = "Primary Hand";
CategorySecondaryHand = "Secondary Hand"
CategoryAdderMultipler = "Adder/Multiplier";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ITEMUPDATETOCORERPG, handleUpdateToCoreRPG);
	
	ItemManager.setCustomCharAdd(charAddItem);
	ItemManager.setCustomCharRemove(charRemoveItem);

end

function TypeList()
	return { 	
				"", 
				"Accessory",
				"Armor",
				"Barding",
				"Base Spell Item",
				"Enchanted Bread",
				"Food",
				"Helmet",
				"Herb",
				"Intoxicant",
				"Missile Weapon",
				"One-Handed Concussion",
				"One-Handed Slashing",
				"Poison",
				"Pole Arm",
				"Service",
				"Shield",
				"Thrown Weapon",
				"Transportation",
				"Two-Handed Weapon",
				"Natural Weapon",
				"Elemental Attack",
				"Special",
				"Potion",
				"Clothing",
				"Gem"
			};
end

function addItemToList2(sClass, nodeSource, nodeTarget, nodeTargetList)
	if LibraryData.isRecordDisplayClass("item", sClass) then
		if sClass == "herb" then
			sEffect = DB.getValue(nodeSource, "effect", "");
			DB.deleteChild(nodeSource, "effect");
			DB.setValue(nodeSource, "notes", "formattedtext", sEffect);
		end

		DB.copyNode(nodeSource, nodeTarget);
		DB.setValue(nodeTarget, "locked", "number", 1);

		-- Set the identified field
		if sClass == "reference_magicitem" then
			DB.setValue(nodeTarget, "isidentified", "number", 0);
		else
			DB.setValue(nodeTarget, "isidentified", "number", 1);
		end

		local msgItem = {};
		msgItem.nodeName = DB.getPath(node);
		notifyUpdateToCoreRPG(msgItem);
		
		return true;
	end

	return false;
end

function ItemTypeList()
		sTypeString = "-";
		sTypeString = "One-Handed Slashing";
		sTypeString = "One-Handed Concussion";
		sTypeString = "Two-Handed Weapon";
		sTypeString = "Pole Arm";
		sTypeString = "Missile Weapon";
		sTypeString = "Thrown Weapon";
		sTypeString = "Shield";
		sTypeString = "Natural Weapon";
		sTypeString = "Elemental Attack";
		sTypeString = "Special";
		sTypeString = "Accessory";
		sTypeString = "Armor";
		sTypeString = "Herbs, Etc.";
		sTypeString = "Potion";
		sTypeString = "Clothing";
		sTypeString = "Gem";
		sTypeString = "Food";
		sTypeString = "Service";
		sTypeString = "Transportation";
		sTypeString = "Arm Greaves";
		sTypeString = "Leg Greaves";
		sTypeString = "Helmet";
end

function getItemTypeString(iType)
	if iType == 1 then
		sTypeString = "One-Handed Slashing";
	elseif iType == 2 then
		sTypeString = "One-Handed Concussion";
	elseif iType == 3 then
		sTypeString = "Two-Handed Weapon";
	elseif iType == 4 then
		sTypeString = "Pole Arm";
	elseif iType == 5 then
		sTypeString = "Missile Weapon";
	elseif iType == 6 then
		sTypeString = "Thrown Weapon";
	elseif iType == 7 then
		sTypeString = "Shield";
	elseif iType == 8 then
		sTypeString = "Natural Weapon";
	elseif iType == 9 then
		sTypeString = "Elemental Attack";
	elseif iType == 10 then
		sTypeString = "Special";
	elseif iType == 11 then
		sTypeString = "Accessory";
	elseif iType == 12 then
		sTypeString = "Armor";
	elseif iType == 13 then
		sTypeString = "Herbs, Etc.";
	elseif iType == 14 then
		sTypeString = "Potion";
	elseif iType == 15 then
		sTypeString = "Clothing";
	elseif iType == 16 then
		sTypeString = "Gem";
	elseif iType == 17 then
		sTypeString = "Food";
	elseif iType == 18 then
		sTypeString = "Service";
	elseif iType == 19 then
		sTypeString = "Transportation";
	elseif iType == 20 then
		sTypeString = "-";
	elseif iType == 21 then
		sTypeString = "Arm Greaves";
	elseif iType == 22 then
		sTypeString = "Leg Greaves";
	elseif iType == 23 then
		sTypeString = "Helmet";
	end
	
	return sTypeString;
end

function charAddItem(nodeItem)
	local sItemType = DB.getValue(nodeItem, "type", "");
	if IsInventoryAttack(sItemType) then
		local nodeChar = DB.getChild(nodeItem, "...");
		local nodeAttackItem = DB.createChild(DB.createChild(nodeChar, "weapons"));
		DB.setValue(nodeAttackItem, "open", "windowreference", "item", DB.getPath(nodeItem));
		DB.setValue(nodeAttackItem, "type", "string", "item", DB.getValue(nodeItem, "type", ""));
		DB.setValue(nodeAttackItem, "name", "string", "item", DB.getValue(nodeItem, "name", ""));
		DB.setValue(nodeAttackItem, "ob", "number", "item", DB.getValue(nodeItem, "ob", 0));
		DB.setValue(nodeAttackItem, "fumble", "number", "item", DB.getValue(nodeItem, "fumble", 0));
		DB.setValue(nodeAttackItem, "meleebonus", "number", "item", DB.getValue(nodeItem, "meleebonus", 0));
		DB.setValue(nodeAttackItem, "missilebonus", "number", "item", DB.getValue(nodeItem, "missilebonus", 0));
	end
end

function charRemoveItem(nodeItem)
	local sItemType = DB.getValue(nodeItem, "type", "");
	if IsInventoryAttack(sItemType) then
		local sItemNodeName = DB.getPath(nodeItem);
		local nodeChar = DB.getChild(nodeItem, "...");
		for _, nodeAttackItem in pairs(DB.getChildList(nodeChar, "weapons")) do
			local sClass, sPath = DB.getValue(nodeAttackItem, "open", nil); 
			if sItemNodeName == sPath then
				DB.deleteNode(nodeAttackItem);
			end
		end
	end
end

function getDisplayName(nodeItem)
	local bID = (DB.getValue(nodeItem, "isidentified", 1) == 1);
	if bID then
		return DB.getValue(nodeItem, "name", "");
	end
	
	local sName = DB.getValue(nodeItem, "nonid_name", "");
	if sName == "" then
		sName = Interface.getString("library_recordtype_empty_nonid_item");
	end
	return sName;
end

-- Convert Item to be compatible with CoreRPG Items
function handleUpdateToCoreRPG(msgItem)
	if msgItem then
		local node = DB.findNode(msgItem.nodeName);
		if node then
			UpdateToCoreRPG(node);
		end
	end
end

function notifyUpdateToCoreRPG(msgItem)
	if not msgItem then
		return;
	end

	msgItem.type = OOB_MSGTYPE_ITEMUPDATETOCORERPG;
	Comm.deliverOOBMessage(msgItem, "");
end

function UpdateToCoreRPG(node)
	-- Update Old GM Item fields to match CoreRPG Item fields Type
	local sPath = DB.getPath(node, "description");
	if (DB.getType(sPath) or "") == "formattedtext" then
		local sDescription = DB.getValue(node, "description", "");
		DB.deleteChild(node, "description");
		DB.setValue(node, "notes", "formattedtext", sDescription);
	end
	sPath = DB.getPath(node, "identified");
	if (DB.getType(sPath) or "") == "string" then
		local sIdentified = DB.getValue(node, "identified", "");
		DB.deleteChild(node, "identified");
		local sDescription = DB.getValue(node, "notes", "");
		if string.len(sDescription) > 0 then
			DB.setValue(node, "notes", "formattedtext", sDescription .. " " .. sIdentified);
		else
			DB.setValue(node, "notes", "formattedtext", sIdentified);
		end
	end
	sPath = DB.getPath(node, "nonidentified");
	if (DB.getType(sPath) or "") == "string" then
		local sNonIdentified = DB.getValue(node, "nonidentified", "");
		DB.deleteChild(node, "nonidentified");
		DB.setValue(node, "nonid_notes", "string", sNonIdentified);
	end
	
	-- Convert the Description field to the CoreRPG Item Notes field
	sPath = DB.getPath(node, "description");
	if (DB.getType(sPath) or "") == "string" then
		local sDescription = DB.getValue(node, "description", "");
		DB.deleteChild(node, "description");
		DB.setValue(node, "notes", "formattedtext", sDescription);
	else
		sPath = DB.getPath(node, "effect");
		if (DB.getType(sPath) or "") == "string" then
			local sEffect = DB.getValue(node, "effect", "");
			DB.deleteChild(node, "effect");
			DB.setValue(node, "notes", "formattedtext", sEffect);
		end
	end
	-- Update Type field to match CoreRPG Item Type Field Type
	sPath = DB.getPath(node, "type");
	if (DB.getType(sPath) or "") == "number" then
		local nType = DB.getValue(node, "type");
		DB.deleteChild(node, "type");
		DB.setValue(node, "type", "string", ItemManager2.getItemTypeString(nType));
	end
	-- Update Length field to match CoreRPG Item Length Field Type
	sPath = DB.getPath(node, "length");
	if (DB.getType(sPath) or "") == "number" then
		local nLength = DB.getValue(node, "length");
		DB.deleteChild(node, "length");
		DB.setValue(node, "length", "string", nLength);
	end
	-- Update OB field to match CoreRPG Item Type Field Type
	sPath = DB.getPath(node, "ob");
	if (DB.getType(sPath) or "") == "string" then
		local sOB = DB.getValue(node, "ob", "");
		DB.deleteChild(node, "ob");
		DB.setValue(node, "transport_ob", "string", sOB);
	end
	-- Update AT field 
	sPath = DB.getPath(node, "armortype");
	if (DB.getType(sPath) or "") == "string" then
		local sAT = DB.getValue(node, "armortype", "");
		if type(tonumber(sAT)) == "number" then
			nArmorType = sAT;
		else
			nArmorType = 0;
		end
		DB.deleteChild(node, "armortype");
		DB.setValue(node, "armortype", "number", nArmorType);
	end
	sPath = DB.getPath(node, "breakage_factor");
	if (DB.getType(sPath) or "") == "string" then
		local sBreakageFactor = DB.getValue(node, "breakage_factor", "");
		DB.deleteChild(node, "breakage_factor");
		DB.setValue(node, "breakfactor", "string", sBreakageFactor);
	end
	sPath = DB.getPath(node, "breakagefactor");
	if (DB.getType(sPath) or "") == "string" then
		sBreakageFactor = DB.getValue(node, "breakagefactor", "");
		DB.deleteChild(node, "breakagefactor");
		DB.setValue(node, "breakfactor", "string", sBreakageFactor);
	end
	
	-- Update Armor Fields if necessary
	if DB.getChild(node, "type") then
		if DB.getValue(node, "type", "") == "Armor" then
			local sName = DB.getValue(node, "name", "");
			if ItemManager2.IsArmGreaves(sName) then
				DB.setValue(node, "type", "string", "Arm Greaves");
			elseif ItemManager2.IsLegGreaves(sName) then
				DB.setValue(node, "type", "string", "Leg Greaves");
			elseif ItemManager2.IsHelmet("Armor", sName) then
				DB.setValue(node, "type", "string", "Helmet");
			end

			if DB.getValue(node, "type", "") == "Armor" then
				local iAT = DB.getValue(node, "armortype", 1);
				local armor = Rules_ArmorTypes.GetATDetails(iAT);
				if armor and not DB.getChild(node, "minimum_mm_penalty") then
					DB.setValue(node, "minimum_mm_penalty", "number", armor.minPenalty);
				end
				if armor and not DB.getChild(node, "maximum_mm_penalty") then
					DB.setValue(node, "maximum_mm_penalty", "number", armor.maxPenalty);
				end
				if armor and not DB.getChild(node, "missile_penalty") then
					DB.setValue(node, "missile_penalty", "number", armor.missilePenalty);
				end
				if armor and not DB.getChild(node, "quickness_penalty") then
					DB.setValue(node, "quickness_penalty", "number", armor.dbPenalty);
				end
				if armor and not DB.getChild(node, "armor_mm_skill") then
					DB.setValue(node, "armor_mm_skill", "string", armor.skillName);
				end
				if armor and not DB.getChild(node, "esfEssense") then
					DB.setValue(node, "esf_armor_essence", "number", armor.esfEssense);
				end
				if armor and not DB.getChild(node, "esfChanneling") then
					DB.setValue(node, "esf_armor_channeling", "number", armor.esfChanneling);
				end
				if armor and not DB.getChild(node, "protection_head") then
					DB.setValue(node, "protection_head", "string", armor.protectionHead);
				end
				if armor and not DB.getChild(node, "protection_face") then
					DB.setValue(node, "protection_face", "string", armor.protectionFace);
				end
				if armor and not DB.getChild(node, "protection_neck") then
					DB.setValue(node, "protection_neck", "string", armor.protectionNeck);
				end
				if armor and not DB.getChild(node, "protection_torso") then
					DB.setValue(node, "protection_torso", "string", armor.protectionTorso);
				end
				if armor and not DB.getChild(node, "protection_arms") then
					DB.setValue(node, "protection_arms", "string", armor.protectionArms);
				end
				if armor and not DB.getChild(node, "protection_legs") then
					DB.setValue(node, "protection_legs", "string", armor.protectionLegs);
				end
			end
		end
	end
end

-- Get Equipment Drop Down Lists
function CharArmorList(nodeChar)
	local list = {};
	table.insert(list, "");

	for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local sItemType = DB.getValue(nodeItem, "type", "");
		if sItemType == "Armor" then
			local sItemName = getDisplayName(nodeItem);

			if not IsArmGreaves(sItemName) and not IsLegGreaves(sItemName) and not IsHelmet("Armor", sItemName) then
				table.insert(list, sItemName);
			end
		end			
	end
	
	return list;
end

function CharHelmetList(nodeChar)
	local list = {};
	table.insert(list, "");

	for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local sItemName = getDisplayName(nodeItem);
		local sItemType = DB.getValue(nodeItem, "type", "");
		
		if IsHelmet(sItemType, sItemName) then
			table.insert(list, sItemName);
		end
	end

	return list;
end

function CharPrimaryHandList(nodeChar)
	local list = {};
	table.insert(list, "");

	for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local sItemType = DB.getValue(nodeItem, "type", "");
		if IsPrimaryHandType(sItemType) then
			local sItemName = getDisplayName(nodeItem);
			table.insert(list, sItemName);
		end			
	end
	
	return list;
end

function CharSecondaryHandList(nodeChar)
	local list = {};
	table.insert(list, "");

	for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local sItemType = DB.getValue(nodeItem, "type", "");
		if IsSecondaryHandType(sItemType) then
			local sItemName = getDisplayName(nodeItem);
			table.insert(list, sItemName);
		end			
	end
	
	return list;
end

function CharAdderMultiplierList(nodeChar)
	local list = {};
	table.insert(list, "");

	for _, nodeItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
		local bID = (DB.getValue(nodeItem, "isidentified", 1) == 1);
		if bID then
			local iAdder = DB.getValue(nodeItem, "adderbonus", 0);
			local iMultiplier = DB.getValue(nodeItem, "multiplierbonus", 0);
			if iAdder + iMultiplier > 0 then
				local sCharRealm = DB.getValue(nodeChar, "realm", "");
				local sItemRealm = DB.getValue(nodeItem, "realm", "");
				if Rules_Realm.RealmsMatch(sCharRealm, sItemRealm) then
					local sItemName = DB.getValue(nodeItem, "name", "");
					table.insert(list, sItemName);
				end
			end			
		end
	end
	
	return list;
end

-- Equipment Type Checks
function IsArmGreaves(sItemName)
	local isArmGreaves = false;
	if string.find(sItemName, "Arm Greaves") then
		isArmGreaves = true;
	end
	return isArmGreaves;
end

function IsLegGreaves(sItemName)
	local isLegGreaves = false;
	if string.find(sItemName, "Leg Greaves") then
		isLegGreaves = true;
	end
	return isLegGreaves;
end

function IsHelmet(sItemType, sItemName)
	local bIsHelmet = false;
	if sItemType == "Helmet" then
		bIsHelmet = true;
	elseif sItemType == "Armor" then
		if string.find(sItemName, "Helm") then
			bIsHelmet = true;
		end
	end			
	return bIsHelmet;
end

function IsPrimaryHandType(sItemType)
	local isPrimaryHandType = false;

	if sItemType == "One-Handed Slashing" then
		isPrimaryHandType = true;
	elseif sItemType == "One-Handed Concussion" then
		isPrimaryHandType = true;
	elseif sItemType == "Two-Handed Weapon" then
		isPrimaryHandType = true;
	elseif sItemType == "Pole Arm" then
		isPrimaryHandType = true;
	elseif sItemType == "Missile Weapon" then
		isPrimaryHandType = true;
	elseif sItemType == "Thrown Weapon" then
		isPrimaryHandType = true;
	elseif sItemType == "Natural Weapon" then
		isPrimaryHandType = true;
	end

	return isPrimaryHandType;	
end

function IsSecondaryHandType(sItemType)
	local isSecondaryHandType = false;

	if sItemType == "One-Handed Slashing" then
		isSecondaryHandType = true;
	elseif sItemType == "One-Handed Concussion" then
		isSecondaryHandType = true;
	elseif sItemType == "Thrown Weapon" then
		isSecondaryHandType = true;
	elseif sItemType == "Natural Weapon" then
		isSecondaryHandType = true;
	elseif sItemType == "Shield" then
		isSecondaryHandType = true;
	end

	return isSecondaryHandType;	
end

-- Protection
function GetEquippedItemNode(sRecordClass, sRecordName)
	if sRecordName and sRecordName ~="" then
		return DB.findNode(sRecordName);
	end
	
	return nil;
end

function GetBestProtection(sHelmetProtection, sArmorProtection)
	if sHelmetProtection == Rules_ArmorTypes.ProtectionMetal or sArmorProtection == Rules_ArmorTypes.ProtectionMetal then
		return Rules_ArmorTypes.ProtectionMetal;
	elseif sHelmetProtection == Rules_ArmorTypes.ProtectionLeather or sArmorProtection == Rules_ArmorTypes.ProtectionLeather then
		return Rules_ArmorTypes.ProtectionLeather;
	else
		return Rules_ArmorTypes.ProtectionNone;
	end
end

function GetProtection(nodeChar, sProtectionLocation)
	local nodeEquippedHelmet = GetEquippedItemNode(DB.getValue(nodeChar, "equipped_helmet_link", nil));
	local nodeEquippedArmor = GetEquippedItemNode(DB.getValue(nodeChar, "equipped_armor_link", nil));
	local sHelmetProtection = Rules_ArmorTypes.ProtectionNone;
	local sArmorProtection = Rules_ArmorTypes.ProtectionNone;

	sHelmetProtection = DB.getValue(nodeEquippedHelmet, sProtectionLocation, Rules_ArmorTypes.ProtectionNone);
	sArmorProtection = DB.getValue(nodeEquippedArmor, sProtectionLocation, Rules_ArmorTypes.ProtectionNone);
	
	local sProtection = GetBestProtection(sHelmetProtection, sArmorProtection);
	
	return sProtection;
end

function HeadProtection(nodeChar)
	return GetProtection(nodeChar, "protection_head");
end

function FaceProtection(nodeChar)
	return GetProtection(nodeChar, "protection_face");
end

function NeckProtection(nodeChar)
	return GetProtection(nodeChar, "protection_neck");
end

function TorsoProtection(nodeChar)
	return GetProtection(nodeChar, "protection_torso");
end

function LegsProtection(nodeChar)
	return GetProtection(nodeChar, "protection_legs");
end

function ArmsProtection(nodeChar)
	return GetProtection(nodeChar, "protection_arms");
end

-- Combat Tab Attacks and Shields
function IsInventoryAttack(sItemType)
	if sItemType == "One-Handed Slashing" then
		return true;
	elseif sItemType == "One-Handed Concussion" then
		return true;
	elseif sItemType == "Two-Handed Weapon" then
		return true;
	elseif sItemType == "Pole Arm" then
		return true;
	elseif sItemType == "Missile Weapon" then
		return true;
	elseif sItemType == "Thrown Weapon" then
		return true;
	elseif sItemType == "Shield" then
		return true;
	end

	return false;
end

function IsNonInventoryAttack(sItemType)
	if sItemType == "Natural Weapon" then
		return true;
	elseif sItemType == "Elemental Attack" then
		return true;
	elseif sItemType == "Special" then
		return true;
	end

	return false;
end

