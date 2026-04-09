-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "initiative";

function onInit()
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function performRoll(draginfo, rActor, bSecretRoll)
	local tOutput = {};
	table.insert(tOutput, string.format("[%s]", Interface.getString("action_init_tag")));

	local nMod = 0;
	local nodeCreature = ActorManager.getCreatureNode(rActor);
	if nodeCreature then
		if ActorManager.isPC(rActor) then
			nMod = DB.getValue(nodeCreature, "initiative.total", 0);
		else
			local sAQ = DB.getValue(nodeCreature, "aq", "");
			if string.len(sAQ) > 1 then
				nMod = Rules_NPC.GetInitMod(sAQ);
			else
				nMod = DB.getValue(nodeCreature, "initmod", "");
			end
		end
	end
	if nMod ~= 0 then
		table.insert(tOutput, string.format("[BONUS %+d]", nMod));
	end

	local aEffectDice, nEffectBonus = EffectManagerRMC.getEffectsBonus(rActor, "INIT");
	if nEffectBonus ~= 0 then
		table.insert(tOutput, EffectManager.buildEffectOutput(nEffectBonus));
		nMod = nMod + nEffectBonus;
	end

	local sDesc = table.concat(tOutput, " ");
	if string.lower(OptionsManager.getOption("INTD")) == string.lower(Interface.getString("option_val_2d10")) then
		rRoll = setupNormalDiceRoll(ActionType, { "d10", "d10" }, nMod, sDesc, bSecretRoll);
	else
		if string.lower(OptionsManager.getOption("INTD")) == string.lower(Interface.getString("option_val_d100")) then
			sDiceType = ActionRMDice.D100;
		elseif string.lower(OptionsManager.getOption("INTD")) == string.lower(Interface.getString("option_val_open_ended")) then
			sDiceType = ActionRMDice.OpenEnded;
		elseif string.lower(OptionsManager.getOption("INTD")) == string.lower(Interface.getString("option_val_high_open_ended")) then
			sDiceType = ActionRMDice.OpenEndedHigh;
		elseif string.lower(OptionsManager.getOption("INTD")) == string.lower(Interface.getString("option_val_low_open_ended")) then
			sDiceType = ActionRMDice.OpenEndedLow;
		end
		rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll);
	end
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function setupNormalDiceRoll(ActionType, aDice, nMod, sDesc, bSecretRoll)
	-- Setup a new Roll structure
	rRoll = {};
	rRoll.sType = ActionType;
	rRoll.aDice = aDice;
	if nMod then
		rRoll.nMod = nMod;
	else
		rRoll.nMod = 0;
	end
	if sDesc then
		if not rRoll.sDesc then
			rRoll.sDesc = sDesc;
		end
	else
		rRoll.sDesc = "";
	end
	rRoll.bSecret = bSecretRoll;
	
	return rRoll;
end

function onRoll(rSource, rTarget, rRoll)
	if string.lower(OptionsManager.getOption("INTD")) == string.lower(Interface.getString("option_val_2d10")) then
		rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	else
		rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);
	end

	if rMessage then
		local nTotal = ActionsManager.total(rRoll);
		local nodeCreature = ActorManager.getCreatureNode(rSource);
		if nodeCreature then
			if ActorManager.isPC(rSource) then
				DB.setValue(nodeCreature, "initiative.initresult", "number", nTotal);
			else
				DB.setValue(nodeCreature, "initresult", "number", nTotal);
			end
		end
		Comm.deliverChatMessage(rMessage);
	end
end
