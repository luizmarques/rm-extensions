-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- tableview_cell
--
--

local entry = nil;
local hits = 0;
local nRR = 0;
local nRRTarget = 0;
local critlist = {};
local selector = {method=nil, key=""};
local draggable = false;
local altcrit = {};

function setSelector(method, key)
	selector.method = method;
	selector.key = key;
end

function clearSelector()
	selector = {method=nil, key=""};
end

function onClickDown(button,x,y)
	if selector.method and (button==1) then
		return true;
	else
		return;
	end
end

function onClickRelease(button,x,y)
	if selector.method then
		selector.method(selector.key);
	end
end

function clearEntry()
	entry = nil;
	critlist = {};
	altcrit = {};
	refresh();
end

function setEntry(ent,active)
	entry = ent;
	refresh(active);
end

function setText(text)
	entry = {Text=text};
	refresh(false);
end

function refresh(active)
	local crit = {};
	local addCrit1 = {};
	local addCrit2 = {};
	local severity = "";
	local crits = "";
	local critnum = 0;
	local isRR = false;
    setValue("");
    hits = 0;
	nRR = 0;
	nRRTarget = 0;
    critlist = {Count=0};
    resetMenuItems();
    setDraggable(false);
    if not entry then
        return;
    end

    -- parse entry effects
    if entry.Effects then

		for i,fx in ipairs(entry.Effects) do
			hits = hits + (fx.Hits or 0);
			nRR = nRR + (fx.RR or 0);
			nRRTarget = nRRTarget + (fx.RR or 0);

			if fx.Criticals and #fx.Criticals > 0 then
				-- Handle table criticals
				for j,text in ipairs(fx.Criticals) do
					crit = parseCritical(text);
					if crit then
						if crits=="" then
							crits = text;
						else
							crits = crits..","..text;
						end
						critnum = critnum + 1;
						altcrit.ResultTable = crit.ResultTable;
						altcrit.Severity = "";
						altcrit.Name = crit.Name;
						altcrit.Code = crit.Code;
						altcrit = Rules_Combat.GetAltCrit(altcrit);
						critlist[critnum] = crit;
						if active then
							if crit.ResultTable == Rules_Constants.RRTableID then
								registerMenuItem("Resolve Resistance Roll", "RRTable", critnum+1);
								isRR = true;
							else
								if altcrit and altcrit.Name ~= "" then
									registerMenuItem("Resolve Alternate " .. crit.Severity .. " " .. altcrit.Name .. " Critical", "alternateCrit", critnum+1);
								else
									registerMenuItem("Resolve " .. crit.Severity .. " " .. crit.Name .. " Critical", "crit" .. crit.Severity, critnum+1);
								end
							end
							setDraggable(true);
						end
					else
						-- Fix for Lightning Bolt results that have a J critical severity
						if text == "J" then
							local JCriticals = { "DI", "CH", "EE" };
							for j,text in ipairs(JCriticals) do
								crit = parseCritical(text);
								if crit then
									if crits=="" then
										crits = text;
									else
										crits = crits..","..text;
									end
									critnum = critnum + 1;
									critlist[critnum] = crit;
									if active then
										registerMenuItem("Resolve "..crit.Severity.." "..crit.Name,"crit"..crit.Severity, critnum+1);
										setDraggable(true);
									end
								end
							end
						end
					end
				end

				-- Only Add Critical Options if not an RR
				if isRR == false then
					-- Add Option for Large Criticals	
					if active then
						registerMenuItem("Resolve Large Critical", "CritLarge", 7);
					end
					
					-- Add option for Super-Large Criticals
					if active then
						registerMenuItem("Resolve Super-Large Critical","CritSuperLarge",8);
					end
					
					-- add Additional Criticals as needed
					local sevNumber = 0;
					addCrit1 = Rules_Combat.aAddCrit1;
					if addCrit1.Name and string.len(addCrit1.Name) > 0 then
						if active and crit and crit.Severity then
							sevNumber = Rules_Combat.GetNewCrit1SevNumber(Rules_Combat.GetSevNumber(crit.Severity));
							if sevNumber >= 1 and sevNumber <= 5 then
								registerMenuItem("Resolve Additional " .. Rules_Combat.GetSev(sevNumber) .. " " .. addCrit1.Name .. " Critical #1", "additionalCrit", 5);
							end
						end
					end
					addCrit2  = Rules_Combat.aAddCrit2;
					if addCrit2.Name and string.len(addCrit2.Name) > 0 then
						if active and crit and crit.Severity then
							sevNumber = Rules_Combat.GetNewCrit2SevNumber(Rules_Combat.GetSevNumber(crit.Severity));
							if sevNumber >= 1 and sevNumber <= 5 then
								registerMenuItem("Resolve Additional " .. Rules_Combat.GetSev(sevNumber) .. " " .. addCrit2.Name .. " Critical #2", "additionalCrit", 6);
							end
						end
					end
				end
			end
		end
	
		critlist.Count = critnum;
		if crits == "RR" then
			local sValue = nRR .. "  " .. crits;
			if nRR > 0 then
				sValue = "+" .. sValue;
			end
			setValue(sValue);
		else
			setValue(hits..crits);
		end
		if hits ~= 0 or nRR ~= 0 or nRRTarget ~= 0 then
			setDraggable(active);
		end
	elseif entry.Fumble then
		local crit = {};
		crit.Code = "";
		crit.Name = "Fumble";
		crit.Table = "";
		crit.Severity = "";
		if active then
			registerMenuItem("Resolve Fumble","fumble",2);
		end
		critlist[1] = crit;
		critlist.Count = 1;
		setValue("F");
	end
	
	-- a Text value over-rides the displayed content but leaves the functionality in place
	if entry.Text and entry.Text ~= "" then
		setValue(entry.Text);
		if not entry.Fumble then
			setDraggable(active);
		end
	end
end

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--
-- Internal routines
--
--

function setDraggable(flag)
	draggable = flag;
	if flag then
		setHoverCursor("hand");
	else
		setHoverCursor("arrow");
	end
end

function onDragStart(button,x,y,draginfo)
	local custdata = {};
	local hits = 0;
	local nRR = 0;
	local nRRTarget = 0;
	local base = draginfo;
	local sCellValue = getValue();
	if not draggable then
		return;
	end
	local resolver = Interface.findWindow("tableresolver","");	
	
	if resolver then
		local sAttackerNodeName = resolver.attackerNodeName.getValue();
		if sAttackerNodeName then
			local nodeAttacker = DB.findNode(sAttackerNodeName);
			if nodeAttacker then
				local rAttacker = ActorManager.resolveActor(nodeAttacker);
				if rAttacker and rAttacker.sCTNode then
					custdata["AttackerNodeName"] = rAttacker.sCTNode;
				end
			end
		end
	end

	-- initial data type is string
	draginfo.setType("tableresult");
	draginfo.setStringData(sCellValue);
	-- number value of the drag info (hits lost)
	base = base.createBaseData("number");
	base.setNumberData(hits);
	base.setDescription(sCellValue);
	-- create the drag data
	base = draginfo.createBaseData(Rules_Constants.DataType.AttackEffects);
	if entry.Effects then
		for i,fx in ipairs(entry.Effects) do
			for k,v in pairs(fx) do
				if k=="Hits" and v~=0 then
					hits = hits + v;
--					local resolver = Interface.findWindow("tableresolver","");	
					
--					if resolver then
--						local nMultiplier = resolver.multiplier.getValue();
--						if nMultiplier and nMultiplier > 0 then
--							local nOldHits = hits;
--							hits = math.floor(hits * nMultiplier);
--							v = hits;
--							sCellValue = string.gsub(sCellValue, tostring(nOldHits), tostring(hits));
--							draginfo.setStringData(sCellValue);
--							draginfo.setDescription(sCellValue);
--						end
--					end
				end
				if k=="RR" and v~=0 then
					nRR = nRR + v;
				end
				if k=="RRTarget" and v~=0 then
					nRRTarget = nRRTarget + v;
				end
				if type(v)=="string" or type(v)=="number" then
					custdata[k] = v;
				end
			end
		end
	end
	if entry.TrueCondition then
		custdata["TrueCondition"] = entry.TrueCondition;
	end
	if entry.ConditionalEffects then
		for i,fx in ipairs(entry.ConditionalEffects) do
			for k,v in pairs(fx) do
				if k=="Hits" and v~=0 then
					hits = hits + v;
--					local resolver = Interface.findWindow("tableresolver","");	
					
--					if resolver then
--						local nMultiplier = resolver.multiplier.getValue();
--						if nMultiplier and nMultiplier > 0 then
--							local nOldHits = hits;
--							hits = math.floor(hits * nMultiplier);
--							v = hits;
--							sCellValue = string.gsub(sCellValue, tostring(nOldHits), tostring(hits));
--							draginfo.setStringData(sCellValue);
--							draginfo.setDescription(sCellValue);
--						end
--					end
				end
				if type(v)=="string" or type(v)=="number" then
					custdata["Conditional" .. k] = v;
				end
			end
		end
	end
	if entry.AttackerEffects then
		for i,fx in ipairs(entry.AttackerEffects) do
			for k,v in pairs(fx) do
				if type(v)=="string" or type(v)=="number" then
					custdata["Attacker" .. k] = v;
				end
			end
		end
	end

	-- Handle RR and RRTarget Effects
	if nRR > 0 then
		draginfo.setType("effect");
		draginfo.setNumberData(0);
		local sDesc = string.format("[%s] RR:%d [ACTION]", Interface.getString("action_effect_tag"), nRR);
		draginfo.setStringData(sDesc);
		draginfo.setDescription(sDesc);
	elseif nRRTarget > 0 then
		draginfo.setType("effect");
		draginfo.setNumberData(0);
		local sDesc = string.format("[%s] RRTarget:%d [ACTION]", Interface.getString("action_effect_tag"), nRRTarget);
		draginfo.setStringData(sDesc);
		draginfo.setDescription(sDesc);
	end
	
	draginfo.setCustomData(custdata);
	base.setCustomData(custdata);
	base.setStringData(sCellValue);
	base.setNumberData(hits);
	-- no further processing is needed
	return true;
end

function parseCritical(...)
	if window.parseCritical then
		return window.parseCritical(...);
	else
		return nil;
	end
end

function onMenuSelection(num, subnum)
	local crit = {};
	local maxSev = 0;
	if num == 5 or num == 6 then
		for i, c in ipairs(critlist) do
			local currSev = 0;
			if c.Severity then
				currSev = Rules_Combat.GetSevNumber(c.Severity);
				if currSev > maxSev then
					maxSev = currSev;
				end
			end
		end
		if num == 5 then
			crit = Rules_Combat.aAddCrit1;
			crit.Severity = Rules_Combat.GetNewCrit1Sev(maxSev);
		else
			crit = Rules_Combat.aAddCrit2;
			crit.Severity = Rules_Combat.GetNewCrit2Sev(maxSev);
		end
		if crit.Severity == "" then
			ChatManager.SystemMessage("No additional critical for this attack because of the additional critical's level difference!");
			crit = nil;
		end
	else
		local sLargeColumnName = window.parentcontrol.window.largeColumnName.getValue();
		local sAttackType = "Arms";
		if string.find(window.getTableClass(), "Spell") then
			sAttackType = "Spell";
		end
		
		if num == 7 then
			-- Large Criticals
			crit.Code = "L";
			crit.Name = "Large";
			crit.Severity = sLargeColumnName;
			if sAttackType == "Spell" then
				crit.ResultTable = "SCT-05";
				if sLargeColumnName ~= "Slaying" then
					crit.Severity = "Normal";
				end
			else
				-- Arms
				crit.ResultTable = "CT-09";
			end
		else
			if num == 8 then
				-- Super-Large Criticals
				crit.Code = "SL";
				crit.Name = "Super-Large";
				crit.Severity = sLargeColumnName;
				if sAttackType == "Spell" then
					crit.ResultTable = "SCT-06";
					if sLargeColumnName ~= "Slaying" then
						crit.Severity = "Normal";
					end
				else
					-- Arms
					crit.ResultTable = "CT-10";
				end
			else
				crit = critlist[num-1];
				if crit.Name ~= "Fumble" then
					if altcrit and altcrit.Name ~= "" then
						crit.Code = altcrit.Code;
						crit.ResultTable = altcrit.ResultTable;
						crit.Name = altcrit.Name;
					end
				end
				if crit.ResultTable == Rules_Constants.RRTableID then
					crit.Severity = Rules_Combat.nLevelAttacker;
				end
			end
		end
	end

	if not crit then
		return;
	end
  
	if window.criticalSelected then
		window.criticalSelected(crit);
	end
	
end

function critSevLarge(subnum)
	if subnum == 1 or subnum == 2 then
		return "Normal";
	else 
		if subnum == 8 then
			return "Mithril";
		else 
			if subnum == 7 then
				return "Magic";
			else 
				if subnum == 6 then
					return "Holy Arms";
				else 
					if subnum == 5 or subnum == 4 then
						return "Slaying";
					end;
				end;
			end;
		end;
	end;
end

function critSevSuperLarge(subnum)
	if subnum == 3 then
		return "Slaying"
	else
		return critSevLarge(subnum)
	end
end