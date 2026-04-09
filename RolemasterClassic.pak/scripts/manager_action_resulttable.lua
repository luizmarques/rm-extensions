-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "resulttable";

OOB_MSGTYPE_RESULTTABLE = "resulttable";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_RESULTTABLE, handleResultTable);

	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function handleResultTable(msgActivity)
	if Session.IsHost and msgActivity and msgActivity.nTotal then
		local resolver = Interface.openWindow("tableresolver","");	

		if resolver then
			resolver.result_roll.setValue(msgActivity.nTotal);
		end
	end
end

function notifyResultTable(msgActivity)
	if not msgActivity then
		return;
	end

	msgActivity.type = OOB_MSGTYPE_RESULTTABLE;

	Comm.deliverOOBMessage(msgActivity, "");
end

function performRoll(draginfo, rActor, sTableID, bSecretRoll)
	local nMod = 0;
	local sDiceType = ActionRMDice.D100;
	local sDesc = "[RESULT TABLE ROLL] ";
	local tData = DiceRollManagerRMC.getResultTableTData(sTableID);
	local nodeTable = RMTableManager.getNode(sTableID);
	local aDice = {};

	if Rules_Tables.IsOpenEndedResultTable(sTableID) then
		sDiceType = ActionRMDice.OpenEndedHigh;
	end
	
	if nodeTable then
		sDesc = sDesc  .. RMTableManager.getTableClass(nodeTable) .. ": " .. RMTableManager.getTableName(nodeTable);
	end

	DiceRollManagerRMC.addResultTableDice (aDice, { "d100" }, tData);
	rRoll = ActionRMDice.setupRoll(ActionType, sDiceType, nMod, sDesc, bSecretRoll, aDice);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	local rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);
	local nTotal = 0;

	for _, v in ipairs(rRoll.aDice) do
		if v.result then
			nTotal = nTotal + v.result;
		end
	end
			
	rRoll.nTotal = nTotal;

	if rMessage then
		Comm.deliverChatMessage(rMessage);
		notifyResultTable(rRoll);
	end
end
