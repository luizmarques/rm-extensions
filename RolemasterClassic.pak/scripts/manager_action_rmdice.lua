-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

ActionType = "rmdice";

HighRoll = 96;
LowRoll = 5;

D100 = "D100";
Closed = "D100";
OpenEnded = "Open-Ended";  				-- was OE
OpenEndedHigh = "High Open-Ended";  	-- was OEH
OpenEndedLow = "Low Open-Ended";		-- was OEL

Positive = 1;
Negative = -1;

function onInit()
	ActionsManager.registerResultHandler(ActionType, onRoll);
end

function performRoll(draginfo, rActor, sDiceType, sDesc, bSecretRoll)
	local rRoll = setupRoll("rmdice", sDiceType, 0, sDesc, bSecretRoll);

	ActionsManager.performAction(draginfo, rActor, rRoll, rOverride);
end

function performAdditionalRoll(draginfo, rActor, sDiceType, bSecretRoll, rRoll)
	local tDiceSkin = {};
	tDiceSkin.diceskin = rRoll.aDice[1].diceskin;
	tDiceSkin.dicebodycolor = rRoll.aDice[1].dicebodycolor;
	tDiceSkin.dicetextcolor = rRoll.aDice[1].dicetextcolor;

	rRoll.aDice = {};
	DiceRollManager.helperAddDice(rRoll.aDice, { "d100" }, {}, tDiceSkin);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function onRoll(rSource, rTarget, rRoll)
	rMessage, rRoll = ActionRMDice.processRoll(rSource, rTarget, rRoll);
	if rMessage then
		Comm.deliverChatMessage(rMessage);
	end
end

function setupRoll(sActionType, sDiceType, nMod, sDesc, bSecretRoll, aDice)
	-- Setup a new Roll structure
	rRoll = {};
	rRoll.sType = sActionType;
	if aDice then
		rRoll.aDice = aDice;
	else
		rRoll.aDice = { "d100" };
	end
	rRoll.sDiceType = sDiceType;
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
	rRoll.nMultiplier = Positive;
	
	return rRoll;
end

function processRoll(rSource, rTarget, rRoll)
	local rMessage = nil;

	if rRoll.aDice[1] and rRoll.aDice[1].result then
		nResult = rRoll.aDice[1].result;
	end 
	sDiceType = rRoll.sDiceType;
	nMultiplier = rRoll.nMultiplier;
	
	if not rRoll.sResults then
		rRoll.sResults = "";
	end
	rRoll.sResults = rRoll.sResults .. "#" .. (nResult * nMultiplier);
	
	if nResult >= HighRoll and (sDiceType == OpenEnded or sDiceType == OpenEndedHigh) then
		rRoll.sDiceType = OpenEndedHigh;
		performAdditionalRoll(draginfo, rSource, rRoll.sDiceType, rRoll.bSecret, rRoll);
	elseif nResult <= LowRoll and (sDiceType == OpenEnded or sDiceType == OpenEndedLow) then
		rRoll.sDiceType = OpenEndedHigh;
		rRoll.nMultiplier = Negative;
		performAdditionalRoll(draginfo, rSource, rRoll.sDiceType, rRoll.bSecret, rRoll);
	else
		rRoll.aDice = getDiceResults(rRoll.sResults);
		rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	end
	return rMessage, rRoll;
end

function getDiceResults(sResults)
	local aDiceResults = {};
	local iLocStart = string.find(sResults,"#");
	local iLocEnd = string.find(sResults, "#", iLocStart + 1);
	
	while iLocEnd do
		iResult = tonumber(string.sub(sResults, iLocStart + 1, iLocEnd - 1));
		table.insert(aDiceResults, { result = iResult, type = "d100" } );
		iLocStart = iLocEnd
		iLocEnd = string.find(sResults, "#", iLocStart + 1);
	end
	iResult = tonumber(string.sub(sResults, iLocStart + 1));
	table.insert(aDiceResults, { result = iResult, type = "d100" } );
	
	return aDiceResults;
end

function getDiceTotal(rRoll)
	local nTotal = 0;
	
	for _,v in ipairs(rRoll.aDice) do
		nTotal = nTotal + v.result;
	end
	
	return nTotal;
end

