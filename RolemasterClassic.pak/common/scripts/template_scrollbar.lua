-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local vertical = true;
local slider = nil;
local visible = true;
local enabled = true;

local range = {min=1,max=1};
local span  = 1;
local step  = 1;
local first = 1;
local mousepos = 0;
local sliderAnchor = {edge="top",offset=0,max=0};

function setVisible(flag)
	super.setVisible(flag)
	if slider and not flag then
		slider.setVisible(false);
	end
	visible = flag;
end

function setEnabled(flag)
	enabled = flag;
	refresh();
end

function onClickDown(...)
	return clickedDown(...);
end

function onWheel(notches)
	if not visible or not enabled or not slider or not slider.isVisible() then
		return;
	end
	first = first - (step * notches);
	if first<range.min then
		first = range.min;
	end
	if first+span>range.max+1 then
		first = range.max+1-span;
	end
	refresh();
	if window.scrollbarChanged then
		window.scrollbarChanged(self);
	end
	return true;
end

function onInit()
	slider = window.createControl("scrollbar_slider","");
	if slider then
		slider.registerParent(self);
		if target and target[1] then
			if horizontal then
				vertical = false;
				slider.setFrame("sliderh");
				setAnchor("left",target[1],"left","absolute",0);
				setAnchor("top",target[1],"bottom","absolute",0);
				setAnchor("right",target[1],"right","absolute",0);
				sliderAnchor.edge = "left";
			else
				setAnchor("top",target[1],"top","absolute",0);
				setAnchor("bottom",target[1],"bottom","absolute",0);
				setAnchor("left",target[1],"right","absolute",0);
				sliderAnchor.edge = "top";
			end
		end
	end
	refresh();
end

function clickedDown(button, x, y)
	local pos,low,high;
	if not visible or not enabled or not slider or not slider.isVisible() then
		return;
	end
	if vertical then
		local dummy;
		dummy,pos = getPosition();
		pos = pos + y;
		dummy,low = slider.getPosition();
		dummy,high = slider.getSize();
	else
		pos = getPosition();
		pos = pos + x;
		low = slider.getPosition();
		high = slider.getSize();
	end
	high = high + low - 1;
	if pos<low then
		first = first - span;
		if first<range.min then
			first = range.min;
		end
		refresh();
		if window.scrollbarChanged then
			window.scrollbarChanged(self);
		end
	elseif pos>high then
		first = first + span;
		if first+span>range.max+1 then
			first = range.max+1-span;
		end
		refresh();
		if window.scrollbarChanged then
			window.scrollbarChanged(self);
		end
	end
	return;
end

function sliderClicked(button,x,y)
	if not visible or not enabled then
		return;
	end
	if vertical then
		mousepos = y;
	else
		mousepos = x;
	end
	deltacells = 0;
	return;
end

local delta = 0;

function sliderDragged(button,x,y,dragdata)
	local newpos = 0;
	local deltapixels = 0;
	local start = 0;
	local r = math.abs(range.max - range.min)+1;
	local w,h = getSize();
	local d = 0;
	if not visible or not enabled then
		return;
	end
	if vertical then
		newpos = y;
		d = h;
	else
		newpos = x;
		d = w;
	end
	if d<=0 then
		-- do nothing
		return;
	end
	start = sliderAnchor.offset + newpos - mousepos;
	if start < 0 then
		start = 0;
	elseif start > sliderAnchor.max then
		start = sliderAnchor.max;
	end
	slider.setAnchor(sliderAnchor.edge,getName(),sliderAnchor.edge,"absolute",start);
	deltapixels = start - sliderAnchor.offset;
	delta = math.floor((deltapixels*r)/d+0.5);
	if window.scrollbarChanged then
		window.scrollbarChanged(self,delta);
	end
	return true;
end

function sliderDragEnded()
	if not visible or not enabled then
		return;
	end
	first = first + delta;
	delta = 0;
	refresh();
end

function isVertical()
	return vertical;
end

function getRange()
	return range.min,range.max;
end

function setRange(min,max)
	if min>=0 and max>=0 then
		range.min = min;
		range.max = max;
		refresh();
	end
end

function getSpan()
	return span;
end

function setSpan(value)
	if value>0 then
		span = value;
		refresh();
	end
end

function getStep()
	return step;
end

function setStep(value)
	if value > 0 then
		step = value;
	end
end

function getFirst()
	return first;
end

function setFirst(value)
	if value>=range.min and value<=range.max then
		first = value;
		refresh();
	end
end

function getLast()
	return (first + span) - 1;
end

function setLast(value)
	if value>=range.min and value>= first and value<=range.max then
		span = (value - first) + 1;
		refresh();
	end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Internal routines
--
--

function refresh()
	local r = math.abs(range.max - range.min)+1;
	local w,h = getSize();
	local slidersize = 0;
	local sliderstart = 0;
	local bounds = {};
	-- constrain the scrollbar width/height to 15 pixels
	if vertical then
		setAnchoredWidth(15);
		w = 15;
	else
		setAnchoredHeight(15);
		h = 15;
	end
	-- nothing else to do if we don't yet have a slider
	if not slider then
		return;
	end
	slider.bringToFront();
	-- if there is enough room to display the table, no need for a slider
	if span >= r or not visible or not enabled then
		-- slider is invisible
		slider.setVisible(false);
		return;
	else
		-- slider is visible
		slider.setVisible(true);
	end
	-- get the (fractional) size and start
	slidersize = span/r;
	sliderstart = math.abs(first - range.min)/r;
	-- set the (in pixels) size and start
	if vertical then
		bounds.y = math.floor(sliderstart * h);
		bounds.h = math.floor(slidersize * h);
		-- constrain min/max size and avoid collisions
		if bounds.h < 8 then bounds.h = 8 end;
		if bounds.h > h then bounds.h = h end;
		if bounds.y+bounds.h > h then bounds.y = h-bounds.h end;
		sliderAnchor.offset = bounds.y;
		sliderAnchor.max = h - bounds.h;
		-- fix the other dimensions
		bounds.x = 0;
		bounds.w = 15;
		slider.setAnchor("left",getName(),"left","absolute",0);
	else
		bounds.x = math.floor(sliderstart * w);
		bounds.w = math.floor(slidersize * w);
		-- constrain min/max size and avoid collisions
		if bounds.w < 8 then bounds.w = 8 end;
		if bounds.w > w then bounds.w = w end;
		if bounds.x+bounds.w > w then bounds.x = w-bounds.w end;
		sliderAnchor.offset = bounds.x;
		sliderAnchor.max = w - bounds.w;
		-- fix the other dimensions
		bounds.y = 0;
		bounds.h = 15;
		slider.setAnchor("top",getName(),"top","absolute",0);
	end
	slider.setAnchor(sliderAnchor.edge,getName(),sliderAnchor.edge,"absolute",sliderAnchor.offset);
	slider.setAnchoredHeight(bounds.h);
	slider.setAnchoredWidth(bounds.w);
end

