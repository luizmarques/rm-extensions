-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local dieType;

function onInit()
	if super and super.onInit then
		super.onInit();
	end

	-- create the overlay widgets
	textLabel = addTextWidget("sheetlabel", "");
	textLabel.setPosition("center",0,0);
	textLabel.setFont("rmdicelabel_white");
	
	if dietype and dietype[1] then
		-- default the dice settings from the xml definition, if present
		setDieType(dietype[1]);
	else
		-- otherwise, default to 'closed-ended'
		setDieType(ActionRMDice.Closed);
	end
end

function setDieType(theType)
	local sLabel = "D100";
	dieType = theType;
	
	-- change the label text accordingly
	if dieType == ActionRMDice.OpenEnded then
		sLabel = "Open";
	elseif dieType == ActionRMDice.OpenEndedHigh then
		sLabel = "High";
	elseif dieType == ActionRMDice.OpenEndedLow then
		sLabel = "Low";
	end
	
	textLabel.setText(sLabel);
end

function action(draginfo)
	local rActor = nil;
	ActionRMDice.performRoll(draginfo, rActor, dieType, dieType);

	return true;
end

function onDragStart(button, x, y, draginfo)
	return action(draginfo);
end
	
function onDoubleClick(x,y)
	return action();
end
