-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getCharacterOwnerList()
	local nodeCharacters = DB.findNode("charsheet");
	local listOwners = {};
	
	if nodeCharacters then
		for _, vCharacter in pairs(DB.getChildren(nodeCharacters)) do
			local sOwner = DB.getOwner(vCharacter);
			if (sOwner or "") ~= "" then
				table.insert(listOwners, sOwner);
			end
		end
	end
	
	return listOwners;
end

function AddModifierStack(modifiers)
	-- add items in the modifier stack
	if not ModifierStack.isEmpty() then
		local mods = ModifierStack.slots;
		local nModifierStackSum = ModifierStack.getSum();
		local nMod = 0;
		local nFreeAdjustment = 0;

		for i = 1, #mods do
			table.insert(modifiers, mods[i]);
			nMod = nMod + mods[i].number;
		end
		
		nFreeAdjustment = nModifierStackSum - nMod;
		if nFreeAdjustment ~= 0 then
			table.insert(modifiers, {description="ModifierStack" , number=nFreeAdjustment });
		end

		-- clear the modifier stack
		ModifierStack.reset();
	end
end

-- String to Table functions  
function tableToString(tbl)
	local result = "";
	if (not tbl) or type(tbl)~="table" then
		return "";
	end
	for k,v in pairs(tbl) do
		local nm=strencode(k);
		local tp = type(v);
		local val = "";
		if tp=="number" then
			val=""..v;
		elseif tp=="string" then
			val=strencode(v);
		elseif tp=="boolean" then
			if v then
				val="true";
			else
				val="false";
			end
		elseif tp=="table" then
			val = strencode(tableToString(v));
		else
			val = "Unknown type: "..tp;
			tp = "string";
		end
		result = result.."type:"..tp.."\tname:"..nm.."\tvalue:"..val.."\n";
	end
	return strencode("{"..result.."}");
end

function StringToTable(str)
	tbl = {};
	if (not str) or type(str)~="string" then
		return nil;
	end
	-- decode the string
	str = strdecode(str);
	if string.len(str)<2 then
		return nil;
	end
	-- remove opening and closing braces
	str = string.sub(str,2,-2);
	-- split into fields
	for fld in string.gfind(str,"([^\n]*)\n") do
    local i,j,tp,nm,val = string.find(fld,"type:([^\t]*)\tname:([^\t]*)\tvalue:(.*)");
		if i then
			if tp=="string" then
				tbl[nm] = ""..strdecode(val);
			elseif tp=="number" then
				tbl[nm] = 0 + tonumber(val);
			elseif tp=="boolean" then
				if val=="true" then
					tbl[nm] = true;
				else
					tbl[nm] = false;
				end
			elseif tp=="table" then
				val = modifiersStringToTable(val);
				tbl[nm] = val;
			else
				tbl[nm] = "Unknown type: "..tp;
			end
		end
	end
	return tbl;
end

function modifiersStringToTable(str)
	tbl = {};
	if (not str) or type(str)~="string" then
		return nil;
	end
	-- decode the string
	str = strdecode(str);

	if string.len(str)<2 then
		return nil;
	end
	-- remove opening and closing braces
	str = string.sub(str,2,-2);
	-- split into fields
	local sDescription = "";
	local iValue = 0;
	local sGMOnly = false;
	for fld in string.gfind(str,"([^\n]*)\n") do
		iLoc = string.find(fld, "{")
		if iLoc and iLoc > 0 then
			fld = string.sub(fld,iLoc);
		end
		if string.sub(fld, 1, 1) == "}" then
			if sGMOnly == "true" then
				table.insert(tbl, { description = sDescription, number = iValue, gmonly = true });
			else
				table.insert(tbl, {description=sDescription, number=iValue});
			end
			sDescription = "";
			iValue = 0;
			sGMOnly = false;
		else
			local i,j,tp,nm,val = string.find(fld,"type:([^\t]*)\tname:([^\t]*)\tvalue:(.*)");
			if i then
				if nm == "description" then
					sDescription = val;
				elseif nm == "number" then
					iValue = val;
				elseif nm == "gmonly" then
					sGMOnly = val;
				end
			end
		end
	end
	return tbl;
end

function modifiersTableToString(tbl)
	local result = "";
	if (not tbl) or type(tbl)~="table" then
		return "";
	end
	for k,v in pairs(tbl) do
		local nm=k;
		local tp = type(v);
		local val = "";
		if tp=="number" then
			val=""..v;
		elseif tp=="string" then
			val=v;
		elseif tp=="boolean" then
			if v then
				val="true";
			else
				val="false";
			end
		elseif tp=="table" then
			val = modifiersTableToString(v);
		else
			val = "Unknown type: "..tp;
			tp = "string";
		end
		result = result.."type:"..tp.."|name:"..nm.."|value:"..val.."\n";
	end
	return "{"..result.."}";
end

function getModifierInfoFromRoll(rRoll)
	local sDesc = "";
	local nMod = 0;
	local modifiers = Utilities.modifiersStringToTable(rRoll.modifiers);
	if modifiers then
		local nCount = 0;
		sDesc = sDesc .. "\n[";
		for i = 1, #modifiers do
			if not modifiers[i].gmonly then
				nCount = nCount + 1;
				if nCount > 1 then
					sDesc = sDesc .. ", ";
				end
				sDesc = sDesc .. modifiers[i].description .. " ";
				if tonumber(modifiers[i].number) >= 0 then
					sDesc = sDesc .. "+";
				end
				sDesc = sDesc .. modifiers[i].number;
				nMod = nMod + modifiers[i].number;
			end
		end
		sDesc = sDesc .. "]";
	end
	
	return sDesc, nMod;
end

function copyWeapon(src, dst)
	-- Main fields
	DB.setValue(dst, "isidentified", "number", DB.getValue(src, "isidentified", 1));

	DB.setValue(dst, "name", "string", DB.getValue(src, "name", ""));
	DB.setValue(dst, "nonid_name", "string", DB.getValue(src, "nonid_name", ""));
	DB.setValue(dst, "nonid_notes", "string", DB.getValue(src, "nonid_notes", ""));
	local nodeType = DB.getChild(src, "type");
	if nodeType then
		if DB.getType(nodeType) == "number" then
			DB.setValue(dst, "type", "string", ItemManager2.getItemTypeString(DB.getValue(src, "type", 0)));
		else
			DB.setValue(dst, "type", "string", DB.getValue(src, "type", ""));
		end
	end
	DB.setValue(dst, "notes", "formattedtext", DB.getValue(src, "notes", ""));

	-- Armor fields
	if DB.getChild(src, "armortype") then
		DB.setValue(dst, "armortype", "number", DB.getValue(src, "armortype", 0));
	end
	if DB.getChild(src, "defensebonus") then
		DB.setValue(dst, "defensebonus", "number", DB.getValue(src, "defensebonus", 0));
	end
	if DB.getChild(src, "minimum_mm_penalty") then
		DB.setValue(dst, "minimum_mm_penalty", "number", DB.getValue(src, "minimum_mm_penalty", 0));
	end
	if DB.getChild(src, "maximum_mm_penalty") then
		DB.setValue(dst, "maximum_mm_penalty", "number", DB.getValue(src, "maximum_mm_penalty", 0));
	end
	if DB.getChild(src, "missile_penalty") then
		DB.setValue(dst, "missile_penalty", "number", DB.getValue(src, "missile_penalty", 0));
	end
	if DB.getChild(src, "quickness_penalty") then
		DB.setValue(dst, "quickness_penalty", "number", DB.getValue(src, "quickness_penalty", 0));
	end
	if DB.getChild(src, "armor_mm_skill") then
		DB.setValue(dst, "armor_mm_skill", "string", DB.getValue(src, "armor_mm_skill", ""));
	end
	if DB.getChild(src, "protection_head") then
		DB.setValue(dst, "protection_head", "string", DB.getValue(src, "protection_head", ""));
	end
	if DB.getChild(src, "protection_face") then
		DB.setValue(dst, "protection_face", "string", DB.getValue(src, "protection_face", ""));
	end
	if DB.getChild(src, "protection_neck") then
		DB.setValue(dst, "protection_neck", "string", DB.getValue(src, "protection_neck", ""));
	end
	if DB.getChild(src, "protection_torso") then
		DB.setValue(dst, "protection_torso", "string", DB.getValue(src, "protection_torso", ""));
	end
	if DB.getChild(src, "protection_arms") then
		DB.setValue(dst, "protection_arms", "string", DB.getValue(src, "protection_arms", ""));
	end
	if DB.getChild(src, "protection_legs") then
		DB.setValue(dst, "protection_legs", "string", DB.getValue(src, "protection_legs", ""));
	end
	
	-- Shield fields
	if DB.getChild(src, "meleebonus") then
		DB.setValue(dst, "meleebonus", "number", DB.getValue(src, "meleebonus", 0));
	end
	if DB.getChild(src, "missilebonus") then
		DB.setValue(dst, "missilebonus", "number", DB.getValue(src, "missilebonus", 0));
	end
	
	-- Weapon fields
	if DB.getChild(src, "fumble") then
		DB.setValue(dst, "fumble", "number", DB.getValue(src, "fumble", 0));
	end
	if DB.getChild(src, "fumbletable") then
		local attknode = DB.createChild(dst, "fumbletable");
		if DB.getChild(src, "fumbletable.tableid") then
			DB.setValue(dst, "fumbletable.tableid", "string", DB.getValue(src, "fumbletable.tableid", ""));
		end
		if DB.getChild(src, "fumbletable.name") then
			DB.setValue(dst, "fumbletable.name", "string", DB.getValue(src, "fumbletable.name", ""));
		end
		if DB.getChild(src, "fumbletable.column") then
			DB.setValue(dst, "fumbletable.column", "string", DB.getValue(src, "fumbletable.column", ""));
		end
	end
	if DB.getChild(src, "weaponbonus") then
		DB.setValue(dst, "weaponbonus", "number", DB.getValue(src, "weaponbonus", 0));
	end
	if DB.getChild(src, "associatedskill") then
		DB.setValue(dst, "associatedskill", "string", DB.getValue(src, "associatedskill", ""));
	end
	if DB.getChild(src, "skillbonus") then
		DB.setValue(dst, "skillbonus", "number", DB.getValue(src, "skillbonus", 0));
	end
	if DB.getChild(src, "ob") then
		DB.setValue(dst, "ob", "number", tonumber(DB.getValue(src, "ob", 0)) or 0);
	end
	if DB.getChild(src, "hitsmultiplier") then
		DB.setValue(dst, "hitsmultiplier", "number", DB.getValue(src, "hitsmultiplier", 0));
	end

	if DB.getChild(src, "attacktable") then
		local attknode = DB.createChild(dst, "attacktable");
		if DB.getChild(src, "attacktable.name") then
			DB.setValue(dst, "attacktable.name", "string", DB.getValue(src, "attacktable.name", ""));
		end
		if DB.getChild(src, "attacktable.tableid") then
			DB.setValue(dst, "attacktable.tableid", "string", DB.getValue(src, "attacktable.tableid", ""));
		end
	end
	if DB.getChild(src, "max_level") then
		DB.setValue(dst, "max_level", "number", DB.getValue(src, "max_level", 0));
	end
	if DB.getChild(src, "max_rank_size") then
		DB.setValue(dst, "max_rank_size", "string", DB.getValue(src, "max_rank_size", ""));
	end
	if DB.getChild(src, "criticaltable") then
		DB.setValue(dst, "criticaltable", "string", DB.getValue(src, "criticaltable", ""));
	end
	if DB.getChild(src, "largecolumnname") then
		DB.setValue(dst, "largecolumnname", "string", DB.getValue(src, "largecolumnname", ""));
	end

	if DB.getChild(src, "altcrit1") then
		local attknode = DB.createChild(dst, "altcrit1");
		if DB.getChild(src, "altcrit1.name") then
			DB.setValue(dst, "altcrit1.name", "string", DB.getValue(src, "altcrit1.name", ""));
		end
		if DB.getChild(src, "altcrit1.tableid") then
			DB.setValue(dst, "altcrit1.tableid", "string", DB.getValue(src, "altcrit1.tableid", ""));
		end
	end
	if DB.getChild(src, "altcrit1mod") then
		DB.setValue(dst, "altcrit1mod", "number", DB.getValue(src, "altcrit1mod", 0));
	end
	if DB.getChild(src, "altcrit2") then
		local attknode = DB.createChild(dst, "altcrit2");
		if DB.getChild(src, "altcrit2.name") then
			DB.setValue(dst, "altcrit2.name", "string", DB.getValue(src, "altcrit2.name", ""));
		end
		if DB.getChild(src, "altcrit2.tableid") then
			DB.setValue(dst, "altcrit2.tableid", "string", DB.getValue(src, "altcrit2.tableid", ""));
		end
	end
	if DB.getChild(src, "altcrit2mod") then
		DB.setValue(dst, "altcrit2mod", "number", DB.getValue(src, "altcrit2mod", 0));
	end
	if DB.getChild(src, "altcrit3") then
		local attknode = DB.createChild(dst, "altcrit3");
		if DB.getChild(src, "altcrit3.name") then
			DB.setValue(dst, "altcrit3.name", "string", DB.getValue(src, "altcrit3.name", ""));
		end
		if DB.getChild(src, "altcrit3.tableid") then
			DB.setValue(dst, "altcrit3.tableid", "string", DB.getValue(src, "altcrit3.tableid", ""));
		end
	end
	if DB.getChild(src, "altcrit3mod") then
		DB.setValue(dst, "altcrit3mod", "number", DB.getValue(src, "altcrit3mod", 0));
	end

	if DB.getChild(src, "addcrit1") then
		local attknode = DB.createChild(dst, "addcrit1");
		if DB.getChild(src, "addcrit1.name") then
			DB.setValue(dst, "addcrit1.name", "string", DB.getValue(src, "addcrit1.name", ""));
		end
		if DB.getChild(src, "addcrit1.tableid") then
			DB.setValue(dst, "addcrit1.tableid", "string", DB.getValue(src, "addcrit1.tableid", ""));
		end
	end
	if DB.getChild(src, "addcrit1leveldiff") then
		DB.setValue(dst, "addcrit1leveldiff", "number", DB.getValue(src, "addcrit1leveldiff", 0));
	end
	if DB.getChild(src, "addcrit2") then
		local attknode = DB.createChild(dst, "addcrit2");
		if DB.getChild(src, "addcrit2.name") then
			DB.setValue(dst, "addcrit2.name", "string", DB.getValue(src, "addcrit2.name", ""));
		end
		if DB.getChild(src, "addcrit2.tableid") then
			DB.setValue(dst, "addcrit2.tableid", "string", DB.getValue(src, "addcrit2.tableid", ""));
		end
	end
	if DB.getChild(src, "addcrit2leveldiff") then
		DB.setValue(dst, "addcrit2leveldiff", "number", DB.getValue(src, "addcrit2leveldiff", 0));
	end

	if DB.getChild(src, "rngslots") then
		DB.setValue(dst, "rngslots", "number", DB.getValue(src, "rngslots", 0));
	end
	for r=1,6 do
		--[[ range limit ]]
		if DB.getChild(src, "rng" .. r) then
			DB.setValue(dst, "rng" .. r, "number", DB.getValue(src, "rng" .. r, 0));
		end
		--[[ attack modifier ]]
		if DB.getChild(src, "mod" .. r) then
			DB.setValue(dst, "mod" .. r, "number", DB.getValue(src, "mod" .. r, 0));
		end
	end

	if DB.getChild(src, "at1_4") then
		DB.setValue(dst, "at1_4", "number", DB.getValue(src, "at1_4", 0));
	end
	if DB.getChild(src, "at5_8") then
		DB.setValue(dst, "at5_8", "number", DB.getValue(src, "at5_8", 0));
	end
	if DB.getChild(src, "at9_12") then
		DB.setValue(dst, "at9_12", "number", DB.getValue(src, "at9_12", 0));
	end
	if DB.getChild(src, "at13_16") then
		DB.setValue(dst, "at13_16", "number", DB.getValue(src, "at13_16", 0));
	end
	if DB.getChild(src, "at17_20") then
		DB.setValue(dst, "at17_20", "number", DB.getValue(src, "at17_20", 0));
	end

	if DB.getChild(src, "description") then
		DB.setValue(dst, "description", "string", DB.getValue(src, "description", ""));
	end

	-- Magic Item fields
	if DB.getChild(src, "realm") then
		DB.setValue(dst, "realm", "string", DB.getValue(src, "realm", ""));
	end
	if DB.getChild(src, "adderbonus") then
		DB.setValue(dst, "adderbonus", "number", DB.getValue(src, "adderbonus", 0));
	end
	if DB.getChild(src, "multiplierbonus") then
		DB.setValue(dst, "multiplierbonus", "number", DB.getValue(src, "multiplierbonus", 0));
	end
	if DB.getChild(src, "charges") then
		DB.setValue(dst, "charges", "string", DB.getValue(src, "charges", ""));
	end
	if DB.getChild(src, "level") then
		DB.setValue(dst, "level", "string", DB.getValue(src, "level", ""));
	end
	if DB.getChild(src, "composition") then
		DB.setValue(dst, "composition", "string", DB.getValue(src, "composition", ""));
	end
	if DB.getChild(src, "use") then
		DB.setValue(dst, "use", "string", DB.getValue(src, "use", ""));
	end
	
	-- Herb fields
	if DB.getChild(src, "aoe") then
		DB.setValue(dst, "aoe", "string", DB.getValue(src, "aoe", ""));
	end
	if DB.getChild(src, "codes") then
		DB.setValue(dst, "codes", "string", DB.getValue(src, "codes", ""));
	end
	if DB.getChild(src, "form") then
		DB.setValue(dst, "form", "string", DB.getValue(src, "form", ""));
	end
	
	-- Transport fields
	if DB.getChild(src, "ftrn") then
		DB.setValue(dst, "ftrn", "string", DB.getValue(src, "ftrn", ""));
	end
	if DB.getChild(src, "mihr") then
		DB.setValue(dst, "mihr", "string", DB.getValue(src, "mihr", ""));
	end
	if DB.getChild(src, "mnb") then
		DB.setValue(dst, "mnb", "string", DB.getValue(src, "mnb", ""));
	end
	if DB.getChild(src, "htwt") then
		DB.setValue(dst, "htwt", "string", DB.getValue(src, "htwt", ""));
	end
	if DB.getChild(src, "capacity") then
		DB.setValue(dst, "capacity", "string", DB.getValue(src, "capacity", ""));
	end
	if DB.getChild(src, "transport_ob") then
		DB.setValue(dst, "transport_ob", "string", DB.getValue(src, "transport_ob", ""));
	end
	
	-- General fields
	if DB.getChild(src, "cost") then
		DB.setValue(dst, "cost", "string", DB.getValue(src, "cost", ""));
	end
	if DB.getChild(src, "weight") then
		DB.setValue(dst, "weight", "number", DB.getValue(src, "weight", 0));
	end
	if DB.getChild(src, "length") then
		DB.setValue(dst, "length", "string", DB.getValue(src, "length", ""));
	end
	if DB.getChild(src, "strength") then
		DB.setValue(dst, "strength", "string", DB.getValue(src, "strength", ""));
	end
	if DB.getChild(src, "breakagefactor") then
		DB.setValue(dst, "breakagefactor", "string", DB.getValue(src, "breakagefactor", ""));
	end
	if DB.getChild(src, "breakage_factor") then
		DB.setValue(dst, "breakage_factor", "string", DB.getValue(src, "breakage_factor", ""));
	end
	if DB.getChild(src, "breakfactor") then
		DB.setValue(dst, "breakfactor", "string", DB.getValue(src, "breakfactor", ""));
	end
	if DB.getChild(src, "broken") then
		DB.setValue(dst, "broken", "number", DB.getValue(src, "broken", 0));
	end
	if DB.getChild(src, "prod") then
		DB.setValue(dst, "prod", "string", DB.getValue(src, "prod", ""));
	end
	if DB.getChild(src, "size") then
		DB.setValue(dst, "size", "string", DB.getValue(src, "size", ""));
	end
	if DB.getChild(src, "stanvalx") then
		DB.setValue(dst, "stanvalx", "number", DB.getValue(src, "stanvalx", 0));
	end
	if DB.getChild(src, "totalvalue") then
		DB.setValue(dst, "totalvalue", "number", DB.getValue(src, "totalvalue", 0));
	end
	if DB.getChild(src, "value") then
		DB.setValue(dst, "value", "number", DB.getValue(src, "value", 0));
	end
	
	-- ESF fields
	if DB.getChild(src, "esf_weight_organic_living") then
		DB.setValue(dst, "esf_weight_organic_living", "number", DB.getValue(src, "esf_weight_organic_living", 0));
	end
	if DB.getChild(src, "esf_weight_organic_dead") then
		DB.setValue(dst, "esf_weight_organic_dead", "number", DB.getValue(src, "esf_weight_organic_dead", 0));
	end
	if DB.getChild(src, "esf_weight_inorganic") then
		DB.setValue(dst, "esf_weight_inorganic", "number", DB.getValue(src, "esf_weight_inorganic", 0));
	end

	if DB.getChild(src, "esf_armor_essence") then
		DB.setValue(dst, "esf_armor_essence", "number", DB.getValue(src, "esf_armor_essence", 0));
	end
	if DB.getChild(src, "esf_armor_channeling") then
		DB.setValue(dst, "esf_armor_channeling", "number", DB.getValue(src, "esf_armor_channeling", 0));
	end

	if DB.getChild(src, "esf_helmet_essence") then
		DB.setValue(dst, "esf_helmet_essence", "number", DB.getValue(src, "esf_helmet_essence", 0));
	end
	if DB.getChild(src, "esf_helmet_channeling") then
		DB.setValue(dst, "esf_helmet_channeling", "number", DB.getValue(src, "esf_helmet_channeling", 0));
	end
	if DB.getChild(src, "esf_helmet_mentalism") then
		DB.setValue(dst, "esf_helmet_mentalism", "number", DB.getValue(src, "esf_helmet_mentalism", 0));
	end

	return dst;
end

function strencode(str)
	local result = str;
	result = string.gsub(result,"@", "|at;");
	result = string.gsub(result,"\n","|nl;");
	result = string.gsub(result,"{", "|op;");
	result = string.gsub(result,"}", "|cl;");
	return result;
end

function strdecode(str)
	local result = str;
	result = string.gsub(result,"|nl;","\n");
	result = string.gsub(result,"|op;","{");
	result = string.gsub(result,"|cl;","}");
	result = string.gsub(result,"|at;","@");
	return result;
end

-- Languages
function LanguageList()
	local listLanguages = {};

	for _,v in pairs(DB.getChildren("languages")) do
		local sLang = DB.getValue(v, "name", "")
		sLang = StringManager.trim(sLang)
		if (sLang or "") ~= "" then
			table.insert(listLanguages, sLang);
		end
	end

	return listLanguages;
end

-- Copy PC to NPC
function copyPCToNPC(nodePC)
	if not nodePC then
		return nil;
	end
	
	local nodeNPC = DB.createChild("npc");
	
	-- Main Tab
	DB.setValue(nodeNPC, "name", "string", DB.getValue(nodePC, "name", ""));
	DB.setValue(nodeNPC, "token", "token", DB.getValue(nodePC, "token", ""));
	DB.setValue(nodeNPC, "size", "string", "Medium");
  	DB.setValue(nodeNPC, "senses", "string", DB.getValue(nodePC, "senses", ""));
	DB.setValue(nodeNPC, "level", "number", DB.getValue(nodePC, "level", 0));
	DB.setValue(nodeNPC, "at", "number", DB.getValue(nodePC, "at", 0));
 	DB.setValue(nodeNPC, "hits", "number", DB.getValue(nodePC, "hits.max", 0));
 	DB.setValue(nodeNPC, "db", "number", DB.getValue(nodePC, "db", 0));
 	DB.setValue(nodeNPC, "baserate", "number", DB.getValue(nodePC, "bmr.total", 0));
 	DB.setValue(nodeNPC, "mnbonus", "number", DB.getValue(nodePC, "mmpenalty", 0));
 	DB.setValue(nodeNPC, "initmod", "number", DB.getValue(nodePC, "initiative.total", 0));
 	DB.setValue(nodeNPC, "exhaustionmisc", "number", DB.getValue(nodePC, "exhaustion_misc", 0));
 	DB.setValue(nodeNPC, "exhaustionmax", "number", DB.getValue(nodePC, "exhaustion_total", 0));

	for _, nodeAttackDefense in pairs(DB.getChildren(nodePC, "weapons")) do
		local nodeEntryList = nil;
		if DB.getValue(nodeAttackDefense, "type", "") == "Shield" then
			nodeEntryList = DB.createChild(nodeNPC, "defences");
		else
			nodeEntryList = DB.createChild(nodeNPC, "weapons");
		end
		if nodeEntryList then
			local nodeNewEntry = DB.createChild(nodeEntryList);
			if nodeNewEntry then
				local sClass, sRecordName = DB.getValue(nodeAttackDefense, "open", nil);
				if sRecordName and sRecordName ~="" then
					local nodeItem = DB.findNode(sRecordName);
					if nodeItem then
						DB.copyNode(nodeItem, nodeNewEntry);  -- DAKADIN
					end
				else
					DB.copyNode(nodeAttackDefense, nodeNewEntry);  -- DAKADIN
				end
				DB.setValue(nodeNewEntry, "open", "windowreference", "item", DB.getPath(nodeNewEntry));
			end
		end
	end
	
	local nodeProtection = DB.createChild(nodePC, "protection");
	local nodeNPCProtection = DB.createChild(nodeNPC, "protection");
	DB.copyNode(nodeProtection, nodeNPCProtection);

	-- Character Tab
	DB.setValue(nodeNPC, "profession", "string", DB.getValue(nodePC, "profession", ""));
	DB.setValue(nodeNPC, "race", "string", DB.getValue(nodePC, "race", ""));

	for _, nodeStat in pairs(DB.getChildren(nodePC, "abilities")) do
		local nodeNPCStat = DB.createChild(DB.createChild(nodeNPC, "stats"), DB.getName(nodeStat));
		DB.setValue(nodeNPCStat, "temp", "number", DB.getValue(nodeStat, "temp", 0));
		DB.setValue(nodeNPCStat, "bonus", "number", DB.getValue(nodeStat, "bonus", 0));
		DB.setValue(nodeNPCStat, "race", "number", DB.getValue(nodeStat, "race", 0));
		DB.setValue(nodeNPCStat, "misc", "number", DB.getValue(nodeStat, "special", 0));
		DB.setValue(nodeNPCStat, "total", "number", DB.getValue(nodeStat, "total", 0));
	end

	for _, nodeRRBase in pairs(DB.getChildren(nodePC, "rr.base")) do
		local sBaseRRName = DB.getName(nodeRRBase);
		local nodeNPCRRBase = DB.createChild(DB.createChild(DB.createChild(nodeNPC, "rr"), "base"), DB.getName(nodeRRBase));
		DB.setValue(nodeNPCRRBase, "statname", "string", Rules_RR.GetStatFromBaseRR(sBaseRRName));
		DB.setValue(nodeNPCRRBase, "misc", "number", DB.getValue(nodeRRBase, "misc", 0) + DB.getValue(nodeRRBase, "special", 0) + DB.getValue(nodeRRBase, "item", 0));
	end

	for _, nodeRRBase in pairs(DB.getChildren(nodePC, "rr.hybrid")) do
		local sHybridRRName = DB.getName(nodeRRBase);
		local nodeNPCRRBase = DB.createChild(DB.createChild(DB.createChild(nodeNPC, "rr"), "hybrid"), DB.getName(nodeRRBase));
		DB.setValue(nodeNPCRRBase, "resistances", "string", Rules_RR.GetResistancesFromHybridRR(sHybridRRName));
		DB.setValue(nodeNPCRRBase, "misc", "number", DB.getValue(nodeRRBase, "misc", 0) + DB.getValue(nodeRRBase, "item", 0));
	end

	-- Spell/Skill Tab
	DB.setValue(nodeNPC, "realm", "string", DB.getValue(nodePC, "realm", ""));
	DB.setValue(nodeNPC, "pp.max", "number", DB.getValue(nodePC, "pp.max", 0));
	DB.setValue(nodeNPC, "pp.used", "number", DB.getValue(nodePC, "pp.used", 0));
	DB.setValue(nodeNPC, "pp.spelladdermax", "number", DB.getValue(nodePC, "pp.spelladdermax", 0));
	DB.setValue(nodeNPC, "pp.spelladderused", "number", DB.getValue(nodePC, "pp.spelladderused", 0));

	-- Backward compatibility
	DB.setValue(nodeNPC, "ppmax", "number", DB.getValue(nodePC, "pp.max", 0));
	DB.setValue(nodeNPC, "ppused", "number", DB.getValue(nodePC, "pp.used", 0));
	DB.setValue(nodeNPC, "spelladdermax", "number", DB.getValue(nodePC, "pp.spelladdermax", 0));
	DB.setValue(nodeNPC, "spelladderused", "number", DB.getValue(nodePC, "pp.spelladderused", 0));
	
	for _, nodeSpellList in pairs(DB.getChildren(nodePC, "spells")) do
		local nodeNPCSpellList = DB.createChild(DB.createChild(nodeNPC, "spells"));
		DB.copyNode(nodeSpellList, nodeNPCSpellList);
	end
	
	for _, nodeSkill in pairs(DB.getChildren(nodePC, "skills")) do
		local nodeNPCSkill = DB.createChild(DB.createChild(nodeNPC, "skills"));
		DB.setValue(nodeNPCSkill, "name", "string", DB.getValue(nodeSkill, "name", ""));
		DB.setValue(nodeNPCSkill, "ranks", "number", DB.getValue(nodeSkill, "rank", 0));
		DB.setValue(nodeNPCSkill, "bonus", "number", DB.getValue(nodeSkill, "total", 0));
	end

	-- Notes Tab
 	DB.setValue(nodeNPC, "group", "string", "NPC");
	
	local sNotes = DB.getValue(nodePC, "notes", "");
	local sGMNotes = DB.getValue(nodePC, "gmnotes", ""); 
	if sNotes ~= "" then
		sNotes = sNotes:gsub("&", "&amp;");
		sNotes = sNotes:gsub("<", "&lt;");
		sNotes = "<p><b>PC NOTES</b></p><p>" .. sNotes:gsub("\n", "</p><p>") .. "</p>";
	end
	if sGMNotes ~= "" then
		sGMNotes = sGMNotes:gsub("&", "&amp;");
		sGMNotes = sGMNotes:gsub("<", "&lt;");
		sGMNotes = "<p><b>GM NOTES</b></p><p>" .. sGMNotes:gsub("\n", "</p><p>") .. "</p>";
	end
	if sNotes ~= "" or sGMNotes ~= "" then
		DB.setValue(nodeNPC, "notes", "formattedtext", sNotes .. sGMNotes);
	end
	
	local sGender = DB.getValue(nodePC, "sex", "");
	local sAge = DB.getValue(nodePC, "age", "");
	local sHair = DB.getValue(nodePC, "hair", "");
	local sEyes = DB.getValue(nodePC, "eyes", "");
	local sHeight = DB.getValue(nodePC, "height", "");
	local nWeight = DB.getValue(nodePC, "weight", 0);
	local nAppearance = DB.getValue(nodePC, "appearance", 0);
	local sAppearanceDesc = DB.getValue(nodePC, "appearancedesc", "");
	if sAppearanceDesc ~= "" then
		sAppearanceDesc = "<p><b>Appearance Description</b></p><p>" .. sAppearanceDesc:gsub("\n", "</p><p>") .. "</p>";
	end
	local sDescription = "<table><tr><td><b>Gender</b></td><td>" .. sGender .. "</td><td><b>Age</b></td><td>" .. sAge .. "</td></tr>"
	sDescription = sDescription .. "<tr><td><b>Hair</b></td><td>" .. sHair .. "</td><td><b>Eyes</b></td><td>" .. sEyes .. "</td></tr>"
	sDescription = sDescription .. "<tr><td><b>Height</b></td><td>" .. sHeight .. "</td><td><b>Weight</b></td><td>" .. nWeight .. "</td></tr>"
	sDescription = sDescription .. "<tr><td><b>App.</b></td><td>" .. nAppearance .. "</td></tr></table>"
	sDescription = sDescription .. sAppearanceDesc;	
	DB.setValue(nodeNPC, "description", "formattedtext", sDescription);
	
	local sAbilities = "";
	if DB.getChild(nodePC, "languagelist") then
		sAbilities = sAbilities .. "<table><tr><td><b>Language</b></td><td><b>Write</b></td><td><b>Speak</b></td></tr>";
		for _, nodeLanguage in pairs(DB.getChildren(nodePC, "languagelist")) do
			local sLanguage = DB.getValue(nodeLanguage, "name", "");
			local nWrite = DB.getValue(nodeLanguage, "written", 0);
			local nSpeak = DB.getValue(nodeLanguage, "spoken", 0);
			sAbilities = sAbilities .. "<tr><td>" .. sLanguage .. "</td><td>" .. nWrite .. "</td><td>" .. nSpeak .. "</td></tr>";
			
		end
		sAbilities = sAbilities .. "</table>"
	end
	
	if sAbilities ~= "" then
		DB.setValue(nodeNPC, "abilities", "formattedtext", sAbilities);
	end
	
	return nodeNPC;
end
