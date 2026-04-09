-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	CharManager.initCharCopyToNPCSupport();

	ItemManager.setCustomCharAdd(CharManager.onCharItemAdd);

	if Session.IsHost then
		CharInventoryManager.enableInventoryUpdates();
		CharInventoryManager.enableSimpleLocationHandling();

		CharInventoryManager.registerFieldUpdateCallback("carried", CharManager.onCharInventoryWeightCalc);
	end
end

function onCharItemAdd(nodeItem)
	DB.setValue(nodeItem, "carried", "number", 1);
end
function onCharInventoryWeightCalc(nodeItem)
	CharEncumbranceManagerRMC.updateTotalWeight(nodeItem);
	CharEncumbranceManagerRMC.calcEncumbrance(DB.getChild(nodeItem, "..."));
end

function initCharCopyToNPCSupport()
	ToolbarManager.registerButton("charsheet_copytonpc", 
		{ 
			sType = "action",
			sIcon = "button_toolbar_copy",
			sTooltipRes = "char_tooltip_copytonpc",
			fnActivate = CharManager.onCharCopyToNPCButtonPressed,
			bHostOnly = true,
		});
end
function onCharCopyToNPCButtonPressed(c)
	if not Session.IsHost then
		return;
	end

	local wChar = WindowManager.getTopWindow(c.window);
	local nodeChar = wChar.getDatabaseNode();
	local nodeTarget = Utilities.copyPCToNPC(nodeChar);
	Interface.openWindow("npc", nodeTarget);
end

--
-- ACTIONS
--

function rest(nodeChar, bLong)
	PowerManager.resetPowers(nodeChar, bLong);
	resetHealth(nodeChar, bLong);
end
function resetHealth(nodeChar, bLong)
	local bResetWounds = false;
	local bResetTemp = false;
	local bResetHitDice = false;
	local bResetHalfHitDice = false;
	local bResetQuarterHitDice = false;
	
	local sOptHRHV = OptionsManager.getOption("HRHV");
	if sOptHRHV == "fast" then
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHitDice = true;
		else
			bResetQuarterHitDice = true;
		end
	elseif sOptHRHV == "slow" then
		if bLong then
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	else
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	end
	
	-- Reset health fields and conditions
	if bResetWounds then
		DB.setValue(nodeChar, "hp.wounds", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavesuccess", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavefail", "number", 0);
	end
	if bResetTemp then
		DB.setValue(nodeChar, "hp.temporary", "number", 0);
	end
	
	-- Reset all hit dice
	if bResetHitDice then
		for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
			DB.setValue(vClass, "hdused", "number", 0);
		end
	end

	-- Reset half or quarter of hit dice (assume biggest hit dice selected first)
	if bResetHalfHitDice or bResetQuarterHitDice then
		local nHDUsed, nHDTotal = getClassHDUsage(nodeChar);
		if nHDUsed > 0 then
			local nHDRecovery;
			if bResetQuarterHitDice then
				nHDRecovery = math.max(math.floor(nHDTotal / 4), 1);
			else
				nHDRecovery = math.max(math.floor(nHDTotal / 2), 1);
			end
			if nHDRecovery >= nHDUsed then
				for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
					DB.setValue(vClass, "hdused", "number", 0);
				end
			else
				local nodeClassMax, nClassMaxHDSides, nClassMaxHDUsed;
				while nHDRecovery > 0 do
					nodeClassMax = nil;
					nClassMaxHDSides = 0;
					nClassMaxHDUsed = 0;
					
					for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
						local nClassHDUsed = DB.getValue(vClass, "hdused", 0);
						if nClassHDUsed > 0 then
							local aClassDice = DB.getValue(vClass, "hddie", {});
							if #aClassDice > 0 then
								local nClassHDSides = tonumber(aClassDice[1]:sub(2)) or 0;
								if nClassHDSides > 0 and nClassMaxHDSides < nClassHDSides then
									nodeClassMax = vClass;
									nClassMaxHDSides = nClassHDSides;
									nClassMaxHDUsed = nClassHDUsed;
								end
							end
						end
					end
					
					if nodeClassMax then
						if nHDRecovery >= nClassMaxHDUsed then
							DB.setValue(nodeClassMax, "hdused", "number", 0);
							nHDRecovery = nHDRecovery - nClassMaxHDUsed;
						else
							DB.setValue(nodeClassMax, "hdused", "number", nClassMaxHDUsed - nHDRecovery);
							nHDRecovery = 0;						
						end
					else
						break;
					end
				end
			end
		end
	end
end

--
-- CHARACTER SHEET DROPS
--

function addInfoDB(nodeChar, sClass, sRecord)
	-- Validate parameters
	if not nodeChar then
		return false;
	end
	
	if sClass == "reference_race" then
		addRaceRef(nodeChar, sClass, sRecord);
	elseif sClass == "reference_profession" then
		addProfessionRef(nodeChar, sClass, sRecord);
	else
		return false;
	end
	
	return true;
end

function addRaceRef(nodeChar, sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		ChatManager.SystemMessage(Interface.getString("char_error_missingrecord"));
		return;
	end
	
	if sClass == "reference_race" then
		local aTable = {};
		aTable["char"] = nodeChar;
		aTable["class"] = sClass;
		aTable["record"] = nodeSource;
		
		addRaceSelect(aTable);
	end
end
function addRaceSelect(aTable)
	local nodeChar = aTable["char"];
	local nodeSource = aTable["record"];
	
	-- Determine race to display on sheet and in notifications
	local sRace = DB.getValue(nodeSource, "name", "");
	
	-- Notify
	ChatManager.SystemMessageResource("char_abilities_message_raceadd", sRace, DB.getValue(nodeChar, "name", ""));
	
	-- Add the name and link to the main character sheet
	DB.setValue(nodeChar, "race", "string", sRace);
	DB.setValue(nodeChar, "racelink", "windowreference", aTable["class"], DB.getPath(nodeSource));
end

function addProfessionRef(nodeChar, sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		ChatManager.SystemMessage(Interface.getString("char_error_missingrecord"));
		return;
	end
	
	if sClass == "reference_profession" then
		local aTable = {};
		aTable["char"] = nodeChar;
		aTable["class"] = sClass;
		aTable["record"] = nodeSource;
		
		addProfessionSelect(aTable);
	end
end
function addProfessionSelect(aTable)
	local nodeChar = aTable["char"];
	local nodeSource = aTable["record"];
	
	-- Determine profession to display on sheet and in notifications
	local sProfession = DB.getValue(nodeSource, "name", "");
	
	-- Notify
	ChatManager.SystemMessageResource("char_abilities_message_professionadd", sProfession, DB.getValue(nodeChar, "name", ""));
	
	-- Add the name and link to the main character sheet
	DB.setValue(nodeChar, "profession", "string", sProfession);
	DB.setValue(nodeChar, "professionlink", "windowreference", aTable["class"], DB.getPath(nodeSource));
end
