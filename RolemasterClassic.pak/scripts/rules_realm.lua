-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Get Realm Information
function List()
	return { "", "Channeling", "Essence", "Mentalism", "Channeling/Essence", "Channeling/Mentalism", "Essence/Mentalism", "Arcane", "Elementalism" };
end

-- 
function RealmsMatch(sCharRealm, sItemRealm)
	if sCharRealm == sItemRealm or string.find(sCharRealm, sItemRealm) or string.find(sItemRealm, sCharRealm) or sCharRealm == "Arcane" or sItemRealm == "Arcane" then
		return true;
	end

	return false;
end
