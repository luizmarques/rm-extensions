-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "resistance";

OOB_MSGTYPE_RESOLVERESISTANCE = "resolveresistance";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RESOLVERESISTANCE, handleResolveResistance);

	ActionsManager.registerModHandler(ActionType, modRoll);
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function handleResolveResistance(msgRoll)
	if msgRoll then
		if msgRoll.tableID then
			msgRoll.attackerName = msgRoll.actorName;
			msgRoll.name = msgRoll.sDesc;
			StackManager.addEntry(msgRoll);
		end
	end
end

function notifyResolveResistance(msgRoll)
	if not msgRoll then
		return;
	end

	msgRoll.type = OOB_MSGTYPE_RESOLVERESISTANCE;
	Comm.deliverOOBMessage(msgRoll, "");
end

function performPartySheetRoll(draginfo, rActor, sDiceType, nodeRR, sResistance)
	local rRoll = getRoll(rActor, sDiceType, nodeRR, sResistance, false);
	if DB.getValue("partysheet.hiderollresults", 0) == 1 then
		rRoll.bSecret = true;
	end
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performRoll(draginfo, rActor, sDiceType, nodeRR, sResistance, bSecretRoll)
	local rRoll = getRoll(rActor, sDiceType, nodeRR, sResistance, bSecretRoll);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function getRoll(rActor, sDiceType, nodeRR, sResistance, bSecretRoll)
	local sDesc = "[RR] " .. sResistance .. " ";
	local nMod = 0;
	local aDice = {};
	local tData = {}; 
	tData = DiceRollManagerRMC.getRealmRRTData(sResistance);
	DiceRollManagerRMC.addRealmRRDice (aDice, { "d100" }, tData);
	local rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll, aDice);
	
	local nodeActor = ActorManager.getCreatureNode(rActor);
	if nodeActor then
		rRoll.nodeActorName = DB.getPath(nodeActor);
		rRoll.actorName = ActorManager.getDisplayName(rActor);
		rRoll.nodeAttackerName = rRoll.nodeActorName;
		rRoll.attackerName = rRoll.actorName;
		rRoll.targetNodeName = rRoll.nodeActorName;
		rRoll.targetName = rRoll.actorName;
	end

	local nRRBonus = 0;
	if nodeRR then
		nRRBonus = DB.getValue(nodeRR, "total", 0);
	end
	rRoll.RRBonus = nRRBonus;
	rRoll.tableID = Rules_Constants.RRTableID;
	rRoll.tableType = Rules_Constants.TableType.Other;
	return rRoll;
end

function modRoll(rSource, rTarget, rRoll)
	-- Verify that this is the first roll so we don't duplicate modifiers on open-ended rolls
	if not rRoll.sResults then
		-- GET MODIFIERS
		local modifiers = {};
		local nodeCreature = ActorManager.getCreatureNode(rSource);

		-- RR Bonus
		if rRoll.RRBonus ~= 0 then
			table.insert(modifiers, { description = "RR Bonus", number = rRoll.RRBonus });
		end
		
		-- Effects Modifiers to RR
		Rules_Modifiers.Effects_RR(modifiers, nodeCreature);
		
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
		local aEffects, nEffectCount = EffectManagerRMC.getEffectsBonusByType(rSource, "RRTarget", true);
		local nTarget = 0;

		rRoll.dieResult = ActionRMDice.getDiceTotal(rRoll);
		rRoll.unmodified = rRoll.aDice[1].result;
		
		if nEffectCount > 0 then
			for _, v in pairs(aEffects) do
				nTarget = v.mod;
			end
		end
		
		if nTarget > 0 then
			local nTotal = ActionsManager.total(rRoll);
			
			if nTotal >= nTarget then
				rMessage.text = rMessage.text .. " [SUCCESS by " .. (nTotal - nTarget) .. "]";
			else
				rMessage.text = rMessage.text .. " [FAILED by " .. (nTarget - nTotal) .. "]";
			end
			
			rRoll.tableID = nil;
			rRoll.tableType = nil;
		end

		Comm.deliverChatMessage(rMessage);
		notifyResolveResistance(rRoll);
	end
end
