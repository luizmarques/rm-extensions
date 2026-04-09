-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	-- Check for empty list
	if Session.IsHost and 
			isEmpty() and 
			(getName() == "defences") and 
			not CombatManager2.isPC(window.getDatabaseNode()) then
		local w = self.addEntry();
		w.name.setValue("Parry");
	end
end

function onMenuSelection(selection)
	if not Session.IsHost then
		return;
	end
	if selection == 7 then
		local w = self.addEntry();
		w.registerDeleteMenu();
		return true;
	end
end
function addEntry()
	local w = createWindow();
	w.open.setValue("item", "");
	return w;
end

function onSortCompare(w1, w2)
	local bPC = CombatManager2.isPC(window.getDatabaseNode());
	return CombatManager2.onSortCompareAttackDefense(bPC, w1, w2);
end

function onDrop(x, y, draginfo)
	if not Session.IsHost then
		return;
	end

	if draginfo.isType("shortcut")  then
		local nodeSource = draginfo.getDatabaseNode();
		if nodeSource then
			local class = draginfo.getShortcutData();
			if (class == "weapon") or (class == "item") then
				local nodeNew;
				if getName() == "defences" then
					nodeNew = CombatManager2.addEntryWeaponItem(window.getDatabaseNode(), "defences", nodeSource);
				else
					nodeNew = CombatManager2.addEntryWeaponItem(window.getDatabaseNode(), "weapons", nodeSource);
				end
				self.helperAddDeleteMenuToNode(nodeNew);
				return true;
			elseif class == "spell" then
				local nodeNew;
				if getName() == "defences" then
					nodeNew = CombatManager2.addEntrySpellItem(window.getDatabaseNode(), "defences", nodeSource);
				else
					nodeNew = CombatManager2.addEntrySpellItem(window.getDatabaseNode(), "weapons", nodeSource);
				end
				self.helperAddDeleteMenuToNode(nodeNew);
				return true;
			end
		end
	end
	return false;
end
function helperAddDeleteMenuToNode(node)
	for _,w in ipairs(getWindows()) do
		if w.getDatabaseNode() == node then
			w.registerDeleteMenu();
			break;
		end
	end
end
