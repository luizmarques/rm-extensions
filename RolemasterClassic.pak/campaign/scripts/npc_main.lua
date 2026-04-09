-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function updateDropDown(sControl, sDropDown)
	if self[sControl].isReadOnly() then
		self[sDropDown].setVisible(false);
	else
		self[sDropDown].setVisible(true);
	end	
end
function updateLabel(sControl, sLabel)
	if self[sControl].isReadOnly() and not self[sControl].isVisible() then
		self[sLabel].setVisible(false);
	else
		self[sLabel].setVisible(true);
	end	
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	space.setReadOnly(bReadOnly);
	reach.setReadOnly(bReadOnly);
	senses.setReadOnly(bReadOnly);
	size.setReadOnly(bReadOnly);
	updateDropDown("size", "sizedropdown");

	level.setReadOnly(bReadOnly);
	at.setReadOnly(bReadOnly);
	hits.setReadOnly(bReadOnly);
	db.setReadOnly(bReadOnly);

	baserate.setReadOnly(bReadOnly);
	mnbonus.setReadOnly(bReadOnly);
	WindowManager.callSafeControlUpdate(self, "maxpace", bReadOnly);
	updateDropDown("maxpace", "maxpacedropdown");
	WindowManager.callSafeControlUpdate(self, "ms", bReadOnly);
	updateDropDown("ms", "msdropdown");
	WindowManager.callSafeControlUpdate(self, "aq", bReadOnly);
	updateDropDown("aq", "aqdropdown");
	if aq.getValue() ~= "" or bReadOnly then
		WindowManager.callSafeControlUpdate(self, "initmod", true);
	else
		WindowManager.callSafeControlUpdate(self, "initmod", false);
	end

	weapons.update(bReadOnly);
	weapons_iadd.setVisible(not bReadOnly);
	updateLabel("weapons", "weapons_attack_label");
	updateLabel("weapons", "weapons_ob_label");
	updateLabel("weapons", "weapons_chance_label");

	defences.update(bReadOnly);
	defences_iadd.setVisible(not bReadOnly);
	updateLabel("defences", "defences_defense_label");
	updateLabel("defences", "defences_melee_label");
	updateLabel("defences", "defences_missile_label");

	local bSection3 = false;
	if WindowManager.callSafeControlUpdate(self, "critmod", bReadOnly) then bSection3 = true; end;
	updateDropDown("critmod", "critmoddropdown");
	if WindowManager.callSafeControlUpdate(self, "immunity", bReadOnly) then bSection3 = true; end;
	updateDropDown("immunity", "immunitydropdown");
	divider3.setVisible(bSection3);
	
	local bSection4 = false;
	if WindowManager.callSafeControlUpdate(self, "protection_head", bReadOnly) then bSection4 = true; end;
	updateDropDown("protection_head", "protection_headdropdown");
	if WindowManager.callSafeControlUpdate(self, "protection_face", bReadOnly) then bSection4 = true; end;
	updateDropDown("protection_face", "protection_facedropdown");
	if WindowManager.callSafeControlUpdate(self, "protection_neck", bReadOnly) then bSection4 = true; end;
	updateDropDown("protection_neck", "protection_neckdropdown");
	if WindowManager.callSafeControlUpdate(self, "protection_torso", bReadOnly) then bSection4 = true; end;
	updateDropDown("protection_torso", "protection_torsodropdown");
	if WindowManager.callSafeControlUpdate(self, "protection_arms", bReadOnly) then bSection4 = true; end;
	updateDropDown("protection_arms", "protection_armsdropdown");
	if WindowManager.callSafeControlUpdate(self, "protection_legs", bReadOnly) then bSection4 = true; end;
	updateDropDown("protection_legs", "protection_legsdropdown");
	protection_header.setVisible(bSection4);
end
