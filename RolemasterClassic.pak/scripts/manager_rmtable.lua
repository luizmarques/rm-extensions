-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Table Manager
--
--

local tablelist = {};
local nCritAdjustment = 0;
local nHitsMultiplier = 1;

function getNode(tableid)
	if not tableid then
		return nil;
	end
	if tablelist[tableid] and tablelist[tableid].nodepath then
		local nodepath = tablelist[tableid].nodepath;
		local node = DB.findNode(nodepath);
		if node then
			return node;
		end
		-- nodepath no longer works, remove it from the list
		tablelist[tableid].nodepath = nil;
	end
	for k,mod in pairs(Module.getModules()) do
		local nodepath = "RMTables."..tableid.."@"..mod;
		local node = DB.findNode(nodepath);
		if node then
--			if not tablelist[tableid] then
				tablelist[tableid] = {};
--			end
			tablelist[tableid].nodepath = nodepath;
			return node;
		end
	end
	return nil;
end

function getTableData(node, nFumble)
	local tableid = getTableID(node);

	if tableid=="" then
		return nil;
	end
	tablelist[tableid] = {};

	if not tablelist[tableid].tabledata or (nFumble and nFumble > 0) then
		local tabledata = {};
		local i,j;
		-- top-level values (such as Name, Id etc)
		for k,v in pairs(DB.getChildren(node)) do
			if DB.getType(v)=="string" or DB.getType(v)=="number" then
				tabledata[k] = DB.getValue(v);
			end
		end
		-- fumble
		if DB.getChild(node, "Fumble") then
			local range = "";
			tabledata.Fumble = {};
			-- Range, Table and ColumnTitle
			for k,v in pairs(DB.getChildren(node, "Fumble")) do
				if DB.getType(v)=="string" or DB.getType(v)=="number" then
					tabledata.Fumble[k] = DB.getValue(v);
				end
			end
			-- split the range into low/high numbers
			range = tabledata.Fumble.Range;
			if range then
				local lower,higher = string.match(range,"(%d+)\-(%d+)");
				if lower then
					lower = lower + 0;
				else
					lower = range + 0;
				end
				if higher then
					higher = higher + 0;
				else
					higher = lower;
					lower  = 1;
				end
				tabledata.Fumble.LowerRoll = math.min(lower,higher);
				tabledata.Fumble.HigherRoll = math.max(lower,higher);
				-- Update Fumble based on Weapon Fumble?
				if nFumble and nFumble ~= tabledata.Fumble.HigherRoll then
					nOldFumble = tabledata.Fumble.HigherRoll;
					tabledata.Fumble.HigherRoll = nFumble;
				end
			end
		end
		-- unmodified
		if DB.getChild(node, "Unmodified") then
			local range = "";
			tabledata.Unmodified = {};
			i = 0;
			for k,v in pairs(DB.getChildren(node, "Unmodified")) do
				if DB.getChild(v, "Range") then
					local unmod = {};
					i = i + 1;
					unmod.Range = DB.getValue(v, "Range");
					-- split the range into low/high numbers
					range = unmod.Range;
					if range then
						local lower,higher = string.match(range,"(%d+)\-(%d+)");
						if lower then
							lower = lower + 0;
						else
							lower = range + 0;
						end
						if higher then
							higher = higher + 0;
						else
							higher = lower;
						end
						unmod.LowerRoll = math.min(lower,higher);
						unmod.HigherRoll = math.max(lower,higher);
						-- Update Unmodified values that match the old fumble value
						if nOldFumble and nOldFumble == unmod.HigherRoll then
							unmod.HigherRoll = nFumble;
						end
						tabledata.Unmodified[i] = unmod;
					end
				end
			end
		end
		-- columns
		tabledata.Columns = {};
		i = 0;
		for k,v in pairs(DB.getChildren(node, "Columns")) do
			local col = {};
			i = i + 1;
			col.Id = DB.getValue(v, "Id", "");
			col.Title = DB.getValue(v, "Title", "");
			tabledata.Columns[col.Id] = col;
		end
		tabledata.Columns.Count = i;
		
		-- degrees
		tabledata.Degrees = {};
		i = 0;
		for k,v in pairs(DB.getChildren(node, "Degrees")) do
			local deg = {};
			i = i + 1;
			deg.Name = DB.getValue(v, "Name", "");
			deg.Rank = DB.getValue(v, "Rank", 0);
			deg.MaxRoll = DB.getValue(v, "MaxRoll", 0);
			tabledata.Degrees[deg.Rank] = deg;
		end
		tabledata.Degrees.Count = i;
		-- criticals
		sCritCodes = "";
		tabledata.Criticals = {};
		i = 0;
		for k,v in pairs(DB.getChildren(node, "Criticals")) do
			local crit = {};
			i = i + 1;
			crit.Name = DB.getValue(v, "Name", "");
			crit.Code = DB.getValue(v, "Code", "");
			if crit.Code ~= "" then
				sCritCodes = sCritCodes .. crit.Code;
			end
			crit.ResultTable = DB.getValue(v, "ResultTable", "");
			tabledata.Criticals[crit.Code] = crit;
		end
		tabledata.Criticals.Count = i;
		-- Chart data
		tabledata.Rows = {};
		tabledata.Rows.Limits = {HighRoll=nil,HighRow=nil,LowRoll=nil,LowRoll=nil};
		i = 0;
		for k,v in pairs(DB.getChildren(node, "Chart")) do
			local row = {};
			local lower, higher;

			row.Roll = DB.getValue(v, "Roll", "");
			lower,higher = string.match(row.Roll,"([\-\+]?%d+)\-([\-\+]?%d+)");
			if lower then
				lower = lower + 0;
			else
				lower = row.Roll + 0;
			end
			if higher then
				higher = higher + 0;
			else
				higher = lower;
			end
			row.LowerRoll = math.min(lower,higher);
			row.HigherRoll = math.max(lower,higher);
			-- high and low rolls
			if tabledata.Rows.Limits.HighRoll==nil or row.HigherRoll>tabledata.Rows.Limits.HighRoll then
				tabledata.Rows.Limits.HighRoll = row.HigherRoll;
				tabledata.Rows.Limits.HighRow = row;
			end
			if tabledata.Rows.Limits.LowRoll==nil or row.LowerRoll<tabledata.Rows.Limits.LowRoll then
				tabledata.Rows.Limits.LowRoll = row.LowerRoll;
				tabledata.Rows.Limits.LowRow = row;
			end
			row.Location = DB.getValue(v, "Location", "");
			-- each entry
			if DB.getChild(v, "Entries") then
				row.Entries = getChartEntries(DB.getChild(v, "Entries"));
			elseif DB.getChild(v, "RMCAttackResults") then
				local sRowResults = DB.getValue(v, "RMCAttackResults");
				sRowResults = RMTableManager.UpdateRowHits(sRowResults);
				row.Entries =  RMCAttackResults(sRowResults); 
			elseif DB.getChild(v, "RMUAttackResults") then
				local sRowResults = DB.getValue(v, "RMUAttackResults");
				sRowResults = RMTableManager.UpdateRowHits(sRowResults);
				sRowResults = RMTableManager.UpdateRowCriticals(sRowResults, sCritCodes);
				row.Entries =  RMUAttackResults(sRowResults); 
			else
				row.Entries = {};
				row.Entries.Count = 0;
			end

			-- Update row for weapon fumble?
			if string.lower(tabledata.TableType) == "attack" and DB.getChild(node, "Fumble") then
				if nOldFumble and nFumble and row.LowerRoll == 1 then
					row.Roll = string.gsub(row.Roll, intStrLeadZero(nOldFumble), intStrLeadZero(nFumble));
					row.HigherRoll = nFumble;
				elseif DB.getChild(node, "Fumble") and nOldFumble and nFumble and nOldFumble + 1 == row.LowerRoll then
					if nFumble + 1 <= row.HigherRoll then
						row.LowerRoll = nFumble + 1;					
						row.Roll = string.gsub(row.Roll, intStrLeadZero(nOldFumble + 1), intStrLeadZero(nFumble + 1));
					end
				end
			end

			i = i + 1;
			tabledata.Rows[i] = row;
		end
		-- add any degrees
		for n=1,tabledata.Degrees.Count do
			local deg = tabledata.Degrees[n];
			if deg then
				local row = {};
				i = i + 1;
				row.LowerRoll = deg.MaxRoll;
				row.HigherRoll = deg.MaxRoll;
				row.Entries = {};
				row.Entries.Count = 0;
				row.DegreeName = deg.Name;
				tabledata.Rows[i] = row;
			end
		end
		-- sort the rows
		table.sort(tabledata.Rows,rowsort);
		tabledata.Rows.Count = i;
				
		-- save the loaded data
		tablelist[tableid].tabledata = tabledata;
	end

	return tablelist[tableid].tabledata;
end

function SetCritAdjustment(nCritAdj)
	nCritAdjustment = nCritAdj;
end

function SetHitsMultiplier(nHitsMult)
	nHitsMultiplier = nHitsMult;
end

-- Handles Critical Adjustments and Hits Mulitpliers
function UpdateRowCriticals(sRowResults, sCriticalCodes)
	local nLength = string.len(sRowResults);
	local nLocCurrent = 1;
	local nLocLast = 1;
	local sNewRowResults = "";

	nLocCurrent = string.find(sRowResults, ";", nLocLast);
	while nLocCurrent do 
		local sCritSeverity = "";
		local sCritCode = "";
		local sCritical = "";
		local sColumnResult = string.sub(sRowResults, nLocLast, nLocCurrent - 1);
		nLocLast = nLocCurrent + 1;
		local nLocCrit = string.find(sColumnResult, "%a");
		if nLocCrit then
			nHits = tonumber(string.sub(sColumnResult, 1, nLocCrit - 1));
			sCritSeverity = string.sub(sColumnResult, nLocCrit, nLocCrit);
			sCritCode = string.sub(sColumnResult, nLocCrit + 1, nLocCrit + 1);
			local nSeverity = string.byte(sCritSeverity);
			local nNewSeverity = nSeverity + nCritAdjustment;

			-- Check if the critical severity is reduced below an A critical and reduce to Z, Y, X, etc.
			if nNewSeverity < 65 then
				local nMod = 91 + (nNewSeverity - 65);
				sCritSeverity = string.char(nMod);
				sCritical = sCritSeverity .. sCritCode .. "(A" .. sCritCode .. ")";
			else
				-- Check if the new critical is greater than a J critical and set it to J if it is
				if nNewSeverity > 74 then
					nNewSeverity = 74;
				end

				sCritSeverity = string.char(nNewSeverity);
				sCritical = sCritSeverity .. sCritCode;

				if sCritSeverity > "E" then
					local sSecondSeverity = "C";
					local sThirdSeverity = "";
					local sSecondCode = "";
					local sThirdCode = "";
					local nCritCodes = string.len(sCriticalCodes);
					
					if nCritCodes > 1 then
						sSecondCode = string.sub(sCriticalCodes, 1, 1);
						sThirdCode = string.sub(sCriticalCodes, 2, 2);
					else
						sSecondCode = sCritCode;
						sThirdCode = sCritCode;
					end	
					
					if sCritSeverity == "F" then
						sSecondSeverity = "A";
					elseif sCritSeverity == "G" then
						sSecondSeverity = "B";
					elseif sCritSeverity == "I" then
						sThirdSeverity = "A";
					elseif sCritSeverity == "J" then
						sThirdSeverity = "B";
					end
					
					sCritical = sCritical .. "(E" .. sCritCode .. "," .. sSecondSeverity .. sSecondCode;
					
					if sThirdSeverity ~= "" then
						sCritical = sCritical .. "," .. sThirdSeverity .. sThirdCode;
					end
					
					sCritical = sCritical .. ")";
				end
			end
		else
			nHits = tonumber(sColumnResult);
		end
		sNewRowResults = sNewRowResults .. tostring(math.floor(nHits + 0.5)) .. sCritical .. ";";
		
		nLocCurrent = string.find(sRowResults, ";", nLocLast);
	end
	
	return sNewRowResults;
end

function UpdateRowHits(sRowResults)
	local nLocCurrent = 1;
	local nLocLast = 1;
	local sNewRowResults = "";

	nLocCurrent = string.find(sRowResults, ";", nLocLast);
	while nLocCurrent do 
		local sCritical = "";
		local sColumnResult = string.sub(sRowResults, nLocLast, nLocCurrent - 1);
		nLocLast = nLocCurrent + 1;
		local nLocCrit = string.find(sColumnResult, "%a");
		if nLocCrit then
			nHits = tonumber(string.sub(sColumnResult, 1, nLocCrit - 1));
			sCritical = string.sub(sColumnResult, nLocCrit);
		else
			nHits = tonumber(sColumnResult);
		end
		if not nHits then
			nHits = 0;
		end
		sNewRowResults = sNewRowResults .. tostring(math.floor((nHits * nHitsMultiplier) + 0.5)) .. sCritical .. ";";
		
		nLocCurrent = string.find(sRowResults, ";", nLocLast);
	end
	
	return sNewRowResults;
end

function intStrLeadZero(nValue)
	if nValue < 10 then
		sValue = "0" .. tostring(nValue);
	else
		sValue = tostring(nValue);
	end

	return sValue;
end

function getTableName(node)
	return DB.getValue(node, "Name", "");
end
function getTableClass(node)
	return DB.getValue(node, "Class", "");
end
function getTableID(node)
	return DB.getValue(node, "Id", "");
end
function getTableType(node)
	return DB.getValue(node, "TableType", "");
end

function getCellSizes(node)
	local row,column,firstRow,firstColumn;
	firstRow = 21;
	firstColumn = 65;
	if node then
		if getTableID(node) == Rules_Constants.BaseSpellAttackTableID then
			row = 21;
			column = 150;	
		elseif getTableType(node) == Rules_Constants.TableType.Attack or getTableID(node) == Rules_Constants.RRTableID then
			row = 21;
			column = 34;
		elseif getTableID(node) == "SF-01" or getTableID(node) == "SF-02" then
			row = 84;
			column = 272;
		elseif getTableID(node) == Rules_Constants.ManeuverTableDefaultTableId then  
			row = 84;
			column = 136;
		elseif getTableID(node) == Rules_Constants.AlternativeStaticActionTableId then  
			row = 84;
			column = 272;
		else
			row = 84;
			column = 136;
		end
	end
	return row,column,firstRow,firstColumn;
end

function browseTable(node)
	local tdw = Interface.findWindow("tablebrowser","");
	if not node then
		return;
	end
	if tdw then
		tdw.close();
	end
	tdw = Interface.openWindow("tablebrowser","");
	tdw.grid.bind(node);
	return;
end

function getTableCellWoundEffects(aTableCell)
	local aWoundEffects = {};
	local hits = 0;
	local nRR = 0;
	local nRRTarget = 0;
	local sText = "";
	
	if aTableCell.Effects then
		for i,fx in ipairs(aTableCell.Effects) do
			for k,v in pairs(fx) do
				if k=="Hits" and v~=0 then
					hits = hits + v;
					sText = sText .. hits .. "";
				end
				if k=="RR" and v~=0 then
					nRR = nRR + v;
					sText = v .. " ";
				end
				if k=="RRTarget" and v~=0 then
					nRRTarget = nRRTarget + v;
					sText = "";
				end
				if type(v)=="string" or type(v)=="number" then
					aWoundEffects[k] = v;
				end
				if fx.Criticals and sText ~= "" then
					for x,y in pairs(fx.Criticals) do
						if x == 1 then
							sText = sText .. y;
						end
					end
				end
			end
		end
	end
	if aTableCell.TrueCondition then
		aWoundEffects["TrueCondition"] = aTableCell.TrueCondition;
	end
	if aTableCell.ConditionalEffects then
		for i,fx in ipairs(aTableCell.ConditionalEffects) do
			for k,v in pairs(fx) do
				if k=="Hits" and v~=0 then
					hits = hits + v;
				end
				if type(v)=="string" or type(v)=="number" then
					aWoundEffects["Conditional" .. k] = v;
				end
			end
		end
	end
	if aTableCell.AttackerEffects then
		for i,fx in ipairs(aTableCell.AttackerEffects) do
			for k,v in pairs(fx) do
				if type(v)=="string" or type(v)=="number" then
					aWoundEffects["Attacker" .. k] = v;
				end
			end
		end
	end

	if aTableCell.Text then
		sText = aTableCell.Text;
	end

	return aWoundEffects;
end

function getTableCellText(aTableCell)
	local sText = "";
	local hits = 0;
	
	if aTableCell.Effects then
		for i,fx in ipairs(aTableCell.Effects) do
			for k,v in pairs(fx) do
				if k=="Hits" then
					hits = hits + v;
					sText = hits .. "";
				end
				if k=="RR" then
					sText = "";
				end
				if k=="RRTarget" then
					sText = "";
				end
				if type(v)=="string" or type(v)=="number" then
					sText = v .. "";
				end

				if fx.Criticals and sText ~= "" then
					for x,y in pairs(fx.Criticals) do
						if y == "RR" then
							sText = "";
						elseif y == "RRTarget" then
							sText = "";
						elseif y ~= 1 then
							sText = sText .. y;
						end
					end
				end
			end
		end
	end
	if aTableCell.ConditionalEffects then
		for i,fx in ipairs(aTableCell.ConditionalEffects) do
			for k,v in pairs(fx) do
				if k=="Hits" then
					hits = hits + v;
					sText = hits .. "";
				end
				if type(v)=="string" or type(v)=="number" then
					sText = v .. "";
				end
			end
		end
	end

	if aTableCell.Text then
		sText = aTableCell.Text;
	end

	return sText;
end

function getTableCellResultTable(aTableCell)
	local sCritical = "";
	local aCritList = {};
	local sOriginalSeverity = nil;

	if aTableCell.Effects then
		for i,fx in ipairs(aTableCell.Effects) do
			if fx.Criticals then
				for k,v in ipairs(fx.Criticals) do
						table.insert(aCritList, v);
					if k == 1 then
						sCritical = v;
					end
				end
			end
		end
	end
	
	if aTableCell.Text and not aTableCell.ConditionalEffects then
		local sResult = aTableCell.Text;
		local iLength = string.len(sResult);
		
		if iLength > 2 then
			sOriginalSeverity = string.sub(sResult, iLength - 1, iLength - 1);
		end
	end

	return sCritical, aCritList, sOriginalSeverity;
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Internal routines
--
--

function rowsort(r1,r2)
	return (r1.LowerRoll<r2.LowerRoll);
end

function getChartEntries(node)
	local list = {};
	local i = 0;
	for k,v in pairs(DB.getChildren(node)) do
		local entry = {};
		local sText = "";
		local nOldHits = 0;
		local nNewHits = 0;
		i = i + 1;
		-- Effects
		if DB.getChild(v, "Effects") then
			entry.Effects, nNewHits, nOldHits = getEntryEffects(DB.getChild(v, "Effects"));
		else
			entry.Effects = {};
			entry.Effects.Count = 0;
		end
		-- top-level values (such as ColumnId)
		for key,value in pairs(DB.getChildren(v)) do
			if DB.getType(value)=="string" or DB.getType(value)=="number" then
				if key == "Text" then
					sText = DB.getValue(value);
				end
				entry[key] = DB.getValue(value);
			end
		end
		-- Update Text if hits changed
		if nOldHits ~= 0 and nOldHits ~= nNewHits then
			-- RMC Criticals
			local sHitsText = " hits";
			if nOldHits == 1 then
				sHitsText = " hit"
			end
			local sNewText = string.gsub(sText, nOldHits .. sHitsText, nNewHits .. sHitsText);
			if sNewText == sText then
				-- RMU Criticals
				sHitsText = " Hits";
				if nOldHits == 1 then
					sHitsText = " Hit"
				end
				sNewText = string.gsub(sText, nOldHits .. sHitsText, nNewHits .. sHitsText);
			end
			entry["Text"] = sNewText;
		end
		-- Conditional Effects
		entry.TrueCondition = DB.getValue(v, "TrueCondition", "");
		if DB.getChild(v, "ConditionalEffects") then
			entry.ConditionalEffects = getEntryEffects(DB.getChild(v, "ConditionalEffects"));
		else
			entry.ConditionalEffects = {};
			entry.ConditionalEffects.Count = 0;
		end
		-- Attacker Effects
		if DB.getChild(v, "AttackerEffects") then
			entry.AttackerEffects = getEntryEffects(DB.getChild(v, "AttackerEffects"));
		else
			entry.AttackerEffects = {};
			entry.AttackerEffects.Count = 0;
		end
		-- ensure we have a key
		if not entry.ColumnId then
			entry.ColumnId = "";
		end
		list[entry.ColumnId] = entry;
	end
	list.Count = i;
	return list;
end

function getChartRollResults(rowResults)  
  local list = {};
  local entryCount = 0;
  local rowLength = string.len(rowResults);
  local currentLoc = 1;
  local lastLoc = 1;
  local columnCount = 0;
  
	while currentLoc and currentLoc < rowLength do
		currentLoc = string.find(rowResults, ";", currentLoc + 1);
		columnCount = columnCount + 1;
	end
	while entryCount < columnCount do
		local entry = {};
		entry.Effects = {};
		entry.Effects.Count = 0;
		
		key = tostring(20 - entryCount);
		if string.len(key) == 1 then
			key = "0" .. key;
		end
		entryCount = entryCount + 1;
		currentLoc = string.find(rowResults, ";", lastLoc);
		entry.ColumnId = key;
		if currentLoc then
			local columnResult = string.sub(rowResults, lastLoc, currentLoc - 1);
			lastLoc = currentLoc + 1;
			local multiCritLoc = string.find(columnResult, "(");
			if multiCritLoc then
			  -- NEEDS CODE TO HANDLE PARENTHESIS
				local critLoc = string.find(columnResult, "%a");
				entry.Effects[1] = {};
				entry.Effects[1].Text = string.sub(columnResult, 1, multiCritLoc - 1);
				entry.Effects[1].Hits = tonumber(string.sub(columnResult, 1, critLoc - 1));
				entry.Effects[1].Criticals = {};
				local commaLoc = string.find(columnResult, ",");
				local count = 0;
				while commaLoc do
					count = count + 1;
					entry.Effects[1].Criticals[count] = {};
					entry.Effects[1].Criticals[count] = string.sub(columnResult, multiCritLoc + 1, commaLoc - 1);
					multiCritLoc = commaLoc;
					commaLoc = string.find(columnResult, ",", commaLoc + 1);
					if not commaLoc then
						commaLoc = string.find(columnResult, ")");
					end
				end
				entry.Effects[1].Criticals.Count = count;
				entry.Effects.Count = 1;
			else
				local critLoc = string.find(columnResult, "%a");
				if critLoc then
					entry.Effects[1] = {};
					entry.Effects[1].Hits = tonumber(string.sub(columnResult, 1, critLoc - 1));
					entry.Effects[1].Criticals = {};
					entry.Effects[1].Criticals[1] = {};
					entry.Effects[1].Criticals[1] = string.sub(columnResult, critLoc);
					entry.Effects[1].Criticals.Count = 1;
					entry.Effects.Count = 1;
				else
					entry.Effects[1] = {};
					if columnResult == "-" then
						entry.Effects[1].Hits = 0;
					else
						entry.Effects[1].Hits = columnResult;
					end
					entry.Effects.Criticals = {};
					entry.Effects.Criticals.Count = 0;
					entry.Effects.Count = 1;
				end
			end
		end
		list[entry.ColumnId] = entry;
	end	
	list.Count = entryCount;
	return list;
end

function RMCAttackResults(rowResults)
	local list = {};
	local entryCount = 0;
	local currentLoc = 1;
	local lastLoc = 1;
	while entryCount < 20 do
		key = tostring(20 - entryCount);
		if string.len(key) == 1 then
			key = "0" .. key;
		end
		entryCount = entryCount + 1;
		list[key], currentLoc, lastLoc = AttackResults(rowResults, currentLoc, lastLoc);
	end	
	list.Count = entryCount;
	return list;
end

function RMUAttackResults(rowResults)
	local list = {};
	local entryCount = 1;
	local currentLoc = 1;
	local lastLoc = 1;
	while entryCount <= 10 do
		key = tostring(entryCount);
		if string.len(key) == 1 then
			key = "0" .. key;
		end
		entryCount = entryCount + 1;
		list[key], currentLoc, lastLoc = AttackResults(rowResults, currentLoc, lastLoc);
	end	
	list.Count = entryCount;
	return list;
end

function AttackResults(rowResults, currentLoc, lastLoc)
	local entry = {};
	entry.Effects = {};
	entry.Effects.Count = 0;

	currentLoc = string.find(rowResults, ";", lastLoc);
	entry.ColumnId = key;
	if currentLoc then
		local columnResult = string.sub(rowResults, lastLoc, currentLoc - 1);
		lastLoc = currentLoc + 1;
		local multiCritLoc = string.find(columnResult, "%(", 1);
		if multiCritLoc then
		  -- NEEDS CODE TO HANDLE PARENTHESIS
			local critLoc = string.find(columnResult, "%a");
			entry.Text = string.sub(columnResult, 1, multiCritLoc - 1);
			entry.Effects[1] = {};
			entry.Effects[1].Hits = tonumber(string.sub(columnResult, 1, critLoc - 1));
			entry.Effects[1].Criticals = {};
			local commaLoc = string.find(columnResult, ",");
			local count = 0;
			while commaLoc do
				count = count + 1;
				entry.Effects[1].Criticals[count] = {};
				entry.Effects[1].Criticals[count] = string.sub(columnResult, multiCritLoc + 1, commaLoc - 1);
				multiCritLoc = commaLoc;
				commaLoc = string.find(columnResult, ",", commaLoc + 1);
			end
			count = count + 1;
			entry.Effects[1].Criticals[count] = {};
			entry.Effects[1].Criticals[count] = string.sub(columnResult, multiCritLoc + 1, -2);
			entry.Effects[1].Criticals.Count = count;
			entry.Effects.Count = 1;
		else
			local critLoc = string.find(columnResult, "%a");
			if critLoc then
				entry.Effects[1] = {};
				entry.Effects[1].Hits = tonumber(string.sub(columnResult, 1, critLoc - 1));
				entry.Effects[1].Criticals = {};
				entry.Effects[1].Criticals[1] = {};
				entry.Effects[1].Criticals[1] = string.sub(columnResult, critLoc);
				entry.Effects[1].Criticals.Count = 1;
				entry.Effects.Count = 1;
			else
				entry.Effects[1] = {};
				if columnResult == "-" then
					entry.Effects[1].Hits = 0;
				else
					entry.Effects[1].Hits = columnResult;
				end
				entry.Effects.Criticals = {};
				entry.Effects.Criticals.Count = 0;
				entry.Effects.Count = 1;
			end
		end
	end
	return entry, currentLoc, lastLoc;
end

function getEntryEffects(node)
	local list = {};
	local i = 0;
	local sWound = "";
	local nOldHits = 0;
	local nNewHits = 0;
	
	for k,v in pairs(DB.getChildren(node)) do
		local effect = {};
		i = i + 1;
		-- top-level values (such as Hits)
		for key,value in pairs(DB.getChildren(v)) do
			if value.getType()=="string" or value.getType()=="number" then
				if key == "Hits" then
					nOldHits = value.getValue();
					nNewHits = math.floor((nOldHits * nHitsMultiplier) + 0.5);
					effect[key] = nNewHits;
				else
					effect[key] = value.getValue();
				end
				if key == "Wound" then
					sWound = value.getValue();
				end
			end
		end
		-- Update Wound if hits changed
		if nOldHits ~= 0 and nOldHits ~= nNewHits then
			local sHitsText = " hits";
			if nOldHits == 1 then
				sHitsText = " hit"
			end
			if sWound ~= "" then
				effect["Wound"] = string.gsub(sWound, nOldHits .. sHitsText, nNewHits .. sHitsText);
			end
		end
		-- Criticals
		if DB.getChild(v, "Criticals") then
			effect.Criticals = getEffectCriticals(DB.getChild(v, "Criticals"));
		else
			effect.Criticals = {};
			effect.Criticals.Count = 0;
		end
		list[i] = effect;
	end
	list.Count = i;
	return list, nNewHits, nOldHits;
end

function getEffectCriticals(node)
	local list = {};
	local i = 0;
	for k,v in pairs(DB.getChildren(node)) do
		i = i + 1;
		list[i] = v.getValue();
	end
	list.Count = i;
	return list;
end

