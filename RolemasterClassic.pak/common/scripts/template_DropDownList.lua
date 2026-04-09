-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- This file is provided under the Open Game License version 1.0a
-- For more information on OGL and related issues, see 
--   http://www.wizards.com/d20

-- See the license.html file included with this distribution for
-- conditions of use.

-- All producers of work derived from this definition are adviced to
-- familiarize themselves with the above licenses, and to take special
-- care in providing the definition of Product Identity (as specified
-- by the OGL) in their products.

local fontvalue = "";
local selectedfont = "";
local framevalue = "";
local selectedframe = "";
local rowheight = 20;
local parentcontrol = nil;
local rowsvalue = 0;

function onInit()
	local myname = getName();
	if myname and myname~="" then
		parentcontrol = window[string.sub(myname,1,#myname-5)];
	end
end

function optionClicked(opt)
	if parentcontrol and parentcontrol.optionClicked then
		parentcontrol.optionClicked(opt);
	end
end

function setRows(num)
	if num==0 then
		num = #(getWindows());
	end
	if num > 20 then
		num = 20;
	end
	rowsvalue = num;
	setAnchoredHeight(num*rowheight);
end

function setFonts(normal,sel)
	if type(normal)=="boolean" then normal = "" end;
	if type(sel)=="boolean" then sel = "" end;
	fontvalue = normal or "";
	selectedfont = sel or "";
	for i,opt in ipairs(getWindows()) do
		opt.setFonts(fontvalue,selectedfont);
	end
end

function setFrames(normal,sel)
	if type(normal)=="boolean" then normal = "" end;
	if type(sel)=="boolean" then sel = "" end;
	framevalue = normal or "";
	selectedframe = sel or "";
	for i,opt in ipairs(getWindows()) do
		opt.setFrames(framevalue,selectedframe);
	end
end

function add(value, text)
	if type(value)=="string" and type(text)=="string" then
		local opt = createWindow();
		opt.Text.setValue(text);
		opt.Value.setValue(value);
		opt.setFonts(fontvalue,selectedfont);
		opt.setFrames(framevalue,selectedframe);
	end
end

function clear()
	closeAll();
end

function scrollToItem(value)
	local row=0;
	local sx,px,vx,sy,py,vy;
	local p;
	for i,opt in ipairs(getWindows()) do
		if opt.Value.getValue()==value then
			row = i;
		end
	end
	if row==0 then
		return;
	end
	row = row - 1;
	sx,px,vx,sy,py,vy = getScrollState();
	p = math.ceil(py/rowheight);
	if row<p then
		--[[ scroll so row is at the top ]]
		p = row;
	elseif row>=(p+rowsvalue) then
		--[[ scroll so row is at the bottom ]]
		p = (row - rowsvalue) + 1;
		if p<0 then p=0 end;
	else
		--[[ nothing to do ]]
		return;
	end
	setScrollPosition(0,p*rowheight);
end

function onSortCompare(opt1,opt2)
	return opt1.Value.getValue()>opt2.Value.getValue();
end

function getHeight()
	return rowsvalue * rowheight;
end

