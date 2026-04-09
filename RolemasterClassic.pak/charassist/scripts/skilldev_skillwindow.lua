-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
bIsRefresh = false;

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

local initialised = false;

function refresh()
	local nCalc = calc.getState(); 
	local sProgression = progression.getValue();
	local nRank = rank.getValue();
	--[[ Don't proceed if the window isn't fully initialised ]]
	if not initialised then
		return;
	end
	
	if not bIsRefresh then
		bIsRefresh = true;
		--[[ Get the average bonus from all applicable stats ]]
		local nodeChar = DB.getChild(getDatabaseNode(), "...");
		local nodeSkill = getDatabaseNode();
		skillclass.setState(Rules_Skills.SkillClass(fullname.getValue(), nodeSkill));
		statbonus.setValue(Rules_PC.CombinedStatBonus(nodeChar, stats.getValue(), fullname.getValue()));
		--[[ Set the rank bonus, if needed ]]
		if nCalc == 1 or nCalc == 2 or sProgression == "Standard" or sProgression == "Base (rank x 5)" then
			local rkbn = getRankBonus(nRank, nCalc);
			rankbonus.setReadOnlyRMC(true);
			rankbonus.setFrame(nil);
			total.setReadOnlyRMC(true);
			total.setFrame(nil);
			rankbonus.setValue(rkbn);
			total.setValue(rkbn + statbonus.getValue() + level.getValue() +
						   item.getValue() + special.getValue() + misc.getValue());
		elseif nCalc == 3 or sProgression == "Hits" then
			local rkbn = rankbonus.getValue();
			rankbonus.setReadOnlyRMC(false);
			rankbonus.setFrame("textline",0,5,0,0);
			total.setReadOnlyRMC(true);
			total.setFrame(nil);
			total.setValue(math.floor(rkbn * (1 + statbonus.getValue()/100)) + level.getValue() +
						   item.getValue() + special.getValue() + misc.getValue());
		elseif nCalc == 5 or sProgression == "Power Point" then
			local rkbn = nRank;
			rankbonus.setReadOnlyRMC(true);
			rankbonus.setFrame(nil);
			rankbonus.setValue(nRank);
			statbonus.setReadOnlyRMC(true);
			statbonus.setFrame(nil);
			statbonus.setValue(Rules_PC.RealmPPMultiplier(windowlist.window.getDatabaseNode()));
			total.setReadOnlyRMC(true);
			total.setFrame(nil);
			total.setValue(math.floor(rkbn * statbonus.getValue()) + level.getValue() +
						   item.getValue() + special.getValue() + misc.getValue());
		else
			rankbonus.setReadOnlyRMC(false);
			rankbonus.setFrame("textline",0,5,0,0);
			total.setReadOnlyRMC(false);
			total.setFrame("textline",0,5,0,0);
		end
		shortname.update();
		checkCost();
		setMenus();
		bIsRefresh = false;
	end
end

function getRankBonus(rank,calc)
	return Rules_Skills.RankBonus(rank, calc);
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

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "name"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "stats"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "rank"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "level"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "item"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "special"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "misc"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "misc"), "onUpdate", self.refresh);

	local nodeChar = windowlist.window.getDatabaseNode();
	DB.addHandler(DB.getPath(nodeChar, "abilities"), "onChildUpdate", self.refresh);

	updateNotesField();
	-- done
	initialised = true;
	refresh();
end

function updateNotesField()
	local node = getDatabaseNode();
	if DB.getChild(node, "notes") and DB.getType(DB.getChild(node, "notes")) == "formattedtext" then
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
