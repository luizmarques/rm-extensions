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

	WindowManager.callSafeControlUpdate(self, "realm", bReadOnly);
	updateDropDown("realm", "realmdropdown");
	WindowManager.callSafeControlUpdate(self, "ppmax", bReadOnly);
	WindowManager.callSafeControlUpdate(self, "spelladdermax", bReadOnly);

	spells.update(bReadOnly);
	spells_iadd.setVisible(not bReadOnly);
	updateLabel("spells", "spells_spelllist_label");
	updateLabel("spells", "spells_esf_label");
	updateLabel("spells", "spells_level_label");

	skills.update(bReadOnly);
	skills_iadd.setVisible(not bReadOnly);
	updateLabel("skills", "skills_skill_label");
	updateLabel("skills", "skills_ranks_label");
	updateLabel("skills", "skills_bonus_label");
end
