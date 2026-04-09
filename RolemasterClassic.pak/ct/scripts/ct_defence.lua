-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	self.onIDChanged();
	self.onNameChanged();

	OptionsManager.registerCallback("MISP", self.onNameChanged);
end
function onClose()
	OptionsManager.unregisterCallback("MISP", self.onNameChanged);
end

function registerDeleteMenu()
	if not Session.IsHost then
		return;
	end
	registerMenuItem("Delete defence","delete_defense",8);
	registerMenuItem(Interface.getString("list_menu_deleteconfirm"), "delete_defense", 8, 8);
end
function onMenuSelection(selection, subselection)
	if not Session.IsHost then
		return;
	end
	if selection == 8 and subselection == 8 then
		WindowManager.safeDelete(self);
	end
end

function onIDChanged()
	local bID = true;
	if (name.getValue() ~= "Parry") and CombatManager2.isPC(windowlist.window.getDatabaseNode()) then
		bID = (isidentified.getValue() == 1);
	end
	name.setVisible(bID);
	nonid_name.setVisible(not bID);
end
function onNameChanged()
	if name.getValue() == "Parry" then
		open.setVisible(false);
		local bOptionMISP = OptionsManager.isOption("MISP", "on");
		missilebonus.setVisible(bOptionMISP);
		spacer_missilebonus.setVisible(not bOptionMISP);
	else
		open.setVisible(true);
		missilebonus.setVisible(true);
		spacer_missilebonus.setVisible(false);
	end
end
function onMeleeBonusChanged()
	if name.getValue() == "Parry" then
		windowlist.window.onParryMeleeChanged(meleebonus.getValue());
	end
end
function onMissileBonusChanged()
	if name.getValue() == "Parry" then
		windowlist.window.onParryMissileChanged(missilebonus.getValue());
	end
end
