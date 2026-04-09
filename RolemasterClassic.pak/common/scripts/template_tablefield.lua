-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

--[[
  This control is bound to the database, and carries the ID and name of an RMC attack/fumble table.

  It displays the table name (such as Broadsword) rather than the ID (such as ALT04).

  The allowDrag and allowDrop flags control how the UI interaction works, and these can
  be set using setAllowDrag and setAllowDrop and queried using getAllowDrag and getAllowDrop.
]]

local allowdragvalue = false;
local allowdropvalue = false;
local namevalue = "";
local idvalue = "";
local sourcenode = nil;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	if window.getDatabaseNode() then
		-- Get value from source node
		if sourcename then
			sourcenode = DB.createChild(window.getDatabaseNode(), sourcename[1]);
		else
			sourcenode = DB.createChild(window.getDatabaseNode(), getName());
		end
		if sourcenode then
			local nodeTableID = DB.createChild(sourcenode, "tableid", "string");
			if nodeTableID then
				DB.addHandler(DB.getPath(nodeTableID), "onUpdate", self.update);
			end
			update(true);
		end
	end
	-- allow <allowDrag/> and <allowDrop/> to override the default settings
	if allowDrag then
		allowdragvalue = true;
	end
	if allowDrop then
		allowdropvalue = true;
	end
end

function onDragStart(button,x,y,dragdata)
	local customData = {};
	if not allowdragvalue then
		return false;
	end
	if idvalue=="" or namevalue=="" then
		return false;
	end
	if not dragdata.getCustomData() then
		dragdata.setType("string")
		dragdata.setStringData(namevalue); 
		customData.type = "RMCTable";
		customData.tableID = idvalue;
		customData.tableName = namevalue;
		dragdata.setCustomData(customData);
		dragdata.setIcon("icon_table");
	end
	return true;
end

function onDrop(x,y,dragdata)
	local customData = dragdata.getCustomData();
	if not allowdropvalue then
		return false;
	end
	if not customData or not customData.type or customData.type~="RMCTable" then
		return false;
	end
	setValue(customData.tableID,customData.tableName);
	return true;
end

function getAllowDrop()
	return allowdropvalue;
end

function getAllowDrag()
	return allowdragvalue;
end

function getValue()
	return idvalue,namevalue;
end

function getTableName()
	return namevalue;
end

function setAllowDrop(state)
	allowdropvalue = state;
end

function setAllowDrag(state)
	allowdragvalue = state;
end

function setValue(tableID,tableName)
	if sourcenode then
		-- set the table name
		DB.setValue(sourcenode, "name", "string", tableName or "");
		-- set the underlying db value, which causes the displayed value to update
		DB.setValue(sourcenode, "tableid", "string", tableID);
	end
end

function update(oninit)
	local tablenode = nil;
	if not sourcenode then
		return;
	end
	-- the id value of the field, eg ALT04
	idvalue = DB.getValue(sourcenode, "tableid", "");
	if idvalue=="" then
		namevalue = "";
	else
		local tablenode = DB.findNode("RMTables."..idvalue);
		if tablenode and DB.getValue(tablenode, "DisplayName", "") ~= "" then
			namevalue = DB.getValue(tablenode, "DisplayName", "");
			DB.setValue(sourcenode, "name","string", namevalue);
		else
			namevalue = DB.getValue(sourcenode, "name", "");
		end
	end
	-- the displayed value, eg Broadsword
	if oninit and namevalue=="" then
		-- do nothing, already is blank
	else
		super.setValue(namevalue);
	end
	-- done
	return;
end
