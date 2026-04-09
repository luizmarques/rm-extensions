-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

LargeColumnList = { "", "Normal", "Magic", "Mithril", "Holy Arms", "Slaying" };

TypeAttack = "Attack"
TypeResult = "Result"
TypeSkill = "Skill"

ClassCritical = "Critical"
ClassFumble = "Fumble"

local vTableList = {};
local vSublists = {};

function onInit()
	Rules_Tables.LoadLists();
end

function CheckTableList()
	if #vTableList == 0 then
		Rules_Tables.LoadLists();
	end
end

function LoadLists()
	local aTableList = {};
	local aSublists = {};
	local nodeTables, nodeSublists;
	
	for _, sModule in ipairs(Module.getModules()) do
		nodeSublists = DB.findNode("Sublists@" .. sModule);
		if nodeSublists then
			for _, vSublist in pairs(DB.getChildren(nodeSublists)) do
				local sListTitle = DB.getValue(vSublist, "ListTitle", "");
				local sTableType = DB.getValue(vSublist, "TableType", "");
				local sTableClass = DB.getValue(vSublist, "TableClass", "");
				local aSublist = { TableType = sTableType, ListTitle = sListTitle, TableClass = sTableClass }
				table.insert(aSublists, aSublist);
			end
		end

		nodeTables = DB.findNode("RMTables@" .. sModule);
		if nodeTables then
			for _, vTable in pairs(DB.getChildren(nodeTables)) do
				local sTableType = DB.getValue(vTable, "TableType", "");
				local sTableClass = DB.getValue(vTable, "Class", "");
				local sTableName = DB.getValue(vTable, "Name", "");
				local sTableID = DB.getValue(vTable, "Id", "");
				local sAbbr = DB.getValue(vTable, "Abbreviation", "");
				local sSource = DB.getValue(vTable, "Source", "");
				local aTable = { TableType = sTableType, Class = sTableClass, Name = sTableName, Id = sTableID, Abbreviation = sAbbr, Source = sSource, Module = sModule }
				table.insert(aTableList, aTable);
			end
		end
	end

	vSublists = aSublists;
	vTableList = aTableList;
end

function Sublists()
	local aSublists = {};
	
	for _, vSublist in pairs(vSublists) do
		local sListTitle = vSublist.ListTitle;
		local sTableType = vSublist.TableType;
		local sTableClass = vSublist.TableClass;
		local aSublist = { TableType = sTableType, ListTitle = sListTitle, TableClass = sTableClass }
		table.insert(aSublists, aSublist);
	end
	return aSublists;
end

function AttackTableList()
	local aAttackTableList = {};
	table.insert(aAttackTableList, "");
	for _, vTable in pairs(vTableList) do
		if vTable.TableType == "Attack" then
			table.insert(aAttackTableList, vTable.Name);
		end
	end
	return aAttackTableList;
end

function CriticalTableList()
	local aCriticalTableList = {};
	table.insert(aCriticalTableList, "");
	for _, vTable in pairs(vTableList) do
		if vTable.TableType == "Result" and string.find(vTable.Class, "Critical") ~= nil then
			table.insert(aCriticalTableList, vTable.Name);
		end
	end
	return aCriticalTableList;
end

function FumbleTableList()
	local aFumbleTableList = {};
	table.insert(aFumbleTableList, "");
	for _, vTable in pairs(vTableList) do
		if vTable.TableType == "Result" and (string.find(vTable.Class, "Fumble") ~= nil or string.find(vTable.Class, "Failure") ~= nil) then
			table.insert(aFumbleTableList, vTable.Name);
		end
	end
	return aFumbleTableList;
end

function TableList(sTableType, sTableClass)
	local aTableList = {};
	table.insert(aTableList, "");
	for _, vTable in pairs(vTableList) do
		if sTableType then
			if sTableClass then
				if vTable.TableType == "Result" and string.find(vTable.Class, "Critical") ~= nil then
					table.insert(aTableList, vTable.Name);
				end
			else
				if vTable.TableType == sTableType then
					table.insert(aTableList, vTable.Name);
				end
			end
		else
			table.insert(aTableList, vTable.Name);		
		end
	end
	return aTableList;
end

function FumbleTableColumnList(sFumbleTableName)
	local aFumbleTableColumnList = {};
	table.insert(aFumbleTableColumnList, "");
	for _, sModule in ipairs(Module.getModules()) do
		nodeTables = DB.findNode("RMTables@" .. sModule);
		if nodeTables then
			for _, vTable in pairs(DB.getChildren(nodeTables)) do
				if DB.getValue(vTable, "Name", "") == sFumbleTableName then
					for _, vColumn in pairs(DB.getChildren(vTable, "Columns")) do
						table.insert(aFumbleTableColumnList, DB.getValue(vColumn, "Title", ""));
					end
				end
			end
		end
	end

	return aFumbleTableColumnList;
end

function IsTableName(sTableName)
	for _, vTable in pairs(vTableList) do
		if vTable.Name == sTableName then
			return true;
		end
	end
	
	return false;
end	

function GetTableName(sTableID, sTableType)
	local sTableName = "";
	
	for k, vTable in pairs(vTableList) do
		if vTable.Id == sTableID then
			if sTableType then
				if sTableType == vTable.TableType then
					sTableName = vTable.Name;
				end
			else
				sTableName = vTable.Name;
			end
		end
	end
	
	return sTableName;
end

function GetTableID(sTableName, sTableType)
	local sTableID = "";
	
	for _, vTable in pairs(vTableList) do
		if vTable.Name == sTableName then
			if sTableType then
				if sTableType == vTable.TableType then
					sTableID = vTable.Id;
				end
			else
				sTableID = vTable.Id;
			end
		end
	end
	
	return sTableID;
end

function GetTableType(sTableID)
	local sTableType = "Attack";

	for k, vTable in pairs(vTableList) do
		if vTable.Id == sTableID then
			sTableType = vTable.TableType;
		end
	end

	return sTableType;
end

function IsOpenEndedResultTable(sTableID)
	if sTableID == "CT-09" or sTableID == "CT-10" 
				or sTableID == "SCT-05" or sTableID == "SCT-06"
				or sTableID == "SF-01" or sTableID == "SF-02" then
		return true;
	else
		return false;
	end
end

