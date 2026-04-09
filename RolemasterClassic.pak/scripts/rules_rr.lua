-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

-- Get RR List
function List_Base()
	local aRRList = {};

	table.insert(aRRList, {resistancetype = "base", label = "Essence", stat = "empathy", order = 1});
	table.insert(aRRList, {resistancetype = "base", label = "Channeling", stat = "intuition", order = 2});
	table.insert(aRRList, {resistancetype = "base", label = "Mentalism", stat = "presence", order = 3});
	table.insert(aRRList, {resistancetype = "base", label = "Disease", stat = "constitution", order = 4});
	table.insert(aRRList, {resistancetype = "base", label = "Poison", stat = "constitution", order = 5});
	table.insert(aRRList, {resistancetype = "base", label = "Terror", stat = "selfdiscipline", order = 6});
	
	return aRRList;
end

function List_Hybrid()
	local aRRList = {};

	table.insert(aRRList, {resistancetype = "hybrid", label = "Ess/Chan", resistances = "Essence/Channeling", order = 7});
	table.insert(aRRList, {resistancetype = "hybrid", label = "Chan/Ment", resistances = "Channeling/Mentalism", order = 8});
	table.insert(aRRList, {resistancetype = "hybrid", label = "Ment/Ess", resistances = "Essence/Mentalism", order = 9});
	table.insert(aRRList, {resistancetype = "hybrid", label = "Arcane", resistances = "Essence/Channeling/Mentalism", order = 10});
	
	return aRRList;
end

function PartySheetList()
	local aNameList = {};
	
	for _, vRR in pairs(Rules_RR.List_Base()) do
		table.insert(aNameList, vRR.label);
	end
	for _, vRR in pairs(Rules_RR.List_Hybrid()) do
		table.insert(aNameList, vRR.label);
	end
	
	return aNameList;
end

function PartySheetGetNodeAndName(sNode, sControlName)
	local sRRType;
	
	if sControlName == "chan_ment" then
		sRRType = "hybrid";
		sName = "Chan/Ment";
	elseif sControlName == "ess_chan" then
		sRRType = "hybrid";
		sName = "Ess/Chan";
	elseif sControlName == "ment_ess" then
		sRRType = "hybrid";
		sName = "Ment/Ess";
	elseif sControlName == "arcane" then
		sRRType = "hybrid";
		sName = "Arcane";
	else
		sRRType = "base";
		sName = string.upper(string.sub(sControlName, 1, 1)) .. string.sub(sControlName, 2);
	end
	local sNodeName = sNode .. ".rr." .. sRRType .. "." .. sControlName;
	local nodeRR = DB.findNode(sNodeName);
	
	return nodeRR, sName;
end

function GetRRNodeName(sRRName)
	local _tRRNodeName = {
		["Channeling"] = ".rr.base.channeling",
		["Essence"] = ".rr.base.essence",
		["Mentalism"] = ".rr.base.mentalism",
		["Disease"] = ".rr.base.disease",
		["Poison"] = ".rr.base.poison",
		["Terror"] = ".rr.base.terror",
		["Channeling/Essence"] = ".rr.hybrid.ess_chan",
		["Ess/Chan"] = ".rr.hybrid.ess_chan",
		["Channeling/Mentalism"] = ".rr.hybrid.chan_ment",
		["Chan/Ment"] = ".rr.hybrid.chan_ment",
		["Essence/Mentalism"] = ".rr.hybrid.ment_ess",
		["Ment/Ess"] = ".rr.hybrid.ment_ess",
		["Arcane"] = ".rr.hybrid.arcane"
	}
	
	return _tRRNodeName[sRRName];
end

function GetStatFromBaseRR(sBaseRRName)
	local aBaseRRs = Rules_RR.List_Base();
	sBaseRRName = string.lower(sBaseRRName);
	
	for _, vBaseRR in pairs(aBaseRRs) do
		if sBaseRRName == string.lower(vBaseRR.label) then
			return vBaseRR.stat;
		end	
	end

	return "";
end

function GetResistancesFromHybridRR(sHybridRRName)
	local aHybridRRs = Rules_RR.List_Hybrid();
	sHybridRRName = string.lower(sHybridRRName);
	
	for _, vHybridRR in pairs(aHybridRRs) do
		local sLabel = string.lower(string.gsub(vHybridRR.label, "/", "_"));
		if sHybridRRName == sLabel then
			return vHybridRR.resistances;
		end	
	end

	return "";
end