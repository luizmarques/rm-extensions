-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function handleDrop(sTarget, draginfo)
	if sTarget == "item" then
		local bAllowEdit = LibraryData.allowEdit(sTarget);
		if bAllowEdit then
			local sRootMapping = LibraryData.getRootMapping(sTarget);
			local sClass, sRecord = draginfo.getShortcutData();
			if ((sClass == "weapon") or (sClass == "herb") or (sClass == "transport")) and ((sRootMapping or "") ~= "") then
				local nodeSource = DB.findNode(sRecord);
				local nodeTarget = DB.createChild(sRootMapping);
				DB.copyNode(nodeSource, nodeTarget);
				DB.setValue(nodeTarget, "locked", "number", 1);
				return true;
			end
		end
	end
end

