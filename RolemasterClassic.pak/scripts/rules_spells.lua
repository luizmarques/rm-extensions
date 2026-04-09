-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Get Realm List
function RealmList()
	return { "Channeling", "Essence", "Mentalism" };
end

function GetClassAndRealm(sType)
	local nOpenStart, nOpenEnd = string.find(string.lower(sType), "open");
	local nClosedStart, nClosedEnd = string.find(string.lower(sType), "closed");
	local sClass = "";
	local sRealm = "";
	local sStart = "";
	local sEnd = "";
	
	if not nOpenStart and not nClosedStart then
		sClass = sType;
	else
		if nOpenStart then
			sClass = "Open";
			if nOpenStart and nOpenStart > 1 then
				sStart = string.sub(sType, 1, nOpenStart - 1);
			end
			if nOpenEnd and nOpenEnd < string.len(sType) then
				sEnd = string.sub(sType, nOpenEnd + 1, string.len(sType));
			end
		elseif nClosedStart then
			sClass = "Closed";
			if nClosedStart and nClosedStart > 1 then
				sStart = string.sub(sType, 1, nClosedStart - 1);
			end
			if nClosedEnd and nClosedEnd < string.len(sType) then
				sEnd = string.sub(sType, nClosedEnd + 1, string.len(sType));
			end
		end
		sRealm = sStart .. sEnd;
	end
	
	return sClass, sRealm;
end

-- Spell Class List
function SpellClassList(sRealm)
	local aSpellClassList = {};

	table.insert(aSpellClassList, "");

	local aMappings = LibraryData.getMappings("spelllist");
	for _, vMapping in ipairs(aMappings) do
		for _, vSpellList in pairs(DB.getChildrenGlobal(vMapping)) do
			if not sRealm or DB.getValue(vSpellList, "realm", "") == sRealm then
				local bAdd = true;
				local sNewSpellClass = DB.getValue(vSpellList, "class", "");
				if (sNewSpellClass == "Open" or sNewSpellClass == "Closed") and DB.getChild(vSpellList, "realm") then
					local sSpacing = " ";
					if sNewSpellClass == "Open" then
						sSpacing = sSpacing .. " ";
					end
					sNewSpellClass = " " .. DB.getValue(vSpellList, "realm", "") .. sSpacing .. sNewSpellClass;
				end
				for _, sSpellClass in pairs(aSpellClassList) do
					if sSpellClass == sNewSpellClass then
						bAdd = false;
					end
				end
				if bAdd == true then
					table.insert(aSpellClassList, sNewSpellClass);
				end
			end
		end
	end

	return aSpellClassList;
end

-- Spell Lists Lists
function SpellListNamesList(sRealm, sClass)
	local aSpellListsList = {};

	local aMappings = LibraryData.getMappings("spelllist");
	for _, vMapping in ipairs(aMappings) do
		for _, vSpellList in pairs(DB.getChildrenGlobal(vMapping)) do
			if not sRealm or DB.getValue(vSpellList, "realm", "") == sRealm then
				if not sClass or DB.getValue(vSpellList, "class", "") == sClass then
					local bAdd = true;
					for _, vList in pairs(aSpellListsList) do
						if vList == DB.getValue(vSpellList, "name", "") then
							bAdd = false;
						end
					end
					if bAdd == true then
						table.insert(aSpellListsList, DB.getValue(vSpellList, "name", ""));
					end
				end
			end
		end
	end

	return aSpellListsList;
end

function SpellListNodesListByClass(sSpellClass)
	local aSpellListsList = {};
	local sClass = sSpellClass;
	local nLoc = string.find(sClass, "  Open");
	local sRealm = nil;
	
	if nLoc then
		sClass = "Open";
		sRealm = string.sub(sSpellClass, 2, nLoc - 1);
	else
		nLoc = string.find(sClass, " Closed");
		if nLoc then
			sClass = "Closed";
			sRealm = string.sub(sSpellClass, 2, nLoc - 1);
		end
	end

	local aMappings = LibraryData.getMappings("spelllist");
	for _, vMapping in ipairs(aMappings) do
		for _, vSpellList in pairs(DB.getChildrenGlobal(vMapping)) do
			if not sRealm or DB.getValue(vSpellList, "realm", "") == sRealm then
				if not sClass or DB.getValue(vSpellList, "class", "") == sClass then
					local bAdd = true;
					for _, vList in pairs(aSpellListsList) do
						if vList == vSpellList then
							bAdd = false;
						end
					end
					if bAdd == true then
						table.insert(aSpellListsList, vSpellList);
					end
				end
			end
		end
	end

	return aSpellListsList;
end

function SpellListNodesListByListName(sListName)
	local aSpellListsList = {};

	local aMappings = LibraryData.getMappings("spelllist");
	for _, vMapping in ipairs(aMappings) do
		for _, vSpellList in pairs(DB.getChildrenGlobal(vMapping)) do
			if DB.getValue(vSpellList, "name", "") == sListName then
				table.insert(aSpellListsList, vSpellList);
			end
		end
	end

	return aSpellListsList;
end

function ClassList()
	return { "", "Open", "Closed", "Base" };
end

-- ESF 
ESFNotLearned = 20;

function GetSpellFailure(nESFTotal)
	return 2 + nESFTotal;
end

function GetESFModFromLevelDiff(nLevelDiff)
	if nLevelDiff > 20 then
		return 200;
	else
		local nESFMod = nLevelDiff * 5;
		if nLevelDiff >= 16 then 
			return nESFMod + 70;
		elseif nLevelDiff >= 11 then
			return nESFMod + 35;
		elseif nLevelDiff >= 6 then
			return nESFMod + 25;
		elseif nLevelDiff >= 1 then
			return nESFMod + 15;
		end
	end
	
	return 0;
end
