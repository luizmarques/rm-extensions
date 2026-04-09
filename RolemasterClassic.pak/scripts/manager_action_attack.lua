-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "attack";
aAttackTargets = {};

OOB_MSGTYPE_ADDATTACKTOSTACK = "addattacktostack";
OOB_MSGTYPE_UPDATEACTIVITY = "updateactivity";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_ADDATTACKTOSTACK, handleAddAttackToStack);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_UPDATEACTIVITY, handleUpdateActivity);

	ActionsManager.registerTargetingHandler(ActionType, onTargeting);
	ActionsManager.registerModHandler(ActionType, modAttack);
	ActionsManager.registerResultHandler(ActionType, onAttack);
end

function handleAddAttackToStack(msgRoll)
	if msgRoll then
		StackManager.addEntry(msgRoll);
	end
end

function notifyAddAttackToStack(msgRoll)
	if not msgRoll then
		return;
	end

	msgRoll.type = OOB_MSGTYPE_ADDATTACKTOSTACK;

	Comm.deliverOOBMessage(msgRoll, "");
end

function handleUpdateActivity(msgActivity)
	if msgActivity and msgActivity.sActorNode then
		local nodeCreature = DB.findNode(msgActivity.sActorNode);
		if nodeCreature then	
			local nActivityMelee = msgActivity.nActivityMelee or 0;
			local nActivityMissile = msgActivity.nActivityMissile or 0;
			local nActivityConcentration = msgActivity.nActivityConcentration or 0;
			
			-- Update Activity Nodes
			DB.setValue(nodeCreature, "activitymelee", "number", nActivityMelee);
			DB.setValue(nodeCreature, "activitymissile", "number", nActivityMissile);
			DB.setValue(nodeCreature, "activityconcentration", "number", nActivityConcentration);
		end
	end
end

function notifyUpdateActivity(msgActivity)
	if not msgActivity then
		return;
	end

	msgActivity.type = OOB_MSGTYPE_UPDATEACTIVITY;

	Comm.deliverOOBMessage(msgActivity, "");
end

function performRoll(draginfo, rActor, rAction, bSecretRoll)
	local sDiceType = ActionRMDice.OpenEndedHigh;
	local sDesc = "[Attack] ";
	if rAction.label then
		sDesc = sDesc .. rAction.label;
	end
	local nMod = 0;
	local nodeCreature = ActorManager.getCreatureNode(rActor);
	local aDice = {};
	local tData = {}; 
	local sTableID = rAction.tableID;
	local sNodeAttack = rAction.nodeAttack;
	local nodeAttack = DB.findNode(sNodeAttack);
	local sAddCritTableID = "";
	if nodeAttack then
		sAddCritTableID = DB.getValue(nodeAttack, "addcrit1.tableid", "");
	end
	
	if sTableID == Rules_Constants.BaseSpellAttackTableID then
		local sRealm = Rules_PC.Realm(nodeCreature);
		tData = DiceRollManagerRMC.getRealmRRTData(sRealm);
		DiceRollManagerRMC.addRealmRRDice (aDice, { "d100" }, tData);
	elseif DiceRollManagerRMC.isResultTable(sTableID) or sTableID == Rules_Constants.ArmourySubdualCritTableID then
		tData = DiceRollManagerRMC.getResultTableTData(sTableID);
		DiceRollManagerRMC.addResultTableDice (aDice, { "d100" }, tData);
	elseif sAddCritTableID ~= "" and DiceRollManagerRMC.isResultTable(sAddCritTableID) then
		tData = DiceRollManagerRMC.getResultTableTData(sAddCritTableID);
		DiceRollManagerRMC.addResultTableDice (aDice, { "d100" }, tData);
	else
		tData = DiceRollManagerRMC.getAttackTData(sTableID);
		DiceRollManagerRMC.addAttackDice (aDice, { "d100" }, tData);
	end
	
	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll, aDice);
	rRoll.nodeAttack = sNodeAttack;
	rRoll.tableID = sTableID;
	if nodeCreature then
		rRoll.nodeAttackerName = DB.getPath(nodeCreature);
		rRoll.attackerName = ActorManager.getDisplayName(rActor);
		rRoll.nodeActorName = rRoll.nodeAttackerName;
		rRoll.actorName = rRoll.attackerName;
	end
	rRoll.tableType = Rules_Tables.GetTableType(rRoll.tableID);
	rRoll.OB = rAction.OB;
	rRoll.hitsMultiplier = rAction.hitsMultiplier;

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modAttack(rSource, rTarget, rRoll)
	-- Verify that this is the first roll so we don't duplicate modifiers on open-ended rolls
	if not rRoll.sResults then
		local nodeCreature = ActorManager.getCreatureNode(rSource);
		local nodeCT = ActorManager.getCTNode(rSource);
		local nodeAttack = nil;
		local targetNode = nil;
		local modifiers = {};

		table.insert(modifiers, {description="OB - Offense bonus", number=rRoll.OB});	
		if rRoll.nodeAttack then
			nodeAttack = DB.findNode(rRoll.nodeAttack);
			local sClass, sRecordName = DB.getValue(nodeAttack, "open", nil);
			if sRecordName and sRecordName ~= "" then
				nodeAttack = DB.findNode(sRecordName);
			end
		end

		if nodeAttack then
			rRoll.attackDBNodeName = DB.getPath(nodeAttack);
			rRoll.attackDBNodeClass = DB.getValue(nodeAttack, "open");
			
			rRoll.fumbleValue = DB.getValue(nodeAttack, "fumble", 2);
			rRoll.maxResultLevel = DB.getValue(nodeAttack, "max_level", 999);
			rRoll.largeColumnName = DB.getValue(nodeAttack, "largecolumnname", "Normal");

			-- Get Non-ID OB modifiers
			Rules_Modifiers.OB_NonID(modifiers, nodeAttack);

			-- Get for OB Effects modifiers
			Rules_Modifiers.Effects_OB(modifiers, nodeCreature);

			-- adjust for alternate criticals 
			local critTableType = DB.getValue(nodeAttack, "criticaltable", "");
			local critTableID = nil;
			local critTableName = nil;
			local altCritMod = 0;
			if critTableType == "Alternate Crit #1" then
				if DB.getChild(nodeAttack, "altcrit1.tableid") and DB.getChild(nodeAttack, "altcrit1.name") and DB.getChild(nodeAttack, "altcrit1mod") then
					critTableID = DB.getValue(nodeAttack, "altcrit1.tableid", "");
					critTableName = DB.getValue(nodeAttack, "altcrit1.name", "");
					altCritMod = DB.getValue(nodeAttack, "altcrit1mod", 0);
				end
			elseif critTableType == "Alternate Crit #2" then
				if DB.getChild(nodeAttack, "altcrit2.tableid") and DB.getChild(nodeAttack, "altcrit2.name") then
					critTableID = DB.getValue(nodeAttack, "altcrit2.tableid", "");
					critTableName = DB.getValue(nodeAttack, "altcrit2.name", "");
					altCritMod = DB.getValue(nodeAttack, "altcrit2mod", 0);
				end
			elseif critTableType == "Alternate Crit #3" then
				if DB.getChild(nodeAttack, "altcrit3.tableid") and DB.getChild(nodeAttack, "altcrit3.name") then
					critTableID = DB.getValue(nodeAttack, "altcrit3.tableid", "");
					critTableName = DB.getValue(nodeAttack, "altcrit3.name", "");
					altCritMod = DB.getValue(nodeAttack, "altcrit3mod", 0);
				end
			end
			if critTableID and critTableName then
				rRoll.critTableID = critTableID;
				rRoll.critTableName = critTableName;
				table.insert(modifiers, {description="Alternate Crit Mod", number=altCritMod});
			end
		end
		
		if rTarget then
			targetNode = ActorManager.getCTNode(rTarget);
			if targetNode then
				rRoll.targetName = ActorManager.getDisplayName(rTarget);
				rRoll.targetNodeName = DB.getPath(targetNode);
				rRoll.tableColumn = DB.getValue(targetNode, "at", 1);
			end
		end
		if nodeCT then
			-- Get Current Activity Values
			local nActivityMelee = DB.getValue(nodeCT, "activitymelee", 0);
			local nActivityMissile = DB.getValue(nodeCT, "activitymissile", 0);
			local nActivityConcentration = DB.getValue(nodeCT, "activityconcentration", 0);
			local msgActivity = {};
			msgActivity.sActorNode = DB.getPath(nodeCT);
			
			-- Check if Base Spell Attack
			local sTableID = rRoll.tableID;
			if sTableID == Rules_Constants.BaseSpellAttackTableID then
				rRoll.columnTitle = "General";
				-- Check Cover Modifiers and Conditions
				if EffectManagerRMC.hasEffect(rTarget, "CoverSoftHalf") or ModifierManager.getKey("halfsoft") or
									EffectManagerRMC.hasEffect(rTarget, "CoverHardHalf") or ModifierManager.getKey("halfhard") then
					table.insert(modifiers, { description = "Partial Cover", number = -10 });
				end
				if EffectManagerRMC.hasEffect(rTarget, "CoverSoftFull") or ModifierManager.getKey("fullsoft") or
									EffectManagerRMC.hasEffect(rTarget, "CoverHardFull") or ModifierManager.getKey("fullhard") then
					table.insert(modifiers, { description = "Full Cover", number = -20 });
				end

				-- Check for static target
				Rules_Modifiers.TargetStunned(modifiers, targetNode, sTableID);

				-- Check Range Modifiers
				local nRange = CombatManager2.getRange(ActorManager.getCTNode(rSource), ActorManager.getCTNode(rTarget));
				local nReach = DB.getValue(nodeCreature, "reach", GameSystem.getDistanceUnitsPerGrid());
				Rules_Modifiers.AttackRange(modifiers, nodeAttack, nRange, nReach);

				-- Track activity for exhaustion
				nActivityConcentration = nActivityConcentration + 1;

			-- Need to add check for Result tables so modifiers aren't added
			elseif Rules_Tables.GetTableType(sTableID) == Rules_Constants.TableType.Result then
				-- Track activity for exhaustion
				nActivityConcentration = nActivityConcentration + 1;

			-- Handle all other attack rolls
			else
				local sAttackType = DB.getValue(nodeAttack, "type", "");
				if sAttackType == "Missile Weapon" or sAttackType == "Thrown Weapon" then
					isMissile = true;
					Rules_Modifiers.ArmorMissilePenalty(modifiers, nodeCreature);

					-- Track activity for exhaustion
					nActivityMissile = nActivityMissile + 1;
				else
					isMissile = false;
					if sAttackType == "Elemental Attack" or sAttackType == "Special" or sAttackType == "Base Spell Item" then
						-- Track activity for exhaustion
						nActivityConcentration = nActivityConcentration + 1;
					else  -- Melee Attack
						-- Track activity for exhaustion
						nActivityMelee = nActivityMelee + 1;
					end
				end

				Rules_Modifiers.Hits(modifiers, nodeCreature);

				-- Get Exhaustion Modifier
				local nodeSource;
				local sourceType, sourceLink = DB.getValue(nodeCreature, "link", "");
				if sourceType == "charsheet" then
					nodeSource = DB.findNode(sourceLink);
				else
					nodeSource = nodeCreature;
				end
				local sDesc, nMod = Rules_Modifiers.Exhaustion(nodeSource);
				if sDesc ~= "" and nMod ~= 0 then
					table.insert(modifiers, { description = sDesc, number = nMod });
				end

				Rules_Modifiers.Effects(modifiers, nodeCreature);
				
				local nRange = CombatManager2.getRange(ActorManager.getCTNode(rSource), ActorManager.getCTNode(rTarget));
				local nReach = DB.getValue(nodeCreature, "reach", GameSystem.getDistanceUnitsPerGrid());
				Rules_Modifiers.AttackRange(modifiers, nodeAttack, nRange, nReach);

				-- Check Cover Modifiers and Conditions
				if EffectManagerRMC.hasEffect(rTarget, "CoverSoftHalf") or ModifierManager.getKey("halfsoft") then
					table.insert(modifiers, { description = "Half Soft Cover", number = -20 });
				end
				if EffectManagerRMC.hasEffect(rTarget, "CoverSoftFull") or ModifierManager.getKey("fullsoft") then
					table.insert(modifiers, { description = "Full Soft Cover", number = -40 });
				end
				if EffectManagerRMC.hasEffect(rTarget, "CoverHardHalf") or ModifierManager.getKey("halfhard") then
					table.insert(modifiers, { description = "Half Hard Cover", number = -50 });
				end
				if EffectManagerRMC.hasEffect(rTarget, "CoverHardFull") or ModifierManager.getKey("fullhard") then
					table.insert(modifiers, { description = "Full Hard Cover", number = -100 });
				end
				
				-- Check Flank/Rear Modifiers
				local bFlank = ModifierManager.getKey("flank");
				local bFlankRear = ModifierManager.getKey("rearflank");
				local bRear = ModifierManager.getKey("rear");

				if bFlank then
					table.insert(modifiers, { description = "Flank Attack", number = 15 });
				elseif bFlankRear then
					table.insert(modifiers, { description = "Rear Flank Attack", number = 25 });
				elseif bRear then
					table.insert(modifiers, { description = "Rear Attack", number = 35 });
				end

				if nodeCreature and targetNode then
					Rules_Modifiers.BonusVsAT(modifiers, nodeAttack, rRoll.tableColumn);
					Rules_Modifiers.TargetDefense(modifiers, nodeCreature, targetNode, isMissile);
					Rules_Modifiers.TargetStunned(modifiers, targetNode);
				end
			end
			-- Notify Activity Update
			msgActivity.nActivityMelee = nActivityMelee;
			msgActivity.nActivityMissile = nActivityMissile;
			msgActivity.nActivityConcentration = nActivityConcentration;
			notifyUpdateActivity(msgActivity);
		end

		-- add items in the modifier stack
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

function onTargeting(rSource, aTargeting, rRolls)
	-- if no targets then build the target list, aAttackTargets, from the Targets
	-- This needs to happen because of the rerolls for the high open-ended rolls being rerolled for each target instead of just the current target
	if #aAttackTargets == 0 then
		for _,vTargetGroup in ipairs(aTargeting) do
			for _,vTarget in ipairs(vTargetGroup) do
				table.insert(aAttackTargets, vTarget);
			end
		end
	end
	
	return aTargeting;
end

function onAttack(rSource, rTarget, rRoll)
	local bProcessRoll = false;
	local aRemainingTargets = {};

	-- Check if the target still needs to be processed
	local sTargetCTNodeName = ActorManager.getCTNodeName(rTarget);
	for _,aTarget in pairs(aAttackTargets) do
		if ActorManager.getCTNodeName(aTarget) == sTargetCTNodeName then
			bProcessRoll = true;
		else
			table.insert(aRemainingTargets, aTarget);
		end
	end	

	-- Process the Roll if no target selected
	if rTarget == nil then
		bProcessRoll = true;
	end
	
	-- Process the attack roll because the target is still valid
	if bProcessRoll then
		sTableID = rRoll.tableID;
		sTableType = rRoll.tableType;
		if sTableID == Rules_Constants.BaseSpellAttackTableID or (sTableType == "Result" and not Rules_Tables.IsOpenEndedResultTable(sTableID)) then
			rRoll.sDiceType = ActionRMDice.Closed;
		end
		
		local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);
		if rMessage then
			local nTotal = ActionsManager.total(rRoll);
			local sModText, nModTotal = Utilities.getModifierInfoFromRoll(rRoll);
			local targetName = "";
			if rTarget then
				targetName = " vs. " .. ActorManager.getDisplayName(rTarget);
			elseif string.find(rMessage.text, "[TOWER]", 1, true) then
				targetName = "";
			else
				targetName = " vs. <NO TARGET SELECTED>";
			end
			rRoll.name = rMessage.text;
			rRoll.dieResult = ActionRMDice.getDiceTotal(rRoll);
			rRoll.unmodified = rRoll.aDice[1].result;
			rRoll.dieType = ActionRMDice.OpenEndedHigh;
			rMessage.text = rMessage.text .. targetName;
			rMessage.diemodifier = nModTotal;
			rMessage.icon = "roll_attack";
			Comm.deliverChatMessage(rMessage);
			notifyAddAttackToStack(rRoll);
			
			bProcessRoll = false;
			aAttackTargets = aRemainingTargets;
		end
	end
end

