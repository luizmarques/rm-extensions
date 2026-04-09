-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ItemManager.setEncumbranceFields("charsheet", { "carried", "count", "totalweight", "weight" });
	CharEncumbranceManager.addCustomCalc(CharEncumbranceManagerRMC.calcEncumbrance);
end

function calcEncumbrance(nodeChar)
	local nEncumbrance = CharEncumbranceManagerRMC.calcInventoryEncumbrance(nodeChar);
	nEncumbrance = nEncumbrance + CharEncumbranceManager.calcDefaultCurrencyEncumbrance(nodeChar);
	CharEncumbranceManager.setDefaultEncumbranceValue(nodeChar, nEncumbrance);
end

function calcInventoryEncumbrance(nodeChar)
 	local nInvTotal = 0;

	local tInventoryPaths = ItemManager.getInventoryPaths("charsheet");
	for _,sList in ipairs(tInventoryPaths) do
		for _,nodeItem in pairs(DB.getChildren(nodeChar, sList)) do
			nInvTotal = nInvTotal + DB.getValue(nodeItem, "totalweight", 0);
		end
	end

	return nInvTotal;
end

function updateTotalWeight(nodeInventoryItem)
	local nCarried = DB.getValue(nodeInventoryItem, "carried", 0);
	local sType = DB.getValue(nodeInventoryItem, "type", "");
	if nCarried == 0 or (nCarried == 2 and (sType == "Armor" or sType == "Helmet" or sType == "Clothing")) then
		DB.setValue(nodeInventoryItem, "totalweight", "number", 0);
	else
		local nCount = DB.getValue(nodeInventoryItem, "count", 0);
		local nWeight = DB.getValue(nodeInventoryItem, "weight", 0);

		-- Assume at least one
		if nCount < 1 then
			nCount = 1;
		end
		nTotalWeight = nCount * nWeight;
		DB.setValue(nodeInventoryItem, "totalweight", "number", nTotalWeight);
	end
end

function onEncumbranceChanged(nodeChar)
	local nWeight = DB.getValue(nodeChar, "weight", 0);
	local nAllowance = math.floor(nWeight/10);
	local nLoad = DB.getValue(nodeChar, "encumbrance.load", 0);
	local nPenalty = Rules_Modifiers.EncumbrancePenalty(nAllowance, nLoad);
	local nStat = Rules_PC.EncumbranceStatBonus(nodeChar);
	local nMisc = DB.getValue(nodeChar, "encumbrance.misc", 0);
	local nTotal = nPenalty + nStat + nMisc;
	if nTotal > 0 then
		nTotal = 0;
	end

	DB.setValue(nodeChar, "encumbrance.allowance", "number", nAllowance);
	DB.setValue(nodeChar, "encumbrance.base", "number", nPenalty);
	DB.setValue(nodeChar, "encumbrance.stat", "number", nStat);
	DB.setValue(nodeChar, "encumbrance.misc", "number", nMisc);
	DB.setValue(nodeChar, "encumbrance.total", "number", nTotal);
	DB.setValue(nodeChar, "dbpen", "number", Rules_PC.ArmorQuicknessPenalty(nodeChar));
end
