-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _nodeChar = nil;

function onInit()
	if Session.IsHost then
		attacks.registerMenuItem("New attack", "new_attack", 7);
		for _,w in ipairs(attacks.getWindows()) do
			w.registerDeleteMenu();
		end
	end

	_nodeChar = CombatManager2.getPCLinkNode(getDatabaseNode());
	if _nodeChar then
		for _,v in pairs(DB.getChildren(_nodeChar, "weapons")) do
			if DB.getValue(v, "type", "") ~= "Shield" then
				local sClass, sRecord = DB.getValue(v, "open", "", "");
				if (sClass == "item") then
					local nodeItem;
					if sRecord == "" then
						nodeItem = v;
					else
						nodeItem = DB.findNode(sRecord);
					end
					if nodeItem then
						attacks.createWindow(nodeItem);
					end
				end
			end
		end
	end

	if Session.IsHost and (attacks.isEmpty()) then
		local w = attacks.addEntry();
		w.registerDeleteMenu();
	end

	for _,w in ipairs(attacks.getWindows()) do
		w.updateNotes();
	end

	self.onParryChanged();

	self.registerCharDataHandlers();
end
function onClose()
	self.unregisterCharDataHandlers();
end

function onTypeChanged()
	for _,w in ipairs(attacks.getWindows()) do
		w.updateNotes();
	end
end
function onParryChanged()
	local nParry = parrymelee.getValue() + parrymissile.getValue();
	for _,w in ipairs(attacks.getWindows()) do
		w.onParryChanged(nParry);
	end
end

function registerCharDataHandlers()
	if _nodeChar then
		DB.addHandler(DB.getPath(_nodeChar), "onDelete", self.onCharDelete);
		DB.addHandler(DB.getPath(_nodeChar, "weapons"), "onChildAdded", self.onCharWeaponAdd);
	end
end
function unregisterCharDataHandlers()
	if _nodeChar then
		DB.removeHandler(DB.getPath(_nodeChar), "onDelete", self.onCharDelete);
		DB.removeHandler(DB.getPath(_nodeChar, "weapons"), "onChildAdded", self.onCharWeaponAdd);
	end
end
function onCharDelete()
	self.unregisterCharDataHandlers();
	_nodeChar = nil;
end
function onCharWeaponAdd(_,nodeWeapon)
	attacks.createWindow(nodeWeapon);
end
