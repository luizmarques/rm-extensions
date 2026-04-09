-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	refresh();
	newtemp.setValue(temp.getValue());
	statgainroll.setValue(0);
	result.setValue(0);

	local node = getDatabaseNode();
	DB.addHandler(DB.getPath(node, "temp"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "potential"), "onUpdate", self.refresh);
	DB.addHandler(DB.getPath(node, "statgainroll"), "onUpdate", self.refresh);
end

function refresh()
	difference.setValue(potential.getValue() - temp.getValue());
	result.setValue(Rules_Stats.StatGain(difference.getValue(), statgainroll.getValue()));
	if statgainroll.getValue() > 0 then
		newtemp.setValue(temp.getValue() + result.getValue());
	end
end

