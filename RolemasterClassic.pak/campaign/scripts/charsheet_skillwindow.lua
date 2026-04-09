-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	local nodeSkill = getDatabaseNode();
	local nodeChar = windowlist.window.getDatabaseNode();
	DB.addHandler(DB.getPath(nodeSkill, "name"), "onUpdate", refresh);
	DB.addHandler(DB.getPath(nodeSkill, "stats"), "onUpdate", refresh);
	DB.addHandler(DB.getPath(nodeChar, "abilities.*.total"), "onUpdate", refresh);

	updateNotesField();
	setMenus();
	refresh();
end

function getCategory()
	local skilltype = type.getValue();
	if group.getValue()~="" then
		return group.getValue();
	end
	if skilltype==1 then
		return "Maneuver, Moving";
	elseif skilltype==2 then
		return "Maneuver, Static";
	elseif skilltype==3 then
		return "Offense Bonus";
	elseif skilltype==4 then
		return "Special";
	else
		return "Other";
	end
end

function refresh()
	local nodeChar = DB.getChild(getDatabaseNode(), "...");
	statbonus.setValue(Rules_PC.CombinedStatBonus(nodeChar, stats.getValue(), fullname.getValue()));
	if fullname.getValue() == Rules_Skills.BodyDevelopment or name.getValue() == Rules_Skills.BodyDevelopment then
		rankbonus.setReadOnly(false);
	else
		rankbonus.setReadOnly(true);
	end
	shortname.update();
	checkCost();
end

function checkCost()
	local skill = name.getValue();
	-- is there a name yet?
	if skill=="" then
		return;
	end
	-- is there a development cost recorded?
	if cost.getValue()=="" then
		-- Set the development cost
		cost.setValue(windowlist.getCost(skill));
	end
end

function updateNotesField()
	local node = getDatabaseNode();
	local nodeNotes = DB.getChild(node, "notes");
	if nodeNotes and DB.getType(nodeNotes) == "formattedtext" then
		local sNotes = DB.getValue(node, "notes", "");
		sNotes = string.gsub(sNotes, "<p>", "");
		sNotes = string.gsub(sNotes, "</p>", "");
		DB.deleteChild(node, "notes");
		DB.setValue(node, "notes", "string", sNotes);
	end
end
          
function setMenus()
	resetMenuItems();
	-- delete menu item
	registerMenuItem("Delete Skill","delete",6);
end

function onMenuSelection(selection)
	if selection == 6 then
		WindowManager.safeDelete(self);
	end
end

function parseShortName()
	--[[ extract the stats and the skill name from the shortname control]]
	local s = shortname.getValue();
	local i = string.find(s,"(",1,true);
	local nm = "";
	local sts = "";
	if i and i > 0 then
		local j = string.find(s,")",i+1,true);
		if j and j > 0 then
			sts = string.sub(s,i+1,j-1);
		else
			sts = string.sub(s,i+1);
		end
		nm = string.gsub(string.sub(s,1,i-1),"%s+$","");
	else
		nm = s;
		sts = "";
	end
	--[[ update the name and stat fields, if needed ]]
	if name and name.getValue()~=nm then
		name.setValue(nm);
    end
	if stats and stats.getValue()~=sts then
		stats.setValue(sts);
	end
	--[[ done ]]
	return;
end
