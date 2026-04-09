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
function updateHeader(sControl, sHeader)
	if self[sControl].isReadOnly() and not self[sControl].isVisible() then
		self[sHeader].setVisible(false);
	else
		self[sHeader].setVisible(true);
	end	
end

function update()
	local nodeRecord = getDatabaseNode();
	local bReadOnly = WindowManager.getReadOnlyState(nodeRecord);
	local bID = LibraryData.getIDState("npc", nodeRecord);

	WindowManager.callSafeControlUpdate(self, "group", bReadOnly);
	updateDropDown("group", "groupdropdown");
	WindowManager.callSafeControlUpdate(self, "subgroup", bReadOnly);
	updateDropDown("subgroup", "subgroupdropdown");

	WindowManager.callSafeControlUpdate(self, "notes", bReadOnly);
	updateHeader("notes", "notes_header");

	WindowManager.callSafeControlUpdate(self, "abilities", bReadOnly);
	updateHeader("abilities", "abilities_header");

	WindowManager.callSafeControlUpdate(self, "description", bReadOnly);
	updateHeader("description", "description_header");
end
