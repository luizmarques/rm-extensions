-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function action(draginfo)
	local tParty = PartyManager.getPartyActors();
	if #tParty == 0 then
		return true;
	end
	
	local sResistance = DB.getValue("partysheet.resistanceselected", "");
	ModifierStack.lock();
	for _,v in pairs(tParty) do
		local nodeCreature = ActorManager.getCreatureNode(v);
		if nodeCreature then
			local nodeRR, sName = Rules_RR.PartySheetGetNodeAndName(DB.getPath(nodeCreature), sResistance:lower());
			ActionResistance.performPartySheetRoll(nil, v, ActionRMDice.OpenEnded, nodeRR, sResistance);
		end
	end
	ModifierStack.unlock(true);
	return true;
end

function onButtonPress()
	return action();
end			
