-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local allowdragvalue = false;
local allowdropvalue = false;
local namevalue = "";
local idvalue = "";
local sourcenode = nil;

function onInit()
	if isReadOnly() then
		self.update(true);
	else
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
					update(true);
				end
			end
		end
		-- allow <allowDrag/> and <allowDrop/> to override the default settings
		if allowDrag then
			allowdragvalue = true;
		end
		if allowDrop then
			allowdropvalue = true;
		end

		local node = getDatabaseNode();
		if not node or node.isReadOnly() then
			self.update(true);
		end
	end
end

function update(bReadOnly, bForceHide)
	local bLocalShow;

	if bForceHide then
		bLocalShow = false;
	else
		bLocalShow = true;
		if bReadOnly == true and not nohide and isEmpty() then
			bLocalShow = false;
		end
	end
	
	setReadOnly(bReadOnly);
	setVisible(bLocalShow);
	
	local sLabel = getName() .. "_label";
	if window[sLabel] then
		window[sLabel].setVisible(bLocalShow);
	end
	if separator then
		if window[separator[1]] then
			window[separator[1]].setVisible(bLocalShow);
		end
	end
	
	if self.onVisUpdate then
		self.onVisUpdate(bLocalShow, bReadOnly);
	end

	-- from RolemasterClassic
	local tablenode = nil;
	if not sourcenode then
		return;
	end
	-- the id value of the field, eg ALT04
	idvalue = DB.getValue(sourcenode, "tableid", "");
	if idvalue == "" then
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
	if oninit and namevalue == "" then
		-- do nothing, already is blank
	else
		super.setValue(namevalue);
	end
	-- done
	
	return bLocalShow;
end

function onVisUpdate(bLocalShow, bReadOnly)
	if bReadOnly == true and bLocalShow then
		setFrame(nil);
	else
		setFrame("fielddark", 7,5,7,5);
	end
end

function onDragStart(button,x,y,dragdata)
	local customData = {};
	if not allowdragvalue then
		--return false;
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
		--return false;
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
	return idvalue, namevalue;
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
	-- Handle DropDown List Selection
	if tableID and not tableName then
		if tabletype then
			sTableType = tabletype[1];
		end
		if Rules_Tables.IsTableName(tableID) then
			tableName = tableID;
			tableID = Rules_Tables.GetTableID(tableName, sTableType);
		else
			tableName = Rules_Tables.GetTableName(tableID, sTableType);
		end
	end
	
	if sourcenode then
		-- set the table name
		DB.setValue(sourcenode, "name", "string", tableName or "")
		-- set the underlying db value, which causes the displayed value to update
		DB.setValue(sourcenode, "tableid", "string", tableID)
	end
end
