-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local scriptName = "sortablelist.lua";
local sortingField = "SortKey";
local sumField;

local filterField;
local filterValue;
local sortMenuFields = {};
local mainSortMenuPosition;
local ascendingMenuPosition = 1;
local descendingMenuPosition = 5;
local sortingDirection = "Ascending";

local ASCENDING = "Ascending";
local DESCENDING = "Descending";

function onInit()
	local functionName = "onInit";

	mainSortMenuPosition = 3
	if sortradialposition and sortradialposition[1] then
		mainSortMenuPosition = tonumber(sortradialposition[1]); 
	end

	if sortfield and sortfield[1] then

		if sortfield[1].nosortfieldsdefined then
			-- default value when no sortfield nodes have been specified to override the template value
			-- ie. no sort fields defined for this sortable list (the sortBy function could still be called directly to sort the list)
		else
			registerMenuItem("Sort","sort",mainSortMenuPosition);

			for i,v in ipairs(sortfield) do

				if v.fieldname and v.fieldname[1] then

					if v.menuname  and v.menuname[1] then
						AddSortableFieldMenuItem(v.fieldname[1], v.menuname[1]);
					else
						AddSortableFieldMenuItem(v.fieldname[1], v.fieldname[1]);
					end
				else
					ErrorHandler.showError("No fieldname supplied for a sortfield entry for " .. getName(), functionName, scriptName, false);
				end
			end
		end
	end

	if defaultsort and defaultsort[1] then
		if defaultsort[1].nodefaultsortdefined then
			-- default value when no defaultsort nodes have been specified to override the template value
			-- ie. no default sort field defined for this sortable list
		else
			if defaultsort[1].fieldname and defaultsort[1].fieldname[1] then
				if defaultsort[1].direction and defaultsort[1].direction[1] and defaultsort[1].direction[1] == DESCENDING then
				sortBy(defaultsort[1].fieldname[1], DESCENDING);
				else
				sortBy(defaultsort[1].fieldname[1], ASCENDING);
				end
			else
				ErrorHandler.showError("No fieldname supplied for defaultsort entry for " .. getName(), functionName, scriptName, false);
			end

		end
	end
end

function sortCompare(w1, w2)
	local functionName = "sortCompare";
	local returnValue = false;
	local w1Value, w2Value;

	if w1.getDatabaseNode() and DB.getChild(w1.getDatabaseNode(), sortingField) then
		w1Value = DB.getValue(w1.getDatabaseNode(), sortingField);
	else
		return false;
	end

	if w2.getDatabaseNode() and DB.getChild(w2.getDatabaseNode(), sortingField) then
		w2Value = DB.getValue(w2.getDatabaseNode(), sortingField);
	else
		return true;
	end

	-- handle blank stringfields (make the blank entries sink to the bottom of the list
	if DB.getType(DB.getChild(w1.getDatabaseNode(), sortingField)) == "string" and DB.getType(DB.getChild(w2.getDatabaseNode(), sortingField)) == "string" then
		if w1Value == "" and w2Value == "" then
			-- if they are both blank then compare the field names (just to force a consistent comparison)
			returnValue = DB.getName(DB.getChild(w1.getDatabaseNode(), sortingField)) > DB.getName(DB.getChild(w2.getDatabaseNode(), sortingField));
		elseif w1Value == "" and w2Value ~= "" then
			-- force a blank value to always be greater than any non-blank
			returnValue = true;
		elseif w1Value ~= "" and w2Value == "" then
			-- force any non-blank value to always be less than a blank
			returnValue = false;  
		else -- both non-blank
			returnValue = w1Value > w2Value;
		end
	else -- not strings
		if DB.getValue(w1.getDatabaseNode(), sortingField) > DB.getValue(w2.getDatabaseNode(), sortingField) then
			returnValue = true;
		else
			returnValue = false;
		end
	end

	if sortingDirection == DESCENDING then
		returnValue = not returnValue;
	end

	return returnValue;
end

function sortBy(fieldName, direction)
	local functionName = "sortBy";

	if direction == null then
		-- toggle current sort direction
		if sortingDirection == ASCENDING then
			sortingDirection = DESCENDING;
		else
			sortingDirection = ASCENDING;
		end
	else
		sortingDirection = direction;
	end

	sortingField = fieldName;
	onSortCompare = sortCompare;

	applySort(true);
	onSortCompare = function() end;
end


function AddSortableFieldMenuItem(fieldName, menuDescription)
	local exists = false;
	for  i,v in ipairs(sortMenuFields) do
		if v == fieldName then
			exists = true;
			break;
		end
	end
	if exists == false and #sortMenuFields <= 7 then
		table.insert(sortMenuFields, fieldName);
		registerMenuItem("Sort by " .. menuDescription,"sort",mainSortMenuPosition, #sortMenuFields);

		-- need to arrange so that the 'return to prev level menu' radial menu is not covered by an asc/desc menu
		if #sortMenuFields == oppositeMenuPosition(ascendingMenuPosition) then
			if ascendingMenuPosition + 1 > 8 then 
				registerMenuItem("Ascending","sort",mainSortMenuPosition, #sortMenuFields, 1);
			else
				registerMenuItem("Ascending","sort",mainSortMenuPosition, #sortMenuFields, ascendingMenuPosition+1);
			end
		else
			registerMenuItem("Ascending","sort",mainSortMenuPosition, #sortMenuFields, ascendingMenuPosition);
		end
		if #sortMenuFields == oppositeMenuPosition(descendingMenuPosition) then
			if descendingMenuPosition + 1 > 8 then 
				registerMenuItem("Descending","sort",mainSortMenuPosition, #sortMenuFields, 1);
			else
				registerMenuItem("Descending","sort",mainSortMenuPosition, #sortMenuFields, descendingMenuPosition+1);
			end
		else
			registerMenuItem("Descending","sort",mainSortMenuPosition, #sortMenuFields, descendingMenuPosition);
		end
	end
end

function oppositeMenuPosition(pos)
	local opp = pos + 4;
	if opp > 8 then 
		opp = opp - 8;
	end
	return opp;
end

function onMenuSelection(slot1, slot2, slot3)
	if slot1 and slot1 == mainSortMenuPosition then
		if slot2 then
			if slot3 then
				if slot3 == ascendingMenuPosition then
					sortBy(sortMenuFields[slot2], ASCENDING);
					return true;
				else
					sortBy(sortMenuFields[slot2], DESCENDING); 
					return true;
				end
			end
		end
	end
end