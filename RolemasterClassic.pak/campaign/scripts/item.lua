-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit();

	local msgItem = {};
	msgItem.nodeName = getDatabasePath();
	ItemManager2.notifyUpdateToCoreRPG(msgItem);
	Rules_Tables.CheckTableList();
end
