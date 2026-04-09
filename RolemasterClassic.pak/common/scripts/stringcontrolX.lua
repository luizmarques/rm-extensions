-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _colorReadOnly;
local _bInvalid = false;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	-- font colours
	if fontcolor and fontcolor[1] then
		if fontcolor[1].readonly and fontcolor[1].readonly[1] then
			_colorReadOnly = fontcolor[1].readonly[1];
		end
	end
	self.refreshFontColor();
end

function refreshFontColor()
	if _bInvalid then
		setColor(ColorManager.getUIColor("field_error"));
	else
		if isReadOnly() then
			setColor(_colorReadOnly);
		else
			setColor(nil);
		end
	end
end

function setInvalid()
	_bInvalid = true;
	self.refreshFontColor();
end
function setValid()
	_bInvalid = false;
	self.refreshFontColor();
end

function setReadOnlyRMC(state)
	if super and super.setReadOnly then
		super.setReadOnly(state);
	end
	self.refreshFontColor();
end

function onWheel(...)
	if parent and parent.onWheel then
		return parent.onWheel(...);
	else
		return false;
	end
end
