-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local modifierWidget = nil;
local modifierFieldNode = nil;

function getModifier()
	if not modifierFieldNode then
		return 0;
	end
	
	return modifierFieldNode.getValue();
end

function setModifier(value)
	if modifierFieldNode then
		modifierFieldNode.setValue(value);
	end
end

function setModifierDisplay(value)
	if value > 0 then
		modifierWidget.setText("+" .. value);
	else
		modifierWidget.setText(value);
	end
	
	if value == 0 then
		modifierWidget.setVisible(false);
	else
		modifierWidget.setVisible(true);
	end
end

function updateModifier(source)
	if modifierFieldNode then
		setModifierDisplay(modifierFieldNode.getValue());
	end
end

function onInit()
	local widgetsize = "small";
	if modifiersize then
		widgetsize = modifiersize[1];
	end
	
	if widgetsize == "mini" then
		modifierWidget = addTextWidget("sheetlabelmini", "0");
		modifierWidget.setFrame("tempmodmini", 3, 1, 6, 3);
		modifierWidget.setPosition("topright", 3, 1);
		modifierWidget.setVisible(false);
	else
		modifierWidget = addTextWidget("sheettext", "0");
		modifierWidget.setFrame("tempmodsmall", 6, 3, 8, 5);
		modifierWidget.setPosition("topright", 0, 0);
		modifierWidget.setVisible(false);
	end
	
	-- By default, the modifier is in a field named based on the parent control.
	local modifierFieldName = getName() .. "modifier";
	if modifierfield then
		-- Use a <modifierfield> override
		modifierFieldName = modifierfield[1];
	end
	
	modifierFieldNode = DB.createChild(window.getDatabaseNode(), modifierFieldName, "number");
	if modifierFieldNode then
		DB.addHandler(DB.getPath(modifierFieldNode), "onUpdate", self.updateModifier);
		addSourceWithOp(modifierFieldName, "+");

		updateModifier(modifierFieldNode);
	end
	
	super.onInit();
end

