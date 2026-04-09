-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "stat";

function onInit()
	ActionsManager.registerModHandler(ActionType, modRoll);
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function performPartySheetRoll(draginfo, rActor, sDiceType, sAbilityStat, sDifficulty)
	local rRoll = getRoll(rActor, sDiceType, sAbilityStat, bSecretRoll);
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
	end
	rRoll.difficultyName = sDifficulty;
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performRoll(draginfo, rActor, sDiceType, sAbilityStat, bSecretRoll)
	local rRoll = getRoll(rActor, sDiceType, sAbilityStat, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sDiceType, sAbilityStat, bSecretRoll)
	local tStat = Rules_Stats.StatEntryFromAbbr(sAbilityStat);
	local sDesc = "[STAT] " .. tStat.name .. " ";
	local nMod = 0;
	local nStatBonus = 0;
	local nodeCreature = ActorManager.getCreatureNode(rActor);
	if nodeCreature then
		nStatBonus = DB.getValue(nodeCreature, "abilities." .. tStat.nodename .. ".total", 0);
	end
	local rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll);
	rRoll.statBonus = nStatBonus;
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- Verify that this is the first roll so we don't duplicate modifiers on open-ended rolls
	if not rRoll.sResults then
		-- GET MODIFIERS
		local modifiers = {};

		-- Stat Bonus
		if rRoll.statBonus ~= 0 then
			table.insert(modifiers, { description = "Stat Bonus", number = rRoll.statBonus });
		end

		-- Damage / Exhaustion
		local nodeCreature = ActorManager.getCreatureNode(rActor);
		Rules_Modifiers.Hits(modifiers, nodeCreature);
		local sDesc, nMod = Rules_Modifiers.Exhaustion(nodeCreature);
		if sDesc ~= "" and nMod ~= 0 then
			table.insert(modifiers, { description = sDesc, number = nMod });
		end

		-- Check ModifierStack Difficulty
		local bRoutine = ModifierManager.getKey("routine");
		local bEasy = ModifierManager.getKey("easy");
		local bLight = ModifierManager.getKey("light");
		local bMedium = ModifierManager.getKey("medium");
		local bHard = ModifierManager.getKey("hard");
		local bVeryHard = ModifierManager.getKey("veryhard");
		local bExtremelyHard = ModifierManager.getKey("extremelyhard");
		local bSheerFolly = ModifierManager.getKey("sheerfolly");
		local bAbsurd = ModifierManager.getKey("absurd");

		if bRoutine then
			sDifficultyName = "Routine";
		elseif bEasy then
			sDifficultyName = "Easy";
		elseif bLight then
			sDifficultyName = "Light";
		elseif bMedium then
			sDifficultyName = "Medium";
		elseif bHard then
			sDifficultyName = "Hard";
		elseif bVeryHard then
			sDifficultyName = "Very Hard";
		elseif bExtremelyHard then
			sDifficultyName = "Extremely Hard";
		elseif bSheerFolly then
			sDifficultyName = "Sheer Folly";
		elseif bAbsurd then
			sDifficultyName = "Absurd";
		else
			sDifficultyName = "Medium";
		end
		nModifier = Rules_Modifiers.GetModFromDifficultyName(sDifficultyName);
		table.insert(modifiers, { description = sDifficultyName, number = nModifier });

		-- Handle Party Sheet Difficulty
		if rRoll.difficultyName then
			local nDifficultyMod = Rules_Modifiers.GetModFromDifficultyName(rRoll.difficultyName);
			table.insert(modifiers, { description = rRoll.difficultyName, number = nDifficultyMod });
		end

		-- Effects
		local nodeCT = ActorManager.getCTNode(rSource);
		Rules_Modifiers.Effects(modifiers, nodeCT);
		Rules_Modifiers.Effects_StatBonus(modifiers, nodeCT);

		-- Modifier Stack
		Utilities.AddModifierStack(modifiers);
		
		-- Determine Modifier Description and Total Modifier so they can be added to the roll
		local sModText = "";
		local nModTotal = 0;
		if modifiers then
			local nCount = 0;
			for i = 1, #modifiers do
				if not modifiers[i].gmonly then
					sModText = sModText .. " [" .. modifiers[i].description .. " ";
					if tonumber(modifiers[i].number) >= 0 then
						sModText = sModText .. "+";
					end
					sModText = sModText .. modifiers[i].number .. "]";
					nModTotal = nModTotal + modifiers[i].number;
				end
			end
		end
		
		rRoll.nMod = rRoll.nMod + nModTotal;
		rRoll.sDesc = rRoll.sDesc .. sModText;
	end	
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);

	if rMessage then
		rRoll.dieResult = ActionRMDice.getDiceTotal(rRoll);
		rRoll.unmodified = rRoll.aDice[1].result;

		Comm.deliverChatMessage(rMessage);
	end
end

