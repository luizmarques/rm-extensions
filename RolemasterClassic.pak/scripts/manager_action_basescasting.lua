-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "basecasting";

OOB_MSGTYPE_SPELLFAILURETOSTACK = "spellfailuretostack";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_SPELLFAILURETOSTACK, handleSpellFailureToStack);

	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function handleSpellFailureToStack(msgRoll)
	if msgRoll then
		msgRoll.name = string.gsub(msgRoll.sDesc, "BASE CASTING ROLL", "SPELL FAILURE");
		StackManager.addEntry(msgRoll);
	end
end

function notifySpellFailureToStack(msgRoll)
	if not msgRoll then
		return;
	end

	msgRoll.type = OOB_MSGTYPE_SPELLFAILURETOSTACK;

	Comm.deliverOOBMessage(msgRoll, "");
end

function performRoll(draginfo, rActor, sSpellList, sSpellListNodeName, sRealm, nFailure, bSecretRoll)
	local nMod = 0;
	local sDiceType = ActionRMDice.D100;
	local sDesc = "[BASE CASTING ROLL] " .. sSpellList .. " (fumble range = " .. nFailure .. ")";
	local tData = DiceRollManagerRMC.getRealmRRTData(sRealm);
	local aDice = {};

	DiceRollManagerRMC.addRealmRRDice(aDice, { "d100" }, tData);
	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll, aDice);
	rRoll.sSpellList = sSpellList;
	rRoll.sSpellListNodeName = sSpellListNodeName;
	rRoll.nFailure = nFailure;
	rRoll.nodeAttackerName = ActorManager.getCreatureNodeName(rActor);
	rRoll.nodeActorName = ActorManager.getCreatureNodeName(rActor);
	rRoll.targetNodeName = ActorManager.getCreatureNodeName(rActor);
	rRoll.attackerName = ActorManager.getDisplayName(rActor);
	rRoll.actorName = ActorManager.getDisplayName(rActor);
	rRoll.targetName = ActorManager.getDisplayName(rActor);
	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);
		
	if rMessage then
		rMessage.icon = "roll_cast";
		rMessage.shortcuts = {};
		table.insert(rMessage.shortcuts, { class = "spelllist", recordname = rRoll.sSpellListNodeName });
		if rRoll.aDice[1].result > (rRoll.nFailure + 0) then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [SPELL FAILURE]";
			rRoll.tableType = "Result";
			rRoll.tableID = "SF-01";
			rRoll.columnTitle = "Non-Attack Spells";
			rRoll.dieResult = 0;
			rRoll.nTotal = 0;

			notifySpellFailureToStack(rRoll);
		end
		Comm.deliverChatMessage(rMessage);

	end
end
