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

	WindowManager.callSafeControlUpdate(self, "race", bReadOnly);
	updateDropDown("race", "racedropdown");
	WindowManager.callSafeControlUpdate(self, "profession", bReadOnly);
	updateDropDown("profession", "professiondropdown");
	
	stats.update(bReadOnly);
	resistances_base.update(bReadOnly);
	resistances_hybrid.update(bReadOnly);
end
