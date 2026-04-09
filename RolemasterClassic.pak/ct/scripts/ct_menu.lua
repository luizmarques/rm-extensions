-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	setColor(ColorManager.getButtonTextColor());
	if Session.IsHost then
		registerMenuItem(Interface.getString("ct_menu_itemdelete"), "delete", 3);
		registerMenuItem(Interface.getString("ct_menu_itemdeletenonfriendly"), "delete_nonfriendly", 3, 1);
		registerMenuItem(Interface.getString("ct_menu_itemdeletefoe"), "delete_foes", 3, 3);
		
		registerMenuItem("Reset the Combat Round back to Round 1", "resetround", 4);
		registerMenuItem("Initiative", "initiative", 5);
		registerMenuItem("Roll All Initiatives", "rollallinits", 5, 8);
		registerMenuItem("Roll NPC Initiatives", "rollnpcinits", 5, 7);
		registerMenuItem("Roll PC Initiatives", "rollpcinits", 5, 6);
		registerMenuItem("Clear All Initiatives", "clearallinits", 5, 4);
		
		registerMenuItem("Rest", "rest", 6);
		registerMenuItem("Rest 1 Hour. 1 hit and all exhaustion recovered.", "rest_1_hour", 6, 3);
		registerMenuItem("Rest 2 Hours. 2 hits and all exhaustion recovered.", "rest_2_hours", 6, 4);
		registerMenuItem("Rest 4 Hours. 4 hits and all exhaustion recovered.", "rest_4_hours", 6, 5);
		registerMenuItem("Rest 8 Hours. 8 hits, all exhaustion and PP recovered.", "rest_8_hours", 6, 6);
		registerMenuItem("Rest 12 Hours. 12 hits, all exhaustion and PP recovered.", "rest_12_hours", 6, 7);
		registerMenuItem("Rest 24 Hours. 24 hits, all exhaustion and PP recovered.", "rest_24_hours", 6, 8);
		registerMenuItem("Remove", "rest_remove", 6, 1);
		registerMenuItem("Remove all Hits", "rest_hits", 6, 1, 6);
		registerMenuItem("Remove all PP", "rest_pp", 6, 1, 7);
		registerMenuItem("Remove all Hits and PP", "rest_hits_pp", 6, 1, 1);

		registerMenuItem("Update PC Ownership", "update_pc_ownership", 8);
		
		CombatManager2.notifyCTUpdateOwners();
	end
end

function onClickDown(button, x, y)
	return true;
end
function onClickRelease(button, x, y)
	if button == 1 then
		Interface.openContextMenu();
		return true;
	end
end

function onMenuSelection(selection, subselection, subsubselection)
	if Session.IsHost then
		if selection == 3 then
			if subselection == 1 then
				CombatManager.deleteNonFaction("friend");
			elseif subselection == 3 then
				CombatManager.deleteFaction("foe");
			end
		elseif selection == 4 then
			window.round.setValue(1);
			CombatManager2.resetTurnComplete();
		elseif selection == 5 then
			if subselection == 4 then
				CombatManager2.clearAllInit();
			elseif subselection == 8 then
				CombatManager2.rollAllInit();
			elseif subselection == 7 then
				CombatManager2.rollAllInit("npc");
			elseif subselection == 6 then
				CombatManager2.rollAllInit("charsheet");
			end
		elseif selection == 6 then
			if subselection == 3 then
				CombatManager2.restHours(1);
			elseif subselection == 4 then
				CombatManager2.restHours(2);
			elseif subselection == 5 then
				CombatManager2.restHours(4);
			elseif subselection == 6 then
				CombatManager2.restHours(8);
			elseif subselection == 7 then
				CombatManager2.restHours(12);
			elseif subselection == 8 then
				CombatManager2.restHours(24);
			elseif subselection == 1 then
				if subsubselection == 6 then
					CombatManager2.restRemoveHits();
				elseif subsubselection == 7 then
					CombatManager2.restRemovePP();
				elseif subsubselection == 1 then
					CombatManager2.restRemoveHitsPP();
				end
			end
		elseif selection == 8 then
			CombatManager2.notifyCTUpdateOwners();
		end
	end
end
