-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "spellgain";

function onInit()
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function performRoll(draginfo, rActor, sDiceType, sSpellListName, sSpellListType, iChance, bSecretRoll)
	local sDesc = "[Spell Gain Roll] " .. sSpellListType .. " List * " .. sSpellListName; 
	local nMod = iChance;

	if nMod ~= 0 then
		sDesc = sDesc .. "[Spell Gain Bonus ";
		if nMod > 0 then
			sDesc = sDesc .. "+";
		end
		sDesc = sDesc .. nMod .. "]";
	end

	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);

	if rMessage then
		local nTotal = ActionsManager.total(rRoll);

		if nTotal >= 101 then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
		Comm.deliverChatMessage(rMessage);
	end
end
