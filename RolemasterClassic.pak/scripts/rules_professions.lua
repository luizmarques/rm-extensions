-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_GETPROFESSIONLINK = "getprofessionlink";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_GETPROFESSIONLINK, handleProfessionGetLink);
end

-- Get Profession List
function List()
	local aProfessions = {}; 

	table.insert(aProfessions, "");
	
	local aMappings = LibraryData.getMappings("profession");
	for _, vMapping in ipairs(aMappings) do
		for _, vProf in pairs(DB.getChildrenGlobal(vMapping)) do
			table.insert(aProfessions, DB.getValue(vProf, "name", ""));
		end
	end

	return aProfessions;
end

-- Get Profession Category List
function CategoryList()
	return { "", "Non Spell User", "Semi Spell User", "Pure Spell User", "Hybrid Spell User" };
end

function Realm(sProfession)
	local sRealm = "";

	local aMappings = LibraryData.getMappings("profession");
	for _, vMapping in ipairs(aMappings) do
		for _, vProf in pairs(DB.getChildrenGlobal(vMapping)) do
			if string.lower(DB.getValue(vProf, "name", "")) == string.lower(sProfession) then
				sRealm = DB.getValue(vProf, "realm", "");
			end
		end
	end

	return sRealm;
end

function IsPrimeRequisite(sProfession, sStat)
	local nIsPrime = 0;
	local aMappings = LibraryData.getMappings("profession");
	for _, vMapping in ipairs(aMappings) do
		for _, vProf in pairs(DB.getChildrenGlobal(vMapping)) do
			if string.lower(DB.getValue(vProf, "name", "")) == string.lower(sProfession) then
				for _, vPrime in pairs(DB.getChildren(vProf, "primerequisites")) do
					if string.lower(DB.getValue(vPrime, "stat", "")) == string.lower(sStat) then
						nIsPrime = 1;
					end
				end
			end
		end
	end

	return nIsPrime;
end

function SetProfessionLink(sProfession, sCharNode)
	if string.len(sProfession) > 0 then
		local msgProfession = {};
		msgProfession.sProfession = sProfession;
		msgProfession.sCharNode = sCharNode;
		notifyProfessionGetLink(msgProfession);
	end

	return nil;
end
function handleProfessionGetLink(msgProfession)
	local sProfession = msgProfession.sProfession;
	if string.len(sProfession) > 0 then
		local aMappings = LibraryData.getMappings("profession");
		for _, vMapping in ipairs(aMappings) do
			for _, vProf in pairs(DB.getChildrenGlobal(vMapping)) do
				if string.lower(sProfession) == string.lower(DB.getValue(vProf, "name", "")) then
					local nodeChar = DB.findNode(msgProfession.sCharNode);
					if nodeChar then
						DB.setValue(nodeChar, "professionlink", "windowreference", "reference_profession", DB.getPath(vProf));
					end
				end
			end
		end
	end
end
function notifyProfessionGetLink(msgProfession)
	if not msgProfession then
		return;
	end

	msgProfession.type = OOB_MSGTYPE_GETPROFESSIONLINK;

	Comm.deliverOOBMessage(msgProfession, "");
end

function GetLink(sProfession)
	if string.len(sProfession) > 0 then
		local aMappings = LibraryData.getMappings("profession");
		for _, vMapping in ipairs(aMappings) do
			for _, vProf in pairs(DB.getChildrenGlobal(vMapping)) do
				if string.lower(sProfession) == string.lower(DB.getValue(vProf, "name", "")) then
					return "reference_profession", DB.getPath(vProf);
				end
			end
		end
	end

	return nil;
end

-- Get Profession Skill Costs Lists
function SkillCostList(sSkillClass, sProfession)
	local aSkillCostList = {}; 

	sSkillClass = string.lower(sSkillClass);
	sProfession = string.lower(string.gsub(sProfession,"%s+",""));

	local aMappings = LibraryData.getMappings("skill");
	for _, vMapping in ipairs(aMappings) do
		for _, vSkill in pairs(DB.getChildrenGlobal(vMapping)) do
			local sClass = string.lower(DB.getValue(vSkill, "class", ""));
			if sClass == sSkillClass or (sClass == "" and sSkillClass == "Secondary") then
				if DB.getChild(vSkill, "costs") and DB.getChild(vSkill, "costs." .. sProfession) then
					table.insert(aSkillCostList, { SkillName = DB.getValue(vSkill, "fullname", ""), SkillName = DB.getValue(vSkill, "name", ""), SkillCost = DB.getValue(vSkill, "costs." .. sProfession, ""), NodeName = DB.getPath(vSkill) });
				else
					table.insert(aSkillCostList, { SkillName = DB.getValue(vSkill, "fullname", ""), SkillName = DB.getValue(vSkill, "name", ""), SkillCost = "", NodeName = DB.getPath(vSkill) });
				end
			end
		end
	end
	
	return aSkillCostList;
end