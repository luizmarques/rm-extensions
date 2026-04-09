-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

OOB_MSGTYPE_GETRACELINK = "getracelink";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_GETRACELINK, handleRaceGetLink);
end

-- Get Race List
function List()
	local aRaces = {};

	table.insert(aRaces, "");
	
	local aMappings = LibraryData.getMappings("race");
	for _,vMapping in ipairs(aMappings) do
		for _,vRace in pairs(DB.getChildrenGlobal(vMapping)) do
			table.insert(aRaces, DB.getValue(vRace, "name", ""));
		end
	end
	
	return aRaces;
end

function SetRaceLink(sRace, sCharNode)
	if string.len(sRace) > 0 then
		local msgRace = {};
		msgRace.sRace = sRace;
		msgRace.sCharNode = sCharNode;
		notifyRaceGetLink(msgRace);
	end

	return nil;
end
function handleRaceGetLink(msgRace)
	local sRace = msgRace.sRace;
	if string.len(sRace) > 0 then
		local aMappings = LibraryData.getMappings("race");
		for _,vMapping in ipairs(aMappings) do
			for _,vRace in pairs(DB.getChildrenGlobal(vMapping)) do
				if string.lower(sRace) == string.lower(DB.getValue(vRace, "name", "")) then
					local nodeChar = DB.findNode(msgRace.sCharNode);
					if nodeChar then
						DB.setValue(nodeChar, "racelink", "windowreference", "reference_race", DB.getPath(vRace));
					end
				end
			end
		end
	end
end
function notifyRaceGetLink(msgRace)
	if not msgRace then
		return;
	end

	msgRace.type = OOB_MSGTYPE_GETRACELINK;

	Comm.deliverOOBMessage(msgRace, "");
end

function GetLink(sRace)
	if string.len(sRace) > 0 then
		local aMappings = LibraryData.getMappings("race");
		for _,vMapping in ipairs(aMappings) do
			for _,vRace in pairs(DB.getChildrenGlobal(vMapping)) do
				if string.lower(sRace) == string.lower(DB.getValue(vRace, "name", "")) then
					return "reference_race", DB.getPath(vRace);
				end
			end
		end
	end
	
	return nil;
end

function GetRecoverMultiplier(nodeRace)
	local nMultiplier = 1;
	local sMultiplier = DB.getValue(nodeRace, "recx", nil);
	
	if sMultiplier then
		sMultiplier = string.gsub(sMultiplier, "%a", "");
		sMultiplier = string.gsub(sMultiplier, "%s", "");
		if sMultiplier ~= "" then
			nMultiplier = tonumber(sMultiplier);
		end
	end

	return nMultiplier;
end
