-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- tableview_window
--
--

local datasource = nil;
local tabledata = nil;
local cells = {width=0,height=0,column={}};
local columnIds = {};
local rowIds = {};
local origin = {dX=0,dY=0};
local windowsize = {width=0,height=0,columns=0,rows=0};
local activeValue = true;
local refreshing = false;
local selection = {unmodified="", roll="", columnId=""};
local resizepending = true;
local selectpending = false;
local customData = {};

local parent = nil;

function onInit()
	if notitle and notitle[1] then
		setTitlebarVisible(false);
	else
		setTitlebarVisible(true);
	end
	self.onLayoutSizeChanged();
end

function onWheel(notches)
	local delta = origin.dY - notches;
	if tabledata then
		local size = tabledata.Rows.Count;
		local span = windowsize.rows - 1;
		if span+delta > size then
			delta = size - span;
		end
	end
	if delta < 0 then
		delta = 0;
	end
	origin.dY = delta;
	if not refreshing then
		refreshing = true;
		refreshContent();
		refreshScrollbars();
		refreshing = false;
	end
end

function setResizePending()
	resizepending = true;
end

function clear()
	datasource = nil;
	tabledata = nil;
	columnIds = {};
	rowIds = {};
	origin = {dX=0,dY=0};
	windowsize.columns=0;
	windowsize.rows=0;
	clearSelection();
	titlebar.setValue("(No Table Selected)");
	if notitle and notitle[1] then
		setTitlebarVisible(false);
	else
		setTitlebarVisible(true);
	end
	for i=1,cells.width do
		for j=1,cells.height do
			if cells.column[i] and cells.column[i].row[j] then
				local cell = cells.column[i].row[j];
				cell.clearEntry();
				cell.clearSelector();
				cell.setVisible(false);
			end
		end
	end
end

function clearSelection()
	selection = {unmodified="", roll="", columnId=""};
	selectpending = false;
end

function showSelection()
	if tabledata then
		if resizepending then
			selectpending = true;
		end
		showSelectedRow();
		showSelectedColumn();
	end
end

function selectRow(unmodified,roll)
	if not unmodified then
		selection.unmodified = "";
	else
		selection.unmodified = unmodified.."";
	end
	if not roll then
		selection.roll = "";
	else
		selection.roll = roll.."";
	end
	refresh();
end

function selectColumn(title)
	selection.columnId = "";
	if not title then
		title = "";
	else
		title = title.."";
	end
	if tabledata then
		for k,v in pairs(tabledata.Columns) do
			if type(v)=="table" and v.Title then
				if title==v.Title then
					selection.columnId = k;
					break;
				end
			end
		end
	end
	refresh();
	return;
end

local oldX = -1;
local oldY = -1;
local oldW = -1;
local oldH = -1;

function onLayoutSizeChanged()
	local x,y;
	local w,h,dummy;
	-- control size
	x,y = getSize();
	-- scrollbar sizes
	w,dummy = hbar.getSize();
	dummy,h = vbar.getSize();
	-- only action if something has changed
	if x==oldX and y==oldY and h==oldH and w==oldW then
		return;
	end
	oldX = x;
	oldY = y;
	oldW = w;
	oldH = h;
	refresh(x,y);
	if resizepending then
		resizepending = false;
		if selectpending then
			selectpending = false;
			showSelection();
		end
	end
end

function setTitlebarVisible(flag)
	titlebar.setVisible(flag);
	refresh();
end

function scrollbarChanged(source,delta)
	local first = source.getFirst();
	if delta then
		first = first + delta;
	end
	if source.isVertical() then
		setFirstRow(first);
	else
		setFirstColumn(first);
	end
end
      
function registerParent(source)
	parent = source;
end

function criticalSelected(...)
	if parent and parent.criticalSelected then
		parent.criticalSelected(...);
	end
end

function setFirstColumn(val)
	if tabledata then
		local size = tabledata.Columns.Count;
		local span = windowsize.columns - 1;
		if (val+span-1) > size then
			val = size - (span - 1);
		end
	end
	if val < 1 then
		val = 1;
	end
	origin.dX = val - 1;
	if not refreshing then
		refreshing = true;
		refreshContent();
		refreshing = false;
	end
end

function setFirstRow(val)
	if tabledata then
		local size = tabledata.Rows.Count;
		local span = windowsize.rows - 1;
		if (val+span-1) > size then
			val = size - (span - 1);
		end
	end
	if val < 1 then
		val = 1;
	end
	origin.dY = val - 1;
	if not refreshing then
		refreshing = true;
		refreshContent();
		refreshing = false;
	end
end

function setActive(flag)
	activeValue = flag;
	refresh();
end

function isActive()
	return activeValue;
end

function bind(tablenode, nFumble)
	-- reset the window
	clear();
	if tablenode then
		local i = 0;
		columnIds = {};
		datasource = tablenode;
		tabledata = RMTableManager.getTableData(tablenode, nFumble);
		if tabledata then
			local titletext = "";
			for k,col in pairs(tabledata.Columns) do
				if k~="Count" then
					i = i + 1;
					columnIds[i] = col.Id;
				end
			end
			table.sort(columnIds);
			-- set the title bar text
			if tabledata.Id == Rules_Constants.RRTableID then
				titletext = string.upper(tabledata.Name .. " [Attacker=Top, Target=Left] (" .. tabledata.Id .. ")");
			else
				titletext = string.upper(tabledata.Name .. " (" .. tabledata.Id .. ")");
			end
			titlebar.setValue(titletext);
			-- redraw the table
			if customdata then
				refresh(customdata);
			else
				refresh();
			end
		end
	end
end

function refresh(x,y)
	if not refreshing then
		--[[ check for blank space ]]
		if tabledata then
			local span, tail, blank;
			span = windowsize.rows - 1;
			tail = tabledata.Rows.Count - origin.dY;
			blank = span - tail;
			if blank > 0 then
				origin.dY = origin.dY - blank;
				if origin.dY < 0 then origin.dY = 0 end;
			end
			span = windowsize.columns - 1;
			tail = tabledata.Columns.Count - origin.dX;
			blank = span - tail;
			if blank > 0 then
				origin.dX = origin.dX - blank;
				if origin.dX < 0 then origin.dX = 0 end;
			end
		end
		--[[ redraw the table ]]
		refreshing = true;
		if x and y then
			-- set display area size (excludes scroll bar width, but includes titlebar height)
			windowsize.width  = x - 15;
			windowsize.height = y - 15;
		end
		refreshCells();
		refreshContent();
		refreshScrollbars();
		refreshApplyButton();
		refreshing = false;
	end;
end

function getSelectedTableCell()
	local nRoll = selection.roll + 0;
	local nUnmodified = selection.unmodified + 0;
	local aTableCell = {};
	local aFumble = nil;

	if not tabledata.MaxRoll then
		if nRoll > 100 then
			nRoll = 100;
		end
	elseif nRoll > tabledata.MaxRoll then
		nRoll = tabledata.MaxRoll;
	end

	if tabledata.Unmodified  then
		for i = 1, #(tabledata.Unmodified) do
			if tabledata.Unmodified[i] and tabledata.Unmodified[i].LowerRoll and tabledata.Unmodified[i].HigherRoll then 
				if tabledata.Unmodified[i].LowerRoll <= nUnmodified and tabledata.Unmodified[i].HigherRoll >= nUnmodified then
					nRoll = nUnmodified;
					if tabledata.Fumble.LowerRoll <= nUnmodified and tabledata.Fumble.HigherRoll >= nUnmodified then
						aFumble = {};
						aFumble.Code = "";
						aFumble.Name = "Fumble";
						aFumble.Table = "";
						aFumble.Severity = "";
					end
				elseif ((nRoll >= tabledata.Unmodified[i].LowerRoll and nRoll <= tabledata.Unmodified[i].HigherRoll) or (nRoll > tabledata.Rows.Limits.HighRoll and tabledata.Rows.Limits.HighRoll == tabledata.Unmodified[i].HigherRoll)) and (nRoll > 50) then
					nRoll = tabledata.Unmodified[i].LowerRoll - 1;
				elseif ((nRoll >= tabledata.Unmodified[i].LowerRoll and nRoll <= tabledata.Unmodified[i].HigherRoll) or (nRoll < tabledata.Rows.Limits.LowRoll and tabledata.Rows.Limits.LowRoll == tabledata.Unmodified[i].LowerRoll)) and (nRoll < 50) then
					nRoll = tabledata.Unmodified[i].HigherRoll + 1;
				end
			end
		end
	end

	for i=1, tabledata.Rows.Count do
		local aRow = tabledata.Rows[i];
		if aRow.LowerRoll <= nRoll and aRow.HigherRoll >= nRoll and not aRow.DegreeName then
			for j=1, aRow.Entries.Count do
				local sEntry = j .. "";
				if j < 10 then
					sEntry = "0" .. sEntry;
				end
				if aRow.Entries[sEntry] and selection and aRow.Entries[sEntry].ColumnId == selection.columnId then
					aTableCell = aRow.Entries[sEntry];
				end
			end
		end
	end

	return aTableCell, aFumble;
end

function getTableClass()
	return tabledata.Class;
end

function getTableId()
	return tabledata.Id;
end

function getTableName()
	return tabledata.Name;
end

function getSelectionColumnId()
	return selection.ColumnId;
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Internal routines
--
--

function refreshApplyButton()
	if selection.roll == "" or selection.columnId == "" then
		button_applyresult.setVisible(false);
	else
		button_applyresult.setVisible(true);
	end
end

function refreshCells()
	local maxW = 0;
	local maxH = 0;
	local winW,winH;
	local t = 0;
	local row,column,firstRow,firstColumn = RMTableManager.getCellSizes(datasource);
	-- allow for the titlebar, if visible
	if titlebar.isVisible() then
		local dummy;
		dummy,t = titlebar.getSize();
	else
		t = 0;
	end
	winW = windowsize.width;
	winH = windowsize.height - t;
	-- check for silly values 
	if not row or not column or not tabledata then
		return;
	end
	-- width of display area in cells 
	winW = winW - firstColumn;
	if winW>=0 then
		maxW = math.floor(winW/column);
	end
	if maxW > tabledata.Columns.Count then
		maxW = tabledata.Columns.Count + 1;
	else
		maxW = maxW + 1;
	end
	windowsize.columns = maxW;
	-- height of display area in cells 
	winH = winH - firstRow;
	if winH>=0 then
		maxH = math.floor(winH/row);
	end
	if maxH > tabledata.Rows.Count then
		maxH = tabledata.Rows.Count + 1;
	else
		maxH = maxH + 1;
	end
	windowsize.rows = maxH;
	-- ensure we have enough cells to fill the display 
	for i=1,maxW do
		local x,w;
		-- ensure we have a row array in this column
		if not cells.column[i] then
			cells.column[i]={row={}};
		end
		-- width and x-position
		if i > 1 then
			x = (i-2)*column+firstColumn;
			w = column;
		else
			x = 0;
			w = firstColumn;
		end
		-- each row
		for j=1,maxH do
			local y,h;
			local cell = cells.column[i].row[j];
			-- ensure we have a cell, if it doesn't already exist
			if not cell then
				cell = createControl("tableview_cell","");
				cells.column[i].row[j] = cell;
			end
			-- height and y-position
			if j > 1 then
				y = (j-2)*row+firstRow;
				h = row;
			else
				y = 0;
				h = firstRow;
			end
			-- set the position/size
			cell.setAnchor("left","","left","absolute",x);
			cell.setAnchor("top","","top","absolute",y+t);
			cell.setAnchoredWidth(w);
			cell.setAnchoredHeight(h);
			cell.sendToBack();
		end
	end
	if cells.width < maxW then cells.width = maxW end;
	if cells.height < maxH then cells.height = maxH end;
	-- control cell visibility
	for i=1,cells.width do
		local x = origin.dX + i - 1;
		for j=1,cells.height do
			local y = origin.dY + j - 1;
			local cell = cells.column[i].row[j];
			if cell then
				if x>tabledata.Columns.Count then
					cell.setVisible(false);
				elseif y>tabledata.Rows.Count then
					cell.setVisible(false);
				elseif i>maxW then
					cell.setVisible(false);
				elseif j>maxH then
					cell.setVisible(false);
				else
					cell.setVisible(true);
				end
			end
		end
	end
end

function refreshContent()
	local rowHeight,columnWidth,firstRow,firstColumn = RMTableManager.getCellSizes(datasource);
	if not tabledata then
		return;
	end
	--[[ top left corner ]]
	if cells.column[1] and cells.column[1].row[1] then
		cells.column[1].row[1].clearEntry();
	end
	--[[ set the column headings ]]
	for i=2,cells.width do
		local x = origin.dX + i - 1;
		local heading = "";
		local selected = false;
		if x <= tabledata.Columns.Count then
			local id = columnIds[x];
			heading = tabledata.Columns[id].Title;
			if selection.columnId==id then
				selected = true;
			end
		end
		if cells.column[i] and cells.column[i].row[1] then
			local cell = cells.column[i].row[1];
			cell.setFont("tablecell_header");
			cell.setText(heading);
			if selected then
				cell.setFrame("Hilight20",0,0,0,0);
			else
				cell.setFrame("rowshade",0,0,-1,-1);
			end
			if activeValue then
				cell.setSelector(cellColumnClicked,heading);
			else
				cell.clearSelector();
			end
		end
	end
	--[[ set the row headings ]]
	for j=2,cells.height do
		local y = origin.dY + j - 1;
		local row;
		local heading = "";
		local selected = false;
		if y <= tabledata.Rows.Count then
			y = chartRowNum(y);
			row = tabledata.Rows[y];
			local sLocation = "";
			if row.Location then
				sLocation = " " .. row.Location;
			end
			if row.DegreeName then
				heading = "Maximum Results for " .. row.DegreeName .." Attacks";
			elseif row.HigherRoll==row.LowerRoll then
				heading = row.LowerRoll .. sLocation;
			else
				heading = row.Roll .. sLocation;
			end
			if isSelectedRow(row) then
				selected = true;
			end
		end
	
		-- Add UM for Unmodified Rolls
		if tabledata.Unmodified and row then
			for i = 1, #(tabledata.Unmodified) do
				if row and row.LowerRoll and row.HigherRoll and tabledata.Unmodified[i] and tabledata.Unmodified[i].LowerRoll and tabledata.Unmodified[i].HigherRoll then
					if row.LowerRoll >= tabledata.Unmodified[i].LowerRoll and row.HigherRoll <= tabledata.Unmodified[i].HigherRoll then
						heading = heading .. " UM";
					end
				end
			end
		end

		if cells.column[1] and cells.column[1].row[j] then
			local cell = cells.column[1].row[j];
			cell.setFont("tablecell_header");
			cell.setText(heading);
			if row and row.DegreeName then
				cell.setAnchoredWidth(windowsize.width);
				cell.setFrame("rowshade",0,0,-1,-1);
			else
				cell.setAnchoredWidth(firstColumn);
				if selected then
					cell.setFrame("Hilight20",0,0,0,0);
				else
					cell.setFrame("rowshade",0,0,-1,-1);
				end
				if row and activeValue then
					local sampleroll = math.floor((row.HigherRoll+row.LowerRoll)/2);
					cell.setSelector(cellRowClicked,sampleroll.."");
				else
					cell.clearSelector();
				end
			end
		end
	end

	--[[ set the cell contents ]]
	for j=2,cells.height do
		local y = origin.dY + j - 1;
		local thisrow;
		if y <= tabledata.Rows.Count then
			local rowselected = false;
			local fumble = nil;
			y = chartRowNum(y);
			thisrow = tabledata.Rows[y];
			if isSelectedRow(thisrow) then
				rowselected = true;
			end
			local nWeaponFumble = Rules_Combat.GetFumble();
			if nWeaponFumble and nWeaponFumble > 0 and thisrow.HigherRoll <= nWeaponFumble then
				fumble = {Text="F",Fumble=true};
			elseif tabledata.Fumble and thisrow.LowerRoll>=tabledata.Fumble.LowerRoll and thisrow.HigherRoll<=tabledata.Fumble.HigherRoll then
				fumble = {Text="F",Fumble=true};
			end
			for i=2,cells.width do
				local x = origin.dX + i - 1;
				local content = nil;
				local selected = rowselected;
				if x <= tabledata.Columns.Count then
					local id = columnIds[x];
					if selection.columnId==id then
						selected = true;
					end
					if thisrow.DegreeName then
						content = {Text=""};
						selected = false;
					elseif fumble then
						content = fumble;
					elseif thisrow.Entries[id] then
						content = thisrow.Entries[id];
					end

					if content then
						if content.Effects then
							for i, fx in ipairs(content.Effects) do
								if fx.Text then
									if fx.Text == "F" then
										content = {Text="F",Fumble=true};
									end
								end
							end
						end
					end

				end
				if cells.column[i] and cells.column[i].row[j] then
					local cell = cells.column[i].row[j];
					cell.setEntry(content,activeValue);
					if thisrow.DegreeName then
						cell.setFrame(nil);
					elseif selected then
						cell.setFrame("Hilight20",0,0,0,0);
					else
						cell.setFrame("rowshade",0,0,-1,-1);
					end
					cell.clearSelector();
				end
			end
		end
	end
end

function refreshScrollbars()
	if tabledata then
		local firstRow = origin.dY + 1;
		local firstColumn = origin.dX + 1;
		local spanRows = windowsize.rows - 1;
		local spanColumns = windowsize.columns - 1;
		local maxColumn = tabledata.Columns.Count;
		local maxRow = tabledata.Rows.Count;
		if spanRows<1 then
			spanRows = 1;
		end
		if spanColumns<1 then
			spanColumns = 1;
		end
		hbar.setRange(1,maxColumn);
		hbar.setSpan(spanColumns);
		hbar.setFirst(firstColumn);
		hbar.setEnabled(true);
		vbar.setRange(1,maxRow);
		vbar.setSpan(spanRows);
		vbar.setFirst(firstRow);
		vbar.setEnabled(true);
	else
		hbar.setEnabled(false);
		vbar.setEnabled(false);
	end
end

function isSelectedRow(row)
	local roll;
	local unmodified;
	if selection.roll=="" or selection.unmodified=="" then
		return false;
	end
	if row.DegreeName then
		return false;
	end
	roll = selection.roll + 0;
	unmodified = selection.unmodified + 0;
	if Rules_Combat.nUnmodifiedRoll ~= -1 then
		unmodified = Rules_Combat.nUnmodifiedRoll;
	end
	if tabledata.Fumble then
		if unmodified>=tabledata.Fumble.LowerRoll and unmodified<=tabledata.Fumble.HigherRoll then
			-- use unmodified roll
			roll = unmodified;
		end
	end
	if tabledata.Unmodified and roll ~= unmodified then
		for i = 1, #(tabledata.Unmodified) do
			if roll and tabledata.Unmodified[i] and tabledata.Unmodified[i].LowerRoll and tabledata.Unmodified[i].HigherRoll and tabledata.Rows and tabledata.Rows.Limits and tabledata.Rows.Limits.HighRoll and tabledata.Rows.Limits.LowRoll then
				if ((roll >= tabledata.Unmodified[i].LowerRoll and roll <= tabledata.Unmodified[i].HigherRoll) or (roll > tabledata.Rows.Limits.HighRoll and tabledata.Rows.Limits.HighRoll == tabledata.Unmodified[i].HigherRoll)) and (roll > 50) then
					roll = tabledata.Unmodified[i].LowerRoll - 1;
				elseif ((roll >= tabledata.Unmodified[i].LowerRoll and roll <= tabledata.Unmodified[i].HigherRoll) or (roll < tabledata.Rows.Limits.LowRoll and tabledata.Rows.Limits.LowRoll == tabledata.Unmodified[i].LowerRoll)) and (roll < 50) then
					roll = tabledata.Unmodified[i].HigherRoll + 1;
				end

				if unmodified>=tabledata.Unmodified[i].LowerRoll and unmodified<=tabledata.Unmodified[i].HigherRoll then
					-- use unmodified roll
					roll = unmodified;
				end
			end
		end
	end
	if roll>=row.LowerRoll and roll<=row.HigherRoll then
		return true;
	elseif roll > tabledata.Rows.Limits.HighRoll and row==tabledata.Rows.Limits.HighRow then
		return true;
	elseif roll < tabledata.Rows.Limits.LowRoll and row==tabledata.Rows.Limits.LowRow then
		return true;
	end
	return false;
end

function showSelectedRow()
	local rownum = 0;
	local delta;
	local windowspan = windowsize.rows - 1;
	if not tabledata or selection.roll=="" or selection.unmodified=="" then
		return;
	end
	for i=1,tabledata.Rows.Count do
		local y = chartRowNum(i);
		local row = tabledata.Rows[y];
		if isSelectedRow(row) then
			rownum = i;
			break;
		end
	end
	if rownum<1 then
		return;
	end
	delta = rownum - (origin.dY+1);
	if delta>=0 and delta<windowspan then
		-- already visible
		return;
	end
	if windowspan>0 then
		delta = rownum - math.floor((windowspan - 1)/2);
	else
		delta = rownum;
	end
	if delta < 1 then
		delta = 1;
	elseif delta + windowspan - 1 > tabledata.Rows.Count then
		delta = tabledata.Rows.Count + 1 - windowspan;
	end
	setFirstRow(delta);
	if not refreshing then
		refreshing = true;
		refreshScrollbars();
		refreshing = false;
	end
end

function showSelectedColumn()
	local colnum = 0;
	local delta;
	local windowspan = windowsize.columns - 1;
	if not tabledata or selection.columnId=="" then
		return;
	end
	for x=1,tabledata.Columns.Count do
		local id = columnIds[x];
		local col = tabledata.Columns[id];
		if selection.columnId==id then
			colnum = x;
			break;
		end
	end
	if colnum<1 then
		return;
	end
	delta = colnum - (origin.dX+1);
	if delta>=0 and delta<windowspan then
		-- already visible
		return;
	end
	if windowspan>0 then
		delta = colnum - math.floor((windowspan - 1)/2);
	else
		delta = colnum;
	end
	if delta < 1 then
		delta = 1;
	elseif delta + windowspan - 1 > tabledata.Columns.Count then
		delta = tabledata.Rows.Count + 1 - windowspan;
	end
	setFirstColumn(delta);
	if not refreshing then
		refreshing = true;
		refreshScrollbars();
		refreshing = false;
	end
end

function cellRowClicked(roll)
	selectRow(roll);
	if parent and parent.rowSelected then
		parent.rowSelected(roll);
	end
end

function cellColumnClicked(title)
	selectColumn(title);
	if parent and parent.columnSelected then
		parent.columnSelected(title);
	end
end

function chartRowNum(row)
	local order = "";
	local sort = string.lower(OptionsManager.getOption("TRSO"));

	if sort == string.lower(Interface.getString("option_val_standard")) and tabledata then
		order = string.lower(tabledata.SortOrder);
	else
		order = sort;
	end

	if not tabledata then
		return row;
	end
	if order == string.lower(Interface.getString("option_val_ascending")) then
		return row;
	else
		return (tabledata.Rows.Count+1)-row;
	end
end

function parseCritical(text)
	local name = "";
	local key = "";
	local code = string.gsub(text,"%s+","");
	local crit = nil;
	local src = nil;
	if string.len(code)~=2 or not tabledata then
		return nil;
	end
	key = string.sub(code,2,2);
	-- look these codes up in the critical table
	src = tabledata.Criticals[key];
	if src then
		crit = {};
		crit.Code = src.Code;
		crit.Name = src.Name;
		crit.ResultTable = src.ResultTable;
		crit.Severity = string.sub(code,1,1);
	end

	return crit;
end

function getCustomData()
	return customData;
end

function setCustomData(newCustomData)
	customData = newCustomData;
end