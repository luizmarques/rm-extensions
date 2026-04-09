-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	for kRecordType, vRecordType in pairs(aRecordOverrides) do
		LibraryData.overrideRecordTypeInfo(kRecordType, vRecordType);
	end
	LibraryData.setRecordViews(aListViews);
	LibraryData.setRecordTypeInfo("vehicle", nil);
end

function getItemRecordDisplayClass(vNode)
	local sRecordDisplayClass = "item";

	return sRecordDisplayClass;
end

function isItemIdentifiable(vNode)
	return (getItemRecordDisplayClass(vNode) == "item");
end

aDefaultSidebarState = {
	["create"] = "charsheet,race,profession,skill,spelllist,item",
};

aRecordOverrides = {
	-- CoreRPG overrides
	["charsheet"] = { 
		aCustom = {
			tWindowMenu = { ["left"] = { "chat_speak", "token_find", }, ["right"] = { "charsheet_copytonpc", }, },
		},
	},
	["npc"] = { 
		aDataMap = { "npc", "reference.creatures", "reference.npcs" }, 
		aGMListButtons = { "button_npc_byletter", "button_npc_bylevel" },
		sSidebarCategory = "campaign",
		aCustomFilters = {
			[" Level"] = { sField = "level", sType = "number" },
			["Group"] = { sField = "group", sType = "string" },
			["Subgroup"] = { sField = "subgroup" },
		},
	},
	["item"] = { 
		fIsIdentifiable = isItemIdentifiable,
		aDataMap = { "item", 
					"reference.equipment.accessories.list",
					"reference.equipment.armor.list",
					"reference.equipment.basespellitems.list",
					"reference.equipment.foodlodgingservices.list",
					"reference.equipment.transport.list",
					"reference.equipment.weapons.list",
					"reference.equipment.herbs.list",
					"reference.equipment.enchantedbreads.list",
					"reference.equipment.intoxicants.list",
					"reference.equipment.poisons.list",
					"reference.weaponlist.standardweapons",
					"reference.weaponlist.additionalweapons",
					"reference.weaponlist.blades",
					"reference.weaponlist.japaneseblades",
					"reference.weaponlist.orientalweapons",
					"reference.weaponlist.polearms",
					"reference.weaponlist.unusualweapons"			
					}, 
		fRecordDisplayClass = getItemRecordDisplayClass,
		aRecordDisplayClasses = { "item", "weapon", "herb", "transport" },
		sSidebarCategory = "campaign",
		aCustomFilters = {
			["Type"] = { sField = "type" },
			["Power Rating"] = { sField = "powerrating" },
		},
	},
	["race"] = {
		bExport = true, 
		aDataMap = { "race", "reference.racedata.list" }, 
		sRecordDisplayClass = "reference_race", 
		sSidebarCategory = "create",
	},
	["profession"] = {
		bExport = true, 
		aDataMap = { "profession", "reference.professions" }, 
		sRecordDisplayClass = "reference_profession", 
		sSidebarCategory = "create",
		aCustomFilters = {
			["Category"] = { sField = "category" },
			["Realm of Power"] = { sField = "realm" },
		},
	},
	["skill"] = {
		bExport = true, 
		aDataMap = { "skill", "reference.skilllist.primaryskills.list", "reference.skilllist.secondaryskills.list" }, 
		sRecordDisplayClass = "skill", 
		sSidebarCategory = "create",
		aCustomFilters = {
			["Skill Class"] = { sField = "class" },
			["Skill Group"] = { sField = "group" },
			["Skill Progression"] = { sField = "progression" },
			["Skill Type"] = { sField = "skilltype" },
		},
	},
	["spelllist"] = {
		bExport = true, 
		aDataMap = { "spelllist", "reference.spelllist.channeling.lists", "reference.spelllist.essence.lists", "reference.spelllist.mentalism.lists" }, 
		sRecordDisplayClass = "spelllist", 
		sSidebarCategory = "create",
		aCustomFilters = {
			["Realm of Power"] = { sField = "realm" },
			["Classification"] = { sField = "class" },
		},
	},
};

aListViews = {
	["npc"] = {
		["byletter"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=300 },
				{ sName = "level", sType = "number", sHeadingRes = "npc_grouped_label_level", nWidth=35 },
			},
			aFilters = { },
			aGroups = { { sDBField = "name", nLength = 1 } },
			aGroupValueOrder = { },
		},
		["bylevel"] = {
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "npc_grouped_label_name", nWidth=300 },
				{ sName = "level", sType = "number", sHeadingRes = "npc_grouped_label_level", nWidth=35 },
			},
			aFilters = { },
			aGroups = { { sDBField = "level" } },
			aGroupValueOrder = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },
		},
	},
};
