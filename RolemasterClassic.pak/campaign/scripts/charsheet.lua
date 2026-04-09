--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	WindowTabManager.populate(self);

	DB.addHandler(DB.getPath(getDatabaseNode(), "weight"), "onUpdate", self.onChange);
	DB.addHandler(DB.getPath(getDatabaseNode(), "abilities.strength.total"), "onUpdate", self.onChange);
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.load"), "onUpdate", self.onChange);
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.misc"), "onUpdate", self.onChange);
	DB.addHandler(DB.getPath(getDatabaseNode(), "encumbrance.base"), "onUpdate", self.onChange);

	DB.addHandler(DB.getPath(getDatabaseNode(), "bmr.race"), "onUpdate", self.onChange);

	OptionsManager.registerCallback("CEMV", self.onChange);

	Rules_PC.UpdateLevelBonuses(getDatabaseNode());
	
	self.onChange();
end

function onClose()
	DB.removeHandler(DB.getPath(getDatabaseNode(), "weight"), "onUpdate", self.onChange);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "abilities.strength.total"), "onUpdate", self.onChange);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.load"), "onUpdate", self.onChange);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.misc"), "onUpdate", self.onChange);
	DB.removeHandler(DB.getPath(getDatabaseNode(), "encumbrance.base"), "onUpdate", self.onChange);

	DB.removeHandler(DB.getPath(getDatabaseNode(), "bmr.race"), "onUpdate", self.onChange);

	OptionsManager.unregisterCallback("CEMV", self.onChange);
end

local _bUpdatingEncumbrance = false;
function onChange()
	if _bUpdatingEncumbrance then
		return;
	end
	_bUpdatingEncumbrance = true;
	CharEncumbranceManagerRMC.onEncumbranceChanged(getDatabaseNode());
	_bUpdatingEncumbrance = false;
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		local sClass, sRecord = draginfo.getShortcutData();

		if StringManager.contains({"reference_profession", "reference_race"}, sClass) then
			CharManager.addInfoDB(getDatabaseNode(), sClass, sRecord);
			return true;
		end
	end
end
