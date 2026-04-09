-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "statgen";

function onInit()
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function performRoll(draginfo, rActor, sDiceType, sAbilityStat, sNodeName, bSecretRoll, bReRoll)
	local sStatType = StringManager.capitalize(string.gsub(sNodeName, "roll", ""));
	local sStatName = StringManager.capitalize(Rules_Stats.StatEntryFromAbbr(sAbilityStat).name);
	local nMod = 0;
	local sDesc = ""
	
	if bReRoll then
		sDesc = sDesc .. "[STAT GEN REROLL] ";
	else
		sDesc = sDesc .. "[STAT GEN] ";
	end
	sDesc = sDesc .. sStatName .. " * " .. sStatType;
	
	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll);
	rRoll.sAbilityStat = sAbilityStat;
	rRoll.sNodeName = sNodeName;

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);

	if rMessage then
		local nTotal = ActionsManager.total(rRoll);
		local nMinRoll = 20;
			
		if Rules_Stats.StatGenMinRollValue() then
			nMinRoll = Rules_Stats.StatGenMinRollValue();
		end
		
		if (rRoll.sNodeName == "temproll" or string.lower(OptionsManager.getOption("CGEN")) == string.lower(Interface.getString("option_val_on"))) and nTotal < nMinRoll then
			Comm.deliverChatMessage(rMessage);
			performRoll(draginfo, rSource, rRoll.sDiceType, rRoll.sAbilityStat, rRoll.sNodeName, rRoll.bSecret, true);
		else
			local tStat = Rules_Stats.StatEntryFromAbbr(rRoll.sAbilityStat);
			local nodeCreature = ActorManager.getCreatureNode(rSource);
			if nodeCreature then
				DB.setValue(nodeCreature, "abilities." .. tStat.nodename .. "." .. rRoll.sNodeName, "number", nTotal);
			end
			Comm.deliverChatMessage(rMessage);
		end
	end
end
