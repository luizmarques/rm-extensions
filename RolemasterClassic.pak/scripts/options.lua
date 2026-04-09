-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Default ruleset options

function onInit()
	--  OptionManager.register("abilitybonus",RMCAbilityBonus);
	OptionManager.register("mmskillname",RMCMMSkillName);
	OptionManager.register("skillcost",RMCSkillCost);
	OptionManager.register("getarmortypes",RMCGetArmorTypes);
	-- C&T codes
	OptionManager.register("pacelabel",RMCPaceLabel);
	OptionManager.register("mslabel",RMCMSLabel);
	OptionManager.register("aqlabel",RMCAQLabel);
	OptionManager.register("sizelabel",RMCSizeLabel);
	OptionManager.register("critlabel",RMCCritLabel);
	OptionManager.register("outlooklabel",RMCOutlookLabel);
	OptionManager.register("iqlabel",RMCIQLabel);
	OptionManager.register("weaponlabel",RMCWeaponLabel);
end

function trim(str)
	return string.gsub(str,"^%s*(.*)%s*$","%1");
end

local attacks =
{ 
	["Ba"] = "bash/ram/butt/knock down/slug",
	["Bi"] = "bite",
	["Cl"] = "claw/talon",
	["Cr"] = "crush/fall",
	["Gr"] = "grapple/grasp/envelop/swallow",
	["Msw"] = "martial arts sweeps & throws",
	["Mst"] = "martial arts strikes",
	["Pi"] = "pincher/beak",
	["St"] = "stinger",
	["Ti"] = "tiny",
	["Ts"] = "trample/stomp",
	["Ho"] = "horn/tusk",
	["ba"] = "battle axe",
	["bs"] = "broadsword",
	["bo"] = "bola",
	["cl"] = "club",
	["cp"] = "composite bow",
	["da"] = "dagger",
	["fa"] = "falchion",
	["ha"] = "hand axe",
	["hb"] = "halbard",
	["hcb"] = "heavy cross bow",
	["ja"] = "javelin",
	["lb"] = "long bow",
	["lcb"] = "light cross bow",
	["ma"] = "mace",
	["ml"] = "mounted lance",
	["pa"] = "pole arm",
	["qs"] = "quarter staff",
	["sb"] = "short bow",
	["sc"] = "scimitar",
	["sl"] = "sling",
	["sp"] = "spear",
	["ss"] = "short sword",
	["th"] = "two handed sword",
	["ts"] = "throwing star",
	["wh"] = "war hammer",
	["wm"] = "war mattock",
	["wp"] = "whip"
};

function abbrev(name)
	local lname = string.lower(name);
	for key,item in pairs(attacks) do
		if string.find(item,lname,1,true) then
			return key;
		end
	end
	return name;
end

function RMCWeaponLabel(optname,weapon)
	local name = trim(DB.getValue(weapon, "name", ""));
	local ob = trim(DB.getValue(weapon, "ob", 0));
	local chance = trim(DB.getValue(weapon, "chance", ""));
	local size = "";
	local result = ob;
	if chance=="SameRnd" then
		chance = "<";
	elseif chance=="NextRnd" then
		chance = "v";
	elseif string.sub(chance,-1)=="%" then
		chance = string.sub(chance,1,-2);
	end
	if string.sub(name,2,2)==" " then
		size = string.sub(name,1,1);
		name = trim(string.sub(name,3,-1));
	end
	name = abbrev(name);
	if name~="" or size~="" then
		result = result.." "..size..name;
	end
	if chance~="" then
		result = result.." "..chance;
	end
	return result;
end

function RMCIQLabel(optname,value)
	if type(value)~="number" then
		return "-","-";
	end
	if value==2 then
		return "None (animal instincts)","NO";
	elseif value==3 then
		return "Very Low (1-5)","VL";
	elseif value==4 then
		return "Low (3-12)","LO";
	elseif value==5 then
		return "Little (7-25)","LI";
	elseif value==6 then
		return "Inferior (13-40)","IN";
	elseif value==7 then
		return "Mediocre (23-50)","MD";
	elseif value==8 then
		return "Average (36-65)","AV";
	elseif value==9 then
		return "Above Average (50-77)","AA";
	elseif value==10 then
		return "Superior (60-86)","SU";
	elseif value==11 then
		return "High (80-98)","HI";
	elseif value==12 then
		return "Very High (94-99)","VH";
	elseif value==13 then
		return "Exceptional (100-102)","EX";
	else
		return "-","-";
	end
end

function RMCOutlookLabel(optname,value)
	if type(value)~="number" then
		return "-","-";
	end
	if value==2 then
		return "Aggressive and will attack if provoked or hungry.","Aggres.";
	elseif value==3 then
		return "Ignores other creatures unless interfered with or attack.","Aloof";
	elseif value==4 then
		return "Altruistic, has an unselfish regard for the interests of others, often to the extent of risking his own safety.","Altru.";
	elseif value==5 then
		return "Belligerent, often attacks without provocation.","Bellig.";
	elseif value==6 then
		return "Attacks closest living creature until it is destroyed.","Berserk";
	elseif value==7 then
		return "Does not believe that danger or misfortune exists for it.","Carefree";
	elseif value==8 then
		return "Not only hostile, but delights in death, pain, and suffering.","Cruel";
	elseif value==9 then
		return "Desires power, attempts to control or dominate other creatures.","Domin.";
	elseif value==10 then
		return "Opposed to 'evil' (e.g., those who are cruel, hostile, belligerent, etc.); supportive of those who are 'good'.","Good";
	elseif value==11 then
		return "Will attack or attempt to steal from other creatures if the risk does not seem too high.","Greedy";
	elseif value==12 then
		return "Normally attacks other creatures on sight.","Hostile";
	elseif value==13 then
		return "If hungry, will attack anything edible; otherwise Normal.","Hungry";
	elseif value==14 then
		return "Inquisitive/Curious will approach and examine unusual situations.","Inquis.";
	elseif value==15 then
		return "Normally bolts at any sign of other creatures.","Jumpy";
	elseif value==16 then
		return "Watches and is wary of other creatures, will sometimes attack if hungry.","Normal";
	elseif value==17 then
		return "Ignores the presence of other creatures unless threatened.","Passive";
	elseif value==18 then
		return "Mischievous/Playful, will attempt to play with or play pranks on other creatures.","Playful";
	elseif value==19 then
		return "Protective of a thing, place, other creature, etc.","Protect";
	elseif value==20 then
		return "Skittish around other creatures, runs at the slightest hint of danger.","Timid";
	elseif value==21 then
		return "Varies","Varies";
	else
		return "-","-";
	end
end

function RMCCritLabel(optname,value)
	if type(value)~="number" then
		return "-","-";
	end
	if value==2 then
		return "-1 severity","I"
	elseif value==3 then
		return "-2 severities","II"
	elseif value==4 then
		return "Large","L"
	elseif value==5 then
		return "Super Large","SL"
	else
		return "-","-";
	end
end

function RMCSizeLabel(optname,value)
	if type(value)~="number" then
		return "-","-";
	end
	if value==1 then
		return "Tiny","T";
	elseif value==2 then
		return "Small","S";
	elseif value==3 then
		return "Medium","M";
	elseif value==4 then
		return "Large","L";
	elseif value==5 then
		return "Huge","H";
	else
		return "-","-";
	end
end

function RMCAQLabel(...)
	return RMCMSLabel(...);
end

function RMCMSLabel(optname,value)
	if type(value)~="number" then
		return "-","-";
	end
	if value==2 then
		return "Inching","IN";
	elseif value==3 then
		return "Creeping","CR";
	elseif value==4 then
		return "Very Slow","VS";
	elseif value==5 then
		return "Slow","SL";
	elseif value==6 then
		return "Medium","MD";
	elseif value==7 then
		return "Moderately Fast","MF";
	elseif value==8 then
		return "Fast","FA";
	elseif value==9 then
		return "Very Fast","VF";
	elseif value==10 then
		return "Blindingly Fast","BF";
	else
		return "-","-";
	end
end

function RMCPaceLabel(optname,value)
	if type(value)~="number" then
		return "-","-";
	end
	if value==2 then
		return "Walk","Walk";
	elseif value==3 then
		return "Jog","Jog";
	elseif value==4 then
		return "Run","Run";
	elseif value==5 then
		return "Sprint","Spt";
	elseif value==6 then
		return "Fast Sprint","FSpt";
	elseif value==7 then
		return "Dash","Dash";
	else
		return "-","-";
	end
end

local armorTypes =
{ Count = 20,
	[1]  = {name="Skin", shortName="Skin", skillName="", minPenalty=0, maxPenalty=0, missilePenalty=0, dbPenalty=0},
	[2]  = {name="Robes", shortName="Robes", skillName="", minPenalty=0, maxPenalty=0, missilePenalty=0, dbPenalty=0},
	[3]  = {name="Light Hide", shortName="Light Hide", skillName="", minPenalty=0, maxPenalty=0, missilePenalty=0, dbPenalty=0},
	[4]  = {name="Heavy Hide", shortName="Heavy Hide", skillName="", minPenalty=0, maxPenalty=0, missilePenalty=0, dbPenalty=0},
	[5]  = {name="Leather Jerkin", shortName="Leather Jerkin", skillName="Maneuvering in Soft Leather", minPenalty=0, maxPenalty=0, missilePenalty=0, dbPenalty=0},
	[6]  = {name="Leather Coat", shortName="Leather Coat", skillName="Maneuvering in Soft Leather", minPenalty=0, maxPenalty=-20, missilePenalty=-5, dbPenalty=0},
	[7]  = {name="Reinforced Leather Coat", shortName="Reinforced Leather Coat", skillName="Maneuvering in Soft Leather", minPenalty=-10, maxPenalty=-40, missilePenalty=-15, dbPenalty=-10},
	[8]  = {name="Reinforced Full Leather Coat", shortName="Rein Full Leather Coat", skillName="Maneuvering in Soft Leather", minPenalty=-15, maxPenalty=-50, missilePenalty=-15, dbPenalty=-15},
	[9]  = {name="Leather Breastplate", shortName="Leather Breastplate", skillName="Maneuvering in Rigid Leather", minPenalty=-5, maxPenalty=-50, missilePenalty=0, dbPenalty=0},
	[10] = {name="Leather Breastplate and Greaves", shortName="Lthr Brstplate & Greaves", skillName="Maneuvering in Rigid Leather", minPenalty=-10, maxPenalty=-70, missilePenalty=-10, dbPenalty=-5},
	[11] = {name="Half-Hide Plate", shortName="Half-Hide Plate", skillName="Maneuvering in Rigid Leather", minPenalty=-15, maxPenalty=-90, missilePenalty=-20, dbPenalty=-15},
	[12] = {name="Full-Hide Plate", shortName="Full-Hide Plate", skillName="Maneuvering in Rigid Leather", minPenalty=-15, maxPenalty=-110, missilePenalty=-30, dbPenalty=-15},
	[13] = {name="Chain Shirt", shortName="Chain Shirt", skillName="Maneuvering in Chain", minPenalty=-10, maxPenalty=-70, missilePenalty=0, dbPenalty=-5},
	[14] = {name="Chain Shirt and Greaves", shortName="Chain Shirt & Greaves", skillName="Maneuvering in Chain", minPenalty=-15, maxPenalty=-90, missilePenalty=-10, dbPenalty=-10},
	[15] = {name="Full Chain", shortName="Full Chain", skillName="Maneuvering in Chain", minPenalty=-25, maxPenalty=-120, missilePenalty=-20, dbPenalty=-20},
	[16] = {name="Chain Hauberk", shortName="Chain Hauberk", skillName="Maneuvering in Chain", minPenalty=-25, maxPenalty=-130, missilePenalty=-20, dbPenalty=-20},
	[17] = {name="Metal Breastplate", shortName="Metal Breastplate", skillName="Maneuvering in Plate", minPenalty=-15, maxPenalty=-90, missilePenalty=0, dbPenalty=-10},
	[18] = {name="Metal Breastplate and Greaves", shortName="Mtl Brstplate & Greaves", skillName="Maneuvering in Plate", minPenalty=-20, maxPenalty=-110, missilePenalty=-10, dbPenalty=-20},
	[19] = {name="Half Plate", shortName="Half Plate", skillName="Maneuvering in Plate", minPenalty=-35, maxPenalty=-150, missilePenalty=-30, dbPenalty=-30},
	[20] = {name="Full Plate", shortName="Full Plate", skillName="Maneuvering in Plate", minPenalty=-45, maxPenalty=-165, missilePenalty=-40, dbPenalty=-40}
};

function RMCGetArmorTypes(optname)
	return armorTypes;
end

function RMCSkillCost(optname,skillname,profession)
	profession = string.lower(string.gsub(profession,"%s+",""));
	for k,mod in pairs(Module.getModules()) do
		-- Primary Skills
		for k,skl in pairs(DB.getChildren("reference.skilllist.primaryskills.list@"..mod)) do
			if DB.getValue(skl, "name", "") == skillname then
				return DB.getValue(skl, "costs." .. profession, "");
			end
		end
		-- Secondary Skills
		for k,skl in pairs(DB.getChildren("reference.skilllist.secondaryskills.list@"..mod)) do
			if DB.getValue(skl, "name", "") == skillname then
				return DB.getValue(skl, "costs." .. profession, "");
			end
		end
	end
	-- not found
	return ""
end

function RMCMMSkillName(optname,at)
	if at>16 then
		return "Maneuvering in Plate";
	elseif at>12 then
		return "Maneuvering in Chain";
	elseif at>8 then
		return "Maneuvering in Rigid Leather";
	elseif at>4 then
		return "Maneuvering in Soft Leather";
	else
		return "";
	end
end

function RMCAbilityBonus(optname,win)
	local val = 0;
	if not win or not win.temp then
		return 0;
	end
	val = win.temp.getValue();
	if val > 101 then
		return 35;
	elseif val > 100 then
		return 30;
	elseif val > 99 then
		return 25;
	elseif val > 97 then
		return 20;
	elseif val > 94 then
		return 15;
	elseif val > 89 then
		return 10;
	elseif val > 74 then
		return 5;
	elseif val > 24 then
		return 0;
	elseif val > 9 then
		return -5;
	elseif val > 4 then
		return -10;
	elseif val > 2 then
		return -15;
	elseif val > 1 then
		return -20;
	else
		return -25;
	end
end
