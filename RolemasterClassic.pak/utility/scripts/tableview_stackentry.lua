-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Die Stack entries

local portraitwidget = nil;
local resolver = nil;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	
	-- store a reference to the attack grid
	if windowlist and windowlist.window then
		resolver = windowlist.window;
	end
	if resolver then
		registerMenuItem("Resolve", "resolve", 3); 
	end

	-- track changes to the customData
	DB.addHandler(DB.getPath(getDatabaseNode(), "customData"), "onChildUpdate", self.redraw);
	self.redraw();
end

function redraw()
	local customData;
	local actorNodeName = "";
	local actorName;
	local actionTitle;
	-- get the custom data
	customData = StackManager.decode(getDatabaseNode());
	-- get the protagonist's charsheet node
	if customData.actorNodeName then
		actorNodeName = customData.actorNodeName;
	end
	-- what type of roll is it?
	if customData.tableType==Rules_Constants.TableType.Attack or customData.tableType==Rules_Constants.TableType.Result then
		actorName = customData.attackerName;
		if string.len(customData.defenderName) > 0 then
			actionTitle = customData.name .. " vs " .. customData.defenderName;
		elseif string.find(customData.name, "[TOWER]", 1, true) then
			actionTitle = customData.name .. "";
		else
			actionTitle = customData.name .. " vs <NO TARGET SELECTED>";
		end
	elseif customData.tableType==Rules_Constants.TableType.Other then
		actorName = customData.actorName;
		actionTitle = customData.name;
	else
		actorName = "(Unknown)";
		actionTitle = "Unexpected action type: " .. customData.tableType;
	end
	name.setValue(actorName);
	name.setTooltipText(actorName);
	result.setValue(customData.dieResult);
	title.setValue(actionTitle);
	title.setTooltipText(actionTitle);
	if customData.defenderName and string.len(customData.defenderName) > 0 then
		target.setValue("vs " .. customData.defenderName);
		target.setTooltipText("vs " .. customData.defenderName);
	end
	-- done
end

function onMenuSelection(level1)
	if level1 == 3 then
		resolve();
	end
end

function resolve()
	-- Resolve stacked roll
	local customData = StackManager.decode(getDatabaseNode());

	if resolver and (customData.tableType==Rules_Constants.TableType.Attack or customData.tableType==Rules_Constants.TableType.Result or customData.tableType==Rules_Constants.TableType.Other) then 
		customData.title = name.getValue()..": "..title.getValue();
		Rules_Combat.SetAddCrits(customData);
		Rules_Combat.SetAltCrit(customData);
		Rules_Combat.SetLevels(customData);
		Rules_Combat.SetUnmodifiedRoll(customData);
		Rules_Combat.SetFumble(customData.fumbleValue);
		Rules_Combat.SetFumbleTableInfo(customData);
		resolver.resolve(customData,self);
	end
end
