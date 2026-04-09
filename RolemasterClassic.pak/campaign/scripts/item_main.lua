-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
local sOldType = "";

function onInit()
	local sPath = DB.getPath(getDatabaseNode(), "type");
	DB.addHandler(sPath, "onUpdate", onTypeUpdate);
	
	sOldType = DB.getValue(getDatabaseNode(), "type", "");
	update();
end

function onTypeUpdate(nodeUpdated)
	local nodeItem = getDatabaseNode();
	local nodeChar = DB.getChild(nodeItem, "...");
	local sType = DB.getValue(nodeUpdated, "", "");
	local sNodeName = DB.getPath(nodeUpdated);
	if sNodeName and string.find(sNodeName, ".inventorylist.") then
		if ItemManager2.IsInventoryAttack(sType) and not ItemManager2.IsInventoryAttack(sOldType) then
			-- Add to Combat Items
			local nodeAttackList = DB.getChild(nodeChar, "weapons");
			if nodeAttackList then
				local nodeAttackItem = DB.createChild(nodeAttackList);
				if nodeAttackItem then
					DB.setValue(nodeAttackItem, "open", "windowreference", "item", DB.getPath(nodeItem));
					DB.setValue(nodeAttackItem, "type", "string", DB.getValue(nodeItem, "type", ""));
					DB.setValue(nodeAttackItem, "name", "string", DB.getValue(nodeItem, "name", ""));
					DB.setValue(nodeAttackItem, "ob", "number", DB.getValue(nodeItem, "ob", 0));
					DB.setValue(nodeAttackItem, "fumble", "number", DB.getValue(nodeItem, "fumble", 0));
					DB.setValue(nodeAttackItem, "meleebonus", "number", DB.getValue(nodeItem, "meleebonus", 0));
					DB.setValue(nodeAttackItem, "missilebonus", "number", DB.getValue(nodeItem, "missilebonus", 0));
				end
			end
		elseif not ItemManager2.IsInventoryAttack(sType) and ItemManager2.IsInventoryAttack(sOldType) then
			-- Remove from Combat Items
			for _, nodeAttackItem in ipairs(DB.getChildList(nodeChar, "weapons")) do
				local sClass, sPath = DB.getValue(nodeAttackItem, "open", nil); 
				if DB.getPath(nodeItem) == sPath then
					DB.deleteNode(nodeAttackItem);
				end
			end
		end
	elseif string.find(sNodeName, ".weapons.") then
		if ItemManager2.IsInventoryAttack(sType) and not ItemManager2.IsInventoryAttack(sOldType) then
			-- Add to Inventory Items
			local nodeInventoryList = DB.getChild(nodeChar, "inventorylist");
			if nodeInventoryList then
				local nodeInventoryItem = DB.createChild(nodeInventoryList);
				if nodeInventoryItem then
					Utilities.copyWeapon(nodeItem,nodeInventoryItem);
					DB.setValue(nodeItem, "open", "windowreference", "item", DB.getPath(nodeInventoryItem));
				end
			end
		elseif not ItemManager2.IsInventoryAttack(sType) and ItemManager2.IsInventoryAttack(sOldType) then
			-- Remove from Inventory Items
			for _, nodeInventoryItem in ipairs(DB.getChildList(nodeChar, "inventorylist")) do
				local _, sPath = DB.getValue(nodeItem, "open", "", ""); 
				if DB.getPath(nodeInventoryItem) == sPath then
					DB.setValue(nodeItem, "open", "windowreference", "item", DB.getPath(nodeItem));
					DB.deleteNode(nodeInventoryItem);
				end
			end
		end
	end
	sOldType = sType;
end

function updateDropDown(sDropDown, bReadOnly, bID)
	if not bID then
		self[sDropDown].setVisible(false);
	else
		if bReadOnly then
			self[sDropDown].setVisible(false);
		else
			self[sDropDown].setVisible(true);
		end
	end	
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = ItemManager.getIDState(nodeRecord);
	
	local bSection1 = false;
	if Session.IsHost then
		if WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_name", bReadOnly, true);
	end
	if (Session.IsHost or not bID) then
		if WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly) then bSection1 = true; end;
	else
		WindowManager.callSafeControlUpdate(self, "nonid_notes", bReadOnly, true);
	end
	divider.setVisible(bSection1);	
	
	local bSectionType = false;
	if WindowManager.callSafeControlUpdate(self, "type", bReadOnly, not bID) then bSectionType = true; end
	self["type"].setComboBoxReadOnly(bReadOnly);
	if WindowManager.callSafeControlUpdate(self, "notes", bReadOnly, not bID) then bSectionType = true; end
	divider_type.setVisible(bSectionType);

	local bItemCategoryButtons = false;
	if bID or Session.IsHost then
		bItemCategoryButtons = (not bReadOnly);
	end		

	self["button_armor_info"].setVisible(bItemCategoryButtons);
	self["button_shield_info"].setVisible(bItemCategoryButtons);
	self["button_weapon_info"].setVisible(bItemCategoryButtons);
	self["button_magicitem_info"].setVisible(bItemCategoryButtons);
	self["button_herb_info"].setVisible(bItemCategoryButtons);
	self["button_transport_info"].setVisible(bItemCategoryButtons);
	self["button_general_info"].setVisible(bItemCategoryButtons);
	self["button_esf_info"].setVisible(bItemCategoryButtons);
	
	self["armor_collapse"].setVisible(bItemCategoryButtons);
	self["shield_collapse"].setVisible(bItemCategoryButtons);
	self["weapon_collapse"].setVisible(bItemCategoryButtons);
	self["magicitem_collapse"].setVisible(bItemCategoryButtons);
	self["herb_collapse"].setVisible(bItemCategoryButtons);
	self["transport_collapse"].setVisible(bItemCategoryButtons);
	self["general_collapse"].setVisible(bItemCategoryButtons);
	self["esf_collapse"].setVisible(bItemCategoryButtons);
	
	self["armor_expand"].setVisible(bItemCategoryButtons);
	self["shield_expand"].setVisible(bItemCategoryButtons);
	self["weapon_expand"].setVisible(bItemCategoryButtons);
	self["magicitem_expand"].setVisible(bItemCategoryButtons);
	self["herb_expand"].setVisible(bItemCategoryButtons);
	self["transport_expand"].setVisible(bItemCategoryButtons);
	self["general_expand"].setVisible(bItemCategoryButtons);
	self["esf_expand"].setVisible(bItemCategoryButtons);

	if armor_info.subwindow then
		armor_info.subwindow.update();
	end
	if shield_info.subwindow then
		shield_info.subwindow.update();
	end
	if weapon_info.subwindow then
		weapon_info.subwindow.update();
	end
	if magicitem_info.subwindow then
		magicitem_info.subwindow.update();
	end
	if herb_info.subwindow then
		herb_info.subwindow.update();
	end
	if transport_info.subwindow then
		transport_info.subwindow.update();
	end
	if general_info.subwindow then
		general_info.subwindow.update();
	end
	if esf_info.subwindow then
		esf_info.subwindow.update();
	end
end

function expandSubwindows()
	self["button_armor_info"].ShowSubwindow();
	self["button_shield_info"].ShowSubwindow();
	self["button_weapon_info"].ShowSubwindow();
	self["button_magicitem_info"].ShowSubwindow();
	self["button_herb_info"].ShowSubwindow();
	self["button_transport_info"].ShowSubwindow();
	self["button_general_info"].ShowSubwindow();
	self["button_esf_info"].ShowSubwindow();
end

function collapseSubwindows()
	self["button_armor_info"].HideSubwindow();
	self["button_shield_info"].HideSubwindow();
	self["button_weapon_info"].HideSubwindow();
	self["button_magicitem_info"].HideSubwindow();
	self["button_herb_info"].HideSubwindow();
	self["button_transport_info"].HideSubwindow();
	self["button_general_info"].HideSubwindow();
	self["button_esf_info"].HideSubwindow();
end
