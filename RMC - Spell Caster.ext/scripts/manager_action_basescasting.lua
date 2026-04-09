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

function performRoll(draginfo, rActor, sSpellList, sSpellListNodeName, sRealm, nFailure, tSpell, bSecretRoll)
	local nMod = 0;
	local sDiceType = ActionRMDice.D100;
	local sSpellName = nil;
	local sSpellNodeName = nil;
	local nSpellLevel = 0;

	if type(tSpell) == "table" then
		sSpellName = tSpell.sSpellName;
		sSpellNodeName = tSpell.sSpellNodeName;
		nSpellLevel = tSpell.nSpellLevel or 0;
	else
		bSecretRoll = tSpell;
	end

	local bIsIndividualSpell = (sSpellList == (sSpellName or ""));

	local sDescSpell = "[BASE CASTING ROLL] " .. (sSpellName or sSpellList or "");
	local sDesc = sDescSpell;
	sDesc = sDesc .. " (fumble range = " .. nFailure .. ")";
	local tData = DiceRollManagerRMC.getRealmRRTData(sRealm);
	local aDice = {};

	DiceRollManagerRMC.addRealmRRDice(aDice, { "d100" }, tData);
	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll, aDice);
	rRoll.sSpellList = sSpellList;
	rRoll.sSpellListNodeName = sSpellListNodeName;
	rRoll.sSpellName = sSpellName;
	rRoll.sSpellNodeName = sSpellNodeName;
	rRoll.nSpellLevel = nSpellLevel;
	rRoll.nFailure = nFailure;
	rRoll.bIsSpellList = not bIsIndividualSpell;

	-- Resolve rActor if not provided
	if not rActor then
		local node = DB.findNode(sSpellListNodeName);
		if node then
			local nodeChar;
			if bIsIndividualSpell then
				nodeChar = DB.getParent(DB.getParent(node));
			else
				nodeChar = DB.getParent(node);
			end
			rActor = ActorManager.resolveActor(nodeChar);
		end
	end

	-- Check PP before performing roll
	local nodeChar = nil;
	if rActor then
		nodeChar = ActorManager.getCreatureNode(rActor);
	end
	if nodeChar then
		local nUsedPP = DB.getValue(nodeChar, "pp.used", 0);
		local nMaxPP = DB.getValue(nodeChar, "pp.max", 0);
		if nUsedPP + rRoll.nSpellLevel > nMaxPP then
			local rMessage = { text = "No Power Points", font = "systemfont" };
			Comm.deliverChatMessage(rMessage);
			return;
		end
	end

	-- PP used is now updated in onRoll, after roll result processing.
	if rActor then
		local nodeCreature = ActorManager.getCreatureNode(rActor);
		local sCreaturePath = "";
		if nodeCreature then
			sCreaturePath = DB.getPath(nodeCreature) or "";
		end
		local sActorType = "NPC";
		if ActorManager.isPC(rActor) then
			sActorType = "Player";
		end

		rRoll.nodeAttackerName = sCreaturePath;
		rRoll.nodeActorName = sCreaturePath;
		rRoll.targetNodeName = sCreaturePath;
		rRoll.attackerName = ActorManager.getDisplayName(rActor);
		rRoll.actorName = ActorManager.getDisplayName(rActor);
		rRoll.targetName = ActorManager.getDisplayName(rActor);
		rRoll.actorType = sActorType;
	else
		rRoll.nodeAttackerName = "";
		rRoll.nodeActorName = "";
		rRoll.targetNodeName = "";
		rRoll.attackerName = "";
		rRoll.actorName = "";
		rRoll.targetName = "";
		rRoll.actorType = "";
	end
	
	ActionsManager.performAction(draginfo, rActor, rRoll, rActor);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);
		
	if rMessage then
		rMessage.icon = "roll_cast";
		rMessage.shortcuts = {};
		if not rRoll.bIsSpellList then
			table.insert(rMessage.shortcuts, { class = "spelllist", recordname = rRoll.sSpellListNodeName });
		else
			table.insert(rMessage.shortcuts, { class = "spell", recordname = rRoll.sSpellNodeName });
		end

		-- Include caster name and actor type inside roll text instead of prefix (Player/NPC)
		if rRoll.actorName and rRoll.actorName ~= "" then
			local sActorType = rRoll.actorType or "NPC";
			if sActorType == "" then
				sActorType = "NPC";
			end

			local sActorText = "[" .. sActorType .. "] " .. rRoll.actorName .. " - ";
			rMessage.text = string.gsub(rMessage.text, "^%[BASE CASTING ROLL%] ", "[BASE CASTING ROLL] " .. sActorText);
		end

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

		-- Add spell level to PP used (applied after roll execution)
		if rRoll.nSpellLevel and rRoll.nSpellLevel > 0 then
			local nodeChar = nil;
			if rRoll.nodeActorName and rRoll.nodeActorName ~= "" then
				nodeChar = DB.findNode(rRoll.nodeActorName);
			end
			if not nodeChar and rSource then
				nodeChar = ActorManager.getCreatureNode(rSource);
			end
			if not nodeChar and rRoll.nodeAttackerName then
				nodeChar = DB.findNode(rRoll.nodeAttackerName);
			end

			if nodeChar then
				local nUsedPP = DB.getValue(nodeChar, "pp.used", 0);
				DB.setValue(nodeChar, "pp.used", "number", nUsedPP + rRoll.nSpellLevel);
			end
		end
		Comm.deliverChatMessage(rMessage);

	end
end
