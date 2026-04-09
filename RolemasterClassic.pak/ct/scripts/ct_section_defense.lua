-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if Session.IsHost then
		defences.registerMenuItem("New defence", "new_defense", 7);
	end

	local nodeChar = CombatManager2.getPCLinkNode(getDatabaseNode());
	if nodeChar then
		for _,v in pairs(DB.getChildren(nodeChar, "weapons")) do
			if DB.getValue(v, "type", "") == "Shield" then
				local sClass, sRecord = DB.getValue(v, "open", "", "");
				if (sClass == "item") then
					local nodeItem;
					if sRecord == "" then
						nodeItem = v;
					else
						nodeItem = DB.findNode(sRecord);
					end
					if nodeItem then
						defences.createWindow(nodeItem);
					end
				end
			end
		end
	end
end

function onParryMeleeChanged(nParryMelee)
	parrymelee.setValue(nParryMelee);
end
function onParryMissileChanged(nParryMissile)
	parrymissile.setValue(nParryMissile);
end
