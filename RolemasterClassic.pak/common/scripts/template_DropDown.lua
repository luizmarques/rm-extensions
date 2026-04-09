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

local targetcontrol = "";
local sourcenode = nil;
local activeflag = false;
local itemlist = {};

local selecteditem = nil;
local fieldname = nil;

local myname = "";
local mylist = nil;
local scrollbar = nil;

function onInit()
	local posn = position[1];
	local i = string.find(posn,",");
	local targetname = "";
	if lookupFieldName and lookupFieldName[1]~="" then
		fieldname = lookupFieldName[1];
	end
	myname = getName();
	if not myname or myname=="" then
		-- a drop-down needs a name, so stop further processing
		setVisible(false);
		return;
	end
	-- get the target control (must inherit from stringcontrol)
	if target and target[1] then
		targetname = target[1];
		targetcontrol = window[targetname];
	end
	-- find the list source
	if datasource and datasource[1] and window.getDatabaseNode() then
		-- this control is bound to a list in the database
		sourcenode = DB.getChild(window.getDatabaseNode(), datasource[1]);
	elseif lookup and type(lookup[1])=="string" then
		-- this control is loaded from one or more lookups
		for n=1,#lookup do
			local name = lookup[n];
			local list = Global.Lookups[name];
			if list then
				-- add each item from the lookup to the list
				for key,value in pairs(list) do
					if fieldname then
						-- If a lookup field name is present, use it to index the lookup entry
						add(value[fieldname]);
					else							
						-- If there is no fieldname, either use the key (if it is a string) or the value itself
						if not key then
							add(value);
						else
							add(key,value);
						end
					end			
				end			
			end
		end
	else
	-- do nothing, the control can be loaded dynamically from the window script
	end
	-- position the control over the target
	if i and targetcontrol then
	local x = tonumber(string.sub(posn,1,i-1)) or 0;
	local y = tonumber(string.sub(posn,i+1)) or 0;
	setAnchor("right",targetname,"right","absolute",x);
	setAnchor("top",targetname,"top","absolute",y);
	else
	-- no target, or position string is invalid
	setVisible(false);
	end
end

function onClickDown(button, x, y)
	if activeflag then
		--[[ list already visible, hide it ]]
		activeflag = false;
		hideList();
		refresh(true);
	else
		if button == 1 then
			--[[ show the drop-down list ]]
			activeflag = true;
			showList();
			refresh(true);
		elseif button == 2 then
			--[[ reset the target value ]]
			targetcontrol.setValue("");
		end
	end
end

function onHover(oncontrol)
	refresh(oncontrol);
end

function showList()
	if not mylist then
		local w,h = targetcontrol.getSize();
		-- create the list control
		mylist = window.createControl("DropDownList",myname.."_list");
		-- anchor it
		mylist.setAnchor("right",myname,"right","absolute",0);
		mylist.setAnchor("top",myname,"bottom","absolute",3);
		mylist.setAnchoredWidth(w);
		-- set the fonts and frames used for normal/selected items
		mylist.setFonts(fonts[1].normal[1],fonts[1].selected[1]);
		mylist.setFrames(frames[1].normal[1],frames[1].selected[1]);
		-- populate the list
		if sourcenode then
			mylist.setDatabaseNode(sourcenode);
		else
			for value,text in pairs(itemlist) do
				mylist.add(value,text);
			end
			itemlist = {};
		end
		-- set the number of rows displayed
		mylist.setRows(tonumber(size[1]) or 0);
		-- create a scrollbar for the list
		scrollbar = window.createControl("DropDown_Scrollbar","");
		scrollbar.setAnchor("left", myname.."_list", "right", "absolute", -10);
		scrollbar.setAnchor("top", myname.."_list", "top");
		scrollbar.setAnchor("bottom", myname.."_list", "bottom");
		scrollbar.setTarget(myname.."_list");
	end
	if mylist then
		local tempval, sTableName = targetcontrol.getValue();
		if sTableName then
			tempval = sTableName;
		end
		mylist.setVisible(true);
		setValue(tempval);
		mylist.applySort();
		mylist.scrollToItem(tempval);
		targetcontrol.setValue(tempval);
	end
end

function hideList()
	if mylist then
		mylist.setVisible(false);
	end
end

function refresh(active)
	if activeflag or active then
		setIcon("indicator_dropdown_active");
	else
		setIcon("indicator_dropdown");
	end
end

function setValue(value)
	if mylist then
		local opt = nil;
		for i,win in ipairs(mylist.getWindows()) do
			if win.Value.getValue()==value then
				opt = win;
			end
		end
		selectitem(opt);
	end
end

function getValue()
	if selecteditem then
		return selecteditem.Value.getValue();
	else
		return "";
	end
end

function getText()
	if selecteditem then
		return selecteditem.Text.getValue();
	else
		return "";
	end
end

function add(value, text)
	if type(value)=="table" then
		text  = value.Text;
		value = value.Value;
	end
	if type(value)~="string" then value = text end;
	if type(text)~="string" then text = value end;
	if type(value)=="string" and type(text)=="string" then
		if mylist then
			mylist.add(value,text);
		else
			itemlist[value] = text;
		end
	end
end

function addItems(list)
	for i,opt in ipairs(list) do
		add(opt);
	end
end

function clear()
	if mylist then
		mylist.clear();
	end
	itemlist = {};
end

function optionClicked(opt)
	if opt and opt.setSelected then
		selectitem(opt);
	end
	activeflag = false;
	hideList();
	refresh();
end

function selectitem(opt)
	if not mylist then
		return;
	end
	if selecteditem==opt then
		return;
	end
	if selecteditem then
		selecteditem.setSelected(false);
	end
	if opt then
		opt.setSelected(true);
	end
	selecteditem = opt;
	if targetcontrol.getValue()~=getValue() then
		targetcontrol.setValue(getValue());
	end
end

