-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Weapon Types
WeaponTypes = { [1] = "One-Handed Slashing", 
				[2] = "One-Handed Concussion", 
				[3] = "Two-Handed Weapon", 
				[4] = "Pole Arm", 
				[5] = "Missile Weapon",
				[6] = "Thrown Weapon",
				[7] = "Shield",
				[8] = "Natural Weapon",
				[9] = "Elemental Attack",
				[10] = "Special",
				[11] = "Accessory",
				[12] = "Armor",
				[13] = "Herbs, Etc.",
				[14] = "Potion",
				[15] = "Clothing",
				[16] = "Gem",
				[17] = "Food",
				[18] = "Service",
				[19] = "Transportation",
				[20] = "-",
}

function WeaponTypesList()
	return WeaponTypes;
end

function WeaponTypeID(sWeaponName)
	for nID, sName in pairs(WeaponTypes) do
		if sName == sWeaponName then
			return nID;
		end
	end
	return 0;
end

function IsRanged(sWeaponType)
	if sWeaponType == "Missile Weapon" or sWeaponType == "Thrown Weapon" or sWeaponType == "Elemental Attack" or sWeaponType == "Special" then
		return true;
	else
		return false;
	end
end
