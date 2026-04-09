-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Protection Types
ProtectionNone = "";
ProtectionLeather = "Leather";
ProtectionMetal = "Metal";

--Protection Locations
ProtectionHead = "Head";
ProtectionFace = "Face";
ProtectionNeck = "Neck";
ProtectionTorso = "Torso";
ProtectionArms = "Arms";
ProtectionLegs = "Legs";

-- Get Realm Information
function List()

	local aArmorTypes =
						{ Count = 20,
						  [1]  = {name="Skin", 								shortName="Skin", 						skillName="", 								minPenalty=0, 		maxPenalty=0, 		missilePenalty=0, 	dbPenalty=0},
						  [2]  = {name="Robes", 							shortName="Robes", 						skillName="", 								minPenalty=0, 		maxPenalty=0, 		missilePenalty=0, 	dbPenalty=0},
						  [3]  = {name="Light Hide", 						shortName="Light Hide", 				skillName="", 								minPenalty=0, 		maxPenalty=0, 		missilePenalty=0, 	dbPenalty=0},
						  [4]  = {name="Heavy Hide", 						shortName="Heavy Hide", 				skillName="", 								minPenalty=0, 		maxPenalty=0, 		missilePenalty=0, 	dbPenalty=0},
						  [5]  = {name="Leather Jerkin", 					shortName="Leather Jerkin", 			skillName="Maneuvering in Soft Leather", 	minPenalty=0, 		maxPenalty=0, 		missilePenalty=0, 	dbPenalty=0, 	esfEssense=-10,						protectionTorso=Rules_ArmorTypes.ProtectionLeather},
						  [6]  = {name="Leather Coat", 						shortName="Leather Coat", 				skillName="Maneuvering in Soft Leather", 	minPenalty=0, 		maxPenalty=-20, 	missilePenalty=-5, 	dbPenalty=0, 	esfEssense=-15,						protectionTorso=Rules_ArmorTypes.ProtectionLeather, 	protectionArms=Rules_ArmorTypes.ProtectionLeather},
						  [7]  = {name="Reinforced Leather Coat", 			shortName="Reinforced Leather Coat", 	skillName="Maneuvering in Soft Leather", 	minPenalty=-10, 	maxPenalty=-40, 	missilePenalty=-15, dbPenalty=-10, 	esfEssense=-20,						protectionTorso=Rules_ArmorTypes.ProtectionLeather,		protectionArms=Rules_ArmorTypes.ProtectionLeather},
						  [8]  = {name="Reinforced Full Leather Coat", 		shortName="Rein Full Leather Coat", 	skillName="Maneuvering in Soft Leather", 	minPenalty=-15, 	maxPenalty=-50, 	missilePenalty=-15, dbPenalty=-15, 	esfEssense=-25,						protectionTorso=Rules_ArmorTypes.ProtectionLeather,		protectionArms=Rules_ArmorTypes.ProtectionLeather, 	protectionLegs=Rules_ArmorTypes.ProtectionLeather},
						  [9]  = {name="Leather Breastplate", 				shortName="Leather Breastplate", 		skillName="Maneuvering in Rigid Leather", 	minPenalty=-5, 		maxPenalty=-50, 	missilePenalty=0, 	dbPenalty=0, 	esfEssense=-15,						protectionTorso=Rules_ArmorTypes.ProtectionLeather},
						  [10] = {name="Leather Breastplate and Greaves", 	shortName="Lthr Brstplate & Greaves", 	skillName="Maneuvering in Rigid Leather", 	minPenalty=-10, 	maxPenalty=-70, 	missilePenalty=-10, dbPenalty=-5,	esfEssense=-30,						protectionTorso=Rules_ArmorTypes.ProtectionLeather,		protectionArms=Rules_ArmorTypes.ProtectionLeather, 	protectionLegs=Rules_ArmorTypes.ProtectionLeather},
						  [11] = {name="Half-Hide Plate", 					shortName="Half-Hide Plate", 			skillName="Maneuvering in Rigid Leather", 	minPenalty=-15, 	maxPenalty=-90, 	missilePenalty=-20, dbPenalty=-15, 	esfEssense=-40,						protectionTorso=Rules_ArmorTypes.ProtectionLeather,		protectionArms=Rules_ArmorTypes.ProtectionLeather, 	protectionLegs=Rules_ArmorTypes.ProtectionLeather, 	protectionHead=Rules_ArmorTypes.ProtectionLeather,	protectionFace=Rules_ArmorTypes.ProtectionLeather, 	protectionNeck=Rules_ArmorTypes.ProtectionLeather},
						  [12] = {name="Full-Hide Plate", 					shortName="Full-Hide Plate", 			skillName="Maneuvering in Rigid Leather", 	minPenalty=-15, 	maxPenalty=-110, 	missilePenalty=-30, dbPenalty=-15, 	esfEssense=-50,						protectionTorso=Rules_ArmorTypes.ProtectionLeather,		protectionArms=Rules_ArmorTypes.ProtectionLeather, 	protectionLegs=Rules_ArmorTypes.ProtectionLeather, 	protectionHead=Rules_ArmorTypes.ProtectionLeather,	protectionFace=Rules_ArmorTypes.ProtectionLeather, 	protectionNeck=Rules_ArmorTypes.ProtectionLeather},
						  [13] = {name="Chain Shirt", 						shortName="Chain Shirt", 				skillName="Maneuvering in Chain", 			minPenalty=-10, 	maxPenalty=-70, 	missilePenalty=0, 	dbPenalty=-5, 	esfEssense=-35,	esfChanneling=-25,	protectionTorso=Rules_ArmorTypes.ProtectionMetal},
						  [14] = {name="Chain Shirt and Greaves", 			shortName="Chain Shirt & Greaves", 		skillName="Maneuvering in Chain", 			minPenalty=-15, 	maxPenalty=-90, 	missilePenalty=-10, dbPenalty=-10, 	esfEssense=-45,	esfChanneling=-35,	protectionTorso=Rules_ArmorTypes.ProtectionMetal, 		protectionArms=Rules_ArmorTypes.ProtectionMetal, 	protectionLegs=Rules_ArmorTypes.ProtectionMetal},
						  [15] = {name="Full Chain", 						shortName="Full Chain", 				skillName="Maneuvering in Chain", 			minPenalty=-25, 	maxPenalty=-120, 	missilePenalty=-20, dbPenalty=-20, 	esfEssense=-70,	esfChanneling=-60,	protectionTorso=Rules_ArmorTypes.ProtectionMetal, 		protectionArms=Rules_ArmorTypes.ProtectionMetal, 	protectionLegs=Rules_ArmorTypes.ProtectionMetal},
						  [16] = {name="Chain Hauberk", 					shortName="Chain Hauberk", 				skillName="Maneuvering in Chain", 			minPenalty=-25, 	maxPenalty=-130, 	missilePenalty=-20, dbPenalty=-20, 	esfEssense=-70,	esfChanneling=-60,	protectionTorso=Rules_ArmorTypes.ProtectionMetal, 		protectionArms=Rules_ArmorTypes.ProtectionMetal, 	protectionLegs=Rules_ArmorTypes.ProtectionMetal},
						  [17] = {name="Metal Breastplate", 				shortName="Metal Breastplate", 			skillName="Maneuvering in Plate", 			minPenalty=-15, 	maxPenalty=-90, 	missilePenalty=0, 	dbPenalty=-10, 	esfEssense=-40,	esfChanneling=-30,	protectionTorso=Rules_ArmorTypes.ProtectionMetal},
						  [18] = {name="Metal Breastplate and Greaves", 	shortName="Mtl Brstplate & Greaves", 	skillName="Maneuvering in Plate", 			minPenalty=-20, 	maxPenalty=-110, 	missilePenalty=-10, dbPenalty=-20, 	esfEssense=-50,	esfChanneling=-40,	protectionTorso=Rules_ArmorTypes.ProtectionMetal, 		protectionArms=Rules_ArmorTypes.ProtectionMetal, 	protectionLegs=Rules_ArmorTypes.ProtectionMetal},
						  [19] = {name="Half Plate", 						shortName="Half Plate", 				skillName="Maneuvering in Plate", 			minPenalty=-35, 	maxPenalty=-150, 	missilePenalty=-30, dbPenalty=-30, 	esfEssense=-75,	esfChanneling=-60,	protectionTorso=Rules_ArmorTypes.ProtectionMetal, 		protectionArms=Rules_ArmorTypes.ProtectionMetal, 	protectionLegs=Rules_ArmorTypes.ProtectionMetal},
						  [20] = {name="Full Plate", 						shortName="Full Plate", 				skillName="Maneuvering in Plate", 			minPenalty=-45, 	maxPenalty=-165, 	missilePenalty=-40, dbPenalty=-40, 	esfEssense=-90,	esfChanneling=-75,	protectionTorso=Rules_ArmorTypes.ProtectionMetal, 		protectionArms=Rules_ArmorTypes.ProtectionMetal, 	protectionLegs=Rules_ArmorTypes.ProtectionMetal}
						};
	return aArmorTypes;
end

function GetATDetails(nAT)
	local aArmorDetails = nil;
	
	for nArmorType, vArmor in pairs(Rules_ArmorTypes.List()) do
		if tonumber(nAT) == nArmorType then
			aArmorDetails = vArmor;
		end
	end
	
	return aArmorDetails;
end

function ProtectionTypeList()
	local aProtectionTypeList = {};

	table.insert(aProtectionTypeList, Rules_ArmorTypes.ProtectionNone);
	table.insert(aProtectionTypeList, Rules_ArmorTypes.ProtectionLeather);
	table.insert(aProtectionTypeList, Rules_ArmorTypes.ProtectionMetal);
	
	return aProtectionTypeList;
end

