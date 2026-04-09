-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	-- Set menus
	resetMenuItems();
	registerMenuItem("New Weapon","insert",5);
end

function addInventoryItem(source)
	local nodeChar = DB.getParent(getDatabaseNode());
	local nodeInventoryList = DB.getChild(nodeChar, "inventorylist");
	local nodeInventoryItem = DB.createChild(nodeInventoryList);
	local newentry = createWindow();
	local newnode = newentry.getDatabaseNode();

	Utilities.copyWeapon(source,nodeInventoryItem);
	newentry.open.setValue("item", DB.getPath(nodeInventoryItem));
	newentry.isidentified.setValue(DB.getValue(nodeInventoryItem, "isidentified", 1));
	newentry.type.setValue(DB.getValue(nodeInventoryItem, "type", ""));
	newentry.name.setValue(DB.getValue(nodeInventoryItem, "name", ""));
	newentry.ob.setValue(DB.getValue(nodeInventoryItem, "ob", 0));
	newentry.fumble.setValue(DB.getValue(nodeInventoryItem, "fumble", 0));
	newentry.meleebonus.setValue(DB.getValue(nodeInventoryItem, "meleebonus", 0));
	newentry.missilebonus.setValue(DB.getValue(nodeInventoryItem, "missilebonus", 0));
			
	return newentry;
end

function addNonInventoryItem(source)
	local newentry = createWindow();
	local newnode = newentry.getDatabaseNode();
  
	Utilities.copyWeapon(source,newnode);

	return newentry;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut")  then
		local class = draginfo.getShortcutData();
		local source = draginfo.getDatabaseNode();
		if source and (class == "weapon" or class == "item") then  
			local newentry = nil;
			local sItemType = DB.getValue(source, "type", "");
			if ItemManager2.IsInventoryAttack(sItemType) then
				newentry = addInventoryItem(source);
			elseif ItemManager2.IsNonInventoryAttack(sItemType) then
				newentry = addNonInventoryItem(source);
			end
		end
		return true;
	end
end


function onMenuSelection(selection, subselection)
	if selection == 5 then
		local win = createWindow();
	end
end

function onSortCompare(w1, w2)
	local node1 = w1.getDatabaseNode();
	local node2 = w2.getDatabaseNode();
	local sName1 = "";
	local sName2 = "";

	if DB.getValue(node1, "isidentified", 1) == 1 then
		sName1 = DB.getValue(node1, "name", "");
	else
		sName1 = DB.getValue(node1, "nonid_name", "");
	end
	
	if DB.getValue(node2, "isidentified", 1) == 1 then
		sName2 = DB.getValue(node2, "name", "");
	else
		sName2 = DB.getValue(node2, "nonid_name", "");
	end

	return sName1 > sName2;
end
