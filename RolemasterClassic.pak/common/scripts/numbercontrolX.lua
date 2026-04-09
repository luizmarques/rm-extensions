-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local _colorReadOnly;
local _colorScrollerActive;
local _bInvalid = false;

function onInit()
	if super and super.onInit then
		super.onInit();
	end
	if fontcolor and fontcolor[1] then
		if fontcolor[1].readonly and fontcolor[1].readonly[1] then
			_colorReadOnly = fontcolor[1].readonly[1];
		end
		if fontcolor[1].mousescroll and fontcolor[1].mousescroll[1] then
			_colorScrollerActive = fontcolor[1].mousescroll[1];
		end
	end
	self.refreshFontColor();
end

function setEnabled(state)
	if super and super.setEnabled then
		super.setEnabled(state);
	end
	self.refreshFontColor();
	return true;
end
function setReadOnlyRMC(state)
	if super and super.setReadOnly then
		super.setReadOnly(state);
	end
	self.refreshFontColor();
	return true;
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

-- override the default behaviour of mouse scroller - only allow scrolling when CTRL is being held down
function onWheel(...)
	if not isReadOnly() and not Input.isControlPressed() then
		if parent and parent.onWheel then
			return parent.onWheel(...);
		else
			return false;
		end
	end
end

function onHover(bState)
	if bState and not isReadOnly() then
		Input.onControl = controlPressed;
	else
		Input.onControl = function() end;
	end
	if bState and not isReadOnly() and Input.isControlPressed() then
		setColor(_colorScrollerActive);
	else
		self.refreshFontColor();
	end
end

function controlPressed(bPressed)
	if not isReadOnly() then
		if bPressed then
			setColor(_colorScrollerActive);
		else
			self.refreshFontColor();
		end
	end
end
