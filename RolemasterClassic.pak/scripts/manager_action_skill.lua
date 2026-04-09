-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "skill";

MM = 1;
SM = 2;

GenericMM = "Generic MM";
MovementMM = "Movement MM";

OOB_MSGTYPE_RESOLVESKILL = "resolveskill";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RESOLVESKILL, handleResolveSkill);

	ActionsManager.registerModHandler(ActionType, modRoll);
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function handleResolveSkill(msgRoll)
	if msgRoll then
		if msgRoll.tableID then
			msgRoll.attackerName = msgRoll.actorName;
			msgRoll.name = msgRoll.sDesc;
			
			StackManager.addEntry(msgRoll);
		end
	end
end

function notifyResolveSkill(msgRoll)
	if not msgRoll then
		return;
	end

	msgRoll.type = OOB_MSGTYPE_RESOLVESKILL;

	Comm.deliverOOBMessage(msgRoll, "");
end

function performPartySheetRoll(draginfo, rActor, sDiceType, sSkillName, sDifficulty)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	local nSkillMod = Rules_PC.SkillTotal(nodeActor, sSkillName);
	local nSkillType = Rules_Skills.SkillType(sSkillName);

	local rRoll = getRoll(rActor, sDiceType, sSkillName, nSkillType, nSkillMod, false);

	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
	end
	if nSkillType == ActionSkill.MM then
		rRoll.columnTitle = sDifficulty;
	else
		rRoll.difficultyName = sDifficulty;
	end
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performRoll(draginfo, rActor, sSkillName, nSkillMod, nSkillType, sColumnTitle, bSecretRoll)
	local rRoll = getRoll(rActor, ActionRMDice.OpenEnded, sSkillName, nSkillType, nSkillMod, bSecretRoll);
	if nSkillType == ActionSkill.MM then
		rRoll.columnTitle = sColumnTitle;
	end
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sDiceType, sSkillName, nSkillType, nSkillMod, bSecretRoll)
	local sDesc = "[" .. getSkillTypeString(nSkillType) .. "] " .. sSkillName .. " ";
	local nMod = 0;
	local rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll);

	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		rRoll.nodeAttackerName = DB.getPath(nodeActor);
		rRoll.attackerName = ActorManager.getDisplayName(rActor);
		rRoll.nodeActorName = DB.getPath(nodeActor);
		rRoll.actorName = ActorManager.getDisplayName(rActor);
		rRoll.targetName = attackerName;
		rRoll.targetNodeName = nodeActorName;
	end
	
	rRoll.dieType = sDiceType;
	rRoll.skillType = nSkillType;
	rRoll.skillName = sSkillName;
	rRoll.skillBonus = nSkillMod;
	rRoll.armorMult = Rules_PC.SkillArmorFactor(nodeActor, sSkillName);

	if nSkillType == ActionSkill.MM then
		rRoll.tableID = Rules_Constants.ManeuverTableDefaultTableId;
		rRoll.tableType = Rules_Constants.TableType.Other;
	elseif nSkillType == ActionSkill.SM and  string.lower(OptionsManager.getOption("CL24")) == string.lower(Interface.getString("option_val_on")) then
		rRoll.tableID = Rules_Constants.AlternativeStaticActionTableId;
		rRoll.columnTitle = Rules_Skills.GetStaticActionColumn(sSkillName);
		rRoll.tableType = Rules_Constants.TableType.Other;
	end
	
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll) 
	-- Verify that this is the first roll so we don't duplicate modifiers on open-ended rolls
	if not rRoll.sResults then
		-- GET MODIFIERS
		local modifiers = {};
		local nodeCreature = ActorManager.getCreatureNode(rSource);

		-- Skill Bonus
		if rRoll.skillBonus ~= 0 then
			table.insert(modifiers, { description = "Skill Bonus", number = rRoll.skillBonus });
		end

		-- Check Difficulty Modifiers
		local bRoutine = ModifierManager.getKey("routine");
		local bEasy = ModifierManager.getKey("easy");
		local bLight = ModifierManager.getKey("light");
		local bMedium = ModifierManager.getKey("medium");
		local bHard = ModifierManager.getKey("hard");
		local bVeryHard = ModifierManager.getKey("veryhard");
		local bExtremelyHard = ModifierManager.getKey("extremelyhard");
		local bSheerFolly = ModifierManager.getKey("sheerfolly");
		local bAbsurd = ModifierManager.getKey("absurd");

		if tonumber(rRoll.skillType) == ActionSkill.MM then
			-- MM Modifier
			if not rRoll.columnTitle then
				if bRoutine then
					rRoll.columnTitle = "Routine";
				elseif bEasy then
					rRoll.columnTitle = "Easy";
				elseif bLight then
					rRoll.columnTitle = "Light";
				elseif bMedium then
					rRoll.columnTitle = "Medium";
				elseif bHard then
					rRoll.columnTitle = "Hard";
				elseif bVeryHard then
					rRoll.columnTitle = "Very Hard";
				elseif bExtremelyHard then
					rRoll.columnTitle = "Extremely Hard";
				elseif bSheerFolly then
					rRoll.columnTitle = "Sheer Folly";
				elseif bAbsurd then
					rRoll.columnTitle = "Absurd";
				else
					rRoll.columnTitle = "Medium";
				end
			end
			Rules_Modifiers.MovementManueverModifier(modifiers, nodeCreature, rRoll.skillName, tonumber(rRoll.armorMult));
			rRoll.sDesc = rRoll.sDesc .. "- " .. rRoll.columnTitle .. " Difficulty ";
		else
			-- Handle Party Sheet Difficulty
			if rRoll.difficultyName then
				local nDifficultyMod = Rules_Modifiers.GetModFromDifficultyName(rRoll.difficultyName);
				table.insert(modifiers, { description = rRoll.difficultyName, number = nDifficultyMod });
			else -- Handle All other SM Difficulties
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
			end
			Rules_Modifiers.Effects_SM(modifiers, nodeCreature);
		end
		
		-- Hits of Damage
		Rules_Modifiers.Hits(modifiers, nodeCreature);
		-- Exhaustion
		local sDesc, nMod = Rules_Modifiers.Exhaustion(nodeCreature);
		if sDesc ~= "" and nMod ~= 0 then
			table.insert(modifiers, { description = sDesc, number = nMod });
		end

		-- Effects
		local nodeCT = ActorManager.getCTNode(rSource);
		Rules_Modifiers.Effects(modifiers, nodeCT, rRoll.skillName);
		Rules_Modifiers.Effects_Skill(modifiers, nodeCreature);
		
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
		rRoll.modifiers = {};
		rRoll.modifiers = Utilities.tableToString(modifiers);	
	end
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);

	if rMessage then
		rRoll.dieResult = ActionRMDice.getDiceTotal(rRoll);
		rRoll.unmodified = rRoll.aDice[1].result;

		Comm.deliverChatMessage(rMessage);
		notifyResolveSkill(rRoll);
	end
end

function getSkillTypeString(nSkillType)
	if tonumber(nSkillType) == ActionSkill.MM then
		return "MM";
	elseif tonumber(nSkillType) == ActionSkill.SM then
		return "SM";
	else
		return "";
	end
end

