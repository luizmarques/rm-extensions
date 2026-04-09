-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "statgain";

function onInit()
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function performRoll(draginfo, rActor, sDiceType, sAbilityStat, bSecretRoll)
	local sStatName = StringManager.capitalize(Rules_Stats.StatEntryFromAbbr(sAbilityStat).name);
	local nMod = 0;
	local sDesc = "[STAT GAIN] " .. sStatName;
	
	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll);
	rRoll.sAbilityStat = sAbilityStat;
	rRoll.sNodeName = sNodeName;
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);

	if rMessage then
		local nTotal = ActionsManager.total(rRoll);
		local tStat = Rules_Stats.StatEntryFromAbbr(rRoll.sAbilityStat);
		local nodeCreature = ActorManager.getCreatureNode(rSource);
		if nodeCreature then
			DB.setValue(nodeCreature, "abilities." .. tStat.nodename .. ".statgainroll", "number", nTotal);
		end
		Comm.deliverChatMessage(rMessage);
	end
end
