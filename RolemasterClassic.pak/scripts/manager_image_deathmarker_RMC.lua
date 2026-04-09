-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function registerStandardDeathMarkersRMC()
	ImageDeathMarkerManager.setEnabled(true);

	ImageDeathMarkerManager.registerGetCreatureTypeFunction(ImageDeathMarkerManagerRMC.getCreatureTypeRMC);

	ImageDeathMarkerManager.registerCreatureTypes(Rules_NPC.SubgroupDeathMarkerList());

	ImageDeathMarkerManager.setCreatureTypeDefault("dangerous plants", "blood_green");
	ImageDeathMarkerManager.setCreatureTypeDefault("entities from other planes", "blood_black");
	ImageDeathMarkerManager.setCreatureTypeDefault("elementals and artificial beings", "blood_black");
	ImageDeathMarkerManager.setCreatureTypeDefault("the undead", "blood_violet");
end

function getCreatureTypeRMC(rActor)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if not nodeActor then
		return nil;
	end
	local sActorType = "";
	if ActorManager.isPC(rActor) then
		local _, sRecordName = DB.getValue(nodeActor, "racelink", nil);
		if sRecordName then
			local nodeRace = DB.findNode(sRecordName);
			if nodeRace then
				sActorType = DB.getValue(nodeRace, "deathmarker", "");
			end
		end
	else
		sActorType = DB.getValue(nodeActor, "subgroup", "");
	end

	return sActorType:lower();
end
