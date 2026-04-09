-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local order = 1;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	--[[ load the RR list ]]
	local rrList = Rules_RR.List_Hybrid();
	for i = 1, #rrList do
		addEntry(rrList[i].order, rrList[i].resistancetype, rrList[i].label, rrList[i].resistances);
	end
	--[[ force a re-sort ]]
	applySort();
end

function addEntry(order, resistancetype, label, resistances)
	local name = string.lower(label);
	name = string.gsub(name, "/", "_");
	local node = DB.getChild(getDatabaseNode(), name);
	local win;
	if not node then
		node = DB.createChild(getDatabaseNode(), name);
	end
	for i,w in ipairs(getWindows()) do
		if DB.getName(w.getDatabaseNode())==name then
			win = w;
		end
	end
	if win then
		win.label.setValue(label);
		win.label.setTooltipText("Drag or double click to roll a " .. label .. " RR");
		win.order.setValue(order);
		win.resistancetype.setValue(resistancetype);
		win.resistances.setValue(resistances);
	end
end

function onSortCompare(w1, w2)
	return (w1.order.getValue() > w2.order.getValue());
end

function delete(win)
	local next = getNextWindow(win);
	if next then
		next.race.setFocus();
	end
	WindowManager.safeDelete(win);
end