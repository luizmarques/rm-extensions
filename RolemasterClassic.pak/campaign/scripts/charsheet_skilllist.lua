-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local categories = {};
local dropnode = nil;

function getSource()
	local src = dropnode;
	dropnode = nil;
	return src;
end

function isGrouped()
	return (DB.getValue(window.getDatabaseNode(), "grouped", 0) ~= 0);
end

function setGrouped(state)
	DB.setValue(window.getDatabaseNode(), "grouped", "number", state and 1 or 0);
	rebuild();
end

function getSkill(name)
	for i,skl in ipairs(getWindows()) do
		if skl.fullname and skl.fullname.getValue()==name then
			return skl;
		end
	end
	return nil;
end

function getCost(SkillName)
	local Prof = window.profession.getValue();
	return Rules_Skills.SkillCost(SkillName, Prof);
end

local disableaction = false;

function rebuild()
	if disableaction then
		return;
	end
	disableaction = true;
	-- Close all category headings
	for k,catwin in pairs(categories) do
		catwin.close();
	end
	categories = {};
	-- Set menus
	resetMenuItems();
	registerMenuItem("Create Skill","insert",5);
	if isGrouped() then
		registerMenuItem("Ungroup","ungroup",4);
	else
		registerMenuItem("Group","group",4);
	end
	-- Create new category headings?
	if isGrouped() then
		for k,v in ipairs(getWindows()) do
			if v.getCategory then
				local category = v.getCategory();
				if not categories[category] then
					-- Create category header
					local win = createWindowWithClass("charsheet_skillgroup");
					win.name.setValue(category);
					categories[category] = win;
				end
			end
		end
	end
	-- Resort
	applySort();
	-- done
	disableaction = false;
end

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	rebuild();
end

function onMenuSelection(item)
	if item and item==5 then
		local win = createWindow();
		win.type.setValue(1);
		win.calc.setState(1);
	elseif item and item==4 then
		setGrouped(not isGrouped());
	end
end

function onSortCompare(w1, w2)
	local category1, category2;
	local iscategory1, iscategory2;
	-- 'normal' case
	if not isGrouped() then
		return w1.name.getValue() > w2.name.getValue();
	end
	-- Get window properties
	if w1.getClass() == "charsheet_skillgroup" then
		category1 = w1.name.getValue();
		iscategory1 = true;
	else
		if w1.getCategory then
			category1 = w1.getCategory();
		end
		iscategory1 = false;
	end
	if w2.getClass() == "charsheet_skillgroup" then
		category2 = w2.name.getValue();
		iscategory2 = true;
	else
		if w2.getCategory then
			category2 = w2.getCategory();
		end
		iscategory2 = false;
	end
	if category1 == category2 then
		if iscategory1 then
			return false;
		elseif iscategory2 then
			return true;
		else
			return w1.name.getValue() > w2.name.getValue();
		end
	else
		return category1 > category2;
	end
end

function onListRearranged(changed)
	-- Only rebuild if the skills aren't grouped - avoids constant rebuild loop.
	if  not isGrouped() then
		rebuild();
	end
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass = draginfo.getShortcutData();
		local nodeSource = draginfo.getDatabaseNode();

		if nodeSource and (sClass == "skill") then
			local win = createWindow();			
			local nodeDestination = win.getDatabaseNode();
			win.fullname.setValue(DB.getValue(nodeSource, "fullname", ""));
			win.name.setValue(DB.getValue(nodeSource, "name", ""));
			win.class.setValue(DB.getValue(nodeSource, "class", ""));
			win.type.setValue(DB.getValue(nodeSource, "type", 0));
			win.skilltype.setValue(DB.getValue(nodeSource, "skilltype", ""));
			win.group.setValue(DB.getValue(nodeSource, "group", ""));
			win.calc.setState(DB.getValue(nodeSource, "calc", 1));
			win.progression.setValue(DB.getValue(nodeSource, "progression", ""));
			win.stats.setValue(DB.getValue(nodeSource, "stats", ""));
			win.armorfactor.setValue(DB.getValue(nodeSource, "armorfactor", 0));
			DB.setValue(nodeDestination, "levelbonus.core", "string", DB.getValue(nodeSource, "levelbonus.core", ""));
			DB.setValue(nodeDestination, "levelbonus.rm2", "string", DB.getValue(nodeSource, "levelbonus.rm2", ""));
			DB.setValue(nodeDestination, "levelbonus.rmfrp", "string", DB.getValue(nodeSource, "levelbonus.rmfrp", ""));
			DB.setValue(nodeDestination, "levelbonus.rmcompanion2", "string", DB.getValue(nodeSource, "levelbonus.rmcompanion2", ""));
			DB.setValue(nodeDestination, "description", "formattedtext", DB.getValue(nodeSource, "description", ""));
			return true;
		end
	end

	return false;
end