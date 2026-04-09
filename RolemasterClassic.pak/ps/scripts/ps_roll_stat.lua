-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end
	
	local sAbilityStat = Rules_Stats.GetAbbrFromName(DB.getValue("partysheet.statselected", ""):lower());
	local sDifficulty = DB.getValue("partysheet.statdifficulty", "");
	ModifierStack.lock();
	for _,v in pairs(tParty) do
		ActionStat.performPartySheetRoll(nil, v, ActionRMDice.OpenEnded, sAbilityStat, sDifficulty);
	end
	ModifierStack.unlock(true);
	return true;
end

function onButtonPress()
	return action();
end			
